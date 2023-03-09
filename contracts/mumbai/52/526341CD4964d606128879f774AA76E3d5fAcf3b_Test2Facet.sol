/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Example library to show a simple example of diamond storage

library TestLib {

  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.test.storage");
  
  struct TestState {
      address myAddress;
      uint256 myNum;
      mapping(uint256 => uint256) numbers;
  }

  function diamondStorage() internal pure returns (TestState storage ds) {
      bytes32 position = DIAMOND_STORAGE_POSITION;
      assembly {
          ds.slot := position
      }
  }

  function setMyAddress(address _myAddress) internal {
    TestState storage testState = diamondStorage();
    testState.myAddress = _myAddress;
  }

  function getMyAddress() internal view returns (address) {
    TestState storage testState = diamondStorage();
    return testState.myAddress;
  }

  function setMyNumber(uint256 _num) internal {
        TestState storage testState = diamondStorage();
        testState.myNum = _num;
  }

  function getMyNumber() internal view returns (uint256) {
    TestState storage testState = diamondStorage();
    return testState.myNum;
  }

  function setNumberMap(uint256 idx, uint256 _num) internal {
      TestState storage testState = diamondStorage();
      testState.numbers[idx] = _num;
  }

  function addOne() internal {
        TestState storage testState = diamondStorage();
        testState.myNum++;
  }

}

contract Test2Facet {
    event TestEvent(address something);

   function test1Func1() external {
      TestLib.addOne();
    }



    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}