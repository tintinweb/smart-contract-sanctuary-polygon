/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

//SPDX-License-Identifier: Unlicenced
pragma solidity ^0.8.7;

contract HoneyPot {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function put() public payable {
        balances[msg.sender] = msg.value;
    }

    function withdraw() public {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function changeOwner(address newOwner) public{
        require(owner == msg.sender, "not owner");
        owner = newOwner;
    }

}