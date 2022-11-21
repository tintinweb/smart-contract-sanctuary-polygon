// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HelloWorldWithArg {
    string private _name;

    constructor(string memory name_) {
        _name = name_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function helloWorld(string memory message)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("Hello world.  ", message));
    }
}