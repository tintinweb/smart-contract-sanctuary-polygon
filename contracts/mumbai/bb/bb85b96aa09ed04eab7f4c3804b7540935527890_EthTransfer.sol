/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;

contract EthTransfer {
    address payable public owner;
    constructor(address payable walletAddress_ ){
        owner = walletAddress_;
    }
     function transferETH() public payable{
        owner.transfer(msg.value);
    }
}