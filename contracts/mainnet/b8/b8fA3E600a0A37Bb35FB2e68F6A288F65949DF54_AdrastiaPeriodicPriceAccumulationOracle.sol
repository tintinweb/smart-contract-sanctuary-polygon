//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IAccumulator
 * @notice An interface that defines an accumulator - that is, a contract that updates cumulative value(s) when the
 *   underlying value(s) change by more than the update threshold.
 */
abstract contract IAccumulator {
    /// @notice Gets the scalar (as a power of 10) to be used for calculating changes in value.
    /// @return The scalar to be used for calculating changes in value.
    function changePrecision() external view virtual returns (uint256);

    /// @notice Gets the threshold at which an update to the cumulative value(s) should be performed.
    /// @return A percentage scaled by the change precision.
    function updateThreshold() external view virtual returns (uint256);

    /// @notice Gets the minimum delay between updates to the cumulative value(s).
    /// @return The minimum delay between updates to the cumulative value(s), in seconds.
    function updateDelay() external view virtual returns (uint256);

    /// @notice Gets the maximum delay (target) between updates to the cumulative value(s), without requiring a change
    ///   past the update threshold.
    /// @return The maximum delay (target) between updates to the cumulative value(s), in seconds.
    function heartbeat() external view virtual returns (uint256);

    /// @notice Determines whether the specified change threshold has been surpassed with respect to the specified
    ///   data.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param data Amy data relating to the update.
    /// @param changeThreshold The change threshold as a percentage multiplied by the change precision
    ///   (`changePrecision`). Ex: a 1% change is respresented as 0.01 * `changePrecision`.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function changeThresholdSurpassed(bytes memory data, uint256 changeThreshold) public view virtual returns (bool);

    /// @notice Determines whether the update threshold has been surpassed with respect to the specified data.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param data Amy data relating to the update.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function updateThresholdSurpassed(bytes memory data) public view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IHasPriceAccumulator
 * @notice An interface that defines a contract containing price accumulator.
 */
interface IHasPriceAccumulator {
    /// @notice Gets the address of the price accumulator.
    /// @return pa The address of the price accumulator.
    function priceAccumulator() external view returns (address pa);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "../libraries/AccumulationLibrary.sol";

/**
 * @title IHistoricalPriceAccumulationOracle
 * @notice An interface that defines an oracle contract that stores historical price accumulations.
 */
interface IHistoricalPriceAccumulationOracle {
    /// @notice Gets a price accumulation for a token at a specific index.
    /// @param token The address of the token to get the accumulation for.
    /// @param index The index of the accumulation to get, where index 0 contains the latest accumulation, and the last
    ///   index contains the oldest accumulation (uses reverse chronological ordering).
    /// @return The accumulation for the token at the specified index.
    function getPriceAccumulationAt(
        address token,
        uint256 index
    ) external view returns (AccumulationLibrary.PriceAccumulator memory);

    /// @notice Gets the latest price accumulations for a token.
    /// @param token The address of the token to get the accumulations for.
    /// @param amount The number of accumulations to get.
    /// @return The latest accumulations for the token, in reverse chronological order, from newest to oldest.
    function getPriceAccumulations(
        address token,
        uint256 amount
    ) external view returns (AccumulationLibrary.PriceAccumulator[] memory);

    /// @notice Gets the latest price accumulations for a token.
    /// @param token The address of the token to get the accumulations for.
    /// @param amount The number of accumulations to get.
    /// @param offset The index of the first accumulations to get (default: 0).
    /// @param increment The increment between accumulations to get (default: 1).
    /// @return The latest accumulations for the token, in reverse chronological order, from newest to oldest.
    function getPriceAccumulations(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view returns (AccumulationLibrary.PriceAccumulator[] memory);

    /// @notice Gets the number of price accumulations for a token.
    /// @param token The address of the token to get the number of accumulations for.
    /// @return count The number of accumulations for the token.
    function getPriceAccumulationsCount(address token) external view returns (uint256);

    /// @notice Gets the capacity of price accumulations for a token.
    /// @param token The address of the token to get the capacity of accumulations for.
    /// @return capacity The capacity of accumulations for the token.
    function getPriceAccumulationsCapacity(address token) external view returns (uint256);

    /// @notice Sets the capacity of price accumulations for a token.
    /// @param token The address of the token to set the capacity of accumulations for.
    /// @param amount The new capacity of accumulations for the token.
    function setPriceAccumulationsCapacity(address token, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/**
 * @title ILiquidityOracle
 * @notice An interface that defines a liquidity oracle with a single quote token (or currency) and many exchange
 *  tokens.
 */
abstract contract ILiquidityOracle is IUpdateable, IQuoteToken {
    /// @notice Gets the liquidity levels of the token and the quote token in the underlying pool.
    /// @param token The token to get liquidity levels of (along with the quote token).
    /// @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    function consultLiquidity(address token)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the liquidity levels of the token and the quote token in the underlying pool, reverting if the
     *  quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get liquidity levels of (along with the quote token).
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./ILiquidityOracle.sol";
import "./IPriceOracle.sol";

/**
 * @title IOracle
 * @notice An interface that defines a price and liquidity oracle.
 */
abstract contract IOracle is IUpdateable, IPriceOracle, ILiquidityOracle {
    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token
     *  andquote token in the underlying pool.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(
        address token
    ) public view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token and
     *  quote token in the underlying pool, reverting if the quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(
        address token,
        uint256 maxAge
    ) public view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    function liquidityDecimals() public view virtual returns (uint8);
}

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

pragma experimental ABIEncoderV2;

import "./IAccumulator.sol";

import "../libraries/AccumulationLibrary.sol";
import "../libraries/ObservationLibrary.sol";

/**
 * @title IPriceAccumulator
 * @notice An interface that defines a "price accumulator" - that is, a cumulative price - with a single quote token
 *   and many exchange tokens.
 * @dev Price accumulators are used to calculate time-weighted average prices.
 */
abstract contract IPriceAccumulator is IAccumulator {
    /// @notice Emitted when the accumulator is updated.
    /// @dev The accumulator's observation and cumulative values are updated when this is emitted.
    /// @param token The address of the token that the update is for.
    /// @param price The quote token denominated price for a whole token.
    /// @param timestamp The epoch timestamp of the update (in seconds).
    event Updated(address indexed token, uint256 price, uint256 timestamp);

    /**
     * @notice Calculates a price from two different cumulative prices.
     * @param firstAccumulation The first cumulative price.
     * @param secondAccumulation The last cumulative price.
     * @dev Reverts if the timestamp of the first accumulation is 0, or if it's not strictly less than the timestamp of
     *  the second.
     * @return price A time-weighted average price derived from two cumulative prices.
     */
    function calculatePrice(
        AccumulationLibrary.PriceAccumulator calldata firstAccumulation,
        AccumulationLibrary.PriceAccumulator calldata secondAccumulation
    ) external view virtual returns (uint112 price);

    /// @notice Gets the last cumulative price that was stored.
    /// @param token The address of the token to get the cumulative price for.
    /// @return The last cumulative price along with the timestamp of that price.
    function getLastAccumulation(
        address token
    ) public view virtual returns (AccumulationLibrary.PriceAccumulator memory);

    /// @notice Gets the current cumulative price.
    /// @param token The address of the token to get the cumulative price for.
    /// @return The current cumulative price along with the timestamp of that price.
    function getCurrentAccumulation(
        address token
    ) public view virtual returns (AccumulationLibrary.PriceAccumulator memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/// @title IPriceOracle
/// @notice An interface that defines a price oracle with a single quote token (or currency) and many exchange tokens.
abstract contract IPriceOracle is IUpdateable, IQuoteToken {
    /**
     * @notice Gets the price of a token in terms of the quote token.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token) public view virtual returns (uint112 price);

    /**
     * @notice Gets the price of a token in terms of the quote token, reverting if the quotation is older than the
     *  maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token, uint256 maxAge) public view virtual returns (uint112 price);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IQuoteToken
 * @notice An interface that defines a contract containing a quote token (or currency), providing the associated
 *  metadata.
 */
abstract contract IQuoteToken {
    /// @notice Gets the quote token (or currency) name.
    /// @return The name of the quote token (or currency).
    function quoteTokenName() public view virtual returns (string memory);

    /// @notice Gets the quote token address (if any).
    /// @dev This may return address(0) if no specific quote token is used (such as an aggregate of quote tokens).
    /// @return The address of the quote token, or address(0) if no specific quote token is used.
    function quoteTokenAddress() public view virtual returns (address);

    /// @notice Gets the quote token (or currency) symbol.
    /// @return The symbol of the quote token (or currency).
    function quoteTokenSymbol() public view virtual returns (string memory);

    /// @notice Gets the number of decimal places that quote prices have.
    /// @return The number of decimals of the quote token (or currency) that quote prices have.
    function quoteTokenDecimals() public view virtual returns (uint8);
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

/**
 * @notice A library for calculating and storing accumulations of time-weighted average values in the form of sumations
 *   of (value * time).
 */
library AccumulationLibrary {
    /**
     * @notice A struct for storing a snapshot of liquidity accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive time-weighted average
     *   liquidities by dividing the difference in value by the difference in time.
     */
    struct LiquidityAccumulator {
        /*
         * @notice Accumulates time-weighted average liquidity of the token in the form of a sumation of (price * time),
         *   with time measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeTokenLiquidity;
        /*
         * @notice Accumulates time-weighted average liquidity of the quote token in the form of a sumation of
         *   (price * time), with time measured in seconds..
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeQuoteTokenLiquidity;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }

    /**
     * @notice A struct for storing a snapshot of price accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive a time-weighted average
     *   price by dividing the difference in value by the difference in time.
     */
    struct PriceAccumulator {
        /*
         * @notice Accumulates time-weighted average prices in the form of a sumation of (price * time), with time
         *   measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint224 cumulativePrice;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library ObservationLibrary {
    struct ObservationMetadata {
        address oracle;
    }

    struct Observation {
        uint112 price;
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct MetaObservation {
        ObservationMetadata metadata;
        Observation data;
    }

    struct LiquidityObservation {
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct PriceObservation {
        uint112 price;
        uint32 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "../interfaces/IOracle.sol";
import "../libraries/ObservationLibrary.sol";
import "../utils/SimpleQuotationMetadata.sol";

abstract contract AbstractOracle is IERC165, IOracle, SimpleQuotationMetadata {
    constructor(address quoteToken_) SimpleQuotationMetadata(quoteToken_) {}

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function update(bytes memory data) public virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool);

    function getLatestObservation(
        address token
    ) public view virtual returns (ObservationLibrary.Observation memory observation);

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return getLatestObservation(token).timestamp;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    function consultPrice(address token) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10 ** quoteTokenDecimals());

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        return observation.price;
    }

    /// @inheritdoc IPriceOracle
    function consultPrice(address token, uint256 maxAge) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10 ** quoteTokenDecimals());

        if (maxAge == 0) {
            (price, , ) = instantFetch(token);

            return price;
        }

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        return observation.price;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(
        address token
    ) public view virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (0, 0);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(
        address token,
        uint256 maxAge
    ) public view virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (0, 0);

        if (maxAge == 0) {
            (, tokenLiquidity, quoteTokenLiquidity) = instantFetch(token);

            return (tokenLiquidity, quoteTokenLiquidity);
        }

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(
        address token
    ) public view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (uint112(10 ** quoteTokenDecimals()), 0, 0);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(
        address token,
        uint256 maxAge
    ) public view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (uint112(10 ** quoteTokenDecimals()), 0, 0);

        if (maxAge == 0) return instantFetch(token);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(SimpleQuotationMetadata, IERC165) returns (bool) {
        return
            interfaceId == type(IOracle).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            interfaceId == type(IPriceOracle).interfaceId ||
            interfaceId == type(ILiquidityOracle).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Fetches the instant rates as of the latest block, straight from the source.
     * @dev This is costly in gas and the rates are easier to manipulate.
     * @param token The token to get the rates for.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function instantFetch(
        address token
    ) internal view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../interfaces/IPeriodic.sol";

import "./AbstractOracle.sol";

abstract contract PeriodicOracle is IPeriodic, AbstractOracle {
    uint256 public immutable override period;
    uint256 public immutable override granularity;

    uint internal immutable _updateEvery;

    constructor(address quoteToken_, uint256 period_, uint256 granularity_) AbstractOracle(quoteToken_) {
        require(period_ > 0, "PeriodicOracle: INVALID_PERIOD");
        require(granularity_ > 0, "PeriodicOracle: INVALID_GRANULARITY");
        require(period_ % granularity_ == 0, "PeriodicOracle: INVALID_PERIOD_GRANULARITY");

        period = period_;
        granularity = granularity_;

        _updateEvery = period_ / granularity_;
    }

    /// @inheritdoc AbstractOracle
    function update(bytes memory data) public virtual override returns (bool) {
        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @inheritdoc AbstractOracle
    function needsUpdate(bytes memory data) public view virtual override returns (bool) {
        return timeSinceLastUpdate(data) >= _updateEvery;
    }

    /// @inheritdoc AbstractOracle
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        // If this oracle doesn't need an update, it can't (won't) update
        return needsUpdate(data);
    }

    /// @inheritdoc AbstractOracle
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IPeriodic).interfaceId || super.supportsInterface(interfaceId);
    }

    function performUpdate(bytes memory data) internal virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";
import "@openzeppelin-v4/contracts/utils/math/Math.sol";

import "./PeriodicOracle.sol";
import "../interfaces/IPriceAccumulator.sol";
import "../interfaces/IHasPriceAccumulator.sol";
import "../interfaces/IHistoricalPriceAccumulationOracle.sol";

import "../libraries/AccumulationLibrary.sol";
import "../libraries/ObservationLibrary.sol";

/**
 * @title PeriodicPriceAccumulationOracle
 * @notice An oracle that periodically stores price accumulations for tokens and calculates TWAPs from them, storing the
 * results as observations.
 *
 * This oracle implements the IOracle interface for compatibility with observation-based aggregators, with token
 * liquidity and quote token liquidity as constants.
 */
contract PeriodicPriceAccumulationOracle is IHistoricalPriceAccumulationOracle, PeriodicOracle, IHasPriceAccumulator {
    using SafeCast for uint256;

    struct BufferMetadata {
        uint16 start;
        uint16 end;
        uint16 size;
        uint16 maxSize;
    }

    address public immutable override priceAccumulator;

    mapping(address => BufferMetadata) internal accumulationBufferMetadata;

    mapping(address => AccumulationLibrary.PriceAccumulator[]) internal priceAccumulationBuffers;

    mapping(address => ObservationLibrary.Observation) internal observations;

    uint112 internal immutable staticTokenLiquidity;
    uint112 internal immutable staticQuoteTokenLiquidity;

    uint8 internal immutable _liquidityDecimals;

    /// @notice Emitted when a stored quotation is updated.
    /// @param token The address of the token that the quotation is for.
    /// @param price The quote token denominated price for a whole token.
    /// @param tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @param quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    /// @param timestamp The epoch timestamp of the quotation (in seconds).
    event Updated(
        address indexed token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity,
        uint256 timestamp
    );

    /// @notice Event emitted when an accumulation buffer's capacity is increased past the initial capacity.
    /// @dev Buffer initialization does not emit an event.
    /// @param token The token for which the accumulation buffer's capacity was increased.
    /// @param oldCapacity The previous capacity of the accumulation buffer.
    /// @param newCapacity The new capacity of the accumulation buffer.
    event AccumulationCapacityIncreased(address indexed token, uint256 oldCapacity, uint256 newCapacity);

    /// @notice Event emitted when an accumulation buffer's capacity is initialized.
    /// @param token The token for which the accumulation buffer's capacity was initialized.
    /// @param capacity The capacity of the accumulation buffer.
    event AccumulationCapacityInitialized(address indexed token, uint256 capacity);

    /// @notice Event emitted when an accumulation is pushed to the buffer.
    /// @param token The token for which the accumulation was pushed.
    /// @param priceCumulative The cumulative price of the token.
    /// @param priceTimestamp The timestamp of the cumulative price.
    event AccumulationPushed(address indexed token, uint256 priceCumulative, uint256 priceTimestamp);

    /// @notice An error that is thrown if the update is this oracle is blocked because the price accumulator needs
    /// to be updated.
    /// @param token The token for which the price accumulator needs to be updated.
    error PriceAccumulatorNeedsUpdate(address token);

    /// @notice An error that is thrown if we try to initialize an accumulation buffer that has already been
    ///   initialized.
    /// @param token The token for which we tried to initialize the accumulation buffer.
    error BufferAlreadyInitialized(address token);

    /// @notice An error that is thrown if we try to retrieve a accumulation at an invalid index.
    /// @param token The token for which we tried to retrieve the accumulation.
    /// @param index The index of the accumulation that we tried to retrieve.
    /// @param size The size of the accumulation buffer.
    error InvalidIndex(address token, uint256 index, uint256 size);

    /// @notice An error that is thrown if we try to decrease the capacity of a accumulation buffer.
    /// @param token The token for which we tried to decrease the capacity of the accumulation buffer.
    /// @param amount The capacity that we tried to decrease the accumulation buffer to.
    /// @param currentCapacity The current capacity of the accumulation buffer.
    error CapacityCannotBeDecreased(address token, uint256 amount, uint256 currentCapacity);

    /// @notice An error that is thrown if we try to increase the capacity of a accumulation buffer past the maximum
    ///   capacity.
    /// @param token The token for which we tried to increase the capacity of the accumulation buffer.
    /// @param amount The capacity that we tried to increase the accumulation buffer to.
    /// @param maxCapacity The maximum capacity of the accumulation buffer.
    error CapacityTooLarge(address token, uint256 amount, uint256 maxCapacity);

    /// @notice An error that is thrown if we try to retrieve more accumulations than are available in the accumulation
    ///   buffer.
    /// @param token The token for which we tried to retrieve the accumulations.
    /// @param size The size of the accumulation buffer.
    /// @param minSizeRequired The minimum size of the accumulation buffer that we require.
    error InsufficientData(address token, uint256 size, uint256 minSizeRequired);

    constructor(
        address priceAccumulator_,
        address quoteToken_,
        uint256 period_,
        uint256 granularity_,
        uint112 staticTokenLiquidity_,
        uint112 staticQuoteTokenLiquidity_,
        uint8 liquidityDecimals_
    ) PeriodicOracle(quoteToken_, period_, granularity_) {
        priceAccumulator = priceAccumulator_;
        staticTokenLiquidity = staticTokenLiquidity_;
        staticQuoteTokenLiquidity = staticQuoteTokenLiquidity_;
        _liquidityDecimals = liquidityDecimals_;
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    function getPriceAccumulationAt(
        address token,
        uint256 index
    ) external view virtual override returns (AccumulationLibrary.PriceAccumulator memory) {
        BufferMetadata memory meta = accumulationBufferMetadata[token];

        if (index >= meta.size) {
            revert InvalidIndex(token, index, meta.size);
        }

        uint256 bufferIndex = meta.end < index ? meta.end + meta.size - index : meta.end - index;

        return priceAccumulationBuffers[token][bufferIndex];
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    function getPriceAccumulations(
        address token,
        uint256 amount
    ) external view virtual override returns (AccumulationLibrary.PriceAccumulator[] memory) {
        return getPriceAccumulationsInternal(token, amount, 0, 1);
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    function getPriceAccumulations(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view virtual returns (AccumulationLibrary.PriceAccumulator[] memory) {
        return getPriceAccumulationsInternal(token, amount, offset, increment);
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    function getPriceAccumulationsCount(address token) external view override returns (uint256) {
        return accumulationBufferMetadata[token].size;
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    function getPriceAccumulationsCapacity(address token) external view virtual override returns (uint256) {
        uint256 maxSize = accumulationBufferMetadata[token].maxSize;
        if (maxSize == 0) return granularity;

        return maxSize;
    }

    /// @inheritdoc IHistoricalPriceAccumulationOracle
    /// @param amount The new capacity of accumulations for the token. Must be greater than the current capacity, but
    ///   less than 65536.
    function setPriceAccumulationsCapacity(address token, uint256 amount) external virtual override {
        setAccumulationsCapacityInternal(token, amount);
    }

    function getLatestObservation(
        address token
    ) public view virtual override returns (ObservationLibrary.Observation memory observation) {
        return observations[token];
    }

    /// @inheritdoc PeriodicOracle
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        uint256 gracePeriod = accumulatorUpdateDelayTolerance();

        if (
            IUpdateable(priceAccumulator).timeSinceLastUpdate(data) >=
            IAccumulator(priceAccumulator).heartbeat() + gracePeriod
        ) {
            // Shouldn't update if the accumulators are not up-to-date
            return false;
        }

        return super.canUpdate(data);
    }

    /// @inheritdoc AbstractOracle
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        BufferMetadata storage meta = accumulationBufferMetadata[token];

        // Return 0 if there are no observations (never updated)
        if (meta.size == 0) return 0;

        // Note: We ignore the last observation timestamp because it always updates when the accumulation timestamps
        // update.
        uint256 lastPriceAccumulationTimestamp = priceAccumulationBuffers[token][meta.end].timestamp;

        return lastPriceAccumulationTimestamp;
    }

    /// @inheritdoc PeriodicOracle
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IHasPriceAccumulator).interfaceId ||
            interfaceId == type(IHistoricalPriceAccumulationOracle).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IOracle
    function liquidityDecimals() public view virtual override returns (uint8) {
        return _liquidityDecimals;
    }

    /// @notice The grace period that we allow for the accumulators to be in need of a heartbeat update before we
    ///   consider it to be out-of-date.
    /// @return The grace period in seconds.
    function accumulatorUpdateDelayTolerance() public view virtual returns (uint256) {
        // We trade some freshness for greater reliability. Using too low of a tolerance reduces the cost of DoS.
        // Furthermore, large price fluctuations can require tokens to be bridged by arbitrageurs to fix DEX prices,
        // and this can take time. Price accumulators may not get updated during this time as we may require on-chain
        // prices to closely match off-chain prices.
        return 1 hours;
    }

    /// @notice The grace period that we allow for the oracle to be in need of an update (as the sum of all update
    ///   delays in a period) before we discard the last accumulation. If this grace period is exceeded, it will take
    ///   more updates to get a new observation.
    /// @dev This is to prevent longer time-weighted averages than we desire. The maximum period is then the period of
    ///   this oracle plus this grace period.
    /// @return The grace period in seconds.
    function updateDelayTolerance() public view virtual returns (uint256) {
        // We tolerate two missed periods plus 5 minutes (to allow for some time to update the oracles).
        // We trade off some freshness for greater reliability. Using too low of a tolerance reduces the cost of DoS
        // attacks.
        return (period * 2) + 5 minutes;
    }

    function setAccumulationsCapacityInternal(address token, uint256 amount) internal virtual {
        BufferMetadata storage meta = accumulationBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Buffer is not initialized yet
            initializeBuffers(token);
        }

        if (amount < meta.maxSize) revert CapacityCannotBeDecreased(token, amount, meta.maxSize);
        if (amount > type(uint8).max) revert CapacityTooLarge(token, amount, type(uint8).max);

        AccumulationLibrary.PriceAccumulator[] storage priceAccumulationBuffer = priceAccumulationBuffers[token];

        // Add new slots to the buffer
        uint256 capacityToAdd = amount - meta.maxSize;
        for (uint256 i = 0; i < capacityToAdd; ++i) {
            // Push dummy accumulations with non-zero values to put most of the gas cost on the caller
            priceAccumulationBuffer.push(AccumulationLibrary.PriceAccumulator({cumulativePrice: 1, timestamp: 1}));
        }

        if (meta.maxSize != amount) {
            emit AccumulationCapacityIncreased(token, meta.maxSize, amount);

            // Update the metadata
            meta.maxSize = uint16(amount);
        }
    }

    function getPriceAccumulationsInternal(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) internal view virtual returns (AccumulationLibrary.PriceAccumulator[] memory) {
        if (amount == 0) return new AccumulationLibrary.PriceAccumulator[](0);

        BufferMetadata memory meta = accumulationBufferMetadata[token];
        if (meta.size <= (amount - 1) * increment + offset)
            revert InsufficientData(token, meta.size, (amount - 1) * increment + offset + 1);

        AccumulationLibrary.PriceAccumulator[] memory accumulations = new AccumulationLibrary.PriceAccumulator[](
            amount
        );

        uint256 count = 0;

        for (
            uint256 i = meta.end < offset ? meta.end + meta.size - offset : meta.end - offset;
            count < amount;
            i = (i < increment) ? (i + meta.size) - increment : i - increment
        ) {
            accumulations[count++] = priceAccumulationBuffers[token][i];
        }

        return accumulations;
    }

    function initializeBuffers(address token) internal virtual {
        if (priceAccumulationBuffers[token].length != 0) {
            revert BufferAlreadyInitialized(token);
        }

        BufferMetadata storage meta = accumulationBufferMetadata[token];

        // Initialize the buffers
        AccumulationLibrary.PriceAccumulator[] storage priceAccumulationBuffer = priceAccumulationBuffers[token];

        for (uint256 i = 0; i < granularity; ++i) {
            priceAccumulationBuffer.push();
        }

        // Initialize the metadata
        meta.start = 0;
        meta.end = 0;
        meta.size = 0;
        meta.maxSize = uint16(granularity);

        emit AccumulationCapacityInitialized(token, meta.maxSize);
    }

    function push(
        address token,
        AccumulationLibrary.PriceAccumulator memory priceAccumulation
    ) internal virtual returns (bool) {
        BufferMetadata storage meta = accumulationBufferMetadata[token];

        if (meta.size == 0) {
            if (meta.maxSize == 0) {
                // Initialize the buffers
                initializeBuffers(token);
            }
        } else {
            // Check that at least one accumulation is newer than the last one
            {
                uint256 lastPriceAccumulationTimestamp = priceAccumulationBuffers[token][meta.end].timestamp;

                // Note: Reverts if the new accumulations are older than the last ones
                uint256 lastPriceAccumulationTimeElapsed = priceAccumulation.timestamp - lastPriceAccumulationTimestamp;

                if (lastPriceAccumulationTimeElapsed == 0) {
                    // Both accumulations haven't changed, so we don't need to update
                    return false;
                }
            }

            meta.end = (meta.end + 1) % meta.maxSize;

            // Check if we have enough accumulations for a new observation
            if (meta.size >= granularity) {
                uint256 startIndex = meta.end < granularity
                    ? meta.end + meta.size - granularity
                    : meta.end - granularity;

                AccumulationLibrary.PriceAccumulator memory firstPriceAccumulation = priceAccumulationBuffers[token][
                    startIndex
                ];

                uint256 pricePeriodTimeElapsed = priceAccumulation.timestamp - firstPriceAccumulation.timestamp;

                uint256 maxUpdateGap = period + updateDelayTolerance();

                if (pricePeriodTimeElapsed <= maxUpdateGap && pricePeriodTimeElapsed >= period) {
                    ObservationLibrary.Observation storage observation = observations[token];

                    observation.price = IPriceAccumulator(priceAccumulator).calculatePrice(
                        firstPriceAccumulation,
                        priceAccumulation
                    );
                    (observation.tokenLiquidity, observation.quoteTokenLiquidity) = (
                        staticTokenLiquidity,
                        staticQuoteTokenLiquidity
                    );
                    observation.timestamp = block.timestamp.toUint32();

                    emit Updated(
                        token,
                        observation.price,
                        observation.tokenLiquidity,
                        observation.quoteTokenLiquidity,
                        observation.timestamp
                    );
                }
            }
        }

        priceAccumulationBuffers[token][meta.end] = priceAccumulation;

        emit AccumulationPushed(token, priceAccumulation.cumulativePrice, priceAccumulation.timestamp);

        if (meta.size < meta.maxSize && meta.end == meta.size) {
            // We are at the end of the array and we have not yet filled it
            meta.size++;
        } else {
            // start was just overwritten
            meta.start = (meta.start + 1) % meta.size;
        }

        return true;
    }

    function performUpdate(bytes memory data) internal virtual override returns (bool) {
        // We require that the accumulators have a heartbeat update that is within the grace period (i.e. they are
        // up-to-date).
        // If they are not up-to-date, the oracle will not update.
        // It is expected that oracle consumers will check the last update time before using the data as to avoid using
        // stale data.
        address token = abi.decode(data, (address));
        uint256 gracePeriod = accumulatorUpdateDelayTolerance();

        if (
            IUpdateable(priceAccumulator).timeSinceLastUpdate(data) >=
            IAccumulator(priceAccumulator).heartbeat() + gracePeriod
        ) {
            revert PriceAccumulatorNeedsUpdate(token);
        }

        AccumulationLibrary.PriceAccumulator memory priceAccumulation = IPriceAccumulator(priceAccumulator)
            .getCurrentAccumulation(token);

        return priceAccumulation.timestamp != 0 && push(token, priceAccumulation);
    }

    /// @inheritdoc AbstractOracle
    function instantFetch(
        address token
    ) internal view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        // We assume the accumulators are also oracles... the interfaces need to be refactored
        price = IPriceOracle(priceAccumulator).consultPrice(token, 0);
        (tokenLiquidity, quoteTokenLiquidity) = (staticTokenLiquidity, staticQuoteTokenLiquidity);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract SimpleQuotationMetadata is IQuoteToken, IERC165 {
    address public immutable quoteToken;

    constructor(address quoteToken_) {
        quoteToken = quoteToken_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.name.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return quoteToken;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.symbol.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        (bool success, bytes memory result) = quoteToken.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (!success) return 18; // Return 18 by default

        return abi.decode(result, (uint8));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        // Calculate string length
        uint256 i = 0;
        while (i < 32 && _bytes32[i] != 0) ++i;

        bytes memory bytesArray = new bytes(i);

        // Extract characters
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) bytesArray[i] = _bytes32[i];

        return string(bytesArray);
    }

    function getStringOrBytes32(address contractAddress, bytes4 selector) internal view returns (string memory) {
        (bool success, bytes memory result) = contractAddress.staticcall(abi.encodeWithSelector(selector));
        if (!success) return "";

        return result.length == 32 ? bytes32ToString(bytes32(result)) : abi.decode(result, (string));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract AdrastiaVersioning {
    string public constant ADRASTIA_CORE_VERSION = "v4.0.0-beta.1";
    string public constant ADRASTIA_PERIPHERY_VERSION = "v4.0.0-beta.1";
    string public constant ADRASTIA_PROTOCOL_VERSION = "v0.1.0";
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/PeriodicPriceAccumulationOracle.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaPeriodicPriceAccumulationOracle is AdrastiaVersioning, PeriodicPriceAccumulationOracle {
    struct PeriodicAccumulationOracleParams {
        address priceAccumulator;
        address quoteToken;
        uint256 period;
        uint256 granularity;
        uint112 staticTokenLiquidity;
        uint112 staticQuoteTokenLiquidity;
        uint8 liquidityDecimals;
    }

    string public name;

    constructor(
        string memory name_,
        PeriodicAccumulationOracleParams memory params
    )
        PeriodicPriceAccumulationOracle(
            params.priceAccumulator,
            params.quoteToken,
            params.period,
            params.granularity,
            params.staticTokenLiquidity,
            params.staticQuoteTokenLiquidity,
            params.liquidityDecimals
        )
    {
        name = name_;
    }
}