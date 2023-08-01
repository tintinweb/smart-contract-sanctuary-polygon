//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IPeriodic
 * @notice An interface that defines a contract containing a period.
 * @dev This typically refers to an update period.
 */
interface IPeriodic {
    /// @notice Gets the period, in seconds.
    /// @return periodSeconds The period, in seconds.
    function period() external view returns (uint256 periodSeconds);

    // @notice Gets the number of observations made every period.
    // @return granularity The number of observations made every period.
    function granularity() external view returns (uint256 granularity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IUpdateByToken
/// @notice An interface that defines a contract that is updateable as per the input data.
abstract contract IUpdateable {
    /// @notice Performs an update as per the input data.
    /// @param data Any data needed for the update.
    /// @return b True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual returns (bool b);

    /// @notice Checks if an update needs to be performed.
    /// @param data Any data relating to the update.
    /// @return b True if an update needs to be performed; false otherwise.
    function needsUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Check if an update can be performed by the caller (if needed).
    /// @dev Tries to determine if the caller can call update with a valid observation being stored.
    /// @dev This is not meant to be called by state-modifying functions.
    /// @param data Any data relating to the update.
    /// @return b True if an update can be performed by the caller; false otherwise.
    function canUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Gets the timestamp of the last update.
    /// @param data Any data relating to the update.
    /// @return A unix timestamp.
    function lastUpdateTime(bytes memory data) public view virtual returns (uint256);

    /// @notice Gets the amount of time (in seconds) since the last update.
    /// @param data Any data relating to the update.
    /// @return Time in seconds.
    function timeSinceLastUpdate(bytes memory data) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./MutatedValueComputer.sol";

/**
 * @title Erc20MutationComputer
 * @notice Abstract contract for computing mutated values from tokens, with decimal trimming and scaling.
 * @dev Extend this contract and implement the extractValueFromToken function to use it.
 */
abstract contract Erc20MutationComputer is MutatedValueComputer {
    /// @notice Default number of decimals for the tokens.
    uint8 public immutable defaultDecimals;

    /// @notice The offset to apply when scaling the value from the token.
    int8 public immutable decimalsOffset;

    /// @notice An error thrown when the token address is invalid.
    /// @param token The invalid token address.
    error InvalidInput(address token);

    /**
     * @notice Constructs a new CTokenMutationComputer instance.
     * @param defaultOneXScalar_ The default scalar value to represent 1x. Recommended value: 1,000,000.
     * @param defaultDecimals_ The default number of decimals for the tokens.
     * @param decimalsOffset_ The offset to apply when scaling the value from the token.
     */
    constructor(
        uint32 defaultOneXScalar_,
        uint8 defaultDecimals_,
        int8 decimalsOffset_
    ) MutatedValueComputer(defaultOneXScalar_) {
        defaultDecimals = defaultDecimals_;
        decimalsOffset = decimalsOffset_;
    }

    /**
     * @notice Returns the mutated value for the given token address.
     * @dev This function calls the abstract function extractValueFromToken to obtain the uint256 value from the token.
     * @param token The address of the token to compute the mutated value for.
     * @return The mutated value.
     */
    function getValue(address token) internal view virtual override returns (uint256) {
        if (token == address(0)) revert InvalidInput(token);

        uint256 value = extractValueFromToken(token);

        // Scale value by decimalsOffset
        if (decimalsOffset >= 0) {
            value = value * (10 ** uint256(int256(decimalsOffset)));
        } else {
            value = value / (10 ** uint256(int256(-decimalsOffset)));
        }

        // Scale value by token decimals
        value = scaleValueByTokenDecimals(token, value);

        return value;
    }

    /**
     * @notice Returns the number of decimals for the token or the default value if decimals cannot be retrieved.
     * @param token The token address whose decimals should be fetched.
     * @return The number of decimals for the token or the default value if decimals cannot be retrieved.
     */
    function getTokenDecimalsOrDefault(address token) internal view virtual returns (uint8) {
        uint8 decimals = defaultDecimals;

        (bool success, bytes memory result) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && result.length == 32) {
            decimals = abi.decode(result, (uint8));
        }

        return decimals;
    }

    /**
     * @notice Scales the value by the token decimals.
     * @param token The token address.
     * @param value The value to be scaled.
     * @return The scaled value.
     */
    function scaleValueByTokenDecimals(address token, uint256 value) internal view virtual returns (uint256) {
        uint8 decimals = getTokenDecimalsOrDefault(token);

        uint256 wholeUnitsValue = value / (10 ** decimals);

        return wholeUnitsValue;
    }

    /**
     * @notice Abstract function to extract a uint256 value from the token.
     * @dev Extend this contract and implement this function to extract the desired value (e.g., totalSupply,
     *   totalBorrows, etc.) from the token. This function will be called by the getValue function.
     * @param token The token to extract the value from.
     * @return The extracted value.
     */
    function extractValueFromToken(address token) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/interfaces/IPeriodic.sol";
import "@adrastia-oracle/adrastia-core/contracts/interfaces/IUpdateable.sol";

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "../IRateComputer.sol";

/**
 * @title MutatedValueComputer
 * @notice Abstract contract for computing mutated values.
 * @dev Extend this contract and implement the getValue function to use it.
 */
abstract contract MutatedValueComputer is IERC165, IRateComputer {
    using SafeCast for uint256;

    struct Config {
        uint64 max;
        uint64 min;
        int64 offset;
        uint32 scalar;
    }

    /// @notice The default scalar value to represent 1x.
    uint32 public immutable defaultOneXScalar; // Suggested default value: 1,000,000

    /// @notice A mapping of token addresses to their Config structs.
    mapping(address => Config) internal configs;

    /// @notice Emitted when a token's configuration is updated.
    /// @param token The address of the token.
    /// @param oldConfig The old configuration.
    /// @param newConfig The new configuration.
    event ConfigUpdated(address indexed token, Config oldConfig, Config newConfig);

    /**
     * @notice Constructs a new MutatedValueComputer instance.
     * @param defaultOneXScalar_ The default scalar value to represent 1x.
     */
    constructor(uint32 defaultOneXScalar_) {
        defaultOneXScalar = defaultOneXScalar_;
    }

    /**
     * @notice Returns the configuration for a token.
     * @param token The token address.
     * @return The token's configuration.
     */
    function getConfig(address token) external view virtual returns (Config memory) {
        return configs[token];
    }

    /**
     * @notice Sets the configuration for a specific token.
     * @dev Override `checkSetConfig` to control the access to this function.
     * @param token The token address.
     * @param max The maximum value for the token's rate.
     * @param min The minimum value for the token's rate.
     * @param offset The offset to apply to the computed value.
     * @param scalar The scalar value to apply to the computed value.
     */
    function setConfig(address token, uint64 max, uint64 min, int64 offset, uint32 scalar) external virtual {
        checkSetConfig();

        Config memory oldConfig = configs[token];
        configs[token] = Config({max: max, min: min, offset: offset, scalar: scalar});
        emit ConfigUpdated(token, oldConfig, configs[token]);
    }

    /// @inheritdoc IRateComputer
    function computeRate(address token) external view virtual override returns (uint64) {
        uint256 value = getValue(token);

        Config memory config = configs[token];

        // Apply the configured parameters
        uint256 scaledValue = (value * config.scalar) / defaultOneXScalar;

        // Check that scaledValue is within the range of int256
        if (scaledValue > uint256(type(int256).max)) {
            scaledValue = uint256(type(int256).max);
        }

        int256 adjustedValue = int256(scaledValue) + config.offset;

        // Ensure adjustedValue is not negative
        adjustedValue = adjustedValue < int256(0) ? int256(0) : adjustedValue;

        // Clamp the adjusted total supply between the configured min and max values
        uint64 clampedValue = (adjustedValue > int256(uint256(config.max)))
            ? config.max
            : uint64(uint256(adjustedValue));
        clampedValue = (clampedValue < config.min) ? config.min : clampedValue;

        return clampedValue;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRateComputer).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Returns the mutated value for a given token.
     * @dev This is an internal virtual function that must be implemented by the derived contract to provide the
     *   specific logic for extracting the mutated value for the token.
     * @param token The token address for which the mutated value should be computed.
     * @return The mutated value for the given token.
     */
    function getValue(address token) internal view virtual returns (uint256);

    /// @notice Checks if the caller is authorized to set the configuration.
    /// @dev This function should contain the access control logic for the setConfig function.
    function checkSetConfig() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../../Erc20MutationComputer.sol";
import "../../../../vendor/aave/IACLManager.sol";
import "../../../../vendor/aave/IAaveV3LendingPool.sol";

/**
 * @title AaveV3SupplyMutationComputer
 * @notice An Erc20MutationComputer implementation that computes mutated values using the total supply of tokens in the
 *   Aave V3 Lending Pool.
 */
contract AaveV3SupplyMutationComputer is Erc20MutationComputer {
    /// @notice The Aave ACL Manager instance.
    IACLManager public immutable aclManager;

    /// @notice The Aave Lending Pool instance.
    IAaveV3LendingPool public immutable lendingPool;

    /// @notice An error that is thrown if the account is not authorized for the required role.
    /// @param account The account that is not authorized.
    /// @param requiredRole The required role (hash) that the account is missing.
    error NotAuthorized(address account, bytes32 requiredRole);

    /**
     * @notice Constructs a new AaveV3SupplyMutationComputer instance.
     * @param defaultOneXScalar_ The default scalar value to represent 1x. Recommended value: 1,000,000.
     * @param defaultDecimals_ The default number of decimals for the underlying tokens. Recommended value: 18.
     * @param decimalsOffset_ The offset to apply when scaling the value from the aToken.
     * @param lendingPool_ The address of the Aave Lending Pool.
     */
    constructor(
        IACLManager aclManager_,
        IAaveV3LendingPool lendingPool_,
        uint32 defaultOneXScalar_,
        uint8 defaultDecimals_,
        int8 decimalsOffset_
    ) Erc20MutationComputer(defaultOneXScalar_, defaultDecimals_, decimalsOffset_) {
        aclManager = aclManager_;
        lendingPool = lendingPool_;
    }

    /**
     * @notice Extracts the total supply of the token in the Aave V3 Lending Pool.
     * @param token The token to extract the total supply for (the underlying token).
     * @return The extracted total supply, with all decimal points of the token included.
     */
    function extractValueFromToken(address token) internal view virtual override returns (uint256) {
        IAaveV3LendingPool.ReserveData memory reserve = lendingPool.getReserveData(token);

        return IERC20(reserve.aTokenAddress).totalSupply();
    }

    /**
     * @notice Checks if the sender has the required role to set the config, namely, the POOL_ADMIN role.
     */
    function checkSetConfig() internal view virtual override {
        if (!aclManager.isPoolAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.POOL_ADMIN_ROLE());
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IRateComputer
 * @notice An interface that defines a contract that computes rates.
 */
interface IRateComputer {
    /// @notice Computes the rate for a token.
    /// @param token The address of the token to compute the rate for.
    /// @return rate The rate for the token.
    function computeRate(address token) external view returns (uint64);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAaveV3LendingPool {
    struct ReserveData {
        //stores the reserve configuration
        uint256 configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (address);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the Bridge role
     * @return The id of the Bridge role
     */
    function BRIDGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an address as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new address as Bridge
     * @param bridge The address of the new Bridge
     */
    function addBridge(address bridge) external;

    /**
     * @notice Removes an address as Bridge
     * @param bridge The address of the bridge to remove
     */
    function removeBridge(address bridge) external;

    /**
     * @notice Returns true if the address is Bridge, false otherwise
     * @param bridge The address to check
     * @return True if the given address is Bridge, false otherwise
     */
    function isBridge(address bridge) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}