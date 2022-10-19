// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract BackendPlayground {
    string public name;
    uint256 public number;
    address public sender;
    address[] public addressArray;
    bool public boolean;

    struct FunctionParams {
        string name;
        uint256 number;
        address sender;
        address[] addressArray;
        bool boolean;
    }

    function setParams(FunctionParams memory params) public {
        name = params.name;
        number = params.number;
        sender = params.sender;
        addressArray = params.addressArray;
        boolean = params.boolean;
    }
}