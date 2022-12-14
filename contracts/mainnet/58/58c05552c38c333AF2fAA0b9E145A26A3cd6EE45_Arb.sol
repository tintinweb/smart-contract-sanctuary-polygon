// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./Owned.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IArb.sol";
import "./RootedTransferGate.sol";

contract Arb is Owned, IArb {
    using SafeMath for uint256;

    IUniswapV2Router02 immutable uniswapRouter;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC20 immutable usd;
    IERC31337 immutable elite;
    RootedTransferGate immutable gate;
    address immutable multisig;
    mapping(address => bool) public arbManager;

    constructor(IERC20 _base, IERC20 _usd, IERC31337 _elite, IERC20 _rooted, IUniswapV2Router02 _uniswapRouter, RootedTransferGate _gate, address _multisig) {
        base = _base;
        elite = _elite;
        usd = _usd;
        rooted = _rooted;
        uniswapRouter = _uniswapRouter;
        gate = _gate;
        multisig = _multisig;
        
        _base.approve(address(_elite), uint256(-1));
        _base.approve(address(_uniswapRouter), uint256(-1));
        _rooted.approve(address(_uniswapRouter), uint256(-1));
        _elite.approve(address(_uniswapRouter), uint256(-1));
        _usd.approve(address(_uniswapRouter), uint256(-1));
    }

    modifier arbManagerOnly() {
        require(arbManager[msg.sender], "Not an arb Manager");
        _;
    }

    // Owner function to enable other contracts or addresses to use the Vault
    function setArbManager(address managerAddress, bool allow) public ownerOnly() {
        arbManager[managerAddress] = allow;
    }

    function withdrawTokensToMultisig(IERC20 token, uint256 amount) public override {
        require (arbManager[msg.sender] || msg.sender == multisig || msg.sender == owner);
        token.transfer(multisig, amount);
    }

    function balanceBaseUsd(uint256 amount, uint256 minAmountOut) public override arbManagerOnly() {
        require (minAmountOut > amount);
        gate.setUnrestricted(true);
        address[] memory path = new address[](4);
        path[0] = address(base);
        path[1] = address(usd);
        path[2] = address(rooted);
        path[3] = address(base);
        uniswapRouter.swapExactTokensForTokens(amount, minAmountOut, path, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    function balanceUsdBase(uint256 amount, uint256 minAmountOut) public override arbManagerOnly() {
        require (minAmountOut > amount);
        gate.setUnrestricted(true);
        address[] memory path = new address[](4);
        path[0] = address(base);
        path[1] = address(rooted);
        path[2] = address(usd);
        path[3] = address(base);
        uniswapRouter.swapExactTokensForTokens(amount, minAmountOut, path, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    function balancePriceBase(uint256 amount, uint256 minAmountOut) public override arbManagerOnly() {
        require (minAmountOut > amount);
        gate.setUnrestricted(true);
        address[] memory path = new address[](3);
        path[0] = address(base);
        path[1] = address(rooted);
        path[2] = address(elite);
        uniswapRouter.swapExactTokensForTokens(amount, minAmountOut, path, address(this), block.timestamp);
        elite.withdrawTokens(amount);
        gate.setUnrestricted(false);
    }

    function balancePriceElite(uint256 amount, uint256 minAmountOut) public override arbManagerOnly() {
        require (minAmountOut > amount);
        gate.setUnrestricted(true);
        elite.depositTokens(amount);
        address[] memory path = new address[](3);
        path[0] = address(elite);
        path[1] = address(rooted);
        path[2] = address(base);
        uniswapRouter.swapExactTokensForTokens(amount, minAmountOut, path, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    function recoverTokens(IERC20 token) public ownerOnly() {
        require(address(token) != address(base) && address(token) != address(usd) && address(token) != address(elite) && address(token) != address(rooted));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // internal functions
    function buyRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rooted);
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, path, address(this), block.timestamp);
        return amounts[1];
    }

    function sellRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(token);
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, path, address(this), block.timestamp);
        return amounts[1];
    }
}