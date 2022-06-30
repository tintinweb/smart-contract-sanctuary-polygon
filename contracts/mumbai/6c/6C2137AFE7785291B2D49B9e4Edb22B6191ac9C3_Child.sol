/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/Child.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Child{
    uint public data;
    
    // use this function instead of the constructor
    // since creation will be done using createClone() function
    function init(uint _data) external {
        data = _data;
    }

}