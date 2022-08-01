// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
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
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

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
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
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
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
  external
  view
  returns (
    uint256 totalCollateralBase,
    uint256 totalDebtBase,
    uint256 availableBorrowsBase,
    uint256 currentLiquidationThreshold,
    uint256 ltv,
    uint256 healthFactor
  );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
  external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
  external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
  external
  view
  returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
  external
  view
  returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
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

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./connectors/aave/interfaces/IPoolAddressesProvider.sol";
import "./connectors/aave/interfaces/IPool.sol";

contract StrategyAaveV3 is Strategy {

    IERC20 public usdcToken;
    IERC20 public aUsdcToken;

    IPoolAddressesProvider public aaveProvider;


    // --- events

    event StrategyAaveUpdatedTokens(address usdcToken, address aUsdcToken);

    event StrategyAaveUpdatedParams(address aaveProvider);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _aUsdcToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_aUsdcToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        aUsdcToken = IERC20(_aUsdcToken);

        emit StrategyAaveUpdatedTokens(_usdcToken, _aUsdcToken);
    }

    function setParams(
        address _aaveProvider
    ) external onlyAdmin {

        require(_aaveProvider != address(0), "Zero address not allowed");

        aaveProvider = IPoolAddressesProvider(_aaveProvider);

        emit StrategyAaveUpdatedParams(_aaveProvider);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");

        IPool pool = IPool(aaveProvider.getPool());
        usdcToken.approve(address(pool), _amount);

        pool.deposit(address(usdcToken), _amount, address(this), 0);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        IPool pool = IPool(aaveProvider.getPool());
        aUsdcToken.approve(address(pool), _amount);

        uint256 withdrawAmount = pool.withdraw(_asset, _amount, address(this));
        return withdrawAmount;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 _amount = aUsdcToken.balanceOf(address(this));

        IPool pool = IPool(aaveProvider.getPool());
        aUsdcToken.approve(address(pool), _amount);

        uint256 withdrawAmount = pool.withdraw(_asset, _amount, address(this));

        return withdrawAmount;
    }

    function netAssetValue() external view override returns (uint256) {
        return aUsdcToken.balanceOf(address(this));
    }

    function liquidationValue() external view override returns (uint256) {
        return aUsdcToken.balanceOf(address(this));
    }

    function _claimRewards(address _beneficiary) internal override returns (uint256) {
        return 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IStrategy.sol";


abstract contract Strategy is IStrategy, Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PORTFOLIO_MANAGER = keccak256("PORTFOLIO_MANAGER");

    address public portfolioManager;


    function __Strategy_init() internal initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}

    // ---  modifiers

    modifier onlyPortfolioManager() {
        require(hasRole(PORTFOLIO_MANAGER, msg.sender), "Restricted to PORTFOLIO_MANAGER");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    // --- setters

    function setPortfolioManager(address _value) public onlyAdmin {
        require(_value != address(0), "Zero address not allowed");

        revokeRole(PORTFOLIO_MANAGER, portfolioManager);
        grantRole(PORTFOLIO_MANAGER, _value);

        portfolioManager = _value;
        emit PortfolioManagerUpdated(_value);
    }


    // --- logic


    function stake(
        address _asset, // USDC
        uint256 _amount // value for staking in USDC
    ) external override onlyPortfolioManager {
        emit Stake(_amount);
        _stake(_asset, IERC20(_asset).balanceOf(address(this)));
    }

    function unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary,
        bool _targetIsZero
    ) external override onlyPortfolioManager returns (uint256) {
        uint256 withdrawAmount;
        if (_targetIsZero) {
            emit Reward(_claimRewards(_beneficiary));
            withdrawAmount = _unstakeFull(_asset, _beneficiary);
        } else {
            withdrawAmount = _unstake(_asset, _amount, _beneficiary);
            require(withdrawAmount >= _amount, 'Returned value less than requested amount');
        }

        IERC20(_asset).transfer(_beneficiary, withdrawAmount);
        emit Unstake(_amount, withdrawAmount);

        return withdrawAmount;
    }

    function claimRewards(address _to) external override onlyPortfolioManager returns (uint256) {
        uint256 totalUsdc = _claimRewards(_to);
        emit Reward(totalUsdc);
        return totalUsdc;
    }

    function healthFactorBalance() external override onlyPortfolioManager {
        uint256 healthFactor = _healthFactorBalance();
        if (healthFactor > 0) {
            emit BalanceHealthFactor(healthFactor);
        }
    }

    function setHealthFactor(uint256 healthFactor) external override onlyPortfolioManager {
        _setHealthFactor(healthFactor);

        emit SetHealthFactor(healthFactor);
    }

    function _stake(
        address _asset,
        uint256 _amount
    ) internal virtual {
        revert("Not implemented");
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal virtual returns (uint256){
        revert("Not implemented");
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal virtual returns (uint256){
        revert("Not implemented");
    }

    function _claimRewards(address _to) internal virtual returns (uint256){
        revert("Not implemented");
    }

    function _healthFactorBalance() internal virtual returns (uint256) {
        
    }

    function _setHealthFactor(uint256 _healthFactor) internal virtual {

    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {

    event Reward(uint256 amount);
    event PortfolioManagerUpdated(address value);

    event Stake(uint256 amount);
    event Unstake(uint256 amount, uint256 amountReceived);

    event BalanceHealthFactor(uint256 healthFactor);
    event SetHealthFactor(uint256 healthFactor);

    function stake(
        address _asset, // USDC
        uint256 _amount // value for staking in USDC
    ) external;

    function unstake(
        address _asset, // USDC
        uint256 _amount, // minimum expected value for unstaking in USDC
        address _beneficiary, // PortfolioManager
        bool targetIsZero // allow unstake full value
    ) external returns (uint256); // Real unstake value

    function netAssetValue() external view returns (uint256); // Return value in USDC - denominator 6

    function liquidationValue() external view returns (uint256); // Return value in USDC - denominator 6

    function claimRewards(address _to) external returns (uint256); // Return received amount in USDC - denominator 6

    function healthFactorBalance() external; // Balancing aave health factor

    function setHealthFactor(uint256 healthFactor) external; // Aave healthFactor setter
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/aave/interfaces/IPoolAddressesProvider.sol";
import "../connectors/aave/interfaces/IPriceFeed.sol";
import "../connectors/aave/interfaces/IPool.sol";
import '../connectors/uniswap/v3/libraries/FullMath.sol';


library AaveBorrowLibrary {

    function getAavePool(
        address aavePoolAddressesProvider,
        uint8 eModeCategoryId
    ) internal returns (address aavePool) {
        aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
        IPool(aavePool).setUserEMode(eModeCategoryId);
    }

    function getAavePool(
        address aavePoolAddressesProvider
    ) internal view returns (address aavePool) {
        aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
    }

    function getCollateralAndBorrowForSupplyAndBorrow(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1,
        uint256 LT,
        uint256 HF,
        uint256 token0Denominator,
        uint256 token1Denominator,
        uint256 price0,
        uint256 price1
    ) internal pure returns (uint256 collateral0, uint256 borrow1) {
        uint256 reserve1InToken0 = convertTokenAmountToTokenAmount(reserve1, token1Denominator, token0Denominator, price1, price0);
        collateral0 = amount0 * HF / (HF + LT * reserve0 / reserve1InToken0);
        uint256 collateral1 = convertTokenAmountToTokenAmount(collateral0, token0Denominator, token1Denominator, price0, price1);
        borrow1 = collateral1 * LT / HF;
    }

    function getBorrowForWithdraw(
        uint256 collateral0,
        uint256 reserve0,
        uint256 reserve1,
        uint256 LT,
        uint256 HF,
        uint256 token0Denominator,
        uint256 token1Denominator,
        uint256 price0,
        uint256 price1
    ) internal pure returns (uint256 borrow1) {
        uint256 collateral1 = convertTokenAmountToTokenAmount(collateral0, token0Denominator, token1Denominator, price0, price1);
        //usdc to usdt
        uint256 reserve1InToken0 = convertTokenAmountToTokenAmount(reserve1, token1Denominator, token0Denominator, price1, price0);
        //usdt to usdc
        borrow1 = (collateral1 * LT * reserve1InToken0) / (HF * reserve1InToken0 + LT * reserve0);
    }

    // function getBorrowForWithdraw(
    //     uint256 collateral0,
    //     uint256 totalCollateralUsd,
    //     uint256 totalBorrowUsd,
    //     uint256 reserve0,
    //     uint256 reserve1,
    //     uint256 LT,
    //     uint256 HF,
    //     uint256 token0Denominator,
    //     uint256 token1Denominator,
    //     uint256 price0,
    //     uint256 price1
    // ) internal pure returns (uint256 borrow1) {
    //     uint256 totalBorrowUsd1 = convertUsdToTokenAmount(totalBorrowUsd, token1Denominator, price1);   //usd to usdt
    //     uint256 totalCollateralUsd1 = convertUsdToTokenAmount(totalCollateralUsd, token1Denominator, price1); //usd to usdt
    //     uint256 collateral1 = convertTokenAmountToTokenAmount(collateral0, token0Denominator, token1Denominator, price0, price1); //usdc to usdt
    //     uint256 reserve1InToken0 = convertTokenAmountToTokenAmount(reserve1, token1Denominator, token0Denominator, price1, price0); //usdt to usdc
    //     borrow1 = (totalBorrowUsd1 * HF + collateral1 * LT - totalCollateralUsd1 * LT) / (HF + LT * reserve0 / reserve1InToken0);
    // }

    // function getLpTokensForWithdraw(
    //     uint256 totalLpBalance,
    //     uint256 borrow1,
    //     uint256 reserve0,
    //     uint256 reserve1,
    //     uint256 token0Denominator,
    //     uint256 token1Denominator,
    //     uint256 price0,
    //     uint256 price1
    // ) internal pure returns (uint256 lpTokensToWithdraw) {
    //     uint256 borrow0 = convertTokenAmountToTokenAmount(borrow1, token1Denominator, token0Denominator, price1, price0);
    //     uint256 reserve1InToken0 = convertTokenAmountToTokenAmount(reserve1, token1Denominator, token0Denominator, price1, price0);
    //     lpTokensToWithdraw = totalLpBalance * (borrow0 + borrow1 * reserve0 / reserve1) / (reserve0 + reserve1InToken0);
    // }

    struct GetWithdrawAmountForBalanceParams {
        uint256 totalCollateralUsd;
        uint256 totalBorrowUsd;
        uint256 reserve0;
        uint256 reserve1;
        uint256 LT;
        uint256 HF;
        uint256 token0Denominator;
        uint256 token1Denominator;
        uint256 price0;
        uint256 price1;
    }

    function getWithdrawAmountForBalance(
        GetWithdrawAmountForBalanceParams memory params
    ) internal pure returns (uint256 withdrawAmount) {
        uint256 reserve1InUsd = convertTokenAmountToUsd(params.reserve1, params.token1Denominator, params.price1);
        uint256 reserve0InUsd = convertTokenAmountToUsd(params.reserve0, params.token0Denominator, params.price0);
        withdrawAmount = FullMath.mulDivRoundingUp(
            params.reserve0, 
            params.totalCollateralUsd * params.LT - params.totalBorrowUsd * params.HF, 
            reserve1InUsd * params.HF + reserve0InUsd * params.LT
        );
    }

    function getBorrowIfZeroAmountForBalance(
        GetWithdrawAmountForBalanceParams memory params
    ) internal pure returns (uint256 withdrawAmount) {
        withdrawAmount = (params.totalCollateralUsd * params.LT - params.totalBorrowUsd * params.HF) / (params.HF);
        withdrawAmount = convertUsdToTokenAmount(withdrawAmount, params.token1Denominator, params.price1);
    }

    struct GetLpTokensForBalanceParams {
        uint256 totalCollateralUsd;
        uint256 totalBorrowUsd;
        uint256 reserve0;
        uint256 reserve1;
        uint256 LT;
        uint256 HF;
        uint256 token0Denominator;
        uint256 token1Denominator;
        uint256 price0;
        uint256 price1;
        uint256 totalSuply;
    }

    function getLpTokensForBalance(
        GetLpTokensForBalanceParams memory params
    ) internal pure returns (uint256 lpTokens) {
        uint256 reserve1InUsd = convertTokenAmountToUsd(params.reserve1, params.token1Denominator, params.price1);
        uint256 reserve0InUsd = convertTokenAmountToUsd(params.reserve0, params.token0Denominator, params.price0);
        lpTokens = FullMath.mulDivRoundingUp(
            params.totalSuply, 
            params.totalBorrowUsd * params.HF - params.totalCollateralUsd * params.LT, 
            reserve1InUsd * params.HF + reserve0InUsd * params.LT
        );
    }

    function convertTokenAmountToTokenAmount(
        uint256 amount0,
        uint256 token0Denominator,
        uint256 token1Denominator,
        uint256 price0,
        uint256 price1
    ) internal pure returns (uint256 amount1) {
        amount1 = (amount0 * token1Denominator * price0) / (token0Denominator * price1);
    }

    function convertTokenAmountToUsd(
        uint256 amount,
        uint256 tokenDenominator,
        uint256 price
    ) internal pure returns (uint256 amountUsd) {
        amountUsd = amount * price / tokenDenominator;
    }

    function convertUsdToTokenAmount(
        uint256 amountUsd,
        uint256 tokenDenominator,
        uint256 price
    ) internal pure returns (uint256 amount) {
        amount = amountUsd * tokenDenominator / price;
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
  function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./libraries/OvnMath.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./exchanges/SynapseExchange.sol";
import "./connectors/stargate/interfaces/IStargateRouter.sol";
import "./connectors/stargate/interfaces/IStargatePool.sol";
import "./connectors/stargate/interfaces/ILPStaking.sol";
import "./connectors/aave/interfaces/IPriceFeed.sol";
import "./libraries/AaveBorrowLibrary.sol";


contract StrategyStargateUsdt is Strategy, UniswapV2Exchange, SynapseExchange {
    using OvnMath for uint256;

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public stgToken;

    IStargateRouter public stargateRouter;
    IStargatePool public pool;
    ILPStaking public lpStaking;
    uint256 public pid;

    uint256 public usdcTokenDenominator;
    uint256 public usdtTokenDenominator;

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleUsdt;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address stgToken, uint256 usdcTokenDenominator,
        uint256 usdtTokenDenominator);

    event StrategyUpdatedParams(address stargateRouter, address pool, address lpStaking, uint256 pid,
        address sushiSwapRouter, address synapseSwap, address oracleUsdc, address oracleUsdt);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _stgToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_stgToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        stgToken = IERC20(_stgToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        usdtTokenDenominator = 10 ** IERC20Metadata(_usdtToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _stgToken, usdcTokenDenominator, usdtTokenDenominator);
    }

    function setParams(
        address _stargateRouter,
        address _pool,
        address _lpStaking,
        uint256 _pid,
        address _sushiSwapRouter,
        address _synapseSwap,
        address _oracleUsdc,
        address _oracleUsdt
    ) external onlyAdmin {

        require(_stargateRouter != address(0), "Zero address not allowed");
        require(_pool != address(0), "Zero address not allowed");
        require(_lpStaking != address(0), "Zero address not allowed");
        require(_sushiSwapRouter != address(0), "Zero address not allowed");
        require(_synapseSwap != address(0), "Zero address not allowed");
        require(_oracleUsdc != address(0), "Zero address not allowed");
        require(_oracleUsdt != address(0), "Zero address not allowed");

        stargateRouter = IStargateRouter(_stargateRouter);
        pool = IStargatePool(_pool);
        lpStaking = ILPStaking(_lpStaking);
        pid = _pid;
        _setUniswapRouter(_sushiSwapRouter);
        _setSynapseSwap(_synapseSwap);

        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleUsdt = IPriceFeed(_oracleUsdt);

        emit StrategyUpdatedParams(_stargateRouter, _pool, _lpStaking, _pid, _sushiSwapRouter, _synapseSwap, _oracleUsdc, _oracleUsdt);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // swap usdc to usdt
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        _synapseSwap(address(usdcToken), address(usdtToken), usdcBalance);

        // add liquidity
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        usdtToken.approve(address(stargateRouter), usdtBalance);
        stargateRouter.addLiquidity(uint16(pool.poolId()), usdtBalance, address(this));

        // stake
        uint256 lpBalance = pool.balanceOf(address(this));
        pool.approve(address(lpStaking), lpBalance);
        lpStaking.deposit(pid, lpBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        uint256 usdcAmount = _amount.addBasisPoints(4) + 10;
        uint256 usdtAmount = _synapseCalculateSwap(address(usdcToken), address(usdtToken), usdcAmount);
        uint256 lpBalance = usdtAmount * usdtTokenDenominator / pool.amountLPtoLD(usdtTokenDenominator);
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (lpBalance > amount) {
            lpBalance = amount;
        }
        lpStaking.withdraw(pid, lpBalance);

        // remove liquidity
        pool.approve(address(stargateRouter), lpBalance);
        stargateRouter.instantRedeemLocal(uint16(pool.poolId()), lpBalance, address(this));

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        _synapseSwap(address(usdtToken), address(usdcToken), usdtBalance);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount == 0) {
            return usdcToken.balanceOf(address(this));
        }
        lpStaking.withdraw(pid, amount);

        // remove liquidity
        pool.approve(address(stargateRouter), amount);
        stargateRouter.instantRedeemLocal(uint16(pool.poolId()), amount, address(this));

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        _synapseSwap(address(usdtToken), address(usdcToken), usdtBalance);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount > 0) {
            uint256 usdtBalance = pool.amountLPtoLD(amount);
            if (nav) {
                uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
                uint256 priceUsdt = uint256(oracleUsdt.latestAnswer());
                usdcBalance += AaveBorrowLibrary.convertTokenAmountToTokenAmount(usdtBalance, usdtTokenDenominator, usdcTokenDenominator, priceUsdt, priceUsdc);
            } else {
                usdcBalance += _synapseCalculateSwap(address(usdtToken), address(usdcToken), usdtBalance);
            }
        }

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount == 0) {
            return 0;
        }
        lpStaking.withdraw(pid, 0);

        // sell rewards
        uint256 totalUsdc;

        uint256 stgBalance = stgToken.balanceOf(address(this));
        if (stgBalance > 0) {
            uint256 stgUsdc = _swapExactTokensForTokens(
                address(stgToken),
                address(usdcToken),
                stgBalance,
                address(this)
            );
            totalUsdc += stgUsdc;
        }

        if (totalUsdc > 0) {
            usdcToken.transfer(_to, totalUsdc);
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library OvnMath {

    uint256 constant BASIS_DENOMINATOR = 10 ** 4;

    function abs(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? (x - y) : (y - x);
    }

    function addBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return amount * (BASIS_DENOMINATOR + basisPoints) / BASIS_DENOMINATOR;
    }

    function reverseAddBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return amount * BASIS_DENOMINATOR / (BASIS_DENOMINATOR + basisPoints);
    }

    function subBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return amount * (BASIS_DENOMINATOR - basisPoints) / BASIS_DENOMINATOR;
    }

    function reverseSubBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return amount * BASIS_DENOMINATOR / (BASIS_DENOMINATOR - basisPoints);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/uniswap/v2/interfaces/IUniswapV2Router02.sol";
import "../libraries/OvnMath.sol";

abstract contract UniswapV2Exchange {

    uint256 public constant BASIS_POINTS_FOR_SLIPPAGE = 4;

    IUniswapV2Router02 private uniswapRouter;

    function _setUniswapRouter(address _uniswapRouter) internal {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function _swapExactTokensForTokens(
        address inputToken,
        address outputToken,
        uint256 amountInput,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(uniswapRouter), amountInput);

        uint256 amountOutMin = _getAmountsOut(inputToken, outputToken, amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountInput,
            OvnMath.subBasisPoints(amountOutMin, BASIS_POINTS_FOR_SLIPPAGE),
            path,
            recipient,
            block.timestamp + 600
        );

        return amounts[1];
    }

    function _getAmountsOut(
        address inputToken,
        address outputToken,
        uint256 amountInput
    ) internal view returns (uint256) {

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint[] memory amounts = uniswapRouter.getAmountsOut(amountInput, path);

        return amounts[1];
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB, uint liquidity) {

        IERC20(tokenA).approve(address(uniswapRouter), amountADesired);
        IERC20(tokenB).approve(address(uniswapRouter), amountBDesired);

        return uniswapRouter.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        address lpToken,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB) {

        IERC20(lpToken).approve(address(uniswapRouter), liquidity);

        return uniswapRouter.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/synapse/interfaces/ISwap.sol";

abstract contract SynapseExchange {

    ISwap private synapseSwap;

    function _setSynapseSwap(address _synapseSwap) internal {
        synapseSwap = ISwap(_synapseSwap);
    }

    function _synapseCalculateSwap(
        address tokenFrom,
        address tokenTo,
        uint256 dx
    ) internal view returns (uint256) {
        uint8 tokenIndexFrom = synapseSwap.getTokenIndex(tokenFrom);
        uint8 tokenIndexTo = synapseSwap.getTokenIndex(tokenTo);
        return synapseSwap.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    function _synapseSwap(
        address tokenFrom,
        address tokenTo,
        uint256 dx
    ) internal returns (uint256) {
        uint8 tokenIndexFrom = synapseSwap.getTokenIndex(tokenFrom);
        uint8 tokenIndexTo = synapseSwap.getTokenIndex(tokenTo);
        uint256 minDy = synapseSwap.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
        if (minDy == 0) {
            return 0;
        }
        IERC20(tokenFrom).approve(address(synapseSwap), dx);
        return synapseSwap.swap(tokenIndexFrom, tokenIndexTo, dx, minDy, block.timestamp);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStargatePool is IERC20 {

    function poolId() external view returns (uint256);

    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

interface ILPStaking {

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingStargate(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

}

// SPDX-License-Identifier: GNU-3
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

/**
 * IUniswapV2Router02.sol is copy of https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);


    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function pairFor(address factoryC, address tokenA, address tokenB) external view returns (address pair) ;

}

// SPDX-License-Identifier: GNU-3
pragma solidity >=0.6.2;

/**
 * IUniswapV2Router01.sol is copy of https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
 */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getAdminBalance(uint256 index) external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external
    view
    returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
    external
    view
    returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        IERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        address lpTokenTargetAddress
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/DystopiaExchange.sol";
import "./exchanges/BalancerExchange.sol";
import "./connectors/dystopia/interfaces/IDystopiaLP.sol";
import "./connectors/aave/interfaces/IPriceFeed.sol";
import "./connectors/penrose/interface/IUserProxy.sol";
import "./connectors/penrose/interface/IPenLens.sol";
import "./libraries/AaveBorrowLibrary.sol";
import "./interfaces/ISwapper.sol";


contract StrategyDystopiaUsdcUsdt is Strategy, DystopiaExchange, BalancerExchange {

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public dystToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public usdtTokenDenominator;

    IDystopiaLP public gauge;
    IDystopiaLP public dystPair;
    bytes32 public poolIdUsdcTusdDaiUsdt;

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleUsdt;

    IERC20 public penToken;
    IUserProxy public userProxy;
    IPenLens public penLens;

    ISwapper public swapper;

    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address dystToken, address wmaticToken, address penToken,
        uint256 usdcTokenDenominator, uint256 usdtTokenDenominator);

    event StrategyUpdatedParams(address gauge, address dystPair, address dystRouter, address balancerVault, bytes32 poolIdUsdcTusdDaiUsdt,
        address oracleUsdc, address oracleUsdt, address userProxy, address penLens, address swapper);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _dystToken,
        address _wmaticToken,
        address _penToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_dystToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_penToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        dystToken = IERC20(_dystToken);
        wmaticToken = IERC20(_wmaticToken);
        penToken = IERC20(_penToken);
        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        usdtTokenDenominator = 10 ** IERC20Metadata(_usdtToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _dystToken, _wmaticToken, _penToken, usdcTokenDenominator, usdtTokenDenominator);
    }

    function setParams(
        address _gauge,
        address _dystPair,
        address _dystRouter,
        address _balancerVault,
        bytes32 _poolIdUsdcTusdDaiUsdt,
        address _oracleUsdc,
        address _oracleUsdt,
        address _userProxy,
        address _penLens,
        address _swapper
    ) external onlyAdmin {

        require(_gauge != address(0), "Zero address not allowed");
        require(_dystPair != address(0), "Zero address not allowed");
        require(_dystRouter != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_poolIdUsdcTusdDaiUsdt != "", "Empty pool id not allowed");
        require(_oracleUsdc != address(0), "Zero address not allowed");
        require(_oracleUsdt != address(0), "Zero address not allowed");
        require(_userProxy != address(0), "Zero address not allowed");
        require(_penLens != address(0), "Zero address not allowed");
        require(_swapper != address(0), "Zero address not allowed");

        gauge = IDystopiaLP(_gauge);
        dystPair = IDystopiaLP(_dystPair);
        _setDystopiaRouter(_dystRouter);
        setBalancerVault(_balancerVault);
        poolIdUsdcTusdDaiUsdt = _poolIdUsdcTusdDaiUsdt;
        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleUsdt = IPriceFeed(_oracleUsdt);
        userProxy = IUserProxy(_userProxy);
        penLens = IPenLens(_penLens);
        swapper = ISwapper(_swapper);

        emit StrategyUpdatedParams(_gauge, _dystPair, _dystRouter, _balancerVault, _poolIdUsdcTusdDaiUsdt, _oracleUsdc,
            _oracleUsdt, _userProxy, _penLens, _swapper);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 amountUsdcToSwap = _getAmountToken0(
            usdcBalance,
            reserveUsdc,
            reserveUsdt,
            usdcTokenDenominator,
            usdtTokenDenominator,
            1,
            address(usdcToken),
            address(usdtToken)
        );

        // swap usdc to usdt
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(usdcToken),
            address(usdtToken),
            amountUsdcToSwap,
            0,
            5
        );
        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        // add liquidity
        usdcBalance = usdcToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));

        _addLiquidity(
            address(usdcToken),
            address(usdtToken),
            usdcBalance,
            usdtBalance,
            OvnMath.subBasisPoints(usdcBalance, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(usdtBalance, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );

        uint256 lpTokenBalance = dystPair.balanceOf(address(this));
        dystPair.approve(address(userProxy), lpTokenBalance);
        userProxy.depositLpAndStake(address(dystPair), lpTokenBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance > 0) {
            // count amount to unstake
            uint256 totalLpBalance = dystPair.totalSupply();
            uint256 lpTokensToWithdraw = _getAmountLpTokens(
                OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE) + 10,
                reserveUsdc,
                reserveUsdt,
                totalLpBalance
            );

            if (lpTokensToWithdraw > lpTokenBalance) {
                lpTokensToWithdraw = lpTokenBalance;
            }

            userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokensToWithdraw);

            uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));

            uint256 amountOutUsdcMin = reserveUsdc * unstakedLPTokenBalance / totalLpBalance;
            uint256 amountOutUsdtMin = reserveUsdt * unstakedLPTokenBalance / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(usdtToken),
                address(dystPair),
                unstakedLPTokenBalance,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutUsdtMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(usdtToken),
            address(usdcToken),
            usdtBalance,
            0,
            5
        );
        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance == 0) {
            return 0;
        }

        userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokenBalance);

        uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));
        if (unstakedLPTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();
            uint256 amountOutUsdcMin = reserveUsdc * unstakedLPTokenBalance / totalLpBalance;
            uint256 amountOutUsdtMin = reserveUsdt * unstakedLPTokenBalance / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(usdtToken),
                address(dystPair),
                unstakedLPTokenBalance,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutUsdtMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(usdtToken),
            address(usdcToken),
            usdtBalance,
            0,
            5
        );
        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();
            (uint256 reserveUsdc, uint256 reserveUsdt,) = dystPair.getReserves();
            usdcBalance += reserveUsdc * lpTokenBalance / totalLpBalance;
            usdtBalance += reserveUsdt * lpTokenBalance / totalLpBalance;
        }

        uint256 usdcBalanceFromUsdt;
        if (usdtBalance > 0) {
            if (nav) {
                uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
                uint256 priceUsdt = uint256(oracleUsdt.latestAnswer());
                usdcBalanceFromUsdt = AaveBorrowLibrary.convertTokenAmountToTokenAmount(usdtBalance, usdtTokenDenominator, usdcTokenDenominator, priceUsdt, priceUsdc);
            } else {
                ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
                    address(usdtToken),
                    address(usdcToken),
                    usdtBalance,
                    0,
                    5
                );
                usdcBalanceFromUsdt = swapper.getAmountOut(swapParams);
            }

        }

        return usdcBalance + usdcBalanceFromUsdt;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        userProxy.claimStakingRewards();

        // sell rewards
        uint256 totalUsdc;

        uint256 dystBalance = dystToken.balanceOf(address(this));
        if (dystBalance > 0) {
            uint256 dystUsdc = _swapExactTokensForTokens(
                address(dystToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                dystBalance,
                address(this)
            );
            totalUsdc += dystUsdc;
        }

        uint256 penBalance = penToken.balanceOf(address(this));
        if (penBalance > 0) {
            uint256 penUsdc = _swapExactTokensForTokens(
                address(penToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                penBalance,
                address(this)
            );
            totalUsdc += penUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));

        return totalUsdc;
    }


    /**
     * Get amount of token1 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountToken0(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1,
        uint256 precision,
        address token0,
        address token1
    ) internal view returns (uint256) {
        uint256 amount0 = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        for (uint i = 0; i < precision; i++) {
            ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
                token0,
                token1,
                amount0,
                0,
                5
            );
            uint256 amount1 = swapper.getAmountOut(swapParams);
            amount0 = (amount0Total * reserve1) / (reserve0 * amount1 / amount0 + reserve1);
        }

        return amount0;
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     */
    function _getAmountLpTokens(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance
    ) internal view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * usdtTokenDenominator) / (reserve0 * usdtTokenDenominator + reserve1 * usdcTokenDenominator);

        uint256 amount1 = reserve1 * lpBalance / totalLpBalance;
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(usdtToken),
            address(usdcToken),
            amount1,
            0,
            5
        );
        uint256 amount0 = swapper.getAmountOut(swapParams);
        lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);

        return lpBalance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/dystopia/interfaces/IDystopiaRouter.sol";
import "../libraries/OvnMath.sol";

abstract contract DystopiaExchange {

    uint256 public constant BASIS_POINTS_FOR_SLIPPAGE = 4;

    IDystopiaRouter private dystRouter;

    function _setDystopiaRouter(address _dystRouter) internal {
        dystRouter = IDystopiaRouter(_dystRouter);
    }

    function _getAmountsOut(
        address inputToken,
        address outputToken,
        bool isStablePair0,
        uint256 amountInput
    ) internal view returns (uint256) {

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](1);
        route[0].from = inputToken;
        route[0].to = outputToken;
        route[0].stable = isStablePair0;

        uint[] memory amounts = dystRouter.getAmountsOut(amountInput, route);

        return amounts[1];
    }

    function _getAmountsOut(
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput
    ) internal view returns (uint256) {

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystRouter.getAmountsOut(amountInput, route);

        return amounts[2];
    }

    function _swapExactTokensForTokens(
        address inputToken,
        address outputToken,
        bool isStablePair0,
        uint256 amountInput,
        address recipient,
        uint256 amountOutMin
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(dystRouter), amountInput);

        uint256 amountOutMin = _getAmountsOut(address(inputToken), address(outputToken), isStablePair0, amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](1);
        route[0].from = inputToken;
        route[0].to = outputToken;
        route[0].stable = isStablePair0;

        uint[] memory amounts = dystRouter.swapExactTokensForTokens(
            amountInput,
            amountOutMin,
            route,
            recipient,
            block.timestamp + 600
        );

        return amounts[1];
    }

    function _swapExactTokensForTokens(
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(dystRouter), amountInput);

        uint256 amountOutMin = _getAmountsOut(address(inputToken), address(middleToken), address(outputToken), isStablePair0, isStablePair1, amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystRouter.swapExactTokensForTokens(
            amountInput,
            0,
            route,
            recipient,
            block.timestamp + 600
        );
    
        return amounts[2];
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB, uint liquidity) {

        IERC20(tokenA).approve(address(dystRouter), amountADesired);
        IERC20(tokenB).approve(address(dystRouter), amountBDesired);

        return dystRouter.addLiquidity(
            tokenA,
            tokenB,
            true,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );

    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        address lpToken,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB) {

        IERC20(lpToken).approve(address(dystRouter), liquidity);

        return dystRouter.removeLiquidity(
            tokenA,
            tokenB,
            true,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/balancer/interfaces/IVault.sol";
import "../connectors/balancer/interfaces/IGeneralPool.sol";
import "../connectors/balancer/interfaces/IMinimalSwapInfoPool.sol";
import "../connectors/balancer/interfaces/IPoolSwapStructs.sol";


abstract contract BalancerExchange {

    int256 public constant MAX_VALUE = 10 ** 27;

    IVault private balancerVault;

    function setBalancerVault(address _balancerVault) internal {
        balancerVault = IVault(_balancerVault);
    }

    function swap(
        bytes32 poolId,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenOut,
        address sender,
        address recipient,
        uint256 amount,
        uint256 limit
    ) internal returns (uint256) {

        IERC20(address(tokenIn)).approve(address(balancerVault), IERC20(address(tokenIn)).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = kind;
        singleSwap.assetIn = tokenIn;
        singleSwap.assetOut = tokenOut;
        singleSwap.amount = amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = payable(recipient);
        fundManagement.toInternalBalance = false;

        return balancerVault.swap(singleSwap, fundManagement, limit, block.timestamp + 600);
    }

    function swap(
        bytes32 poolId,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenOut,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {

        IERC20(address(tokenIn)).approve(address(balancerVault), IERC20(address(tokenIn)).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = kind;
        singleSwap.assetIn = tokenIn;
        singleSwap.assetOut = tokenOut;
        singleSwap.amount = amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = payable(recipient);
        fundManagement.toInternalBalance = false;

        return balancerVault.swap(singleSwap, fundManagement, uint256(MAX_VALUE), block.timestamp + 600);
    }

    function batchSwap(
        bytes32 poolId1,
        bytes32 poolId2,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenMid,
        IAsset tokenOut,
        address sender,
        address payable recipient,
        uint256 amount
    ) internal returns (uint256) {

        IERC20(address(tokenIn)).approve(address(balancerVault), amount);

        IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](2);

        IVault.BatchSwapStep memory batchSwap1;
        batchSwap1.poolId = poolId1;
        batchSwap1.assetInIndex = 0;
        batchSwap1.assetOutIndex = 1;
        batchSwap1.amount = amount;
        swaps[0] = batchSwap1;

        IVault.BatchSwapStep memory batchSwap2;
        batchSwap2.poolId = poolId2;
        batchSwap2.assetInIndex = 1;
        batchSwap2.assetOutIndex = 2;
        batchSwap2.amount = 0;
        swaps[1] = batchSwap2;

        IAsset[] memory assets = new IAsset[](3);
        assets[0] = tokenIn;
        assets[1] = tokenMid;
        assets[2] = tokenOut;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = recipient;
        fundManagement.toInternalBalance = false;

        int256[] memory limits = new int256[](3);
        if (kind == IVault.SwapKind.GIVEN_IN) {
            limits[0] = MAX_VALUE;
            limits[1] = MAX_VALUE;
            limits[2] = MAX_VALUE;
        } else {
            limits[0] = 0;
            limits[1] = 0;
            limits[2] = 0;
        }

        return uint256(- balancerVault.batchSwap(kind, swaps, assets, fundManagement, limits, block.timestamp + 600)[2]);
    }

    function onSwap(
        bytes32 poolId,
        IVault.SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 balance
    ) internal view returns (uint256) {

        IPoolSwapStructs.SwapRequest memory swapRequest;
        swapRequest.kind = kind;
        swapRequest.tokenIn = tokenIn;
        swapRequest.tokenOut = tokenOut;
        swapRequest.amount = balance;

        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(poolId);

        (address pool, IVault.PoolSpecialization poolSpecialization) = balancerVault.getPool(poolId);

        if (poolSpecialization == IVault.PoolSpecialization.GENERAL) {

            uint256 indexIn;
            uint256 indexOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    indexIn = i;
                } else if (tokens[i] == tokenOut) {
                    indexOut = i;
                }
            }

            return IGeneralPool(pool).onSwap(swapRequest, balances, indexIn, indexOut);

        } else if (poolSpecialization == IVault.PoolSpecialization.MINIMAL_SWAP_INFO) {

            uint256 balanceIn;
            uint256 balanceOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    balanceIn = balances[i];
                } else if (tokens[i] == tokenOut) {
                    balanceOut = balances[i];
                }
            }

            return IMinimalSwapInfoPool(pool).onSwap(swapRequest, balanceIn, balanceOut);

        } else {

            uint256 balanceIn;
            uint256 balanceOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    balanceIn = balances[i];
                } else if (tokens[i] == tokenOut) {
                    balanceOut = balances[i];
                }
            }

            return IMinimalSwapInfoPool(pool).onSwap(swapRequest, balanceIn, balanceOut);
        }
    }

    /**
     * Get amount of token1 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountToSwap(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1,
        uint256 precision,
        bytes32 poolId,
        IERC20 token0,
        IERC20 token1
    ) internal view returns (uint256) {
        uint256 amount0ToSwap = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        for (uint i = 0; i < precision; i++) {
            uint256 amount1 = onSwap(poolId, IVault.SwapKind.GIVEN_IN, token0, token1, amount0ToSwap);
            amount0ToSwap = (amount0Total * reserve1) / (reserve0 * amount1 / amount0ToSwap + reserve1);
        }

        return amount0ToSwap;
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountLpTokensToWithdraw(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance,
        uint256 denominator0,
        uint256 denominator1,
        bytes32 poolId,
        IERC20 token0,
        IERC20 token1
    ) internal view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * denominator1) / (reserve0 * denominator1 + reserve1 * denominator0);
        for (uint i = 0; i < 1; i++) {
            uint256 amount1 = reserve1 * lpBalance / totalLpBalance;
            uint256 amount0 = onSwap(poolId, IVault.SwapKind.GIVEN_IN, token1, token0, amount1);
            lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);
        }
        return lpBalance;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5 <0.9.0;

import "../../uniswap/v2/interfaces/IUniswapV2Pair.sol";

abstract contract IDystopiaLP is IUniswapV2Pair {

    function deposit(uint amount, uint tokenId) external virtual;

    function withdraw(uint amount) external virtual;

    function withdrawAll() external virtual;

    function getReward(address account, address[] memory tokens) external virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address penPoolAddress;
        address dystPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToPenDyst(uint256) external;

    function convertDystToPenDyst(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakePenLp(address, uint256) external;

    function unstakePenLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
    external
    view
    returns (PositionStakingPool[] memory);

    function stakePenDyst(uint256) external;

    function unstakePenDyst(uint256) external;

    function unstakePenDyst(address, uint256) external;

    function convertDystToPenDystAndStake(uint256) external;

    function convertNftToPenDystAndStake(uint256) external;

    function claimPenDystStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlPenRewards() external;

    function depositPen(uint256, uint256) external;

    function withdrawPen(bool, uint256) external;

    function voteLockPen(uint256, uint256) external;

    function withdrawVoteLockedPen(uint256, bool) external;

    function relockVoteLockedPen(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migratePenDystToPartner() external;

    function stakePenDystInPenV1(uint256) external;

    function unstakePenDystInPenV1(uint256) external;

    function redeemPenV1(uint256) external;

    function redeemAndStakePenV1(uint256) external;

    function whitelist(address) external;

    function implementationsAddresses()
    external
    view
    returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPenLens {

    /* ========== PUBLIC VARS ========== */

    function penPoolFactoryAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function userProxyFactoryAddress() external view returns (address);

    function dystopiaLensAddress() external view returns (address);

    function penAddress() external view returns (address);

    function vlPenAddress() external view returns (address);

    function penDystAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function veAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function penDystRewardsPoolAddress() external view returns (address);

    function partnersRewardsPoolAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function cvlPenAddress() external view returns (address);

    function penV1RewardsAddress() external view returns (address);

    function penV1RedeemAddress() external view returns (address);

    function penV1Address() external view returns (address);

    function tokensAllowlistAddress() external view returns (address);

    /* ========== PUBLIC VIEW FUNCTIONS ========== */

    function voterAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function penPoolsLength() external view returns (uint256);

    function userProxiesLength() external view returns (uint256);

    function userProxyByAccount(address accountAddress)
    external
    view
    returns (address);

    function userProxyByIndex(uint256 index) external view returns (address);

    function gaugeByDystPool(address) external view returns (address);

    function dystPoolByPenPool(address penPoolAddress)
    external
    view
    returns (address);

    function penPoolByDystPool(address dystPoolAddress)
    external
    view
    returns (address);

    function stakingRewardsByDystPool(address dystPoolAddress)
    external
    view
    returns (address);

    function stakingRewardsByPenPool(address dystPoolAddress)
    external
    view
    returns (address);

    function isPenPool(address penPoolAddress) external view returns (bool);

    function penPoolsAddresses() external view returns (address[] memory);

    function isPartner(address userProxyAddress) external view returns (bool);

    function stakedPenDystBalanceOf(address accountAddress)
    external
    view
    returns (uint256 stakedBalance);

    function dystInflationSinceInception() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface ISwapper {

    // ---  fields

    // ---  modifiers

    // ---  constructor

    // ---  setters

    // ---  structures

    struct SwapRoute {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        address swapPlace;
        address pool;
        //        string swapPlaceType;
    }

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 partsAmount;
    }


    // ---  logic

    function swap(SwapParams calldata params) external returns (uint256);

    function getAmountOut(SwapParams calldata params) external view returns (uint256);

    function swapPath(SwapParams calldata params) external view returns (SwapRoute[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IDystopiaRouter {
    
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);
    function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts);
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";

interface IVault {

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
    external
    view
    returns (
        uint256 cash,
        uint256 managed,
        uint256 lastChangeBlock,
        address assetManager
    );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        IERC20[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev IPools with the General specialization setting should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will
 * grant to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev Pool contracts with the MinimalSwapInfo or TwoToken specialization settings should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will grant
 * to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./IPoolSwapStructs.sol";

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    function getPoolId() external view returns (bytes32);
}

// SPDX-License-Identifier: GNU-3
pragma solidity >=0.6.2;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/DystopiaExchange.sol";
import "./connectors/dystopia/interfaces/IDystopiaLP.sol";
import "./connectors/aave/interfaces/IPriceFeed.sol";
import "./connectors/penrose/interface/IUserProxy.sol";
import "./connectors/penrose/interface/IPenLens.sol";
import "./libraries/AaveBorrowLibrary.sol";
import "./interfaces/ISwapper.sol";

contract StrategyDystopiaUsdcTusd is Strategy, DystopiaExchange {

    uint256 public constant BASIS_POINTS_FOR_SLIPPAGE_EIGHT = 8;

    IERC20 public usdcToken;
    IERC20 public tusdToken;
    IERC20 public dystToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public tusdTokenDenominator;

    IDystopiaLP public gauge;
    IDystopiaLP public dystPair;

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleTusd;

    IERC20 public penToken;
    IUserProxy public userProxy;
    IPenLens public penLens;

    ISwapper public swapper;

    uint256 public stakeStep;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address dystToken, address wmaticToken, address penToken,
        uint256 usdcTokenDenominator, uint256 tusdTokenDenominator);

    event StrategyUpdatedParams(address gauge, address dystPair, address dystRouter,
        address oracleUsdc, address oracleTusd, address userProxy, address penLens, address swapper);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _tusdToken,
        address _dystToken,
        address _wmaticToken,
        address _penToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_tusdToken != address(0), "Zero address not allowed");
        require(_dystToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_penToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        tusdToken = IERC20(_tusdToken);
        dystToken = IERC20(_dystToken);
        wmaticToken = IERC20(_wmaticToken);
        penToken = IERC20(_penToken);
        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        tusdTokenDenominator = 10 ** IERC20Metadata(_tusdToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _tusdToken, _dystToken, _wmaticToken, _penToken, usdcTokenDenominator, tusdTokenDenominator);
    }

    function setParams(
        address _gauge,
        address _dystPair,
        address _dystRouter,
        address _oracleUsdc,
        address _oracleTusd,
        address _userProxy,
        address _penLens,
        address _swapper,
        uint256 _stakeStep
    ) external onlyAdmin {

        require(_gauge != address(0), "Zero address not allowed");
        require(_dystPair != address(0), "Zero address not allowed");
        require(_dystRouter != address(0), "Zero address not allowed");
        require(_oracleUsdc != address(0), "Zero address not allowed");
        require(_oracleTusd != address(0), "Zero address not allowed");
        require(_userProxy != address(0), "Zero address not allowed");
        require(_penLens != address(0), "Zero address not allowed");
        require(_swapper != address(0), "Zero address not allowed");

        gauge = IDystopiaLP(_gauge);
        dystPair = IDystopiaLP(_dystPair);
        _setDystopiaRouter(_dystRouter);
        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleTusd = IPriceFeed(_oracleTusd);
        userProxy = IUserProxy(_userProxy);
        penLens = IPenLens(_penLens);
        swapper = ISwapper(_swapper);
        stakeStep = _stakeStep;

        emit StrategyUpdatedParams(_gauge, _dystPair, _dystRouter, _oracleUsdc, _oracleTusd, _userProxy, _penLens, _swapper);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveTusd,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveTusd > 10 ** 15, 'Liquidity lpToken reserves too low');

        uint256 usdcFullBalance = usdcToken.balanceOf(address(this));

        while (usdcFullBalance > 0) {
            uint256 usdcBalance = stakeStep;
            if (usdcFullBalance < usdcBalance) {
                usdcBalance = usdcFullBalance;
            }

            uint256 usdcBalanceFromTusd2 = AaveBorrowLibrary.convertTokenAmountToTokenAmount(
                tusdToken.balanceOf(address(this)),
                tusdTokenDenominator,
                usdcTokenDenominator,
                uint256(oracleTusd.latestAnswer()),
                uint256(oracleUsdc.latestAnswer())
            );

            uint256 amountUsdcToSwap = (usdcBalance - usdcBalanceFromTusd2) / 2;

            uint256 tusdBalanceFromUsdc = AaveBorrowLibrary.convertTokenAmountToTokenAmount(
                amountUsdcToSwap,
                usdcTokenDenominator,
                tusdTokenDenominator,
                uint256(oracleUsdc.latestAnswer()),
                uint256(oracleTusd.latestAnswer())
            );

            uint256 supposedTusdBalance = _getAmountsOut(address(usdcToken), address(tusdToken), true, amountUsdcToSwap);

            if (supposedTusdBalance < OvnMath.subBasisPoints(tusdBalanceFromUsdc, 8)) {
                break;
            }

            _swapExactTokensForTokens(
                address(usdcToken),
                address(tusdToken),
                true,
                amountUsdcToSwap,
                address(this),
                OvnMath.subBasisPoints(tusdBalanceFromUsdc, 8)
            );

            usdcBalance = usdcToken.balanceOf(address(this));
            uint256 tusdBalance = tusdToken.balanceOf(address(this));

            (reserveUsdc, reserveTusd,) = dystPair.getReserves();

            uint256 amountTusdMin = usdcBalance * reserveTusd / reserveUsdc;
            if (amountTusdMin > tusdBalance) {
                amountTusdMin = tusdBalance;
            }
            uint256 amountUsdcMin = tusdBalance * reserveUsdc / reserveTusd;
            if (amountUsdcMin > usdcBalance) {
                amountUsdcMin = usdcBalance;
            }

            _addLiquidity(
                address(usdcToken),
                address(tusdToken),
                usdcBalance,
                tusdBalance,
                OvnMath.subBasisPoints(amountUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountTusdMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );

            usdcFullBalance = usdcToken.balanceOf(address(this));
        }

        uint256 lpTokenBalance = dystPair.balanceOf(address(this));

        if (lpTokenBalance > 0) {
            dystPair.approve(address(userProxy), lpTokenBalance);
            userProxy.depositLpAndStake(address(dystPair), lpTokenBalance);
        }
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 currentUsdcBalance = usdcToken.balanceOf(address(this));
        if(currentUsdcBalance >= _amount)
            return _amount;


        (uint256 reserveUsdc, uint256 reserveTusd,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveTusd > 10 ** 15, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);

        if (lpTokenBalance > 0) {
            // count amount to unstake
            uint256 totalLpBalance = dystPair.totalSupply();
            uint256 lpTokensToWithdraw = _getAmountLpTokens(
                OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE) + 10,
                reserveUsdc,
                reserveTusd,
                totalLpBalance
            );

            if (lpTokensToWithdraw > lpTokenBalance) {
                lpTokensToWithdraw = lpTokenBalance;
            }

            userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokensToWithdraw);

            uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(tusdToken),
                address(dystPair),
                unstakedLPTokenBalance,
                0,
                0,
                address(this)
            );
        }

        if (tusdToken.balanceOf(address(this)) > 0) {
            _swapExactTokensForTokens(
                address(tusdToken),
                address(usdcToken),
                true,
                tusdToken.balanceOf(address(this)),
                address(this),
                0
            );
        }

        uint256 returnValue = usdcToken.balanceOf(address(this));

        if (returnValue > _amount) {
            returnValue = _amount;
        }
        return returnValue;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveTusd,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveTusd > 10 ** 15, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance == 0) {
            return usdcToken.balanceOf(address(this));
        }

        userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokenBalance);

        uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));
        if (unstakedLPTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(tusdToken),
                address(dystPair),
                unstakedLPTokenBalance,
                0,
                0,
                address(this)
            );
        }

        if (tusdToken.balanceOf(address(this)) > 0) {
            _swapExactTokensForTokens(
            address(tusdToken),
            address(usdcToken),
            true,
            tusdToken.balanceOf(address(this)),
            address(this),
            0);
        }

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 tusdBalance = tusdToken.balanceOf(address(this));

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();
            (uint256 reserveUsdc, uint256 reserveTusd,) = dystPair.getReserves();
            usdcBalance += reserveUsdc * lpTokenBalance / totalLpBalance;
            tusdBalance += reserveTusd * lpTokenBalance / totalLpBalance;
        }

        uint256 usdcBalanceFromTusd;
        if (tusdBalance > 0) {
            if (nav) {
                uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
                uint256 priceTusd = uint256(oracleTusd.latestAnswer());
                usdcBalanceFromTusd = AaveBorrowLibrary.convertTokenAmountToTokenAmount(
                    tusdBalance,
                    tusdTokenDenominator,
                    usdcTokenDenominator,
                    priceTusd,
                    priceUsdc
                );
            } else {
                usdcBalanceFromTusd = _getAmountsOut(address(tusdToken), address(usdcToken), true, tusdBalance);
            }
        }

        return usdcBalance + usdcBalanceFromTusd;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance > 0) {
            userProxy.claimStakingRewards();
        }

        // sell rewards
        uint256 totalUsdc;

        uint256 dystBalance = dystToken.balanceOf(address(this));
        if (dystBalance > 0) {
            uint256 dystUsdc = _swapExactTokensForTokens(
                address(dystToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                dystBalance,
                address(this)
            );
            totalUsdc += dystUsdc;
        }

        uint256 penBalance = penToken.balanceOf(address(this));
        if (penBalance > 0) {
            uint256 penUsdc = _swapExactTokensForTokens(
                address(penToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                penBalance,
                address(this)
            );
            totalUsdc += penUsdc;
        }

        usdcToken.transfer(_to, totalUsdc);

        return totalUsdc;
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountLpTokens(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance
    ) internal view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * tusdTokenDenominator) / (reserve0 * tusdTokenDenominator + reserve1 * usdcTokenDenominator);

        uint256 amount1 = reserve1 * lpBalance / totalLpBalance;

        uint256 amount0 = _getAmountsOut(address(tusdToken), address(usdcToken), true, amount1);

        lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);

        return lpBalance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/DystopiaExchange.sol";
import "./exchanges/BalancerExchange.sol";
import "./connectors/dystopia/interfaces/IDystopiaLP.sol";
import "./connectors/aave/interfaces/IPriceFeed.sol";
import "./connectors/penrose/interface/IUserProxy.sol";
import "./connectors/penrose/interface/IPenLens.sol";
import "./libraries/AaveBorrowLibrary.sol";
import "./interfaces/ISwapper.sol";


contract StrategyDystopiaUsdcDai is Strategy, DystopiaExchange, BalancerExchange {

    IERC20 public usdcToken;
    IERC20 public daiToken;
    IERC20 public dystToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public daiTokenDenominator;

    IDystopiaLP public gauge;
    IDystopiaLP public dystPair;
    bytes32 public poolIdUsdcTusdDaiUsdt;

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleDai;

    IERC20 public penToken;
    IUserProxy public userProxy;
    IPenLens public penLens;

    ISwapper public swapper;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address dystToken, address wmaticToken, address penToken,
        uint256 usdcTokenDenominator, uint256 daiTokenDenominator);

    event StrategyUpdatedParams(address gauge, address dystPair, address dystRouter, address balancerVault, bytes32 poolIdUsdcTusdDaiUsdt,
        address oracleUsdc, address oracleDai, address userProxy, address penLens, address swapper);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _daiToken,
        address _dystToken,
        address _wmaticToken,
        address _penToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_daiToken != address(0), "Zero address not allowed");
        require(_dystToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_penToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        daiToken = IERC20(_daiToken);
        dystToken = IERC20(_dystToken);
        wmaticToken = IERC20(_wmaticToken);
        penToken = IERC20(_penToken);
        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        daiTokenDenominator = 10 ** IERC20Metadata(_daiToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _daiToken, _dystToken, _wmaticToken, _penToken, usdcTokenDenominator, daiTokenDenominator);
    }

    function setParams(
        address _gauge,
        address _dystPair,
        address _dystRouter,
        address _balancerVault,
        bytes32 _poolIdUsdcTusdDaiUsdt,
        address _oracleUsdc,
        address _oracleDai,
        address _userProxy,
        address _penLens,
        address _swapper
    ) external onlyAdmin {

        require(_gauge != address(0), "Zero address not allowed");
        require(_dystPair != address(0), "Zero address not allowed");
        require(_dystRouter != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_poolIdUsdcTusdDaiUsdt != "", "Empty pool id not allowed");
        require(_oracleUsdc != address(0), "Zero address not allowed");
        require(_oracleDai != address(0), "Zero address not allowed");
        require(_userProxy != address(0), "Zero address not allowed");
        require(_penLens != address(0), "Zero address not allowed");
        require(_swapper != address(0), "Zero address not allowed");

        gauge = IDystopiaLP(_gauge);
        dystPair = IDystopiaLP(_dystPair);
        _setDystopiaRouter(_dystRouter);
        setBalancerVault(_balancerVault);
        poolIdUsdcTusdDaiUsdt = _poolIdUsdcTusdDaiUsdt;
        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleDai = IPriceFeed(_oracleDai);
        userProxy = IUserProxy(_userProxy);
        penLens = IPenLens(_penLens);
        swapper = ISwapper(_swapper);

        emit StrategyUpdatedParams(_gauge, _dystPair, _dystRouter, _balancerVault, _poolIdUsdcTusdDaiUsdt, _oracleUsdc,
            _oracleDai, _userProxy, _penLens, _swapper);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveDai,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveDai > 10 ** 15, 'Liquidity lpToken reserves too low');

        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 amountUsdcToSwap = _getAmountToken0(
            usdcBalance,
            reserveUsdc,
            reserveDai,
            usdcTokenDenominator,
            daiTokenDenominator,
            1,
            address(usdcToken),
            address(daiToken)
        );

        // swap usdc to usdt
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(usdcToken),
            address(daiToken),
            amountUsdcToSwap,
            0,
            5
        );
        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        // add liquidity
        usdcBalance = usdcToken.balanceOf(address(this));
        uint256 daiBalance = daiToken.balanceOf(address(this));

        _addLiquidity(
            address(usdcToken),
            address(daiToken),
            usdcBalance,
            daiBalance,
            OvnMath.subBasisPoints(usdcBalance, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(daiBalance, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );

        uint256 lpTokenBalance = dystPair.balanceOf(address(this));
        dystPair.approve(address(userProxy), lpTokenBalance);
        userProxy.depositLpAndStake(address(dystPair), lpTokenBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveDai,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveDai > 10 ** 15, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);

        if (lpTokenBalance > 0) {
            // count amount to unstake
            uint256 totalLpBalance = dystPair.totalSupply();
            uint256 lpTokensToWithdraw = _getAmountLpTokens(
                OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE) + 10,
                reserveUsdc,
                reserveDai,
                totalLpBalance
            );

            if (lpTokensToWithdraw > lpTokenBalance) {
                lpTokensToWithdraw = lpTokenBalance;
            }

            userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokensToWithdraw);

            uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));

            uint256 amountOutUsdcMin = reserveUsdc * unstakedLPTokenBalance / totalLpBalance;
            uint256 amountOutDaiMin = reserveDai * unstakedLPTokenBalance / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(daiToken),
                address(dystPair),
                unstakedLPTokenBalance,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutDaiMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap dai to usdc
        uint256 daiBalance = daiToken.balanceOf(address(this));
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(daiToken),
            address(usdcToken),
            daiBalance,
            0,
            5
        );

        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveDai,) = dystPair.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveDai > 10 ** 15, 'Liquidity lpToken reserves too low');

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance == 0) {
            return 0;
        }

        userProxy.unstakeLpAndWithdraw(address(dystPair), lpTokenBalance);

        uint256 unstakedLPTokenBalance = dystPair.balanceOf(address(this));
        if (unstakedLPTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();
            uint256 amountOutUsdcMin = reserveUsdc * unstakedLPTokenBalance / totalLpBalance;
            uint256 amountOutDaiMin = reserveDai * unstakedLPTokenBalance / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(daiToken),
                address(dystPair),
                unstakedLPTokenBalance,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutDaiMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap dai to usdc
        uint256 daiBalance = daiToken.balanceOf(address(this));
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(daiToken),
            address(usdcToken),
            daiBalance,
            0,
            5
        );
        IERC20(swapParams.tokenIn).approve(address(swapper), swapParams.amountIn);
        swapper.swap(swapParams);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 daiBalance = daiToken.balanceOf(address(this));

        // Fetch amount of penPool LP currently staked
        address userProxyThis = penLens.userProxyByAccount(address(this));
        address stakingAddress = penLens.stakingRewardsByDystPool(address(dystPair));
        uint256 lpTokenBalance = IERC20(stakingAddress).balanceOf(userProxyThis);
        if (lpTokenBalance > 0) {
            uint256 totalLpBalance = dystPair.totalSupply();
            (uint256 reserveUsdc, uint256 reserveDai,) = dystPair.getReserves();
            usdcBalance += reserveUsdc * lpTokenBalance / totalLpBalance;
            daiBalance += reserveDai * lpTokenBalance / totalLpBalance;
        }

        uint256 usdcBalanceFromDai;
        if (daiBalance > 0) {
            if (nav) {
                uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
                uint256 priceDai = uint256(oracleDai.latestAnswer());
                usdcBalanceFromDai = AaveBorrowLibrary.convertTokenAmountToTokenAmount(daiBalance, daiTokenDenominator, usdcTokenDenominator, priceDai, priceUsdc);
            } else {
                ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
                    address(daiToken),
                    address(usdcToken),
                    daiBalance,
                    0,
                    5
                );
                usdcBalanceFromDai = swapper.getAmountOut(swapParams);
            }
        }

        return usdcBalance + usdcBalanceFromDai;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        userProxy.claimStakingRewards();

        // sell rewards
        uint256 totalUsdc;

        uint256 dystBalance = dystToken.balanceOf(address(this));
        if (dystBalance > 0) {
            uint256 dystUsdc = _swapExactTokensForTokens(
                address(dystToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                dystBalance,
                address(this)
            );
            totalUsdc += dystUsdc;
        }

        uint256 penBalance = penToken.balanceOf(address(this));
        if (penBalance > 0) {
            uint256 penUsdc = _swapExactTokensForTokens(
                address(penToken),
                address(wmaticToken),
                address(usdcToken),
                false,
                false,
                penBalance,
                address(this)
            );
            totalUsdc += penUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));

        return totalUsdc;
    }

    /**
     * Get amount of token1 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountToken0(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1,
        uint256 precision,
        address token0,
        address token1
    ) internal view returns (uint256) {
        uint256 amount0 = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        for (uint i = 0; i < precision; i++) {
            ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
                token0,
                token1,
                amount0,
                0,
                5
            );
            uint256 amount1 = swapper.getAmountOut(swapParams);
            amount0 = (amount0Total * reserve1) / (reserve0 * amount1 / amount0 + reserve1);
        }

        return amount0;
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountLpTokens(
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance
    ) internal view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * daiTokenDenominator) / (reserve0 * daiTokenDenominator + reserve1 * usdcTokenDenominator);

        uint256 amount1 = reserve1 * lpBalance / totalLpBalance;
        ISwapper.SwapParams memory swapParams = ISwapper.SwapParams(
            address(daiToken),
            address(usdcToken),
            amount1,
            0,
            5
        );
        uint256 amount0 = swapper.getAmountOut(swapParams);
        lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);

        return lpBalance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../connectors/dystopia/interfaces/IDystopiaRouter.sol";
import "../connectors/dystopia/interfaces/IDystopiaLP.sol";
import "../connectors/aave/interfaces/IPriceFeed.sol";
import "../connectors/aave/interfaces/IPool.sol";
import "../connectors/aave/interfaces/IPoolAddressesProvider.sol";
import "../connectors/penrose/interface/IUserProxy.sol";
import "../connectors/penrose/interface/IPenLens.sol";
import "../libraries/WadRayMath.sol";
import "../interfaces/IExchange.sol";
import "../core/HedgeStrategy.sol";

import {AaveBorrowLibrary} from "../libraries/AaveBorrowLibrary.sol";
import {OvnMath} from "../libraries/OvnMath.sol";
import {UsdPlusWmaticLibrary} from "./libraries/UsdPlusWmaticLibrary.sol";

import "hardhat/console.sol";

contract StrategyUsdPlusWmatic is HedgeStrategy {
    using WadRayMath for uint256;
    using UsdPlusWmaticLibrary for StrategyUsdPlusWmatic;

    uint8 public constant E_MODE_CATEGORY_ID = 0;
    uint256 public constant INTEREST_RATE_MODE = 2;
    uint16 public constant REFERRAL_CODE = 0;
    uint256 public constant BASIS_POINTS_FOR_STORAGE = 100; // 1%
    uint256 public constant BASIS_POINTS_FOR_SLIPPAGE = 400; // 4%
    uint256 public constant MAX_UINT_VALUE = type(uint256).max;

    IExchange public exchange;

    IERC20 public usdPlus;
    IERC20 public usdc;
    IERC20 public aUsdc;
    IERC20 public wmatic;
    IERC20 public dyst;

    uint256 public usdcDm;
    uint256 public wmaticDm;

    IDystopiaRouter public dystRouter;
    IDystopiaLP public dystRewards;
    IDystopiaLP public dystVault;


    IERC20 public penToken;
    IUserProxy public penProxy;
    IPenLens public penLens;


    // Aave
    IPoolAddressesProvider public aavePoolAddressesProvider;
    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleWmatic;

    uint256 public usdcStorage;

    uint256 public liquidationThreshold;
    uint256 public healthFactor;
    uint256 public balancingDelta;
    uint256 public realHealthFactor;


    // method 0--nothing, 1--stake, 2--unstake
    struct Delta {
        uint256 aaveCollateralUsdNeeded;
        uint256 aaveBorrowUsdNeeded;
        uint256 poolUsdpUsdDelta;
        uint256 method;
        uint256 amount;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }

    function setTokens(
        address _usdc,
        address _aUsdc,
        address _wmatic,
        address _usdPlus,
        address _penToken,
        address _dyst
    ) external onlyAdmin {
        usdc = IERC20(_usdc);
        aUsdc = IERC20(_aUsdc);
        wmatic = IERC20(_wmatic);
        usdcDm = 10 ** IERC20Metadata(_usdc).decimals();
        wmaticDm = 10 ** IERC20Metadata(_wmatic).decimals();

        usdPlus = IERC20(_usdPlus);
        setAsset(_usdPlus);

        penToken = IERC20(_penToken);
        dyst = IERC20(_dyst);

    }


    function setParams(
        address _exchanger,
        address _dystRewards,
        address _dystVault,
        address _dystRouter,
        address _penProxy,
        address _penLens
    ) external onlyAdmin {

        dystRewards = IDystopiaLP(_dystRewards);
        dystVault = IDystopiaLP(_dystVault);
        dystRouter = IDystopiaRouter(_dystRouter);

        penProxy = IUserProxy(_penProxy);
        penLens = IPenLens(_penLens);

        exchange = IExchange(_exchanger);
    }

    function setAaveParams(
        address _aavePoolAddressesProvider,
        address _oracleUsdc,
        address _oracleWmatic,
        uint256 _liquidationThreshold,
        uint256 _healthFactor,
        uint256 _balancingDelta
    ) external onlyAdmin {

        aavePoolAddressesProvider = IPoolAddressesProvider(_aavePoolAddressesProvider);
        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleWmatic = IPriceFeed(_oracleWmatic);

        liquidationThreshold = _liquidationThreshold * 10 ** 15;
        healthFactor = _healthFactor * 10 ** 15;
        realHealthFactor = 0;
        balancingDelta = _balancingDelta * 10 ** 15;
    }

    function _stake(uint256 _amount) internal override {

        (uint256 caseNumber, uint256 aaveCollateralUsdNeeded, uint256 aaveBorrowUsdNeeded, uint256 poolUsdpUsdDelta) = getDeltas(1, _amount);

        console.log("stake case", caseNumber);

        Delta memory delta = Delta(
            aaveCollateralUsdNeeded,
            aaveBorrowUsdNeeded,
            poolUsdpUsdDelta, 1, _amount
        );

        if (caseNumber == 1) {
            this._caseNumber1(delta);
        }

        if (caseNumber == 2) {
            this._caseNumber2(delta);
        }

        if (caseNumber == 3) {
            this._caseNumber3(delta);
        }

        if (caseNumber == 4) {
            this._caseNumber4(delta);
        }

        if (caseNumber == 5) {
            this._caseNumber5(delta);
        }

        if (caseNumber == 6) {
            this._caseNumber6(delta);
        }

        // TODO: set realHealthFactor instead useless healthFactorCurrent
        (,,,,,uint256 healthFactorCurrent) = IPool(_aavePool()).getUserAccountData(address(this));
        realHealthFactor = healthFactorCurrent;
    }


    function _unstake(
        uint256 _amount
    ) internal override returns (uint256) {

        (uint256 caseNumber, uint256 aaveCollateralUsdNeeded, uint256 aaveBorrowUsdNeeded, uint256 poolUsdpUsdDelta) = getDeltas(2, _amount);

        console.log("unstake case", caseNumber);

        Delta memory delta = Delta(
            aaveCollateralUsdNeeded,
            aaveBorrowUsdNeeded,
            poolUsdpUsdDelta, 2, _amount
        );

        if (caseNumber == 1) {
            this._caseNumber1(delta);
        }

        if (caseNumber == 2) {
            this._caseNumber2(delta);
        }

        if (caseNumber == 3) {
            this._caseNumber3(delta);
        }

        if (caseNumber == 4) {
            this._caseNumber4(delta);
        }

        if (caseNumber == 5) {
            this._caseNumber5(delta);
        }

        if (caseNumber == 6) {
            this._caseNumber6(delta);
        }

        // TODO: set realHealthFactor instead useless healthFactorCurrent
        (,,,,,uint256 healthFactorCurrent) = IPool(_aavePool()).getUserAccountData(address(this));
        realHealthFactor = healthFactorCurrent;

        return _amount;
    }

    //TODO: remove underscore if public
    function _aavePool() public returns (IPool aavePool){
        aavePool = IPool(AaveBorrowLibrary.getAavePool(address(aavePoolAddressesProvider), E_MODE_CATEGORY_ID));
    }


    function balances() external view override returns (BalanceItem[] memory){

        // debt base (USD) convert to Wmatic amount
        //TODO: use _aavePool method if same
        (, uint256 debtBase,,,,) = IPool(AaveBorrowLibrary.getAavePool(address(aavePoolAddressesProvider))).getUserAccountData(address(this));
        uint256 aaveWmatic = AaveBorrowLibrary.convertUsdToTokenAmount(debtBase, wmaticDm, uint256(oracleWmatic.latestAnswer()));
        uint256 usdcWmatic = AaveBorrowLibrary.convertUsdToTokenAmount(debtBase, usdcDm, uint256(oracleUsdc.latestAnswer()));

        BalanceItem[] memory items = new BalanceItem[](4);
        items[0] = BalanceItem(address(wmatic), usdcWmatic, aaveWmatic, true);

        uint256 amountAusdc = aUsdc.balanceOf(address(this)) + usdc.balanceOf(address(this));
        items[1] = BalanceItem(address(aUsdc), amountAusdc, amountAusdc, false);

        (uint256 poolWmatic, uint256 poolUsdPlus) = this._getLiquidity();

        poolUsdPlus += usdPlus.balanceOf(address(this));

        usdcWmatic = AaveBorrowLibrary.convertTokenAmountToTokenAmount(
            poolWmatic,
            wmaticDm,
            usdcDm,
            uint256(oracleWmatic.latestAnswer()),
            uint256(oracleUsdc.latestAnswer())
        );

        items[2] = BalanceItem(address(wmatic), usdcWmatic, poolWmatic, false);
        items[3] = BalanceItem(address(usdPlus), poolUsdPlus, poolUsdPlus, false);

        return items;
    }


    function netAssetValue() external view override returns (uint256){


        (uint256 poolWmatic, uint256 poolUsdPlus) = this._getLiquidity();
        uint256 totalUsdPlus = poolUsdPlus + usdPlus.balanceOf(address(this));
        uint256 totalUsdc = usdc.balanceOf(address(this)) + aUsdc.balanceOf(address(this));


        // debt base (USD) convert to Wmatic amount
        (, uint256 debtBase,,,,) = IPool(AaveBorrowLibrary.getAavePool(address(aavePoolAddressesProvider))).getUserAccountData(address(this));
        uint256 aaveWmatic = AaveBorrowLibrary.convertUsdToTokenAmount(debtBase, wmaticDm, uint256(oracleWmatic.latestAnswer()));

        if (aaveWmatic < poolWmatic) {
            uint256 deltaWmatic = poolWmatic - aaveWmatic;
            totalUsdc += AaveBorrowLibrary.convertTokenAmountToTokenAmount(
                deltaWmatic,
                wmaticDm,
                usdcDm,
                uint256(oracleWmatic.latestAnswer()),
                uint256(oracleUsdc.latestAnswer())
            );

        } else {
            uint256 deltaWmatic = aaveWmatic - poolWmatic;
            totalUsdc -= AaveBorrowLibrary.convertTokenAmountToTokenAmount(
                deltaWmatic,
                wmaticDm,
                usdcDm,
                uint256(oracleWmatic.latestAnswer()),
                uint256(oracleUsdc.latestAnswer())
            );
        }


        uint256 wmaticBalance = wmatic.balanceOf(address(this));
        console.log("wmaticBalance: ", wmaticBalance);

//
        uint256 wmaticBalanceUsd = AaveBorrowLibrary.convertTokenAmountToUsd(wmaticBalance, wmaticDm, uint256(oracleWmatic.latestAnswer()));
        uint256 wmaticBalanceUsdc = wmaticBalanceUsd / 100;

        console.log("wmaticBalanceUsdc: ", wmaticBalanceUsdc);
        console.log("sum1: ", totalUsdPlus + totalUsdc + wmaticBalanceUsdc);
        console.log("sum2: ", totalUsdPlus + totalUsdc);

        return totalUsdPlus + totalUsdc + wmaticBalanceUsdc;
    }





    function _claimRewards(address _to) internal override returns (uint256){
       return this.claimRewards();
    }

    function _balance() internal override returns (uint256) {

        (uint256 caseNumber, uint256 aaveCollateralUsdNeeded, uint256 aaveBorrowUsdNeeded, uint256 poolUsdpUsdDelta) = getDeltas(0, 0);

        console.log("case", caseNumber);

        Delta memory delta = Delta(
            aaveCollateralUsdNeeded,
            aaveBorrowUsdNeeded,
            poolUsdpUsdDelta, 0, 0
        );

        //TODO: try to use readable enums and readable method names
        if (caseNumber == 1) {
            this._caseNumber1(delta);
        }

        if (caseNumber == 2) {
            this._caseNumber2(delta);
        }

        if (caseNumber == 3) {
            this._caseNumber3(delta);
        }

        if (caseNumber == 4) {
            this._caseNumber4(delta);
        }

        if (caseNumber == 5) {
            this._caseNumber5(delta);
        }

        if (caseNumber == 6) {
            this._caseNumber6(delta);
        }

        (,,,,,uint256 healthFactorCurrent) = IPool(_aavePool()).getUserAccountData(address(this));
        realHealthFactor = healthFactorCurrent;

        return healthFactorCurrent;
    }


    function currentHealthFactor() external view override returns (uint256){
        return realHealthFactor;
    }


    function getDeltas(uint256 method, uint256 amount) public view returns (uint256, uint256, uint256, uint256){
        //TODO: make getDeltas return Delta struct

        uint256 aaveCollateralPercent;
        uint256 aaveBorrowAndPoolMaticPercent;
        uint256 poolUsdpPercent;

        //TODO: may be extract to method
        {
            uint256 chainlinkUsdUsdc = uint256(oracleUsdc.latestAnswer());
            uint256 chainlinkUsdMatic = uint256(oracleWmatic.latestAnswer());
            (uint256 amount0Current, uint256 amount1Current,) = dystVault.getReserves();
            uint256 dystUsdpMatic = amount1Current * 10**20 / amount0Current;

            // console.log(chainlinkUsdUsdc);
            // console.log(chainlinkUsdMatic);
            // console.log(dystUsdpMatic);

            aaveCollateralPercent = (healthFactor * chainlinkUsdUsdc * chainlinkUsdMatic * 10 ** 18) / (healthFactor * chainlinkUsdUsdc * chainlinkUsdMatic + liquidationThreshold * dystUsdpMatic * 10 ** 8);
            aaveBorrowAndPoolMaticPercent = aaveCollateralPercent * liquidationThreshold / healthFactor;

            poolUsdpPercent = aaveBorrowAndPoolMaticPercent * dystUsdpMatic * 10 ** 8 / (chainlinkUsdUsdc * chainlinkUsdMatic);
        }

        // console.log("aaveCollateralPercent", aaveCollateralPercent);
        // console.log("aaveBorrowAndPoolMaticPercent", aaveBorrowAndPoolMaticPercent);
        // console.log("poolUsdpPercent", poolUsdpPercent);

        // TODO: use method _aavePool if same
        (uint256 aaveCollateralUsd, uint256 aaveBorrowUsd,,,,) = IPool(AaveBorrowLibrary.getAavePool(address(aavePoolAddressesProvider))).getUserAccountData(address(this));
        uint256 poolWmatic;
        uint256 poolUsdPlus;

        //TODO: extract to method
        {
            address userProxyThis = penLens.userProxyByAccount(address(this));
            address stakingAddress = penLens.stakingRewardsByDystPool(address(dystVault));
            uint256 balanceLp = IERC20(stakingAddress).balanceOf(userProxyThis);
            (poolWmatic, poolUsdPlus) = this._getLiquidityByLp(balanceLp);
        }

        // TODO: move definition to usage
        uint256 NAV;
        uint256 poolMaticUsd = AaveBorrowLibrary.convertTokenAmountToUsd(poolWmatic, wmaticDm, uint256(oracleWmatic.latestAnswer()));
        uint256 poolUsdpUsd = AaveBorrowLibrary.convertTokenAmountToUsd(poolUsdPlus, usdcDm, uint256(oracleUsdc.latestAnswer()));
        // console.log("aaveCollateralUsd", aaveCollateralUsd);
        // console.log("aaveBorrowUsd", aaveBorrowUsd);
        // console.log("poolMaticUsd", poolMaticUsd);
        // console.log("poolUsdpUsd", poolUsdpUsd);
        NAV = poolMaticUsd + poolUsdpUsd + aaveCollateralUsd - aaveBorrowUsd;

        if (method == 1) {
            NAV += amount;
        } else if (method == 2) {
            NAV -= amount;
        }
        // console.log("NAV", NAV);


        // console.log("aaveCollateralUsdNeeded", NAV*aaveCollateralPercent/10**18);
        // console.log("aaveBorrowUsdNeeded", NAV*aaveBorrowAndPoolMaticPercent/10**18);
        // console.log("poolMaticUsdNeeded", NAV*aaveBorrowAndPoolMaticPercent/10**18);
        // console.log("poolUsdpUsdNeeded", NAV*poolUsdpPercent/10**18);
        console.log("");
        // console.log("aaveCollateralUsdDelta", NAV*aaveCollateralPercent/10**18 - aaveCollateralUsd);
        // console.log("aaveBorrowUsdDelta", aaveBorrowUsd - NAV*aaveBorrowAndPoolMaticPercent/10**18);
        // console.log("poolMaticUsdDelta", poolMaticUsd - NAV*aaveBorrowAndPoolMaticPercent/10**18);
        // console.log("poolUsdpUsdDelta", poolUsdpUsd - NAV*poolUsdpPercent/10**18);
        // console.log("");

        //TODO: split by bracnches
        //TODO: add revert for unexpected branches
        //TODO: move computations out to vars or context struct for readability
        if (poolUsdpUsd > NAV*poolUsdpPercent/10**18 && aaveBorrowUsd > NAV*aaveBorrowAndPoolMaticPercent/10**18 && aaveCollateralUsd > NAV*aaveCollateralPercent/10**18) {
            return (1, aaveCollateralUsd - NAV*aaveCollateralPercent/10**18,
            aaveBorrowUsd - NAV*aaveBorrowAndPoolMaticPercent/10**18,
            poolUsdpUsd - NAV*poolUsdpPercent/10**18
            );
        } else if (aaveCollateralUsd > NAV*aaveCollateralPercent/10**18 && aaveBorrowUsd > NAV*aaveBorrowAndPoolMaticPercent/10**18 && NAV*poolUsdpPercent/10**18 > poolUsdpUsd){
            return (2, aaveCollateralUsd - NAV*aaveCollateralPercent/10**18,
            aaveBorrowUsd - NAV*aaveBorrowAndPoolMaticPercent/10**18,
            NAV*poolUsdpPercent/10**18 - poolUsdpUsd
            );
        } else if (aaveCollateralUsd > NAV*aaveCollateralPercent/10**18 && NAV*aaveBorrowAndPoolMaticPercent/10**18 > aaveBorrowUsd && NAV*poolUsdpPercent/10**18 > poolUsdpUsd) {
            return (3, aaveCollateralUsd - NAV*aaveCollateralPercent/10**18,
            NAV*aaveBorrowAndPoolMaticPercent/10**18 - aaveBorrowUsd,
            NAV*poolUsdpPercent/10**18 - poolUsdpUsd
            );
        } else if (NAV*aaveCollateralPercent/10**18 > aaveCollateralUsd && aaveBorrowUsd > NAV*aaveBorrowAndPoolMaticPercent/10**18 && poolUsdpUsd > NAV*poolUsdpPercent/10**18) {
            return (4, NAV*aaveCollateralPercent/10**18 - aaveCollateralUsd,
            aaveBorrowUsd - NAV*aaveBorrowAndPoolMaticPercent/10**18,
            poolUsdpUsd - NAV*poolUsdpPercent/10**18
            );
        } else if (NAV*aaveCollateralPercent/10**18 > aaveCollateralUsd && NAV*aaveBorrowAndPoolMaticPercent/10**18 > aaveBorrowUsd && poolUsdpUsd > NAV*poolUsdpPercent/10**18) {
            return (5, NAV*aaveCollateralPercent/10**18 - aaveCollateralUsd,
            NAV*aaveBorrowAndPoolMaticPercent/10**18 - aaveBorrowUsd,
            poolUsdpUsd - NAV*poolUsdpPercent/10**18
            );
        } else if (NAV*aaveCollateralPercent/10**18 > aaveCollateralUsd && NAV*aaveBorrowAndPoolMaticPercent/10**18 > aaveBorrowUsd && NAV*poolUsdpPercent/10**18 > poolUsdpUsd) {
            return (6, NAV*aaveCollateralPercent/10**18 - aaveCollateralUsd,
            NAV*aaveBorrowAndPoolMaticPercent/10**18 - aaveBorrowUsd,
            NAV*poolUsdpPercent/10**18 - poolUsdpUsd
            );
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

//import {Errors} from '../helpers/Errors.sol';

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

    require(a <= (type(uint256).max - halfWAD) / b, 'Errors.MATH_MULTIPLICATION_OVERFLOW');

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Errors.MATH_DIVISION_BY_ZERO');
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, 'Errors.MATH_MULTIPLICATION_OVERFLOW');

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

    require(a <= (type(uint256).max - halfRAY) / b, 'Errors.MATH_MULTIPLICATION_OVERFLOW');

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Errors.MATH_DIVISION_BY_ZERO');
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, 'Errors.MATH_MULTIPLICATION_OVERFLOW');

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
    require(result >= halfRatio, 'Errors.MATH_ADDITION_OVERFLOW');

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, 'Errors.MATH_MULTIPLICATION_OVERFLOW');
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IExchange {

    function balance() external view returns (uint256);

    /**
     * @param _addrTok Token to withdraw
     * @param _amount Amount of USD+ tokens to burn
     * @return Amount of minted to caller tokens
     */
    function buy(address _addrTok, uint256 _amount) external returns (uint256);

    /**
     * @param _addrTok Token to withdraw
     * @param _amount Amount of USD+ tokens to burn
     * @return Amount of unstacked and transferred to caller tokens
     */
    function redeem(address _addrTok, uint256 _amount) external returns (uint256);

    function payout() external;

    function redeemFee() external view returns (uint256);
    function redeemFeeDenominator() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IHedgeStrategy.sol";


abstract contract HedgeStrategy is IHedgeStrategy, Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EXCHANGER = keccak256("EXCHANGER");

    IERC20 public asset;
    address public exchanger;


    function __Strategy_init() internal initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}

    // ---  modifiers

    modifier onlyExchanger() {
        require(hasRole(EXCHANGER, msg.sender), "Restricted to EXCHANGER");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    // --- setters

    function setExchanger(address _value) public onlyAdmin {
        require(_value != address(0), "Zero address not allowed");

        revokeRole(EXCHANGER, exchanger);
        grantRole(EXCHANGER, _value);

        exchanger = _value;
    }

    function setAsset(address _value) internal {
        require(_value != address(0), "Zero address not allowed");
        asset = IERC20(_value);
    }


    // --- logic


    function stake(
        uint256 _amount // value for staking in USDC
    ) external override onlyExchanger {
        emit Stake(_amount);
        _stake(asset.balanceOf(address(this)));
    }

    function unstake(
        uint256 _amount,
        address _to
    ) external override onlyExchanger returns (uint256) {
        uint256   withdrawAmount = _unstake(_amount );
        require(withdrawAmount >= _amount, 'Returned value less than requested amount');

        asset.transfer(_to, withdrawAmount);
        emit Unstake(_amount, withdrawAmount);

        return withdrawAmount;
    }

    function claimRewards(address _to) external override onlyExchanger returns (uint256) {
        uint256 totalUsdc = _claimRewards(_to);
        emit Reward(totalUsdc);
        return totalUsdc;
    }

    function balance() external override {
        _balance();
    }



    function _stake(
        uint256 _amount
    ) internal virtual {
        revert("Not implemented");
    }

    function _unstake(
        uint256 _amount
    ) internal virtual returns (uint256){
        revert("Not implemented");
    }

    function _claimRewards(address _to) internal virtual returns (uint256){
        revert("Not implemented");
    }

    function _balance() internal virtual returns (uint256) {

    }


    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

import "../StrategyUsdPlusWmatic.sol";
import "../../libraries/AaveBorrowLibrary.sol";
import "../../connectors/dystopia/interfaces/IDystopiaLP.sol";
import "../../connectors/dystopia/interfaces/IDystopiaRouter.sol";
import {OvnMath} from "../../libraries/OvnMath.sol";
import {DystopiaLibrary} from "../../libraries/DystopiaLibrary.sol";

import "hardhat/console.sol";

library UsdPlusWmaticLibrary {


    function _addLiquidity(StrategyUsdPlusWmatic self, uint256 wmaticAmount, uint256 usdPlusAmount) public {

        self.usdPlus().approve(address(self.dystRouter()), type(uint256).max);
        self.wmatic().approve(address(self.dystRouter()), wmaticAmount);

        self.dystRouter().addLiquidity(
            address(self.wmatic()),
            address(self.usdPlus()),
            false,
            wmaticAmount,
            usdPlusAmount,
            0,
            0,
            address(self),
            block.timestamp + 600
        );


        uint256 lpTokenBalance = self.dystVault().balanceOf(address(self));
        self.dystVault().approve(address(self.penProxy()), lpTokenBalance);
        self.penProxy().depositLpAndStake(address(self.dystVault()), lpTokenBalance);
    }

    function _aavePool(StrategyUsdPlusWmatic self) public returns (IPool aavePool){
        aavePool = IPool(AaveBorrowLibrary.getAavePool(address(self.aavePoolAddressesProvider()), self.E_MODE_CATEGORY_ID()));
    }


    function _removeLiquidity(StrategyUsdPlusWmatic self, uint256 amountLp) public returns (uint256 amountWmatic, uint256 amountUsdPlus) {

        (uint256 amountLiq0, uint256 amountLiq1) = _getLiquidityByLp(self, amountLp);
        (amountWmatic, amountUsdPlus) = self.dystRouter().removeLiquidity(
            address(self.wmatic()),
            address(self.usdPlus()),
            false,
            amountLp,
            (amountLiq0 == 0) ? 0 : OvnMath.subBasisPoints(amountLiq0, self.BASIS_POINTS_FOR_SLIPPAGE()),
            (amountLiq1 == 0) ? 0 : OvnMath.subBasisPoints(amountLiq1, self.BASIS_POINTS_FOR_SLIPPAGE()),
            address(self),
            block.timestamp + 600
        );

    }


    function _getLiquidityForToken(StrategyUsdPlusWmatic self, uint256 token0Borrow) public view returns (uint256) {
        (uint256 amount0, uint256 amount1,) = self.dystVault().getReserves();
        uint256 amountLp = token0Borrow * self.dystVault().totalSupply() / amount0;
        return amountLp;
    }


    function _convertTokensToUsdPlus(StrategyUsdPlusWmatic self) public {

        IERC20 wmatic = self.wmatic();
        IERC20 usdc = self.usdc();
        IERC20 usdPlus = self.usdPlus();

        if (wmatic.balanceOf(address(self)) > 0) {
            DystopiaLibrary._swap(
                self.dystRouter(),
                address(wmatic),
                address(usdPlus),
                false,
                wmatic.balanceOf(address(self)),
                address(self)
            );
        }

        usdc.approve(address(self.exchange()), usdc.balanceOf(address(self)));
        self.exchange().buy(address(usdc), usdc.balanceOf(address(self)));
    }


    function _getAmountToken0(
        StrategyUsdPlusWmatic self,
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1,
        uint256 precision,
        address token0,
        address token1
    ) public view returns (uint256) {
        uint256 amount0 = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        for (uint i = 0; i < precision; i++) {
            uint256 amount1 = DystopiaLibrary._getAmountOut(self.dystRouter(), token0, token1, false, amount0);
            amount0 = (amount0Total * reserve1) / (reserve0 * amount1 / amount0 + reserve1);
        }

        return amount0;
    }

    function _getLiquidity(StrategyUsdPlusWmatic self) public view returns (uint256, uint256){

        address userProxyThis = self.penLens().userProxyByAccount(address(self));
        address stakingAddress = self.penLens().stakingRewardsByDystPool(address(self.dystVault()));
        uint256 balanceLp = IERC20(stakingAddress).balanceOf(userProxyThis);

        return _getLiquidityByLp(self, balanceLp);
    }

    function _getLiquidityByLp(StrategyUsdPlusWmatic self, uint256 balanceLp) public view returns (uint256, uint256){

        (uint256 amount0Current, uint256 amount1Current,) = self.dystVault().getReserves();

        uint256 amountLiq0 = amount0Current * balanceLp / self.dystVault().totalSupply();
        uint256 amountLiq1 = amount1Current * balanceLp / self.dystVault().totalSupply();
        return (amountLiq0, amountLiq1);
    }

    function _getAmountLpTokensToWithdraw(
        StrategyUsdPlusWmatic self,
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance,
        uint256 denominator0,
        uint256 denominator1,
        address token0,
        address token1
    ) public view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * denominator1) / (reserve0 * denominator1 + reserve1 * denominator0);
        uint256 amount1 = reserve1 * lpBalance / totalLpBalance;

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = token1;
        route[0].to = token0;
        route[0].stable = true;
        uint256 amount0 = self.dystRouter().getAmountsOut(amount1, route)[2];

        lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);

        return lpBalance;
    }


    function _pushAllUsdpToPool(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        IERC20 usdPlus = self.usdPlus();
        IERC20 wmatic = self.wmatic();

        (uint256 amount0Current, uint256 amount1Current,) = self.dystVault().getReserves();

        uint256 allowedAmount = usdPlus.balanceOf(address(self)) - (delta.method == 2 ? delta.amount : 0);
        console.log("allowedAmount", allowedAmount);
        uint256 amountUsdcToSwap = _getAmountToken0(
            self,
            allowedAmount,
            amount1Current,
            amount0Current,
            self.usdcDm(),
            self.wmaticDm(),
            1,
            address(usdPlus),
            address(wmatic)
        );

        DystopiaLibrary._swap(
            self.dystRouter(),
            address(usdPlus),
            address(wmatic),
            false,
            amountUsdcToSwap,
            address(self));

        uint256 usdPlusAmount = usdPlus.balanceOf(address(self)) - (delta.method == 2 ? delta.amount : 0);
        uint256 wmaticAmount = wmatic.balanceOf(address(self));

        _addLiquidity(self, wmaticAmount, usdPlusAmount);
    }

    function _removeLiq(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {
        delta.poolUsdpUsdDelta = AaveBorrowLibrary.convertUsdToTokenAmount(delta.poolUsdpUsdDelta, self.usdcDm(), uint256(self.oracleUsdc().latestAnswer()));
        IPool aave = _aavePool(self);

        {
            address userProxyThis = self.penLens().userProxyByAccount(address(self));
            address stakingAddress = self.penLens().stakingRewardsByDystPool(address(self.dystVault()));
            uint256 balanceLp = IERC20(stakingAddress).balanceOf(userProxyThis);
            (, uint256 poolUsdPlus) = _getLiquidityByLp(self, balanceLp);
            uint256 lpforusdp = delta.poolUsdpUsdDelta * balanceLp / poolUsdPlus;

            self.penProxy().unstakeLpAndWithdraw(address(self.dystVault()), lpforusdp);
            self.dystVault().approve(address(self.dystRouter()), lpforusdp);
            _removeLiquidity(self, lpforusdp);
        }
    }

    function _repayAllWmatic(StrategyUsdPlusWmatic self) public {
        self.wmatic().approve(address(_aavePool(self)), self.wmatic().balanceOf(address(self)));
        _aavePool(self).repay(address(self.wmatic()), self.wmatic().balanceOf(address(self)), self.INTEREST_RATE_MODE(), address(self));
    }

    function _withdrawNeededUsdcInUsd(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {
        uint256 aaveUsdc = AaveBorrowLibrary.convertUsdToTokenAmount(delta.aaveCollateralUsdNeeded, self.usdcDm(), uint256(self.oracleUsdc().latestAnswer()));
        _aavePool(self).withdraw(address(self.usdc()), aaveUsdc, address(self));
    }

    function _supplyCurrentUsdcAmount(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta, uint256 amount) public {
        self.usdc().approve(address(_aavePool(self)), amount);
        _aavePool(self).supply(address(self.usdc()), amount, address(this), self.REFERRAL_CODE());

    }

    function _borrowNeededWmatic(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {
        uint256 aaveMatic = AaveBorrowLibrary.convertUsdToTokenAmount(delta.aaveBorrowUsdNeeded, self.wmaticDm(), uint256(self.oracleWmatic().latestAnswer()));
        _aavePool(self).borrow(address(self.wmatic()), aaveMatic, self.INTEREST_RATE_MODE(), self.REFERRAL_CODE(), address(self));
    }

    function _swapUspPlusToToken(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta, address _to, uint256 amount, bool stable) public {
        DystopiaLibrary._swap(
            self.dystRouter(),
            address(self.usdPlus()),
            _to,
            stable,
            amount,
            address(self));
    }

    function _swapUsdcToWmatic(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta, uint256 amount) public {
        DystopiaLibrary._swap(
            self.dystRouter(),
            address(self.usdc()),
            address(self.wmatic()),
            false,
            amount,
            address(self));
    }

    function _caseNumber1(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _removeLiq(self, delta);
        _withdrawNeededUsdcInUsd(self, delta);

        _convertTokensToUsdPlus(self);

        _swapUspPlusToToken(self, delta, address(self.wmatic()), self.usdPlus().balanceOf(address(self)) - (delta.method == 2 ? delta.amount : 0), false);
        _repayAllWmatic(self);
    }

    function _caseNumber2(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _withdrawNeededUsdcInUsd(self, delta);

//        _convertTokensToUsdPlus(self); leads to an error during the exchange _swapUsdcToWmatic()
        _swapUsdcToWmatic(self, delta, delta.aaveBorrowUsdNeeded / 100);

        _repayAllWmatic(self);
        _pushAllUsdpToPool(self, delta);
    }


    function _caseNumber3(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _withdrawNeededUsdcInUsd(self, delta);
        _borrowNeededWmatic(self, delta);

        _convertTokensToUsdPlus(self);

        _pushAllUsdpToPool(self, delta);
    }

    function _caseNumber4(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _removeLiq(self, delta);

        _convertTokensToUsdPlus(self);

        _swapUspPlusToToken(self, delta, address(self.usdc()), self.usdPlus().balanceOf(address(self)) - (delta.method == 2 ? delta.amount : 0), true);
        _supplyCurrentUsdcAmount(self, delta, delta.aaveCollateralUsdNeeded / 100);
        _swapUsdcToWmatic(self, delta, self.usdc().balanceOf(address(self)));

        _repayAllWmatic(self);
    }


    function _caseNumber5(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _removeLiq(self, delta);
        _borrowNeededWmatic(self, delta);

        _convertTokensToUsdPlus(self);

        _swapUspPlusToToken(self, delta, address(self.usdc()), self.usdPlus().balanceOf(address(self)) - (delta.method == 2 ? delta.amount : 0), true);
        _supplyCurrentUsdcAmount(self, delta, self.usdc().balanceOf(address(self)));
    }


    function _caseNumber6(StrategyUsdPlusWmatic self, StrategyUsdPlusWmatic.Delta memory delta) public {

        _borrowNeededWmatic(self, delta);

        _convertTokensToUsdPlus(self);

        _swapUspPlusToToken(self, delta, address(self.usdc()), delta.aaveCollateralUsdNeeded / 100, true);
        _supplyCurrentUsdcAmount(self, delta, self.usdc().balanceOf(address(self)));
        _pushAllUsdpToPool(self, delta);
    }


    function claimRewards(StrategyUsdPlusWmatic self) public returns (uint256){

        // claim rewards
        self.penProxy().claimStakingRewards();

        // sell rewards
        uint256 totalUsdc = 0;

        uint256 dystBalance = self.dyst().balanceOf(address(self));
        if (dystBalance > 0) {
            uint256 dystUsdc = DystopiaLibrary._swapExactTokensForTokens(
                self.dystRouter(),
                address(self.dyst()),
                address(self.wmatic()),
                address(self.usdPlus()),
                false,
                false,
                dystBalance,
                address(self)
            );
            totalUsdc += dystUsdc;
        }

        uint256 penBalance = self.penToken().balanceOf(address(self));
        if (penBalance > 0) {
            uint256 penUsdc = DystopiaLibrary._swapExactTokensForTokens(
                self.dystRouter(),
                address(self.penToken()),
                address(self.wmatic()),
                address(self.usdPlus()),
                false,
                false,
                penBalance,
                address(self)
            );
            totalUsdc += penUsdc;
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHedgeStrategy {

    event Reward(uint256 amount);

    event Stake(uint256 amount);
    event Unstake(uint256 amount, uint256 amountReceived);

    event SetHealthFactor(uint256 healthFactor);

    struct BalanceItem {
        address token;
        uint256 amountUSDC;
        uint256 amount;
        bool    borrowed;
    }

    function stake(
        uint256 _amount // value for staking in asset
    ) external;

    function unstake(
        uint256 _amount, // minimum expected value for unstaking in asset
        address _to      // PortfolioManager
    ) external returns (uint256); // Real unstake value

    function netAssetValue() external view returns (uint256); // Return value in USDC - denominator 6

    function claimRewards(address _to) external returns (uint256); // Return received amount in USDC - denominator 6

    function balance() external ; // Balancing aave health factor

    function currentHealthFactor() external returns (uint256);      // Aave healthFactor

    function balances() external view returns (BalanceItem[] memory ); // Balancing aave health factor

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/dystopia/interfaces/IDystopiaRouter.sol";
import "../libraries/OvnMath.sol";

import "hardhat/console.sol";

library DystopiaLibrary {


    function _swapExactTokensForTokens(
        IDystopiaRouter dystRouter,
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(dystRouter), amountInput);

        uint256 amountOutMin = _getAmountsOut(dystRouter, address(inputToken), address(middleToken), address(outputToken), isStablePair0, isStablePair1, amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystRouter.swapExactTokensForTokens(
            amountInput,
            0,
            route,
            recipient,
            block.timestamp + 600
        );

        return amounts[2];
    }

    function _swap(
        IDystopiaRouter dystRouter,
        address inputToken,
        address outputToken,
        bool isStablePair,
        uint256 amountInput,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(dystRouter), type(uint256).max);

        uint256 amountOutMin = _getAmountOut(dystRouter, address(inputToken), address(outputToken), isStablePair,  amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](1);
        route[0].from = inputToken;
        route[0].to = outputToken;
        route[0].stable = isStablePair;

        uint[] memory amounts = dystRouter.swapExactTokensForTokens(
            amountInput,
            amountOutMin,
            route,
            recipient,
            block.timestamp + 600
        );

        return amounts[1];
    }

    function _getAmountOut(
        IDystopiaRouter dystRouter,
        address inputToken,
        address outputToken,
        bool isStablePair,
        uint256 amountInput
    ) internal view returns (uint256) {

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](1);
        route[0].from = inputToken;
        route[0].to = outputToken;
        route[0].stable = isStablePair;

        uint[] memory amounts = dystRouter.getAmountsOut(amountInput, route);

        return amounts[1];
    }

    function _getAmountsOut(
        IDystopiaRouter dystRouter,
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput
    ) internal view returns (uint256) {

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystRouter.getAmountsOut(amountInput, route);

        return amounts[2];
    }

    function _addLiquidity(
        IDystopiaRouter dystRouter,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB, uint liquidity) {

        IERC20(tokenA).approve(address(dystRouter), amountADesired);
        IERC20(tokenB).approve(address(dystRouter), amountBDesired);

        return dystRouter.addLiquidity(
            tokenA,
            tokenB,
            true,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );

    }

    function _removeLiquidity(
        IDystopiaRouter dystRouter,
        address tokenA,
        address tokenB,
        address lpToken,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal returns (uint amountA, uint amountB) {

        IERC20(lpToken).approve(address(dystRouter), liquidity);

        return dystRouter.removeLiquidity(
            tokenA,
            tokenB,
            true,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + 600
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./libraries/OvnMath.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/synapse/interfaces/ISwap.sol";
import "./connectors/synapse/interfaces/IMiniChefV2.sol";
import "./connectors/dystopia/interfaces/IDystopiaRouter.sol";


contract StrategySynapseUsdc is Strategy, UniswapV2Exchange {
    using OvnMath for uint256;

    IERC20 public usdcToken;
    IERC20 public nUsdLPToken;
    IERC20 public synToken;

    ISwap public swap;
    IMiniChefV2 public miniChefV2;
    uint256 public pid;

    IERC20 public usdPlusToken;
    IDystopiaRouter public dystopiaRouter;

    // --- events

    event StrategyUpdatedTokens(address usdcToken, address nUsdLPToken, address synToken, address usdPlusToken);

    event StrategyUpdatedParams(address swap, address miniChefV2, address sushiSwapRouter, uint256 pid, address dystopiaRouter);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _nUsdLPToken,
        address _synToken,
        address _usdPlusToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_nUsdLPToken != address(0), "Zero address not allowed");
        require(_synToken != address(0), "Zero address not allowed");
        require(_usdPlusToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        nUsdLPToken = IERC20(_nUsdLPToken);
        synToken = IERC20(_synToken);
        usdPlusToken = IERC20(_usdPlusToken);

        emit StrategyUpdatedTokens(_usdcToken, _nUsdLPToken, _synToken, _usdPlusToken);
    }

    function setParams(
        address _swap,
        address _miniChefV2,
        address _sushiSwapRouter,
        uint64 _pid,
        address _dystopiaRouter
    ) external onlyAdmin {

        require(_swap != address(0), "Zero address not allowed");
        require(_miniChefV2 != address(0), "Zero address not allowed");
        require(_sushiSwapRouter != address(0), "Zero address not allowed");
        require(_pid != 0, "Zero value not allowed");
        require(_dystopiaRouter != address(0), "Zero address not allowed");

        swap = ISwap(_swap);
        miniChefV2 = IMiniChefV2(_miniChefV2);
        _setUniswapRouter(_sushiSwapRouter);
        pid = _pid;
        dystopiaRouter = IDystopiaRouter(_dystopiaRouter);

        emit StrategyUpdatedParams(_swap, _miniChefV2, _sushiSwapRouter, _pid, _dystopiaRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // add liquidity
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = _amount.subBasisPoints(4);
        amounts[3] = 0;
        uint256 minToMint = swap.calculateTokenAmount(amounts, true);
        amounts[2] = _amount;
        usdcToken.approve(address(swap), _amount);
        uint256 nUsdLPTokenAmount = swap.addLiquidity(amounts, minToMint, block.timestamp);

        // stake
        nUsdLPToken.approve(address(miniChefV2), nUsdLPTokenAmount);
        miniChefV2.deposit(pid, nUsdLPTokenAmount, address(this));
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = _amount.addBasisPoints(4) + 1;
        amounts[3] = 0;
        uint256 balanceLP = swap.calculateTokenAmount(amounts, false);
        (uint256 amount,) = miniChefV2.userInfo(pid, address(this));
        if (balanceLP > amount) {
            balanceLP = amount;
        }
        miniChefV2.withdraw(pid, balanceLP, address(this));

        // remove liquidity
        nUsdLPToken.approve(address(swap), balanceLP);
        swap.removeLiquidityOneToken(balanceLP, 2, _amount, block.timestamp);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        (uint256 amount,) = miniChefV2.userInfo(pid, address(this));
        if (amount == 0) {
            return usdcToken.balanceOf(address(this));
        }
        miniChefV2.withdraw(pid, amount, address(this));

        // remove liquidity
        uint256 usdcBalance = swap.calculateRemoveLiquidityOneToken(amount, 2);
        nUsdLPToken.approve(address(swap), amount);
        swap.removeLiquidityOneToken(amount, 2, usdcBalance, block.timestamp);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        (uint256 amount,) = miniChefV2.userInfo(pid, address(this));
        if (amount > 0) {
            if (nav) {
                usdcBalance += swap.calculateRemoveLiquidityOneToken(1e18, 2) * amount / 1e18;
            } else {
                usdcBalance += swap.calculateRemoveLiquidityOneToken(amount, 2);
            }
        }

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        (uint256 amount,) = miniChefV2.userInfo(pid, address(this));
        if (amount == 0) {
            return 0;
        }
        miniChefV2.harvest(pid, address(this));

        // sell rewards
        uint256 totalUsdc;

        uint256 synBalance = synToken.balanceOf(address(this));
        if (synBalance > 0) {
            uint256 synUsdc = _swapExactTokensForTokens(
                address(synToken),
                address(usdPlusToken),
                address(usdcToken),
                false,
                true,
                synBalance,
                address(this)
            );
            totalUsdc += synUsdc;
        }

        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        if (usdcBalance > 0) {
            usdcToken.transfer(_to, usdcBalance);
        }

        return totalUsdc;
    }

    function _getAmountsOut(
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput
    ) internal view returns (uint256) {

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystopiaRouter.getAmountsOut(amountInput, route);

        return amounts[2];
    }

    function _swapExactTokensForTokens(
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStablePair0,
        bool isStablePair1,
        uint256 amountInput,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(dystopiaRouter), amountInput);

        uint256 amountOutMin = _getAmountsOut(address(inputToken), address(middleToken), address(outputToken), isStablePair0, isStablePair1, amountInput);
        if (amountOutMin == 0) {
            return 0;
        }

        IDystopiaRouter.Route[] memory route = new IDystopiaRouter.Route[](2);
        route[0].from = inputToken;
        route[0].to = middleToken;
        route[0].stable = isStablePair0;
        route[1].from = middleToken;
        route[1].to = outputToken;
        route[1].stable = isStablePair1;

        uint[] memory amounts = dystopiaRouter.swapExactTokensForTokens(
            amountInput,
            0,
            route,
            recipient,
            block.timestamp + 600
        );

        return amounts[2];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSynapsePerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function poolLength() external view returns (uint256);

    function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/uniswap/v2/interfaces/IUniswapV2Pair.sol";
import "./libraries/LowGasSafeMath.sol";
import "./connectors/uniswap/v2/interfaces/IUniswapV2Router01.sol";

contract StrategyQsMaiUsdt is Strategy, UniswapV2Exchange {
    using LowGasSafeMath for uint256;

    uint256 public constant minimumAmount = 1000;

    IUniswapV2Router01 public router;
    IUniswapV2Pair public pair;
    IERC20 public mai;
    IERC20 public usdt;
    IERC20 public usdc;

    // --- events

    event ConnectorQuickswapUsdtMaiUpdated(address router, address pair, address mai, address usdt, address usdc);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();

    }

    // --- setters

    function setParameters(
        address _mai,
        address _usdt,
        address _usdc,
        address _router,
        address _pair
    ) external onlyAdmin {
        require(_mai != address(0), "Zero address not allowed");
        require(_usdt != address(0), "Zero address not allowed");
        require(_usdc != address(0), "Zero address not allowed");
        require(_router != address(0), "Zero address not allowed");
        require(_pair != address(0), "Zero address not allowed");

        router = IUniswapV2Router01(_router);
        pair = IUniswapV2Pair(_pair);
        mai = IERC20(_mai);
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
        emit ConnectorQuickswapUsdtMaiUpdated(_router, _pair, _mai, _usdt, _usdc);
    }



    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdc), "Some token not compatible");

        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
        require(reserveA > minimumAmount && reserveB > minimumAmount, 'ConnectorQuickswapUsdtMai: Liquidity pair reserves too low');

        uint256 swapAmountUSDT = _swapToUSDT(_amount);

        uint256 amountMAI = _getSwapAmount(swapAmountUSDT, reserveB, reserveA);
        uint256 swapAmountMAI = _swapToMAI(amountMAI);

        _addLiquidity();

    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdc), "Some token not compatible");

        pair.approve(address(router), _amount);

        (uint amountA, uint amountB) = router.removeLiquidity(pair.token0(), pair.token1(), _amount, 0, 0, address(this), block.timestamp + 600);


        _swapToUSDC();


        return _amount;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdc), "Some token not compatible");

        uint256 _amount = mai.balanceOf(address(this));

        //TODO
        return 0;
    }

    function _addLiquidity() private {

        address[] memory path = new address[](2);
        path[0] = address(mai);
        path[1] = address(usdt);

        uint256 amountUSDT = usdt.balanceOf(address(this));
        uint256 amountMAI = mai.balanceOf(address(this));
        usdt.approve(address(router), amountUSDT);
        mai.approve(address(router), amountMAI);

        (,, uint256 amountLiquidity) = router.addLiquidity(path[0], path[1], amountMAI, amountUSDT, 1, 1, address(this), block.timestamp + 600);

    }

    function _swapToMAI(uint256 amount) private returns (uint256 swapAmount) {

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(mai);

        uint[] memory amountsOut = router.getAmountsOut(amount, path);

        usdt.approve(address(router), amount);

        uint256[] memory swapedAmounts = router.swapExactTokensForTokens(
            amount, //    uint amountIn,
            0, //          uint amountOutMin,
            path,
            address(this),
            block.timestamp + 600 // 10 mins
        );

        return swapedAmounts[1];
    }


    function _swapToUSDC() private returns (uint256 swapAmount) {

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(usdc);

        uint256 amountUSDT = usdt.balanceOf(address(this));
        usdt.approve(address(router), amountUSDT);

        uint256[] memory swapedAmountsUSDT = router.swapExactTokensForTokens(
            amountUSDT, //    uint amountIn,
            0, //          uint amountOutMin,
            path,
            address(this),
            block.timestamp + 600 // 10 mins
        );

        path[0] = address(mai);
        path[1] = address(usdc);

        uint256 amountMAI = mai.balanceOf(address(this));
        mai.approve(address(router), amountMAI);

        uint256[] memory swapedAmountsMAI = router.swapExactTokensForTokens(
            amountMAI, //    uint amountIn,
            0, //          uint amountOutMin,
            path,
            address(this),
            block.timestamp + 600 // 10 mins
        );

        return swapedAmountsUSDT[1] + swapedAmountsMAI[1];
    }

    function _swapToUSDT(uint256 amount) private returns (uint256 swapAmount) {

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        uint[] memory amountsOut = router.getAmountsOut(amount, path);

        usdc.approve(address(router), amount);

        uint256[] memory swapedAmounts = router.swapExactTokensForTokens(
            amount, //    uint amountIn,
            0, //          uint amountOutMin,
            path,
            address(this),
            block.timestamp + 600 // 10 mins
        );

        return swapedAmounts[1];
    }

    function _getSwapAmount(uint256 investmentA, uint256 reserveA, uint256 reserveB) private view returns (uint256 swapAmount) {
        uint256 halfInvestment = investmentA / 2;
        uint256 nominator = router.getAmountOut(halfInvestment, reserveA, reserveB);
        uint256 denominator = router.quote(halfInvestment, reserveA.add(halfInvestment), reserveB.sub(nominator));
        //        swapAmount = investmentA.sub(Babylonian.sqrt(halfInvestment * halfInvestment * nominator / denominator));
        return swapAmount;
    }


    function netAssetValue() external view override returns (uint256){
        return 0;
    }

    function liquidationValue() external view override returns (uint256){
        return 0;
    }

    function _claimRewards(address _to) internal override returns (uint256){
        return 0;
    }


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../connectors/uniswap/v2/interfaces/IUniswapV2Router02.sol";

/**
 * @dev Contract to learn how to swap on Uniswap
 */
contract BuyonSwap {

    function buy(address _tokenAddress, address _router) public payable {
        IUniswapV2Router02 router = IUniswapV2Router02(_router);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = _tokenAddress;

        uint[] memory amountsOut = router.getAmountsOut(msg.value, path);

        amountsOut = router.swapExactETHForTokens{value: msg.value}(
            (amountsOut[1] * 9) / 10,
            path,
            msg.sender,
            block.timestamp + 600
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/tetu/interfaces/ISmartVault.sol";


contract StrategyTetuUsdc is Strategy, UniswapV2Exchange {

    IERC20 public usdcToken;
    IERC20 public tetuToken;

    ISmartVault public usdcSmartVault;
    ISmartVault public xTetuSmartVault;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address tetuToken);

    event StrategyUpdatedParams(address usdcSmartVault, address xTetuSmartVault, address tetuSwapRouter);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _tetuToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_tetuToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        tetuToken = IERC20(_tetuToken);

        emit StrategyUpdatedTokens(_usdcToken, _tetuToken);
    }

    function setParams(
        address _usdcSmartVault,
        address _xTetuSmartVault,
        address _tetuSwapRouter
    ) external onlyAdmin {

        require(_usdcSmartVault != address(0), "Zero address not allowed");
        require(_xTetuSmartVault != address(0), "Zero address not allowed");
        require(_tetuSwapRouter != address(0), "Zero address not allowed");

        usdcSmartVault = ISmartVault(_usdcSmartVault);
        xTetuSmartVault = ISmartVault(_xTetuSmartVault);
        _setUniswapRouter(_tetuSwapRouter);

        emit StrategyUpdatedParams(_usdcSmartVault, _xTetuSmartVault, _tetuSwapRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        usdcToken.approve(address(usdcSmartVault), _amount);
        usdcSmartVault.depositAndInvest(_amount);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 numberOfShares = OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE) * usdcSmartVault.totalSupply() / usdcSmartVault.underlyingBalanceWithInvestment();
        usdcSmartVault.withdraw(numberOfShares);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        usdcSmartVault.exit();

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return usdcSmartVault.underlyingBalanceWithInvestmentForHolder(address(this));
    }

    function liquidationValue() external view override returns (uint256) {
        return usdcSmartVault.underlyingBalanceWithInvestmentForHolder(address(this));
    }

    function _claimRewards(address _beneficiary) internal override returns (uint256) {

        // claim rewards
        if (IERC20(address(usdcSmartVault)).balanceOf(address(this)) <= 0) {
            return 0;
        }
        usdcSmartVault.getAllRewards();

        if (IERC20(address(xTetuSmartVault)).balanceOf(address(this)) <= 0) {
            return 0;
        }
        xTetuSmartVault.exit();

        // sell rewards
        uint256 totalUsdc;

        uint256 tetuBalance = tetuToken.balanceOf(address(this));
        if (tetuBalance > 0) {
            uint256 tetuUsdc = _swapExactTokensForTokens(
                address(tetuToken),
                address(usdcToken),
                tetuBalance,
                address(this)
            );
            totalUsdc += tetuUsdc;
        }

        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        if (usdcBalance > 0) {
            usdcToken.transfer(_beneficiary, usdcBalance);
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISmartVault is IERC20 {

    function setStrategy(address _strategy) external;

    function changeActivityStatus(bool _active) external;

    function changeProtectionMode(bool _active) external;

    function changePpfsDecreaseAllowed(bool _value) external;

    function setLockPeriod(uint256 _value) external;

    function setLockPenalty(uint256 _value) external;

    function setToInvest(uint256 _value) external;

    function doHardWork() external;

    function rebalance() external;

    function disableLock() external;

    function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

    function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

    function deposit(uint256 amount) external;

    function depositAndInvest(uint256 amount) external;

    function depositFor(uint256 amount, address holder) external;

    function withdraw(uint256 numberOfShares) external;

    function exit() external;

    function getAllRewards() external;

    function getReward(address rt) external;

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function getRewardTokenIndex(address rt) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function underlyingUnit() external view returns (uint256);

    function duration() external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

    function availableToInvestOut() external view returns (uint256);

    function earned(address rt, address account) external view returns (uint256);

    function earnedWithBoost(address rt, address account) external view returns (uint256);

    function rewardPerToken(address rt) external view returns (uint256);

    function lastTimeRewardApplicable(address rt) external view returns (uint256);

    function rewardTokensLength() external view returns (uint256);

    function active() external view returns (bool);

    function rewardTokens() external view returns (address[] memory);

    function periodFinishForToken(address _rt) external view returns (uint256);

    function rewardRateForToken(address _rt) external view returns (uint256);

    function lastUpdateTimeForToken(address _rt) external view returns (uint256);

    function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

    function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

    function rewardsForToken(address _rt, address account) external view returns (uint256);

    function userLastWithdrawTs(address _user) external view returns (uint256);

    function userLastDepositTs(address _user) external view returns (uint256);

    function userBoostTs(address _user) external view returns (uint256);

    function userLockTs(address _user) external view returns (uint256);

    function addRewardToken(address rt) external;

    function removeRewardToken(address rt) external;

    function stop() external;

    function ppfsDecreaseAllowed() external view returns (bool);

    function lockPeriod() external view returns (uint256);

    function lockPenalty() external view returns (uint256);

    function toInvest() external view returns (uint256);

    function depositFeeNumerator() external view returns (uint256);

    function lockAllowed() external view returns (bool);

    function protectionMode() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/balancer/interfaces/IVault.sol";
import "../connectors/balancer/interfaces/IGeneralPool.sol";
import "../connectors/balancer/interfaces/IMinimalSwapInfoPool.sol";
import "../connectors/balancer/interfaces/IPoolSwapStructs.sol";


library BalancerLibrary {

    int256 public constant MAX_VALUE = 10 ** 27;

    function swap(
        IVault vault,
        bytes32 poolId,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenOut,
        address sender,
        address recipient,
        uint256 amount,
        uint256 limit
    ) public returns (uint256) {

        IERC20(address(tokenIn)).approve(address(vault), IERC20(address(tokenIn)).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = kind;
        singleSwap.assetIn = tokenIn;
        singleSwap.assetOut = tokenOut;
        singleSwap.amount = amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = payable(recipient);
        fundManagement.toInternalBalance = false;

        return vault.swap(singleSwap, fundManagement, limit, block.timestamp + 600);
    }

    function swap(
        IVault vault,
        bytes32 poolId,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenOut,
        address sender,
        address recipient,
        uint256 amount
    ) public returns (uint256) {

        IERC20(address(tokenIn)).approve(address(vault), IERC20(address(tokenIn)).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = kind;
        singleSwap.assetIn = tokenIn;
        singleSwap.assetOut = tokenOut;
        singleSwap.amount = amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = payable(recipient);
        fundManagement.toInternalBalance = false;

        return vault.swap(singleSwap, fundManagement, uint256(MAX_VALUE), block.timestamp + 600);
    }


    function onSwap(
        IVault vault,
        bytes32 poolId,
        IVault.SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 balance
    ) public view returns (uint256) {

        IPoolSwapStructs.SwapRequest memory swapRequest;
        swapRequest.kind = kind;
        swapRequest.tokenIn = tokenIn;
        swapRequest.tokenOut = tokenOut;
        swapRequest.amount = balance;

        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = vault.getPoolTokens(poolId);

        (address pool, IVault.PoolSpecialization poolSpecialization) = vault.getPool(poolId);

        if (poolSpecialization == IVault.PoolSpecialization.GENERAL) {

            uint256 indexIn;
            uint256 indexOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    indexIn = i;
                } else if (tokens[i] == tokenOut) {
                    indexOut = i;
                }
            }

            return IGeneralPool(pool).onSwap(swapRequest, balances, indexIn, indexOut);

        } else if (poolSpecialization == IVault.PoolSpecialization.MINIMAL_SWAP_INFO) {

            uint256 balanceIn;
            uint256 balanceOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    balanceIn = balances[i];
                } else if (tokens[i] == tokenOut) {
                    balanceOut = balances[i];
                }
            }

            return IMinimalSwapInfoPool(pool).onSwap(swapRequest, balanceIn, balanceOut);

        } else {

            uint256 balanceIn;
            uint256 balanceOut;
            for (uint8 i = 0; i < tokens.length; i++) {
                if (tokens[i] == tokenIn) {
                    balanceIn = balances[i];
                } else if (tokens[i] == tokenOut) {
                    balanceOut = balances[i];
                }
            }

            return IMinimalSwapInfoPool(pool).onSwap(swapRequest, balanceIn, balanceOut);
        }
    }

    /**
     * Get amount of token1 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountToSwap(
        IVault vault,
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1,
        uint256 precision,
        bytes32 poolId,
        IERC20 token0,
        IERC20 token1
    ) public view returns (uint256) {
        uint256 amount0ToSwap = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        for (uint i = 0; i < precision; i++) {
            uint256 amount1 = onSwap(vault, poolId, IVault.SwapKind.GIVEN_IN, token0, token1, amount0ToSwap);
            amount0ToSwap = (amount0Total * reserve1) / (reserve0 * amount1 / amount0ToSwap + reserve1);
        }

        return amount0ToSwap;
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     * precision: 0 - no correction, 1 - one correction (recommended value), 2 or more - several corrections
     */
    function _getAmountLpTokensToWithdraw(
        IVault vault,
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLpBalance,
        uint256 denominator0,
        uint256 denominator1,
        bytes32 poolId,
        IERC20 token0,
        IERC20 token1
    ) public view returns (uint256) {
        uint256 lpBalance = (totalLpBalance * amount0Total * denominator1) / (reserve0 * denominator1 + reserve1 * denominator0);
        for (uint i = 0; i < 1; i++) {
            uint256 amount1 = reserve1 * lpBalance / totalLpBalance;
            uint256 amount0 = onSwap(vault, poolId, IVault.SwapKind.GIVEN_IN, token1, token0, amount1);
            lpBalance = (totalLpBalance * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);
        }
        return lpBalance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./connectors/uniswap/v3/libraries/TickMath.sol";
import "./connectors/arrakis/IArrakisV1RouterStaking.sol";
import "./connectors/arrakis/IArrakisRewards.sol";
import "./connectors/arrakis/IArrakisVault.sol";
import "./connectors/aave/interfaces/IPriceFeed.sol";
import "./exchanges/BalancerExchange.sol";
import "./libraries/OvnMath.sol";
import "./libraries/BalancerLibrary.sol";
import "./connectors/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import "./connectors/uniswap/v3/interfaces/INonfungiblePositionManager.sol";


contract StrategyArrakis is Strategy, BalancerExchange {
    using OvnMath for uint256;

    uint256 constant BASIS_POINTS_FOR_SLIPPAGE = 4; // 0.04%

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public wmaticToken;

    IArrakisV1RouterStaking arrakisRouter;
    IArrakisRewards arrakisRewards;
    IArrakisVault arrakisVault;

    IUniswapV3Pool uniswapV3Pool;
    INonfungiblePositionManager uniswapPositionManager;

    bytes32 public balancerPoolIdStable; // Stable Pool
    bytes32 public balancerPoolIdWmatic; // Wmatic/USDC Pool

    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleUsdt;

    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address wmaticToken);

    event StrategyUpdatedParams(address arrakisRouter, address arrakisRewards, address arrakisVault, address balancerVault, address uniswapPositionManager,
        bytes32 balancerPoolIdStable, bytes32 balancerPoolIdWmatic, address oracleUsdc, address oracleUsdt);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _wmaticToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        wmaticToken = IERC20(_wmaticToken);

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _wmaticToken);
    }

    function setParams(
        address _arrakisRouter,
        address _arrakisRewards,
        address _arrakisVault,
        address _balancerVault,
        bytes32 _balancerPoolIdStable,
        bytes32 _balancerPoolIdWmatic,
        address _uniswapPositionManager,
        address _oracleUsdc,
        address _oracleUsdt
    ) external onlyAdmin {

        require(_arrakisRouter != address(0), "Zero address not allowed");
        require(_arrakisRewards != address(0), "Zero address not allowed");
        require(_arrakisVault != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_uniswapPositionManager != address(0), "Zero address not allowed");
        require(_balancerPoolIdStable != "", "Empty pool id not allowed");
        require(_balancerPoolIdWmatic != "", "Empty pool id not allowed");
        require(_oracleUsdc != address(0), "Zero address not allowed");
        require(_oracleUsdt != address(0), "Zero address not allowed");

        arrakisRouter = IArrakisV1RouterStaking(_arrakisRouter);
        arrakisRewards = IArrakisRewards(_arrakisRewards);
        arrakisVault = IArrakisVault(_arrakisVault);

        balancerPoolIdStable = _balancerPoolIdStable;
        balancerPoolIdWmatic = _balancerPoolIdWmatic;
        setBalancerVault(_balancerVault);

        oracleUsdc = IPriceFeed(_oracleUsdc);
        oracleUsdt = IPriceFeed(_oracleUsdt);

        emit StrategyUpdatedParams(_arrakisRouter, _arrakisRewards, _arrakisVault, _balancerVault, _uniswapPositionManager,
            _balancerPoolIdStable, _balancerPoolIdWmatic, _oracleUsdc, _oracleUsdt);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");

        // 1. Calculate needed USDC to swap to USDT
        (uint256 amountLiq0, uint256 amountLiq1) = arrakisVault.getUnderlyingBalances();
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 amountUsdcToSwap = _getAmountToSwap(
            usdcBalance,
            amountLiq0,
            amountLiq1,
            1,
            1,
            1,
            balancerPoolIdStable,
            usdcToken,
            usdtToken
        );


        // 2. Swap USDC to needed USDT amount
        swap(
            balancerPoolIdStable,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdcToken)),
            IAsset(address(usdtToken)),
            address(this),
            address(this),
            amountUsdcToSwap,
            0
        );


        // 3. Stake USDC/USDT to Arrakis
        uint256 usdcAmount = usdcToken.balanceOf(address(this));
        uint256 usdtAmount = usdtToken.balanceOf(address(this));
        usdcToken.approve(address(arrakisRouter), usdcAmount);
        usdtToken.approve(address(arrakisRouter), usdtAmount);

        arrakisRouter.addLiquidityAndStake(
            address(arrakisRewards),
            usdcAmount,
            usdtAmount,
            OvnMath.subBasisPoints(usdcAmount, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(usdtAmount, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 amount = OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE);
        amount += 10;

        // 1. Calculating need amount lp tokens - depends on amount USDC/USDT
        (uint256 amount0Current, uint256 amount1Current) = arrakisVault.getUnderlyingBalances();
        uint256 totalLpBalance = arrakisVault.totalSupply();
        uint256 amountLp = _getAmountLpTokensToWithdraw(
                amount,
                amount0Current,
                amount1Current,
                arrakisVault.totalSupply(),
                1,
                1,
                balancerPoolIdStable,
                usdcToken,
                usdtToken
            );

        if (amountLp > totalLpBalance) {
            amountLp = totalLpBalance;
        }

        uint256 amountOut0Min = amount0Current * amountLp / totalLpBalance;
        uint256 amountOut1Min = amount1Current * amountLp / totalLpBalance;

        // 2. Get tokens USDC/USDT from Arrakis
        arrakisRewards.approve(address(arrakisRouter), amountLp);
        arrakisRouter.removeLiquidityAndUnstake(
            address(arrakisRewards),
            amountLp,
            OvnMath.subBasisPoints(amountOut0Min, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(amountOut1Min, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );

        // 3. Swap USDT to USDC
        swap(balancerPoolIdStable, IVault.SwapKind.GIVEN_IN, IAsset(address(usdtToken)), IAsset(address(usdcToken)), address(this), address(this), usdtToken.balanceOf(address(this)), 0);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");


        // 1. Get balance LP tokens
        uint256 amountLp = arrakisRewards.balanceOf(address(this));

        if (amountLp == 0)
            return 0;


        // 2. Calculating amount usdc/usdt under lp tokens
        (uint256 amount0Current, uint256 amount1Current) = arrakisVault.getUnderlyingBalances();
        uint256 amountLiq0 = amount0Current * amountLp / arrakisVault.totalSupply();
        uint256 amountLiq1 = amount1Current * amountLp / arrakisVault.totalSupply();


        // 3. Get usdc/usdt tokens from Arrakis
        arrakisRewards.approve(address(arrakisRouter), amountLp);
        arrakisRouter.removeLiquidityAndUnstake(
            address(arrakisRewards),
            amountLp,
            OvnMath.subBasisPoints(amountLiq0, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(amountLiq1, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );


        // 4. Swap USDT to USDC tokens on Balancer
        swap(balancerPoolIdStable, IVault.SwapKind.GIVEN_IN, IAsset(address(usdtToken)), IAsset(address(usdcToken)), address(this), address(this), usdtToken.balanceOf(address(this)), 0);

        return usdcToken.balanceOf(address(this));
    }


    function netAssetValue() external override view returns (uint256) {
        return _getTotal(true);
    }

    function liquidationValue() external override view returns (uint256) {
        return _getTotal(false);
    }

    function _getTotal(bool nav) internal view returns (uint256){

        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        uint256 balanceLp = arrakisRewards.balanceOf(address(this));

        if (balanceLp == 0)
            return 0;

        (uint256 amount0Current, uint256 amount1Current) = arrakisVault.getUnderlyingBalances();
        usdcBalance += amount0Current * balanceLp / arrakisVault.totalSupply();
        usdtBalance += amount1Current * balanceLp / arrakisVault.totalSupply();

        uint256 totalUsdtToUsdc;
        if(nav){
            uint256 priceUsdc = uint256(oracleUsdc.latestAnswer());
            uint256 priceUsdt = uint256(oracleUsdt.latestAnswer());
            totalUsdtToUsdc = ((usdtBalance * 1e6) * priceUsdt) / (1e6 * priceUsdc);
        }else {
            // check how many USDC tokens we will get if we sell USDT tokens now
            totalUsdtToUsdc = onSwap(balancerPoolIdStable, IVault.SwapKind.GIVEN_IN, usdtToken, usdcToken, usdtBalance);
        }
        return usdcBalance + totalUsdtToUsdc;

    }

    function _claimRewards(address _to) internal override returns (uint256) {

        if(arrakisRewards.balanceOf(address(this)) != 0){
            arrakisRewards.claim_rewards(address(this));
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));

        if (wmaticBalance > 0) {

            uint256 usdcAmount = swap(balancerPoolIdWmatic, IVault.SwapKind.GIVEN_IN, IAsset(address(wmaticToken)),
                IAsset(address(usdcToken)), address(this), address(this), wmaticBalance, 0);

            usdcToken.transfer(_to, usdcAmount);
            return usdcAmount;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
// TODO Updated -> see below TODO breakpoints
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
//        require(absTick <= uint256(MAX_TICK), 'T'); //TODO Need convert int24 to uint256

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

pragma solidity >=0.8.0 <0.9.0;

interface IArrakisV1RouterStaking {

    function addLiquidityAndStake(
        address gauge,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
    external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 mintAmount
    );


    function removeLiquidityAndUnstake(
        address gauge,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
    external
    returns (
        uint256 amount0,
        uint256 amount1,
        uint128 liquidityBurned
    );


}

pragma solidity >=0.8.0 <0.9.0;

interface IArrakisRewards {

    function claim_rewards(address to) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

pragma solidity >=0.8.0 <0.9.0;

interface IArrakisVault {

    /// @notice compute total underlying holdings of the G-UNI token supply
    /// includes current liquidity invested in uniswap position, current fees earned
    /// and any uninvested leftover (but does not include manager or gelato fees accrued)
    /// @return amount0Current current total underlying balance of token0
    /// @return amount1Current current total underlying balance of token1
    function getUnderlyingBalances() external view returns (uint256 amount0Current, uint256 amount1Current);

    function getUnderlyingBalancesAtPrice(uint160 sqrtRatioX96) external view returns (uint256 amount0Current, uint256 amount1Current);

    function getPositionID() external view returns (bytes32 positionID);

    function token0() external view returns (address token);

    function token1() external view returns (address token);

    function upperTick() external view returns (int24);

    function lowerTick() external view returns (int24);

    function pool() external view returns (address pool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
    external
    view
    returns (
        uint256 amount0,
        uint256 amount1,
        uint256 mintAmount
    );

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV3Pool {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
    external
    view
    returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
    external
    view
    returns (
        uint128 _liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
    external
    view
    returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface INonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/uniswap/v3/interfaces/INonfungiblePositionManager.sol";
import "./connectors/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import "./connectors/izumi/interfaces/IMiningFixRangeBoost.sol";
import "./connectors/uniswap/v3/interfaces/ISwapRouterV3.sol";
import "./connectors/uniswap/v3/libraries/LiquidityAmounts.sol";
import "./connectors/balancer/interfaces/IVault.sol";
import "./connectors/curve/interfaces/IStableSwapPool.sol";

contract StrategyIzumi is Strategy, UniswapV2Exchange, IERC721Receiver {

    uint160 internal constant MIN_SQRT_RATIO = 79188560314459151373725315960; // TickMath.getSqrtRatioAtTick(-10)
    uint160 internal constant MAX_SQRT_RATIO = 79267784519130042428790663799; // TickMath.getSqrtRatioAtTick(10)
    int256 public constant MAX_VALUE = 10 ** 27;

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public iziToken;
    IERC20 public yinToken;
    IERC20 public wethToken;

    IERC721 public uniswapToken;

    uint256 public usdcTokenDenominator;
    uint256 public usdtTokenDenominator;
    uint256 public iziTokenDenominator;
    uint256 public yinTokenDenominator;

    uint256 public tokenId;

    INonfungiblePositionManager public uniswapPositionManager;
    IUniswapV3Pool public uniswapV3Pool;
    IMiningFixRangeBoost public izumiBoost;
    ISwapRouter public uniswapV3Router;

    IVault public balancerVault;
    bytes32 public balancerPoolId;

    IStableSwapPool public aavePool;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address iziToken, address yinToken, address uniswapToken, address wethToken);
    event StrategyUpdatedParams(address uniswapPositionManager, address uniswapV3Pool, address izumiBoost, address uniswapV3Router, address balancerVault, bytes32 balancerPoolId, address aavePool);

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _iziToken,
        address _yinToken,
        address _uniswapToken,
        address _wethToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_iziToken != address(0), "Zero address not allowed");
        require(_yinToken != address(0), "Zero address not allowed");
        require(_uniswapToken != address(0), "Zero address not allowed");
        require(_wethToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        iziToken = IERC20(_iziToken);
        yinToken = IERC20(_yinToken);
        wethToken = IERC20(_wethToken);
        uniswapToken = IERC721(_uniswapToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        usdtTokenDenominator = 10 ** IERC20Metadata(_usdtToken).decimals();
        iziTokenDenominator = 10 ** IERC20Metadata(_iziToken).decimals();
        yinTokenDenominator = 10 ** IERC20Metadata(_yinToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _iziToken, _yinToken, _uniswapToken, _wethToken);

    }

    function setParams(
        address _uniswapPositionManager,
        address _uniswapV3Pool,
        address _izumiBoost,
        address _uniswapV3Router,
        bytes32 _balancerPoolId,
        address _balancerVault,
        address _aavePool,
        address _uniswapV2Router
    ) external onlyAdmin {

        require(_uniswapPositionManager != address(0), "Zero address not allowed");
        require(_uniswapV3Pool != address(0), "Zero address not allowed");
        require(_uniswapV3Router != address(0), "Zero address not allowed");
        require(_izumiBoost != address(0), "Zero address not allowed");
        require(_balancerPoolId != 0, "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_aavePool != address(0), "Zero address not allowed");

        uniswapPositionManager = INonfungiblePositionManager(_uniswapPositionManager);
        uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
        izumiBoost = IMiningFixRangeBoost(_izumiBoost);
        uniswapV3Router = ISwapRouter(_uniswapV3Router);

        _setUniswapRouter(_uniswapV2Router);

        balancerPoolId = _balancerPoolId;
        balancerVault = IVault(_balancerVault);

        aavePool = IStableSwapPool(_aavePool);

        emit StrategyUpdatedParams(_uniswapPositionManager, _uniswapV3Pool,  _izumiBoost, _uniswapV3Router, _balancerVault, _balancerPoolId, _aavePool);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");
        if (tokenId == 0) {
            // create NFT in UniswapV3
            _mint();
        } else {
            _addLiquidity();
        }
    }


    function _removeLiquidity(uint256 _amount) internal {

        izumiBoost.withdraw(tokenId, false);

        uint256 usdtAmount = _getNeedToByUsdt(_amount);
        uint256 usdcAmount = _amount - usdtAmount;

        (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, MIN_SQRT_RATIO, MAX_SQRT_RATIO, usdcAmount, usdtAmount);
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
            tokenId,
            liquidity,
            0,
            0,
            block.timestamp + 600
        );

        uniswapPositionManager.decreaseLiquidity(params);

        _collectLiquidityAndSwap();

        uniswapToken.approve(address(izumiBoost), tokenId);

        izumiBoost.deposit(tokenId, 0);
    }

    function _addLiquidity() internal {

        _buyNeedAmountUsdt();

        uint256 amount0Desired = usdcToken.balanceOf(address(this));
        uint256 amount1Desired = usdtToken.balanceOf(address(this));

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams(
            tokenId,
            amount0Desired,
            amount1Desired,
            0, // TODO UPDATE slippage
            0, // TODO UPDATE slippage
            block.timestamp + 600
        );

        usdcToken.approve(address(uniswapPositionManager), amount0Desired);
        usdtToken.approve(address(uniswapPositionManager), amount1Desired);

        (uint128 liquidity, uint256 amount0, uint256 amount1) = uniswapPositionManager.increaseLiquidity(params);
    }


    function _getNeedToByUsdt(uint256 _amount) internal returns (uint256){

        (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();

        (uint256 amountLiq0, uint256 amountLiq1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            MIN_SQRT_RATIO,
            MAX_SQRT_RATIO,
            uniswapV3Pool.liquidity());

        uint256 needUsdtValue = (_amount * amountLiq1) / (amountLiq0 + amountLiq1);
        return needUsdtValue;
    }


    function _buyNeedAmountUsdt() internal {

        uint256 neededUsdtBalance = _getNeedToByUsdt(usdcToken.balanceOf(address(this)));
        uint256 currentUsdtBalance = usdtToken.balanceOf(address(this));

        if (currentUsdtBalance <= neededUsdtBalance) {
            neededUsdtBalance = neededUsdtBalance - currentUsdtBalance;
            swap(balancerPoolId, IVault.SwapKind.GIVEN_OUT, IAsset(address(usdcToken)), IAsset(address(usdtToken)), address(this), address(this), neededUsdtBalance);
        }

    }

    function _mint() internal {

        _buyNeedAmountUsdt();

        uint256 amount0Desired = usdcToken.balanceOf(address(this));
        uint256 amount1Desired = usdtToken.balanceOf(address(this));

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams(
            address(usdcToken),
            address(usdtToken),
            uniswapV3Pool.fee(),
            - 10, // price 0.999
            10, // price 1.001
            amount0Desired,
            amount1Desired,
            (amount0Desired * 95 / 100), // slippage 1%
            (amount1Desired * 95 / 100), // slippage 1%
            address(this),
            block.timestamp + 600
        );

        usdcToken.approve(address(uniswapPositionManager), amount0Desired);
        usdtToken.approve(address(uniswapPositionManager), amount1Desired);

        (uint256 _tokenId, ,uint256 amount0, uint256 amount1) = uniswapPositionManager.mint(params);

        tokenId = _tokenId;

        uniswapToken.approve(address(izumiBoost), _tokenId);
        izumiBoost.deposit(_tokenId, 0);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");

        if (usdcToken.balanceOf(address(this)) <= _amount) {
            _removeLiquidity(_amount);
        }

        return _amount;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");

        _claimRewards(address(this));

        if (tokenId == 0) {
            return usdcToken.balanceOf(address(this));
        } else {
            izumiBoost.withdraw(tokenId, false);

            (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();
            (,,,,,,,uint128 liquidity,,,,) = uniswapPositionManager.positions(tokenId);


            (uint256 amountLiq0, uint256 amountLiq1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                MIN_SQRT_RATIO,
                MAX_SQRT_RATIO,
                liquidity);

            INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
                tokenId,
                liquidity,
                (amountLiq0 * 99 / 100),
                (amountLiq1 * 99 / 100),
                block.timestamp + 600
            );

            uniswapPositionManager.decreaseLiquidity(params);

            _collectLiquidityAndSwap();
            uniswapPositionManager.burn(tokenId);

            tokenId = 0;

            return usdcToken.balanceOf(address(this));
        }
    }


    function _collectLiquidityAndSwap() internal {
        INonfungiblePositionManager.CollectParams memory collectParam = INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max);

        uniswapPositionManager.collect(collectParam);


        uint256 balanceUSDT = usdtToken.balanceOf(address(this));
        usdtToken.approve(address(aavePool), balanceUSDT);

        // index 2 - USDT send coin
        // index 1 - USDC received coin
        uint256 minAmount = (aavePool.get_dy_underlying(2, 1, balanceUSDT) * 99 / 100); // slippage 1%;


        aavePool.exchange_underlying(2, 1, balanceUSDT, minAmount);

    }

    function netAssetValue() external override view returns (uint256) {
        return _getTotal();
    }

    function liquidationValue() external override view returns (uint256) {
        return _getTotal();
    }

    function _getTotal() internal view returns (uint256){

        if (tokenId == 0)
            return 0;

        (,,,,,,,uint128 liquidity,,,,) = uniswapPositionManager.positions(tokenId);
        (uint160 sqrtPriceX96,,,,,,) = uniswapV3Pool.slot0();


        (uint256 amountLiq0, uint256 amountLiq1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            MIN_SQRT_RATIO,
            MAX_SQRT_RATIO,
            liquidity);


        uint256 totalUsdc = usdcToken.balanceOf(address(this)) + amountLiq0;
        uint256 totalUsdt = usdtToken.balanceOf(address(this)) + amountLiq1;

        // index 2 - USDT
        // index 1 - USDC
        return totalUsdc + aavePool.get_dy_underlying(2, 1, totalUsdt);
    }



    function _swapIziWeth() internal  {

        uint256 balanceIzi = iziToken.balanceOf(address(this));

        if (balanceIzi == 0){
            return;
        }

        _swapExactTokensForTokens(
            address(iziToken), 
            address(wethToken), 
            balanceIzi, 
            address(this)
        );        
    }

    function _swapYinWeth() internal {

        uint256 balanceYin = yinToken.balanceOf(address(this));

        if (balanceYin == 0){
            return;
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(yinToken),
            address(wethToken),
            3000, // pool fee 0.3%
            address(this),
            block.timestamp + 600,
            balanceYin,
            0,
            0
        );

        yinToken.approve(address(uniswapV3Router), balanceYin);
        uint256 amountOut = uniswapV3Router.exactInputSingle(params);
    }


    function _swapWethUsdc() internal {

        uint256 balanceWeth = wethToken.balanceOf(address(this));
        if(balanceWeth == 0){
            return;
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(wethToken),
            address(usdcToken),
            500, // pool fee 0.05%
            address(this),
            block.timestamp + 600,
            balanceWeth,
            0,
            0
        );

        wethToken.approve(address(uniswapV3Router), balanceWeth);
        uint256 amountOut = uniswapV3Router.exactInputSingle(params);
    }

    function _claimRewards(address _to) internal override returns (uint256) {
        izumiBoost.collectReward(tokenId);

        _swapIziWeth();
        _swapYinWeth();
        _swapWethUsdc();

        uint256 balanceUSDC = usdcToken.balanceOf(address(this));
        usdcToken.transfer(_to, balanceUSDC);
        return balanceUSDC;
    }

    /// @notice Used for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes memory)
    public
    virtual
    override
    returns (bytes4)
    {
        return this.onERC721Received.selector;
    }


    function swap(
        bytes32 poolId,
        IVault.SwapKind kind,
        IAsset tokenIn,
        IAsset tokenOut,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {

        IERC20(address(tokenIn)).approve(address(balancerVault), IERC20(address(tokenIn)).balanceOf(address(this)));

        IVault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = kind;
        singleSwap.assetIn = tokenIn;
        singleSwap.assetOut = tokenOut;
        singleSwap.amount = amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = sender;
        fundManagement.fromInternalBalance = false;
        fundManagement.recipient = payable(recipient);
        fundManagement.toInternalBalance = false;

        uint256 amountReceived = balancerVault.swap(singleSwap, fundManagement, uint256(MAX_VALUE), block.timestamp + 600);
        return amountReceived;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5 <0.9.0;

interface IMiningFixRangeBoost {

    function deposit(uint256 tokenId, uint256 nIZI) external returns (uint256 vLiquidity);

    function withdraw(uint256 tokenId, bool noReward) external;

    function collectReward(uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import './FullMath.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) internal pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStableSwapPool {

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts, bool _use_underlying) external returns (uint256[3] memory);

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);

    function underlying_coins(uint256 i) external view returns (address);

    function lp_token() external view returns (address);

    function calc_token_amount(uint256[3] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    // Get the amount of coin j(received) one would receive for swapping _dx of coin i(send).
    function get_dy(int128 sendToken, int128 receivedToken, uint256 _dx) external view returns (uint256);

    function get_dy_underlying(int128 sendToken, int128 receivedToken, uint256 _dx) external view returns (uint256);

    //Perform an exchange between two coins.
    // i: Index value for the coin to send
    // j: Index value of the coin to receive
    // _dx: Amount of i being exchanged
    // _min_dy: Minimum amount of j to receive
    // Returns the actual amount of coin j received. Index values can be found via the coins public getter method.
    function exchange(int128 sendToken, int128 receivedToken, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function exchange_underlying(int128 sendToken, int128 receivedToken, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying) external returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./core/Strategy.sol";
import "./connectors/curve/interfaces/IStableSwapPool.sol";
import "./connectors/curve/interfaces/IRewardsOnlyGauge.sol";


contract StrategyCurve is Strategy, UniswapV2Exchange {

    IERC20 public usdcToken;
    IERC20 public a3CrvToken;
    IERC20 public a3CrvGaugeToken;
    IERC20 public crvToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public a3CrvTokenDenominator;
    uint256 public crvTokenDenominator;
    uint256 public wmaticTokenDenominator;

    IStableSwapPool public crvPool;
    IRewardsOnlyGauge public rewardGauge;


    // --- events

    event StrategyCurveUpdatedTokens(
        address usdcToken,
        address a3CrvToken,
        address a3CrvGaugeToken,
        address crvToken,
        address wmaticToken,
        uint256 usdcTokenDenominator,
        uint256 a3CrvTokenDenominator,
        uint256 crvTokenDenominator,
        uint256 wmaticTokenDenominator
    );

    event StrategyCurveUpdatedParams(address crvPool, address rewardGauge, address uniswapRouter);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }



    // --- Setters

    function setTokens(
        address _usdcToken,
        address _a3CrvToken,
        address _a3CrvGaugeToken,
        address _crvToken,
        address _wmaticToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_a3CrvToken != address(0), "Zero address not allowed");
        require(_a3CrvGaugeToken != address(0), "Zero address not allowed");
        require(_crvToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        a3CrvToken = IERC20(_a3CrvToken);
        a3CrvGaugeToken = IERC20(_a3CrvGaugeToken);
        crvToken = IERC20(_crvToken);
        wmaticToken = IERC20(_wmaticToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        a3CrvTokenDenominator = 10 ** IERC20Metadata(_a3CrvToken).decimals();
        crvTokenDenominator = 10 ** IERC20Metadata(_crvToken).decimals();
        wmaticTokenDenominator = 10 ** IERC20Metadata(_wmaticToken).decimals();

        emit StrategyCurveUpdatedTokens(
            _usdcToken,
            _a3CrvToken,
            _a3CrvGaugeToken,
            _crvToken,
            _wmaticToken,
            usdcTokenDenominator,
            a3CrvTokenDenominator,
            crvTokenDenominator,
            wmaticTokenDenominator
        );
    }

    function setParams(
        address _crvPool,
        address _rewardGauge,
        address _uniswapRouter
    ) external onlyAdmin {

        require(_crvPool != address(0), "Zero address not allowed");
        require(_rewardGauge != address(0), "Zero address not allowed");
        require(_uniswapRouter != address(0), "Zero address not allowed");

        crvPool = IStableSwapPool(_crvPool);
        rewardGauge = IRewardsOnlyGauge(_rewardGauge);
        _setUniswapRouter(_uniswapRouter);

        emit StrategyCurveUpdatedParams(_crvPool, _rewardGauge, _uniswapRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");

        address current = address(this);

        _stakeCurve(address(usdcToken), _amount, current);

        uint256 a3CrvBalance = a3CrvToken.balanceOf(current);
        a3CrvToken.approve(address(rewardGauge), a3CrvBalance);
        rewardGauge.deposit(a3CrvBalance, current, false);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        address current = address(this);
        // gauge doesn't need approve on withdraw, but we should have amount token
        // on Strategy

        // 6 = 18 + 6 - 18
        uint256 price = crvPool.get_virtual_price() * usdcTokenDenominator / a3CrvTokenDenominator;

        // Add +1% - slippage curve
        uint256 amount = _amount + (_amount * 1 / 100);

        // 18 = 18 + 6 - 6
        uint256 tokenAmountToWithdrawFromGauge = a3CrvTokenDenominator * amount / price;

        rewardGauge.withdraw(tokenAmountToWithdrawFromGauge, false);

        uint256 withdrewAmount = _unstakeCurve();

        return withdrewAmount;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 _amount = a3CrvGaugeToken.balanceOf(address(this));

        address current = address(this);
        // gauge doesn't need approve on withdraw, but we should have amount token
        // on Strategy

        rewardGauge.withdraw(_amount, false);

        uint256 withdrewAmount = _unstakeCurve();

        return withdrewAmount;
    }

    function netAssetValue() external view override returns (uint256){
        uint256 balance = a3CrvGaugeToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        // 6 = 18 + 6 - 18
        uint256 price = crvPool.get_virtual_price() * usdcTokenDenominator / a3CrvTokenDenominator;
        // 18 + 6 - 18 = 6
        return balance * price / a3CrvTokenDenominator;
    }

    function liquidationValue() external view override returns (uint256){
        uint256 balance = a3CrvGaugeToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }

        // get amount usdc that will be unstaked, gauge is 1:1 to am3Crv
        int128 usdcIndex = 1;
        // position of usdc token
        uint256 withdrawUsdcAmount = crvPool.calc_withdraw_one_coin(balance, usdcIndex);

        return withdrawUsdcAmount;
    }


    function _stakeCurve(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal {
        uint256[3] memory amounts;
        for (uint256 i = 0; i < 3; i++) {
            address coin = crvPool.underlying_coins(i);
            if (coin == _asset) {
                IERC20(_asset).approve(address(crvPool), _amount);
                // номер позиции в массиве (amounts) определяет какой актив (_asset) и в каком количестве (_amount)
                // на стороне керва будет застейкано
                amounts[i] = _amount;
                uint256 lpTokAmount = crvPool.calc_token_amount(amounts, true);
                //TODO: процентажи кудато вынести, slippage
                uint256 retAmount = crvPool.add_liquidity(amounts, (lpTokAmount * 99) / 100, true);
                if (_beneficiary != address(this)) {
                    IERC20(crvPool.lp_token()).transfer(_beneficiary, retAmount);
                }

                return;
            }
        }
        revert("can't find active for staking in curve");
    }


    function _unstakeCurve() internal returns (uint256) {

        // index got from curve.coins(i) for USDC
        uint256 index = 1;
        require(crvPool.underlying_coins(index) == address(usdcToken), "Invalid index for unstaking curve");

        uint256 lpTokenAmount = a3CrvToken.balanceOf(address(this));

        a3CrvToken.approve(address(crvPool), lpTokenAmount);

        //TODO: use withdrawAmount?
        uint256 retAmount = crvPool.remove_liquidity_one_coin(lpTokenAmount, int128(uint128(index)), 0, true);
        return retAmount;
    }

    function _claimRewards(address _to) internal override returns (uint256){
        rewardGauge.claim_rewards(address(this));

        uint256 totalUsdc;

        uint256 crvBalance = crvToken.balanceOf(address(this));
        if (crvBalance != 0) {
            uint256 crvUsdc = _swapExactTokensForTokens(
                address(crvToken),
                address(usdcToken),
                crvBalance,
                address(this)
            );
            totalUsdc += crvUsdc;
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance != 0) {
            uint256 wmaticUsdc = _swapExactTokensForTokens(
                address(wmaticToken),
                address(usdcToken),
                wmaticBalance,
                address(this)
            );
            totalUsdc += wmaticUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));
        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsOnlyGauge is IERC20 {

    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function deposit(uint256 _value, address _addr) external;

    function deposit(uint256 _value, bool _claim_rewards) external;

    function deposit(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function withdraw(uint256 _value) external;

    function lp_token() external returns (address);

    function claim_rewards(address _addr, address _receiver) external;

    function claim_rewards(address _addr) external;

    function claim_rewards() external;

    function claimed_reward(address _addr, address _token) external returns (uint256);

    function claimable_reward(address _addr, address _token) external returns (uint256);

    function claimable_reward_write(address _addr, address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./libraries/OvnMath.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/stargate/interfaces/IStargateRouter.sol";
import "./connectors/stargate/interfaces/IStargatePool.sol";
import "./connectors/stargate/interfaces/ILPStaking.sol";


contract StrategyStargateUsdc is Strategy, UniswapV2Exchange {
    using OvnMath for uint256;

    IERC20 public usdcToken;
    IERC20 public stgToken;

    IStargateRouter public stargateRouter;
    IStargatePool public pool;
    ILPStaking public lpStaking;
    uint256 public pid;

    uint256 public usdcTokenDenominator;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address stgToken, uint256 usdcTokenDenominator);

    event StrategyUpdatedParams(address stargateRouter, address pool, address lpStaking, uint256 pid, address sushiSwapRouter);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _stgToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_stgToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        stgToken = IERC20(_stgToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _stgToken, usdcTokenDenominator);
    }

    function setParams(
        address _stargateRouter,
        address _pool,
        address _lpStaking,
        uint256 _pid,
        address _sushiSwapRouter
    ) external onlyAdmin {

        require(_stargateRouter != address(0), "Zero address not allowed");
        require(_pool != address(0), "Zero address not allowed");
        require(_lpStaking != address(0), "Zero address not allowed");
        require(_sushiSwapRouter != address(0), "Zero address not allowed");

        stargateRouter = IStargateRouter(_stargateRouter);
        pool = IStargatePool(_pool);
        lpStaking = ILPStaking(_lpStaking);
        pid = _pid;
        _setUniswapRouter(_sushiSwapRouter);

        emit StrategyUpdatedParams(_stargateRouter, _pool, _lpStaking, _pid, _sushiSwapRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // add liquidity
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        usdcToken.approve(address(stargateRouter), usdcBalance);
        stargateRouter.addLiquidity(uint16(pool.poolId()), usdcBalance, address(this));

        // stake
        uint256 lpBalance = pool.balanceOf(address(this));
        pool.approve(address(lpStaking), lpBalance);
        lpStaking.deposit(pid, lpBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        uint256 usdcAmount = _amount + 10;
        uint256 lpBalance = usdcAmount * usdcTokenDenominator / pool.amountLPtoLD(usdcTokenDenominator);
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (lpBalance > amount) {
            lpBalance = amount;
        }
        lpStaking.withdraw(pid, lpBalance);

        // remove liquidity
        pool.approve(address(stargateRouter), lpBalance);
        stargateRouter.instantRedeemLocal(uint16(pool.poolId()), lpBalance, address(this));

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // unstake
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount == 0) {
            return usdcToken.balanceOf(address(this));
        }
        lpStaking.withdraw(pid, amount);

        // remove liquidity
        pool.approve(address(stargateRouter), amount);
        stargateRouter.instantRedeemLocal(uint16(pool.poolId()), amount, address(this));

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount > 0) {
            usdcBalance += pool.amountLPtoLD(amount);
        }

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        (uint256 amount,) = lpStaking.userInfo(pid, address(this));
        if (amount == 0) {
            return 0;
        }
        lpStaking.withdraw(pid, 0);

        // sell rewards
        uint256 totalUsdc;

        uint256 stgBalance = stgToken.balanceOf(address(this));
        if (stgBalance > 0) {
            uint256 stgUsdc = _swapExactTokensForTokens(
                address(stgToken),
                address(usdcToken),
                stgBalance,
                address(this)
            );
            totalUsdc += stgUsdc;
        }

        if (totalUsdc > 0) {
            usdcToken.transfer(_to, totalUsdc);
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/BalancerExchange.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/mstable/interfaces/IMasset.sol";
import "./connectors/mstable/interfaces/ISavingsContract.sol";
import "./connectors/mstable/interfaces/IBoostedVaultWithLockup.sol";

contract StrategyMStable is Strategy, BalancerExchange, UniswapV2Exchange {

    IERC20 public usdcToken;
    IMasset public mUsdToken;
    ISavingsContractV2 public imUsdToken;
    IBoostedVaultWithLockup public vimUsdToken;
    IERC20 public mtaToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public vimUsdTokenDenominator;
    uint256 public wmaticTokenDenominator;

    bytes32 public balancerPoolId1;
    bytes32 public balancerPoolId2;


    // --- events

    event StrategyMStableUpdatedTokens(address usdcToken, address mUsdToken, address imUsdToken, address vimUsdToken, address mtaToken, address wmaticToken,
        uint256 usdcTokenDenominator, uint256 vimUsdTokenDenominator, uint256 wmaticTokenDenominator);

    event StrategyMStableUpdatedParams(address balancerVault, address uniswapRouter, bytes32 balancerPoolId1, bytes32 balancerPoolId2);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _mUsdToken,
        address _imUsdToken,
        address _vimUsdToken,
        address _mtaToken,
        address _wmaticToken
    ) external onlyAdmin {
        require(_usdcToken != address(0), "Zero address not allowed");
        require(_mUsdToken != address(0), "Zero address not allowed");
        require(_imUsdToken != address(0), "Zero address not allowed");
        require(_vimUsdToken != address(0), "Zero address not allowed");
        require(_mtaToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        mUsdToken = IMasset(_mUsdToken);
        imUsdToken = ISavingsContractV2(_imUsdToken);
        vimUsdToken = IBoostedVaultWithLockup(_vimUsdToken);
        mtaToken = IERC20(_mtaToken);
        wmaticToken = IERC20(_wmaticToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        vimUsdTokenDenominator = 10 ** IERC20Metadata(_vimUsdToken).decimals();
        wmaticTokenDenominator = 10 ** IERC20Metadata(_wmaticToken).decimals();

        emit StrategyMStableUpdatedTokens(_usdcToken, _mUsdToken, _imUsdToken, _vimUsdToken, _mtaToken, _wmaticToken,
            usdcTokenDenominator, vimUsdTokenDenominator, wmaticTokenDenominator);
    }

    function setParams(
        address _balancerVault,
        address _uniswapRouter,
        bytes32 _balancerPoolId1,
        bytes32 _balancerPoolId2
    ) external onlyAdmin {
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_uniswapRouter != address(0), "Zero address not allowed");

        require(_balancerPoolId1 != "", "Empty pool id not allowed");
        require(_balancerPoolId2 != "", "Empty pool id not allowed");

        setBalancerVault(_balancerVault);
        _setUniswapRouter(_uniswapRouter);

        balancerPoolId1 = _balancerPoolId1;
        balancerPoolId2 = _balancerPoolId2;

        emit StrategyMStableUpdatedParams(_balancerVault, _uniswapRouter, _balancerPoolId1, _balancerPoolId2);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // 1) Mint mUSD token
        usdcToken.approve(address(mUsdToken), _amount);
        uint256 mintedTokens = mUsdToken.mint(address(usdcToken), _amount, 0, address(this));

        // 2) Deposit mUsd
        mUsdToken.approve(address(imUsdToken), mintedTokens);
        uint256 savedTokens = imUsdToken.depositSavings(mintedTokens, address(this));

        // 3) Stake imUsd
        imUsdToken.approve(address(vimUsdToken), savedTokens);
        vimUsdToken.stake(address(this), savedTokens);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 mUsdAmount = mUsdToken.getMintOutput(address(usdcToken), _amount);
        uint256 imUsdAmount = imUsdToken.underlyingToCredits(mUsdAmount);
        // vimUsd and imUsd in ratio 1:1. we can use imUsdAmount for vimUsdAmount
        // add 0.1% to withdraw more than request amount
        uint256 vimUsdAmount = imUsdAmount * 1001 / 1000;

        vimUsdToken.withdraw(vimUsdAmount);

        imUsdToken.redeem(imUsdToken.balanceOf(address(this)));

        mUsdToken.redeem(address(usdcToken), mUsdToken.balanceOf(address(this)), 0, address(this));

        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        return usdcBalance;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 vimUsdBalance = vimUsdToken.balanceOf(address(this));

        vimUsdToken.withdraw(vimUsdBalance);

        imUsdToken.redeem(imUsdToken.balanceOf(address(this)));

        mUsdToken.redeem(address(usdcToken), mUsdToken.balanceOf(address(this)), 0, address(this));

        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        return usdcBalance;
    }

    function netAssetValue() external override view returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external override view returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        uint256 vimUsdBalance = vimUsdToken.balanceOf(address(this));
        if (vimUsdBalance == 0) {
            return 0;
        }

        // vimUsd and imUsd in ratio 1:1. we can use vimUsdBalance for imUsdBalance
        uint256 mUsdBalance = imUsdToken.creditsToUnderlying(vimUsdBalance);

        uint256 usdcBalance = mUsdToken.getRedeemOutput(address(usdcToken), mUsdBalance);

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {
        vimUsdToken.claimReward();

        uint256 totalUsdc;

        uint256 mtaBalance = mtaToken.balanceOf(address(this));
        if (mtaBalance != 0) {
            uint256 mtaUsdc = batchSwap(balancerPoolId1, balancerPoolId2, IVault.SwapKind.GIVEN_IN, IAsset(address(mtaToken)),
                IAsset(address(wmaticToken)), IAsset(address(usdcToken)), address(this), payable(address(this)), mtaBalance);
            totalUsdc += mtaUsdc;
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance != 0) {
            uint256 wmaticUsdc = _swapExactTokensForTokens(
                address(wmaticToken), 
                address(usdcToken), 
                wmaticBalance,
                address(this)
            );
            totalUsdc += wmaticUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));
        return totalUsdc;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../MassetStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IMasset is IERC20 {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
    external
    view
    virtual
    returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
    external
    view
    virtual
    returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
    external
    view
    virtual
    returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view virtual returns (bool, bool);

    function getBasset(address _token)
    external
    view
    virtual
    returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
    external
    view
    virtual
    returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view virtual returns (uint8);

    function getPrice() external view virtual returns (uint256 price, uint256 k);

    // SavingsManager
    function collectInterest() external virtual returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest()
    external
    virtual
    returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external virtual;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external virtual;

    function setTransferFeesFlag(address _bAsset, bool _flag) external virtual;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISavingsContractV1 is IERC20 {
    function depositInterest(uint256 _amount) external;

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued);

    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function exchangeRate() external view returns (uint256);

    function creditBalances(address) external view returns (uint256);
}

interface ISavingsContractV2 is IERC20 {
    // DEPRECATED but still backwards compatible
    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

    // --------------------------------------------

    function depositInterest(uint256 _amount) external; // V1 & V2

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued); // V1 & V2

    function depositSavings(uint256 _amount, address _beneficiary)
        external
        returns (uint256 creditsIssued); // V2

    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function redeemUnderlying(uint256 _amount) external returns (uint256 creditsBurned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2

    function balanceOfUnderlying(address _user) external view returns (uint256 underlying); // V2

    function underlyingToCredits(uint256 _underlying) external view returns (uint256 credits); // V2

    function creditsToUnderlying(uint256 _credits) external view returns (uint256 underlying); // V2

    function underlying() external view returns (IERC20 underlyingMasset); // V2
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostedVaultWithLockup is IERC20 {
    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last) external;

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @dev Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external;

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @dev Pokes a given account to reset the boost
     */
    function pokeBoost(address _account) external;

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
    external
    view
    returns (
        uint256 amount,
        uint256 first,
        uint256 last
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

struct BassetPersonal {
    // Address of the bAsset
    address addr;
    // Address of the bAsset
    address integrator;
    // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
    bool hasTxFee; // takes a byte in storage
    // Status of the bAsset
    BassetStatus status;
}

struct BassetData {
    // 1 Basset * ratio / ratioScale == x Masset (relative value)
    // If ratio == 10e8 then 1 bAsset = 10 mAssets
    // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
    uint128 ratio;
    // Amount of the Basset that is held in Collateral
    uint128 vaultBalance;
}

// Status of the Basset - has it broken its peg?
enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

struct BasketState {
    bool undergoingRecol;
    bool failed;
}

struct FeederConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
}

struct InvariantConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
    uint256 recolFee;
}

struct BasicConfig {
    uint256 a;
    WeightLimits limits;
}

struct WeightLimits {
    uint128 min;
    uint128 max;
}

struct AmpData {
    uint64 initialA;
    uint64 targetA;
    uint64 rampStartTime;
    uint64 rampEndTime;
}

struct FeederData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 govFee;
    uint256 pendingFees;
    uint256 cacheSize;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct MassetData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 cacheSize;
    uint256 surplus;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    BasketState basket;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct AssetData {
    uint8 idx;
    uint256 amt;
    BassetPersonal personal;
}

struct Asset {
    uint8 idx;
    address addr;
    bool exists;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./exchanges/BalancerExchange.sol";
import "./connectors/meshswap/interfaces/IMeshSwapLP.sol";


contract StrategyMeshSwapUsdcUsdt is Strategy, UniswapV2Exchange, BalancerExchange {

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public meshToken;
    uint256 public usdcTokenDenominator;
    uint256 public usdtTokenDenominator;

    IMeshSwapLP public meshSwapUsdcUsdt;
    bytes32 public poolIdUsdcTusdDaiUsdt;

    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address meshToken, uint256 usdcTokenDenominator, uint256 usdtTokenDenominator);

    event StrategyUpdatedParams(address meshSwapUsdcUsdt, address meshSwapRouter, address balancerVault, bytes32 balancerPoolIdUsdcTusdDaiUsdt);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _meshToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_meshToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        meshToken = IERC20(_meshToken);
        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        usdtTokenDenominator = 10 ** IERC20Metadata(_usdtToken).decimals();

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _meshToken, usdcTokenDenominator, usdtTokenDenominator);
    }

    function setParams(
        address _meshSwapUsdcUsdt,
        address _meshSwapRouter,
        address _balancerVault,
        bytes32 _poolIdUsdcTusdDaiUsdt
    ) external onlyAdmin {

        require(_meshSwapUsdcUsdt != address(0), "Zero address not allowed");
        require(_meshSwapRouter != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_poolIdUsdcTusdDaiUsdt != "", "Empty pool id not allowed");

        meshSwapUsdcUsdt = IMeshSwapLP(_meshSwapUsdcUsdt);
        _setUniswapRouter(_meshSwapRouter);
        setBalancerVault(_balancerVault);
        poolIdUsdcTusdDaiUsdt = _poolIdUsdcTusdDaiUsdt;

        emit StrategyUpdatedParams(_meshSwapUsdcUsdt, _meshSwapRouter, _balancerVault, _poolIdUsdcTusdDaiUsdt);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = meshSwapUsdcUsdt.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        // count amount usdt to swap
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        uint256 amountUsdcFromUsdt;
        if (usdtBalance > 0) {
            amountUsdcFromUsdt = onSwap(
                poolIdUsdcTusdDaiUsdt,
                IVault.SwapKind.GIVEN_IN,
                usdtToken,
                usdcToken,
                usdtBalance
            );
        }
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        //TODO add parameter to _getAmountToSwap() second token amount
        uint256 amountUsdcToSwap = _getAmountToSwap(
            usdcBalance - (amountUsdcFromUsdt / 2),
            reserveUsdc,
            reserveUsdt,
            usdcTokenDenominator,
            usdtTokenDenominator,
            1,
            poolIdUsdcTusdDaiUsdt,
            usdcToken,
            usdtToken
        );

        // swap usdc to usdt
        swap(
            poolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdcToken)),
            IAsset(address(usdtToken)),
            address(this),
            address(this),
            amountUsdcToSwap,
            0
        );

        // add liquidity
        usdcBalance = usdcToken.balanceOf(address(this));
        usdtBalance = usdtToken.balanceOf(address(this));
        _addLiquidity(
            address(usdcToken),
            address(usdtToken),
            usdcBalance,
            usdtBalance,
            OvnMath.subBasisPoints(usdcBalance, BASIS_POINTS_FOR_SLIPPAGE),
            OvnMath.subBasisPoints(usdtBalance, BASIS_POINTS_FOR_SLIPPAGE),
            address(this)
        );
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = meshSwapUsdcUsdt.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        uint256 lpTokenBalance = meshSwapUsdcUsdt.balanceOf(address(this));
        if (lpTokenBalance > 0) {
            // count amount to unstake
            uint256 totalLpBalance = meshSwapUsdcUsdt.totalSupply();
            uint256 lpTokensToWithdraw = _getAmountLpTokensToWithdraw(
                OvnMath.addBasisPoints(_amount, BASIS_POINTS_FOR_SLIPPAGE),
                reserveUsdc,
                reserveUsdt,
                totalLpBalance,
                usdcTokenDenominator,
                usdtTokenDenominator,
                poolIdUsdcTusdDaiUsdt,
                usdcToken,
                usdtToken
            );
            if (lpTokensToWithdraw > lpTokenBalance) {
                lpTokensToWithdraw = lpTokenBalance;
            }
            uint256 amountOutUsdcMin = reserveUsdc * lpTokensToWithdraw / totalLpBalance;
            uint256 amountOutUsdtMin = reserveUsdt * lpTokensToWithdraw / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(usdtToken),
                address(meshSwapUsdcUsdt),
                lpTokensToWithdraw,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutUsdtMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        swap(
            poolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdtToken)),
            IAsset(address(usdcToken)),
            address(this),
            address(this),
            usdtBalance,
            0
        );

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (uint256 reserveUsdc, uint256 reserveUsdt,) = meshSwapUsdcUsdt.getReserves();
        require(reserveUsdc > 10 ** 3 && reserveUsdt > 10 ** 3, 'Liquidity lpToken reserves too low');

        uint256 lpTokenBalance = meshSwapUsdcUsdt.balanceOf(address(this));
        if (lpTokenBalance > 0) {
            uint256 totalLpBalance = meshSwapUsdcUsdt.totalSupply();
            uint256 amountOutUsdcMin = reserveUsdc * lpTokenBalance / totalLpBalance;
            uint256 amountOutUsdtMin = reserveUsdt * lpTokenBalance / totalLpBalance;

            // remove liquidity
            _removeLiquidity(
                address(usdcToken),
                address(usdtToken),
                address(meshSwapUsdcUsdt),
                lpTokenBalance,
                OvnMath.subBasisPoints(amountOutUsdcMin, BASIS_POINTS_FOR_SLIPPAGE),
                OvnMath.subBasisPoints(amountOutUsdtMin, BASIS_POINTS_FOR_SLIPPAGE),
                address(this)
            );
        }

        // swap usdt to usdc
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        swap(
            poolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdtToken)),
            IAsset(address(usdcToken)),
            address(this),
            address(this),
            usdtBalance,
            0
        );

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));

        uint256 lpTokenBalance = meshSwapUsdcUsdt.balanceOf(address(this));
        if (lpTokenBalance > 0) {
            uint256 totalLpBalance = meshSwapUsdcUsdt.totalSupply();
            (uint256 reserveUsdc, uint256 reserveUsdt,) = meshSwapUsdcUsdt.getReserves();
            usdcBalance += reserveUsdc * lpTokenBalance / totalLpBalance;
            usdtBalance += reserveUsdt * lpTokenBalance / totalLpBalance;
        }

        uint256 usdcBalanceFromUsdt;
        if (usdtBalance > 0) {
            usdcBalanceFromUsdt = onSwap(
                poolIdUsdcTusdDaiUsdt,
                IVault.SwapKind.GIVEN_IN,
                usdtToken,
                usdcToken,
                usdtBalance
            );
        }

        return usdcBalance + usdcBalanceFromUsdt;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        meshSwapUsdcUsdt.claimReward();

        // sell rewards
        uint256 totalUsdc;

        uint256 meshBalance = meshToken.balanceOf(address(this));
        if (meshBalance > 0) {
            uint256 meshUsdc = _swapExactTokensForTokens(
                address(meshToken),
                address(usdcToken),
                meshBalance,
                address(this)
            );
            totalUsdc += meshUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));

        return totalUsdc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5 <0.9.0;

import "../../uniswap/v2/interfaces/IUniswapV2Pair.sol";

interface IMeshSwapLP is IUniswapV2Pair {

    function depositToken(uint256 _amount) external;

    function withdrawToken(uint256 withdrawAmount) external;

    function claimReward() external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/meshswap/interfaces/IMeshSwapLP.sol";


contract StrategyMeshSwapUsdc is Strategy, UniswapV2Exchange {

    IERC20 public usdcToken;
    IERC20 public meshToken;

    IMeshSwapLP public meshSwapUsdc;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address meshToken);

    event StrategyUpdatedParams(address meshSwapUsdc, address meshSwapRouter );


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _meshToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_meshToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        meshToken = IERC20(_meshToken);

        emit StrategyUpdatedTokens(_usdcToken, _meshToken);
    }

    function setParams(
        address _meshSwapUsdc,
        address _meshSwapRouter
    ) external onlyAdmin {

        require(_meshSwapUsdc != address(0), "Zero address not allowed");
        require(_meshSwapRouter != address(0), "Zero address not allowed");

        meshSwapUsdc = IMeshSwapLP(_meshSwapUsdc);
        _setUniswapRouter(_meshSwapRouter);

        emit StrategyUpdatedParams(_meshSwapUsdc, _meshSwapRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        usdcToken.approve(address(meshSwapUsdc), _amount);
        meshSwapUsdc.depositToken(_amount);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        meshSwapUsdc.withdrawToken(_amount);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        //TODO fix count
        uint256 usdcTokenAmount = meshSwapUsdc.balanceOf(address(this)) * 2;
        meshSwapUsdc.withdrawToken(usdcTokenAmount);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        //TODO fix count
        return meshSwapUsdc.balanceOf(address(this)) * 2;
    }

    function liquidationValue() external view override returns (uint256) {
        //TODO fix count
        return meshSwapUsdc.balanceOf(address(this)) * 2;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        //claim rewards
        meshSwapUsdc.claimReward();

        // sell rewards
        uint256 totalUsdc;

        uint256 meshBalance = meshToken.balanceOf(address(this));
        if (meshBalance > 0) {
            uint256 meshUsdc = _swapExactTokensForTokens(
                address(meshToken),
                address(usdcToken),
                meshBalance,
                address(this)
            );
            totalUsdc += meshUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/BalancerExchange.sol";
import "./connectors/impermax/interfaces/IPoolToken.sol";
import "./connectors/impermax/interfaces/IImpermaxRouter.sol";
import "./connectors/uniswap/v2/interfaces/IUniswapV2Pair.sol";

contract StrategyImpermaxQsUsdt is Strategy, BalancerExchange {

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IPoolToken public imxBToken;

    bytes32 public balancerPoolId;

    IImpermaxRouter public impermaxRouter;
    IUniswapV2Pair public pair;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address imxBToken);

    event StrategyUpdatedParams(address impermaxRouter, address balancerVault,  bytes32 balancerPoolId);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _imxBToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_imxBToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        imxBToken = IPoolToken(_imxBToken);

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _imxBToken);
    }

    function setParams(
        address _impermaxRouter,
        address _balancerVault,
        bytes32 _balancerPoolId
    ) external onlyAdmin {

        require(_impermaxRouter != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_balancerPoolId != "", "Empty pool id not allowed");

        impermaxRouter = IImpermaxRouter(_impermaxRouter);

        pair = IUniswapV2Pair(impermaxRouter.getUniswapV2Pair(imxBToken.underlying()));

        balancerPoolId = _balancerPoolId;
        setBalancerVault(_balancerVault);

        emit StrategyUpdatedParams(_impermaxRouter, _balancerVault, _balancerPoolId);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");

        address current = address(this);

        swap(balancerPoolId, IVault.SwapKind.GIVEN_IN, IAsset(address(usdcToken)), IAsset(address(usdtToken)), current, current, usdcToken.balanceOf(current), 0);

        usdtToken.approve(address(impermaxRouter), usdtToken.balanceOf(current));
        impermaxRouter.mint(address(imxBToken), usdtToken.balanceOf(current), current, block.timestamp);

    }


    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");

        address current = address(this);

        imxBToken.approve(address(impermaxRouter), imxBToken.balanceOf(current));
        impermaxRouter.redeem(address(imxBToken), imxBToken.balanceOf(current), current, block.timestamp, "");

        swap(balancerPoolId, IVault.SwapKind.GIVEN_OUT, IAsset(address(usdtToken)), IAsset(address(usdcToken)), current, current, _amount);

        usdtToken.approve(address(impermaxRouter), usdtToken.balanceOf(current));
        impermaxRouter.mint(address(imxBToken), usdtToken.balanceOf(current), current, block.timestamp);


        return usdcToken.balanceOf(current);
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {
        require(_asset == address(usdcToken), "Some token not compatible");

        address current = address(this);

        imxBToken.approve(address(impermaxRouter), imxBToken.balanceOf(current));
        impermaxRouter.redeem(address(imxBToken), imxBToken.balanceOf(current), current, block.timestamp, "");

        swap(balancerPoolId, IVault.SwapKind.GIVEN_IN, IAsset(address(usdtToken)), IAsset(address(usdcToken)), current, current, usdtToken.balanceOf(current), 0);


        return usdcToken.balanceOf(current);
    }

    function netAssetValue() external view override returns (uint256) {
        return _getTotal();

    }

    function liquidationValue() external view override returns (uint256) {
        return _getTotal();
    }

    function _getTotal() internal view returns (uint256){
        uint256 balance = usdcToken.balanceOf(address(this));

        uint256 lockedBalance = imxBToken.balanceOf(address(this));

        if (lockedBalance != 0) {
            // 6 + 18 - 18 = 6
            uint256 balanceUsdt = (lockedBalance * imxBToken.exchangeRateLast()) / 1e18;
            balance += onSwap(balancerPoolId, IVault.SwapKind.GIVEN_OUT, usdcToken, usdtToken, balanceUsdt);
        }

        return balance;
    }


    // No claiming. Natural increase in liquidity.
    function _claimRewards(address _beneficiary) internal override returns (uint256) {
        return 0;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IPoolToken {

    /*** Impermax ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function totalBalance() external view returns (uint);
    function exchangeRateLast() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function underlying() external view returns (address);

    function exchangeRate() external  returns (uint);

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IImpermaxRouter {

    function mint(address poolToken, uint256 amount, address to, uint256 deadline) external;

    function redeem(address poolToken, uint256 tokens, address to, uint256 deadline, bytes memory permitData) external;

    function getUniswapV2Pair(address underlying) external view returns (address);

    function getBorrowable(address uniswapV2Pair, uint8 index) external view returns (address borrowable);

    function getCollateral(address uniswapV2Pair) external view returns (address collateral);

    function getLendingPool(address uniswapV2Pair) external view returns (address collateral, address borrowableA, address borrowableB);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/DodoExchange.sol";
import "./exchanges/BalancerExchange.sol";
import "./libraries/OvnMath.sol";
import "./connectors/dodo/interfaces/IDODOV1.sol";
import "./connectors/dodo/interfaces/IDODOV2.sol";
import "./connectors/dodo/interfaces/IDODOMine.sol";


contract StrategyDodoUsdt is Strategy, DodoExchange, BalancerExchange {
    using OvnMath for uint256;

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public dodoToken;
    IERC20 public wmaticToken;
    IERC20 public usdtLPToken;

    IDODOV1 public dodoV1UsdcUsdtPool;
    IDODOV2 public dodoV2DodoUsdtPool;
    IDODOMine public dodoMine;
    bytes32 public balancerPoolIdUsdcTusdDaiUsdt;
    bytes32 public balancerPoolIdWmaticUsdcWethBal;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address dodoToken, address wmaticToken, address usdtLPToken);

    event StrategyUpdatedParams(address dodoV1UsdcUsdtPool, address dodoV2DodoUsdtPool, address dodoMine, address dodoV1Helper,
        address dodoProxy, address dodoApprove, address balancerVault, bytes32 balancerPoolIdUsdcTusdDaiUsdt, bytes32 balancerPoolIdWmaticUsdcWethBal);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _dodoToken,
        address _wmaticToken,
        address _usdtLPToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_dodoToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_usdtLPToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        dodoToken = IERC20(_dodoToken);
        wmaticToken = IERC20(_wmaticToken);
        usdtLPToken = IERC20(_usdtLPToken);

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _dodoToken, _wmaticToken, _usdtLPToken);
    }

    function setParams(
        address _dodoV1UsdcUsdtPool,
        address _dodoV2DodoUsdtPool,
        address _dodoMine,
        address _dodoV1Helper,
        address _dodoProxy,
        address _dodoApprove,
        address _balancerVault,
        bytes32 _balancerPoolIdUsdcTusdDaiUsdt,
        bytes32 _balancerPoolIdWmaticUsdcWethBal
    ) external onlyAdmin {

        require(_dodoV1UsdcUsdtPool != address(0), "Zero address not allowed");
        require(_dodoV2DodoUsdtPool != address(0), "Zero address not allowed");
        require(_dodoMine != address(0), "Zero address not allowed");
        require(_dodoV1Helper != address(0), "Zero address not allowed");
        require(_dodoProxy != address(0), "Zero address not allowed");
        require(_dodoApprove != address(0), "Zero address not allowed");
        require(_balancerVault != address(0), "Zero address not allowed");
        require(_balancerPoolIdUsdcTusdDaiUsdt != "", "Empty pool id not allowed");
        require(_balancerPoolIdWmaticUsdcWethBal != "", "Empty pool id not allowed");

        dodoV1UsdcUsdtPool = IDODOV1(_dodoV1UsdcUsdtPool);
        dodoV2DodoUsdtPool = IDODOV2(_dodoV2DodoUsdtPool);
        dodoMine = IDODOMine(_dodoMine);
        _setDodoParams(_dodoV1Helper, _dodoProxy, _dodoApprove);
        setBalancerVault(_balancerVault);
        balancerPoolIdUsdcTusdDaiUsdt = _balancerPoolIdUsdcTusdDaiUsdt;
        balancerPoolIdWmaticUsdcWethBal = _balancerPoolIdWmaticUsdcWethBal;

        emit StrategyUpdatedParams(_dodoV1UsdcUsdtPool, _dodoV2DodoUsdtPool, _dodoMine, _dodoV1Helper, _dodoProxy,
            _dodoApprove, _balancerVault, _balancerPoolIdUsdcTusdDaiUsdt, _balancerPoolIdWmaticUsdcWethBal);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // swap all usdc to usdt
        swap(
            balancerPoolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdcToken)),
            IAsset(address(usdtToken)),
            address(this),
            address(this),
            usdcToken.balanceOf(address(this)),
            0
        );

        // add liquidity to pool
        uint256 usdtTokenAmount = usdtToken.balanceOf(address(this));
        usdtToken.approve(address(dodoV1UsdcUsdtPool), usdtTokenAmount);
        dodoV1UsdcUsdtPool.depositQuoteTo(address(this), usdtTokenAmount);

        // stake all lp tokens
        uint256 usdtLPTokenBalance = usdtLPToken.balanceOf(address(this));
        usdtLPToken.approve(address(dodoMine), usdtLPTokenBalance);
        dodoMine.deposit(usdtLPTokenBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // add 5 basis points and 0.000005 usdc for small values
        uint256 amountToUnstake = _amount.addBasisPoints(5) + 5;

        // get usdt amount
        uint256 usdtTokenAmount = onSwap(
            balancerPoolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_OUT,
            usdtToken,
            usdcToken,
            amountToUnstake
        );

        // get lp tokens
        uint256 usdtLPTokenTotalSupply = usdtLPToken.totalSupply();
        (, uint256 quoteTarget) = dodoV1UsdcUsdtPool.getExpectedTarget();
        uint256 unstakeLpBalance = usdtTokenAmount * usdtLPTokenTotalSupply / quoteTarget;
        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (unstakeLpBalance > userLPBalance) {
            unstakeLpBalance = userLPBalance;
        }

        // unstake lp tokens
        dodoMine.withdraw(unstakeLpBalance);

        // remove liquidity from pool
        dodoV1UsdcUsdtPool.withdrawAllQuote();

        // swap all usdt to usdc
        swap(
            balancerPoolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdtToken)),
            IAsset(address(usdcToken)),
            address(this),
            address(this),
            usdtToken.balanceOf(address(this)),
            0
        );

        // return all usdc tokens
        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // get all lp tokens
        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance == 0) {
            return usdcToken.balanceOf(address(this));
        }

        // unstake lp tokens
        dodoMine.withdraw(userLPBalance);

        // remove liquidity from pool
        dodoV1UsdcUsdtPool.withdrawAllQuote();

        // swap all usdt to usdc
        swap(
            balancerPoolIdUsdcTusdDaiUsdt,
            IVault.SwapKind.GIVEN_IN,
            IAsset(address(usdtToken)),
            IAsset(address(usdcToken)),
            address(this),
            address(this),
            usdtToken.balanceOf(address(this)),
            0
        );

        // return all usdc tokens
        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external override view returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external override view returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));

        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance > 0) {
            uint256 usdcLPTokenTotalSupply = usdtLPToken.totalSupply();
            (, uint256 quoteTarget) = dodoV1UsdcUsdtPool.getExpectedTarget();
            uint256 usdtTokenAmount = quoteTarget * userLPBalance / usdcLPTokenTotalSupply;
            usdtBalance += usdtTokenAmount;
        }

        if (usdtBalance > 0) {
            uint256 usdtBalanceInUsdc;
            if (nav) {
                // check how many USDC tokens we have by current price
                uint256 priceUsdt = onSwap(
                    balancerPoolIdUsdcTusdDaiUsdt,
                    IVault.SwapKind.GIVEN_IN,
                    usdtToken,
                    usdcToken,
                    1e6
                );
                usdtBalanceInUsdc = (priceUsdt * usdtBalance) / 1e6;
            } else {
                // check how many USDC tokens we will get if we sell USDT tokens now
                usdtBalanceInUsdc = onSwap(
                    balancerPoolIdUsdcTusdDaiUsdt,
                    IVault.SwapKind.GIVEN_IN,
                    usdtToken,
                    usdcToken,
                    usdtBalance
                );
            }
            usdcBalance += usdtBalanceInUsdc;
        }

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance == 0) {
            return 0;
        }

        // claim rewards
        dodoMine.claimAllRewards();

        // sell rewards
        uint256 totalUsdc;

        uint256 dodoBalance = dodoToken.balanceOf(address(this));
        if (dodoBalance > 0) {
            // swap v2 dodo -> usdt
            uint256 usdtTokenAmount = _useDodoSwapV2(
                address(dodoV2DodoUsdtPool),
                address(dodoToken),
                address(usdtToken),
                dodoBalance,
                1,
                0
            );

            uint256 usdcTokenAmount;
            if (usdtTokenAmount > 0) {
                // swap usdt -> usdc
                usdcTokenAmount = swap(
                    balancerPoolIdUsdcTusdDaiUsdt,
                    IVault.SwapKind.GIVEN_IN,
                    IAsset(address(usdtToken)),
                    IAsset(address(usdcToken)),
                    address(this),
                    address(this),
                    usdtTokenAmount,
                    0
                );
            }

            totalUsdc += usdcTokenAmount;
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance > 0) {
            uint256 wmaticUsdc = swap(
                balancerPoolIdWmaticUsdcWethBal,
                IVault.SwapKind.GIVEN_IN,
                IAsset(address(wmaticToken)),
                IAsset(address(usdcToken)),
                address(this),
                address(this),
                wmaticBalance,
                0
            );

            totalUsdc += wmaticUsdc;
        }

        if (totalUsdc > 0) {
            usdcToken.transfer(_to, totalUsdc);
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../connectors/dodo/interfaces/IDODOV1Helper.sol";
import "../connectors/dodo/interfaces/IDODOProxy.sol";
import "../connectors/dodo/interfaces/IDODOV2.sol";

/*
    There are six swap functions in DODOProxy. Which are executed for different sources or versions

    - dodoSwapV1: Used for DODOV1 pools
    - dodoSwapV2ETHToToken: Used for DODOV2 pools and specify ETH as fromToken
    - dodoSwapV2TokenToETH: Used for DODOV2 pools and specify ETH as toToken
    - dodoSwapV2TokenToToken:  Used for DODOV2 pools and both fromToken and toToken are ERC20
    - externalSwap: Used for executing third-party protocols' aggregation algorithm
    - mixSwap: Used for executing DODO’s custom aggregation algorithm

    Note: Best Trading path is calculated by off-chain program. DODOProxy's swap functions is only used for executing.
*/
abstract contract DodoExchange {

    IDODOV1Helper private dodoV1Helper;
    IDODOProxy private dodoProxy;
    address private dodoApprove;

    function _setDodoParams(
        address _dodoV1Helper,
        address _dodoProxy,
        address _dodoApprove
    ) internal {
        dodoV1Helper = IDODOV1Helper(_dodoV1Helper);
        dodoProxy = IDODOProxy(_dodoProxy);
        dodoApprove = _dodoApprove;
    }

    /*
        The code example assumes user wanting to use the specify DODOV1 pool for swapping

        Note: Differentiate sellBaseToken or sellQuoteToken. If sellBaseToken represents 0, sellQuoteToken represents 1.
        At the same time, dodoSwapV1 supports multi-hop linear routing, so here we use 0,1
        combination to represent the multi-hop directions to save gas consumption
        For example:
            A - B - C (A - B sellBase and  B - C sellQuote)  Binary: 10, Decimal 2 (directions = 2)
            D - E - F (D - E sellQuote and E - F sellBase) Binary: 01, Decimal 1 (directions = 1)
    */
    function _useDodoSwapV1(
        address dodoV1Pool,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 slippage,
        uint256 directions
    ) internal returns (uint256) {

        uint256 minReturnAmount;
        if (directions == 0) {
            uint256 receivedQuoteAmount = dodoV1Helper.querySellBaseToken(dodoV1Pool, fromTokenAmount);
            minReturnAmount = receivedQuoteAmount * (100 - slippage) / 100;
        } else {
            uint256 receivedBaseAmount = dodoV1Helper.querySellQuoteToken(dodoV1Pool, fromTokenAmount);
            minReturnAmount = receivedBaseAmount * (100 - slippage) / 100;
        }
        if (minReturnAmount == 0) {
            return 0;
        }

        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV1Pool;

        IERC20(fromToken).approve(dodoApprove, fromTokenAmount);

        return dodoProxy.dodoSwapV1(
            fromToken,
            toToken,
            fromTokenAmount,
            minReturnAmount,
            dodoPairs,
            directions,
            false,
            block.timestamp + 600
        );
    }

    /*
        The code example assumes user wanting to use the specify DODOV2 pool for swapping

        Note: Differentiate sellBaseToken or sellQuoteToken. If sellBaseToken represents 0, sellQuoteToken represents 1.
        At the same time, dodoSwapV1 supports multi-hop linear routing, so here we use 0,1
        combination to represent the multi-hop directions to save gas consumption
        For example:
            A - B - C (A - B sellBase and  B - C sellQuote)  Binary: 10, Decimal 2 (directions = 2)
            D - E - F (D - E sellQuote and E - F sellBase) Binary: 01, Decimal 1 (directions = 1)
    */
    function _useDodoSwapV2(
        address dodoV2Pool,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 slippage,
        uint256 directions
    ) internal returns (uint256) {

        uint256 minReturnAmount;
        if (directions == 0) {
            (uint256 receiveQuoteAmount,) = IDODOV2(dodoV2Pool).querySellBase(address(this), fromTokenAmount);
            minReturnAmount = receiveQuoteAmount * (100 - slippage) / 100;
        } else {
            (uint256 receiveBaseAmount,) = IDODOV2(dodoV2Pool).querySellQuote(address(this), fromTokenAmount);
            minReturnAmount = receiveBaseAmount * (100 - slippage) / 100;
        }
        if (minReturnAmount == 0) {
            return 0;
        }

        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV2Pool;

        IERC20(fromToken).approve(dodoApprove, fromTokenAmount);

        return dodoProxy.dodoSwapV2TokenToToken(
            fromToken,
            toToken,
            fromTokenAmount,
            minReturnAmount,
            dodoPairs,
            directions,
            false,
            block.timestamp + 600
        );
    }

}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;

interface IDODOV1 {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function depositBaseTo(address to, uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function _K_() external view returns (uint256);

    function _R_STATUS_() external view returns (RStatus);

    function _TARGET_BASE_TOKEN_AMOUNT_() external view returns (uint256);

    function _TARGET_QUOTE_TOKEN_AMOUNT_() external view returns (uint256);

    function _BASE_BALANCE_() external view returns (uint256);

    function _QUOTE_BALANCE_() external view returns (uint256);

    function getOraclePrice() external view returns (uint256);

    enum RStatus {ONE, ABOVE_ONE, BELOW_ONE}

}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;

interface IDODOV2 {
    function querySellBase(
        address trader,
        uint256 payBaseAmount
    ) external view returns (uint256 receiveQuoteAmount, uint256 mtFee);

    function querySellQuote(
        address trader,
        uint256 payQuoteAmount
    ) external view returns (uint256 receiveBaseAmount, uint256 mtFee);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;

interface IDODOMine {

    function balanceOf(address user) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function claimAllRewards() external;

}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;

interface IDODOV1Helper {
    function querySellQuoteToken(
        address dodoV1Pool,
        uint256 quoteAmount
    ) external view returns (uint256 receivedBaseAmount);

    function querySellBaseToken(
        address dodoV1Pool,
        uint256 baseAmount
    ) external view returns (uint256 receivedQuoteAmount);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;

interface IDODOProxy {
    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/DodoExchange.sol";
import "./exchanges/BalancerExchange.sol";
import "./libraries/OvnMath.sol";
import "./libraries/StrategyDodoLibrary.sol";
import "./connectors/dodo/interfaces/IDODOV1.sol";
import "./connectors/dodo/interfaces/IDODOV2.sol";
import "./connectors/dodo/interfaces/IDODOMine.sol";


contract StrategyDodoUsdc is Strategy, DodoExchange, BalancerExchange {
    using OvnMath for uint256;

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IERC20 public dodoToken;
    IERC20 public wmaticToken;
    IERC20 public usdcLPToken;

    IDODOV1 public dodoV1UsdcUsdtPool;
    IDODOV2 public dodoV2DodoUsdtPool;
    IDODOMine public dodoMine;
    bytes32 public balancerPoolIdWmaticUsdcWethBal;


    // --- events

    event StrategyUpdatedTokens(address usdcToken, address usdtToken, address dodoToken, address wmaticToken, address usdcLPToken);

    event StrategyUpdatedParams(address dodoV1UsdcUsdtPool, address dodoV2DodoUsdtPool, address dodoMine, address dodoV1Helper,
        address dodoProxy, address dodoApprove, address balancerVault, bytes32 balancerPoolIdWmaticUsdcWethBal);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _usdtToken,
        address _dodoToken,
        address _wmaticToken,
        address _usdcLPToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_usdtToken != address(0), "Zero address not allowed");
        require(_dodoToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_usdcLPToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        usdtToken = IERC20(_usdtToken);
        dodoToken = IERC20(_dodoToken);
        wmaticToken = IERC20(_wmaticToken);
        usdcLPToken = IERC20(_usdcLPToken);

        emit StrategyUpdatedTokens(_usdcToken, _usdtToken, _dodoToken, _wmaticToken, _usdcLPToken);
    }

    function setParams(
        address _dodoV1UsdcUsdtPool,
        address _dodoV2DodoUsdtPool,
        address _dodoMine,
        address _dodoV1Helper,
        address _dodoProxy,
        address _dodoApprove,
        address _balancerVault,
        bytes32 _balancerPoolIdWmaticUsdcWethBal
    ) external onlyAdmin {

        require(_dodoV1UsdcUsdtPool != address(0), "Zero address not allowed");
        require(_dodoV2DodoUsdtPool != address(0), "Zero address not allowed");
        require(_dodoMine != address(0), "Zero address not allowed");
        require(_dodoV1Helper != address(0), "Zero address not allowed");
        require(_dodoProxy != address(0), "Zero address not allowed");
        require(_dodoApprove != address(0), "Zero address not allowed");
        require(_balancerPoolIdWmaticUsdcWethBal != "", "Empty pool id not allowed");

        dodoV1UsdcUsdtPool = IDODOV1(_dodoV1UsdcUsdtPool);
        dodoV2DodoUsdtPool = IDODOV2(_dodoV2DodoUsdtPool);
        dodoMine = IDODOMine(_dodoMine);
        _setDodoParams(_dodoV1Helper, _dodoProxy, _dodoApprove);
        setBalancerVault(_balancerVault);
        balancerPoolIdWmaticUsdcWethBal = _balancerPoolIdWmaticUsdcWethBal;

        emit StrategyUpdatedParams(_dodoV1UsdcUsdtPool, _dodoV2DodoUsdtPool, _dodoMine, _dodoV1Helper, _dodoProxy,
            _dodoApprove, _balancerVault, _balancerPoolIdWmaticUsdcWethBal);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        // stake all usdc tokens
        uint256 usdcTokenAmount = usdcToken.balanceOf(address(this));

        // add liquidity to pool
        usdcToken.approve(address(dodoV1UsdcUsdtPool), usdcTokenAmount);
        dodoV1UsdcUsdtPool.depositBaseTo(address(this), usdcTokenAmount);

        // stake all lp tokens
        uint256 usdcLPTokenBalance = usdcLPToken.balanceOf(address(this));
        usdcLPToken.approve(address(dodoMine), usdcLPTokenBalance);
        dodoMine.deposit(usdcLPTokenBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 amountToUnstake = StrategyDodoLibrary._getAmountIn(_amount, dodoV1UsdcUsdtPool) + 1;

        // get lp tokens
        uint256 usdcLPTokenTotalSupply = usdcLPToken.totalSupply();
        (uint256 baseTarget,) = dodoV1UsdcUsdtPool.getExpectedTarget();
        uint256 unstakeLpBalance = amountToUnstake * usdcLPTokenTotalSupply / baseTarget;
        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (unstakeLpBalance > userLPBalance) {
            unstakeLpBalance = userLPBalance;
        }

        // unstake lp tokens
        dodoMine.withdraw(unstakeLpBalance);

        // remove liquidity from pool
        dodoV1UsdcUsdtPool.withdrawAllBase();

        // return all usdc tokens
        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // get all lp tokens
        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance == 0) {
            return usdcToken.balanceOf(address(this));
        }

        // unstake lp tokens
        dodoMine.withdraw(userLPBalance);

        // remove liquidity from pool
        dodoV1UsdcUsdtPool.withdrawAllBase();

        // return all usdc tokens
        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external override view returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external override view returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance > 0) {
            uint256 usdcLPTokenTotalSupply = usdcLPToken.totalSupply();
            (uint256 baseTarget,) = dodoV1UsdcUsdtPool.getExpectedTarget();
            uint256 usdcTokenAmount = baseTarget * userLPBalance / usdcLPTokenTotalSupply;

            if(nav){
                usdcBalance += usdcTokenAmount;
            }else {
                // minus 0.06%
                usdcBalance += usdcTokenAmount - (usdcTokenAmount * 6 / 10000);
            }

        }

        return usdcBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        uint256 userLPBalance = dodoMine.balanceOf(address(this));
        if (userLPBalance == 0) {
            return 0;
        }

        // claim rewards
        dodoMine.claimAllRewards();

        // sell rewards
        uint256 totalUsdc;

        uint256 dodoBalance = dodoToken.balanceOf(address(this));
        if (dodoBalance > 0) {
            // swap v2 dodo -> usdt
            uint256 usdtTokenAmount = _useDodoSwapV2(
                address(dodoV2DodoUsdtPool),
                address(dodoToken),
                address(usdtToken),
                dodoBalance,
                1,
                0
            );

            uint256 usdcTokenAmount;
            if (usdtTokenAmount > 0) {
                // swap v1 usdt -> usdc
                usdcTokenAmount = _useDodoSwapV1(
                    address(dodoV1UsdcUsdtPool),
                    address(usdtToken),
                    address(usdcToken),
                    usdtTokenAmount,
                    1,
                    1
                );
            }

            totalUsdc += usdcTokenAmount;
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance > 0) {
            uint256 wmaticUsdc = swap(
                balancerPoolIdWmaticUsdcWethBal,
                IVault.SwapKind.GIVEN_IN,
                IAsset(address(wmaticToken)),
                IAsset(address(usdcToken)),
                address(this),
                address(this),
                wmaticBalance,
                0
            );

            totalUsdc += wmaticUsdc;
        }

        if (totalUsdc > 0) {
            usdcToken.transfer(_to, totalUsdc);
        }

        return totalUsdc;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../connectors/dodo/interfaces/IDODOV1.sol";
import "./SafeMath.sol";
import "./DecimalMath.sol";

library StrategyDodoLibrary {
    using SafeMath for uint256;


    struct Context {
        IDODOV1 dodo;
        uint256 amountOut;
        uint256 fairAmount;
        uint256 targetBase;
        uint256 dd;
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
        uint256 g;
        uint256 h;
        uint256 i;
    }

    function _getAmountIn(uint256 amountOut, IDODOV1 dodo) internal view returns (uint256) {
        if (dodo._R_STATUS_() != IDODOV1.RStatus.ABOVE_ONE) {
            return amountOut;
        }

        Context memory ctx;
        ctx.dodo = dodo;
        ctx.amountOut = amountOut;

        ctx.fairAmount = _fairAmount(ctx);
        ctx.targetBase = _solveQuadraticFunctionForTargetCeil(ctx);

        ctx.dd = getDD(ctx);
        ctx.a = getA(ctx);
        ctx.b = getB(ctx);
        ctx.c = getC(ctx);
        ctx.d = getD(ctx);
        ctx.e = getE(ctx);
        ctx.g = getG(ctx);
        ctx.h = getH(ctx);
        ctx.i = getI(ctx);

        uint256 underSqrt = ctx.a.add(ctx.c).add(ctx.d).add(ctx.e).sub(ctx.b);
        uint256 sqrt = underSqrt.sqrt();
        uint256 t1 = ctx.g.add(sqrt);
        uint256 t2 = t1.mul(1e18).div(ctx.i);
        uint256 res = ctx.h.sub(t2);

        return res;
    }


    function _fairAmount(Context memory ctx) internal view returns (uint256){
        uint256 spareQuote = ctx.dodo._QUOTE_BALANCE_().sub(ctx.dodo._TARGET_QUOTE_TOKEN_AMOUNT_());
        uint256 price = ctx.dodo.getOraclePrice();
        uint256 fairAmount = DecimalMath.divFloor(spareQuote, price);
        return fairAmount;
    }

    function getDD(Context memory ctx) internal view returns (uint256){
        return ctx.dodo._BASE_BALANCE_().mul(2).sub(ctx.amountOut);
    }

    function getA(Context memory ctx) internal view returns (uint256){
        return ctx.fairAmount.mul(ctx.fairAmount).add(ctx.targetBase.mul(ctx.targetBase));
    }

    function getB(Context memory ctx) internal view returns (uint256){

        uint256 t1 = ctx.fairAmount.mul(ctx.dodo._K_()).mul(2).div(1e18);
        uint256 t2 = ctx.dd.add(ctx.fairAmount).add(t1);
        uint256 t3 = t2.mul(ctx.targetBase).mul(2);

        return t3;
    }

    function getC(Context memory ctx) internal view returns (uint256){
        return ctx.dd.mul(ctx.fairAmount).mul(2);
    }

    function getD(Context memory ctx) internal view returns (uint256){
        return ctx.c.mul(ctx.dodo._K_()).mul(2).div(1e18);
    }

    function getE(Context memory ctx) internal view returns (uint256){
        return ctx.dd.mul(ctx.dd);
    }

    function getG(Context memory ctx) internal view returns (uint256){
        return ctx.targetBase.add(ctx.fairAmount).sub(ctx.dd);
    }

    function getH(Context memory ctx) internal view returns (uint256){
        return ctx.targetBase.add(ctx.dodo._BASE_BALANCE_()).sub(ctx.dd);
    }

    function getI(Context memory ctx) internal view returns (uint256){
        return ctx.dodo._K_().mul(2).add(uint256(2).mul(1e18));
    }


    function _solveQuadraticFunctionForTargetCeil(
        Context memory ctx
    ) internal view returns (uint256) {
        uint256 V1 = ctx.dodo._BASE_BALANCE_();
        uint256 k = ctx.dodo._K_();

        // V0 = V1+V1*(sqrt-1)/2k
        uint256 sqrt = DecimalMath.divCeil(DecimalMath.mulCeil(k, ctx.fairAmount).mul(4), V1);
        sqrt = sqrt.add(DecimalMath.ONE).mul(DecimalMath.ONE).sqrt();
        uint256 premium = DecimalMath.divCeil(sqrt.sub(DecimalMath.ONE), k.mul(2));
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mul(V1, DecimalMath.ONE.add(premium));
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).divCeil(d);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/BalancerExchange.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/balancer/interfaces/IVault.sol";
import "./connectors/balancer/MerkleOrchard.sol";


contract StrategyBalancer is Strategy, BalancerExchange, UniswapV2Exchange {

    IERC20 public usdcToken;
    IERC20 public bpspTUsdToken;
    IERC20 public balToken;
    IERC20 public wmaticToken;
    IERC20 public tusdToken;

    uint256 public usdcTokenDenominator;
    uint256 public bpspTUsdTokenDenominator;
    uint256 public balTokenDenominator;
    uint256 public wmaticTokenDenominator;
    uint256 public tusdTokenDenominator;

    IVault public balancerVault;

    bytes32 public balancerPoolId1;
    bytes32 public balancerPoolId2;

    MerkleOrchard public merkleOrchard;

    address public distributorBal;
    address public distributorWMatic;
    address public distributorTUsd;

    // Not using
    uint256 public distributionId;

    uint256 public distributionIdBal;
    uint256 public distributionIdWMatic;
    uint256 public distributionIdTUsd;

    uint256 public claimedBalanceBal;
    uint256 public claimedBalanceWMatic;
    uint256 public claimedBalanceTUsd;

    bytes32[] public merkleProofBal;
    bytes32[] public merkleProofWMatic;
    bytes32[] public merkleProofTUsd;


    // --- events

    event StrategyBalancerUpdatedTokens(address usdcToken, address bpspTUsdToken, address balToken, address wmaticToken,
        address tusdToken, uint256 usdcTokenDenominator, uint256 bpspTUsdTokenDenominator,uint256 balTokenDenominator,
        uint256 wmaticTokenDenominator, uint256 tusdTokenDenominator);

    event StrategyBalancerUpdatedParams(address balancerVault, address uniswapRouter, bytes32 balancerPoolId1,
        bytes32 balancerPoolId2, address merkleOrchard);

    event StrategyBalancerClaimingParamsUpdated(
        address distributorBal, address distributorWMatic, address distributorTUsd,
        uint256 distributionIdBal, uint256 distributionIdWMatic, uint256 distributionIdTUsd,
        uint256 claimedBalanceBal, uint256 claimedBalanceWMatic, uint256 claimedBalanceTUsd,
        bytes32[] merkleProofBal, bytes32[] merkleProofWMatic, bytes32[] merkleProofTUsd);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _bpspTUsdToken,
        address _balToken,
        address _wmaticToken,
        address _tusdToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_bpspTUsdToken != address(0), "Zero address not allowed");
        require(_balToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");
        require(_tusdToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        bpspTUsdToken = IERC20(_bpspTUsdToken);
        balToken = IERC20(_balToken);
        wmaticToken = IERC20(_wmaticToken);
        tusdToken = IERC20(_tusdToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        bpspTUsdTokenDenominator = 10 ** IERC20Metadata(_bpspTUsdToken).decimals();
        balTokenDenominator = 10 ** IERC20Metadata(_balToken).decimals();
        wmaticTokenDenominator = 10 ** IERC20Metadata(_wmaticToken).decimals();
        tusdTokenDenominator = 10 ** IERC20Metadata(_tusdToken).decimals();

        emit StrategyBalancerUpdatedTokens(_usdcToken, _bpspTUsdToken, _balToken, _wmaticToken, _tusdToken,
            usdcTokenDenominator, bpspTUsdTokenDenominator, balTokenDenominator, wmaticTokenDenominator, tusdTokenDenominator);
    }

    function setParams(
        address _balancerVault,
        address _uniswapRouter,
        bytes32 _balancerPoolId1,
        bytes32 _balancerPoolId2,
        address _merkleOrchard
    ) external onlyAdmin {

        require(_balancerVault != address(0), "Zero address not allowed");
        require(_uniswapRouter != address(0), "Zero address not allowed");
        require(_balancerPoolId1 != "", "Empty pool id not allowed");
        require(_balancerPoolId2 != "", "Empty pool id not allowed");
        require(_merkleOrchard != address(0), "Zero address not allowed");

        setBalancerVault(_balancerVault);
        _setUniswapRouter(_uniswapRouter);

        balancerVault = IVault(_balancerVault);
        balancerPoolId1 = _balancerPoolId1;
        balancerPoolId2 = _balancerPoolId2;
        merkleOrchard = MerkleOrchard(_merkleOrchard);

        emit StrategyBalancerUpdatedParams(_balancerVault, _uniswapRouter, _balancerPoolId1, _balancerPoolId2, _merkleOrchard);
    }

    function setClaimingParams(
        address _distributorBal,
        address _distributorWMatic,
        address _distributorTUsd,
        uint256 _distributionIdBal,
        uint256 _distributionIdWMatic,
        uint256 _distributionIdTUsd,
        uint256 _claimedBalanceBal,
        uint256 _claimedBalanceWMatic,
        uint256 _claimedBalanceTUsd,
        bytes32[] memory _merkleProofBal,
        bytes32[] memory _merkleProofWMatic,
        bytes32[] memory _merkleProofTUsd
    ) external onlyAdmin {

        distributorBal = _distributorBal;
        distributorWMatic = _distributorWMatic;
        distributorTUsd = _distributorTUsd;
        distributionIdBal = _distributionIdBal;
        distributionIdWMatic = _distributionIdWMatic;
        distributionIdTUsd = _distributionIdTUsd;
        claimedBalanceBal = _claimedBalanceBal;
        claimedBalanceWMatic = _claimedBalanceWMatic;
        claimedBalanceTUsd = _claimedBalanceTUsd;
        merkleProofBal = _merkleProofBal;
        merkleProofWMatic = _merkleProofWMatic;
        merkleProofTUsd = _merkleProofTUsd;

        emit StrategyBalancerClaimingParamsUpdated(
            _distributorBal, _distributorWMatic, _distributorTUsd,
            _distributionIdBal, _distributionIdWMatic, _distributionIdTUsd,
            _claimedBalanceBal, _claimedBalanceWMatic, _claimedBalanceTUsd,
            _merkleProofBal, _merkleProofWMatic, _merkleProofTUsd);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        usdcToken.approve(address(balancerVault), _amount);

        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(balancerPoolId1);

        IAsset[] memory assets = new IAsset[](4);
        uint256[] memory maxAmountsIn = new uint256[](4);
        uint256[] memory amountsIn = new uint256[](4);
        for (uint256 i; i < tokens.length; i++) {
            assets[i] = IAsset(address(tokens[i]));
            if (tokens[i] == usdcToken) {
                maxAmountsIn[i] = _amount;
                amountsIn[i] = _amount;
            } else {
                maxAmountsIn[i] = 0;
                amountsIn[i] = 0;
            }
        }

        uint256 joinKind = 1;
        uint256 minimumBPT = 0;
        bytes memory userData = abi.encode(joinKind, amountsIn, minimumBPT);

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(assets, maxAmountsIn, userData, false);

        balancerVault.joinPool(balancerPoolId1, address(this), address(this), request);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(balancerPoolId1);

        IAsset[] memory assets = new IAsset[](4);
        uint256[] memory minAmountsOut = new uint256[](4);
        for (uint256 i; i < tokens.length; i++) {
            assets[i] = IAsset(address(tokens[i]));
            if (tokens[i] == usdcToken) {
                //TODO: Balancer. FIX if big slippage
                minAmountsOut[i] = _amount * 99 / 100;
            } else {
                minAmountsOut[i] = 0;
            }
        }

        uint256 exitKind = 0;
        uint256 exitTokenIndex = 0;
        // 18 = 18 + 6 - 6
        uint256 amountBpspTUsd = bpspTUsdTokenDenominator * _amount / _getBpspTUsdSellPrice(bpspTUsdTokenDenominator);
        bytes memory userData = abi.encode(exitKind, amountBpspTUsd, exitTokenIndex);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(assets, minAmountsOut, userData, false);

        balancerVault.exitPool(balancerPoolId1, address(this), payable(address(this)), request);

        return usdcToken.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 amountBpspTUsd = bpspTUsdToken.balanceOf(address(this));
        uint256 amountUsdc = _getBpspTUsdSellPrice(amountBpspTUsd);

        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(balancerPoolId1);

        IAsset[] memory assets = new IAsset[](4);
        uint256[] memory minAmountsOut = new uint256[](4);
        for (uint256 i; i < tokens.length; i++) {
            assets[i] = IAsset(address(tokens[i]));
            if (tokens[i] == usdcToken) {
                //TODO: Balancer. FIX if big slippage
                minAmountsOut[i] = amountUsdc * 99 / 100;
            } else {
                minAmountsOut[i] = 0;
            }
        }

        uint256 exitKind = 0;
        uint256 exitTokenIndex = 0;
        bytes memory userData = abi.encode(exitKind, amountBpspTUsd, exitTokenIndex);

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(assets, minAmountsOut, userData, false);

        balancerVault.exitPool(balancerPoolId1, address(this), payable(address(this)), request);

        return usdcToken.balanceOf(address(this));
    }

    function netAssetValue() external override view returns (uint256) {
        uint256 balance = bpspTUsdToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        return _getBpspTUsdBuyPrice(balance);
    }

    function liquidationValue() external override view returns (uint256) {
        uint256 balance = bpspTUsdToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        return _getBpspTUsdSellPrice(balance);
    }

    function _getBpspTUsdBuyPrice(uint256 balanceBpspTUsd) internal view returns (uint256) {
        uint256 totalSupply = bpspTUsdToken.totalSupply();

        uint256 totalBalanceUsdc;
        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(balancerPoolId1);
        for (uint256 i; i < tokens.length; i++) {
            uint256 tokenBalance = balances[i] * balanceBpspTUsd / totalSupply;
            if (tokens[i] != usdcToken) {
                totalBalanceUsdc += onSwap(balancerPoolId1, IVault.SwapKind.GIVEN_OUT, usdcToken, tokens[i], tokenBalance);
            } else {
                totalBalanceUsdc += tokenBalance;
            }
        }

        return totalBalanceUsdc;
    }

    function _getBpspTUsdSellPrice(uint256 balanceBpspTUsd) internal view returns (uint256) {
        uint256 totalSupply = bpspTUsdToken.totalSupply();

        uint256 totalBalanceUsdc;
        (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock) = balancerVault.getPoolTokens(balancerPoolId1);
        for (uint256 i; i < tokens.length; i++) {
            uint256 tokenBalance = balances[i] * balanceBpspTUsd / totalSupply;
            if (tokens[i] != usdcToken) {
                totalBalanceUsdc += onSwap(balancerPoolId1, IVault.SwapKind.GIVEN_IN, tokens[i], usdcToken, tokenBalance);
            } else {
                totalBalanceUsdc += tokenBalance;
            }
        }

        return totalBalanceUsdc;
    }

    //TODO: Make call once week. Maybe make call with setting new params for claiming
    function _claimRewards(address _to) internal override returns (uint256) {

        _claimRewardsBalancer();

        uint256 totalUsdc;

        uint256 balBalance = balToken.balanceOf(address(this));
        if (balBalance > 0) {
            uint256 balUsdc = swap(balancerPoolId2, IVault.SwapKind.GIVEN_IN, IAsset(address(balToken)),
                IAsset(address(usdcToken)), address(this), address(this), balBalance);
            totalUsdc += balUsdc;
        }

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance > 0) {
            uint256 wmaticUsdc = swap(balancerPoolId2, IVault.SwapKind.GIVEN_IN, IAsset(address(wmaticToken)),
                IAsset(address(usdcToken)), address(this), address(this), wmaticBalance);
            totalUsdc += wmaticUsdc;
        }

        uint256 tusdBalance = tusdToken.balanceOf(address(this));
        if (tusdBalance > 0) {
            uint256 tusdUsdc = swap(balancerPoolId1, IVault.SwapKind.GIVEN_IN, IAsset(address(tusdToken)),
                IAsset(address(usdcToken)), address(this), address(this), tusdBalance);
            totalUsdc += tusdUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));

        return totalUsdc;
    }

    function _claimRewardsBalancer() internal {

        uint8 size;
        if (claimedBalanceBal > 0) {
            size++;
        }
        if (claimedBalanceWMatic > 0) {
            size++;
        }
        if (claimedBalanceTUsd > 0) {
            size++;
        }

        if (size == 0) {
            return;
        }

        uint8 i;
        MerkleOrchard.Claim[] memory claims = new MerkleOrchard.Claim[](size);
        IERC20[] memory tokens = new IERC20[](size);

        if (claimedBalanceBal > 0) {
            MerkleOrchard.Claim memory claimBal = MerkleOrchard.Claim(
                distributionIdBal,
                claimedBalanceBal,
                distributorBal,
                i,
                merkleProofBal);
            claims[i] = claimBal;
            tokens[i] = balToken;
            i++;
        }

        if (claimedBalanceWMatic > 0) {
            MerkleOrchard.Claim memory claimWMatic = MerkleOrchard.Claim(
                distributionIdWMatic,
                claimedBalanceWMatic,
                distributorWMatic,
                i,
                merkleProofWMatic);
            claims[i] = claimWMatic;
            tokens[i] = wmaticToken;
            i++;
        }

        if (claimedBalanceTUsd > 0) {
            MerkleOrchard.Claim memory claimTUsd = MerkleOrchard.Claim(
                distributionIdTUsd,
                claimedBalanceTUsd,
                distributorTUsd,
                i,
                merkleProofTUsd);
            claims[i] = claimTUsd;
            tokens[i] = tusdToken;
        }

        merkleOrchard.claimDistributions(address(this), claims, tokens);

        // set 0 for not spamming claiming
        claimedBalanceBal = 0;
        claimedBalanceWMatic = 0;
        claimedBalanceTUsd = 0;

    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MerkleProof.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IDistributorCallback.sol";

pragma solidity >=0.8.0 <0.9.0;

contract MerkleOrchard {
    using SafeERC20 for IERC20;

    // Recorded distributions
    // channelId > distributionId
    mapping(bytes32 => uint256) private _nextDistributionId;
    // channelId > distributionId > root
    mapping(bytes32 => mapping(uint256 => bytes32)) private _distributionRoot;
    // channelId > claimer > distributionId / 256 (word index) -> bitmap
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256))) private _claimedBitmap;
    // channelId > balance
    mapping(bytes32 => uint256) private _remainingBalance;

    event DistributionAdded(
        address indexed distributor,
        IERC20 indexed token,
        uint256 distributionId,
        bytes32 merkleRoot,
        uint256 amount
    );
    event DistributionClaimed(
        address indexed distributor,
        IERC20 indexed token,
        uint256 distributionId,
        address indexed claimer,
        address recipient,
        uint256 amount
    );

    IVault private immutable _vault;

    constructor(IVault vault) {
        _vault = vault;
    }

    struct Claim {
        uint256 distributionId;
        uint256 balance;
        address distributor;
        uint256 tokenIndex;
        bytes32[] merkleProof;
    }

    // Getters
    function getVault() public view returns (IVault) {
        return _vault;
    }

    function getDistributionRoot(
        IERC20 token,
        address distributor,
        uint256 distributionId
    ) external view returns (bytes32) {
        bytes32 channelId = _getChannelId(token, distributor);
        return _distributionRoot[channelId][distributionId];
    }

    function getRemainingBalance(IERC20 token, address distributor) external view returns (uint256) {
        bytes32 channelId = _getChannelId(token, distributor);
        return _remainingBalance[channelId];
    }

    /**
     * @notice distribution ids must be sequential and can have an optional offset
     */
    function getNextDistributionId(IERC20 token, address distributor) external view returns (uint256) {
        bytes32 channelId = _getChannelId(token, distributor);
        return _nextDistributionId[channelId];
    }

    function isClaimed(
        IERC20 token,
        address distributor,
        uint256 distributionId,
        address claimer
    ) public view returns (bool) {
        (uint256 distributionWordIndex, uint256 distributionBitIndex) = _getIndices(distributionId);

        bytes32 channelId = _getChannelId(token, distributor);
        return (_claimedBitmap[channelId][claimer][distributionWordIndex] & (1 << distributionBitIndex)) != 0;
    }

    function verifyClaim(
        IERC20 token,
        address distributor,
        uint256 distributionId,
        address claimer,
        uint256 claimedBalance,
        bytes32[] memory merkleProof
    ) external view returns (bool) {
        bytes32 channelId = _getChannelId(token, distributor);
        return _verifyClaim(channelId, distributionId, claimer, claimedBalance, merkleProof);
    }

    // Claim functions

    /**
     * @notice Allows anyone to claim multiple distributions for a claimer.
     */
    function claimDistributions(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens
    ) external {
        _processClaims(claimer, claimer, claims, tokens, false);
    }

    /**
     * @notice Allows a user to claim their own multiple distributions to internal balance.
     */
    function claimDistributionsToInternalBalance(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens
    ) external {
        require(msg.sender == claimer, "user must claim own balance");
        _processClaims(claimer, claimer, claims, tokens, true);
    }

    /**
     * @notice Allows a user to claim their own several distributions to a callback.
     */
    function claimDistributionsWithCallback(
        address claimer,
        Claim[] memory claims,
        IERC20[] memory tokens,
        IDistributorCallback callbackContract,
        bytes calldata callbackData
    ) external {
        require(msg.sender == claimer, "user must claim own balance");
        _processClaims(claimer, address(callbackContract), claims, tokens, true);
        callbackContract.distributorCallback(callbackData);
    }

    /**
     * @notice Allows a distributor to add funds to the contract as a merkle tree.
     */
    function createDistribution(
        IERC20 token,
        bytes32 merkleRoot,
        uint256 amount,
        uint256 distributionId
    ) external {
        address distributor = msg.sender;

        bytes32 channelId = _getChannelId(token, distributor);
        require(
            _nextDistributionId[channelId] == distributionId || _nextDistributionId[channelId] == 0,
            "invalid distribution ID"
        );
        token.safeTransferFrom(distributor, address(this), amount);

        token.approve(address(getVault()), amount);
        IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](1);

        ops[0] = IVault.UserBalanceOp({
            asset: IAsset(address(token)),
            amount: amount,
            sender: address(this),
            recipient: payable(address(this)),
            kind: IVault.UserBalanceOpKind.DEPOSIT_INTERNAL
        });

        getVault().manageUserBalance(ops);

        _remainingBalance[channelId] += amount;
        _distributionRoot[channelId][distributionId] = merkleRoot;
        _nextDistributionId[channelId] = distributionId + 1;
        emit DistributionAdded(distributor, token, distributionId, merkleRoot, amount);
    }

    // Helper functions

    function _getChannelId(IERC20 token, address distributor) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, distributor));
    }

    function _processClaims(
        address claimer,
        address recipient,
        Claim[] memory claims,
        IERC20[] memory tokens,
        bool asInternalBalance
    ) internal {
        uint256[] memory amounts = new uint256[](tokens.length);

        // To save gas when setting claimed statuses in storage, we group claims for each channel and word index
        // (referred to as a 'claims set'), aggregating the claim bits to set and total claimed amount, only committing
        // to storage when changing claims sets (or when processing the last claim).
        // This means that callers should sort claims by grouping distribution channels and distributions with the same
        // word index in order to achieve reduced gas costs.

        // Variables to support claims set aggregation
        bytes32 currentChannelId; // Since channel ids are a hash, the initial zero id can be safely considered invalid
        uint256 currentWordIndex;

        uint256 currentBits; // The accumulated claimed bits to set in storage
        uint256 currentClaimAmount; // The accumulated tokens to be claimed from the current channel (not claims set!)

        Claim memory claim;
        for (uint256 i = 0; i < claims.length; i++) {
            claim = claims[i];

            // New scope to avoid stack-too-deep issues
            {
                (uint256 distributionWordIndex, uint256 distributionBitIndex) = _getIndices(claim.distributionId);

                if (currentChannelId == _getChannelId(tokens[claim.tokenIndex], claim.distributor)) {
                    if (currentWordIndex == distributionWordIndex) {
                        // Same claims set as the previous one: simply track the new bit to set.
                        currentBits |= 1 << distributionBitIndex;
                    } else {
                        // This case is an odd exception: the claims set is not the same, but the channel id is. This
                        // happens for example when there are so many distributions that they don't fit in a single 32
                        // byte bitmap.
                        // Since the channel is the same, we can continue accumulating the claim amount, but must commit
                        // the previous claim bits as they correspond to a different word index.
                        _setClaimedBits(currentChannelId, claimer, currentWordIndex, currentBits);

                        // Start a new claims set, except channel id is the same as the previous one, and amount is not
                        // reset.
                        currentWordIndex = distributionWordIndex;
                        currentBits = 1 << distributionBitIndex;
                    }

                    // Amounts are always accumulated for the same channel id
                    currentClaimAmount += claim.balance;
                } else {
                    // Skip initial invalid claims set
                    if (currentChannelId != bytes32(0)) {
                        // Commit previous claims set
                        _setClaimedBits(currentChannelId, claimer, currentWordIndex, currentBits);
                        _deductClaimedBalance(currentChannelId, currentClaimAmount);
                    }

                    // Start a new claims set
                    currentChannelId = _getChannelId(tokens[claim.tokenIndex], claim.distributor);
                    currentWordIndex = distributionWordIndex;
                    currentBits = 1 << distributionBitIndex;
                    currentClaimAmount = claim.balance;
                }
            }

            // Since a claims set is only committed if the next one is not part of the same set, the last claims set
            // must be manually committed always.
            if (i == claims.length - 1) {
                _setClaimedBits(currentChannelId, claimer, currentWordIndex, currentBits);
                _deductClaimedBalance(currentChannelId, currentClaimAmount);
            }

            require(
                _verifyClaim(currentChannelId, claim.distributionId, claimer, claim.balance, claim.merkleProof),
                "incorrect merkle proof"
            );

            // Note that balances to claim are here accumulated *per token*, independent of the distribution channel and
            // claims set accounting.
            amounts[claim.tokenIndex] += claim.balance;

            emit DistributionClaimed(
                claim.distributor,
                tokens[claim.tokenIndex],
                claim.distributionId,
                claimer,
                recipient,
                claim.balance
            );
        }

        IVault.UserBalanceOpKind kind = asInternalBalance
            ? IVault.UserBalanceOpKind.TRANSFER_INTERNAL
            : IVault.UserBalanceOpKind.WITHDRAW_INTERNAL;
        IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            ops[i] = IVault.UserBalanceOp({
                asset: IAsset(address(tokens[i])),
                amount: amounts[i],
                sender: address(this),
                recipient: payable(recipient),
                kind: kind
            });
        }
        getVault().manageUserBalance(ops);
    }

    /**
     * @dev Sets the bits set in `newClaimsBitmap` for the corresponding distribution.
     */
    function _setClaimedBits(
        bytes32 channelId,
        address claimer,
        uint256 wordIndex,
        uint256 newClaimsBitmap
    ) private {
        uint256 currentBitmap = _claimedBitmap[channelId][claimer][wordIndex];

        // All newly set bits must not have been previously set
        require((newClaimsBitmap & currentBitmap) == 0, "cannot claim twice");

        _claimedBitmap[channelId][claimer][wordIndex] = currentBitmap | newClaimsBitmap;
    }

    /**
     * @dev Deducts `balanceBeingClaimed` from a distribution channel's allocation. This isolates tokens accross
     * distribution channels, and prevents claims for one channel from using the tokens of another one.
     */
    function _deductClaimedBalance(bytes32 channelId, uint256 balanceBeingClaimed) private {
        require(
            _remainingBalance[channelId] >= balanceBeingClaimed,
            "distributor hasn't provided sufficient tokens for claim"
        );
        _remainingBalance[channelId] -= balanceBeingClaimed;
    }

    function _verifyClaim(
        bytes32 channelId,
        uint256 distributionId,
        address claimer,
        uint256 claimedBalance,
        bytes32[] memory merkleProof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, claimedBalance));
        return MerkleProof.verify(merkleProof, _distributionRoot[channelId][distributionId], leaf);
    }

    function _getIndices(uint256 distributionId)
        private
        pure
        returns (uint256 distributionWordIndex, uint256 distributionBitIndex)
    {
        distributionWordIndex = distributionId / 256;
        distributionBitIndex = distributionId % 256;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;

interface IDistributorCallback {
    function distributorCallback(bytes calldata callbackData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./exchanges/UniswapV2Exchange.sol";
import "./connectors/idle/interfaces/IIdleToken.sol";

contract StrategyIdle is Strategy, UniswapV2Exchange {

    IERC20 public usdcToken;
    IIdleToken public idleToken;
    IERC20 public wmaticToken;

    uint256 public usdcTokenDenominator;
    uint256 public idleTokenDenominator;
    uint256 public wmaticTokenDenominator;


    // --- events

    event StrategyIdleUpdatedTokens(address usdcToken, address idleToken, address wmaticToken,
        uint256 usdcTokenDenominator, uint256 idleTokenDenominator, uint256 wmaticTokenDenominator);

    event StrategyIdleUpdatedParams(address uniswapRouter);

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _idleToken,
        address _wmaticToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_idleToken != address(0), "Zero address not allowed");
        require(_wmaticToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        idleToken = IIdleToken(_idleToken);
        wmaticToken = IERC20(_wmaticToken);

        usdcTokenDenominator = 10 ** IERC20Metadata(_usdcToken).decimals();
        idleTokenDenominator = 10 ** IERC20Metadata(_idleToken).decimals();
        wmaticTokenDenominator = 10 ** IERC20Metadata(_wmaticToken).decimals();

        emit StrategyIdleUpdatedTokens(_usdcToken, _idleToken, _wmaticToken,
            usdcTokenDenominator, idleTokenDenominator, wmaticTokenDenominator);
    }

    function setParams(
        address _uniswapRouter
    ) external onlyAdmin {

        require(_uniswapRouter != address(0), "Zero address not allowed");

        _setUniswapRouter(_uniswapRouter);

        emit StrategyIdleUpdatedParams(_uniswapRouter);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdcToken), "Some token not compatible");

        usdcToken.approve(address(idleToken), _amount);
        uint256 mintedTokens = idleToken.mintIdleToken(_amount, true, address(this));
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        // fee 1% - misinformation
        uint256 fixedAmount = _amount * 101 / 100;

        // 18 = 18 + 6 - 6
        uint256 tokenAmount = idleTokenDenominator * fixedAmount / idleToken.tokenPrice();

        uint256 redeemedTokens = idleToken.redeemIdleToken(tokenAmount);

        return redeemedTokens;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 _amount = idleToken.balanceOf(address(this));

        uint256 redeemedTokens = idleToken.redeemIdleToken(_amount);

        return redeemedTokens;
    }

    function netAssetValue() external override view returns (uint256) {
        uint256 balance = idleToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint256 price = idleToken.tokenPrice();
        // 18 + 6 - 18 = 6
        return balance * price / idleTokenDenominator;
    }

    function liquidationValue() external override view returns (uint256) {
        uint256 balance = idleToken.balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint256 price = idleToken.tokenPrice();
        // 18 + 6 - 18 = 6
        return balance * price / idleTokenDenominator;
    }

    function _claimRewards(address _to) internal override returns (uint256) {
        uint256 totalUsdc;

        uint256 wmaticBalance = wmaticToken.balanceOf(address(this));
        if (wmaticBalance != 0) {
            uint256 wmaticUsdc = _swapExactTokensForTokens(
                address(wmaticToken),
                address(usdcToken),
                wmaticBalance,
                address(this)
            );
            totalUsdc += wmaticUsdc;
        }

        usdcToken.transfer(_to, usdcToken.balanceOf(address(this)));
        return totalUsdc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156.sol";

interface IIdleToken is IERC20 {
    function token() external view returns (address underlying);
    function govTokens(uint256) external view returns (address govToken);
    function userAvgPrices(address) external view returns (uint256 avgPrice);
    function mintIdleToken(uint256 _amount, bool _skipWholeRebalance, address _referral) external returns (uint256 mintedTokens);
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
    function redeemInterestBearingTokens(uint256 _amount) external;
    function rebalance() external returns (bool);
    function tokenPrice() external view returns (uint256 price);
    function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);
    function getAvgAPR() external view returns (uint256 avgApr);
    function getGovTokensAmounts(address _usr) external view returns (uint256[] memory _amounts);
    function flashLoanFee() external view returns (uint256 fee);
    function flashFee(address _token, uint256 _amount) external view returns (uint256);
    function maxFlashLoan(address _token) external view returns (uint256);
    function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _params) external returns (bool);
    function getAllocations() external view returns (uint256[] memory);
    function getGovTokens() external view returns (address[] memory);
    function getAllAvailableTokens() external view returns (address[] memory);
    function getProtocolTokenToGov(address _protocolToken) external view returns (address);
    function tokenPriceWithFee(address user) external view returns (uint256 priceWFee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./core/Strategy.sol";
import "./connectors/aave/v2/ILendingPoolAddressesProvider.sol";
import "./connectors/aave/v2/ILendingPool.sol";

contract StrategyAave is Strategy {

    IERC20 public usdcToken;
    IERC20 public aUsdcToken;

    ILendingPoolAddressesProvider public aaveProvider;


    // --- events

    event StrategyAaveUpdatedTokens(address usdcToken, address aUsdcToken);

    event StrategyAaveUpdatedParams(address aaveProvider);


    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }


    // --- Setters

    function setTokens(
        address _usdcToken,
        address _aUsdcToken
    ) external onlyAdmin {

        require(_usdcToken != address(0), "Zero address not allowed");
        require(_aUsdcToken != address(0), "Zero address not allowed");

        usdcToken = IERC20(_usdcToken);
        aUsdcToken = IERC20(_aUsdcToken);

        emit StrategyAaveUpdatedTokens(_usdcToken, _aUsdcToken);
    }

    function setParams(
        address _aaveProvider
    ) external onlyAdmin {

        require(_aaveProvider != address(0), "Zero address not allowed");

        aaveProvider = ILendingPoolAddressesProvider(_aaveProvider);

        emit StrategyAaveUpdatedParams(_aaveProvider);
    }


    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {
        require(_asset == address(usdcToken), "Some token not compatible");

        ILendingPool pool = ILendingPool(aaveProvider.getLendingPool());
        usdcToken.approve(address(pool), _amount);

        pool.deposit(address(usdcToken), _amount, address(this), 0);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        ILendingPool pool = ILendingPool(aaveProvider.getLendingPool());
        aUsdcToken.approve(address(pool), _amount);

        uint256 withdrawAmount = pool.withdraw(_asset, _amount, address(this));
        return withdrawAmount;
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdcToken), "Some token not compatible");

        uint256 _amount = aUsdcToken.balanceOf(address(this));

        ILendingPool pool = ILendingPool(aaveProvider.getLendingPool());
        aUsdcToken.approve(address(pool), _amount);

        uint256 withdrawAmount = pool.withdraw(_asset, _amount, address(this));

        return withdrawAmount;
    }

    function netAssetValue() external view override returns (uint256) {
        return aUsdcToken.balanceOf(address(this));
    }

    function liquidationValue() external view override returns (uint256) {
        return aUsdcToken.balanceOf(address(this));
    }

    function _claimRewards(address _beneficiary) internal override returns (uint256) {
        return 0;
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >= 0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from './DataTypes.sol';

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
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
   * @param referral The referral code used
   **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
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
     * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

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
     * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

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
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
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

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
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
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
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
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
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
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

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

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
    function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
    function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity  >=0.8.0;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/WadRayMath.sol";

contract RebaseToken is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant EXCHANGER = keccak256("EXCHANGER");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // --- ERC20 fields

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // ---  fields

    uint256 private _totalMint;
    uint256 private _totalBurn;

    uint256 public liquidityIndexChangeTime;
    uint256 public liquidityIndex;
    uint256 public liquidityIndexDenominator;

    EnumerableSet.AddressSet _owners;

    address public exchange;

    // ---  events

    event ExchangerUpdated(address exchanger);
    event LiquidityIndexUpdated(uint256 changeTime, uint256 liquidityIndex);

    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    modifier onlyExchanger() {
        require(hasRole(EXCHANGER, msg.sender), "Caller is not the EXCHANGER");
        _;
    }

    // ---  setters

    function setName(string memory name, string memory symbol) external onlyAdmin {
//        require(name != "", "Empty value");
//        require(_name == "", "Value already initialized");
//
//        require(symbol != "", "Empty value");
//        require(symbol == "", "Value already initialized");

        _name = name;
        _symbol = symbol;

    }

    function setExchanger(address _exchanger) external onlyAdmin {
        if (exchange != address(0)) {
            revokeRole(EXCHANGER, exchange);
        }
        grantRole(EXCHANGER, _exchanger);
        exchange = _exchanger;
        emit ExchangerUpdated(_exchanger);
    }

    function setLiquidityIndex(uint256 _liquidityIndex) external onlyExchanger {
        require(_liquidityIndex > 0, "Zero liquidity index not allowed");
        liquidityIndex = _liquidityIndex;
        liquidityIndexChangeTime = block.timestamp;
        emit LiquidityIndexUpdated(liquidityIndexChangeTime, liquidityIndex);
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Context_init_unchained();

        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // as Ray
        liquidityIndex = 10 ** 27;
        // 1 Ray
        liquidityIndexDenominator = 10 ** 27;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override
    {}


    // ---  logic


    function mint(address _sender, uint256 _amount) external onlyExchanger {
        // up to ray
        uint256 mintAmount = _amount.wadToRay();
        mintAmount = mintAmount.rayDiv(liquidityIndex);
        _mint(_sender, mintAmount);
        _totalMint += mintAmount;
        emit Transfer(address(0), _sender, _amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address _sender, uint256 _amount) external onlyExchanger {
        uint256 burnAmount;
        if (_amount == balanceOf(_sender)) {
            // burn all
            burnAmount = _balances[_sender];
        } else {
            // up to ray
            burnAmount = _amount.wadToRay();
            burnAmount = burnAmount.rayDiv(liquidityIndex);
        }

        _burn(_sender, burnAmount);
        _totalBurn += burnAmount;
        emit Transfer(_sender, address(0), _amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;


        _afterTokenTransfer(account, address(0), amount);
    }



    /**
       * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        _afterTokenTransfer(sender, recipient, amount);
    }


    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 transferAmount;
        if (amount == balanceOf(_msgSender())) {
            // transfer all
            transferAmount = _balances[_msgSender()];
        } else {
            // up to ray
            transferAmount = amount.wadToRay();
            transferAmount = transferAmount.rayDiv(liquidityIndex);
        }

        _transfer(_msgSender(), recipient, transferAmount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        uint256 allowanceRay = _allowance(owner, spender);
        if (allowanceRay > (type(uint256).max / liquidityIndex)) {
            return type(uint256).max;
        }
        allowanceRay = allowanceRay.rayMul(liquidityIndex);

        // ray -> wad
        return allowanceRay.rayToWad();
    }

    /**
    * @dev See {IERC20-allowance}.
     */
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowances[owner][spender];
    }


    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) external override returns (bool){
        uint256 scaledAmount;
        if (amount > (type(uint256).max / liquidityIndex / 10 ** 9)) {
            scaledAmount = type(uint256).max;
        } else {
            // up to ray
            scaledAmount = amount.wadToRay();
            scaledAmount = scaledAmount.rayDiv(liquidityIndex);
        }
        _approve(_msgSender(), spender, scaledAmount);
        return true;
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 transferAmount;
        if (amount == balanceOf(sender)) {
            // transfer all
            transferAmount = _balances[sender];
        } else {
            // up to ray
            transferAmount = amount.wadToRay();
            transferAmount = transferAmount.rayDiv(liquidityIndex);
        }

        _transfer(sender, recipient, transferAmount);

        uint256 currentAllowance = _allowance(sender, _msgSender());
        require(currentAllowance >= transferAmount, "RebaseToken: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - transferAmount);
    }
        emit Transfer(sender, recipient, amount);

        return true;
    }


    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user)
    public
    view
    override
    returns (uint256)
    {
        // stored balance is ray (27)
        uint256 balanceInMapping = _balanceOf(user);
        // ray -> ray
        uint256 balanceRay = balanceInMapping.rayMul(liquidityIndex);
        // ray -> wad
        return balanceRay.rayToWad();
    }

    /**
    * @dev See {IERC20-balanceOf}.
     */
    function _balanceOf(address account) internal view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256) {
        return _balanceOf(user);
    }


    /**
     * @dev calculates the total supply of the specific aToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply() public view override returns (uint256) {
        // stored totalSupply is ray (27)
        uint256 currentSupply = _totalSupply;
        // ray -> ray
        uint256 currentSupplyRay = currentSupply.rayMul(liquidityIndex);
        // ray -> wad
        return currentSupplyRay.rayToWad();
    }

    function totalMint() external view returns (uint256) {
        uint256 totalMintRay = _totalMint.rayMul(liquidityIndex);
        return totalMintRay.rayToWad();
    }

    function totalBurn() external view returns (uint256) {
        uint256 totalBurnRay = _totalBurn.rayMul(liquidityIndex);
        return totalBurnRay.rayToWad();
    }



    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        // up to ray
        uint256 scaledAmount = addedValue.wadToRay();
        scaledAmount = scaledAmount.rayDiv(liquidityIndex);
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + scaledAmount);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 scaledAmount;
        if (subtractedValue == allowance(_msgSender(), spender)) {
            // transfer all
            scaledAmount = _allowances[_msgSender()][spender];
        } else {
            // up to ray
            scaledAmount = subtractedValue.wadToRay();
            scaledAmount = scaledAmount.rayDiv(liquidityIndex);
        }

        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= scaledAmount, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - scaledAmount);
    }

        return true;
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token
     * @return the scaled total supply
     **/
    function scaledTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function ownerLength() external view returns (uint256) {
        return _owners.length();
    }

    function ownerAt(uint256 index) external view returns (address) {
        return _owners.at(index);
    }

    function ownerBalanceAt(uint256 index) external view returns (uint256) {
        return balanceOf(_owners.at(index));
    }

    /**
   * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }


    /**
   * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }


    /**
    * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {

    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {

        if (from == address(0)) {
            // mint
            _owners.add(to);
        } else if (to == address(0)) {
            // burn
            if (balanceOf(from) == 0) {
                _owners.remove(from);
            }
        } else {
            // transfer
            if (balanceOf(from) == 0) {
                _owners.remove(from);
            }
            _owners.add(to);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}