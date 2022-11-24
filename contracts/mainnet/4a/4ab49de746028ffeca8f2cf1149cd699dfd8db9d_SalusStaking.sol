// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract SalusStaking {

    struct Stake {
        uint256 amount;
        uint256 unlockTime;
    }

    uint256 public constant MAX_STAKE = 10_000_000_000; // USDC has 6 decimals. This equates to 10,000 USDC
    uint256 public constant MAX_TIME = 180 days; // Maximum 6 months stake
    address public constant token = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC on Polygon
    
    uint256 public stakeAmount;
    uint256 public stakeTime;
    address public owner;
    mapping (address => Stake) private stakes;
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor (uint256 _stakeAmount, uint256 _stakeTime, address _owner) {
        require(_stakeAmount <= MAX_STAKE, "Max stake amount exceeded");
        require(_stakeAmount != 0, "Cannot have 0 stake");
        require(_stakeTime <= MAX_TIME, "Max stake time exceeded");
        require(_owner != address(0), "0 address not allowed");
        stakeAmount = _stakeAmount;
        stakeTime = _stakeTime;
        owner = _owner;
    }

    function updateStakeAmount(uint256 _stakeAmount) public onlyOwner {
        require(_stakeAmount <= MAX_STAKE, "Max stake amount exceeded");
        require(_stakeAmount != 0, "Cannot have 0 stake");
        stakeAmount = _stakeAmount;
    }
    
    function updateStakeTime(uint256 _stakeTime) public onlyOwner {
        require(_stakeTime <= MAX_TIME, "Max stake time exceeded");
        stakeTime = _stakeTime;
    }

    function stake(uint256 _amount, uint256 _time) public {
        require(_amount == stakeAmount, "Incorrect stake amount");
        require(_time == stakeTime, "Incorrect stake time");
        require(stakes[msg.sender].amount == 0, "Already staked");

        Stake memory newStake = Stake(_amount, block.timestamp + _time);
        stakes[msg.sender] = newStake;

        IERC20(token).transferFrom(msg.sender, address(this), stakeAmount);
    }

    function unstake() public {
        require(stakes[msg.sender].amount != 0, "No stake");
        require(stakes[msg.sender].unlockTime <= block.timestamp, "Stake still locked");

        Stake memory currentStake = stakes[msg.sender];
        delete stakes[msg.sender];

        IERC20(token).transfer(msg.sender, currentStake.amount);
    }

    function sweepStake(address _staker) public onlyOwner {
        require(stakes[_staker].amount != 0, "No stake for staker");
        require(stakes[_staker].unlockTime + 30 days <= block.timestamp, "Stake not unlocked for sweeping");

        Stake memory currentStake = stakes[_staker];
        delete stakes[_staker];

        IERC20(token).transfer(owner, currentStake.amount);
    }

    function getStake(address _staker) public view returns (uint256 amount, uint256 unlockTime) {
        Stake memory currentStake = stakes[_staker];
        amount = currentStake.amount;
        unlockTime = currentStake.unlockTime;
    }
}