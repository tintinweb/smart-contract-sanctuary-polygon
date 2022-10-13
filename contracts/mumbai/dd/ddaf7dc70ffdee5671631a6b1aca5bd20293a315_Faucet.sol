/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable owner = payable(msg.sender);
    bool paused;
    uint i;
    uint limitAmount = 0.01 ether;
    address lastSender;

    modifier onlyOwner {
        require(owner == msg.sender, "you are not authorizeid");
        _;
    }
    modifier notPaused() {
        require(paused == false, "Paused smart contract");
        _;
    } 

    constructor () payable {   
        if (msg.value < 0.5 ether) {            
           revert("Inject minimum 0.5 ether, thamk you!"); 
           }                               
    }  

    function inject() external payable notPaused onlyOwner { 
        require(msg.value > 0, "You are not authorized");         
    }

    function destroy() external notPaused onlyOwner {
        selfdestruct(owner);
    }

    function setResume() external notPaused onlyOwner {
        paused = false;
    }

    function setAmount(uint _amount) external notPaused {
        limitAmount = _amount;
    }

    function setOwner(address payable _owner) external notPaused onlyOwner {
        owner = _owner;
    }
       
    function sendLimitEthers() external notPaused {        
        if (getBalance() < 0.01 ether) {            
            revert("Not funds");
        }
        i = i + 1;        
        address payable to = payable(msg.sender);
        if (i % 5 == 0) { 
            limitAmount = limitAmount + 0.005 ether;
        }
        if (lastSender == msg.sender) {
            revert("you need to wait for another user to withdraw money before you ");
        }
        lastSender = msg.sender; 

        to.transfer(limitAmount);
    }

    function send() external notPaused {
        require(owner != msg.sender, "you are not authorized");
        require(getBalance() > 0.01 ether, "Not funds");

        address payable to = payable(msg.sender);

        to.transfer(0.01 ether);
    }

    function emergencyWithdraw() external notPaused onlyOwner {  
        require (getBalance() > 0,"Not funds"); 

        address payable to = payable(msg.sender);
        uint amount = getBalance(); 

        to.transfer(amount);
    }  

    function getBalance() public view notPaused returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }   

     function setPaused() external onlyOwner returns (bool) {
        paused = true;
        return paused;
    }
}