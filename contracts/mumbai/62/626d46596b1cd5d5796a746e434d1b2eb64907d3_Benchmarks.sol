// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPyth} from "pyth/IPyth.sol";
import {PythStructs} from "pyth/PythStructs.sol";
import {IBenchmarks, IBenchmarksEE} from "./interfaces/IBenchmarks.sol";

/// @title Benchmarks
/// @author Mike Shrieve ([email protected])
/// @notice Verifies and records signed Pyth benchmark price data
contract Benchmarks is IBenchmarks {
    /// @notice Pyth contract
    IPyth public immutable pyth;
    /// @notice time which must pass to add 1 second to the validity period
    uint256 public constant VALIDITY_PERIOD_SCALE = 1 minutes;
    /// @notice the maximum difference between a timestamp and a publishTime
    uint256 public constant VALIDITY_PERIOD_MAX = 5 seconds;
    /// @notice internal decimals used for prices
    uint256 public constant DECIMALS = 18;

    /// @notice (benchmarkId => price)
    mapping(bytes32 => uint256) public prices;

    /// @param _pyth - Pyth price ID
    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    /// @notice Computes the benchmark ID
    /// @param _priceId     - Pyth price ID
    /// @param _timestamp   - timestamp of the benchmark price
    /// @return benchmarkId - the associated benchmark ID
    function computeBenchmarkId(bytes32 _priceId, uint256 _timestamp)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_priceId, _timestamp));
    }

    /// @notice Gets the fee required to verify and decode benchmark price data
    /// @param _priceData - signed and encoded Pyth price data
    /// @return fee       - the Pyth fee
    function getFee(bytes calldata _priceData) public view returns (uint256) {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = _priceData;
        return pyth.getUpdateFee(updateData);
    }

    /// @notice Records a benchmark price, first validating the signature of the price data
    /// @notice on the Pyth contract.
    /// @notice Benchmark prices are scaled to 18 decimals. There may be loss of precision
    /// @notice if the priceData is using more than 18 decimals.
    /// @param _priceId   - Pyth price ID
    /// @param _timestamp - request timestamp
    /// @param _priceData - the signed price data
    /// @return price     - the recorded price, scaled to 18 decimals
    function recordPrice(bytes32 _priceId, uint256 _timestamp, bytes calldata _priceData)
        external
        payable
        returns (uint256)
    {
        bytes32 benchmarkId = computeBenchmarkId(_priceId, _timestamp);

        if (prices[benchmarkId] != 0) {
            revert PriceIsAlreadyRecorded(_priceId, _timestamp);
        }

        (uint256 price, uint256 decimals, uint256 publishTime) =
            _parsePriceFeedUpdate(_priceId, _timestamp, _priceData);
        price = _scaleDecimals(price, decimals);

        emit PriceRecorded(_priceId, _timestamp, price, publishTime);

        prices[benchmarkId] = price;
        return price;
    }

    /// @notice Submits _priceData to the Pyth contract for signature verification
    /// @notice and returns the decoded data
    /// @param _priceId     - Pyth price ID
    /// @param _timestamp   - request timestamp
    /// @param _priceData   - the signed price data
    /// @return price       - the scaled price
    /// @return decimals    - the decimal precision of the price
    /// @return publishTime - the publish time of the price
    function _parsePriceFeedUpdate(bytes32 _priceId, uint256 _timestamp, bytes memory _priceData)
        internal
        returns (uint256 price, uint256 decimals, uint256 publishTime)
    {
        bytes[] memory updateData = new bytes[](1);
        updateData[0] = _priceData;
        bytes32[] memory priceIds = new bytes32[](1);
        priceIds[0] = _priceId;

        uint256 updateFee = pyth.getUpdateFee(updateData);
        if (msg.value != updateFee) {
            revert FeeIsNotExact(msg.value, updateFee);
        }

        uint64 maxPublishTime = _computeMaxPublishTime(_timestamp);

        PythStructs.Price memory priceData = pyth.parsePriceFeedUpdates{value: msg.value}({
            updateData: updateData,
            priceIds: priceIds,
            minPublishTime: uint64(_timestamp),
            maxPublishTime: maxPublishTime
        })[0].price;

        // non-positive prices are not supported
        if (priceData.price <= 0) {
            revert PriceIsInvalid(priceData.price);
        }

        // positive decimals are not supported
        if (priceData.expo > 0) {
            revert ExponentIsInvalid(priceData.expo);
        }

        price = uint256(int256(priceData.price));
        decimals = uint256(-1 * int256(priceData.expo));
        publishTime = priceData.publishTime;
    }

    /// @notice Computes the maximum allowed value of publishTime
    /// @notice given the request timestamp and the current block timestamp.
    /// @notice The maxPublishTime increases linearly as a function of block.timestamp.
    /// @notice It starts at _timestamp and increases by 1 second every VALIDITY_PERIOD_SCALE,
    /// @notice until it hits a maximum of VALIDITY PERIOD MAX.
    /// @param _timestamp      - the request timestamp
    /// @return maxPublishTime - the max value of publishTime
    function _computeMaxPublishTime(uint256 _timestamp) internal view returns (uint64) {
        if (block.timestamp < _timestamp) {
            return uint64(_timestamp);
        }

        // the validity period increases by 1 second, every 1 minutes
        uint64 validityPeriod = uint64(
            _min((block.timestamp - _timestamp) / VALIDITY_PERIOD_SCALE, VALIDITY_PERIOD_MAX)
        );
        // add max validity period
        uint64 maxPublishTime = uint64(_timestamp + validityPeriod);
        return maxPublishTime;
    }

    /// @notice Returns the minimum of two uint256 values
    /// @param _a       - the first value to compare
    /// @param _b       - the second value to compare
    /// @return minimum - the minimum of _a and _b
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    /// @notice Rescale the price to the internal decimal precision
    /// @param _price    - the original price
    /// @param _decimals - decimals of the original price
    /// @return price    - the price rescaled to DECIMALS decimals
    function _scaleDecimals(uint256 _price, uint256 _decimals) internal pure returns (uint256) {
        if (_decimals < DECIMALS) {
            _price *= 10 ** (DECIMALS - _decimals);
        } else if (_decimals > DECIMALS) {
            _price /= 10 ** (_decimals - DECIMALS);
        }

        return _price;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBenchmarksEE {
    error PriceIsAlreadyRecorded(bytes32 priceId, uint256 timestamp);
    error FeeIsNotExact(uint256 received, uint256 expected);
    error PriceIsInvalid(int64 price);
    error ExponentIsInvalid(int32 exponent);

    event PriceRecorded(
        bytes32 indexed priceId, uint256 indexed timestamp, uint256 price, uint256 publishTime
    );
}

interface IBenchmarks is IBenchmarksEE {
    function DECIMALS() external view returns (uint256);

    function prices(bytes32 _benchmarkId) external view returns (uint256);

    function computeBenchmarkId(bytes32 _priceId, uint256 _timestamp)
        external
        pure
        returns (bytes32);

    function getFee(bytes calldata _priceData) external view returns (uint256);

    function recordPrice(bytes32 _priceId, uint256 _timestamp, bytes calldata _priceData)
        external
        payable
        returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}