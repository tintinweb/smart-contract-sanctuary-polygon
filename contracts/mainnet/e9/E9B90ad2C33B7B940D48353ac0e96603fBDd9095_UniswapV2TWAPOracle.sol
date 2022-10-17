// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../lib/FixedPoint.sol";
import "../../../lib/uniswap/IUniswapV2Factory.sol";
import "../../../interfaces/IERC20Detailed.sol";

import "../ProviderAwareOracle.sol";

/**
See https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
for the basis for the below contract. ExampleOracleSimple contract has been extended to support tracking multiple
pairs within the same contract.
*/

contract UniswapV2TWAPOracle is ProviderAwareOracle {
    using FixedPoint for *;

    struct TwapConfig {
        uint lastUpdateCumulativePrice;
        uint32 timestampLatest; // 4 bytes
        FixedPoint.uq112x112 lastUpdateTwapPrice; // 28 bytes
        // Should conform to IUniswapV2Pair interface
        address pairAddress; // 20 bytes
        bool isToken0; // 1 byte
        uint8 decimals; // 1 byte
        uint32 lastTimeTwapPoked;
    }

    /// The commonly-used asset tokens on this TWAP are paired with
    /// May be token0 or token1 depending on sort order
    address public immutable TOKEN;

    address public immutable WETH;

    // Maps token0 to it's latest readings
    mapping(address => TwapConfig) public twaps;

    // 5 minutes
    uint32 public constant MIN_UPDATE_DEFAULT = 5 minutes;
    uint32 public constant MAX_UPDATE = 60 minutes;

    uint32 public immutable MIN_UPDATE;

    address public uniswap;

    /**
     * @dev sets up the Price Oracle
     *
     * @param _inToken the pool token which will be a common component for all govi tokens on this TWAP
     * @param _weth the WETH address for the given chain
     * @param _minimumUpdateInterval how often to permit updates to the TWAP (seconds)
     *                               If set to 0, will use the default of 5 minutes
     * @param _factory the address of the uniswap factory (NOT THE ROUTER) to retrieve pairs from
     */
    constructor(address _provider, address _inToken, address _weth, uint32 _minimumUpdateInterval, address _factory) ProviderAwareOracle(_provider) {
        require(_inToken != address(0) && _weth != address(0), "ER003");
        MIN_UPDATE = _minimumUpdateInterval == 0 ? MIN_UPDATE_DEFAULT : _minimumUpdateInterval;
        TOKEN = _inToken;
        WETH = _weth;
        uniswap = _factory;
    }

    /****** OPERATIONAL METHODS ******/

    /**
     * @dev returns the TWAP for the provided pair as of the last update
     */
    function getSafePrice(address asset) public view returns (uint256 amountOut) {
        require(block.timestamp - twaps[asset].lastTimeTwapPoked <= MAX_UPDATE, 'ER037');
        TwapConfig memory twap = twaps[asset];
        amountOut = _convertPrice(asset, twap.lastUpdateTwapPrice);
    }

    /**
     * @dev returns the current "unsafe" price that can be easily manipulated
     */
    function getCurrentPrice(address asset) public view returns (uint256 amountOut) {
        TwapConfig memory twap = twaps[asset];
        IUniswapV2Pair pair = IUniswapV2Pair(twap.pairAddress);

        uint8 decimals;

        try IERC20Detailed(asset).decimals() returns (uint8 numDecimals) {
            decimals = numDecimals;
        } catch {
            decimals = 18;
        }

        (uint reserve0, uint reserve1, ) = pair.getReserves();
      
        uint8 _token1MissingDecimals;
        if (twap.isToken0) {
            if (decimals > IERC20Detailed(TOKEN).decimals()) {
                _token1MissingDecimals = decimals - (IERC20Detailed(TOKEN).decimals());
                amountOut = (reserve1 * (10**_token1MissingDecimals) * PRECISION) / reserve0;
            } else {

                _token1MissingDecimals = (IERC20Detailed(TOKEN).decimals()) - decimals;
                amountOut = (reserve1 * PRECISION) / (reserve0 * (10**_token1MissingDecimals));
            }    
        } else {
            if (decimals > IERC20Detailed(TOKEN).decimals()) {
                _token1MissingDecimals = decimals - (IERC20Detailed(TOKEN).decimals());
                amountOut = (reserve0 * (10**_token1MissingDecimals) * PRECISION) / reserve1;

            } else {
                _token1MissingDecimals = (IERC20Detailed(TOKEN).decimals()) - decimals;
                        // amountOut = (reserve0 * (10**_token1MissingDecimals) * PRECISION) / reserve1;
                amountOut = (reserve0 * PRECISION) / (reserve1 * (10**_token1MissingDecimals));

            }    
        }
        
        if(TOKEN != WETH) {
            amountOut = amountOut * provider.getSafePrice(TOKEN) / PRECISION;
        }
    }

    /**
     * @dev updates the TWAP (if enough time has lapsed) and returns the current safe price
     */
    function updateSafePrice(address asset) public returns (uint256 amountOut) {
        // This method will fail if the TWAP has not been initialized on this contract
        // This action must be performed externally
        (uint cumulativeLast, uint lastCumPrice, uint32 lastTimeSync, uint32 lastTimeUpdate) = _fetchParameters(asset);
        TwapConfig storage twap = twaps[asset];
        FixedPoint.uq112x112 memory lastAverage;
        lastAverage = FixedPoint.uq112x112(uint224((cumulativeLast - lastCumPrice) / (lastTimeSync - lastTimeUpdate)));
        if(lastTimeSync > lastTimeUpdate) {
            twap.lastUpdateTwapPrice = lastAverage;
            twap.lastUpdateCumulativePrice = cumulativeLast;
            twap.timestampLatest = lastTimeSync;
        }   
        twap.lastTimeTwapPoked = uint32(block.timestamp);

        // Call sub method HERE to same thing getSafePrice uses to avoid extra SLOAD
        amountOut = _convertPrice(asset, lastAverage);
    }

    /****** INTERNAL METHODS ******/

    function _convertPrice(address asset, FixedPoint.uq112x112 memory lastUpdatePrice) private view returns (uint amountOut) {
        uint nativeDecimals = 10**IERC20Metadata(asset).decimals();
        
        // calculate the value based upon the average cumulative prices
        // over the time period (TWAP)
        if (TOKEN == WETH) {
            // No need to convert the asset
            amountOut = lastUpdatePrice.mul(nativeDecimals).decode144();
        } else {
            // Need to convert the feed to be in terms of ETH
            uint8 tokenDecimals = 24 + IERC20Metadata(TOKEN).decimals();
            uint conversion = provider.getSafePrice(TOKEN);
            // amountOut = FixedPoint.uq112x112(uint112(lastUpdatePrice.mul(uint144(10**tokenDecimals)).decode144())).div(nativeDecimals).decode();
            amountOut = lastUpdatePrice.mul(10**tokenDecimals).decode144() * conversion / nativeDecimals;
        }
    }

    function _fetchParameters(
        address asset
    ) private view returns (
        uint cumulativeLast, 
        uint lastCumPrice, 
        uint32 lastTimeSync, 
        uint32 lastTimeUpdate
    ) {    
        TwapConfig memory twap = twaps[asset];
        require(twap.decimals > 0, 'ER035');
        // Enforce passage of a safe amount of time
        lastTimeUpdate = twap.timestampLatest;
        require(block.timestamp > twap.lastTimeTwapPoked + MIN_UPDATE, 'ER036');
        IUniswapV2Pair pair = IUniswapV2Pair(twap.pairAddress);
        cumulativeLast = twap.isToken0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
        lastCumPrice = twap.lastUpdateCumulativePrice;
        (, , lastTimeSync) = pair.getReserves();
    }

    /**
    * @dev Setup the twap for a new token to pair it to
    * @param asset token to initialize a twap for that is paired with TOKEN (WETH) 
    */
    function initializeOracle(address asset) external {
        require(asset != address(0), 'ER003');
        require(twaps[asset].decimals == 0, 'ER038');

        // Resolve Uniswap pair sorting order
        address token1 = asset < TOKEN ? TOKEN : asset;
        bool isToken0 = token1 != asset;
        address token0 = isToken0 ? asset : TOKEN;

        address pair = IUniswapV2Factory(uniswap).getPair(token0, token1);
        require(pair != address(0), 'ER003');
        IUniswapV2Pair uni_pair = IUniswapV2Pair(pair);        
        TwapConfig memory twap = TwapConfig(
            isToken0 ? uni_pair.price0CumulativeLast() : uni_pair.price1CumulativeLast(), 
            0,
            FixedPoint.uq112x112(0),
            pair, 
            isToken0, 
            IERC20Detailed(asset).decimals(),
            uint32(block.timestamp)
        );
        (, , twap.timestampLatest) = uni_pair.getReserves();
        twaps[asset] = twap;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IPriceProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProviderAwareOracle is IPriceOracle, Ownable {

    uint internal constant PRECISION = 1 ether;

    IPriceProvider public provider;

    event ProviderTransfer(address _newProvider, address _oldProvider);

    constructor(address _provider) {
        provider = IPriceProvider(_provider);
    }

    function setPriceProvider(address _newProvider) external onlyOwner {
        address oldProvider = address(provider);
        provider = IPriceProvider(_newProvider);
        emit ProviderTransfer(_newProvider, oldProvider);
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceProvider {

    event SetTokenOracle(address token, address oracle);

    function getSafePrice(address token) external view returns (uint256);

    function getCurrentPrice(address token) external view returns (uint256);

    function updateSafePrice(address token) external returns (uint256);

    /// Get value of an asset in units of quote
    function getValueOfAsset(address asset, address quote) external view returns (uint safePrice);

    function tokenHasOracle(address token) external view returns (bool hasOracle);

    function pairHasOracle(address token, address quote) external view returns (bool hasOracle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @dev Oracles should always return un the price in FTM with 18 decimals
interface IPriceOracle {
    /// @dev This method returns a flashloan resistant price.
    function getSafePrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external returns (uint256 _amountOut);
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