//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceFeed {
  function token() external view returns (address);

  function price() external view returns (uint256);

  function pricePoint() external view returns (uint256);

  function emitPriceSignal() external;

  event PriceUpdate(address token, uint256 price, uint256 average);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";

interface ITokenPriceFeed is IOwnable {
  struct TokenInfo {
    address priceFeed;
    uint256 mcr;
    uint256 mrf; // Maximum Redemption Fee
  }

  function tokenPriceFeed(address) external view returns (address);

  function tokenPrice(address _token) external view returns (uint256);

  function mcr(address _token) external view returns (uint256);

  function mrf(address _token) external view returns (uint256);

  function setTokenPriceFeed(
    address _token,
    address _priceFeed,
    uint256 _mcr,
    uint256 _maxRedemptionFeeBasisPoints
  ) external;

  function emitPriceUpdate(
    address _token,
    uint256 _priceAverage,
    uint256 _pricePoint
  ) external;

  event NewTokenPriceFeed(address _token, address _priceFeed, string _name, string _symbol, uint256 _mcr, uint256 _mrf);
  event PriceUpdate(address token, uint256 priceAverage, uint256 pricePoint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IPriceFeed.sol";
import "./interfaces/ITokenPriceFeed.sol";

interface ITellorFeed {
  function getCurrentValue(bytes32 _queryId) external view returns (bytes calldata _value);
}

contract TellorPriceFeed is IPriceFeed {
  ITellorFeed public immutable oracle;
  address public immutable override token;
  bytes32 public immutable queryId;

  constructor(
    address _oracle,
    address _token,
    bytes32 _queryId
  ) {
    require(_oracle != address(0x0), "e2637b _oracle must not be address 0x0");
    require(_token != address(0x0), "e2637b _token must not be address 0x0");
    require(_queryId.length > 0, "e2637b _queryId must not be 0 length");

    token = _token;
    oracle = ITellorFeed(_oracle);
    queryId = _queryId;
  }

  function price() public view virtual override returns (uint256) {
    return uint256(bytes32(oracle.getCurrentValue(queryId)));
  }

  function pricePoint() public view override returns (uint256) {
    return price();
  }

  function emitPriceSignal() public override {
    emit PriceUpdate(token, price(), price());
  }
}