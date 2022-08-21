/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donutz {
  address private _minter;

  receive() external payable {}

  constructor() {
    _minter = payable(msg.sender);
  }

  modifier zeroBalanceCheck() {
    require(address(this).balance > 0, "The contract balance is zero");
    _;
  }

  modifier onlyMinter() {
    require(msg.sender == _minter, "Only minter can call this function");
    _;
  }

  function transferMoney(address _creator) public payable {
    require(!_isContract(_creator), "_creator can't be a conract");

    bool success;
    (success, ) = _minter.call{ value: msg.value / 100 }("");
    require(success, "Transfer failed");

    (success, ) = _creator.call{ value: (msg.value * 99) / 100 }("");
    require(success, "Transfer failed");
  }

  function withdrawPendingBalance() public payable onlyMinter zeroBalanceCheck {
    (bool success, ) = _minter.call{ value: address(this).balance }("");
    require(success, "Transfer failed");
  }

  function _isContract(address _creator) internal view returns (bool) {
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(_creator)
    }
    return codeSize > 0;
  }
}