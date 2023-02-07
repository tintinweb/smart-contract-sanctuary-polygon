// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Proxy{
    address public implementation;
    address public immutable owner;


    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    function upgradeTo(address _implementation) public onlyOwner {
        implementation = _implementation;
    }

    function execute(bytes memory _data) public {
        (bool success,) = address(implementation).delegatecall(_data);
        require(success);
    }
}