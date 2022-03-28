// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Greeter {
    function greet(string memory name) public pure returns(string memory ) {
        return string(abi.encodePacked("hello ", name));
    }
}