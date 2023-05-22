/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSig {
    address president = 0x7bC3f4886Ec1850FB4Dd83F0FF21f6B80b721fCb;
    address vicepresident = 0x6a0A2946D11a1203b7E7dB9e2A5623d7cfEC0b2A;
    address electrican = 0x714655E53E6669a2754E1B515D4197b6A8294AE3;
    bool public isApproved;
    bool isSent = false;
    // owner
    address public owner;
    // Bonus 
    bool isPresidentApprove = false;
    bool isVicePresidentApprove = false;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sorry, you are not the owner");
        _;
    }

    function inject() external payable onlyOwner {
        require(msg.value == 0.01 ether, "Sorry, you have to pay 0.01 ether");
    }

    function sendToElectrician() external onlyOwner {
        require(isApproved == true && isSent == false, "Sorry the transaction is not approved by president/vicepresient");
        payable(electrican).transfer(0.07 ether);
    }

    function approve() external onlyOwner {
        require(isPresidentApprove == true && isVicePresidentApprove == true, "Sorry You are not allowed");
        isApproved = true;
    }

    function presidentApprove() external {
        require(msg.sender == president, "Sorry You are not The President");
        isPresidentApprove = true;
    }

    function vicePresidentApprove() external {
        require(msg.sender == president, "Sorry You are not The Vice President");
        isVicePresidentApprove = true;
    }
}