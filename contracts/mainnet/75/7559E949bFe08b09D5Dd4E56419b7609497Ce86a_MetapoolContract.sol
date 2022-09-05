// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import { console } from "hardhat/console.sol";

import { Metapool } from "./structs/Metapool.sol";

import "./Errors.sol";

contract MetapoolContract is Ownable {

  uint constant private SHORTEST_ROUND = 120;
  uint constant private SHORTEST_POSITIONING = 60;

  mapping(bytes32 => Metapool) private _metapools;
  mapping(bytes32 => bool) private _blockedMetapools;

  function addMetapool(

    address pricefeed,
    address erc20,
    uint16 version,
    uint schedule,
    uint positioning,
    uint minWager

  )
    external
    onlyOwner
  {

    // console.log("addMetapool");

    if (schedule < SHORTEST_ROUND) {
      // console.log("revert CannotAddMetapoolScheduleTooShort");
      revert CannotAddMetapoolScheduleTooShort({
        schedule: schedule,
        min: SHORTEST_ROUND
      });
    }

    if (positioning < SHORTEST_POSITIONING) {
      // console.log("revert CannotAddMetapoolPositioningTooShort");
      revert CannotAddMetapoolPositioningTooShort({
        positioning: positioning,
        min: SHORTEST_ROUND
      });
    }

    if (positioning > SafeMath.div(schedule, 2)) {
      // console.log("revert CannotAddMetapoolPositioningTooLarge");
      revert CannotAddMetapoolPositioningTooLarge({
        positioning: positioning,
        min: SafeMath.div(schedule, 2)
      });
    }

    if (minWager == 0) {
      // console.log("revert CannotAddMetapoolMinWagerZero");
      revert CannotAddMetapoolMinWagerZero();
    }

    if (version == 0) {
      // console.log("revert CannotAddMetapoolVersionZero");
      revert CannotAddMetapoolVersionZero();
    }

    // console.log("_priceFeed");
    AggregatorV3Interface _priceFeed = AggregatorV3Interface(pricefeed);
    uint8 decimals = _priceFeed.decimals();
    if (decimals == 0) {
      // console.log("revert CannotAddMetapoolWithInvalidFeedAddress");
      revert CannotAddMetapoolWithInvalidFeedAddress({
        pricefeed: pricefeed
      });
    }
    // console.log("decimals");

    IERC20 wagerToken = IERC20(erc20);
    uint balance = wagerToken.balanceOf(_msgSender());
    if (balance == 0) {
      // console.log("revert CannotAddMetapoolERC20InsufficientFunds");
      revert CannotAddMetapoolERC20InsufficientFunds({
        balance: balance,
        erc20: erc20
      });
    }

    bytes32 metapoolid = keccak256(abi.encode(
      pricefeed,
      erc20,
      version,
      schedule,
      positioning
    ));

    if (_metapools[metapoolid].metapoolid != 0x0) {
      // console.log("revert CannotAddMetapoolAlreadyExists");
      revert CannotAddMetapoolAlreadyExists();
    }

    _metapools[metapoolid] = Metapool({
      metapoolid: metapoolid,
      pricefeed: pricefeed,
      erc20: erc20,
      version: version,
      schedule: schedule,
      positioning: positioning,
      minWager: minWager,
      blocked: false
    });

    emit MetapoolAdded(
      metapoolid,
      pricefeed,
      erc20,
      version,
      schedule,
      positioning,
      minWager
    );
  }

  function _getMetapool(
    bytes32 _metapoolid
  )
    internal
    view
    returns (
      Metapool storage
    )
  {

    return _metapools[_metapoolid];

  }

  function getMetapool(
    bytes32 metapoolid
  )
    external
    view
    returns (
      Metapool memory
    )
  {

    return _getMetapool(metapoolid);

  }

  function unblockMetapool(
    bytes32 metapoolid
  )
    external
    onlyOwner
  {

    Metapool storage metapool = _metapools[metapoolid];
    if (metapool.metapoolid == 0x0) {
      // console.log("revert CannotUnblockMetapoolDoNotExists");
      revert CannotUnblockMetapoolDoNotExists();
    }
    if (!metapool.blocked) {
      // console.log("revert CannotUnblockMetapoolIsNotBlocked");
      revert CannotUnblockMetapoolIsNotBlocked();
    }

    metapool.blocked = false;

    emit MetapoolUnblocked(metapoolid);

  }

  function blockMetapool(
    bytes32 metapoolid
  )
    external
    onlyOwner
  {

    Metapool storage metapool = _metapools[metapoolid];
    if (metapool.metapoolid == 0x0) {
      // console.log("revert CannotBlockMetapoolDoNotExists");
      revert CannotBlockMetapoolDoNotExists();
    }
    if (metapool.blocked) {
      // console.log("revert CannotBlockMetapoolIsAlreadyBlocked");
      revert CannotBlockMetapoolIsAlreadyBlocked();
    }

    metapool.blocked = true;

    emit MetapoolBlocked(metapoolid);
  }

  function isMetapoolBlocked(
    bytes32 metapoolid
  )
    external
    view
    returns (bool)
  {

    Metapool storage metapool = _metapools[metapoolid];

    return metapool.blocked;

  }

  event MetapoolAdded(
    bytes32 indexed metapoolid,
    address pricefeed,
    address erc20,
    uint16 version,
    uint schedule,
    uint positioning,
    uint minWager
  );
  event MetapoolBlocked(bytes32 indexed metapoolid);
  event MetapoolUnblocked(bytes32 indexed metapoolid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

struct Metapool {

  bytes32 metapoolid;
  address pricefeed;
  address erc20;
  uint16 version;
  uint schedule;
  uint positioning;
  uint minWager;
  bool blocked;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// ERC20 tokens supported as assets
error ThisTokenIsNotSupported();

/// Insufficient funds for wagered amount
error InsufficientFunds();

/// Insufficient allowance for amount
error InsufficientAllowance();

/// Only Externally Owned Account bettors allowed
error OnlyEOABettorsAllowed();

/// Provided MetaPool is not supporded
error NotSupportedMetaPool();

/// Impossible to place pari after Positioning period
error CannotPlacePariOutOfPositioningPeriod();

/// Supported only Positions DOWN=1 or UP=2 or EQUAL=2
error NotSupportedPosition();

/// Only off-Chain
error OnlyOffChainCallesAllowed();

/// Nothing to Withdraw place some Paris
error NothingToWithdraw();

/// Unacceptable wager amount
/// Try to increase wager amount
error UnacceptableWagerAmount();

/// Insufficient funds for Payout Fatal error
/// This contract stops working with provided token
error InsufficientFundsFatal(address token, uint balance, uint payout);

/// Cannot palce pari after positioning period has ended.
error PlacePariAfterPositioning();

/// Cannot update pool after positioning period has ended.
error UpdatePoolAfterPositioning();

/// Cannot open pool after positioning period has ended.
error OpenPoolAfterPositioning();

/// Cannot open pool with price timestamp is valid price to open pool.
/// @param openDate is pool open date timestamp.
/// @param openPrice is price timestamp.
error PoolOpenPriceTimestampTooEarly(
  uint openDate,
  uint openPrice
);

/// Cannot there is valid price to open pool.
/// @param openDate is pool open date timestamp.
/// @param openPrice is price timestamp.
error PoolOpenPriceTimestampTooLate(
  uint openDate,
  uint openPrice
);

/// Cannot settle resolved Pool.
/// Try to settle unresolved Pool.
error CannotSettleResolvedPool();

/// Cannot settle Pool before resolution
/// Try to settle after `resolutionDate`.
/// @param now block timestamp.
/// @param resolutionDate it's possible to resolve pool after this timestamp.
error CannotSettlePoolBeforeResolution(
  uint now,
  uint resolutionDate
);

/// Cannot settle Pool during positioning period.
/// Try to settle after `positioningTill`.
/// @param now block timestamp.
/// @param lockDate it's possible to place pari till this timestamp.
error CannotSettlePoolDuringPositioning(
  uint now,
  uint lockDate
);

/// Cannot resolve Pool with provided price combination.
/// @param resolutionPrice price that pool will be resolved with.
/// @param controlPrice price that resolution will be validated with.
/// @param resolutionDate date after which pool should be resolved.
error InvalidPoolResolution(
  uint80 resolutionPrice,
  uint80 controlPrice,
  uint resolutionDate
);

/// Insufficient pricefund.
/// @param released founds.
/// @param total funds.
error InsufficientPricefund(
  uint released,
  uint total
);

/// ERC20 Pari Pool mismatch combination.
/// @param poolERC20 address.
/// @param pariERC20 address.
error ERC20PariPoolMismatch(
  address poolERC20,
  address pariERC20
);

/// Bettor and Pari owner mismatch.
/// @param pariOwner address.
/// @param bettor address.
error BettorPariMismatch(
  address pariOwner,
  address bettor
);

/// Cannot claime claimed pari.
error CannotClaimeClaimedPari();

/// Cannot claime Pari in unresolved pool.
error CannotClaimePariUnresolvedPool();

/// Cannot claime Pari in unresolved pool.
error CannotResolveAsNoContestPool();

/// Cannot palce Pari on this erc20 token.
/// Try to place pari on other metapool with other ERC20 token.
error CannotPlacePariERC20TokenIsBlocked();

/// Cannot palce Pari on this metapool.
/// Try to place pari on other metapool.
error CannotPlacePariMetapoolIsBlocked();

/// Cannot add Metapool `schedule` too short.
/// Try to increase schedule time
/// @param schedule is a time period between rounds in seconds.
/// @param min is minimum allowed schedule period.
error CannotAddMetapoolScheduleTooShort(
  uint schedule,
  uint min
);

/// Cannot add Metapool `positioning` too short.
/// Try to increase positioning time
/// @param positioning is a time period when pari allowed.
/// @param min is minimum allowed positioning pariod.
error CannotAddMetapoolPositioningTooShort(
  uint positioning,
  uint min
);

/// Cannot add Metapool `positioning` too long.
/// Try to increase positioning time
/// @param positioning is a time period when pari allowed.
/// @param min is minimum allowed positioning pariod.
error CannotAddMetapoolPositioningTooLarge(
  uint positioning,
  uint min
);

/// Cannot add Metapool `minWager` is zero.
/// Try to increase minWager
error CannotAddMetapoolMinWagerZero();

/// Cannot add Metapool `Version` is zero.
/// Try to increase Version
error CannotAddMetapoolVersionZero();

/// Cannot add Metapool because `pricefeed` address is invalid.
/// Try to chage `pricefeed` address
/// @param pricefeed is an address of pricefeed proxy contract for which bettors will predict.
error CannotAddMetapoolWithInvalidFeedAddress(
  address pricefeed
);

/// Cannot add Metapool need positive balance in `erc20` token.
/// Try to add minimum amount fo 1/10**18 of `erc20` token to you balance and try again.
/// @param balance is your current balance of `erc20` tokens.
/// @param erc20 is token what bettors will play for.
error CannotAddMetapoolERC20InsufficientFunds(
  uint balance,
  address erc20
);

/// Cannot add Metapool that already exists.
error CannotAddMetapoolAlreadyExists();

/// Cannot unblock Metapool that doesn't exists.
error CannotUnblockMetapoolDoNotExists();

/// Cannot unblock Metapool that is not blocked.
error CannotUnblockMetapoolIsNotBlocked();

/// Cannot block Metapool that doesn't exists.
error CannotBlockMetapoolDoNotExists();

/// Cannot block Metapool that is already blocked.
error CannotBlockMetapoolIsAlreadyBlocked();

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