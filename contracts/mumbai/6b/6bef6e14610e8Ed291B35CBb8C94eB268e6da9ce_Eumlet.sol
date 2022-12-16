// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";

contract Eumlet is Ownable, ReentrancyGuard {
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public utils;
    uint256 public limit;
    mapping(address => mapping(uint128 => Stream)) public userToStreams;
    mapping(address => mapping(uint128 => Deferred)) public userToDeferred;
    mapping(address => Ids) public userToIds;
    // all supported tokens return value == 1
    mapping(address => uint256) public tokens;

    struct Ids {
        uint128 streamId;
        uint128 deferredId;
    }

    struct Stream {
        address creator;
        address token;
        bool paused;
        uint256 amount;
        uint128 start;
        uint128 end;
        uint128 step;
        uint128 lastClaimed;
    }

    struct Deferred {
        address creator;
        address token;
        uint256 amount;
        uint256 unlockTime;
    }

    event Multisend(
        address from,
        address token,
        address[] users,
        uint256[] amounts
    );
    event Multistream(
        address from,
        address token,
        uint128 start,
        address[] users,
        uint128[] ids,
        uint256[] amounts // all stream amount
    );
    event DeferredTransfer(
        address from,
        address token,
        address[] users,
        uint128[] ids,
        uint256[] amounts
    );
    event Withdraw(address user, uint128 id, uint256 amount);
    event Claim(address user, uint128 id);
    event Pause(address user, uint128 id);
    event Resume(address user, uint128 id);
    event CancelStream(address user, uint128 id, int256 deferredId);
    event CancelDeferred(address user, uint128 id);
    event Resolve(address user, uint128 id, bool stream);

    modifier eqLengths(uint256 len1, uint256 len2) {
        require(len1 == len2, "Lengths not equal");
        _;
    }

    modifier exist(uint128 nextId, uint128 id) {
        require(nextId > id, "Wrong id");
        _;
    }

    constructor(
        address owner,
        address[2] memory _tokens,
        uint256 _limit
    ) {
        require(
            owner != address(0) &&
                _tokens[0] != address(0) &&
                _tokens[1] != address(0) &&
                _limit > 0,
            "Zero params"
        );
        _transferOwnership(owner);
        tokens[_tokens[0]] = 1;
        tokens[_tokens[1]] = 1;
        tokens[NATIVE] = 1;
        limit = _limit;
    }

    function approveProposal(
        address creator,
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount,
        bytes calldata data
    ) external payable nonReentrant {
        require(msg.sender == utils, "Only utils contract");
        if (data.length == 96) {
            _multistream(
                creator,
                token,
                accounts,
                amounts,
                abi.decode(data, (uint128[3])),
                totalAmount
            );
        } else if (data.length == 32) {
            _deferredTransfer(
                creator,
                token,
                accounts,
                amounts,
                abi.decode(data, (uint256)),
                totalAmount
            );
        } else if (data.length == 0) {
            if (token == NATIVE) {
                _multisendNative(accounts, amounts, totalAmount);
            } else {
                _multisendToken(token, accounts, amounts, totalAmount);
            }
            emit Multisend(creator, token, accounts, amounts);
        } else {
            revert("Wrong data");
        }
    }

    /**
     * @notice allow send tokens/native for multiple users in one call
     * @param token - address of supported tokens, = NATIVE if send native,
     * tokens must be approved for totalAmount before call
     * @param accounts - addresses of users, who will receive tokens
     * @param amounts - amounts of tokens, accounts[i] will receive amounts[i]
     * @param totalAmount - sum of all amounts
     */
    function multisend(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external payable nonReentrant eqLengths(accounts.length, amounts.length) {
        require(totalAmount > 0, "Zero total amount");
        require(tokens[token] == 1, "Unsupported token");
        if (token == NATIVE) {
            require(msg.value == totalAmount, "Wrong amount sended");
            _multisendNative(accounts, amounts, totalAmount);
        } else {
            require(msg.value == 0, "Native sended");
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                totalAmount
            );
            _multisendToken(token, accounts, amounts, totalAmount);
        }
        emit Multisend(msg.sender, token, accounts, amounts);
    }

    /**
     * @notice create streams for users - sended amount will lineary unlock within duration
     * @param token - address of supported tokens, = NATIVE if send native,
     * tokens must be approved for totalAmount before call
     * @param accounts - addresses of users, who will receive tokens
     * @param amounts - amounts of tokens, accounts[i] will receive amounts[i]
     * @param params - [0] - start, [1] - steps num, [2] - step in sec
     * @param totalAmount - sum of all amounts * steps num
     */
    function multistream(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint128[3] calldata params,
        uint256 totalAmount
    ) external payable nonReentrant eqLengths(accounts.length, amounts.length) {
        require(totalAmount > 0, "Zero total amount");
        require(
            params[0] >= block.timestamp && params[1] > 0 && params[2] > 0,
            "Wrong params"
        );
        _collectTokens(token, totalAmount);
        _multistream(msg.sender, token, accounts, amounts, params, totalAmount);
    }

    /**
     * @notice
     */
    function deferredTransfer(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 unlockTimestamp,
        uint256 totalAmount
    ) external payable nonReentrant eqLengths(accounts.length, amounts.length) {
        require(totalAmount > 0, "Zero total amount");
        require(unlockTimestamp > block.timestamp, "Wrong unlock time");
        _collectTokens(token, totalAmount);
        _deferredTransfer(
            msg.sender,
            token,
            accounts,
            amounts,
            unlockTimestamp,
            totalAmount
        );
    }

    /**
     * @notice allow users withdraw unlocked amount from stream
     * @param streamId - index of stream in userToStream[msg.sender]
     */
    function withdraw(uint128 streamId)
        external
        nonReentrant
        exist(userToIds[msg.sender].streamId, streamId)
    {
        Stream storage stream = userToStreams[msg.sender][streamId];
        require(stream.amount > 0, "Stream ended");
        if (stream.paused && stream.start + 10 minutes <= block.timestamp) {
            _resume(msg.sender, streamId, 10 minutes);
        }
        (uint256 amount, uint128 numSteps) = pendingStream(
            msg.sender,
            streamId
        );
        require(amount > 0, "Nothing to withdraw");
        stream.lastClaimed += stream.step * numSteps;
        _sendTokens(stream.token, msg.sender, amount);
        if (stream.lastClaimed == stream.end) {
            delete userToStreams[msg.sender][streamId];
        }
        emit Withdraw(msg.sender, streamId, amount);
    }

    /**
     * @notice allow users withdraw unlocked amount from deferred transfer
     * @param deferredId - index of deferred in userToDeferred[msg.sender]
     */
    function claim(uint128 deferredId)
        external
        nonReentrant
        exist(userToIds[msg.sender].deferredId, deferredId)
    {
        Deferred memory deferred = userToDeferred[msg.sender][deferredId];
        require(deferred.unlockTime <= block.timestamp, "Come back later");
        require(deferred.amount > 0, "Already claimed");
        delete userToDeferred[msg.sender][deferredId];
        _sendTokens(deferred.token, msg.sender, deferred.amount);
        emit Claim(msg.sender, deferredId);
    }

    /**
     * @notice allow stream creator pause it
     */
    function pause(address user, uint128 streamId)
        external
        exist(userToIds[user].streamId, streamId)
    {
        Stream storage stream = userToStreams[user][streamId];
        require(stream.creator == msg.sender, "Only creator");
        require(stream.paused == false, "Already paused");
        require(
            stream.start < block.timestamp && block.timestamp < stream.end,
            "Stream is not active"
        );
        stream.paused = true;
        stream.start = uint128(block.timestamp);
        emit Pause(user, streamId);
    }

    /**
     * @notice allow stream creator resume it
     */
    function resume(address user, uint128 streamId)
        external
        exist(userToIds[user].streamId, streamId)
    {
        require(
            userToStreams[user][streamId].creator == msg.sender,
            "Only creator"
        );
        require(userToStreams[user][streamId].paused, "Not paused");
        _resume(
            user,
            streamId,
            uint128(block.timestamp) - userToStreams[user][streamId].start
        );
    }

    /**
     * @notice allow stream creator cancel it
     */
    function cancelStream(address user, uint128 streamId)
        external
        nonReentrant
        exist(userToIds[user].streamId, streamId)
    {
        Stream memory stream = userToStreams[user][streamId];
        require(
            userToStreams[user][streamId].creator == msg.sender,
            "Only creator"
        );
        require(
            stream.end > block.timestamp || stream.paused,
            "Stream is over"
        );
        (uint256 amount, uint128 numSteps) = pendingStream(user, streamId);
        delete userToStreams[user][streamId];
        int256 deferredId;
        if (amount > 0) {
            stream.lastClaimed += stream.step * numSteps;
            deferredId = int256(uint256(userToIds[user].deferredId));
            userToDeferred[user][userToIds[user].deferredId++] = Deferred(
                msg.sender,
                stream.token,
                amount,
                block.timestamp
            );
        }
        amount =
            stream.amount *
            ((stream.end - stream.lastClaimed) / stream.step);
        _sendTokens(stream.token, msg.sender, amount);
        emit CancelStream(user, streamId, deferredId);
    }

    /**
     * @notice allow deferred transfer creator cancel it
     */
    function cancelDeferred(address user, uint128 deferredId)
        external
        nonReentrant
        exist(userToIds[user].deferredId, deferredId)
    {
        Deferred memory deferred = userToDeferred[user][deferredId];
        require(deferred.creator == msg.sender, "Only creator");
        require(deferred.unlockTime > block.timestamp, "Deferred is over");
        delete userToDeferred[user][deferredId];
        _sendTokens(deferred.token, msg.sender, deferred.amount);
        emit CancelDeferred(user, deferredId);
    }

    /**
     * @notice owner can send tokens from stream or deferred transfer
     * if user don't claim it for Limit time
     * @param user address of user
     * @param id id of stream or deferred transfer of this user
     * @param stream = true if resolve stream, = false if deferred
     * @param recipient send all tokens to him
     */
    function resolve(
        address user,
        uint128 id,
        bool stream,
        address recipient
    )
        external
        onlyOwner
        nonReentrant
        exist(
            stream ? userToIds[user].streamId : userToIds[user].deferredId,
            id
        )
    {
        require(recipient != address(0), "Zero address");
        uint256 amount;
        address token;
        if (stream) {
            require(
                userToStreams[user][id].end + limit < block.timestamp,
                "Come back later"
            );
            require(userToStreams[user][id].amount > 0, "Nothing to withdraw");
            token = userToStreams[user][id].token;
            (amount, ) = pendingStream(user, id);
            delete userToStreams[user][id];
        } else {
            require(
                userToDeferred[user][id].unlockTime + limit < block.timestamp,
                "Come back later"
            );
            amount = userToDeferred[user][id].amount;
            require(amount > 0, "Already claimed");
            token = userToDeferred[user][id].token;
            delete userToDeferred[user][id];
        }
        _sendTokens(token, recipient, amount);
        emit Resolve(user, id, stream);
    }

    /**
     * @notice owner can setup utils contract address only once
     */
    function initiate(address _utils) external onlyOwner {
        require(_utils != address(0), "Zero address");
        require(utils == address(0), "Already initiated");
        utils = _utils;
    }

    function setLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Zero limit");
        limit = newLimit;
    }

    function changeTokenStatus(address token) external onlyOwner {
        require(token != address(0), "Zero token address");
        tokens[token] = (tokens[token] + 1) % 2;
    }

    /**
     * @notice return unlocked amount for certain user's stream
     */
    function pendingStream(address user, uint128 streamId)
        public
        view
        returns (uint256 amount, uint128 numSteps)
    {
        Stream memory stream = userToStreams[user][streamId];
        if (
            stream.start > block.timestamp ||
            stream.lastClaimed + stream.step > block.timestamp
        ) {
            return (0, 0);
        }
        numSteps = _getNumSteps(
            stream.lastClaimed,
            stream.paused ? stream.start : block.timestamp >= stream.end
                ? stream.end
                : uint128(block.timestamp),
            stream.step
        );
        amount = stream.amount * numSteps;
    }

    function getStreams(address user, uint128[] calldata ids)
        external
        view
        returns (Stream[] memory)
    {
        Stream[] memory streams = new Stream[](ids.length);
        for (uint256 i = ids.length - 1; ; --i) {
            streams[i] = userToStreams[user][ids[i]];
            if (i == 0) {
                break;
            }
        }
        return streams;
    }

    function getDeferreds(address user, uint128[] calldata ids)
        external
        view
        returns (Deferred[] memory)
    {
        Deferred[] memory deferreds = new Deferred[](ids.length);
        for (uint256 i = ids.length - 1; ; --i) {
            deferreds[i] = userToDeferred[user][ids[i]];
            if (i == 0) {
                break;
            }
        }
        return deferreds;
    }

    function _multisendNative(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) internal {
        uint256 sendedAmount;
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            sendedAmount += amounts[i];
            TransferHelper.safeTransferETH(accounts[i], amounts[i]);
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
    }

    function _multisendToken(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) internal {
        uint256 sendedAmount;
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            sendedAmount += amounts[i];
            TransferHelper.safeTransfer(token, accounts[i], amounts[i]);
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
    }

    function _multistream(
        address creator,
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint128[3] memory params,
        uint256 totalAmount
    ) internal {
        uint256 sendedAmount;
        uint128 end = params[0] + params[1] * params[2];
        uint256[] memory _amounts = new uint256[](accounts.length);
        uint128[] memory ids = new uint128[](accounts.length);
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            _amounts[i] = amounts[i] * params[1];
            sendedAmount += _amounts[i];
            ids[i] = userToIds[accounts[i]].streamId++;
            userToStreams[accounts[i]][ids[i]] = Stream(
                creator,
                token,
                false,
                amounts[i],
                params[0],
                end,
                params[2],
                params[0]
            );
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
        emit Multistream(creator, token, params[0], accounts, ids, _amounts);
    }

    function _deferredTransfer(
        address creator,
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 unlockTimestamp,
        uint256 totalAmount
    ) internal {
        uint256 sendedAmount;
        uint128[] memory ids = new uint128[](accounts.length);
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            sendedAmount += amounts[i];
            ids[i] = userToIds[accounts[i]].deferredId++;
            userToDeferred[accounts[i]][ids[i]] = Deferred(
                creator,
                token,
                amounts[i],
                unlockTimestamp
            );
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
        emit DeferredTransfer(creator, token, accounts, ids, amounts);
    }

    function _collectTokens(address token, uint256 totalAmount) internal {
        require(tokens[token] == 1, "Unsupported token");
        if (token == NATIVE) {
            require(msg.value == totalAmount, "Wrong amount sended");
        } else {
            require(msg.value == 0, "Native sended");
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                totalAmount
            );
        }
    }

    function _sendTokens(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == NATIVE) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    function _resume(
        address user,
        uint128 streamId,
        uint128 pausedTime
    ) internal {
        Stream storage stream = userToStreams[user][streamId];
        stream.paused = false;
        stream.lastClaimed += pausedTime;
        stream.end += pausedTime;
        emit Resume(user, streamId);
    }

    function _getNumSteps(
        uint128 from,
        uint128 to,
        uint128 step
    ) internal pure returns (uint128) {
        return (to - from) / step;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}