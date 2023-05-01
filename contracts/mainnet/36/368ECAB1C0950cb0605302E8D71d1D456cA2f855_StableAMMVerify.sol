// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "StableAMMLibrary.sol";

contract StableAMMVerify {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 decimalIn,
        uint256 decimalOut,
        uint256 fee,
        uint256 feeBase
    ) public pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        return
            StableAMMLibrary.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut,
                decimalIn,
                decimalOut,
                fee,
                feeBase
            );
    }

    function batchGetAmountOut(
        uint256[] memory amountIns,
        uint256[][] memory reserveIns,
        uint256[][] memory reserveOuts,
        uint256[][] memory decimalIns,
        uint256[][] memory decimalOuts,
        uint256[][] memory fees,
        uint256[][] memory feeBases
    ) external pure returns (uint256[] memory) {
        uint256[] memory amountOuts = new uint256[](amountIns.length);
        uint256 i = 0;
        while (i < amountIns.length) {
            uint256 j = 0;
            uint256 amountOut = amountIns[i];
            while (j < reserveIns[i].length) {
                amountOut = getAmountOut(
                    amountOut,
                    reserveIns[i][j],
                    reserveOuts[i][j],
                    decimalIns[i][j],
                    decimalOuts[i][j],
                    fees[i][j],
                    feeBases[i][j]
                );
                j++;
            }
            amountOuts[i] = amountOut;
            i++;
        }
        return amountOuts;
    }

    function batchGetAmountOutCall(
        uint256[] memory amountIns,
        uint256[][] memory reserveIns,
        uint256[][] memory reserveOuts,
        uint256[][] memory decimalIns,
        uint256[][] memory decimalOuts,
        uint256[][] memory fees,
        uint256[][] memory feeBases
    ) external returns (uint256[] memory) {
        uint256[] memory amountOuts = new uint256[](amountIns.length);
        uint256 i = 0;
        while (i < amountIns.length) {
            uint256 j = 0;
            uint256 amountOut = amountIns[i];
            while (j < reserveIns[i].length) {
                amountOut = getAmountOut(
                    amountOut,
                    reserveIns[i][j],
                    reserveOuts[i][j],
                    decimalIns[i][j],
                    decimalOuts[i][j],
                    fees[i][j],
                    feeBases[i][j]
                );
                j++;
            }
            amountOuts[i] = amountOut;
            i++;
        }
        return amountOuts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IStableAMMPair.sol";

import "SafeMath.sol";

library StableAMMLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "StableAMMLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "StableAMMLibrary: ZERO_ADDRESS");
    }

    function isSortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (bool)
    {
        require(tokenA != tokenB, "StableAMMLibrary: IDENTICAL_ADDRESSES");
        return tokenA < tokenB;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IStableAMMPair(pair)
            .getReserves();
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
        require(amountA > 0, "StableAMMLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "StableAMMLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function _k(
        uint256 x,
        uint256 y,
        uint256 decimalIn,
        uint256 decimalOut
    ) internal pure returns (uint256) {
        uint256 _x = (x * 1e18) / decimalIn;
        uint256 _y = (y * 1e18) / decimalOut;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18;
        // x3y+y3x >= k
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 decimalIn,
        uint256 decimalOut,
        uint256 fee,
        uint256 feeBase
    ) internal pure returns (uint256) {
        require(amountIn > 0, "StableAMMLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "StableAMMLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountIn = (amountIn * fee) / feeBase;
        // remove fee from amount received
        uint256 xy = _k(reserveIn, reserveOut, decimalIn, decimalOut);
        reserveIn = (reserveIn * 1e18) / decimalIn;
        reserveOut = (reserveOut * 1e18) / decimalOut;
        amountIn = (amountIn * 1e18) / decimalIn;
        uint256 y = reserveOut - _get_y(amountIn + reserveIn, xy, reserveOut);
        return (y * decimalOut) / 1e18;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOutByPair(
        address pair,
        uint256 amountIn,
        address[] memory path,
        uint256 decimalIn,
        uint256 decimalOut,
        uint256 fee,
        uint256 feeBase
    ) internal view returns (uint256) {
        require(path.length == 2, "StableAMMLibrary: INVALID_PATH");
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            pair,
            path[0],
            path[1]
        );
        return
            getAmountOut(
                amountIn,
                reserveIn,
                reserveOut,
                decimalIn,
                decimalOut,
                fee,
                feeBase
            );
    }

    function isStable(address _factory, address pair)
        internal
        view
        returns (bool)
    {
        return IStableAMMPair(pair).stable();
    }
}

pragma solidity >=0.5.0;

interface IStableAMMPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function stable() external pure returns (bool);
    function pairFee() external pure returns (uint256);
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

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}