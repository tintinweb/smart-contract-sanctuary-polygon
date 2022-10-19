/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error  Does_Not_Record_Your_Masturbation_Count();

contract masturbationCount{

    address owner ;
    uint times;
    uint dateOfStartOfCountDown;

    constructor(){
        owner = msg.sender;
        times = 0;
        dateOfStartOfCountDown = block.timestamp;
    }

     modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Does_Not_Record_Your_Masturbation_Count();
        }
        _;
    }

    function increment()external onlyOwner{
        times++;
    }

    function getTimes()external  view  returns(uint){
        return times;
    }
    
    function getCountdownStartDate()external  view  returns(uint){
        return dateOfStartOfCountDown;
    }
}