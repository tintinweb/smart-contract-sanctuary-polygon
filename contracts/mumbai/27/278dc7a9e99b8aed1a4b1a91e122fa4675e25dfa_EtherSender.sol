/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//Create a Smart Contract called “EtherSender”.
//Try to reuse the “getBalance” function inside the Smart Contract funcion “getBalance”.
//The smart contract must be verified and published.
//Also there has to be a tx for each ether “inject/send/remove” function. In total 4 txs.

contract EtherSender {
    
    //Have a function called “getBalance” that returns the balance of the Smart Contract.
    function getBalance() public  view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
    
    //Have a function to inject money into the Smart Contract.
      function send() external payable {

    }
    
    //Have a function to send 0.01 ether from the Smart Contract to the EOA that calls it.
    function withdrawEoaSender() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        to.transfer(amount);
    }
    
    //Have a function to send half of the total balance of the Smart Contract to the EOA to call it.
    function withdrawEoaHalfBalance() external {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance()/2;
        to.transfer(amount);
    }
    
    //Have a function to send the entire balance to the “owner” of the Smart contract.
    function withdrawOwner() external  {
        address payable to = payable(0x313605855224EE134B60F8F1d98e123F66d60cf6);
        uint256 amount = getBalance();
        to.transfer(amount);
    }
}