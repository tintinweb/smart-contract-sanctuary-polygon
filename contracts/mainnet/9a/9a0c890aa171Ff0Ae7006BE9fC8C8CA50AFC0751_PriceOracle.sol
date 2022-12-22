// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IPriceOracle.sol";
import "../integrations/aave3/IAavePriceOracle.sol";

/// @notice Trivial implementation of a price oracle as a wrapper of AAVE3 price oracle
contract PriceOracle is IPriceOracle {
  address public constant AAVE3_PRICE_ORACLE = 0xb023e699F5a33916Ea823A16485e259257cA8Bd1;
  IAavePriceOracle immutable _priceOracle;

  constructor() {
    _priceOracle = IAavePriceOracle(AAVE3_PRICE_ORACLE);
  }

  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view override returns (uint256) {
    // AAVE3 price oracle returns price with decimals 1e8, we need decimals 18
    try _priceOracle.getAssetPrice(asset) returns (uint value) {
      return value * 1e10;
    } catch {}

    return 0; // unknown asset or unknown price
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @notice Restored from 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654 (events were removed)
interface IAavePriceOracle {
  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (address);
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);
  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);
  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] memory assets) external view returns (uint256[] memory);
  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);
  function setAssetSources(address[] memory assets, address[] memory sources) external;
  function setFallbackOracle(address fallbackOracle) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPriceOracle {
  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view returns (uint256);
}