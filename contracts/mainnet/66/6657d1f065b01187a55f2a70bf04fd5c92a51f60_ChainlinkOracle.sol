// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/external/chainlink/IAggregatorV3.sol";
import "../interfaces/oracles/IOracle.sol";

/// @notice Contract for getting chainlink data
contract ChainlinkOracle is IOracle, Ownable {
    /// @notice Thrown when tokens.length != oracles.length
    error InvalidLength();

    /// @notice Thrown when price feed doesn't work by some reason
    error InvalidOracle();

    /// @notice Thrown when sum of token.decimals and oracle.decimals is too high
    error InvalidOverallDecimals();

    /// @notice Price update error
    error PriceUpdateFailed();

    uint256 public constant DECIMALS = 18;
    uint256 public constant Q96 = 2**96;

    struct PriceData {
        IAggregatorV3 feed;
        uint48 heartbeat;
        uint48 fallbackUpdatedAt;
        uint256 fallbackPriceX96;
        uint256 priceMultiplier;
    }

    /// @notice Mapping, returning underlying prices for each token
    mapping(address => PriceData) public pricesInfo;

    /// @notice Valid period of underlying prices (in seconds)
    uint256 public validPeriod;

    /// @notice Creates a new contract
    /// @param tokens Initial supported tokens
    /// @param oracles Initial approved Chainlink oracles
    /// @param heartbeats Initial heartbeats for chainlink oracles
    /// @param validPeriod_ Initial valid period of underlying prices (in seconds)
    constructor(
        address[] memory tokens,
        address[] memory oracles,
        uint48[] memory heartbeats,
        uint256 validPeriod_
    ) {
        validPeriod = validPeriod_;
        _addChainlinkOracles(tokens, oracles, heartbeats);
    }

    // -------------------------  EXTERNAL, VIEW  ------------------------------

    /// @inheritdoc IOracle
    function hasOracle(address token) external view returns (bool) {
        return address(pricesInfo[token].feed) != address(0);
    }

    /// @inheritdoc IOracle
    function price(address token) external view returns (bool success, uint256 priceX96) {
        PriceData storage priceData = pricesInfo[token];
        (IAggregatorV3 feed, uint48 heartbeat, uint48 fallbackUpdatedAt) = (
            priceData.feed,
            priceData.heartbeat,
            priceData.fallbackUpdatedAt
        );
        uint256 oraclePrice;
        uint256 updatedAt;
        if (address(priceData.feed) == address(0)) {
            return (false, 0);
        }
        (success, oraclePrice, updatedAt) = _queryChainlinkOracle(feed);
        if (!success || updatedAt + heartbeat < block.timestamp) {
            if (block.timestamp <= fallbackUpdatedAt + validPeriod) {
                return (true, priceData.fallbackPriceX96);
            } else {
                return (false, 0);
            }
        }

        success = true;
        priceX96 = oraclePrice * priceData.priceMultiplier;
    }

    // -------------------------  EXTERNAL, MUTATING  ------------------------------

    /// @notice Add more chainlink oracles and tokens
    /// @param tokens Array of new tokens
    /// @param oracles Array of new oracles
    /// @param heartbeats Array of heartbeats for oracles
    function addChainlinkOracles(
        address[] memory tokens,
        address[] memory oracles,
        uint48[] memory heartbeats
    ) external onlyOwner {
        _addChainlinkOracles(tokens, oracles, heartbeats);
    }

    /// @notice Set new valid period
    /// @param validPeriod_ New valid period
    function setValidPeriod(uint256 validPeriod_) external onlyOwner {
        validPeriod = validPeriod_;
        emit ValidPeriodUpdated(tx.origin, msg.sender, validPeriod_);
    }

    /// @notice Set new underlying fallbackPriceX96 for specific token
    /// @param token Address of the token
    /// @param fallbackPriceX96 Value of price multiplied by 2**96
    /// @param fallbackUpdatedAt Timestamp of the price
    function setUnderlyingPriceX96(
        address token,
        uint256 fallbackPriceX96,
        uint48 fallbackUpdatedAt
    ) external onlyOwner {
        if (fallbackUpdatedAt >= block.timestamp) {
            fallbackUpdatedAt = uint48(block.timestamp);
        } else if (fallbackUpdatedAt + validPeriod < block.timestamp) {
            revert PriceUpdateFailed();
        }

        PriceData storage priceData = pricesInfo[token];

        priceData.fallbackUpdatedAt = fallbackUpdatedAt;
        priceData.fallbackPriceX96 = fallbackPriceX96;

        emit PricePosted(tx.origin, msg.sender, token, fallbackPriceX96, fallbackUpdatedAt);
    }

    // -------------------------  INTERNAL, VIEW  ------------------------------

    /// @notice Attempt to send a price query to chainlink oracle
    /// @param oracle Chainlink oracle
    /// @return success Query to chainlink oracle (if oracle.latestRoundData call works correctly => the answer can be received), answer Result of the query
    function _queryChainlinkOracle(IAggregatorV3 oracle)
        internal
        view
        returns (
            bool success,
            uint256 answer,
            uint256 fallbackUpdatedAt
        )
    {
        try oracle.latestRoundData() returns (uint80, int256 ans, uint256, uint256 fallbackUpdatedAt_, uint80) {
            if (ans <= 0) {
                return (false, 0, 0);
            }
            return (true, uint256(ans), fallbackUpdatedAt_);
        } catch (bytes memory) {
            return (false, 0, 0);
        }
    }

    // -------------------------  INTERNAL, MUTATING  ------------------------------

    /// @notice Add more chainlink oracles and tokens (internal)
    /// @param tokens Array of new tokens
    /// @param oracles Array of new oracles
    /// @param heartbeats Array of heartbeats for oracles
    function _addChainlinkOracles(
        address[] memory tokens,
        address[] memory oracles,
        uint48[] memory heartbeats
    ) internal {
        if (tokens.length != oracles.length || oracles.length != heartbeats.length) {
            revert InvalidLength();
        }
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            address oracle = oracles[i];
            uint48 heartbeat = heartbeats[i];

            IAggregatorV3 chainlinkOracle = IAggregatorV3(oracle);
            (bool flag, , ) = _queryChainlinkOracle(chainlinkOracle);

            if (!flag) {
                revert InvalidOracle(); // hence a token for this 'oracle' can not be added
            }

            uint256 decimals = uint256(IERC20Metadata(token).decimals() + IAggregatorV3(oracle).decimals());

            // when decimals is more than 18 + 26 priceDeviation becomes too high
            if (decimals > 44) {
                revert InvalidOverallDecimals();
            }

            uint256 priceMultiplier;
            if (DECIMALS > decimals) {
                priceMultiplier = (10**(DECIMALS - decimals)) * Q96;
            } else {
                priceMultiplier = Q96 / 10**(decimals - DECIMALS);
            }

            pricesInfo[token] = PriceData({
                feed: chainlinkOracle,
                heartbeat: heartbeat,
                fallbackUpdatedAt: 0,
                fallbackPriceX96: 0,
                priceMultiplier: priceMultiplier
            });
        }
        emit OraclesAdded(tx.origin, msg.sender, tokens, oracles, heartbeats);
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when new Chainlink oracles are added
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param tokens Tokens added
    /// @param oracles Oracles added for the tokens
    /// @param heartbeats Array of heartbeats for oracles
    event OraclesAdded(
        address indexed origin,
        address indexed sender,
        address[] tokens,
        address[] oracles,
        uint48[] heartbeats
    );

    /// @notice Emitted when underlying price of the token updates
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param token Address of the token
    /// @param newPriceX96 New underlying price multiplied by 2**96
    /// @param fallbackUpdatedAt Timestamp of underlying price updating
    event PricePosted(
        address indexed origin,
        address indexed sender,
        address token,
        uint256 newPriceX96,
        uint48 fallbackUpdatedAt
    );

    /// @notice Emitted when validPeriod updates
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param validPeriod Current valid period
    event ValidPeriodUpdated(address indexed origin, address indexed sender, uint256 validPeriod);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IAggregatorV3 {
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Oracle price for token.
    /// @param token Reference to token
    /// @return success True if call to an external oracle was successful, false otherwise
    /// @return priceX96 Price that satisfy token
    function price(address token) external view returns (bool success, uint256 priceX96);

    /// @notice Returns if an oracle was approved for a token
    /// @param token A given token address
    /// @return bool True if an oracle was approved for a token, else - false
    function hasOracle(address token) external view returns (bool);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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