/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract FaucetPlus {

    
    // We declare a state variable for the owner's address and another one to solve the problem of not requesting 2 consecutive times.
    address owner;
    address lastAddress;
    
    // this constructor is to send money to the faucet, it is only executed once and we are also going to take the opportunity to add the address of the owner
    constructor() payable {
        // designate the owner variable with the address with which the contract is displayed
        owner = msg.sender;
    }

    // function change owner
    // this function returns the entered address, output
    function getChangeOwner() external view returns (address) {
        return owner;
    }

    // here we enter the address, input
    function setChangeOwner(address newAddress) external {
        require(owner == msg.sender,"Only the Owner is authorized");

        owner = newAddress;
    }
   
    // function to provide money to the SC from the owner's account
    function sendMoney() external payable {      
        require(msg.sender == owner, "Only the Owner is authorized"); 
    }

    // function so that the user can request 0.01 eth to the faucet with some conditions:
    function request() external {
        
        address payable to = payable(msg.sender);            
        
        // the require is to check that the user does not withdraw money twice in a row and the if is to avoid the error in case the SC does not have money
        if (address(this).balance >= 0.01 ether) {
        require(msg.sender == owner, "you can't ask for money twice in a row"); 
            require(msg.sender != lastAddress,"");
            lastAddress = msg.sender;
            to.transfer(0.01 ether);
        }
    }    

    // function to know the balance of the SC
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // function in this case to remove all the money that is in the SC using balance and require to make sure that it is the address of the owner
    function withdraw() external {
        require(msg.sender == owner,"Only the Owner is authorized");

        address payable to = payable(msg.sender);
        uint balance = address(this).balance;

        to.transfer(balance);
        
    }
}