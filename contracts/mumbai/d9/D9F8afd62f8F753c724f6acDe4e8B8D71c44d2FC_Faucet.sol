/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {
    address payable owner;
    address formerSender;
    uint256 counter = 1;
    uint256 amount = 0.01 ether;
    bool public paused;

    
    constructor() payable {
        require(msg.value == 0.5 ether, "Error: value must be equal to 0.5 ether");
        owner = payable(msg.sender);
        paused = false;
    }
    modifier isNotPaused() {
        require(paused == false, "Error: contract is paused");
        _;
    }
    
    modifier isOwner() {        
        require(msg.sender == owner,"Error: You are not the owner");
        _;
    }

    function pause() external isOwner {
        paused = true;
    }
 
    function resume() external isOwner {
        paused = false;
    }

    function getBalance() view public isNotPaused returns(uint256) {
        return  address(this).balance;      
    }

    function inject() payable external isOwner isNotPaused {   
    } 

    function setAmount(uint256 _amount) external isOwner isNotPaused {
        require (_amount > 0, "Error: Amount must be greater than zero");
        amount = _amount;
    }

    function send() external isNotPaused {
        require(msg.sender != owner, "Error: You are the owner");
        require(msg.sender != formerSender, "Error: You have to wait for next address to ask for eth");
        require(address(this).balance >= amount, "Error: Not enough balance");
        if (counter % 5 != 0) {
            (bool success,) = msg.sender.call{value : amount}("");
		    require(success, "Error: Transaction failed");    
        } else if (address(this).balance >= amount + 0.005 ether) {
             (bool success,) = msg.sender.call{value : amount + 0.005 ether}("");
		     require(success, "Error: Transaction failed");
        } else {
              (bool success,) = msg.sender.call{value : getBalance()}("");
		      require(success, "Error: Transaction failed");
        }
        formerSender = msg.sender;
        counter += 1;
    }

    function emergencyWithdraw() external isOwner isNotPaused {
        (bool success,) = msg.sender.call{value : getBalance()}("");
		 require(success, "Error: Transaction failed");
    }
    
    function setOwner(address payable _newOwner) external isOwner isNotPaused {
        require (_newOwner != address(0),"Error: Not a valid address");
        owner = _newOwner;
    }

    function destroy() external isOwner isNotPaused {
        selfdestruct(owner);
    }
}