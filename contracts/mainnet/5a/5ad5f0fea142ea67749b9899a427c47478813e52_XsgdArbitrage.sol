/**
 *Submitted for verification at polygonscan.com on 2022-05-02
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

contract XsgdArbitrage {
    IErc20 internal constant xsgd = IErc20(0x769434dcA303597C8fc4997Bf3DAB233e961Eda2);
    IErc20 internal constant jsgd = IErc20(0xa926db7a4CC0cb1736D5ac60495ca8Eb7214B503);
    IErc20 internal constant usdc = IErc20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IUniswapQuoter internal constant quoterUniswap = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IUniswapRouter internal constant routerUniswap = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ICurvePool internal constant poolCurve = ICurvePool(0xeF75E9C7097842AcC5D0869E1dB4e5fDdf4BFDDA);
    IJarvisPool internal constant poolJarvis = IJarvisPool(0x91436EB8038ecc12c60EE79Dfe011EdBe0e6C777);
    IJarvisAggregator internal constant aggregatorJarvis = IJarvisAggregator(0x8CE3cAc0E6635ce04783709ca3CC4F5fc5304299);
    address internal constant derivativeJarvis = 0xb6C683B89228455B15cF1b2491cC22b529cdf2c4;
    constructor() {
        xsgd.approve(address(routerUniswap), type(uint256).max);
        xsgd.approve(address(poolCurve), type(uint256).max);
        jsgd.approve(address(poolCurve), type(uint256).max);
        jsgd.approve(address(poolJarvis), type(uint256).max);
        usdc.approve(address(routerUniswap), type(uint256).max);
        usdc.approve(address(poolJarvis), type(uint256).max);
    }
    function checkArbitrage(uint256 amount) public returns(uint256, uint256) {
        if(rateJsgdToUsdc(rateXsgdToJsgd(rateUsdcToXsgd(amount))) >= rateXsgdToUsdc(rateJsgdToXsgd(rateUsdcToJsgd(amount)))) {
            return (rateJsgdToUsdc(rateXsgdToJsgd(rateUsdcToXsgd(amount))), 0);
        }
        return (rateXsgdToUsdc(rateJsgdToXsgd(rateUsdcToJsgd(amount))), 1);
    }
    function arbitrage(uint256 amount, uint256 minimum, uint256 route, uint256 loop) public {
        uint256 balance;
        uint256 profitOld;
        uint256 profit;
        balance = usdc.balanceOf(msg.sender);
        usdc.transferFrom(msg.sender, address(this), amount);
        profitOld = 0;
        while(loop > 0) {
            try XsgdArbitrage(this).exchange(amount, route) {
            }
            catch {
                break;
            }
            profit = usdc.balanceOf(address(this)) - amount;
            amount += profit;
            if(profit <= profitOld / 2) {
                break;
            }
            profitOld = profit;
            loop--;
        }
        require(amount >= minimum);
        usdc.transfer(msg.sender, amount);
        require(usdc.balanceOf(msg.sender) >= balance);
    }
    function exchange(uint256 amount, uint256 route) external {
        if(route == 0) {
            exchangeUsdcToXsgd();
            exchangeXsgdToJsgd();
            exchangeJsgdToUsdc();
        }
        else if(route == 1) {
            exchangeUsdcToJsgd();
            exchangeJsgdToXsgd();
            exchangeXsgdToUsdc();
        }
        require(usdc.balanceOf(address(this)) >= amount);
    }
    function rateXsgdToUsdc(uint256 amount) public returns(uint256) {
        return quoterUniswap.quoteExactInputSingle(address(xsgd), address(usdc), 500, amount, 0);
    }
    function exchangeXsgdToUsdc() public {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(xsgd), address(usdc), 500, address(this), block.timestamp, xsgd.balanceOf(address(this)), 0, 0));
    }
    function rateUsdcToXsgd(uint256 amount) public returns(uint256) {
        return quoterUniswap.quoteExactInputSingle(address(usdc), address(xsgd), 500, amount, 0);
    }
    function exchangeUsdcToXsgd() public {
        routerUniswap.exactInputSingle(UniswapExactInputSingle(address(usdc), address(xsgd), 500, address(this), block.timestamp, usdc.balanceOf(address(this)), 0, 0));
    }
    function rateJsgdToXsgd(uint256 amount) public view returns(uint256) {
        return poolCurve.get_dy(0, 1, amount);
    }
    function exchangeJsgdToXsgd() public {
        poolCurve.exchange(0, 1, jsgd.balanceOf(address(this)), 0);
    }
    function rateXsgdToJsgd(uint256 amount) public view returns(uint256) {
        return poolCurve.get_dy(1, 0, amount);
    }
    function exchangeXsgdToJsgd() public {
        poolCurve.exchange(1, 0, xsgd.balanceOf(address(this)), 0);
    }
    function rateUsdcToJsgd(uint256 amount) public view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return ((amount * amount / (amount + poolJarvis.calculateFee(amount))) * (10 ** jsgd.decimals()) / (10 ** usdc.decimals())) * (10 ** aggregatorJarvis.decimals()) / uint256(a);
    }
    function exchangeUsdcToJsgd() public {
        poolJarvis.mint(JarvisMint(derivativeJarvis, 0, usdc.balanceOf(address(this)), 2000000000000000, block.timestamp, address(this)));
    }
    function rateJsgdToUsdc(uint256 amount) public view returns(uint256) {
        int256 a;
        (, a, , , ) = aggregatorJarvis.latestRoundData();
        return ((amount - poolJarvis.calculateFee(amount)) * (10 ** usdc.decimals()) / (10 ** jsgd.decimals())) * uint256(a) / (10 ** aggregatorJarvis.decimals());
    }
    function exchangeJsgdToUsdc() public {
        poolJarvis.redeem(JarvisMint(derivativeJarvis, jsgd.balanceOf(address(this)), 0, 2000000000000000, block.timestamp, address(this)));
    }
}