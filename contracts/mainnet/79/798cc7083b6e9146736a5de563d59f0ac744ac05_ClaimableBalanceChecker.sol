/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IStakingModuleB {
  function claimable(address account, bytes calldata auxData) external view returns (uint256);
}

/**
 * @title ClaimableBalanceChecker
 * @author Amir Shirif, Telcoin, LLC.
 * @notice Returns current claimable balance
 */
contract ClaimableBalanceChecker is IERC20 {

  IStakingModuleB public immutable _stakingContract;

  constructor(IStakingModuleB stakingContract_) {
    _stakingContract = stakingContract_;
  }

  function balanceOf(address wallet) public view override returns (uint256) {
    return _stakingContract.claimable(wallet, '');
  }
}