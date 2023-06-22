//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ReentrancyGuard.sol";


contract EVC is Ownable, ERC20, ERC20Burnable, ReentrancyGuard {

    IERC20 Token = IERC20(address(this));
    IERC20 RewardToken = IERC20(address(this));

//
    // Fixed Staking
    uint ID = 1; //initialization of the fix stake ID
    uint256 public fixPlanCount;
    uint256 public flexplanCount;
    uint unstaketime6 = 30;
    uint unstaketime12 = 60;
    uint unstaketime24 = 90;

    struct infoFix {
        uint stakeid;
        uint amount;
        uint256 depositAttime;
        uint lastClaim;
        uint planid;
        uint indexofid;
        uint unstakeAt;
    }

    struct Plan {
        uint256 rewardBal;
        uint256 maxApyPer;
        uint256 currCount;
        uint256 perEVCPrice;
    }

    mapping(address => mapping(uint => infoFix)) public userStakedFix; //addr => id => info
    mapping(address => uint[]) public stakedIdsFix; //addr => id
    mapping(uint256 => Plan) public fixPlans;

    // Flexible Staking
    uint flexid;
    uint256 public claimLockFlex = 60; //7 days;
    uint256 public minStakeFlex = 1 * 10 ** decimals();

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

    struct flexPlan {
        uint256 planid;
        uint256 rewardBal;
        uint256 maxApyPer;
        uint256 currCount;
        uint256 perEVCPrice;
    }

    struct flexUnstakebeforeTime {
        uint id;
        uint flexAmountDeposited;
        uint flexClaimable;
        uint amountDepositedAt;
        uint index;
    }

    mapping(address => mapping(uint => StakerFlex)) public userStakedFlex; //addr => id => info
    mapping(address => uint[]) internal stakedIdsFlex; //address => array of stakeid
    mapping(uint => flexPlan) public flexplans;
    mapping(address => uint[]) flexUnstakeBeforeTime; // address => flexUnstakedId
    mapping(address => mapping(uint => flexUnstakebeforeTime)) public flexUnstakeBeforeTimeInfo; // address => id => struct

    //Constructor
    constructor() ERC20("EVCCoin", "EVC1") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }


    // Fixed Staking

    //User
    function stakeFix(uint _amount, uint planid) public {
        require(fixPlans[planid].rewardBal > 0, "Invalid Staking Plan");
        require(_amount > 0, "Stake amount cannot be zero");
        uint unstakeAt;
        if (planid == 1) {
            unstakeAt = unstaketime6;
        } else if (planid == 2) {
            unstakeAt = unstaketime12;
        } else if (planid == 3) {
            unstakeAt = unstaketime24;
        }
        userStakedFix[msg.sender][ID] = infoFix(ID, _amount, block.timestamp, 0, planid, stakedIdsFix[msg.sender].length, block.timestamp + unstakeAt);
        fixPlans[planid].currCount++;
        _transfer(msg.sender, address(this), _amount);
        stakedIdsFix[msg.sender].push(ID);
        ID++;
    }

    function claimRewardFix(uint id, address _user) public {
        require(userStakedFix[_user][id].unstakeAt < block.timestamp, "you cannot claim reward before unstaketiming");
        require(userStakedFix[msg.sender][id].stakeid == id, "You do not own this ID");
        require(userStakedFix[_user][id].amount > 0, "Can't generate the reward with no staking");
        require(userStakedFix[_user][id].lastClaim < block.timestamp, "Can't claim now, wait until claimable time.");
        uint amount = getRewardFix(id, _user);
        _transfer(address(this), _user, amount);
        userStakedFix[_user][id].lastClaim = block.timestamp;
    }

    function unstakeFix(uint id) public {
        require(userStakedFix[msg.sender][id].unstakeAt < block.timestamp, "you cannot unstake before unstaketiming");
        claimRewardFix(id, msg.sender);
        uint amount = userStakedFix[msg.sender][id].amount;
        _transfer(address(this), msg.sender, amount);
        popSlot(id);
        fixPlans[userStakedFix[msg.sender][id].planid].currCount--;
        delete userStakedFix[msg.sender][id];
    }

    //View
    function getRewardFix(uint id, address _user) public view returns(uint) {
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
        stakeSeconds = block.timestamp - userStakedFix[_user][id].lastClaim;
        reward = stakeSeconds * perSecondReward;
        return reward;
    }

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

    function getStakedFixid(address _user) external view returns(uint[] memory) {
        return stakedIdsFix[_user];
    }

    //Private
    function popSlot(uint _id) private {
        uint lastID = stakedIdsFix[msg.sender][stakedIdsFix[msg.sender].length - 1];
        uint currentPos = userStakedFix[msg.sender][_id].indexofid;
        stakedIdsFix[msg.sender][currentPos] = lastID;
        userStakedFix[msg.sender][lastID].indexofid = currentPos;
        stakedIdsFix[msg.sender].pop();
    }

    //Admin
    function setFixStakePlan(uint256 id, uint256 _rewardBal, uint256 _maxApyPer, uint256 _perEVCPrice) external onlyOwner {
        //require(_rewardBal <= erc20Token.balanceOf(address(this)),"Given reward is less then balance");
        if (fixPlans[id].maxApyPer == 0) fixPlanCount++;
        fixPlans[id].rewardBal = _rewardBal; //Staking reward bucket
        fixPlans[id].maxApyPer = _maxApyPer;
        fixPlans[id].perEVCPrice = _perEVCPrice;
    }

    function setunstakeFix6(uint256 _newtime) public onlyOwner {
        unstaketime6 = _newtime;
    }

    function setunstakeFix12(uint256 _newtime) public onlyOwner {
        unstaketime12 = _newtime;
    }

    function setunstakeFix24(uint256 _newtime) public onlyOwner {
        unstaketime24 = _newtime;
    }

    // Flexible Staking

    //User
    function stakeFlex(uint _amount, uint planid) public {
        require(_amount >= minStakeFlex, "Amount smaller than minimimum deposit");
        require(flexplans[planid].planid == planid, "this plan is not valid");
        // require(planid <= 1,"invalid staking id");
        flexid++;
        userStakedFlex[msg.sender][flexid] = StakerFlex(flexid, _amount, block.timestamp, block.timestamp, 0, planid, stakedIdsFlex[msg.sender].length, false);
        flexplans[planid].currCount++;
        _transfer(msg.sender, address(this), _amount);
        stakedIdsFlex[msg.sender].push(flexid);
    }

    function claimRewardFlex(uint id) public {
        require(userStakedFlex[msg.sender][id].unstake == false, "you cannot claim unstaked ammount");
        require(userStakedFlex[msg.sender][id].flexid == id, "id not stake by user");
        // require(flexinfo[msg.sender][id].amountdeposited > 0 ,"cannot generate reward for 0 stake");
        require(userStakedFlex[msg.sender][id].depositAttime + claimLockFlex < block.timestamp, "cannot claim now wait for some time");
        if (userStakedFlex[msg.sender][id].claimable > 0) { //if unstaked before minimum set time (7 days)
            uint reward = userStakedFlex[msg.sender][id].claimable;
            _transfer(address(this), msg.sender, reward);
            userStakedFlex[msg.sender][id].claimable = 0;
            flexUnstakeBeforeTimeInfo[msg.sender][id].flexAmountDeposited = 0;
            flexUnstakeBeforeTimeInfo[msg.sender][id].flexClaimable = 0;
            flexUnstakeBeforeTimeInfo[msg.sender][id].amountDepositedAt = 0;
            userStakedFlex[msg.sender][id].unstake = true;
            popSlotflexBeforeTime(id);
        } else { // if unstaked after set time (7 days)
            uint reward = getRewardFlex(id, msg.sender);
            _transfer(address(this), msg.sender, reward);
            userStakedFlex[msg.sender][id].rewardtime = block.timestamp;
        }
    }

    function unstakeFlex(uint id) external nonReentrant {
        require(userStakedFlex[msg.sender][id].flexid == id, "id not stake by user");
        require(userStakedFlex[msg.sender][id].amountdeposited > 0, "You have no deposit");
        if (block.timestamp > userStakedFlex[msg.sender][id].depositAttime + claimLockFlex) { //for 7days and above
            uint deposite = userStakedFlex[msg.sender][id].amountdeposited;
            uint reward = getRewardFlex(id, msg.sender);
            uint totaltransfer = deposite + reward;
            _transfer(address(this), msg.sender, totaltransfer);
            //flexinfo[msg.sender][id].rewardtime = block.timestamp;
            userStakedFlex[msg.sender][id].amountdeposited = 0;
            popSlotflex(id);
            userStakedFlex[msg.sender][id].unstake = true;
        } //less than 7 days
        else {
            uint deposite = userStakedFlex[msg.sender][id].amountdeposited;
            uint reward = getRewardFlex(id, msg.sender);
            userStakedFlex[msg.sender][id].claimable = reward;
            _transfer(address(this), msg.sender, deposite);
            uint amountDepositedAt = userStakedFlex[msg.sender][id].depositAttime;
            flexUnstakeBeforeTimeInfo[msg.sender][id] = flexUnstakebeforeTime(id, deposite, reward, amountDepositedAt, flexUnstakeBeforeTime[msg.sender].length);
            flexUnstakeBeforeTime[msg.sender].push(id);
            userStakedFlex[msg.sender][id].amountdeposited = 0;
            popSlotflex(id);
        }
        flexplans[userStakedFlex[msg.sender][id].planid].currCount--;
    }

    //View
    function getRewardFlex(uint id, address _user) public view returns(uint) {
        if (userStakedFlex[_user][id].amountdeposited == 0) {
            return userStakedFlex[_user][id].claimable;
        }
        uint256 apy;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        apy = getFlexApy(userStakedFlex[_user][id].planid);
        anualReward = (flexplans[userStakedFlex[_user][id].planid].perEVCPrice * apy) / 100;
        perSecondReward = anualReward / (365 * 86400);
        stakeSeconds = block.timestamp - userStakedFlex[_user][id].rewardtime;
        reward = stakeSeconds * perSecondReward;
        return reward;
    }

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

    function getStakedflexId(address _user) external view returns(uint[] memory) {
        return stakedIdsFlex[_user];
    }

    function getFlexUnstakeBeforeTime(address _user) public view returns(uint[] memory) {
        return flexUnstakeBeforeTime[_user];
    }

    function userFlexInfo(uint id, address _user) public view returns(uint _amountdeposited, uint _claimable, uint _nextclaimTime) {
        _amountdeposited = userStakedFlex[_user][id].amountdeposited;
        _claimable = getRewardFlex(id, _user);
        if (_claimable > 0) {
            _nextclaimTime = userStakedFlex[_user][id].rewardtime + claimLockFlex;
        } else {
            _nextclaimTime = 0;
        }
        return (_amountdeposited, _claimable, _nextclaimTime);
    }

    //Private
    function popSlotflex(uint _id) private {
        uint lastID = stakedIdsFlex[msg.sender][stakedIdsFlex[msg.sender].length - 1];
        uint currentPos = userStakedFlex[msg.sender][_id].index;
        stakedIdsFlex[msg.sender][currentPos] = lastID;
        userStakedFlex[msg.sender][lastID].index = currentPos;
        stakedIdsFlex[msg.sender].pop();
    }

    function popSlotflexBeforeTime(uint _id) private {
        uint lastID = flexUnstakeBeforeTime[msg.sender][flexUnstakeBeforeTime[msg.sender].length - 1];
        uint currentPos = flexUnstakeBeforeTimeInfo[msg.sender][_id].index;
        flexUnstakeBeforeTime[msg.sender][currentPos] = lastID;
        flexUnstakeBeforeTimeInfo[msg.sender][lastID].index = currentPos;
        flexUnstakeBeforeTime[msg.sender].pop();
    }

    //Admin
    function setFlexStakePlan(uint256 id, uint256 _rewardBal, uint256 _maxApyPer, uint256 _perEVCPrice) external onlyOwner {
        //require(_rewardBal <= erc20Token.balanceOf(address(this)),"Given reward is less then balance");
        if (flexplans[id].maxApyPer == 0) {
            flexplanCount++;
        }
        flexplans[id].planid = id;
        flexplans[id].rewardBal = _rewardBal; //Staking reward bucket
        flexplans[id].maxApyPer = _maxApyPer;
        flexplans[id].perEVCPrice = _perEVCPrice;
    }

    function setMinStakeFlex(uint256 _minStakeFlex) public onlyOwner {
        minStakeFlex = _minStakeFlex;
    }

    function setClaimLockFlex(uint256 _claimLockFlex) public onlyOwner {
        claimLockFlex = _claimLockFlex;
    }

}





///////////////////////////////////////////////////////////////////


/** For 6 months
setStakePlan
id:
1
_rewardBal:
1,20000000000000000000000000,100000000,1000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000
*/


/** For 12 months
setStakePlan
id:
2
100000000
_rewardBal:
2,40000000000000000000000000,100000000,1000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000
*/


/** For 24 months
setStakePlan
id:
3
_rewardBal:
3,80000000000000000000000000,100000000,1000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000




FLEXIBLE=>
setStakePlan
id:
1
_rewardBal:
1,60000000000000000000000000,100000000,1000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000

10000000000000000000
1000000000000000000000000
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4- owner
0xdD870fA1b7C4700F2BD7f44238821C26f7392148
0x583031D1113aD414F02576BD6afaBfb302140225
0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB
0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
*/

/** For 6 months
setStakePlan
id:
1
_rewardBal:
20000000000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000
*/


/** For 12 months
setStakePlan
id:
2
_rewardBal:
40000000000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000
*/


/** For 24 months
setStakePlan
id:
3
_rewardBal:
80000000000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000




FLEXIBLE=>
setStakePlan
id:
1
_rewardBal:
60000000000000000000000000
_maxApyPer:
100000000
_perNFTPrice:
1000000000000000000

10000000000000000000
1000000000000000000000000
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
*/