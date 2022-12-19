// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;



//import "hardhat/console.sol";

contract Mock {
    uint256 public counter;

    function increase(uint256 increment) external {
        counter += increment;
    }
    
}