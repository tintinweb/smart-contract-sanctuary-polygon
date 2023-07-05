//SPDX-License-Identifier: UNLICENSED 

pragma solidity ^0.8.9;

contract MyCounter {  
    uint256 private counter = 0;

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function incrementCounter() public {
        counter++;
    }
    
     function decrementCounter() public {
        counter--;
    }
}