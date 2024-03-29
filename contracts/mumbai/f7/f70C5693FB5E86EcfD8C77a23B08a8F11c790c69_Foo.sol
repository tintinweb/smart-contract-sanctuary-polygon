/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

// File: ./Bar.sol

pragma solidity ^0.8.0;

contract Bar {
    function bar() public pure returns (string memory) {
        return "Bar2";
    }
}

// File: Foo.sol

pragma solidity >=0.8.0 <0.8.20;


contract Foo is Bar {

    uint256 public value;

    // constructor with single uint256 parameter
    constructor(uint256 _value) {
        value = _value;
    }

    function foo() public pure returns (string memory) {
        return "Foo";
    }
}