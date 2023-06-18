/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Lazymint {



    constructor(){
    }

    function transferAmount( address creator) external payable {
        require(msg.value <= 0 , "Insufficient Balance for transfer!");
        payable(creator).transfer(msg.value);
        
    }

 

}