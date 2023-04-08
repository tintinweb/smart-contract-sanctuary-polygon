/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
      return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor() {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require( _owner == _msgSender());
      _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
      emit OwnershipTransferred(_owner, account);
      _owner = account;
    }
}

contract PolycashV1Address is Context, Ownable {

    address[] public storageAddress;

    constructor() {}

    function applyAddress(address[] memory input) public onlyOwner returns (bool) {
      storageAddress = input;
      return true;
    }

    function viewAddress() public view returns (address[] memory) {
      return storageAddress;
    }

}