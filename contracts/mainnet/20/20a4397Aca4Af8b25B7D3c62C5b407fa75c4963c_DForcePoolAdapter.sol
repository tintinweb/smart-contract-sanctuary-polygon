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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDForceCTokenMatic {
  function mint(address _recipient) external payable;
  function repayBorrow() external payable;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IWmatic {

  function balanceOf(address target) external view returns (uint256);

  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function totalSupply() external view returns (uint256);

  function approve(address guy, uint256 wad) external returns (bool);

  function transfer(address dst, uint256 wad) external returns (bool);

  function transferFrom(address src, address dst, uint256 wad) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";

interface IConverter {
  function getConversionKind() external pure returns (
    AppDataTypes.ConversionKind
  );
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
  ///        Core application contracts
  //-----------------------------------------------------

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  //-----------------------------------------------------
  ///        External contracts
  //-----------------------------------------------------
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Collects list of registered borrow-positions. Allow to check state of the collaterals.
interface IDebtMonitor {

  /// @notice Enumerate {maxCountToCheck} pool adapters starting from {index0} and return unhealthy pool-adapters
  ///         i.e. adapters with health factor below min allowed value
  ///         It calculates two amounts: amount of borrow asset and amount of collateral asset
  ///         To fix the health factor it's necessary to send EITHER one amount OR another one.
  ///         There is special case: a liquidation happens inside the pool adapter.
  ///         It means, that this is "dirty" pool adapter and this position must be closed and never used again.
  ///         In this case, both amounts are zero (we need to make FULL repay)
  /// @return nextIndexToCheck0 Index of next pool-adapter to check; 0: all pool-adapters were checked
  /// @return outPoolAdapters List of pool adapters that should be reconverted
  /// @return outAmountBorrowAsset What borrow-asset amount should be send to pool adapter to fix health factor
  /// @return outAmountCollateralAsset What collateral-asset amount should be send to pool adapter to fix health factor
  function checkHealth(
    uint startIndex0,
    uint maxCountToCheck,
    uint maxCountToReturn
  ) external view returns (
    uint nextIndexToCheck0,
    address[] memory outPoolAdapters,
    uint[] memory outAmountBorrowAsset,
    uint[] memory outAmountCollateralAsset
  );

  /// @notice Register new borrow position if it's not yet registered
  /// @dev This function is called from a pool adapter after any borrow
  function onOpenPosition() external;

  /// @notice Unregister the borrow position if it's completely repaid
  /// @dev This function is called from a pool adapter when the borrow is completely repaid
  function onClosePosition() external;

  /// @notice Check if the pool-adapter-caller has an opened position
  function isPositionOpened() external view returns (bool);

  /// @notice Pool adapter has opened borrow, but full liquidation happens and we've lost all collateral
  ///         Close position without paying the debt and never use the pool adapter again.
  function closeLiquidatedPosition(address poolAdapter_) external;

  /// @notice Get total count of pool adapters with opened positions
  function getCountPositions() external view returns (uint);

  /// @notice Get active borrows of the user with given collateral/borrowToken
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositions (
    address user_,
    address collateralToken_,
    address borrowedToken_
  ) external view returns (
    address[] memory poolAdaptersOut
  );

  /// @notice Get active borrows of the given user
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositionsForUser(address user_) external view returns(
    address[] memory poolAdaptersOut
  );

  /// @notice Return true if there is a least once active pool adapter created on the base of the {converter_}
  function isConverterInUse(address converter_) external view returns (bool);

// TODO for next versions of the application
//  /// @notice Enumerate {maxCountToCheck} pool adapters starting from {index0} and return all pool-adapters
//  ///         with health factor exceeds max allowed value. In other words, it's safe to make additional borrow.
//  /// @return nextIndexToCheck0 Index of next pool-adapter to check; 0: all pool-adapters were checked
//  /// @return outPoolAdapters List of pool adapters that should be reconverted
//  /// @return outAmountsToBorrow What amount can be additionally borrowed using exist collateral
//  function checkAdditionalBorrow(
//    uint startIndex0,
//    uint maxCountToCheck,
//    uint maxCountToReturn
//  ) external view returns (
//    uint nextIndexToCheck0,
//    address[] memory outPoolAdapters,
//    uint[] memory outAmountsToBorrow
//  );

// TODO for next versions of the application
//  /// @notice Enumerate {maxCountToCheck} pool adapters starting from {index0} and return not-optimal pool-adapters
//  /// @param periodInBlocks Period in blocks that should be used in rebalancing
//  /// @return nextIndexToCheck0 Index of next pool-adapter to check; 0: all pool-adapters were checked
//  /// @return poolAdapters List of pool adapters that should be reconverted
//  function checkBetterBorrowExists(
//    uint startIndex0,
//    uint maxCountToCheck,
//    uint maxCountToReturn,
//    uint periodInBlocks
//  ) external view returns (
//    uint nextIndexToCheck0,
//    address[] memory poolAdapters
//  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverter.sol";

/// @notice Allow to borrow given asset from the given pool using given asset as collateral.
///         There is Template-Pool-Adapter contract for each platform (AAVE, HF, etc).
/// @dev Terms: "pool adapter" is an instance of "converter" created using minimal-proxy-pattern
interface IPoolAdapter is IConverter {
  /// @notice Update all interests, recalculate borrowed amount;
  ///         After this call, getStatus will return exact amount-to-repay
  function updateStatus() external;

  /// @notice Supply collateral to the pool and borrow specified amount
  /// @dev No re-balancing here; Collateral amount must be approved to the pool adapter before the call of this function
  /// @param collateralAmount_ Amount of collateral, must be approved to the pool adapter before the call of borrow()
  /// @param borrowAmount_ Amount that should be borrowed in result
  /// @param receiver_ Receiver of the borrowed amount
  /// @return borrowedAmountOut Result borrowed amount sent to the {receiver_}
  function borrow(uint collateralAmount_, uint borrowAmount_, address receiver_) external returns (
    uint borrowedAmountOut
  );

  /// @notice Borrow additional amount {borrowAmount_} using exist collateral and send it to {receiver_}
  /// @dev Re-balance: too big health factor => target health factor
  /// @return resultHealthFactor18 Result health factor after borrow
  /// @return borrowedAmountOut Exact amount sent to the borrower
  function borrowToRebalance(uint borrowAmount_, address receiver_) external returns (
    uint resultHealthFactor18,
    uint borrowedAmountOut
  );

  /// @notice Repay borrowed amount, return collateral to the user
  /// @param amountToRepay_ Exact amount of borrow asset that should be repaid
  ///                       The amount should be approved for the pool adapter before the call of repay()
  /// @param closePosition_ true to pay full borrowed amount
  /// @param receiver_ Receiver of withdrawn collateral
  /// @return collateralAmountOut Amount of collateral asset sent to the {receiver_}
  function repay(uint amountToRepay_, address receiver_, bool closePosition_) external returns (
    uint collateralAmountOut
  );

  /// @notice Repay with rebalancing. Send amount of collateral/borrow asset to the pool adapter
  ///         to recover the health factor to target state.
  /// @dev It's not allowed to close position here (pay full debt) because no collateral will be returned.
  /// @param amount_ Exact amount of asset that is transferred to the balance of the pool adapter.
  ///                It can be amount of collateral asset or borrow asset depended on {isCollateral_}
  ///                It must be stronger less then total borrow debt.
  ///                The amount should be approved for the pool adapter before the call.
  /// @param isCollateral_ true/false indicates that {amount_} is the amount of collateral/borrow asset
  /// @return resultHealthFactor18 Result health factor after repay, decimals 18
  function repayToRebalance(uint amount_, bool isCollateral_) external returns (
    uint resultHealthFactor18
  );

  /// @return originConverter Address of original PoolAdapter contract that was cloned to make the instance of the pool adapter
  /// @return user User of the pool adapter
  /// @return collateralAsset Asset used as collateral by the pool adapter
  /// @return borrowAsset Asset borrowed by the pool adapter
  function getConfig() external view returns (
    address originConverter,
    address user,
    address collateralAsset,
    address borrowAsset
  );

  /// @notice Get current status of the borrow position
  /// @dev It returns STORED status. To get current status it's necessary to call updateStatus
  ///      at first to update interest and recalculate status.
  /// @return collateralAmount Total amount of provided collateral, collateral currency
  /// @return amountToPay Total amount of borrowed debt in [borrow asset]. 0 - for closed borrow positions.
  /// @return healthFactor18 Current health factor, decimals 18
  /// @return opened The position is opened (there is not empty collateral/borrow balance)
  /// @return collateralAmountLiquidated How much collateral was liquidated
  /// @return debtGapRequired When paying off a debt, the amount of the payment must be greater
  ///         than the amount of the debt by a small amount (debt gap, see IConverterController.debtGap)
  ///         getStatus returns it (same as getConfig) to exclude additional call of getConfig by the caller
  function getStatus() external view returns (
    uint collateralAmount,
    uint amountToPay,
    uint healthFactor18,
    bool opened,
    uint collateralAmountLiquidated,
    bool debtGapRequired
  );

  /// @notice Check if any reward tokens exist on the balance of the pool adapter, transfer reward tokens to {receiver_}
  /// @return rewardToken Address of the transferred reward token
  /// @return amount Amount of the transferred reward token
  function claimRewards(address receiver_) external returns (address rewardToken, uint amount);

  /// @notice If we paid {amountToRepay_}, how much collateral would we receive?
  function getCollateralAmountToReturn(uint amountToRepay_, bool closePosition_) external view returns (uint);

//  /// @notice Compute current APR value, decimals 18
//  /// @return Interest * 1e18, i.e. 2.25e18 means APR=2.25%
//  function getAPR18() external view returns (int);
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success,) = recipient.call{value : amount}("");
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
    (bool success, bytes memory returndata) = target.call{value : value}(data);
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
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
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
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
import "../../openzeppelin/Initializable.sol";
import "../../openzeppelin/IERC20Metadata.sol";
import "../../libs/AppErrors.sol";
import "../../interfaces/IPoolAdapter.sol";
import "../../interfaces/IPoolAdapterInitializerWithAP.sol";
import "../../interfaces/ITokenAddressProvider.sol";
import "../../interfaces/IConverterController.sol";
import "../../interfaces/IDebtMonitor.sol";
import "../../integrations/dforce/IDForceController.sol";
import "../../integrations/dforce/IDForceCToken.sol";
import "../../integrations/dforce/IDForcePriceOracle.sol";
import "../../integrations/dforce/IDForceCTokenMatic.sol";
import "../../integrations/IWmatic.sol";
import "../../integrations/dforce/IDForceInterestRateModel.sol";
import "../../integrations/dforce/IDForceRewardDistributor.sol";

/// @notice Implementation of IPoolAdapter for dForce-protocol, see https://developers.dforce.network/
/// @dev Instances of this contract are created using proxy-minimal pattern, so no constructor
contract DForcePoolAdapter is IPoolAdapter, IPoolAdapterInitializerWithAP, Initializable {
  using SafeERC20 for IERC20;

  /// @notice Max allowed difference for sumCollateralSafe - sumBorrowPlusEffects == liquidity
  uint private constant DELTA = 100;
  address private constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

  address public collateralAsset;
  address public borrowAsset;
  address public collateralCToken;
  address public borrowCToken;
  address public user;

  IConverterController public controller;
  IDForceController private _comptroller;

  /// @notice Address of original PoolAdapter contract that was cloned to make the instance of the pool adapter
  address public originConverter;

  /// @notice Total amount of all supplied and withdrawn amounts of collateral in collateral tokens
  uint public collateralTokensBalance;

  //-----------------------------------------------------
  ///                Events
  //-----------------------------------------------------
  event OnInitialized(
    address controller,
    address cTokenAddressProvider,
    address comptroller,
    address user,
    address collateralAsset,
    address borrowAsset,
    address originConverter
  );
  event OnBorrow(uint collateralAmount, uint borrowAmount, address receiver, uint resultHealthFactor18);
  event OnBorrowToRebalance(uint borrowAmount, address receiver, uint resultHealthFactor18);
  event OnRepay(uint amountToRepay, address receiver, bool closePosition, uint resultHealthFactor18);
  event OnRepayToRebalance(uint amount, bool isCollateral, uint resultHealthFactor18);
  /// @notice On claim not empty {amount} of reward tokens
  event OnClaimRewards(address rewardToken, uint amount, address receiver);

  //-----------------------------------------------------
  ///                Initialization
  //-----------------------------------------------------

  function initialize(
    address controller_,
    address cTokenAddressProvider_,
    address comptroller_,
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    address originConverter_
  ) override external
    // Borrow Manager creates a pool adapter using minimal proxy pattern, adds it the the set of known pool adapters
    // and initializes it immediately. We should ensure only that the re-initialization is not possible
  initializer
  {
    require(
      controller_ != address(0)
      && comptroller_ != address(0)
      && user_ != address(0)
      && collateralAsset_ != address(0)
      && borrowAsset_ != address(0)
      && originConverter_ != address(0)
      && cTokenAddressProvider_ != address(0),
      AppErrors.ZERO_ADDRESS
    );

    controller = IConverterController(controller_);
    user = user_;
    collateralAsset = collateralAsset_;
    borrowAsset = borrowAsset_;
    originConverter = originConverter_;

    (address cTokenCollateral,
     address cTokenBorrow
    ) = ITokenAddressProvider(cTokenAddressProvider_).getCTokenByUnderlying(collateralAsset_, borrowAsset_);

    require(cTokenCollateral != address(0), AppErrors.C_TOKEN_NOT_FOUND);
    require(cTokenBorrow != address(0), AppErrors.C_TOKEN_NOT_FOUND);

    collateralCToken = cTokenCollateral;
    borrowCToken = cTokenBorrow;

    _comptroller = IDForceController(comptroller_);

    // The pool adapter doesn't keep assets on its balance, so it's safe to use infinity approve
    // All approves replaced by infinity-approve were commented in the code below
    IERC20(collateralAsset_).safeApprove(cTokenCollateral, 2**255); // 2*255 is more gas-efficient than type(uint).max
    IERC20(borrowAsset_).safeApprove(cTokenBorrow, 2**255); // 2*255 is more gas-efficient than type(uint).max

    emit OnInitialized(controller_, cTokenAddressProvider_, comptroller_, user_, collateralAsset_, borrowAsset_, originConverter_);
  }

  //-----------------------------------------------------
  ///                 Restrictions
  //-----------------------------------------------------

  /// @notice Ensure that the caller is TetuConverter
  function _onlyTetuConverter(IConverterController controller_) internal view {
    require(controller_.tetuConverter() == msg.sender, AppErrors.TETU_CONVERTER_ONLY);
  }

  //-----------------------------------------------------
  ///                 Borrow logic
  //-----------------------------------------------------
  function updateStatus() external override {
    // no restrictions, anybody can call this function

    // Update borrowBalance to actual value
    IDForceCToken(borrowCToken).borrowBalanceCurrent(address(this));
    IDForceCToken(collateralCToken).exchangeRateCurrent();
  }

  /// @notice Supply collateral to the pool and borrow specified amount
  /// @dev No re-balancing here; Collateral amount must be approved to the pool adapter before the call of this function
  /// @param collateralAmount_ Amount of collateral, must be approved to the pool adapter before the call of borrow()
  /// @param borrowAmount_ Amount that should be borrowed in result
  /// @param receiver_ Receiver of the borrowed amount
  /// @return Result borrowed amount sent to the {receiver_}
  function borrow(
    uint collateralAmount_,
    uint borrowAmount_,
    address receiver_
  ) external override returns (uint) {
    IConverterController c = controller;
    _onlyTetuConverter(c);

    address cTokenCollateral = collateralCToken;
    address cTokenBorrow = borrowCToken;
    address assetCollateral = collateralAsset;
    address assetBorrow = borrowAsset;

    IERC20(assetCollateral).safeTransferFrom(msg.sender, address(this), collateralAmount_);

    // enter markets (repeat entering is not a problem)
    address[] memory markets = new address[](2);
    markets[0] = cTokenCollateral;
    markets[1] = cTokenBorrow;
    _comptroller.enterMarkets(markets);

    uint tokenBalanceBefore = _supply(cTokenCollateral, assetCollateral, collateralAmount_);

    // make borrow
    uint balanceBorrowAsset0 = _getBalance(assetBorrow);
    IDForceCToken(cTokenBorrow).borrow(borrowAmount_);

    // ensure that we have received required borrowed amount, send the amount to the receiver
    if (_isMatic(assetBorrow)) {
      IWmatic(WMATIC).deposit{value : borrowAmount_}();
    }
    require(
      borrowAmount_ + balanceBorrowAsset0 == IERC20(assetBorrow).balanceOf(address(this)),
      AppErrors.WRONG_BORROWED_BALANCE
    );
    IERC20(assetBorrow).safeTransfer(receiver_, borrowAmount_);

    // register the borrow in DebtMonitor
    IDebtMonitor(c.debtMonitor()).onOpenPosition();

    // ensure that current health factor is greater than min allowed
    (uint healthFactor, uint tokenBalanceAfter) = _validateHealthStatusAfterBorrow(c, cTokenCollateral, cTokenBorrow);
    require(tokenBalanceAfter >= tokenBalanceBefore, AppErrors.WEIRD_OVERFLOW); // overflow below is not possible
    collateralTokensBalance += tokenBalanceAfter - tokenBalanceBefore;

    emit OnBorrow(collateralAmount_, borrowAmount_, receiver_, healthFactor);

    return borrowAmount_;
  }

  /// @notice Supply collateral to DForce market
  /// @return Collateral token balance before supply
  function _supply(
    address cTokenCollateral_,
    address assetCollateral_,
    uint collateralAmount_
  ) internal returns (uint) {
    uint tokenBalanceBefore = IERC20(cTokenCollateral_).balanceOf(address(this));

    // the amount is received through safeTransferFrom before calling of _supply()
    // so we don't need following additional check:
    //    require(tokenBalanceBefore >= collateralAmount_, AppErrors.MINT_FAILED);

    // supply collateral
    if (_isMatic(assetCollateral_)) {
      IWmatic(WMATIC).withdraw(collateralAmount_);
      IDForceCTokenMatic(cTokenCollateral_).mint{value : collateralAmount_}(address(this));
    } else {
      // replaced by infinity approve: IERC20(assetCollateral_).safeApprove(cTokenCollateral_, collateralAmount_);
      IDForceCToken(cTokenCollateral_).mint(address(this), collateralAmount_);
    }
    return tokenBalanceBefore;
  }

  /// @return (Health factor, decimal 18; collateral-token-balance)
  function _validateHealthStatusAfterBorrow(
    IConverterController controller_,
    address cTokenCollateral_,
    address cTokenBorrow_
  ) internal view returns (uint, uint) {
    (uint tokenBalance,,
     uint collateralBase36,
     uint borrowBase36,,
    ) = _getStatus(cTokenCollateral_, cTokenBorrow_);

    (uint sumCollateralSafe36,
     uint healthFactor18
    ) = _getHealthFactor(cTokenCollateral_, collateralBase36, borrowBase36);

    // USD with 36 integer precision
    // see https://developers.dforce.network/lend/lend-and-synth/controller#calcaccountequity
    (uint liquidity36,,,) = _comptroller.calcAccountEquity(address(this));

    require(
      sumCollateralSafe36 > borrowBase36
      && borrowBase36 != 0
    // here we should have: sumCollateralSafe - sumBorrowPlusEffects == liquidity
      && liquidity36 + DELTA + borrowBase36 >= sumCollateralSafe36,
      AppErrors.INCORRECT_RESULT_LIQUIDITY
    );

    _validateHealthFactor(controller_, healthFactor18);
    return (healthFactor18, tokenBalance);
  }

  /// @notice Borrow additional amount {borrowAmount_} using exist collateral and send it to {receiver_}
  /// @dev Re-balance: too big health factor => target health factor
  /// @return resultHealthFactor18 Result health factor after borrow
  /// @return borrowedAmountOut Exact amount sent to the borrower
  function borrowToRebalance(
    uint borrowAmount_,
    address receiver_
  ) external override returns (
    uint resultHealthFactor18,
    uint borrowedAmountOut
  ) {
    IConverterController c = controller;
    _onlyTetuConverter(c);
    address cTokenBorrow = borrowCToken;
    address assetBorrow = borrowAsset;

    // ensure that the position is opened
    require(IDebtMonitor(c.debtMonitor()).isPositionOpened(), AppErrors.BORROW_POSITION_IS_NOT_REGISTERED);

    // make borrow
    uint balanceBorrowAsset0 = _getBalance(assetBorrow);
    IDForceCToken(cTokenBorrow).borrow(borrowAmount_);

    // ensure that we have received required borrowed amount, send the amount to the receiver
    if (_isMatic(assetBorrow)) {
      IWmatic(WMATIC).deposit{value : borrowAmount_}();
    }
    require(
      borrowAmount_ + balanceBorrowAsset0 == IERC20(assetBorrow).balanceOf(address(this)),
      AppErrors.WRONG_BORROWED_BALANCE
    );
    IERC20(assetBorrow).safeTransfer(receiver_, borrowAmount_);

    // ensure that current health factor is greater than min allowed
    (resultHealthFactor18,) = _validateHealthStatusAfterBorrow(c, collateralCToken, cTokenBorrow);

    emit OnBorrowToRebalance(borrowAmount_, receiver_, resultHealthFactor18);
    return (resultHealthFactor18, borrowAmount_);
  }

  //-----------------------------------------------------
  ///                 Repay logic
  //-----------------------------------------------------

  /// @notice Repay borrowed amount, return collateral to the user
  /// @param amountToRepay_ Exact amount of borrow asset that should be repaid
  ///                       The amount should be approved for the pool adapter before the call of repay()
  /// @param closePosition_ true to pay full borrowed amount
  /// @param receiver_ Receiver of withdrawn collateral
  /// @return collateralAmountToReturn Amount of collateral asset sent to the {receiver_}
  function repay(
    uint amountToRepay_,
    address receiver_,
    bool closePosition_
  ) external override returns (uint collateralAmountToReturn) {
    IConverterController c = controller;
    _onlyTetuConverter(c);

    uint healthFactor18;
    {
      address assetBorrow = borrowAsset;
      address assetCollateral = collateralAsset;
      address cTokenBorrow = borrowCToken;
      address cTokenCollateral = collateralCToken;

      {
        // Update borrowBalance to actual value, we must do it before calculation of collateral to withdraw
        uint debt = IDForceCToken(cTokenBorrow).borrowBalanceCurrent(address(this));
        if (amountToRepay_ > debt) {
          // all amount exceeded the debt should be directly sent to the {receiver_}
          IERC20(assetBorrow).safeTransferFrom(msg.sender, receiver_, amountToRepay_ - debt);
          amountToRepay_ = debt;
        }
      }

      IERC20(assetBorrow).safeTransferFrom(msg.sender, address(this), amountToRepay_);
      // we don't need following check after successful safeTransferFrom
      //    require(IERC20(assetBorrow).balanceOf(address(this)) >= amountToRepay_, AppErrors.MINT_FAILED);

      // how much collateral we are going to return
      (uint collateralTokensToWithdraw, uint tokenBalanceBefore) = _getCollateralTokensToRedeem(
        cTokenCollateral,
        cTokenBorrow,
        closePosition_,
        amountToRepay_
      );

      // transfer borrow amount back to the pool
      if (_isMatic(address(assetBorrow))) {
        IWmatic(WMATIC).withdraw(amountToRepay_);
        IDForceCTokenMatic(cTokenBorrow).repayBorrow{value : amountToRepay_}();
      } else {
        // replaced by infinity approve: IERC20(assetBorrow).safeApprove(cTokenBorrow, amountToRepay_);
        IDForceCToken(cTokenBorrow).repayBorrow(amountToRepay_);
      }

      // withdraw the collateral
      uint balanceCollateralAsset = _getBalance(assetCollateral);
      IDForceCToken(cTokenCollateral).redeem(address(this), collateralTokensToWithdraw);
      uint balanceCollateralAssetAfterRedeem = _getBalance(assetCollateral);

      // transfer collateral back to the user
      require(balanceCollateralAssetAfterRedeem >= balanceCollateralAsset, AppErrors.WEIRD_OVERFLOW); // overflow is not possible below
      collateralAmountToReturn = balanceCollateralAssetAfterRedeem - balanceCollateralAsset;
      if (_isMatic(assetCollateral)) {
        IWmatic(WMATIC).deposit{value : collateralAmountToReturn}();
      }
      IERC20(assetCollateral).safeTransfer(receiver_, collateralAmountToReturn);

      // validate result status
      (uint tokenBalanceAfter,
       uint borrowBalance,
       uint collateralBase,
       uint sumBorrowPlusEffects,,
      ) = _getStatus(cTokenCollateral, cTokenBorrow);


      if (tokenBalanceAfter == 0 && borrowBalance == 0) {
        IDebtMonitor(c.debtMonitor()).onClosePosition();
        // We don't exit the market to avoid additional gas consumption
      } else {
        require(!closePosition_, AppErrors.CLOSE_POSITION_FAILED);
        (, healthFactor18) = _getHealthFactor(cTokenCollateral, collateralBase, sumBorrowPlusEffects);
        _validateHealthFactor(c, healthFactor18);
      }

      require(
        tokenBalanceBefore >= tokenBalanceAfter
        && collateralTokensBalance >= tokenBalanceBefore - tokenBalanceAfter,
        AppErrors.WEIRD_OVERFLOW
      );
      collateralTokensBalance -= tokenBalanceBefore - tokenBalanceAfter;
    }

    emit OnRepay(amountToRepay_, receiver_, closePosition_, healthFactor18);
    return collateralAmountToReturn;
  }

  /// @return Amount of collateral tokens to redeem, full balance of collateral tokens
  function _getCollateralTokensToRedeem(
    address cTokenCollateral_,
    address cTokenBorrow_,
    bool closePosition_,
    uint amountToRepay_
  ) internal view returns (uint, uint) {
    uint tokenBalance = IERC20(cTokenCollateral_).balanceOf(address(this));

    uint borrowBalance = IDForceCToken(cTokenBorrow_).borrowBalanceStored(address(this));
    require(borrowBalance != 0, AppErrors.ZERO_BALANCE);
    if (closePosition_) {
      require(borrowBalance <= amountToRepay_, AppErrors.CLOSE_POSITION_PARTIAL);

      return (tokenBalance, tokenBalance);
    } else {
      require(amountToRepay_ <= borrowBalance, AppErrors.WRONG_BORROWED_BALANCE);
    }

    return (tokenBalance * amountToRepay_ / borrowBalance, tokenBalance);
  }

  /// @notice Repay with rebalancing. Send amount of collateral/borrow asset to the pool adapter
  ///         to recover the health factor to target state.
  /// @dev It's not allowed to close position here (pay full debt) because no collateral will be returned.
  /// @param amount_ Exact amount of asset that is transferred to the balance of the pool adapter.
  ///                It can be amount of collateral asset or borrow asset depended on {isCollateral_}
  ///                It must be stronger less then total borrow debt.
  ///                The amount should be approved for the pool adapter before the call.
  /// @param isCollateral_ true/false indicates that {amount_} is the amount of collateral/borrow asset
  /// @return resultHealthFactor18 Result health factor after repay, decimals 18
  function repayToRebalance(
    uint amount_,
    bool isCollateral_
  ) external override returns (
    uint resultHealthFactor18
  ) {
    IConverterController c = controller;
    _onlyTetuConverter(c);

    address cTokenBorrow = borrowCToken;
    address cTokenCollateral = collateralCToken;
    uint tokenBalanceBefore;

    // ensure that the position is opened
    require(IDebtMonitor(c.debtMonitor()).isPositionOpened(), AppErrors.BORROW_POSITION_IS_NOT_REGISTERED);

    if (isCollateral_) {
      address assetCollateral = collateralAsset;
      IERC20(assetCollateral).safeTransferFrom(msg.sender, address(this), amount_);
      tokenBalanceBefore = _supply(cTokenCollateral, collateralAsset, amount_);
    } else {
      uint borrowBalance;
      address assetBorrow = borrowAsset;
      // ensure, that amount to repay is less then the total debt
      (tokenBalanceBefore, borrowBalance,,,,) = _getStatus(cTokenCollateral, cTokenBorrow);
      require(borrowBalance != 0 && amount_ < borrowBalance, AppErrors.REPAY_TO_REBALANCE_NOT_ALLOWED);

      IERC20(assetBorrow).safeTransferFrom(msg.sender, address(this), amount_);
      // the amount is received through safeTransferFrom so we don't need following additional check:
      //    require(IERC20(assetBorrow).balanceOf(address(this)) >= amount_, AppErrors.MINT_FAILED);

      // transfer borrow amount back to the pool
      if (_isMatic(assetBorrow)) {
        IWmatic(WMATIC).withdraw(amount_);
        IDForceCTokenMatic(cTokenBorrow).repayBorrow{value : amount_}();
      } else {
        // replaced by infinity approve in constructor: IERC20(assetBorrow).safeApprove(cTokenBorrow, amount_);
        IDForceCToken(cTokenBorrow).repayBorrow(amount_);
      }
    }
    // validate result status
    (uint tokenBalanceAfter,,
     uint collateralBase,
     uint sumBorrowPlusEffects,,
    ) = _getStatus(cTokenCollateral, cTokenBorrow);

    (, uint healthFactor18) = _getHealthFactor(cTokenCollateral, collateralBase, sumBorrowPlusEffects);
    _validateHealthFactor(c, healthFactor18);

    require(tokenBalanceAfter >= tokenBalanceBefore, AppErrors.WEIRD_OVERFLOW);
    collateralTokensBalance += tokenBalanceAfter - tokenBalanceBefore;

    emit OnRepayToRebalance(amount_, isCollateral_, healthFactor18);
    return healthFactor18;
  }

  /// @notice If we paid {amountToRepay_}, how much collateral would we receive?
  function getCollateralAmountToReturn(uint amountToRepay_, bool closePosition_) external view override returns (uint) {
    address cTokenCollateral = collateralCToken;

    (uint tokensToReturn,) = _getCollateralTokensToRedeem(cTokenCollateral, borrowCToken, closePosition_, amountToRepay_);
    return tokensToReturn * IDForceCToken(cTokenCollateral).exchangeRateStored() / 10**18;
  }

  //-----------------------------------------------------
  ///                 Rewards
  //-----------------------------------------------------

  /// @notice Check if any reward tokens exist on the balance of the pool adapter, transfer reward tokens to {receiver_}
  /// @return rewardTokenOut Address of the transferred reward token
  /// @return amountOut Amount of the transferred reward token
  function claimRewards(address receiver_) external override returns (
    address rewardTokenOut,
    uint amountOut
  ) {
    _onlyTetuConverter(controller);

    IDForceRewardDistributor rd = IDForceRewardDistributor(_comptroller.rewardDistributor());
    rewardTokenOut = rd.rewardToken();

    address cTokenBorrow = borrowCToken;
    address cTokenCollateral = collateralCToken;
    rd.updateDistributionState(cTokenCollateral, false);
    rd.updateDistributionState(cTokenBorrow, true);
    rd.updateReward(cTokenCollateral, address(this), false);
    rd.updateReward(cTokenBorrow, address(this), true);

    amountOut = rd.reward(address(this));
    if (amountOut != 0) {
      address[] memory holders = new address[](1);
      holders[0] = address(this);
      rd.claimAllReward(holders);

      uint balance = IERC20(rewardTokenOut).balanceOf(address(this));
      if (balance != 0) {
        IERC20(rewardTokenOut).safeTransfer(receiver_, balance);
      }

      emit OnClaimRewards(rewardTokenOut, amountOut, receiver_);
    }

    return (rewardTokenOut, amountOut);
  }

  //-----------------------------------------------------
  ///         View current status
  //-----------------------------------------------------

  /// @inheritdoc IPoolAdapter
  function getConfig() external view override returns (
    address origin,
    address outUser,
    address outCollateralAsset,
    address outBorrowAsset
  ) {
    return (originConverter, user, collateralAsset, borrowAsset);
  }

  /// @inheritdoc IPoolAdapter
  function getStatus() external view override returns (
    uint collateralAmount,
    uint amountToPay,
    uint healthFactor18,
    bool opened,
    uint collateralAmountLiquidated,
    bool debtGapRequired
  ) {
    address cTokenBorrow = borrowCToken;
    address cTokenCollateral = collateralCToken;

    ( uint collateralTokens,
      uint borrowBalance,
      uint collateralBase36,
      uint borrowBase36,
      uint collateralAmountLiquidatedBase36,
      uint collateralPrice
    ) = _getStatus(cTokenCollateral, cTokenBorrow);

    (, healthFactor18) = _getHealthFactor(
      cTokenCollateral,
      collateralBase36,
      borrowBase36
    );

    return (
    // Total amount of provided collateral in [collateral asset]
      collateralBase36 / collateralPrice,
    // Total amount of borrowed debt in [borrow asset]. 0 - for closed borrow positions.
      borrowBalance,
    // Current health factor, decimals 18
      healthFactor18,
      collateralTokens != 0 || borrowBalance != 0,
    // Amount of liquidated collateral == amount of lost
      collateralAmountLiquidatedBase36 / collateralPrice,
    false
    );
  }

  /// @return tokenBalanceOut Count of collateral tokens on balance
  /// @return borrowBalanceOut Borrow amount [borrow asset units]
  /// @return collateralAmountBase36 Total collateral in base currency, decimals 36
  /// @return sumBorrowBase36 Total borrow amount in base currency, decimals 36
  function _getStatus(address cTokenCollateral_, address cTokenBorrow_) internal view returns (
    uint tokenBalanceOut,
    uint borrowBalanceOut,
    uint collateralAmountBase36,
    uint sumBorrowBase36,
    uint collateralAmountLiquidatedBase36,
    uint collateralPrice
  ) {
    // Calculate value of all collaterals, see ControllerV2.calcAccountEquityWithEffect
    // collateralValuePerToken = underlyingPrice * exchangeRate * collateralFactor
    // collateralValue = balance * collateralValuePerToken
    // sumCollateral += collateralValue
    tokenBalanceOut = IDForceCToken(cTokenCollateral_).balanceOf(address(this));

    IDForcePriceOracle priceOracle = IDForcePriceOracle(_comptroller.priceOracle());
    collateralPrice = DForceAprLib.getPrice(priceOracle, cTokenCollateral_);

    {
      uint exchangeRateMantissa = IDForceCToken(cTokenCollateral_).exchangeRateStored();
      collateralAmountBase36 = tokenBalanceOut * collateralPrice * exchangeRateMantissa / 10**18;
      collateralAmountLiquidatedBase36 =  tokenBalanceOut > collateralTokensBalance
        ? 0
        : (collateralTokensBalance - tokenBalanceOut) * collateralPrice * exchangeRateMantissa / 10**18;
    }

    // Calculate all borrowed value, see ControllerV2.calcAccountEquityWithEffect
    // borrowValue = underlyingPrice * underlyingBorrowed / borrowFactor
    // sumBorrowed += borrowValue
    borrowBalanceOut = IDForceCToken(cTokenBorrow_).borrowBalanceStored(address(this));

    uint underlyingPrice = DForceAprLib.getPrice(priceOracle, cTokenBorrow_);

    sumBorrowBase36 = borrowBalanceOut * underlyingPrice;

    return (
      tokenBalanceOut,
      borrowBalanceOut,
      collateralAmountBase36,
      sumBorrowBase36,
      collateralAmountLiquidatedBase36,
      collateralPrice
    );
  }

  function getConversionKind() external pure override returns (AppDataTypes.ConversionKind) {
    return AppDataTypes.ConversionKind.BORROW_2;
  }

//  /// @notice Compute current cost of the money
//  function getAPR18() external view override returns (int) {
//    return int(IDForceCToken(borrowCToken).borrowRatePerBlock() * controller.blocksPerDay() * 365 * 100);
//  }

  //-----------------------------------------------------
  ///                     Utils
  //-----------------------------------------------------
  function _getHealthFactor(address cTokenCollateral_, uint sumCollateralBase36_, uint sumBorrowBase36_)
  internal view returns (
    uint sumCollateralSafe36,
    uint healthFactor18
  ) {
    (uint collateralFactorMantissa,,,,,,) = _comptroller.markets(cTokenCollateral_);

    sumCollateralSafe36 = collateralFactorMantissa * sumCollateralBase36_ / 10**18;

    healthFactor18 = sumBorrowBase36_ == 0
      ? type(uint).max
      : sumCollateralSafe36 * 10**18 / sumBorrowBase36_;
    return (sumCollateralSafe36, healthFactor18);
  }

  function _validateHealthFactor(IConverterController controller_, uint hf18) internal view {
    require(hf18 > uint(controller_.minHealthFactor2())*10**(18-2), AppErrors.WRONG_HEALTH_FACTOR);
  }

  //-----------------------------------------------------
  ///                Native tokens
  //-----------------------------------------------------

  function _isMatic(address asset_) internal pure returns (bool) {
    return asset_ == WMATIC;
  }

  function _getBalance(address asset) internal view returns (uint) {
    return _isMatic(asset)
      ? address(this).balance
      : IERC20(asset).balanceOf(address(this));
  }

  receive() external payable {} // this is needed for the native token unwrapping
}