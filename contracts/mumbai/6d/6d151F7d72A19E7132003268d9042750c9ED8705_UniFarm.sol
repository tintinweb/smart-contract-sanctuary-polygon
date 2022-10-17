/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UniFarm {

  mapping(address => uint256) addressToValue;
  address[] totalAddress;
  uint256 total = 0;

  event ValueAdded(uint256 value, uint256 totalValue, uint256 totalAddress, uint256 addressValue);

  function addValue(uint256 value) external {
    require(value != 0, "Value can't be zero");
    total += value;
    if(addressToValue[msg.sender] == 0) {
      totalAddress.push(msg.sender);
    }
    addressToValue[msg.sender] += value;
    emit ValueAdded(value, total, totalAddress.length, addressToValue[msg.sender]);
  }

  function getTotalValue() external view returns(uint256) {
    return total;
  }

  function getTotalAddress() external view returns(uint256) {
    return totalAddress.length;
  }

  function getAddressValue(address _address) external view returns(uint256) {
    return addressToValue[_address];
  }

}