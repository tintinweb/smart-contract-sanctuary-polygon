/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;



/**

 * @dev Interface of the ERC20 standard as defined in the EIP.

 */

interface IERC20 {

    /**

     * @dev Returns the amount of tokens in existence.

     */

    function totalSupply() external view returns (uint256);



    /**

     * @dev Returns the amount of tokens owned by `account`.

     */

    function balanceOf(address account) external view returns (uint256);



    /**

     * @dev Moves `amount` tokens from the caller's account to `recipient`.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transfer(address recipient, uint256 amount) external returns (bool);



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

     * @dev Moves `amount` tokens from `sender` to `recipient` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



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

}






contract MetaBolt {



    IERC20 public DAI;

    uint256 private constant baseDivider = 10000;

    uint256 private constant feePercents = 200; // fee deducted on every deposit

    uint256 private constant minDeposit = 10e6; // 10 DAI

    uint256 private constant maxDeposit = 500e6; // 500 DAI

    uint256 private constant freezeIncomePercents = 3000;

    uint256 private constant timeStep = 1 days;

    uint256 private  constant aliveRoyalityExipiry = 60 days;

    uint256 private constant dayPerCycle = 10 days; 

    uint256 private constant dayRewardPercents = 170; // 1.7 % per day yield

    uint256 private constant maxAddFreeze = 51 days; // 51 days

    uint256 private constant referDepth = 20; // 20 levels



    uint256 private constant directPercents = 500; // direct income

    uint256[4] private level4Percents = [300, 200, 100, 100]; // level 2 to 5 income

    uint256[15] private level5Percents = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50]; // level 5 to 20 income



    uint256 private constant luckPoolPercents = 50; // global pool

    uint256 private constant starPoolPercents = 30; // four star player

    uint256 private constant topPoolPercents = 20; // top3 reward income



    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];

    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 

    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];

    mapping(uint256=>bool) public balStatus; // bal=>status



    address[2] public feeReceivers;



    address public defaultRefer;

    uint256 public startTime;

    uint256 public lastDistribute;

    uint256 public totalUser; 

    uint256 public luckPool;

    uint256 public starPool;

    uint256 public topPool;


    mapping(uint256=>address[]) public dayLuckUsers;

    mapping(uint256=>uint256[]) public dayLuckUsersDeposit;

    mapping(uint256=>uint256[]) public dayGlobalBusiness;

    address[] public AliveRoyalityUser;

    mapping(uint256=>address[3]) public dayTopUsers;



    address[] public level4Users;



    struct OrderInfo {

        uint256 amount; 

        uint256 start;

        uint256 unfreeze; 

        bool isUnfreezed;

    }



    mapping(address => OrderInfo[]) public orderInfos;



    address[] public depositors;



    struct UserInfo {

        address referrer;

        uint256 start;

        uint256 level; // 0, 1, 2, 3, 4, 5

        uint256 direct;

        uint256 maxDeposit;

        uint256 totalDeposit;

        uint256 teamNum;

        uint256 maxDirectDeposit;

        uint256 teamTotalDeposit;

        uint256 totalFreezed;

        uint256 totalRevenue;

        uint aliveRoyalityValidity;

    }



    mapping(address=>UserInfo) public userInfo;

    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount

    mapping(address => mapping(uint256 => address[])) public teamUsers;



    struct RewardInfo{

        uint256 capitals;

        uint256 statics;

        uint256 directs;

        uint256 level4Freezed;

        uint256 level4Released;

        uint256 level5Left;

        uint256 level5Freezed;

        uint256 level5Released;

        uint256 star;

        uint256 luck;

        uint256 top;

        uint256 split;

        uint256 splitDebt;

       

        uint aliveRoyalityReward;

    

    }



    mapping(address=>RewardInfo) public rewardInfo;

    

    bool public isFreezeReward;



    event Register(address user, address referral);

    event Deposit(address user, uint256 amount);

    event DepositBySplit(address user, uint256 amount);

    event TransferBySplit(address user, address receiver, uint256 amount);

    event Withdraw(address user, uint256 withdrawable);



    constructor(address _daiAddr, address _defaultRefer, address[2] memory _feeReceivers)  {

        DAI = IERC20(_daiAddr);

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

        user.start = block.timestamp;

        _updateTeamNum(msg.sender);

        totalUser = totalUser+(1);


        emit Register(msg.sender, _referral);

    }



    function deposit(uint256 _amount) external {

        DAI.transferFrom(msg.sender, address(this), _amount);

        _deposit(msg.sender, _amount);

        uint day = getCurDay();

        dayGlobalBusiness[day].push(_amount);

        if(userInfo[msg.sender].totalDeposit==0){

            address sponser = userInfo[msg.sender].referrer;
            userInfo[sponser].direct++;
          

            _updateAliveRoyality(sponser); // update 
        }

        emit Deposit(msg.sender, _amount);

    }



    function depositBySplit(uint256 _amount) external {

        require(_amount >= minDeposit && _amount%(minDeposit) == 0, "amount err");

        require(userInfo[msg.sender].totalDeposit == 0, "actived");

        uint256 splitLeft = getCurSplit(msg.sender);

        require(splitLeft >= _amount, "insufficient split");

        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt+(_amount);

        _deposit(msg.sender, _amount);

        emit DepositBySplit(msg.sender, _amount);

    }



    function transferBySplit(address _receiver, uint256 _amount) external {

        require(_amount >= minDeposit && _amount%(minDeposit) == 0, "amount err");

        uint256 splitLeft = getCurSplit(msg.sender);

        require(splitLeft >= _amount, "insufficient income");

        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt+(_amount);

        rewardInfo[_receiver].split = rewardInfo[_receiver].split+(_amount);

        emit TransferBySplit(msg.sender, _receiver, _amount);

    }



    function distributePoolRewards() public {

        if(block.timestamp > lastDistribute+(timeStep)){

            uint256 dayNow = getCurDay();

            _distributeStarPool(); // pool distribution


            _distributeGlobalRoyality(dayNow); // global Royality


            _distributeTopPool(dayNow); //  top 3Percent reward

            _distributeAliveRoyality(dayNow); // aliveRoyality
            


            lastDistribute = block.timestamp;

        }

    }



    function withdraw() external {

        distributePoolRewards();

        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(msg.sender);

        uint256 splitAmt = staticSplit;

        uint256 withdrawable = staticReward;



        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(msg.sender);

        withdrawable = withdrawable+(dynamicReward);

        splitAmt = splitAmt+(dynamicSplit);



        RewardInfo storage userRewards = rewardInfo[msg.sender];

        userRewards.split = userRewards.split+(splitAmt);



        userRewards.statics = 0;



        userRewards.directs = 0;

        userRewards.level4Released = 0;

        userRewards.level5Released = 0;

        

        userRewards.luck = 0;

        userRewards.star = 0;

        userRewards.top = 0;

        

        withdrawable = withdrawable+(userRewards.capitals);

        userRewards.capitals = 0;

        

        DAI.transfer(msg.sender, withdrawable);

        uint256 bal = DAI.balanceOf(address(this));

        _setFreezeReward(bal);



        emit Withdraw(msg.sender, withdrawable);

    }



    function getCurDay() public view returns(uint256) {

        return (block.timestamp-(startTime))/(timeStep);

    }



    function getDayLuckLength(uint256 _day) external view returns(uint256) {

        return dayLuckUsers[_day].length;

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

        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){

            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit+(userInfo[teamUsers[_user][0][i]].totalDeposit);

            totalTeam = totalTeam+(userTotalTeam);

            if(userTotalTeam > maxTeam){

                maxTeam = userTotalTeam;

            }

        }

        otherTeam = totalTeam-(maxTeam);

        return(maxTeam, otherTeam, totalTeam);

    }



    function getCurSplit(address _user) public view returns(uint256){

        (, uint256 staticSplit) = _calCurStaticRewards(_user);

        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);

        return rewardInfo[_user].split+(staticSplit)+(dynamicSplit)-(rewardInfo[_user].splitDebt);

    }



    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {

        RewardInfo storage userRewards = rewardInfo[_user];

        uint256 totalRewards = userRewards.statics;

        uint256 splitAmt = totalRewards*(freezeIncomePercents)/(baseDivider);

        uint256 withdrawable = totalRewards-(splitAmt);

        return(withdrawable, splitAmt);

    }



    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {

        RewardInfo storage userRewards = rewardInfo[_user];

        uint256 totalRewards = userRewards.directs+(userRewards.level4Released)+(userRewards.level5Released);

        totalRewards = totalRewards+(userRewards.luck+(userRewards.star)+(userRewards.top));

        uint256 splitAmt = totalRewards*(freezeIncomePercents)/(baseDivider);

        uint256 withdrawable = totalRewards-(splitAmt);

        return(withdrawable, splitAmt);

    }



    function _updateTeamNum(address _user) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                userInfo[upline].teamNum = userInfo[upline].teamNum+(1);

                teamUsers[upline][i].push(_user);

                _updateLevel(upline);

                if(upline == defaultRefer) break;

                upline = userInfo[upline].referrer;

            }else{

                break;

            }

        }

    }



    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow) private {

        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user]+(_amount);

        bool updated;

        for(uint256 i = 0; i < 3; i++){

            address topUser = dayTopUsers[_dayNow][i];

            if(topUser == _user){

                _reOrderTop(_dayNow);

                updated = true;

                break;

            }

        }

        if(!updated){

            address lastUser = dayTopUsers[_dayNow][2];

            if(userLayer1DayDeposit[_dayNow][lastUser] < userLayer1DayDeposit[_dayNow][_user]){

                dayTopUsers[_dayNow][2] = _user;

                _reOrderTop(_dayNow);

            }

        }

    }



    function _reOrderTop(uint256 _dayNow) private {

        for(uint256 i = 3; i > 1; i--){

            address topUser1 = dayTopUsers[_dayNow][i - 1];

            address topUser2 = dayTopUsers[_dayNow][i - 2];

            uint256 amount1 = userLayer1DayDeposit[_dayNow][topUser1];

            uint256 amount2 = userLayer1DayDeposit[_dayNow][topUser2];

            if(amount1 > amount2){

                dayTopUsers[_dayNow][i - 1] = topUser2;

                dayTopUsers[_dayNow][i - 2] = topUser1;

            }

        }

    }



    function _removeInvalidDeposit(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                if(userInfo[upline].teamTotalDeposit > _amount){

                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit-(_amount);

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



    function _updateReferInfo(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit+(_amount);

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

            if(levelNow == 4){

                level4Users.push(_user);

            }

        }

    }



    function _calLevelNow(address _user) private view returns(uint256) {

        UserInfo storage user = userInfo[_user];

        uint256 total = user.totalDeposit;

        uint256 levelNow;

        if(total >= 1000e6){

            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);

            if(total >= 2000e6 && user.teamNum >= 200 && maxTeam >= 50000e6 && otherTeam >= 50000e6){

                levelNow = 5;

            }else if(user.teamNum >= 50 && maxTeam >= 10000e6 && otherTeam >= 10000e6){

                levelNow = 4;

            }else{

                levelNow = 3;

            }

        }else if(total >= 500e6){

            levelNow = 2;

        }else if(total >= 50e6){

            levelNow = 1;

        }



        return levelNow;

    }



    function _deposit(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        require(user.referrer != address(0), "register first");

        require(_amount >= minDeposit, "less than min");

        require(_amount%(minDeposit) == 0 && _amount >= minDeposit, "mod err");

        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");


        if(user.maxDeposit == 0){

            user.maxDeposit = _amount;

        }else if(user.maxDeposit < _amount){

            user.maxDeposit = _amount;

        }


        _distributeDeposit(_amount);


        if(user.totalDeposit == 0){

            uint256 dayNow = getCurDay();

            dayLuckUsers[dayNow].push(_user);

            dayLuckUsersDeposit[dayNow].push(_amount);

            _updateTopUser(user.referrer, _amount, dayNow);

        }



        depositors.push(_user);

        

        user.totalDeposit = user.totalDeposit+(_amount);

        user.totalFreezed = user.totalFreezed+(_amount);



        _updateLevel(msg.sender);



        uint256 addFreeze = (orderInfos[_user].length/(2))*(timeStep);

        if(addFreeze > maxAddFreeze){

            addFreeze = maxAddFreeze;

        }

        uint256 unfreezeTime = block.timestamp+(dayPerCycle)+(addFreeze);

        orderInfos[_user].push(OrderInfo(

            _amount, 

            block.timestamp, 

            unfreezeTime,

            false

        ));



        _unfreezeFundAndUpdateReward(msg.sender, _amount);



        distributePoolRewards();



        _updateReferInfo(msg.sender, _amount);



        _updateReward(msg.sender, _amount);



        _releaseUpRewards(msg.sender, _amount);



        uint256 bal = DAI.balanceOf(address(this));

        _balActived(bal);

        if(isFreezeReward){

            _setFreezeReward(bal);

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

                    user.totalFreezed = user.totalFreezed-(order.amount);

                }else{

                    user.totalFreezed = 0;

                }

                

                _removeInvalidDeposit(_user, order.amount);



                uint256 staticReward = order.amount*(dayRewardPercents)*(dayPerCycle)/(timeStep)/(baseDivider);

                if(isFreezeReward){

                    if(user.totalFreezed > user.totalRevenue){

                        uint256 leftCapital = user.totalFreezed-(user.totalRevenue);

                        if(staticReward > leftCapital){

                            staticReward = leftCapital;

                        }

                    }else{

                        staticReward = 0;

                    }

                }

                rewardInfo[_user].capitals = rewardInfo[_user].capitals+(order.amount);



                rewardInfo[_user].statics = rewardInfo[_user].statics+(staticReward);

                

                user.totalRevenue = user.totalRevenue+(staticReward);



                break;

            }

        }



        if(!isUnfreezeCapital){ 

            RewardInfo storage userReward = rewardInfo[_user];

            if(userReward.level5Freezed > 0){

                uint256 release = _amount;

                if(_amount >= userReward.level5Freezed){

                    release = userReward.level5Freezed;

                }

                userReward.level5Freezed = userReward.level5Freezed-(release);

                userReward.level5Released = userReward.level5Released+(release);

                user.totalRevenue = user.totalRevenue+(release);

            }

        }

    }



    function _distributeStarPool() private {

        uint256 level4Count;

        for(uint256 i = 0; i < level4Users.length; i++){

            if(userInfo[level4Users[i]].level == 4){

                level4Count = level4Count+(1);

            }

        }

        if(level4Count > 0){

            uint256 reward = starPool/(level4Count);

            uint256 totalReward;

            for(uint256 i = 0; i < level4Users.length; i++){

                if(userInfo[level4Users[i]].level == 4){

                    rewardInfo[level4Users[i]].star = rewardInfo[level4Users[i]].star+(reward);

                    userInfo[level4Users[i]].totalRevenue = userInfo[level4Users[i]].totalRevenue+(reward);

                    totalReward = totalReward+(reward);

                }

            }

            if(starPool > totalReward){

                starPool = starPool-(totalReward);

            }else{

                starPool = 0;

            }

        }

    }



    function _distributeGlobalRoyality(uint256 _dayNow) private {

        uint256 dayDepositCount = dayLuckUsers[_dayNow - 1].length;

        if(dayDepositCount > 0){

            uint256 checkCount = 10;

            if(dayDepositCount < 10){

                checkCount = dayDepositCount;

            }

            uint256 totalDeposit;

            uint256 totalReward;

            for(uint256 i = dayDepositCount; i > dayDepositCount-(checkCount); i--){

                totalDeposit = totalDeposit+(dayLuckUsersDeposit[_dayNow - 1][i - 1]);

            }



            for(uint256 i = dayDepositCount; i > dayDepositCount-(checkCount); i--){

                address userAddr = dayLuckUsers[_dayNow - 1][i - 1];

                if(userAddr != address(0)){

                    uint256 reward = luckPool*(dayLuckUsersDeposit[_dayNow - 1][i - 1])/(totalDeposit);

                    totalReward = totalReward+(reward);

                    rewardInfo[userAddr].luck = rewardInfo[userAddr].luck+(reward);

                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue+(reward);

                }

            }

            if(luckPool > totalReward){

                luckPool = luckPool-(totalReward);

            }else{

                luckPool = 0;

            }

        }

    }



    function _distributeTopPool(uint256 _dayNow) private {

        uint16[3] memory rates = [5000, 3000, 2000];

        uint32[3] memory maxReward = [2000e6, 1000e6, 500e6];

        uint256 totalReward;

        for(uint256 i = 0; i < 3; i++){

            address userAddr = dayTopUsers[_dayNow - 1][i];

            if(userAddr != address(0)){

                uint256 reward = topPool*(rates[i])/(baseDivider);

                if(reward > maxReward[i]){

                    reward = maxReward[i];

                }

                rewardInfo[userAddr].top = rewardInfo[userAddr].top+(reward);

                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue+(reward);

                totalReward = totalReward+(reward);

            }

        }

        if(topPool > totalReward){

            topPool = topPool-(totalReward);

        }else{

            topPool = 0;

        }

    }



    function _distributeDeposit(uint256 _amount) private {

        uint256 fee = _amount*(feePercents)/(baseDivider);

        DAI.transfer(feeReceivers[0], fee/(2));

        DAI.transfer(feeReceivers[1], fee/(2));

        uint256 luck = _amount*(luckPoolPercents)/(baseDivider);

        luckPool = luckPool+(luck);

        uint256 star = _amount*(starPoolPercents)/(baseDivider);

        starPool = starPool+(star);

        uint256 top = _amount*(topPoolPercents)/(baseDivider);

        topPool = topPool+(top);

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

                    if(userInfo[upline].level > 4){

                        reward = newAmount*(level5Percents[i - 5])/(baseDivider);

                        upRewards.level5Freezed = upRewards.level5Freezed+(reward);

                    }

                }else if(i > 0){

                    if( userInfo[upline].level > 3){

                        reward = newAmount*(level4Percents[i - 1])/(baseDivider);

                        upRewards.level4Freezed = upRewards.level4Freezed+(reward);

                    }

                }else{

                    reward = newAmount*(directPercents)/(baseDivider);

                    upRewards.directs = upRewards.directs+(reward);

                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue+(reward);

                }

                if(upline == defaultRefer) break;

                upline = userInfo[upline].referrer;

            }else{

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

                if(i > 0 && i < 5 && userInfo[upline].level > 3){

                    if(upRewards.level4Freezed > 0){

                        uint256 level4Reward = newAmount*(level4Percents[i - 1])/(baseDivider);

                        if(level4Reward > upRewards.level4Freezed){

                            level4Reward = upRewards.level4Freezed;

                        }

                        upRewards.level4Freezed = upRewards.level4Freezed-(level4Reward); 

                        upRewards.level4Released = upRewards.level4Released+(level4Reward);

                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue+(level4Reward);

                    }

                }



                if(i >= 5 && userInfo[upline].level > 4){

                    if(upRewards.level5Left > 0){

                        uint256 level5Reward = newAmount*(level5Percents[i - 5])/(baseDivider);

                        if(level5Reward > upRewards.level5Left){

                            level5Reward = upRewards.level5Left;

                        }

                        upRewards.level5Left = upRewards.level5Left-(level5Reward); 

                        upRewards.level5Freezed = upRewards.level5Freezed+(level5Reward);

                    }

                }

                upline = userInfo[upline].referrer;

            }else{

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


    function _distributeAliveRoyality(uint _dayNow) internal {

        // iterate all user

            uint256 dayDepositCount = dayGlobalBusiness[_dayNow - 1].length;

            uint256 totalBusiness;
            uint rewardPerShare;

            for(uint256 i = dayDepositCount; i > dayDepositCount; i--){

                totalBusiness = totalBusiness+(dayGlobalBusiness[_dayNow - 1][i - 1]);
            }

            rewardPerShare = totalBusiness/AliveRoyalityUser.length;


        for (uint i=0;i<AliveRoyalityUser.length;i++){

            uint validity = userInfo[AliveRoyalityUser[i]].aliveRoyalityValidity;

            if(validity>block.timestamp){
                // eligible

                userInfo[AliveRoyalityUser[i]].totalRevenue = userInfo[AliveRoyalityUser[i]].totalRevenue+(rewardPerShare);
                rewardInfo[AliveRoyalityUser[i]].aliveRoyalityReward+(rewardPerShare);
            
            }

        }

       

    }

    function _updateAliveRoyality(address _referral) internal {

        if (userInfo[_referral].direct>=10){

          if(userInfo[_referral].aliveRoyalityValidity==0){

              // expire or fresh position
              AliveRoyalityUser.push(_referral);

              userInfo[_referral].aliveRoyalityValidity=block.timestamp+aliveRoyalityExipiry;
          }

          else if (userInfo[_referral].aliveRoyalityValidity>block.timestamp){
              // not expire extend it 

               userInfo[_referral].aliveRoyalityValidity+=aliveRoyalityExipiry;

          }

        }
    }


    function _setFreezeReward(uint256 _bal) private {

        for(uint256 i = balDown.length; i > 0; i--){

            if(balStatus[balDown[i - 1]]){

                uint256 maxDown = balDown[i - 1]*(balDownRate[i - 1])/(baseDivider);

                if(_bal < balDown[i - 1]-(maxDown)){

                    isFreezeReward = true;

                }else if(isFreezeReward && _bal >= balRecover[i - 1]){

                    isFreezeReward = false;

                }

                break;

            }

        }

    }

 

}