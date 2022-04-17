/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: coin.sol


pragma solidity ^0.8.0;





contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
   
    string public constant name = "TrippyEggs DeFi Token";
    string public constant symbol = "TED";
    uint8 public constant decimals = 12;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

 
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
contract Events is ERC20 {

    event StakeStart(
        uint256  timestamp,   
        uint256  burnedTEDs,
        uint256  hiddenCandy,
        uint256  stakedDays,  
        address indexed stakerAddr,
        uint40 indexed stakeId
    );


    event StakeEnd(
        uint256  timestamp,   
        uint256  burnedTEDs,
        uint256  hiddenCandy,
        uint256  payout,      
        uint256  servedDays,  
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    event DailyEggHuntRefresh(
        uint256  timestamp,       
        uint256  indexed beginDay,        
        uint256  endDay,
        bool    isAutoUpdate,    
        address indexed updaterAddr
    );

    event CandyPriceChange(
       uint256   timestamp,
        uint256   candyPrice,
        uint40 indexed stakeId
    );

    event CandySale(
       uint256   timestamp,
        uint256   candyPrice
        
    );

}

contract Structs is Events{
    
    struct GlobalHuntCache {
        uint256 _burnedTEDsTotal;
        uint256 _nextHiddenCandyTotal;
        uint256 _candyPrice;
        uint256 _dailyEggHuntCount;
        uint256 _hiddenCandyTotal;
        uint40 _latestStakeId;   
        uint256 _currentDay;
        uint40 _multiplier;
    }

    struct GlobalStakeStore {

        uint256 burnedTEDsTotal;
        uint256 nextHiddenCandyTotal;
        uint256 candyPrice;
        uint256 dailyEggHuntCount;
        uint256 hiddenCandyTotal;
        uint40 latestStakeId; 
        uint40 multiplier;  
    }

    GlobalStakeStore public stakingTotals;

    /* Daily data */
    struct DailyEggHuntData {
        uint128 dayPayoutTotal;
        uint128 dayhiddenCandyTotal;
    }

    mapping(uint256 => DailyEggHuntData) public dailyEggHuntRewards;


    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _burnedTEDs;
        uint256 _hiddenCandy;
        uint256 _hiddenDay;
        uint256 _stakedDays;
    }

    struct StakeStore {
        uint40 stakeId;
        uint256 burnedTEDs;
        uint256 hiddenCandy;
        uint256 hiddenDay;
        uint256 stakedDays;   
    }

    mapping(address => StakeStore[]) public yourStakes;

    /* Temporary state for calculating daily rounds */
    struct DailyEggHuntStats {
        uint256 _createdSupplyCache;
        uint256 _payoutTotal;
        
    }
}


contract Vars is Structs {
    uint256 public dayOverride;
  
    /*Time Parameters*/
    /* Time of contract launch (2022-04-17T00:00:00Z GMT) */
    uint256 internal constant LAUNCH_TIME_UNIX = 1650153600;
    uint256 internal constant STAKING_START_DAY_NUM = 0;
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MAX_STAKE_DAYS = 420; 


    /*Share/candy parameters*/
    /* Size of a CANDIES or Shares uint */
    uint256 internal constant CANDY_UINT_SIZE = 128;
   
    /* Share rate is scaled to increase precision */
    uint256 internal constant RATE_SCALE = 1e12;

    /* Share rate max (after scaling) */
    uint256 internal constant MAX_RATE = (1 << 128) - 1;
    
    function TotalTEDsCreated() external view
        returns (uint256)
    {
        return totalSupply() + stakingTotals.burnedTEDsTotal;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay() external view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay() internal view
        returns (uint256)
    {
       if (dayOverride > 0){
           return dayOverride;
       } else {
           return (block.timestamp - LAUNCH_TIME_UNIX) / 1 days;
       }
       
        
    }

}  


contract EasterEggHuntData is Vars{
        
    function stakingTotalsList()
        external
        view
        returns (uint256[9] memory)
    {

        return [
            stakingTotals.burnedTEDsTotal,
            stakingTotals.nextHiddenCandyTotal,
            stakingTotals.candyPrice,
            stakingTotals.dailyEggHuntCount,
            stakingTotals.hiddenCandyTotal,
            stakingTotals.latestStakeId,
            stakingTotals.multiplier,
            block.timestamp,
            totalSupply()
            
        ];
    }

    function _globalsLoad(GlobalHuntCache memory g, GlobalHuntCache memory gSnapshot)
        internal
        view
    {
        g._burnedTEDsTotal = stakingTotals.burnedTEDsTotal;
        g._nextHiddenCandyTotal = stakingTotals.nextHiddenCandyTotal;
        g._candyPrice = stakingTotals.candyPrice;
        g._dailyEggHuntCount = stakingTotals.dailyEggHuntCount;
        g._hiddenCandyTotal = stakingTotals.hiddenCandyTotal;
        g._latestStakeId = stakingTotals.latestStakeId;
        g._currentDay = _currentDay();
        g._multiplier = stakingTotals.multiplier;
        
        _GlobalHuntCacheSnapshot(g, gSnapshot);
    }

    function _GlobalHuntCacheSnapshot(GlobalHuntCache memory g, GlobalHuntCache memory gSnapshot)
        internal
        pure
    {

        gSnapshot._burnedTEDsTotal = g._burnedTEDsTotal;
        gSnapshot._nextHiddenCandyTotal = g._nextHiddenCandyTotal;
        gSnapshot._candyPrice = g._candyPrice;
        gSnapshot._dailyEggHuntCount = g._dailyEggHuntCount;
        gSnapshot._hiddenCandyTotal = g._hiddenCandyTotal;
        gSnapshot._latestStakeId = g._latestStakeId;
        gSnapshot._multiplier = g._multiplier;
    }

    function _globalsSync(GlobalHuntCache memory g, GlobalHuntCache memory gSnapshot)
        internal
    {
        if (g._burnedTEDsTotal != gSnapshot._burnedTEDsTotal
            || g._nextHiddenCandyTotal != gSnapshot._nextHiddenCandyTotal
            || g._candyPrice != gSnapshot._candyPrice
            || g._dailyEggHuntCount != gSnapshot._dailyEggHuntCount
            || g._hiddenCandyTotal != gSnapshot._hiddenCandyTotal
            || g._latestStakeId != gSnapshot._latestStakeId
            || g._multiplier != gSnapshot._multiplier
            ) 
            {
            stakingTotals.burnedTEDsTotal = g._burnedTEDsTotal;
            stakingTotals.nextHiddenCandyTotal = g._nextHiddenCandyTotal;
            stakingTotals.candyPrice = g._candyPrice;
            stakingTotals.dailyEggHuntCount = g._dailyEggHuntCount;
            stakingTotals.hiddenCandyTotal = g._hiddenCandyTotal;
            stakingTotals.latestStakeId = g._latestStakeId;
            stakingTotals.multiplier = g._multiplier;
           }

    }
}

contract StakeUtility is EasterEggHuntData{
    
    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "ECT: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._burnedTEDs = stRef.burnedTEDs;
        st._hiddenCandy = stRef.hiddenCandy;
        st._hiddenDay = stRef.hiddenDay;
        st._stakedDays = stRef.stakedDays;
       }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakeId = st._stakeId;
        stRef.burnedTEDs = st._burnedTEDs;
        stRef.hiddenCandy =st._hiddenCandy;
        stRef.hiddenDay = st._hiddenDay;
        stRef.stakedDays = st._stakedDays;
       
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 stakeTEDsAmount,
        uint256 newHiddenCandy,
        uint256 newhiddenDay,
        uint256 stakeDays
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                stakeTEDsAmount,
                newHiddenCandy,
                newhiddenDay,
                stakeDays
                
            )
        );
    }

    function CountOfOwnedStakes(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return yourStakes[stakerAddr].length;
    }

    function _stakePoP(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }
        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }

    
}

contract EasterCandyUtility is StakeUtility{
    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param previousDay Only update days before this day number (optional; 0 for current day)
     */
    function RefreshDailyHuntData(uint256 previousDay)
        external
    {
        GlobalHuntCache memory g;
        GlobalHuntCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);


        if (previousDay != 0) {
            require(previousDay <= g._currentDay, "ECT: previousDay cannot be in the future");

            _refreshDailyHunt(g, previousDay, false);
        } else {
            /* Default to updating before current day */
            _refreshDailyHunt(g, g._currentDay, false);
        }

        _globalsSync(g, gSnapshot);
    }

    function _refreshDailyHuntAuto(GlobalHuntCache memory g)
        internal
    {
        _refreshDailyHunt(g, g._currentDay, true);
    }
    
    function _dailyHuntCalc(GlobalHuntCache memory g, DailyEggHuntStats memory rs)
        private
        pure
     {
           if (g._multiplier > 1){
                rs._payoutTotal = rs._createdSupplyCache * g._multiplier / 88469187;
           }

           if(g._hiddenCandyTotal > (10000000000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache * 10000 / 88469187;
           
           } else if (g._hiddenCandyTotal >(100000000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache * 1000 / 88469187;
          
           } else if (g._hiddenCandyTotal > (1000000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache * 100 / 88469187;
          
           } else if (g._hiddenCandyTotal > (100000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache * 10 / 88469187;
         
           } else if (g._hiddenCandyTotal > (20000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache / 88469187;
           
           } else if (g._hiddenCandyTotal > (1000 * 1e12)){
               rs._payoutTotal = rs._createdSupplyCache / 884691870;
           
           } else{
                rs._payoutTotal = rs._createdSupplyCache / 8846918700;
            }
              
      
        /*Lucky 7 bonus*/  
        if (g._currentDay % 7 == 0) {
                rs._payoutTotal += 25 * 1e12;
                
            }

    }


    function _dailyHuntCalcAndStore(GlobalHuntCache memory g, DailyEggHuntStats memory rs, uint256 day)
        private
    {
        
        _dailyHuntCalc(g, rs);

        dailyEggHuntRewards[day].dayPayoutTotal = uint128(rs._payoutTotal);
        dailyEggHuntRewards[day].dayhiddenCandyTotal = uint128(g._hiddenCandyTotal);
    }

    function _refreshDailyHunt(GlobalHuntCache memory g, uint256 beforeDay, bool isAutoUpdate)
        private
    {
        if (g._dailyEggHuntCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }

        DailyEggHuntStats memory rs;

        if (totalSupply() + g._burnedTEDsTotal < 420000000000 * 1e12){
            rs._createdSupplyCache = totalSupply() + g._burnedTEDsTotal;
        } else if (totalSupply() + g._burnedTEDsTotal > 420000000000 * 1e12 && g._multiplier >1){
            rs._createdSupplyCache = totalSupply() + g._burnedTEDsTotal;
        } else {
            rs._createdSupplyCache = 420000000000 * 1e12;
        }

        uint256 day = g._dailyEggHuntCount;

        _dailyHuntCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        if (g._nextHiddenCandyTotal != 0) {
            g._hiddenCandyTotal += g._nextHiddenCandyTotal;
            g._nextHiddenCandyTotal = 0;
        }

        while (++day < beforeDay) {
            _dailyHuntCalcAndStore(g, rs, day);
        }

        _emitEggHuntDataRefresh(g._dailyEggHuntCount, day, isAutoUpdate);
        g._dailyEggHuntCount = day;

    }

    function _emitEggHuntDataRefresh(
        uint256 beginDay, 
        uint256 endDay, 
        bool isAutoUpdate
       )
        private
    {
        emit DailyEggHuntRefresh( // (auto-generated event)
           block.timestamp,
            beginDay,
            endDay,
            isAutoUpdate,
            msg.sender
        );
    }
}


contract StakeableToken is EasterCandyUtility {

    function stakeStart(uint256 stakeTEDsAmount, uint256 stakeDays)
        external
    {
        GlobalHuntCache memory g;
        GlobalHuntCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Enforce the minimum stake time */
        require(stakeDays >= 1, "Must stake for at least 1 day");

        /* Check if log data needs to be updated */
        _refreshDailyHuntAuto(g);

        _stakeStart(g, stakeTEDsAmount, stakeDays);

        /* Remove staked CANDIES from balance of staker */
        _burn(msg.sender, stakeTEDsAmount);

        _globalsSync(g, gSnapshot);
    }

    function _stakeStart(
        GlobalHuntCache memory g,
        uint256 stakeTEDsAmount,
        uint256 stakeDays
       )
        internal
    {
        /* Enforce the maximum stake time */
        require(stakeDays <= MAX_STAKE_DAYS, "ECT: stakeDays higher than maximum");

        uint256 newHiddenCandy = stakeTEDsAmount * RATE_SCALE / g._candyPrice;

        /* Ensure stakeTEDsAmount is enough for at least one stake share */
        require(newHiddenCandy != 0, "ECT: stakeTEDsAmount must be at least minimum candyPrice");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newhiddenDay = g._currentDay < STAKING_START_DAY_NUM
            ? STAKING_START_DAY_NUM + 1
            : g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            yourStakes[msg.sender],
            newStakeId,
            stakeTEDsAmount,
            newHiddenCandy,
            newhiddenDay,
            stakeDays
            );

        _emitStakeStart(newStakeId, stakeTEDsAmount, newHiddenCandy, stakeDays); 

        /* Stake is added to total in the next round, not the current round */
        g._nextHiddenCandyTotal += newHiddenCandy;

        /* Track total staked CANDIES for inflation calculations */
        g._burnedTEDsTotal += stakeTEDsAmount;
    }


    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalHuntCache memory g;
        GlobalHuntCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        StakeStore[] storage stakeListRef = yourStakes[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "ECT: No stakes found in list");
        require(stakeIndex < stakeListRef.length, "ECT: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _refreshDailyHuntAuto(g);

        uint256 servedDays = 0;

        //bool prevUnlocked = (st._unhiddenDay != 0);
        uint256 stakeReturn;
        uint256 payout = 0;


        if (g._currentDay >= st._hiddenDay) {
            
                g._hiddenCandyTotal -= st._hiddenCandy;
                servedDays = g._currentDay - st._hiddenDay;
                
                if (servedDays > st._stakedDays) 
                    {
                    servedDays = st._stakedDays;
                    }
                
                (stakeReturn, payout) = _openedEggs(g, st, servedDays);
            
                if (servedDays >= 100 && st._hiddenCandy > 5000){
                    stakeReturn += 1000 * 1e12;
                    if (servedDays == 420) {
                        stakeReturn += 1000 * 1e12;
                    }
                }

                if (servedDays == 420 && st._hiddenCandy > 10000){
                    stakeReturn += 5000 * 1e12;
                }

                if (servedDays < st._stakedDays){
                    stakeReturn = (stakeReturn / 4);
                    stakeReturn = (stakeReturn * 3);
                }

        } else {
           
            /* If not locked, return staked amount without any rewards or penalty */
            g._nextHiddenCandyTotal -= st._hiddenCandy;
            stakeReturn = st._burnedTEDs;
        }

        _emitStakeEnd(stakeIdParam, st._burnedTEDs, st._hiddenCandy,  payout,  servedDays);

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);

            /* Update the share rate if necessary */
            _UpdateCandyPrice(g, st, stakeReturn);
        }

        g._burnedTEDsTotal -= st._burnedTEDs;
        _stakePoP(stakeListRef, stakeIndex);
        _globalsSync(g, gSnapshot);
    }
    


    function _UpdateCandyPrice(GlobalHuntCache memory g, StakeCache memory st, uint256 stakeReturn)
        private
    {
        if (stakeReturn > st._burnedTEDs) {

            uint256 newCandyPrice = stakeReturn * RATE_SCALE / st._hiddenCandy;

            if (newCandyPrice > MAX_RATE) {

                newCandyPrice = MAX_RATE;
            }

            if (newCandyPrice > g._candyPrice) {
                g._candyPrice = newCandyPrice;

                _emitCandyPriceChange(newCandyPrice, st._stakeId);
            }
        }
    }

  
    function _calcPayoutRewards(
        uint256 hiddenCandyParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {
        for (uint256 day = beginDay; day < endDay; day++) {
            payout += dailyEggHuntRewards[day].dayPayoutTotal * hiddenCandyParam
                / dailyEggHuntRewards[day].dayhiddenCandyTotal;
        }

        return payout;
    }


   function _openedEggs(GlobalHuntCache memory g, StakeCache memory st, uint256 servedDays)
        private
        view
        returns (uint256 stakeReturn, uint256 payout)
    {
        require(g._currentDay > 0, "Day must be greater than zero");
        payout = _calcPayoutRewards(
                st._hiddenCandy,
                st._hiddenDay,
                st._hiddenDay + servedDays
            );
        stakeReturn = st._burnedTEDs + payout;
       
        return (stakeReturn, payout); 
    }
    

    function _emitStakeStart(
        uint40 stakeId,
        uint256 burnedTEDs,
        uint256 hiddenCandy,
        uint256 stakedDays
        
    )
        private
    {
        emit StakeStart( // (auto-generated event)
            block.timestamp,
            burnedTEDs,
            hiddenCandy,
            stakedDays,
            msg.sender,
            stakeId
         );
    }

    function _emitStakeEnd(
        uint40 stakeId,
        uint256 burnedTEDs,
        uint256 hiddenCandy,
        uint256 payout,
        uint256 servedDays
    )
        private
    {
        emit StakeEnd( // (auto-generated event)
                block.timestamp,
                burnedTEDs,
                hiddenCandy,
                payout,
                servedDays,
            msg.sender,
            stakeId
        );
    }

    function _emitCandyPriceChange(uint256 candyPrice, uint40 stakeId)
        private
    {
        emit CandyPriceChange( // (auto-generated event)
            block.timestamp,
            candyPrice,
            stakeId
        );
    }


}

contract TED is StakeableToken {

    address private daoAdmin;
    

    address constant XFER_ADDRESS = payable(0xde8cD0BCc9545ec18c7DE52F96Cd76d36d62663b);
    
    modifier onlyDao() {
        require(msg.sender == daoAdmin, "reclaimTokens: Caller is not the DAO");
        _;
    }

    constructor(
         address _daoAdmin
    )  
    
    {
        daoAdmin = _daoAdmin;
        
        /* Initialize global candyPrice to 1 */
        stakingTotals.candyPrice = uint128(1 * RATE_SCALE);

        /* Initialize multiplier to 1 */
        stakingTotals.multiplier = uint40(1);

        /* Initialize dailyEggHuntCount to skip pre-claim period */
        stakingTotals.dailyEggHuntCount = uint16(STAKING_START_DAY_NUM);

        _mint(msg.sender, 420000000000 * 1e12);
    }

   

    //flush any money sent to the contract 
    function XferConTokens() onlyDao payable 
        external
    {
        require(address(this).balance != 0, "ECT: No value");

        payable(XFER_ADDRESS).transfer(payable(address(this)).balance);
    }
    
    function SetCandyPrice(uint128 _candyPrice) onlyDao public {
      stakingTotals.candyPrice = _candyPrice;
     
      _emitCandySale(_candyPrice);
    }
   
    function TimeWarp(uint256 _dayOverride) onlyDao public {
      dayOverride = _dayOverride;
    }

    function SetMultiplier(uint40 _multiplier) onlyDao public {
      stakingTotals.multiplier = _multiplier;
     
    }

    function _emitCandySale(uint256 candyPrice)
        private
    {
        emit CandySale(
            block.timestamp,
            candyPrice 
        );
    }
    receive() external payable {}
}