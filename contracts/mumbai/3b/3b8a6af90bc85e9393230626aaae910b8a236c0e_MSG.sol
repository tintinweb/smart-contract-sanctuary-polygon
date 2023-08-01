/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: newmsg.sol



pragma solidity ^0.8.18;




contract MSG is Ownable{
    using SafeMath for uint256; 
    uint256 private constant timeStep =  1 minutes;
    uint256 private constant dayPerCycle = 5 minutes; 
    uint256 private constant maxAddFreeze = 30 minutes;
    uint256 private constant predictDuration = 30 minutes;
    uint256 private constant initDayNewbies = 5;
    uint256 private constant incInterval = 2;
    uint256 private constant incNumber = 1;
    uint256 private constant unlimitDay = 150;
    uint256 private constant predictFee = 1e6;
    uint256 private constant dayPredictLimit = 10;
    uint256 private constant maxSearchDepth = 3000;
    uint256 private constant baseDividend = 10000;
    uint256 private constant incomeFeePercents = 1000;
    uint256 private constant bonusPercents = 500;
    uint256 private constant splitPercents = 3000;
    uint256 private constant CTOPoolPercents = 100;
    uint256 private constant transferFeePercents = 1000;
    uint256 private constant dayRewardPercents = 150;
    uint256 private constant predictPoolPercents = 300;
    uint256 private constant unfreezeWithoutIncomePercents = 15000;
    uint256 private constant unfreezeWithIncomePercents = 20000;
    // uint256[5] private levelTeam = [0, 0, 0, 50, 200];
    uint256[5] private levelTeam = [0, 0, 2, 4, 6];
    uint256[5] private levelInvite = [0, 0, 2000e6, 4000e6, 6000e6];
    // uint256[5] private levelDeposit = [50e6, 500e6, 1000e6, 2000e6, 3000e6];
    uint256[5] private levelDeposit = [25e6, 500e6, 1000e6, 2000e6, 3000e6];
    uint256[5] private balReached = [50e10, 100e10, 200e10, 500e10, 1000e10];
    uint256[5] private balFreeze = [35e10, 70e10, 100e10, 300e10, 500e10];
    uint256[5] private balUnfreeze = [80e10, 150e10, 200e10, 500e10, 1000e10];
    uint256[20] private invitePercents = [500, 100, 200, 300, 200, 100, 100, 100, 50, 50, 50, 50, 30, 30, 30, 30, 30, 30, 30, 30];
    uint256[20] private predictWinnerPercents = [3000, 2000, 1000, 500, 500, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200];

    IERC20 private usdt;
    address public defaultRefer;
    uint256 public startTime;
    uint256 private lastDistribute;
    uint256 private totalUsers;
    uint256 private totalDeposit;
    uint256 private freezedTimes;
    uint256 private predictPool;
    uint256 private totalPredictPool;
    uint256 private totalWinners;
    bool private isFreezing;
    uint256 public deployTime;
    uint256 public totalCTO ;
    address[] private depositors;
    address[] public CTOUser;

    address public wallet1;
    address public wallet2;
    address public wallet3;
    address public wallet4;

    mapping(uint256=>bool) private balStatus;
    mapping(uint256=>address[]) private dayNewbies;
    mapping(uint256=>uint256) private freezeTime;
    mapping(uint256=>uint256) private unfreezeTime;
    mapping(uint256=>uint256) private dayPredictPool;
    mapping(uint256=>uint256) private dayDeposits;
    mapping(address=>mapping(uint256=>bool)) private isUnfreezedReward;
    mapping(uint256=>mapping(uint256=>address[])) private dayPredictors;
    mapping(uint256=>mapping(address=>PredictInfo[])) private userPredicts;
    
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
        uint256 predictWin;
        uint256 split;
        uint256 CTO;
        uint256 lastWithdaw;
    }
    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
    }
    struct PredictInfo {
        uint256 time;
        uint256 number;
    }
    mapping(uint256 => uint256) public daybalance;
    mapping(uint256 => uint256) private balancePerDay;
    mapping(uint256 => bool) public daycheck;
    mapping (address => bool) private isAdded;
    mapping(address=>UserInfo) private userInfo;
    mapping(address=>RewardInfo) private rewardInfo;
    mapping(address=>OrderInfo[]) private orderInfos;
    mapping(address=>mapping(uint256=>uint256)) private userCycleMax;
    mapping(address=>mapping(uint256=>address[])) private teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 types, uint256 amount, bool isFreezing);
    event TransferBySplit(address user, uint256 subBal, address receiver, uint256 amount);
    event Withdraw(address user, uint256 incomeFee, uint256 poolFee, uint256 split, uint256 withdraw);
    event Predict(uint256 time, address user, uint256 amount);
    event DistributePredictPool(uint256 day, uint256 reward, uint256 pool, uint256 time);

    constructor(address _usdtAddr, address _defaultRefer, uint256 _startTime) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        startTime = _startTime;
        deployTime = block.timestamp;
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
            require(_amount.mod(levelDeposit[0].mul(2)) == 0, "amount err");
            userRewards.split = userRewards.split.sub(_amount);
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
        getdayBalance();
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
                            if(i == 0 || (i < 4 && userInfo[upline].level >= 3)){
                                upRewards.invited = upRewards.invited.add(reward);
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            }else if(userInfo[upline].level >= 5){
                                upRewards.l5Freezed = upRewards.l5Freezed.add(reward);
                            }
                        }
                        if(userInfo[upline].level >= 3){
                            (bool _isAvailables,) = CTOIncomeIsReady(upline);
                            if(!_isAvailables && !isAdded[upline])
                            { 
                                CTOUser.push(upline); 
                                isAdded[upline] = true;
                        }   }
                    }
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

        function getdayBalance() private {
        uint256 day = getCurDay();
        if(!daycheck[day])
        {
            daybalance[day] = usdt.balanceOf(address(this));
            daycheck[day] = true;
            if(day > 0)
            {
                if(daybalance[day] > daybalance[day-1])
                { balancePerDay[day-1] = daybalance[day] .sub(daybalance[day-1]); }
                else 
                { balancePerDay[day-1]  = 0 ; }
                _distributeCTOPOol(day-1);
            }
        } 
    }

    function _distributeCTOPOol(uint256 previousDay) internal {
        
        balancePerDay[previousDay];

        uint256 CTOPoolCount = CTOUser.length;
        if (CTOPoolCount > 0) {
            uint256 rewardPerUser = balancePerDay[previousDay].mul(CTOPoolPercents).div(baseDividend).div(CTOPoolCount); // 1% of contract balance divided by CTO Pool count
            
            for (uint256 i = 0; i < CTOPoolCount; i++) {
                address userAddr = CTOUser[i];
                // Distribute the reward to the qualified user
                rewardInfo[userAddr].CTO = rewardInfo[userAddr].CTO.add(rewardPerUser);
                totalCTO = totalCTO.add(rewardPerUser);    
            }
        }
    }

    function CTOIncomeIsReady(address _address) public view returns (bool, uint256) {
    UserInfo storage user = userInfo[_address];

    // Check if the user meets the required level and has a sufficient deposit
    if (user.level == 3 && user.maxDeposit >= levelDeposit[user.level]) {
        // Check if the user's team size meets the required condition
        if (user.teamNum >= levelTeam[user.level]) {
            uint256 maxTeam;
            uint256 otherTeam;
            uint256 totalTeam;

            // Get the team deposit for the user
            (maxTeam, otherTeam, totalTeam) = getTeamDeposit(_address);

            // Check if the total team deposit meets the required condition
            if (totalTeam >= levelInvite[user.level]) {
                // Check if the max and other team deposits meet the required conditions
                if (maxTeam >= levelInvite[user.level] && otherTeam >= levelInvite[user.level] ) {
                    // User meets all the required conditions, return true and the user's level
                    return (true, user.level);
                }
            }
        }
    }
    // User doesn't meet the requirements
    return (false, 0);
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
        uint256 rewardsStatic = userRewards.statics.add(userRewards.invited).add(userRewards.bonusReleased).add(userRewards.predictWin).add(userRewards.CTO);
        uint256 incomeFee = rewardsStatic.mul(incomeFeePercents).div(baseDividend);
       (uint256 share1,uint256 share2,uint256 share3,uint256 share4) = calculateTokenDistribution(incomeFee);
        usdt.transfer(wallet1, share1);
        usdt.transfer(wallet2, share2);
        usdt.transfer(wallet3, share3);
        usdt.transfer(wallet4, share4);
        uint256 predictPoolFee = rewardsStatic.mul(predictPoolPercents).div(baseDividend);
        predictPool = predictPool.add(predictPoolFee);
        totalPredictPool = totalPredictPool.add(predictPoolFee);
        uint256 leftReward = rewardsStatic.add(userRewards.l5Released).sub(incomeFee).sub(predictPoolFee);
        uint256 split = leftReward.mul(splitPercents).div(baseDividend);
        uint256 withdrawable = leftReward.sub(split);
        uint256 capitals = userRewards.capitals;
        userRewards.capitals = 0;
        userRewards.statics = 0;
        userRewards.invited = 0;
        userRewards.bonusReleased = 0;
        userRewards.l5Released = 0;
        userRewards.predictWin = 0;
        userRewards.CTO = 0;
        userRewards.split = userRewards.split.add(split);
        userRewards.lastWithdaw = block.timestamp;
        withdrawable = withdrawable.add(capitals);
        usdt.transfer(msg.sender, withdrawable);
        if(!isFreezing) _setFreezeReward();
        emit Withdraw(msg.sender, incomeFee, predictPoolFee, split, withdrawable);
    }

    function predict(uint256 _amount) external {
        require(userInfo[msg.sender].referrer != address(0), "not register");
        require(_amount.mod(levelDeposit[0]) == 0, "amount err");
        uint256 curDay = getCurDay();
        require(userPredicts[curDay][msg.sender].length < dayPredictLimit, "reached day limit");
        uint256 predictEnd = startTime.add(curDay.mul(timeStep)).add(predictDuration);
        require(block.timestamp < predictEnd, "today is over");
        usdt.transferFrom(msg.sender, address(this), predictFee);
        dayPredictors[curDay][_amount].push(msg.sender);
        userPredicts[curDay][msg.sender].push(PredictInfo(block.timestamp, _amount));
        if(isFreezing) _setFreezeReward();
        emit Predict(block.timestamp, msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        uint256 minTransfer = levelDeposit[0].mul(2);
        require(_amount >= minTransfer && _amount.mod(minTransfer) == 0, "amount err");
        uint256 subBal = _amount.add(_amount.mul(transferFeePercents).div(baseDividend));
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        require(userRewards.split >= subBal, "insufficient split");
        userRewards.split = userRewards.split.sub(subBal);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, subBal, _receiver, _amount);
    }

    function distributePredictPool() external {
        if(block.timestamp >= lastDistribute.add(timeStep)){
            uint256 curDay = getCurDay();
            uint256 lastDay = curDay - 1;
            uint256 totalReward;
            if(predictPool > 0){
                address[] memory winners = getPredictWinners(lastDay);
                for(uint256 i = 0; i < winners.length; i++){
                    if(winners[i] != address(0)){
                        uint256 reward = predictPool.mul(predictWinnerPercents[i]).div(baseDividend);
                        totalReward = totalReward.add(reward);
                        rewardInfo[winners[i]].predictWin = rewardInfo[winners[i]].predictWin.add(reward);
                        userInfo[winners[i]].totalRevenue = userInfo[winners[i]].totalRevenue.add(reward);
                        totalWinners++;
                    }else{
                        break;
                    }
                }
                dayPredictPool[lastDay] = predictPool;
                predictPool = predictPool > totalReward ? predictPool.sub(totalReward) : 0;
            }
            lastDistribute = startTime.add(curDay.mul(timeStep));
            emit DistributePredictPool(lastDay, totalReward, predictPool, lastDistribute);
        }
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

    function calculateTokenDistribution(uint256 _amount) public pure returns (uint256, uint256, uint256, uint256) {
        require(_amount > 0, "Amount should be greater than zero");

        uint256 wallet1Share = (_amount.mul(2)).div(100); // 2% of the amount
        uint256 wallet2Share = (_amount.mul(2)).div(100); // 2% of the amount
        uint256 wallet3Share = (_amount.mul(2)).div(100); // 2% of the amount
        uint256 wallet4Share = (_amount.mul(4)).div(100); // 2% of the amount


        return (wallet1Share, wallet2Share, wallet3Share, wallet4Share);
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

    function getPredictWinners(uint256 _day) public view returns(address[] memory winners) {
        uint256 steps = dayDeposits[_day].div(levelDeposit[0]);
        uint256 maxWinners = predictWinnerPercents.length;
        winners = new address[](maxWinners);
        uint256 counter;
        for(uint256 i = steps; i >= 0; i--){
            uint256 winAmount = i.mul(levelDeposit[0]);
            for(uint256 j = 0; j < dayPredictors[_day][winAmount].length; j++){
                address predictUser = dayPredictors[_day][winAmount][j];
                if(predictUser != address(0)){
                    winners[counter] = predictUser;
                    counter++;
                    if(counter >= maxWinners) break;
                }
            }
            if(counter >= maxWinners || i == 0 || steps.sub(i) >= maxSearchDepth) break;
        }
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

    // function getCurCycle() public view returns(uint256) {
    //     return (block.timestamp.sub(startTime)).div(dayPerCycle);
    // }

    function getCurCycle() public view returns(uint256) {

        uint256 currentDay = (block.timestamp.sub(startTime)).div(dayPerCycle);
        uint256 cycleCount = 1;
        uint256 daysInCycle = 10; // Initial number of days in a cycle
        
        while (currentDay >= daysInCycle) {
            currentDay = currentDay.sub(daysInCycle);
            cycleCount = cycleCount.add(1);
            
            // Increment the number of days in the next cycle by 1
            daysInCycle = daysInCycle.add(1);
            
            if (daysInCycle > 40) {
                daysInCycle = 40; // Set the maximum number of days in a cycle to 40
            }
        }
        
        return cycleCount;
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

    function getUserDayPredicts(address _userAddr, uint256 _day) public view returns(PredictInfo[] memory) {
        return userPredicts[_day][_userAddr];
    }

    function getDayPredictors(uint256 _day, uint256 _number) external view returns(address[] memory) {
        return dayPredictors[_day][_number];
    }

    function getDayInfos(uint256 _day) external view returns(address[] memory newbies, uint256 deposits, uint256 pool){
        return (dayNewbies[_day], dayDeposits[_day], dayPredictPool[_day]);
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

    function setWalletAddresses(address[] memory wallets) external onlyOwner {
        require(wallets.length == 4, "Invalid number of wallet addresses");

        for (uint256 i = 0; i < wallets.length; i++) {
            require(wallets[i] != address(0), "Wallet address cannot be zero");
        }

        wallet1 = wallets[0];
        wallet2 = wallets[1];
        wallet3 = wallets[2];
        wallet4 = wallets[3];

    }

    function getContractInfos() external view returns(address[2] memory infos0, uint256[10] memory infos1, bool freezing) {
        infos0[0] = address(usdt);
        infos0[1] = defaultRefer;
        infos1[0] = startTime;
        infos1[1] = lastDistribute;
        infos1[2] = totalUsers;
        infos1[3] = totalDeposit;
        infos1[4] = predictPool;
        infos1[5] = totalPredictPool;
        infos1[6] = totalWinners;
        infos1[7] = freezedTimes;
        infos1[8] = freezeTime[freezedTimes];
        infos1[9] = unfreezeTime[freezedTimes];
        freezing = isFreezing;
    }
}