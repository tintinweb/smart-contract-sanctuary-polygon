/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract XiraSpaceEarn {
    address public token;  // Address of the token contract
    address public owner;  // Address of the contract owner
    
    uint256 private totalTokens;  // Total number of tokens sent to the contract
    uint256 public startTime;  // Start time of the vesting period in Unix (https://www.unixtimestamp.com/)
    uint256 public releaseInterval;  // Time interval between releases in seconds
    uint256 public numReleases;  // Total number of releases
    uint256 public releasedWeeks;  // Number of releases / weeks released so far
    
    uint256 private constant ONE_WEEK = 1 weeks;
    uint256 private constant DECIMALS = 18;  // Number of decimal places for the token
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function setTokenAddress(address _token) external onlyOwner {
        require(token == address(0), "Token address has already been set.");
        require(_token != address(0), "Invalid token address.");
        
        token = _token;
        
        // Approve maximum token allowance on deployment
        IERC20(_token).approve(address(this), type(uint256).max);
    }
    
    function startVesting() external onlyOwner {
        require(totalTokens == 0, "Vesting has already started.");
        require(token != address(0), "Token address has not been set.");
        
        totalTokens = IERC20(token).balanceOf(address(this));  // Retrieve token balance of the contract
        startTime = block.timestamp;
        releaseInterval = ONE_WEEK;
        numReleases = 50;  // 50 weeks until all tokens have been released
        releasedWeeks = 0; // Starting on week 0
        
        require(totalTokens > 0, "No tokens available for vesting.");
    }

    // Withdraw released tokens (Total tokens / total weeks)
    function withdrawTokens() external onlyOwner {
    require(totalTokens > 0, "Vesting has not started yet.");

    uint256 currentRelease = (block.timestamp - startTime) / releaseInterval;
    uint256 tokensToRelease = totalTokens / numReleases;

    // Ensure there are tokens to release and the release is due
    require(currentRelease > releasedWeeks, "No tokens available for release.");

    uint256 tokensAvailable;
    if (currentRelease >= numReleases) {
        // Vesting period has ended, withdraw remaining tokens
        tokensAvailable = IERC20(token).balanceOf(address(this));
    } else {
        tokensAvailable = (currentRelease - releasedWeeks) * tokensToRelease;
    }

    require(tokensAvailable > 0, "No tokens available for withdrawal.");

    require(IERC20(token).transfer(owner, tokensAvailable), "Token transfer failed.");

    releasedWeeks = currentRelease;
}


    
    function getContractBalance() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    function getNextReleaseTime() external view returns (uint256) {
        require(totalTokens > 0, "Vesting has not started yet.");
        
        uint256 currentRelease = (block.timestamp - startTime) / releaseInterval;
        uint256 nextRelease = (currentRelease + 1) * releaseInterval + startTime;
        
        return nextRelease;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}