// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Interface/IPriceOracleGetter.sol';

contract MockPriceOracleGetter is IPriceOracleGetter {
  mapping(address => uint256) prices;
  uint256 ethPriceUsd;

  event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
  event EthPriceUpdated(uint256 _price, uint256 timestamp);

  function getAssetPrice(address _asset) external view override returns (uint256) {
    return prices[_asset];
  }

  function setAssetPrice(address _asset, uint256 _price) external {
    prices[_asset] = _price;
    emit AssetPriceUpdated(_asset, _price, block.timestamp);
  }

  function getEthUsdPrice() external view returns (uint256) {
    return ethPriceUsd;
  }

  function setEthUsdPrice(uint256 _price) external {
    ethPriceUsd = _price;
    emit EthPriceUpdated(_price, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH (wad)
   */
  function getAssetPrice(address asset) external view returns (uint256);

}