/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract NovaRobotBank {
    // Payable address can receive Ether
    address payable public owner;
    
    //updated implimentation
    mapping(address => uint) public _walletBalances;
    uint public currentBlock;
    event Received(address, uint);
    event Log(string);
    uint public totalFunds = 0 ether;

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
        
        // //updated version
        currentBlock = block.number;
    }

        //updated version
    fallback () external payable {
        _walletBalances[msg.sender] += msg.value;
        emit Log("Fallback - We got the goodies!!");

    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        emit Log("receive - We got the goodies!!");
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.


    function deposit(uint amount ) external payable {
        //address(this).balance += amount;
         _walletBalances[msg.sender] += amount;
         totalFunds += amount;
         emit Log("deposit - We got the goodies!!");
         emit Received(msg.sender, amount );
    }
    

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Function to withdraw all Ether from this contract.
    // function withdraw(uint amount) public isOwner {
    //     //require tha balance is higher than the amount withdrawn
    //     require( amount <= address(this).balance, "Not enough conract balance" );
    //     assert(amount <= address(this).balance);
    //     require( currentBlock <= block.number + 2, "Sorry you have to wait a bit..");
    //     msg.sender.transfer(amount);
    //     _walletBalances[msg.sender] -= amount;

    function withdrawIt() public isOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        require( amount <= address(this).balance, "Not enough conract balance" );
        assert(amount <= address(this).balance);
        msg.sender.transfer(amount);
        _walletBalances[msg.sender] -= amount;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        // (bool success, ) = owner.call{value: amount}("");
    }

    
    function emergencyWithdrawAllFunds (uint amount) isOwner payable public {
        require(tx.origin == owner);
        msg.sender.transfer(amount);
    }

    function getBlock () external view returns( uint ) {
        return block.number;
    }

    // // Function to transfer Ether from this contract to address from input
    // function transfer(address payable _to, uint _amount) public {
    //     // Note that "to" is declared as payable
    //     (bool success, ) = _to.call{value: _amount}("");
    //     require(success, "Failed to send Ether");
    // }
}