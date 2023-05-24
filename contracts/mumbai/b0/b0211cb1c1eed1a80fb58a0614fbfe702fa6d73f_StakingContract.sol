/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StakingContract {
    IERC20 public token;
    uint256 public feePercentage;
    uint256 public lastUpdateTime;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public feeBalances;

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event FeeWithdrawn(address indexed staker, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        feePercentage = 3; 
        lastUpdateTime = block.timestamp;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");

        updateStaking(msg.sender);

        token.transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;

        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");

        updateStaking(msg.sender);

        stakedBalances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    function withdrawFee() external {
        updateStaking(msg.sender);

        uint256 feeAmount = feeBalances[msg.sender];
        require(feeAmount > 0, "No fees to withdraw");

        feeBalances[msg.sender] = 0;
        token.transfer(msg.sender, feeAmount);

        emit FeeWithdrawn(msg.sender, feeAmount);
    }

    function updateStaking(address staker) internal {
        uint256 elapsedTime = block.timestamp - lastUpdateTime;
        uint256 feeAmount = stakedBalances[staker] * feePercentage * elapsedTime / (1000 * 1 days);

        if (feeAmount > 0) {
            stakedBalances[staker] -= feeAmount;
            feeBalances[staker] += feeAmount;
        }

        lastUpdateTime = block.timestamp;
    }
}