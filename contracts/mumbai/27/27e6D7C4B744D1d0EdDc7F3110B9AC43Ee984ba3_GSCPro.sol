// SPDX-License-Identifier: GPLv3

import "./IERC20.sol";
import "./SafeMath.sol";

pragma solidity >=0.8.0;

contract GSCPro {
    using SafeMath for uint256;
    IERC20 public dai = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address public defualtRefer = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;
    uint256 private constant timestep = 5 minutes;
    uint256 private constant baseDivider = 10000;
    uint256 private constant registrationFee = 10e18;
    uint256 private constant directPercents = 500;
    uint256 private constant growthPercents = 2000;

    uint256[15] private registrationRewards = [5000, 1000, 700, 500, 500, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200];
    uint256[12] private communityPackages = [50e18, 1000e18, 1100e18, 2500e18, 2600e18, 5000e18, 550018, 10000e18, 10500e18, 50000e18, 50500e18, 100000e18];
    uint256[6] private communityReturns = [700, 800, 900, 1000, 1100, 1300];
    uint256[20] private bonusRewards = [2000, 1000, 1000, 1000, 1000, 700, 500, 300, 300, 300, 300, 300, 200, 200, 200, 200, 200, 200, 200, 200];
    uint256[5] public royaltyPoolPercents = [100, 100, 50, 50, 50];
    uint256[5] public PoolBusinessRequired = [1000e18, 3000e18, 10000e18, 25000e18, 50000e18];
    uint256[5] public royaltyPool;
    address public jackpotFund = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27; 
    uint256 public jackpotFundPercents = 50; 
    uint256 public poolsLastDistributed;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    uint256 public totalUsers;
    address[] public Manager;
    address[] public Coordinator;
    address[] public Director;
    address[] public DiamondDirector;
    address[] public GlobalCoordinator;
    uint256 public startTime;

    bool public SL1;
    bool public SL2;
    uint256[2] private SL = [7500, 5000];
    uint256 private SLRecover = 12000;
    uint256 public ATH;
    uint256 public SLHitFor;
    uint256 private rewardingMultiple = 3;
    uint256[8] private SLWeeklyBusiness = [700e18, 1400e18, 2100e18, 2500e18, 5000e18, 1000018, 15000e18, 25000e18];

    struct WeeklyBusiness {
        uint256 amount;
        uint256 time;
    }

    struct User {
        uint256 level;
        uint256 start;
        uint256 curPackage;
        uint256 selfDeposit;
        address referrer;
        uint256 directTeam;
        WeeklyBusiness[] weeklyBusiness;
        uint256 totalBusiness;
        uint256 totalTeam;
        uint256 curRevenue;
        uint256 totalRevenue;
    }

    struct Reward {
        uint256 registrations;
        uint256 directs;
        uint256 layerIncome;
        uint256 lastClaimed;
        uint256 statics;
        uint256[5] royalty;
        uint256 growth;
        uint256 growthDebt;
        uint256 incomeFreezed;
        uint256 incomeReleased;
    }

    mapping(address => Reward) public rewardInfo;
    mapping(address => User) public userInfo;

    constructor() {
        startTime = block.timestamp;
    }

    function register(address _ref) public {  
        require(userInfo[msg.sender].referrer == address(0), "Referrer bonded");
        require(userInfo[_ref].level > 0 || _ref == defualtRefer, "Invalid Referrer");
        dai.transferFrom(msg.sender, address(this), registrationFee);

        if(msg.sender == defualtRefer) {
            userInfo[msg.sender].referrer = address(this);
        } else {
            userInfo[msg.sender].referrer = _ref;
        }

        totalUsers = totalUsers.add(1);

        address upline = _ref;
        for(uint256 i=0; i<registrationRewards.length; i++) {
            if(upline != address(0)) {
                uint256 rewarding = _calCurRewardingMultiple(upline);
                uint256 reward = registrationFee.mul(registrationRewards[i]).div(baseDivider);
                if(userInfo[upline].curRevenue + reward > userInfo[upline].selfDeposit.mul(rewarding)) {
                    reward = (userInfo[upline].curRevenue.add(reward)).sub(userInfo[upline].selfDeposit.mul(rewarding));
                }

                if(userInfo[upline].directTeam >= i) { 
                    if(userInfo[upline].curRevenue >= userInfo[upline].selfDeposit.mul(2)) {
                        rewardInfo[upline].incomeFreezed = rewardInfo[upline].incomeFreezed.add(reward);
                    } else {
                        rewardInfo[upline].registrations = rewardInfo[upline].registrations.add(reward);
                    }
                    upline = userInfo[upline].referrer;
                }
            } else {
                break;
            }
        }

        uint256 bal = dai.balanceOf(address(this));
        if(bal > ATH) {
            ATH = bal;
        }
    }

    function updateLevel() public {
        uint256 curLevel = userInfo[msg.sender].level;
        uint256 levelNow = _calLevel(msg.sender);
        if(levelNow > curLevel) {
            userInfo[msg.sender].level = levelNow;
        }
    }

    function _calLevel(address _user) private view returns(uint256) {
        User memory user = userInfo[_user];

        if(user.directTeam >= 21 && user.totalTeam >= 10000 && user.selfDeposit >= 10000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 3000000e18);
            if(forLevel >= 3000000e18) return 9;
        } 
        if(user.directTeam >= 17 && user.totalTeam >= 6000 && user.selfDeposit >= 7000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 1200000e18);
            if(forLevel >= 1200000e18) return 8;
        }
        if(user.directTeam >= 14 && user.totalTeam >= 2000 && user.selfDeposit >= 4000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 500000e18);
            if(forLevel >= 500000e18) return 7;
        }
        if(user.directTeam >= 12 && user.totalTeam >= 1000 && user.selfDeposit >= 2000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 100000e18);
            if(forLevel >= 100000e18) return 6;
        }
        if(user.directTeam >= 10 && user.totalTeam >= 300 && user.selfDeposit >= 1000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 25000e18);
            if(forLevel >= 25000e18) return 5;
        }
        if(user.directTeam >= 7 && user.totalTeam >= 100 && user.selfDeposit >= 500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 10000e18);
            if(forLevel >= 10000e18) return 4;
        }
        if(user.directTeam >= 5 && user.totalTeam >= 30 && user.selfDeposit >= 200e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 5000e18);
            if(forLevel >= 5000e18) return 3;
        }
        if(user.directTeam >= 3 && user.totalTeam >= 10 && user.selfDeposit >= 100e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 1000e18);
            if(forLevel >= 1000e18) return 2;
        }
        if(user.curPackage >= 1) {
            return 1;
        }

        return 0;
    }

    function calBusiness(address _user, uint256 _amount) public view returns(uint256, uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 forLevel;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            User memory user = userInfo[teamUsers[_user][0][i]];
            uint256 userTotalTeam = user.totalBusiness.add(user.selfDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
            uint256 toCheck = _amount.mul(4000).div(10000);
            if(userTotalTeam > toCheck) {
                userTotalTeam = toCheck;
            }

            forLevel = forLevel.add(userTotalTeam);
        }

        uint256 otherTeam = totalTeam.sub(maxTeam);
        return (forLevel, maxTeam, otherTeam, totalTeam);
    }

    function upgrade(uint256 amount) public {
        dai.transferFrom(msg.sender, address(this), amount);
        _upgrade(msg.sender, amount);
    }

    function _upgrade(address _user, uint256 amount) private {
        User storage user = userInfo[_user];
        uint256 _prevAmount = user.selfDeposit;
        require(userInfo[_user].referrer != address(0), "register first");
        require(amount >= communityPackages[user.curPackage.mul(2)] && amount <= communityPackages[user.curPackage.mul(2).add(1)], "invalid amount");
        require(amount.mod(50e18) == 0, "amount should be in multiple of 50");
        require(user.curPackage < 6, "No more packages available");

        user.curPackage = user.curPackage.add(1);
        require(user.curRevenue >= user.selfDeposit.mul(rewardingMultiple), "cannot upgrade without 3x bonus");
        
        user.selfDeposit = amount;

        if(user.level == 1) {
            user.start = block.timestamp;
        }

        bool isNew = (user.level == 1) ? true : false ;
        _updateReferInfo(_user, amount, _prevAmount, isNew);
        uint256 _directreward = amount.mul(directPercents).div(baseDivider);
        if(userInfo[user.referrer].curRevenue >= userInfo[user.referrer].selfDeposit.mul(2)) {
            rewardInfo[user.referrer].incomeFreezed = rewardInfo[user.referrer].incomeFreezed.add(_directreward);
        } else {
            rewardInfo[user.referrer].directs = rewardInfo[user.referrer].directs.add(_directreward);
        }
        userInfo[user.referrer].totalRevenue = userInfo[user.referrer].totalRevenue.add(_directreward);
        userInfo[user.referrer].curRevenue = userInfo[user.referrer].curRevenue.add(_directreward);
        userInfo[user.referrer].directTeam = userInfo[user.referrer].directTeam.add(1);
        
        for(uint256 i=0; i<5; i++) {
            royaltyPool[i] = royaltyPool[i].add(amount.mul(royaltyPoolPercents[i]).div(baseDivider));
        }

        dai.transfer(jackpotFund, amount.mul(jackpotFundPercents).div(baseDivider));

        uint256 bal = dai.balanceOf(address(this));
        if(bal > ATH) ATH = bal;
        if(SL1 || SL2) _checkTriggering();
    }    

    function _updateReferInfo(address _user, uint256 _amount, uint256 _prevAmount, bool isNew) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<20; i++) {
            if(upline != address(0)) {
                userInfo[upline].totalBusiness = userInfo[upline].totalBusiness.add(_amount.sub(_prevAmount));  
                userInfo[upline].weeklyBusiness.push(WeeklyBusiness(_amount.sub(_prevAmount), block.timestamp));
                if(isNew){
                    userInfo[upline].totalTeam = userInfo[upline].totalTeam.add(1);
                    teamUsers[upline][i].push(_user);  
                }
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _distributeBonus(address _user, uint256 _amount, uint256 _interestInMultiples) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i=1; i<=20; i++) {
            if(upline != address(0)) {
                uint256 rewarding = _calCurRewardingMultiple(upline);
                uint256 reward = _amount.mul(bonusRewards[i-1]).div(baseDivider);

                if(userInfo[upline].curRevenue + reward > userInfo[upline].selfDeposit.mul(rewarding)) {
                    reward = (userInfo[upline].curRevenue.add(reward)).sub(userInfo[upline].selfDeposit.mul(rewarding));
                }

                bool isDistributed;
                if(userInfo[_user].selfDeposit > userInfo[upline].selfDeposit && (SL1 || SL2)) {
                    reward = userInfo[upline].selfDeposit.mul(communityReturns[userInfo[_user].curPackage.sub(1)]).div(baseDivider);
                    reward = reward.mul(bonusRewards[i-1]).div(baseDivider).mul(_interestInMultiples); 
                }

                if(i >= 2 && i <= 7) {
                    if(userInfo[upline].level >= i) {
                        isDistributed = true;
                    }
                } else if(i >= 8 && i <= 12) {
                    if(userInfo[upline].level >= 8) {
                        isDistributed = true;                        
                    }
                } else if(i >= 13 && i<= 20) {
                    if(userInfo[upline].level >= 9) {
                        isDistributed = true;                        
                    }
                } else { 
                    isDistributed = true;
                }

                if(isDistributed) {
                    if(userInfo[upline].curRevenue >= userInfo[upline].selfDeposit.mul(2)) {
                        rewardInfo[upline].incomeFreezed = rewardInfo[upline].incomeFreezed.add(reward);
                    } else {
                        rewardInfo[upline].layerIncome = rewardInfo[upline].layerIncome.add(reward);
                    }

                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    userInfo[upline].curRevenue = userInfo[upline].curRevenue.add(reward);
                }
                upline = userInfo[upline].referrer;    
            } else {
                break;
            }
        }
    }

    function claimReward() public {
        User storage user = userInfo[msg.sender];
        require(user.curRevenue < user.selfDeposit.mul(rewardingMultiple), "3x bonus completed, upgrade level to get more");
        require(user.curPackage > 0, "No Rewarding Package Purchased");

        uint256 rewarding = _calCurRewardingMultiple(msg.sender);

        require(user.curRevenue < user.selfDeposit.mul(rewarding), "cannot claim more than 3x, update level");
        require(block.timestamp.sub(rewardInfo[msg.sender].lastClaimed) >= 2 minutes, "Claimed before time");

        uint256 interest = user.selfDeposit.mul(communityReturns[user.curPackage.sub(1)]).div(baseDivider);
        uint256 interestInMultiple = block.timestamp.sub(rewardInfo[msg.sender].lastClaimed).div(2 minutes);
        if(interestInMultiple > 1) {
            interest = interest.mul(interestInMultiple);
        }
        if(user.curRevenue + interest > user.selfDeposit.mul(rewarding)) {
            interest = (user.curRevenue + interest).sub(user.selfDeposit.mul(rewarding));
        } 

        rewardInfo[msg.sender].statics = rewardInfo[msg.sender].statics.add(interest);
        rewardInfo[msg.sender].lastClaimed = block.timestamp;
        userInfo[msg.sender].curRevenue = userInfo[msg.sender].curRevenue.add(interest);

        _distributeBonus(msg.sender, interest, interestInMultiple);
    }

    function distributePoolRewards() public {
        require(block.timestamp.sub(poolsLastDistributed) > timestep, "timestep not completed");
        address[] storage users = Manager;
        uint256 usersCount;
        uint256 toCheck = 0;
        uint256 level = 4;

        for(uint256 j=0; j<5; j++) {
            for(uint256 i=0; i<users.length; i++) {
                if(userInfo[users[i]].level == level) {
                    uint256 _weeklyBusiness;
                    for(uint256 k=userInfo[users[i]].weeklyBusiness.length; k>0; k--) {
                        if(block.timestamp.sub(userInfo[users[i]].weeklyBusiness[k].time) <= 30 minutes) {
                            _weeklyBusiness = _weeklyBusiness.add(userInfo[users[i]].weeklyBusiness[k].amount);
                        } else {
                            break;
                        }
                    }
                    if(_weeklyBusiness >= PoolBusinessRequired[toCheck]) {
                        usersCount = usersCount.add(1);
                    }
                }
            }

            uint256 usersReward = royaltyPool[toCheck].div(usersCount);
            uint256 totalDistributed;
            for(uint256 i=0; i<users.length; i++) {
                if(userInfo[users[i]].level == level) {
                    uint256 _weeklyBusiness;
                    for(uint256 k=userInfo[users[i]].weeklyBusiness.length; k>0; k--) {
                        if(block.timestamp.sub(userInfo[users[i]].weeklyBusiness[k].time) <= 30 minutes) {
                            _weeklyBusiness = _weeklyBusiness.add(userInfo[users[i]].weeklyBusiness[k].amount);
                        } else {
                            break;
                        }
                    }
                    if(_weeklyBusiness >= PoolBusinessRequired[toCheck]) {
                        rewardInfo[users[i]].royalty[0] = rewardInfo[users[i]].royalty[0].add(usersReward);
                        userInfo[users[i]].totalRevenue = userInfo[users[i]].totalRevenue.add(usersReward);
                        userInfo[users[i]].curRevenue = userInfo[users[i]].curRevenue.add(usersReward);
                        totalDistributed = totalDistributed.add(usersReward);
                    }
                }
            }

            if(royaltyPool[toCheck] > totalDistributed) {
                royaltyPool[toCheck] = royaltyPool[toCheck].sub(totalDistributed);
            } else {
                royaltyPool[toCheck] = 0;
            }

            usersCount = 0;
            toCheck = toCheck.add(1);
            if(j == 0) {
                users = Coordinator;
                level = 5;
            } else if(j == 1) {
                users = Director;
                level = 7;
            } else if(j == 2) {
                users = DiamondDirector;
                level = 8;
            } else if(j == 3) {
                users = GlobalCoordinator;
                level = 9;
            }
        }

        poolsLastDistributed = block.timestamp;
    }

    function upgradeByGrowth(uint256 amount) public {
        require(userInfo[msg.sender].level >= 1, "Can only be after registeration");
        require(getCurGrowth(msg.sender) >= amount, "insufficient funds");
        _upgrade(msg.sender , amount);
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(amount);
    }

    function transferByGrowth(address _to, uint256 _amount) public {
        require(userInfo[_to].referrer != address(0), "user not registered");
        require(_amount >= 50e18 && _amount.mod(50e6) == 0, "invalid error");
        
        uint256 _curGrowth = getCurGrowth(msg.sender);
        bool isChargeable;
        if(userInfo[_to].curPackage >= 2) {
            require(_curGrowth >= _curGrowth.mul(11000e18), "insufficient funds, fee included");
            isChargeable = true;
        } else if(userInfo[_to].curPackage <= 1) {
            require(_curGrowth >= _amount, "insufficient funds");
        }

        bool isSameLine;
        address upline = userInfo[msg.sender].referrer;
        for(uint256 i=0; i<5; i++) {
            if(upline != address(0)) {
                if(upline == _to) {
                    isSameLine = true;
                    break;
                }
            } else {
                break;
            }
        }

        upline = userInfo[_to].referrer;
        for(uint256 i=0; i<50; i++) {
            if(upline != address(0) && !isSameLine) {
                if(upline == msg.sender) {
                    isSameLine = true;
                    break;
                }
            } else {
                break;
            }
            upline = userInfo[upline].referrer;
        }

        require(isSameLine == true, "cannot transfer crossline");

        rewardInfo[_to].growth = rewardInfo[_to].growth.add(_amount); 
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(_amount); 
        if(isChargeable) rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(_amount.mul(1000).div(baseDivider)); 
    }

    function withdraw() public {
        Reward storage reward = rewardInfo[msg.sender];
        uint256 totalRewards = reward.registrations.add(reward.directs).add(reward.layerIncome).add(reward.statics);
        for(uint256 i=0; i<5; i++) {
            totalRewards = totalRewards.add(reward.royalty[i]);
        }

        require(totalRewards >= 10e18, "cannot be less than 10");

        uint256 _curGrowth = getCurGrowth(msg.sender);
        reward.registrations = 0;
        reward.directs = 0;
        reward.layerIncome = 0;
        reward.statics = 0;
        for(uint256 i=0; i<5; i++) {
            reward.royalty[i] = 0;
        }

        reward.growth = reward.growth.add(_curGrowth);
        uint256 withdrawable = totalRewards.mul(8000).div(baseDivider);
        dai.transfer(msg.sender, withdrawable);
        _checkTriggering();
    }

    function getCurGrowth(address _user) public view returns(uint256) {
        Reward memory user = rewardInfo[_user];
        uint256 reward = user.registrations.add(user.directs).add(user.layerIncome).add(user.statics);
        for(uint256 i=0; i<5; i++) {
            reward = reward.add(user.royalty[i]);
        }

        return (reward.mul(growthPercents).div(baseDivider)).sub(user.growthDebt);
    }

    function _calCurRewardingMultiple(address _user) private view returns(uint256) {
        uint256 rewarding = rewardingMultiple;
        if(SL2 && userInfo[_user].level > 1) {
            uint256 _weeklyBusiness;
            for(uint256 k=userInfo[_user].weeklyBusiness.length; k>0; k--) {
                if(block.timestamp.sub(userInfo[_user].weeklyBusiness[k].time) <= 30 minutes) {
                    _weeklyBusiness = _weeklyBusiness.add(userInfo[_user].weeklyBusiness[k].amount);
                } else {
                    break;
                }
            }
            if(_weeklyBusiness > SLWeeklyBusiness[userInfo[_user].level.sub(2)]) {
                rewarding = 2;
            }
        }

        return rewarding;
    }

    function _checkTriggering() private {
        uint256 _bal = dai.balanceOf(address(this));
        if(!SL1 && _bal <= ATH.mul(SL[0]).div(baseDivider)) {
            SL1 = true;
            rewardingMultiple = 2;
        } else if(SL1 && _bal >= ATH.mul(SLRecover).div(baseDivider)) {
            SL1 = false;          
            rewardingMultiple = 3; 
        }

        if(!SL2 && _bal <= ATH.mul(SL[1]).div(baseDivider)) {
            SL2 = true;
            rewardingMultiple = 1;
        } else if(SL2 && _bal >= ATH.mul(SL[0]).div(baseDivider)) {
            SL2 = false;          
            rewardingMultiple = 2; 
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp - startTime).div(timestep);
    }

}