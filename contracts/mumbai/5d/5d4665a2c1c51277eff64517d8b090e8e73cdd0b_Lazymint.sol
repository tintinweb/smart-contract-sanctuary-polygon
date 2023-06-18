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
        payable(creator).transfer(msg.value);
        
    }

 

}