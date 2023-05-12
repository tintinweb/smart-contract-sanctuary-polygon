/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



contract StakingContract {
    IERC20 public token;
    address public owner;
    uint256 public constant APY = 520; // 520% annual percentage yield
    uint256 public constant DECIMALS = 10 ** 18;
    uint256 public totalStaked;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastStakedTime;

    event Deposit(address indexed user, uint256 amount);
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {

        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    function deposit(uint256 _amount) external {
    require(_amount > 0, "Amount must be greater than 0");
    require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance too low");
    require(token.transferFrom(msg.sender, address(this), _amount), "Failed to transfer tokens to contract");
    emit Deposit(msg.sender, _amount);
}

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(address(this)) >= totalStaked + _amount, "Insufficient balance in the contract");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        uint256 timeSinceLastStaked = block.timestamp - lastStakedTime[msg.sender];
        uint256 interest = balances[msg.sender] * APY * timeSinceLastStaked / (365 * 24 * 3600 * DECIMALS);
        require(IERC20(address(token)).transferFrom(address(this), msg.sender, interest), "Failed to transfer interest to user");
        token.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
        totalStaked += _amount;
        lastStakedTime[msg.sender] = block.timestamp;
        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        uint256 timeSinceLastStaked = block.timestamp - lastStakedTime[msg.sender];
        uint256 interest = balances[msg.sender] * APY * timeSinceLastStaked / (365 * 24 * 3600 * DECIMALS);
        require(payable(address(token)).send(_amount + interest), "Failed to transfer tokens to user");

        balances[msg.sender] -= _amount;
        totalStaked -= _amount;
        lastStakedTime[msg.sender] = block.timestamp;
        emit Unstake(msg.sender, _amount);
    }

    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    
}

contract RewardsPool is StakingContract {


    constructor(address _token) StakingContract(_token) {
        
        
    }
    
    function addTokens(uint _amount) public {
        require(token.transferFrom(msg.sender, address(this), _amount), "Failed to transfer tokens to contract");
    }
    
    
    function getBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }
}