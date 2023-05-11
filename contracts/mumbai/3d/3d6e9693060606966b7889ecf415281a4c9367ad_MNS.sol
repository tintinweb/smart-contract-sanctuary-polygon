/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MNS{
    mapping(address => bool) public isInit;

    uint256 private conv;
    address private owner;


    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function Init() public
        payable 
        {
        require(msg.value == 0.1 ether);
        isInit[msg.sender] = true;
        require(isInit[msg.sender] == true);
    }

    function DeInit() public{
        isInit[msg.sender] = false;
    }

    function withdraw(uint256 ammount) public onlyOwner{
        address payable walletAddress = payable(msg.sender);

        (bool success, ) = walletAddress.call{value: ammount}("");
        require(success);


    }
}