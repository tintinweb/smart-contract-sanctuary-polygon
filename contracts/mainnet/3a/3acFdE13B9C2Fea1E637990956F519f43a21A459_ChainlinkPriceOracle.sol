// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "BaseChainLinkOracle.sol";

import "Errors.sol";
import "DecimalScale.sol";

contract ChainlinkPriceOracle is BaseChainlinkPriceOracle {
    using DecimalScale for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event FeedUpdated(address indexed asset, address indexed previousFeed, address indexed newFeed);

    constructor(address _governor) BaseChainlinkPriceOracle(_governor) {}

    /// @inheritdoc IUSDPriceOracle
    function getPriceUSD(address asset) external view override returns (uint256) {
        address feed = feeds[asset];
        require(feed != address(0), Errors.ASSET_NOT_SUPPORTED);
        (, uint256 price, ) = _getLatestRoundData(feed);
        return price.scaleFrom(AggregatorV2V3Interface(feed).decimals());
    }

    /// @notice Allows to set Chainlink feeds
    /// This can only be called by governance
    function setFeed(address asset, address feed) external virtual governanceOnly {
        address previousFeed = feeds[asset];
        require(feed != previousFeed, Errors.INVALID_ARGUMENT);
        _supportedAssets.add(asset);
        feeds[asset] = feed;
        emit FeedUpdated(asset, previousFeed, feed);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Governable.sol";

import "IUSDPriceOracle.sol";
import "ChainlinkAggregator.sol";

import "Errors.sol";
import "DecimalScale.sol";

abstract contract BaseChainlinkPriceOracle is IUSDPriceOracle, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using DecimalScale for uint256;

    uint256 public constant MAX_LAG = 86400;

    EnumerableSet.AddressSet internal _supportedAssets;
    mapping(address => address) public feeds;

    constructor(address _governor) Governable(_governor) {}

    function listSupportedAssets() external view returns (address[] memory) {
        return _supportedAssets.values();
    }

    function _getLatestRoundData(address feed)
        internal
        view
        returns (
            uint80 roundId,
            uint256 price,
            uint256 updatedAt
        )
    {
        int256 answer;
        (roundId, answer, , updatedAt, ) = AggregatorV2V3Interface(feed).latestRoundData();
        require(block.timestamp <= updatedAt + MAX_LAG, Errors.STALE_PRICE);
        require(answer >= 0, Errors.NEGATIVE_PRICE);
        price = uint256(answer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "GovernableBase.sol";

contract Governable is GovernableBase {
    constructor(address _governor) {
        governor = _governor;
        emit GovernorChanged(address(0), _governor);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Errors.sol";
import "IGovernable.sol";

contract GovernableBase is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    modifier governanceOnly() {
        require(msg.sender == governor, Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IGovernable
    function changeGovernor(address newGovernor) external override governanceOnly {
        require(address(newGovernor) != address(0), Errors.INVALID_ARGUMENT);
        pendingGovernor = newGovernor;
        emit GovernorChangeRequested(newGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override {
        require(msg.sender == pendingGovernor, Errors.NOT_AUTHORIZED);
        address currentGovernor = governor;
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorChanged(currentGovernor, msg.sender);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IGovernable {
    /// @notice Emmited when the governor is changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    /// @notice Emmited when the governor is change is requested
    event GovernorChangeRequested(address newGovernor);

    /// @notice Returns the current governor
    function governor() external view returns (address);

    /// @notice Returns the pending governor
    function pendingGovernor() external view returns (address);

    /// @notice Changes the governor
    /// can only be called by the current governor
    function changeGovernor(address newGovernor) external;

    /// @notice Called by the pending governor to approve the change
    function acceptGovernance() external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IUSDPriceOracle {
    /// @notice Quotes the USD price of `tokenAddress`
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param tokenAddress the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

library DecimalScale {
    uint8 internal constant DECIMALS = 18; // 18 decimal places

    function scaleFrom(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == DECIMALS) {
            return value;
        } else if (decimals > DECIMALS) {
            return value / 10**(decimals - DECIMALS);
        } else {
            return value * 10**(DECIMALS - decimals);
        }
    }

    function scaleTo(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == DECIMALS) {
            return value;
        } else if (decimals > DECIMALS) {
            return value * 10**(decimals - DECIMALS);
        } else {
            return value / 10**(DECIMALS - decimals);
        }
    }
}