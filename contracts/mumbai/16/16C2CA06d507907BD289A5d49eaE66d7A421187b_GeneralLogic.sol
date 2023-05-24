// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title GeneralLogic library
 * @author Aave
 * @notice Implements the logic for General specific functions
 */
library GeneralLogic{
  uint256 internal constant RATE_PRECISION = 1000000;

  function getUserBalanceInBaseCurrency(address asset, uint256 amount, address oracle) external view returns (uint256) {
    if(amount == 0) return 0;
    uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(asset);
    uint8 decimals = IERC20Detailed(asset).decimals();
    uint256 assetUnit = 10 ** decimals;
    return amount * assetPrice / assetUnit;
  }

  function getBaseCurrencyInBalance(address asset, uint256 baseCurrency, address oracle) external view returns (uint256) {
    if(baseCurrency == 0) return 0;
    uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(asset);
    uint8 decimals = IERC20Detailed(asset).decimals();
    uint256 assetUnit = 10 ** decimals;
    return baseCurrency * assetUnit /  assetPrice;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library DataTypes {
  struct ReserveData {
    // stores the reserve configuration
    ReserveConfigurationMap configuration;
    // supplying asset address
    address supplyingAsset;
    // prxy asset address
    address prxyAsset;
    // the supply rate.
    uint256 supplyRate;   // Dynamic Rate
    // the borrow rate.
    uint256 borrowRate;   // Fixed Rate
    // the uncollateral prxy rate.
    uint256 prxyRate;     // Fixed Rate
    // the collateral prxy rate.
    uint256 prxyRate2;     // Fixed Rate
    // the split rate.
    uint256 splitRate;    // Fixed Rate
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //pToken address
    address pTokenAddress;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused
    uint256 data;
  }

  struct UserList {
    address[] list;
    mapping(address => uint256) ids;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    uint16 referralCode;
    uint256 reservesCount;
  }

  struct ExecuteBorrowParams {
    address asset;
    address borrowingAsset;
    uint256 amount;
    uint16 referralCode;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteRepayParams {
    address asset;
    address borrowingAsset;
    uint256 amount;
    uint256 reservesCount;
  }

  struct ExecuteLiquidationCallParams {
    address user;
    address asset;
    address oracle;
    uint256 reservesCount;
  }

  struct InitReserveParams {
    address supplyingAsset;
    uint256 borrowRate;
    uint256 prxyRate;
    uint256 prxyRate2;
    uint256 splitRate;
    address pTokenAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }

  struct CalculateUserAccountDataParams {
    address user;
    address asset;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteSplitReduxInterestParams {
    address asset;
    address daoWallet;
    address oracle;
    uint256 reservesCount;
    uint256 elapsedTime;
  }

  struct ExecuteClaimPrxyParams {
    address asset;
    uint256 amount;
    address prxyTreasury;
  }

  struct ExecuteSwitchSupplyModeParams {
    address asset;
  }

  struct ExecuteAddFundParams {
    address asset;
    uint256 amount;
  }

  struct ExecuteRemoveFundParams {
    address asset;
    uint256 amount;
  }

  struct ExecuteRecoverTokenParams {
    address user;
    address asset;
    uint256 amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}