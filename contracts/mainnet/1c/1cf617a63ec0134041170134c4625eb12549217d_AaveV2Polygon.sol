// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AaveV2Polygon
 *
 * @author Fujidao Labs
 *
 * @notice This contract allows interaction with AaveV2.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";
import {IV2Pool} from "../../interfaces/aaveV2/IV2Pool.sol";

contract AaveV2Polygon is ILendingProvider {
  /**
   * @dev Returns the {IV2Pool} pool to interact with AaveV2
   */
  function _getPool() internal pure returns (IV2Pool) {
    return IV2Pool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
  }

  /// @inheritdoc ILendingProvider
  function providerName() public pure override returns (string memory) {
    return "Aave_V2";
  }

  /// @inheritdoc ILendingProvider
  function approvedOperator(
    address,
    address,
    address
  )
    external
    pure
    override
    returns (address operator)
  {
    operator = address(_getPool());
  }

  /// @inheritdoc ILendingProvider
  function deposit(uint256 amount, IVault vault) external override returns (bool success) {
    IV2Pool aave = _getPool();
    aave.deposit(vault.asset(), amount, address(vault), 0);
    // aave.setUserUseReserveAsCollateral(asset, true);
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function borrow(uint256 amount, IVault vault) external override returns (bool success) {
    IV2Pool aave = _getPool();
    aave.borrow(vault.debtAsset(), amount, 2, 0, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function withdraw(uint256 amount, IVault vault) external override returns (bool success) {
    IV2Pool aave = _getPool();
    aave.withdraw(vault.asset(), amount, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function payback(uint256 amount, IVault vault) external override returns (bool success) {
    IV2Pool aave = _getPool();
    aave.repay(vault.debtAsset(), amount, 2, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function getDepositRateFor(IVault vault) external view override returns (uint256 rate) {
    IV2Pool aaveData = _getPool();
    IV2Pool.ReserveData memory rdata = aaveData.getReserveData(vault.asset());
    rate = rdata.currentLiquidityRate;
  }

  /// @inheritdoc ILendingProvider
  function getBorrowRateFor(IVault vault) external view override returns (uint256 rate) {
    IV2Pool aaveData = _getPool();
    IV2Pool.ReserveData memory rdata = aaveData.getReserveData(vault.debtAsset());
    rate = rdata.currentVariableBorrowRate;
  }

  /// @inheritdoc ILendingProvider
  function getDepositBalance(
    address user,
    IVault vault
  )
    external
    view
    override
    returns (uint256 balance)
  {
    IV2Pool aaveData = _getPool();
    IV2Pool.ReserveData memory rdata = aaveData.getReserveData(vault.asset());
    balance = IERC20(rdata.aTokenAddress).balanceOf(user);
  }

  /// @inheritdoc ILendingProvider
  function getBorrowBalance(
    address user,
    IVault vault
  )
    external
    view
    override
    returns (uint256 balance)
  {
    IV2Pool aaveData = _getPool();
    IV2Pool.ReserveData memory rdata = aaveData.getReserveData(vault.debtAsset());
    balance = IERC20(rdata.variableDebtTokenAddress).balanceOf(user);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for vaults extending from IERC4326.
 */

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {IFujiOracle} from "./IFujiOracle.sol";

interface IVault is IERC4626 {
  /**
   * @dev Emit when borrow action occurs.
   *
   * @param sender who calls {IVault-borrow}
   * @param receiver of the borrowed 'debt' amount
   * @param owner who will incur the debt
   * @param debt amount
   * @param shares amount of 'debtShares' received
   */
  event Borrow(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 debt,
    uint256 shares
  );

  /**
   * @dev Emit when payback action occurs.
   *
   * @param sender address who calls {IVault-payback}
   * @param owner address whose debt will be reduced
   * @param debt amount
   * @param shares amound of 'debtShares' burned
   */
  event Payback(address indexed sender, address indexed owner, uint256 debt, uint256 shares);

  /**
   * @dev Emit when the vault is initialized
   *
   * @param initializer of this vault
   *
   */
  event VaultInitialized(address initializer);

  /**
   * @dev Emit when the oracle address is changed.
   *
   * @param newOracle the new oracle address
   */
  event OracleChanged(IFujiOracle newOracle);

  /**
   * @dev Emit when the available providers for the vault change.
   *
   * @param newProviders the new providers available
   */
  event ProvidersChanged(ILendingProvider[] newProviders);

  /**
   * @dev Emit when the active provider is changed.
   *
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(ILendingProvider newActiveProvider);

  /**
   * @dev Emit when the vault is rebalanced.
   *
   * @param assets amount to be rebalanced
   * @param debt amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assets, uint256 debt, address indexed from, address indexed to);

  /**
   * @dev Emit when the max LTV is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newMaxLtv the new max LTV
   */
  event MaxLtvChanged(uint256 newMaxLtv);

  /**
   * @dev Emit when the liquidation ratio is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newLiqRatio the new liquidation ratio
   */
  event LiqRatioChanged(uint256 newLiqRatio);

  /**
   * @dev Emit when the minumum amount is changed.
   *
   * @param newMinAmount the new minimum amount
   */
  event MinAmountChanged(uint256 newMinAmount);

  /**
   * @dev Emit when the deposit cap is changed.
   *
   * @param newDepositCap the new deposit cap of this vault
   */
  event DepositCapChanged(uint256 newDepositCap);

  /*///////////////////////////
    Asset management functions
  //////////////////////////*/

  /**
   * @notice Returns the amount of assets owned by `owner`.
   *
   * @param owner to check balance
   *
   * @dev This method avoids having to do external conversions from shares to
   * assets, since {IERC4626-balanceOf} returns shares.
   */
  function balanceOfAsset(address owner) external view returns (uint256 assets);

  /*///////////////////////////
    Debt management functions
  //////////////////////////*/

  /**
   * @notice Returns the decimals for 'debtAsset' of this vault.
   *
   * @dev Requirements:
   * - Must match the 'debtAsset' decimals in ERC20 token.
   * - Must return zero in a {YieldVault}.
   */
  function debtDecimals() external view returns (uint8);

  /**
   * @notice Returns the address of the underlying token used as debt in functions
   * `borrow()`, and `payback()`. Based on {IERC4626-asset}.
   *
   * @dev Requirements:
   * - Must be an ERC-20 token contract.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function debtAsset() external view returns (address);

  /**
   * @notice Returns the amount of debt owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebt(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebtShares(address owner) external view returns (uint256 debtShares);

  /**
   * @notice Returns the total amount of the underlying debt asset
   * that is “managed” by this vault. Based on {IERC4626-totalAssets}.
   *
   * @dev Requirements:
   * - Must account for any compounding occuring from yield or interest accrual.
   * - Must be inclusive of any fees that are charged against assets in the Vault.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function totalDebt() external view returns (uint256);

  /**
   * @notice Returns the amount of shares this vault would exchange for the amount
   * of debt assets provided. Based on {IERC4626-convertToShares}.
   *
   * @param debt to convert into `debtShares`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead Must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertDebtToShares(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt assets that this vault would exchange for the amount
   * of shares provided. Based on {IERC4626-convertToAssets}.
   *
   * @param shares amount to convert into `debt`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertToDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of the debt asset that can be borrowed for the `owner`,
   * through a borrow call.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must return a limited value if receiver is subject to some borrow limit.
   * - Must return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be borrowed.
   * - Must not revert.
   */
  function maxBorrow(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of debt that can be payback by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxPayback(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of debt shares that can be "minted-for-borrowing" by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxMintDebt(address owner) external view returns (uint256 shares);

  /**
   * @notice Returns the maximum amount of debt shares that can be "burned-for-payback" by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxBurnDebt(address owner) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of `debtShares` that borrowing `debt` amount will generate.
   *
   * @param debt amount to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewBorrow(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt that borrowing `debtShares` amount will generate.
   *
   * @param shares of debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewMintDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` that will be burned by paying back
   * `debt` amount.
   *
   * @param debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewPayback(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt asset that will be pulled from user, if `debtShares` are
   * burned to payback.
   *
   * @param debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewBurnDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Perform a borrow action. Function inspired on {IERC4626-deposit}.
   *
   * @param debt amount
   * @param receiver of the `debt` amount
   * @param owner who will incur the `debt` amount
   *
   * * @dev Mints debtShares to owner by taking a loan of exact amount of underlying tokens.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256 shares);

  /**
   * @notice Perform a borrow action by minting `debtShares`.
   *
   * @param shares of debt to mint
   * @param receiver of the borrowed amount
   * @param owner who will incur the `debt` and whom `debtShares` will be accounted
   *
   * * @dev Mints `debtShares` to `owner`.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function mintDebt(
    uint256 shares,
    address receiver,
    address owner
  )
    external
    returns (uint256 debt);

  /**
   * @notice Burns `debtShares` to `receiver` by paying back loan with exact amount of underlying tokens.
   *
   * @param debt amount to payback
   * @param receiver to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying debt token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function payback(uint256 debt, address receiver) external returns (uint256 shares);

  /**
   * @notice Burns `debtShares` to `owner` by paying back loan by specifying debt shares.
   *
   * @param shares of debt to payback
   * @param owner to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying debt token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function burnDebt(uint256 shares, address owner) external returns (uint256 debt);

  /*///////////////////
    General functions
  ///////////////////*/

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (ILendingProvider);

  /*/////////////////////////
     Rebalancing Function
  ////////////////////////*/

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   *
   * @param assets amount of this vault to be rebalanced
   * @param debt amount of this vault to be rebalanced (Note: pass zero if this is a {YieldVault})
   * @param from provider
   * @param to provider
   * @param fee expected from rebalancing operation
   * @param setToAsActiveProvider boolean
   *
   * @dev Requirements:
   * - Must check providers `from` and `to` are valid.
   * - Must be called from a {RebalancerManager} contract that makes all proper checks.
   * - Must revert if caller is not an approved rebalancer.
   * - Must emit the VaultRebalance event.
   * - Must check `fee` is a reasonable amount.
   */
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool);

  /*/////////////////////////
     Liquidation Functions
  /////////////////////////*/

  /**
   * @notice Returns the current health factor of 'owner'.
   *
   * @param owner to get health factor
   *
   * @dev Requirements:
   * - Must return type(uint254).max when 'owner' has no debt.
   * - Must revert in {YieldVault}.
   *
   * 'healthFactor' is scaled up by 1e18. A value below 1e18 means 'owner' is eligable for liquidation.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   */
  function getHealthFactor(address owner) external returns (uint256 healthFactor);

  /**
   * @notice Returns the liquidation close factor based on 'owner's' health factor.
   *
   * @param owner of debt position
   *
   * @dev Requirements:
   * - Must return zero if `owner` is not liquidatable.
   * - Must revert in {YieldVault}.
   */
  function getLiquidationFactor(address owner) external returns (uint256 liquidationFactor);

  /**
   * @notice Performs liquidation of an unhealthy position, meaning a 'healthFactor' below 100.
   *
   * @param owner to be liquidated
   * @param receiver of the collateral shares of liquidation
   *
   * @dev Requirements:
   * - Must revert if caller is not an approved liquidator.
   * - Must revert if 'owner' is not liquidatable.
   * - Must emit the Liquidation event.
   * - Must liquidate 50% of 'owner' debt when: 100 >= 'healthFactor' > 95.
   * - Must liquidate 100% of 'owner' debt when: 95 > 'healthFactor'.
   * - Must revert in {YieldVault}.
   *
   * WARNING! It is liquidator's responsability to check if liquidation is profitable.
   */
  function liquidate(address owner, address receiver) external returns (uint256 gainedShares);

  /*/////////////////////
     Setter functions 
  ////////////////////*/

  /**
   * @notice Sets the lists of providers of this vault.
   *
   * @param providers address array
   *
   * @dev Requirements:
   * - Must not contain zero addresses.
   */
  function setProviders(ILendingProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * @param activeProvider address
   *
   * @dev Requirements:
   * - Must be a provider previously set by `setProviders()`.
   * - Must be called from a timelock contract.
   *
   * WARNING! Changing active provider without a `rebalance()` call
   * can result in denial of service for vault users.
   */
  function setActiveProvider(ILendingProvider activeProvider) external;

  /**
   * @notice Sets the minimum amount for: `deposit()`, `mint()` and borrow()`.
   *
   * @param amount to be as minimum.
   */
  function setMinAmount(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title ILendingProvider
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param keyAsset address to inquiry operator
   * @param asset address of the calling vault
   * @param debtAsset address of the calling vault. Note: if {YieldVault} this will be address(0).
   *
   * @dev Provider implementations may or not require all 3 inputs.
   */
  function approvedOperator(
    address keyAsset,
    address asset,
    address debtAsset
  )
    external
    view
    returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   *
   * @param amount amount to deposit
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   *
   * @param amount amount to borrow
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   *
   * @notice Performs payback operation at lending provider on behalf vault.
   *
   * @param amount amount to payback
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IV2Pool
 *
 * @author Aave
 *
 * @notice Defines the interface for AaveV2 main
 * pool contract.
 */
interface IV2Pool {
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

  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  )
    external;

  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  function deposit(
    address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode
  )
    external;

  function withdraw(address _asset, uint256 _amount, address _to) external;

  function borrow(
    address _asset,
    uint256 _amount,
    uint256 _interestRateMode,
    uint16 _referralCode,
    address _onBehalfOf
  )
    external;

  function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;

  function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;

  function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFujiOracle
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface of the {FujiOracle}.
 */

interface IFujiOracle {
  /**
   * @dev Emit when a change in price feed address is done for an `asset`.
   *
   * @param asset address
   * @param newPriceFeedAddress that returns USD price from Chainlink
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  /**
   * @notice Returns the exchange rate between two assets, with price oracle given in
   * specified `decimals`.
   *
   * @param currencyAsset to be used, zero-address for USD
   * @param commodityAsset to be used, zero-address for USD
   * @param decimals  of the desired price output
   *
   * @dev Price format is defined as: (amount of currencyAsset per unit of commodityAsset Exchange Rate).
   * Requirements:
   * - Must check that both `currencyAsset` and `commodityAsset` are set in
   *   usdPriceFeeds, otherwise return zero.
   */
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256);
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