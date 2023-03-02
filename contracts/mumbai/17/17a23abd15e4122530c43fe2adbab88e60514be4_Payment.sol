/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Payment {

    address public reciever;
    address public owner = msg.sender;
    
    constructor(address _reciever) {
        reciever = _reciever;
    }

    function sendPayment(uint _amount) public payable {
        payable(reciever).transfer(_amount);
    }

}