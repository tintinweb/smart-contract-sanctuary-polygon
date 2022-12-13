/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IStakingModuleA {
  function stakedBy(address account) external view returns (uint256);
}

/**
 * @title StakeBalanceChecker
 * @author Amir Shirif, Telcoin, LLC.
 * @notice Returns current staked balance
 */
contract StakeBalanceChecker is IERC20 {

  IStakingModuleA public immutable _stakingContract;

  constructor(IStakingModuleA stakingContract_) {
    _stakingContract = stakingContract_;
  }

  function balanceOf(address wallet) public view override returns (uint256) {
    return _stakingContract.stakedBy(wallet);
  }
}