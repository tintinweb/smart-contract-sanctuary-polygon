// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BoxJoe {
    uint256 private value;

    string public _name;
    string public _symbol;
    address public _owner;

 event ValueChanged (uint256 value);
    function store (uint256 _value) public  {
        value = _value;
        emit ValueChanged (value);
    }

    function initialize(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }

    function retrieve () public view returns (uint256) {
        return value;
    }
    function boxVersion() external pure returns (uint256) {
       return 1;
    }
}