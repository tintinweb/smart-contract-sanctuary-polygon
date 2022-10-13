// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract WooTemplate {
    uint256 number;
    function store(uint256 num) public {
        number = num+1;
    }
    function retrieve() public view returns (uint256){
        return number;
    }
}