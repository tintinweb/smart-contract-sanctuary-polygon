/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract V1 {
    function pay(uint256 amount, address payable[] memory receivers) public payable {
        for(uint256 i = 0; i< receivers.length; i++){
            receivers[i].transfer(amount);
        }
    }
}