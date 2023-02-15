/**
 *Submitted for verification at polygonscan.com on 2023-02-15
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: contracts/strategies/IStrategy.sol

pragma solidity 0.8.7;

interface IStrategy {
    function invest(address _inboundCurrency, uint256 _minAmount) external payable;

    function earlyWithdraw(address _inboundCurrency, uint256 _amount, uint256 _minAmount) external;

    function redeem(
        address _inboundCurrency,
        uint256 _amount,
        uint256 _minAmount,
        bool disableRewardTokenClaim
    ) external;

    function getTotalAmount() external view returns (uint256);

    function getLPTokenAmount(uint256 _amount) external view returns (uint256);

    function getFee() external view returns (uint256);

    function getNetDepositAmount(uint256 _amount) external view returns (uint256);

    function getAccumulatedRewardTokenAmounts(bool disableRewardTokenClaim) external returns (uint256[] memory);

    function getRewardTokens() external view returns (IERC20[] memory);

    function getUnderlyingAsset() external view returns (address);

    function strategyOwner() external view returns (address);
}

// File: contracts/Pool.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;




// import "hardhat/console.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error ADMIN_FEE_WITHDRAWN();
error DEPOSIT_NOT_ALLOWED();
error EARLY_EXIT_NOT_POSSIBLE();
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
error INVALID_NET_DEPOSIT_AMOUNT();
error INVALID_TRANSACTIONAL_TOKEN_SENDER();
error INVALID_OWNER();
error INVALID_SEGMENT_LENGTH();
error INVALID_SEGMENT_PAYMENT();
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
@author Francis Odisi & Viraz Malhotra.
*/
contract Pool is Ownable, Pausable, ReentrancyGuard {
    /// @notice Multiplier used for calculating playerIndex to avoid precision issues.
    uint256 public constant MULTIPLIER = 10 ** 12;

    /// @notice Maximum Flexible Deposit Amount in case of flexible pools.
    uint256 public immutable maxFlexibleSegmentPaymentAmount;

    /// @notice The time duration (in seconds) of each segment.
    uint64 public immutable segmentLength;

    /// @notice The performance admin fee (percentage).
    uint64 public immutable adminFee;

    /// @notice The time duration (in seconds) of last segment (waiting round).
    uint64 public immutable waitingRoundSegmentLength;

    /// @notice Defines the max quantity of players allowed in the game.
    uint64 public immutable maxPlayersCount;

    /// @notice The amount to be paid on each segment in case "flexibleSegmentPayment" is false (fixed payments).
    uint256 public immutable segmentPayment;

    /// @notice Address of the token used for depositing into the game by players.
    address public immutable inboundToken;

    /// @notice Flag which determines whether the segment payment is fixed or not.
    bool public immutable flexibleSegmentPayment;

    /// @notice Flag which determines whether the deposit token is a transactional token like eth or matic (blockchain native token, not ERC20).
    bool public immutable isTransactionalToken;

    /// @notice When the game started (game initialized timestamp).
    uint64 public firstSegmentStart;

    /// @notice Timestamp when the waiting segment starts.
    uint64 public waitingRoundSegmentStart;

    /// @notice The number of segments in the game (segment count).
    uint64 public depositCount;

    /// @notice The early withdrawal fee (percentage).
    uint64 public earlyWithdrawalFee;

    /// @notice Controls the amount of active players in the game (ignores players that early withdraw).
    uint64 public activePlayersCount;

    /// @notice winner counter to track no of winners.
    uint64 public winnerCount;

    /// @notice counter to track no of winners lef to withdraw for admin accounting.
    uint64 public winnersLeftToWithdraw;

    /// @notice the % share of interest accrued during the total duration of deposit rounds.
    /// @dev the interest/rewards/incentive accounting is divided in two phases:
    ///     a) the total duration of deposit rounds in the game
    ///     b) the total duration of the waiting round in the game
    /// These are compared against the total game duration to calculate the weight
    uint64 public depositRoundInterestSharePercentage;

    /// @notice Stores the total amount of net interest received in the game.
    uint256 public totalGameInterest;

    /// @notice net total principal amount to reduce the slippage imapct from amm strategies.
    uint256 public netTotalGamePrincipal;

    /// @notice total principal amount only used to keep a track of the gross deposits.
    uint256 public totalGamePrincipal;

    /// @notice performance fee amount allocated to the admin.
    uint256[] public adminFeeAmount;

    /// @notice total amount of incentive tokens to be distributed among winners.
    uint256 public totalIncentiveAmount;

    /// @notice share % from impermanent loss.
    uint256 public impermanentLossShare;

    /// @notice total rewardTokenAmounts.
    uint256[] public rewardTokenAmounts;

    /// @notice emaergency withdraw flag.
    bool public emergencyWithdraw;

    /// @notice Checks if admin fee has been assigned.
    bool public adminFeeSet;

    /// @notice Controls if reward tokens are to be claimed at the time of redeem.
    bool public disableRewardTokenClaim;

    /// @notice controls if admin withdrew or not the performance fee.
    bool public adminWithdraw;

    /// @notice Ownership Control flag.
    bool public allowRenouncingOwnership;

    /// @notice Strategy Contract Address
    IStrategy public strategy;

    /// @notice Defines an optional token address used to provide additional incentives to users. Accepts "0x0" adresses when no incentive token exists.
    IERC20 public incentiveToken;

    /// @notice address of additional reward token accured from investing via different strategies like wmatic.
    IERC20[] public rewardTokens;

    /// @notice struct for storing all player stats.
    /// @param withdrawn boolean flag indicating whether a player has withdrawn or not
    /// @param canRejoin boolean flag indicating whether a player can re-join or not
    /// @param isWinner boolean flag indicating whether a player is a winner or not
    /// @param addr player address
    /// @param withdrawalSegment segment at which a player withdraws
    /// @param mostRecentSegmentPaid is the most recent segment in which the deposit was made by the player
    /// @param amountPaid the total amount paid by a player
    /// @param netAmountPaid the new total amount paid by a player considering the slippage & fees for amm strategies
    /// @param depositAmount the deposit amount the player has decided to pay per segment needed for variable deposit game
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

    /// @notice Stores info of the no of players that deposited in each segment.
    mapping(uint256 => uint256) public segmentCounter;

    /// @notice Stores info of cumulativePlayerIndexSum for each segment for early exit scenario.
    /// so if for the key as segment `3` cumulativePlayerIndexSum will have player index sum
    /// of all players who have deposited in segment `3` from the current segment and previous segments.
    mapping(uint256 => uint256) public cumulativePlayerIndexSum;

    /// @notice Stores the total deposited amount by winners in each segment.
    /// @dev we need this for calculating the waiting round share amount of the
    /// winners depending on their total deposit size (individual ratio compared to all winners).
    /// totalWinnerDepositsPerSegment for let's say segment `3` will be the sum of deposits from
    // all winning players who have deposited in segment `3` & other previous segments.
    mapping(uint256 => uint256) public totalWinnerDepositsPerSegment;

    /// @notice list of players.
    address[] public iterablePlayers;

    //*********************************************************************//
    // ------------------------- events -------------------------- //
    //*********************************************************************//
    event JoinedGame(address indexed player, uint256 amount, uint256 netAmount);

    event Deposit(address indexed player, uint256 indexed segment, uint256 amount, uint256 netAmount);

    event WithdrawInboundTokens(address indexed player, uint256 amount);

    event WithdrawIncentiveToken(address indexed player, uint256 amount);

    event WithdrawRewardTokens(address indexed player, uint256[] amounts);

    event UpdateGameStats(
        address indexed player,
        uint256 totalBalance,
        uint256 totalGamePrincipal,
        uint256 netTotalGamePrincipal,
        uint256 totalGameInterest,
        uint256 totalIncentiveAmount,
        uint256[] totalRewardAmounts,
        uint256 impermanentLossShare
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
        address indexed player,
        uint256 totalBalance,
        uint256 totalGamePrincipal,
        uint256 netTotalGamePricipal,
        uint256 totalGameInterest,
        uint256[] grossRewardTokenAmount,
        uint256 totalIncentiveAmount,
        uint256 impermanentLossShare
    );

    event AdminFee(uint256[] adminFeeAmounts);

    event ExternalTokenTransferError(address indexed token, bytes reason);

    event ExternalTokenGetBalanceError(address indexed token, bytes reason);

    event Initialized(uint64 firstSegmentStart, uint64 waitingRoundSegmentStart);

    event IncentiveTokenSet(address token);

    event EmergencyWithdrawalEnabled(
        uint64 currentSegment,
        uint64 winnerCount,
        uint64 depositRoundInterestSharePercentage
    );

    event EarlyWithdrawalFeeChanged(uint64 currentSegment, uint64 oldFee, uint64 newFee);

    event ClaimRewardTokensDisabled(uint64 currentSegment);

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
    function isWinner(address _player) external view returns (bool) {
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
    // UPDATE - A1 Audit Report
    function getCurrentSegment() public view whenGameIsInitialized returns (uint64) {
        uint256 currentSegment;
        // to avoid SLOAD multiple times
        uint256 _waitingRoundSegmentStart = waitingRoundSegmentStart;
        uint256 endOfWaitingRound = _waitingRoundSegmentStart + waitingRoundSegmentLength;
        // logic for getting the current segment while the game is on waiting round
        if (_waitingRoundSegmentStart <= block.timestamp && block.timestamp < endOfWaitingRound) {
            currentSegment = depositCount;
        } else if (block.timestamp >= endOfWaitingRound) {
            // logic for getting the current segment after the game completes (waiting round is over)
            currentSegment = depositCount + 1 + ((block.timestamp - endOfWaitingRound) / segmentLength);
        } else {
            // logic for getting the current segment during segments that allows depositing (before waiting round)
            currentSegment = (block.timestamp - firstSegmentStart) / segmentLength;
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
        uint64 _segmentLength,
        uint64 _waitingRoundSegmentLength,
        uint256 _segmentPayment,
        uint64 _earlyWithdrawalFee,
        uint64 _customFee,
        uint64 _maxPlayersCount,
        bool _flexibleSegmentPayment,
        IStrategy _strategy,
        bool _isTransactionalToken
    ) {
        flexibleSegmentPayment = _flexibleSegmentPayment;
        isTransactionalToken = _isTransactionalToken;
        if (_customFee > 100) {
            revert INVALID_CUSTOM_FEE();
        }
        if (_earlyWithdrawalFee > 99) {
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

        // UPDATE - A4 Audit Report
        if (_underlyingAsset != _inboundCurrency && !_isTransactionalToken) {
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
        // length of the array is more, considering the inbound token since there would be fee on interest
        adminFeeAmount = new uint256[](rewardTokens.length + 1);
    }

    /**
    @dev Initializes the pool by setting the start time, the waiting round start time, incentive token (optional) & updates the interest share % of the deposit phase
    @param _incentiveToken Incentive token address (optional to set).
    */
    function initialize(IERC20 _incentiveToken) public virtual onlyOwner whenGameIsNotInitialized whenNotPaused {
        if (strategy.strategyOwner() != address(this)) {
            revert INVALID_OWNER();
        }
        firstSegmentStart = uint64(block.timestamp); //gets current time
        unchecked {
            waitingRoundSegmentStart = firstSegmentStart + (segmentLength * depositCount);
        }
        _updateInterestShares(0);
        setIncentiveToken(_incentiveToken);
        emit Initialized(firstSegmentStart, waitingRoundSegmentStart);
    }

    //*********************************************************************//
    // ------------------------- internal methods -------------------------- //
    //*********************************************************************//
    /**
    @dev Transfer external tokens with try/catch in place so the external token transfer failures don't affect the transaction confirmation
    @param _token token address.
    @param _to recipient of the token.
    @param _amount transfer amount.
    */
    // UPDATE - N1 Audit Report
    function _transferTokenOrContinueOnFailure(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        try IERC20(_token).balanceOf(address(this)) returns (uint256 tokenBalance) {
            if (_amount > tokenBalance) {
                _amount = tokenBalance;
            }
        } catch (bytes memory reason) {
            _amount = 0;
            emit ExternalTokenGetBalanceError(_token, reason);
        }
        if (_amount != 0) {
            try IERC20(_token).transfer(_to, _amount) returns (bool success) {
                if (!success) {
                    // forces error event to be emitted in case false is returned from ERC20.transfer.
                    revert TOKEN_TRANSFER_FAILURE();
                }
            } catch (bytes memory reason) {
                emit ExternalTokenTransferError(_token, reason);
            }
        }
        return _amount;
    }

    /**
    @dev Winner interest accounting based on the interest amount share in the deposit rounds & waiting round.
    @param _segment last deposit segment for the winners.
    @param _impermanentLossShare impermanent loss share during the current withdrawal.
    @return _playerIndexSharePercentage is the percentage share of the winners during deposit rounds for getting interest/rewards/incentives based on player index.
    @return _playerDepositAmountSharePercentage is the percentage share of the winners during waiting round for getting interest/rewards/incentives based on player deposits.
    @return _payout total amount to be transferred to the winners.
    */
    function _calculateAndUpdateWinnerInterestAccounting(
        uint64 _segment,
        uint256 _impermanentLossShare
    )
        internal
        returns (uint256 _playerIndexSharePercentage, uint256 _playerDepositAmountSharePercentage, uint256 _payout)
    {
        // memory variables for the player interest amount accounting for both deposits and waiting rounds.
        uint256 playerInterestAmountDuringDepositRounds;
        uint256 playerInterestAmountDuringWaitingRounds;

        // winners of the game get a share of the interest, reward & incentive tokens based on how early they deposit, the amount they deposit in case of avriable deposit pool & the ratio of the deposit & waiting round.
        // Calculate Cummalative index of the withdrawing player
        uint256 playerIndexSum = 0;

        // calculate playerIndexSum for each player
        for (uint256 i = 0; i <= _segment; ) {
            playerIndexSum += playerIndex[msg.sender][i];
            unchecked {
                ++i;
            }
        }

        // calculate playerIndexSharePercentage for each player
        // UPDATE - H3 Audit Report
        _playerIndexSharePercentage = (playerIndexSum * MULTIPLIER) / cumulativePlayerIndexSum[_segment];

        // reduce cumulativePlayerIndexSum since a winner only withdraws their own funds.
        cumulativePlayerIndexSum[_segment] -= playerIndexSum;

        _payout = players[msg.sender].netAmountPaid;

        // calculate _playerDepositAmountSharePercentage for each player for waiting round calculations depending on how much deposit share the player has.
        // have a safety check players[msg.sender].netAmountPaid > totalWinnerDepositsPerSegment[segment] in case of a impermanent loss
        // in case of a impermanent loss although we probably won't need it since we reduce player's netAmountPaid too but just in case.
        _playerDepositAmountSharePercentage = _payout > totalWinnerDepositsPerSegment[_segment]
            ? MULTIPLIER // UPDATE - H3 Audit Report
            : (_payout * MULTIPLIER) / totalWinnerDepositsPerSegment[_segment];

        // update storage vars since each winner withdraws only funds entitled to them.
        if (totalWinnerDepositsPerSegment[_segment] < _payout) {
            totalWinnerDepositsPerSegment[_segment] = 0;
        } else {
            totalWinnerDepositsPerSegment[_segment] -= _payout;
        }

        // checking for impermenent loss
        if (_impermanentLossShare != 0) {
            // new payput in case of impermanent loss
            _payout = (_payout * _impermanentLossShare) / 100;

            // update netAmountPaid in case of impermanent loss
            players[msg.sender].netAmountPaid = _payout;
        }

        // checking for impermenent loss
        // save gas by checking the interest before entering in the if block
        if (_impermanentLossShare == 0 && totalGameInterest != 0) {
            // calculating the interest amount accrued in waiting & deposit Rounds.
            uint256 interestAccruedDuringDepositRounds = (totalGameInterest * depositRoundInterestSharePercentage) /
                MULTIPLIER;
            // we calculate interestAccruedDuringWaitingRound by subtracting the totalGameInterest by interestAccruedDuringDepositRounds
            uint256 interestAccruedDuringWaitingRound = depositRoundInterestSharePercentage == MULTIPLIER
                ? 0
                : totalGameInterest - interestAccruedDuringDepositRounds;

            // calculating the player interest share split b/w the waiting & deposit rounds.
            playerInterestAmountDuringWaitingRounds =
                (interestAccruedDuringWaitingRound * _playerDepositAmountSharePercentage) /
                MULTIPLIER;

            playerInterestAmountDuringDepositRounds =
                (interestAccruedDuringDepositRounds * _playerIndexSharePercentage) /
                MULTIPLIER;

            // update the total amount to be redeemed
            _payout += playerInterestAmountDuringDepositRounds + playerInterestAmountDuringWaitingRounds;

            // reduce totalGameInterest since a winner only withdraws their own funds.
            totalGameInterest -= (playerInterestAmountDuringDepositRounds + playerInterestAmountDuringWaitingRounds);
        }
        winnersLeftToWithdraw -= 1;
    }

    /**
    @dev Non-winner amount accounting.
    @param _impermanentLossShare impermanent loss share %.
    @param _netAmountPaid net amount paid by the player.
    @return payout amount to be sent to the player.
    */
    function _calculateAndUpdateNonWinnerAccounting(
        uint256 _impermanentLossShare,
        uint256 _netAmountPaid
    ) internal returns (uint256 payout) {
        if (_impermanentLossShare != 0) {
            // new payput in case of impermanent loss
            payout = (_netAmountPaid * _impermanentLossShare) / 100;
            // reduce player netAmountPaid in case of impermanent loss
            players[msg.sender].netAmountPaid = payout;
        } else {
            payout = _netAmountPaid;
        }

        // non-winners don't get any rewards/incentives
        uint256[] memory rewardAmounts = new uint256[](rewardTokens.length);
        emit WithdrawIncentiveToken(msg.sender, 0);
        emit WithdrawRewardTokens(msg.sender, rewardAmounts);
    }

    /**
    @dev Winner reward accounting based on the player amount share % calculated based on player index & total deposits made.
    @param playerDepositAmountSharePercentage Deposit amount share %.
    @param playerIndexSharePercentage Player index share %..
    */
    function _calculateAndUpdateWinnerRewardAccounting(
        uint256 playerDepositAmountSharePercentage,
        uint256 playerIndexSharePercentage
    ) internal {
        // calculating winners share of the reward amounts
        // memory vars to avoid SLOADS & for the player rewards share accounting
        IERC20[] memory _rewardTokens = rewardTokens;
        uint256[] memory _rewardTokenAmounts = rewardTokenAmounts;
        uint256[] memory playerRewards = new uint256[](_rewardTokens.length);
        // reference for array length to save gas
        uint256 _rewardLength = _rewardTokens.length;

        for (uint256 i = 0; i < _rewardLength; ) {
            if (address(_rewardTokens[i]) != address(0) && _rewardTokenAmounts[i] != 0) {
                // calculating the reward token amount split b/w waiting & deposit Rounds.
                uint256 totalRewardAmountsDuringDepositRounds = (_rewardTokenAmounts[i] *
                    depositRoundInterestSharePercentage) / MULTIPLIER;
                // we calculate totalRewardAmountsWaitingRounds by subtracting the rewardTokenAmounts by totalRewardAmountsDuringDepositRounds
                uint256 totalRewardAmountsWaitingRounds = depositRoundInterestSharePercentage == MULTIPLIER
                    ? 0
                    : _rewardTokenAmounts[i] - totalRewardAmountsDuringDepositRounds;

                // calculating the winner reward token amount share split b/w the waiting & deposit rounds.
                uint256 playerRewardShareAmountDuringDepositRounds = (totalRewardAmountsDuringDepositRounds *
                    playerIndexSharePercentage) / MULTIPLIER;
                uint256 playerRewardShareAmountDuringWaitingRounds = (totalRewardAmountsWaitingRounds *
                    playerDepositAmountSharePercentage) / MULTIPLIER;

                // update the rewards to be transferred
                playerRewards[i] =
                    playerRewardShareAmountDuringDepositRounds +
                    playerRewardShareAmountDuringWaitingRounds;

                // update storage var since each winner withdraws only funds entitled to them.
                _rewardTokenAmounts[i] -= playerRewards[i];

                // transferring the reward token share to the winner
                // updates variable value to make sure on a failure, event is emitted w/ correct value.
                // UPDATE - Related to N1 Audit Report (If an external protocol reward token get's compromised)
                playerRewards[i] = _transferTokenOrContinueOnFailure(
                    address(_rewardTokens[i]),
                    msg.sender,
                    playerRewards[i]
                );
            }
            unchecked {
                ++i;
            }
        }
        // avoid SSTORE inside loop
        rewardTokenAmounts = _rewardTokenAmounts;

        // We have to ignore the "check-effects-interactions" pattern here and emit the event
        // only at the end of the function, in order to emit it w/ the correct withdrawal amount.
        // In case the safety checks above are evaluated to true, payout, playerIncentiv and playerReward
        // are updated, so we need the event to be emitted with the correct info.
        emit WithdrawRewardTokens(msg.sender, playerRewards);
    }

    /**
    @dev Winner incentive accounting based on the player amount share % calculated based on player index & total deposits made.
    @param playerDepositAmountSharePercentage Deposit amount share %.
    @param playerIndexSharePercentage Player index share %..
    */
    function _calculateAndUpdateWinnerIncentivesAccounting(
        uint256 playerDepositAmountSharePercentage,
        uint256 playerIndexSharePercentage
    ) internal {
        uint256 playerIncentive;
        if (totalIncentiveAmount != 0) {
            // calculating the incentive amount split b/w waiting & deposit Rounds.
            uint256 incentiveAmountSharedDuringDepositRounds = (totalIncentiveAmount *
                depositRoundInterestSharePercentage) / MULTIPLIER;
            // we calculate incentiveAmountShareDuringWaitingRound by subtracting the totalIncentiveAmount by incentiveAmountSharedDuringDepositRounds
            uint256 incentiveAmountShareDuringWaitingRound = depositRoundInterestSharePercentage == MULTIPLIER
                ? 0
                : totalIncentiveAmount - incentiveAmountSharedDuringDepositRounds;

            // calculating the winner incentive amount share split b/w the waiting & deposit rounds.
            uint256 playerIncentiveAmountDuringDepositRounds = (incentiveAmountSharedDuringDepositRounds *
                playerIndexSharePercentage) / MULTIPLIER;
            uint256 playerIncentiveAmountDuringWaitingRounds = (incentiveAmountShareDuringWaitingRound *
                playerDepositAmountSharePercentage) / MULTIPLIER;

            playerIncentive = playerIncentiveAmountDuringDepositRounds + playerIncentiveAmountDuringWaitingRounds;

            // update storage var since each winner withdraws only funds entitled to them.
            totalIncentiveAmount -= playerIncentive;

            // transferring the incentive share to the winner
            // updates variable value to make sure on a failure, event is emitted w/ correct value.
            // UPDATE - N1 Audit Report
            playerIncentive = _transferTokenOrContinueOnFailure(address(incentiveToken), msg.sender, playerIncentive);
        }
        // We have to ignore the "check-effects-interactions" pattern here and emit the event
        // only at the end of the function, in order to emit it w/ the correct withdrawal amount.
        // In case the safety checks above are evaluated to true, payout, playerIncentiv and playerReward
        // are updated, so we need the event to be emitted with the correct info.
        emit WithdrawIncentiveToken(msg.sender, playerIncentive);
    }

    /**
    @notice updates the waiting and deposit rounds time percentages based on the total duration of the pool, total deposit round & waiting round duration.
    @param _currentSegment current segment value.
    */
    function _updateInterestShares(uint64 _currentSegment) internal {
        // if emergencyWithdraw hasn't been enabled then the calculation of the percentages is pretty straightforward
        // we get the total durations of the deposit and waiting round and get the % share out of the total duration
        if (!emergencyWithdraw) {
            uint64 endOfWaitingRound = waitingRoundSegmentStart + waitingRoundSegmentLength;
            uint64 totalGameDuration = endOfWaitingRound - firstSegmentStart;
            depositRoundInterestSharePercentage = uint64(
                (segmentLength * depositCount * MULTIPLIER) / totalGameDuration
            );
        } else {
            // if emergencyWithdraw is enabled & it got enabled during the waiting round then we re-calculate the waiting round period
            // we then get the total durations of the deposit and waiting round and get the % share out of the total duration
            if (_currentSegment == depositCount) {
                uint64 totalGameDuration = uint64(block.timestamp) - firstSegmentStart;
                depositRoundInterestSharePercentage = uint64(
                    (segmentLength * depositCount * MULTIPLIER) / totalGameDuration
                );
            } else {
                // if emergencyWithdraw is enabled & it got enabled before the waiting round then we set the depositRoundInterestSharePercentage to 100 % and waitingRoundInterestSharePercentage will indirectly be 0.
                depositRoundInterestSharePercentage = uint64(MULTIPLIER);
            }
        }
    }

    /**
    @notice check if there are any rewards to claim for the admin.
    @param _adminFeeAmount admin fee amount value.
    */
    function _checkRewardsClaimableByAdmin(uint256[] memory _adminFeeAmount) internal pure returns (bool) {
        // reference for array length to save gas
        uint256 _adminFeeAmountsLength = _adminFeeAmount.length;
        // starts loop from 1, because first spot of _adminFeeAmount is reserved for admin interest share.
        for (uint256 i = 1; i < _adminFeeAmountsLength; ) {
            if (_adminFeeAmount[i] != 0) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /**
    @notice Transfer funds after balance checks to the players / admin.
    @param _recepient address which will receive tokens.
    @param _amount transfer amount.
    */
    // UPDATE - A3 Audit Report
    function _transferFundsSafelyOrFail(address _recepient, uint256 _amount) internal returns (uint256) {
        if (isTransactionalToken) {
            // safety check
            // this scenario is very tricky to mock
            // and our mock contracts are pretty complex currently so haven't tested this line with unit tests
            if (_amount > address(this).balance) {
                _amount = address(this).balance;
            }
            (bool success, ) = _recepient.call{ value: _amount }("");
            if (!success) {
                revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
            }
        } else {
            // safety check
            if (_amount > IERC20(inboundToken).balanceOf(address(this))) {
                _amount = IERC20(inboundToken).balanceOf(address(this));
            }
            bool success = IERC20(inboundToken).transfer(_recepient, _amount);
            if (!success) {
                revert TOKEN_TRANSFER_FAILURE();
            }
        }
        return _amount;
    }

    /**
    @notice
    Calculates and updates's game accounting called by methods _setGlobalPoolParams.
    Updates the game storage vars used for calculating player interest, incentives etc.
    @param _totalBalance Total inbound token balance in the contract.
    @param _grossRewardTokenAmount Gross reward amounts.
    */
    function _calculateAndUpdateGameAccounting(
        uint256 _totalBalance,
        uint256[] memory _grossRewardTokenAmount
    ) internal returns (uint256) {
        uint256 _grossInterest = 0;

        if (_totalBalance >= netTotalGamePrincipal) {
            // calculates the gross interest
            _grossInterest = _totalBalance - netTotalGamePrincipal;
        } else {
            // handling impermanent loss case
            impermanentLossShare = (_totalBalance * 100) / netTotalGamePrincipal;
            netTotalGamePrincipal = _totalBalance;
        }
        // sets the totalIncentiveAmount if available
        // UPDATE - N1 Audit Report
        address _incentiveToken = address(incentiveToken);
        if (_incentiveToken != address(0)) {
            try IERC20(_incentiveToken).balanceOf(address(this)) returns (uint256 _totalIncentiveAmount) {
                totalIncentiveAmount = _totalIncentiveAmount;
            } catch (bytes memory reason) {
                emit ExternalTokenGetBalanceError(_incentiveToken, reason);
            }
        }
        // this condition is added because emit is to only be emitted when adminFeeSet flag is false but this mehtod is called for every player withdrawal in variable deposit pool.
        if (!adminFeeSet) {
            winnersLeftToWithdraw = winnerCount;
            emit EndGameStats(
                msg.sender,
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
    Calculates and set's admin accounting called by methods _setGlobalPoolParams.
    Updates the admin fee storage var used for admin fee.
    @param _grossInterest Gross interest amount.
    @param _grossRewardTokenAmount Gross reward amount array.
    */
    function _calculateAndSetAdminAccounting(
        uint256 _grossInterest,
        uint256[] memory _grossRewardTokenAmount
    ) internal {
        // calculates the performance/admin fee (takes a cut - the admin percentage fee - from the pool's interest, strategy rewards).
        // calculates the "gameInterest" (net interest) that will be split among winners in the game
        // calculates the rewardTokenAmounts that will be split among winners in the game
        // when there's no winners, admin takes all the interest + rewards
        // to avoid SLOAD multiple times
        IERC20[] memory _rewardTokens = rewardTokens;
        uint256[] memory _adminFeeAmount = adminFeeAmount;
        uint256[] memory _rewardTokenAmounts = rewardTokenAmounts;

        // handling the scenario when some winners withdraw later so they should get extra interest/rewards
        // the scenario wasn't handled before
        if (adminFeeSet) {
            // if the admin fee is set a check is made to check whether the admin has withdrawn or not
            if (adminWithdraw) {
                // we update the totalGameInterest/reward amounts as the gross values
                totalGameInterest = _grossInterest;
                _rewardTokenAmounts = _grossRewardTokenAmount;
            } else {
                uint256 _interestIncludingFee = totalGameInterest + _adminFeeAmount[0];
                // if the admin hasn't made a withdrawal yet so we calculate the rise in interest & update the admin fee & interest
                if (_grossInterest >= _interestIncludingFee) {
                    uint256 difference = _grossInterest - _interestIncludingFee;

                    uint256 adminfeeShareForDifference;
                    // if there are no winners then set the difference as the admin share & total game interest
                    if (winnerCount == 0 || winnersLeftToWithdraw == 0) {
                        adminfeeShareForDifference = difference;
                        totalGameInterest += difference;
                    } else {
                        // if there are winners then calculate the rise in admin fee & update both admin fee & interest accordingly
                        adminfeeShareForDifference = (difference * adminFee) / 100;
                        totalGameInterest = difference > 0 ? _grossInterest - adminfeeShareForDifference : totalGameInterest;
                    }
                    _adminFeeAmount[0] += adminfeeShareForDifference;
                } else {
                    // if _grossInterest is non zero then update admin fee & game interest with the new gross interest
                    uint256 adminfeeShareForDifference;
                    if (winnerCount == 0 || winnersLeftToWithdraw == 0) {
                    // if there are no winners then set the _grossInterest as the admin share & total game interest
                        adminfeeShareForDifference = _grossInterest;
                        totalGameInterest = _grossInterest;
                    } else {
                        // if there are winners then calculate the new admin fee share based on the gross interest & update both admin fee & interest
                        adminfeeShareForDifference = (_grossInterest * adminFee) / 100;
                        totalGameInterest = _grossInterest - adminfeeShareForDifference;
                    }
                    _adminFeeAmount[0] = adminfeeShareForDifference;
                }

                // reference for array length to save gas
                uint256 _rewardsLength = _rewardTokens.length;
                for (uint256 i = 0; i < _rewardsLength; ) {
                    // first slot is reserved for admin interest amount, so starts at 1.
                    if (_grossRewardTokenAmount[i] >= _rewardTokenAmounts[i]) {
                        uint256 difference = _grossRewardTokenAmount[i] - _rewardTokenAmounts[i];
                        uint256 adminfeeShareForDifference;
                        if (winnerCount == 0 || winnersLeftToWithdraw == 0) {
                           adminfeeShareForDifference = difference;
                           _rewardTokenAmounts[i] += difference;
                        } else {
                           adminfeeShareForDifference = (difference * adminFee) / 100;
                           _rewardTokenAmounts[i] = difference > 0 ? _grossRewardTokenAmount[i] - adminfeeShareForDifference : _rewardTokenAmounts[i];
                        }
                        _adminFeeAmount[i + 1] += adminfeeShareForDifference;
                    } else {
                        uint256 adminfeeShareForDifference;
                        if (winnerCount == 0 || winnersLeftToWithdraw == 0) {
                            adminfeeShareForDifference = _grossRewardTokenAmount[i];
                            _rewardTokenAmounts[i] = _grossRewardTokenAmount[i];
                        } else {
                            adminfeeShareForDifference = (_grossRewardTokenAmount[i] * adminFee) / 100;
                            _rewardTokenAmounts[i] = _grossRewardTokenAmount[i] - adminfeeShareForDifference;
                        }
                        _adminFeeAmount[i + 1] = adminfeeShareForDifference;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        } else {
            // reference for array length to save gas
            uint256 _rewardsLength = _rewardTokens.length;
            // if the admin fee isn't set then we set it in the else part
            // UPDATE - N2 Audit Report
            if (winnerCount == 0) {
                // in case of no winners the admin takes all the interest and the rewards & the incentive amount (check adminFeeWithdraw method)
                _adminFeeAmount[0] = _grossInterest;
                // just setting these for consistency since if there are no winners then for accounting both these vars aren't used
                totalGameInterest = _grossInterest;

                for (uint256 i = 0; i < _rewardsLength; ) {
                    _rewardTokenAmounts[i] = _grossRewardTokenAmount[i];
                    // first slot is reserved for admin interest amount, so starts at 1.
                    _adminFeeAmount[i + 1] = _grossRewardTokenAmount[i];
                    unchecked {
                        ++i;
                    }
                }
            } else if (adminFee != 0) {
                // if admin fee != 0 then the admin get's a share based on the adminFee %
                _adminFeeAmount[0] = (_grossInterest * adminFee) / 100;
                totalGameInterest = _grossInterest - _adminFeeAmount[0];

                for (uint256 i = 0; i < _rewardsLength; ) {
                    // first slot is reserved for admin interest amount, so starts at 1.
                    _adminFeeAmount[i + 1] = (_grossRewardTokenAmount[i] * adminFee) / 100;
                    _rewardTokenAmounts[i] = _grossRewardTokenAmount[i] - _adminFeeAmount[i + 1];
                    unchecked {
                        ++i;
                    }
                }
            } else {
                // if there are winners and there is no admin fee in that case the admin fee will always be 0
                totalGameInterest = _grossInterest;

                for (uint256 i = 0; i < _rewardsLength; ) {
                    _rewardTokenAmounts[i] = _grossRewardTokenAmount[i];
                    unchecked {
                        ++i;
                    }
                }
            }
            emit AdminFee(adminFeeAmount);
        }

        // avoid SSTORE in loop
        rewardTokenAmounts = _rewardTokenAmounts;
        adminFeeAmount = _adminFeeAmount;
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

        activePlayersCount += 1;
        if (activePlayersCount > maxPlayersCount) {
            revert MAX_PLAYER_COUNT_REACHED();
        }

        if (flexibleSegmentPayment && (_depositAmount == 0 || _depositAmount > maxFlexibleSegmentPaymentAmount)) {
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
        // get net deposit amount from the strategy
        uint256 netAmount = strategy.getNetDepositAmount(amount);
        if (netAmount == 0) {
            revert INVALID_NET_DEPOSIT_AMOUNT();
        }

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

        emit JoinedGame(msg.sender, amount, netAmount);
        _transferInboundTokenToContract(_minAmount, amount, netAmount);
    }

    /**
        @dev Manages the transfer of funds from the player to the specific strategy used for the game/pool and updates the player index 
        which determines the interest and reward share of the winner based on the deposit amount amount and the time they deposit in a particular segment.
        @param _minAmount Slippage based amount to cover for impermanent loss scenario.
        @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
        @param _netDepositAmount Net deposit amount.
     */
    function _transferInboundTokenToContract(
        uint256 _minAmount,
        uint256 _depositAmount,
        uint256 _netDepositAmount
    ) internal virtual {
        // this scenario given the inputs to the mock contract methods isn't possible to mock locally
        // UPDATE - H1 Audit Report
        if (_netDepositAmount > _depositAmount) {
            revert INVALID_NET_DEPOSIT_AMOUNT();
        }
        uint64 currentSegment = getCurrentSegment();
        players[msg.sender].mostRecentSegmentPaid = currentSegment;

        players[msg.sender].amountPaid += _depositAmount;
        players[msg.sender].netAmountPaid += _netDepositAmount;

        // PLAYER INDEX CALCULATION TO DETERMINE INTEREST SHARE
        // player index = prev. segment player index + segment amount deposited / difference in time of deposit from the current segment starting time
        // UPDATE - H2 Audit Report
        uint256 currentSegmentplayerIndex = (_netDepositAmount * MULTIPLIER) /
            (segmentLength + block.timestamp - (firstSegmentStart + (currentSegment * segmentLength)));
        playerIndex[msg.sender][currentSegment] = currentSegmentplayerIndex;

        // updating the cummulative player Index with all the deposits made by the player till that segment
        // Avoids SLOAD in loop
        uint256 cummalativePlayerIndexSumInMemory = cumulativePlayerIndexSum[currentSegment];
        for (uint256 i = 0; i <= currentSegment; ) {
            cummalativePlayerIndexSumInMemory += playerIndex[msg.sender][i];
            unchecked {
                ++i;
            }
        }
        cumulativePlayerIndexSum[currentSegment] = cummalativePlayerIndexSumInMemory;

        // update totalWinnerDepositsPerSegment for every segment for every deposit made
        totalWinnerDepositsPerSegment[currentSegment] += players[msg.sender].netAmountPaid;
        // check if this is deposit for the last segment. If yes, the player is a winner.
        // since both join game and deposit method call this method so having it here
        if (currentSegment == (depositCount - 1)) {
            // array indexes start from 0
            unchecked {
                winnerCount += 1;
            }
            players[msg.sender].isWinner = true;
        }

        // segment counter calculation
        unchecked {
            segmentCounter[currentSegment] += 1;
            if (currentSegment != 0 && segmentCounter[currentSegment - 1] != 0) {
                segmentCounter[currentSegment - 1] -= 1;
            }
        }

        // updating both totalGamePrincipal & netTotalGamePrincipal to maintain consistency
        totalGamePrincipal += _depositAmount;
        netTotalGamePrincipal += _netDepositAmount;

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
    function _setGlobalPoolParams() internal virtual whenGameIsCompleted {
        // this method is called everytime a player decides to withdraw,
        // to update the game storage vars because every player withdraw's their entitled amount that includes the incentive & reward tokens.
        // so totalBalance keeps a track of the ucrrent balance & the accumulated principal + interest stored in the strategy protocol.
        uint256 totalBalance = isTransactionalToken
            ? address(this).balance + strategy.getTotalAmount()
            : IERC20(inboundToken).balanceOf(address(this)) + strategy.getTotalAmount();

        // to avoid SLOAD multiple times
        IERC20[] memory _rewardTokens = rewardTokens;
        uint256[] memory _rewardTokenAmounts = rewardTokenAmounts;
        uint256[] memory grossRewardTokenAmount = new uint256[](_rewardTokens.length);
        // get the accumulated reward tokens from the strategy
        uint256[] memory accumulatedRewardTokenAmount = strategy.getAccumulatedRewardTokenAmounts(
            disableRewardTokenClaim
        );

        // reference for array length to save gas
        uint256 _rewardsLength = _rewardTokens.length;
        // iterate through the reward token array to set the total reward amounts accumulated
        for (uint256 i = 0; i < _rewardsLength; ) {
            // the reward calculation is the sum of the current reward amount the remaining rewards being accumulated in the strategy protocols.
            // the reason being like totalBalance for every player this is updated and prev. value is used to add any left over value
            if (address(_rewardTokens[i]) != address(0) && inboundToken != address(_rewardTokens[i])) {
                grossRewardTokenAmount[i] = _rewardTokenAmounts[i] + accumulatedRewardTokenAmount[i];
            }
            unchecked {
                ++i;
            }
        }
        // gets the grossInterest after updating the game accounting
        uint256 grossInterest = _calculateAndUpdateGameAccounting(totalBalance, grossRewardTokenAmount);

        _calculateAndSetAdminAccounting(grossInterest, grossRewardTokenAmount);
        adminFeeSet = true;
    }

    /// @dev Checks if player is a winner.
    /// @dev this function assumes that the player has already joined the game.
    /// We check if the player is a participant in the pool before using this function.
    /// @return "true" if player is a winner; otherwise, return "false".
    function _isWinner(Player storage _player, uint64 _depositCountMemory) internal view returns (bool) {
        // considers the emergency withdraw scenario too where if a player has paid in that or the previous segment they are considered as a winner
        return
            _player.isWinner ||
            (emergencyWithdraw &&
                (
                    _depositCountMemory == 0
                        ? _player.mostRecentSegmentPaid >= _depositCountMemory
                        : _player.mostRecentSegmentPaid >= (_depositCountMemory - 1)
                ));
    }

    /**
       Returns the maximum amount that can be redeemed from a strategy for a player/admin
     */
    function getRedemptionValue(uint256 _amountToRedeem, uint256 _totalAmount) internal returns (uint256) {
        if (_amountToRedeem > _totalAmount) {
            return _totalAmount;
        }
        return _amountToRedeem;
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
        uint64 currentSegment = getCurrentSegment();
        // UPDATE - N2 Audit Report
        // updates the winner count based on the segment counter
        winnerCount = currentSegment != 0
            ? uint64(segmentCounter[currentSegment] + segmentCounter[currentSegment - 1])
            : uint64(segmentCounter[currentSegment]);

        emergencyWithdraw = true;
        // updates the interest shhare % for the deposit round
        _updateInterestShares(currentSegment);
        // setting depositCount as current segment to manage all scenario's to handle emergency withdraw
        depositCount = currentSegment;

        emit EmergencyWithdrawalEnabled(currentSegment, winnerCount, depositRoundInterestSharePercentage);
    }

    /**
    @dev Set's the incentive token address.
    @param _incentiveToken Incentive token address
    */
    function setIncentiveToken(IERC20 _incentiveToken) public onlyOwner whenGameIsNotCompleted {
        // incentiveToken can only be set once, so we check if it has already been set if not then we check the inbound token is same as incentive token
        if (
            (address(incentiveToken) != address(0)) ||
            (inboundToken != address(0) && inboundToken == address(_incentiveToken))
        ) {
            revert INVALID_INCENTIVE_TOKEN();
        }
        // incentiveToken cannot be the same as one of the reward tokens.
        IERC20[] memory _rewardTokens = rewardTokens;

        // reference for array length to save gas
        uint256 _rewardsLength = _rewardTokens.length;
        for (uint256 i = 0; i < _rewardsLength; ) {
            if ((address(_rewardTokens[i]) != address(0) && address(_rewardTokens[i]) == address(_incentiveToken))) {
                revert INVALID_INCENTIVE_TOKEN();
            }
            unchecked {
                ++i;
            }
        }
        incentiveToken = _incentiveToken;
        emit IncentiveTokenSet(address(_incentiveToken));
    }

    /**
    @dev Disable claiming reward tokens for emergency scenarios, like when external reward contracts become
        inactive or rewards funds aren't available, allowing users to withdraw principal + interest from contract.
    */
    function disableClaimingRewardTokens() external onlyOwner whenGameIsNotCompleted {
        disableRewardTokenClaim = true;
        emit ClaimRewardTokensDisabled(getCurrentSegment());
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
    @param _newEarlyWithdrawFee New earlywithdrawal fee.
    */
    function lowerEarlyWithdrawFee(uint64 _newEarlyWithdrawFee) external virtual onlyOwner {
        uint64 currentFee = earlyWithdrawalFee;
        if (_newEarlyWithdrawFee >= currentFee) {
            revert INVALID_EARLY_WITHDRAW_FEE();
        }
        earlyWithdrawalFee = _newEarlyWithdrawFee;
        emit EarlyWithdrawalFeeChanged(getCurrentSegment(), currentFee, _newEarlyWithdrawFee);
    }

    /// @dev Allows the admin to withdraw the performance fee, if applicable. This function can be called only by the contract's admin.
    /// Cannot be called before the game ends.
    /// @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    function adminFeeWithdraw(uint256 _minAmount) external virtual onlyOwner whenGameIsCompleted {
        if (adminWithdraw) {
            revert ADMIN_FEE_WITHDRAWN();
        }
        adminWithdraw = true;

        // UPDATE - C2 Audit Report - removing redeem method
        _setGlobalPoolParams();
        // to avoid SLOAD multiple times
        // UPDATE - A5 Audit Report
        uint256[] memory _adminFeeAmount = adminFeeAmount;
        IERC20[] memory _rewardTokens = rewardTokens;

        // flag that indicates if there are any rewards claimable by the admin
        bool _claimableRewards = _checkRewardsClaimableByAdmin(_adminFeeAmount);

        // have to check for both since the rewards, interest accumulated along with the total deposit is withdrawn in a single redeem call
        if (_adminFeeAmount[0] != 0 || _claimableRewards) {
            // safety check in case some incentives in the form of the deposit tokens are transferred to the pool
            uint256 _amountToRedeem = getRedemptionValue(_adminFeeAmount[0], strategy.getTotalAmount());
            strategy.redeem(inboundToken, _amountToRedeem, _minAmount, disableRewardTokenClaim);

            // need the updated value for the event
            // balance check before transferring the funds
            _adminFeeAmount[0] = _transferFundsSafelyOrFail(owner(), _adminFeeAmount[0]);

            if (_claimableRewards) {
                // reference for array length to save gas
                uint256 _rewardsLength = _rewardTokens.length;
                for (uint256 i = 0; i < _rewardsLength; ) {
                    if (address(_rewardTokens[i]) != address(0)) {
                        // updates variable value to make sure on a failure, event is emitted w/ correct value.
                        // first slot is reserved for admin interest amount, so starts at 1.
                        _adminFeeAmount[i + 1] = _transferTokenOrContinueOnFailure(
                            address(_rewardTokens[i]),
                            owner(),
                            _adminFeeAmount[i + 1]
                        );
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        }

        uint256 _adminIncentiveAmount;
        // winnerCount will always have the correct number of winners fetched from segment counter if emergency withdraw is enabled.
        // UPDATE - N2 Audit Report
        if (winnerCount == 0) {
            if (totalIncentiveAmount != 0) {
                // updates variable value to make sure on a failure, event is emitted w/ correct value.
                // UPDATE - N1 Audit Report
                _adminIncentiveAmount = _transferTokenOrContinueOnFailure(
                    address(incentiveToken),
                    owner(),
                    totalIncentiveAmount
                );
            }
        }

        // emitting it here since to avoid duplication made the if block common for incentive and reward tokens
        emit AdminWithdrawal(owner(), totalGameInterest, _adminIncentiveAmount, _adminFeeAmount);
    }

    /**
    @dev Allows a player to join the game/pool by makking the first deposit.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
    */
    function joinGame(
        uint256 _minAmount,
        uint256 _depositAmount
    ) external payable virtual whenGameIsInitialized whenNotPaused whenGameIsNotCompleted nonReentrant {
        _joinGame(_minAmount, _depositAmount);
    }

    /**
    @dev Allows a player to withdraw funds before the game ends. An early withdrawal fee is charged.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario in case of a amm strategy like curve or mobius.
    */
    // UPDATE - L1 Audit Report
    function earlyWithdraw(uint256 _minAmount) external whenNotPaused whenGameIsNotCompleted nonReentrant {
        Player storage player = players[msg.sender];
        if (player.amountPaid == 0) {
            revert PLAYER_DOES_NOT_EXIST();
        }
        if (player.withdrawn) {
            revert PLAYER_ALREADY_WITHDREW_EARLY();
        }
        player.withdrawn = true;
        activePlayersCount -= 1;

        // In an early withdraw, users get their principal minus the earlyWithdrawalFee % defined in the constructor & it also considers the impermanent loss.
        uint256 _totalBalance = isTransactionalToken
            ? address(this).balance + strategy.getTotalAmount()
            : IERC20(inboundToken).balanceOf(address(this)) + strategy.getTotalAmount();

        uint256 withdrawAmount = player.netAmountPaid - ((player.netAmountPaid * earlyWithdrawalFee) / 100);
        if (_totalBalance < netTotalGamePrincipal) {
            // handling impermanent loss case
            uint256 _impermanentLossShare = (_totalBalance * 100) / netTotalGamePrincipal;
            withdrawAmount = (withdrawAmount * _impermanentLossShare) / 100;
        }

        // Decreases the totalGamePrincipal & netTotalGamePrincipal on earlyWithdraw
        totalGamePrincipal -= player.amountPaid;
        netTotalGamePrincipal -= player.netAmountPaid;

        uint64 currentSegment = getCurrentSegment();
        player.withdrawalSegment = currentSegment;

        uint256 playerIndexSum;
        // calculate playerIndexSum for each player
        for (uint256 i = 0; i <= player.mostRecentSegmentPaid; ) {
            playerIndexSum += playerIndex[msg.sender][i];
            unchecked {
                ++i;
            }
        }
        // Users that early withdraw during the first segment, are allowed to rejoin.
        if (currentSegment == 0) {
            player.canRejoin = true;
            playerIndex[msg.sender][currentSegment] = 0;
        }

        // FIX - C3 Audit Report
        // reduce the cumulativePlayerIndexSum for the segment where the player doing the early withdraw deposited last
        // cumulativePlayerIndexSum has the value of the player index sums for all player till the current segment.
        cumulativePlayerIndexSum[player.mostRecentSegmentPaid] -= playerIndexSum;
        // reduce the totalWinnerDepositsPerSegment for the segment.
        totalWinnerDepositsPerSegment[player.mostRecentSegmentPaid] -= player.netAmountPaid;

        unchecked {
            // update winner count
            if (winnerCount != 0 && player.isWinner) {
                winnerCount -= 1;
                player.isWinner = false;
            }

            // segment counter calculation needed for ui as backup in case graph goes down
            if (segmentCounter[currentSegment] != 0) {
                segmentCounter[currentSegment] -= 1;
            }
        }

        strategy.earlyWithdraw(inboundToken, withdrawAmount, _minAmount);

        // balance check before transferring the funds
        uint256 actualTransferredAmount = _transferFundsSafelyOrFail(msg.sender, withdrawAmount);

        // We have to ignore the "check-effects-interactions" pattern here and emit the event
        // only at the end of the function, in order to emit it w/ the correct withdrawal amount.
        // In case the safety checks above are evaluated to true, withdrawAmount is updated,
        // so we need the event to be emitted with the correct info.
        emit EarlyWithdrawal(msg.sender, actualTransferredAmount, totalGamePrincipal, netTotalGamePrincipal);
    }

    /**
    @dev Allows player to withdraw their funds after the game ends with no loss (fee). Winners get a share of the interest earned & additional rewards based on the player index.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario in case of a amm strategy like curve or mobius.
    */
    // UPDATE - L1 Audit Report
    function withdraw(uint256 _minAmount) external virtual nonReentrant {
        Player storage player = players[msg.sender];
        if (player.amountPaid == 0) {
            revert PLAYER_DOES_NOT_EXIST();
        }
        if (player.withdrawn) {
            revert PLAYER_ALREADY_WITHDREW();
        }
        player.withdrawn = true;

        // UPDATE - C2 Audit Report - removing redeem method
        _setGlobalPoolParams();

        // to avoid SLOAD multiple times
        uint64 depositCountMemory = depositCount;
        uint256 _impermanentLossShare = impermanentLossShare;

        uint256 payout;

        if (_isWinner(player, depositCountMemory)) {
            // determining last game segment considering the possibility of emergencyWithdraw
            uint64 segment = depositCountMemory == 0 ? 0 : uint64(depositCountMemory - 1);
            (
                uint256 playerIndexSharePercentage,
                uint256 playerDepositAmountSharePercentage,
                uint256 _payout
            ) = _calculateAndUpdateWinnerInterestAccounting(segment, _impermanentLossShare);
            payout = _payout;
            // safety check in case some incentives in the form of the deposit tokens are transferred to the pool\
            uint256 _amountToRedeem = getRedemptionValue(payout, strategy.getTotalAmount());

            strategy.redeem(inboundToken, _amountToRedeem, _minAmount, disableRewardTokenClaim);

            // calculating winners share of the incentive amount
            _calculateAndUpdateWinnerIncentivesAccounting(
                playerDepositAmountSharePercentage,
                playerIndexSharePercentage
            );

            // calculating winners share of the reward earned from the external protocol deposits/no_strategy
            _calculateAndUpdateWinnerRewardAccounting(playerDepositAmountSharePercentage, playerIndexSharePercentage);
        } else {
            payout = _calculateAndUpdateNonWinnerAccounting(_impermanentLossShare, player.netAmountPaid);
            // safety check in case some incentives in the form of the deposit tokens are transferred to the pool
            uint256 _amountToRedeem = getRedemptionValue(payout, strategy.getTotalAmount());
            // Withdraws the principal for non-winners
            strategy.redeem(inboundToken, _amountToRedeem, _minAmount, disableRewardTokenClaim);
        }

        // sets withdrawalSegment for the player
        player.withdrawalSegment = getCurrentSegment();
        if (_impermanentLossShare != 0) {
            // resetting I.Loss Share % after every withdrawal to be consistent
            impermanentLossShare = 0;
        }

        // Updating total principal as well after each player withdraws this is separate since we have to do this for non-players
        if (netTotalGamePrincipal < player.netAmountPaid) {
            netTotalGamePrincipal = 0;
            totalGamePrincipal = 0;
        } else {
            netTotalGamePrincipal -= player.netAmountPaid;
            totalGamePrincipal -= player.amountPaid;
        }

        // sending the inbound token amount i.e principal + interest to the winners and just the principal in case of players
        // adding a balance safety check to ensure the tx does not revert in case of impermanent loss
        uint256 actualTransferredAmount = _transferFundsSafelyOrFail(msg.sender, payout);
        // We have to ignore the "check-effects-interactions" pattern here and emit the event
        // only at the end of the function, in order to emit it w/ the correct withdrawal amount.
        // In case the safety checks above are evaluated to true, payout, playerIncentive and playerReward
        // are updated, so we need the event to be emitted with the correct info.
        emit WithdrawInboundTokens(msg.sender, actualTransferredAmount);

        emit UpdateGameStats(
            msg.sender,
            isTransactionalToken ? address(this).balance : IERC20(inboundToken).balanceOf(address(this)),
            totalGamePrincipal,
            netTotalGamePrincipal,
            totalGameInterest,
            totalIncentiveAmount,
            rewardTokenAmounts,
            impermanentLossShare
        );
    }

    /**
    @dev Allows players to make deposits for the game segments, after joining the game.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param _depositAmount Variable Deposit Amount in case of a variable deposit pool.
    */
    function makeDeposit(uint256 _minAmount, uint256 _depositAmount) external payable whenNotPaused nonReentrant {
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
        if (players[msg.sender].mostRecentSegmentPaid != (currentSegment - 1)) {
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

        // get net deposit amount from the strategy
        uint256 netAmount = strategy.getNetDepositAmount(amount);
        if (netAmount == 0) {
            revert INVALID_NET_DEPOSIT_AMOUNT();
        }
        emit Deposit(msg.sender, currentSegment, amount, netAmount);
        _transferInboundTokenToContract(_minAmount, amount, netAmount);
    }

    // Fallback Functions for calldata and reciever for handling only ether transfer
    // UPDATE - A7 Audit Report
    receive() external payable {
        if (msg.sender != address(strategy)) {
            revert INVALID_TRANSACTIONAL_TOKEN_SENDER();
        }
        if (!isTransactionalToken) {
            revert INVALID_TRANSACTIONAL_TOKEN_AMOUNT();
        }
    }
}