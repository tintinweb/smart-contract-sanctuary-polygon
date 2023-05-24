// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";

contract NFTStaking {
    struct Staker {
        uint256 stakedTokenId;
        uint256 stakingTime;
        uint256 lastClaimTime;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenStakers;
    mapping(address => uint256) public rewards;

    uint256 public stakingPeriod = 300; // 7 days (in seconds)
    uint256 public rewardRate;

    IERC721 public nftToken;
    IERC20 public rewardToken;

    event Staked(address indexed staker, uint256 tokenId);
    event Unstaked(address indexed staker, uint256 tokenId);
    event RewardClaimed(address indexed staker, uint256 amount);

    constructor(
        address _nftTokenAddress,
        address _rewardTokenAddress,
        uint256 _rewardRate
    ) {
        nftToken = IERC721(_nftTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        rewardRate = _rewardRate;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(
            nftToken.ownerOf(_tokenId) == msg.sender,
            "You must be the owner of the token"
        );
        _;
    }

    modifier onlyStaker() {
        require(stakers[msg.sender].stakedTokenId != 0, "You are not a staker");
        _;
    }

    function stakeToken(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        require(
            stakers[msg.sender].stakedTokenId == 0,
            "You have already staked a token"
        );
        require(
            tokenStakers[_tokenId] == address(0),
            "Token is already staked by someone else"
        );

        nftToken.transferFrom(msg.sender, address(this), _tokenId);

        tokenStakers[_tokenId] = msg.sender;
        stakers[msg.sender] = Staker(_tokenId, block.timestamp, block.timestamp);

        emit Staked(msg.sender, _tokenId);
    }

    function unstakeToken() external onlyStaker() {
        uint256 stakedTokenId = stakers[msg.sender].stakedTokenId;

        require(
            block.timestamp >= stakers[msg.sender].stakingTime + stakingPeriod,
            "Staking period has not ended yet"
        );

        delete tokenStakers[stakedTokenId];
        delete stakers[msg.sender];

        nftToken.transferFrom(address(this), msg.sender, stakedTokenId);

        emit Unstaked(msg.sender, stakedTokenId);
    }

    function claimReward() external onlyStaker() {
        uint256 rewardAmount = calculateReward(msg.sender);

        require(rewardAmount > 0, "No rewards to claim");

        stakers[msg.sender].lastClaimTime = block.timestamp;
        rewards[msg.sender] = 0;

        rewardToken.transfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function calculateReward(address _staker)
        public
        view
        returns (uint256 rewardAmount)
    {
        Staker memory staker = stakers[_staker];
        uint256 stakedTime = block.timestamp - staker.lastClaimTime;

        if (staker.stakingTime + stakingPeriod > block.timestamp) {
            rewardAmount =
                (stakedTime * rewardRate) /
                stakingPeriod;
        } else {
            uint256 fullPeriod = block.timestamp - staker.stakingTime;
            rewardAmount =
                (fullPeriod * rewardRate) /
                stakingPeriod;
        }

        rewardAmount += rewards[_staker];

        return rewardAmount;
    }
}