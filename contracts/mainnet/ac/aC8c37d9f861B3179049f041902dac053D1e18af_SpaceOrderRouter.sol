// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/UniswapV2Library.sol";
import "../interfaces/IUniswapV2Pair.sol";

// Use second contract for router as allows try catch on external router calls from main contract to make cancelling failing swaps possible in same tx

contract SpaceOrderRouter {
    using SafeMath for uint256;
    
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { ETH_TOKEN, TOKEN_TOKEN, TOKEN_ETH }
    
    struct Order {
        uint256 id;                 // Order ID 
        uint256 pendingIndex;       // Index in pending order array
        address owner;              // Order placer 
        OrderStatus status;         // Order status 
        OrderType swapType;         // Order type
        address tokenIn;            // Token to swap 
        address tokenOut;           // Token to swap for
        uint256 amountIn;           // ETH Amount in 
        uint256 priceExecuted;    // Price to trigger order at 
        uint256 minAmountOut;       // Max price to trigger order at (in case price changed before tx has been mined)
        uint256 timestamp;
    }
    
    address public WETH;
    
    address authorizedCaller;
    

    constructor (address _WETH) {
        authorizedCaller = msg.sender;
        WETH = _WETH;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == authorizedCaller); _;
    }
    
    receive() external payable {
        assert(msg.sender == WETH);
    }
    

    function makeTokenTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        IERC20(tokenIn).transfer(pair, amountIn);
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    
     function makeTokenETHSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        IERC20(tokenIn).transfer(pair, amountIn);

        
        uint balanceBefore = IERC20(WETH).balanceOf(address(this));
        _swap(pair, tokenIn, tokenOut, address(this));
        
        uint amountOut = IERC20(WETH).balanceOf(address(this)).sub(balanceBefore);
        
        require(amountOut >= minAmountOut, 'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWETH(WETH).withdraw(amountOut);
        
        payable(owner).transfer(amountOut);
    }
    
    function makeETHTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external payable onlyAuthorized {
        // Swap bnb for WETH then transfer to pair
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        
        uint balanceBefore = IERC20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IERC20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'SpaceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    
    // function _swap(
    //     uint256[] memory amounts,
    //     address[] memory path,
    //     address _to
    // ) internal virtual {
    //     for (uint256 i; i < path.length - 1; i++) {
    //         (address input, address output) = (path[i], path[i + 1]);
    //         (address token0, ) = UniswapV2Library.sortTokens(input, output);
    //         uint256 amountOut = amounts[i + 1];
    //         (uint256 amount0Out, uint256 amount1Out) = input == token0
    //             ? (uint256(0), amountOut)
    //             : (amountOut, uint256(0));
    //         address to = i < path.length - 2
    //             ? UniswapV2Library.pairFor(factory, output, path[i + 2])
    //             : _to;
    //         IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
    //             .swap(amount0Out, amount1Out, to, new bytes(0));
    //     }
    // }
    function _swap(
        address _pair,
        address tokenIn,
        address tokenOut,
        address to
    ) internal virtual {
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        uint amountInput;
        uint amountOutput;
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(tokenIn).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);

        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            // hex"966a963e3b25b66a576eb88e424b7615304e3e0b136a99fcf39cd343c6baa72f" // UniswapV2Pair bytecode hash
                            hex"9d5ddce9e360e6ed1fb3230c538363b64a1970f93e8539e959a827e0f6aedc68" // UniswapV2Pair bytecode hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997); // 99.7 || 1* 997
        uint256 numerator = amountInWithFee.mul(reserveOut); //99.7 * 100 = 9970 || 997 * 100 = 99700
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee); // 1000+99.7 = 1099.7 || 1000+997 = 1997
        amountOut = numerator / denominator; // 99700 / 1997
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {

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