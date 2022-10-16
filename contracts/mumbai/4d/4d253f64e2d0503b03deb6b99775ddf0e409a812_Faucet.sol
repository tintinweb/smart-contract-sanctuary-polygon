/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable owner = payable(msg.sender);
    bool paused;
    uint counterEveryFive;
    uint limitAmount = 0.01 ether;
    uint plus;
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
        require(msg.value >= 0.5 ether, "Inject minimum 0.5 ether, thank you!");                                
    }  

    function inject() external payable notPaused onlyOwner { 
        require(msg.value > 0, "You are not authorized");         
    }

    function destroy() external notPaused onlyOwner {
        selfdestruct(owner);
    }

    function pause() external onlyOwner {
        paused = true;        
    }

    function resume() external onlyOwner {
        paused = false;
    }

    function setAmount(uint newLimitAmount) external notPaused {
        limitAmount = newLimitAmount;
    }

    function setOwner(address payable newOwner) external notPaused onlyOwner {
        owner = newOwner;
    }
       
    function sendLimitEthers() external notPaused {       
        if (getBalance() < 0.01 ether) {            
            revert("Not funds");
        }
        counterEveryFive = counterEveryFive + 1;        
        address payable to = payable(msg.sender);
        if (counterEveryFive % 5 == 0) { 
            plus = 0.005 ether;
        }
        if (counterEveryFive % 5 != 0) { 
            plus = 0 ether;
        }
        if (lastSender == msg.sender) {
            revert("you need to wait for another user to withdraw money before you");
        }
        lastSender = msg.sender; 

        to.transfer(limitAmount + plus);
    }

    function send() external notPaused {
        require(owner != msg.sender, "you are not authorized");
        require(getBalance() >= 0.01 ether, "Not funds");

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
}