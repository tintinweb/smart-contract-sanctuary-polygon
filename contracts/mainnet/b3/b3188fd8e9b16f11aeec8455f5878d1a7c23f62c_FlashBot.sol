//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import 'IERC20.sol';
import 'ERC20.sol';
import 'SafeERC20.sol';
import 'EnumerableSet.sol';
import 'Initializable.sol';
import 'console.sol';

import 'IUniswapV2Pair.sol';
import 'IWETH.sol';
import 'Decimal.sol';
import 'ContractOwnable.sol';
import 'SafeMath.sol';

struct OrderedReserves {
    uint256 a1; // base asset
    uint256 b1;
    uint256 a2;
    uint256 b2;
}

struct ArbitrageInfo {
    address baseToken;
    address quoteToken;
    bool baseTokenSmaller;
    address lowerPool; // pool with lower price, denominated in quote asset
    address higherPool; // pool with higher price, denominated in quote asset
}

struct CallbackData {
    address debtPool;
    address targetPool;
    bool debtTokenSmaller;
    address borrowedToken;
    address debtToken;
    uint256 debtAmount;
    uint256 debtTokenOutAmount;
}

contract FlashBot is ContractOwnable, Initializable {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint constant private _PRECISION = 10000;
    address constant private _TETUSWAP_FACTORY = 0x684d8c187be836171a1Af8D533e4724893031828;


    // WETH on ETH or WBNB on BSC, WMATIC on Polygon
    address public WETH;

    // AVAILABLE BASE TOKENS
    EnumerableSet.AddressSet baseTokens;

    event Withdrawn(address indexed to, uint256 indexed value);
    event BaseTokenAdded(address indexed token);
    event BaseTokenRemoved(address indexed token);

    constructor(address _WETH, address[] memory _baseTokens) {
        //TODO remove for proxy deploy (add fixture to test first)
        initialize(_WETH, _baseTokens);
    }

    function initialize(address _WETH, address[] memory _baseTokens) public {
        if (_msgSender()!=address(0)) return;
        initOwner(_msgSender());
        WETH = _WETH;
        baseTokens.add(_WETH);
        for (uint256 i=0; i<_baseTokens.length; i++) {
            addBaseToken(_baseTokens[i]);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(getOwner()).transfer(balance);
            emit Withdrawn(getOwner(), balance);
        }

        for (uint256 i = 0; i < baseTokens.length(); i++) {
            address token = baseTokens.at(i);
            balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                // do not use safe transfer here to prevents revert by any shitty token
                IERC20(token).transfer(getOwner(), balance);
            }
        }
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance >= amount) {
            IERC20(token).transfer(getOwner(), amount);
        } else {
            IERC20(token).transfer(getOwner(), balance);
        }
    }

    function addBaseToken(address token) public onlyOwner {
        baseTokens.add(token);
        emit BaseTokenAdded(token);
    }

    function removeBaseToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            // do not use safe transfer to prevents revert by any shitty token
            IERC20(token).transfer(getOwner(), balance);
        }
        baseTokens.remove(token);
        emit BaseTokenRemoved(token);
    }

    function getBaseTokens() external view returns (address[] memory tokens) {
        uint256 length = baseTokens.length();
        tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = baseTokens.at(i);
        }
    }

    function isBaseTokenSmaller(address pool0, address pool1)
        internal
        view
        returns (
            bool baseSmaller,
            address baseToken,
            address quoteToken
        )
    {
        require(pool0 != pool1, 'BOT: Same pair address');
        (address pool0Token0, address pool0Token1) = (IUniswapV2Pair(pool0).token0(), IUniswapV2Pair(pool0).token1());
        (address pool1Token0, address pool1Token1) = (IUniswapV2Pair(pool1).token0(), IUniswapV2Pair(pool1).token1());
        require(pool0Token0 < pool0Token1 && pool1Token0 < pool1Token1, 'BOT: Non standard uniswap AMM pair');
        require(pool0Token0 == pool1Token0 && pool0Token1 == pool1Token1, 'BOT: Require same token pair');
        require(baseTokens.contains(pool0Token0) || baseTokens.contains(pool0Token1), 'BOT: No base token in pair');

        (baseSmaller, baseToken, quoteToken) = baseTokens.contains(pool0Token0)
            ? (true, pool0Token0, pool0Token1)
            : (false, pool0Token1, pool0Token0);
    }

    /// @dev Compare price denominated in quote token between two pools
    /// We borrow base token by using flash swap from lower price pool and sell them to higher price pool
    function getOrderedReserves(
        address pool0,
        address pool1,
        bool baseTokenSmaller
    )
        internal
        view
        returns (
            address lowerPool,
            address higherPool,
            OrderedReserves memory orderedReserves
        )
    {
        (uint256 pool0Reserve0, uint256 pool0Reserve1, ) = IUniswapV2Pair(pool0).getReserves();
        (uint256 pool1Reserve0, uint256 pool1Reserve1, ) = IUniswapV2Pair(pool1).getReserves();

        // Calculate the price denominated in quote asset token
        (Decimal.D256 memory price0, Decimal.D256 memory price1) =
            baseTokenSmaller
                ? (Decimal.from(pool0Reserve0).div(pool0Reserve1), Decimal.from(pool1Reserve0).div(pool1Reserve1))
                : (Decimal.from(pool0Reserve1).div(pool0Reserve0), Decimal.from(pool1Reserve1).div(pool1Reserve0));

        // get a1, b1, a2, b2 with following rule:
        // 1. (a1, b1) represents the pool with lower price, denominated in quote asset token
        // 2. (a1, a2) are the base tokens in two pools
        if (price0.lessThan(price1)) {
            (lowerPool, higherPool) = (pool0, pool1);
            (orderedReserves.a1, orderedReserves.b1, orderedReserves.a2, orderedReserves.b2) = baseTokenSmaller
                ? (pool0Reserve0, pool0Reserve1, pool1Reserve0, pool1Reserve1)
                : (pool0Reserve1, pool0Reserve0, pool1Reserve1, pool1Reserve0);
        } else {
            (lowerPool, higherPool) = (pool1, pool0);
            (orderedReserves.a1, orderedReserves.b1, orderedReserves.a2, orderedReserves.b2) = baseTokenSmaller
                ? (pool1Reserve0, pool1Reserve1, pool0Reserve0, pool0Reserve1)
                : (pool1Reserve1, pool1Reserve0, pool0Reserve1, pool0Reserve0);
        }
        console.log('-Buy from pool:', lowerPool);
        console.log('-Sell  to pool:', higherPool);
    }

    /// @notice Do an arbitrage between two Uniswap-like AMM pools
    /// @dev Two pools must contains same token pair
    function swap(address pool0, address pool1) external returns (bool){
        ArbitrageInfo memory info;
        (info.baseTokenSmaller, info.baseToken, info.quoteToken) = isBaseTokenSmaller(pool0, pool1);

        OrderedReserves memory orderedReserves;
        (info.lowerPool, info.higherPool, orderedReserves) = getOrderedReserves(pool0, pool1, info.baseTokenSmaller);

        uint256 balanceBefore = IERC20(info.baseToken).balanceOf(address(this));
        console.log('-balanceBefore', balanceBefore);

        // avoid stack too deep error
        {
            uint256 fee1 = getFee(info.lowerPool);
            console.log('-fee1', fee1);
            uint256 startAmount = balanceBefore;
            console.log('-startAmount', startAmount);
            uint256 quoteOutAmount = getAmountOut(startAmount, orderedReserves.a1, orderedReserves.b1, fee1);
            console.log('-quoteOutAmount', quoteOutAmount);

            // sell borrowed quote token on higher price pool, calculate how much base token we can get
            uint256 fee2 = getFee(info.higherPool);
            console.log('-fee2', fee2);
            uint256 baseOutAmount = getAmountOut(quoteOutAmount, orderedReserves.b2, orderedReserves.a2, fee2);
            console.log('-baseOutAmount', baseOutAmount);
            require(baseOutAmount > startAmount, 'BOT: Arbitrage fail, no profit');
            console.log('-estimated profit:', (baseOutAmount - startAmount) /* / 1 ether*/);

            require(startAmount<=balanceBefore, 'BOT: Not enough base token balance');

            IERC20(info.baseToken).safeTransfer(info.lowerPool, startAmount);
            (uint256 amount0Out, uint256 amount1Out) =
            info.baseTokenSmaller ? (uint256(0), quoteOutAmount) : (quoteOutAmount, uint256(0));
            if (!swap(info.lowerPool, amount0Out, amount1Out)) {
                return false;
            }
            uint256 outBalance = IERC20(info.quoteToken).balanceOf(address(this));
            console.log('-outBalance', outBalance);

            quoteOutAmount = outBalance < quoteOutAmount ? outBalance : quoteOutAmount;
            console.log('-quoteOutAmount', quoteOutAmount);
            IERC20(info.quoteToken).safeTransfer(info.higherPool, quoteOutAmount);

            baseOutAmount = getAmountOut(quoteOutAmount, orderedReserves.b2, orderedReserves.a2, fee2);
            console.log('-baseOutAmount', baseOutAmount);

            (uint256 amount0Out2, uint256 amount1Out2) =
            info.baseTokenSmaller ? (baseOutAmount, uint256(0)) : (uint256(0), baseOutAmount);
            if (!swap(info.higherPool, amount0Out2, amount1Out2)) {
                return false;
            }
        }

        uint256 balanceAfter = IERC20(info.baseToken).balanceOf(address(this));
        console.log('-balanceAfter', balanceAfter);
        require(balanceAfter > balanceBefore, 'BOT: Losing money');
        uint256 profit = balanceAfter-balanceBefore;
        console.log('-received profit', balanceAfter-balanceBefore);
        IERC20(info.baseToken).transfer(getOwner(), profit);
        return true;
    }

    function swap(address pool, uint256 amount0Out, uint256 amount1Out) private returns (bool) {
        bytes memory noData;
        try IUniswapV2Pair(pool).swap(amount0Out, amount1Out, address(this), noData) {
        } catch Error(string memory reason) {
            if (stringsEquals(reason, "TSP: K too low")) {
                IUniswapV2Pair(pool).sync();
                return false;
            }
            revert(reason);
        }
        return true;
    }

    function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        uint256 l2 = b2.length;
        if (l1 != l2) return false;
        for (uint256 i=0; i<l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }


    /// @notice Calculate how much profit we can by arbitraging between two pools
    function getProfit(address pool0, address pool1) external view
    returns (uint256 profit, address baseToken) {
        (bool baseTokenSmaller, address _baseToken, ) = isBaseTokenSmaller(pool0, pool1);
        baseToken = _baseToken;

        (address p1, address p2, OrderedReserves memory orderedReserves) = getOrderedReserves(pool0, pool1, baseTokenSmaller);

        uint256 baseStartAmount = IERC20(baseToken).balanceOf(address(this));
        console.log('+baseStartAmount', baseStartAmount);

        // sell base token on lower price pool for quite token,
        uint256 fee1 = getFee(p1);
        console.log('+fee1', fee1);
        uint256 quoteOutAmount = getAmountOut(baseStartAmount, orderedReserves.a1, orderedReserves.b1, fee1);
        console.log('+quoteOutAmount', quoteOutAmount);

        // sell quote token on higher price pool
        uint256 fee2 = getFee(p2);
        console.log('+fee2', fee2);
        uint256 baseOutAmount = getAmountOut(quoteOutAmount, orderedReserves.b2, orderedReserves.a2, fee2);
        console.log('+baseOutAmount', baseOutAmount);

        if (baseOutAmount < baseStartAmount) {
            profit = 0;
        } else {
            profit = baseOutAmount - baseStartAmount;
            console.log('+profit', profit);
        }
    }

    // copy from UniswapV2Library
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
 /*   function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'BOT: UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BOT: UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn.mul(amountOut).mul(_PRECISION);
        uint256 denominator = reserveOut.sub(amountOut).mul(_PRECISION-fee);
        amountIn = (numerator / denominator).add(1);
    }*/

    // copy from UniswapV2Library
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'BOT: UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'BOT: UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(_PRECISION-fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(_PRECISION).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getFee(address pair) internal view returns(uint) {
        if (IUniswapV2Pair(pair).factory()==_TETUSWAP_FACTORY) {
            try IUniswapV2Pair(pair).fee() returns (uint fee) {
                return fee;
            } catch Error(string memory /*reason*/) {
            } catch (bytes memory /*lowLevelData*/) {
            }
        }
        return 30;

    }

    receive() external payable {}


}