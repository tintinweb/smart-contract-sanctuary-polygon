/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract GiveawayFactory {
    Giveaway[] public giveawayArray;

    mapping(string => address) giveawayMap;

    function createNewGiveawayContract(string memory name) public {
        Giveaway giveaway = new Giveaway(msg.sender);
        giveawayArray.push(giveaway);
        giveawayMap[name] = address(giveaway);
    }

    function getGiveaways() public view returns (Giveaway[] memory) {
        return giveawayArray;
    }
}

contract Giveaway {

    event Received(address sender, uint256 amount);
    event Transferred(address sender, uint256 amount);

    address public owner;

    constructor(address giveawayOwner) public {
        //owner = msg.sender;
        owner = giveawayOwner;
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