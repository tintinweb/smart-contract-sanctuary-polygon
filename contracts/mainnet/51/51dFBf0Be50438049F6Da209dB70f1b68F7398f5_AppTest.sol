//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract AppTest {
    // have a public function that takes in a integer and emits an event with that integer

    event TestEvent(uint256 testNumber);

    function test(uint256 _num) public {
        emit TestEvent(_num);
    }

    uint256 public myValu = 2;

    function test2(uint256 newValue) public returns (uint256) {
        return myValu = newValue;
    }

    function getMyalue() public view returns (uint256) {
        return myValu;
    }

    function get2() public pure returns (uint256) {
        return 2;
    }
}