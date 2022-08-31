// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract Eumlet is ReentrancyGuard {
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => Stream[]) public userToStreams;
    mapping(address => uint256) private tokens;

    struct Stream {
        address token;
        uint128 amount;
        uint128 claimed;
        uint128 start;
        uint128 duration;
    }

    modifier lengths(uint256 len1, uint256 len2) {
        require(len1 == len2, "Lengths not equal");
        _;
    }

    event Multisend(address from, uint256 totalAmount);
    event Multistream(address from, uint256 totalAmount);
    event Withdraw(address user, uint256 claimedAmont);

    constructor(address[2] memory _tokens) {
        require(
            _tokens[0] != address(0) && _tokens[1] != address(0),
            "Zero address"
        );
        tokens[_tokens[0]] = 1;
        tokens[_tokens[1]] = 1;
    }

    function multisend(
        address token,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external payable nonReentrant lengths(accounts.length, amounts.length) {
        if (token == NATIVE) {
            _multisendNative(accounts, amounts, totalAmount);
        } else {
            _multisendToken(token, accounts, amounts, totalAmount);
        }
        emit Multisend(msg.sender, totalAmount);
    }

    function multistream(
        address token,
        address[] calldata accounts,
        uint128[] calldata amounts,
        uint128 start,
        uint128 duration,
        uint256 totalAmount
    ) external payable nonReentrant lengths(accounts.length, amounts.length) {
        require(start >= block.timestamp && duration > 0, "Wrong params");
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
        uint256 sendedAmount;
        for (uint256 i = accounts.length - 1; ; --i) {
            require(amounts[i] > 0, "Zero amount");
            sendedAmount += amounts[i];
            userToStreams[accounts[i]].push(
                Stream(token, amounts[i], 0, start, duration)
            );
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
        emit Multistream(msg.sender, totalAmount);
    }

    function withdraw(uint256 streamId) external nonReentrant {
        uint256 length = userToStreams[msg.sender].length;
        require(length > 0 && streamId < length, "Wrong stream id");
        Stream memory stream = userToStreams[msg.sender][streamId];
        require(stream.start < block.timestamp, "Stream not start");
        uint128 amount;
        if (block.timestamp > stream.start + stream.duration) {
            amount = stream.amount - stream.claimed;
            --length;
            if (streamId < length) {
                userToStreams[msg.sender][streamId] = userToStreams[msg.sender][
                    length
                ];
            }
            userToStreams[msg.sender].pop();
        } else {
            amount =
                (stream.amount * (uint128(block.timestamp) - stream.start)) /
                stream.duration;
            userToStreams[msg.sender][streamId].claimed += amount;
        }
        require(amount > 0, "Nothing to withdraw");
        if (stream.token == NATIVE) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(stream.token, msg.sender, amount);
        }
        emit Withdraw(msg.sender, amount);
    }

    function getStreamsAmount(address user) external view returns (uint256) {
        return userToStreams[user].length;
    }

    function _multisendNative(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) internal {
        require(msg.value == totalAmount, "Wrong amount sended");
        uint256 sendedAmount;
        for (uint256 i = accounts.length - 1; ; --i) {
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
            sendedAmount += amounts[i];
            TransferHelper.safeTransfer(token, accounts[i], amounts[i]);
            if (i == 0) {
                break;
            }
        }
        require(totalAmount == sendedAmount, "Wrong total amount");
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