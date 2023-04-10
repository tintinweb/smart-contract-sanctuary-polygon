/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract PolygonDapp {

    address  public owner;

    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address sender, uint amount);

    function PolyDapp() public {
        owner = msg.sender; // only the owner will be permitted to withdraw funds
    }

    function deposit() public payable returns(bool success) {
        emit LogDeposit(msg.sender, msg.value);
        return true;
    }

    /**
     * This is NOT needed, but for learning purposes, a convenience ... 
     * Anyone can check the balance at any address at any time, without this assistance.
     */
    function getBalance() public view returns(uint balance) {
        return address(this).balance;
    }

    function withdraw(uint amount) public returns(bool success) {
        require(msg.sender==owner);
        emit LogWithdrawal(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        return true;
    }

}