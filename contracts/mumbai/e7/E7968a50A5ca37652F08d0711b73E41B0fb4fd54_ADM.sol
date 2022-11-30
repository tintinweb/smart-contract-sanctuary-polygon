/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0

/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// File: contracts/IERC20.sol


pragma solidity >=0.4.22 <0.8.19;

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
// File: contracts/SafeMath.sol



pragma solidity ^0.8.0;

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

// File: contracts/ADM.sol


pragma solidity ^0.8.0;




contract ADM {
    using SafeMath for uint256; 
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256[2] private feePercents = [180,20]; 
    uint256 private constant minDeposit = 50e6;
    uint256 private constant maxDeposit = 2000e6;
    uint256 private constant timeStep = 1 minutes;
    uint256 private constant dayPerCycle = 7 minutes; 
    uint256 private constant dayRewardPercents = 150;
    uint256 private constant maxAddFreeze = 30 minutes;
    uint256 private constant referDepth = 20;
    bool private freezeStaticReward;
    bool private freezeDynamicReward;
    

    uint256 private constant directPercents = 250;
    uint256[2] private level2Percents = [50, 100];
    uint256[2] private level4Percents = [ 150, 50];
    uint256[15] private level5Percents = [50, 50, 50, 50, 50, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25];
    

    uint256 private constant luckPoolPercents = 50;
    uint256 private constant stbPoolPercents = 30;
    uint256 private constant topPoolPercents = 20;

     
    uint256[3] private balReached = [100e10, 500e10, 1000e10];
    uint256[3] private balFreezeStatic = [70e10, 300e10, 500e10];
    uint256[3] private balFreezeDynamic = [40e10, 150e10, 200e10];
    uint256[3] private balRecover = [150e10, 500e10, 1000e10];

    mapping(uint256=>bool) public balStatus; // bal=>status

    address[2] public feeReceivers;
    address public push_back_fund_wallet;

    address public defaultRefer;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public luckPool;
    uint256 public stbPool;
    uint256 public topPool;

    mapping(uint256=>address[]) public dayLuckUsers;
    mapping(uint256=>uint256[]) public dayLuckUsersDeposit;
    mapping(uint256=>address[3]) public dayTopUsers;
    mapping(address=>bool) private hasUpdateDownline;

    address[] public level5Users;

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
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }

    mapping(address=>UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level2Freezed;
        uint256 level2Released;
        uint256 level4Freezed;
        uint256 level4Released;
        uint256 level5Left;
        uint256 level5Freezed;
        uint256 level5Released;
        uint256 contributor;
        uint256 luck;
        uint256 top;
    }

    mapping(address=>RewardInfo) public rewardInfo;
    
    bool public isFreezeReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(address _usdtAddr, address _defaultRefer, address _pushBackFundWallet, address[2] memory _feeReceivers)  {
        usdt = IERC20(_usdtAddr);
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
        push_back_fund_wallet = _pushBackFundWallet;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > minDeposit || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

     
 
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute.add(timeStep)){
            uint256 dayNow = getCurDay();
            _distributeStbPool();

            _distributeLuckPool(dayNow);

            _distributeTopPool(dayNow);
            lastDistribute = block.timestamp;
        }
    }

    function withdraw() external {
        distributePoolRewards();
        uint256 staticReward = _calCurStaticRewards(msg.sender);
        uint256 withdrawable = staticReward;
        uint256 dynamicReward  = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);

        // if(withdrawable>=10e6)
        // {
        //subtract the 10%
        uint256 _withdrawFee = withdrawable.mul(1000).div(baseDivider);
        //subtract the 10% fee
        withdrawable = withdrawable.sub(_withdrawFee);

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.level2Released = 0;
        userRewards.level4Released = 0;
        userRewards.level5Released = 0;
        userRewards.luck = 0;
        userRewards.contributor= 0;
        userRewards.top = 0;
        
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;
       
            usdt.transfer(msg.sender, withdrawable);
            usdt.transfer(push_back_fund_wallet, _withdrawFee);
            uint256 bal = usdt.balanceOf(address(this));
            _setFreezeReward(bal);
        //}

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
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function getTeamDepositCount(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamNum + 1;
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }
 

    function _calCurStaticRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 withdrawable = totalRewards; //remove splits
        return withdrawable;
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        //add all the released rewards
        uint256 totalRewards = userRewards.directs.add(userRewards.level2Released).add(userRewards.level4Released).add(userRewards.level5Released);
        totalRewards = totalRewards.add(userRewards.luck.add(userRewards.contributor).add(userRewards.top));
        uint256 withdrawable = totalRewards; //remove splits
        return withdrawable ;
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        if(user.totalDeposit >= minDeposit && hasUpdateDownline[_user] == false){
            //only update downline if user makes deposit         
            address upline = user.referrer;
            for(uint256 i = 0; i < referDepth; i++){
                if(upline != address(0)){
                    //only do this if the user has deposited
                    userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                    teamUsers[upline][i].push(_user);
                    _updateLevel(upline);
                    if(upline == defaultRefer) break;
                    upline = userInfo[upline].referrer;
                }else{
                    break;
                }
            }
            hasUpdateDownline[_user] = true;
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

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 5){
                level5Users.push(_user);
            }
        }
    }


    function getMaxDeposit(address _user) private view returns(uint256) {
        uint256 _maxDeposit;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.amount > _maxDeposit){
                    _maxDeposit = order.amount;
            } 
        }
        return _maxDeposit;
    }

    function _calLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = getMaxDeposit(_user);
        uint256 levelNow;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
         (uint256 maxTeamC, uint256 otherTeamC, ) = getTeamDepositCount(_user);

        if(total >= 200e6 && user.teamNum >= 20 && maxTeam >= 4000e6 && otherTeam >= 4000e6 && maxTeamC >= 10 && otherTeamC >= 10){
             levelNow = 5;
        }else if(total >= 200e6 && user.teamNum >= 16 && maxTeam >= 2500e6 && otherTeam >= 2500e6 && maxTeamC >= 8 && otherTeamC >= 8){
             levelNow = 4;
        }else if(total >= 150e6 && user.teamNum >= 10 && maxTeam >= 2000e6 && otherTeam >= 2000e6 && maxTeamC >= 5 && otherTeamC >= 5){
             levelNow = 3;
        }
        else if(total >= 100e6 && user.teamNum >= 6 && maxTeam >= 1000e6 && otherTeam >= 1000e6 && maxTeamC >= 3 && otherTeamC >= 3 ){
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
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
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
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);
        //update downlinw once
        _updateTeamNum(msg.sender);
        
        uint256 addFreeze = (orderInfos[_user].length.div(2)).mul(timeStep);
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
        
        //change the level currently
        _updateLevel(msg.sender);

        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        distributePoolRewards();

        _updateReferInfo(msg.sender, _amount);

        _updateReward(msg.sender, _amount);

        _releaseUpRewards(msg.sender, _amount);

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }

    function getRewardInfos(address _address, uint256 _type) public view returns (uint256, uint256, uint256, uint256, uint256, uint256){
     
     if(_type == 1){
         uint256 _release = rewardInfo[_address].level4Released.add(rewardInfo[_address].level2Released);
         return (rewardInfo[_address].capitals, rewardInfo[_address].statics, rewardInfo[_address].directs, rewardInfo[_address].level4Freezed , _release, 0);
      }
      else{
        return (rewardInfo[_address].level5Left, rewardInfo[_address].level5Freezed, rewardInfo[_address].level5Released, rewardInfo[_address].contributor, rewardInfo[_address].luck, rewardInfo[_address].top);
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
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                
                user.totalRevenue = user.totalRevenue.add(staticReward);

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
                userReward.level5Freezed = userReward.level5Freezed.sub(release);
                userReward.level5Released = userReward.level5Released.add(release);
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
    }

    function _distributeStbPool() private {
        uint256 level5Count;
        for(uint256 i = 0; i < level5Users.length; i++){
            if(userInfo[level5Users[i]].level == 4){
                level5Count = level5Count.add(1);
            }
        }
        if(level5Count > 0){
            uint256 reward = stbPool.div(level5Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level5Users.length; i++){
                if(userInfo[level5Users[i]].level == 5){
                    rewardInfo[level5Users[i]].contributor= rewardInfo[level5Users[i]].contributor.add(reward);
                    userInfo[level5Users[i]].totalRevenue = userInfo[level5Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(stbPool > totalReward){
                stbPool = stbPool.sub(totalReward);
            }else{
                stbPool = 0;
            }
        }
    }

    
    function _distributeLuckPool(uint256 _dayNow) private {
        uint256 dayDepositCount = dayLuckUsers[_dayNow - 1].length;
        if(dayDepositCount > 0){
            uint256 checkCount = 10;
            if(dayDepositCount < 10){
                checkCount = dayDepositCount;
            }
            uint256 totalDeposit;
            uint256 totalReward;
            for(uint256 i = dayDepositCount; i > dayDepositCount.sub(checkCount); i--){
                totalDeposit = totalDeposit.add(dayLuckUsersDeposit[_dayNow - 1][i - 1]);
            }

            for(uint256 i = dayDepositCount; i > dayDepositCount.sub(checkCount); i--){
                address userAddr = dayLuckUsers[_dayNow - 1][i - 1];
                if(userAddr != address(0)){
                    uint256 reward = luckPool.mul(dayLuckUsersDeposit[_dayNow - 1][i - 1]).div(totalDeposit);
                    totalReward = totalReward.add(reward);
                    rewardInfo[userAddr].luck = rewardInfo[userAddr].luck.add(reward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                }
            }
            if(luckPool > totalReward){
                luckPool = luckPool.sub(totalReward);
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
                uint256 reward = topPool.mul(rates[i]).div(baseDivider);
                if(reward > maxReward[i]){
                    reward = maxReward[i];
                }
                rewardInfo[userAddr].top = rewardInfo[userAddr].top.add(reward);
                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                totalReward = totalReward.add(reward);
            }
        }
        if(topPool > totalReward){
            topPool = topPool.sub(totalReward);
        }else{
            topPool = 0;
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee_1 = _amount.mul(feePercents[0]).div(baseDivider); //1.8percents
        uint256 fee_2 =  _amount.mul(feePercents[1]).div(baseDivider); //0.2percents
        usdt.transfer(feeReceivers[0], fee_1);
        usdt.transfer(feeReceivers[1], fee_2);
        uint256 luck = _amount.mul(luckPoolPercents).div(baseDivider);
        luckPool = luckPool.add(luck);
        uint256 stb = _amount.mul(stbPoolPercents).div(baseDivider);
        stbPool = stbPool.add(stb);
        uint256 top = _amount.mul(topPoolPercents).div(baseDivider);
        topPool = topPool.add(top);
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
              

              if(i==0){
                     
                     reward = newAmount.mul(directPercents).div(baseDivider);
                     upRewards.directs = upRewards.directs.add(reward);                       
                     userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);

               }else if(i>=6 ) {
                                        if(userInfo[upline].level >=5  ){
                                            reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider);
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
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                 
                  if(i ==1 && userInfo[upline].level== 2){
                    if(upRewards.level2Freezed > 0){
                        uint256 level3Reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                        if(level3Reward > upRewards.level2Freezed){
                            level3Reward = upRewards.level2Freezed;
                        }
                        upRewards.level2Freezed = upRewards.level2Freezed.sub(level3Reward); 
                        upRewards.level2Released = upRewards.level2Released.add(level3Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level3Reward);
                    }
                }

                if(i ==2 && userInfo[upline].level==3){
                    if(upRewards.level2Freezed > 0){
                        uint256 level3Reward = newAmount.mul(level2Percents[i - 1]).div(baseDivider);
                        if(level3Reward > upRewards.level2Freezed){
                            level3Reward = upRewards.level2Freezed;
                        }
                        upRewards.level2Freezed = upRewards.level2Freezed.sub(level3Reward); 
                        upRewards.level2Released = upRewards.level2Released.add(level3Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level3Reward);
                    }
                }


                if(i >= 3 && i <=4 && userInfo[upline].level==4){
                    if(upRewards.level4Freezed > 0){
                        uint256 level4Reward = newAmount.mul(level4Percents[i - 3]).div(baseDivider);
                        if(level4Reward > upRewards.level4Freezed){
                            level4Reward = upRewards.level4Freezed;
                        }
                        upRewards.level4Freezed = upRewards.level4Freezed.sub(level4Reward); 
                        upRewards.level4Released = upRewards.level4Released.add(level4Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level4Reward);
                    }
                }

                if(i >= 5 && userInfo[upline].level > 4 ){
                    if(upRewards.level5Left > 0){
                        uint256 level5Reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider);
                        if(level5Reward > upRewards.level5Left){
                            level5Reward = upRewards.level5Left;
                        }

                        upRewards.level5Left = upRewards.level5Left.sub(level5Reward); 
                        upRewards.level5Freezed = upRewards.level5Freezed.add(level5Reward);
                    }
                }
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        } 
    } 
 
    function _balActived(uint256 _bal) private {
        for(uint256 i = balReached.length; i > 0; i--){
            if(_bal >= balReached[i - 1]){
                balStatus[balReached[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balReached.length; i > 0; i--){
            if(balStatus[balReached[i - 1]]){
                if(_bal < balFreezeStatic[i - 1]){
                    freezeStaticReward = true;
                    if(_bal < balFreezeDynamic[i - 1]){
                        freezeDynamicReward = true;
                    }
                }else{
                    if((freezeStaticReward || freezeDynamicReward) && _bal >= balRecover[i - 1]){
                        freezeStaticReward = false;
                        freezeDynamicReward = false;
                    }
                }
                break;
            }
        }
    }
 
}