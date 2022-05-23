/**
 *Submitted for verification at polygonscan.com on 2022-05-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract GiveawayFactory {
    Giveaway[] public giveawayArray;

    function createNewGiveawayContract() public {
        Giveaway giveaway = new Giveaway();
        giveawayArray.push(giveaway);
    }
}

contract Giveaway {

    event Received(address sender, uint256 amount);
    event Transferred(address sender, uint256 amount);

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function collectMoney() public payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transfer(address payable to, uint256 amount) public {
        require(msg.sender == owner, "You are not the owner");
        require(amount > 0, "Transfer amount should be > 0");
        require(address(this).balance > 0, "No balance in escrow");
        require(amount <= address(this).balance, "Not enough balance in escrow");

        to.transfer(amount);

        emit Transferred(to, amount);
    }
}