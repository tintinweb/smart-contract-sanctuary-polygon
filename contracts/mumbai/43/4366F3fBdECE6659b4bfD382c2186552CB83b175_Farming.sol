//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface Cake {

    function balanceOf(address owner) external view returns(uint256);

    function approve(address spender, uint256 value) external returns(bool);

    function transfer(address to, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

}

contract Farming is Ownable, ReentrancyGuard {

    IERC20 public EVCToken;

    address public cakeToken;

    uint256 public cakePlanCount;
    uint256 public totalFarmed;

    mapping(address => uint256) public stakeCount;
    mapping(address => uint256) public userCakeBalance;
    mapping(address => uint256) public userCakeClaimed;
    mapping(address => uint256[][]) public rewardDetails;
    mapping(uint256 => cakePlanDetails) public cakePlan;
    mapping(address => cakeStakeDetails) public userCakeStakedInfo;

    struct cakePlanDetails {
        uint256 planid;
        uint256 rewardBal;
        uint256 maxAprPer;
        uint256 currCount;
        uint256 perCakePrice;
    }

    struct cakeStakeDetails {
        uint256 amountDeposited;
        uint256 stakedAt;
        uint256 claimedAt;
        uint256 planid;
    }

    event CakeRewardClaimed(address indexed user, uint256 amount);
    event CakeStaked(address indexed account, uint256 amount);
    event CakeUnstaked(address indexed account, uint256 cakeAmount, uint256 EVCRewardAmount);

    //Constructor
    constructor(address _cakeToken, address _evcAddress) {
        cakeToken = _cakeToken;
        EVCToken = IERC20(_evcAddress);
    }

    //User
    function claimCakeReward() public {
        cakeStakeDetails storage stakedInfo = userCakeStakedInfo[msg.sender];
        require(stakedInfo.amountDeposited > 0, "Cannot generate the reward with no staking");
        uint256 amount = getCakeStakedReward(msg.sender);
        EVCToken.transfer(msg.sender, amount);
        stakedInfo.claimedAt = block.timestamp;
        totalFarmed += amount;
        userCakeClaimed[msg.sender] += amount;
        emit CakeRewardClaimed(msg.sender, amount);
    }

    function stakeCake() public {
        // require(_amount > 0, "Stake amount cannot be zero");
        // require(cakePlan[_planId].rewardBal > 0, "Invalid Staking Plan");
        uint256 cakeValue = Cake(cakeToken).balanceOf(msg.sender);
        require(cakeValue > 0, "Amount should be greater than zero");
        uint256 planId = 1;
        userCakeBalance[msg.sender] += cakeValue;
        stakeCount[msg.sender]++;
        userCakeStakedInfo[msg.sender] = cakeStakeDetails(userCakeBalance[msg.sender], block.timestamp, 0, planId);
        cakePlan[planId].currCount++;
        rewardDetails[msg.sender].push([cakeValue, block.timestamp]);
        Cake(cakeToken).transferFrom(msg.sender, address(this), cakeValue);
        emit CakeStaked(msg.sender, cakeValue);
    }

    function unstakeCake() public {
        cakeStakeDetails storage stakedInfo = userCakeStakedInfo[msg.sender];
        uint256 stakedCakeAmount = stakedInfo.amountDeposited;
        uint256 EVCRewardAmount = getCakeStakedReward(msg.sender);
        userCakeBalance[msg.sender] -= stakedCakeAmount;
        Cake(cakeToken).transfer(msg.sender, stakedCakeAmount);
        EVCToken.transfer(msg.sender, EVCRewardAmount);
        cakePlan[userCakeStakedInfo[msg.sender].planid].currCount -= stakeCount[msg.sender];
        totalFarmed += EVCRewardAmount;
        userCakeClaimed[msg.sender] += EVCRewardAmount;
        delete userCakeStakedInfo[msg.sender];
        delete rewardDetails[msg.sender];
        delete stakeCount[msg.sender];
        emit CakeUnstaked(msg.sender, stakedCakeAmount, EVCRewardAmount);
    }

    //View
    function getCakeApr(uint256 planId) public view returns(uint256) {
        require(cakePlan[planId].rewardBal > 0, "Invalid Staking Plan");
        uint256 perCakeShare;
        uint256 stakingBucket = cakePlan[planId].rewardBal;
        uint256 currstakeCount = cakePlan[planId].currCount == 0 ? 1 : cakePlan[planId].currCount; //avoid divisible by 0 error
        uint256 maxCakeShare = (currstakeCount * cakePlan[planId].perCakePrice * cakePlan[planId].maxAprPer) / 100;
        if (maxCakeShare < stakingBucket)
            perCakeShare = maxCakeShare / currstakeCount;
        else perCakeShare = stakingBucket / currstakeCount;
        return (perCakeShare * 100) / cakePlan[planId].perCakePrice;
    }

    function getCakeStakedReward(address _user) public view returns(uint256) {
        if (userCakeStakedInfo[_user].amountDeposited == 0) {
            return 0;
        }
        uint256 apy;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        apy = getCakeApr(userCakeStakedInfo[_user].planid);
        for (uint256 i = 0; i < rewardDetails[_user].length; i++) {
            anualReward = (rewardDetails[_user][i][0] * apy) / 100;
            perSecondReward = anualReward / (365 * 86400);
            stakeSeconds = block.timestamp - (rewardDetails[_user][i][1] > userCakeStakedInfo[_user].claimedAt ? rewardDetails[_user][i][1] : userCakeStakedInfo[_user].claimedAt);
            reward += stakeSeconds * perSecondReward;
        }
        return reward;
    }

    //Admin
    function setCakeToken(address _cakeToken) public onlyOwner {
        cakeToken = _cakeToken;
    }

    function setEVCToken(address _EVCToken) public onlyOwner {
        EVCToken = IERC20(_EVCToken);
    }

    function setCakeStakePlan(uint256 _id, uint256 _rewardBal, uint256 _maxAprPer, uint256 _perCakePrice) public onlyOwner {
        if (cakePlan[_id].maxAprPer == 0) {
            cakePlanCount++;
        }
        cakePlan[_id].planid = _id;
        cakePlan[_id].rewardBal = _rewardBal; // Staking reward bucket
        cakePlan[_id].maxAprPer = _maxAprPer;
        cakePlan[_id].perCakePrice = _perCakePrice;
    }

}