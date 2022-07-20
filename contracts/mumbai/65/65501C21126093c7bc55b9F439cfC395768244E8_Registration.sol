/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/utils/Context.sol

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


// File contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;
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


// File contracts/AdvertiserRegistration.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract Registration is Ownable {
    struct Register {
        uint256 advertiserID;
        string name;
        string category;
    }

    mapping(address => Register) public registered;

    uint256 uniqueID = 1;

    error RegisteredAlready(address user , string message);

    error InvalidUser(address user, string message);

    event Registered(address advertiser, string name, string category);

    function advertiserRegister(address advertiser_, string memory name_, string memory category_)
        external onlyOwner
    {
        require(isNotRegistred(advertiser_));
        Register storage register = registered[advertiser_];
        register.advertiserID = uniqueID;
        register.name = name_;
        register.category = category_;
        uniqueID++;
        emit Registered(advertiser_, name_, category_);
    }

    function isNotRegistred(address user_) public view returns (bool) {
        if (registered[user_].advertiserID == 0)
            return true;
        else
            revert RegisteredAlready(user_, "User already registred"); 
    }

    function isValidAdvertiser(address user_) public view returns (bool) {
        if (registered[user_].advertiserID != 0)
            return true;
        else
            revert InvalidUser(user_, "New User / User not registered"); 
    }
}