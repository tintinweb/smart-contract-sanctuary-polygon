/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

contract TransETH{

    function transferBatch(address[] memory receivers,uint perValue) public payable {
        require(msg.value >= receivers.length * perValue,"value is not enough");
        uint balance = msg.value - receivers.length * perValue;
    
        for (uint i = 0 ; i< receivers.length;i++){
            payable(receivers[i]).transfer(perValue);
        }
        if(balance >= 10**9){
            payable(msg.sender).transfer(balance);
        }
    } 
}