// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./two.sol";
contract TestOne is TestTwo {
    function testOne() public pure returns (uint256) {
        return testfunc() +1;
    }
}