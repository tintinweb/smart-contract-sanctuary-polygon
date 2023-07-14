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

    string public greeting;
    string public goodbye;
    uint256 public value;

    // constructor with single uint256 parameter
    constructor(uint256 _value, string memory greeting, string memory _goodbye) {
        value = _value;
        greeting = greeting;
        goodbye = _goodbye;
    }

    function foo() public pure returns (string memory) {
        return "Foo";
    }
}