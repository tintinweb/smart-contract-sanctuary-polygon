// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract PlayDSGTest {
    using SafeMath for uint256;
    IERC20 public usdc;
    IERC20 public dsgcoin;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 300;
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant timeStep = 1 minutes;
    uint256 private constant dayPerCycle = 15 minutes;
    uint256 private dayRewardPercents = 150;
    uint256 private constant maxAddFreeze = 25 minutes;
    uint256 private constant referDepth = 20;

    uint256 private constant directPercents = 500;
    uint256[2] private level2Percents = [100, 200];
    uint256[2] private level3Percents = [200, 200];
    uint256[15] private level4And5Percents = [200,100,100,100,100,50,50,50,50,50,50,50,50,50,50];
    uint256 private constant level4And5Bonus = 800e6;

    uint256 private constant diamondRoyaltyIncomePercent = 50;
    uint256 private constant welcomeBonusIncomePercent = 20;
    uint256 private constant topPoolPercents = 20;

    uint256[6] private balDown = [50e9,30e10,100e10,500e10,1000e10,2000e10];
    uint256[6] private balDownRate = [1000, 1500, 2000, 5000, 5000, 5000];
    uint256[6] private balRecover = [60e9,50e10,150e10,500e10,1000e10,2000e10];
    mapping(uint256 => bool) public balStatus;

    address[3] public feeReceivers; // the third address fee will be used to create use cases and liquidity for DSG Coin.
    uint256 private feeReceived1;
    uint256 private feeReceived2;
    uint256 private constant maxFeeReceived1 = 100e6;
    uint256 private constant maxFeeReceived2 = 200e6;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser;
    uint256 public diamondRoyaltyPool;
    uint256 public welcomeBonus;
    uint256 public topPool;

    uint256 public tokenToDistribute = 50e18;
    uint256 private tokenLastReduced = block.timestamp;
    uint256 private constant tokenReduceRate = 5;
    uint256 private tokenDistributed = 0;

    address[] public diamondPlayers;
    address[] public welcomeBonusUsers;
    mapping(uint256 => address[3]) public dayTopUsers;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit;
    uint256 public topUserLastDistributed;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level; // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 level4And5Total;
        uint256 depositDistributed;
        bool aon;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level2Freezed;
        uint256 level2Released;
        uint256 level3Freezed;
        uint256 level3Released;
        uint256 level4And5Freezed;
        uint256 level4And5Released;
        uint256 diamond;
        uint256 bonus;
        uint256 top;
        uint256 split;
        uint256 splitDebt;
    }

    mapping(address => RewardInfo) public rewardInfo;

    bool public isFreezeReward;
    bool public isFreezeDynamicReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(
        address _usdcAddr,
        address _tokenAddr,
        address[3] memory _feeReceivers
    ) {
        usdc = IERC20(_usdcAddr);
        dsgcoin = IERC20(_tokenAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = address(this);
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;

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
        uint256 levelNow = _calLevelNow(_user);
        if (levelNow > user.level) {
            user.level = levelNow;
            if (levelNow == 5) {
                diamondPlayers.push(_user);
            }

            if (dsgcoin.balanceOf(address(this)) >= tokenToDistribute) {
                if (user.level > 1) {
                    dsgcoin.transfer(_user, tokenToDistribute);
                    tokenDistributed = tokenDistributed.add(tokenToDistribute);
                } else if ((block.timestamp - startTime) < 1 days) {
                    dsgcoin.transfer(_user, tokenToDistribute);
                    tokenDistributed = tokenDistributed.add(tokenToDistribute);
                }

                if (tokenDistributed >= 300e18 && tokenToDistribute > 1e18) {
                    tokenToDistribute = tokenToDistribute.sub(
                        tokenToDistribute.mul(tokenReduceRate).div(100)
                    );
                    tokenDistributed = 0;
                }
            }
        }
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.maxDeposit;
        uint256 levelNow;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
        uint256 directTeam = teamUsers[_user][0].length;
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
        _updatemaxdirectdepositInfo(msg.sender, _amount, prevMaxDeposit);

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
            user.aon = true;
            user.start = block.timestamp;
            _updateTeamNum(_user);
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if (user.totalDeposit == 0) {
            uint256 dayNow = topUserLastDistributed;
            _updateTopUser(user.referrer, _amount, dayNow);
        }

        if (prevMaxDeposit < maxDeposit && _amount >= maxDeposit) {
            welcomeBonusUsers.push(msg.sender);
        }

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(msg.sender);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if (addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);

        if (_isRunning(_user, _amount)) {
            user.aon = true;
        } else {
            user.aon = false;
        }

        if (_isRunning(user.referrer, _amount) && user.referrer != address(0)) {
            userInfo[user.referrer].aon = true;
        }

        orderInfos[_user].push(
            OrderInfo(_amount, block.timestamp, unfreezeTime, false)
        );

        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        distributePoolRewards();

        _updateReferInfo(msg.sender, _amount);

        _updateReward(msg.sender, _amount, prevMaxDeposit);

        uint256 bal = usdc.balanceOf(address(this));
        _balActived(bal);
        if (isFreezeReward) {
            _setFreezeReward(bal);
        }
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
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);

        if (feeReceived1 < maxFeeReceived1 && feeReceived2 < maxFeeReceived2) {
            usdc.transfer(feeReceivers[2], fee.div(3));
        } else if (feeReceived1 >= maxFeeReceived1 && feeReceived2 < maxFeeReceived2) {
            uint256 feeAfterMax = _amount.mul(150).div(baseDivider);
            usdc.transfer(feeReceivers[2], feeAfterMax);
        } else {
            uint256 feeAfterMax = _amount.mul(200).div(baseDivider);
            usdc.transfer(feeReceivers[2], feeAfterMax);
        }

        if (feeReceived1 < maxFeeReceived1) {
            usdc.transfer(feeReceivers[0], fee.div(3));
            feeReceived1 = feeReceived1.add(fee.div(3));
        }
        if (feeReceived2 < maxFeeReceived2) {
            usdc.transfer(feeReceivers[1], fee.div(3));
            feeReceived2 = feeReceived2.add(fee.div(3));
        }

        if (diamondPlayers.length > 0) {
            uint256 diamondRoyalty = _amount
                .mul(diamondRoyaltyIncomePercent)
                .div(baseDivider);
            diamondRoyaltyPool = diamondRoyaltyPool.add(diamondRoyalty);
        }

        uint256 calWelcomeBonus = _amount.mul(welcomeBonusIncomePercent).div(baseDivider);
        welcomeBonus = welcomeBonus.add(calWelcomeBonus);

        uint256 top = _amount.mul(topPoolPercents).div(baseDivider);
        topPool = topPool.add(top);
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
                if (!(user.aon)) {
                    rewardPercents = 80;
                } else {
                    rewardPercents = dayRewardPercents;
                }

                uint256 staticReward = order
                    .amount
                    .mul(rewardPercents)
                    .mul(dayPerCycle)
                    .div(timeStep)
                    .div(baseDivider);

                if (isFreezeReward) {
                    if (user.totalFreezed > user.totalRevenue) {
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if (staticReward > leftCapital) {
                            staticReward = leftCapital;
                        }
                    } else {
                        staticReward = 0;
                    }
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

            if(userReward.level2Freezed > 0) {
                if(release >= userReward.level2Freezed) {
                  release = release.sub(userReward.level2Freezed);
                  userReward.level2Released = userReward.level2Released.add(userReward.level2Freezed);
                  userReward.level2Freezed = 0;  
                } else {
                  userReward.level2Freezed = userReward.level2Freezed.sub(release);
                  userReward.level2Released = userReward.level2Released.add(release);
                  release = 0;
                }
                user.totalRevenue = user.totalRevenue.add(release);
            }

            if(userReward.level3Freezed > 0 && release > 0) {
                if(release >= userReward.level3Freezed) {
                  release = release.sub(userReward.level3Freezed);
                  userReward.level3Released = userReward.level3Released.add(userReward.level3Freezed);
                  userReward.level3Freezed = 0;  
                } else {
                  userReward.level3Freezed = userReward.level3Freezed.sub(release);
                  userReward.level3Released = userReward.level3Released.add(release);
                  release = 0;
                }
                user.totalRevenue = user.totalRevenue.add(release);
            }

            if (userReward.level4And5Freezed > 0 && release > 0) {
                if(release >= userReward.level4And5Freezed) {
                  release = release.sub(userReward.level4And5Freezed);
                  userReward.level4And5Released = userReward.level4And5Released.add(userReward.level4And5Freezed);
                  userReward.level4And5Freezed = 0;  
                } else {
                  userReward.level4And5Freezed = userReward.level4And5Freezed.sub(release);
                  userReward.level4And5Released = userReward.level4And5Released.add(release);
                  release = 0;
                }
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
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

    function _isRunning(address _user, uint256 _amount) private view returns (bool) {
        UserInfo storage user = userInfo[_user];
        uint256 ordersLength = getOrdersLength(_user);
        bool aon = false;

        uint256 volume;

        uint256 toCheck;
        if (user.level < 4) {
            toCheck = 4;
        } else if (user.level > 3) {
            toCheck = 5;
        }

        if (ordersLength >= toCheck) {
            OrderInfo storage order = orderInfos[_user][ordersLength.sub(toCheck)];
            uint256 _reqVolume = (((order.amount).mul(60)).div(100));
            if (_user == msg.sender) {
                volume = volume.add(_amount.sub(order.amount));
            } else {
                volume = volume.add((orderInfos[_user][ordersLength.sub(1)].amount).sub(order.amount));
            }

            uint256 teamUsersLength = teamUsers[_user][0].length;
            if (teamUsersLength > 0) {
                for (uint256 i = teamUsersLength; i >= 1; i--) {
                    address _curUser = teamUsers[_user][0][i - 1];
                    UserInfo storage downline = userInfo[_curUser];
                    uint256 _curUserOrdersLength = getOrdersLength(_curUser);

                    if (order.start <= downline.start) {
                        if (_curUserOrdersLength > 0) {
                            volume = volume.add(orderInfos[_curUser][0].amount);
                        } else if (_curUserOrdersLength < 1) {
                            volume = volume.add(_amount);
                        }
                    } else {
                        break;
                    }
                }
            }

            if (volume >= _reqVolume) {
                aon = true;
            }
        } else {
            aon = true;
        }

        return aon;
    }

    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow) private {
        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user].add(_amount);
        bool updated;
        for (uint256 i = 0; i < 3; i++) {
            address topUser = dayTopUsers[_dayNow][i];
            if (topUser == _user) {
                _reOrderTop(_dayNow);
                updated = true;
                break;
            }
        }
        if (!updated) {
            address lastUser = dayTopUsers[_dayNow][2];
            if (userLayer1DayDeposit[_dayNow][lastUser] < userLayer1DayDeposit[_dayNow][_user]) {
                dayTopUsers[_dayNow][2] = _user;
                _reOrderTop(_dayNow);
            }
        }
    }

    function _reOrderTop(uint256 _dayNow) private {
        for (uint256 i = 3; i > 1; i--) {
            address topUser1 = dayTopUsers[_dayNow][i - 1];
            address topUser2 = dayTopUsers[_dayNow][i - 2];
            uint256 amount1 = userLayer1DayDeposit[_dayNow][topUser1];
            uint256 amount2 = userLayer1DayDeposit[_dayNow][topUser2];
            if (amount1 > amount2) {
                dayTopUsers[_dayNow][i - 1] = topUser2;
                dayTopUsers[_dayNow][i - 2] = topUser1;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            _distributeDiamondRoyaltyPool();
            _distributeWelcomeBonus();
            _distributeTopPool();

            lastDistribute = block.timestamp;
        }
    }

    function _distributeDiamondRoyaltyPool() private {
        uint256 level5Count;
        for (uint256 i = 0; i < diamondPlayers.length; i++) {
            if (userInfo[diamondPlayers[i]].level == 5) {
                level5Count = level5Count.add(1);
            }
        }

        if (level5Count > 0) {
            uint256 reward = diamondRoyaltyPool.div(level5Count);
            uint256 totalReward;
            for (uint256 i = 0; i < diamondPlayers.length; i++) {
                if (userInfo[diamondPlayers[i]].level == 5) {
                    if (!isFreezeDynamicReward || userInfo[diamondPlayers[i]].totalRevenue < (getMaxFreezing(diamondPlayers[i])).add(((getMaxFreezing(diamondPlayers[i])).mul(5000)).div(baseDivider))) {
                        rewardInfo[diamondPlayers[i]].diamond = rewardInfo[diamondPlayers[i]].diamond.add(reward);
                        userInfo[diamondPlayers[i]].totalRevenue = userInfo[diamondPlayers[i]].totalRevenue.add(reward);
                        totalReward = totalReward.add(reward);
                    }
                }
            }
            if (diamondRoyaltyPool > totalReward) {
                diamondRoyaltyPool = diamondRoyaltyPool.sub(totalReward);
            } else {
                diamondRoyaltyPool = 0;
            }
        }
    }

    function _distributeWelcomeBonus() private {
        if (welcomeBonusUsers.length > 0) {
            uint256 reward = welcomeBonus.div(welcomeBonusUsers.length);
            if (reward > 100e6) {
                reward = 100e6;
            }
            uint256 totalReward;
            for (uint256 i = 0; i < welcomeBonusUsers.length; i++) {
                if (!isFreezeDynamicReward || userInfo[welcomeBonusUsers[i]].totalRevenue < (getMaxFreezing(welcomeBonusUsers[i])).add(((getMaxFreezing(welcomeBonusUsers[i])).mul(5000)).div(baseDivider))) {
                    rewardInfo[welcomeBonusUsers[i]].bonus = rewardInfo[welcomeBonusUsers[i]].bonus.add(reward);
                    userInfo[welcomeBonusUsers[i]].totalRevenue = userInfo[welcomeBonusUsers[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }

            welcomeBonus = 0;

            for (uint256 i = 0; i < welcomeBonusUsers.length; i++) {
                welcomeBonusUsers.pop();
            }
        } else {
            welcomeBonus = 0;
        }
    }

    function _distributeTopPool() private {
        uint16[3] memory rates = [5000, 3000, 2000];
        uint32[3] memory maxReward = [1000e6, 500e6, 300e6];
        uint256 totalReward;
        for (uint256 i = 0; i < 3; i++) {
            address userAddr = dayTopUsers[topUserLastDistributed][i];
            if (userAddr != address(0)) {
                uint256 calRevenue = (getMaxFreezing(userAddr)).add(((getMaxFreezing(userAddr)).mul(5000)).div(baseDivider));
                if (!isFreezeDynamicReward || userInfo[userAddr].totalRevenue < calRevenue) {
                    uint256 reward = topPool.mul(rates[i]).div(baseDivider);
                    if (reward > maxReward[i]) {
                        reward = maxReward[i];
                    }

                    if (isFreezeDynamicReward) {
                        if (calRevenue > userInfo[userAddr].totalRevenue) {
                            uint256 freezeReward = calRevenue.sub(userInfo[userAddr].totalRevenue);
                            if (freezeReward < reward) {
                                reward = freezeReward;
                            }
                        }
                    }

                    rewardInfo[userAddr].top = rewardInfo[userAddr].top.add(reward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
        }

        topPool = 0;

        topUserLastDistributed = topUserLastDistributed.add(1);
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if (upline == defaultRefer) break;
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
        if (_amount > _prevMax || user.depositDistributed < 4) {
            shouldDistribute = true;
        }

        if (_amount > _prevMax) {
            user.depositDistributed = 0;
        }

        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0) && shouldDistribute) {
                uint256 newAmount = _amount;

                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount) {
                    newAmount = maxFreezing;
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                if (!isFreezeDynamicReward || userInfo[upline].totalRevenue < (getMaxFreezing(upline)).add(((getMaxFreezing(upline)).mul(5000)).div(baseDivider))) {
                    if (i > 4) {
                        if (userInfo[upline].level > 3 && userInfo[upline].level4And5Total < level4And5Bonus) {
                            reward = newAmount.mul(level4And5Percents[i - 5]).div(baseDivider);
                            upRewards.level4And5Freezed = upRewards.level4And5Freezed.add(reward);
                            userInfo[upline].level4And5Total = userInfo[upline].level4And5Total.add(reward);
                        }
                    } else if (i > 2) {
                        if (userInfo[upline].level > 2) {
                            reward = newAmount.mul(level3Percents[i - 3]).div(baseDivider);
                            if (userInfo[upline].aon) {
                                upRewards.level3Released = upRewards.level3Released.add(reward);
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            } else {
                                upRewards.level3Freezed = upRewards.level3Freezed.add(reward);
                            }
                        }
                            
                    } else if (i > 0) {
                        if (userInfo[upline].level > 1) {
                            reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                            if (userInfo[upline].aon) {upRewards.level2Released = upRewards.level2Released.add(reward); 
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            } else {
                                upRewards.level2Freezed = upRewards.level2Freezed.add(reward);
                            }
                        }
                    } else {
                        reward = newAmount.mul(directPercents).div(baseDivider);
                        if (userInfo[upline].aon) {
                            upRewards.directs = upRewards.directs.add(reward);
                            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                        } else {
                            upRewards.level2Freezed = upRewards.level2Freezed.add(reward);
                        }
                    }

                    isDistributed = true;

                    if (upline == defaultRefer) break;

                    upline = userInfo[upline].referrer;
                } else {
                    break;
                }
            }

            if (isDistributed) {
                user.depositDistributed = (user.depositDistributed).add(1);
            }
        }
    }

    function getMaxFreezing(address _user) public view returns (uint256) {
        uint256 maxFreezing;
        for (uint256 i = orderInfos[_user].length; i > 0; i--) {
            OrderInfo storage order = orderInfos[_user][i - 1];
            if (order.unfreeze > block.timestamp) {
                if (order.amount > maxFreezing) {
                    maxFreezing = order.amount;
                }
            } else {
                break;
            }
        }
        return maxFreezing;
    }

    function _balActived(uint256 _bal) private {
        for (uint256 i = balDown.length; i > 0; i--) {
            if (_bal >= balDown[i - 1]) {
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for (uint256 i = balDown.length; i > 0; i--) {
            if (balStatus[balDown[i - 1]]) {
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if (_bal < balDown[i - 1].sub(maxDown)) {
                    isFreezeReward = true;
                } else if (isFreezeReward && _bal >= balRecover[i - 1]) {
                    isFreezeReward = false;
                }

                if (isFreezeReward && _bal < (balDown[i - 1].sub(maxDown)).div(2)) {
                    isFreezeDynamicReward = true;
                } else if (isFreezeDynamicReward && _bal >= balRecover[i - 1]) {
                    isFreezeDynamicReward = false;
                }

                break;
            }
        }
    }

    function depositBySplit(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(_amount <= maxDeposit, "more than max");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient split");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        _deposit(msg.sender, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function withdraw() external {
        distributePoolRewards();
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(msg.sender);
        uint256 splitAmt = staticSplit;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        splitAmt = splitAmt.add(dynamicSplit);

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.split = userRewards.split.add(splitAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.level2Released = 0;
        userRewards.level3Released = 0;
        userRewards.level4And5Released = 0;
        userRewards.diamond = 0;
        userRewards.bonus = 0;
        userRewards.top = 0;

        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        usdc.transfer(msg.sender, withdrawable);
        uint256 bal = usdc.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurSplit(address _user) public view returns (uint256) {
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
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
            .add(userRewards.level4And5Released)
            .add(userRewards.level3Released)
            .add(userRewards.level2Released);
        totalRewards = totalRewards
            .add(userRewards.diamond)
            .add(userRewards.bonus)
            .add(userRewards.top);

        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return (withdrawable, splitAmt);
    }

    // ---------------------> Extra Functions read only
    function getCurDay() public view returns (uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns (uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrdersLength(address _user) public view returns (uint256) {
        return orderInfos[_user].length;
    }

    function getRoyaltyPlayersCount() public view returns (uint256, uint256) {
        return (diamondPlayers.length, welcomeBonusUsers.length);
    }
}