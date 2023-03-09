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

}

contract Test1Facet {
    event TestEvent(address something);

   function test1Func1() external {
      TestLib.setMyAddress(address(this));
    }

    function test1Func2() external view returns (address){
      return TestLib.getMyAddress();
    } 

   function test1Func3(uint256 _num) external {
      TestLib.setMyNumber(_num);
    }

    function test1Func4() external view returns (uint256){
      return TestLib.getMyNumber();
    }

    function test1Func5(uint256 idx, uint256 _num) external {
      TestLib.setNumberMap(idx, _num);
    }


    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}