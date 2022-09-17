/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Greenlist {
    address public admin;

    uint256 public l;
    uint256 public max;
    string public message;
    uint256 public stamp;

    mapping(address => bool) public isListed;
    address[1234] public users;
    modifier notListed(address _adr) {
        require(isListed[_adr] == false, "already listed");
        _;
    }

    constructor() {
        admin = msg.sender;
        isListed[msg.sender] = true;
        users[0] = msg.sender;
        message = "BE FRESH MY FRUITY FRENZ !";
        l = 1;
        max = 1234;
    }

    function getListed() external notListed(msg.sender) returns (bool) {
        require(l < max, "no more greenlist tickets left");
        isListed[msg.sender] = true;
        users[l] = (msg.sender);
        l++;
        return isListed[msg.sender];
    }

    function makeListing(address _adr) external notListed(_adr) returns (bool) {
        require(admin == msg.sender, "you are not admin");
        isListed[_adr] = true;
        users[l] = (_adr);
        l++;
        return isListed[_adr];
    }

    function showUsers() external view returns (address[1234] memory) {
        return users;
    }

    function setMsg(string memory _msg) external payable returns (bool) {
        require(msg.value <= 1 * 10**18, "insufficient balance sent");
        require(block.timestamp >= stamp + 60 * 60, "you need to wait");
        message = _msg;
        stamp = block.timestamp;
        return true;
    }

    function setMsgAdmin(string memory _msg) external returns (bool) {
        require(admin == msg.sender, "you are not admin");
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