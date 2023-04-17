// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface AffiliateContract {
  function payCommissions(address seller, uint256 amount, address tokenAddress) external returns (address);
}

contract MarketplaceMock {
  AffiliateContract affContract;
  function setAffiliateContract(address affiliateContract) external {
    affContract = AffiliateContract(affiliateContract);
  }
  function sellNative(address seller, uint256 amount) external {
    affContract.payCommissions(seller, amount, address(0));
  }

  function sellUSDT(address seller, uint256 amount, address usdtAddress) external {
    affContract.payCommissions(seller, amount, usdtAddress);
  }
}