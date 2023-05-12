// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Restored from 0xcf427e1ac52a2d976b02b83f72baeb905a92e488 (Optimism; events and _xxx were removed)
/// @dev We need sources of Controller, see https://developers.dforce.network/lend/lend-and-synth/deployed-contracts
///      but contract 0x52eaCd19E38D501D006D2023C813d7E37F025f37 doesn't have sources on polygonscan
///      So, the sources were taken from the Optimism (source on Ethereum are exactly the same)
interface IDForceController {
  /**
   * @notice Hook function after iToken `borrow()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being borrewd
     * @param _borrower The account which borrowed iToken
     * @param _borrowedAmount  The amount of underlying being borrowed
     */
  function afterBorrow(
    address _iToken,
    address _borrower,
    uint256 _borrowedAmount
  ) external;

  /**
   * @notice Hook function after iToken `flashloan()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken was flashloaned
     * @param _to The account flashloan transfer to
     * @param _amount  The amount was flashloaned
     */
  function afterFlashloan(
    address _iToken,
    address _to,
    uint256 _amount
  ) external;

  function afterLiquidateBorrow(
    address _iTokenBorrowed,
    address _iTokenCollateral,
    address _liquidator,
    address _borrower,
    uint256 _repaidAmount,
    uint256 _seizedAmount
  ) external;

  function afterMint(
    address _iToken,
    address _minter,
    uint256 _mintAmount,
    uint256 _mintedAmount
  ) external;

  function afterRedeem(
    address _iToken,
    address _redeemer,
    uint256 _redeemAmount,
    uint256 _redeemedUnderlying
  ) external;

  function afterRepayBorrow(
    address _iToken,
    address _payer,
    address _borrower,
    uint256 _repayAmount
  ) external;

  function afterSeize(
    address _iTokenCollateral,
    address _iTokenBorrowed,
    address _liquidator,
    address _borrower,
    uint256 _seizedAmount
  ) external;

  function afterTransfer(
    address _iToken,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  /**
   * @notice Hook function before iToken `borrow()`
     * Checks if the account should be allowed to borrow the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the borrow against
     * @param _borrower The account which would borrow iToken
     * @param _borrowAmount The amount of underlying to borrow
     */
  function beforeBorrow(
    address _iToken,
    address _borrower,
    uint256 _borrowAmount
  ) external;

  function beforeFlashloan(
    address _iToken,
    address _to,
    uint256 _amount
  ) external;

  function beforeLiquidateBorrow(
    address _iTokenBorrowed,
    address _iTokenCollateral,
    address _liquidator,
    address _borrower,
    uint256 _repayAmount
  ) external;

  function beforeMint(
    address _iToken,
    address _minter,
    uint256 _mintAmount
  ) external;

  function beforeRedeem(
    address _iToken,
    address _redeemer,
    uint256 _redeemAmount
  ) external;

  function beforeRepayBorrow(
    address _iToken,
    address _payer,
    address _borrower,
    uint256 _repayAmount
  ) external;

  function beforeSeize(
    address _iTokenCollateral,
    address _iTokenBorrowed,
    address _liquidator,
    address _borrower,
    uint256 _seizeAmount
  ) external;

  function beforeTransfer(
    address _iToken,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  /// @notice return account equity, shortfall, collateral value, borrowed value.
  function calcAccountEquity(address _account)
  external
  view
  returns (
    uint256 accountEquity,
    uint256 shortfall,
    uint256 collateralValue,
    uint256 borrowedValue
  );

  /**
   * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
  function closeFactorMantissa() external view returns (uint256);

  /**
   * @notice Only expect to be called by iToken contract.
     * @dev Add the market to the account's markets list for liquidity calculations
     * @param _account The address of the account to modify
     */
  function enterMarketFromiToken(address _market, address _account) external;

  /**
   * @notice Add markets to `msg.sender`'s markets list for liquidity calculations
     * @param _iTokens The list of addresses of the iToken markets to be entered
     * @return _results Success indicator for whether each corresponding market was entered
     */
  function enterMarkets(address[] memory _iTokens) external returns (bool[] memory _results);

  /**
   * @notice Remove markets from `msg.sender`'s collaterals for liquidity calculations
     * @param _iTokens The list of addresses of the iToken to exit
     * @return _results Success indicators for whether each corresponding market was exited
     */
  function exitMarkets(address[] memory _iTokens) external returns (bool[] memory _results);

  /**
   * @notice Return all of the iTokens
     * @return _alliTokens The list of iToken addresses
     */
  function getAlliTokens() external view returns (address[] memory _alliTokens);

  /**
 * @notice Returns the asset list the account has borrowed
     * @param _account The address of the account to query
     * @return _borrowedAssets The asset list the account has borrowed
     */
  function getBorrowedAssets(address _account) external view returns (address[] memory _borrowedAssets);

  /**
 * @notice Returns the markets list the account has entered
     * @param _account The address of the account to query
     * @return _accountCollaterals The markets list the account has entered
     */
  function getEnteredMarkets(address _account) external view returns (address[] memory _accountCollaterals);

  /**
   * @notice Returns whether the given account has borrowed the given iToken
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has borrowed the iToken, otherwise false.
     */
  function hasBorrowed(address _account, address _iToken) external view returns (bool);

  /**
 * @notice Returns whether the given account has entered the market
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has entered the market, otherwise false.
     */
  function hasEnteredMarket(address _account, address _iToken) external view returns (bool);

  /**
 * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
  function hasiToken(address _iToken) external view returns (bool);
  function initialize() external;
  function isController() external view returns (bool);

  function liquidateCalculateSeizeTokens(
    address _iTokenBorrowed,
    address _iTokenCollateral,
    uint256 _actualRepayAmount
  ) external view returns (uint256 _seizedTokenCollateral);

  function liquidationIncentiveMantissa() external view returns (uint256);

  /// @notice Mapping of iTokens to corresponding markets
  function markets(address)
  external
  view
  returns (
    uint256 collateralFactorMantissa,
    uint256 borrowFactorMantissa,
    uint256 borrowCapacity,
    uint256 supplyCapacity,
    bool mintPaused,
    bool redeemPaused,
    bool borrowPaused
  );

  function owner() external view returns (address);
  function pauseGuardian() external view returns (address);
  function pendingOwner() external view returns (address);

  /**
   * @notice Oracle to query the price of a given asset
     */
  function priceOracle() external view returns (address);
  function rewardDistributor() external view returns (address);

  function seizePaused() external view returns (bool);

  /// @notice whether global transfer is paused
  function transferPaused() external view returns (bool);



  function _setPriceOracle(address _newOracle) external;

  /// @notice Sets the borrowCapacity for a iToken
  function _setBorrowCapacity(address _iToken, uint256 _newBorrowCapacity) external;
  /// @notice Sets the supplyCapacity for a iToken
  function _setSupplyCapacity(address _iToken, uint256 _newSupplyCapacity) external;
  function _setMintPaused(address _iToken, bool _paused) external;
  function _setRedeemPaused(address _iToken, bool _paused) external;
  function _setBorrowPaused(address _iToken, bool _paused) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Restored from 0xcF427E1AC52A2D976B02B83F72BaeB905A92e488 (events and _xxx were removed)
/// @dev it's implementation of iDAI, 0xec85F77104Ffa35a5411750d70eDFf8f1496d95b
///      see https://developers.dforce.network/lend/lend-and-synth/deployed-contracts
interface IDForceCToken {

  /**
   * @dev Block number that interest was last accrued at.
     */
  function accrualBlockNumber() external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address) external view returns (uint256);
  function balanceOfUnderlying(address _account) external returns (uint256);

  /**
   * @dev Caller borrows tokens from the protocol to their own address.
     * @param _borrowAmount The amount of the underlying token to borrow.
     */
  function borrow(uint256 _borrowAmount) external;
  /**
   * @dev Gets the user's borrow balance with the latest `borrowIndex`.
     */
  function borrowBalanceCurrent(address _account) external returns (uint256);
  /**
   * @dev Gets the borrow balance of user without accruing interest.
     */
  function borrowBalanceStored(address _account) external view returns (uint256);
  /**
   * @dev The interest index for borrows of asset as of blockNumber.
     */
  function borrowIndex() external view returns (uint256);
  /**
   * @dev Returns the current per-block borrow interest rate.
     */
  function borrowRatePerBlock() external view returns (uint256);
  /**
   * @dev Gets user borrowing information.
   *      principal, interestIndex
   */
  function borrowSnapshot(address _account) external view returns (uint256 principal, uint256 interestIndex);
  function controller() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  /**
   * @dev Gets the newest exchange rate by accruing interest.
   */
  function exchangeRateCurrent() external returns (uint256);
  /**
   * @dev Calculates the exchange rate without accruing interest.
   */
  function exchangeRateStored() external view returns (uint256);
  /**
   * @notice This ratio is relative to the total flashloan fee.
   * @dev Flash loan fee rate(scaled by 1e18).
   */
  function flashloanFeeRatio() external view returns (uint256);
  /**
   * @dev Get cash balance of this iToken in the underlying token.
   */
  function getCash() external view returns (uint256);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function initialize(
    address _underlyingToken,
    string memory _name,
    string memory _symbol,
    address _controller,
    address _interestRateModel
  ) external;

  /**
   * @dev Current interest rate model contract.
   */
  function interestRateModel() external view returns (address);
  /**
   * @dev Whether this token is supported in the market or not.
   */
  function isSupported() external view returns (bool);
  function isiToken() external pure returns (bool);

  function liquidateBorrow(
    address _borrower,
    uint256 _repayAmount,
    address _cTokenCollateral
  ) external;

  function mint(address _recipient, uint256 _mintAmount) external;
  function mintForSelfAndEnterMarket(uint256 _mintAmount) external;
  function name() external view returns (string memory);
  function nonces(address) external view returns (uint256);
  function owner() external view returns (address);
  function pendingOwner() external view returns (address);

  /// @dev EIP2612 permit function. For more details, please look at here:
  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /**
   * @notice This ratio is relative to the total flashloan fee.
   * @dev Protocol fee rate when a flashloan happens(scaled by 1e18);
   */
  function protocolFeeRatio() external view returns (uint256);

  /**
   * @dev Caller redeems specified iToken from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemiToken The number of iToken to redeem.
     */
  function redeem(address _from, uint256 _redeemiToken) external;

  /**
   * @dev Caller redeems specified underlying from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemUnderlying The number of underlying to redeem.
     */
  function redeemUnderlying(address _from, uint256 _redeemUnderlying) external;

  /**
   * @dev Caller repays their own borrow.
     * @param _repayAmount The amount to repay.
     */
  function repayBorrow(uint256 _repayAmount) external;

  /**
   * @dev Caller repays a borrow belonging to borrower.
     * @param _borrower the account with the debt being payed off.
     * @param _repayAmount The amount to repay.
     */
  function repayBorrowBehalf(address _borrower, uint256 _repayAmount) external;

  /**
   * @dev Interest ratio set aside for reserves(scaled by 1e18).
     */
  function reserveRatio() external view returns (uint256);

  /**
   * @dev Transfers this tokens to the liquidator.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
  function seize(
    address _liquidator,
    address _borrower,
    uint256 _seizeTokens
  ) external;

  /**
   * @dev Returns the current per-block supply interest rate.
     *  Calculates the supply rate:
     *  underlying = totalSupply × exchangeRate
     *  borrowsPer = totalBorrows ÷ underlying
     *  supplyRate = borrowRate × (1-reserveFactor) × borrowsPer
     */
  function supplyRatePerBlock() external view returns (uint256);
  function symbol() external view returns (string memory);

  /**
   * @dev Total amount of this reserve borrowed.
     */
  function totalBorrows() external view returns (uint256);
  function totalBorrowsCurrent() external returns (uint256);

  /**
   * @dev Total amount of this reserves accrued.
     */
  function totalReserves() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address _recipient, uint256 _amount) external returns (bool);

  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool);

  function underlying() external view returns (address);

  /**
   * @notice Calculates interest and update total borrows and reserves.
   * @dev Updates total borrows and reserves with any accumulated interest.
   */
  function updateInterest() external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice Sources: https://github.com/dforce-network/LendingContractsV2
 */
interface IDForceInterestRateModel {
  function isInterestRateModel() external view returns (bool);

  function blocksPerYear() external view returns (uint256);

  /**
   * @dev Calculates the current borrow interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amount of reserves the market has.
     * @return The borrow rate per block (as a percentage, and scaled by 1e18).
     */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @dev Calculates the current supply interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amount of reserves the market has.
     * @param reserveRatio The current reserve factor the market has.
     * @return The supply rate per block (as a percentage, and scaled by 1e18).
     */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveRatio
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Sources: https://github.com/dforce-network/LendingContractsV2
interface IDForcePriceOracle {
  /**
   * @notice Get the underlying price of a iToken asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
  function getUnderlyingPrice(address _iToken)
  external
  view
  returns (uint256);

  /**
   * @notice Get the price of a underlying asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable and whether the price is valid.
     */
  function getUnderlyingPriceAndStatus(address _iToken)
  external
  view
  returns (uint256, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDForceRewardDistributor {

  //-----------------------------------------------------/////////
  // Following functions were taken from LendingContractsV2, IRewardDistributor.sol
  //-----------------------------------------------------/////////
  function _setRewardToken(address newRewardToken) external;
  function _addRecipient(address _iToken, uint256 _distributionFactor) external;
  function _pause() external;
  function _unpause(uint256 _borrowSpeed, uint256 _supplySpeed) external;
  function _setGlobalDistributionSpeeds(uint256 borrowSpeed, uint256 supplySpeed) external;
  function updateDistributionSpeed() external;
  function _setDistributionFactors(address[] calldata iToken, uint256[] calldata distributionFactors) external;
  function updateDistributionState(address _iToken, bool _isBorrow) external;
  function updateReward(address _iToken, address _account, bool _isBorrow) external;
  function updateRewardBatch(address[] memory _holders, address[] memory _iTokens) external;
  function claimReward(address[] memory _holders, address[] memory _iTokens) external;
  function claimAllReward(address[] memory _holders) external;

  //-----------------------------------------------------/////////
  // Following functions were restored from 0x7d25d250fbd63b0dac4a38c661075930c9a87 (optimism)
  // https://optimistic.etherscan.io/address/0x870ac6a76A30742800609F205c741E86Db9b71a2#readProxyContract
  // There are no sources for last implementation, so previous implementation were used
  //-----------------------------------------------------/////////

  /// @notice the Reward distribution borrow state of each iToken
  function distributionBorrowState(address) external view returns (uint256 index, uint256 block_);

  /// @notice the Reward distribution state of each account of each iToken
  function distributionBorrowerIndex(address, address) external view returns (uint256);

  /// @notice the Reward distribution factor of each iToken, 1.0 by default. stored as a mantissa
  function distributionFactorMantissa(address) external view returns (uint256);

  /// @notice the Reward distribution speed of each iToken
  function distributionSpeed(address) external view returns (uint256);

  /// @notice the Reward distribution state of each account of each iToken
  function distributionSupplierIndex(address, address) external view returns (uint256);

  /// @notice the Reward distribution speed supply side of each iToken
  function distributionSupplySpeed(address) external view returns (uint256);

  /// @notice the Reward distribution supply state of each iToken
  function distributionSupplyState(address) external view returns (uint256 index, uint256 block_);

  /// @notice the global Reward distribution speed
  function globalDistributionSpeed() external view returns (uint256);

  /// @notice the global Reward distribution speed for supply
  function globalDistributionSupplySpeed() external view returns (uint256);

  /// @notice the Reward distributed into each account
  function reward(address) external view returns (uint256);

  /// @notice the Reward token address
  function rewardToken() external view returns (address);

  /// @notice whether the reward distribution is paused
  function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Keep and provide addresses of all application contracts
interface IConverterController {
  function governance() external view returns (address);

  // ********************* Health factor explanation  ****************
  // For example, a landing platform has: liquidity threshold = 0.85, LTV=0.8, LTV / LT = 1.0625
  // For collateral $100 we can borrow $80. A liquidation happens if the cost of collateral will reduce below $85.
  // We set min-health-factor = 1.1, target-health-factor = 1.3
  // For collateral 100 we will borrow 100/1.3 = 76.92
  //
  // Collateral value   100        77            assume that collateral value is decreased at 100/77=1.3 times
  // Collateral * LT    85         65.45
  // Borrow value       65.38      65.38         but borrow value is the same as before
  // Health factor      1.3        1.001         liquidation almost happens here (!)
  //
  /// So, if we have target factor 1.3, it means, that if collateral amount will decreases at 1.3 times
  // and the borrow value won't change at the same time, the liquidation happens at that point.
  // Min health factor marks the point at which a rebalancing must be made asap.
  // *****************************************************************

  /// @notice min allowed health factor with decimals 2, must be >= 1e2
  function minHealthFactor2() external view returns (uint16);
  function setMinHealthFactor2(uint16 value_) external;

  /// @notice target health factor with decimals 2
  /// @dev If the health factor is below/above min/max threshold, we need to make repay
  ///      or additional borrow and restore the health factor to the given target value
  function targetHealthFactor2() external view returns (uint16);
  function setTargetHealthFactor2(uint16 value_) external;

  /// @notice max allowed health factor with decimals 2
  /// @dev For future versions, currently max health factor is not used
  function maxHealthFactor2() external view returns (uint16);
  /// @dev For future versions, currently max health factor is not used
  function setMaxHealthFactor2(uint16 value_) external;

  /// @notice get current value of blocks per day. The value is set manually at first and can be auto-updated later
  function blocksPerDay() external view returns (uint);
  /// @notice set value of blocks per day manually and enable/disable auto update of this value
  function setBlocksPerDay(uint blocksPerDay_, bool enableAutoUpdate_) external;
  /// @notice Check if it's time to call updateBlocksPerDay()
  /// @param periodInSeconds_ Period of auto-update in seconds
  function isBlocksPerDayAutoUpdateRequired(uint periodInSeconds_) external view returns (bool);
  /// @notice Recalculate blocksPerDay value
  /// @param periodInSeconds_ Period of auto-update in seconds
  function updateBlocksPerDay(uint periodInSeconds_) external;

  /// @notice 0 - new borrows are allowed, 1 - any new borrows are forbidden
  function paused() external view returns (bool);

  /// @notice the given user is whitelisted and is allowed to make borrow/swap using TetuConverter
  function isWhitelisted(address user_) external view returns (bool);

  /// @notice The size of the gap by which the debt should be increased upon repayment
  ///         Such gaps are required by AAVE pool adapters to workaround dust tokens problem
  ///         and be able to make full repayment.
  /// @dev Debt gap is applied as following: toPay = debt * (DEBT_GAP_DENOMINATOR + debtGap) / DEBT_GAP_DENOMINATOR
  function debtGap() external view returns (uint);

  //-----------------------------------------------------
  //        Core application contracts
  //-----------------------------------------------------

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  //-----------------------------------------------------
  //        External contracts
  //-----------------------------------------------------
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);
  /// @notice Controller of tetu-contracts-v2, that is allowed to update proxy contracts
  function proxyUpdater() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";

/// @notice Adapter for lending platform attached to the given platform's pool.
interface IPlatformAdapter {
  /// @notice Current version of contract
  ///         There is a chance that we will register several versions of the same platform
  ///         at the same time (only last version will be active, others will be frozen)
  function PLATFORM_ADAPTER_VERSION() external view returns (string memory);

  /// @notice Get pool data required to select best lending pool
  /// @param healthFactor2_ Health factor (decimals 2) to be able to calculate max borrow amount
  ///                       See IConverterController for explanation of health factors.
  function getConversionPlan(
    AppDataTypes.InputConversionParams memory params_,
    uint16 healthFactor2_
  ) external view returns (
    AppDataTypes.ConversionPlan memory plan
  );

  /// @notice Full list of supported converters
  function converters() external view returns (address[] memory);

  function platformKind() external pure returns (AppDataTypes.LendingPlatformKinds);

  /// @notice Initialize {poolAdapter_} created from {converter_} using minimal proxy pattern
  function initializePoolAdapter(
    address converter_,
    address poolAdapter_,
    address user_,
    address collateralAsset_,
    address borrowAsset_
  ) external;

  /// @notice True if the platform is frozen and new borrowing is not possible (at this moment)
  function frozen() external view returns (bool);

  /// @notice Set platform to frozen/unfrozen state. In frozen state any new borrowing is forbidden.
  function setFrozen(bool frozen_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Initializer for pool-adapters with AddressProvider
interface IPoolAdapterInitializerWithAP {

  /// @param cTokenAddressProvider_ This is ICTokenAddressProvider
  function initialize(
    address controller_,
    address cTokenAddressProvider_,
    address pool_,
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    address originConverter_
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Compound comptroller doesn't allow to get underlying by cToken,
///      so platform adapter provider provides such function
interface ITokenAddressProvider {
  /// @notice Get cTokens by underlying
  function getCTokenByUnderlying(address token1, address token2)
  external view
  returns (address cToken1, address cToken2);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library AppDataTypes {

  enum LendingPlatformKinds {
    UNKNOWN_0,
    DFORCE_1,
    AAVE2_2,
    AAVE3_3,
    HUNDRED_FINANCE_4,
    COMPOUND3_5
  }

  enum ConversionKind {
    UNKNOWN_0,
    SWAP_1,
    BORROW_2
  }

  /// @notice Input params for BorrowManager.findPool (stack is too deep problem)
  struct InputConversionParams {
    address collateralAsset;
    address borrowAsset;

    /// @notice Encoded entry kind and additional params if necessary (set of params depends on the kind)
    ///         See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
    bytes entryData;

    uint countBlocks;

    /// @notice The meaning depends on entryData kind, see EntryKinds library for details.
    ///         For entry kind = 0: Amount of {sourceToken} to be converted to {targetToken}
    ///         For entry kind = 1: Available amount of {sourceToken}
    ///         For entry kind = 2: Amount of {targetToken} that should be received after conversion
    uint amountIn;
  }

  /// @notice Explain how a given lending pool can make specified conversion
  struct ConversionPlan {
    /// @notice Template adapter contract that implements required strategy.
    address converter;
    /// @notice Current collateral factor [0..1e18], where 1e18 is corresponded to CF=1
    uint liquidationThreshold18;

    /// @notice Amount to borrow in terms of borrow asset
    uint amountToBorrow;
    /// @notice Amount to be used as collateral in terms of collateral asset
    uint collateralAmount;

    /// @notice Cost for the period calculated using borrow rate in terms of borrow tokens, decimals 36
    /// @dev It doesn't take into account supply increment and rewards
    uint borrowCost36;
    /// @notice Potential supply increment after borrow period recalculated to Borrow Token, decimals 36
    uint supplyIncomeInBorrowAsset36;
    /// @notice Potential rewards amount after borrow period in terms of Borrow Tokens, decimals 36
    uint rewardsAmountInBorrowAsset36;
    /// @notice Amount of collateral in terms of borrow asset, decimals 36
    uint amountCollateralInBorrowAsset36;

    /// @notice Loan-to-value, decimals = 18 (wad)
    uint ltv18;
    /// @notice How much borrow asset we can borrow in the pool (in borrow tokens)
    uint maxAmountToBorrow;
    /// @notice How much collateral asset can be supplied (in collateral tokens).
    ///         type(uint).max - unlimited, 0 - no supply is possible
    uint maxAmountToSupply;
  }

  struct PricesAndDecimals {
    /// @notice Price of the collateral asset (decimals same as the decimals of {priceBorrow})
    uint priceCollateral;
    /// @notice Price of the borrow asset (decimals same as the decimals of {priceCollateral})
    uint priceBorrow;
    /// @notice 10**{decimals of the collateral asset}
    uint rc10powDec;
    /// @notice 10**{decimals of the borrow asset}
    uint rb10powDec;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice List of all errors generated by the application
///         Each error should have unique code TC-XXX and descriptive comment
library AppErrors {
  /// @notice Provided address should be not zero
  string public constant ZERO_ADDRESS = "TC-1 zero address";
  /// @notice Pool adapter for the given set {converter, user, collateral, borrowToken} not found and cannot be created
  string public constant POOL_ADAPTER_NOT_FOUND = "TC-2 adapter not found";
  /// @notice Health factor is not set or it's less then min allowed value
  string public constant WRONG_HEALTH_FACTOR = "TC-3 wrong health factor";
  /// @notice Received price is zero
  string public constant ZERO_PRICE = "TC-4 zero price";
  /// @notice Given platform adapter is not found in Borrow Manager
  string public constant PLATFORM_ADAPTER_NOT_FOUND = "TC-6 platform adapter not found";
  /// @notice Only pool adapters are allowed to make such operation
  string public constant POOL_ADAPTER_ONLY = "TC-7 pool adapter not found";
  /// @notice Only TetuConverter is allowed to make such operation
  string public constant TETU_CONVERTER_ONLY = "TC-8 tetu converter only";
  /// @notice Only Governance is allowed to make such operation
  string public constant GOVERNANCE_ONLY = "TC-9 governance only";
  /// @notice Cannot close borrow position if the position has not zero collateral or borrow balance
  string public constant ATTEMPT_TO_CLOSE_NOT_EMPTY_BORROW_POSITION = "TC-10 position not empty";
  /// @notice Borrow position is not registered in DebtMonitor
  string public constant BORROW_POSITION_IS_NOT_REGISTERED = "TC-11 position not registered";
  /// @notice Passed arrays should have same length
  string public constant WRONG_LENGTHS = "TC-12 wrong lengths";
  /// @notice Pool adapter expects some amount of collateral on its balance
  string public constant WRONG_COLLATERAL_BALANCE="TC-13 wrong collateral balance";
  /// @notice Pool adapter expects some amount of derivative tokens on its balance after borrowing
  string public constant WRONG_DERIVATIVE_TOKENS_BALANCE="TC-14 wrong ctokens balance";
  /// @notice Pool adapter expects some amount of borrowed tokens on its balance
  string public constant WRONG_BORROWED_BALANCE = "TC-15 wrong borrow balance";
  /// @notice cToken is not found for provided underlying
  string public constant C_TOKEN_NOT_FOUND = "TC-16 ctoken not found";
  /// @notice cToken.mint failed
  string public constant MINT_FAILED = "TC-17 mint failed";
  string public constant COMPTROLLER_GET_ACCOUNT_LIQUIDITY_FAILED = "TC-18 get account liquidity failed";
  string public constant COMPTROLLER_GET_ACCOUNT_LIQUIDITY_UNDERWATER = "TC-19 get account liquidity underwater";
  /// @notice borrow failed
  string public constant BORROW_FAILED = "TC-20 borrow failed";
  string public constant CTOKEN_GET_ACCOUNT_SNAPSHOT_FAILED = "TC-21 snapshot failed";
  string public constant CTOKEN_GET_ACCOUNT_LIQUIDITY_FAILED = "TC-22 liquidity failed";
  string public constant INCORRECT_RESULT_LIQUIDITY = "TC-23 incorrect liquidity";
  string public constant CLOSE_POSITION_FAILED = "TC-24 close position failed";
  string public constant CONVERTER_NOT_FOUND = "TC-25 converter not found";
  string public constant REDEEM_FAILED = "TC-26 redeem failed";
  string public constant REPAY_FAILED = "TC-27 repay failed";
  /// @notice Balance shouldn't be zero
  string public constant ZERO_BALANCE = "TC-28 zero balance";
  string public constant INCORRECT_VALUE = "TC-29 incorrect value";
  /// @notice Only user can make this action
  string public constant USER_ONLY = "TC-30 user only";
  /// @notice It's not allowed to close position with a pool adapter and make re-conversion using the same adapter
  string public constant RECONVERSION_WITH_SAME_CONVERTER_FORBIDDEN = "TC-31 reconversion forbidden";

  /// @notice Platform adapter cannot be unregistered because there is active pool adapter (open borrow on the platform)
  string public constant PLATFORM_ADAPTER_IS_IN_USE = "TC-33 platform adapter is in use";

  string public constant DIVISION_BY_ZERO = "TC-34 division by zero";

  string public constant UNSUPPORTED_CONVERSION_KIND = "TC-35: UNKNOWN CONVERSION";
  string public constant SLIPPAGE_TOO_BIG = "TC-36: SLIPPAGE TOO BIG";

  /// @notice The relation "platform adapter - converter" is invariant.
  ///         It's not allowed to assign new platform adapter to the converter
  string public constant ONLY_SINGLE_PLATFORM_ADAPTER_CAN_USE_CONVERTER = "TC-37 one platform adapter per conv";

  /// @notice Provided health factor value is not applicable for other health factors
  ///         Invariant: min health factor < target health factor < max health factor
  string public constant WRONG_HEALTH_FACTOR_CONFIG = "TC-38: wrong health factor config";

  /// @notice Health factor is not good after rebalancing
  string public constant WRONG_REBALANCING = "TC-39: wrong rebalancing";

  /// @notice It's not allowed to pay debt completely using repayToRebalance
  ///         Please use ordinal repay for this purpose (it allows to receive the collateral)
  string public constant REPAY_TO_REBALANCE_NOT_ALLOWED = "TC-40 repay to rebalance not allowed";

  /// @notice Received amount is different from expected one
  string public constant WRONG_AMOUNT_RECEIVED = "TC-41 wrong amount received";
  /// @notice Only one of the keepers is allowed to make such operation
  string public constant KEEPER_ONLY = "TC-42 keeper only";

  /// @notice The amount cannot be zero
  string public constant ZERO_AMOUNT = "TC-43 zero amount";

  /// @notice Value of "converter" passed to TetuConverter.borrow is incorrect ( != SwapManager address)
  string public constant INCORRECT_CONVERTER_TO_SWAP = "TC-44 incorrect converter";

  string public constant BORROW_MANAGER_ONLY = "TC-45 borrow manager only";

  /// @notice Attempt to make a borrow using unhealthy pool adapter
  ///         This is not normal situation.
  ///         Health factor is greater 1 but it's less then minimum allowed value.
  ///         Keeper doesn't work?
  string public constant REBALANCING_IS_REQUIRED = "TC-46 rebalancing is required";

  /// @notice Position can be closed as "liquidated" only if there is no collateral on it
  string public constant CANNOT_CLOSE_LIVE_POSITION = "TC-47 cannot close live pos";

  string public constant ACCESS_DENIED = "TC-48 access denied";

  /// @notice Value A is less then B, so we will have overflow on A - B, but it's weird situation
  ///         If balance is decreased after a supply or increased after a deposit
  string public constant WEIRD_OVERFLOW = "TC-49 weird overflow";

  string public constant AMOUNT_TOO_BIG = "TC-50 amount too big";

  string public constant NOT_PENDING_GOVERNANCE = "TC-51 not pending gov";

  string public constant INCORRECT_OPERATION = "TC-52 incorrect op";

  string public constant ONLY_SWAP_MANAGER = "TC-53 swap manager only";

  string public constant TOO_HIGH_PRICE_IMPACT = "TC-54 price impact";

  /// @notice It's not possible to make partial repayment and close the position
  string public constant CLOSE_POSITION_PARTIAL = "TC-55 close position not allowed";
  string public constant ZERO_VALUE_NOT_ALLOWED = "TC-56 zero not allowed";
  string public constant OUT_OF_WHITE_LIST = "TC-57 whitelist";

  string public constant INCORRECT_BORROW_ASSET = "TC-58 incorrect borrow asset";

  string public constant UNSALVAGEABLE = "TC-59: unsalvageable";

  string public constant GELATO_ONLY_OPS = "TC-60: onlyOps";
  string public constant GELATO_ETH_TRANSFER_FAILED = "TC-61: _transfer: ETH transfer failed";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Common utils
library AppUtils {
  /// @notice Convert {amount} with [sourceDecimals} to new amount with {targetDecimals}
  function toMantissa(uint amount, uint8 sourceDecimals, uint8 targetDecimals) internal pure returns (uint) {
    return sourceDecimals == targetDecimals
      ? amount
      : amount * (10 ** targetDecimals) / (10 ** sourceDecimals);
  }

  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /// @notice Remove {itemToRemove} from {items}, move last item of {items} to the position of the removed item
  function removeItemFromArray(address[] storage items, address itemToRemove) internal {
    uint lenItems = items.length;
    for (uint i = 0; i < lenItems; i = uncheckedInc(i)) {
      if (items[i] == itemToRemove) {
        if (i < lenItems - 1) {
          items[i] = items[lenItems - 1];
        }
        items.pop();
        break;
      }
    }
  }

  /// @notice Create new array with only first {countItemsToKeep_} items from {items_} array
  /// @dev We assume, that trivial case countItemsToKeep_ == 0 is excluded, the function is not called in that case
  function removeLastItems(address[] memory items_, uint countItemsToKeep_) internal pure returns (address[] memory) {
    uint lenItems = items_.length;
    if (lenItems <= countItemsToKeep_) {
      return items_;
    }

    address[] memory dest = new address[](countItemsToKeep_);
    for (uint i = 0; i < countItemsToKeep_; i = uncheckedInc(i)) {
      dest[i] = items_[i];
    }

    return dest;
  }

  /// @dev We assume, that trivial case countItemsToKeep_ == 0 is excluded, the function is not called in that case
  function removeLastItems(uint[] memory items_, uint countItemsToKeep_) internal pure returns (uint[] memory) {
    uint lenItems = items_.length;
    if (lenItems <= countItemsToKeep_) {
      return items_;
    }

    uint[] memory dest = new uint[](countItemsToKeep_);
    for (uint i = 0; i < countItemsToKeep_; i = uncheckedInc(i)) {
      dest[i] = items_[i];
    }

    return dest;
  }

  /// @notice (amount1 - amount2) / amount1/2 < expected difference
  function approxEqual(uint amount1, uint amount2, uint divisionMax18) internal pure returns (bool) {
    return amount1 > amount2
      ? (amount1 - amount2) * 1e18 / (amount2 + 1) < divisionMax18
      : (amount2 - amount1) * 1e18 / (amount2 + 1) < divisionMax18;
  }

  /// @notice Reduce size of {aa_}, {bb_}, {cc_}, {dd_} ot {count_} if necessary
  ///         and order all arrays in ascending order of {aa_}
  /// @dev We assume here, that {count_} is rather small (it's a number of available lending platforms) < 10
  function shrinkAndOrder(
    uint count_,
    address[] memory bb_,
    uint[] memory cc_,
    uint[] memory dd_,
    int[] memory aa_
  ) internal pure returns (
    address[] memory bbOut,
    uint[] memory ccOut,
    uint[] memory ddOut,
    int[] memory aaOut
  ) {
    uint[] memory indices = _sortAsc(count_, aa_);

    aaOut = new int[](count_);
    bbOut = new address[](count_);
    ccOut = new uint[](count_);
    ddOut = new uint[](count_);
    for (uint i = 0; i < count_; ++i) {
      aaOut[i] = aa_[indices[i]];
      bbOut[i] = bb_[indices[i]];
      ccOut[i] = cc_[indices[i]];
      ddOut[i] = dd_[indices[i]];
    }
  }

  /// @notice Insertion sorting algorithm for using with arrays fewer than 10 elements, isert in ascending order.
  ///         Take into account only first {length_} items of the {items_} array
  /// @dev Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  /// @return indices Ordered list of indices of the {items_}, size = {length}
  function _sortAsc(uint length_, int[] memory items_) internal pure returns (uint[] memory indices) {
    indices = new uint[](length_);
    unchecked {
      for (uint i; i < length_; ++i) {
        indices[i] = i;
      }

      for (uint i = 1; i < length_; i++) {
        uint key = indices[i];
        uint j = i - 1;
        while ((int(j) >= 0) && items_[indices[j]] > items_[key]) {
          indices[j + 1] = indices[j];
          j--;
        }
        indices[j + 1] = key;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppDataTypes.sol";
import "./AppErrors.sol";

/// @notice Utils and constants related to entryKind param of ITetuConverter.findBorrowStrategy
library EntryKinds {
  /// @notice Amount of collateral is fixed. Amount of borrow should be max possible.
  uint constant public ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0 = 0;

  /// @notice Split provided source amount S on two parts: C1 and C2 (C1 + C2 = S)
  ///         C2 should be used as collateral to make a borrow B.
  ///         Results amounts of C1 and B (both in terms of USD) must be in the given proportion
  uint constant public ENTRY_KIND_EXACT_PROPORTION_1 = 1;

  /// @notice Borrow given amount using min possible collateral
  uint constant public ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2 = 2;


  /// @notice Decode entryData, extract first uint - entry kind
  ///         Valid values of entry kinds are given by ENTRY_KIND_XXX constants above
  function getEntryKind(bytes memory entryData_) internal pure returns (uint) {
    if (entryData_.length == 0) {
      return ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0;
    }
    return abi.decode(entryData_, (uint));
  }

  /// @notice Use {collateralAmount} as a collateral to receive max available {amountToBorrowOut}
  ///         for the given {healthFactor18} and {liquidationThreshold18}
  /// @param collateralAmount Available collateral amount
  /// @param healthFactor18 Required health factor, decimals 18
  /// @param liquidationThreshold18 Liquidation threshold of the selected landing platform, decimals 18
  /// @param priceDecimals36 True if the prices in {pd} have decimals 36 (DForce, HundredFinance)
  ///                        In this case, we can have overloading if collateralAmount is high enough,
  ///                        so we need a special logic to avoid it
  function exactCollateralInForMaxBorrowOut(
    uint collateralAmount,
    uint healthFactor18,
    uint liquidationThreshold18,
    AppDataTypes.PricesAndDecimals memory pd,
    bool priceDecimals36
  ) internal pure returns (
    uint amountToBorrowOut
  ) {
    if (priceDecimals36) {
      amountToBorrowOut =
        1e18 * collateralAmount / healthFactor18
        * (liquidationThreshold18 * pd.priceCollateral / pd.priceBorrow) // avoid overloading
        * pd.rb10powDec
        / 1e18
        / pd.rc10powDec;
    } else {
      amountToBorrowOut =
        1e18 * collateralAmount / healthFactor18
        * liquidationThreshold18 * pd.priceCollateral / pd.priceBorrow
        * pd.rb10powDec
        / 1e18
        / pd.rc10powDec;
    }
  }

  /// @notice Borrow given {borrowAmount} using min possible collateral
  /// @param borrowAmount Required amount to borrow
  /// @param healthFactor18 Required health factor, decimals 18
  /// @param liquidationThreshold18 Liquidation threshold of the selected landing platform, decimals 18
  /// @param priceDecimals36 True if the prices in {pd} have decimals 36 (DForce, HundredFinance)
  ///                        In this case, we can have overloading if collateralAmount is high enough,
  ///                        so we need a special logic to avoid it
  function exactBorrowOutForMinCollateralIn(
    uint borrowAmount,
    uint healthFactor18,
    uint liquidationThreshold18,
    AppDataTypes.PricesAndDecimals memory pd,
    bool priceDecimals36
  ) internal pure returns (
    uint amountToCollateralOut
  ) {
    if (priceDecimals36) {
      amountToCollateralOut = borrowAmount
        * pd.priceBorrow / pd.priceCollateral
        * healthFactor18 / liquidationThreshold18
        * pd.rc10powDec
        / pd.rb10powDec;
    } else {
      amountToCollateralOut = borrowAmount
        * healthFactor18
        * pd.priceBorrow / (liquidationThreshold18 * pd.priceCollateral)
        * pd.rc10powDec
        / pd.rb10powDec;
    }
  }

  /// @notice Split {collateralAmount} on two parts: C1 and {collateralAmountOut}.
  ///         {collateralAmountOut} will be used as collateral to borrow {amountToBorrowOut}.
  ///         Result cost of {amountToBorrowOut} and C1 should be equal or almost equal.
  /// @param collateralAmount Available collateral amount, we should use less amount.
  /// @param healthFactor18 Required health factor, decimals 18
  /// @param liquidationThreshold18 Liquidation threshold of the selected landing platform, decimals 18
  /// @param priceDecimals36 True if the prices in {pd} have decimals 36 (DForce, HundredFinance)
  ///                        In this case, we can have overloading if collateralAmount is high enough,
  ///                        so we need a special logic to avoid it
  /// @param entryData Additional encoded data: required proportions of C1' and {amountToBorrowOut}', X:Y
  ///                  Encoded data: (uint entryKind, uint X, uint Y)
  ///                  X - portion of C1, Y - portion of {amountToBorrowOut}
  ///                  2:1 means, that we will have 2 parts of source asset and 1 part of borrowed asset in result.
  ///                  entryKind must be equal to 1 (== ENTRY_KIND_EQUAL_COLLATERAL_AND_BORROW_OUT_1)
  function exactProportion(
    uint collateralAmount,
    uint healthFactor18,
    uint liquidationThreshold18,
    AppDataTypes.PricesAndDecimals memory pd,
    bytes memory entryData,
    bool priceDecimals36
  ) internal pure returns (
    uint collateralAmountOut,
    uint amountToBorrowOut
  ) {
    collateralAmountOut = getCollateralAmountToConvert(
      entryData,
      collateralAmount,
      healthFactor18,
      liquidationThreshold18
    );
    amountToBorrowOut = exactCollateralInForMaxBorrowOut(
      collateralAmountOut,
      healthFactor18,
      liquidationThreshold18,
      pd,
      priceDecimals36
    );
  }

  /// @notice Split {sourceAmount_} on two parts: C1 and C2. Swap C2 => {targetAmountOut}
  ///         Result cost of {targetAmountOut} and C1 should be equal or almost equal
  function getCollateralAmountToConvert(
    bytes memory entryData,
    uint collateralAmount,
    uint healthFactor18,
    uint liquidationThreshold18
  ) internal pure returns (
    uint collateralAmountOut
  ) {
    // C = C1 + C2, HF = healthFactor18, LT = liquidationThreshold18
    // C' = C1' + C2' where C' is C recalculated to USD
    // C' = C * PC / DC, where PC is price_C, DC = 10**decimals_C
    // Y*B' = X*(C' - C1')*LT/HF ~ C1` => C1' = C' * a / (1 + a), C2' = C' / (1 + a)
    // where a = (X * LT)/(HF * Y)

    (, uint x, uint y) = abi.decode(entryData, (uint, uint, uint));
    require(x != 0 && y != 0, AppErrors.ZERO_VALUE_NOT_ALLOWED);

    uint a = (x * liquidationThreshold18 * 1e18) / (healthFactor18 * y);
    return collateralAmount * 1e18 / (1e18 + a);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../openzeppelin/IERC20Metadata.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/IERC20.sol";
import "../../libs/AppErrors.sol";
import "../../libs/AppUtils.sol";
import "../../libs/AppDataTypes.sol";
import "../../integrations/dforce/IDForceController.sol";
import "../../integrations/dforce/IDForceCToken.sol";
import "../../integrations/dforce/IDForcePriceOracle.sol";
import "../../integrations/dforce/IDForceInterestRateModel.sol";
import "../../integrations/dforce/IDForceRewardDistributor.sol";

/// @notice DForce utils: estimate reward tokens, predict borrow rate in advance
library DForceAprLib {
  address internal constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address internal constant iMATIC = address(0x6A3fE5342a4Bd09efcd44AC5B9387475A0678c74);

  //-----------------------------------------------------
  //                  Data type
  //-----------------------------------------------------
  struct DForceCore {
    IDForceCToken cTokenCollateral;
    IDForceCToken cTokenBorrow;
    IDForceRewardDistributor rd;
  }

  /// @notice Set of input params for borrowRewardAmounts function
  struct DBorrowRewardsInput {
    /// @notice Block where the borrow is made
    uint blockNumber;
    uint amountToBorrow;
    uint accrualBlockNumber;

    uint stateIndex;
    uint stateBlock;
    uint borrowIndex;
    uint distributionSpeed;

    uint totalCash;
    uint totalBorrows;
    uint totalReserves;
    uint reserveFactor;

    address interestRateModel;
  }

  struct RewardsAmountInput {
    uint collateralAmount;
    uint borrowAmount;
    uint countBlocks;
    uint delayBlocks;
    uint priceBorrow36;
    IDForcePriceOracle priceOracle;
  }

  //-----------------------------------------------------
  //                  Addresses
  //-----------------------------------------------------

  /// @notice Get core address of DForce
  function getCore(
    IDForceController comptroller,
    address cTokenCollateral_,
    address cTokenBorrow_
  ) internal view returns (DForceCore memory) {
    return DForceCore({
      cTokenCollateral: IDForceCToken(cTokenCollateral_),
      cTokenBorrow: IDForceCToken(cTokenBorrow_),
      rd: IDForceRewardDistributor(comptroller.rewardDistributor())
    });
  }

  //-----------------------------------------------------
  //                  Estimate APR
  //-----------------------------------------------------

  /// @notice Calculate costs and incomes, take into account all borrow rate, supply rate, borrow and supply tokens.
  /// @return borrowCost36 Estimated borrow APR for the period, borrow tokens, decimals 36
  /// @return supplyIncomeInBorrowAsset36 Current supply APR for the period (in terms of borrow tokens), decimals 36
  /// @return rewardsAmountInBorrowAsset36 Estimated total amount of rewards at the end of the period
  ///         (in terms of borrow tokens), decimals 36
  function getRawCostAndIncomes(
    DForceCore memory core,
    uint collateralAmount_,
    uint countBlocks_,
    uint amountToBorrow_,
    AppDataTypes.PricesAndDecimals memory pad_,
    IDForcePriceOracle priceOracle_
  ) internal view returns (
    uint borrowCost36,
    uint supplyIncomeInBorrowAsset36,
    uint rewardsAmountInBorrowAsset36
  ) {
    // estimate amount of supply+borrow rewards in terms of borrow asset
    (,, rewardsAmountInBorrowAsset36) = getRewardAmountInBorrowAsset(core,
      RewardsAmountInput({
        collateralAmount: collateralAmount_,
        borrowAmount: amountToBorrow_,
        countBlocks: countBlocks_,
        delayBlocks: 1, // we need to estimate rewards inside next (not current) block
        priceBorrow36: pad_.priceBorrow,
        priceOracle: priceOracle_
      })
    );

    {
      supplyIncomeInBorrowAsset36 = getSupplyIncomeInBorrowAsset36(
        getEstimatedSupplyRate(core.cTokenCollateral, collateralAmount_),
        countBlocks_,
        pad_.rc10powDec,
        pad_.priceCollateral,
        pad_.priceBorrow,
        collateralAmount_
      );
    }

    // estimate borrow rate value after the borrow and calculate result APR
    borrowCost36 = getBorrowCost36(
      getEstimatedBorrowRate(
        IDForceInterestRateModel(IDForceCToken(core.cTokenBorrow).interestRateModel()),
        core.cTokenBorrow,
        amountToBorrow_
      ),
      amountToBorrow_,
      countBlocks_,
      pad_.rb10powDec
    );
  }

  /// @notice Calculate supply income in terms of borrow tokens with decimals 36
  function getSupplyIncomeInBorrowAsset36(
    uint supplyRatePerBlock,
    uint countBlocks,
    uint collateral10PowDecimals,
    uint priceCollateral36,
    uint priceBorrow36,
    uint suppliedAmount
  ) internal pure returns (uint) {
    // original code:
    //    rmul(supplyRatePerBlock * countBlocks, suppliedAmount) * priceCollateral / priceBorrow,
    // but we need result decimals 36
    // so, we replace rmul by ordinal mul and take into account /1e18
    return
      supplyRatePerBlock * countBlocks * suppliedAmount * priceCollateral36 / priceBorrow36
      * 1e18 // not 36 because we replaced rmul by mul
      / collateral10PowDecimals;
  }

  /// @notice Calculate borrow APR in terms of borrow tokens with decimals 36
  /// @dev see LendingContractsV2, Base.sol, _updateInterest
  function getBorrowCost36(
    uint borrowRatePerBlock,
    uint borrowedAmount,
    uint countBlocks,
    uint borrow10PowDecimals
  ) internal pure returns (uint) {
    // simpleInterestFactor = borrowRate * blockDelta
    // interestAccumulated = simpleInterestFactor * totalBorrows
    // newTotalBorrows = interestAccumulated + totalBorrows
    uint simpleInterestFactor = borrowRatePerBlock * countBlocks;

    // Replace rmul(simpleInterestFactor, borrowedAmount) by ordinal mul and take into account /1e18
    return
      simpleInterestFactor * borrowedAmount
      * 1e18 // not 36 because we replaced rmul by mul
      / borrow10PowDecimals;
  }

  //-----------------------------------------------------
  //         Estimate borrow rate
  //-----------------------------------------------------

  /// @notice Estimate value of variable borrow rate after borrowing {amountToBorrow_}
  ///         Rewards are not taken into account
  function getEstimatedBorrowRate(
    IDForceInterestRateModel interestRateModel_,
    IDForceCToken cTokenBorrow_,
    uint amountToBorrow_
  ) internal view returns (uint) {
    uint cash = cTokenBorrow_.getCash();
    require(cash >= amountToBorrow_, AppErrors.WEIRD_OVERFLOW);

    return interestRateModel_.getBorrowRate(
      cash - amountToBorrow_,
      cTokenBorrow_.totalBorrows() + amountToBorrow_,
      cTokenBorrow_.totalReserves()
    );
  }

  /// @notice Estimate value of variable borrow rate after borrowing {amountToBorrow_}
  function getBorrowRateAfterBorrow(address borrowCToken_, uint amountToBorrow_) internal view returns (uint) {
    IDForceCToken borrowCToken = IDForceCToken(borrowCToken_);
    return DForceAprLib.getEstimatedBorrowRate(
      IDForceInterestRateModel(borrowCToken.interestRateModel()),
      borrowCToken,
      amountToBorrow_
    );
  }


  //-----------------------------------------------------
  //         Estimate supply rate
  //-----------------------------------------------------

  function getEstimatedSupplyRate(
    IDForceCToken cTokenCollateral_,
    uint amountToSupply_
  ) internal view returns(uint) {
    return getEstimatedSupplyRatePure(
      cTokenCollateral_.totalSupply(),
      amountToSupply_,
      cTokenCollateral_.getCash(),
      cTokenCollateral_.totalBorrows(),
      cTokenCollateral_.totalReserves(),
      IDForceInterestRateModel(cTokenCollateral_.interestRateModel()),
      cTokenCollateral_.reserveRatio(),
      cTokenCollateral_.exchangeRateStored()
    );
  }

  /// @dev repeats LendingContractsV2, iToken.sol, supplyRatePerBlock() impl
  function getEstimatedSupplyRatePure(
    uint totalSupply_,
    uint amountToSupply_,
    uint cash_,
    uint totalBorrows_,
    uint totalReserves_,
    IDForceInterestRateModel interestRateModel_,
    uint reserveRatio_,
    uint currentExchangeRate_
  ) internal view returns(uint) {
    require(reserveRatio_ <= 1e18, AppErrors.AMOUNT_TOO_BIG);

    uint totalSupply = totalSupply_ + amountToSupply_ * 1e18 / currentExchangeRate_;

    uint exchangeRateInternal = getEstimatedExchangeRate(
      totalSupply,
      cash_ + amountToSupply_, // cash is increased exactly on amountToSupply_, no approximation here
      totalBorrows_,
      totalReserves_
    );

    uint underlyingScaled = totalSupply * exchangeRateInternal;
    if (underlyingScaled == 0) {
      return 0;
    }

    uint borrowRatePerBlock = interestRateModel_.getBorrowRate(
      cash_ + amountToSupply_,
      totalBorrows_,
      totalReserves_
    );

    return tmul(
      borrowRatePerBlock,
      1e18 - reserveRatio_,
      rdiv(totalBorrows_ * 1e18, underlyingScaled)
    );
  }

  function getEstimatedExchangeRate(
    uint totalSupply_,
    uint cash_,
    uint totalBorrows_,
    uint totalReserves_
  ) internal pure returns (uint) {
    require(cash_ + totalBorrows_ >= totalReserves_, AppErrors.WEIRD_OVERFLOW);
    return totalSupply_ == 0
      ? 0
      : rdiv(cash_ + totalBorrows_ - totalReserves_, totalSupply_);
  }

  //-----------------------------------------------------
  //       Calculate supply and borrow rewards
  //-----------------------------------------------------

  /// @notice Calculate total amount of rewards (supply rewards + borrow rewards) in terms of borrow asset
  function getRewardAmountInBorrowAsset(
    DForceCore memory core,
    RewardsAmountInput memory p_
  ) internal view returns (
    uint rewardAmountSupply,
    uint rewardAmountBorrow,
    uint totalRewardsInBorrowAsset36
  ) {
    uint distributionSpeed = core.rd.distributionSupplySpeed(address(core.cTokenCollateral));
    if (distributionSpeed != 0) {
      (uint stateIndex, uint stateBlock0) = core.rd.distributionSupplyState(address(core.cTokenCollateral));
      rewardAmountSupply = supplyRewardAmount(
          block.number + p_.delayBlocks,
          stateIndex,
          stateBlock0,
          distributionSpeed,
          core.cTokenCollateral.totalSupply(),
          // actually, after supplying we will have a bit less amount on user's balance
          // because of the supply fee, but we assume that this change can be neglected
          p_.collateralAmount,
          block.number + p_.delayBlocks + p_.countBlocks
      );
    }
    distributionSpeed = core.rd.distributionSpeed(address(core.cTokenBorrow));
    if (distributionSpeed != 0) {
      rewardAmountBorrow = borrowRewardAmount(core,
        p_.borrowAmount,
        distributionSpeed,
        p_.delayBlocks + p_.countBlocks
      );
    }

    if (rewardAmountSupply + rewardAmountBorrow != 0) {
      // EA(x) = ( RA_supply(x) + RA_borrow(x) ) * PriceRewardToken / PriceBorrowUnderlying
      // recalculate the amount from [rewards tokens] to [borrow tokens]
      totalRewardsInBorrowAsset36 = (rewardAmountSupply + rewardAmountBorrow)
        * getPrice(p_.priceOracle, address(core.rd.rewardToken())) // * 10**core.cRewardsToken.decimals()
        * 10**18
        / p_.priceBorrow36
        * 10**18
        // / 10**core.cRewardsToken.decimals()
      ;
    }

    return (rewardAmountSupply, rewardAmountBorrow, totalRewardsInBorrowAsset36);
  }

  /// @notice Calculate amount of supply rewards inside the supply-block
  ///         in assumption that after supply no data will be changed on market
  /// @dev Algo repeats original algo implemented in LendingContractsV2.
  ///      github.com:dforce-network/LendingContractsV2.git
  ///      Same algo is implemented in tests, see DForceHelper.predictRewardsStatePointAfterSupply
  function supplyRewardAmount(
    uint blockSupply_,
    uint stateIndex_,
    uint stateBlock_,
    uint distributionSpeed_,
    uint totalSupply_,
    uint supplyAmount_,
    uint targetBlock_
  ) internal pure returns (uint) {
    // nextStateIndex = stateIndex_ +  distributedPerToken
    uint nextStateIndex = stateIndex_ + rdiv(
      distributionSpeed_ * (
        blockSupply_ > stateBlock_
          ? blockSupply_ - stateBlock_
          : 0
      ),
      totalSupply_
    );

    return getRewardAmount(
      supplyAmount_,
      nextStateIndex,
      distributionSpeed_,
      totalSupply_ + supplyAmount_,
      nextStateIndex,
      targetBlock_ > blockSupply_
        ? targetBlock_ - blockSupply_
        : 0
    );
  }

  /// @notice Take data from DeForce protocol and estimate amount of user's rewards in countBlocks_
  function borrowRewardAmount(
    DForceCore memory core,
    uint borrowAmount_,
    uint distributionSpeed_,
    uint countBlocks_
  ) internal view returns (uint) {
    (uint stateIndex, uint stateBlock) = core.rd.distributionBorrowState(address(core.cTokenBorrow));

    return borrowRewardAmountInternal(
      DBorrowRewardsInput({
        blockNumber: block.number,
        amountToBorrow: borrowAmount_,

        accrualBlockNumber: core.cTokenBorrow.accrualBlockNumber(),

        stateIndex: stateIndex,
        stateBlock: stateBlock,
        borrowIndex: core.cTokenBorrow.borrowIndex(),
        distributionSpeed: distributionSpeed_,

        totalCash: core.cTokenBorrow.getCash(),
        totalBorrows: core.cTokenBorrow.totalBorrows(),
        totalReserves: core.cTokenBorrow.totalReserves(),
        reserveFactor: core.cTokenBorrow.reserveRatio(),

        interestRateModel: core.cTokenBorrow.interestRateModel()
      }), block.number + countBlocks_
    );
  }

  /// @notice Calculate amount of borrow rewards inside the borrow-block
  ///         in assumption that after borrow no data will be changed on market
  /// @dev Algo repeats original algo implemented in LendingContractsV2.
  ///      github.com:dforce-network/LendingContractsV2.git
  ///      Same algo is implemented in tests, see DForceHelper.predictRewardsAfterBorrow
  function borrowRewardAmountInternal(
    DBorrowRewardsInput memory p_,
    uint blockToClaimRewards_
  ) internal view returns (uint rewardAmountBorrow) {
    // borrow block: before borrow
    require(p_.blockNumber >= p_.accrualBlockNumber, AppErrors.WEIRD_OVERFLOW);
    uint simpleInterestFactor = (p_.blockNumber - p_.accrualBlockNumber)
      * IDForceInterestRateModel(p_.interestRateModel).getBorrowRate(
          p_.totalCash,
          p_.totalBorrows,
          p_.totalReserves
        );
    uint interestAccumulated = rmul(simpleInterestFactor, p_.totalBorrows);
    p_.totalBorrows += interestAccumulated; // modify p_.totalBorrows - avoid stack too deep
    uint totalReserves = p_.totalReserves + rmul(interestAccumulated, p_.reserveFactor);
    uint borrowIndex = rmul(simpleInterestFactor, p_.borrowIndex) + p_.borrowIndex;
    uint totalTokens = rdiv(p_.totalBorrows, borrowIndex);
    uint userInterest = borrowIndex;

    // borrow block: after borrow
    uint stateIndex = p_.stateIndex + (
      totalTokens == 0
        ? 0
        : rdiv(p_.distributionSpeed * (
            p_.blockNumber > p_.stateBlock
              ? p_.blockNumber - p_.stateBlock
              : 0
        ), totalTokens)
    );
    p_.totalBorrows += p_.amountToBorrow;

    // target block (where we are going to claim the rewards)
    require(blockToClaimRewards_ >= 1 + p_.blockNumber, AppErrors.WEIRD_OVERFLOW);
    simpleInterestFactor = (blockToClaimRewards_ - 1 - p_.blockNumber)
      * IDForceInterestRateModel(p_.interestRateModel).getBorrowRate(
          p_.totalCash + p_.amountToBorrow,
          p_.totalBorrows,
          totalReserves
        );
    interestAccumulated = rmul(simpleInterestFactor, p_.totalBorrows);
    p_.totalBorrows += interestAccumulated;
    borrowIndex += rmul(simpleInterestFactor, borrowIndex);
    totalTokens = rdiv(p_.totalBorrows, borrowIndex);

    return getRewardAmount(
      rdiv(divup(p_.amountToBorrow * borrowIndex, userInterest), borrowIndex),
      stateIndex,
      p_.distributionSpeed,
      totalTokens,
      stateIndex,
      blockToClaimRewards_ - p_.blockNumber // no overflow, see require above
    );
  }

  //-----------------------------------------------------
  //  Rewards pre-calculations. The algo repeats the code from
  //     LendingContractsV2, RewardsDistributorV3.sol, updateDistributionState, updateReward
  //
  //  RA(x) = rmul(AB, (SI + rdiv(DS * x, TT)) - AI);
  //
  // where:
  //  RA(x) - reward amount
  //  x - count of blocks
  //  AB - account balance (cToken.balance OR rdiv(borrow balance stored, borrow index)
  //  SI - state index (distribution supply state OR distribution borrow state)
  //  DS - distribution speed
  //  TT - total tokens (total supply OR rdiv(total borrow, borrow index)
  //  TD - total distributed = mul(DS, x)
  //  DT - distributed per token = rdiv(TD, TT);
  //  TI - token index, TI = SI + DT = SI + rdiv(DS * x, TT)
  //  AI - account index (distribution supplier index OR distribution borrower index)
  //  rmul(x, y): x * y / 1e18
  //  rdiv(x, y): x * 1e18 / y
  //
  //  Total amount of rewards = RA_supply + RA_borrow
  //
  //  Earned amount EA per block:
  //       EA(x) = ( RA_supply(x) + RA_borrow(x) ) * PriceRewardToken / PriceUnderlying
  //
  //  borrowIndex is calculated according to Base.sol, _updateInterest() algo
  //     simpleInterestFactor = borrowRate * blockDelta
  //     newBorrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
  //-----------------------------------------------------

  function getRewardAmount(
    uint accountBalance_,
    uint stateIndex_,
    uint distributionSpeed_,
    uint totalToken_,
    uint accountIndex_,
    uint countBlocks_
  ) internal pure returns (uint) {
    uint totalDistributed = distributionSpeed_ * countBlocks_;
    uint dt = rdiv(totalDistributed, totalToken_);
    uint ti = stateIndex_ + dt;

    require(ti >= accountIndex_, AppErrors.WEIRD_OVERFLOW);
    return rmul(accountBalance_, ti - accountIndex_);
  }

  //-----------------------------------------------------
  //                 Utils to inline
  //-----------------------------------------------------
  function getPrice(IDForcePriceOracle priceOracle, address token) internal view returns (uint) {
    (uint price, bool isPriceValid) = priceOracle.getUnderlyingPriceAndStatus(token);
    require(price != 0 && isPriceValid, AppErrors.ZERO_PRICE);
    return price;
  }

  function getUnderlying(address token) internal view returns (address) {
    return token == iMATIC
      ? WMATIC
      : IDForceCToken(token).underlying();
  }

  //-----------------------------------------------------
  //  Math utils, see LendingContractsV2, SafeRatioMath.sol
  //-----------------------------------------------------

  function rmul(uint x, uint y) internal pure returns (uint) {
    return x * y / 10**18;
  }

  function rdiv(uint x, uint y) internal pure returns (uint) {
    require(y != 0, AppErrors.DIVISION_BY_ZERO);
    return x * 10**18 / y;
  }

  function divup(uint x, uint y) internal pure returns (uint) {
    require(y != 0, AppErrors.DIVISION_BY_ZERO);
    return (x + y - 1) / y;
  }

  function tmul(uint256 x, uint256 y, uint256 z) internal pure returns (uint256 result) {
    result = x * y * z / 10**36;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./DForceAprLib.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/IERC20Metadata.sol";
import "../../libs/AppDataTypes.sol";
import "../../libs/AppErrors.sol";
import "../../libs/AppUtils.sol";
import "../../libs/EntryKinds.sol";
import "../../interfaces/IPlatformAdapter.sol";
import "../../interfaces/IConverterController.sol";
import "../../interfaces/IPoolAdapterInitializerWithAP.sol";
import "../../interfaces/ITokenAddressProvider.sol";
import "../../integrations/dforce/IDForcePriceOracle.sol";
import "../../integrations/dforce/IDForceInterestRateModel.sol";
import "../../integrations/dforce/IDForceController.sol";
import "../../integrations/dforce/IDForceCToken.sol";

/// @notice Adapter to read current pools info from DForce-protocol, see https://developers.dforce.network/
contract DForcePlatformAdapter is IPlatformAdapter, ITokenAddressProvider {
  using SafeERC20 for IERC20;
  using AppUtils for uint;

  //region ----------------------------------------------------- Constants
  string public constant override PLATFORM_ADAPTER_VERSION = "1.0.2";
  //endregion ----------------------------------------------------- Constants

  //region ----------------------------------------------------- Data types
  /// @notice Local vars inside getConversionPlan - to avoid stack too deep
  struct LocalsGetConversionPlan {
    IDForceController comptroller;
    IDForcePriceOracle priceOracle;
    uint healthFactor18;
    uint entryKind;
  }
  //endregion ----------------------------------------------------- Data types

  //region ----------------------------------------------------- Variables
  IConverterController immutable public controller;
  IDForceController immutable public comptroller;
  /// @notice Template of pool adapter
  address immutable public converter;
  /// @dev Same as controller.borrowManager(); we cache it for gas optimization
  address immutable public borrowManager;

  /// @notice All enabled pairs underlying : cTokens. All assets usable for collateral/to borrow.
  /// @dev There is no underlying for WMATIC, we store iMATIC:WMATIC
  mapping(address => address) public activeAssets;

  /// @notice True if the platform is frozen and new borrowing is not possible (at this moment)
  bool public override frozen;
  //endregion ----------------------------------------------------- Variables

  //region ----------------------------------------------------- Events
  event OnPoolAdapterInitialized(address converter, address poolAdapter, address user, address collateralAsset, address borrowAsset);
  event OnRegisterCTokens(address[] cTokens);
  //endregion ----------------------------------------------------- Events

  //region ----------------------------------------------------- Constructor and initialization
  constructor(address controller_, address borrowManager_, address comptroller_, address templatePoolAdapter_, address[] memory activeCTokens_) {
    require(
      comptroller_ != address(0)
      && borrowManager_ != address(0)
      && templatePoolAdapter_ != address(0)
      && controller_ != address(0),
      AppErrors.ZERO_ADDRESS
    );

    comptroller = IDForceController(comptroller_);
    controller = IConverterController(controller_);
    converter = templatePoolAdapter_;
    borrowManager = borrowManager_;

    _registerCTokens(activeCTokens_);
  }

  /// @notice Initialize {poolAdapter_} created from {converter_} using minimal proxy pattern
  function initializePoolAdapter(address converter_, address poolAdapter_, address user_, address collateralAsset_, address borrowAsset_) external override {
    require(msg.sender == controller.borrowManager(), AppErrors.BORROW_MANAGER_ONLY);
    require(converter == converter_, AppErrors.CONVERTER_NOT_FOUND);

    // HF-pool-adapters support IPoolAdapterInitializer
    IPoolAdapterInitializerWithAP(poolAdapter_).initialize(
      address(controller),
      address(this),
      address(comptroller),
      user_,
      collateralAsset_,
      borrowAsset_,
      converter_
    );

    emit OnPoolAdapterInitialized(converter_, poolAdapter_, user_, collateralAsset_, borrowAsset_);
  }

  /// @notice Set platform to frozen/unfrozen state. In frozen state any new borrowing is forbidden.
  function setFrozen(bool frozen_) external {
    require(msg.sender == controller.governance(), AppErrors.GOVERNANCE_ONLY);
    frozen = frozen_;
  }

  /// @notice Register new CTokens supported by the market
  /// @dev It's possible to add CTokens only because, we can add unregister function if necessary
  function registerCTokens(address[] memory cTokens_) external {
    _onlyGovernance();
    _registerCTokens(cTokens_);
    emit OnRegisterCTokens(cTokens_);
  }

  function _registerCTokens(address[] memory cTokens_) internal {
    uint lenCTokens = cTokens_.length;
    for (uint i = 0; i < lenCTokens; i = i.uncheckedInc()) {
      // Special case: there is no underlying for WMATIC, so we store iMATIC:WMATIC
      activeAssets[DForceAprLib.getUnderlying(cTokens_[i])] = cTokens_[i];
    }
  }
  //endregion ----------------------------------------------------- Constructor and initialization

  //region ----------------------------------------------------- Access

  /// @notice Ensure that the caller is governance
  function _onlyGovernance() internal view {
    require(controller.governance() == msg.sender, AppErrors.GOVERNANCE_ONLY);
  }
  //endregion ----------------------------------------------------- Access

  //region ----------------------------------------------------- View
  function converters() external view override returns (address[] memory) {
    address[] memory dest = new address[](1);
    dest[0] = converter;
    return dest;
  }

  function getCTokenByUnderlying(address token1_, address token2_) external view override returns (
    address cToken1,
    address cToken2
  ) {
    return (activeAssets[token1_], activeAssets[token2_]);
  }

  function platformKind() external pure returns (AppDataTypes.LendingPlatformKinds) {
    return AppDataTypes.LendingPlatformKinds.DFORCE_1;
  }

  //endregion ----------------------------------------------------- View

  //region ----------------------------------------------------- Get conversion plan

  function getConversionPlan(AppDataTypes.InputConversionParams memory p_, uint16 healthFactor2_) external override view returns (
    AppDataTypes.ConversionPlan memory plan
  ) {
    require(p_.collateralAsset != address(0) && p_.borrowAsset != address(0), AppErrors.ZERO_ADDRESS);
    require(p_.amountIn != 0 && p_.countBlocks != 0, AppErrors.INCORRECT_VALUE);
    require(healthFactor2_ >= controller.minHealthFactor2(), AppErrors.WRONG_HEALTH_FACTOR);

    if (! frozen && !controller.paused()) {
      LocalsGetConversionPlan memory vars;
      vars.comptroller = comptroller;
      address cTokenCollateral = activeAssets[p_.collateralAsset];
      if (cTokenCollateral != address(0)) {
        address cTokenBorrow = activeAssets[p_.borrowAsset];
        if (cTokenBorrow != address(0)) {
          (uint collateralFactor, uint supplyCapacity) = _getCollateralMarketData(vars.comptroller, cTokenCollateral);
          if (collateralFactor != 0 && supplyCapacity != 0) {
            (uint borrowFactorMantissa, uint borrowCapacity) = _getBorrowMarketData(vars.comptroller, cTokenBorrow);
            if (borrowFactorMantissa != 0 && borrowCapacity != 0) {
              //------------------------------- Calculate maxAmountToSupply and maxAmountToBorrow
              plan.maxAmountToBorrow = IDForceCToken(cTokenBorrow).getCash();
              // BorrowCapacity: -1 means there is no limit on the capacity
              //                  0 means the asset can not be borrowed any more
              if (borrowCapacity != type(uint).max) { // == uint(-1)
                // we shouldn't exceed borrowCapacity limit, see Controller.beforeBorrow
                uint totalBorrow = IDForceCToken(cTokenBorrow).totalBorrows();
                if (totalBorrow > borrowCapacity) {
                  plan.maxAmountToBorrow = 0;
                } else {
                  if (totalBorrow + plan.maxAmountToBorrow > borrowCapacity) {
                    plan.maxAmountToBorrow = borrowCapacity - totalBorrow;
                  }
                }
              }

              if (supplyCapacity == type(uint).max) { // == uint(-1)
                plan.maxAmountToSupply = type(uint).max;
              } else {
                // we shouldn't exceed supplyCapacity limit, see Controller.beforeMint
                uint totalSupply = IDForceCToken(cTokenCollateral).totalSupply()
                  * IDForceCToken(cTokenCollateral).exchangeRateStored()
                  / 1e18;
                plan.maxAmountToSupply = totalSupply >= supplyCapacity
                  ? 0
                  : supplyCapacity - totalSupply;
              }

              if (plan.maxAmountToSupply != 0 && plan.maxAmountToBorrow != 0) {
                //-------------------------------- LTV and liquidation threshold
                plan.converter = converter;
                plan.liquidationThreshold18 = collateralFactor;
                plan.ltv18 = collateralFactor * borrowFactorMantissa / 10**18;

                //-------------------------------- Prices and health factor
                vars.priceOracle = IDForcePriceOracle(vars.comptroller.priceOracle());

                AppDataTypes.PricesAndDecimals memory pd;
                pd.rc10powDec = 10**IERC20Metadata(p_.collateralAsset).decimals();
                pd.rb10powDec = 10**IERC20Metadata(p_.borrowAsset).decimals();
                pd.priceCollateral = DForceAprLib.getPrice(vars.priceOracle, cTokenCollateral) * pd.rc10powDec;
                pd.priceBorrow = DForceAprLib.getPrice(vars.priceOracle, cTokenBorrow) * pd.rb10powDec;

                // calculate amount that can be borrowed and amount that should be provided as the collateral

                // Protocol has min allowed health factor at the borrow moment: liquidationThreshold18/LTV, i.e. 0.85/0.8=1.06...
                // Target health factor can be smaller but it's not possible to make a borrow with such low health factor
                // see explanation of health factor value in IConverterController.sol
                vars.healthFactor18 = plan.liquidationThreshold18 * 1e18 / plan.ltv18;
                if (vars.healthFactor18 < uint(healthFactor2_) * 10**(18 - 2)) {
                  vars.healthFactor18 = uint(healthFactor2_) * 10**(18 - 2);
                }

                //------------------------------- Calculate collateralAmount and amountToBorrow
                vars.entryKind = EntryKinds.getEntryKind(p_.entryData);
                if (vars.entryKind == EntryKinds.ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0) {
                  plan.collateralAmount = p_.amountIn;
                  plan.amountToBorrow = EntryKinds.exactCollateralInForMaxBorrowOut(
                    p_.amountIn,
                    vars.healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    true // prices have decimals 36
                  );
                } else if (vars.entryKind == EntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
                  (plan.collateralAmount, plan.amountToBorrow) = EntryKinds.exactProportion(
                    p_.amountIn,
                    vars.healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    p_.entryData,
                    true // prices have decimals 36
                  );
                } else if (vars.entryKind == EntryKinds.ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2) {
                  plan.amountToBorrow = p_.amountIn;
                  plan.collateralAmount = EntryKinds.exactBorrowOutForMinCollateralIn(
                    p_.amountIn,
                    vars.healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    true // prices have decimals 36
                  );
                }

                //------------------------------- Validate the borrow
                if (plan.amountToBorrow == 0 || plan.collateralAmount == 0) {
                  plan.converter = address(0);
                } else {
                  // reduce collateral amount and borrow amount proportionally to fit available limits
                  if (plan.collateralAmount > plan.maxAmountToSupply) {
                    plan.amountToBorrow = plan.amountToBorrow * plan.maxAmountToSupply / plan.collateralAmount;
                    plan.collateralAmount = plan.maxAmountToSupply;
                  }

                  if (plan.amountToBorrow > plan.maxAmountToBorrow) {
                    plan.collateralAmount = plan.collateralAmount * plan.maxAmountToBorrow / plan.amountToBorrow;
                    plan.amountToBorrow = plan.maxAmountToBorrow;
                  }

                //------------------------------- values for APR
                  // calculate current borrow rate and predicted APR after borrowing required amount
                  (plan.borrowCost36,
                   plan.supplyIncomeInBorrowAsset36,
                   plan.rewardsAmountInBorrowAsset36
                  ) = DForceAprLib.getRawCostAndIncomes(
                    DForceAprLib.getCore(vars.comptroller, cTokenCollateral, cTokenBorrow),
                    plan.collateralAmount,
                    p_.countBlocks,
                    plan.amountToBorrow,
                    pd,
                    vars.priceOracle
                  );

                  plan.amountCollateralInBorrowAsset36 =
                    plan.collateralAmount * (10**36 * pd.priceCollateral / pd.priceBorrow)
                    / pd.rc10powDec;
                }
              } // else either max borrow or max supply amount is zero
            } // else the borrowing is not enabled
          } // else supply is not enabled
        } // else borrow token is not active
      } // else collateral token is not active
    }

    if (plan.converter == address(0)) {
      AppDataTypes.ConversionPlan memory planNotFound;
      return planNotFound;
    } else {
      return plan;
    }
  }
  //endregion ----------------------------------------------------- Get conversion plan

  //region ----------------------------------------------------- Utils

  /// @dev See LendingContractsV2, ConverterController.sol, calcAccountEquityWithEffect
  /// @return collateralFactorMantissa Multiplier representing the most one can borrow against their collateral in
  ///         this market. For instance, 0.9 to allow borrowing 90% of collateral value.
  /// @return supplyCapacity iToken's supply capacity, -1 means no limit
  function _getCollateralMarketData(IDForceController comptroller_, address cTokenCollateral_) internal view returns (
    uint collateralFactorMantissa,
    uint supplyCapacity
  ) {
    (uint256 collateralFactorMantissa0,,, uint256 supplyCapacity0, bool mintPaused,,) = comptroller_.markets(cTokenCollateral_);
    return mintPaused || supplyCapacity0 == 0
      ? (0, 0)
      : (collateralFactorMantissa0, supplyCapacity0);
  }

  /// @dev See LendingContractsV2, ConverterController.sol, calcAccountEquityWithEffect
  /// @return borrowFactorMantissa Multiplier representing the most one can borrow the asset.
  ///         For instance, 0.5 to allow borrowing this asset 50% * collateral value * collateralFactor.
  /// @return borrowCapacity iToken's borrow capacity, -1 means no limit
  function _getBorrowMarketData(IDForceController comptroller_, address cTokenBorrow_) internal view returns (
    uint borrowFactorMantissa,
    uint borrowCapacity
  ) {
    (, uint256 borrowFactorMantissa0, uint256 borrowCapacity0,,, bool redeemPaused, bool borrowPaused) = comptroller_.markets(cTokenBorrow_);
    return (redeemPaused || borrowPaused || borrowCapacity0 == 0)
      ? (0, 0)
      : (borrowFactorMantissa0, borrowCapacity0);
  }
  //endregion ----------------------------------------------------- Utils
}