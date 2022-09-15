/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Greenlist {
    address admin;

    uint256 l;
    uint256 max;
    string message;
    uint256 stamp;

    mapping(address => bool) public isListed;
    address[250] public users;
    modifier notListed() {
        require(isListed[msg.sender] == false, "already listed");
        _;
    }

    constructor() {
        admin = msg.sender;
        users[0] = msg.sender;
        message = "BE FRESH MY FRUITY FRENZ !";
        l = 1;
        max = 250;
    }

    function getListed() external notListed returns (bool) {
        require(l < max, "no more greenlist tickets left");
        isListed[msg.sender] = true;
        users[l] = (msg.sender);
        l++;
        return isListed[msg.sender];
    }

    function showUsers() external view returns (address[250] memory) {
        return users;
    }

    function setMsg(string memory _msg) external payable returns (bool) {
        require(msg.value <= 1 * 10**18, "insufficient balance sent");
        require(block.timestamp >= stamp + 60 * 60, "you need to wait");
        message = _msg;
        stamp = block.timestamp;
        return true;
    }

    function showMsg() external view returns (string memory) {
        return message;
    }

    function withdraw() external returns (uint256) {
        require(admin == msg.sender, "you are not admin");
        payable(admin).transfer(address(this).balance);
        return address(this).balance;
    }
}