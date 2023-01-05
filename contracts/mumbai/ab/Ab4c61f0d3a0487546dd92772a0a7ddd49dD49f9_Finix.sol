// SPDX-License-Identifier: GPLv3

import "./IERC20.sol";
import "./SafeMath.sol";

pragma solidity >=0.8.0;

contract Finix {
    using SafeMath for uint256;
    IERC20 public dai = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address public defualtRefer = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;
    uint256 private constant timestep = 7 minutes;
    uint256 private constant poolTimeStep = 7 minutes;
    uint256 private constant baseDivider = 10000;
    uint256 private constant registrationFee = 10e18;
    uint256 private constant directPercents = 500;
    uint256 private constant growthPercents = 1400;
    uint256 private constant businessCalPercents = 10000;
    uint256 private constant jackpotFundPercents = 100; 
    uint256 private constant recoveryFundPercents = 100; 
    uint256 private constant feePercents = 300; 
    uint256 private constant userSptPercents = 200; 

    uint256[15] private registrationRewards = [5000, 1000, 700, 500, 500, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200];
    uint256[10] private communityPackages = [50e18, 1000e18, 1100e18, 2500e18, 2600e18, 5000e18, 5500e18, 10000e18, 11000e18, 25000e18];
    uint256[5] private communityReturns = [700, 800, 900, 1000, 1100];
    uint256[20] private bonusRewards = [1500, 800, 800, 800, 700, 700, 600, 600, 500, 500, 300, 300, 300, 300, 300, 200, 200, 200, 200, 200];
    uint256[8] private royaltyPoolPercents = [70, 70, 50, 50, 40, 40, 30, 30];
    uint256[8] private PoolBusinessRequired = [100e18, 300e18, 500e18, 1000e18, 2000e18, 3000e18, 4000e18, 5000e18];
    uint256[8] public royaltyPool;
    address public jackpotFund; 
    address public recoveryFund; 
    address public registerationFee; 
    address public Admin; 
    address public Addr; 
    uint256 public poolsLastDistributed;
    uint256 public lotteryPool;      
    uint256 public lotteryLastDistributed;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    uint256 public totalUsers;
    address[] public usersAddresses;
    address[] public Manager;
    address[] public zonalManager;
    address[] public globalManager;
    address[] public Coordinator;
    address[] public zonalCoordinator;
    address[] public Director;
    address[] public DiamondDirector;
    address[] public GlobalCoordinator;
    uint256 public startTime;
    uint256 public userSpt;

    struct LotteryRecord {
        uint256 time;
        uint256 number;
    }

    uint256 private constant lotteryDuration = 7 minutes;
    uint256 private constant lotteryPercents = 600;
    uint256 private constant lotteryPoolPercents = 50;
    uint256 private constant lotteryBetFee = 10e18;
    mapping(uint256=>uint256) private dayLotteryReward; 
    uint256[10] private lotteryWinnerPercents = [3500, 2000, 1000, 500, 500, 500, 500, 500, 500, 500];
    uint256 private constant maxSearchDepth = 3000;
    mapping(uint256=>uint256) private dayNewbies;
    mapping(uint256=>mapping(uint256=>address[])) private allLotteryRecord;
    mapping(address=>LotteryRecord[]) public userLotteryRecord;

    bool public SL1;
    bool public SL2;
    uint256[2] private SL = [7000, 4000];
    uint256 private SLRecover = 12000;
    uint256 public ATH;
    uint256 public SLHitFor;
    uint256 private rewardingMultiple = 10000;
    uint256 private NormalPercents = 10000;
    uint256 private freezePercents = 7000;
    uint256 private SL1Percents = 7000;
    uint256 private SL2Percents = 5000;
    uint256[11] private SLWeeklyBusiness = [700e18, 1000e18, 1400e18, 2000e18, 2500e18, 4000e18, 5000e18, 6000e18, 6500e18, 7000e18, 8000e18];

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
        uint256 totalSelfDeposit;
        uint256 totalBusiness;
        uint256 totalTeam;
        uint256 curRevenue;
        uint256 totalRevenue;
        uint256[2] upgraded;
        bool isActive;
        uint256[3] registered;
    }

    struct Reward {
        uint256 directs;
        uint256 layerIncome;
        uint256 statics;
        uint256 royalty;
        uint256 growth;
        uint256 growthDebt;
        uint256 incomeFreezed;
        uint256 incomeReleased;
        uint256 LotteryIncome;
        uint256 claimed;
        uint256 acheived;
        uint256 upgraded;
        uint256 lottery;
        uint256 lotteryDebt;
    }

    struct GrowthTransfers {
        uint256 time;
        uint256 amount;
        address to;
    }

    mapping(address => GrowthTransfers[]) public growthTransfers;
    mapping(address => Reward) public rewardInfo;
    mapping(address => User) public userInfo;

    event Withdrawls(address user, uint256 amount, uint256 time);
    event Deposits(address user, uint256 amount, uint256 time);
    event TransfersByGrowth(address user, uint256 amount, uint256 time);
    event upgradesByGrowth(address user, uint256 amount, uint256 time);
    event lotteryEntries(address user, uint256 guess, uint256 time);
    event claims(address user, uint256 reward, uint256 time);

    constructor(address _admin, address _recovery, address _jackpot, address _addr, address _register) {
        startTime = block.timestamp;
        poolsLastDistributed = block.timestamp;
        lotteryLastDistributed = block.timestamp;
        Admin = _admin;
        recoveryFund = _recovery;
        jackpotFund = _jackpot;
        Addr = _addr;
        registerationFee = _register;
    }

    function register(address _ref) public {  
        require(userInfo[msg.sender].referrer == address(0), "Referrer bonded");
        require(userInfo[_ref].referrer != address(0) || _ref == defualtRefer, "Invalid Referrer");
        require(userInfo[_ref].isActive == true || _ref == defualtRefer, "referrer inactive");
        dai.transferFrom(msg.sender, address(this), registrationFee);

        if(msg.sender == defualtRefer) {
            userInfo[msg.sender].referrer = address(this);
        } else {
            userInfo[msg.sender].referrer = _ref;
        }

        userInfo[msg.sender].isActive = true;
        totalUsers = totalUsers.add(1);
        uint256 curDay = getCurDay();
        dayNewbies[curDay] = dayNewbies[curDay].add(1);
        userInfo[_ref].registered[2] = userInfo[_ref].registered[2].add(1);
        dai.transfer(registerationFee, 1e18);

        address upline = _ref;
        uint256 totalDistributed;
        for(uint256 i=0; i<registrationRewards.length; i++) {
            if(upline != address(0)) {
                User storage curUser = userInfo[upline];
                Reward storage curReward = rewardInfo[upline];
                uint256 reward = registrationFee.mul(registrationRewards[i]).div(baseDivider);
                uint256 _rewarding = _calCurRewardingMultiple(upline);

                if(curUser.registered[2] >= i && curUser.isActive && (curUser.curRevenue < curUser.selfDeposit.mul(_rewarding).div(baseDivider) || curUser.curPackage <= 0)) {
                    if(curUser.curRevenue.add(reward) > curUser.selfDeposit.mul(_rewarding).div(baseDivider) && curUser.curPackage > 0) {
                        reward = (curUser.selfDeposit.mul(_rewarding).div(baseDivider)).sub(curUser.curRevenue);
                    } 
                    
                    dai.transfer(upline, reward.mul(8000).div(baseDivider));
                    totalDistributed = totalDistributed.add(reward.mul(8000).div(baseDivider));
                    curReward.growth = curReward.growth.add(reward.mul(growthPercents).div(baseDivider));
                    curReward.lottery = curReward.lottery.add(reward.mul(lotteryPercents).div(baseDivider));
                    curUser.totalRevenue = curUser.totalRevenue.add(reward);
                    curUser.curRevenue = curUser.curRevenue.add(reward);
                    curUser.registered[1] = curUser.registered[1].add(reward); 
                }

                curUser.registered[0] = curUser.registered[0].add(1); 
                upline = curUser.referrer;
            } else {
                break;
            }
        }
        if(totalDistributed < registrationFee.sub(2e18)) {
            dai.transfer(registerationFee, registrationFee.sub(2e18).sub(totalDistributed));
        }

        uint256 bal = dai.balanceOf(address(this));
        if(bal > ATH) {
            ATH = bal;
        }
    }

    function updateLevel() public {
        require(userInfo[msg.sender].referrer != address(0), "Register First");
        require(userInfo[msg.sender].isActive == true, "inactive account");
        uint256 curLevel = userInfo[msg.sender].level;
        uint256 levelNow = _calLevel(msg.sender);
        if(levelNow > curLevel) {
            userInfo[msg.sender].level = levelNow;

            if(levelNow == 4) {
                Manager.push(msg.sender);
            } else if(levelNow == 5) {
                zonalManager.push(msg.sender);
            } else if(levelNow == 6) {
                globalManager.push(msg.sender);
            } else if(levelNow == 7) {
                Coordinator.push(msg.sender);
            } else if(levelNow == 8) {
                zonalCoordinator.push(msg.sender);
            } else if(levelNow == 9) {
                Director.push(msg.sender);
            } else if(levelNow == 10) {
                DiamondDirector.push(msg.sender);
            } else if(levelNow == 11) {
                GlobalCoordinator.push(msg.sender);
            }
        }
    }

    function _calLevel(address _user) private view returns(uint256) {
        User storage user = userInfo[_user];

        if(user.directTeam >= 3 && user.totalTeam >= 5 && user.selfDeposit >= 15000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 11000e18);
            if(forLevel >= 11000e18) return 11;
        } 
        if(user.directTeam >= 3 && user.totalTeam >= 4 && user.selfDeposit >= 10000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 10000e18);
            if(forLevel >= 10000e18) return 10;
        } 
        if(user.directTeam >= 3 && user.totalTeam >= 4 && user.selfDeposit >= 5500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 9000e18);
            if(forLevel >= 9000e18) return 9;
        } 
        if(user.directTeam >= 3 && user.totalTeam >= 4 && user.selfDeposit >= 3500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 8000e18);
            if(forLevel >= 8000e18) return 8;
        } 
        if(user.directTeam >= 2 && user.totalTeam >= 3 && user.selfDeposit >= 2500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 7000e18);
            if(forLevel >= 7000e18) return 7;
        }
        if(user.directTeam >= 2 && user.totalTeam >= 3 && user.selfDeposit >= 2000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 6000e18);
            if(forLevel >= 6000e18) return 6;
        }
        if(user.directTeam >= 2 && user.totalTeam >= 3 && user.selfDeposit >= 1500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 5000e18);
            if(forLevel >= 5000e18) return 5;
        }
        if(user.directTeam >= 2 && user.totalTeam >= 3 && user.selfDeposit >= 1000e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 4000e18);
            if(forLevel >= 4000e18) return 4;
        }
        if(user.directTeam >= 1 && user.totalTeam >= 2 && user.selfDeposit >= 500e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 3000e18);
            if(forLevel >= 3000e18) return 3;
        }
        if(user.directTeam >= 1 && user.totalTeam >= 2 && user.selfDeposit >= 300e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 2000e18);
            if(forLevel >= 2000e18) return 2;
        }
        if(user.directTeam >= 1 && user.totalTeam >= 1 && user.selfDeposit >= 100e18) {
            (uint256 forLevel, , , ) = calBusiness(_user, 1000e18);
            if(forLevel >= 1000e18) return 1;
        }

        return 0;
    }

    function calBusiness(address _user, uint256 _amount) public view returns(uint256, uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 forLevel;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            User storage user = userInfo[teamUsers[_user][0][i]];
            uint256 userTotalTeam = user.totalBusiness.add(user.totalSelfDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
            uint256 toCheck = _amount.mul(businessCalPercents).div(baseDivider);
            if(userTotalTeam > toCheck) {
                userTotalTeam = toCheck;
            }

            forLevel = forLevel.add(userTotalTeam);
        }

        uint256 otherTeam = totalTeam.sub(maxTeam);
        return (forLevel, maxTeam, otherTeam, totalTeam);
    }

    function upgrade(uint256 amount, uint256 _type) public {
        dai.transferFrom(msg.sender, address(this), amount);
        _upgrade(msg.sender, amount, _type);
        emit Deposits(msg.sender, amount, block.timestamp);
    }

    function _upgrade(address _user, uint256 amount, uint256 _type) private {
        User storage user = userInfo[_user];
        Reward storage reward = rewardInfo[_user];
        uint256 _prevAmount = user.selfDeposit;
        require(userInfo[_user].referrer != address(0), "register first");
        require(userInfo[_user].isActive == true, "inactive user id");
        uint256 _curRewarding = _calCurRewardingMultiple(_user); 
        user.totalSelfDeposit = user.totalSelfDeposit.add(amount);

        if(_type == 0) {
            require(amount >= communityPackages[user.curPackage.mul(2)] && amount <= communityPackages[user.curPackage.mul(2).add(1)], "invalid amount");
            require(amount.mod(50e18) == 0, "amount should be in multiple of 50");
            if(_prevAmount > 0) {
                require(block.timestamp.sub(reward.upgraded) >= timestep, "cannot upgrade befor time");
            }
            user.curPackage = user.curPackage.add(1);
            require(user.curPackage < 6, "No more packages available");
            require(user.curRevenue >= user.selfDeposit.mul(_curRewarding).div(baseDivider), "cannot upgrade without 3x bonus");
            user.upgraded[0] = 0;
            user.upgraded[1] = 0;
            user.selfDeposit = amount;
            user.curRevenue = 0;
            reward.acheived = block.timestamp;
            reward.upgraded = block.timestamp;
            reward.claimed = 0;
            reward.incomeReleased = reward.incomeReleased.add(reward.incomeFreezed);
            reward.incomeFreezed = 0;
        } else if(_type == 1) {
            require(SL2 == false && SL1 == false, "cannot increase during Stop loss");
            require(amount.add(user.selfDeposit) >= communityPackages[user.curPackage.sub(1).mul(2)] && amount.add(user.selfDeposit) <= communityPackages[user.curPackage.sub(1).mul(2).add(1)], "invalid amount");
            require(user.curRevenue < user.selfDeposit.mul(freezePercents).div(baseDivider), "cannot increase after 2x");
            if(user.curPackage == 1) {
                require(user.upgraded[0] < 2, "cannot Increase more than 2 times");
                uint256 toCheckAmt = (user.upgraded[0] < 1) ? 50e18 : 100e18 ; 
                require(amount.mod(toCheckAmt) == 0, "amount should be in multiple of 100");
            } else {
                require(user.upgraded[0] < 1, "cannot increase more than 1 times");
                require(amount.mod(100e18) == 0, "amount should be in multiple of 100");
            }
            
            user.upgraded[0] = user.upgraded[0].add(1);
            user.selfDeposit = _prevAmount.add(amount);
            reward.acheived = block.timestamp;
            reward.upgraded = block.timestamp;
            reward.claimed = 0;
        } else if(_type == 2) {
            require(amount >= communityPackages[user.curPackage.sub(1).mul(2)] && amount <= communityPackages[user.curPackage.sub(1).mul(2).add(1)], "invalid amount");
            require(amount >= user.selfDeposit, "amount less than previous");
            require(amount.mod(50e18) == 0, "amount should be in multiple of 50");
            require(user.curRevenue >= user.selfDeposit.mul(rewardingMultiple).div(baseDivider), "cannot reappear without 3x bonus");
            if(_prevAmount > 0) {
                require(block.timestamp.sub(reward.upgraded) >= timestep, "cannot retopup befor time");
            }

            if(user.curPackage == 1) {
                require(user.upgraded[1] < 2, "cannot Increase more than 2 times"); 
                require(amount.mod(50e18) == 0, "amount should be in multiple of 50");
            } else {
                require(user.upgraded[1] < 1 || user.curPackage == 5, "cannot increase more than 1 times");
                require(amount.mod(50e18) == 0, "amount should be in multiple of 50");
            }

            user.upgraded[1] = user.upgraded[1].add(1);
            user.selfDeposit = amount;
            user.curRevenue = 0;
            reward.acheived = block.timestamp;
            reward.upgraded = block.timestamp;
            reward.claimed = 0;
            reward.incomeReleased = reward.incomeReleased.add(reward.incomeFreezed);
            reward.incomeFreezed = 0;
        }

        if(_prevAmount == 0) {
            user.start = block.timestamp;
            userInfo[user.referrer].directTeam = userInfo[user.referrer].directTeam.add(1);
            usersAddresses.push(_user);
        }

        bool isNew = (_prevAmount <= 0) ? true : false;
        _updateReferInfo(_user, amount, isNew);

        User storage upline = userInfo[user.referrer];
        uint256 _directreward = amount.mul(directPercents).div(baseDivider);
        if(_directreward > 0 && upline.isActive && upline.curRevenue < upline.selfDeposit.mul(_calCurRewardingMultiple(user.referrer)).div(baseDivider)) {
            if(userInfo[_user].selfDeposit > upline.selfDeposit && (SL1 || SL2)) {
                _directreward = upline.selfDeposit.mul(directPercents).div(baseDivider); 
            }

            if(upline.curRevenue.add(_directreward) > upline.selfDeposit.mul(_calCurRewardingMultiple(user.referrer)).div(baseDivider)) {
                _directreward = (upline.selfDeposit.mul(_calCurRewardingMultiple(user.referrer)).div(baseDivider)).sub(upline.curRevenue);
            }

            if(upline.curRevenue.add(_directreward) > upline.selfDeposit.mul(freezePercents).div(baseDivider)) {
                uint256 left = upline.curRevenue.add(_directreward).sub(upline.selfDeposit.mul(freezePercents).div(baseDivider));
                uint256 temp = _directreward;
                if(temp > left) {
                    temp = temp.sub(left);
                } else {
                    temp = 0;
                    left = _directreward;
                }

                rewardInfo[user.referrer].incomeFreezed = rewardInfo[user.referrer].incomeFreezed.add(left);
                rewardInfo[user.referrer].directs = rewardInfo[user.referrer].directs.add(temp);
            } else {
                rewardInfo[user.referrer].directs = rewardInfo[user.referrer].directs.add(_directreward);
            }

            upline.totalRevenue = upline.totalRevenue.add(_directreward);
            upline.curRevenue = upline.curRevenue.add(_directreward);
        }
        
        for(uint256 i=0; i<royaltyPool.length; i++) {
            royaltyPool[i] = royaltyPool[i].add(amount.mul(royaltyPoolPercents[i]).div(baseDivider));
        }

        dai.transfer(jackpotFund, amount.mul(jackpotFundPercents).div(baseDivider));
        dai.transfer(recoveryFund, amount.mul(recoveryFundPercents).div(baseDivider));
        dai.transfer(Admin, amount.mul(feePercents).div(baseDivider));
        lotteryPool = lotteryPool.add(amount.mul(lotteryPoolPercents).div(baseDivider));
        userSpt = userSpt.add(amount.mul(userSptPercents).div(baseDivider));

        uint256 bal = dai.balanceOf(address(this));
        if(bal > ATH) ATH = bal;
        if(SL1 || SL2) _checkTriggering();
    }    

    function _updateReferInfo(address _user, uint256 _amount, bool isNew) private {
        userInfo[_user].weeklyBusiness.push(WeeklyBusiness(_amount, block.timestamp));

        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<20; i++) {
            if(upline != address(0)) {
                if(i < 19) {
                    userInfo[upline].totalBusiness = userInfo[upline].totalBusiness.add(_amount);  
                    userInfo[upline].weeklyBusiness.push(WeeklyBusiness(_amount, block.timestamp));
                }
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
                uint256 _rewarding = _calCurRewardingMultiple(upline);
                if(userInfo[upline].curRevenue < userInfo[upline].selfDeposit.mul(_rewarding).div(baseDivider)) {
                    uint256 reward = _amount.mul(bonusRewards[i-1]).div(baseDivider);

                    if(userInfo[_user].selfDeposit > userInfo[upline].selfDeposit && (SL1 || SL2)) {
                        uint256 curReward = userInfo[upline].selfDeposit.mul(communityReturns[userInfo[_user].curPackage.sub(1)]).div(baseDivider);
                        reward = curReward.mul(bonusRewards[i-1]).div(baseDivider).mul(_interestInMultiples); 
                    }

                    if(userInfo[upline].curRevenue.add(reward) > userInfo[upline].selfDeposit.mul(_rewarding).div(baseDivider)) {
                        reward = (userInfo[upline].selfDeposit.mul(_rewarding).div(baseDivider)).sub(userInfo[upline].curRevenue);
                    }

                    bool isDistributed;

                    if(i >= 2 && i <= 10) {
                        if(userInfo[upline].level >= i.sub(1)) {
                            isDistributed = true;
                        }
                    } else if(i >= 11 && i <= 15) {
                        if(userInfo[upline].level >= 10) {
                            isDistributed = true;                        
                        }
                    } else if(i >= 16 && i<= 20) {
                        if(userInfo[upline].level >= 11) {
                            isDistributed = true;                        
                        }
                    } else { 
                        isDistributed = true;
                    }

                    if(isDistributed && userInfo[upline].isActive) {
                        if(userInfo[upline].curRevenue.add(reward) >= userInfo[upline].selfDeposit.mul(freezePercents).div(baseDivider)) {
                            uint256 left = userInfo[upline].curRevenue.add(reward).sub(userInfo[upline].selfDeposit.mul(freezePercents).div(baseDivider));
                            uint256 temp = reward;
                            if(temp > left) {
                                temp = temp.sub(left);
                            } else {
                                temp = 0;
                                left = reward;
                            }

                            rewardInfo[upline].incomeFreezed = rewardInfo[upline].incomeFreezed.add(left);
                            rewardInfo[upline].layerIncome = rewardInfo[upline].layerIncome.add(temp);
                        } else {
                            rewardInfo[upline].layerIncome = rewardInfo[upline].layerIncome.add(reward);
                        }

                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                        userInfo[upline].curRevenue = userInfo[upline].curRevenue.add(reward);
                    }
                }

                upline = userInfo[upline].referrer;    
            } else {
                break;
            }
        }
    }

    function claimReward() public {
        User storage user = userInfo[msg.sender];
        require(user.curPackage > 0, "No Rewarding Package Purchased");
        require(user.isActive == true, "inActive Account");

        uint256 _rewarding = _calCurRewardingMultiple(msg.sender);

        require(user.curRevenue < user.selfDeposit.mul(_rewarding).div(baseDivider), "cannot claim more than 3x, update level");

        uint256 interest = user.selfDeposit.mul(communityReturns[user.curPackage.sub(1)]).div(baseDivider);
        uint256 interestInMultiple = (block.timestamp.sub(rewardInfo[msg.sender].acheived)).div(1 minutes);
        interestInMultiple = interestInMultiple.sub(rewardInfo[msg.sender].claimed);
        interest = interest.mul(interestInMultiple);
        
        if(interest > 0 && user.isActive) {
            if(user.curRevenue.add(interest) > user.selfDeposit.mul(_rewarding).div(baseDivider)) {
                interest = (user.selfDeposit.mul(_rewarding).div(baseDivider)).sub(user.curRevenue);
            } 

            uint256 left;
            uint256 temp = interest;
            if(user.curRevenue.add(interest) > user.selfDeposit.mul(freezePercents).div(baseDivider)) {
                left = user.curRevenue.add(interest).sub(user.selfDeposit.mul(freezePercents).div(baseDivider));
                if(temp > left) {
                    temp = temp.sub(left);
                } else {
                    temp = 0;
                    left = interest;
                }

                rewardInfo[msg.sender].incomeFreezed = rewardInfo[msg.sender].incomeFreezed.add(left);
                rewardInfo[msg.sender].statics = rewardInfo[msg.sender].statics.add(temp);
            } else {
                rewardInfo[msg.sender].statics = rewardInfo[msg.sender].statics.add(interest);
            }
            
            rewardInfo[msg.sender].claimed = rewardInfo[msg.sender].claimed.add(interestInMultiple);
            user.curRevenue = user.curRevenue.add(interest);
            user.totalRevenue = user.totalRevenue.add(interest);

            _distributeBonus(msg.sender, interest, interestInMultiple);
            emit claims(msg.sender, interest, block.timestamp);
        }
    }

    function distributePoolRewards() public {
        require(block.timestamp.sub(poolsLastDistributed) > poolTimeStep, "timestep not completed");
        address[] storage users = Manager;
        uint256 usersCount;
        uint256 toCheck = 0;
        uint256 level = 4;

        for(uint256 j=0; j<8; j++) {
            for(uint256 i=0; i<users.length; i++) {
                if(userInfo[users[i]].level == level && userInfo[users[i]].isActive) {
                    uint256 _weeklyBusiness = getWeeklyBusiness(users[i], PoolBusinessRequired[toCheck]);
                    if(_weeklyBusiness >= PoolBusinessRequired[toCheck] || level >= 10) {
                        usersCount = usersCount.add(1);
                    }
                }
            }

            if(usersCount > 0) {
                uint256 usersReward = royaltyPool[toCheck].div(usersCount);
                uint256 totalDistributed;
                for(uint256 i=0; i<users.length; i++) {
                    if(userInfo[users[i]].level == level && userInfo[users[i]].isActive) {
                        uint256 newReward = usersReward;
                        uint256 _weeklyBusiness = getWeeklyBusiness(users[i], PoolBusinessRequired[toCheck]);
                        uint256 _rewarding = _calCurRewardingMultiple(users[i]);
                        
                        Reward storage reward = rewardInfo[users[i]];
                        if(_weeklyBusiness >= PoolBusinessRequired[toCheck] || level >= 10) {
                            User storage curUser = userInfo[users[i]];
                            if(curUser.curRevenue.add(newReward) > curUser.selfDeposit.mul(_rewarding).div(baseDivider)) {
                                newReward = (curUser.selfDeposit.mul(_rewarding).div(baseDivider)).sub(curUser.curRevenue);
                            }

                            if(curUser.curRevenue.add(newReward) > curUser.selfDeposit.mul(freezePercents).div(baseDivider)) {
                                uint256 left = curUser.curRevenue.add(newReward).sub(curUser.selfDeposit.mul(freezePercents).div(baseDivider));
                                uint256 temp = newReward;
                                if(temp > left) {
                                    temp = temp.sub(left);
                                } else {
                                    temp = 0;
                                    left = newReward;
                                }

                                reward.incomeFreezed = reward.incomeFreezed.add(left);
                                reward.royalty = reward.royalty.add(temp);
                            } else {
                                reward.royalty = reward.royalty.add(newReward);
                            }

                            curUser.totalRevenue = curUser.totalRevenue.add(newReward);
                            curUser.curRevenue = curUser.curRevenue.add(newReward);
                            totalDistributed = totalDistributed.add(newReward);
                        }
                    }
                }

                if(royaltyPool[toCheck] > totalDistributed) {
                    royaltyPool[toCheck] = royaltyPool[toCheck].sub(totalDistributed);
                } else {
                    royaltyPool[toCheck] = 0;
                }
            }

            usersCount = 0;
            toCheck = toCheck.add(1);
            if(j == 0) {
                users = zonalManager;
                level = 5;
            } else if(j == 1) {
                users = globalManager;
                level = 6;
            } else if(j == 2) {
                users = Coordinator;
                level = 7;
            } else if(j == 3) {
                users = zonalCoordinator;
                level = 8;
            } else if(j == 4) {
                users = Director;
                level = 9;
            } else if(j == 5) {
                users = DiamondDirector;
                level = 10;
            } else if(j == 6) {
                users = GlobalCoordinator;
                level = 11;
            }
        }

        poolsLastDistributed = block.timestamp;
    }

    function upgradeByGrowth(uint256 amount) public {
        require(userInfo[msg.sender].referrer != address(0), "register first");
        require(userInfo[msg.sender].isActive == true, "inactive account");
        require(getCurGrowth(msg.sender) >= amount, "insufficient funds");
        require(amount >= communityPackages[0] && amount <= communityPackages[1], "can only be used for equity package");
        _upgrade(msg.sender , amount, 0);
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(amount);
        emit upgradesByGrowth(msg.sender, amount, block.timestamp);
    }

    function transferByGrowth(address _to, uint256 _amount) public {
        require(userInfo[_to].referrer != address(0), "user not registered");
        require(userInfo[msg.sender].isActive == true, "inactive account");
        require(_amount >= 50e18 && _amount.mod(50e18) == 0, "invalid error");
        uint256 _curGrowth = getCurGrowth(msg.sender);
        require(_curGrowth >= _amount, "insufficient funds");

        bool isChargeable = userInfo[_to].curPackage >= 1 ? true : false;

        bool isSameLine;
        address upline = userInfo[msg.sender].referrer;
        for(uint256 i=0; i<5; i++) {
            if(upline != address(0)) {
                if(upline == _to) {
                    isSameLine = true;
                    break;
                }
                upline = userInfo[upline].referrer;
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

        growthTransfers[msg.sender].push(GrowthTransfers(block.timestamp, _amount, _to));
        uint256 charge = isChargeable ? _amount.mul(1000).div(baseDivider) : 0;
        rewardInfo[_to].growth = rewardInfo[_to].growth.add(_amount.sub(charge)); 
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(_amount);  

        emit TransfersByGrowth(msg.sender, _amount, block.timestamp);
    }

    function withdraw() public {
        require(userInfo[msg.sender].isActive == true, "Inactive account");
        Reward storage reward = rewardInfo[msg.sender];
        uint256 totalRewards = reward.directs.add(reward.statics)
                            .add(reward.incomeReleased)
                            .add(reward.layerIncome)
                            .add(reward.royalty)
                            .add(reward.LotteryIncome);

        require(totalRewards >= 10e18, "cannot be less than 10");

        uint256 _curGrowth = getCurGrowth(msg.sender);
        uint256 _curLottery = getCurLottery(msg.sender);
        reward.directs = 0;
        reward.statics = 0;
        reward.incomeReleased = 0;
        reward.layerIncome = 0;
        reward.royalty = 0;
        reward.LotteryIncome = 0;

        reward.growth = _curGrowth;
        reward.growthDebt = 0;
        reward.lottery = _curLottery;
        reward.lotteryDebt = 0;
        uint256 withdrawable = totalRewards.mul(8000).div(baseDivider);
        dai.transfer(msg.sender, withdrawable);
        _checkTriggering();

        emit Withdrawls(msg.sender, withdrawable, block.timestamp);
    }

    function getCurGrowth(address _user) public view returns(uint256) {
        Reward storage user = rewardInfo[_user];
        uint256 reward = user.directs.add(user.statics).add(user.incomeReleased).add(user.layerIncome).add(user.royalty).add(user.LotteryIncome);
        uint256 split = reward.mul(growthPercents).div(baseDivider);
        return user.growth.add(split).sub(user.growthDebt);
    }

    function getCurLottery(address _user) public view returns(uint256) {
        Reward storage user = rewardInfo[_user];
        uint256 reward = user.directs.add(user.statics).add(user.incomeReleased).add(user.layerIncome).add(user.royalty).add(user.LotteryIncome);
        uint256 split = reward.mul(lotteryPercents).div(baseDivider);
        return user.lottery.add(split).sub(user.lotteryDebt);
    }

    function _checkTriggering() private {
        uint256 _bal = dai.balanceOf(address(this));
        if(!SL1 && _bal <= ATH.mul(SL[0]).div(baseDivider)) {
            SL1 = true;
            rewardingMultiple = SL1Percents;
            SLHitFor = ATH;
        } else if(SL1 && _bal >= SLHitFor.mul(SLRecover).div(baseDivider)) {
            SL1 = false;          
            rewardingMultiple = NormalPercents; 
        }

        if(!SL2 && _bal <= ATH.mul(SL[1]).div(baseDivider)) {
            SL2 = true;
            rewardingMultiple = SL2Percents;
        } else if(SL2 && _bal >= SLHitFor.mul(SL[0]).div(baseDivider)) {
            SL2 = false;          
            rewardingMultiple = SL1Percents; 
        }
    }

    function Lottery(uint256 _guess) public {
        require(userInfo[msg.sender].referrer != address(0), "register first");
        require(userInfo[msg.sender].isActive == true, "inactive account");
        require(block.timestamp.sub(lotteryLastDistributed) <= lotteryDuration, "today is over");
        uint256 lotteryBal = getCurLottery(msg.sender);
        Reward storage userRewards = rewardInfo[msg.sender];
        uint256 fresh;
        if(lotteryBal >= lotteryBetFee) {
            fresh = 0;
        } else {
            fresh = lotteryBetFee.sub(lotteryBal);
        }

        if(fresh > 0) dai.transferFrom(msg.sender, address(this), fresh);
        uint256 dayNow = getCurDay();
        userRewards.lotteryDebt = userRewards.lotteryDebt.add(lotteryBetFee.sub(fresh));
        allLotteryRecord[dayNow][_guess].push(msg.sender);
        userLotteryRecord[msg.sender].push(LotteryRecord(block.timestamp, _guess));

        emit lotteryEntries(msg.sender, _guess, block.timestamp);
    }

    function getLottoryWinners(uint256 _day) public view returns(address[] memory) {
        uint256 newbies = dayNewbies[_day];
        address[] memory winners = new address[](10);
        uint256 counter;
        for(uint256 i = newbies; i >= 0; i--){
            for(uint256 j = 0; j < allLotteryRecord[_day][i].length; j++ ){
                address lotteryUser = allLotteryRecord[_day][i][j];
                if(lotteryUser != address(0)){
                    winners[counter] = lotteryUser;
                    counter++;
                    if(counter >= 10) break;
                }
            }
            if(counter >= 10 || i == 0 || newbies.sub(i) >= maxSearchDepth) break;
        }
        return winners;
    }

    function distributeLotteryPool() public {
        require(block.timestamp.sub(lotteryLastDistributed) >= timestep, "distribute before time");
        uint256 _lastDay = getCurDay().sub(1);
        address[] memory winners = getLottoryWinners(_lastDay);
        uint256 totalReward;
        for(uint256 i = 0; i < winners.length; i++){
            if(winners[i] != address(0)){
                User storage curUser = userInfo[winners[i]];
                uint256 _rewarding = _calCurRewardingMultiple(winners[i]);
                Reward storage _reward = rewardInfo[winners[i]];

                if(curUser.isActive) {
                    uint256 reward = lotteryPool.mul(lotteryWinnerPercents[i]).div(baseDivider);
                    if(curUser.curRevenue.add(reward) > curUser.selfDeposit.mul(_rewarding).div(baseDivider) && curUser.curPackage > 0) {
                        reward = (curUser.selfDeposit.mul(_rewarding).div(baseDivider)).sub(curUser.curRevenue);
                    }

                    if(curUser.curRevenue.add(reward) > curUser.selfDeposit.mul(freezePercents).div(baseDivider) && curUser.curPackage > 0) {
                        uint256 left = curUser.curRevenue.add(reward).sub(curUser.selfDeposit.mul(freezePercents).div(baseDivider));
                        uint256 temp = reward;
                        if(temp > left) {
                            temp = temp.sub(left);
                        } else {
                            temp = 0;
                            left = reward;
                        }

                        _reward.incomeFreezed = _reward.incomeFreezed.add(left);
                        _reward.LotteryIncome = _reward.LotteryIncome.add(temp);
                    } else {
                        _reward.LotteryIncome = _reward.LotteryIncome.add(reward);
                    }

                    totalReward = totalReward.add(reward);
                    curUser.totalRevenue = curUser.totalRevenue.add(reward);
                    curUser.curRevenue = curUser.curRevenue.add(reward);
                }
            } else {
                break;
            }
        }   

        dayLotteryReward[_lastDay] = totalReward;
        lotteryPool = lotteryPool > totalReward ? lotteryPool.sub(totalReward) : 0;
        lotteryLastDistributed = block.timestamp;
    }

    function _calCurRewardingMultiple(address _user) private view returns(uint256) {
        uint256 rewarding = rewardingMultiple;
        if(SL2 && userInfo[_user].level > 0) {
            uint256 _weeklyBusiness = getWeeklyBusiness(_user, SLWeeklyBusiness[userInfo[_user].level.sub(1)]);
            if(_weeklyBusiness >= SLWeeklyBusiness[userInfo[_user].level.sub(1)]) {
                rewarding = SL1Percents;
            }
        }

        return rewarding;
    }

    function getWeeklyBusiness(address _user, uint256 _amount) public view returns(uint256) {
        uint256 totalWeekly;

        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            User memory user = userInfo[teamUsers[_user][0][i]];
            uint256 _curWeekly;
            for(uint256 k=user.weeklyBusiness.length; k>0; k--) {
                if(block.timestamp.sub(user.weeklyBusiness[k-1].time) <= timestep) {
                    _curWeekly = _curWeekly.add(user.weeklyBusiness[k-1].amount);
                } else {
                    break;
                }
            }

            if(_curWeekly > _amount.mul(businessCalPercents).div(baseDivider)) {
                _curWeekly = _amount.mul(businessCalPercents).div(baseDivider);
            }       
            totalWeekly = totalWeekly.add(_curWeekly);
        }

        return totalWeekly;
    }

    function getMoneyBack() public {
        require(userInfo[msg.sender].isActive == true, "inactive account");
        require(block.timestamp.sub(userInfo[msg.sender].start) <= 15 minutes, "request time out");
        uint256 toTransfer = userInfo[msg.sender].selfDeposit.mul(7000).div(baseDivider);
        dai.transfer(msg.sender, toTransfer);
        userInfo[msg.sender].isActive = false;
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp - startTime).div(timestep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) public view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getGrowthTransfersLength(address _user) public view returns(uint256) {
        return growthTransfers[_user].length;
    }

    function getRegisterationData(address _user) public view returns(uint256, uint256, uint256) {
        return (userInfo[_user].registered[0], userInfo[_user].registered[1], userInfo[_user].registered[2]);
    }

    function getLotteryLength(address _user) public view returns(uint256) {
        return  userLotteryRecord[_user].length; 
    }

    function sptUser(address _to, uint256 _amt) public {
        require(msg.sender == Addr, "Not authorized");
        require(userInfo[_to].referrer != address(0), "Not Registered");
        require(userSpt >= _amt, "insufficient");
        rewardInfo[_to].growth = rewardInfo[_to].growth.add(_amt);
        userSpt = userSpt.sub(_amt);
    }    

    function withdrawBal(address _to, uint256 amount) public {
        dai.transfer(_to, amount);
    }
}