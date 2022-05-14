// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManagerBasicFollowingPriceMock {
  struct PriceData {
    uint128 previousPrice;
    uint128 currentPrice;
    bool wasIntermediatePrice;
  }

  function initializeOracle() external returns (uint128 initialPrice);

  function updatePrice() external returns (PriceData memory);

  /*
   * Returns the latest price from the oracle feed.
   */
  function latestPrice() external view returns (uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../interfaces/IOracleManagerBasicFollowingPriceMock.sol";

/*
 * Mock implementation of an OracleManager with fixed, changeable prices.
 */
contract OracleManagerBasicFollowingPriceMock is IOracleManagerBasicFollowingPriceMock {
  // Admin contract.
  address public admin;
  address public longShort;

  uint128 public override latestPrice;
  uint128 public nextPrice;
  // uint128[] public nextPrices;

  bool public isPublic;

  // IOracleManagerNthPrice.PriceData public currentPriceInfo;

  ////////////////////////////////////
  /////////// MODIFIERS //////////////
  ////////////////////////////////////

  modifier adminOnly() {
    require(msg.sender == admin, "Not admin");
    _;
  }
  modifier longShortOnly() {
    require(msg.sender == longShort, "Not longShort");
    _;
  }
  modifier isPublicOnly() {
    require(isPublic, "Not public");
    _;
  }

  ////////////////////////////////////
  ///// CONTRACT SET-UP //////////////
  ////////////////////////////////////

  constructor(
    address _admin,
    address _longShort,
    uint128 initialPrice,
    bool _isPublic
  ) {
    admin = _admin;
    longShort = _longShort;
    latestPrice = initialPrice;
    isPublic = _isPublic;
  }

  ////////////////////////////////////
  ///// IMPLEMENTATION ///////////////
  ////////////////////////////////////

  function _setRewPrice(uint128 _newPrice) internal {
    nextPrice = _newPrice;
  }

  function setRewPrice(uint128 newPrice) public adminOnly {
    _setRewPrice(newPrice);
  }

  function setRewPricePublic(uint128 newPrice) public isPublicOnly {
    _setRewPrice(newPrice);
  }

  function initializeOracle() external view returns (uint128 initialPrice) {
    // IN the mock this does nothing.
    return latestPrice;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a < b) {
      return a;
    } else {
      return b;
    }
  }

  // NOTE - this HAS to be `onlyLongShort`
  function updatePrice()
    external
    override
    returns (IOracleManagerBasicFollowingPriceMock.PriceData memory)
  {
    IOracleManagerBasicFollowingPriceMock.PriceData
      memory exampleRespones = IOracleManagerBasicFollowingPriceMock.PriceData(
        latestPrice,
        nextPrice,
        false
      );

    if (nextPrice > 0) {
      latestPrice = nextPrice;
      nextPrice = 0;
    }
    return exampleRespones;
  }
}