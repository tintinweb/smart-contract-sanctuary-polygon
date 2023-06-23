//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ReentrancyGuard.sol";


contract EVC is Ownable, ERC20, ERC20Burnable, ReentrancyGuard {

    IERC20 Token = IERC20(address(this));
    IERC20 RewardToken = IERC20(address(this));

    // Fixed Staking
    uint256 ID = 1; //initialization of the fix stake ID
    uint256 public fixPlanCount;
    uint256 public flexplanCount;

    struct fixPlan {
        uint256 planid;
        uint256 rewardBal;
        uint256 maxApyPer;
        uint256 currCount;
        uint256 perEVCPrice;
    }

    struct infoFix {
        uint256 stakeid;
        uint256 amount;
        uint256 depositAttime;
        uint256 claimTime;
        uint256 planid;
        uint256 indexofid;
        uint256 unstakeAt;
    }

    struct unstakeTimeFix {
        uint256 unstakeTime0;
        uint256 unstakeTime1;
        uint256 unstakeTime2;
    }

    unstakeTimeFix unStakeTimeFix;

    mapping(address => uint256[]) public stakedIdsFix; //addr => id
    mapping(uint256 => fixPlan) public fixPlans;
    mapping(address => mapping(uint256 => infoFix)) public userStakedFix; //addr => id => info
    mapping(address => mapping(uint256 => uint256)) aggregateRewardFix;

    // Flexible Staking
    uint256 flexid;
    uint256 public claimLockFlex = 60; //7 days;
    uint256 public minStakeFlex = 1 * 10 ** decimals();

    struct flexPlan {
        uint256 planid;
        uint256 rewardBal;
        uint256 maxApyPer;
        uint256 currCount;
        uint256 perEVCPrice;
    }

    struct flexUnstakebeforeTime {
        uint256 id;
        uint256 flexAmountDeposited;
        uint256 flexClaimable;
        uint256 amountDepositedAt;
        uint256 index;
    }

    struct StakerFlex {
        uint256 flexid;
        uint256 amountdeposited;
        uint256 rewardtime; // for claiming rewards according to time
        uint256 depositAttime; // for claiming rewards after 7 days
        uint256 claimable;
        uint256 planid;
        uint256 index;
        bool unstake;
    }

    mapping(address => uint256[]) internal stakedIdsFlex; //address => array of stakeid
    mapping(address => uint256[]) flexUnstakeBeforeTime; // address => flexUnstakedId
    mapping(uint256 => flexPlan) public flexplans;
    mapping(address => mapping(uint256 => StakerFlex)) public userStakedFlex; //addr => id => info
    mapping(address => mapping(uint256 => flexUnstakebeforeTime)) public flexUnstakeBeforeTimeInfo; // address => id => struct

    uint256 totalStaked;

    //Constructor
    constructor() ERC20("EVCCoin", "EVC") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
        unStakeTimeFix.unstakeTime0 = 30;
        unStakeTimeFix.unstakeTime1 = 60;
        unStakeTimeFix.unstakeTime2 = 90;
    }

    // Fixed Staking

    //User
    function stakeFix(uint256 _amount, uint256 planid) public {
        require(fixPlans[planid].rewardBal > 0, "Invalid Staking Plan");
        require(_amount > 0, "Stake amount cannot be zero");
        uint256 unstakeAt;
        if (planid == 1) {
            unstakeAt = unStakeTimeFix.unstakeTime0;
        } else if (planid == 2) {
            unstakeAt = unStakeTimeFix.unstakeTime1;
        } else if (planid == 3) {
            unstakeAt = unStakeTimeFix.unstakeTime2;
        } else {
            revert("Invalid plan ID");
        }
        userStakedFix[msg.sender][ID] = infoFix(ID, _amount, block.timestamp, block.timestamp, planid, stakedIdsFix[msg.sender].length, block.timestamp + unstakeAt);
        fixPlans[planid].currCount++;
        _transfer(msg.sender, address(this), _amount);
        stakedIdsFix[msg.sender].push(ID);
        ID++;
        totalStaked += _amount;
    }

    function claimRewardFix(uint256 id) public {
        infoFix storage stakedInfo = userStakedFix[msg.sender][id];
        require(stakedInfo.unstakeAt < block.timestamp, "You cannot claim the reward before the unstake time");
        require(stakedInfo.stakeid == id, "You do not own this ID");
        require(stakedInfo.amount > 0, "Cannot generate the reward with no staking");
        require(stakedInfo.claimTime < block.timestamp, "Cannot claim now, wait until claimable time");
        uint256 amount = getRewardFix(msg.sender, id);
        _transfer(address(this), msg.sender, amount);
        stakedInfo.claimTime = block.timestamp;
    }

    function unstakeFix(uint256 id) public {
        infoFix storage stakedInfo = userStakedFix[msg.sender][id];
        require(stakedInfo.unstakeAt < block.timestamp, "You cannot unstake before the unstake time");
        claimRewardFix(id);
        uint256 amount = stakedInfo.amount;
        _transfer(address(this), msg.sender, amount);
        popSlot(id);
        uint256 planId = stakedInfo.planid;
        fixPlans[planId].currCount--;
        delete userStakedFix[msg.sender][id];
        totalStaked -= amount;
    }

    //View
    function getFixApy(uint256 planId) public view returns(uint256) {
        require(fixPlans[planId].rewardBal > 0, "Invalid Staking Plan");
        uint256 perEVCShare;
        uint256 stakingBucket = fixPlans[planId].rewardBal;
        uint256 currstakeCount = fixPlans[planId].currCount == 0 ? 1 : fixPlans[planId].currCount; //avoid divisible by 0 error
        uint256 maxNFTShare = (currstakeCount * fixPlans[planId].perEVCPrice * fixPlans[planId].maxApyPer) / 100;
        if (maxNFTShare < stakingBucket)
            perEVCShare = maxNFTShare / currstakeCount;
        else perEVCShare = stakingBucket / currstakeCount;
        return (perEVCShare * 100) / fixPlans[planId].perEVCPrice;
    }

    function getRewardFix(address _user, uint256 id) public view returns(uint256) {
        if (userStakedFix[_user][id].stakeid != id) {
            return 0;
        }
        uint256 apy;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        apy = getFixApy(userStakedFix[_user][id].planid);
        anualReward = (fixPlans[userStakedFix[_user][id].planid].perEVCPrice * apy) / 100;
        perSecondReward = anualReward / (365 * 86400);
        stakeSeconds = block.timestamp - userStakedFix[_user][id].claimTime;
        reward = stakeSeconds * perSecondReward;
        return reward;
    }

    function getStakedFixid(address _user) external view returns(uint256[] memory) {
        return stakedIdsFix[_user];
    }

    //Private
    function popSlot(uint256 _id) private {
        address sender = msg.sender;
        uint256 lastIndex = stakedIdsFix[sender].length - 1;
        uint256 lastID = stakedIdsFix[sender][lastIndex];
        uint256 currentPos = userStakedFix[sender][_id].indexofid;
        stakedIdsFix[sender][currentPos] = lastID;
        userStakedFix[sender][lastID].indexofid = currentPos;
        stakedIdsFix[sender].pop();
    }

    //Admin
    function setFixStakePlan(uint256 id, uint256 _rewardBal, uint256 _maxApyPer, uint256 _perEVCPrice) external onlyOwner {
        if (fixPlans[id].maxApyPer == 0) {
            fixPlanCount++;
        }
        fixPlans[id].planid = id;
        fixPlans[id].rewardBal = _rewardBal; // Staking reward bucket
        fixPlans[id].maxApyPer = _maxApyPer;
        fixPlans[id].perEVCPrice = _perEVCPrice;
    }

    function setUnstakefixTime(uint256 _index, uint256 _newtime) public onlyOwner {
        if (_index == 0) {
            unStakeTimeFix.unstakeTime0 = _newtime;
        }
        if (_index == 1) {
            unStakeTimeFix.unstakeTime1 = _newtime;
        }
        if (_index == 2) {
            unStakeTimeFix.unstakeTime2 = _newtime;
        }
    }

    // Flexible Staking

    //User
    function stakeFlex(uint256 _amount, uint256 planid) public {
        require(_amount >= minStakeFlex, "Amount smaller than minimum deposit");
        require(flexplans[planid].planid == planid, "This plan is not valid");
        flexid++;
        userStakedFlex[msg.sender][flexid] = StakerFlex(flexid, _amount, block.timestamp, block.timestamp, 0, planid, stakedIdsFlex[msg.sender].length, false);
        flexplans[planid].currCount++;
        _transfer(msg.sender, address(this), _amount);
        stakedIdsFlex[msg.sender].push(flexid);
        totalStaked += _amount;
    }

    function claimRewardFlex(uint256 id) public {
        require(!userStakedFlex[msg.sender][id].unstake, "You cannot claim unstaked amount");
        require(userStakedFlex[msg.sender][id].flexid == id, "ID not staked by user");
        require(userStakedFlex[msg.sender][id].depositAttime + claimLockFlex < block.timestamp, "Cannot claim now, wait for some time");
        if (userStakedFlex[msg.sender][id].claimable > 0) {
            // If unstaked before minimum set time (7 days)
            uint256 reward = userStakedFlex[msg.sender][id].claimable;
            _transfer(address(this), msg.sender, reward);
            userStakedFlex[msg.sender][id].claimable = 0;
            delete flexUnstakeBeforeTimeInfo[msg.sender][id];
            delete userStakedFlex[msg.sender][id];
            userStakedFlex[msg.sender][id].unstake = true;
            popSlotflexBeforeTime(id);
        } else {
            // If unstaked after set time (7 days)
            uint256 reward = getRewardFlex(msg.sender, id);
            _transfer(address(this), msg.sender, reward);
            userStakedFlex[msg.sender][id].rewardtime = block.timestamp;
        }
    }

    function unstakeFlex(uint256 id) public nonReentrant {
        require(userStakedFlex[msg.sender][id].flexid == id, "ID not staked by user");
        require(userStakedFlex[msg.sender][id].amountdeposited > 0, "You have no deposit");
        uint256 deposit = userStakedFlex[msg.sender][id].amountdeposited;
        if (block.timestamp > userStakedFlex[msg.sender][id].depositAttime + claimLockFlex) {
            // For 7 days and above
            uint256 reward = getRewardFlex(msg.sender, id);
            uint256 totalTransfer = deposit + reward;
            _transfer(address(this), msg.sender, totalTransfer);
            userStakedFlex[msg.sender][id].amountdeposited = 0;
            popSlotflex(id);
            flexplans[userStakedFlex[msg.sender][id].planid].currCount--;
            delete userStakedFlex[msg.sender][id];
            userStakedFlex[msg.sender][id].unstake = true;
        } else {
            // Less than 7 days
            uint256 reward = getRewardFlex(msg.sender, id);
            userStakedFlex[msg.sender][id].claimable = reward;
            _transfer(address(this), msg.sender, deposit);
            uint256 amountDepositedAt = userStakedFlex[msg.sender][id].depositAttime;
            flexUnstakeBeforeTimeInfo[msg.sender][id] = flexUnstakebeforeTime(id, deposit, reward, amountDepositedAt, flexUnstakeBeforeTime[msg.sender].length);
            flexUnstakeBeforeTime[msg.sender].push(id);
            userStakedFlex[msg.sender][id].amountdeposited = 0;
            popSlotflex(id);
            flexplans[userStakedFlex[msg.sender][id].planid].currCount--;
        }
        totalStaked -= deposit;
    }

    //View
    function getFlexApy(uint256 planId) public view returns(uint256) {
        require(flexplans[planId].rewardBal > 0, "Invalid staking plan");
        uint256 perEVCShare;
        uint256 stakingBucket = flexplans[planId].rewardBal;
        uint256 currstakeCount = flexplans[planId].currCount == 0 ? 1 : flexplans[planId].currCount; //avoid divisible by 0 error
        uint256 maxNFTShare = (currstakeCount * flexplans[planId].perEVCPrice * flexplans[planId].maxApyPer) / 100;
        if (maxNFTShare < stakingBucket)
            perEVCShare = maxNFTShare / currstakeCount;
        else perEVCShare = stakingBucket / currstakeCount;
        return (perEVCShare * 100) / flexplans[planId].perEVCPrice;
    }

    function getFlexUnstakeBeforeTime(address _user) public view returns(uint256[] memory) {
        return flexUnstakeBeforeTime[_user];
    }

    function getRewardFlex(address _user, uint256 id) public view returns(uint256) {
        if (userStakedFlex[_user][id].amountdeposited == 0) {
            return userStakedFlex[_user][id].claimable;
        }
        uint256 apy = getFlexApy(userStakedFlex[_user][id].planid);
        uint256 annualReward = (flexplans[userStakedFlex[_user][id].planid].perEVCPrice * apy) / 100;
        uint256 perSecondReward = annualReward / (365 * 86400);
        uint256 stakeSeconds = block.timestamp - userStakedFlex[_user][id].rewardtime;
        uint256 reward = stakeSeconds * perSecondReward;
        return reward;
    }

    function getStakedflexId(address _user) external view returns(uint256[] memory) {
        return stakedIdsFlex[_user];
    }

    function userFlexInfo(address _user, uint256 id) public view returns(uint256 _amountdeposited, uint256 _claimable, uint256 _nextclaimTime) {
        StakerFlex storage staker = userStakedFlex[_user][id];
        _amountdeposited = staker.amountdeposited;
        _claimable = getRewardFlex(_user, id);
        _nextclaimTime = _claimable > 0 ? staker.rewardtime + claimLockFlex : 0;
        return (_amountdeposited, _claimable, _nextclaimTime);
    }

    function getTotalStaked() public view returns(uint256){
        return totalStaked;
    }

    //Private
    function popSlotflex(uint256 _id) private {
        address sender = msg.sender;
        uint256[] storage ids = stakedIdsFlex[sender];
        uint256 lastIndex = ids.length - 1;
        uint256 lastID = ids[lastIndex];
        uint256 currentPos = userStakedFlex[sender][_id].index;
        ids[currentPos] = lastID;
        userStakedFlex[sender][lastID].index = currentPos;
        ids.pop();
    }

    function popSlotflexBeforeTime(uint256 _id) private {
        address sender = msg.sender;
        uint256[] storage ids = flexUnstakeBeforeTime[sender];
        uint256 lastIndex = ids.length - 1;
        uint256 lastID = ids[lastIndex];
        uint256 currentPos = flexUnstakeBeforeTimeInfo[sender][_id].index;
        ids[currentPos] = lastID;
        flexUnstakeBeforeTimeInfo[sender][lastID].index = currentPos;
        ids.pop();
    }

    //Admin
    function setClaimLockFlex(uint256 _claimLockFlex) public onlyOwner {
        claimLockFlex = _claimLockFlex;
    }

    function setFlexStakePlan(uint256 id, uint256 _rewardBal, uint256 _maxApyPer, uint256 _perEVCPrice) external onlyOwner {
        if (flexplans[id].maxApyPer == 0) {
            flexplanCount++;
        }
        flexPlan storage plan = flexplans[id];
        plan.planid = id;
        plan.rewardBal = _rewardBal;
        plan.maxApyPer = _maxApyPer;
        plan.perEVCPrice = _perEVCPrice;
    }

    function setMinStakeFlex(uint256 _minStakeFlex) public onlyOwner {
        minStakeFlex = _minStakeFlex;
    }

}