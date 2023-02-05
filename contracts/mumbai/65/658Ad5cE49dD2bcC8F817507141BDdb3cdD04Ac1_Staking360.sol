/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File contracts/IERC20.sol



pragma solidity ^0.8.13;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address receiver, uint256 amount) external;
    function burn(uint256 amount) external;
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}


// File contracts/Staking360.sol



pragma solidity ^0.8.13;
/// @title Prozium staking contract - 360 days
/// @author Michal Kazdan

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. 
 * @dev Expanded with minting function for fixed rewards 
*/


contract Staking360 is Pausable, ReentrancyGuard, Ownable  {

    IERC20 public token;

    /// @notice Staking period in days, 3 contracts with 3 plans - 180, 360, 720 days
    uint256 public period = 360 days;

    /// @notice Timestamp when the lock period is over. After this participants can take out their stake without penalty. 
    mapping(address => uint256) private lockPeriodFinish;
    mapping(address => uint256) private lockPeriodStart;

    /// @dev Staking parameters specific for each user
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public stakeType;
    mapping(address => uint256) public rewards;

    /// @notice contract balance
    uint256 public balance;
    mapping(address => uint256) public balances;

   
    /* ========== CONSTRUCTOR ========== */

    /// @notice Token address is passed as a parameter with deployment
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }
    
    /* ========== VIEWS ========== */

    /// @notice Indicates penalty-free withdrawal period
    function isPeriodFinished(address account) public view returns (bool) {
        return block.timestamp > lockPeriodFinish[account];
    }

    /// @notice Estimated reward at the end of staking period
    /// @return Yearly reward rate in %
    function estimatedReward(address account) public view returns (uint256) {
        return balances[account] * rewardRate[account]/100;  
    }


    /// @dev Total amount of staking rewards earned by account -
    /// @notice Yearly calculation divided
    /// @return Real reward in token currency
    function earned(address account) public view returns (uint256) {
        if (isPeriodFinished(account)) {
            return  estimatedReward(account) ;
        } else {
            uint256 daysDiff = (lockPeriodFinish[account] - block.timestamp) / 60 / 60 / 24; 
            uint256 periodInDays = period / 60 / 60 / 24;
            return  ((estimatedReward(account) * ((periodInDays- daysDiff) * 10000 / periodInDays)) / 10000);
        }
    }
    /// @notice Staked amount + Earned rewards
    function getAllAssets (address account) public view returns (uint256) {
        return balances[account] + earned(account);
    }


    function getUserPenalty(address account) public view returns (uint256) {
        if (isPeriodFinished(account)) {
            return 0;
        } else {
            uint256 daysDiff = (lockPeriodFinish[account] - block.timestamp) / 60 / 60 / 24; 
            uint256 _penalty = (balances[account]) * ((daysDiff * 100) / 360) ;// 180, 360, 720
            return _penalty / 100 ; 
        }
    }

    /// @dev Aggregated function to get all user data
    /// @return _rewardYearlyRate = APY %
    /// @return _rewardsEligible = Earned rewards
    /// @return _daysLeft = Days left until end of the period
    /// @return _deposited = Amount originally staked
    /// @return _penalty = Penalty for early withdrawal
    /// @return _allAllocations = Total amount of assets available for withdrawal
    function getStakingOverview(address account) external view returns (uint256 _rewardYearlyRate, uint256 _rewardsEligible, uint256 _daysLeft, uint256 _deposited, uint256 _penalty, uint256 _allAllocations) {
        if (block.timestamp <= lockPeriodFinish[account]) {
            _daysLeft = (lockPeriodFinish[account] - block.timestamp) / 60 / 60 / 24;  
         } 
            _rewardYearlyRate = rewardRate[account];
            _rewardsEligible = earned(account);
            _deposited = balances[account];
            _penalty = getUserPenalty(account);
            _allAllocations = getAllAssets(account);
        }



    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Stake function for specific time period
    /// @dev Stake type is diffferent for each staking contract per period
    function stake(uint256 amount) external  whenNotPaused {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Balance");
        balance += amount;
        balances[msg.sender] += amount;
        token.transferFrom(msg.sender,address(this), amount);
        lockPeriodStart[msg.sender] = block.timestamp;
        lockPeriodFinish[msg.sender] = block.timestamp + period; 
        stakeType[msg.sender] = 2; // 2,3
        setRewardPlan();
        emit Staked(msg.sender, amount, lockPeriodFinish[msg.sender]);
    }
    

    /// @notice Withdrawal/Unstake function
    /// @dev Withdrawal takes penalty if not period over
    /// @dev Reward are minted automatically with unstaked amount

    function withdraw(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Cannot withdraw less than 0");
        rewards[msg.sender] = earned(msg.sender);
        require (balances[msg.sender] + rewards[msg.sender] >= _amount, "Insufficient balance");
        uint256 penalty = 0;
        uint256 difference = _amount;	
            /// @dev Penalty is calculated only if period is not over
            if (block.timestamp < lockPeriodFinish[msg.sender]) {
                rewards[msg.sender] = 0;
                penalty = getUserPenalty(msg.sender);
                difference = _amount - penalty;
                token.burn(penalty);
                balances[msg.sender] -= penalty;
                emit Burned(msg.sender, penalty);
            } 
            ///@dev Mint supply if rewards eligible
            if (rewards[msg.sender] > 0){
                token.mint(msg.sender, rewards[msg.sender]);
                emit Minted(msg.sender, rewards[msg.sender]);
                rewards[msg.sender] = 0;
            }
            ///@dev Transfer amount-penalty to the caller
            token.approve(address(this), difference);
            token.transferFrom(address(this), msg.sender, difference);
            balance -= _amount;
            rewards[msg.sender] = 0;
            balances[msg.sender] -= difference;
            emit TotalWithdraw(msg.sender, difference, penalty);
    }

    // Set APY based on selected type
    function setRewardPlan() private {
        if (stakeType[msg.sender] == 0){
            rewardRate[msg.sender] = 0;
        }
        if (stakeType[msg.sender] == 1){
            rewardRate[msg.sender] = 9;
        }
        if (stakeType[msg.sender] == 2){
            rewardRate[msg.sender] = 18;
        }
        if (stakeType[msg.sender] == 3){
            rewardRate[msg.sender] = 27;
        }
    }
 


    /* ========== ADMIN MAINTENANCE FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    // Allow again staking/withdraw
    function unpause() external onlyOwner {
        _unpause();
    }


    /* ========== EVENTS ========== */

    // Reward has been set
    event Staked(address user, uint256 amount, uint256 period); // New staking participant
    event TotalWithdraw(address user, uint256 amount, uint256 penalty); // Participant has withdrawn part or full stake
    event Minted(address user, uint256 amount); // Reward has been minted
    event Burned(address user, uint256 amount); // Burned penalty
}