//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


//PancakeRouter interface
interface Cake {

    function approve(address spender, uint256 value) external returns(bool);

    function balanceOf(address owner) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

}

contract Farming is Ownable, ReentrancyGuard {

    IERC20 public EVCToken;

    address public cakeToken;

    uint256 public cakePlanCount;
    uint256 public totalFarmed;
    uint256 public lockTime = 60 seconds;

    uint256 stakeId;

    mapping(address => uint256[]) stakedIds;
    mapping(address => uint256) public stakeCount;
    mapping(address => uint256) public userCakeBalance;
    mapping(address => uint256) public userCakeClaimed;
    mapping(address => uint256[][]) public rewardDetails;
    mapping(uint256 => cakePlanDetails) public cakePlan;
    mapping(address => mapping(uint256 => cakeStakeDetails)) public userCakeStakedInfo;

    struct cakePlanDetails {
        uint256 planid;
        uint256 rewardBal;
        uint256 maxAprPer;
        uint256 currCount;
        uint256 perCakePrice;
    }

    struct cakeStakeDetails {
        uint256 id;
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
        uint256 amount = getCakeStakedReward(msg.sender);
        require(amount > 0, "Amount not staked");
        EVCToken.transfer(msg.sender, amount);
        for (uint256 i = 0; i < stakedIds[msg.sender].length; i++) {
            userCakeStakedInfo[msg.sender][stakedIds[msg.sender][i]].claimedAt = block.timestamp;
        }
        totalFarmed += amount;
        userCakeClaimed[msg.sender] += amount;
        emit CakeRewardClaimed(msg.sender, amount);
    }

    function claimCakeRewardById(uint256 _id) public {
        cakeStakeDetails storage stakedInfo = userCakeStakedInfo[msg.sender][_id];
        require(stakedInfo.amountDeposited > 0, "Amount not staked");
        uint256 amount = getCakeStakedRewardById(msg.sender, _id);
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
        stakeId++;
        userCakeBalance[msg.sender] += cakeValue;
        stakeCount[msg.sender]++;
        userCakeStakedInfo[msg.sender][stakeId] = cakeStakeDetails(stakeId, cakeValue, block.timestamp, 0, planId);
        stakedIds[msg.sender].push(stakeId);
        cakePlan[planId].currCount++;
        rewardDetails[msg.sender].push([cakeValue, block.timestamp]);
        Cake(cakeToken).transferFrom(msg.sender, address(this), cakeValue);
        emit CakeStaked(msg.sender, cakeValue);
    }

    function unstakeCake(uint256 _id) public {
        cakeStakeDetails storage stakedInfo = userCakeStakedInfo[msg.sender][_id];
        require(stakedInfo.amountDeposited > 0, "Invalid Id");
        require(stakedInfo.stakedAt + lockTime < block.timestamp, "Cannot unstake before Lock time");
        uint256 stakedCakeAmount = stakedInfo.amountDeposited;
        uint256 EVCRewardAmount = getCakeStakedRewardById(msg.sender, _id);
        userCakeBalance[msg.sender] -= stakedCakeAmount;
        Cake(cakeToken).transfer(msg.sender, stakedCakeAmount);
        EVCToken.transfer(msg.sender, EVCRewardAmount);
        cakePlan[userCakeStakedInfo[msg.sender][_id].planid].currCount--;
        totalFarmed += EVCRewardAmount;
        userCakeClaimed[msg.sender] += EVCRewardAmount;
        delete userCakeStakedInfo[msg.sender][_id];
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
        if (stakedIds[_user].length == 0) {
            return 0;
        }
        uint256 apy;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        apy = getCakeApr(1);
        for (uint256 i = 0; i < stakedIds[_user].length; i++) {
            anualReward = (userCakeStakedInfo[_user][stakedIds[_user][i]].amountDeposited * apy) / 100;
            perSecondReward = anualReward / (365 * 86400);
            stakeSeconds = block.timestamp - (userCakeStakedInfo[_user][stakedIds[_user][i]].stakedAt > userCakeStakedInfo[_user][stakedIds[_user][i]].claimedAt ? userCakeStakedInfo[_user][stakedIds[_user][i]].stakedAt : userCakeStakedInfo[_user][stakedIds[_user][i]].claimedAt);
            reward += stakeSeconds * perSecondReward;
        }
        return reward;
    }

    function getCakeStakedRewardById(address _user, uint256 _id) public view returns(uint256) {
        if (userCakeStakedInfo[_user][_id].amountDeposited == 0) {
            return 0;
        }
        uint256 apr = getCakeApr(userCakeStakedInfo[_user][_id].planid);
        uint256 annualReward = (userCakeStakedInfo[_user][_id].amountDeposited * apr) / 100;
        uint256 perSecondReward = annualReward / (365 * 86400);
        uint256 stakedSeconds = block.timestamp - (userCakeStakedInfo[_user][_id].stakedAt > userCakeStakedInfo[_user][_id].claimedAt ? userCakeStakedInfo[_user][_id].stakedAt : userCakeStakedInfo[_user][_id].claimedAt);
        uint256 reward = perSecondReward * stakedSeconds;
        return reward;
    }

    function getStakedIds(address _user) public view returns(uint256[] memory) {
        return stakedIds[_user];
    }

    //Admin
    function setCakeToken(address _cakeToken) public onlyOwner {
        cakeToken = _cakeToken;
    }

    function setEVCToken(address _EVCToken) public onlyOwner {
        EVCToken = IERC20(_EVCToken);
    }

    function setLockTime(uint256 _seconds) public onlyOwner {
        lockTime = _seconds;
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