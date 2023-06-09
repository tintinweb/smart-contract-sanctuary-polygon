/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Faucet {

    address owner;
    address lastReciever;
    uint256 countRecievers;
    uint256 amountToSent;
    event ChangeOwner(address newOwner);
    event SendTransfer(address sender, address reciever, uint256 amount, bool resultTransfer);
    bool isPaused;

    constructor() {
        owner = msg.sender;
        amountToSent = 10000000000000000; // 0.001 ether
        isPaused = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Error! only owner can execute this function.");
        _;
    }

    modifier isNotPaused {
        require(isPaused == false, "Error! Contract is paused.");
        _;
    }

    function getBalance () public view returns (uint256)  {
        return address(this).balance;
    }

    function inject () external payable onlyOwner {}

    function send(address reciever) external isNotPaused returns(bool){
        require(msg.sender != owner, "Error! owner cant send founds."); 
        require(address(this).balance >= 0.01 ether,"Error! not sufficient founds.");
        require(msg.sender != lastReciever, "Error! you are the last to receive funds");
        (bool sent, ) = reciever.call{value: amountToSent}("");
        countRecievers++;
        if(countRecievers % 5 == 0) {
            (bool sentExtra, ) = reciever.call{value: 0.005 ether}("");
            emit SendTransfer(msg.sender, reciever, 0.005 ether, sentExtra);
        }
        lastReciever = msg.sender;
        emit SendTransfer(msg.sender, reciever, amountToSent, sent);
        return sent;
    }

    function emergencyWithdraw() external onlyOwner  returns (bool) {
       (bool sent,) = owner.call{value: address(this).balance}("");
       return sent;
    }

    function setOwner(address newOwner) external onlyOwner isNotPaused {
        require(newOwner != address(0), "Error! Address zero not allowed to be owner");
        owner = newOwner;
        emit ChangeOwner(newOwner);
    }    

    function setAmount(uint256 newAmount) external onlyOwner isNotPaused {
        amountToSent = newAmount;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }
    
    function resume() external onlyOwner {
        isPaused = false;
    }

    function isContractPaused() public view returns (bool) {
        return isPaused;
    }
}