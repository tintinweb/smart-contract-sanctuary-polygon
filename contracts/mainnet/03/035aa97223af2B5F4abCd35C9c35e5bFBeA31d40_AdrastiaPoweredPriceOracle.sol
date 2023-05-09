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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/ERC165.sol";
import "@adrastia-oracle/adrastia-core/contracts/interfaces/IPriceOracle.sol";

import "../vendor/chainlink/AggregatorV3Interface.sol";

/**
 * @title AdrastiaPoweredPriceOracle
 * @notice Chainlink price oracle adapter for Adrastia.
 * @dev This contract is a Chainlink price oracle adapter for Adrastia.
 * It implements the AggregatorV3Interface interface and uses an implementation of IPriceOracle to get the price data.
 * The `getRoundData` function is not supported because Adrastia does not implement round IDs.
 * The `latestRoundData` function uses Adrastia's observation timestamp as the round ID and all timestamps.
 */
contract AdrastiaPoweredPriceOracle is AggregatorV3Interface, IERC165 {
    /// @notice The Adrastia price oracle.
    IPriceOracle public immutable adrastiaOracle;

    /// @notice The token for which the price is returned.
    address public immutable token;

    /// @notice The number of decimals used in the price.
    uint8 public immutable override decimals;

    /// @notice The description of the price feed.
    string public override description;

    /// @notice The error message for unsupported functions.
    error NotSupported();

    /**
     * @notice Constructs a new AdrastiaPoweredPriceOracle.
     * @param adrastiaOracle_ The Adrastia price oracle.
     * @param token_ The token for which the price is returned.
     * @param description_ The description of the price feed.
     */
    constructor(IPriceOracle adrastiaOracle_, address token_, uint8 decimals_, string memory description_) {
        adrastiaOracle = adrastiaOracle_;
        token = token_;
        decimals = decimals_;
        description = description_;
    }

    /**
     * @notice Returns the version of the price feed.
     * @return The version of the price feed.
     */
    function version() external pure override returns (uint256) {
        return 1;
    }

    /// @dev This function is not supported because Adrastia does not implement round IDs.
    function getRoundData(uint80) external pure override returns (uint80, int256, uint256, uint256, uint80) {
        revert NotSupported();
    }

    /**
     * @notice Returns the latest price data.
     * @dev This function calls the `consultPrice` and `lastUpdateTime` functions of the Adrastia price oracle.
     * @return roundId The timestamp of the latest price data.
     * @return answer The latest price.
     * @return startedAt The timestamp of the latest price data.
     * @return updatedAt The timestamp of the latest price data.
     * @return answeredInRound The timestamp of the latest price data.
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint112 price = adrastiaOracle.consultPrice(token);
        uint256 timestamp = adrastiaOracle.lastUpdateTime(abi.encode(token));

        roundId = uint80(timestamp);
        answer = int256(uint256(price));
        startedAt = timestamp;
        updatedAt = timestamp;
        answeredInRound = uint80(timestamp);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(AggregatorV3Interface).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}