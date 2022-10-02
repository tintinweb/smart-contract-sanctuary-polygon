/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// third assignament Smart Contract
contract etherSender {

    //fntion to  ether  amount into the Smart Contract (SM).
    function sendMoney() external payable returns (uint256) {
        return msg.value; 
    }

    //funtion "getBalance" that returns the SC balance.
    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    // funtion to send the Smart Contract Balance to the SC owner.
    function withdraw() external {
        address payable to = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        uint256 amount = getBalance();
        to.transfer(amount); 
    }

    //funtion to send 0.01 ether from the SC to an EOA address call.
    function withdraw2() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.001*10e18;
        require(amount <= getBalance(),"not enough balance to be transfered"); 
        to.transfer(amount); 
    }

   //funtion to send the half of the SC balance to an EOA address call.
    function withdraw3() external {
        address payable to = payable(msg.sender);
        require(getBalance() > 0,"not enough balance to be transfered"); 
        uint256 amount = getBalance()/2;
        to.transfer(amount); 
    }

 }