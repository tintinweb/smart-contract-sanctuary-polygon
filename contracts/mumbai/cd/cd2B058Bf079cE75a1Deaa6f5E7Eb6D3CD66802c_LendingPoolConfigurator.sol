// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from '../Interface/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../Interface/ILendingPool.sol';
import {IERC20Detailed} from '../Dependency/openzeppelin/IERC20Detailed.sol';
import {Errors} from '../Library/Helper/Errors.sol';
import {PercentageMath} from '../Library/Math/PercentageMath.sol';
import {DataTypes} from '../Library/Type/DataTypes.sol';
import {ILendingPoolConfigurator} from '../Interface/ILendingPoolConfigurator.sol';
import {KToken} from '../Token/KToken.sol';
import {DToken} from '../Token/DToken.sol';

contract LendingPoolConfigurator is ILendingPoolConfigurator {
  using PercentageMath for uint256;

  ILendingPoolAddressesProvider internal addressesProvider;
  ILendingPool internal pool;

  modifier onlyMainAdmin {
    require(addressesProvider.getMainAdmin() == msg.sender, Errors.GetError(Errors.Error.CALLER_NOT_MAIN_ADMIN));
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      addressesProvider.getEmergencyAdmin() == msg.sender,
      Errors.GetError(Errors.Error.CALLER_NOT_EMERGENCY_ADMIN)
    );
    _;
  }

  constructor(
    ILendingPoolAddressesProvider provider,
    ILendingPool lending_pool
  ) {
    addressesProvider = provider;
    pool = lending_pool;
  }

  /**
   * @dev Initializes reserves in batch
   **/
  function batchInitReserve(InitReserveInput[] calldata input) external onlyMainAdmin {
    ILendingPool cachedPool = pool;
    for (uint256 i = 0; i < input.length; i++) {
      _initReserve(cachedPool, input[i]);
    }
  }

  function initReserve(InitReserveInput calldata input) external onlyMainAdmin {
    ILendingPool cachedPool = pool;
    _initReserve(cachedPool, input);
  }

  function _initReserve(ILendingPool _pool, InitReserveInput calldata input) internal {
    KToken kToken = new KToken(
      _pool,
      input.treasury,
      input.underlyingAsset,
      input.kTokenDecimals,
      input.kTokenName,
      input.kTokenSymbol
    );
    address kTokenAddress = address(kToken);

    DToken dToken = new DToken(
      _pool,
      input.underlyingAsset,
      input.dTokenDecimals,
      input.dTokenName,
      input.dTokenSymbol
    );
    address dTokenAddress = address(dToken);

    pool.initReserve(
      input.underlyingAsset,
      kTokenAddress,
      dTokenAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfiguration memory currentConfig =
      pool.getConfiguration(input.underlyingAsset);

    currentConfig.decimals = input.underlyingAssetDecimals;
    currentConfig.active = true;
    currentConfig.frozen = false;

    pool.setConfiguration(input.underlyingAsset, currentConfig);

    emit ReserveInitialized(
      input.underlyingAsset,
      kTokenAddress,
      dTokenAddress,
      input.interestRateStrategyAddress
    );
  }

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableBorrowingOnReserve(address asset)
    external
    onlyMainAdmin
  {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);

    currentConfig.borrowingEnabled = true;

    pool.setConfiguration(asset, currentConfig);

    emit BorrowingEnabledOnReserve(asset);
  }

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);

    currentConfig.borrowingEnabled = false;

    pool.setConfiguration(asset, currentConfig);
    emit BorrowingDisabledOnReserve(asset);
  }

  /**
   * @dev Configures the reserve collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);

    // validation of the parameters: the LTV can
    // only be lower or equal than the liquidation threshold
    // (otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.GetError(Errors.Error.LPC_INVALID_CONFIGURATION));

    if (liquidationThreshold != 0) {
      //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      //collateral than needed to cover the debt
      require(
        liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
        Errors.GetError(Errors.Error.LPC_INVALID_CONFIGURATION)
      );

      //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      //a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
        Errors.GetError(Errors.Error.LPC_INVALID_CONFIGURATION)
      );
    } else {
      require(liquidationBonus == 0, Errors.GetError(Errors.Error.LPC_INVALID_CONFIGURATION));
      // if the liquidation threshold is being set to 0,
      // the reserve is being disabled as collateral. To do so,
      // we need to ensure no liquidity is supplied
      _checkNoLiquidity(asset);
    }

    currentConfig.ltv = ltv;
    currentConfig.liquidationThreshold = liquidationThreshold;
    currentConfig.liquidationBonus = liquidationBonus;

    pool.setConfiguration(asset, currentConfig);

    emit CollateralConfigurationChanged(asset, ltv, liquidationThreshold, liquidationBonus);
  }

  function configureReservePosition(
    address asset,
    bool collateralEnabled,
    bool longEnabled,
    bool shortEnabled
  ) external onlyMainAdmin {
    DataTypes.ReservePositionConfiguration memory positionConfig =
      DataTypes.ReservePositionConfiguration(
        false,
        collateralEnabled,
        longEnabled,
        shortEnabled
      );
    
    pool.setPositionConfiguration(asset, positionConfig);
    emit PositionConfigurationChanged(collateralEnabled, longEnabled, shortEnabled);
  }

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);

    currentConfig.active = true;

    pool.setConfiguration(asset, currentConfig);

    emit ReserveActivated(asset);
  }

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external onlyMainAdmin {
    _checkNoLiquidity(asset);

    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);

    currentConfig.active = false;

    pool.setConfiguration(asset, currentConfig);

    emit ReserveDeactivated(asset);
  }

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new supply, borrow or rate swap
   *  but allows repayments, liquidations, rate rebalances and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);
    currentConfig.frozen = true;
    pool.setConfiguration(asset, currentConfig);
    emit ReserveFrozen(asset);
  }

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);
    currentConfig.frozen = false;
    pool.setConfiguration(asset, currentConfig);
    emit ReserveUnfrozen(asset);
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external onlyMainAdmin {
    DataTypes.ReserveConfiguration memory currentConfig = pool.getConfiguration(asset);
    currentConfig.reserveFactor = reserveFactor;
    pool.setConfiguration(asset, currentConfig);
    emit ReserveFactorChanged(asset, reserveFactor);
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    onlyMainAdmin
  {
    pool.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
    emit ReserveInterestRateStrategyChanged(asset, rateStrategyAddress);
  }

  function activateReservePosition(address asset) external onlyMainAdmin {
    DataTypes.ReservePositionConfiguration memory currentPositionConfig = pool.getPositionConfiguration(asset);
    currentPositionConfig.active = true;
    pool.setPositionConfiguration(asset, currentPositionConfig);

    emit ReservePositionActivated(asset);
  }

  // Note: trader can close position, but cannot open position with the asset after is deactivated
  function deactivateReservePosition(address asset) external onlyMainAdmin {
    DataTypes.ReservePositionConfiguration memory currentPositionConfig = pool.getPositionConfiguration(asset);
    currentPositionConfig.active = false;
    pool.setPositionConfiguration(asset, currentPositionConfig);

    emit ReservePositionDeactivated(asset);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including kToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    pool.setPause(val);
  }

  function _checkNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

    uint256 availableLiquidity = IERC20Detailed(asset).balanceOf(reserveData.kTokenAddress);

    require(
      availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
      Errors.GetError(Errors.Error.LPC_RESERVE_LIQUIDITY_NOT_0)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress);
  event PoolAdded(address pool_address, address configuratorAddress);
  event LendingPoolUpdated(uint id, address pool, address lending_pool_configurator_address);
  event PoolRemoved(address pool_address);
  event SwapRouterUpdated(address dex);

  function getAllPools() external view returns (address[] memory);

  /**
   * @dev Returns the address of the LendingPool by id
   * @return The LendingPool address, if pool is valid
   **/
  function getLendingPool(uint id) external view returns (address, bool);

  function getLendingPoolID(address pool) external view returns (uint);

  function getLendingPoolConfigurator(address pool) external view returns (address);

  /**
   * @dev Updates the address of the LendingPool
   * @param pool The new LendingPool implementation
   **/
  function setLendingPool(uint id, address pool, address poolConfiguratorAddress) external;

  function addPool(address poolAddress, address poolConfiguratorAddress) external;

  function removePool(address poolAddress) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  function getMainAdmin() external view returns (address);

  function setMainAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracleAddress) external;

  function getSwapRouter() external view returns (address);

  function setSwapRouter(address dex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from '../Library/Type/DataTypes.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {IAggregationRouterV4} from './1inch/IAggregationRouterV4.sol';

interface ILendingPool {
  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the kTokens
   * @param amount The amount supplied
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of kTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receivekToken `true` if the liquidators wants to receive the collateral kTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receivekToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  event OpenPosition(
    address trader,
    address collateralTokenAddress,
    address shortTokenAddress,
    uint256 collateralAmount,
    uint256 shortAmount,
    uint256 liquidationThreshold,
    uint id
  );

  event ClosePosition(
    uint256 id,
    address traderAddress,
    address collateralTokenAddress,
    uint256 collateralAmount,
    address shortTokenAddress,
    uint256 shortAmount
  );

  event LiquidationCallPosition(
    uint256 id,
    address liquidator,
    address traderAddress,
    address collateralTokenAddress,
    uint256 collateralAmount,
    address shortTokenAddress,
    uint256 shortAmount
  );

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  /**
   * @dev Supply an `amount` of underlying asset into the reserve, receiving in return overlying kTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 kUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the kTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of kTokens
   *   is a different wallet
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent kTokens owned
   * E.g. User has 100 kUSDC, calls withdraw() and receives 100 USDC, burning the 100 kUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole kToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral `true` if the user wants to use the supply as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receivekToken `true` if the liquidators wants to receive the collateral kTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receivekToken
  ) external;

  /**
   * @dev Open a position, supply margin and borrow from pool. Traders should 
   * approve pools at first for the transfer of their assets
   * @param collateralAsset The address of asset the trader supply as margin
   * @param shortAsset The address of asset the trader would like to borrow at a leverage
   * @param longAsset The address of asset the pool will hold after swap
   * @param collateralAmount The amount of margin the trader transfers in margin decimals
   * @param leverage The leverage specified by user in ray
   **/
  function openPosition(
    address collateralAsset,
    address shortAsset,
    address longAsset,
    uint256 collateralAmount,
    uint256 leverage,
    uint256 minLongAmountOut,
    address onBehalfOf
  )
    external
    returns (
      DataTypes.TraderPosition memory position
    );

  /**
   * @dev Close a position, swap all margin / pnl into paymentAsset
   * @param positionId The id of position
   * @return paymentAmount The amount of asset to payback user 
   * @return pnl The pnl in ETH (wad)
   **/
  function closePosition(
    uint256 positionId,
    address to,
    uint256 minLongToShortAmountOut,
    uint256 minShortToCollateralAmountOut,
    uint256 minCollateralToShortAmountOut
  )
    external
    returns (
      uint256 paymentAmount,
      int256 pnl
    );

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
  
  /**
   * @dev Close a position, swap all margin / pnl into paymentAsset
   * @param id The id of position
   **/
  function liquidationCallPosition(uint id) external;

  function initReserve(
    address reserve,
    address kTokenAddress,
    address dTokenAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, DataTypes.ReserveConfiguration memory configuration) external;

  function setPositionConfiguration(
    address asset,
    DataTypes.ReservePositionConfiguration calldata positionConfig
  ) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfiguration memory);
  
  function getPositionConfiguration(address asset)
    external
    view
    returns (DataTypes.ReservePositionConfiguration memory);

  function getUserConfiguration(address user, uint256 reserve_id)
    external
    view
    returns (bool reserve_is_collateral, bool reserve_for_borrowing);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized debt
   */
  function getReserveNormalizedDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
  
  function getReservesList() external view returns (address[] memory);

  function getUsersList() external view returns (address[] memory);

  function getTradersList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);

  function name() external view returns (string memory);

  function getTraderPositions(address trader) external view returns (DataTypes.TraderPosition[] memory positions);

  function getPositionData(uint256 id) external view returns (int256 pnl, uint256 healthFactor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "../../Dependency/openzeppelin/Strings.sol";

library Errors {
    using Strings for uint256;
    enum Error {
        /** KTOKEN, DTOKEN*/
        CALLER_MUST_BE_LENDING_POOL, // 0
        INVALID_BURN_AMOUNT,
        INVALID_MINT_AMOUNT,
        BORROW_ALLOWANCE_NOT_ENOUGH,
        /** Math library */
        MATH_MULTIPLICATION_OVERFLOW,
        MATH_DIVISION_BY_ZERO, // 5
        MATH_ADDITION_OVERFLOW,
        /** Configuration */
        LENDING_POOL_EXIST,
        LENDING_POOL_NONEXIST,
        /** Permission */
        CALLER_NOT_MAIN_ADMIN,
        CALLER_NOT_EMERGENCY_ADMIN, // 10
        /** LP */
        LP_NOT_CONTRACT,
        LP_IS_PAUSED,
        LP_POSITION_IS_PAUSED,
        LPC_RESERVE_LIQUIDITY_NOT_0,
        LPC_INVALID_CONFIGURATION, // 15
        LP_NO_MORE_RESERVES_ALLOWED,
        LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR,
        LP_LIQUIDATION_CALL_FAILED,
        LP_CALLER_MUST_BE_AN_KTOKEN,
        LP_LEVERAGE_INVALID, // 20
        LP_POSITION_INVALID,
        LP_LIQUIDATE_LP,
        LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN,
        /** Reserve Logic */
        RL_LIQUIDITY_INDEX_OVERFLOW,
        RL_BORROW_INDEX_OVERFLOW,
        RL_RESERVE_ALREADY_INITIALIZED, // 25
        RL_LIQUIDITY_RATE_OVERFLOW,
        RL_BORROW_RATE_OVERFLOW,
        /** Validation Logic */
        VL_INVALID_AMOUNT,
        VL_NO_ACTIVE_RESERVE,
        VL_NO_ACTIVE_RESERVE_POSITION, // 30
        VL_POSITION_COLLATERAL_NOT_ENABLED,
        VL_POSITION_LONG_NOT_ENABLED,
        VL_POSITION_SHORT_NOT_ENABLED,
        VL_RESERVE_FROZEN,
        VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE, // 35
        VL_TRANSFER_NOT_ALLOWED,
        VL_BORROWING_NOT_ENABLED,
        VL_INVALID_INTEREST_RATE_MODE_SELECTED,
        VL_COLLATERAL_BALANCE_IS_0,
        VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD, // 40
        VL_COLLATERAL_CANNOT_COVER_NEW_BORROW,
        VL_NO_DEBT_OF_SELECTED_TYPE,
        VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF,
        VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0,
        VL_SUPPLY_ALREADY_IN_USE, // 45
        VL_TRADER_ADDRESS_MISMATCH,
        VL_POSITION_NOT_OPEN,
        VL_POSITION_NOT_UNHEALTHY,
        VL_INCONSISTENT_FLASHLOAN_PARAMS,
        /** Collateral Manager */
        CM_NO_ERROR, // 50
        CM_NO_ACTIVE_RESERVE,
        CM_HEALTH_FACTOR_ABOVE_THRESHOLD,
        CM_COLLATERAL_CANNOT_BE_LIQUIDATED,
        CM_CURRRENCY_NOT_BORROWED,
        CM_NOT_ENOUGH_LIQUIDITY, // 55
        /** Liquidation Logic */
        LL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD,
        LL_COLLATERAL_CANNOT_BE_LIQUIDATED,
        LL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER,
        LL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE,
        LL_NO_ERRORS // 60
    }

    function GetError(Error error) internal pure returns (string memory error_string) {
        error_string = Strings.toString(uint(error));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../Helper/Errors.sol';

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW)
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW)
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    ReserveConfiguration configuration;
    ReservePositionConfiguration positionConfiguration;
    // the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    // (variable) borrow index. Expressed in ray
    uint128 borrowIndex;
    // the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    // the current borrow rate. Expressed in ray
    uint128 currentBorrowRate;
    // the timestamp 
    uint40 lastUpdateTimestamp;
    // interest token address
    address kTokenAddress;
    // debt token address
    address dTokenAddress;
    // address of the interest rate strategy
    address interestRateStrategyAddress;
    // the id of the reserve
    uint256 id;
  }

  struct ReserveConfiguration {
    // loan-to-value
    uint256 ltv;
    // the liquidation threshold
    uint256 liquidationThreshold;
    // the liquidation bonus
    uint256 liquidationBonus;
    // the decimals
    uint8 decimals;
    // reserve is active
    bool active;
    // reserve is frozen
    bool frozen;
    // borrowing is enabled
    bool borrowingEnabled;
    // reserve factor
    uint256 reserveFactor;
  }

  struct UserConfigurationMap {
    // uint256 data;
    mapping(uint256 => bool) isUsingAsCollateral;
    mapping(uint256 => bool) isBorrowing;
  }

  struct ReservePositionConfiguration {
    // position-related is active
    bool active;
    // position collateral is enabled
    bool collateralEnabled;
    // position long is enabled
    bool longEnabled;
    // position short is enabled
    bool shortEnabled;
  }

  struct TraderPosition {
    // the trader
    address traderAddress;
    // the token as margin
    address collateralTokenAddress;
    // the token to borrow
    address shortTokenAddress;
    // the token held
    address longTokenAddress;
    // the amount of provided margin
    uint256 collateralAmount;
    // the amount of borrowed asset
    uint256 shortAmount;
    // the amount of held asset
    uint256 longAmount;
    // the liquidationThreshold at trade
    uint256 liquidationThreshold;
    // the id of position
    uint256 id;
    // position is open
    bool isOpen;
  }

  enum InterestRateMode {NONE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {
  struct InitReserveInput {
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    string kTokenName;
    string kTokenSymbol;
    uint8 kTokenDecimals;
    string dTokenName;
    string dTokenSymbol;
    uint8 dTokenDecimals;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param kToken The address of the associated kToken contract
   * @param dToken The address of the associated dToken
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed kToken,
    address dToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  event PositionConfigurationChanged(
    bool collateralEnabled,
    bool longEnabled,
    bool shortEnabled
  );

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when a reserve is activated for margin trading
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReservePositionActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated for margin trading
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReservePositionDeactivated(address indexed asset);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {SafeERC20} from '../Dependency/openzeppelin/SafeERC20.sol';
import {ILendingPool} from '../Interface/ILendingPool.sol';
import {IKToken} from '../Interface/IKToken.sol';
import {WadRayMath} from '../Library/Math/WadRayMath.sol';
import {Errors} from '../Library/Helper/Errors.sol';
import {KERC20} from './KERC20.sol';

// TODO
contract KToken is KERC20('KTOKEN_IMPL', 'KTOKEN_IMPL', 0), IKToken {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  ILendingPool internal _pool;
  address internal _treasury;
  address internal _underlyingAsset;

  modifier onlyLendingPool {
    require(_msgSender() == address(_pool), Errors.GetError(Errors.Error.CALLER_MUST_BE_LENDING_POOL));
    _;
  }

  constructor(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    uint8 kTokenDecimals,
    string memory kTokenName,
    string memory kTokenSymbol
  ) {
    _setName(kTokenName);
    _setSymbol(kTokenSymbol);
    _setDecimals(kTokenDecimals);

    _pool = pool;
    _treasury = treasury;
    _underlyingAsset = underlyingAsset;
  }

  /**
   * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the LendingPool, as extra state updates there need to be managed
   * @param user The owner of the kTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.GetError(Errors.Error.INVALID_BURN_AMOUNT));
    _burn(user, amountScaled);

    IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Transfer(user, address(0), amount);
    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` kTokens to `user`
   * - Only callable by the LendingPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.GetError(Errors.Error.INVALID_MINT_AMOUNT));
    _mint(user, amountScaled);

    emit Transfer(address(0), user, amount);
    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Mints kTokens to the reserve treasury
   * - Only callable by the LendingPool
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendingPool {
    if (amount == 0) {
      return;
    }

    address treasury = _treasury;

    // Compared to the normal mint, we don't check for rounding errors.
    // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
    // In that case, the treasury will experience a (very small) loss, but it
    // wont cause potentially valid transactions to fail.
    _mint(treasury, amount.rayDiv(index));

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }

  /**
   * @dev Transfers kTokens in the event of a borrow being liquidated, in case the liquidators reclaims the kToken
   * - Only callable by the LendingPool
   * @param from The address getting liquidated, current owner of the kTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyLendingPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _transfer(from, to, value, false);

    emit Transfer(from, to, value);
  }

  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user)
    public
    view
    override(KERC20, IERC20)
    returns (uint256)
  {
    return super.balanceOf(user).rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev calculates the total supply of the specific kToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply() public view override(KERC20, IERC20) returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    return currentSupplyScaled.rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the Aave treasury, receiving the fees on this kToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  /**
   * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() public override view returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this kToken is used
   **/
  function POOL() public view returns (ILendingPool) {
    return _pool;
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the kTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount)
    external
    override
    onlyLendingPool
    returns (uint256)
  {
    IERC20(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  /**
   * @dev Invoked to execute actions on the kToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external override onlyLendingPool {}

  /**
   * @dev Transfers the kTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate `true` if the transfer needs to be validated
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    address underlyingAsset = _underlyingAsset;
    ILendingPool pool = _pool;

    uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index));

    if (validate) {
      pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  /**
   * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    _transfer(from, to, amount, true);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MathUtils} from '../Library/Math/MathUtils.sol';
import {WadRayMath} from '../Library/Math/WadRayMath.sol';
import {IDToken} from '../Interface/IDToken.sol';
import {ILendingPool} from '../Interface/ILendingPool.sol';
import {Errors} from '../Library/Helper/Errors.sol';
import {KERC20} from './KERC20.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {SafeMath} from '../Dependency/openzeppelin/SafeMath.sol';

contract DToken is KERC20('DEBTTOKEN_IMPL', 'DEBTTOKEN_IMPL', 0), IDToken {
  using WadRayMath for uint256;
  using SafeMath for uint256;

  ILendingPool internal _pool;
  address internal _underlyingAsset;

  constructor(
    ILendingPool pool,
    address underlyingAsset,
    uint8 dTokenDecimals,
    string memory dTokenName,
    string memory dTokenSymbol
  ) {
    _setName(dTokenName);
    _setSymbol(dTokenSymbol);
    _setDecimals(dTokenDecimals);

    _pool = pool;
    _underlyingAsset = underlyingAsset;
  }

  mapping(address => mapping(address => uint256)) internal _borrowAllowances;

  /**
   * @dev Only lending pool can call functions marked by this modifier
   **/
  modifier onlyLendingPool {
    require(_msgSender() == address(_getLendingPool()), Errors.GetError(Errors.Error.CALLER_MUST_BE_LENDING_POOL));
    _;
  }

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external override {
    _borrowAllowances[_msgSender()][delegatee] = amount;
    emit BorrowAllowanceDelegated(_msgSender(), delegatee, _getUnderlyingAssetAddress(), amount);
  }

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser)
    external
    view
    override
    returns (uint256)
  {
    return _borrowAllowances[fromUser][toUser];
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override(KERC20, IERC20)
    returns (uint256)
  {
    owner;
    spender;
    revert('ALLOWANCE_NOT_SUPPORTED');
  }

  function approve(address spender, uint256 amount) public virtual override(KERC20, IERC20) returns (bool) {
    spender;
    amount;
    revert('APPROVAL_NOT_SUPPORTED');
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override(KERC20, IERC20) returns (bool) {
    sender;
    recipient;
    amount;
    revert('TRANSFER_NOT_SUPPORTED');
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    override
    returns (bool)
  {
    spender;
    addedValue;
    revert('ALLOWANCE_NOT_SUPPORTED');
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    override
    returns (bool)
  {
    spender;
    subtractedValue;
    revert('ALLOWANCE_NOT_SUPPORTED');
  }

  function _decreaseBorrowAllowance(
    address delegator,
    address delegatee,
    uint256 amount
  ) internal {
    uint256 newAllowance =
      _borrowAllowances[delegator][delegatee].sub(amount, Errors.GetError(Errors.Error.BORROW_ALLOWANCE_NOT_ENOUGH));

    _borrowAllowances[delegator][delegatee] = newAllowance;

    emit BorrowAllowanceDelegated(delegator, delegatee, _getUnderlyingAssetAddress(), newAllowance);
  }

  /**
   * @dev Being non transferrable, the debt token does not implement any of the
   * standard ERC20 functions for transfer and allowance.
   **/
  function transfer(address recipient, uint256 amount) public virtual override(KERC20, IERC20) returns (bool) {
    recipient;
    amount;
    revert('TRANSFER_NOT_SUPPORTED');
  }

  /**
   * @dev Calculates the accumulated debt balance of the user
   * @return The debt balance of the user
   **/
  function balanceOf(address user) public view virtual override(KERC20, IERC20) returns (uint256) {
    uint256 scaledBalance = super.balanceOf(user);

    if (scaledBalance == 0) {
      return 0;
    }

    return scaledBalance.rayMul(_pool.getReserveNormalizedDebt(_underlyingAsset));
  }

  /**
   * @dev Mints debt token to the `onBehalfOf` address
   * -  Only callable by the LendingPool
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    // NOTE: we let pool to have infinite borrow ability
    if (user != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, user, amount);
    }

    uint256 previousBalance = super.balanceOf(onBehalfOf);
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.GetError(Errors.Error.INVALID_MINT_AMOUNT));

    _mint(onBehalfOf, amountScaled);

    emit Transfer(address(0), onBehalfOf, amount);
    emit Mint(user, onBehalfOf, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Burns user variable debt
   * - Only callable by the LendingPool
   * @param user The user whose debt is getting burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.GetError(Errors.Error.INVALID_BURN_AMOUNT));

    _burn(user, amountScaled);

    emit Transfer(user, address(0), amount);
    emit Burn(user, amount, index);
  }

  /**
   * @dev Returns the principal debt balance of the user from
   * @return The debt balance of the user since the last burn/mint action
   **/
  function scaledBalanceOf(address user) public view virtual override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the total supply of the variable debt token. Represents the total debt accrued by the users
   * @return The total supply
   **/
  function totalSupply() public view virtual override(KERC20, IERC20) returns (uint256) {
    return super.totalSupply().rayMul(_pool.getReserveNormalizedDebt(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the principal balance of the user and principal total supply.
   * @param user The address of the user
   * @return The principal balance of the user
   * @return The principal total supply
   **/
  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() public view returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this kToken is used
   **/
  function POOL() public view returns (ILendingPool) {
    return _pool;
  }

  function _getUnderlyingAssetAddress() internal view returns (address) {
    return _underlyingAsset;
  }

  function _getLendingPool() internal view returns (ILendingPool) {
    return _pool;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "../../Dependency/openzeppelin/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IAggregationRouterV4  {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    event Swapped(
        address sender,
        IERC20 srcToken,
        IERC20 dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    );


    /// @notice Performs a swap and burns chi tokens to get gas refund
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function discountedSwap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft, uint256 chiSpent);

    /// @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

    function rescueFunds(IERC20 token, uint256 amount) external;

    function destroy() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGasDiscountExtension} from "./IGasDiscountExtension.sol";

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor is IGasDiscountExtension {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IChi} from "./IChi.sol";

/// @title Interface for calculating CHI discounts
interface IGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IChi, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../../Dependency/openzeppelin/IERC20.sol";

/// @title Interface for CHI gas token
interface IChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';

interface IKToken is IERC20, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` kTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after kTokens are burned
   * @param from The owner of the kTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the kTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints kTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers kTokens in the event of a borrow being liquidated, in case the liquidators reclaims the kToken
   * @param from The address getting liquidated, current owner of the kTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the kToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../Helper/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.GetError(Errors.Error.MATH_ADDITION_OVERFLOW));

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from '../Dependency/openzeppelin/Context.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {IERC20Detailed} from '../Dependency/openzeppelin/IERC20Detailed.sol';
import {SafeMath} from '../Dependency/openzeppelin/SafeMath.sol';

abstract contract KERC20 is Context, IERC20, IERC20Detailed {
  using SafeMath for uint256;
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 internal _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return The name of the token
   **/
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
   * @return The symbol of the token
   **/
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @return The decimals of the token
   **/
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @return The total supply of the token
   **/
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @return The balance of the token
   **/
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Executes a transfer of tokens from _msgSender() to recipient
   * @param recipient The recipient of the tokens
   * @param amount The amount of tokens being transferred
   * @return `true` if the transfer succeeds, `false` otherwise
   **/
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    emit Transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Returns the allowance of spender on the tokens owned by owner
   * @param owner The owner of the tokens
   * @param spender The user allowed to spend the owner's tokens
   * @return The amount of owner's tokens spender is allowed to spend
   **/
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev Allows `spender` to spend the tokens owned by _msgSender()
   * @param spender The user allowed to spend _msgSender() tokens
   * @return `true`
   **/
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
   * @param sender The owner of the tokens
   * @param recipient The recipient of the tokens
   * @param amount The amount of tokens being transferred
   * @return `true` if the transfer succeeds, `false` otherwise
   **/
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    emit Transfer(sender, recipient, amount);
    return true;
  }

  /**
   * @dev Increases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param addedValue The amount being added to the allowance
   * @return `true`
   **/
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Decreases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param subtractedValue The amount being subtracted to the allowance
   * @return `true`
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 oldSenderBalance = _balances[sender];
    _balances[sender] = oldSenderBalance.sub(amount, 'ERC20: transfer amount exceeds balance');
    uint256 oldRecipientBalance = _balances[recipient];
    _balances[recipient] = oldRecipientBalance.add(amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply.add(amount);

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance.add(amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply.sub(amount);

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance.sub(amount, 'ERC20: burn amount exceeds balance');
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setName(string memory newName) internal {
    _name = newName;
  }

  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from '../../Dependency/openzeppelin/SafeMath.sol';
import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp.sub(uint256(lastUpdateTimestamp));

    return (rate.mul(timeDifference) / SECONDS_PER_YEAR).add(WadRayMath.ray());
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

    return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';

interface IDToken is IERC20, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param onBehalfOf The address of the user on which behalf minting has been performed
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;
    event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address asset,
    uint256 amount
  );

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

}