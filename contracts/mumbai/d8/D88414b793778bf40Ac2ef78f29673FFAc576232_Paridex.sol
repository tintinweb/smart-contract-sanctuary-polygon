/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// File: ITrigger.sol



pragma solidity ^0.8.7;

interface ITrigger {
    function trigger(address[] calldata _factories, uint[] memory amounts, address[] memory path, address _to) external returns (bool);
}
// File: IAnyOracle.sol



pragma solidity ^0.8.7;

interface IAnyOracle {
    function update(uint _period, address _tokenA, address _tokenB) external returns (uint256 price0TotalAvg, uint256 price1TotalAvg, bool aToBswitch);
    function update(address _tokenA, address _tokenB) external returns (uint256 price0PTotalAvg, uint256 price1TotalAvg, bool aToBswitch);
    function refreshPeriodsAvg(address _tokenA, address _tokenB) external returns (uint256 price0PTotalAvg, uint256 price1TotalAvg, bool aToBswitch);
    function updateNRefresh(uint _period, address _tokenA, address _tokenB) external returns (uint256 price0TotalAvg, uint256 price1TotalAvg, bool aToBswitch);
    function consult(address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint amountOut);
    function consult(uint _period, address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256 amountOut);
    function consultByFactory(uint _period, address _factory, address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256 amountOut);
    function getFactories() external view returns (address[] memory);
    function getPeriods() external view returns (uint256[] memory);
    function getPeriod(uint _index) external view returns (uint256);
    function getFactoriesSorted(uint _period, address _tokenA, address _tokenB, bool _desc) external view returns (address[] memory);
    function getFactoryData(uint _period, address _factory, address _tokenA, address _tokenB, uint256 Ain, uint256 Bout) external view returns (uint256 reserve0, uint256 reserve1, uint256 price0Avg, uint256 price1Avg, uint256 maxProfitableIn, bool aToB);
    function getFactoryData(uint _period, address _factory, address _tokenA, address _tokenB) external view returns (uint256 reserve0, uint256 reserve1, uint256 price0Avg, uint256 price1Avg, uint256 maxProfitableIn, bool aToB);
    function getBestFactory(uint _period, address _tokenA, address _tokenB) external view returns (address, uint);
    function getBestFactoryAsPair(uint _period, address _tokenA, address _tokenB) external view returns (address, uint);
    function addFactory(address _factory, string memory _key) external returns (bool);
    function removeFactory(address _factory, string memory _key) external returns (bool);
    function setParidex(address _paridex, string[] memory _key) external returns (bool);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: ILeva.sol



pragma solidity ^0.8.7;



interface ILeva is IERC20, IERC20Metadata {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burnNGet(uint256 _amount) external returns (uint256);
    function burnFromNGet(address _account, uint256 _amount) external returns (uint256);
    function mint(address _to, uint256 _amount) external returns (bool);
    function getPeg() external view returns (address);
    function rePeg(address _pegOracle, string memory _key) external returns (bool);
    function setParidex(address _paridex, string[] memory _key) external returns (bool);
}
// File: IPari.sol



pragma solidity ^0.8.7;



interface IPari is IERC20, IERC20Metadata {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burnNGet(address _leva, uint256 _amount) external returns (uint256);
    function burnFromNGet(address _leva, address _account, uint256 _amount) external returns (uint256);
    function mint(address _to, uint256 _amount) external returns (bool);
    function manMint(address _to, uint256 _amount, string memory _key) external returns (bool);
    function setParidex(address _paridex, string[] memory _key) external returns (bool);
}
// File: IParidex.sol



pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

interface IParidex {
    function isMan(string calldata _key) external returns (bool);
    function isPari(address _pari) external returns (bool);
    function isLeva(address _leva) external returns (bool);
    function getPari() external returns (address);
    function getLevaList() external returns (address[] memory);
    function consultLeva2Usd(address _leva, uint256 _amount) external returns (uint256);
    function consultPari2Usd(uint256 _amount) external returns (uint256);
    function consultPari2Leva(address _leva, uint256 _pariAmount) external returns (uint256);
    function consultLeva2Pari(address _leva, uint256 _levaAmount) external returns (uint256);
    function consultLeva2Leva(address _levaIn, address _levaOut, uint256 _levaInAmount) external returns (uint256);
    function consultSmart(address _inToken, address _outToken, uint256 _inAmount) external returns (uint256);
    function swapPari2Leva(address _leva, uint256 _pariAmount, uint256 _minLevaAmount) external returns (uint256 out);
    function swapLeva2Pari(address _leva, uint256 _levaAmount, uint256 _minPariAmount) external returns (uint256 out);
    function swapLeva2Leva(address _levaIn, address _levaOut, uint256 _levaAmount, uint256 _minLevaAmount) external returns (uint256 out);
    function swapSmart(address _inToken, address _outToken, uint256 _inAmount, uint256 _minOutAmount) external returns (uint256 out);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint steps, uint deadline) external returns (uint[] memory amounts, address[] memory factories);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint steps, uint deadline) external returns (uint[] memory amounts, address[] memory factories);
    function stabilize(address _sender, address _taker, uint _amount) external returns (uint revenue, address[] memory factories);
    function arbitrage(address _token, uint _amount, address _middleToken) external returns (uint revenue, address[] memory factories);
    function addLeva(address _leva, string calldata _key) external returns (bool);
    function removeLeva(address _leva, string calldata _key) external returns (bool);
    function changePari(address _pari, string calldata _key) external returns (bool);
    function changeStableCoin2Usd(address _stablecoin2usd, string calldata _key) external returns (bool);
    function changeSTABLECOIN(address _STABLECOIN, string calldata _key) external returns (bool);
    function changeAnyOracle(address _anyOracle, string calldata _key) external returns (bool);
    function changeTrigger(address _trigger, string calldata _key) external returns (bool);
    function changeManKey(string[] calldata _manKey) external returns (bool);
    function migrate(address _newInstance, string[] calldata _manKey) external returns (bool);
}
// File: include/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// File: include/SafeMath.sol



pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol



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

// File: include/UniswapV2Library.sol



pragma solidity >=0.5.0;




library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
        if(isContract(pair)) {
            return pair;
        } else {
            try IUniswapV2Factory(factory).getPair(token0, token1) returns (address _pair) {
                if(isContract(_pair)) {
                    return _pair;
                } else {
                    return address(0);
                }
            } catch (bytes memory) {
                return address(0);
            }
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        if(pair == address(0)) {
            return (0, 0);
        }
        try IUniswapV2Pair(pair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        } catch (bytes memory) {
            (reserveA, reserveB) = (0, 0);
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs and with different factories
    function getAmountsOut(address[] memory factories, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factories[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs and with different factories
    function getAmountsIn(address[] memory factories, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factories[i - 1], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function isContract(address _addr) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// File: Paridex.sol



pragma solidity ^0.8.7;









 
contract Paridex {
    address public STABLECOIN = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    
    string[] private manKey;
    uint256 private manIteration = 0;
    address public pari;
    address[] public levaList;
    address public anyOracle;
    address public trigger;
    address public instance;

    address public stablecoin2usd;

    event Converted(address indexed _token0, address indexed _token1, uint256 _amount, uint256 _out);
    event Swapped(address indexed _token0, address indexed _token1, uint256 _amount, uint256 _out);
    event LevaAdded(address indexed _leva);
    event LevaRemoved(address indexed _leva);
    event PariChanged(address indexed _newPari);
    event StableCoin2UsdChanged(address indexed _newStableCoin2Usd);
    event STABLECOINChanged(address indexed _newSTABLECOIN);
    event AnyOracleChanged(address indexed _newAnyOracle);
    event TriggerChanged(address indexed _newTrigger);
    event Migrated(address indexed _newInstance);
    
    constructor(string[] memory _manKey, address _pari, address[] memory _levaList, address _stablecoin2usd, address _anyOracle) {
        manKey = _manKey;
        pari = _pari;
        levaList = _levaList;
        stablecoin2usd = _stablecoin2usd;
        anyOracle = _anyOracle;
        instance = address(this);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
        return msg.data;
    }

    function isMan(string memory _key) public returns (bool) {
        if(keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked(manKey[manIteration % manKey.length]))) {
            manIteration++;
            return true;
        } else return false;
    }

    function isPari(address _pari) public view returns (bool) {
        return pari == _pari;
    }

    function isLeva(address _leva) public view returns (bool) {
        for (uint256 i = 0; i < levaList.length; i++) {
            if (_leva == levaList[i]) {
                return true;
            }
        }
        return false;
    }

    function getPari() public view returns (address) {
        return pari;
    }

    function getLevaList() public view returns (address[] memory) {
        return levaList;
    }

    function _onlyMan(string memory _key) internal {
        require(isMan(_key), "ONLY_MANAGER");
    }

    modifier onlyMan(string memory _key) {
        _onlyMan(_key);
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    function isContract(address _addr) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function consultLeva2Usd(address _leva, uint256 _amount) public view returns (uint256) {
        require(isLeva(_leva), "NO_LEVA");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(ILeva(_leva).getPeg());
        uint8 decimals = priceFeed.decimals();
        (, int256 Leva2USD, , , ) = priceFeed.latestRoundData();

        return uint256(_amount * uint256(Leva2USD) / 10 ** decimals);
    }

    function consultPari2Usd(uint256 _amount) public view returns (uint256) {
        uint256 pari2stablecoin = IAnyOracle(anyOracle).consult(0, pari, STABLECOIN, _amount);
        AggregatorV3Interface stablecoin2usdFeed = AggregatorV3Interface(stablecoin2usd);
        uint8 decimals = stablecoin2usdFeed.decimals();
        (, int256 stablecoin2usdPrice, , , ) = stablecoin2usdFeed.latestRoundData();

        return uint256(pari2stablecoin * uint256(stablecoin2usdPrice) / 10 ** decimals);
    }

    function consultPari2Leva(address _leva, uint256 _pariAmount) public view returns (uint256) {
        uint256 pari2usd = consultPari2Usd(_pariAmount);
        uint256 leva2usd = consultLeva2Usd(_leva, 1e18);

        return pari2usd * 1e18 / leva2usd;
    }

    function consultLeva2Pari(address _leva, uint256 _levaAmount) public view returns (uint256) {
        uint256 leva2usd = consultLeva2Usd(_leva, _levaAmount);
        uint256 pari2usd = consultPari2Usd(1e18);

        return leva2usd * 1e18 / pari2usd;
    }

    function consultLeva2Leva(address _levaIn, address _levaOut, uint256 _levaInAmount) public view returns (uint256) {
        uint256 levaIn2usd = consultLeva2Usd(_levaIn, _levaInAmount);
        uint256 levaOut2usd = consultLeva2Usd(_levaOut, 1e18);

        return levaIn2usd * 1e18 / levaOut2usd;
    }

    function consultSmart(address _inToken, address _outToken, uint256 _inAmount) public view returns (uint256) {
        if(isLeva(_inToken) && isLeva(_outToken)) {
            return consultLeva2Leva(_inToken, _outToken, _inAmount);
        } else if(isLeva(_inToken) && isPari(_outToken)) {
            return consultLeva2Pari(_inToken, _inAmount);
        } else if(isPari(_inToken) && isLeva(_outToken)) {
            return consultPari2Leva(_outToken, _inAmount);
        } else {
            return 0;
        }
    }

    function _swapPari2Leva(address _from, address _leva, uint256 _pariAmount, uint256 _minLevaAmount) internal returns (uint256 out) {
        out = IPari(pari).burnFromNGet(_leva, _from, _pariAmount);
        if(out < _minLevaAmount) return 0;

        emit Converted(pari, _leva, _pariAmount, out);
    }

    function _swapLeva2Pari(address _from, address _leva, uint256 _levaAmount, uint256 _minPariAmount) internal returns (uint256 out) {
        out = ILeva(_leva).burnFromNGet(_from, _levaAmount);
        if(out < _minPariAmount) return 0;

        emit Converted(_leva, pari, _levaAmount, out);
    }

    function _swapLeva2Leva(address _from, address _levaIn, address _levaOut, uint256 _levaAmount, uint256 _minLevaAmount) internal returns (uint256 out) {
        out = ILeva(_levaIn).burnFromNGet(_from, _levaAmount);
        out = IPari(pari).burnFromNGet(_levaOut, _from, out);
        if(out < _minLevaAmount) return 0;

        emit Converted(_levaIn, _levaOut, _levaAmount, out);
    }

    function _swapSmart(address _from, address _inToken, address _outToken, uint256 _inAmount, uint256 _minOutAmount) internal returns (uint256 out) {
        if(isLeva(_inToken) && isLeva(_outToken)) {
            out = _swapLeva2Leva(_from, _inToken, _outToken, _inAmount, _minOutAmount);
        } else if(isLeva(_inToken) && isPari(_outToken)) {
            out = _swapLeva2Pari(_from, _inToken, _inAmount, _minOutAmount);
        } else if(isPari(_inToken) && isLeva(_outToken)) {
            out = _swapPari2Leva(_from, _outToken, _inAmount, _minOutAmount);
        } else {
            return 0;
        }
    }

    function swapPari2Leva(address _leva, uint256 _pariAmount, uint256 _minLevaAmount) external returns (uint256 out) {
        out = _swapPari2Leva(_msgSender(), _leva, _pariAmount, _minLevaAmount);
        require(out != 0 && out >= _minLevaAmount, "LOW_OUT_OR_NOLEVAORPARI");
    }

    function swapLeva2Pari(address _leva, uint256 _levaAmount, uint256 _minPariAmount) external returns (uint256 out) {
        out = _swapLeva2Pari(_msgSender(), _leva, _levaAmount, _minPariAmount);
        require(out != 0 && out >= _minPariAmount, "LOW_OUT_OR_NOLEVAORPARI");
    }

    function swapLeva2Leva(address _levaIn, address _levaOut, uint256 _levaAmount, uint256 _minLevaAmount) external returns (uint256 out) {
        out = _swapLeva2Leva(_msgSender(), _levaIn, _levaOut, _levaAmount, _minLevaAmount);
        require(out != 0 && out >= _minLevaAmount, "LOW_OUT_OR_NOLEVA");
    }

    function swapSmart(address _inToken, address _outToken, uint256 _inAmount, uint256 _minOutAmount) external returns (uint256 out) {
        out = _swapSmart(_msgSender(), _inToken, _outToken, _inAmount, _minOutAmount);
        require(out != 0 && out >= _minOutAmount, "LOW_OUT_OR_NOLEVAORPARI");
    }

    function _swap(address[] memory _factories, uint[] memory amounts, address[] memory path, address _to) internal returns (uint[] memory) {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address pair = UniswapV2Library.pairFor(_factories[i], input, output);
            require(pair != address(0), "NO_PAIR");
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(_factories[i + 1], output, path[i + 2]) : _to;
            require(to != address(0), "INVALID_TO_OR_PATH");
            if(consultSmart(input, output, amounts[i]) < amounts[i + 1]) {
                (address token0,) = UniswapV2Library.sortTokens(input, output);
                IUniswapV2Pair(pair).swap(
                    input == token0 ? uint(0) : amounts[i + 1], input == token0 ? amounts[i + 1] : uint(0), to, new bytes(0)
                );
                IAnyOracle ao = IAnyOracle(anyOracle);
                ao.update(0, input, output);

                emit Swapped(input, output, amounts[i], amounts[i + 1]);
            } else {
                amounts[i + 1] = _swapSmart(pair, input, output, amounts[i], amounts[i + 1]);
                TransferHelper.safeTransferFrom(output, pair, to, amounts[i + 1]);
            }
        }

        if(isContract(trigger)) {
            ITrigger(trigger).trigger(_factories, amounts, path, _to);
        }

        return amounts;
    }

    function _swapExactTokensForTokens(
        address _sender,
        address[] memory _factories,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint steps
    ) internal returns (uint[] memory amountsTotal) {
        amountsTotal = new uint[](path.length);
        uint[] memory amounts;
        steps = steps == 0 ? _factories.length : steps;
        for(uint i = 0; i < steps; i++) {
            amounts = UniswapV2Library.getAmountsOut(_factories, amountIn / steps, path);
            require(amounts[amounts.length - 1] >= amountOutMin / steps, "LOW_OUT");
            TransferHelper.safeTransferFrom(
                path[0], _sender, UniswapV2Library.pairFor(_factories[0], path[0], path[1]), amounts[0]
            );
            amounts = _swap(_factories, amounts, path, to);
            for(uint j = 0; j < amounts.length; j++) {
                amountsTotal[j] += amounts[j];
            }
        }
    }

    function _swapTokensForExactTokens(
        address _sender,
        address[] memory _factories,
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        uint steps
    ) internal returns (uint[] memory amountsTotal) {
        amountsTotal = new uint[](path.length);
        uint[] memory amounts;
        steps = steps == 0 ? _factories.length : steps;
        for(uint i = 0; i < steps; i++) {
            amounts = UniswapV2Library.getAmountsIn(_factories, amountOut / steps, path);
            require(amounts[0] <= amountInMax / steps, "EXCESSIVE_INPUT");
            TransferHelper.safeTransferFrom(
                path[0], _sender, UniswapV2Library.pairFor(_factories[0], path[0], path[1]), amounts[0]
            );
            amounts = _swap(_factories, amounts, path, to);
            for(uint j = 0; j < amounts.length; j++) {
                amountsTotal[j] += amounts[j];
            }
        }
    }

    function _getBestFactories(address[] memory _path) internal view returns (address[] memory factories) {
        for(uint i = 0; i < _path.length - 1; i++) {
            (factories[i], ) = IAnyOracle(anyOracle).getBestFactory(0, _path[i], _path[i + 1]);
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint steps,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts, address[] memory factories) {
        factories = _getBestFactories(path);
        amounts = _swapExactTokensForTokens(_msgSender(), factories, amountIn, amountOutMin, path, to, steps);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint steps,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts, address[] memory factories) {
        factories = _getBestFactories(path);
        amounts = _swapTokensForExactTokens(_msgSender(), factories, amountOut, amountInMax, path, to, steps);
    }

    function _arbitrage(address _sender, address _taker, address _token, uint _amount, address _middleToken) internal returns (uint revenue, address[] memory factories) {
        address[] memory path = new address[](3);
        path[0] = _token;
        path[1] = _middleToken == address(0) ? STABLECOIN : _middleToken;
        path[2] = _token;
        factories = _getBestFactories(path);
        uint[] memory amounts = _swapExactTokensForTokens(_sender, factories, _amount, 0, path, _taker, 0);
        require(amounts[2] >= _amount, "LOSS");
        revenue = amounts[2] - _amount;
    }

    function arbitrage(address _token, uint _amount, address _middleToken) external returns (uint revenue, address[] memory factories) {
        (revenue, factories) = _arbitrage(_msgSender(), _msgSender(), _token, _amount, _middleToken);
    }

    function stabilize(address _sender, address _taker, uint _amount) external returns (uint revenue, address[] memory factories) {
        if(isLeva(_msgSender())) {
            (revenue, factories) = _arbitrage(_sender, _taker, _msgSender(), _amount, pari);
        } else if(isPari(_msgSender())) {
            (revenue, factories) = _arbitrage(_sender, _taker, _msgSender(), _amount, levaList[uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, _amount))) % levaList.length]);
        } else {
            revert("INVALID CALLER");
        }
    }

    function addLeva(address _leva, string memory _key) public onlyMan(_key) returns (bool) {
        for (uint256 i = 0; i < levaList.length; i++) {
            require(_leva != levaList[i], "EXISTS");
        }
        levaList.push(_leva);

        emit LevaAdded(_leva);

        return true;
    }

    function removeLeva(address _leva, string memory _key) public onlyMan(_key) returns (bool) {
        for (uint256 i = 0; i < levaList.length; i++) {
            if (levaList[i] == _leva) {
                levaList[i] = levaList[levaList.length - 1];
                levaList.pop();

                emit LevaRemoved(_leva);

                return true;
            }
        }
        return false;
    }

    function changePari(address _pari, string memory _key) public onlyMan(_key) returns (bool) {
        pari = _pari;

        emit PariChanged(_pari);

        return true;
    }

    function changeStableCoin2Usd(address _stablecoin2usd, string memory _key) public onlyMan(_key) returns (bool) {
        stablecoin2usd = _stablecoin2usd;

        emit StableCoin2UsdChanged(_stablecoin2usd);
        
        return true;
    }

    function changeSTABLECOIN(address _STABLECOIN, string memory _key) public onlyMan(_key) returns (bool) {
        STABLECOIN = _STABLECOIN;

        emit STABLECOINChanged(_STABLECOIN);

        return true;
    }

    function changeAnyOracle(address _anyOracle, string memory _key) public onlyMan(_key) returns (bool) {
        anyOracle = _anyOracle;

        emit AnyOracleChanged(_anyOracle);

        return true;
    }

    function changeTrigger(address _trigger, string memory _key) public onlyMan(_key) returns (bool) {
        trigger = _trigger;

        emit TriggerChanged(_trigger);

        return true;
    }

    function changeManKey(string[] memory _manKey) public onlyMan(_manKey[0]) returns (bool) {
        _onlyMan(_manKey[1 % _manKey.length]);
        _onlyMan(_manKey[2 % _manKey.length]);
        manKey = _manKey;
        return true;
    }

    function migrate(address _newInstance, string[] memory _manKey) public onlyMan(_manKey[0]) returns (bool) {
        require(_newInstance != address(0), "ZERO_ADDRESS");
        require(_newInstance != instance, "SAME");
        _onlyMan(_manKey[1 % _manKey.length]);
        _onlyMan(_manKey[2 % _manKey.length]);
        
        require(IPari(pari).setParidex(_newInstance, _manKey) == true, "PARI_MIG_FAIL");
        require(IAnyOracle(anyOracle).setParidex(_newInstance, _manKey) == true, "AO_MIG_FAIL");
        for (uint256 i = 0; i < levaList.length; i++) {
            require(ILeva(levaList[i]).setParidex(_newInstance, _manKey) == true, "LEVA_MIG_FAIL");
        }

        instance = _newInstance;

        emit Migrated(_newInstance);

        return true;
    }
}

/*

*/