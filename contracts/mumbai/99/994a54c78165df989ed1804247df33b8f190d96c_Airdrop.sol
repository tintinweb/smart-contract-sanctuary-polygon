/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    mapping(address => bool) public airdropUsers;
    uint256 public totalAmount;
    IERC20 public token;

    constructor(IERC20 _token, uint256 _totalAmount) {
        owner = msg.sender;
        totalAmount = _totalAmount;
        token = _token;
    }

    function addToAirdrop(address[] calldata _users) external {
        require(msg.sender == owner, "Only owner can add users to airdrop");
        for (uint i = 0; i < _users.length; i++) {
            airdropUsers[_users[i]] = true;
            require(token.balanceOf(address(this)) >= totalAmount, "Insufficient balance for airdrop");
            require(token.transfer(_users[i],totalAmount), "Token transfer failed");
        }
    }

    function withdrawTokens() external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        require(token.transfer(owner, token.balanceOf(address(this))), "Token transfer failed");
    }
}