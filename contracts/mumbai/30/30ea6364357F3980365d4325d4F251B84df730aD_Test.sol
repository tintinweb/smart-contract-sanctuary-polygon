/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Test {
    event Event1();
    event Event2();
    event Event3(uint256 divider);

    function foo(uint256 amount) public {
        emit Event1();
        emit Event2();
        emit Event3(5/amount);

    }

}