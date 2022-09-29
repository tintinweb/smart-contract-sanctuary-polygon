// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";

contract Eumlet is Ownable, ReentrancyGuard {
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public limit;
    mapping(address => mapping(uint128 => Stream)) public userToStreams;
    mapping(address => mapping(uint128 => Deferred)) public userToDeferred;
    mapping(address => Deferred[]) public userPart; // pop
    mapping(address => Deferred[]) public creatorPart; // pop
    mapping(address => mapping(uint256 => uint256)) public argued;
    // list of supported tokens, uint256 = bool
    mapping(address => uint256) private tokens;
    mapping(address => Ids) private userToIds;

    struct Ids {
        uint128 streamId;
        uint128 deferredId;
    }

    struct Stream {
        address creator;
        address token;
        bool paused;
        uint256 amount; // add base?
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
    event Withdraw(address user, uint256 id, uint256 amount);
    event Claim(address user, uint256 id);
    event Pause(address user, uint256 id);
    event Resume(address user, uint256 id);
    event CancelStream(address user, uint256 id);
    event CancelDeferred(address user, uint256 id);

    modifier eqLengths(uint256 len1, uint256 len2) {
        require(len1 == len2, "Lengths not equal");
        _;
    }

    modifier exist(uint128 nextId, uint128 id) {
        require(nextId > id, "Wrong id");
        _;
    }

    modifier existCanceled(uint256 len, uint256 id) {
        require(len > 0 && len > id, "Wrong Id");
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
        limit = _limit;
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
        if (token == NATIVE) {
            _multisendNative(accounts, amounts, totalAmount);
        } else {
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
     * @param params - [0] - start, [1] - , [2] - step in sec, [3] - totalAmount
     */
    function multistream(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint128[4] calldata params
    ) external payable nonReentrant eqLengths(accounts.length, amounts.length) {
        require(
            params[0] >= block.timestamp &&
                params[1] > 0 &&
                params[2] > 0 &&
                params[3] > 0,
            "Wrong params"
        );
        if (token == NATIVE) {
            require(msg.value == params[3], "Wrong amount sended");
        } else {
            require(tokens[token] == 1, "Unsupported token");
            require(msg.value == 0, "Native sended");
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                params[3]
            );
        }
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
                msg.sender,
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
        require(params[3] == sendedAmount, "Wrong total amount");
        emit Multistream(msg.sender, token, accounts, ids, _amounts);
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
        require(unlockTimestamp > block.timestamp, "Wrong unlock time");
        _collectTokens(token, totalAmount);
        uint256 sendedAmount;
        uint128[] memory ids = new uint128[](accounts.length);
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            sendedAmount += amounts[i];
            ids[i] = userToIds[accounts[i]].deferredId++;
            userToDeferred[accounts[i]][ids[i]] = Deferred(
                msg.sender,
                token,
                amounts[i],
                unlockTimestamp
            );
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
        emit DeferredTransfer(msg.sender, token, accounts, ids, amounts);
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
        require(!stream.paused, "Paused");
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
        stream.paused = true;
        (uint256 amount, uint128 numSteps) = pendingStream(user, streamId);
        if (amount > 0) {
            stream.lastClaimed += stream.step * numSteps;
            _sendTokens(stream.token, msg.sender, amount);
        }
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
        userToStreams[user][streamId].paused = false;
        emit Resume(user, streamId);
    }

    /**
     * @notice allow stream creator cancel it
     */
    function cancelStream(address user, uint128 streamId)
        external
        exist(userToIds[user].streamId, streamId)
    {
        Stream memory stream = userToStreams[user][streamId];
        require(
            userToStreams[user][streamId].creator == msg.sender,
            "Only creator"
        );
        (uint256 amount, uint128 numSteps) = pendingStream(user, streamId);
        delete userToStreams[user][streamId];
        if (amount > 0) {
            stream.lastClaimed += stream.step * numSteps;
            userPart[user].push(
                Deferred(msg.sender, stream.token, amount, block.timestamp)
            );
        }
        if (stream.lastClaimed < stream.end) {
            amount =
                stream.amount *
                ((stream.end - stream.lastClaimed) / stream.step);
            creatorPart[msg.sender].push(
                Deferred(user, stream.token, amount, block.timestamp)
            );
        }
        emit CancelStream(user, streamId);
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
        require(
            userToDeferred[user][deferredId].creator == msg.sender,
            "Only creator"
        );
        delete userToDeferred[user][deferredId];
        _sendTokens(deferred.token, msg.sender, deferred.amount);
        emit CancelDeferred(user, deferredId);
    }

    function claimCanceledUser(uint256 canceledId)
        external
        nonReentrant
        existCanceled(userPart[msg.sender].length, canceledId)
    {
        Deferred memory part = userPart[msg.sender][canceledId];
        require(part.amount > 0, "Already claimed");
        delete userPart[msg.sender][canceledId];
        _sendTokens(part.token, msg.sender, part.amount);
    }

    function claimCanceledCreator(uint256 canceledId)
        external
        nonReentrant
        existCanceled(creatorPart[msg.sender].length, canceledId)
    {
        require(argued[msg.sender][canceledId] == 0, "Argued");
        Deferred memory part = creatorPart[msg.sender][canceledId];
        require(part.amount > 0, "Already claimed");
        require(part.unlockTime + limit <= block.timestamp, "Come back later");
        delete creatorPart[msg.sender][canceledId];
        _sendTokens(part.token, msg.sender, part.amount);
    }

    function claimCanceledFromUser(address user, uint256 canceledId)
        external
        nonReentrant
        existCanceled(userPart[user].length, canceledId)
    {
        Deferred memory part = userPart[user][canceledId];
        require(msg.sender == part.creator, "Only creator");
        require(part.amount > 0, "Already claimed");
        require(part.unlockTime + limit <= block.timestamp, "Come back later");
        delete userPart[user][canceledId];
        _sendTokens(part.token, msg.sender, part.amount);
    }

    function argue(address creator, uint256 canceledId)
        external
        existCanceled(creatorPart[creator].length, canceledId)
    {
        require(
            creatorPart[creator][canceledId].creator == msg.sender,
            "Only recipient"
        );
        argued[creator][canceledId] = 1;
    }

    function resolve(
        address creator,
        uint256 canceledId,
        uint256 amountToCreator,
        uint256 amountToUser
    )
        external
        nonReentrant
        onlyOwner
        existCanceled(creatorPart[creator].length, canceledId)
    {
        require(argued[creator][canceledId] == 1, "Not argued");
        delete argued[creator][canceledId];
        require(
            creatorPart[creator][canceledId].amount ==
                amountToCreator + amountToUser,
            "Wrong amount"
        );
        if (amountToCreator > 0) {
            _sendTokens(
                creatorPart[creator][canceledId].token,
                creator,
                amountToCreator
            );
        }
        if (amountToUser > 0) {
            _sendTokens(
                creatorPart[creator][canceledId].token,
                creatorPart[creator][canceledId].creator,
                amountToUser
            );
        }
        delete creatorPart[creator][canceledId];
    }

    function setLimit(uint256 newLimin) external onlyOwner {
        limit = newLimin;
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
            stream.start >= block.timestamp ||
            stream.lastClaimed + stream.step > block.timestamp
        ) {
            return (0, 0);
        }
        numSteps = block.timestamp >= stream.end
            ? (stream.end - stream.lastClaimed) / stream.step
            : (uint128(block.timestamp) - stream.lastClaimed) / stream.step;
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

    function _multisendNative(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) internal {
        require(msg.value == totalAmount, "Wrong amount sended");
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
        require(tokens[token] == 1, "Unsupported token");
        require(msg.value == 0, "Native sended");
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            totalAmount
        );
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

    function _collectTokens(address token, uint256 totalAmount) internal {
        if (token == NATIVE) {
            require(msg.value == totalAmount, "Wrong amount sended");
        } else {
            require(tokens[token] == 1, "Unsupported token");
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