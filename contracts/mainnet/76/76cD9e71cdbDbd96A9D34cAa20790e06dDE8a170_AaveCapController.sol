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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./AaveRateController.sol";
import "../../../../vendor/aave/IAaveV3ConfigEngine.sol";
import {EngineFlags} from "../../../../vendor/aave/AaveV3EngineFlags.sol";

/**
 * @title AaveCapController
 * @notice A smart contract that extends AaveRateController to implement functionality specific to Aave v3's supply and
 *   borrow cap management.
 * @dev This contract overrides `willAnythingChange` to only check if the next rate changes by more than the configured
 *   threshold. This changes the behavior of the rate queue where old rates do not necessarily relate to the period.
 *   i.e. If the period is a day, the rate at index 1 is not necessarily the rate from the previous day.
 */
contract AaveCapController is AaveRateController {
    uint256 public constant CHANGE_PRECISION = 10 ** 8;

    /// @notice The Aave Config Engine instance.
    IAaveV3ConfigEngine public immutable configEngine;

    /// @notice True if this controller updates supply caps, false if it updates borrow caps.
    bool public immutable forSupplyCaps;

    /**
     * @notice Constructs the AaveCapController contract.
     * @param configEngine_ The Aave Config Engine instance.
     * @param forSupplyCaps_ True if this controller updates supply caps, false if it updates borrow caps.
     * @param aclManager_ The Aave ACL Manager instance.
     * @param period_ The period of the rate controller.
     * @param initialBufferCardinality_ The initial cardinality of the rate buffers.
     * @param updatersMustBeEoa_ Whether or not the updaters must be EOA.
     */
    constructor(
        IAaveV3ConfigEngine configEngine_,
        bool forSupplyCaps_,
        IACLManager aclManager_,
        uint32 period_,
        uint8 initialBufferCardinality_,
        bool updatersMustBeEoa_
    ) AaveRateController(aclManager_, period_, initialBufferCardinality_, updatersMustBeEoa_) {
        configEngine = configEngine_;
        forSupplyCaps = forSupplyCaps_;
    }

    /**
     * @notice Sets the change threshold for the specified token. When the rate changes by more than the threshold, an
     *   update is triggered, assuming the period has been surpassed.
     * @param token The token to set the change threshold for.
     * @param changeThreshold Percent change that allows an update to make place, respresented as the numerator of a
     *   fraction with a denominator of `CHANGE_PRECISION`. Ex: With `CHANGE_PRECISION` of 1e8, a change threshold of
     *   2% would be represented as 2e6 (2000000).
     */
    function setChangeThreshold(address token, uint32 changeThreshold) external virtual {
        checkSetChangeThreshold();

        rateBufferMetadata[token].changeThreshold = changeThreshold;
    }

    /**
     * @notice Gets the change threshold for the specified token.
     * @param token The token to get the change threshold for.
     * @return uint32 Percent change that allows an update to make place, respresented as the numerator of a
     *   fraction with a denominator of `CHANGE_PRECISION`. Ex: With `CHANGE_PRECISION` of 1e8, a change threshold of
     *   2% would be represented as 2e6 (2000000).
     */
    function getChangeThreshold(address token) external view virtual returns (uint32) {
        return rateBufferMetadata[token].changeThreshold;
    }

    /// @notice Checks if the sender has the required role to set the change threshold, namely, the POOL_ADMIN role.
    function checkSetChangeThreshold() internal view virtual {
        if (!aclManager.isPoolAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.POOL_ADMIN_ROLE());
        }
    }

    /// @dev Overridden to push the rate to the Aave Config Engine.
    function push(address token, RateLibrary.Rate memory rate) internal virtual override {
        super.push(token, rate);

        // Push the latest rate to the Aave Config Engine
        pushToConfigEngine(token, rate);
    }

    /**
     * @notice Pushes the rate to the Aave Config Engine.
     * @dev Whether the rate is for supply caps or borrow caps is determined by the `forSupplyCaps` field.
     * @param token The token to push the rate for.
     * @param rate The rate to push.
     */
    function pushToConfigEngine(address token, RateLibrary.Rate memory rate) internal virtual {
        IAaveV3ConfigEngine.CapsUpdate[] memory capsUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);

        capsUpdates[0] = IAaveV3ConfigEngine.CapsUpdate({
            asset: token,
            supplyCap: forSupplyCaps ? rate.current : EngineFlags.KEEP_CURRENT,
            borrowCap: forSupplyCaps ? EngineFlags.KEEP_CURRENT : rate.current
        });

        IAaveV3ConfigEngine(configEngine).updateCaps(capsUpdates);
    }

    /// @dev Overridden to only check if the the rate changes by at least the desired threshold.
    function willAnythingChange(bytes memory data) internal view virtual override returns (bool) {
        address token = abi.decode(data, (address));

        BufferMetadata memory meta = rateBufferMetadata[token];

        // No rates in the buffer, so the rate will change.
        if (meta.size == 0) return true;

        uint256 lastRate = _getRates(token, 1, 0, 1)[0].current;
        (, uint64 nextRate) = computeRateAndClamp(token);

        return changeThresholdSurpassed(lastRate, nextRate, meta.changeThreshold);
    }

    /// @dev Overridden to allow anyone to extend the capacity of the rate buffers. Since `willAnythingChange` only
    ///   compares the previous rate to the next rate, extending the capacity of the rate buffers does not affect the
    ///   gas consumption of the rate controller (by much).
    function checkSetRatesCapacity() internal view virtual override {
        // Anyone can extend the capacity of the rate buffers.
    }

    /// @dev Taken from adrastia-core/contracts/accumulators/AbstractAccumulator.
    /// @custom:todo Add this to a library upstream.
    function calculateChange(uint256 a, uint256 b) internal view virtual returns (uint256 change, bool isInfinite) {
        // Ensure a is never smaller than b
        if (a < b) {
            uint256 temp = a;
            a = b;
            b = temp;
        }

        // a >= b

        if (a == 0) {
            // a == b == 0 (since a >= b), therefore no change
            return (0, false);
        } else if (b == 0) {
            // (a > 0 && b == 0) => change threshold passed
            // Zero to non-zero always returns true
            return (0, true);
        }

        unchecked {
            uint256 delta = a - b; // a >= b, therefore no underflow
            uint256 preciseDelta = delta * CHANGE_PRECISION;

            // If the delta is so large that multiplying by CHANGE_PRECISION overflows, we assume that
            // the change threshold has been surpassed.
            // If our assumption is incorrect, the accumulator will be extra-up-to-date, which won't
            // really break anything, but will cost more gas in keeping this accumulator updated.
            if (preciseDelta < delta) return (0, true);

            change = preciseDelta / b;
            isInfinite = false;
        }
    }

    /// @dev Taken from adrastia-core/contracts/accumulators/AbstractAccumulator.
    /// @custom:todo Add this to a library upstream.
    function changeThresholdSurpassed(
        uint256 a,
        uint256 b,
        uint256 changeThreshold
    ) internal view virtual returns (bool) {
        (uint256 change, bool isInfinite) = calculateChange(a, b);

        return isInfinite || change >= changeThreshold;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../../../RateController.sol";
import "../../../../vendor/aave/IACLManager.sol";

/**
 * @title AaveRateController
 * @notice A smart contract that extends RateController to implement access control based on Aave's ACL Manager.
 */
contract AaveRateController is RateController {
    /// @notice The Aave ACL Manager instance.
    IACLManager public immutable aclManager;

    /// @notice An error that is thrown if the account is not authorized for the required role.
    /// @param account The account that is not authorized.
    /// @param requiredRole The required role (hash) that the account is missing.
    error NotAuthorized(address account, bytes32 requiredRole);

    /**
     * @notice Constructs the AaveRateController contract.
     * @param aclManager_ The Aave ACL Manager instance.
     * @param period_ The period of the rate controller.
     * @param initialBufferCardinality_ The initial cardinality of the rate buffers.
     * @param updatersMustBeEoa_ Whether or not the updaters must be EOA.
     */
    constructor(
        IACLManager aclManager_,
        uint32 period_,
        uint8 initialBufferCardinality_,
        bool updatersMustBeEoa_
    ) RateController(period_, initialBufferCardinality_, updatersMustBeEoa_) {
        aclManager = aclManager_;
    }

    /**
     * @notice Checks if the sender has the required role to set the rate, namely, the POOL_ADMIN role.
     */
    function checkSetConfig() internal view virtual override {
        if (!aclManager.isPoolAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.POOL_ADMIN_ROLE());
        }
    }

    /**
     * @notice Checks if the sender has the required role to manually push rates, namely, the POOL_ADMIN role.
     */
    function checkManuallyPushRate() internal view virtual override {
        if (!aclManager.isPoolAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.POOL_ADMIN_ROLE());
        }
    }

    /**
     * @notice Checks if the sender has the required role to [un]pause updates, namely, the EMERGENCY_ADMIN role.
     */
    function checkSetUpdatesPaused() internal view virtual override {
        if (!aclManager.isEmergencyAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.EMERGENCY_ADMIN_ROLE());
        }
    }

    /**
     * @notice Checks if the sender has the required role change the rate buffer capacity, namely, the POOL_ADMIN role.
     */
    function checkSetRatesCapacity() internal view virtual override {
        if (!aclManager.isPoolAdmin(msg.sender)) {
            revert NotAuthorized(msg.sender, aclManager.POOL_ADMIN_ROLE());
        }
    }

    /**
     * @notice Checks if the sender has the required role to poke rate updates, which is anyone.
     */
    function checkUpdate() internal view virtual override {
        // Anyone can poke updates (provided they are not paused)
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./IHistoricalRates.sol";

/**
 * @title HistoricalRates
 * @notice The HistoricalRates contract is an abstract contract designed to store historical rate data for various
 * tokens on the blockchain. It provides functionalities for initializing, updating, and querying historical rate
 * data in a circular buffer with a fixed capacity.
 * @dev This contract implements the IHistoricalRates interface and maintains a mapping of tokens to their respective
 * rate buffers and metadata. Each rate buffer holds an array of Rate structs containing target rate, current rate, and
 * timestamp data. The metadata includes information about the buffer's start, end, size, maximum size, and a pause
 * flag, which can be used to pause updates in extended contracts.
 */
abstract contract HistoricalRates is IHistoricalRates {
    struct BufferMetadata {
        uint16 start;
        uint16 end;
        uint16 size;
        uint16 maxSize;
        uint16 flags; // Bit flags
        uint32 changeThreshold;
        uint80 __reserved; // Reserved for future use
        uint64 extra; // For user extensions
    }

    /// @notice Event emitted when a rate buffer's capacity is increased past the initial capacity.
    /// @dev Buffer initialization does not emit an event.
    /// @param token The token for which the rate buffer's capacity was increased.
    /// @param oldCapacity The previous capacity of the rate buffer.
    /// @param newCapacity The new capacity of the rate buffer.
    event RatesCapacityIncreased(address indexed token, uint256 oldCapacity, uint256 newCapacity);

    /// @notice Event emitted when a rate buffer's capacity is initialized.
    /// @param token The token for which the rate buffer's capacity was initialized.
    /// @param capacity The capacity of the rate buffer.
    event RatesCapacityInitialized(address indexed token, uint256 capacity);

    /// @notice Event emitted when a new rate is pushed to the rate buffer.
    /// @param token The token for which the rate was pushed.
    /// @param target The target rate.
    /// @param current The current rate, which may be different from the target rate if the rate change is capped.
    /// @param timestamp The timestamp at which the rate was pushed.
    event RateUpdated(address indexed token, uint256 target, uint256 current, uint256 timestamp);

    /// @notice An error that is thrown if we try to initialize a rate buffer that has already been initialized.
    /// @param token The token for which we tried to initialize the rate buffer.
    error BufferAlreadyInitialized(address token);

    /// @notice An error that is thrown if we try to retrieve a rate at an invalid index.
    /// @param token The token for which we tried to retrieve the rate.
    /// @param index The index of the rate that we tried to retrieve.
    /// @param size The size of the rate buffer.
    error InvalidIndex(address token, uint256 index, uint256 size);

    /// @notice An error that is thrown if we try to decrease the capacity of a rate buffer.
    /// @param token The token for which we tried to decrease the capacity of the rate buffer.
    /// @param amount The capacity that we tried to decrease the rate buffer to.
    /// @param currentCapacity The current capacity of the rate buffer.
    error CapacityCannotBeDecreased(address token, uint256 amount, uint256 currentCapacity);

    /// @notice An error that is thrown if we try to increase the capacity of a rate buffer past the maximum capacity.
    /// @param token The token for which we tried to increase the capacity of the rate buffer.
    /// @param amount The capacity that we tried to increase the rate buffer to.
    /// @param maxCapacity The maximum capacity of the rate buffer.
    error CapacityTooLarge(address token, uint256 amount, uint256 maxCapacity);

    /// @notice An error that is thrown if we try to retrieve more rates than are available in the rate buffer.
    /// @param token The token for which we tried to retrieve the rates.
    /// @param size The size of the rate buffer.
    /// @param minSizeRequired The minimum size of the rate buffer that we require.
    error InsufficientData(address token, uint256 size, uint256 minSizeRequired);

    /// @notice The initial capacity of the rate buffer.
    uint16 internal immutable initialBufferCardinality;

    /// @notice Maps a token to its metadata.
    mapping(address => BufferMetadata) internal rateBufferMetadata;

    /// @notice Maps a token to a buffer of rates.
    mapping(address => RateLibrary.Rate[]) internal rateBuffers;

    /**
     * @notice Constructs the HistoricalRates contract with a specified initial buffer capacity.
     * @param initialBufferCardinality_ The initial capacity of the rate buffer.
     */
    constructor(uint16 initialBufferCardinality_) {
        initialBufferCardinality = initialBufferCardinality_;
    }

    /// @inheritdoc IHistoricalRates
    function getRateAt(address token, uint256 index) external view virtual override returns (RateLibrary.Rate memory) {
        BufferMetadata memory meta = rateBufferMetadata[token];

        if (index >= meta.size) {
            revert InvalidIndex(token, index, meta.size);
        }

        uint256 bufferIndex = meta.end < index ? meta.end + meta.size - index : meta.end - index;

        return rateBuffers[token][bufferIndex];
    }

    /// @inheritdoc IHistoricalRates
    function getRates(
        address token,
        uint256 amount
    ) external view virtual override returns (RateLibrary.Rate[] memory) {
        return _getRates(token, amount, 0, 1);
    }

    /// @inheritdoc IHistoricalRates
    function getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view virtual override returns (RateLibrary.Rate[] memory) {
        return _getRates(token, amount, offset, increment);
    }

    /// @inheritdoc IHistoricalRates
    function getRatesCount(address token) external view override returns (uint256) {
        return rateBufferMetadata[token].size;
    }

    /// @inheritdoc IHistoricalRates
    function getRatesCapacity(address token) external view virtual override returns (uint256) {
        uint256 maxSize = rateBufferMetadata[token].maxSize;
        if (maxSize == 0) return initialBufferCardinality;

        return maxSize;
    }

    /// @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
    ///   less than 256.
    /// @inheritdoc IHistoricalRates
    function setRatesCapacity(address token, uint256 amount) external virtual {
        _setRatesCapacity(token, amount);
    }

    /**
     * @dev Internal function to set the capacity of the rate buffer for a token.
     * @param token The token for which to set the new capacity.
     * @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
     * less than 256.
     */
    function _setRatesCapacity(address token, uint256 amount) internal virtual {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (amount < meta.maxSize) revert CapacityCannotBeDecreased(token, amount, meta.maxSize);
        if (amount > type(uint16).max) revert CapacityTooLarge(token, amount, type(uint16).max);

        RateLibrary.Rate[] storage rateBuffer = rateBuffers[token];

        // Add new slots to the buffer
        uint256 capacityToAdd = amount - meta.maxSize;
        for (uint256 i = 0; i < capacityToAdd; ++i) {
            // Push a dummy rate with non-zero values to put most of the gas cost on the caller
            rateBuffer.push(RateLibrary.Rate({target: 1, current: 1, timestamp: 1}));
        }

        if (meta.maxSize != amount) {
            emit RatesCapacityIncreased(token, meta.maxSize, amount);

            // Update the metadata
            meta.maxSize = uint16(amount);
        }
    }

    /**
     * @dev Internal function to get historical rates with specified amount, offset, and increment.
     * @param token The token for which to retrieve the rates.
     * @param amount The number of historical rates to retrieve.
     * @param offset The number of rates to skip before starting to collect the rates.
     * @param increment The step size between the rates to collect.
     * @return observations An array of Rate structs containing the retrieved historical rates.
     */
    function _getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) internal view virtual returns (RateLibrary.Rate[] memory) {
        if (amount == 0) return new RateLibrary.Rate[](0);

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.size <= (amount - 1) * increment + offset)
            revert InsufficientData(token, meta.size, (amount - 1) * increment + offset + 1);

        RateLibrary.Rate[] memory observations = new RateLibrary.Rate[](amount);

        uint256 count = 0;

        for (
            uint256 i = meta.end < offset ? meta.end + meta.size - offset : meta.end - offset;
            count < amount;
            i = (i < increment) ? (i + meta.size) - increment : i - increment
        ) {
            observations[count++] = rateBuffers[token][i];
        }

        return observations;
    }

    /**
     * @dev Internal function to initialize rate buffers for a token.
     * @param token The token for which to initialize the rate buffer.
     */
    function initializeBuffers(address token) internal virtual {
        if (rateBuffers[token].length != 0) {
            revert BufferAlreadyInitialized(token);
        }

        BufferMetadata storage meta = rateBufferMetadata[token];

        // Initialize the buffers
        RateLibrary.Rate[] storage observationBuffer = rateBuffers[token];

        for (uint256 i = 0; i < initialBufferCardinality; ++i) {
            observationBuffer.push();
        }

        // Initialize the metadata
        meta.start = 0;
        meta.end = 0;
        meta.size = 0;
        meta.maxSize = initialBufferCardinality;

        emit RatesCapacityInitialized(token, meta.maxSize);
    }

    /**
     * @dev Internal function to push a new rate data into the rate buffer and update metadata accordingly.
     * @param token The token for which to push the new rate data.
     * @param rate The Rate struct containing target rate, current rate, and timestamp data to be pushed.
     */
    function push(address token, RateLibrary.Rate memory rate) internal virtual {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (meta.size == 0) {
            if (meta.maxSize == 0) {
                // Initialize the buffers
                initializeBuffers(token);
            }
        } else {
            meta.end = (meta.end + 1) % meta.maxSize;
        }

        rateBuffers[token][meta.end] = rate;

        emit RateUpdated(token, rate.target, rate.current, block.timestamp);

        if (meta.size < meta.maxSize && meta.end == meta.size) {
            // We are at the end of the array and we have not yet filled it
            meta.size++;
        } else {
            // start was just overwritten
            meta.start = (meta.start + 1) % meta.size;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./RateLibrary.sol";

/**
 * @title IHistoricalRates
 * @notice An interface that defines a contract that stores historical rates.
 */
interface IHistoricalRates {
    /// @notice Gets an rate for a token at a specific index.
    /// @param token The address of the token to get the rates for.
    /// @param index The index of the rate to get, where index 0 contains the latest rate, and the last
    ///   index contains the oldest rate (uses reverse chronological ordering).
    /// @return rate The rate for the token at the specified index.
    function getRateAt(address token, uint256 index) external view returns (RateLibrary.Rate memory);

    /// @notice Gets the latest rates for a token.
    /// @param token The address of the token to get the rates for.
    /// @param amount The number of rates to get.
    /// @return rates The latest rates for the token, in reverse chronological order, from newest to oldest.
    function getRates(address token, uint256 amount) external view returns (RateLibrary.Rate[] memory);

    /// @notice Gets the latest rates for a token.
    /// @param token The address of the token to get the rates for.
    /// @param amount The number of rates to get.
    /// @param offset The index of the first rate to get (default: 0).
    /// @param increment The increment between rates to get (default: 1).
    /// @return rates The latest rates for the token, in reverse chronological order, from newest to oldest.
    function getRates(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view returns (RateLibrary.Rate[] memory);

    /// @notice Gets the number of rates for a token.
    /// @param token The address of the token to get the number of rates for.
    /// @return count The number of rates for the token.
    function getRatesCount(address token) external view returns (uint256);

    /// @notice Gets the capacity of rates for a token.
    /// @param token The address of the token to get the capacity of rates for.
    /// @return capacity The capacity of rates for the token.
    function getRatesCapacity(address token) external view returns (uint256);

    /// @notice Sets the capacity of rates for a token.
    /// @param token The address of the token to set the capacity of rates for.
    /// @param amount The new capacity of rates for the token.
    function setRatesCapacity(address token, uint256 amount) external;
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/interfaces/IPeriodic.sol";
import "@adrastia-oracle/adrastia-core/contracts/interfaces/IUpdateable.sol";

import "@openzeppelin-v4/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin-v4/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "./HistoricalRates.sol";
import "./IRateComputer.sol";

/// @title RateController
/// @notice A contract that periodically computes and stores rates for tokens.
/// @dev This contract is abstract because it lacks restrictions on sensitive functions. Please override checkSetConfig,
/// checkSetUpdatesPaused, checkSetRatesCapacity, and checkUpdate to add restrictions.
abstract contract RateController is ERC165, HistoricalRates, IRateComputer, IUpdateable, IPeriodic {
    using SafeCast for uint256;

    struct RateConfig {
        uint64 max;
        uint64 min;
        uint64 maxIncrease;
        uint64 maxDecrease;
        uint32 maxPercentIncrease; // 10000 = 100%
        uint16 maxPercentDecrease; // 10000 = 100%
        uint64 base;
        uint16[] componentWeights; // 10000 = 100%
        IRateComputer[] components;
    }

    /// @notice The flag that indicates whether rate updates are paused.
    uint16 internal constant PAUSE_FLAG_MASK = 0x0000000000000001;

    /// @notice The period of the rate controller, in seconds. This is the frequency at which rates are updated.
    uint256 public immutable override period;

    /// @notice True if all rate updaters must be EOA accounts; false otherwise.
    /// @dev This is a security feature to prevent malicious contracts from updating rates.
    bool public immutable updatersMustBeEoa;

    /// @notice Maps a token to its rate configuration.
    mapping(address => RateConfig) internal rateConfigs;

    /// @notice Event emitted when a new rate is manually pushed to the rate buffer.
    /// @param token The token for which the rate was pushed.
    /// @param target The target rate.
    /// @param current The effective rate.
    /// @param timestamp The timestamp at which the rate was pushed.
    /// @param amount The amount of times the rate was pushed.
    event RatePushedManually(address indexed token, uint256 target, uint256 current, uint256 timestamp, uint256 amount);

    /// @notice Event emitted when the pause status of rate updates for a token is changed.
    /// @param token The token for which the pause status of rate updates was changed.
    /// @param areUpdatesPaused Whether rate updates are paused for the token.
    event PauseStatusChanged(address indexed token, bool areUpdatesPaused);

    /// @notice Event emitted when the rate configuration for a token is updated.
    /// @param token The token for which the rate configuration was updated.
    event RateConfigUpdated(address indexed token, RateConfig oldConfig, RateConfig newConfig);

    /// @notice An error that is thrown if we try to set a rate configuration with invalid parameters.
    /// @param token The token for which we tried to set the rate configuration.
    error InvalidConfig(address token);

    /// @notice An error that is thrown if we require a rate configuration that has not been set.
    /// @param token The token for which we require a rate configuration.
    error MissingConfig(address token);

    /// @notice An error that is thrown if we require that all rate updaters be EOA accounts, but the updater is not.
    /// @param txOrigin The address of the transaction origin.
    /// @param updater The address of the rate updater.
    error UpdaterMustBeEoa(address txOrigin, address updater);

    /// @notice Creates a new rate controller.
    /// @param period_ The period of the rate controller, in seconds. This is the frequency at which rates are updated.
    /// @param initialBufferCardinality_ The initial capacity of the rate buffer.
    /// @param updatersMustBeEoa_ True if all rate updaters must be EOA accounts; false otherwise.
    constructor(
        uint32 period_,
        uint8 initialBufferCardinality_,
        bool updatersMustBeEoa_
    ) HistoricalRates(initialBufferCardinality_) {
        period = period_;
        updatersMustBeEoa = updatersMustBeEoa_;
    }

    /// @notice Returns the rate configuration for a token.
    /// @param token The token for which to get the rate configuration.
    /// @return The rate configuration for the token.
    function getConfig(address token) external view virtual returns (RateConfig memory) {
        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            revert MissingConfig(token);
        }

        return rateConfigs[token];
    }

    /// @notice Sets the rate configuration for a token. This can only be called by the rate admin.
    /// @param token The token for which to set the rate configuration.
    /// @param config The rate configuration to set.
    function setConfig(address token, RateConfig calldata config) external virtual {
        checkSetConfig();

        if (config.components.length != config.componentWeights.length) {
            revert InvalidConfig(token);
        }

        if (config.maxPercentDecrease > 10000) {
            // The maximum percent decrease must be less than or equal to 100%.
            revert InvalidConfig(token);
        }

        if (config.max < config.min) {
            // The maximum rate must be greater than or equal to the minimum rate.
            revert InvalidConfig(token);
        }

        // Ensure that the sum of the component weights less than or equal to 10000 (100%)
        // Notice: It's possible to have the sum of the component weights be less than 10000 (100%). It's also possible
        // to have the component weights be 100% and the base rate be non-zero. This is intentional because we don't
        // have a hard cap on the rate.
        uint256 sum = 0;
        for (uint256 i = 0; i < config.componentWeights.length; ++i) {
            if (
                address(config.components[i]) == address(0) ||
                !ERC165Checker.supportsInterface(address(config.components[i]), type(IRateComputer).interfaceId)
            ) {
                revert InvalidConfig(token);
            }

            sum += config.componentWeights[i];
        }
        if (sum > 10000) {
            revert InvalidConfig(token);
        }

        // Ensure that the base rate plus the sum of the maximum component rates won't overflow
        if (uint256(config.base) + ((sum * type(uint64).max) / 10000) > type(uint64).max) {
            revert InvalidConfig(token);
        }

        RateConfig memory oldConfig = rateConfigs[token];

        rateConfigs[token] = config;

        emit RateConfigUpdated(token, oldConfig, config);

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // We require that the buffer is initialized before allowing rate updates to occur
            initializeBuffers(token);
        }
    }

    /// @notice Manually pushes new rates for a token, bypassing the update logic, clamp logic, pause logic, and
    /// other restrictions.
    /// @dev WARNING: This function is very powerful and should only be used in emergencies. It is intended to be used
    /// to manually push rates when the rate controller is in a bad state. It should not be used to push rates
    /// regularly. Make sure to lock it down with the highest level of security.
    /// @param token The token for which to push rates.
    /// @param target The target rate to push.
    /// @param current The current rate to push.
    /// @param amount The number of times to push the rate.
    function manuallyPushRate(address token, uint64 target, uint64 current, uint256 amount) external {
        checkManuallyPushRate();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Uninitialized buffer means that the rate config is missing
            revert MissingConfig(token);
        }

        // Note: We don't check the pause status here because we want to allow rate updates to be manually pushed even
        // if rate updates are paused.

        RateLibrary.Rate memory rate = RateLibrary.Rate({
            target: target,
            current: current,
            timestamp: uint32(block.timestamp)
        });

        for (uint256 i = 0; i < amount; ++i) {
            push(token, rate);
        }

        if (amount > 0) {
            emit RatePushedManually(token, target, current, block.timestamp, amount);
        }
    }

    /// @notice Determines whether rate updates are paused for a token.
    /// @param token The token for which to determine whether rate updates are paused.
    /// @return Whether rate updates are paused for the given token.
    function areUpdatesPaused(address token) external view virtual returns (bool) {
        return _areUpdatesPaused(token);
    }

    /// @notice Changes the pause state of rate updates for a token. This can only be called by the update pause admin.
    /// @param token The token for which to change the pause state.
    /// @param paused Whether rate updates should be paused.
    function setUpdatesPaused(address token, bool paused) external virtual {
        checkSetUpdatesPaused();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Uninitialized buffer means that the rate config is missing
            // It doesn't make sense to pause updates if they can't occur in the first place
            revert MissingConfig(token);
        }

        uint16 flags = rateBufferMetadata[token].flags;

        bool currentlyPaused = (flags & PAUSE_FLAG_MASK) != 0;
        if (currentlyPaused != paused) {
            if (paused) {
                flags |= PAUSE_FLAG_MASK;
            } else {
                flags &= ~PAUSE_FLAG_MASK;
            }

            rateBufferMetadata[token].flags = flags;

            emit PauseStatusChanged(token, paused);
        }
    }

    /// @inheritdoc IRateComputer
    function computeRate(address token) external view virtual override returns (uint64) {
        (, uint64 newRate) = computeRateAndClamp(token);

        return newRate;
    }

    /// @inheritdoc IPeriodic
    function granularity() external view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc IUpdateable
    function update(bytes memory data) public virtual override returns (bool b) {
        checkUpdate();

        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool b) {
        address token = abi.decode(data, (address));

        BufferMetadata memory meta = rateBufferMetadata[token];

        // Requires that:
        //   0. The update period has elapsed.
        //   1. The buffer is initialized. We do this to prevent zero values from being pushed to the buffer.
        //   2. Updates are not paused.
        //   3. Something will change. Otherwise, updating is a waste of gas.
        return
            timeSinceLastUpdate(data) >= period &&
            meta.maxSize > 0 &&
            !_areUpdatesPaused(token) &&
            willAnythingChange(data);
    }

    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool b) {
        return
            // Can only update if the update is needed
            needsUpdate(data) &&
            // Can only update if the sender is an EOA or the contract allows EOA updates
            (!updatersMustBeEoa || msg.sender == tx.origin);
    }

    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return getLatestRate(token).timestamp;
    }

    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IHistoricalRates).interfaceId ||
            interfaceId == type(IRateComputer).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            interfaceId == type(IPeriodic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to set the capacity of the rate buffer for a token. Only callable by the admin because the
     * updating logic is O(n) on the capacity. Only callable when the rate config is set.
     * @param token The token for which to set the new capacity.
     * @param amount The new capacity of rates for the token. Must be greater than the current capacity, but
     * less than 256.
     */
    function _setRatesCapacity(address token, uint256 amount) internal virtual override {
        checkSetRatesCapacity();

        BufferMetadata storage meta = rateBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Buffer is not initialized yet
            // Buffer can only be initialized when the rate config is set
            revert MissingConfig(token);
        }

        super._setRatesCapacity(token, amount);
    }

    /// @notice Determines if rate updates are paused for a token.
    /// @return bool A boolean value indicating whether rate updates are paused for the given token.
    function _areUpdatesPaused(address token) internal view virtual returns (bool) {
        return (rateBufferMetadata[token].flags & PAUSE_FLAG_MASK) != 0;
    }

    /// @notice Determines if any changes will occur in the rate buffer after a new rate is added.
    /// @dev This function is used to reduce the amount of gas used by updaters when the rate is not changing.
    /// @param data A bytes array containing the token address to be decoded.
    /// @return bool A boolean value indicating whether any changes will occur in the rate buffer.
    function willAnythingChange(bytes memory data) internal view virtual returns (bool) {
        address token = abi.decode(data, (address));

        BufferMetadata memory meta = rateBufferMetadata[token];

        // If the buffer has empty slots, they can be filled
        if (meta.size != meta.maxSize) return true;

        // All current rates in the buffer should match the next rate. Otherwise, the rate will change.
        // We don't check target rates because if the rate is capped, the current rate may never reach the target rate.
        (, uint64 nextRate) = computeRateAndClamp(token);
        RateLibrary.Rate[] memory rates = _getRates(token, meta.size, 0, 1);
        for (uint256 i = 0; i < rates.length; ++i) {
            if (rates[i].current != nextRate) return true;
        }

        return false;
    }

    /// @notice Gets the latest rate for a token. If the buffer is empty, returns a zero rate.
    /// @param token The token to get the latest rate for.
    /// @return The latest rate for the token, or a zero rate if the buffer is empty.
    function getLatestRate(address token) internal view virtual returns (RateLibrary.Rate memory) {
        BufferMetadata storage meta = rateBufferMetadata[token];

        if (meta.size == 0) {
            // If the buffer is empty, return the default (zero) rate
            return RateLibrary.Rate({target: 0, current: 0, timestamp: 0});
        }

        return rateBuffers[token][meta.end];
    }

    /// @notice Computes the rate for the given token.
    /// @dev This function calculates the rate for the specified token by summing its base rate
    /// and the weighted rates of its components. The component rates are computed using the `computeRate`
    /// function of each component and multiplied by the corresponding weight, then divided by 10,000.
    /// @param token The address of the token for which to compute the rate.
    /// @return uint64 The computed rate for the given token.
    function computeRateInternal(address token) internal view virtual returns (uint64) {
        RateConfig memory config = rateConfigs[token];

        uint64 rate = config.base;

        for (uint256 i = 0; i < config.componentWeights.length; ++i) {
            uint64 componentRate = ((uint256(config.components[i].computeRate(token)) * config.componentWeights[i]) /
                10000).toUint64();

            rate += componentRate;
        }

        return rate;
    }

    /// @notice Computes the target rate and clamps it based on the specified token's rate configuration.
    /// @dev This function calculates the target rate by calling `computeRateInternal`. It then clamps the new rate
    /// to ensure it is within the specified bounds for maximum constant and percentage increases or decreases.
    /// This helps to prevent sudden or extreme rate fluctuations.
    /// @param token The address of the token for which to compute the clamped rate.
    /// @return target The computed target rate for the given token.
    /// @return newRate The clamped rate for the given token, taking into account the maximum increase and decrease
    /// constraints.
    function computeRateAndClamp(address token) internal view virtual returns (uint64 target, uint64 newRate) {
        // Compute the target rate
        target = computeRateInternal(token);
        newRate = target;

        RateConfig memory config = rateConfigs[token];

        // Clamp the rate to the minimum and maximum rates
        // We do this before clamping the rate to the maximum constant and percentage increases or decreases because
        // we don't want a change in the minimum or maximum rate to cause a sudden change in the rate.
        if (newRate < config.min) {
            // The new rate is too low, so we change it to the minimum rate
            newRate = config.min;
        } else if (newRate > config.max) {
            // The new rate is too high, so we change it to the maximum rate
            newRate = config.max;
        }

        BufferMetadata memory meta = rateBufferMetadata[token];
        if (meta.size > 0) {
            // We have a previous rate, so let's make sure we don't change it too much

            uint64 last = rateBuffers[token][meta.end].current;

            if (newRate > last) {
                // Clamp the rate to the maximum constant increase
                if (newRate - last > config.maxIncrease) {
                    // The new rate is too high, so we change it by the maximum increase
                    newRate = last + config.maxIncrease;
                }

                // Clamp the rate to the maximum percentage increase
                uint256 maxIncreaseAbsolute = (uint256(last) * config.maxPercentIncrease) / 10000;
                if (newRate - last > maxIncreaseAbsolute) {
                    // The new rate is too high, so we change it by the maximum percentage increase
                    newRate = last + uint64(maxIncreaseAbsolute);
                }
            } else if (newRate < last) {
                // Clamp the rate to the maximum constant decrease
                if (last - newRate > config.maxDecrease) {
                    // The new rate is too low, so we change it by the maximum decrease
                    newRate = last - config.maxDecrease;
                }

                // Clamp the rate to the maximum percentage decrease
                uint256 maxDecreaseAbsolute = (uint256(last) * config.maxPercentDecrease) / 10000;
                if (last - newRate > maxDecreaseAbsolute) {
                    // The new rate is too low, so we change it by the maximum percentage decrease
                    newRate = last - uint64(maxDecreaseAbsolute);
                }
            }
        }
    }

    /// @notice Performs an update of the token's rate based on the provided data.
    /// @dev This function ensures that only EOAs (Externally Owned Accounts) can update the rate
    /// if `updatersMustBeEoa` is set to true. It decodes the token address from the input data, computes
    /// the new clamped rate using `computeRateAndClamp`, and then pushes the new rate to the rate buffer.
    /// @param data The input data, containing the token address to be updated.
    /// @return bool Returns true if the update is successful.
    function performUpdate(bytes memory data) internal virtual returns (bool) {
        if (updatersMustBeEoa && msg.sender != tx.origin) {
            // Only EOA can update
            revert UpdaterMustBeEoa(tx.origin, msg.sender);
        }

        address token = abi.decode(data, (address));

        // Compute the new target rate and clamp it
        (uint64 target, uint64 newRate) = computeRateAndClamp(token);

        // Push the new rate
        push(token, RateLibrary.Rate({target: target, current: newRate, timestamp: uint32(block.timestamp)}));

        return true;
    }

    /// @notice Checks if the caller is authorized to set the configuration.
    /// @dev This function should contain the access control logic for the setConfig function.
    function checkSetConfig() internal view virtual;

    /// @notice Checks if the caller is authorized to manually push rates.
    /// @dev This function should contain the access control logic for the manuallyPushRate function.
    /// WARNING: The manuallyPushRate function is very dangerous and should only be used in emergencies. Ensure that
    /// this function is implemented correctly and that the access control logic is sufficient to prevent abuse.
    function checkManuallyPushRate() internal view virtual;

    /// @notice Checks if the caller is authorized to pause or resume updates.
    /// @dev This function should contain the access control logic for the setUpdatesPaused function.
    function checkSetUpdatesPaused() internal view virtual;

    /// @notice Checks if the caller is authorized to set the rates capacity.
    /// @dev This function should contain the access control logic for the setRatesCapacity function.
    function checkSetRatesCapacity() internal view virtual;

    /// @notice Checks if the caller is authorized to perform an update.
    /// @dev This function should contain the access control logic for the update function.
    function checkUpdate() internal view virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library RateLibrary {
    struct Rate {
        uint64 target;
        uint64 current;
        uint32 timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EngineFlags {
    /// @dev magic value to be used as flag to keep unchanged any current configuration
    /// Strongly assumes that the value `type(uint256).max - 42` will never be used, which seems reasonable
    uint256 internal constant KEEP_CURRENT = type(uint256).max - 42;

    /// @dev value to be used as flag for bool value true
    uint256 internal constant ENABLED = 1;

    /// @dev value to be used as flag for bool value false
    uint256 internal constant DISABLED = 0;

    /// @dev converts flag ENABLED DISABLED to bool
    function toBool(uint256 flag) internal pure returns (bool) {
        require(flag == 0 || flag == 1, "INVALID_CONVERSION_TO_BOOL");
        return flag == 1;
    }

    /// @dev converts bool to ENABLED DISABLED flags
    function fromBool(bool isTrue) internal pure returns (uint256) {
        return isTrue ? ENABLED : DISABLED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveV3ConfigEngine {
    /**
     * @dev Example (mock):
     * CapsUpdate({
     *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
     *   supplyCap: 1_000_000,
     *   borrowCap: EngineFlags.KEEP_CURRENT
     * }
     */
    struct CapsUpdate {
        address asset;
        uint256 supplyCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
        uint256 borrowCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
    }

    /**
     * @notice Performs an update of the caps (supply, borrow) of the assets, in the Aave pool configured in this engine instance
     * @param updates `CapsUpdate[]` list of declarative updates containing the new caps
     *   More information on the documentation of the struct.
     */
    function updateCaps(CapsUpdate[] memory updates) external;
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