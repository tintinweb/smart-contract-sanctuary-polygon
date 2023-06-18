// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Retreive {
    uint[] public unlockTime;

    constructor()  { 
        unlockTime.push(block.timestamp);
         unlockTime.push(block.timestamp+1);
         //  unlockTime[0]=  block.timestamp ;
          //  unlockTime[1]=  block.timestamp+1 ;
          //  unlockTime[2]=  block.timestamp+2 ;
    }

    function callIt() external view returns(uint[] memory myDynamicArray ){
        myDynamicArray = new uint[](2);
        myDynamicArray[0] = unlockTime[0];
       myDynamicArray[1] = unlockTime[1];
    }

}