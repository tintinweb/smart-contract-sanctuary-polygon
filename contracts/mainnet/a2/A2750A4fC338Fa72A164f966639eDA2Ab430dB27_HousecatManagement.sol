// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {Constants} from './Constants.sol';
import {TokenMeta, FeeSettings, MirrorSettings, RebalanceSettings} from './structs.sol';

contract HousecatManagement is Constants, Ownable, Pausable {
  using SafeMath for uint;

  address public treasury;
  address public weth;
  uint public minInitialDepositAmount = 1 ether;
  uint public userSettingsTimeLockSeconds = 60 * 60 * 24;
  mapping(address => bool) private adapters;
  mapping(address => bool) private supportedIntegrations;
  address[] private supportedAssets;
  address[] private supportedLoans;
  mapping(address => TokenMeta) private tokenMeta;

  MirrorSettings private mirrorSettings =
    MirrorSettings({
      minPoolValue: ONE_USD.mul(100),
      minMirroredValue: ONE_USD.mul(100),
      maxWeightDifference: SafeCast.toUint32(PERCENT_100.div(20))
    });

  RebalanceSettings private rebalanceSettings =
    RebalanceSettings({
      reward: SafeCast.toUint32(PERCENT_100.mul(25).div(10000)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      maxSlippage: SafeCast.toUint32(PERCENT_100.div(100)),
      maxCumulativeSlippage: SafeCast.toUint32(PERCENT_100.mul(3).div(100)),
      cumulativeSlippagePeriodSeconds: 60 * 60 * 24 * 7,
      minSecondsBetweenRebalances: 60 * 15,
      rebalancers: new address[](0)
    });

  FeeSettings private managementFee =
    FeeSettings({
      maxFee: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      defaultFee: SafeCast.toUint32(PERCENT_100.div(100)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100))
    });

  FeeSettings private performanceFee =
    FeeSettings({
      maxFee: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      defaultFee: SafeCast.toUint32(PERCENT_100.div(10)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100))
    });

  event UpdateTreasury(address treasury);
  event UpdateWETH(address weth);
  event UpdateMinInitialDeposit(uint minInitialDepositAmount);
  event UpdateUserSettingsTimeLock(uint userSettingsTimeLockSeconds);
  event SetAdapter(address adapter, bool enabled);
  event SetIntegration(address integration, bool enabled);
  event SetSupportedAssets(address[] _tokens);
  event SetSupportedLoans(address[] _tokens);
  event UpdateMirrorSettings(MirrorSettings mirrorSettings);
  event UpdateRebalanceSettings(RebalanceSettings rebalanceSettings);
  event UpdateManagementFee(FeeSettings managementFee);
  event UpdatePerformanceFee(FeeSettings performanceFee);
  event SetTokenMeta(address token, TokenMeta _tokenMeta);

  constructor(address _treasury, address _weth) {
    treasury = _treasury;
    weth = _weth;
  }

  function emergencyPause() external onlyOwner {
    _pause();
  }

  function emergencyUnpause() external onlyOwner {
    _unpause();
  }

  function updateTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit UpdateTreasury(_treasury);
  }

  function updateWETH(address _weth) external onlyOwner {
    weth = _weth;
    emit UpdateWETH(_weth);
  }

  function updateMinInitialDepositAmount(uint _minInitialDepositAmount) external onlyOwner {
    minInitialDepositAmount = _minInitialDepositAmount;
    emit UpdateMinInitialDeposit(_minInitialDepositAmount);
  }

  function updateUserSettingsTimeLock(uint _userSettingsTimeLockSeconds) external onlyOwner {
    userSettingsTimeLockSeconds = _userSettingsTimeLockSeconds;
    emit UpdateUserSettingsTimeLock(_userSettingsTimeLockSeconds);
  }

  function isAdapter(address _adapter) external view returns (bool) {
    return adapters[_adapter];
  }

  function setAdapter(address _adapter, bool _enabled) external onlyOwner {
    adapters[_adapter] = _enabled;
    emit SetAdapter(_adapter, _enabled);
  }

  function getSupportedAssets() external view returns (address[] memory) {
    return supportedAssets;
  }

  function getSupportedLoans() external view returns (address[] memory) {
    return supportedLoans;
  }

  function getTokenMeta(address _token) external view returns (TokenMeta memory) {
    return tokenMeta[_token];
  }

  function getAssetsWithMeta() external view returns (address[] memory, TokenMeta[] memory) {
    TokenMeta[] memory meta = new TokenMeta[](supportedAssets.length);
    for (uint i = 0; i < supportedAssets.length; i++) {
      meta[i] = tokenMeta[supportedAssets[i]];
    }
    return (supportedAssets, meta);
  }

  function getLoansWithMeta() external view returns (address[] memory, TokenMeta[] memory) {
    TokenMeta[] memory meta = new TokenMeta[](supportedLoans.length);
    for (uint i = 0; i < supportedLoans.length; i++) {
      meta[i] = tokenMeta[supportedLoans[i]];
    }
    return (supportedLoans, meta);
  }

  function isIntegrationSupported(address _integration) external view returns (bool) {
    return supportedIntegrations[_integration];
  }

  function isAssetSupported(address _token, bool _excludeDelisted) external view returns (bool) {
    return _isTokenSupported(_token, supportedAssets, _excludeDelisted);
  }

  function isLoanSupported(address _token, bool _excludeDelisted) external view returns (bool) {
    return _isTokenSupported(_token, supportedLoans, _excludeDelisted);
  }

  function getMirrorSettings() external view returns (MirrorSettings memory) {
    return mirrorSettings;
  }

  function getRebalanceSettings() external view returns (RebalanceSettings memory) {
    return rebalanceSettings;
  }

  function isRebalancer(address _account) external view returns (bool) {
    RebalanceSettings memory settings = rebalanceSettings;
    for (uint i = 0; i < settings.rebalancers.length; i++) {
      if (_account == settings.rebalancers[i]) {
        return true;
      }
    }
    return false;
  }

  function getManagementFee() external view returns (FeeSettings memory) {
    return managementFee;
  }

  function getPerformanceFee() external view returns (FeeSettings memory) {
    return performanceFee;
  }

  function setSupportedAssets(address[] memory _tokens) external onlyOwner {
    supportedAssets = _tokens;
    emit SetSupportedAssets(_tokens);
  }

  function setSupportedLoans(address[] memory _tokens) external onlyOwner {
    supportedLoans = _tokens;
    emit SetSupportedLoans(_tokens);
  }

  function setTokenMeta(address _token, TokenMeta memory _tokenMeta) external onlyOwner {
    _setTokenMeta(_token, _tokenMeta);
  }

  function setTokenMetaMany(address[] memory _tokens, TokenMeta[] memory _tokensMeta) external onlyOwner {
    require(_tokens.length == _tokensMeta.length, 'HousecatManagement: array size mismatch');
    for (uint i = 0; i < _tokens.length; i++) {
      _setTokenMeta(_tokens[i], _tokensMeta[i]);
    }
  }

  function setSupportedIntegration(address _integration, bool _value) external onlyOwner {
    supportedIntegrations[_integration] = _value;
    emit SetIntegration(_integration, _value);
  }

  function updateMirrorSettings(MirrorSettings memory _mirrorSettings) external onlyOwner {
    _validateMirrorSettings(_mirrorSettings);
    mirrorSettings = _mirrorSettings;
    emit UpdateMirrorSettings(_mirrorSettings);
  }

  function updateRebalanceSettings(RebalanceSettings memory _rebalanceSettings) external onlyOwner {
    _validateRebalanceSettings(_rebalanceSettings);
    rebalanceSettings = _rebalanceSettings;
    emit UpdateRebalanceSettings(_rebalanceSettings);
  }

  function updateManagementFee(FeeSettings memory _managementFee) external onlyOwner {
    _validateFeeSettings(_managementFee);
    managementFee = _managementFee;
    emit UpdateManagementFee(_managementFee);
  }

  function updatePerformanceFee(FeeSettings memory _performanceFee) external onlyOwner {
    _validateFeeSettings(_performanceFee);
    performanceFee = _performanceFee;
    emit UpdatePerformanceFee(_performanceFee);
  }

  function _isTokenSupported(
    address _token,
    address[] memory _supportedTokens,
    bool _excludeDelisted
  ) private view returns (bool) {
    for (uint i = 0; i < _supportedTokens.length; i++) {
      if (_supportedTokens[i] == _token) {
        if (_excludeDelisted && tokenMeta[_token].delisted) {
          return false;
        }
        return true;
      }
    }
    return false;
  }

  function _setTokenMeta(address _token, TokenMeta memory _tokenMeta) private {
    require(_token != address(0), 'HousecatManagement: zero address');
    tokenMeta[_token] = _tokenMeta;
    emit SetTokenMeta(_token, _tokenMeta);
  }

  function _validateMirrorSettings(MirrorSettings memory _settings) private pure {
    require(_settings.maxWeightDifference <= PERCENT_100, 'maxWeightDifference > 100%');
  }

  function _validateRebalanceSettings(RebalanceSettings memory _settings) private pure {
    require(_settings.maxSlippage <= PERCENT_100.div(2), 'maxSlippage > 50%');
    require(_settings.reward <= PERCENT_100.mul(50).div(10000), 'reward > 0.50%');
    require(_settings.protocolTax <= PERCENT_100, 'protocolTax > 100%');
  }

  function _validateFeeSettings(FeeSettings memory _settings) private pure {
    require(_settings.maxFee <= PERCENT_100, 'maxFee too large');
    require(_settings.defaultFee <= _settings.maxFee, 'defaultFee > maxFee');
    require(_settings.protocolTax <= PERCENT_100.div(2), 'protocolTax > 50%');
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

contract Constants {
  uint internal constant PERCENT_100 = 1e8;
  uint internal constant PRICE_DECIMALS = 18;
  uint internal constant ONE_USD = 10**PRICE_DECIMALS;

  function getPercent100() external pure returns (uint) {
    return PERCENT_100;
  }

  function getPriceDecimals() external pure returns (uint) {
    return PRICE_DECIMALS;
  }

  function getOneUSD() external pure returns (uint) {
    return ONE_USD;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

struct FeeSettings {
  uint32 maxFee;
  uint32 defaultFee;
  uint32 protocolTax;
}

struct PoolTransaction {
  address adapter;
  bytes data;
}

struct MirrorSettings {
  uint minPoolValue;
  uint minMirroredValue;
  uint32 maxWeightDifference;
}

struct RebalanceSettings {
  uint32 reward;
  uint32 protocolTax;
  uint32 maxSlippage;
  uint32 maxCumulativeSlippage;
  uint32 cumulativeSlippagePeriodSeconds;
  uint32 minSecondsBetweenRebalances;
  address[] rebalancers;
}

struct TokenData {
  address[] tokens;
  uint[] decimals;
  uint[] prices;
  bool[] delisted;
}

struct TokenMeta {
  address priceFeed;
  uint8 decimals;
  bool delisted;
}

struct UserSettings {
  uint createdAt;
  uint32 managementFee;
  uint32 performanceFee;
}

struct WalletContent {
  uint[] assetBalances;
  uint[] loanBalances;
  uint[] assetWeights;
  uint[] loanWeights;
  uint assetValue;
  uint loanValue;
  uint totalValue;
  uint netValue;
}

struct PoolState {
  uint ethBalance;
  uint totalValue;
  uint netValue;
  uint weightDifference;
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