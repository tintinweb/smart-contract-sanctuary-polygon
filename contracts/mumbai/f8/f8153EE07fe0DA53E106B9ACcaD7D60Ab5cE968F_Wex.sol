// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wex is Ownable {
    uint256 private _feePercentage = 0;
    uint256 private _serviceFee = 0;
    uint256 private _poolSize = 0;

    event DepositedEx(string receiverId, uint256 amount);
    event WithdrewEx(address receiver, uint256 amount, string transactionId);

    function depositEx(string calldata receiverId) external payable {
        require(msg.value > 0, "Deposit can not be zero");

        _poolSize += msg.value;
        emit DepositedEx(receiverId, msg.value);
    }

    function withdrawEx(
        address receiver,
        uint256 amount,
        string calldata transactionId
    ) external onlyOwner {
        require(amount > 0, "Amount can'tt be zero");
        require(amount <= _poolSize, "Amount can't be greater than pool size");
        // Insert fee calculation
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Transfer failed.");

        _poolSize -= amount;
        emit WithdrewEx(receiver, amount, transactionId);
    }

    function setFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Fee is invalid");
        _feePercentage = _newFee;
    }

    function feePercentage() external view onlyOwner returns (uint256) {
        return _feePercentage;
    }

    function serviceFee() external view onlyOwner returns (uint256) {
        return _serviceFee;
    }

    function poolSize() external view onlyOwner returns (uint256) {
        return _poolSize;
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