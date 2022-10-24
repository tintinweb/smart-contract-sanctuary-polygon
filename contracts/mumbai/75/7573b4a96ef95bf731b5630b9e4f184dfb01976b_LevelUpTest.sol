// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract LevelUpTest {
    using SafeMath for uint256; 
    IERC20 public usdc;
    IERC20 public dsgcoin;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 300; 
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant otherPercent = 6000;
    uint256 private constant timeStep = 1 minutes;
    uint256 private constant dayPerCycle = 15 minutes; 
    uint256[7] private dayRewardPercents = [150,160,170,180,185,187,200]; // 22.50,24,25.50, 27, 27.75, 28.05, 30
    uint256[6] private dayRewardMilestones = [1e12,2e12,4e12,8e12,16e12,32e12]; // 1, 2, 4, 8, 16,32 Million $
    uint256 private constant maxAddFreeze = 45 minutes;
    uint256 private constant referDepth = 20;

    uint256 private constant directPercents = 500;
    uint256[2] private level2Percents = [100, 200];
    uint256[2] private level3Percents = [200, 200];
    uint256[15] private level4And5Percents = [200, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50];
    uint256 private constant level4And5Bonus = 1000e6;


    uint256 private constant diamondRoyaltyIncomePercent = 50;
    uint256 private constant rubyRoyaltyIncomePercent = 40;
    uint256 private constant goldRoyaltyIncomePercent = 40;

    uint256[6] private balDown = [50e9, 30e10, 100e10, 500e10, 1000e10, 2000e10];
    uint256[6] private balDownRate = [1000, 1500, 2000, 5000, 6000, 6000]; 
    uint256[6] private balRecover = [60e9, 50e10, 150e10, 500e10, 1000e10, 2000e10];
    mapping(uint256=>bool) public balStatus; // bal=>status

    address[3] public feeReceivers;
    uint256 private feeReceived;
    uint256 private constant maxFeeReceived = 200e6;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public diamondRoyaltyPool;
    uint256 public rubyRoyaltyPool;
    uint256 public goldRoyaltyPool;

    uint256 public tokenToDistribute = 100e18;
    uint256 private tokenLastReduced = block.timestamp;
    uint256 private constant tokenReduceRate = 10;
    uint256 private tokenDistributed = 0;

    address[] public diamondPlayers;
    address[] public rubyPlayers;
    address[] public goldPlayers;

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
        bool uA;
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
        bool aon;
    }

    mapping(address=>UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 capitals;
        uint256[2] statics; 
        uint256[2] directs; 
        uint256[2] level2Freezed;
        uint256[2] level2Released;
        uint256[2] level3Freezed;
        uint256[2] level3Released;
        uint256 level4And5Freezed;
        uint256 level4And5Released;
        uint256[2] diamond; 
        uint256[2] ruby; 
        uint256[2] gold; 
        uint256 split;
        uint256 splitDebt;
    }

    mapping(address=>RewardInfo) public rewardInfo;
    
    bool public isFreezeReward;
    bool public isFreezeDynamicReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(address _usdtAddr, address _tokenAddr, address _defaultRefer, address[3] memory _feeReceivers) {
        usdc = IERC20(_usdtAddr);
        dsgcoin = IERC20(_tokenAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;

        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 5){
                diamondPlayers.push(_user);
            } else if(levelNow == 4) {
                rubyPlayers.push(_user);
            } else if(levelNow ==  3) {
                goldPlayers.push(_user);
            }


            if (dsgcoin.balanceOf(address(this)) >= tokenToDistribute) {
                if(user.level > 1) {
                    dsgcoin.transfer(_user, tokenToDistribute);
                    tokenDistributed = tokenDistributed.add(tokenToDistribute);
                } else if((block.timestamp - startTime) < 3 days) {
                    dsgcoin.transfer(_user, tokenToDistribute);
                    tokenDistributed = tokenDistributed.add(tokenToDistribute);
                }
                

                if (tokenDistributed >= 300e18 && tokenToDistribute > 1e18) {
                    tokenToDistribute = tokenToDistribute.sub(tokenToDistribute
                        .mul(tokenReduceRate)
                        .div(100));
                    tokenDistributed = 0;
                }
            }
        }
    }

    function _calLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
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

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
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
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(msg.sender);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);

        uint256 _reqVolume = (prevMaxDeposit.mul(60)).div(100);
        if (_isRunning(_user, _amount) || _amount >= _reqVolume.add(prevMaxDeposit)) {
            user.aon = true;
        } else {
            user.aon = false;
        }

        if (_isRunning(user.referrer, _amount) && user.referrer != address(0)) {
            userInfo[user.referrer].aon = true;
        }

        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false,
            user.aon
        ));


        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        distributePoolRewards();

        _updateReferInfo(msg.sender, _amount);

        _updateReward(msg.sender, _amount);

        _releaseUpRewards(msg.sender, _amount);

        uint256 bal = usdc.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }

    function _updatemaxdirectdepositInfo(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        if(upline != address(0)){
            userInfo[upline].maxDirectDeposit = userInfo[upline].maxDirectDeposit.add(_amount);       
            userInfo[upline].maxDirectDeposit = userInfo[upline].maxDirectDeposit.sub(_prevMax);       
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        if(feeReceived < maxFeeReceived) {
            usdc.transfer(feeReceivers[0], fee.div(3));
            usdc.transfer(feeReceivers[1], fee.div(3));
            usdc.transfer(feeReceivers[2], fee.div(3));
            feeReceived = feeReceived.add(fee.div(3));
        } else {
            usdc.transfer(feeReceivers[2], fee.div(2));
        }

        if (diamondPlayers.length > 0) {
            uint256 diamondRoyalty = _amount
                .mul(diamondRoyaltyIncomePercent)
                .div(baseDivider);
            diamondRoyaltyPool = diamondRoyaltyPool.add(diamondRoyalty);
        }

        if (rubyPlayers.length > 0) {
            uint256 rubyRoyalty = _amount.mul(rubyRoyaltyIncomePercent).div(
                baseDivider
            );
            rubyRoyaltyPool = rubyRoyaltyPool.add(rubyRoyalty);
        }

        if (goldPlayers.length > 0) {
            uint256 goldRoyalty = _amount.mul(goldRoyaltyIncomePercent).div(
                baseDivider
            );
            goldRoyaltyPool = goldRoyaltyPool.add(goldRoyalty);
        }
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount){
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else{
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward = order
                    .amount
                    .mul(_calStaticRewardPercent())
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

                if (order.uA) {
                    rewardInfo[_user].statics[0] = rewardInfo[_user].statics[0].add(staticReward);
                } else {
                    rewardInfo[_user].statics[1] = rewardInfo[_user].statics[1].add(staticReward);
                }

                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }

        if(!isUnfreezeCapital){ 
            RewardInfo storage userReward = rewardInfo[_user];
            if(userReward.level4And5Freezed > 0){
                uint256 release = _amount;
                if(_amount >= userReward.level4And5Freezed){
                    release = userReward.level4And5Freezed;
                }
                userReward.level4And5Freezed = userReward.level4And5Freezed.sub(release);
                userReward.level4And5Released = userReward.level4And5Released.add(release);
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
    }

    function _calStaticRewardPercent() public view returns(uint256) {
        uint256 curStatic;
        uint256 bal = usdc.balanceOf(address(this));
        if(bal < dayRewardMilestones[0]) {
            curStatic = dayRewardPercents[0];
        } else if(bal < dayRewardMilestones[1]) {
            curStatic = dayRewardPercents[1];
        } else if(bal < dayRewardMilestones[2]) {
            curStatic = dayRewardPercents[2];
        } else if(bal < dayRewardMilestones[3]) {
            curStatic = dayRewardPercents[3];
        } else if(bal < dayRewardMilestones[4]) {
            curStatic = dayRewardPercents[4];
        } else if(bal < dayRewardMilestones[5]){
            curStatic = dayRewardPercents[5];
        } else {
            curStatic = dayRewardPercents[6];
        }

        return curStatic;
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].teamTotalDeposit > _amount){
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
                }else{
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _isRunning(address _user, uint256 _amount) private view returns (bool) {
        UserInfo storage user = userInfo[_user];
        uint256 ordersLength = getOrdersLength(_user);
        bool aon = false;

        uint256 _reqVolume = (user.maxDeposit.mul(60)).div(100);

        uint256 volume;

        if (ordersLength >= 5) {
            OrderInfo storage order = orderInfos[_user][ordersLength.sub(5)];
            uint256 teamUsersLength = teamUsers[_user][0].length;
            if (teamUsersLength > 0) {
                for (uint256 i = teamUsersLength; i >= 1; i--) {
                    UserInfo storage downline = userInfo[
                        teamUsers[_user][0][i-1]
                    ];
                    if (order.start <= downline.start) {
                        if(teamUsers[_user][0][i-1] == msg.sender) {
                            volume = volume.add(_amount);
                        } else {
                            volume = volume.add(downline.maxDeposit);
                        }
                    } else {
                        break;
                    }
                }

                if (volume >= _reqVolume) {
                    aon = true;
                }
            }
        } else {
            aon = true;
        }

        return aon;
    }

    
    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            _distributeDiamondRoyaltyPool();
            _distributeRubyRoyaltyPool();
            _distributeGoldRoyaltyPool();

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
                if(!isFreezeDynamicReward || userInfo[diamondPlayers[i]].totalRevenue < (getMaxFreezing(diamondPlayers[i])).mul(2)) {
                    if(userInfo[diamondPlayers[i]].aon) {
                        rewardInfo[diamondPlayers[i]].diamond[0] = rewardInfo[diamondPlayers[i]].diamond[0].add(reward);
                    } else {
                        rewardInfo[diamondPlayers[i]].diamond[1] = rewardInfo[diamondPlayers[i]].diamond[1].add(reward);
                    }

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

    function _distributeRubyRoyaltyPool() private {
        uint256 level4Count;
        for (uint256 i = 0; i < rubyPlayers.length; i++) {
            if (userInfo[rubyPlayers[i]].level == 4) {
                level4Count = level4Count.add(1);
            }
        }

        if (level4Count > 0) {
            uint256 reward = rubyRoyaltyPool.div(level4Count);
            uint256 totalReward;
            for (uint256 i = 0; i < rubyPlayers.length; i++) {
                if (userInfo[rubyPlayers[i]].level == 4) {
                if(!isFreezeDynamicReward || userInfo[rubyPlayers[i]].totalRevenue < (getMaxFreezing(rubyPlayers[i])).mul(2)) {
                    if(userInfo[rubyPlayers[i]].aon) {
                        rewardInfo[rubyPlayers[i]].ruby[0] = rewardInfo[rubyPlayers[i]].ruby[0].add(reward);
                    } else {
                        rewardInfo[rubyPlayers[i]].ruby[1] = rewardInfo[rubyPlayers[i]].ruby[1].add(reward);
                    }
                    userInfo[rubyPlayers[i]].totalRevenue = userInfo[rubyPlayers[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
                }
            }
            if (rubyRoyaltyPool > totalReward) {
                rubyRoyaltyPool = rubyRoyaltyPool.sub(totalReward);
            } else {
                rubyRoyaltyPool = 0;
            }
        }
    }

    function _distributeGoldRoyaltyPool() private {
        uint256 level3Count;
        for (uint256 i = 0; i < goldPlayers.length; i++) {
            if (userInfo[goldPlayers[i]].level == 3) {
                level3Count = level3Count.add(1);
            }
        }

        if (level3Count > 0) {
            uint256 reward = goldRoyaltyPool.div(level3Count);
            uint256 totalReward;
            for (uint256 i = 0; i < goldPlayers.length; i++) {
                if (userInfo[goldPlayers[i]].level == 3) {
                if(!isFreezeDynamicReward || userInfo[goldPlayers[i]].totalRevenue < (getMaxFreezing(goldPlayers[i])).mul(2)) {
                    if(userInfo[goldPlayers[i]].aon) {
                        rewardInfo[goldPlayers[i]].gold[0] = rewardInfo[goldPlayers[i]].gold[0].add(reward);
                    } else {
                        rewardInfo[goldPlayers[i]].gold[1] = rewardInfo[goldPlayers[i]].gold[1].add(reward);
                    }
                    userInfo[goldPlayers[i]].totalRevenue = userInfo[goldPlayers[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
                }
            }
            if (goldRoyaltyPool > totalReward) {
                goldRoyaltyPool = goldRoyaltyPool.sub(totalReward);
            } else {
                goldRoyaltyPool = 0;
            }
        }
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

    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
   
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                uint256 newAmount = _amount;

                if (upline != defaultRefer) {
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if (maxFreezing < _amount) {
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                if(!isFreezeDynamicReward || userInfo[upline].totalRevenue < (getMaxFreezing(upline)).mul(2)) {
                    if (i > 4) {
                        if (userInfo[upline].level > 3 && userInfo[upline].level4And5Total < level4And5Bonus) {
                            reward = newAmount.mul(level4And5Percents[i - 5]).div(baseDivider);
                            upRewards.level4And5Freezed = upRewards.level4And5Freezed.add(reward);

                            userInfo[upline].level4And5Total = userInfo[upline].level4And5Total.add(reward); 
                        }
                    } else if (i > 2) {
                        if (userInfo[upline].level > 2) {
                            reward = newAmount.mul(level3Percents[i - 3]).div(baseDivider);

                            if(userInfo[upline].aon) {
                                upRewards.level3Freezed[0] = upRewards.level3Freezed[0].add(reward);
                            } else {
                                upRewards.level3Freezed[1] = upRewards.level3Freezed[1].add(reward);
                            }
                            
                            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                        }
                    } else if (i > 0) {
                        if (userInfo[upline].level > 1) {               
                            reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                            
                            if(userInfo[upline].aon) {
                                upRewards.level2Freezed[0] = upRewards.level2Freezed[0].add(reward);
                            } else {
                                upRewards.level2Freezed[1] = upRewards.level2Freezed[1].add(reward);
                            }

                            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                        }
                    } else {
                        reward = newAmount.mul(directPercents).div(baseDivider);
                        if(userInfo[upline].aon) {
                            upRewards.directs[0] = upRewards.directs[0].add(reward);
                        } else {
                            upRewards.directs[1] = upRewards.directs[1].add(reward);
                        }
                        
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                }

                if (upline == defaultRefer) break;

                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _releaseUpRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];

                if(i > 2 && i < 5 && userInfo[upline].level > 2){
                    if(upRewards.level3Freezed[0] > 0 || upRewards.level3Freezed[1] > 0){
                        uint256 level3Reward = newAmount.mul(level3Percents[i - 3]).div(baseDivider);

                        if(level3Reward > upRewards.level3Freezed[0].add(upRewards.level3Freezed[1])){
                            level3Reward = upRewards.level3Freezed[0].add(upRewards.level3Freezed[1]);
                        }
                        
                        if(level3Reward > upRewards.level3Freezed[0]) {
                            uint256 freezed = upRewards.level3Freezed[0];
                            upRewards.level3Freezed[0] = upRewards.level3Freezed[0].sub(freezed); 
                            upRewards.level3Released[0] = upRewards.level3Released[0].add(freezed);
                            
                            upRewards.level3Freezed[1] = upRewards.level3Freezed[1].sub(level3Reward.sub(freezed)); 
                            upRewards.level3Released[1] = upRewards.level3Released[1].add(level3Reward.sub(freezed));
                        } else {
                            upRewards.level3Freezed[0] = upRewards.level3Freezed[0].sub(level3Reward); 
                            upRewards.level3Released[0] = upRewards.level3Released[0].add(level3Reward);
                        }

                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level3Reward);
                    }
                }


                if(i > 0 && i < 3 && userInfo[upline].level > 1){
                    if(upRewards.level2Freezed[0] > 0 || upRewards.level2Freezed[1] > 0){
                        uint256 level2Reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);

                        if(level2Reward > upRewards.level2Freezed[0].add(upRewards.level2Freezed[1])){
                            level2Reward = upRewards.level2Freezed[0].add(upRewards.level2Freezed[1]);
                        }
                        
                        if(level2Reward > upRewards.level2Freezed[0]) {
                            uint256 freezed = upRewards.level2Freezed[0];
                            upRewards.level2Freezed[0] = upRewards.level2Freezed[0].sub(freezed); 
                            upRewards.level2Released[0] = upRewards.level2Released[0].add(freezed);

                            upRewards.level2Freezed[1] = upRewards.level2Freezed[1].sub(level2Reward.sub(freezed)); 
                            upRewards.level2Released[1] = upRewards.level2Released[1].add(level2Reward.sub(freezed));
                        } else {
                            upRewards.level2Freezed[0] = upRewards.level2Freezed[0].sub(level2Reward); 
                            upRewards.level2Released[0] = upRewards.level2Released[0].add(level2Reward);
                        }

                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level2Reward);
                    }
                }

                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function getMaxFreezing(address _user) public view returns(uint256) {
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

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }

                if(isFreezeReward && _bal < (balDown[i - 1].sub(maxDown)).div(2)) {
                    isFreezeDynamicReward = true;
                } else if(isFreezeDynamicReward && _bal >= (balDown[i - 1].sub(maxDown)).mul(2)) {
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

        userRewards.statics[0] = 0;
        userRewards.statics[1] = 0;

        userRewards.directs[0] = 0;
        userRewards.directs[1] = 0;

        userRewards.level2Released[0] = 0;
        userRewards.level2Released[1] = 0;

        userRewards.level3Released[0] = 0;
        userRewards.level3Released[1] = 0;

        userRewards.level4And5Released = 0;
        
        userRewards.diamond[0] = 0;
        userRewards.diamond[1] = 0;

        userRewards.gold[0] = 0;
        userRewards.gold[1] = 0;

        userRewards.ruby[0] = 0;
        userRewards.ruby[1] = 0;
        
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;
        
        usdc.transfer(msg.sender, withdrawable);
        uint256 bal = usdc.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics[0].add(userRewards.statics[1]);

        uint256 splitAmt = userRewards.statics[0].mul(freezeIncomePercents).div(baseDivider);
        uint256 otherSplitAmt = userRewards.statics[1].mul(otherPercent).div(baseDivider);

        uint256 withdrawable = totalRewards.sub(splitAmt.add(otherSplitAmt));
        return(withdrawable, splitAmt.add(otherSplitAmt));
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs[0].add(userRewards.level4And5Released).add(userRewards.level3Released[0]).add(userRewards.level2Released[0]);
        uint256 otherTotalRewards = userRewards.directs[1].add(userRewards.level3Released[1]).add(userRewards.level2Released[1]);
        uint256 poolTotalRewards = userRewards.diamond[0].add(userRewards.ruby[0]).add(userRewards.gold[0]);
        uint256 otherPoolTotalRewards = userRewards.diamond[1].add(userRewards.ruby[1]).add(userRewards.gold[1]);

        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        splitAmt = splitAmt.add(otherTotalRewards.mul(otherPercent).div(baseDivider));
        splitAmt = splitAmt.add(poolTotalRewards.mul(freezeIncomePercents).div(baseDivider));
        splitAmt = splitAmt.add(otherPoolTotalRewards.mul(otherPercent).div(baseDivider));


        totalRewards = totalRewards.add(otherTotalRewards).add(poolTotalRewards).add(otherPoolTotalRewards);

        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    // ---------------------> Extra Functions read only
    function getCurDay() public view returns (uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer)
        external
        view
        returns (uint256)
    {
        return teamUsers[_user][_layer].length;
    }

    function getOrdersLength(address _user) public view returns (uint256) {
        return orderInfos[_user].length;
    }

    function getRoyaltyPlayersCount() public view returns (uint256, uint256, uint256) {
        uint256 rubyPlayersCount;
        uint256 goldPlayersCount;
        
        for(uint256 i=0; i<rubyPlayers.length; i++) {
            if(userInfo[rubyPlayers[i]].level == 4) {
                rubyPlayersCount += 1;
            }
        }

        for(uint256 i=0; i<goldPlayers.length; i++) {
            if(userInfo[goldPlayers[i]].level == 3) {
                goldPlayersCount += 1;
            }
        }
        return (diamondPlayers.length, rubyPlayersCount, goldPlayersCount);
    }

    function getDynamicIncome(address _user) public view returns(uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory, uint256[2] memory) {
        RewardInfo storage reward = rewardInfo[_user];
        return (
        reward.statics, 
        reward.directs, 
        reward.level2Released, 
        reward.level2Freezed,  
        reward.level3Released, 
        reward.level3Freezed,  
        reward.diamond, 
        reward.ruby, 
        reward.gold
        );
    }
}