/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {
    address owner = msg.sender;

    // Injecting money 
    function send() external payable {
    }

    //sending 0.01 eth to the EOA call
    function sendLimit() external {
        address payable to = payable(msg.sender);
        uint amount = (0.01 ether);
        to.transfer(amount);
    }

    //sending half balance
    function sendHalf() external {
        address payable to = payable(msg.sender);
        uint amount = getBalance() / 2;
        to.transfer(amount);
    }

    //withdraw entier balance 
    function withdrawAllBalance() external {       
        address payable to = payable(msg.sender);
        uint amount = getBalance();  
        require (to == owner, "no estas autorizado");  
        to.transfer(amount);
    }

    // balance total from SC
    function getBalance() public view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}