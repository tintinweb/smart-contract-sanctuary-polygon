/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.8.20;

contract Bar {
    function bar() public pure returns (string memory) {
        return "Bar";
    }
}

contract Foo is Bar {
    function foo() public pure returns (string memory) {
        return "Foo";
    }
}