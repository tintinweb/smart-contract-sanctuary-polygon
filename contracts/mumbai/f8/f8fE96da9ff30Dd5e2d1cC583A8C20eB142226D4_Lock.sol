// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    uint public percent = 50;
    uint public min = 1 ether;
    uint public max = 1000 ether;
    address public owner;

    uint public countGames = 0;
    uint public amountPayment = 0;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "not owner");
        _;

    }

    receive () external payable {
        address payable sender = payable(msg.sender);
        if (msg.value < min) {
            sender.transfer(msg.value);
        } else if (msg.value > max) {
            sender.transfer(1 ether); //lox
        } else {
            uint numberSender = random(100 / percent);
            if (numberSender < 2) {
                sender.transfer(msg.value * 2);
            } else {
                //lox
            }
        }
    }

    function random(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function writePercent (uint percentOwner) external onlyOwner {
        percent = percentOwner;
    }

    function sendMoneyOwner (uint amount) external onlyOwner {
        uint amountE = amount * 10 ** 18;
        address payable addressP = payable(owner);
        addressP.transfer(amountE);
    }


}