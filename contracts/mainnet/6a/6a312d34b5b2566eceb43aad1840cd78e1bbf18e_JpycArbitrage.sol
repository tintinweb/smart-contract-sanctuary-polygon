/**
 *Submitted for verification at polygonscan.com on 2022-03-20
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

contract JpycArbitrage {
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
    function checkArbitrage(uint256 amount) public returns(uint256, uint256) {
        if(rateUsdcToJpyc(rateJjpyToUsdc(rateJpycToJjpy(amount))) >= rateJjpyToJpyc(rateUsdcToJjpy(rateJpycToUsdc(amount)))) {
            return (rateUsdcToJpyc(rateJjpyToUsdc(rateJpycToJjpy(amount))), 0);
        }
        return (rateJjpyToJpyc(rateUsdcToJjpy(rateJpycToUsdc(amount))), 1);
    }
    function arbitrage(uint256 amount, uint256 minimum, uint256 route, uint256 loop) public {
        uint256 amountOld;
        uint256 profitOld;
        jpyc.transferFrom(msg.sender, address(this), amount);
        amountOld = amount;
        profitOld = 0;
        if(route == 0 || route == 1) {
            while(loop > 0) {
                if(route == 0) {
                    exchangeJpycToJjpy();
                    exchangeJjpyToUsdc();
                    exchangeUsdcToJpyc();
                }
                else if(route == 1) {
                    exchangeJpycToUsdc();
                    exchangeUsdcToJjpy();
                    exchangeJjpyToJpyc();
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
        }
        else {
            revert();
        }
        require(amount >= minimum);
        jpyc.transfer(msg.sender, jpyc.balanceOf(address(this)));
        require(jpyc.balanceOf(address(this)) == 0);
    }
    function rateJpycToUsdc(uint256 amount) public returns(uint256) {
        return quoterUniswap.quoteExactInputSingle(address(jpyc), address(usdc), 500, amount, 0);
    }
    function exchangeJpycToUsdc() public {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(jpyc), address(usdc), 500, address(this), block.timestamp, jpyc.balanceOf(address(this)), 0, 0));
    }
    function rateUsdcToJpyc(uint256 amount) public returns(uint256) {
        return quoterUniswap.quoteExactInputSingle(address(usdc), address(jpyc), 500, amount, 0);
    }
    function exchangeUsdcToJpyc() public {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(jpyc), 500, address(this), block.timestamp, usdc.balanceOf(address(this)), 0, 0));
    }
    function rateJjpyToJpyc(uint256 amount) public view returns(uint256) {
        return poolCurve.get_dy(0, 1, amount);
    }
    function exchangeJjpyToJpyc() public {
        poolCurve.exchange(0, 1, jjpy.balanceOf(address(this)), 0);
    }
    function rateJpycToJjpy(uint256 amount) public view returns(uint256) {
        return poolCurve.get_dy(1, 0, amount);
    }
    function exchangeJpycToJjpy() public {
        poolCurve.exchange(1, 0, jpyc.balanceOf(address(this)), 0);
    }
    function rateUsdcToJjpy(uint256 amount) public view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return ((amount * amount / (amount + poolJarvis.calculateFee(amount))) * (10 ** jjpy.decimals()) / (10 ** usdc.decimals())) * (10 ** aggregatorJarvis.decimals()) / uint256(a);
    }
    function exchangeUsdcToJjpy() public {
        poolJarvis.mint(JarvisMint(derivativeJarvis, 0, usdc.balanceOf(address(this)), 2000000000000000, block.timestamp, address(this)));
    }
    function rateJjpyToUsdc(uint256 amount) public view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return ((amount - poolJarvis.calculateFee(amount)) * (10 ** usdc.decimals()) / (10 ** jjpy.decimals())) * uint256(a) / (10 ** aggregatorJarvis.decimals());
    }
    function exchangeJjpyToUsdc() public {
        poolJarvis.redeem(JarvisMint(derivativeJarvis, jjpy.balanceOf(address(this)), 0, 2000000000000000, block.timestamp, address(this)));
    }
}