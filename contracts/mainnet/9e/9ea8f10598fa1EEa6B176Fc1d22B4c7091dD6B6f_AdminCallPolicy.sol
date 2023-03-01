// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFirewallPolicy.sol";

/**
 * @dev This contract is a policy which requires a third party to approve any admin calls.
 *
 * This policy is useful for contracts that have sensitive admin functions that need to be called frequently, and you
 * don't necessarily want to use a multisig wallet to call them (although this can also be used on top of a multisig
 * for even better security). You can use this policy to allow a third party to approve the call after off-chain
 * authentication verifying that the owner of the contract is the one making the call.
 *
 */
contract AdminCallPolicy is IFirewallPolicy, Ownable {

    // The default amount of time a call hash is valid for after it is approved.
    uint public expirationTime = 1 days;
    // The timestamp that a call hash was approved at (if approved at all).
    mapping (bytes32 => uint) public adminCallHashApprovalTimestamp;

    function preExecution(address consumer, address sender, bytes calldata data, uint value) external override {
        bytes32 callHash = getCallHash(consumer, sender, tx.origin, data, value);
        require(adminCallHashApprovalTimestamp[callHash] > 0, "AdminCallPolicy: Call not approved");
        require(adminCallHashApprovalTimestamp[callHash] + expirationTime > block.timestamp, "AdminCallPolicy: Call expired");
        adminCallHashApprovalTimestamp[callHash] = 0;
    }

    function postExecution(address, address, bytes calldata, uint) external override {
    }

    function setExpirationTime(uint _expirationTime) external onlyOwner {
        expirationTime = _expirationTime;
    }

    function approveCall(bytes32 _callHash) external onlyOwner {
        adminCallHashApprovalTimestamp[_callHash] = block.timestamp;
    }

    function getCallHash(
        address consumer,
        address sender,
        address origin,
        bytes memory data,
        uint value
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(consumer, sender, origin, data, value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFirewallPolicy {
    function preExecution(address consumer, address sender, bytes memory data, uint value) external;
    function postExecution(address consumer, address sender, bytes memory data, uint value) external;
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