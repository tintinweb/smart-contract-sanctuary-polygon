/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity >=0.7.0 <0.9.0;
contract KeyforMe  {
 uint256 private key;
 address private _owner;
  function owner() public view virtual returns (address) {
        return _owner;
    }
   modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }


  function getkey() public view returns (uint) {
     return  key;
    }
    function setkey(uint256 _key) public onlyOwner {
   key = _key;
  }
  }