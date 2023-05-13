/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Charity {
    string private name;
    uint8 private decimals;
    uint256 private totalSupply;
    address payable public owner;
    uint256 private donation;
    uint256 public totalDonation;

    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 setSupply) payable {
        name = "SOUL";
        decimals = 100;
        totalSupply = setSupply * decimals;
        owner = payable(msg.sender);
        balanceOf[msg.sender] = totalSupply;
    }

    function donate() public payable returns(uint256 soulsReceived) {
        require(msg.value > 0, "Donation value should be greater than zero");
        donation = msg.value;
        totalDonation += donation;

        if(donation < 1 ether){
            uint256 souls = 1;
            balanceOf[owner] -= souls;
            balanceOf[msg.sender] += souls;
            emit Transfer(owner, msg.sender, souls);
            return souls;
        }
        else if(donation == 1 ether){
            uint256 souls = 10;
            balanceOf[owner] -= souls;
            balanceOf[msg.sender] += souls;
            emit Transfer(owner, msg.sender, souls);
            return souls;
        }
        else if(donation > 1 ether && donation <= 10 ether){
            uint256 souls = 11;
            balanceOf[owner] -= souls;
            balanceOf[msg.sender] += souls;
            emit Transfer(owner, msg.sender, souls);
            return souls;

        }
        else {
            uint256 souls = 15;
            balanceOf[owner] -= souls;
            balanceOf[msg.sender] += souls;
            emit Transfer(owner, msg.sender, souls);
            return souls;
        }
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero.");
        owner.transfer(address(this).balance);
    }

    modifier onlyOwner(){
        require(msg.sender == owner , "Only owner can call this function");
        _;
    }
}