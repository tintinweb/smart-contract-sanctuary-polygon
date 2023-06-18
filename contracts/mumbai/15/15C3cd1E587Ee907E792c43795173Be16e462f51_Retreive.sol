// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Retreive {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor()  { 
           unlockTime=  block.timestamp ;
    }

    function callIt(uint increment) external returns(uint[] memory val){
        val[0]=unlockTime;
        val[1]=unlockTime+increment;
        unlockTime=  block.timestamp ;
    }

}