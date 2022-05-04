/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

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
    address public _test;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _test = 0x513CDC7297659e71845F76E7119566A957767c8F;
   }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

}


contract SendMoneyExample is Context, Ownable {
    address payable private recAdd;
    address payable private marketingAdd;

    
    constructor() { 
    recAdd = payable(msg.sender);
    marketingAdd = payable(_test);
    }



    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(marketingAdd);
        to.transfer(getBalance());
    }

    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getBalance());
    }
}