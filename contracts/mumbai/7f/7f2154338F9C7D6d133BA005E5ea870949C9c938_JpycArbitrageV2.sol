/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IErc20 {
    function decimals() external pure returns(uint8);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

interface IQuickSwapRouter {
    function getAmountsOut(uint256, address[] calldata) external view returns(uint256[] memory);
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external returns(uint256[] memory);
}

struct UniswapExactInputSingle {
    address _0;
    address _1;
    uint24 _2;
    address _3;
    uint256 _4;
    uint256 _5;
    uint256 _6;
    uint160 _7;
}

interface IUniswapQuoter {
    function quoteExactInputSingle(address, address, uint24, uint256, uint160) external returns(uint256);
}

interface IUniswapRouter {
    function exactInputSingle(UniswapExactInputSingle calldata) external returns(uint256);
}

interface ICurvePool {
    function get_dy(int128, int128, uint256) external view returns(uint256);
    function exchange(int128, int128, uint256, uint256) external returns(uint256);
}

struct JarvisMint {
    address _0;
    uint256 _1;
    uint256 _2;
    uint256 _3;
    uint256 _4;
    address _5;
}

interface IJarvisPool {
    function mint(JarvisMint calldata) external returns(uint256, uint256);
    function redeem(JarvisMint calldata) external returns(uint256, uint256);
    function calculateFee(uint256) external view returns(uint256);
    function getPriceFeedIdentifier() external view returns(bytes32);
}

interface IJarvisAggregator {
    function latestRoundData() external view returns(uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns(uint8);
}

contract JpycArbitrageV2 {
    IErc20 internal constant jpycv2 = IErc20(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
    IErc20 internal constant jjpy = IErc20(0x8343091F2499FD4b6174A46D067A920a3b851FF9);
    IErc20 internal constant usdc = IErc20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IQuickSwapRouter internal constant routerQuickSwap = IQuickSwapRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapQuoter internal constant quoterUniswap = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IUniswapRouter internal constant routerUniswap = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ICurvePool internal constant poolCurve = ICurvePool(0xaA91CDD7abb47F821Cf07a2d38Cc8668DEAf1bdc);
    IJarvisPool internal constant poolJarvis = IJarvisPool(0x6cA82a7E54053B102e7eC452788cC19204e831de);
    IJarvisAggregator internal constant aggregatorJarvis = IJarvisAggregator(0xD647a6fC9BC6402301583C91decC5989d8Bc382D);
    address internal constant derivativeJarvis = 0x2076648e2D9d452D55f4252CBa9b162A1850Db48;
    constructor() {
        // jpycv2.approve(address(routerQuickSwap), type(uint256).max);
        // jpycv2.approve(address(routerUniswap), type(uint256).max);
        // jpycv2.approve(address(poolCurve), type(uint256).max);
        // jjpy.approve(address(routerUniswap), type(uint256).max);
        // jjpy.approve(address(poolCurve), type(uint256).max);
        // jjpy.approve(address(poolJarvis), type(uint256).max);
        // usdc.approve(address(routerQuickSwap), type(uint256).max);
        // usdc.approve(address(routerUniswap), type(uint256).max);
        // usdc.approve(address(poolJarvis), type(uint256).max);
    }

    function checkArbitrage(uint256 amount) public returns(uint256, uint256) {
        uint256 route0;
        uint256 amountOut0;
        uint256 route1;
        uint256 amountOut1;
        uint256 amountIn;
        uint256 amountOut;
        uint256 i;
        route0 = 0;
        amountIn = amount;
        amountOut0 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateJpycToJjpy(i, amountIn);
            if(amountOut > amountOut0) {
                amountOut0 = amountOut;
                route0 = (route0 & ~(uint256(1) << 1)) | (i << 1);
            }
        }
        amountIn = amountOut0;
        amountOut0 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateJjpyToUsdc(i, amountIn);
            if(amountOut > amountOut0) {
                amountOut0 = amountOut;
                route0 = (route0 & ~(uint256(1) << 2)) | (i << 2);
            }
        }
        amountIn = amountOut0;
        amountOut0 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateUsdcToJpyc(i, amountIn);
            if(amountOut > amountOut0) {
                amountOut0 = amountOut;
                route0 = (route0 & ~(uint256(1) << 3)) | (i << 3);
            }
        }
        route1 = 1;
        amountIn = amount;
        amountOut1 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateJpycToUsdc(i, amountIn);
            if(amountOut > amountOut1) {
                amountOut1 = amountOut;
                route1 = (route1 & ~(uint256(1) << 1)) | (i << 1);
            }
        }
        amountIn = amountOut1;
        amountOut1 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateUsdcToJjpy(i, amountIn);
            if(amountOut > amountOut1) {
                amountOut1 = amountOut;
                route1 = (route1 & ~(uint256(1) << 2)) | (i << 2);
            }
        }
        amountIn = amountOut1;
        amountOut1 = 0;
        for(i = 0; i < 2; i++) {
            amountOut = rateJjpyToJpyc(i, amountIn);
            if(amountOut > amountOut1) {
                amountOut1 = amountOut;
                route1 = (route1 & ~(uint256(1) << 3)) | (i << 3);
            }
        }
        if(amountOut0 >= amountOut1) {
            return (amountOut0, route0);
        }
        return (amountOut1, route1);
    }
    function checkArbitrageLimited(uint256 amount, uint256 enable0, uint256 enable1) internal returns(uint256, uint256) {
        uint256 route0;
        uint256 amountOut0;
        uint256 route1;
        uint256 amountOut1;
        uint256 amountIn;
        uint256 amountOut;
        uint256 i;
        route0 = 0;
        amountOut0 = 0;
        if(enable0 != 0) {
            amountOut0 = rateJpycToJjpy(0, amount);
            amountOut0 = rateJjpyToUsdc(0, amountOut0);
            amountIn = amountOut0;
            amountOut0 = 0;
            for(i = 0; i < 2; i++) {
                amountOut = rateUsdcToJpyc(i, amountIn);
                if(amountOut > amountOut0) {
                    amountOut0 = amountOut;
                    route0 = (route0 & ~(uint256(1) << 3)) | (i << 3);
                }
            }
        }
        route1 = 1;
        amountOut1 = 0;
        if(enable1 != 0) {
            amountIn = amount;
            for(i = 0; i < 2; i++) {
                amountOut = rateJpycToUsdc(i, amountIn);
                if(amountOut > amountOut1) {
                    amountOut1 = amountOut;
                    route1 = (route1 & ~(uint256(1) << 1)) | (i << 1);
                }
            }
            amountOut1 = rateUsdcToJjpy(0, amountOut1);
            amountOut1 = rateJjpyToJpyc(0, amountOut1);
        }
        if(amountOut0 >= amountOut1) {
            return (amountOut0, route0);
        }
        return (amountOut1, route1);
    }
    function arbitrage(uint256 amount, uint256 minimum, uint256 route, uint256 loop) public {
        uint256 balance;
        uint256 profitOld;
        uint256 profit;
        if((route & (1 << 4)) != 0) {
            if((route & 1) == 0) {
                (balance, route) = checkArbitrageLimited(amount, 1, 0);
            }
            else {
                (balance, route) = checkArbitrageLimited(amount, 0, 1);
            }
            require(balance >= amount);
        }
        balance = jpycv2.balanceOf(msg.sender);
        jpycv2.transferFrom(msg.sender, address(this), amount);
        profitOld = 0;
        while(loop > 0) {
            try JpycArbitrageV2(this).exchange(amount, route) {
            }
            catch {
                break;
            }
            profit = jpycv2.balanceOf(address(this)) - amount;
            amount += profit;
            if(profit <= profitOld / 2) {
                break;
            }
            profitOld = profit;
            loop--;
        }
        require(amount >= minimum);
        jpycv2.transfer(msg.sender, amount);
        require(jpycv2.balanceOf(msg.sender) >= balance);
    }
    function exchange(uint256 amount, uint256 route) external {
        if((route & 1) == 0) {
            exchangeJpycToJjpy((route & (1 << 1)) >> 1);
            exchangeJjpyToUsdc((route & (1 << 2)) >> 2);
            exchangeUsdcToJpyc((route & (1 << 3)) >> 3);
        }
        else {
            exchangeJpycToUsdc((route & (1 << 1)) >> 1);
            exchangeUsdcToJjpy((route & (1 << 2)) >> 2);
            exchangeJjpyToJpyc((route & (1 << 3)) >> 3);
        }
        require(jpycv2.balanceOf(address(this)) >= amount);
    }
    function rateJpycToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return routerQuickSwap.getAmountsOut(amount, addressArray(address(jpycv2), address(usdc)))[1];
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jpycv2), address(usdc), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJpycToUsdc(uint256 route) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(jpycv2.balanceOf(address(this)), 0, addressArray(address(jpycv2), address(usdc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpycv2), address(usdc), 500, address(this), block.timestamp, jpycv2.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateUsdcToJpyc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return routerQuickSwap.getAmountsOut(amount, addressArray(address(usdc), address(jpycv2)))[1];
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(usdc), address(jpycv2), 500, amount, 0);
        }
        return 0;
    }
    function exchangeUsdcToJpyc(uint256 route) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this)), 0, addressArray(address(usdc), address(jpycv2)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpycv2), 500, address(this), block.timestamp, usdc.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateJjpyToJpyc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return poolCurve.get_dy(0, 1, amount);
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jjpy), address(jpycv2), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJjpyToJpyc(uint256 route) internal {
        if(route == 0) {
            poolCurve.exchange(0, 1, jjpy.balanceOf(address(this)), 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jjpy), address(jpycv2), 500, address(this), block.timestamp, jjpy.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateJpycToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return poolCurve.get_dy(1, 0, amount);
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jpycv2), address(jjpy), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJpycToJjpy(uint256 route) internal {
        if(route == 0) {
            poolCurve.exchange(1, 0, jpycv2.balanceOf(address(this)), 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpycv2), address(jjpy), 500, address(this), block.timestamp, jpycv2.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateUsdcToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        int256 a;
        if(route == 0) {
            (, a, , , ) = aggregatorJarvis.latestRoundData();
            return ((amount * amount / (amount + poolJarvis.calculateFee(amount))) * (10 ** jjpy.decimals()) / (10 ** usdc.decimals())) * (10 ** aggregatorJarvis.decimals()) / uint256(a);
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(usdc), address(jjpy), 500, amount, 0);
        }
        return 0;
    }
    function exchangeUsdcToJjpy(uint256 route) internal {
        if(route == 0) {
            poolJarvis.mint(JarvisMint(derivativeJarvis, 0, usdc.balanceOf(address(this)), 2000000000000000, block.timestamp, address(this)));
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jjpy), 500, address(this), block.timestamp, usdc.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateJjpyToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        int256 a;
        if(route == 0) {
            (, a, , , ) = aggregatorJarvis.latestRoundData();
            return ((amount - poolJarvis.calculateFee(amount)) * (10 ** usdc.decimals()) / (10 ** jjpy.decimals())) * uint256(a) / (10 ** aggregatorJarvis.decimals());
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jjpy), address(usdc), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJjpyToUsdc(uint256 route) internal {
        if(route == 0) {
            poolJarvis.redeem(JarvisMint(derivativeJarvis, jjpy.balanceOf(address(this)), 0, 2000000000000000, block.timestamp, address(this)));
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jjpy), address(usdc), 500, address(this), block.timestamp, jjpy.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function addressArray(address _0, address _1) internal pure returns(address[] memory) {
        address[] memory a;
        a = new address[](2);
        a[0] = _0;
        a[1] = _1;
        return a;
    }
}