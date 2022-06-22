// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Counter {
  uint256 count0 = 0;
  uint256 count1 = 0;

  function increment0() public {
    count0++;
  }
  function increment1() public {
    count1 = count0 + count1;
  }

  function getCount0() external view returns(uint256) {
    return count0;
  }
  function getCount1() external view returns(uint256) {
    return count1;
  }
  function getTotalCount() external view returns(uint256) {
    return count0 + count1;
  }

}