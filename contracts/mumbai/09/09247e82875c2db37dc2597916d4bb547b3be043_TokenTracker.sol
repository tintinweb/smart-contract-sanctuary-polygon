/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenTracker {
    struct TokenInfo {
        bool isTracked;
        uint256 earnedTokens;
        uint256 spentTokens;
    }

    address private owner;
    mapping(address => TokenInfo) private tokenInfos;
    address[] private trackedTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToken(address token) public onlyOwner {
        require(!tokenInfos[token].isTracked, "Token is already tracked");
        tokenInfos[token].isTracked = true;
        trackedTokens.push(token);
    }

    function getTrackedTokens() public view returns (address[] memory) {
        return trackedTokens;
    }

    function getEarnedTokens(address token) public view returns (uint256) {
        require(tokenInfos[token].isTracked, "Token is not tracked");
        return tokenInfos[token].earnedTokens;
    }

    function getSpentTokens(address token) public view returns (uint256) {
        require(tokenInfos[token].isTracked, "Token is not tracked");
        return tokenInfos[token].spentTokens;
    }

    function earnTokens(address token, uint256 amount) public {
        require(tokenInfos[token].isTracked, "Token is not tracked");
        tokenInfos[token].earnedTokens += amount;
    }

    function spendTokens(address token, uint256 amount) public {
        require(tokenInfos[token].isTracked, "Token is not tracked");
        require(tokenInfos[token].earnedTokens >= amount, "Insufficient tokens");
        tokenInfos[token].earnedTokens -= amount;
        tokenInfos[token].spentTokens += amount;
    }
}