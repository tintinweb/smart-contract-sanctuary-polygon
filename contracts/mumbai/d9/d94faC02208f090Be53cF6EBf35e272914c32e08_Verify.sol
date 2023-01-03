// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Verify {

    string private greeting;

    constructor() {}

    function hello(bool isHello) public pure returns(string memory) {
        if(isHello) {
            return "Hello!";
        }
        return "";
     }

}