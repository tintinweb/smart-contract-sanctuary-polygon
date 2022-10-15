/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface BIFIMaxi {
  function getPricePerFullShare() external view returns (uint256);
}

struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

interface GiddyPool {
    function userInfo(uint256, address) external view returns (UserInfo memory); 
    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;
}

contract BIFIGiddyBalance {

  BIFIMaxi public maxi;
  GiddyPool public giddyPool;

  constructor(BIFIMaxi _bifiMaxiVault, GiddyPool _giddyPool) {
    maxi = _bifiMaxiVault;
    giddyPool = _giddyPool;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint ppfs = maxi.getPricePerFullShare();
    return giddyPool.userInfo(9, account).amount * ppfs/ 1e18;
  }

}