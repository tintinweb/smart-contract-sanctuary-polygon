/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

//SPDX-License-Identifier: MIT
// File: ERC20/Context.sol


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

// File: ERC20/Ownable.sol


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
contract OwnableContract is Context {
    address private _owner;
    mapping (address => bool) private _whitelistedAdmin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed addedBy, address indexed newAdmin);
    event AdminRemoved(address indexed removedBy, address indexed admin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _whitelistedAdmin[_msgSender()] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(address _address) {
        require(owner() == _address, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the whitelistedAdmin.
     */
    modifier onlyWhitelistedAdmin(address _address){
        require(_whitelistedAdmin[_address], "Ownable: caller is not the whitelisted admin");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Add new Admin to _whitelistedAdmin mapping.
     * Can only be called by the current owner and existing admin.
     */
    function addWhitelistedAdmin(address _whitelistAdmin)external onlyWhitelistedAdmin(msg.sender) returns(bool){
        require(!_whitelistedAdmin[_whitelistAdmin], "Ownable: already a whitelisted admin");
        _whitelistedAdmin[_whitelistAdmin] = true;
        emit AdminAdded(msg.sender, _whitelistAdmin);
        return true;
    }

    /**
     * @dev Remove existing Admin from _whitelistedAdmin mapping.
     * Can only be called by the current owner and existing admin.
     * Existing admin will not able to remove him/her self form _whitelistedAdmin mapping.
     */
    function removeWhitelistedAdmin(address _whitelistAdmin)external onlyWhitelistedAdmin(msg.sender) returns(bool){
        require(_whitelistedAdmin[_whitelistAdmin], "Ownable: not a whitelisted admin");
        require(_whitelistAdmin != msg.sender, "Ownable: self-remove not allowed");
        _whitelistedAdmin[_whitelistAdmin] = false;
        emit AdminRemoved(msg.sender, _whitelistAdmin);
        return true;
    }


    /**
     * @dev Return `true` if the sender is the whitelistedAdmin else `revert`.
     * 
     * Requirements:
     *
     * - `_address` that you need to check whether it is a whitelistedAdmin or not.
     */
    function checkAdmin(address _address) external view onlyWhitelistedAdmin(_address) returns(bool){
        return true;
    }

    /**
     * @dev Return `true` if the sender is the owner else `revert`.
     * 
     * Requirements:
     *
     * - `_address` that you need to check whether it is a owner or not.
     */
    function checkOwner(address _address) external view onlyOwner(_address) returns(bool){
        return true;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner(msg.sender) {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner(msg.sender) {
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