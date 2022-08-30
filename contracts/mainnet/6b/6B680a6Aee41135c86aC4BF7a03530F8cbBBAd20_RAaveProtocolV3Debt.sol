// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IATokenV3} from "../../../interfaces/IATokenV3.sol";
import {IAssetResolver} from "../../interfaces/IAssetResolver.sol";
import {AssetResolverBase} from "../../AssetResolverBase.sol";
import {Errors} from "../../../utils/Errors.sol";

/// @title Aave protocol v3 debt resolver
contract RAaveProtocolV3Debt is IAssetResolver, AssetResolverBase {
    /// @notice Calculate asset value
    /// @param asset_ The asset address. Should be a debtToken address.
    /// @param amount_ The amount of asset.
    /// @param quote_ The address of the quote token.
    /// @return The value of asset in quote token.
    /// @dev The value must be negative.
    function calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) external view returns (int256) {
        address underlying = IATokenV3(asset_).UNDERLYING_ASSET_ADDRESS();
        int256 value = -(_calcAssetValue(underlying, amount_, quote_));
        Errors._require(value <= 0, Errors.Code.RESOLVER_ASSET_VALUE_POSITIVE);
        return value;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IATokenV3 {
    // IAToken
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    function mintToTreasury(uint256 amount, uint256 index) external;

    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    function transferUnderlyingTo(address user, uint256 amount) external;

    function handleRepayment(address user, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    // IScaledBalanceToken
    function scaledBalanceOf(address user) external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function scaledTotalSupply() external view returns (uint256);

    // IERC20
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetResolver {
    function calcAssetValue(
        address,
        uint256,
        address
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IAssetRouter} from "./interfaces/IAssetRouter.sol";
import {IAssetOracle} from "./interfaces/IAssetOracle.sol";

/// @title Asset resolver base contract
abstract contract AssetResolverBase {
    using SafeCast for uint256;

    /// @dev Cast asset value is positive.
    /// @return The calculated amount.
    function _castAssetValue(uint256 amount_) internal pure returns (int256) {
        return amount_.toInt256();
    }

    /// @notice Get the asset oracle.
    /// @return The asset oracle address.
    function _getAssetOracle() internal view returns (IAssetOracle) {
        return IAssetRouter(msg.sender).oracle();
    }

    /// @notice Calculate asset value.
    /// @param asset_ The asset address.
    /// @param amount_ The amount of asset.
    /// @param quote_ The address of the quote token.
    function _calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) internal view virtual returns (int256) {
        return IAssetRouter(msg.sender).calcAssetValue(asset_, amount_, quote_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error RevertCode(Code errorCode);

    enum Code {
        COMPTROLLER_HALTED, // 0: "Halted"
        COMPTROLLER_BANNED, // 1: "Banned"
        COMPTROLLER_ZERO_ADDRESS, // 2: "Zero address"
        COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT, // 3: "tos and sigs length are inconsistent"
        COMPTROLLER_BEACON_IS_INITIALIZED, // 4: "Beacon is initialized"
        COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT, // 5: "denominations and dusts length are inconsistent"
        IMPLEMENTATION_ASSET_LIST_NOT_EMPTY, // 6: "assetList is not empty"
        IMPLEMENTATION_INVALID_DENOMINATION, // 7: "Invalid denomination"
        IMPLEMENTATION_INVALID_MORTGAGE_TIER, // 8: "Mortgage tier not set in comptroller"
        IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE, // 9: "pending share is not resolvable"
        IMPLEMENTATION_PENDING_NOT_START, // 10: "Pending does not start"
        IMPLEMENTATION_PENDING_NOT_EXPIRE, // 11: "Pending does not expire"
        IMPLEMENTATION_INVALID_ASSET, // 12: "Invalid asset"
        IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION, // 13: "Insufficient total value for execution"
        FUND_PROXY_FACTORY_INVALID_CREATOR, // 14: "Invalid creator"
        FUND_PROXY_FACTORY_INVALID_DENOMINATION, // 15: "Invalid denomination"
        FUND_PROXY_FACTORY_INVALID_MORTGAGE_TIER, // 16: "Mortgage tier not set in comptroller"
        FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION, // 17: "Invalid denomination"
        FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER, // 18: "Unknown owner"
        FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE, // 19: "Wrong allowance"
        FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO, // 20: "Is not zero value or address "
        FUND_PROXY_STORAGE_UTILS_IS_ZERO, // 21: "Is zero value or address"
        MORTGAGE_VAULT_FUND_MORTGAGED, // 22: "Fund mortgaged"
        SHARE_TOKEN_INVALID_FROM, // 23: "Invalid from"
        SHARE_TOKEN_INVALID_TO, // 24: "Invalid to"
        TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT, // 25: "tos and datas length inconsistent"
        TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT, // 26: "tos and configs length inconsistent"
        TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL, // 27: "Invalid comptroller delegate call"
        TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL, // 28: "Invalid comptroller contract call"
        TASK_EXECUTOR_INVALID_DEALING_ASSET, // 29: "Invalid dealing asset"
        TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK, // 30: "Reference to out of localStack"
        TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED, // 31: "Return num and parsed return num not matched"
        TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE, // 32: "Illegal length for _parse"
        TASK_EXECUTOR_STACK_OVERFLOW, // 33: "Stack overflow"
        TASK_EXECUTOR_INVALID_INITIAL_ASSET, // 34: "Invalid initial asset"
        TASK_EXECUTOR_NON_ZERO_QUOTA, // 35: "Quota is not zero"
        AFURUCOMBO_DUPLICATED_TOKENSOUT, // 36: "Duplicated tokensOut"
        AFURUCOMBO_REMAINING_TOKENS, // 37: "Furucombo has remaining tokens"
        AFURUCOMBO_TOKENS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 38: "Token length != amounts length"
        AFURUCOMBO_INVALID_COMPTROLLER_HANDLER_CALL, // 39: "Invalid comptroller handler call"
        CHAINLINK_ASSETS_AND_AGGREGATORS_INCONSISTENT, // 40: "assets.length == aggregators.length"
        CHAINLINK_ZERO_ADDRESS, // 41: "Zero address"
        CHAINLINK_EXISTING_ASSET, // 42: "Existing asset"
        CHAINLINK_NON_EXISTENT_ASSET, // 43: "Non-existent asset"
        CHAINLINK_INVALID_PRICE, // 44: "Invalid price"
        CHAINLINK_STALE_PRICE, // 45: "Stale price"
        ASSET_REGISTRY_UNREGISTERED, // 46: "Unregistered"
        ASSET_REGISTRY_BANNED_RESOLVER, // 47: "Resolver has been banned"
        ASSET_REGISTRY_ZERO_RESOLVER_ADDRESS, // 48: "Resolver zero address"
        ASSET_REGISTRY_ZERO_ASSET_ADDRESS, // 49: "Asset zero address"
        ASSET_REGISTRY_REGISTERED_RESOLVER, // 50: "Resolver is registered"
        ASSET_REGISTRY_NON_REGISTERED_RESOLVER, // 51: "Asset not registered"
        ASSET_REGISTRY_NON_BANNED_RESOLVER, // 52: "Resolver is not banned"
        ASSET_ROUTER_ASSETS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 53: "assets length != amounts length"
        ASSET_ROUTER_NEGATIVE_VALUE, // 54: "Negative value"
        RESOLVER_ASSET_VALUE_NEGATIVE, // 55: "Resolver's asset value < 0"
        RESOLVER_ASSET_VALUE_POSITIVE, // 56: "Resolver's asset value > 0"
        RCURVE_STABLE_ZERO_ASSET_ADDRESS, // 57: "Zero asset address"
        RCURVE_STABLE_ZERO_POOL_ADDRESS, // 58: "Zero pool address"
        RCURVE_STABLE_ZERO_VALUED_ASSET_ADDRESS, // 59: "Zero valued asset address"
        RCURVE_STABLE_VALUED_ASSET_DECIMAL_NOT_MATCH_VALUED_ASSET, // 60: "Valued asset decimal not match valued asset"
        RCURVE_STABLE_POOL_INFO_IS_NOT_SET, // 61: "Pool info is not set"
        ASSET_MODULE_DIFFERENT_ASSET_REMAINING, // 62: "Different asset remaining"
        ASSET_MODULE_FULL_ASSET_CAPACITY, // 63: "Full Asset Capacity"
        MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE, // 64: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET, // 65: "Can not crystallized yet"
        PERFORMANCE_FEE_MODULE_TIME_BEFORE_START, // 66: "Time before start"
        PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE, // 67: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT, // 68: "Crystallization period too short"
        SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE, // 69: "The requesting share amount is greater than total share amount"
        SHARE_MODULE_PURCHASE_ZERO_BALANCE, // 70: "The purchased balance is zero"
        SHARE_MODULE_PURCHASE_ZERO_SHARE, // 71: "The share purchased need to greater than zero"
        SHARE_MODULE_REDEEM_ZERO_SHARE, // 72: "The redeem share is zero"
        SHARE_MODULE_INSUFFICIENT_SHARE, // 73: "Insufficient share amount"
        SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION, // 74: "Redeem in pending without permission"
        SHARE_MODULE_PENDING_ROUND_INCONSISTENT, // 75: "User pending round and current pending round are inconsistent"
        SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE, // 76: "Pending redemption is not claimable"
        ASSET_REGISTRY_ASSETS_AND_RESOLVERS_LENGTH_INCONSISTENT // 77: "Assets and resolvers are inconsistent"
    }

    function _require(bool condition_, Code errorCode_) internal pure {
        if (!condition_) revert RevertCode(errorCode_);
    }

    function _revertMsg(string memory functionName_, string memory reason_) internal pure {
        revert(string(abi.encodePacked(functionName_, ": ", reason_)));
    }

    function _revertMsg(string memory functionName_) internal pure {
        _revertMsg(functionName_, "Unspecified");
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
pragma solidity ^0.8.0;

import {IAssetRegistry} from "./IAssetRegistry.sol";
import {IAssetOracle} from "./IAssetOracle.sol";

interface IAssetRouter {
    function oracle() external view returns (IAssetOracle);

    function registry() external view returns (IAssetRegistry);

    function setOracle(address oracle_) external;

    function setRegistry(address registry_) external;

    function calcAssetsTotalValue(
        address[] calldata bases_,
        uint256[] calldata amounts_,
        address quote_
    ) external view returns (uint256);

    function calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetOracle {
    function calcConversionAmount(
        address base_,
        uint256 baseAmount_,
        address quote_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetRegistry {
    function bannedResolvers(address) external view returns (bool);

    function register(address asset_, address resolver_) external;

    function unregister(address asset_) external;

    function banResolver(address resolver_) external;

    function unbanResolver(address resolver_) external;

    function resolvers(address asset_) external view returns (address);
}