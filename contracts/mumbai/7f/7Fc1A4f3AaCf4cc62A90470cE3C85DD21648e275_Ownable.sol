/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    uint256 public totalOwners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        totalOwners++;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() virtual {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

  
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        totalOwners++;
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }
}