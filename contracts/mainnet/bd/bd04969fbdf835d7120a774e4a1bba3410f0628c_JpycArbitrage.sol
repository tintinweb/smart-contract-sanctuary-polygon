/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract JpycArbitrage {
    IErc20 internal constant jpyc = IErc20(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
    IErc20 internal constant jjpy = IErc20(0x8343091F2499FD4b6174A46D067A920a3b851FF9);
    IErc20 internal constant usdc = IErc20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IQuickSwapRouter internal constant routerQuickSwap = IQuickSwapRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapQuoter internal constant quoterUniswap = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IUniswapRouter internal constant routerUniswap = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ICurvePool internal constant poolCurve = ICurvePool(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
    IJarvisPool internal constant poolJarvis = IJarvisPool(0x6cA82a7E54053B102e7eC452788cC19204e831de);
    IJarvisAggregator internal constant aggregatorJarvis = IJarvisAggregator(0xD647a6fC9BC6402301583C91decC5989d8Bc382D);
    address internal constant derivativeJarvis = 0x2076648e2D9d452D55f4252CBa9b162A1850Db48;
    constructor() {
        jpyc.approve(address(routerQuickSwap), type(uint256).max);
        jpyc.approve(address(routerUniswap), type(uint256).max);
        jpyc.approve(address(poolCurve), type(uint256).max);
        jjpy.approve(address(routerUniswap), type(uint256).max);
        jjpy.approve(address(poolCurve), type(uint256).max);
        jjpy.approve(address(poolJarvis), type(uint256).max);
        usdc.approve(address(routerQuickSwap), type(uint256).max);
        usdc.approve(address(routerUniswap), type(uint256).max);
        usdc.approve(address(poolJarvis), type(uint256).max);
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
    function arbitrage(uint256 amount, uint256 minimum, uint256 route, uint256 loop) public {
        uint256 balance;
        uint256 amountOld;
        uint256 profitOld;
        balance = jpyc.balanceOf(msg.sender);
        jpyc.transferFrom(msg.sender, address(this), amount);
        amountOld = amount;
        profitOld = 0;
        while(loop > 0) {
            try JpycArbitrage(this).exchange(route) {
            }
            catch {
            }
            amount = jpyc.balanceOf(address(this));
            if(amount <= amountOld) {
                break;
            }
            if(amount - amountOld < profitOld / 2) {
                break;
            }
            profitOld = amount - amountOld;
            amountOld = amount;
            loop--;
        }
        require(amount >= minimum);
        jpyc.transfer(msg.sender, jpyc.balanceOf(address(this)));
        require(jpyc.balanceOf(msg.sender) >= balance);
    }
    function exchange(uint256 route) external {
        uint256 amount;
        amount = jpyc.balanceOf(address(this));
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
        require(jpyc.balanceOf(address(this)) >= amount);
    }
    function rateJpycToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return routerQuickSwap.getAmountsOut(amount, addressArray(address(jpyc), address(usdc)))[1];
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jpyc), address(usdc), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJpycToUsdc(uint256 route) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(jpyc.balanceOf(address(this)), 0, addressArray(address(jpyc), address(usdc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(usdc), 500, address(this), block.timestamp, jpyc.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateUsdcToJpyc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return routerQuickSwap.getAmountsOut(amount, addressArray(address(usdc), address(jpyc)))[1];
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(usdc), address(jpyc), 500, amount, 0);
        }
        return 0;
    }
    function exchangeUsdcToJpyc(uint256 route) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(usdc.balanceOf(address(this)), 0, addressArray(address(usdc), address(jpyc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpyc), 500, address(this), block.timestamp, usdc.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateJjpyToJpyc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return poolCurve.get_dy(0, 1, amount);
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jjpy), address(jpyc), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJjpyToJpyc(uint256 route) internal {
        if(route == 0) {
            poolCurve.exchange(0, 1, jjpy.balanceOf(address(this)), 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jjpy), address(jpyc), 500, address(this), block.timestamp, jjpy.balanceOf(address(this)), 0, 0));
            return;
        }
        revert();
    }
    function rateJpycToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return poolCurve.get_dy(1, 0, amount);
        }
        if(route == 1) {
            return quoterUniswap.quoteExactInputSingle(address(jpyc), address(jjpy), 500, amount, 0);
        }
        return 0;
    }
    function exchangeJpycToJjpy(uint256 route) internal {
        if(route == 0) {
            poolCurve.exchange(1, 0, jpyc.balanceOf(address(this)), 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(jjpy), 500, address(this), block.timestamp, jpyc.balanceOf(address(this)), 0, 0));
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