// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {SystemAccessControl} from "./access/SystemAccessControl.sol";
import {IAggregatorV3} from "./interfaces/chainlink/IAggregatorV3.sol";
import {IFujiOracle} from "./interfaces/IFujiOracle.sol";

/**
 * @dev Contract that returns and computes prices for the Fuji protocol
 */

contract FujiOracle is IFujiOracle, SystemAccessControl {
  error FujiOracle__lengthMismatch();
  error FujiOracle__noZeroAddress();
  error FujiOracle__noPriceFeed();
  error FujiOracle_invalidPriceFeedDecimals(address priceFeed);

  // mapping from asset address to its price feed oracle in USD - decimals: 8
  mapping(address => address) public usdPriceFeeds;

  /**
   * @dev Initializes the contract setting '_priceFeeds' addresses for '_assets'
   */
  constructor(
    address[] memory assets,
    address[] memory priceFeeds,
    address chief_
  )
    SystemAccessControl(chief_)
  {
    if (assets.length != priceFeeds.length) {
      revert FujiOracle__lengthMismatch();
    }

    for (uint256 i = 0; i < assets.length; i++) {
      _validatePriceFeedDecimals(priceFeeds[i]);
      usdPriceFeeds[assets[i]] = priceFeeds[i];
    }
  }

  /**
   * @dev Sets '_priceFeed' address for a '_asset'.
   * Can only be called by the contract TIMELOCK_ADMIN_ROLE in {Chief}.
   * Emits a {AssetPriceFeedChanged} event.
   */
  function setPriceFeed(address asset, address priceFeed) public onlyTimelock {
    if (priceFeed == address(0)) {
      revert FujiOracle__noZeroAddress();
    }

    _validatePriceFeedDecimals(priceFeed);

    usdPriceFeeds[asset] = priceFeed;
    emit AssetPriceFeedChanged(asset, priceFeed);
  }

  /**
   * @dev Calculates the exchange rate between two assets, with price oracle given in specified decimals.
   * Format is: (_currencyAsset per unit of _commodityAsset Exchange Rate).
   * @param _currencyAsset: the currency asset, zero-address for USD.
   * @param _commodityAsset: the commodity asset, zero-address for USD.
   * @param _decimals: the decimals of the price output.
   * Returns the exchange rate of the given pair.
   */
  function getPriceOf(
    address _currencyAsset,
    address _commodityAsset,
    uint8 _decimals
  )
    external
    view
    override
    returns (uint256 price)
  {
    price = 10 ** uint256(_decimals);

    if (_commodityAsset != address(0)) {
      price = price * _getUSDPrice(_commodityAsset);
    } else {
      price = price * (10 ** 8);
    }

    if (_currencyAsset != address(0)) {
      price = price / _getUSDPrice(_currencyAsset);
    } else {
      price = price / (10 ** 8);
    }
  }

  /**
   * @dev Calculates the USD price of asset.
   * @param _asset: the asset address.
   * Returns the USD price of the given asset
   */
  function _getUSDPrice(address _asset) internal view returns (uint256 price) {
    if (usdPriceFeeds[_asset] == address(0)) {
      revert FujiOracle__noPriceFeed();
    }

    (, int256 latestPrice,,,) = IAggregatorV3(usdPriceFeeds[_asset]).latestRoundData();

    price = uint256(latestPrice);
  }

  function _validatePriceFeedDecimals(address priceFeed) internal view {
    if (IAggregatorV3(priceFeed).decimals() != 8) {
      revert FujiOracle_invalidPriceFeedDecimals(priceFeed);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl.
 * @author Fujidao Labs
 * @notice Helper contract that should be inherited by contract implementations that
 * should call {Chief} for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyHouseKeeper_notHouseKeeper();

  IChief public immutable chief;

  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  modifier onlyHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyHouseKeeper_notHouseKeeper();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  constructor(address chief_) {
    chief = IChief(chief_);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Chief helper interface.
 * @author Fujidao Labs
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  function timelock() external view returns (address);

  function addrMapper() external view returns (address);

  function allowedFlasher(address flasher) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IFujiOracle {
  // FujiOracle Events

  /**
   * @dev Log a change in price feed address for asset address
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAggregatorV3 {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}