/**
 *Submitted for verification at polygonscan.com on 2022-10-15
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

interface IExchangeV1forV2Wrapper {
    function quote(uint256) external view returns(uint256);
    function swap(uint256, address) external;
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

struct JarvisV2Mint {
    uint256 _0;
    uint256 _1;
    uint256 _2;
    address _3;
}

interface IJarvisV2Pool {
    function getMintTradeInfo(uint256) external view returns(uint256, uint256);
    function getRedeemTradeInfo(uint256) external view returns(uint256, uint256);
    function mint(JarvisV2Mint calldata) external returns(uint256, uint256);
    function redeem(JarvisV2Mint calldata) external returns(uint256, uint256);
}

contract JpycExchangeV3 {
    IErc20 internal constant jpycv1 = IErc20(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
    IErc20 internal constant jpycv2 = IErc20(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
    IErc20 internal constant jjpy = IErc20(0x8343091F2499FD4b6174A46D067A920a3b851FF9);
    IErc20 internal constant usdc = IErc20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IExchangeV1forV2Wrapper internal constant exchangeV1forV2 = IExchangeV1forV2Wrapper(0xdc65838a5D3Bb48505F346f2112f677cd780F73b);
    IQuickSwapRouter internal constant routerQuickSwap = IQuickSwapRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IUniswapQuoter internal constant quoterUniswap = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IUniswapRouter internal constant routerUniswap = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ICurvePool internal constant poolCurveV1 = ICurvePool(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
    ICurvePool internal constant poolCurveV2 = ICurvePool(0xaA91CDD7abb47F821Cf07a2d38Cc8668DEAf1bdc);
    IJarvisV2Pool internal constant poolJarvisV2 = IJarvisV2Pool(0xAEc757BF73cc1f4609a1459205835Dd40b4e3F29);
    mapping(address => mapping(address => function(uint256, uint256) returns(uint256))) internal rate;
    mapping(address => mapping(address => function(uint256, uint256))) internal exchange;
    struct Calculation {
        uint256 amountIn;
        uint256 amountOut;
        uint256 amountOutDelta;
    }
    constructor() {
        jpycv1.approve(address(exchangeV1forV2), type(uint256).max);
        jpycv1.approve(address(routerQuickSwap), type(uint256).max);
        jpycv1.approve(address(routerUniswap), type(uint256).max);
        jpycv1.approve(address(poolCurveV1), type(uint256).max);
        jpycv2.approve(address(routerQuickSwap), type(uint256).max);
        jpycv2.approve(address(routerUniswap), type(uint256).max);
        jpycv2.approve(address(poolCurveV2), type(uint256).max);
        jjpy.approve(address(routerUniswap), type(uint256).max);
        jjpy.approve(address(poolCurveV1), type(uint256).max);
        jjpy.approve(address(poolCurveV2), type(uint256).max);
        jjpy.approve(address(poolJarvisV2), type(uint256).max);
        usdc.approve(address(routerQuickSwap), type(uint256).max);
        usdc.approve(address(routerUniswap), type(uint256).max);
        usdc.approve(address(poolJarvisV2), type(uint256).max);
        rate[address(jpycv1)][address(jpycv2)] = rateCombinedJpycV1ToJpycV2;
        rate[address(jpycv1)][address(usdc)] = rateCombinedJpycV1ToUsdc;
        rate[address(jpycv2)][address(jpycv1)] = rateCombinedJpycV2ToJpycV1;
        rate[address(jpycv2)][address(usdc)] = rateCombinedJpycV2ToUsdc;
        rate[address(usdc)][address(jpycv1)] = rateCombinedUsdcToJpycV1;
        rate[address(usdc)][address(jpycv2)] = rateCombinedUsdcToJpycV2;
        exchange[address(jpycv1)][address(jpycv2)] = exchangeCombinedJpycV1ToJpycV2;
        exchange[address(jpycv1)][address(usdc)] = exchangeCombinedJpycV1ToUsdc;
        exchange[address(jpycv2)][address(jpycv1)] = exchangeCombinedJpycV2ToJpycV1;
        exchange[address(jpycv2)][address(usdc)] = exchangeCombinedJpycV2ToUsdc;
        exchange[address(usdc)][address(jpycv1)] = exchangeCombinedUsdcToJpycV1;
        exchange[address(usdc)][address(jpycv2)] = exchangeCombinedUsdcToJpycV2;
    }
    function quote(address tokenIn, address tokenOut, uint256 amount, uint256 precision) public returns(uint256[] memory, uint256) {
        function(uint256, uint256) returns(uint256) f;
        uint256 amountDelta;
        uint256 amountCumulative;
        uint256 index;
        Calculation[5] memory calculation;
        uint256[] memory amountIn;
        uint256 amountOut;
        f = rate[tokenIn][tokenOut];
        assembly {
            if eq(f, 0) {
                revert(mload(0x40), 0)
            }
        }
        amountDelta = amount / precision;
        amountCumulative = 0;
        for(uint256 i = 0; i < 5; i++) {
            calculation[i].amountIn = 0;
            calculation[i].amountOut = 0;
            calculation[i].amountOutDelta = f(i, amountDelta);
        }
        for(uint256 i = 0; i < precision; i++) {
            if(i == precision - 1) {
                if(amountDelta != amount - amountCumulative) {
                    amountDelta = amount - amountCumulative;
                    for(uint256 j = 0; j < 5; j++) {
                        calculation[j].amountOutDelta = f(j, calculation[j].amountIn + amountDelta) - calculation[j].amountOut;
                    }
                }
            }
            index = 0;
            for(uint256 j = 1; j < 5; j++) {
                if(calculation[j].amountOutDelta > calculation[index].amountOutDelta) {
                    index = j;
                }
            }
            calculation[index].amountIn += amountDelta;
            calculation[index].amountOut += calculation[index].amountOutDelta;
            if(i < precision - 1) {
                calculation[index].amountOutDelta = f(index, calculation[index].amountIn + amountDelta) - calculation[index].amountOut;
                amountCumulative += amountDelta;
            }
        }
        amountIn = new uint256[](5);
        amountOut = 0;
        for(uint256 i = 0; i < 5; i++) {
            amountIn[i] = calculation[i].amountIn;
            amountOut += calculation[i].amountOut;
        }
        return (amountIn, amountOut);
    }
    function swap(address tokenIn, address tokenOut, uint256[] memory amount, uint256 minimum) public {
        function(uint256, uint256) f;
        uint256 amountIn;
        uint256 amountOut;
        f = exchange[tokenIn][tokenOut];
        assembly {
            if eq(f, 0) {
                revert(mload(0x40), 0)
            }
        }
        amountIn = 0;
        for(uint256 i = 0; i < amount.length; i++) {
            amountIn += amount[i];
        }
        IErc20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        for(uint256 i = 0; i < amount.length; i++) {
            if(amount[i] > 0) {
                f(i, amount[i]);
            }
        }
        amountOut = IErc20(tokenOut).balanceOf(address(this));
        require(amountOut >= minimum);
        IErc20(tokenOut).transfer(msg.sender, amountOut);
    }
    function rateCombinedJpycV1ToJpycV2(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateJpycV1ToJpycV2(0, amount);
        }
        if(route == 1) {
            return rateUsdcToJpycV2(1, rateJpycV1ToUsdc(1, amount));
        }
        if(route == 2) {
            return rateJjpyToJpycV2(0, rateJpycV1ToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedJpycV1ToJpycV2(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeJpycV1ToJpycV2(0, amount);
            return;
        }
        if(route == 1) {
            exchangeJpycV1ToUsdc(1, amount);
            exchangeUsdcToJpycV2(1, usdc.balanceOf(address(this)));
            return;
        }
        if(route == 2) {
            exchangeJpycV1ToJjpy(0, amount);
            exchangeJjpyToJpycV2(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedJpycV2ToJpycV1(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateUsdcToJpycV1(1, rateJpycV2ToUsdc(1, amount));
        }
        if(route == 1) {
            return rateJjpyToJpycV1(0, rateJpycV2ToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedJpycV2ToJpycV1(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeJpycV2ToUsdc(1, amount);
            exchangeUsdcToJpycV1(1, usdc.balanceOf(address(this)));
            return;
        }
        if(route == 1) {
            exchangeJpycV2ToJjpy(0, amount);
            exchangeJjpyToJpycV1(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedJpycV1ToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateJpycV1ToUsdc(0, amount);
        }
        if(route == 1) {
            return rateJpycV1ToUsdc(1, amount);
        }
        if(route == 2) {
            return rateJpycV2ToUsdc(1, rateJpycV1ToJpycV2(0, amount));
        }
        if(route == 3) {
            return rateJjpyToUsdc(0, rateJpycV1ToJjpy(0, amount));
        }
        if(route == 4) {
            return rateJjpyToUsdc(0, rateJpycV2ToJjpy(0, rateJpycV1ToJpycV2(0, amount)));
        }
        return 0;
    }
    function exchangeCombinedJpycV1ToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeJpycV1ToUsdc(0, amount);
            return;
        }
        if(route == 1) {
            exchangeJpycV1ToUsdc(1, amount);
            return;
        }
        if(route == 2) {
            exchangeJpycV1ToJpycV2(0, amount);
            exchangeJpycV2ToUsdc(1, jpycv2.balanceOf(address(this)));
            return;
        }
        if(route == 3) {
            exchangeJpycV1ToJjpy(0, amount);
            exchangeJjpyToUsdc(0, jjpy.balanceOf(address(this)));
            return;
        }
        if(route == 4) {
            exchangeJpycV1ToJpycV2(0, amount);
            exchangeJpycV2ToJjpy(0, jpycv2.balanceOf(address(this)));
            exchangeJjpyToUsdc(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedUsdcToJpycV1(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateUsdcToJpycV1(0, amount);
        }
        if(route == 1) {
            return rateUsdcToJpycV1(1, amount);
        }
        if(route == 2) {
            return rateJjpyToJpycV1(0, rateUsdcToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedUsdcToJpycV1(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeUsdcToJpycV1(0, amount);
            return;
        }
        if(route == 1) {
            exchangeUsdcToJpycV1(1, amount);
            return;
        }
        if(route == 2) {
            exchangeUsdcToJjpy(0, amount);
            exchangeJjpyToJpycV1(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedJpycV2ToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateJpycV2ToUsdc(0, amount);
        }
        if(route == 1) {
            return rateJpycV2ToUsdc(1, amount);
        }
        if(route == 2) {
            return rateJjpyToUsdc(0, rateJpycV2ToJjpy(0, amount));
        }
        return 0;
    }
    function exchangeCombinedJpycV2ToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeJpycV2ToUsdc(0, amount);
            return;
        }
        if(route == 1) {
            exchangeJpycV2ToUsdc(1, amount);
            return;
        }
        if(route == 2) {
            exchangeJpycV2ToJjpy(0, amount);
            exchangeJjpyToUsdc(0, jjpy.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateCombinedUsdcToJpycV2(uint256 route, uint256 amount) internal returns(uint256) {
        if(route == 0) {
            return rateUsdcToJpycV2(0, amount);
        }
        if(route == 1) {
            return rateUsdcToJpycV2(1, amount);
        }
        if(route == 2) {
            return rateJpycV1ToJpycV2(0, rateUsdcToJpycV1(1, amount));
        }
        if(route == 3) {
            return rateJjpyToJpycV2(0, rateUsdcToJjpy(0, amount));
        }
        if(route == 4) {
            return rateJpycV1ToJpycV2(0, rateJjpyToJpycV1(0, rateUsdcToJjpy(0, amount)));
        }
        return 0;
    }
    function exchangeCombinedUsdcToJpycV2(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeUsdcToJpycV2(0, amount);
            return;
        }
        if(route == 1) {
            exchangeUsdcToJpycV2(1, amount);
            return;
        }
        if(route == 2) {
            exchangeUsdcToJpycV1(1, amount);
            exchangeJpycV1ToJpycV2(0, jpycv1.balanceOf(address(this)));
            return;
        }
        if(route == 3) {
            exchangeUsdcToJjpy(0, amount);
            exchangeJjpyToJpycV2(0, jjpy.balanceOf(address(this)));
            return;
        }
        if(route == 4) {
            exchangeUsdcToJjpy(0, amount);
            exchangeJjpyToJpycV1(0, jjpy.balanceOf(address(this)));
            exchangeJpycV1ToJpycV2(0, jpycv1.balanceOf(address(this)));
            return;
        }
        revert();
    }
    function rateJpycV1ToJpycV2(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try exchangeV1forV2.quote(amount) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJpycV1ToJpycV2(uint256 route, uint256 amount) internal {
        if(route == 0) {
            exchangeV1forV2.swap(amount, address(this));
            return;
        }
        revert();
    }
    function rateJpycV1ToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try routerQuickSwap.getAmountsOut(amount, addressArray(address(jpycv1), address(usdc))) returns(uint256[] memory a) {
                return a[1];
            }
            catch {
            }
        }
        if(route == 1) {
            try quoterUniswap.quoteExactInputSingle(address(jpycv1), address(usdc), 500, amount, 0) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJpycV1ToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(jpycv1), address(usdc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpycv1), address(usdc), 500, address(this), block.timestamp, amount, 0, 0));
            return;
        }
        revert();
    }
    function rateUsdcToJpycV1(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try routerQuickSwap.getAmountsOut(amount, addressArray(address(usdc), address(jpycv1))) returns(uint256[] memory a) {
                return a[1];
            }
            catch {
            }
        }
        if(route == 1) {
            try quoterUniswap.quoteExactInputSingle(address(usdc), address(jpycv1), 500, amount, 0) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeUsdcToJpycV1(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(usdc), address(jpycv1)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpycv1), 500, address(this), block.timestamp, amount, 0, 0));
            return;
        }
        revert();
    }
    function rateJjpyToJpycV1(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolCurveV1.get_dy(0, 1, amount) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJjpyToJpycV1(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurveV1.exchange(0, 1, amount, 0);
            return;
        }
        revert();
    }
    function rateJpycV1ToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolCurveV1.get_dy(1, 0, amount) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJpycV1ToJjpy(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurveV1.exchange(1, 0, amount, 0);
            return;
        }
        revert();
    }
    function rateUsdcToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolJarvisV2.getMintTradeInfo(amount) returns(uint256 a, uint256) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeUsdcToJjpy(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolJarvisV2.mint(JarvisV2Mint(0, amount, block.timestamp, address(this)));
            return;
        }
        revert();
    }
    function rateJjpyToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolJarvisV2.getRedeemTradeInfo(amount) returns(uint256 a, uint256) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJjpyToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolJarvisV2.redeem(JarvisV2Mint(amount, 0, block.timestamp, address(this)));
            return;
        }
        revert();
    }
    function rateJpycV2ToUsdc(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try routerQuickSwap.getAmountsOut(amount, addressArray(address(jpycv2), address(usdc))) returns(uint256[] memory a) {
                return a[1];
            }
            catch {
            }
        }
        if(route == 1) {
            try quoterUniswap.quoteExactInputSingle(address(jpycv2), address(usdc), 500, amount, 0) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJpycV2ToUsdc(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(jpycv2), address(usdc)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpycv2), address(usdc), 500, address(this), block.timestamp, amount, 0, 0));
            return;
        }
        revert();
    }
    function rateUsdcToJpycV2(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try routerQuickSwap.getAmountsOut(amount, addressArray(address(usdc), address(jpycv2))) returns(uint256[] memory a) {
                return a[1];
            }
            catch {
            }
        }
        if(route == 1) {
            try quoterUniswap.quoteExactInputSingle(address(usdc), address(jpycv2), 500, amount, 0) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeUsdcToJpycV2(uint256 route, uint256 amount) internal {
        if(route == 0) {
            routerQuickSwap.swapExactTokensForTokens(amount, 0, addressArray(address(usdc), address(jpycv2)), address(this), block.timestamp);
            return;
        }
        if(route == 1) {
            routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpycv2), 500, address(this), block.timestamp, amount, 0, 0));
            return;
        }
        revert();
    }
    function rateJjpyToJpycV2(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolCurveV2.get_dy(0, 1, amount) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJjpyToJpycV2(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurveV2.exchange(0, 1, amount, 0);
            return;
        }
        revert();
    }
    function rateJpycV2ToJjpy(uint256 route, uint256 amount) internal returns(uint256) {
        if(amount == 0) {
            return 0;
        }
        if(route == 0) {
            try poolCurveV2.get_dy(1, 0, amount) returns(uint256 a) {
                return a;
            }
            catch {
            }
        }
        return 0;
    }
    function exchangeJpycV2ToJjpy(uint256 route, uint256 amount) internal {
        if(route == 0) {
            poolCurveV2.exchange(1, 0, amount, 0);
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