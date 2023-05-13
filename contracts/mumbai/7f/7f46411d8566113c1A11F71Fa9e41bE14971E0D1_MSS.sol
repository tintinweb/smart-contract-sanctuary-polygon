/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MSS{

    //variables
    mapping (address => string) public statusOf;
    mapping (address => bool) public isInit;
    address public owner;
    uint256 private ammount;

    //constructor
    constructor() {
        owner = msg.sender;
    }

    //functions
    function init() payable public {
        require(msg.value == 0.1 ether);
        isInit[msg.sender] = true;
        statusOf[msg.sender] = "undefined";
        require(isInit[msg.sender] == true);
    }

    function setStatus(string memory newStatus) public{
        statusOf[msg.sender] = newStatus;
    }

    function withdraw(uint256 finney) public{
        require(msg.sender == owner);
        ammount = finney * 1000000000000000;
        address payable walletAddress = payable(msg.sender);

        (bool success, ) = walletAddress.call{value: ammount}("");
        require(success);
    }

}