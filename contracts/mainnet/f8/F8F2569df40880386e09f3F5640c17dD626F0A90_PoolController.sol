// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGame {
    function supportsIGame() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInternalToken is IERC20 {
    function supportsIInternalToken() external view returns (bool);

    function burnTokenFrom(address account, uint256 amount) external;

    function mint(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPool {
    function supportsIPool() external view returns (bool);

    function addBetToPool(uint256 betAmount) external payable;

    function jackpotDistribution(
        address payable player,
        uint256 prize
    ) external;

    function rewardDistribution(address payable player, uint256 prize) external;

    function freezeJackpot(uint256 amount) external;

    function addToJackpot(uint256 amount) external;

    function updateRefereeStats(
        address player,
        uint256 amount,
        uint256 betEdge
    ) external;

    function getOracleGasFee() external view returns (uint256);

    function getNativeTokensTotal() external view returns (uint256);

    function getAvailableJackpot() external view returns (uint256);

    function totalJackpot() external view returns (uint256);

    function jackpotLimit() external view returns (uint256);

    function receiveFundsFromGame() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IInternalToken.sol";
import "./interfaces/IGame.sol";

/**
 * @notice Controls the tokens pool of the game, distributes rewards.
 *        Controls the referral program payments
 */
contract PoolController is IPool, Context, Ownable {
    using SafeMath for uint256;

    /**
     * @dev The representation of the pool
     */
    struct Pool {
        // The internal token of the pool
        IInternalToken internalToken;
        // The amount of native tokens paid to mint internal tokens into the pool
        uint256 nativeTokensTotal;
        // Gas fee for oracle services
        uint256 oracleGasFee;
        // Total amount of fees collected by the oracle
        uint256 oracleTotalGasFee;
    }

    /**
     * The representation of the account taking part in the referral system
     */
    struct RefAccount {
        // The account who invited another account to the referral system
        address parent;
        // The percent to be paid for referral system membership as a bonus
        uint256 bonusPercent;
        // Total amount of tokens won buy the referer
        uint256 referersTotalWinnings;
        // Total amount of tokens earned buy the referee during the referral program
        uint256 referralEarningsBalance;
        // The amount of referers of the referee
        uint256 referralCounter;
    }
    /**
     * @dev If `bonusPercent` is 5 and `_percentDivider` is 100, then house edge is 5 / 100 = 0.05%
     */
    uint256 private constant _percentDivider = 100;

    /**
     * @notice Indicates that a new referer has been registered
     */
    event RegisteredReferer(address referee, address referral);

    /**
     * @notice Indicates that a player won a jackpot
     */
    event JackpotWin(address player, uint256 amount);

    /**
     * @notice Each milestone reached by the referee increases his bonus percent
     * @dev {refereesBonusPercentMilestones[i]} corresponds to {referersTotalWinningsMilestones[i]} and vice versa
     */
    uint256[7] public referersTotalWinningsMilestones;
    uint256[7] public refereesBonusPercentMilestones;

    /**
     * @dev Equivalent between native token and internal tokens
     *      e.g. 1 ETH (native) = 1_000_000 xETH (internal)
     * NOTE: This is NOT a price. Price is not constant.
     */
    uint256 internal constant INTERNALS_FOR_NATIVE = 10 ** 6;

    /**
     * @notice The total amount of tokens stored to be paid as jackpot
     */
    uint256 public totalJackpot;
    /**
     * @notice Amount of tokens freezed to be paid some time in the future
     */
    uint256 public freezedJackpot;
    /**
     * @notice The maximum amount of tokens to be stored for jackpot payments
     */
    uint256 public jackpotLimit;

    /**
     * @notice All account taking part in the referral program
     */
    mapping(address => RefAccount) public refAccounts;
    /**
     * @notice The list of addresses that can deposit funds into the pool
     */
    mapping(address => bool) public whitelist;

    /**
     * @dev The address of the operator. Usually the backend address
     */
    address private _oracleOperator;
    /**
     * @dev The game using this pool controller
     */
    IGame private _game;
    /**
     * @dev The pool controlled by this pool controller
     */
    Pool private pool;

    /**
     * @dev Checks that caller is the game using this pool controller
     */
    modifier onlyGame() {
        require(
            _msgSender() == address(_game),
            "PoolController: caller is not a game owner!"
        );
        _;
    }
    /**
     * @dev Checks that caller is the pool operator
     */
    modifier onlyOracleOperator() {
        require(
            _msgSender() == _oracleOperator,
            "PoolController: caller is not an operator!"
        );
        _;
    }

    constructor(address internalTokenAddress) {
        IInternalToken internalCandidate = IInternalToken(internalTokenAddress);
        require(
            internalCandidate.supportsIInternalToken(),
            "PoolController: invalid xTRX token address!"
        );

        pool.internalToken = internalCandidate;
        pool.oracleGasFee = 3000000;
        whitelist[_msgSender()] = true;
        referersTotalWinningsMilestones = [
            0,
            20000000000,
            60000000000,
            100000000000,
            140000000000,
            180000000000,
            220000000000
        ];
        refereesBonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];
        totalJackpot = 78000000000;
        jackpotLimit = 1950000000000;
    }

    /**
     * @notice Allows anyone to add funds into the pool
     */
    receive() external payable {}

    /** @notice Returns referral program winnings milestones
     * @return Referral program winnings milestones
     */
    function getTotalWinningsMilestones()
        external
        view
        returns (uint256[7] memory)
    {
        return referersTotalWinningsMilestones;
    }

    /**
     * @notice Returns referral program bonus percent milestones
     * @return Referral program bonus percent milestones
     */
    function getBonusPercentMilestones()
        external
        view
        returns (uint256[7] memory)
    {
        return refereesBonusPercentMilestones;
    }

    /**
     * @notice Returns the address of the game that is using this pool controller
     * @return The address of the game that is using this pool controller
     */
    function getGame() external view returns (address) {
        return address(_game);
    }

    /**
     * @notice Should be called by other contracts to check that the contract with the given
     *        address supports the {IPool} interface
     * @return Always True
     */
    function supportsIPool() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Calculates the amount of native tokens ready to be withdrawn from the pool based
     *        on the provided amount of internal tokens
     * @param internalTokensAmount The amount of internal tokens used to calculate the withdrawable amount of native tokens
     * @return The withdrawable amount of native tokens
     */
    function getWithDrawableNatives(
        uint256 internalTokensAmount
    ) external view returns (uint256) {
        // 1. internalTokensAmount.div(INTERNALS_FOR_NATIVE) - The equivalent of how many native tokens was provided as internal tokens in the parameter
        // 2. (1).mul(_realNativePrice()) - Calibrate the amount on native tokens based on the real price of the native tokens
        return
            internalTokensAmount.mul(_realNativePrice()).div(
                INTERNALS_FOR_NATIVE
            );
    }

    /**
     * @notice Returns information about the current pool
     * @return - The Address of internal token
     *         - The total amount of native tokens paid to the pool
     *         - The gas fee paid for oracle services
     *         - The total amount of fees paid to the
     */
    function getPoolInfo()
        external
        view
        returns (address, uint256, uint256, uint256)
    {
        return (
            address(pool.internalToken),
            pool.nativeTokensTotal,
            pool.oracleGasFee,
            pool.oracleTotalGasFee
        );
    }

    /**
     * @notice Returns the total amount of native tokens paid to the pool
     * @return The total amount of native tokens paid to the pool
     */
    function getNativeTokensTotal() external view returns (uint256) {
        return pool.nativeTokensTotal;
    }

    /**
     * @notice Returns the address of the internal token of the pool
     * @return The address of the internal token of the pool
     */
    function getTokenAddress() external view returns (address) {
        return address(pool.internalToken);
    }

    /**
     * @notice Returns the gas fee paid for oracle services
     * @return The gas fee paid for oracle services
     */
    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }

    /**
     * @notice Returns the address of the oracle operator
     * @return The address of the oracle operator
     */
    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }

    /**
     * @notice Shows information about the referral program referee
     * @param referee The address of the referee to check
     * @return - The address of the referee's parent
     *         - The bonus percent for the referee
     *         - The total amount of tokens won while using referral program
     *         - The amount of referers of the referee
     */
    function getReferralStats(
        address referee
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        return (
            refAccounts[referee].parent,
            refAccounts[referee].bonusPercent,
            refAccounts[referee].referersTotalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].referralCounter
        );
    }

    /**
     * @notice Sets new milestones for referral program winnings
     * @param newTotalWinningMilestones New milestones to be set
     */
    function setTotalWinningsMilestones(
        uint256[] calldata newTotalWinningMilestones
    ) external onlyOwner {
        for (uint256 i = 0; i < 7; i++) {
            referersTotalWinningsMilestones[i] = newTotalWinningMilestones[i];
        }
    }

    /**
     * @notice Sets new milestones for bonus percents of the referral program winnings
     * @param newBonusPercents New milestones to be set
     */
    function setBonusPercentMilestones(
        uint256[] calldata newBonusPercents
    ) external onlyOwner {
        for (uint256 i = 0; i < 7; i++) {
            refereesBonusPercentMilestones[i] = newBonusPercents[i];
        }
    }

    /**
     * @notice Changes the jackpot amount of the game
     * @param jackpot The new jackpot
     */
    function setTotalJackpot(uint256 jackpot) external onlyOwner {
        totalJackpot = jackpot;
    }

    /**
     * @notice Changes the jackpot limit of the game
     * @param jackpotLimit_ The new jackpot limit
     */
    function setJackpotLimit(uint256 jackpotLimit_) external onlyOwner {
        jackpotLimit = jackpotLimit_;
    }

    /**
     * @notice Adds the provided amount of tokens to the jackpot
     * @param amount The amount of tokens to add to jackpot
     */
    function addToJackpot(uint256 amount) external onlyGame {
        totalJackpot = totalJackpot.add(amount);
    }

    /**
     * @notice Locks a part of jackpot to be paid to the player later in the future
     * @param amount The amount of tokens to lock
     */
    function freezeJackpot(uint256 amount) external onlyGame {
        freezedJackpot = freezedJackpot.add(amount);
    }

    /**
     * @notice Returns the amount of non-freezed jackpot available
     * @return The amount of available jackpot
     */
    function getAvailableJackpot() public view returns (uint256) {
        return totalJackpot.sub(freezedJackpot);
    }

    /**
     * @notice Receives tokens from game and stores them on the contract's balance
     */
    function receiveFundsFromGame() external payable onlyGame {}

    /**
     * @notice Pays the prize to the jackpot winner
     * @param player The jackpot winner address
     * @param prize The prize to pay
     */
    function jackpotDistribution(
        address payable player,
        uint256 prize
    ) external onlyGame {
        // Prize to be paid is subtracted from the total jackpot
        totalJackpot = totalJackpot.sub(prize);
        // Prize to be paid is subtracted from the freezed jackpot
        freezedJackpot = freezedJackpot.sub(prize);
        _rewardDistribution(player, prize);
        emit JackpotWin(player, prize);
    }

    /**
     * @notice Updates referral program information of the referee of the provided member (referer)
     * @param referer The member taking part on the referral program
     * @param winAmount The amount the referer won in the game
     * @param refAmount The amount used to calculcate the payment for the refere
     */
    function updateRefereeStats(
        address referer,
        uint256 winAmount,
        uint256 refAmount
    ) external onlyGame {
        // Get the parent (referee) of the current member (referer) and update his stats
        address parent = refAccounts[referer].parent;
        // Add referer's winnings
        refAccounts[parent].referersTotalWinnings = refAccounts[parent]
            .referersTotalWinnings
            .add(winAmount);
        _updateReferralBonusPercent(parent);
        // Add referral amount to the earnings
        uint256 referralEarnings = refAmount
            .mul(refAccounts[parent].bonusPercent)
            .div(_percentDivider);
        refAccounts[parent].referralEarningsBalance = refAccounts[parent]
            .referralEarningsBalance
            .add(referralEarnings);
    }

    /**
     * @notice Adds bet to the pool and pays oracle for services
     * @param betAmount The bet to add to the pool
     */
    function addBetToPool(uint256 betAmount) external payable onlyGame {
        uint256 oracleGasFee = pool.oracleGasFee;
        pool.nativeTokensTotal = pool.nativeTokensTotal.add(betAmount).sub(
            oracleGasFee
        );
        pool.oracleTotalGasFee = pool.oracleTotalGasFee.add(oracleGasFee);
    }

    /**
     * @notice Pays the prize to the player
     * @param player The player receiving the prize
     * @param prize The prize to be paid
     */
    function rewardDistribution(
        address payable player,
        uint256 prize
    ) public onlyGame {
        _rewardDistribution(player, prize);
    }

    /**
     * @notice Transfers referral earnings of the referee to the provided player
     * @param player The receiver of withdrawn referral earnings
     */
    function withdrawReferralEarnings(address payable player) external {
        uint256 reward = refAccounts[player].referralEarningsBalance;
        refAccounts[player].referralEarningsBalance = 0;
        _rewardDistribution(player, reward);
    }

    /**
     * @notice Deposits the provided amount of native tokens to the pool
     * @param to The address of the staker inside the pool to mint internal tokens to
     */
    function deposit(address to) external payable {
        require(
            whitelist[_msgSender()],
            "PoolController: deposit is forbidden for the caller!"
        );
        _deposit(to, msg.value);
    }

    /**
     * @notice Withdraws the amount of native tokens from the pool equal to the provided amount of internal tokens of the pool
     * @param internalTokensAmount The amount of internal tokens used to calculate the amount of native tokens to be withdrawn
     */
    function withdrawNativeForInternal(uint256 internalTokensAmount) external {
        require(
            pool.internalToken.balanceOf(_msgSender()) >= internalTokensAmount,
            "PoolController: amount exceeds token balance!"
        );
        // NOTE The real logical order of operations:
        // 1. internalTokensAmount.div(INTERNALS_FOR_NATIVE) - The equivalent of how many native tokens was provided as internal tokens in the parameter
        // 2. (1).mul(_realNativePrice()) - Calibrate the amount on native tokens based on the real price of the native tokens
        uint256 withdrawAmount = internalTokensAmount
            .mul(_realNativePrice())
            .div(INTERNALS_FOR_NATIVE);
        pool.nativeTokensTotal = pool.nativeTokensTotal.sub(withdrawAmount);
        payable(_msgSender()).transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), internalTokensAmount);
    }

    /**
     * @notice Adds an account to the whitelist
     * @param account The account to add to the whitelist
     */
    function addToWhitelist(address account) public onlyOwner {
        require(
            !whitelist[account],
            "PoolController: account is already in the whitelist"
        );
        whitelist[account] = true;
    }

    /**
     * @notice Removes the account from the whitelist
     * @param account The account to remove from the whitelist
     */
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /**
     * @notice Changes the address of the game using this pool controller
     * @param gameAddress The new address of the game
     */
    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _game = game;
    }

    /**
     * @notice Changes oracle gas fee
     * @param oracleGasFee A new oracle gas fee
     */
    function setOracleGasFee(uint256 oracleGasFee) external onlyOwner {
        pool.oracleGasFee = oracleGasFee;
    }

    /**
     * @notice Changes the oracle operator
     * @param oracleOperator The address of the new oracle operator
     */
    function setOracleOperator(address oracleOperator) external onlyOwner {
        _oracleOperator = oracleOperator;
    }

    /**
     * @notice Transfers oracle gas fee to the oracle operator and resets the fee
     */
    function takeOracleFee() external onlyOracleOperator {
        uint256 oracleTotalGasFee = pool.oracleTotalGasFee;
        pool.oracleTotalGasFee = 0;
        payable(_msgSender()).transfer(oracleTotalGasFee);
    }

    /**
     * @notice Adds a new referer to the referee in the referral program
     * @param parent The address of the referee
     * @param child The address of the referer
     */
    function addReferer(address parent, address child) external {
        require(
            refAccounts[child].parent == address(0),
            "PoolController: this address is already a referer!"
        );
        require(
            parent != child,
            "PoolController: referee and referer can not have the same address!"
        );
        refAccounts[child].parent = parent;
        refAccounts[parent].referralCounter = refAccounts[parent]
            .referralCounter
            .add(1);
        emit RegisteredReferer(parent, child);
    }

    /**
     * @dev Mints the amount of interanl tokens equal to the amount of native tokens into the pool
     * @param staker The address to mint internal tokens to
     * @param nativeTokensAmount The amount of native tokens (e.g. wei)
     */
    function _deposit(address staker, uint256 nativeTokensAmount) internal {
        // 1. nativeTokensAmount.mul(INTERNALS_FOR_NATIVE) - The equivalent of how many internal tokens was provided as native tokens
        // 2. (1).div(_realNativePrice()) - Calibrate the amount on internal tokens based on the real price of the native tokens
        uint256 tokenAmount = nativeTokensAmount.mul(INTERNALS_FOR_NATIVE).div(
            _realNativePrice()
        );
        pool.nativeTokensTotal = pool.nativeTokensTotal.add(nativeTokensAmount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    /**
     * @notice Checks the amount of tokens a referer won in total and updates
     *        a bonus percent of his referee
     * @param parent The address of the referee
     */
    function _updateReferralBonusPercent(address parent) internal {
        uint256 currentBonusPercent;
        for (uint256 i = 0; i < referersTotalWinningsMilestones.length; i++) {
            if (
                // If referees total winnings are greater than the milestone,
                // the bonus percent increases
                referersTotalWinningsMilestones[i] <
                refAccounts[parent].referersTotalWinnings
            ) {
                currentBonusPercent = refereesBonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonusPercent;
    }

    /**
     * @dev Calculates the price of a signle native token in internal tokens
     * @return The price of a single native tokens in internal tokens
     */
    function _realNativePrice() internal view returns (uint256) {
        // If no internal tokens were minted, the price is equal to the "constant price"
        if (pool.internalToken.totalSupply() == 0) {
            return INTERNALS_FOR_NATIVE;
        }
        // With each minted internal token the price changes
        // 1. (pool.nativeTokensTotal).mul(INTERNALS_FOR_NATIVE) - Equivalent of how many internal tokens is stored as native tokens in the pool
        // 2. (1).div(pool.internalToken.totalSupply()) - Ratio between internal tokens in the pool and the total amount of internal tokens in existence
        return
            (pool.nativeTokensTotal).mul(INTERNALS_FOR_NATIVE).div(
                pool.internalToken.totalSupply()
            );
    }

    /**
     * @dev Pays the prize to the provided address
     * @param player The player to pay the prize to
     * @param prize The prize to pay
     */
    function _rewardDistribution(
        address payable player,
        uint256 prize
    ) internal {
        require(
            prize <= address(this).balance,
            "PoolControoller: not enough funds to pay the reward!"
        );
        require(
            prize <= pool.nativeTokensTotal,
            "PoolControoller: not enough funds in the pool!"
        );
        pool.nativeTokensTotal = pool.nativeTokensTotal.sub(prize);
        player.transfer(prize);
    }
}