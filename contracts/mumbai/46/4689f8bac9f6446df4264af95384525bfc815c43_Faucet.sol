/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Faucet {
    address payable public owner;
    uint256 public counter;
    address public lastOne;
    bool public active;
    uint256 public amount;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor () {
        lastOne = msg.sender;
        active = true;
        counter = 0;
        amount = 10000000000000000;
        owner = payable(msg.sender);
    }

    function getBalance() public view returns(uint256) {
        require(active, "SC paused");
        uint256 balance = address(this).balance;
        return balance;
    }

    function inject() external payable onlyOwner {
        require(active, "SC paused");
    }

    function send() external payable {
        require(active, "SC paused");
        require (owner != msg.sender, "You are the owner");
        require (lastOne != msg.sender, "Can not repeat"); 

        address payable to = payable(msg.sender);
        uint256 value = amount;
        
        if (counter % 5 == 0 && counter != 0) {
            value += 5000000000000000;
        } 

        require (getBalance() >= value, "There are not enough funds");
        to.transfer(value); 

        counter += 1;
        lastOne = msg.sender;
    }
    
    function emergencyWithdraw() external onlyOwner {
        require(active, "SC paused");
        owner.transfer(getBalance());
    }

    function setOwner(address payable newOwner) external onlyOwner {
        require(active, "SC paused");
        owner = newOwner;
    }

    function setAmount(uint newAmount) external onlyOwner {
        require(active, "SC paused");
        amount = newAmount ;
    }

    function destroy() external onlyOwner {
        require(active, "SC paused");
        selfdestruct(owner);
    }

    function pause() external onlyOwner {
        active = false;
    }

    function resume() external onlyOwner {
        active = true;
    }
}