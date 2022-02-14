// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFishDividends.sol";

import "./BaseCompoundStrategy.sol";

contract CompoundChef is BaseCompoundStrategy {
    using SafeERC20 for IERC20;

    function _vaultDeposit(uint256 amount) internal override {
        IERC20(stakeToken).safeIncreaseAllowance(masterChef, amount);
        IFishDividends(masterChef).deposit(pid, amount);
    }

    function _vaultHarvest() internal override {
        IFishDividends(underlyingStrategy).harvest();
    }

    function _vaultWithdraw(uint256 amount) internal override {
        IFishDividends(masterChef).withdraw(pid, amount);
    }

    function _vaultEmergencyWithdraw() internal override {
        IFishDividends(masterChef).withdrawAll(pid);
    }

    function _totalStakedTokens() internal view override returns (uint256) {
        return IFishDividends(masterChef).stakedWantTokens(pid, address(this));
    }
}