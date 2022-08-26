// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TestEventPrecedence {
    event Event1(uint256 id, uint256 func, uint256 when);
    event Event2(uint256 id, uint256 func, uint256 when);

    uint256 public id;

    function function1() public {
        function2();
        emit Event1(id, uint256(1), block.timestamp);
    }

    function function2() public {
        emit Event2(id, uint256(2), block.timestamp);
    }

    function batchExecute(uint256 count) external {
        for (uint256 i; i < count; i++) {
            function1();
        }
    }
}