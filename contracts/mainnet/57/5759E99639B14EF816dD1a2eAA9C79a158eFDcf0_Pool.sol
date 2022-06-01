/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/strategies/IStrategy.sol

pragma solidity ^0.8.7;

interface IStrategy {
    function invest(address _inboundCurrency, uint256 _minAmount) external payable;

    function earlyWithdraw(
        address _inboundCurrency,
        uint256 _amount,
        uint256 _minAmount
    ) external;

    function redeem(
        address _inboundCurrency,
        uint256 _amount,
        bool variableDeposits,
        uint256 _minAmount,
        bool disableRewardTokenClaim
    ) external;

    function getTotalAmount() external view returns (uint256);

    function getNetDepositAmount(uint256 _amount) external view returns (uint256);

    function getAccumulatedRewardTokenAmounts(bool disableRewardTokenClaim) external returns (uint256[] memory);

    function getRewardTokens() external view returns (IERC20[] memory);

    function getUnderlyingAsset() external view returns (address);

    function strategyOwner() external view returns (address);
}

// File: contracts/Pool.sol


pragma solidity ^0.8.7;






//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error ADMIN_FEE_WITHDRAWN();
error DEPOSIT_NOT_ALLOWED();
error EARLY_EXIT_NOT_POSSIBLE();
error FLEXIBLE_DEPOSIT_GAME();
error FUNDS_NOT_REDEEMED_FROM_EXTERNAL_POOL();
error FUNDS_REDEEMED_FROM_EXTERNAL_POOL();
error GAME_ALREADY_INITIALIZED();
error GAME_ALREADY_STARTED();
error GAME_COMPLETED();
error GAME_NOT_COMPLETED();
error GAME_NOT_INITIALIZED();
error INVALID_CUSTOM_FEE();
error INVALID_DEPOSIT_COUNT();
error INVALID_EARLY_WITHDRAW_FEE();
error INVALID_FLEXIBLE_AMOUNT();
error INVALID_INBOUND_TOKEN();
error INVALID_INCENTIVE_TOKEN();
error INVALID_MAX_FLEXIBLE_AMOUNT();
error INVALID_MAX_PLAYER_COUNT();
error INVALID_OWNER();
error INVALID_SEGMENT_LENGTH();
error INVALID_SEGMENT_PAYMENT();
error INCENTIVE_TOKEN_ALREADY_SET();
error INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
error INVALID_STRATEGY();
error INVALID_WAITING_ROUND_SEGMENT_LENGTH();
error MAX_PLAYER_COUNT_REACHED();
error NOT_PLAYER();
error PLAYER_ALREADY_JOINED();
error PLAYER_ALREADY_PAID_IN_CURRENT_SEGMENT();
error PLAYER_DID_NOT_PAID_PREVIOUS_SEGMENT();
error PLAYER_ALREADY_WITHDREW_EARLY();
error PLAYER_ALREADY_WITHDREW();
error PLAYER_DOES_NOT_EXIST();
error TOKEN_TRANSFER_FAILURE();
error TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
error RENOUNCE_OWNERSHIP_NOT_ALLOWED();

/**
@title GoodGhosting V2 Hodl Contract
@notice Allows users to join a pool with a yield bearing strategy, the winners get interest and rewards, losers get their principal back.
*/
contract Pool is Ownable, Pausable, ReentrancyGuard {
    /// using for better readability.
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint64;

    /// @notice Multiplier used for calculating playerIndex to avoid precision issues.
    uint256 public constant MULTIPLIER = 10**3;

    /// @notice Maximum Flexible Deposit Amount in case of flexible pools.
    uint256 public immutable maxFlexibleSegmentPaymentAmount;

    /// @notice The time duration (in seconds) of each segment.
    uint256 public immutable segmentLength;

    /// @notice The time duration (in seconds) of last segment (waiting round).
    uint256 public immutable waitingRoundSegmentLength;

    /// @notice The performance admin fee (percentage).
    uint128 public immutable adminFee;

    /// @notice Defines the max quantity of players allowed in the game.
    uint256 public immutable maxPlayersCount;

    /// @notice The amount to be paid on each segment in case "flexibleSegmentPayment" is false (fixed payments).
    uint256 public immutable segmentPayment;

    /// @notice Address of the token used for depositing into the game by players.
    address public immutable inboundToken;

    /// @notice Flag which determines whether the segment payment is fixed or not.
    bool public immutable flexibleSegmentPayment;

    /// @notice Flag which determines whether the deposit token is a transactional token like eth or matic (blockchain native token, not ERC20).
    bool public immutable isTransactionalToken;

    /// @notice When the game started (game initialized timestamp).
    uint256 public firstSegmentStart;

    /// @notice Timestamp when the waiting segment starts.
    uint256 public waitingRoundSegmentStart;

    /// @notice The number of segments in the game (segment count).
    uint64 public depositCount;

    /// @notice The early withdrawal fee (percentage).
    uint128 public earlyWithdrawalFee;

    /// @notice Stores the total amount of net interest received in the game.
    uint256 public totalGameInterest;

    /// @notice net total principal amount to reduce the slippage imapct from amm strategies.
    uint256 public netTotalGamePrincipal;

    /// @notice total principal amount only used to keep a track of the gross deposits.
    uint256 public totalGamePrincipal;

    /// @notice performance fee amount allocated to the admin.
    uint256[] public adminFeeAmount;

    /// @notice total amount of incentive tokens to be distributed among winners.
    uint256 public totalIncentiveAmount = 0;

    /// @notice Controls the amount of active players in the game (ignores players that early withdraw).
    uint256 public activePlayersCount = 0;

    /// @notice winner counter to track no of winners.
    uint256 public winnerCount = 0;

    /// @notice share % from impermanent loss.
    uint256 public impermanentLossShare;

    /// @notice total rewardTokenAmounts.
    uint256[] public rewardTokenAmounts;

    /// @notice emaergency withdraw flag.
    bool public emergencyWithdraw = false;

    /// @notice Controls if tokens were redeemed or not from the pool.
    bool public redeemed;

    /// @notice Controls if reward tokens are to be claimed at the time of redeem.
    bool public disableRewardTokenClaim = false;

    /// @notice controls if admin withdrew or not the performance fee.
    bool public adminWithdraw;

    /// @notice Ownership Control flag.
    bool public allowRenouncingOwnership = false;

    /// @notice Strategy Contract Address
    IStrategy public strategy;

    /// @notice Defines an optional token address used to provide additional incentives to users. Accepts "0x0" adresses when no incentive token exists.
    IERC20 public incentiveToken;

    /// @notice address of additional reward token accured from investing via different strategies like wmatic.
    IERC20[] public rewardTokens;

    /// @notice struct for storing all player stats.
    struct Player {
        bool withdrawn;
        bool canRejoin;
        bool isWinner;
        address addr;
        uint64 withdrawalSegment;
        uint64 mostRecentSegmentPaid;
        uint256 amountPaid;
        uint256 netAmountPaid;
        uint256 depositAmount;
    }

    /// @notice Stores info about the players in the game.
    mapping(address => Player) public players;

    /// @notice Stores info about the player index which is used to determine the share of interest of each winner.
    mapping(address => mapping(uint256 => uint256)) public playerIndex;

    /// @notice Stores info of the segment counter needed for ui as backup for graph.
    mapping(uint256 => uint256) public segmentCounter;

    /// @notice Stores info of cumulativePlayerIndexSum for each segment for early exit scenario.
    mapping(uint256 => uint256) public cumulativePlayerIndexSum;

    /// @notice list of players.
    address[] public iterablePlayers;

    //*********************************************************************//
    // ------------------------- events -------------------------- //
    //*********************************************************************//
    event JoinedGame(address indexed player, uint256 amount);

    event Deposit(address indexed player, uint256 indexed segment, uint256 amount, uint256 netAmount);

    event Withdrawal(address indexed player, uint256 amount, uint256 playerIncentive, uint256[] playerRewardAmounts);

    event FundsRedeemedFromExternalPool(
        uint256 totalAmount,
        uint256 totalGamePrincipal,
        uint256 totalGameInterest,
        uint256 totalIncentiveAmount,
        uint256[] totalRewardAmounts
    );

    event VariablePoolParamsSet(
        uint256 totalAmount,
        uint256 totalGamePrincipal,
        uint256 totalGameInterest,
        uint256 totalIncentiveAmount,
        uint256[] totalRewardAmounts
    );

    event EarlyWithdrawal(
        address indexed player,
        uint256 amount,
        uint256 totalGamePrincipal,
        uint256 netTotalGamePrincipal
    );

    event AdminWithdrawal(
        address indexed admin,
        uint256 totalGameInterest,
        uint256 adminIncentiveAmount,
        uint256[] adminFeeAmounts
    );

    event EndGameStats(
        uint256 totalBalance,
        uint256 totalGamePrincipal,
        uint256 netTotalGamePricipal,
        uint256 grossInterest,
        uint256[] grossRewardTokenAmount,
        uint256 totalIncentiveAmount,
        uint256 impermanentLossShare
    );

    event AdminFee(uint256[] adminFeeAmounts);

    //*********************************************************************//
    // ------------------------- modifiers -------------------------- //
    //*********************************************************************//
    modifier whenGameIsCompleted() {
        if (!isGameCompleted()) {
            revert GAME_NOT_COMPLETED();
        }
        _;
    }

    modifier whenGameIsNotCompleted() {
        if (isGameCompleted()) {
            revert GAME_COMPLETED();
        }
        _;
    }

    modifier whenGameIsInitialized() {
        if (firstSegmentStart == 0) {
            revert GAME_NOT_INITIALIZED();
        }
        _;
    }

    modifier whenGameIsNotInitialized() {
        if (firstSegmentStart != 0) {
            revert GAME_ALREADY_INITIALIZED();
        }
        _;
    }

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//
    /// @dev Checks if the game is completed or not.
    /// @return "true" if completeted; otherwise, "false".
    function isGameCompleted() public view returns (bool) {
        // Game is completed when the current segment is greater than "depositCount" of the game
        // or if "emergencyWithdraw" was enabled.
        return getCurrentSegment() > depositCount || emergencyWithdraw;
    }

    /// @dev Checks if player is a winner.
    /// @param _player player address
    /// @return "true" if player is a winner; otherwise, return "false".
    function isWinner(address _player) public view returns (bool) {
        if (players[_player].amountPaid == 0) {
            return false;
        }

        return _isWinner(players[_player], depositCount);
    }

    /// @dev gets the number of players in the game.
    /// @return number of players.
    function getNumberOfPlayers() external view returns (uint256) {
        return iterablePlayers.length;
    }

    /// @dev Calculates the current segment of the game.
    /// @return current game segment.
    function getCurrentSegment() public view whenGameIsInitialized returns (uint64) {
        uint256 currentSegment;
        if (
            waitingRoundSegmentStart <= block.timestamp &&
            block.timestamp <= (waitingRoundSegmentStart.add(waitingRoundSegmentLength))
        ) {
            uint256 waitingRoundSegment = block.timestamp.sub(waitingRoundSegmentStart).div(waitingRoundSegmentLength);
            currentSegment = depositCount.add(waitingRoundSegment);
        } else if (block.timestamp > (waitingRoundSegmentStart.add(waitingRoundSegmentLength))) {
            // handling the logic after waiting round has passed in to avoid inconsistency in current segment value
            currentSegment =
                waitingRoundSegmentStart.sub(firstSegmentStart).div(segmentLength) +
                block.timestamp.sub((waitingRoundSegmentStart.add(waitingRoundSegmentLength))).div(segmentLength) +
                1;
        } else {
            currentSegment = block.timestamp.sub(firstSegmentStart).div(segmentLength);
        }
        return uint64(currentSegment);
    }

    /// @dev Checks if the game has been initialized or not.
    function isInitialized() external view returns (bool) {
        return firstSegmentStart != 0;
    }

    //*********************************************************************//
    // ------------------------- constructor -------------------------- //
    //*********************************************************************//
    /**
        Creates a new instance of GoodGhosting game
        @param _inboundCurrency Smart contract address of inbound currency used for the game.
        @param _maxFlexibleSegmentPaymentAmount Maximum Flexible Deposit Amount in case of flexible pools.
        @param _depositCount Number of segments in the game.
        @param _segmentLength Lenght of each segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _waitingRoundSegmentLength Lenght of waiting round segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _segmentPayment Amount of tokens each player needs to contribute per segment
        @param _earlyWithdrawalFee Fee paid by users on early withdrawals (before the game completes). Used as an integer percentage (i.e., 10 represents 10%).
        @param _customFee performance fee charged by admin. Used as an integer percentage (i.e., 10 represents 10%). Does not accept "decimal" fees like "0.5".
        @param _maxPlayersCount max quantity of players allowed to join the game
        @param _strategy investment strategy contract address.
        @param _isTransactionalToken isTransactionalToken flag.
     */
    constructor(
        address _inboundCurrency,
        uint256 _maxFlexibleSegmentPaymentAmount,
        uint64 _depositCount,
        uint256 _segmentLength,
        uint256 _waitingRoundSegmentLength,
        uint256 _segmentPayment,
        uint128 _earlyWithdrawalFee,
        uint128 _customFee,
        uint256 _maxPlayersCount,
        bool _flexibleSegmentPayment,
        IStrategy _strategy,
        bool _isTransactionalToken
    ) {
        flexibleSegmentPayment = _flexibleSegmentPayment;
        isTransactionalToken = _isTransactionalToken;
        if (_customFee > 100) {
            revert INVALID_CUSTOM_FEE();
        }
        if (_earlyWithdrawalFee > 100) {
            revert INVALID_EARLY_WITHDRAW_FEE();
        }
        if (_maxPlayersCount == 0) {
            revert INVALID_MAX_PLAYER_COUNT();
        }

        if (address(_inboundCurrency) == address(0) && !_isTransactionalToken) {
            revert INVALID_INBOUND_TOKEN();
        }
        if (address(_strategy) == address(0)) {
            revert INVALID_STRATEGY();
        }
        if (_depositCount == 0) {
            revert INVALID_DEPOSIT_COUNT();
        }
        if (_segmentLength == 0) {
            revert INVALID_SEGMENT_LENGTH();
        }
        if (!_flexibleSegmentPayment && _segmentPayment == 0) {
            revert INVALID_SEGMENT_PAYMENT();
        }
        if (_waitingRoundSegmentLength == 0) {
            revert INVALID_WAITING_ROUND_SEGMENT_LENGTH();
        }
        if (_waitingRoundSegmentLength < _segmentLength) {
            revert INVALID_WAITING_ROUND_SEGMENT_LENGTH();
        }

        if (_flexibleSegmentPayment && _maxFlexibleSegmentPaymentAmount == 0) {
            revert INVALID_MAX_FLEXIBLE_AMOUNT();
        }

        address _underlyingAsset = _strategy.getUnderlyingAsset();
        if (_underlyingAsset != address(0) && _underlyingAsset != _inboundCurrency && !_isTransactionalToken) {
            revert INVALID_INBOUND_TOKEN();
        }

        // Initializes default variables
        depositCount = _depositCount;
        segmentLength = _segmentLength;
        waitingRoundSegmentLength = _waitingRoundSegmentLength;
        segmentPayment = _segmentPayment;
        earlyWithdrawalFee = _earlyWithdrawalFee;
        adminFee = _customFee;
        inboundToken = _inboundCurrency;
        strategy = _strategy;
        maxPlayersCount = _maxPlayersCount;
        maxFlexibleSegmentPaymentAmount = _maxFlexibleSegmentPaymentAmount;
        rewardTokens = strategy.getRewardTokens();
        rewardTokenAmounts = new uint256[](rewardTokens.length);
        // considering the inbound token since there would be fee on interest
        adminFeeAmount = new uint256[](rewardTokens.length + 1);
    }

    /**
    @dev Initializes the pool
    @param _incentiveToken Incentive token address (optional to set).
    */
    function initialize(IERC20 _incentiveToken) public virtual onlyOwner whenGameIsNotInitialized whenNotPaused {
        if (strategy.strategyOwner() != address(this)) {
            revert INVALID_OWNER();
        }
        firstSegmentStart = block.timestamp; //gets current time
        waitingRoundSegmentStart = firstSegmentStart + (segmentLength * depositCount);
        setIncentiveToken(_incentiveToken);
    }

    //*********************************************************************//
    // ------------------------- internal methods -------------------------- //
    //*********************************************************************//
    /**
    @notice
    Calculates and updates's game accounting called by methods _setGlobalPoolParamsForFlexibleDepositPool & redeemFromExternalPoolForFixedDepositPool.
    Updates the game storage vars used for calculating player interest, incentives etc.
    @param _totalBalance Total inbound token balance in the contract.
    */
    function _calculateAndUpdateGameAccounting(uint256 _totalBalance, uint256[] memory _grossRewardTokenAmount)
        internal
        returns (uint256)
    {
        uint256 _grossInterest = 0;
        if (_totalBalance >= netTotalGamePrincipal) {
            _grossInterest = _totalBalance.sub(netTotalGamePrincipal);
        } else {
            // handling impermanent loss case
            impermanentLossShare = (_totalBalance.mul(100)).div(netTotalGamePrincipal);
            netTotalGamePrincipal = _totalBalance;
        }
        if (address(incentiveToken) != address(0)) {
            totalIncentiveAmount = IERC20(incentiveToken).balanceOf(address(this));
        }
        // this condition is added because emit is to only be emitted when redeemed flag is false but this mehtod is called for every player withdrawal in variable deposit pool.
        if (!redeemed) {
            emit EndGameStats(
                _totalBalance,
                totalGamePrincipal,
                netTotalGamePrincipal,
                _grossInterest,
                _grossRewardTokenAmount,
                totalIncentiveAmount,
                impermanentLossShare
            );
        }
        return _grossInterest;
    }

    /**
    @notice
    Calculates and set's admin accounting called by methods _setGlobalPoolParamsForFlexibleDepositPool & redeemFromExternalPoolForFixedDepositPool.
    Updates the admin fee storage var used for admin fee.
    @param _grossInterest Gross interest amount.
    @param _grossRewardTokenAmount Gross reward amount array.
    */
    function _calculateAndSetAdminAccounting(uint256 _grossInterest, uint256[] memory _grossRewardTokenAmount)
        internal
    {
        // calculates the performance/admin fee (takes a cut - the admin percentage fee - from the pool's interest, strategy rewards).
        // calculates the "gameInterest" (net interest) that will be split among winners in the game
        // calculates the rewardTokenAmounts that will be split among winners in the game
        // when there's no winners, admin takes all the interest + rewards
        if (winnerCount == 0 && !emergencyWithdraw) {
            adminFeeAmount[0] = _grossInterest;
            // just setting these for consistency since if there are no winners then for accounting both these vars aren't used
            totalGameInterest = _grossInterest;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                rewardTokenAmounts[i] = _grossRewardTokenAmount[i];
            }
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                adminFeeAmount[i + 1] = _grossRewardTokenAmount[i];
            }
        } else if (adminFee > 0) {
            adminFeeAmount[0] = (_grossInterest.mul(adminFee)).div(100);
            totalGameInterest = _grossInterest.sub(adminFeeAmount[0]);

            for (uint256 i = 0; i < rewardTokens.length; i++) {
                adminFeeAmount[i + 1] = (_grossRewardTokenAmount[i].mul(adminFee)).div(100);
                rewardTokenAmounts[i] = _grossRewardTokenAmount[i].sub(adminFeeAmount[i + 1]);
            }
        } else {
            totalGameInterest = _grossInterest;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                rewardTokenAmounts[i] = _grossRewardTokenAmount[i];
            }
        }
        emit AdminFee(adminFeeAmount);
    }

    /**
    @dev Initializes the player stats when they join.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
    */
    function _joinGame(uint256 _minAmount, uint256 _depositAmount) internal virtual {
        if (getCurrentSegment() != 0) {
            revert GAME_ALREADY_STARTED();
        }
        bool canRejoin = players[msg.sender].canRejoin;

        if (players[msg.sender].addr == msg.sender && !canRejoin) {
            revert PLAYER_ALREADY_JOINED();
        }

        activePlayersCount = activePlayersCount.add(1);
        if (activePlayersCount > maxPlayersCount) {
            revert MAX_PLAYER_COUNT_REACHED();
        }

        if (flexibleSegmentPayment && _depositAmount > maxFlexibleSegmentPaymentAmount) {
            revert INVALID_FLEXIBLE_AMOUNT();
        }
        uint256 amount = flexibleSegmentPayment ? _depositAmount : segmentPayment;
        if (isTransactionalToken) {
            if (msg.value != amount) {
                revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
            }
        } else {
            if (msg.value != 0) {
                revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
            }
        }

        uint256 netAmount = strategy.getNetDepositAmount(amount);

        Player memory newPlayer = Player({
            addr: msg.sender,
            withdrawalSegment: 0,
            mostRecentSegmentPaid: 0,
            amountPaid: 0,
            netAmountPaid: 0,
            withdrawn: false,
            canRejoin: false,
            isWinner: false,
            depositAmount: amount
        });
        players[msg.sender] = newPlayer;
        if (!canRejoin) {
            iterablePlayers.push(msg.sender);
        }

        emit JoinedGame(msg.sender, amount);
        _transferInboundTokenToContract(_minAmount, amount, netAmount);
    }

    /**
        @dev Manages the transfer of funds from the player to the specific strategy used for the game/pool and updates the player index 
             which determines the interest and reward share of the winner based on the deposit amount amount and the time they deposit in a particular segment.
        @param _minAmount Slippage based amount to cover for impermanent loss scenario.
        @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
     */
    function _transferInboundTokenToContract(
        uint256 _minAmount,
        uint256 _depositAmount,
        uint256 _netDepositAmount
    ) internal virtual nonReentrant {
        uint64 currentSegment = getCurrentSegment();
        players[msg.sender].mostRecentSegmentPaid = currentSegment;

        players[msg.sender].amountPaid = players[msg.sender].amountPaid.add(_depositAmount);
        players[msg.sender].netAmountPaid = players[msg.sender].netAmountPaid.add(_netDepositAmount);

        // PLAYER INDEX CALCULATION TO DETERMINE INTEREST SHARE
        // player index = prev. segment player index + segment amount deposited / time stamp of deposit
        uint256 currentSegmentplayerIndex = _netDepositAmount.mul(MULTIPLIER).div(block.timestamp);
        playerIndex[msg.sender][currentSegment] = currentSegmentplayerIndex;

        uint256 cummalativePlayerIndexSumInMemory = cumulativePlayerIndexSum[currentSegment];
        for (uint256 i = 0; i <= players[msg.sender].mostRecentSegmentPaid; i++) {
            cummalativePlayerIndexSumInMemory = cummalativePlayerIndexSumInMemory.add(playerIndex[msg.sender][i]);
        }
        cumulativePlayerIndexSum[currentSegment] = cummalativePlayerIndexSumInMemory;
        // check if this is deposit for the last segment. If yes, the player is a winner.
        // since both join game and deposit method call this method so having it here
        if (currentSegment == depositCount.sub(1)) {
            // array indexes start from 0
            winnerCount = winnerCount.add(1);
            players[msg.sender].isWinner = true;
        }

        // segment counter calculation needed for ui as backup in case graph goes down
        segmentCounter[currentSegment] += 1;
        if (currentSegment != 0 && segmentCounter[currentSegment - 1] != 0) {
            segmentCounter[currentSegment - 1] -= 1;
        }

        // updating both totalGamePrincipal & netTotalGamePrincipal to maintain consistency
        totalGamePrincipal = totalGamePrincipal.add(_depositAmount);
        netTotalGamePrincipal = netTotalGamePrincipal.add(_netDepositAmount);

        if (!isTransactionalToken) {
            bool success = IERC20(inboundToken).transferFrom(msg.sender, address(strategy), _depositAmount);
            if (!success) {
                revert TOKEN_TRANSFER_FAILURE();
            }
        }

        strategy.invest{ value: msg.value }(inboundToken, _minAmount);
    }

    /// @dev Sets the game stats without redeeming the funds from the strategy.
    /// Can only be called after the game is completed when each player withdraws.
    function _setGlobalPoolParamsForFlexibleDepositPool() internal virtual nonReentrant whenGameIsCompleted {
        // Since this is only called in the case of variable deposit & it is called everytime a player decides to withdraw,
        // so totalBalance keeps a track of the ucrrent balance & the accumulated principal + interest stored in the strategy protocol.
        uint256 totalBalance = isTransactionalToken
            ? address(this).balance.add(strategy.getTotalAmount())
            : IERC20(inboundToken).balanceOf(address(this)).add(strategy.getTotalAmount());

        uint256[] memory grossRewardTokenAmount = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            // the reward calculation is the sum of the current reward amount the remaining rewards being accumulated in the strategy protocols.
            // the reason being like totalBalance for every player this is updated and prev. value is used to add any left over value
            if (address(rewardTokens[i]) != address(0) && inboundToken != address(rewardTokens[i])) {
                grossRewardTokenAmount[i] = rewardTokenAmounts[i].add(
                    strategy.getAccumulatedRewardTokenAmounts(disableRewardTokenClaim)[i]
                );
            }
        }
        uint256 grossInterest = _calculateAndUpdateGameAccounting(totalBalance, grossRewardTokenAmount);

        if (!redeemed) {
            _calculateAndSetAdminAccounting(grossInterest, grossRewardTokenAmount);
            redeemed = true;
        }

        emit VariablePoolParamsSet(
            totalBalance,
            netTotalGamePrincipal,
            totalGameInterest,
            totalIncentiveAmount,
            rewardTokenAmounts
        );
    }

    /// @dev Checks if player is a winner.
    /// @dev this function assumes that the player has already joined the game.
    ///      We should always check if the player is a participant in the pool before using this function.
    /// @return "true" if player is a winner; otherwise, return "false".
    function _isWinner(Player storage _player, uint64 _depositCountMemory) internal view returns (bool) {
        return
            _player.isWinner ||
            (emergencyWithdraw &&
                (
                    _depositCountMemory == 0
                        ? _player.mostRecentSegmentPaid >= _depositCountMemory
                        : _player.mostRecentSegmentPaid >= _depositCountMemory.sub(1)
                ));
    }

    //*********************************************************************//
    // ------------------------- external/public methods -------------------------- //
    //*********************************************************************//

    /**
    @dev Enable early game completion in case of a emergency like the strategy contract becomes inactive in the midddle of the game etc.
    // Once enabled players can withdraw their funds along with interest for winners.
    */
    function enableEmergencyWithdraw() external onlyOwner whenGameIsNotCompleted {
        if (totalGamePrincipal == 0) {
            revert EARLY_EXIT_NOT_POSSIBLE();
        }
        // setting depositCount as current segment to manage all scenario's to handle emergency withdraw
        depositCount = getCurrentSegment();
        emergencyWithdraw = true;
    }

    /**
    @dev Set's the incentive token address.
    @param _incentiveToken Incentive token address
    */
    function setIncentiveToken(IERC20 _incentiveToken) public onlyOwner whenGameIsNotCompleted {
        if (address(incentiveToken) != address(0)) {
            revert INCENTIVE_TOKEN_ALREADY_SET();
        } else {
            if ((inboundToken != address(0) && inboundToken == address(_incentiveToken))) {
                revert INVALID_INCENTIVE_TOKEN();
            }
            IERC20[] memory _rewardTokens = strategy.getRewardTokens();
            for (uint256 i = 0; i < _rewardTokens.length; i++) {
                // If there's an incentive token address defined, sets the total incentive amount to be distributed among winners.
                if (
                    ((address(_rewardTokens[i]) != address(0) && address(_rewardTokens[i]) == address(_incentiveToken)))
                ) {
                    revert INVALID_INCENTIVE_TOKEN();
                }
            }
        }
        incentiveToken = _incentiveToken;
    }

    /**
    @dev Disable claiming reward tokens for emergency scenarios, like when external reward contracts become
        inactive or rewards funds aren't available, allowing users to withdraw principal + interest from contract.
    */
    function disableClaimingRewardTokens() external onlyOwner whenGameIsNotCompleted {
        disableRewardTokenClaim = true;
    }

    /// @dev pauses the game. This function can be called only by the contract's admin.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev unpauses the game. This function can be called only by the contract's admin.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Unlocks renounceOwnership.
    function unlockRenounceOwnership() external onlyOwner {
        allowRenouncingOwnership = true;
    }

    /// @dev Renounces Ownership.
    function renounceOwnership() public override onlyOwner {
        if (!allowRenouncingOwnership) {
            revert RENOUNCE_OWNERSHIP_NOT_ALLOWED();
        }
        super.renounceOwnership();
    }

    /**
    @dev Allows admin to set a lower early withdrawal fee.
    @param _newEarlyWithdrawFees New earlywithdrawal fee.
    */
    function lowerEarlyWithdrawFees(uint128 _newEarlyWithdrawFees) external virtual onlyOwner {
        if (_newEarlyWithdrawFees >= earlyWithdrawalFee) {
            revert INVALID_EARLY_WITHDRAW_FEE();
        }
        earlyWithdrawalFee = _newEarlyWithdrawFees;
    }

    /// @dev Allows the admin to withdraw the performance fee, if applicable. This function can be called only by the contract's admin.
    /// Cannot be called before the game ends.
    function adminFeeWithdraw() external virtual onlyOwner whenGameIsCompleted {
        if (adminWithdraw) {
            revert ADMIN_FEE_WITHDRAWN();
        }
        adminWithdraw = true;

        if (!flexibleSegmentPayment) {
            if (!redeemed) {
                revert FUNDS_NOT_REDEEMED_FROM_EXTERNAL_POOL();
            }
        } else {
            _setGlobalPoolParamsForFlexibleDepositPool();
        }

        // to avoid SLOAD multiple times
        uint256 adminInterestShare = adminFeeAmount[0];
        if (adminInterestShare != 0) {
            if (flexibleSegmentPayment) {
                strategy.redeem(inboundToken, adminInterestShare, flexibleSegmentPayment, 0, disableRewardTokenClaim);
            }
            if (isTransactionalToken) {
                // safety check
                // this scenario is very tricky to mock
                // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
                if (adminInterestShare > address(this).balance) {
                    adminInterestShare = address(this).balance;
                }
                (bool success, ) = msg.sender.call{ value: adminInterestShare }("");
                if (!success) {
                    revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
                }
            } else {
                // safety check
                if (adminInterestShare > IERC20(inboundToken).balanceOf(address(this))) {
                    adminInterestShare = IERC20(inboundToken).balanceOf(address(this));
                }
                bool success = IERC20(inboundToken).transfer(owner(), adminInterestShare);
                if (!success) {
                    revert TOKEN_TRANSFER_FAILURE();
                }
            }
        }

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (address(rewardTokens[i]) != address(0)) {
                if (adminFeeAmount[i + 1] != 0) {
                    bool success = rewardTokens[i].transfer(owner(), adminFeeAmount[i + 1]);
                    if (!success) {
                        revert TOKEN_TRANSFER_FAILURE();
                    }
                }
            }
        }

        if (winnerCount == 0) {
            if (totalIncentiveAmount != 0) {
                bool success = IERC20(incentiveToken).transfer(owner(), totalIncentiveAmount);
                if (!success) {
                    revert TOKEN_TRANSFER_FAILURE();
                }
            }
        }

        // emitting it here since to avoid duplication made the if block common for incentive and reward tokens
        emit AdminWithdrawal(owner(), totalGameInterest, totalIncentiveAmount, adminFeeAmount);
    }

    /**
    @dev Allows a player to join the game/pool by makking the first deposit.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
    */
    function joinGame(uint256 _minAmount, uint256 _depositAmount)
        external
        payable
        virtual
        whenGameIsInitialized
        whenNotPaused
        whenGameIsNotCompleted
    {
        _joinGame(_minAmount, _depositAmount);
    }

    /**
    @dev Allows a player to withdraw funds before the game ends. An early withdrawal fee is charged.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario in case of a amm strategy like curve or mobius.
    */
    function earlyWithdraw(uint256 _minAmount) external whenNotPaused whenGameIsNotCompleted {
        Player storage player = players[msg.sender];
        if (player.amountPaid == 0) {
            revert PLAYER_DOES_NOT_EXIST();
        }
        if (player.withdrawn) {
            revert PLAYER_ALREADY_WITHDREW_EARLY();
        }
        player.withdrawn = true;
        activePlayersCount = activePlayersCount.sub(1);

        // In an early withdraw, users get their principal minus the earlyWithdrawalFee % defined in the constructor.
        uint256 withdrawAmount = player.netAmountPaid.sub(player.netAmountPaid.mul(earlyWithdrawalFee).div(100));
        // Decreases the totalGamePrincipal on earlyWithdraw
        totalGamePrincipal = totalGamePrincipal.sub(player.amountPaid);
        netTotalGamePrincipal = netTotalGamePrincipal.sub(player.netAmountPaid);

        uint64 currentSegment = getCurrentSegment();
        player.withdrawalSegment = currentSegment;
        // Users that early withdraw during the first segment, are allowed to rejoin.
        if (currentSegment == 0) {
            player.canRejoin = true;
            playerIndex[msg.sender][currentSegment] = 0;
        }

        // since there is complexity of 2 vars here with if else logic so not using 2 memory vars here only 1.
        uint256 cumulativePlayerIndexSumForCurrentSegment = cumulativePlayerIndexSum[currentSegment];
        for (uint256 i = 0; i <= players[msg.sender].mostRecentSegmentPaid; i++) {
            if (cumulativePlayerIndexSumForCurrentSegment != 0) {
                cumulativePlayerIndexSumForCurrentSegment = cumulativePlayerIndexSumForCurrentSegment.sub(
                    playerIndex[msg.sender][i]
                );
            } else {
                cumulativePlayerIndexSum[currentSegment - 1] = cumulativePlayerIndexSum[currentSegment - 1].sub(
                    playerIndex[msg.sender][i]
                );
            }
        }
        cumulativePlayerIndexSum[currentSegment] = cumulativePlayerIndexSumForCurrentSegment;

        // update winner count
        if (winnerCount != 0 && player.isWinner) {
            winnerCount = winnerCount.sub(1);
            player.isWinner = false;
        }

        // segment counter calculation needed for ui as backup in case graph goes down
        if (segmentCounter[currentSegment] != 0) {
            segmentCounter[currentSegment] -= 1;
        }

        emit EarlyWithdrawal(msg.sender, withdrawAmount, totalGamePrincipal, netTotalGamePrincipal);
        strategy.earlyWithdraw(inboundToken, withdrawAmount, _minAmount);
        if (isTransactionalToken) {
            // safety check
            // this scenario is very tricky to mock
            // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
            if (address(this).balance < withdrawAmount) {
                withdrawAmount = address(this).balance;
            }
            (bool success, ) = msg.sender.call{ value: withdrawAmount }("");
            if (!success) {
                revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
            }
        } else {
            // safety check
            if (IERC20(inboundToken).balanceOf(address(this)) < withdrawAmount) {
                withdrawAmount = IERC20(inboundToken).balanceOf(address(this));
            }
            bool success = IERC20(inboundToken).transfer(msg.sender, withdrawAmount);
            if (!success) {
                revert TOKEN_TRANSFER_FAILURE();
            }
        }
    }

    /**
    @dev Allows player to withdraw their funds after the game ends with no loss (fee). Winners get a share of the interest earned & additional rewards based on the player index.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario in case of a amm strategy like curve or mobius.
    */
    function withdraw(uint256 _minAmount) external virtual {
        Player storage player = players[msg.sender];
        if (player.amountPaid == 0) {
            revert PLAYER_DOES_NOT_EXIST();
        }
        if (player.withdrawn) {
            revert PLAYER_ALREADY_WITHDREW();
        }
        player.withdrawn = true;

        if (!flexibleSegmentPayment) {
            // First player to withdraw redeems everyone's funds
            if (!redeemed) {
                redeemFromExternalPoolForFixedDepositPool(_minAmount);
            }
        } else {
            _setGlobalPoolParamsForFlexibleDepositPool();
        }
        uint256 payout = player.netAmountPaid;
        uint256 playerIncentive = 0;
        uint256 playerInterestShare = 0;
        uint256 playerSharePercentage = 0;
        uint256[] memory playerReward = new uint256[](rewardTokens.length);
        // to avoid SLOAD multiple times
        uint64 depositCountMemory = depositCount;
        if (_isWinner(player, depositCountMemory)) {
            // Calculate Cummalative index for each player
            uint256 playerIndexSum = 0;

            uint64 segment = depositCountMemory == 0 ? 0 : uint64(depositCountMemory.sub(1));
            uint64 segmentPaid = emergencyWithdraw ? segment : players[msg.sender].mostRecentSegmentPaid;

            // calculate playerIndexSum for each player
            for (uint256 i = 0; i <= segmentPaid; i++) {
                playerIndexSum = playerIndexSum.add(playerIndex[msg.sender][i]);
            }
            player.withdrawalSegment = uint64(segmentPaid.add(1));
            // calculate playerSharePercentage for each player
            playerSharePercentage = (playerIndexSum.mul(100)).div(cumulativePlayerIndexSum[segment]);

            if (impermanentLossShare != 0 && totalGameInterest == 0) {
                // new payput in case of impermanent loss
                payout = player.netAmountPaid.mul(impermanentLossShare).div(100);
            } else {
                // Player is a winner and gets a bonus!
                // the player share of interest is calculated from player index
                // player share % = playerIndex / cumulativePlayerIndexSum of player indexes of all winners * 100
                // so, interest share = player share % * total game interest
                playerInterestShare = totalGameInterest.mul(playerSharePercentage).div(100);
                payout = payout.add(playerInterestShare);
            }

            // Calculates winner's share of the additional rewards & incentives
            if (totalIncentiveAmount != 0) {
                playerIncentive = totalIncentiveAmount.mul(playerSharePercentage).div(100);
            }
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                if (address(rewardTokens[i]) != address(0) && rewardTokenAmounts[i] != 0) {
                    playerReward[i] = rewardTokenAmounts[i].mul(playerSharePercentage).div(100);
                }
            }

            // subtract global params to make sure they are updated in case of flexible segment payment
            if (flexibleSegmentPayment) {
                totalGameInterest = totalGameInterest.sub(playerInterestShare);
                cumulativePlayerIndexSum[segment] = cumulativePlayerIndexSum[segment].sub(playerIndexSum);
                for (uint256 i = 0; i < rewardTokens.length; i++) {
                    rewardTokenAmounts[i] = rewardTokenAmounts[i].sub(playerReward[i]);
                }

                totalIncentiveAmount = totalIncentiveAmount.sub(playerIncentive);
            }
        }
        emit Withdrawal(msg.sender, payout, playerIncentive, playerReward);
        // Updating total principal as well after each player withdraws this is separate since we have to do this for non-players
        if (flexibleSegmentPayment) {
            if (netTotalGamePrincipal < player.netAmountPaid) {
                netTotalGamePrincipal = 0;
            } else {
                netTotalGamePrincipal = netTotalGamePrincipal.sub(player.netAmountPaid);
            }

            // Withdraws funds (principal + interest + rewards) from external pool
            strategy.redeem(inboundToken, payout, flexibleSegmentPayment, _minAmount, disableRewardTokenClaim);
        }

        // sending the inbound token amount i.e principal + interest to the winners and just the principal in case of players
        // adding a balance safety check to ensure the tx does not revert in case of impermanent loss
        if (isTransactionalToken) {
            // this scenario is very tricky to mock
            // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
            if (payout > address(this).balance) {
                payout = address(this).balance;
            }
            (bool success, ) = msg.sender.call{ value: payout }("");
            if (!success) {
                revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
            }
        } else {
            // this scenario is very tricky to mock
            // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
            if (payout > IERC20(inboundToken).balanceOf(address(this))) {
                payout = IERC20(inboundToken).balanceOf(address(this));
            }
            bool success = IERC20(inboundToken).transfer(msg.sender, payout);
            if (!success) {
                revert TOKEN_TRANSFER_FAILURE();
            }
        }

        // sending the rewards & incentives to the winners
        if (playerIncentive != 0) {
            // this scenario is very tricky to mock
            // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
            if (playerIncentive > IERC20(incentiveToken).balanceOf(address(this))) {
                playerIncentive = IERC20(incentiveToken).balanceOf(address(this));
            }
            bool success = IERC20(incentiveToken).transfer(msg.sender, playerIncentive);
            if (!success) {
                revert TOKEN_TRANSFER_FAILURE();
            }
        }

        for (uint256 i = 0; i < playerReward.length; i++) {
            if (playerReward[i] != 0) {
                // this scenario is very tricky to mock
                // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
                if (playerReward[i] > IERC20(rewardTokens[i]).balanceOf(address(this))) {
                    playerReward[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
                }
                bool success = IERC20(rewardTokens[i]).transfer(msg.sender, playerReward[i]);
                if (!success) {
                    revert TOKEN_TRANSFER_FAILURE();
                }
            }
        }
    }

    /**
    @dev Allows players to make deposits for the game segments, after joining the game.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
    */
    function makeDeposit(uint256 _minAmount, uint256 _depositAmount) external payable whenNotPaused {
        if (players[msg.sender].withdrawn) {
            revert PLAYER_ALREADY_WITHDREW_EARLY();
        }
        // only registered players can deposit
        if (players[msg.sender].addr != msg.sender) {
            revert NOT_PLAYER();
        }
        if (flexibleSegmentPayment) {
            if (_depositAmount != players[msg.sender].depositAmount) {
                revert INVALID_FLEXIBLE_AMOUNT();
            }
        }
        uint256 currentSegment = getCurrentSegment();
        // User can only deposit between segment 1 and segment n-1 (where n is the number of segments for the game) or if the emergencyWithdraw flag has not been enabled.
        // Details:
        // Segment 0 is paid when user joins the game (the first deposit window).
        // Last segment doesn't accept payments, because the payment window for the last
        // segment happens on segment n-1 (penultimate segment).
        // Any segment greater than the last segment means the game is completed, and cannot
        // receive payments
        if (currentSegment == 0 || currentSegment >= depositCount || emergencyWithdraw) {
            revert DEPOSIT_NOT_ALLOWED();
        }

        //check if current segment is currently unpaid
        if (players[msg.sender].mostRecentSegmentPaid == currentSegment) {
            revert PLAYER_ALREADY_PAID_IN_CURRENT_SEGMENT();
        }

        // check if player has made payments up to the previous segment
        if (players[msg.sender].mostRecentSegmentPaid != currentSegment.sub(1)) {
            revert PLAYER_DID_NOT_PAID_PREVIOUS_SEGMENT();
        }

        uint256 amount = flexibleSegmentPayment ? _depositAmount : segmentPayment;
        if (isTransactionalToken) {
            if (msg.value != amount) {
                revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
            }
        } else {
            if (msg.value != 0) {
                revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
            }
        }
        uint256 netAmount = strategy.getNetDepositAmount(amount);
        emit Deposit(msg.sender, currentSegment, amount, netAmount);
        _transferInboundTokenToContract(_minAmount, amount, netAmount);
    }

    /**
    @dev Redeems funds from the external pool and updates the game stats.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    */
    function redeemFromExternalPoolForFixedDepositPool(uint256 _minAmount) public virtual whenGameIsCompleted {
        uint256 totalBalance = 0;

        // Withdraws funds (principal + interest + rewards) from external pool
        strategy.redeem(inboundToken, 0, flexibleSegmentPayment, _minAmount, disableRewardTokenClaim);

        if (isTransactionalToken) {
            totalBalance = address(this).balance;
        } else {
            totalBalance = IERC20(inboundToken).balanceOf(address(this));
        }

        rewardTokens = strategy.getRewardTokens();
        uint256[] memory grossRewardTokenAmount = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            // the reward calculation is the sum of the current reward amount the remaining rewards being accumulated in the strategy protocols.
            // the reason being like totalBalance for every player this is updated and prev. value is used to add any left over value
            if (address(rewardTokens[i]) != address(0) && inboundToken != address(rewardTokens[i])) {
                grossRewardTokenAmount[i] = rewardTokens[i].balanceOf(address(this));
            }
        }

        uint256 grossInterest = _calculateAndUpdateGameAccounting(totalBalance, grossRewardTokenAmount);
        // shifting this after the game accounting since we need to emit a accounting event
        if (redeemed) {
            revert FUNDS_REDEEMED_FROM_EXTERNAL_POOL();
        }
        redeemed = true;

        _calculateAndSetAdminAccounting(grossInterest, grossRewardTokenAmount);

        emit FundsRedeemedFromExternalPool(
            isTransactionalToken ? address(this).balance : IERC20(inboundToken).balanceOf(address(this)),
            netTotalGamePrincipal,
            totalGameInterest,
            totalIncentiveAmount,
            rewardTokenAmounts
        );
    }

    // Fallback Functions for calldata and reciever for handling only ether transfer
    receive() external payable {
        if (!isTransactionalToken) {
            revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
        }
    }
}