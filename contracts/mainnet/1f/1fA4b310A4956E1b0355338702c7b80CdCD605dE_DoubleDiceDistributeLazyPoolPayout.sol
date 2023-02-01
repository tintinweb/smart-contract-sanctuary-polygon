// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IDoubleDiceLazyPoolLocking.sol";
import "./library/FixedPointTypes.sol";

contract DoubleDiceDistributeLazyPoolPayout is Ownable, ReentrancyGuard {

  using FixedPointTypes for UFixed256x18;
  using SafeERC20 for IERC20;

  IDoubleDiceLazyPoolLocking immutable public doubleDiceLazyPoolLocking;
  IERC20 immutable public distributableToken;

  struct Config {
    uint256 firstQuarterDay;
    uint256 lastQuarterDay;
    uint256 earliestStakingTime;
    uint256 latestStakingTime;
    uint256 maxLockDurationInDays;
    uint256 tokenPerValue;
    uint256 dateWeight;
    uint256 lengthWeight;
  }
  mapping(uint256 => Config) public config;
  mapping(address => mapping(uint256 => uint256)) public userAmountClaimed;

  uint256 public currentConfigNumber = 0;
  uint32 public constant ONE_DAY = 1 days;

  error TransferFailed();
  error ZeroAddress();

  constructor(address _distributableToken, address lazyPoolAddress) {

    if (_distributableToken == address(0)) revert ZeroAddress();
    if (lazyPoolAddress == address(0)) revert ZeroAddress();

    distributableToken = IERC20(_distributableToken);
    doubleDiceLazyPoolLocking = IDoubleDiceLazyPoolLocking(lazyPoolAddress);
  }

  error NoClaimableAmount();

  event Claim(
    address indexed sender,
    uint256 amount 
  );

  function claimPayout() external nonReentrant {
    uint256 totalPayoutAmount = 0;
    IDoubleDiceLazyPoolLocking.UserLock memory lockInfo = doubleDiceLazyPoolLocking.getUserLockInfo(_msgSender());

    uint256 startTime = lockInfo.startTime;
    uint256 expiryTime = lockInfo.expiryTime;
    uint256 amount = lockInfo.amount;

    for (uint256 i = 0; i < currentConfigNumber; i++) {
      Config memory _config = config[i];

      if (
        (startTime >= _config.earliestStakingTime && startTime <= _config.latestStakingTime) &&
        userAmountClaimed[msg.sender][i] == 0
      ) {
        uint256 payoutAmount = weightedToken(startTime, expiryTime, amount, i).mul0(_config.tokenPerValue).floorToUint256() / 1e18;

        userAmountClaimed[msg.sender][i] = payoutAmount;
        totalPayoutAmount += payoutAmount;
      } 
    }

    if (totalPayoutAmount == 0) revert NoClaimableAmount();

    bool isSent = distributableToken.transfer(_msgSender(), totalPayoutAmount);

    if (!isSent) revert TransferFailed();

    emit Claim(_msgSender(), totalPayoutAmount);
  }

  event SetPayoutConfiguration(Config newConfig);

  function setPayoutConfiguration(Config memory newConfig) external onlyOwner {
    config[currentConfigNumber] = Config({
      firstQuarterDay: newConfig.firstQuarterDay,
      lastQuarterDay: newConfig.lastQuarterDay,
      earliestStakingTime: newConfig.earliestStakingTime,
      latestStakingTime: newConfig.latestStakingTime,
      maxLockDurationInDays: newConfig.maxLockDurationInDays,
      tokenPerValue: newConfig.tokenPerValue,
      dateWeight: newConfig.dateWeight,
      lengthWeight: newConfig.lengthWeight
    });

    emit SetPayoutConfiguration(config[currentConfigNumber]);

    currentConfigNumber++;

  }

  event WithdrawToken(
    address indexed receiver,
    address indexed tokenAddress,
    uint256 amount
  );

  error ZeroBalance();

  function withdrawToken(address tokenAddress, address receiver) external onlyOwner nonReentrant{
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

    if (balance > 0) {
      bool isSent = IERC20(tokenAddress).transfer(receiver, balance);
      if (!isSent) revert TransferFailed();
    }
    else revert ZeroBalance();

    emit WithdrawToken(receiver, tokenAddress, balance);
  }

  function getPayoutAmount(address userAddress) external view returns (uint256 payoutAmount) {
    payoutAmount = 0;
    IDoubleDiceLazyPoolLocking.UserLock memory lockInfo = doubleDiceLazyPoolLocking.getUserLockInfo(userAddress);

    uint256 startTime = lockInfo.startTime;
    uint256 expiryTime = lockInfo.expiryTime;
    uint256 amount = lockInfo.amount;

    for (uint256 i = 0; i < currentConfigNumber; i++) {
      Config memory _config = config[i];
      if (
        (startTime >= _config.earliestStakingTime && startTime <= _config.latestStakingTime) &&
        userAmountClaimed[msg.sender][i] == 0
      ) {
        payoutAmount += weightedToken(startTime, expiryTime, amount, i).mul0(_config.tokenPerValue).floorToUint256() / 1e18;
      } 
    }
  }

  function getConfigurationByNumber(uint256 configNumber) external view returns (Config memory) {
    return config[configNumber];
  }

  function getUserAmountClaimed(address user, uint256 configNumber) external view returns (uint256) {
    return userAmountClaimed[user][configNumber];
  }

  function distanceFromEarliestStaking(uint256 startTime, uint256 configNumber) internal view returns (uint256) {
    return (startTime - config[configNumber].earliestStakingTime) / ONE_DAY;
  }

  function dateCoefficient(uint256 startTime, uint256 configNumber) internal view returns (UFixed256x18) {
    uint256 distanceFromEarliestStake = distanceFromEarliestStaking(startTime, configNumber);
    uint256 daysBetweenEarliestAndLatestStake = (config[configNumber].latestStakingTime - config[configNumber].earliestStakingTime) / ONE_DAY;

    UFixed256x18 earliestTimeDiff = FixedPointTypes.toUFixed256x18(distanceFromEarliestStake).div0(daysBetweenEarliestAndLatestStake);

    return UFIXED256X18_ONE.sub(earliestTimeDiff);
  }

  function lengthOfLock(uint256 startTime, uint256 expiryTime) internal pure returns (uint256) {
    return (expiryTime - startTime) / ONE_DAY;
  }

  function lengthCoefficient(uint256 startTime, uint256 expiryTime, uint256 configNumber) internal view returns (UFixed256x18) {
    return FixedPointTypes.toUFixed256x18(lengthOfLock(startTime, expiryTime)).div0(config[configNumber].maxLockDurationInDays);
  }

  function lockDaysWithinQuarter(uint256 startTime, uint256 configNumber) internal view returns (uint256) {
    Config memory _config = config[configNumber];
    uint256 _firstQuarterDay = 0;
    if (startTime < _config.firstQuarterDay) {
      _firstQuarterDay = _config.firstQuarterDay;
    } else {
      _firstQuarterDay = startTime;
    }
    return (_config.lastQuarterDay - _firstQuarterDay) / ONE_DAY;
  }

  function quarterlyCoverage(uint256 startTime, uint256 configNumber) internal view returns (UFixed256x18) {
    Config memory _config = config[configNumber];
    uint256 daysWithinFirstAndLastQuater = (_config.lastQuarterDay - _config.firstQuarterDay) / ONE_DAY;
    return FixedPointTypes.toUFixed256x18(lockDaysWithinQuarter(startTime, configNumber)).div0(daysWithinFirstAndLastQuater);
  }

  function overallWeight(uint256 startTime, uint256 expiryTime, uint256 configNumber) internal view returns (UFixed256x18) {
    Config memory _config = config[configNumber];

    UFixed256x18 firstSummation = dateCoefficient(startTime, configNumber).mul0(_config.dateWeight).div0(1e18);
    UFixed256x18 secondSummation = lengthCoefficient(startTime, expiryTime, configNumber).mul0(_config.lengthWeight).div0(1e18);

    UFixed256x18 summation = firstSummation.add(secondSummation);
    return summation.add(quarterlyCoverage(startTime, configNumber));
  }

  function weightedToken(uint256 startTime, uint256 expiryTime, uint256 amountStaked, uint256 configNumber) internal view returns (UFixed256x18) {
    return overallWeight(startTime, expiryTime, configNumber).mul0(amountStaked).div0(1e18);
  }
    
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IDoubleDiceLazyPoolLocking {

    struct UserLock {
        uint256 amount;
        uint256 startTime;
        uint256 expiryTime;
        bool    hasLock;
        bool    claimed;
    }

    function getUserLockInfo(address user) external view returns(UserLock memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";


/**
 * @dev Holds range [0.000000, 4294.967295]
 * https://doubledice.slack.com/archives/C02LH8C2BS6/p1653930424588689?thread_ts=1653926936.620019&cid=C02LH8C2BS6
 */
type UFixed32x6 is uint32;

/**
 * @dev Holds range [0.0000, 6.5535]
 */
type UFixed16x4 is uint16;

/**
 * @dev Holds range
 * [000000000000000000000000000000000000000000000000000000000000.000000000000000000,
 * 115792089237316195423570985008687907853269984665640564039457.584007913129639935]
 */
type UFixed256x18 is uint256;


/**
 * @dev The value 1.000000000000000000
 */
UFixed256x18 constant UFIXED256X18_ONE = UFixed256x18.wrap(1e18);


/**
 * @dev The value 0.000000000000000000
 */
UFixed256x18 constant UFIXED256X18_ZERO = UFixed256x18.wrap(0);


/**
 * @dev The value 1.000000
 */
UFixed32x6 constant UFIXED32X6_ONE = UFixed32x6.wrap(1e6);


/**
 * @title Generic fixed-point type arithmetic and safe-casting functions
 * @author 🎲🎲 <[email protected]>
 * @dev The primary fixed-point type in this library is UFixed256x18,
 * but some conversions to/from UFixed32x6 and UFixed16x4 are also provided,
 * as these are used in the main contract.
 */
library FixedPointTypes {

    using SafeCast for uint256;
    using FixedPointTypes for UFixed16x4;
    using FixedPointTypes for UFixed32x6;
    using FixedPointTypes for UFixed256x18;

    function add(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
    }

    function sub(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) - UFixed256x18.unwrap(b));
    }

    /**
     * @dev e.g. 1.230000_000000_000000 * 3 = 3.690000_000000_000000
     * Named `mul0` because unlike `add` and `sub`, `b` is `UFixed256x0`, not `UFixed256x18`
     */
    function mul0(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) * b);
    }

    function div0(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) / b);
    }

    /**
     * @dev More efficient implementation of (hypothetical) `value.div(b).toUint256()`
     * e.g. 200.000000_000000_000000 / 3.000000_000000_000000 = 33
     */
    function divToUint256(UFixed256x18 a, UFixed256x18 b) internal pure returns (uint256) {
        return UFixed256x18.unwrap(a) / UFixed256x18.unwrap(b);
    }

    /**
     * @dev More efficient implementation of (hypothetical) `value.floor().toUint256()`
     * e.g. 987.654321_000000_000000 => 987
     */
    function floorToUint256(UFixed256x18 value) internal pure returns (uint256) {
        return UFixed256x18.unwrap(value) / 1e18;
    }

    function eq(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) == UFixed256x18.unwrap(b);
    }

    function gte(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) >= UFixed256x18.unwrap(b);
    }

    function lte(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) <= UFixed256x18.unwrap(b);
    }


     /**
      * @notice Cannot convert UFixed256x18 `value` to UFixed16x4 without losing precision
      */
    error UFixed16x4LossOfPrecision(UFixed256x18 value);

    /**
     * @notice e.g. 1.234500_000000_000000 => 1.2345
     * Reverts if input is too large to fit in output-type,
     * or if conversion would lose precision, e.g. 1.234560_000000_000000 will revert.
     */
    function toUFixed16x4(UFixed256x18 value) internal pure returns (UFixed16x4 converted) {
        converted = UFixed16x4.wrap((UFixed256x18.unwrap(value) / 1e14).toUint16());
        if (!(converted.toUFixed256x18().eq(value))) revert UFixed16x4LossOfPrecision(value);
    }


    /**
     * @notice Cannot convert UFixed256x18 `value` to UFixed32x6 without losing precision
     */
    error UFixed32x6LossOfPrecision(UFixed256x18 value);

    /**
     * @notice e.g. 123.456789_000000_000000 => 123.456789
     * Reverts if input is too large to fit in output-type,
     * or if conversion would lose precision, e.g. 123.456789_100000_000000 will revert.
     */
    function toUFixed32x6(UFixed256x18 value) internal pure returns (UFixed32x6 converted) {
        converted = UFixed32x6.wrap((UFixed256x18.unwrap(value) / 1e12).toUint32());
        if (!(converted.toUFixed256x18().eq(value))) revert UFixed32x6LossOfPrecision(value);
    }

    function toUFixed32x6Lossy(UFixed256x18 value) internal pure returns (UFixed32x6 converted) {
        converted = UFixed32x6.wrap((UFixed256x18.unwrap(value) / 1e12).toUint32());
    }

    /**
     * @notice e.g. 123 => 123.000000_000000_000000
     * Reverts if input is too large to fit in output-type.
     */
    function toUFixed256x18(uint256 value) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(value * 1e18);
    }

    /**
     * @notice e.g. 1.2345 => 1.234500_000000_000000
     * Input always fits in output-type.
     */
    function toUFixed256x18(UFixed16x4 value) internal pure returns (UFixed256x18 converted) {
        unchecked { // because type(uint16).max * 1e14 <= type(uint256).max
            return UFixed256x18.wrap(uint256(UFixed16x4.unwrap(value)) * 1e14);
        }
    }

    /**
     * @notice e.g. 123.456789 => 123.456789_000000_000000
     * Input always fits in output-type.
     */
    function toUFixed256x18(UFixed32x6 value) internal pure returns (UFixed256x18 converted) {
        unchecked { // because type(uint32).max * 1e12 <= type(uint256).max
            return UFixed256x18.wrap(uint256(UFixed32x6.unwrap(value)) * 1e12);
        }
    }

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}