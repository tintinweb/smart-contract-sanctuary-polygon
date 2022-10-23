/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

interface IAdmin {

    //check the address is the implement of the IAdmin contract
    function ping() external view returns (address);

    function isAdmin(address account)
    view
    external
    returns (bool);

    function getAllAdmins()
    view
    external
    returns (address[] memory);
}

library AddrSet {

    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    function insert(Set storage self, address key) internal {
        require(key != address(0), "Key can not be 0x0");
        require(!exists(self, key), "Key already exist");
        self.keyList.push(key);
        self.keyPointers[key] = count(self)-1;
    }

    function remove(Set storage self, address key) internal {
        require(exists(self, key), "Key not exist");
        address keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) internal {
        delete self.keyList;
    }
}

/** ****************************************************************************
 * @title Admin
 * *****************************************************************************
 * @notice * Stores the address of the account specified by the owner as the administrator
 */
contract Admin is IAdmin, Ownable {
    using AddrSet for AddrSet.Set;

    // the set of all the admins' addresses
    AddrSet.Set admins;

    // Throws if caller is not in the admins' set
    modifier onlyAdmin() {
        require(admins.exists(msg.sender), "msg sender is not in admins");
        _;
    }

    /**
     * @dev set the caller to be the owner of this contract, and also to be the firt admin
     */
    constructor() Ownable() {
        admins.insert(msg.sender);
    }

    function ping() public view virtual override returns (address) {return address(this);}

    /**
     * @dev Insert a new admin address, throws if caller is not admin
     * @param accounts: accounts' addresses need to be set as admin
     */
    function insertAdmin(address[] memory accounts)
    onlyAdmin
//    virtual
//    override
    public {
        for(uint i = 0; i < accounts.length; i++) {
            if (!admins.exists(accounts[i])) {
                admins.insert(accounts[i]);
            }
        }
    }

    /**
     * @dev Remove a admin address that already in the admins, throws if caller is not admin
     * @param accounts: accounts' addresses need to be set as admin
     */
    function removeAdmin(address[] memory accounts)
    onlyAdmin
//    virtual
//    override
    public {
        require(accounts.length < admins.count(), "need at least one admin");
        for(uint i = 0; i < accounts.length; i++) {
            if (admins.exists(accounts[i])) {
                admins.remove(accounts[i]);
            }
        }
    }

    /**
     * @dev Check whether the given user's address is recorded in the admins.
     * @param account: user address
     * @return bool: return true if user is admin
     */
    function isAdmin(address account)
    virtual
    override
    view
    public
    returns (bool) {
        return admins.exists(account);
    }

    /**
     * @dev Get all admins' addresses
     * @return address[]: admins' addresses
     */
    function getAllAdmins()
    virtual
    override
    view
    public
    returns (address[] memory) {
        return admins.keyList;
    }

}