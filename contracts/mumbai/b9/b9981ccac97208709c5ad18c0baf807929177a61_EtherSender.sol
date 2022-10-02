/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {
    address owner = msg.sender;

    // Injecting money 
    function send() external payable {
    }

    //sending 0.01 eth to the EOA call
    function sendLimit_0_01_Ethers() external {
        address payable to = payable(owner);
        require(getBalance() >= (0.01 ether),"insufficient money");
        uint amount = (0.01 ether);
        to.transfer(amount);
    }

    //sending half balance to the EOA call
    function sendHalfBalance() external {
        address payable to = payable(owner);
        require(getBalance() > 0,"no funds");
        uint amount = getBalance() / 2;
        to.transfer(amount);
    }

    //withdraw entier balance (only owner)
    function withdrawAllBalance() external {       
        address payable to = payable(owner);
        uint amount = getBalance();  
        require (to == owner, "you are not authorized"); 
        to.transfer(amount);        
    }

    // Total public balance from the Smart contract
        function getBalance() internal view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}