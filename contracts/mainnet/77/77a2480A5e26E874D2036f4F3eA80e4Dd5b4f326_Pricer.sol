// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./FullMath.sol";

library Babylonian {

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {

    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}


library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
    
    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

// https://uniswap.org/docs/v2/smart-contracts/factory/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.solimplementation
// SPDX-License-Identifier: MIT
// UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// https://uniswap.org/docs/v2/smart-contracts/pair/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol implementation
// SPDX-License-Identifier: MIT

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
  
}

// https://uniswap.org/docs/v2/smart-contracts/router01/
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router01.sol implementation
// UniswapV2Router01 is deployed at 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// https://uniswap.org/docs/v2/smart-contracts/router02/
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol implementation
// UniswapV2Router02 is deployed at 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets.

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

// You can add this typing "uniV2Router01" 
import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '../lib/int/IUniswapV2Pair.sol';
import '../lib/int/IUniswapV2Factory.sol';
import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB)).getReserves(); 
        //changed how it gets the pair address to avoid having fixed init code hash
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../lib/int/IUniswapV2Factory.sol";
import "../lib/int/IUniswapV2Pair.sol";
import "../lib/int/IUniswapV2Router02.sol";
import "../lib/SafeMath.sol";
import "../lib/FixedPoint.sol";
import "../lib/FullMath.sol";
import "../lib/UniswapV2Library.sol";

contract Pricer {
    using SafeMath for uint;
    using FixedPoint for uint224;
    
    function getFactoryRouter(address router) public pure returns(address factory){ //works
        IUniswapV2Router02 Router = IUniswapV2Router02(router);
        factory = Router.factory();
    }

    
    function getFactoryPair(address pair) public view returns(address factory){ //works
        factory =  IUniswapV2Pair(pair).factory();
    }

    function getPair(address token0, address token1, address router) external view returns(address pair){ //works 
        address factory = getFactoryRouter(router);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    function getRatio(address tokenIn, uint amountIn, address tokenOut, address _quoteToken, address router) public view returns(uint ratio){ //SHOULD WORK
        IUniswapV2Router02 Router = IUniswapV2Router02(router);

        address[] memory path;
        path = new address[](3);
        path[0] = tokenIn;
        path[1] = _quoteToken;
        path[2] = tokenOut;

        uint[] memory amounts = Router.getAmountsOut(amountIn, path);

        ratio = FixedFraction(amounts[2], amountIn); //returns the ratio between the two tokens with 18 decimals precision

    }

    function getAmtOut(uint amountIn, address token0, address token1, address router) public view returns(uint amoutOut){ //WORKS
        IUniswapV2Router02 Router = IUniswapV2Router02(router);

        address[] memory path;
        path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint[] memory amounts = Router.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint kLast
    ) public pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator1 = totalSupply;
                uint numerator2 = rootK.sub(rootKLast);
                uint denominator = rootK.mul(5).add(rootKLast);
                uint feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        return (reservesA.mul(liquidityAmount) / totalSupply, reservesB.mul(liquidityAmount) / totalSupply);
    }

    function getLiquidityValue(address factory, address tokenA, address tokenB, uint256 liquidityAmount) public view 
    returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint reservesA, uint reservesB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB));
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        uint kLast = feeOn ? pair.kLast() : 0;
        uint totalSupply = pair.totalSupply();
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    function getLpTokens(address lp) public view returns(address token0, address token1){ //WORKS
        IUniswapV2Pair pair = IUniswapV2Pair(lp);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function getLpTokensAmount(address lp, uint amountLp) public view returns (address tokenA, uint amountA, address tokenB, uint amountB){
        address factory = IUniswapV2Pair(lp).factory();
        (tokenA, tokenB) = getLpTokens(lp);
        (amountA, amountB) = getLiquidityValue(factory, tokenA, tokenB, amountLp);
    }

    function getBondRatio(address tokenIn, uint amountIn, address tokenOut, address _quoteToken, address router, bool isLpBond) external view returns(uint ratio){

        if (isLpBond){
            (address tokenA, uint amountA, address tokenB, uint amountB) = getLpTokensAmount(tokenIn, amountIn);
            if (tokenA == tokenOut){
                uint sum = amountA.add(getAmtOut(amountB, tokenB, _quoteToken, router));
                ratio = FixedFraction(sum, amountIn);
            }
            else if (tokenB == tokenOut){
                uint sum = amountB.add(getAmtOut(amountA, tokenA, _quoteToken, router));
                ratio = FixedFraction(sum, amountIn);
            }
            else { uint sum;
            if (tokenA == _quoteToken){
                sum = getAmtOut(amountA, tokenA, tokenOut, router); //get amount of tokenOut for amtTknA
                uint amountQuote = (getAmtOut(amountB, tokenB, _quoteToken, router)); //get amount of _quoteToken for amtTokB
                sum = sum.add(getAmtOut(amountQuote, _quoteToken, tokenOut, router));
              
            }
            else if (tokenB == _quoteToken){
                sum = getAmtOut(amountB, tokenB, tokenOut, router); //get amount of tokenOut for amtTknA
                uint amountQuote = (getAmtOut(amountA, tokenA, _quoteToken, router)); //get amount of _quoteToken for amtTokB
                sum = sum.add(getAmtOut(amountQuote, _quoteToken, tokenOut, router));

            }
            else {
                uint amountQuote = getAmtOut(amountA, tokenA, _quoteToken, router); //get amount of tokenOut for amtTknA
                amountQuote = amountQuote.add(getAmtOut(amountB, tokenB, _quoteToken, router)); //get amount of tokenOut for amtTknA
                sum = getAmtOut(amountQuote, _quoteToken, tokenOut, router);
            }
        
            ratio = FixedFraction(sum, amountIn);}
        }
        if (!isLpBond){
            if (tokenIn == _quoteToken || tokenOut == _quoteToken){
                uint amountOut = getAmtOut(amountIn, tokenIn, tokenOut, router);
                ratio = FixedFraction(amountOut, amountIn);
            }

            else{
            ratio = getRatio(tokenIn, amountIn, tokenOut, _quoteToken, router);
            }
        }
    }

    function getBondPrice(address tokenIn, uint amountIn, address tokenOut, address _quoteToken, address router, bool isLpBond) external{

    }

    function FixedFraction(uint numerator, uint denominator) internal pure returns(uint result){
        FixedPoint.uq112x112 memory resultEnc = FixedPoint.fraction(numerator, denominator);
        result = FixedPoint.decode112with18(resultEnc);
    }

}