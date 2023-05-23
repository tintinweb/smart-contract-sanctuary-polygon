/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

abstract contract StakingContract {
    using SafeMath for uint256;

    struct Stake {
        uint256 startDate;
    }

    mapping(address => mapping(uint256 => Stake)) public stakes;
    mapping(address => mapping(uint256 => uint256)) public rewards;

    uint256 public rewardPerEpoch = 1;
    uint256 public epochDuration = 7 days;

    modifier notStaking(uint256 _tokenId) {
        require(stakes[msg.sender][_tokenId].startDate == 0, "Already staking");
        _;
    }

    modifier isStaking(uint256 _tokenId) {
        require(stakes[msg.sender][_tokenId].startDate > 0, "Not staking");
        _;
    }

    constructor(uint256 _rewardPerEpoch, uint256 _epochDuration) {
        rewardPerEpoch = _rewardPerEpoch;
        epochDuration = _epochDuration;
    }

    function stake(uint256 _tokenId) public notStaking(_tokenId) {
        stakes[msg.sender][_tokenId] = Stake(block.timestamp);
        onStake(msg.sender, _tokenId);
    }

    function unstake(uint256 _tokenId) public isStaking(_tokenId) {
        claim(_tokenId);
        stakes[msg.sender][_tokenId].startDate = 0;
        onUnstake(msg.sender, _tokenId);
    }

    function claim(uint256 _tokenId) public isStaking(_tokenId) {
        uint256 rewardAmount = pending(msg.sender, _tokenId);
        stakes[msg.sender][_tokenId].startDate = block.timestamp;
        rewards[msg.sender][_tokenId] = rewards[msg.sender][_tokenId].add(rewardAmount);
        onClaim(msg.sender, _tokenId, rewardAmount);
    }

    function pending(address _staker, uint256 _tokenId) public view returns(uint _rewardAmount) {
        if(stakes[_staker][_tokenId].startDate > 0) {
            uint256 stakingDuration = block.timestamp.sub(stakes[_staker][_tokenId].startDate);
            uint256 rewardEpochs = stakingDuration.div(epochDuration);
            _rewardAmount = rewardEpochs.mul(rewardPerEpoch);
        }
    }

    function onStake(address _staker, uint256 _tokenId) internal virtual;
    function onUnstake(address _staker, uint256 _tokenId) internal virtual;
    function onClaim(address _claimer, uint256 _tokenId, uint256 _reward) internal virtual;
}

/* Abstracted Implementation */
/* Just Using the overrides. */
/* Mumbai 0xc77140c0236f42d13998696b911dd34c11a22d09 */
contract NX7Steaking is StakingContract {

    event Staked(address indexed staker, uint256 indexed tokenId);
    event Unstaked(address indexed staker, uint256 indexed tokenId);
    event Claimed(address indexed claimer, uint256 indexed tokenId, uint256 rewards);

    constructor() StakingContract(rewardPerEpoch = 2, epochDuration = 1 minutes) {}

    function onStake(address _staker, uint256 _tokenId) internal override {
        emit Staked(_staker, _tokenId);
    }

    function onUnstake(address _staker, uint256 _tokenId) internal override {
        emit Unstaked(_staker, _tokenId);
    }

    function onClaim(address _claimer, uint256 _tokenId, uint256 _rewards) internal override {
        emit Claimed(_claimer, _tokenId, _rewards);
    }
}