/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 1;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public multiplier = 1e18;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    address[] public stakers;
    address private owner;
    mapping(address => bool) private isAdmin;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        owner = msg.sender;
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Admin is only allowed!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner is only allowed");
        _;
    }

    function addAdmin(address user) external onlyOwner() {
        isAdmin[user] = true;
    }

    function removeAdmin(address user) external onlyOwner() {
        isAdmin[user] = false;
    }

    function transferOwnership(address user) external onlyOwner() {
        owner = user;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18 * multiplier) / _totalSupply / 3600 / 24);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account]) / multiplier)) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        if(_balances[msg.sender] == 0) stakers.push(msg.sender);
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(rewards[msg.sender] > 0, "There isn't any rewards for this address");
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
        require(_balances[msg.sender] >= _amount, "Insufficient withdraw amount!");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        if(_balances[msg.sender] == 0) {
            uint i;
            for(i = 0; i < stakers.length; i ++)
            {
                if(msg.sender == stakers[i]) break;
            }
            removeElement(i);
        }
    }

    function getBalance() public view returns(uint256) {
        return _balances[msg.sender];
    }

    function getBalanceOfUser(address _user) external view onlyAdmin() returns(uint) {
        return _balances[_user];
    }

    function totalStaked() external view onlyAdmin() returns(uint) {
        return _totalSupply;
    }

    function totalRewards() external view onlyAdmin() returns(uint) {
        uint _totalRewards = 0;
        for(uint i; i < stakers.length; i ++) {
            if(_balances[stakers[i]] != 0)
            _totalRewards += earned(stakers[i]);
        }
        return _totalRewards;
    }
    function removeElement(uint _index) internal {
        require(_index < stakers.length, "index out of bound");

        for (uint i = _index; i < stakers.length - 1; i++) {
            stakers[i] = stakers[i + 1];
        }
        stakers.pop();
    }
    function getReward() external updateReward(msg.sender) {
        require(rewards[msg.sender] > 0, "There isn't any rewards for this address");
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}