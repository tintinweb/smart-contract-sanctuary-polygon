/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Bank {
    address ownerAddress = 0xfb0133D62A4F3f13E78DfA9D2638C0B6cEf81120;
    mapping(address => uint256) public moneyMade;
    bool public saleIsActive = true;
    uint256 public constant PRICE_PER_TOKEN = 5 ether;


    function buyTicket(uint amount) public payable {
        require(saleIsActive == true, "sale is off");
        require(PRICE_PER_TOKEN * amount <= msg.value, "Ether value sent is not correct");
        moneyMade[msg.sender] -= msg.value;
    }

    function setSaleState(bool newState) public  {
        require(msg.sender==ownerAddress,"only owner can change");
        saleIsActive = newState;
    }


    function sendMoney(address sendTo, uint amount) public payable {
        require(msg.sender==ownerAddress,"only owner");
        payable(sendTo).transfer(amount);
        moneyMade[sendTo] += amount;
    }
}