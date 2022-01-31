// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultLP is ReentrancyGuard, Pausable, Ownable {

    //---------- Libraries ----------//
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    //---------- Contracts ----------//
    IERC20 private TOKEN_A;
    IERC20 private TOKEN_B;

    //---------- Variables ----------//
    Counters.Counter public totalHolders;
    uint256 constant pointMultiplier = 10e18;
    uint256 constant day = 86400; // 1 Day Timestamp 
    uint256 constant month = 2629743; // 1 Month Timestamp 
    uint256 constant year = 31556926; // 1 Year Timestamp  
    uint256 private totalTokenBPoints;
    uint256 private totalTokenAPoints;
    uint256 public totalTokenB;
    uint256 public unclaimedTokenB;
    uint256 public processedTokenB;
    uint256 public totalTokenA;
    uint256 public unclaimedTokenA;
    uint256 public processedTokenA;
    uint256 public totalStaked;
    uint256 public lastPaused;
    uint256 public lastUpdated;


    //---------- Storage -----------//
    struct Wallet {
        uint256 stakedBal;
        uint256 startTime;
        uint256 lastTokenBPoints;
        uint256 lastTokenAPoints;
        uint256 pendingTokenBbal;
        uint256 pendingTokenAbal;
        bool inStake;
    }

    mapping(address => Wallet) private stakeHolders;

    //---------- Events -----------//
    event Deposited(address indexed payee, uint256 weiAmount, string coin, uint256 totalStaked);
    event Withdrawn(address indexed payee, uint256 weiAmount, string coin);
    event Staked(address indexed wallet, uint256 amount);
    event UnStaked(address indexed wallet);
    event ReStaked(address indexed wallet, uint256 amount);

    //---------- Constructor ----------//
    constructor(address tokenA, address tokenB) {
        TOKEN_A = IERC20(tokenA);
        TOKEN_B = IERC20(tokenB);
    }    

    //---------- Deposits -----------//   
    function depositTokenB(address from_, uint256 amount_) external nonReentrant {
        require(amount_ > 0, 'TokenB too low');
        require(from_ != address(0), 'Invalid address');
        require(TOKEN_B.transferFrom(from_, address(this), amount_)); 
        _disburseTokenB(amount_);      
    }

    //----------- Internal Functions -----------//
    function _disburseTokenB(uint amount) internal {  
        if(totalStaked > 1000000 && amount > 99) {          
            totalTokenBPoints = totalTokenBPoints.add((amount.mul(pointMultiplier)).div(totalStaked));
            unclaimedTokenB = unclaimedTokenB.add(amount);
            totalTokenB = totalTokenB.add(amount);
            emit Deposited(_msgSender(), amount, "TokenB", totalStaked);
        }
    }

    function _disburseTokenA(uint amount) internal {
        if(totalStaked > 1000000 && amount > 99) {      
            totalTokenAPoints = totalTokenAPoints.add((amount.mul(pointMultiplier)).div(totalStaked));
            unclaimedTokenA = unclaimedTokenA.add(amount);
            totalTokenA = totalTokenA.add(amount);
            emit Deposited(_msgSender(), amount, "TokenA", totalStaked);
        }
    }

    function _thisBalanceTokenB() internal view returns(uint256) {        
        return TOKEN_B.balanceOf(address(this));
    }

    function _thisBalanceTokenA() internal view returns(uint256) {        
        return TOKEN_A.balanceOf(address(this));
    }

    function _recalculateBalances() internal virtual { 
        uint256 balanceTokenB = _thisBalanceTokenB();
        uint256 balanceTokenA = _thisBalanceTokenA().sub(totalStaked);
        uint256 tprocessedTokenB = unclaimedTokenB.add(processedTokenB);
        uint256 tprocessedTokenA = unclaimedTokenA.add(processedTokenA);
        if(balanceTokenB > tprocessedTokenB) {   
            uint256 pending = balanceTokenB.sub(tprocessedTokenB);
            if(pending > 1000000) {
                _disburseTokenB(pending); 
            }
        }
        if(balanceTokenA > tprocessedTokenA) {      
            uint256 pending = balanceTokenA.sub(tprocessedTokenA);
            if(pending > 1000000) {
                _disburseTokenA(pending);
            }
        }
    }      
    
    function _processRewardsTokenB(address account) internal virtual returns(bool) {
        uint256 rewards = getRewardsTokenB(account);
        if(rewards > 0) {        
            unclaimedTokenB = unclaimedTokenB.sub(rewards);
            processedTokenB = processedTokenB.add(rewards);
            stakeHolders[account].lastTokenBPoints = totalTokenBPoints;
            stakeHolders[account].pendingTokenBbal = stakeHolders[account].pendingTokenBbal.add(rewards);    
            return true;
        }
        return false;                 
    } 
    
    function _processRewardsTokenA(address account) internal virtual returns(bool) {
        uint256 rewards = getRewardsTokenA(account);
        if(rewards > 0) {        
            unclaimedTokenA = unclaimedTokenA.sub(rewards);
            processedTokenA = processedTokenA.add(rewards);
            stakeHolders[account].lastTokenAPoints = totalTokenAPoints;
            stakeHolders[account].pendingTokenAbal = stakeHolders[account].pendingTokenAbal.add(rewards);    
            return true;
        }
        return false;                 
    }
    
    
    function _initWithdrawnTokenB(address account) internal virtual returns(bool) {
        uint256 pendingRewards = getRewardsTokenB(account);
        if(pendingRewards > 0) {
            require(_processRewardsTokenB(account));
        }   
        uint256 amount = stakeHolders[account].pendingTokenBbal;
        require(amount > 0, "Balance too low");
        stakeHolders[account].pendingTokenBbal = 0;
        processedTokenB = processedTokenB.sub(amount);
        bool success = TOKEN_B.transfer(account, amount);
        emit Withdrawn(account, amount, "TokenB");
        return success;  
    }
    
    function _initWithdrawnTokenA(address account) internal virtual returns(bool) {
        uint256 pendingRewards = getRewardsTokenA(account);
        if(pendingRewards > 0) {
            require(_processRewardsTokenA(account));
        }     
        uint256 amount = stakeHolders[account].pendingTokenAbal;
        require(amount > 0, "Balance too low");
        stakeHolders[account].pendingTokenAbal = 0;
        processedTokenA = processedTokenA.sub(amount);
        bool success = TOKEN_A.transfer(account, amount);
        emit Withdrawn(account, amount, "TokenA");
        return success;  
    }
    
    
    function _reStakeTokenA(address account) internal virtual returns(bool) {
        _recalculateBalances();
        if(getRewardsTokenA(account) > 0) {
            require(_processRewardsTokenA(account));
        }  
        if(getRewardsTokenB(account) > 0) {
            require(_processRewardsTokenB(account));
        }
        uint256 amount = stakeHolders[account].pendingTokenAbal;
        require(amount > 0, "Balance too low");
        stakeHolders[account].pendingTokenAbal = 0;
        processedTokenA = processedTokenA.sub(amount);
        stakeHolders[account].stakedBal = stakeHolders[account].stakedBal.add(amount);
        totalStaked = totalStaked.add(amount);
        emit ReStaked(account, amount);
        return true;                
    }

    function _initStake(address account_, uint256 amount_) internal virtual returns(bool) { 
        _recalculateBalances();        
        if(TOKEN_A.transferFrom(account_, address(this), amount_)) {
            stakeHolders[account_].startTime = block.timestamp;
            stakeHolders[account_].lastTokenBPoints = totalTokenBPoints;
            stakeHolders[account_].lastTokenAPoints = totalTokenAPoints;  
            stakeHolders[account_].inStake = true;
            stakeHolders[account_].stakedBal = amount_;
            totalStaked = totalStaked.add(amount_);
            totalHolders.increment();
            return true;  
        }
        return false;    
    }

    function _initStake(address account_, uint256 amount_, address operator_) internal virtual returns(bool) {  
        _recalculateBalances();       
        if(TOKEN_A.transferFrom(operator_, address(this), amount_)) {
            stakeHolders[account_].startTime = block.timestamp;
            stakeHolders[account_].lastTokenBPoints = totalTokenBPoints;
            stakeHolders[account_].lastTokenAPoints = totalTokenAPoints;  
            stakeHolders[account_].inStake = true;
            stakeHolders[account_].stakedBal = amount_;
            totalStaked = totalStaked.add(amount_);
            totalHolders.increment();
            return true;  
        }
        return false;    
    }

    function _addStake(address account_, uint256 amount_) internal virtual returns(bool) {
        _recalculateBalances();
        if(getRewardsTokenB(account_) > 0) {
            require(_processRewardsTokenB(account_));
        }
        if(getRewardsTokenA(account_) > 0) {
            require(_processRewardsTokenA(account_));
        } 
        if(TOKEN_A.transferFrom(account_, address(this), amount_)) {
            stakeHolders[account_].stakedBal = stakeHolders[account_].stakedBal.add(amount_);
            totalStaked = totalStaked.add(amount_);
            return true;
        }        
        return false; 
    }

    function _addStake(address account_, uint256 amount_, address operator_) internal virtual returns(bool) {
        _recalculateBalances();
        if(getRewardsTokenB(account_) > 0) {
            require(_processRewardsTokenB(account_));
        }
        if(getRewardsTokenA(account_) > 0) {
            require(_processRewardsTokenA(account_));
        } 
        if(TOKEN_A.transferFrom(operator_, address(this), amount_)) {
            stakeHolders[account_].stakedBal = stakeHolders[account_].stakedBal.add(amount_);
            totalStaked = totalStaked.add(amount_);
            return true;
        }        
        return false; 
    }

    function _unStakeBal(address account_) internal virtual returns(uint256) {
        uint256 accumulated = block.timestamp.sub(stakeHolders[account_].startTime);
        uint256 balance = stakeHolders[account_].stakedBal;
        uint minPercent = 88; 
        if(accumulated >= year) {
            return balance;
        }
        balance = balance.mul(pointMultiplier);        
        if(accumulated < month) {
            balance = (balance.mul(minPercent)).div(100);
            return balance.div(pointMultiplier);
        }
        for(uint m = 1; m < 12; m++) {
            if(accumulated >= month.mul(m) && accumulated < month.mul(m + 1)) {
                minPercent = minPercent.add(m);
                balance = (balance.mul(minPercent)).div(100);
                return balance.div(pointMultiplier);
            }

        }
        return 0;
    } 

    //----------- External Functions -----------// 
    function isInStake(address account_) external view returns(bool) {
        return stakeHolders[account_].inStake;
    }  
    
    function getRewardsTokenB(address account) public view returns(uint256) {
        uint256 newTokenBPoints = totalTokenBPoints.sub(stakeHolders[account].lastTokenBPoints);
        return (stakeHolders[account].stakedBal.mul(newTokenBPoints)).div(pointMultiplier);
    }   
    
    function getRewardsTokenA(address account) public view returns(uint256) {
        uint256 newTokenAPoints = totalTokenAPoints.sub(stakeHolders[account].lastTokenAPoints);
        return (stakeHolders[account].stakedBal.mul(newTokenAPoints)).div(pointMultiplier);
    }   
    
    function getWalletInfo(address account) external view returns(Wallet memory) {       
        return stakeHolders[account];
    }
    
    
    function stakeFor(address account_, uint256 amount_) external whenNotPaused nonReentrant returns(bool) {
        require(amount_ > 0);
        if(stakeHolders[account_].inStake) {
            require(_addStake(account_, amount_, _msgSender()));

        } else {
            require(amount_ > 1000000);
            require(_initStake(account_, amount_, _msgSender()));
        }     
        emit Staked(account_, amount_);
        return true;               
    }  
    
    function Stake(uint256 amount_) external whenNotPaused nonReentrant  {
        require(amount_ > 1000000);
        require(!stakeHolders[_msgSender()].inStake, "You are already in stake, do addStake");
        require(TOKEN_A.allowance(_msgSender(), address(this)) >= amount_, "Amount not allowed");
        require(_initStake(_msgSender(), amount_));
        emit Staked(_msgSender(), amount_);               
    } 
    
    function addStake(uint256 amount_) external whenNotPaused nonReentrant  {
        require(amount_ > 0);
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        require(TOKEN_A.allowance(_msgSender(), address(this)) >= amount_, "Amount not allowed");
        require(_addStake(_msgSender(), amount_));
        emit ReStaked(_msgSender(), amount_);               
    }
    
    function reStake() external whenNotPaused nonReentrant  {
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        require(_reStakeTokenA(_msgSender()));        
    }  
    
    function withdrawnTokenB() external nonReentrant {
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        require(_initWithdrawnTokenB(_msgSender()));
    }
    
    function withdrawnTokenA() external nonReentrant {
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        require(_initWithdrawnTokenA(_msgSender()));
    }

    function unStake() external nonReentrant {
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        if(getRewardsTokenB(_msgSender()) > 0) {
            require(_initWithdrawnTokenB(_msgSender())); 
        }
        if(getRewardsTokenA(_msgSender()) > 0) {
            require(_initWithdrawnTokenA(_msgSender()));
        } 
        uint256 stakedBal = stakeHolders[_msgSender()].stakedBal;
        uint256 balance = _unStakeBal(_msgSender());
        uint256 balanceDiff = stakedBal.sub(balance);
        if(balance > 0) {
            require(TOKEN_A.transfer(_msgSender(), balance));            
        }
        totalStaked = totalStaked.sub(stakedBal);
        delete stakeHolders[_msgSender()];
        totalHolders.decrement();
        if(balanceDiff > 0) {
            _disburseTokenA(balanceDiff);            
        }
        emit UnStaked(_msgSender());
    }

    function safeUnStake() external whenPaused nonReentrant {
        require(stakeHolders[_msgSender()].inStake, "Not in stake");
        uint256 stakedBal = stakeHolders[_msgSender()].stakedBal;
        delete stakeHolders[_msgSender()];
        require(TOKEN_A.transfer(_msgSender(), stakedBal));          
        totalStaked = totalStaked.sub(stakedBal);
        totalHolders.decrement();
    }       

    function rescueBalances(address to_) external whenPaused onlyOwner {
        require(block.timestamp.sub(lastPaused) > year);
        if(_thisBalanceTokenB() > 0) {
            TOKEN_B.transfer(to_, _thisBalanceTokenB());
        }
        if(_thisBalanceTokenA() > 0) {
            TOKEN_A.transfer(to_, _thisBalanceTokenA());
        }
    }

    function pause() external onlyOwner {
        _pause();
        lastPaused = block.timestamp;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateBalances() external whenNotPaused nonReentrant {
        if(lastUpdated.add(day) < block.timestamp) {
            _recalculateBalances();
            lastUpdated = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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