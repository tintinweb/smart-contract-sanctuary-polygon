/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// File: contracts/problem10.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract Problem10 {

    address private _owner;

    string private _name;

    constructor() {
        _owner = msg.sender;
        _name = "Julia Butenko";
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function sum(uint8 x, uint8 y) external pure returns (bool, uint8) {
        uint _sum = uint(x) + uint(y);
        uint8 _max = type(uint8).max;

        if (_sum <= _max) {
            return (true, uint8(_sum));
        }
        else {
            return (false, 0);
        }
    }
    
}