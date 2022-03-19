/**
 *Submitted for verification at polygonscan.com on 2022-03-19
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
    IUniswapQuoter internal constant quoterUniswap = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IUniswapRouter internal constant routerUniswap = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ICurvePool internal constant poolCurve = ICurvePool(0xE8dCeA7Fb2Baf7a9F4d9af608F06d78a687F8d9A);
    IJarvisPool internal constant poolJarvis = IJarvisPool(0x6cA82a7E54053B102e7eC452788cC19204e831de);
    IJarvisAggregator internal constant aggregatorJarvis = IJarvisAggregator(0xD647a6fC9BC6402301583C91decC5989d8Bc382D);
    address internal constant derivativeJarvis = 0x2076648e2D9d452D55f4252CBa9b162A1850Db48;
    constructor() {
        jpyc.approve(address(routerUniswap), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        jpyc.approve(address(poolCurve), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        jjpy.approve(address(poolCurve), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        jjpy.approve(address(poolJarvis), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        usdc.approve(address(routerUniswap), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        usdc.approve(address(poolJarvis), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
    function swap(address tokenIn, address tokenOut, uint256 amount, uint256 minimum) public returns(uint256) {
        uint256 i;
        uint256 amountIn1Upper;
        uint256 amountIn1Lower;
        uint256 amountOutUpper;
        uint256 amountOutLower;
        amountIn1Upper = amount;
        amountIn1Lower = 0;
        if(tokenIn == address(jpyc) && tokenOut == address(usdc)) {
            amountOutUpper = rateJpycToUsdc(amount);
            amountOutLower = rateJjpyToUsdc(rateJpycToJjpy(amount));
            for(i = 0; i < 10; i++) {
                if(amountOutUpper >= amountOutLower) {
                    amountIn1Lower = (amountIn1Upper + amountIn1Lower) / 2;
                    amountOutLower = rateJpycToUsdc(amountIn1Lower) + rateJjpyToUsdc(rateJpycToJjpy(amount - amountIn1Lower));
                }
                else {
                    amountIn1Upper = (amountIn1Upper + amountIn1Lower) / 2;
                    amountOutUpper = rateJpycToUsdc(amountIn1Upper) + rateJjpyToUsdc(rateJpycToJjpy(amount - amountIn1Upper));
                }
            }
            amountIn1Upper = amountOutUpper >= amountOutLower ? amountIn1Upper : amountIn1Lower;
            if(minimum > 0) {
                jpyc.transferFrom(msg.sender, address(this), amount);
                if(amountIn1Upper > 0) {
                    exchangeJpycToUsdc(amountIn1Upper);
                }
                if(amount - amountIn1Upper > 0) {
                    exchangeJpycToJjpy(amount - amountIn1Upper);
                    exchangeJjpyToUsdc(jjpy.balanceOf(address(this)));
                }
                amountOutUpper = usdc.balanceOf(address(this));
                require(amountOutUpper >= minimum);
                usdc.transfer(msg.sender, amountOutUpper);
            }
            else {
                amountOutUpper = rateJpycToUsdc(amountIn1Upper) + rateJjpyToUsdc(rateJpycToJjpy(amount - amountIn1Upper));
            }
        }
        else if(tokenIn == address(usdc) && tokenOut == address(jpyc)) {
            amountOutUpper = rateUsdcToJpyc(amount);
            amountOutLower = rateJjpyToJpyc(rateUsdcToJjpy(amount));
            for(i = 0; i < 10; i++) {
                if(amountOutUpper >= amountOutLower) {
                    amountIn1Lower = (amountIn1Upper + amountIn1Lower) / 2;
                    amountOutLower = rateUsdcToJpyc(amountIn1Lower) + rateJjpyToJpyc(rateUsdcToJjpy(amount - amountIn1Lower));
                }
                else {
                    amountIn1Upper = (amountIn1Upper + amountIn1Lower) / 2;
                    amountOutUpper = rateUsdcToJpyc(amountIn1Upper) + rateJjpyToJpyc(rateUsdcToJjpy(amount - amountIn1Upper));
                }
            }
            amountIn1Upper = amountOutUpper >= amountOutLower ? amountIn1Upper : amountIn1Lower;
            if(minimum > 0) {
                usdc.transferFrom(msg.sender, address(this), amount);
                if(amountIn1Upper > 0) {
                    exchangeUsdcToJpyc(amountIn1Upper);
                }
                if(amount - amountIn1Upper > 0) {
                    exchangeUsdcToJjpy(amount - amountIn1Upper);
                    exchangeJjpyToJpyc(jjpy.balanceOf(address(this)));
                }
                amountOutUpper = jpyc.balanceOf(address(this));
                require(amountOutUpper >= minimum);
                jpyc.transfer(msg.sender, amountOutUpper);
            }
            else {
                amountOutUpper = rateUsdcToJpyc(amountIn1Upper) + rateJjpyToJpyc(rateUsdcToJjpy(amount - amountIn1Upper));
            }
        }
        else {
            revert();
        }
        return amountOutUpper;
    }
    function rateJpycToUsdc(uint256 amount) internal returns(uint256) {
        return amount == 0 ? 0 : quoterUniswap.quoteExactInputSingle(address(jpyc), address(usdc), 500, amount, 0);
    }
    function exchangeJpycToUsdc(uint256 amount) internal {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(usdc), 500, address(this), block.timestamp, amount, 0, 0));
    }
    function rateUsdcToJpyc(uint256 amount) internal returns(uint256) {
        return amount == 0 ? 0 : quoterUniswap.quoteExactInputSingle(address(usdc), address(jpyc), 500, amount, 0);
    }
    function exchangeUsdcToJpyc(uint256 amount) internal {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpyc), 500, address(this), block.timestamp, amount, 0, 0));
    }
    function rateJjpyToJpyc(uint256 amount) internal view returns(uint256) {
        return amount == 0 ? 0 : poolCurve.get_dy(0, 1, amount);
    }
    function exchangeJjpyToJpyc(uint256 amount) internal {
        poolCurve.exchange(0, 1, amount, 0);
    }
    function rateJpycToJjpy(uint256 amount) internal view returns(uint256) {
        return amount == 0 ? 0 : poolCurve.get_dy(1, 0, amount);
    }
    function exchangeJpycToJjpy(uint256 amount) internal {
        poolCurve.exchange(1, 0, amount, 0);
    }
    function rateUsdcToJjpy(uint256 amount) internal view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return amount == 0 ? 0 : ((amount - poolJarvis.calculateFee(amount)) * (10 ** jjpy.decimals()) / (10 ** usdc.decimals())) * (10 ** aggregatorJarvis.decimals()) / uint256(a);
    }
    function exchangeUsdcToJjpy(uint256 amount) internal {
        poolJarvis.mint(JarvisMint(derivativeJarvis, 0, amount, 2000000000000000, block.timestamp, address(this)));
    }
    function rateJjpyToUsdc(uint256 amount) internal view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return amount == 0 ? 0 : ((amount - poolJarvis.calculateFee(amount)) * (10 ** usdc.decimals()) / (10 ** jjpy.decimals())) * uint256(a) / (10 ** aggregatorJarvis.decimals());
    }
    function exchangeJjpyToUsdc(uint256 amount) internal {
        poolJarvis.redeem(JarvisMint(derivativeJarvis, amount, 0, 2000000000000000, block.timestamp, address(this)));
    }
}