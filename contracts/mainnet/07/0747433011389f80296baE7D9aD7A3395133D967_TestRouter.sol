// SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/// Interface Imports
import {ISocketsRegistry} from "./Interface/ISocketsRegistry.sol";
import {UserRequest} from "./types.sol";

/// @title Test Router
contract TestRouter is Ownable {
    /// @dev represents the address of sockets.tech implementation.
    ISocketsRegistry public socketsRegistry;

    /// @param socketsRegistryAddress represents the address of sockets registry.
    function setRegistry(address socketsRegistryAddress) external onlyOwner {
        socketsRegistry = ISocketsRegistry(socketsRegistryAddress);
    }

    function outBoundTransfer(UserRequest[] calldata userRequests)
        external
        virtual
    {
        for (uint256 i = 0; i < userRequests.length; i++) {
            socketsRegistry.outboundTransferTo(userRequests[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

// Type imports
import {UserRequest} from "../types.sol";

/// @title Sockets Router
interface ISocketsRegistry {
    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.13;

struct BridgeRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct MiddlewareRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct UserRequest {
    address receiverAddress;
    uint256 toChainId;
    uint256 amount;
    MiddlewareRequest middlewareRequest;
    BridgeRequest bridgeRequest;
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