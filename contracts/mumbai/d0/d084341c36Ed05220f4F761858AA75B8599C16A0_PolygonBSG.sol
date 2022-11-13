// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract PolygonBSG {
    using SafeMath for uint256;
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant limitProfit = 20000;
    uint256 private constant feePercents = 200; //2%
    uint256 private constant minTransferAmount = 10e6; //$10
    uint256 private constant minDeposit = 100e6; //$100
    uint256 private constant maxDeposit = 2500e6; //$2500
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant LuckDeposit = 1000e6; //$1000
    uint256 private constant timeStep = 1 minutes; //1 days
    uint256 private constant dayPerCycle = 1 minutes; //15 days
    uint256 private constant normalcycleRewardPercents = 1500;
    uint256 private constant boostercycleRewardPercents = 2000;
    uint256 private constant maxdayPerCycle = 36 minutes; //50 days
    uint256 private constant referDepth = 12;

    uint256 private constant directPercents = 500;
    uint256[] private percent4Levels = [500,100,200,100,200,100,100,100,100,100,50,50]; //percent real value is current/baseDivider

    uint256 private constant infiniteRewardPercents = 400; //4%
    uint256 private constant insurancePoolPercents = 50; //0.5%
    uint256 private constant diamondIncomePoolPercents = 50; //0.5%
    uint256 private constant more1kIncomePoolPercents = 50; //0.5%

    uint256[5] private balDown = [6000, 8000, 11000];
    mapping(uint256=>bool) public balStatus; // bal=>status

    address[2] public feeReceivers; //2 creator
    address public insuranceAccount; //0.5%

    address public defaultRefer; //set it as level 1
    uint256 public startTime;
    uint256 public lastDistribute; //daliy distribution pool reward
    uint256 public totalUser;
    uint256 public insurancePool;
    uint256 public diamondIncomePool;
    uint256 public more1kIncomePool;

    uint256 public AllTimeHigh;
    uint256 private constant ATHSTOPLOSS30 = 3000;
    uint256 private constant ATHSTOPLOSS50 = 5000;

    mapping(uint256=>address[]) public dayMore1kUsers;

    address[] public diamondUsers;
    address[] public blueDiamondUsers;
    address[] public crownDiamondUsers;

    struct OrderInfo {
        uint256 cycle;
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
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 teamTotalVolume;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 membership; //normal, boost, diamond, blue diamond, crown diamond
        uint256 directBonusCount;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => address[]) public myTeamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 levelReleased;
        uint256 infinityBonusReleased;
        uint256 cycleNumber; //start with 0
        uint256 more1k;
        uint256 lockusdt;
        uint256 lockusdtDebt; // locked amount got from other lock amount
    }

    mapping(address => RewardInfo) public rewardInfo;

    bool public isFreezeReward = false;
    bool public isStopLoss30ofATH = false;
    bool public isStopLoss50ofATH = false;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBylockusdt(address user, uint256 amount);
    event TransferBylockusdt(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(
        address _usdtAddr,
        address _defaultRefer,
        address _insurance,
        address[2] memory _feeReceivers
    ) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        insuranceAccount = _insurance;
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        myTeamUsers[_referral].push(msg.sender);
        UserInfo storage uplineUser = userInfo[_referral];
        if(msg.sender != _referral){
            uplineUser.teamNum = uplineUser.teamNum.add(1);
        }
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0) && _user != upline) {
                teamUsers[upline][i].push(_user);
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
        if (_user == defaultRefer) return 0;
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = 1;
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            UserInfo storage tmp_user = userInfo[upline];
            if (tmp_user.referrer == defaultRefer) {
                break;
            } else {
                upline = tmp_user.referrer;
                levelNow = levelNow + 1;
            }
        }
        return levelNow;
    }

    function deposit(uint256 amount) external {
        uint256 _amount = amount.mul(1000000);
        require(_amount.mod(minDeposit) == 0,"amount should be multiple of 100");
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0),"register first with referral address");
        require(_amount >= minDeposit, "should be more than min 100");
        require(_amount <= maxDeposit, "should be less than min 2500");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit,"next deposit should be equal or more than previous");

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0 && _amount >= LuckDeposit){
            uint256 dayNow = getCurDay();
            dayMore1kUsers[dayNow].push(_user);
        }

        _updateDepositors(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateMembership(_user);

        RewardInfo storage reward = rewardInfo[_user];
        uint256 addFreeze = 35;
        if(reward.cycleNumber >= 35){
            addFreeze = addFreeze.mul(timeStep);
        }else{
            addFreeze = reward.cycleNumber.mul(timeStep);
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(reward.cycleNumber,_amount, block.timestamp, unfreezeTime, false));
        reward.cycleNumber = reward.cycleNumber.add(1);
        
        _unfreezeFundAndUpdateReward(_user); //calculate main static reward

        distributePoolRewards(); //give more1k users reward

        _updateReferInfo(_user, _amount); //update totalDep and totalVol

        _updateDirectReward(_user, _amount); //calculate directs and level reward

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if (isFreezeReward) {
            _setFreezeReward(bal, true);
        }else{
            if(AllTimeHigh < bal)
                AllTimeHigh = bal;
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(2));
        usdt.transfer(feeReceivers[1], fee.div(2));
        uint256 _insurance = _amount.mul(insurancePoolPercents).div(baseDivider);
        usdt.transfer(insuranceAccount, _insurance);
        insurancePool = insurancePool.add(_insurance);
        uint256 poolIncome = _amount.mul(diamondIncomePoolPercents).div(baseDivider);
        diamondIncomePool = diamondIncomePool.add(poolIncome);
        uint256 more1kPool = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        more1kIncomePool = more1kIncomePool.add(more1kPool);
    }

    function _unfreezeFundAndUpdateReward(address _user) private {
        UserInfo storage user = userInfo[_user];

        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && !order.isClaimed && order.cycle < rewardInfo[_user].cycleNumber.sub(1)) {
                uint256 staticReward;
                if (isStopLoss30ofATH || isStopLoss50ofATH) {
                    staticReward = 0;
                } else {
                    if(user.teamNum >= 5 && user.teamTotalVolume >= 5000e6){
                        staticReward = order.amount.mul(boostercycleRewardPercents).div(baseDivider);
                    }else{
                        staticReward = order.amount.mul(normalcycleRewardPercents).div(baseDivider);
                    }

                    if(user.totalRevenue > order.amount.mul(limitProfit).div(baseDivider)){
                        staticReward = 0;
                    }
                    rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                    rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                }
                order.isClaimed = true;
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0) && upline != _user) {
            if (userInfo[upline].teamTotalDeposit > _amount) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
            } else {
                userInfo[upline].teamTotalDeposit = 0;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            uint256 dayNow = block.timestamp;
            _distributeLuckPool1k(dayNow);
            lastDistribute = block.timestamp;
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function _distributeLuckPool1k(uint256 _dayNow) private {
        uint256 day1kDepositCount = dayMore1kUsers[_dayNow - 1].length;
        if(day1kDepositCount > 0){
            for(uint256 i = day1kDepositCount; i > 0; i--){
                address userAddr = dayMore1kUsers[_dayNow - 1][i - 1];
                if(userAddr != address(0)){
                    uint256 reward = more1kIncomePool.div(day1kDepositCount);
                    rewardInfo[userAddr].more1k = rewardInfo[userAddr].more1k.add(reward);
                }
            }
            more1kIncomePool = 0;
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0) && _user != upline) {
            userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
            userInfo[upline].teamTotalVolume = userInfo[upline].teamTotalVolume.add(_amount);
            _updateMembership(upline);
        }
    }

    function _updateDirectReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0)) {
            for(uint256 i = 0; i < referDepth; i++){
                if(upline != address(0) && upline != _user){
                    uint256 levelReward = _amount.mul(percent4Levels[i]).div(baseDivider);
                    rewardInfo[upline].levelReleased = rewardInfo[upline].levelReleased.add(levelReward);
                    if(upline == defaultRefer) break;
                    upline = userInfo[upline].referrer;
                }else{
                    break;
                }
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

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= AllTimeHigh.mul(balDown[i-1]).div(baseDivider)){
                balStatus[balDown[i - 1]] = true;
                break;
            }else{
                balStatus[balDown[i - 1]] = false;
            }
        }
    }

    function _setFreezeReward(uint256 _bal, bool when) private {
        if(when){ //deposit - only isFreezed = true
            depositFromInsurance();
            for(uint256 i = balDown.length; i > 0; i--){
                if(balStatus[balDown[i - 1]]){
                    isFreezeReward = false;
                    break;
                }
            }
        }else{
            for(uint256 i = balDown.length; i > 0; i--){
                if(_bal < AllTimeHigh.mul(baseDivider.sub(ATHSTOPLOSS30)).div(baseDivider)){
                    isFreezeReward = true;
                    depositFromInsurance();
                    break;
                }
            }
        }
    }

    function withdraw() external {
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        bool _withdrawable = orderInfos[msg.sender][userRewards.cycleNumber.sub(2)].unfreeze < block.timestamp && userRewards.capitals > 0;

        require(_withdrawable == true, "Cant claim, Please check stake date and deposit status!");
        distributePoolRewards();
        (uint256 staticReward, uint256 staticlockusdt) = _calCurStaticRewards(msg.sender);
        uint256 lockusdtAmt = staticlockusdt;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamiclockusdt) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        lockusdtAmt = lockusdtAmt.add(dynamiclockusdt);

        UserInfo storage userin = userInfo[msg.sender];

        userin.totalRevenue = userin.totalRevenue.add(withdrawable).add(lockusdtAmt);
        userin.totalFreezed = userin.totalFreezed.sub(withdrawable.add(lockusdtAmt));

        userRewards.lockusdt = userRewards.lockusdt.add(lockusdtAmt);

        userRewards.statics = 0;

        userRewards.levelReleased = 0;
        userRewards.infinityBonusReleased = 0;
        
        userRewards.more1k = 0;
        withdrawable = withdrawable.add(userRewards.capitals);
        _removeInvalidDeposit(msg.sender, userRewards.capitals);
        userRewards.capitals = 0;
        
        usdt.transfer(msg.sender, withdrawable);
        uint256 _membership = checkDiamondMembership(msg.sender);
        if(_membership == 4){
            uint256 _count = checkCrownDiamondClaimCount(msg.sender);
            if(_count < 10){
                crownDiamondUsers.push(msg.sender);
                usdt.transfer(insuranceAccount, 50e6);
                insurancePool = insurancePool.add(50e6);
            }
        } else if(_membership == 3){
            uint256 _count = checkBlueDiamondClaimCount(msg.sender);
            if(_count < 20){
                blueDiamondUsers.push(msg.sender);
                usdt.transfer(insuranceAccount, 25e6);
                insurancePool = insurancePool.add(25e6);
            }
        }
        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal, false);

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
        
        uint256 totalRewards = 0;
        uint256 teamReward;
        uint256 _member = checkDiamondMembership(_user);
        if(_member >= 2){
            teamReward = getDiamondReward(_user);
        } else {
            teamReward = getActiveTeamReward(_user);
        }

        totalRewards = totalRewards.add(teamReward);
        totalRewards = totalRewards.add(userRewards.more1k);
        totalRewards = totalRewards.add(userRewards.infinityBonusReleased);

        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        
        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function depositBylockusdt(uint256 amount) external {
        uint256 _amount = amount.mul(1000000);
        require(_amount >= minDeposit.div(2) && _amount.mod(minDeposit.div(2)) == 0, "amount err");
        require(orderInfos[msg.sender].length == 0, "First depositors can only use this function");
        uint256 lockusdtLeft = rewardInfo[msg.sender].lockusdt;
        require(lockusdtLeft <= _amount, "insufficient fresh lockusdt"); //fresh should be more than 50%
        rewardInfo[msg.sender].lockusdt = 0;
        _deposit(msg.sender, _amount.add(lockusdtLeft));
        emit DepositBylockusdt(msg.sender, _amount.add(lockusdtLeft));
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
        require(_amount >= minDeposit.div(10) && _amount.mod(minDeposit.div(10)) == 0, "amount err");
        require(userInfo[_receiver].referrer != address(0), "Receiver should be registrant");
        uint256 lockusdtLeft = rewardInfo[msg.sender].lockusdt;
        require(lockusdtLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].lockusdt = rewardInfo[msg.sender].lockusdt.sub(_amount);
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

    function getTeamUsersLengthwithDepth(address _user, uint256 _layer) external view returns(uint256) {
        if(_layer >= referDepth){
            return 0;
        }else{
            return teamUsers[_user][_layer].length;
        }
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getTeamDeposit(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        return user.teamTotalDeposit;
    }

    function _updateMembership(address _user) private {
        UserInfo storage user = userInfo[_user];
        if(user.teamNum >= 2 && user.teamTotalDeposit >= user.maxDeposit.mul(2)){
            if(user.maxDeposit >= 2500e6 && user.teamNum >= 15 && 
            user.teamTotalDeposit >= 15000e6 && user.teamTotalVolume >= 500000e6){
                user.membership = 4;
            }else if(user.maxDeposit >= 2500e6 && user.teamNum >= 10 && 
            user.teamTotalDeposit >= 10000e6 && user.teamTotalVolume >= 100000e6){
                user.membership = 3;
            }else if(user.maxDeposit >= 1000e6 && user.teamNum >= 5 && 
            user.teamTotalDeposit >= 10000e6 && user.teamTotalVolume >= 100000e6){
                user.membership = 2;
            }else{
                user.membership = 1;
            }
        }else{
            user.membership = 0;
        }
    }

    function _checkClaimable(address _user) public view returns(bool){
        RewardInfo storage userRewards = rewardInfo[_user];
        bool _withdrawable = (userRewards.cycleNumber >= 2 && userRewards.capitals > 0
            && orderInfos[_user][userRewards.cycleNumber.sub(2)].unfreeze < block.timestamp);
        return _withdrawable;
    }

    function depositFromInsurance() private {
        uint256 allowanceAmount = usdt.allowance(insuranceAccount, address(this));
        if(allowanceAmount >= uint256(1000000))
        {
            if(allowanceAmount > insurancePool){
                usdt.transferFrom(insuranceAccount, address(this), insurancePool);
            } else {
                usdt.transferFrom(insuranceAccount, address(this), allowanceAmount);
            }
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

    function getActiveTeam(address _user) public view returns(uint256) {
        address[] storage _teams = myTeamUsers[_user];
        uint256 teamLength = _teams.length;
        uint256 activeCount = 0;
        for (uint256 i = 0; i < teamLength; i++) {
            OrderInfo[] storage _order = orderInfos[myTeamUsers[_user][i]];
            if(_order.length > 0){
                OrderInfo storage _finalOrder = _order[_order.length - 1];
                uint256 _deadline = _finalOrder.unfreeze;
                if(_deadline > block.timestamp){
                    //active
                    activeCount = activeCount.add(1);
                }
            }
        }
        return activeCount;
    }

    function getActiveTeamReward(address _user) public view returns(uint256) {
        address[] storage _teams = myTeamUsers[_user];
        uint256 teamLength = _teams.length;
        uint256 teamReward = 0;
        for (uint256 i = 0; i < teamLength; i++) {
            OrderInfo[] storage _order = orderInfos[myTeamUsers[_user][i]];
            if(_order.length > 0){
                OrderInfo storage _finalOrder = _order[_order.length - 1];
                uint256 _deadline = _finalOrder.unfreeze;
                if(_deadline > block.timestamp){
                    //active
                    uint256 _teammemberamount = _finalOrder.amount;
                    teamReward = teamReward.add(_teammemberamount.mul(directPercents).div(baseDivider));
                }
            }
        }

        return teamReward;
    }

    function checkDiamondMembership(address _user) public view returns(uint256){
        uint256 _membership = 0;
        uint256 _selfAmount = 0;
        uint256 _directs = 0;
        uint256 _directSize = 0;
        uint256 _totalTeamSize = 0;
        uint256 _totalTeamVolume = 0;

        OrderInfo[] storage _orderlist = orderInfos[_user];
        UserInfo storage _userInfo = userInfo[_user];
        uint256 _orderLength = _orderlist.length;
        if(_orderLength > 0){
            OrderInfo storage _finalOrder = _orderlist[_orderLength - 1];
            _selfAmount = _finalOrder.amount;
            _directs = _userInfo.teamNum;
            _directSize = getActiveTeamReward(_user);
            _directSize = _directSize.mul(20);
            _totalTeamSize = getActiveTeambyDepth(_user);
            _totalTeamVolume = _userInfo.teamTotalVolume;
            if(_selfAmount >= 2500e6 && _directs >=15 && _directSize >= 15000e6 && _totalTeamSize >= 400 && _totalTeamVolume >= 500000e6){
                _membership = 4;
            }else if(_selfAmount >= 2500e6 && _directs >=10 && _directSize >= 10000e6 && _totalTeamSize >= 180 && _totalTeamVolume >= 100000e6){
                _membership = 3;
            }else if(_totalTeamSize >= 40 && _totalTeamVolume >= 20000e6){
                _membership = 2;
            }
        } else {
            _membership = 0;
        }
        return _membership;
    }

    function getActiveTeambyDepth(address _user) public view returns(uint256){
        uint256 _count = 0;
        for (uint256 i = 0; i < referDepth; i++) {
            address[] storage _curUserlst = teamUsers[_user][i];
            uint256 _length = _curUserlst.length;
            for (uint256 j = 0; j < _length; j++) {
                address _selUser = _curUserlst[j];
                OrderInfo[] storage _orderlst = orderInfos[_selUser];
                if(_orderlst.length > 0){
                    OrderInfo storage _finalOrder = _orderlst[_orderlst.length - 1];
                    if(_finalOrder.unfreeze > block.timestamp){
                        _count = _count.add(1);
                    }
                }
            }
        }
        return _count;
    }

    function getDiamondReward(address _user) public view returns(uint256){
        uint256 _member = checkDiamondMembership(_user);
        uint256 _membershipReward = 0;
        if(_member >= 2) {
            if(_member == 4) {
                uint256 _claimCount = checkCrownDiamondClaimCount(_user);
                if(_claimCount < 10){
                    for (uint256 i = 0; i < referDepth; i++) {
                        address[] storage teambylevel = teamUsers[_user][i];
                        for (uint256 j = 0; j < teambylevel.length; j++) {
                            OrderInfo[] storage _orderInfo = orderInfos[teambylevel[j]];
                            if(_orderInfo.length > 0){
                                OrderInfo storage _finalOrder = _orderInfo[_orderInfo.length - 1];
                                if(_finalOrder.unfreeze > block.timestamp){
                                    _membershipReward = _membershipReward.add(_finalOrder.amount.mul(percent4Levels[i] + infiniteRewardPercents).div(baseDivider));
                                }
                            }
                        }
                    }
                    if(_membershipReward > 50e6){
                        _membershipReward = _membershipReward.sub(50e6);
                    }else{
                        _membershipReward = 0;
                    }
                }
            } else if(_member == 3) {
                uint256 _claimCount = checkBlueDiamondClaimCount(_user);
                if(_claimCount < 20){
                    for (uint256 i = 0; i < referDepth; i++) {
                        address[] storage teambylevel = teamUsers[_user][i];
                        for (uint256 j = 0; j < teambylevel.length; j++) {
                            OrderInfo[] storage _orderInfo = orderInfos[teambylevel[j]];
                            if(_orderInfo.length > 0){
                                OrderInfo storage _finalOrder = _orderInfo[_orderInfo.length - 1];
                                if(_finalOrder.unfreeze > block.timestamp){
                                    _membershipReward = _membershipReward.add(_finalOrder.amount.mul(percent4Levels[i]).div(baseDivider));
                                }
                            }
                        }
                    }
                    if(_membershipReward > 25e6){
                        _membershipReward = _membershipReward.sub(25e6);
                    }else{
                        _membershipReward = 0;
                    }
                }
            } else if(_member == 2) {
                for (uint256 i = 0; i < 5; i++) {
                    address[] storage teambylevel = teamUsers[_user][i];
                    for (uint256 j = 0; j < teambylevel.length; j++) {
                        OrderInfo[] storage _orderInfo = orderInfos[teambylevel[j]];
                        if(_orderInfo.length > 0){
                            OrderInfo storage _finalOrder = _orderInfo[_orderInfo.length - 1];
                            if(_finalOrder.unfreeze > block.timestamp){
                                _membershipReward = _membershipReward.add(_finalOrder.amount.mul(percent4Levels[i]).div(baseDivider));
                            }
                        }
                    }
                }
            }
        }
        return _membershipReward;
    }

    function checkBlueDiamondClaimCount(address _user) public view returns(uint256){
        uint256 _length = blueDiamondUsers.length;
        uint256 _times = 0;
        for (uint256 i = 0; i < _length; i++) {
            if(blueDiamondUsers[i] == _user){
                _times = _times.add(1);
            }
        }
        return _times;
    }

    function checkCrownDiamondClaimCount(address _user) public view returns(uint256){
        uint256 _length = crownDiamondUsers.length;
        uint256 _times = 0;
        for (uint256 i = 0; i < _length; i++) {
            if(crownDiamondUsers[i] == _user){
                _times = _times.add(1);
            }
        }
        return _times;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}