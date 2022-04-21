/**
 *Submitted for verification at polygonscan.com on 2022-04-21
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

contract JpycExchange {
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
    struct Calculation {
        uint256 amountIn;
        uint256 amountOut;
        uint256 amountOutDelta;
    }
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
    function quote(address tokenIn, address tokenOut, uint256 amount, uint256 precision) public returns(uint256[] memory, uint256) {
        uint256 i;
        uint256 j;
        function(uint256, uint256) returns(uint256) rate;
        uint256 amountDelta;
        uint256 amountCumulative;
        Calculation[3] memory calculation;
        uint256 index;
        uint256[] memory amountIn;
        uint256 amountOut;
        if(tokenIn == address(jpyc) && tokenOut == address(usdc)) {
            rate = rateCombinedJpycToUsdc;
        }
        else if(tokenIn == address(usdc) && tokenOut == address(jpyc)) {
            rate = rateCombinedUsdcToJpyc;
        }
        else {
            revert();
        }
        amountDelta = amount / precision;
        amountCumulative = 0;
        for(i = 0; i < 3; i++) {
            calculation[i].amountIn = 0;
            calculation[i].amountOut = 0;
            calculation[i].amountOutDelta = rate(i, amountDelta);
        }
        for(i = 0; i < precision; i++) {
            if(i == precision - 1) {
                if(amountDelta != amount - amountCumulative) {
                    amountDelta = amount - amountCumulative;
                    for(j = 0; j < 3; j++) {
                        calculation[j].amountOutDelta = rate(j, calculation[j].amountIn + amountDelta) - calculation[j].amountOut;
                    }
                }
            }
            index = 0;
            for(j = 1; j < 3; j++) {
                if(calculation[j].amountOutDelta > calculation[index].amountOutDelta) {
                    index = j;
                }
            }
            calculation[index].amountIn += amountDelta;
            calculation[index].amountOut += calculation[index].amountOutDelta;
            if(i < precision - 1) {
                calculation[index].amountOutDelta = rate(index, calculation[index].amountIn + amountDelta) - calculation[index].amountOut;
                amountCumulative += amountDelta;
            }
        }
        amountIn = new uint256[](3);
        amountOut = 0;
        for(i = 0; i < 3; i++) {
            amountIn[i] = calculation[i].amountIn;
            amountOut += calculation[i].amountOut;
        }
        return (amountIn, amountOut);
    }
    function swap(address tokenIn, address tokenOut, uint256[] memory amount, uint256 minimum) public {
        uint256 i;
        function(uint256, uint256) exchange;
        uint256 amountIn;
        uint256 amountOut;
        if(tokenIn == address(jpyc) && tokenOut == address(usdc)) {
            exchange = exchangeCombinedJpycToUsdc;
        }
        else if(tokenIn == address(usdc) && tokenOut == address(jpyc)) {
            exchange = exchangeCombinedUsdcToJpyc;
        }
        else {
            revert();
        }
        amountIn = 0;
        for(i = 0; i < amount.length; i++) {
            amountIn += amount[i];
        }
        IErc20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        for(i = 0; i < amount.length; i++) {
            if(amount[i] > 0) {
                exchange(i, amount[i]);
            }
        }
        amountOut = IErc20(tokenOut).balanceOf(address(this));
        require(amountOut >= minimum);
        IErc20(tokenOut).transfer(msg.sender, amountOut);
    }
    function rateCombinedJpycToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateJpycToUsdc(0, amount);
        }
        if(route == 1) {
            return rateJpycToUsdc(1, amount);
        }
        if(route == 2) {
            return rateJjpyToUsdc(0, rateJpycToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedJpycToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeJpycToUsdc(0, amount);
            return;
        }
        if(route == 1) {
            exchangeJpycToUsdc(1, amount);
            return;
        }
        if(route == 2) {
            exchangeJpycToJjpy(0, amount);
            exchangeJjpyToUsdc(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedUsdcToJpyc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateUsdcToJpyc(0, amount);
        }
        if(route == 1) {
            return rateUsdcToJpyc(1, amount);
        }
        if(route == 2) {
            return rateJjpyToJpyc(0, rateUsdcToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedUsdcToJpyc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeUsdcToJpyc(0, amount);
            return;
        }
        if(route == 1) {
            exchangeUsdcToJpyc(1, amount);
            return;
        }
        if(route == 2) {
            exchangeUsdcToJjpy(0, amount);
            exchangeJjpyToJpyc(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
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
    function exchangeJpycToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(jpyc), address(usdc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(usdc), 500, address(this), block.timestamp, amount, 0, 0));
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
    function exchangeUsdcToJpyc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(usdc), address(jpyc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpyc), 500, address(this), block.timestamp, amount, 0, 0));
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
    function exchangeJjpyToJpyc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurve.exchange(0, 1, amount, 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jjpy), address(jpyc), 500, address(this), block.timestamp, amount, 0, 0));
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
    function exchangeJpycToJjpy(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurve.exchange(1, 0, amount, 0);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(jjpy), 500, address(this), block.timestamp, amount, 0, 0));
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
    function exchangeUsdcToJjpy(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolJarvis.mint(JarvisMint(derivativeJarvis, 0, amount, 2000000000000000, block.timestamp, address(this)));
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jjpy), 500, address(this), block.timestamp, amount, 0, 0));
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
    function exchangeJjpyToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolJarvis.redeem(JarvisMint(derivativeJarvis, amount, 0, 2000000000000000, block.timestamp, address(this)));
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jjpy), address(usdc), 500, address(this), block.timestamp, amount, 0, 0));
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