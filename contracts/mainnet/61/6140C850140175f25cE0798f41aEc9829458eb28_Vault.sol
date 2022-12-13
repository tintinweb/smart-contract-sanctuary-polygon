// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./TokensRecoverable.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./RootedTransferGate.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";
import "./IVault.sol";
import "./IFloorCalculator.sol";

contract Vault is TokensRecoverable, IVault
{
    using SafeMath for uint256;

    IUniswapV2Router02 immutable uniswapRouter;
    IUniswapV2Factory immutable uniswapFactory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC20 immutable usd;
    IERC31337 immutable elite;
    IERC20 rootedEliteLP;
    IERC20 rootedBaseLP;
    IERC20 rootedUsdLP;
    IFloorCalculator public calculator;
    RootedTransferGate public gate;
    mapping(address => bool) public seniorVaultManager;

    constructor(IERC20 _base, IERC20 _usd, IERC31337 _elite, IERC20 _rooted, IFloorCalculator _calculator, RootedTransferGate _gate, IUniswapV2Router02 _uniswapRouter) 
    {        
        base = _base;
        elite = _elite;
        usd = _usd;
        rooted = _rooted;
        calculator = _calculator;
        gate = _gate;
        uniswapRouter = _uniswapRouter;
        uniswapFactory = IUniswapV2Factory(_uniswapRouter.factory());
        
        _base.approve(address(_elite), uint256(-1));
        _base.approve(address(_uniswapRouter), uint256(-1));
        _rooted.approve(address(_uniswapRouter), uint256(-1));
        _elite.approve(address(_uniswapRouter), uint256(-1));
        _usd.approve(address(_uniswapRouter), uint256(-1));
    }

    function setupPools() public ownerOnly() {
        rootedBaseLP = IERC20(uniswapFactory.getPair(address(base), address(rooted)));
        rootedBaseLP.approve(address(uniswapRouter), uint256(-1));
       
        rootedEliteLP = IERC20(uniswapFactory.getPair(address(elite), address(rooted)));
        rootedEliteLP.approve(address(uniswapRouter), uint256(-1));

        rootedUsdLP = IERC20(uniswapFactory.getPair(address(usd), address(rooted)));
        rootedUsdLP.approve(address(uniswapRouter), uint256(-1));
    }

    modifier seniorVaultManagerOnly()
    {
        require(seniorVaultManager[msg.sender], "Not a Senior Vault Manager");
        _;
    }

    // Owner function to enable other contracts or addresses to use the Vault
    function setSeniorVaultManager(address managerAddress, bool allow) public ownerOnly()
    {
        seniorVaultManager[managerAddress] = allow;
    }

    function setCalculatorAndGate(IFloorCalculator _calculator, RootedTransferGate _gate) public ownerOnly()
    {
        calculator = _calculator;
        gate = _gate;
    }

    // Standard swaps with v2 router
    function swap(uint amountIn, uint amountOutMin, address[] calldata path) public override seniorVaultManagerOnly() {
        uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
    }

    function swapSupportingFee(uint amountIn, uint amountOutMin, address[] calldata path) public override seniorVaultManagerOnly() {
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
    }

    // Removes liquidity, buys from either pool, sets a temporary dump tax
    function removeBuyAndTax(uint256 amount, uint256 minAmountOut, address token, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        amount = removeLiq(token, amount);
        buyRootedToken(token, amount, minAmountOut);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }

    // Use Base tokens held by this contract to buy from the Base Pool and sell in the Elite Pool
    function balancePriceBase(uint256 amount, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        uint balance = base.balanceOf(address(this));
        amount = buyRootedToken(address(base), amount, 0);
        amount = sellRootedToken(address(elite), amount, minAmountOut);
        elite.withdrawTokens(amount);
        require(balance < base.balanceOf(address(this)));
    }

    // Use Base tokens held by this contract to buy from the Elite Pool and sell in the Base Pool
    function balancePriceElite(uint256 amount, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        uint balance = base.balanceOf(address(this));
        elite.depositTokens(amount);
        amount = buyRootedToken(address(elite), amount, 0);
        amount = sellRootedToken(address(base), amount, minAmountOut);
        require(balance < base.balanceOf(address(this)));
    }

    // Uses value in the controller to buy
    function buyAndTax(address token, uint256 amountToSpend, uint256 minAmountOut, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        buyRootedToken(token, amountToSpend, minAmountOut);
        gate.setDumpTax(tax, time);
    }

    // Sweeps the Base token under the floor to this address
    function sweepFloor() public override seniorVaultManagerOnly()
    {
        elite.sweepFloor(address(this));
    }

    function wrapToElite(uint256 baseAmount) public override seniorVaultManagerOnly() 
    {
        elite.depositTokens(baseAmount);
    }

    function unwrapElite(uint256 eliteAmount) public override seniorVaultManagerOnly() 
    {
        elite.withdrawTokens(eliteAmount);
    }

    function buyRooted(address token, uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        buyRootedToken(token, amountToSpend, minAmountOut);
    }

    function sellRooted(address token, uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        sellRootedToken(token, amountToSpend, minAmountOut);
    }

    function addLiquidity(address pairedToken, uint256 pairedAmount, uint256 rootedAmount, uint256 pairedAmountMin, uint256 rootedAmountMin) public override seniorVaultManagerOnly() 
    {
        gate.setUnrestricted(true);
        uniswapRouter.addLiquidity(address(pairedToken), address(rooted), pairedAmount, rootedAmount, pairedAmountMin, rootedAmountMin, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    function removeLiquidity(address pairedToken, uint256 lpTokens, uint256 pairedAmountMin, uint256 rootedAmountMin) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        uniswapRouter.removeLiquidity(address(pairedToken), address(rooted), lpTokens, pairedAmountMin, rootedAmountMin, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }


    // internal functions
    function buyRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, buyPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function sellRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, sellPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function removeLiq(address eliteOrBase, uint256 tokens) internal returns (uint256)
    {
        (tokens, ) = uniswapRouter.removeLiquidity(address(eliteOrBase), address(rooted), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }

    function buyPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rooted);
        return path;
    }

    function sellPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(token);
        return path;
    }
}