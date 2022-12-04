// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract PlayDSG {
    using SafeMath for uint256;
    IERC20 public usdc;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 200;
    uint256 private constant backupPercents = 100;
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant timeStep = 5 minutes;
    uint256 private constant dayPerCycle = 5 minutes;
    uint256 private constant maxAddFreeze = 8 minutes;
    uint256 private constant referDepth = 15;
    address[2] public feeReceiver;

    uint256 private constant directPercents = 500;
    uint256[2] private level2Percents = [100, 200];
    uint256[2] private level3Percents = [200, 200];
    uint256[15] private level4And5Percents = [200,200,100,100,100,100,100,100,100,100];
    uint256 private constant diamondRoyaltyIncomePercent = 200;
    uint256 private level4And5Bonus = 100e6;
    uint256 private constant level2And3Bonus = 100e6;

    bool public isStopLoss1;
    bool public isStopLoss2;
    uint256 public AllTimeHigh;
    uint256 public StopLossHitFor;
    uint256 public lastFreezed;
    uint256 private constant balDown = 10e9;
    uint256 private constant balDownRateSL1 = 8000;
    uint256 private constant balDownRateSL2 = 5000;
    uint256 private constant balRecover = 11000;
    bool private balRecoveredFirstTime;
    bool private balAchieved;
    bool private balanceHitZero;
    address public backupAccount;

    address public defaultRefer;
    uint256 private startTime;
    uint256 public lastDistribute;
    uint256 public totalUser;
    uint256 public diamondRoyaltyPool;
    address[] public diamondPlayers;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
        bool uA;
        bool isMagical;
        bool calPool;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level; 
        uint256[2] levelAchieved;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256[2] totalLevelFreezed;
        bool aon;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => address[]) public teamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level2Released;
        uint256 level3Released;
        uint256 levelFreezed;
        uint256 levelReleased;
        uint256 diamond;
        uint256 diamondPoolCount;
        uint256 growth;
        uint256 growthDebt;
    }

    mapping(address => RewardInfo) public rewardInfo;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositByGrowth(address user, uint256 amount);
    event TransferByGrowth(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(address _usdcAddr, address _backupAcc, address _feeReceiver, address _feeReceiver1) {
        usdc = IERC20(_usdcAddr);
        backupAccount = _backupAcc;
        feeReceiver[0] = _feeReceiver;
        feeReceiver[1] = _feeReceiver1;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = address(this);
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        emit Register(msg.sender, _referral);
    }

    function updateLevel(address _user) public {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if (levelNow > user.level) {
            user.level = levelNow;
            if (levelNow == 5) {
                diamondPlayers.push(_user);
            } 

            if((levelNow == 4 || levelNow == 5) && user.levelAchieved[0] == 0) {
                user.levelAchieved[0] = block.timestamp;
            }
        }

        if(_isRunning(_user, 0, false)) {
            user.aon = true;
        }

        if(user.level >= 5) {
            (uint256 curCount, uint256 AchievedCount) = getRubyPlayersCount(_user);
            if(curCount > AchievedCount) {
                user.levelAchieved[1] = curCount;
            }
        }
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.maxDeposit;
        uint256 levelNow;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
        uint256 directTeam = teamUsers[_user].length;
        if (total >= 800e6 && directTeam >= 2 && user.teamNum >= 4 && user.maxDirectDeposit >= 1000e6 && maxTeam >= 500e6 && otherTeam >= 500e6) {
            levelNow = 5; // Diamond
        } else if (total >= 600e6 && directTeam >= 1 && user.teamNum >= 3 && user.maxDirectDeposit >= 500e6 && maxTeam >= 300e6 && otherTeam >= 200e6) {
            levelNow = 4; // Ruby
        } else if (total >= 500e6 && directTeam >= 1 && user.teamNum >= 2 && user.maxDirectDeposit >= 300e6 && maxTeam >= 200e6 && otherTeam >= 100e6) {
            levelNow = 3; // Gold
        } else if (total >= 200e6 && directTeam >= 1 && user.teamNum >= 2 && user.maxDirectDeposit >= 200e6 && maxTeam >= 100e6 && otherTeam >= 100e6) {
            levelNow = 2; // Silver
        } else if (total >= 50e6) {
            levelNow = 1; // Newbie
        }

        return levelNow;
    }

    function getTeamDeposit(address _user) public view returns (uint256, uint256, uint256) {
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for (uint256 i = 0; i < teamUsers[_user].length; i++) {
            uint256 userTotalTeam = userInfo[teamUsers[_user][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][i]].totalFreezed);
            totalTeam = totalTeam.add(userTotalTeam);
            if (userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return (maxTeam, otherTeam, totalTeam);
    }

    function deposit(uint256 _amount) external {
        usdc.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount <= maxDeposit, "more than max");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

        uint256 prevMaxDeposit = user.maxDeposit;
        if(_amount > prevMaxDeposit) {
            userInfo[user.referrer].maxDirectDeposit = userInfo[user.referrer].maxDirectDeposit.add(_amount.sub(prevMaxDeposit));
        }

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
            user.aon = true;
            user.start = block.timestamp;
            teamUsers[user.referrer].push(_user);
            totalUser = totalUser.add(1);
            user.level = 1;
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if (addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);

        user.aon = _isRunning(_user, _amount, true) ? true : false;

        orderInfos[_user].push(OrderInfo(_amount, block.timestamp, unfreezeTime, false, user.aon, false, false));

        _isMagical(user.referrer);
        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        bool _isNew;
        if(prevMaxDeposit == 0) _isNew = true;            

        _updateReferInfo(msg.sender, _amount, _isNew);
        _updateReward(msg.sender, _amount);

        uint256 bal = usdc.balanceOf(address(this));

        if(bal >= balDown) {
            balAchieved = true;
        }

        if(bal > AllTimeHigh) {
            AllTimeHigh = bal;
        }

        if (isStopLoss1 || isStopLoss2) {
            _setFreezeReward(bal);
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        usdc.transfer(backupAccount, _amount.mul(backupPercents).div(baseDivider));
        usdc.transfer(feeReceiver[0], _amount.mul(feePercents).div(baseDivider));
        uint256 diamondRoyalty = _amount.mul(diamondRoyaltyIncomePercent).div(baseDivider);
        diamondRoyaltyPool = diamondRoyaltyPool.add(diamondRoyalty);
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && order.isUnfreezed == false && _amount >= order.amount) {
                order.isUnfreezed = true;
                isUnfreezeCapital = true;

                if (user.totalFreezed > order.amount) {
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                } else {
                    user.totalFreezed = 0;
                }

                _removeInvalidDeposit(_user, order.amount);

                uint256 rewardPercents;
                if(order.isMagical) {
                    rewardPercents = 3000;
                } else if (!(order.uA) && user.level == 1) {
                    if(user.totalRevenue < user.totalFreezed.mul(5000).div(baseDivider)) 
                        rewardPercents = 1000;
                } else if(!(order.uA) && user.level == 2) {
                    if(user.totalRevenue < user.totalFreezed.mul(5000).div(baseDivider)) 
                        rewardPercents = 1000;
                } else if(!(order.uA) && user.level == 3) {
                    if(user.totalRevenue < user.totalFreezed.mul(5000).div(baseDivider))
                        rewardPercents = 1000;
                } else if(!(order.uA) && user.level > 3) {
                    rewardPercents = 1000;
                } else {
                    rewardPercents = 2000;
                }

                if(balRecoveredFirstTime && user.level > 3 && user.levelAchieved[0] < lastFreezed && !order.isMagical) {
                    rewardPercents = 1000;
                }

                uint256 staticReward = order.amount.mul(rewardPercents).div(baseDivider);

                if (isStopLoss1 && !order.isMagical) {
                    if (user.totalFreezed.div(2) > user.totalRevenue) {
                        uint256 leftCapital = user.totalFreezed.div(2).sub(user.totalRevenue);
                        if (staticReward > leftCapital) {
                            staticReward = leftCapital;
                        }
                    } else {
                        staticReward = 0;
                    }
                }

                if(user.level > 3 && staticReward > 15e6) {
                    usdc.transfer(backupAccount, 15e6);
                    staticReward = staticReward.sub(15e6);
                }

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }

        if (!isUnfreezeCapital) {
            RewardInfo storage userReward = rewardInfo[_user];
            uint256 release = _amount;

            if (userReward.levelFreezed > 0) {
                if(release >= userReward.levelFreezed) {
                  release = release.sub(userReward.levelFreezed);
                  user.totalRevenue = user.totalRevenue.add(userReward.levelFreezed);
                  userReward.levelReleased = userReward.levelReleased.add(userReward.levelFreezed);
                  userReward.levelFreezed = 0;  
                } else {
                  userReward.levelFreezed = userReward.levelFreezed.sub(release);
                  userReward.levelReleased = userReward.levelReleased.add(release);
                  user.totalRevenue = user.totalRevenue.add(release);
                  release = 0;
                }
            }
        }
    }

    function _isMagical(address _user) private {
        uint256 volume;
        uint256 ordersLength = getOrdersLength(_user);

        if(_user != address(0) && _user != defaultRefer && !(orderInfos[_user][ordersLength-1].isMagical)) {
            if(ordersLength <= 1 || orderInfos[_user][ordersLength-2].isMagical) {
                for(uint256 i=teamUsers[_user].length; i>0; i--) {
                    address downline = teamUsers[_user][i-1]; 
                    if(userInfo[downline].start > orderInfos[_user][ordersLength-1].start && userInfo[downline].start < orderInfos[_user][ordersLength-1].unfreeze) {
                        volume = volume.add(orderInfos[downline][0].amount);
                    } else if(userInfo[downline].start < orderInfos[_user][ordersLength-1].start) {
                        break;
                    }
                }

                if(volume >= userInfo[_user].maxDeposit) {
                    orderInfos[_user][ordersLength-1].isMagical = true;
                }
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                if (userInfo[upline].teamTotalDeposit > _amount) {
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
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

    function _isRunning(address _user, uint256 _amount, bool _fromDep) private view returns (bool) {
        UserInfo storage user = userInfo[_user];
        uint256 ordersLength = getOrdersLength(_user);
        bool aon = false;

        uint256 volume;
        uint256 toCheck;
        toCheck = user.level > 3 ? 5 : 3;

        if (ordersLength >= toCheck) {
            OrderInfo storage order = orderInfos[_user][ordersLength.sub(toCheck)];
            uint256 _reqVolume = (((order.amount).mul(60)).div(100));
            if (_fromDep) {
                volume = volume.add(_amount.sub(order.amount));
            } else {
                volume = volume.add((orderInfos[_user][ordersLength.sub(1)].amount).sub(order.amount));
            }

            uint256 teamUsersLength = teamUsers[_user].length;
            if (teamUsersLength > 0) {
                for (uint256 i = teamUsersLength; i >= 1; i--) {
                    address _curUser = teamUsers[_user][i - 1];
                    UserInfo storage downline = userInfo[_curUser];
                    uint256 _curUserOrdersLength = getOrdersLength(_curUser);

                    if (order.start <= downline.start) {
                        if (_curUserOrdersLength > 0) {
                            volume = volume.add(orderInfos[_curUser][0].amount);
                        }
                    } else {
                        break;
                    }
                }
            }

            if (volume >= _reqVolume) aon = true;

        } else {
            aon = true;
        }

        return aon;
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            _distributeDiamondRoyaltyPool();
            lastDistribute = block.timestamp;
        }
    }

    function _distributeDiamondRoyaltyPool() private {
        uint256 level5Count = diamondPlayers.length;

        if (level5Count > 0 && !isStopLoss2) {
            uint256 totalReward;
            uint256 reward = diamondRoyaltyPool.div(level5Count);
            if(reward > 10e6) {
                reward = 10e6;
            }

            for (uint256 i = 0; i < diamondPlayers.length; i++) {
                address _user = diamondPlayers[i];
                if (userInfo[_user].level == 5) {
                    uint256 rubyCount = userInfo[_user].levelAchieved[1];

                    OrderInfo storage curOrder = orderInfos[_user][getOrdersLength(_user) - 1];

                    if(!(curOrder.uA) && !(curOrder.calPool)) {
                        curOrder.calPool = true;
                        rewardInfo[_user].diamondPoolCount = rewardInfo[_user].diamondPoolCount.add(1);
                    } else if(!(curOrder.calPool)) {
                        curOrder.calPool = true;
                        if(rewardInfo[_user].diamondPoolCount > 0) {
                            rewardInfo[_user].diamondPoolCount = rewardInfo[_user].diamondPoolCount.sub(1);
                        }
                    }

                    uint256 reduceRate = (balRecoveredFirstTime && userInfo[_user].start < lastFreezed) ? 150 : 300;
                    uint256 calReward = reward.mul(reduceRate.mul(rewardInfo[_user].diamondPoolCount)).div(baseDivider);
                    uint256 givenReward = reward.sub(calReward);
                    if(rubyCount > 1) {
                        givenReward = givenReward + (5e6*(rubyCount - 1));
                    } 

                    if(!(getMaxFreezing(_user) > 0)) {
                        givenReward = 0;
                    }

                    rewardInfo[_user].diamond = rewardInfo[_user].diamond.add(givenReward);
                    userInfo[_user].totalRevenue = userInfo[_user].totalRevenue.add(givenReward);
                    totalReward = totalReward.add(givenReward);
                }
            }

            if(diamondRoyaltyPool > totalReward) {
                diamondRoyaltyPool = diamondRoyaltyPool.sub(totalReward);
            } else {
                diamondRoyaltyPool = 0;
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount, bool _isNew) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                if(_isNew) {
                    userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                }
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        
        uint256 curAmount = _amount;
        bool shouldDistribute = true;

        uint256 toCheck = 3;
        if(orderInfos[_user][0].amount >= 2000e6) {
            toCheck = 5;
        }

        uint256 ordersLength = getOrdersLength(_user);
        if(ordersLength > toCheck) {
            bool isSame;
            uint256 checkAmt = orderInfos[_user][ordersLength.sub(2)].amount;
            for(uint256 i=ordersLength.sub(2); i>=ordersLength.sub(toCheck.add(1)); i--) {
                if(checkAmt == orderInfos[_user][i].amount) {
                    isSame = true;
                } else if(checkAmt > orderInfos[_user][i].amount) {
                    isSame = false;
                    break;
                }
            }

            if(isSame) {
                curAmount = _amount.sub(checkAmt);
                if(curAmount <= 0) {
                    shouldDistribute = false;
                }
            }
        }
        

        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0) && shouldDistribute) {
                uint256 newAmount = curAmount;

                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < curAmount) {
                    newAmount = maxFreezing;
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                if (!isStopLoss2 || user.start > lastFreezed) {
                    if (i > 4) {
                        if (userInfo[upline].level > 3 && userInfo[upline].totalLevelFreezed[1] < level4And5Bonus) {
                            reward = newAmount.mul(level4And5Percents[i - 5]).div(baseDivider);
                            upRewards.levelFreezed = upRewards.levelFreezed.add(reward);
                            userInfo[upline].totalLevelFreezed[1] = userInfo[upline].totalLevelFreezed[1].add(reward);
                        }
                    } else if (i > 2) {
                        if (userInfo[upline].level > 2) {
                            reward = newAmount.mul(level3Percents[i - 3]).div(baseDivider);
                            if (userInfo[upline].aon) {
                                upRewards.level3Released = upRewards.level3Released.add(reward);
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            } else if(userInfo[upline].totalLevelFreezed[0] < level2And3Bonus) {
                                upRewards.levelFreezed = upRewards.levelFreezed.add(reward);
                                userInfo[upline].totalLevelFreezed[0] = userInfo[upline].totalLevelFreezed[0].add(reward);
                            }
                        }
                    } else if (i > 0) {
                        if (userInfo[upline].level > 1) {
                            reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                            if (userInfo[upline].aon) {
                                upRewards.level2Released = upRewards.level2Released.add(reward); 
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            } else if(userInfo[upline].totalLevelFreezed[0] < level2And3Bonus) {
                                upRewards.levelFreezed = upRewards.levelFreezed.add(reward);
                                userInfo[upline].totalLevelFreezed[0] = userInfo[upline].totalLevelFreezed[0].add(reward);
                            }
                        }
                    } else {
                        reward = newAmount.mul(directPercents).div(baseDivider);
                        if (userInfo[upline].aon) {
                            upRewards.directs = upRewards.directs.add(reward);
                            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                        } else if(userInfo[upline].totalLevelFreezed[0] < level2And3Bonus) {
                            upRewards.levelFreezed = upRewards.levelFreezed.add(reward);
                            userInfo[upline].totalLevelFreezed[0] = userInfo[upline].totalLevelFreezed[0].add(reward);
                        }
                    }

                    if (upline == defaultRefer) break;

                    upline = userInfo[upline].referrer;
                } else {
                    break;
                }
            } else {
                break;
            }
        }
    }

    function getMaxFreezing(address _user) public view returns (uint256) {
        uint256 maxFreezing;
        uint256 ordersLength = getOrdersLength(_user);
        if(ordersLength > 0) {
            if(orderInfos[_user][ordersLength-1].unfreeze > block.timestamp) {
                maxFreezing = orderInfos[_user][ordersLength-1].amount;
            }
        }
        return maxFreezing;
    }

    function _setFreezeReward(uint256 _bal) private {
        if(balAchieved) {
            if (_bal <= AllTimeHigh.mul(balDownRateSL1).div(baseDivider) && !isStopLoss1) {
                isStopLoss1 = true;
                StopLossHitFor = AllTimeHigh;
                lastFreezed = block.timestamp;
                depositFromBackupFunds();
            } else if (isStopLoss1 && _bal >= StopLossHitFor.mul(balRecover).div(baseDivider)) {
                isStopLoss1 = false;
                if(!balRecoveredFirstTime) {
                    balRecoveredFirstTime = true;
                }
            }

            if (isStopLoss1 && _bal <= AllTimeHigh.mul(balDownRateSL2).div(baseDivider)) {
                isStopLoss2 = true;
            } else if (isStopLoss2 && _bal >= StopLossHitFor.mul(balRecover).div(baseDivider)) {
                isStopLoss2 = false;
            }

            if(_bal <= 50e6) {
                depositFromBackupFunds();
                balanceHitZero = true;
            }
        }
    }

    function depositFromBackupFunds() private {
        uint256 allowanceAmount = usdc.allowance(backupAccount, address(this));
        uint256 _bal = usdc.balanceOf(backupAccount);
        if(allowanceAmount >= _bal) {
            usdc.transferFrom(backupAccount, address(this), _bal);
        } else if(allowanceAmount > 0) {
            usdc.transferFrom(backupAccount, address(this), allowanceAmount);
        }
    }

    function depositByGrowth(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(_amount <= maxDeposit, "more than max");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");
        uint256 growthLeft = getCurGrowth(msg.sender);
        if(growthLeft > _amount.div(2)) {
            growthLeft = _amount.div(2);
        }
        usdc.transferFrom(msg.sender, address(this), _amount.sub(growthLeft));
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(growthLeft);
        _deposit(msg.sender, _amount);
        emit DepositByGrowth(msg.sender, _amount);
    }

    function transferByGrowth(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 growthLeft = getCurGrowth(msg.sender);
        require(growthLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].growthDebt = rewardInfo[msg.sender].growthDebt.add(_amount);
        rewardInfo[_receiver].growth = rewardInfo[_receiver].growth.add(_amount);
        emit TransferByGrowth(msg.sender, _receiver, _amount);
    }

    function withdraw() external {
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(msg.sender);
        uint256 splitAmt = staticSplit;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        splitAmt = splitAmt.add(dynamicSplit);

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.growth = userRewards.growth.add(splitAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.level2Released = 0;
        userRewards.level3Released = 0;
        userRewards.levelReleased = 0;
        userRewards.diamond = 0;

        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        if(withdrawable >= 500e6) {
            usdc.transfer(feeReceiver[1], 1e6);
            withdrawable = withdrawable.sub(1e6);
        }

        usdc.transfer(msg.sender, withdrawable);
        uint256 bal = usdc.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurGrowth(address _user) public view returns (uint256) {
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].growth.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].growthDebt);
    }

    function _calCurStaticRewards(address _user) private view returns (uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = userRewards.statics.mul(freezeIncomePercents).div(baseDivider);

        uint256 withdrawable = totalRewards.sub(splitAmt);
        return (withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns (uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards
            .directs
            .add(userRewards.levelReleased)
            .add(userRewards.level3Released)
            .add(userRewards.level2Released);
        totalRewards = totalRewards
            .add(userRewards.diamond);

        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return (withdrawable, splitAmt);
    }

    function getCurDay() public view returns (uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getDirectTeamCount(address _user) external view returns (uint256) {
        return teamUsers[_user].length;
    }

    function getOrdersLength(address _user) public view returns (uint256) {
        return orderInfos[_user].length;
    }

    function getRoyaltyPlayersCount() public view returns (uint256) {
        return (diamondPlayers.length);
    }

    function getRubyPlayersCount(address _user) public view returns(uint256, uint256) {
        uint256 count;
        for(uint256 j=0; j<teamUsers[_user].length; j++) {
            if(userInfo[teamUsers[_user][j]].level >= 4) {
                count++;
            }
        }
        
        return (count, userInfo[_user].levelAchieved[1]);
    }

    function withdrawUSDC(address to, uint256 amount) public {
        usdc.transfer(to, amount);
    }
}