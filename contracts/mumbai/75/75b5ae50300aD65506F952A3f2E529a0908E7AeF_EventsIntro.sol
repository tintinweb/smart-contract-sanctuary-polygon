/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EventsIntro {
    mapping(address => uint) public accounts;
    // Here you define the event with the parameters you want to pass
    event Registered(address Sender, uint Amount);

    function addAccount() public payable returns(bool) {
        require(msg.value > 0);
        accounts[msg.sender] = msg.value;
        // Here we call our event if the transation is successful 
        // emit EventName(params);
        emit Registered(msg.sender, msg.value);
        return true;
    }
}