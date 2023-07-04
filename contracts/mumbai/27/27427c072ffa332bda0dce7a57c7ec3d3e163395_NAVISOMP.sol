/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract NAVISOMP {
    using SafeMath for uint256; 
    uint256 private constant timeStep = 1 hours;
    uint256 private constant dayPerCycle = 1 hours; 
    uint256 private constant maxAddFreeze = 5 hours;
    uint256 private constant initDayNewbies = 3;
    uint256 private constant incInterval = 2;
    uint256 private constant incNumber = 1;
    uint256 private constant unlimitDay = 3650;
    uint256 private constant maxSearchDepth = 3000;
    uint256 private constant baseDividend = 10000;
    uint256 private constant incomeFeePercents = 700;
    uint256 private constant bonusPercents = 500;
    uint256 private constant splitPercents = 3000;
    uint256 private constant baseSplitPercents = 2500;
    uint256 private constant baseFundPercents = 7500;
    uint256 private constant transferFeePercents = 1000;
    uint256 private constant dayRewardPercents = 150;    
    uint256 private constant unfreezeWithoutIncomePercents = 15000;
    uint256 private constant unfreezeWithIncomePercents = 20000;
    uint256[5] private levelTeam = [0, 0, 0, 50, 200];
    uint256[5] private levelInvite = [0, 0, 0, 10000e6, 60000e6];
    uint256[6] private levelDeposit = [50e6, 500e6, 1000e6, 2000e6, 3000e6];
    uint256[5] private balReached = [50e10, 100e10, 200e10, 500e10, 1000e10];
    uint256[5] private balFreeze = [35e10, 70e10, 100e10, 300e10, 500e10];
    uint256[5] private balUnfreeze = [80e10, 150e10, 200e10, 500e10, 1000e10];
    uint256[20] private invitePercents = [500, 100, 200, 300, 100, 100, 100, 100, 50, 50, 50, 50, 30, 30, 30, 30, 30, 30, 30, 30];
    

    IERC20 private usdt;
    address private feeReceiver;
    address private defaultRefer;
    uint256 private startTime;
    uint256 private lastDistribute;
    uint256 private totalUsers;
    uint256 private totalDeposit;
    uint256 private freezedTimes;
    bool private isFreezing;
    address[] private depositors;
    mapping(uint256=>bool) private balStatus;
    mapping(uint256=>address[]) private dayNewbies;
    mapping(uint256=>uint256) private freezeTime;
    mapping(uint256=>uint256) private unfreezeTime;
    mapping(uint256=>uint256) private dayDeposits;
    mapping(address=>mapping(uint256=>bool)) private isUnfreezedReward;
    struct UserInfo {
        address referrer;
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDepositable;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 unfreezeIndex;
        uint256 startTime;
        uint256 totalUsdt;
        bool isMaxFreezing;
    }
    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 invited;
        uint256 bonusFreezed;
        uint256 bonusReleased;
        uint256 l5Freezed;
        uint256 l5Released;
        uint256 split;
        uint256 lastWithdaw;
    }
    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
    }
    
    mapping(address=>UserInfo) private userInfo;
    mapping(address=>RewardInfo) private rewardInfo;
    mapping(address=>OrderInfo[]) private orderInfos;
    mapping(address=>mapping(uint256=>uint256)) private userCycleMax;
    mapping(address=>mapping(uint256=>address[])) private teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 types, uint256 amount, bool isFreezing);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 incomeFee, uint256 split, uint256 withdraw);
    event DepositFund(address user, uint256 amount);
    event TransferFund(address user, address receiver, uint256 amount);

    constructor(address _usdtAddr, address _defaultRefer, address _feeReceiver, uint256 _startTime) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        feeReceiver = _feeReceiver;
        startTime = _startTime;
        lastDistribute = _startTime;
    }

    function register(address _referral) external {
        require(userInfo[_referral].maxDeposit > 0 || _referral == defaultRefer, "invalid refer");
        require(userInfo[msg.sender].referrer == address(0), "referrer bonded");
        userInfo[msg.sender].referrer = _referral;
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external {
        _deposit(msg.sender, _amount, 0);
    }

    function depositBySplit(uint256 _amount) public {
        _deposit(msg.sender, _amount, 1);

    }

    function redeposit() public {
        _deposit(msg.sender, 0, 2);
    }

    function _deposit(address _userAddr, uint256 _amount, uint256 _types) private {
        require(block.timestamp >= startTime, "not start");
        UserInfo storage user = userInfo[_userAddr];
        require(user.referrer != address(0), "not register");
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        if(_types == 0){
            usdt.transferFrom(_userAddr, address(this), _amount);
            _balActived();
        }else if(_types == 1){
            require(user.level == 0, "actived");
            require(userRewards.split >= _amount, "insufficient");
            require(_amount.mod(levelDeposit[0]) == 0, "amount err");

            uint256 baseSplitBal = _amount.mul(baseSplitPercents).div(baseDividend);
            uint256 baseFundBal = _amount.mul(baseFundPercents).div(baseDividend);

            require(userRewards.split >= baseSplitBal, "insufficient split");
            require(user.totalUsdt >= baseFundBal, "insufficient fund balance");

            userRewards.split = userRewards.split.sub(baseSplitBal);
            user.totalUsdt = user.totalUsdt.sub(baseFundBal);
            
        }else{
            require(user.level > 0, "newbie");
            _amount = orderInfos[_userAddr][user.unfreezeIndex].amount;
        }

        uint256 curCycle = getCurCycle();
        (uint256 userCurMin, uint256 userCurMax) = getUserCycleDepositable(_userAddr, curCycle);
        require(_amount >= userCurMin && _amount <= userCurMax && _amount.mod(levelDeposit[0]) == 0, "amount err");
        if(isFreezing && !isUnfreezedReward[_userAddr][freezedTimes]) isUnfreezedReward[_userAddr][freezedTimes] = true;
        
        uint256 curDay = getCurDay();
        dayDeposits[curDay] = dayDeposits[curDay].add(_amount);
        totalDeposit = totalDeposit.add(_amount);
        depositors.push(_userAddr);

        if(user.level == 0){
            if(curDay < unlimitDay) require(dayNewbies[curDay].length < getMaxDayNewbies(curDay), "reach max");
            dayNewbies[curDay].push(_userAddr);
            totalUsers = totalUsers + 1;
            user.startTime = block.timestamp;
            if(_types == 0) {
                userRewards.bonusFreezed = _amount.mul(bonusPercents).div(baseDividend);
                user.totalRevenue = user.totalRevenue.add(userRewards.bonusFreezed);
            }
        }
        _updateUplineReward(_userAddr, _amount);
        _unfreezeCapitalOrReward(_userAddr, _amount, _types);
        bool isMaxFreezing = _addNewOrder(_userAddr, _amount, _types, user.startTime, user.isMaxFreezing);
        user.isMaxFreezing = isMaxFreezing;
        _updateUserMax(_userAddr, _amount, userCurMax, curCycle);
        _updateLevel(_userAddr);
        if(isFreezing) _setFreezeReward();
        emit Deposit(_userAddr, _types, _amount, isFreezing);
    }

    function _updateUplineReward(address _userAddr, uint256 _amount) private {
        address upline = userInfo[_userAddr].referrer;
        for(uint256 i = 0; i < invitePercents.length; i++){
            if(upline != address(0)){
                if(!isFreezing || isUnfreezedReward[upline][freezedTimes]){
                    OrderInfo[] storage upOrders = orderInfos[upline];
                    if(upOrders.length > 0){
                        uint256 latestUnFreezeTime = getOrderUnfreezeTime(upline, upOrders.length - 1);
                        uint256 maxFreezing = latestUnFreezeTime > block.timestamp ? upOrders[upOrders.length - 1].amount : 0;
                        uint256 newAmount = maxFreezing < _amount ? maxFreezing : _amount;
                        if(newAmount > 0){
                            RewardInfo storage upRewards = rewardInfo[upline];
                            uint256 reward = newAmount.mul(invitePercents[i]).div(baseDividend);
                            if(i == 0 || (i < 4 && userInfo[upline].level >= 4)){
                                upRewards.invited = upRewards.invited.add(reward);
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            }else if(userInfo[upline].level >= 5){
                                upRewards.l5Freezed = upRewards.l5Freezed.add(reward);
                            }
                        }
                    }
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount, uint256 _types) private {
        (uint256 unfreezed, uint256 rewards) = _unfreezeOrder(_userAddr, _amount);
        if(_types == 0){
            require(_amount > unfreezed, "redeposit only");
        }else if(_types >= 2){
            require(_amount == unfreezed, "redeposit err");
        }

        UserInfo storage user = userInfo[_userAddr];
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        if(unfreezed > 0){
            user.unfreezeIndex = user.unfreezeIndex + 1;
            if(userRewards.bonusFreezed > 0){
                userRewards.bonusReleased = userRewards.bonusFreezed;
                userRewards.bonusFreezed = 0;
            }

            if(rewards > 0) userRewards.statics = userRewards.statics.add(rewards);
            if(_types < 2) userRewards.capitals = userRewards.capitals.add(unfreezed);
        }else{
            uint256 l5Freezed = userRewards.l5Freezed;
            if(l5Freezed > 0){
                rewards = _amount <= l5Freezed ? _amount : l5Freezed;
                userRewards.l5Freezed = l5Freezed.sub(rewards);
                userRewards.l5Released = userRewards.l5Released.add(rewards);
            }
        }
        user.totalRevenue = user.totalRevenue.add(rewards);
        _updateFreezeAndTeamDeposit(_userAddr, _amount, unfreezed);
    }

    function _unfreezeOrder(address _userAddr, uint256 _amount) private returns(uint256 unfreezed, uint256 rewards){
        if(orderInfos[_userAddr].length > 0){
            UserInfo storage user = userInfo[_userAddr];
            OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];
            uint256 orderUnfreezeTime = getOrderUnfreezeTime(_userAddr, user.unfreezeIndex);
            // below lv5, deposit once per cycle
            if(user.level > 0 && user.level < 5) require(block.timestamp >= orderUnfreezeTime, "freezing");
            if(order.isUnfreezed == false && block.timestamp >= orderUnfreezeTime && _amount >= order.amount){
                order.isUnfreezed = true;
                unfreezed = order.amount;
                rewards = order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDividend);
                if(isFreezing){
                    if(user.totalFreezed > user.totalRevenue){
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(rewards > leftCapital){
                            rewards = leftCapital;
                        }
                    }else{
                        rewards = 0;
                    }
                }
            }
        }
    }

    function _updateFreezeAndTeamDeposit(address _userAddr, uint256 _amount, uint256 _unfreezed) private {
        UserInfo storage user = userInfo[_userAddr];
        if(_amount > _unfreezed){
            uint256 incAmount = _amount.sub(_unfreezed);
            user.totalFreezed = user.totalFreezed.add(incAmount);
            address upline = user.referrer;
            for(uint256 i = 0; i < invitePercents.length; i++){
                if(upline != address(0)){
                    UserInfo storage upUser = userInfo[upline];
                    if(user.level == 0 && _userAddr != upline){
                        upUser.teamNum = upUser.teamNum + 1;
                        teamUsers[upline][i].push(_userAddr);
                    }
                    upUser.teamTotalDeposit = upUser.teamTotalDeposit.add(incAmount);
                    if(upline == defaultRefer) break;
                    upline = upUser.referrer;
                }else{
                    break;
                }
            }
        }
    }

    function _addNewOrder(address _userAddr, uint256 _amount, uint256 _types, uint256 _startTime, bool _isMaxFreezing) private returns(bool isMaxFreezing){
        uint256 addFreeze;
        OrderInfo[] storage orders = orderInfos[_userAddr];
        if(_isMaxFreezing){
            isMaxFreezing = true;
        }else{
            if((freezedTimes > 0 && _types == 1) || (!isFreezing && _startTime < freezeTime[freezedTimes])){
                isMaxFreezing = true;
            }else{
                addFreeze = (orders.length).mul(timeStep);
                if(addFreeze > maxAddFreeze) isMaxFreezing = true;
            }
        }
        uint256 unfreeze = isMaxFreezing ? block.timestamp.add(dayPerCycle).add(maxAddFreeze) : block.timestamp.add(dayPerCycle).add(addFreeze);
        orders.push(OrderInfo(_amount, block.timestamp, unfreeze, false));
    }

    function _updateUserMax(address _userAddr, uint256 _amount, uint256 _userCurMax, uint256 _curCycle) internal {
        UserInfo storage user = userInfo[_userAddr];
        if(_amount > user.maxDeposit) user.maxDeposit = _amount;
        userCycleMax[_userAddr][_curCycle] = _userCurMax;
        uint256 nextMaxDepositable;
        if(_amount == _userCurMax){
            uint256 curMaxDepositable = getCurMaxDepositable();
            if(_userCurMax >= curMaxDepositable){
                nextMaxDepositable = curMaxDepositable;
            }else{
                if(_userCurMax < levelDeposit[3]){
                    nextMaxDepositable = _userCurMax.add(levelDeposit[1]);
                }else{
                    nextMaxDepositable = _userCurMax.add(levelDeposit[2]);
                }
            }
        }else{
            nextMaxDepositable = _userCurMax;
        }
        userCycleMax[_userAddr][_curCycle + 1] = nextMaxDepositable;
        user.maxDepositable = nextMaxDepositable;
    }

    function _updateLevel(address _userAddr) private {
        UserInfo storage user = userInfo[_userAddr];
        for(uint256 i = user.level; i < levelDeposit.length; i++){
            if(user.maxDeposit >= levelDeposit[i]){
                if(i < 3){
                    user.level = i + 1;
                }else{
                    (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_userAddr);
                    if(maxTeam >= levelInvite[i] && otherTeam >= levelInvite[i] && user.teamNum >= levelTeam[i]){
                        user.level = i + 1;
                    }
                }
            }
        }
    }

    function withdraw() external {
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        uint256 rewardsStatic = userRewards.statics.add(userRewards.invited).add(userRewards.bonusReleased);
        uint256 incomeFee = rewardsStatic.mul(incomeFeePercents).div(baseDividend);
        usdt.transfer(feeReceiver, incomeFee);        
        uint256 leftReward = rewardsStatic.add(userRewards.l5Released).sub(incomeFee);
        uint256 split = leftReward.mul(splitPercents).div(baseDividend);
        uint256 withdrawable = leftReward.sub(split);
        uint256 capitals = userRewards.capitals;
        userRewards.capitals = 0;
        userRewards.statics = 0;
        userRewards.invited = 0;
        userRewards.bonusReleased = 0;
        userRewards.l5Released = 0;        
        userRewards.split = userRewards.split.add(split);
        userRewards.lastWithdaw = block.timestamp;
        withdrawable = withdrawable.add(capitals);
        usdt.transfer(msg.sender, withdrawable);
        if(!isFreezing) _setFreezeReward();
        emit Withdraw(msg.sender, incomeFee, split, withdrawable);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        uint256 minTransfer = levelDeposit[0];
        require(_amount >= minTransfer && _amount.mod(minTransfer) == 0, "amount err");
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        require(userRewards.split >= _amount, "insufficient split");
        userRewards.split = userRewards.split.sub(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function depositFund(uint256 _amount) external {        
        usdt.transferFrom(msg.sender, address(this), _amount);
		userInfo[msg.sender].totalUsdt = userInfo[msg.sender].totalUsdt.add(_amount);
        emit DepositFund(msg.sender, _amount);
    }

    function transferFund(address _receiver, uint256 _amount) external {
        uint256 minTransfer = levelDeposit[0];
        require(_amount >= minTransfer, "amount err");        
        userInfo[msg.sender].totalUsdt = userInfo[msg.sender].totalUsdt.sub(_amount);
        userInfo[_receiver].totalUsdt = userInfo[_receiver].totalUsdt.add(_amount);
        emit TransferFund(msg.sender, _receiver, _amount);
    }

    function _balActived() private {
        uint256 bal = usdt.balanceOf(address(this));
        for(uint256 i = balReached.length; i > 0; i--){
            if(bal >= balReached[i - 1]){
                balStatus[balReached[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward() private {
        uint256 bal = usdt.balanceOf(address(this));
        for(uint256 i = balReached.length; i > 0; i--){
            if(balStatus[balReached[i - 1]]){
                if(!isFreezing){
                    if(bal < balFreeze[i - 1]){
                        isFreezing = true;
                        freezedTimes = freezedTimes + 1;
                        freezeTime[freezedTimes] = block.timestamp;
                    }
                }else{
                    if(bal >= balUnfreeze[i - 1]){
                        isFreezing = false;
                        unfreezeTime[freezedTimes] = block.timestamp;
                    }
                }
                break;
            }
        }
    }

    function getOrderUnfreezeTime(address _userAddr, uint256 _index) public view returns(uint256 orderUnfreezeTime) {
        OrderInfo storage order = orderInfos[_userAddr][_index];
        orderUnfreezeTime = order.unfreeze;
        if(!isFreezing && !order.isUnfreezed && userInfo[_userAddr].startTime < freezeTime[freezedTimes]){
            orderUnfreezeTime =  order.start.add(dayPerCycle).add(maxAddFreeze);
        }
    }

    function getUserCycleDepositable(address _userAddr, uint256 _cycle) public view returns(uint256 cycleMin, uint256 cycleMax) {
        UserInfo storage user = userInfo[_userAddr];
        if(user.maxDeposit > 0){
            cycleMin = user.maxDeposit;
            cycleMax = userCycleMax[_userAddr][_cycle];
            if(cycleMax == 0) cycleMax = user.maxDepositable;
            uint256 curMaxDepositable = getCurMaxDepositable();
            if(isFreezing){
                if(user.startTime < freezeTime[freezedTimes] && !isUnfreezedReward[_userAddr][freezedTimes]){
                    cycleMin = user.totalFreezed > user.totalRevenue ? cycleMin.mul(unfreezeWithoutIncomePercents).div(baseDividend) : cycleMin.mul(unfreezeWithIncomePercents).div(baseDividend);
                    cycleMax = curMaxDepositable;
                }
            }else{
                if(user.startTime < freezeTime[freezedTimes]) cycleMax = curMaxDepositable;
            }
        }else{
            cycleMin = levelDeposit[0];
            cycleMax = levelDeposit[1];
        }

        if(cycleMin > cycleMax) cycleMin = cycleMax;
    }

    function getTeamDeposit(address _userAddr) public view returns(uint256 maxTeam, uint256 otherTeam, uint256 totalTeam){
        address[] memory directTeamUsers = teamUsers[_userAddr][0];
        for(uint256 i = 0; i < directTeamUsers.length; i++){
            UserInfo storage user = userInfo[directTeamUsers[i]];
            uint256 userTotalTeam = user.teamTotalDeposit.add(user.totalFreezed);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam) maxTeam = userTotalTeam;
            if(i >= maxSearchDepth) break;
        }
        otherTeam = totalTeam.sub(maxTeam);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getCurCycle() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(dayPerCycle);
    }

    function getCurMaxDepositable() public view returns(uint256) {
        return levelDeposit[4].mul(2**freezedTimes);
    }

    function getMaxDayNewbies(uint256 _day) public pure returns(uint256) {
        return initDayNewbies + _day.mul(incNumber).div(incInterval);
    }

    function getOrderLength(address _userAddr) public view returns(uint256) {
        return orderInfos[_userAddr].length;
    }

    function getLatestDepositors(uint256 _length) public view returns(address[] memory latestDepositors) {
        uint256 totalCount = depositors.length;
        if(_length > totalCount) _length = totalCount;
        latestDepositors = new address[](_length);
        for(uint256 i = totalCount; i > totalCount - _length; i--){
            latestDepositors[totalCount - i] = depositors[i - 1];
        }
    }

    function getTeamUsers(address _userAddr, uint256 _layer) public view returns(address[] memory) {
        return teamUsers[_userAddr][_layer];
    }

    function getDayInfos(uint256 _day) external view returns(address[] memory newbies, uint256 deposits){
        return (dayNewbies[_day], dayDeposits[_day]);
    }

    function getBalStatus(uint256 _bal) external view returns(bool) {
        return balStatus[_bal];
    }

    function getUserCycleMax(address _userAddr, uint256 _cycle) external view returns(uint256){
        return userCycleMax[_userAddr][_cycle];
    }

    function getUserInfos(address _userAddr) external view returns(UserInfo memory user, RewardInfo memory reward, OrderInfo[] memory orders, bool unfreeze) {
        user = userInfo[_userAddr];
        reward = rewardInfo[_userAddr];
        orders = orderInfos[_userAddr];
        unfreeze = isUnfreezedReward[_userAddr][freezedTimes];
    }

    function getContractInfos() external view returns(address[3] memory infos0, uint256[10] memory infos1, bool freezing) {
        infos0[0] = address(usdt);
        infos0[1] = feeReceiver;
        infos0[2] = defaultRefer;
        infos1[0] = startTime;
        infos1[1] = lastDistribute;
        infos1[2] = totalUsers;
        infos1[3] = totalDeposit;
        infos1[4] = freezedTimes;
        infos1[5] = freezeTime[freezedTimes];
        infos1[6] = unfreezeTime[freezedTimes];
        freezing = isFreezing;
    }   
}