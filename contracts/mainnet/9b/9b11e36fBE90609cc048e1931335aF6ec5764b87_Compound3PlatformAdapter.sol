// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IComet {
  struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
  }

  struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
  }

  function baseTokenPriceFeed() external view returns (address);

  function numAssets() external view returns (uint8);

  function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

  function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

  function supply(address asset, uint amount) external;

  function withdraw(address asset, uint amount) external;

  function baseToken() external view returns (address);

  function balanceOf(address account) external view returns (uint);

  function totalSupply() external view returns (uint);

  function isSupplyPaused() external view returns (bool);

  function isWithdrawPaused() external view returns (bool);

  function getBorrowRate(uint utilization) external view returns (uint64);

  function getUtilization() external view returns (uint);

  function baseTrackingBorrowSpeed() external view returns (uint);

  function baseScale() external view returns (uint);

  function baseIndexScale() external view returns (uint);

  function totalBorrow() external view returns (uint);

  function baseBorrowMin() external view returns (uint);

  function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused) external;

  function pauseGuardian() external view returns (address);

  function userCollateral(address user, address asset) external view returns (UserCollateral memory);

  function borrowBalanceOf(address account) external view returns (uint);

  function absorb(address absorber, address[] calldata accounts) external;

  function quoteCollateral(address asset, uint baseAmount) external view returns (uint);

  function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) external;

  function accrueAccount(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ICometRewards {
  struct RewardConfig {
    address token;
    uint64 rescaleFactor;
    bool shouldUpscale;
  }

  struct RewardOwed {
    address token;
    uint owed;
  }

  function rewardConfig(address comet) external view returns(RewardConfig memory);
  function getRewardOwed(address comet, address account) external returns (RewardOwed memory);
  function claim(address comet, address src, bool shouldAccrue) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPriceFeed {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function latestRoundData() external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint priceImpactTolerance
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint priceImpactTolerance
  ) external;

  function addLargestPools(PoolData[] memory _pools, bool rewrite) external;
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

/// @notice Initializer for pool-adapters with rewards contract address
interface IPoolAdapterInitializerWithRewards {

  function initialize(
    address controller_,
    address pool_,
    address rewards_,
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    address originConverter_
  ) external;
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
pragma solidity 0.8.17;

import "../../openzeppelin/IERC20Metadata.sol";
import "../../integrations/compound3/IComet.sol";
import "../../integrations/compound3/ICometRewards.sol";
import "../../integrations/compound3/IPriceFeed.sol";
import "../../interfaces/IConverterController.sol";
import "../../integrations/tetu/ITetuLiquidator.sol";
import "../../libs/AppErrors.sol";

library Compound3AprLib {
  struct GetRewardsParamsLocal {
    IComet comet;
    ICometRewards cometRewards;
    IConverterController controller;
    uint borrowAmount;
    uint blocks;
    uint blocksPerDay;
    uint borrowAssetDecimals;
  }

  function getRewardsAmountInBorrowAsset36(IComet comet, address cometRewards, IConverterController controller, uint borrowAmount, uint blocks, uint blocksPerDay, uint borrowAssetDecimals) internal view returns (uint) {
    return _getRewardsAmountInBorrowAsset36(GetRewardsParamsLocal(comet, ICometRewards(cometRewards), controller, borrowAmount, blocks, blocksPerDay, borrowAssetDecimals));
  }

  function _getRewardsAmountInBorrowAsset36(GetRewardsParamsLocal memory p) internal view returns (uint) {
    IComet _comet = p.comet;
    ICometRewards.RewardConfig memory config = p.cometRewards.rewardConfig(address(_comet));
    uint timeElapsed = p.blocks * 86400 / p.blocksPerDay;

    // https://github.com/compound-developers/compound-3-developer-faq/blob/master/contracts/MyContract.sol#L181
    uint rewardToBorrowersForPeriod = _comet.baseTrackingBorrowSpeed() * timeElapsed * (_comet.baseIndexScale() / _comet.baseScale());
    uint rewardTokenDecimals = 10**IERC20Metadata(config.token).decimals();
    uint price = ITetuLiquidator(p.controller.tetuLiquidator()).getPrice(config.token, _comet.baseToken(), rewardTokenDecimals);
    return price * rewardToBorrowersForPeriod / _comet.totalBorrow() * p.borrowAmount * 1e36 / rewardTokenDecimals / (p.borrowAssetDecimals ** 2);
  }

  function getBorrowCost36(IComet comet, uint borrowAmount, uint blocks, uint blocksPerDay, uint borrowAssetDecimals) internal view returns (uint) {
    uint rate = getBorrowRate(comet, borrowAmount);
    uint timeElapsed = blocks * 86400 / blocksPerDay;
    return rate * timeElapsed * borrowAmount * 1e18 / borrowAssetDecimals;
  }

  function getBorrowRate(IComet comet, uint borrowAmount) internal view returns(uint) {
    uint totalSupply = comet.totalSupply();
    uint totalBorrow = comet.totalBorrow() + borrowAmount;
    uint utilization = totalSupply == 0 ? 0 : totalBorrow * 1e18 / totalSupply;
    return uint(comet.getBorrowRate(utilization));
  }

  /// @notice Price of asset served by oracle in terms of USD, decimals 8
  function getPrice(address oracle) internal view returns (uint) {
    (,int answer,,,) = IPriceFeed(oracle).latestRoundData();
    require(answer != 0, AppErrors.ZERO_PRICE);
    return uint(answer);
  }

  /// @notice Estimate value of variable borrow rate after borrowing {amountToBorrow_}
  function getBorrowRateAfterBorrow(address cometAddress, uint amountToBorrow_) external view returns (uint) {
    if (cometAddress != address(0)) {
      return Compound3AprLib.getBorrowRate(IComet(cometAddress), amountToBorrow_);
    }
    return 0;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/IERC20Metadata.sol";
import "../../libs/AppErrors.sol";
import "../../libs/EntryKinds.sol";
import "../../interfaces/IConverterController.sol";
import "../../interfaces/IPlatformAdapter.sol";
import "../../interfaces/IPoolAdapterInitializerWithRewards.sol";
import "../../integrations/compound3/IComet.sol";
import "../../integrations/compound3/ICometRewards.sol";
import "./Compound3AprLib.sol";

contract Compound3PlatformAdapter is IPlatformAdapter {
  ///////////////////////////////////////////////////////
  //region Constants
  ///////////////////////////////////////////////////////

  string public constant override PLATFORM_ADAPTER_VERSION = "1.0.2";
  //endregion Constants

  ///////////////////////////////////////////////////////
  //region Variables
  ///////////////////////////////////////////////////////

  IConverterController immutable public controller;

  /// @notice Template of pool adapter
  address immutable public converter;

  /// @dev Same as controller.borrowManager(); we cache it for gas optimization
  address immutable public borrowManager;

  /// @notice True if the platform is frozen and new borrowing is not possible (at this moment)
  bool public override frozen;

  address[] public comets;

  address public cometRewards;
  //endregion Variables

  ///////////////////////////////////////////////////////
  //region Events
  ///////////////////////////////////////////////////////

  event OnPoolAdapterInitialized(address converter, address poolAdapter, address user, address collateralAsset, address borrowAsset);
  //endregion Events

  ///////////////////////////////////////////////////////
  //region Initialization
  ///////////////////////////////////////////////////////

  constructor(address controller_, address borrowManager_, address templatePoolAdapter_, address[] memory comets_, address cometRewards_) {
    require(
      borrowManager_ != address(0)
      && templatePoolAdapter_ != address(0)
      && controller_ != address(0)
      && comets_.length > 0
      && cometRewards_ != address(0),
      AppErrors.ZERO_ADDRESS
    );

    controller = IConverterController(controller_);
    converter = templatePoolAdapter_;
    borrowManager = borrowManager_;
    comets = comets_;
    cometRewards = cometRewards_;
  }
  //endregion Initialization

  ///////////////////////////////////////////////////////
  //region Modifiers
  ///////////////////////////////////////////////////////

  /// @notice Ensure that the caller is governance
  function _onlyGovernance() internal view {
    require(controller.governance() == msg.sender, AppErrors.GOVERNANCE_ONLY);
  }
  //endregion Modifiers

  ///////////////////////////////////////////////////////
  //region Gov actions
  ///////////////////////////////////////////////////////

  /// @notice Initialize {poolAdapter_} created from {converter_} using minimal proxy pattern
  function initializePoolAdapter(address converter_, address poolAdapter_, address user_, address collateralAsset_, address borrowAsset_) external override {
    require(msg.sender == borrowManager, AppErrors.BORROW_MANAGER_ONLY);
    require(converter == converter_, AppErrors.CONVERTER_NOT_FOUND);

    // borrowAsset_ must be baseToken of comet
    for (uint i; i < comets.length; ++i) {
      if (IComet(comets[i]).baseToken() == borrowAsset_) {
        IPoolAdapterInitializerWithRewards(poolAdapter_).initialize(
          address(controller),
          comets[i],
          cometRewards,
          user_,
          collateralAsset_,
          borrowAsset_,
          converter_
        );
        emit OnPoolAdapterInitialized(converter_, poolAdapter_, user_, collateralAsset_, borrowAsset_);
        return;
      }
    }

    revert(AppErrors.INCORRECT_BORROW_ASSET);
  }

  function addComet(address comet_) external {
    _onlyGovernance();
    comets.push(comet_);
  }

  function removeComet(uint index) external {
    _onlyGovernance();
    require(index < comets.length, AppErrors.INCORRECT_VALUE);
    comets[index] = comets[comets.length - 1];
    comets.pop();
  }

  /// @notice Set platform to frozen/unfrozen state. In frozen state any new borrowing is forbidden.
  function setFrozen(bool frozen_) external {
    _onlyGovernance();
    frozen = frozen_;
  }
  //endregion Gov actions

  ///////////////////////////////////////////////////////
  //region Views
  ///////////////////////////////////////////////////////

  function converters() external view override returns (address[] memory) {
    address[] memory dest = new address[](1);
    dest[0] = converter;
    return dest;
  }

  function platformKind() external pure returns (AppDataTypes.LendingPlatformKinds) {
    return AppDataTypes.LendingPlatformKinds.COMPOUND3_5;
  }


  /// @notice Get pool data required to select best lending pool
  /// @param healthFactor2_ Health factor (decimals 2) to be able to calculate max borrow amount
  ///                       See IConverterController for explanation of health factors.
  function getConversionPlan(AppDataTypes.InputConversionParams memory p_, uint16 healthFactor2_) external view returns (
    AppDataTypes.ConversionPlan memory plan
  ) {
    require(p_.collateralAsset != address(0) && p_.borrowAsset != address(0), AppErrors.ZERO_ADDRESS);
    require(p_.amountIn != 0 && p_.countBlocks != 0, AppErrors.INCORRECT_VALUE);
    require(healthFactor2_ >= controller.minHealthFactor2(), AppErrors.WRONG_HEALTH_FACTOR);

    if (!frozen && !controller.paused()) {
      address cometAddress = _getCometForBorrowAsset(p_.borrowAsset);
      if (cometAddress != address(0)) {
        // comet was found
        IComet _comet = IComet(cometAddress);
        if (!_comet.isSupplyPaused() && !_comet.isWithdrawPaused()) {
          for (uint8 k; k < _comet.numAssets(); ++k) {
            IComet.AssetInfo memory assetInfo = _comet.getAssetInfo(k);
            if (assetInfo.asset == p_.collateralAsset) {
              // collateral asset was found

              AppDataTypes.PricesAndDecimals memory pd;
              pd.rc10powDec = 10**IERC20Metadata(p_.collateralAsset).decimals();
              pd.rb10powDec = 10**IERC20Metadata(p_.borrowAsset).decimals();
              pd.priceCollateral = Compound3AprLib.getPrice(assetInfo.priceFeed);
              pd.priceBorrow = Compound3AprLib.getPrice(_comet.baseTokenPriceFeed());

              plan.maxAmountToBorrow = IERC20(p_.borrowAsset).balanceOf(address(_comet));
              uint b = IERC20(p_.collateralAsset).balanceOf(address(_comet));
              if (b < assetInfo.supplyCap) {
                plan.maxAmountToSupply = assetInfo.supplyCap - b;
              }

              if (plan.maxAmountToBorrow > 0 && plan.maxAmountToSupply > 0) {
                plan.converter = converter;
                plan.ltv18 = assetInfo.borrowCollateralFactor;
                plan.liquidationThreshold18 = assetInfo.liquidateCollateralFactor;

                uint healthFactor18 = plan.liquidationThreshold18 * 1e18 / plan.ltv18;
                if (healthFactor18 < uint(healthFactor2_) * 10**(18 - 2)) {
                  healthFactor18 = uint(healthFactor2_) * 10**(18 - 2);
                }

                uint entryKind = EntryKinds.getEntryKind(p_.entryData);
                if (entryKind == EntryKinds.ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0) {
                  plan.collateralAmount = p_.amountIn;
                  plan.amountToBorrow = EntryKinds.exactCollateralInForMaxBorrowOut(
                    p_.amountIn,
                    healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    false
                  );
                } else if (entryKind == EntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
                  (plan.collateralAmount, plan.amountToBorrow) = EntryKinds.exactProportion(
                    p_.amountIn,
                    healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    p_.entryData,
                    false
                  );
                } else if (entryKind == EntryKinds.ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2) {
                  plan.amountToBorrow = p_.amountIn;
                  plan.collateralAmount = EntryKinds.exactBorrowOutForMinCollateralIn(
                    p_.amountIn,
                    healthFactor18,
                    plan.liquidationThreshold18,
                    pd,
                    false
                  );
                }

                if (plan.amountToBorrow > plan.maxAmountToBorrow) {
                  plan.collateralAmount = plan.collateralAmount * plan.maxAmountToBorrow / plan.amountToBorrow;
                  plan.amountToBorrow = plan.maxAmountToBorrow;
                }

                if (plan.collateralAmount > plan.maxAmountToSupply) {
                  plan.amountToBorrow = plan.amountToBorrow * plan.maxAmountToSupply / plan.collateralAmount;
                  plan.collateralAmount = plan.maxAmountToSupply;
                }

                if (plan.amountToBorrow < _comet.baseBorrowMin()) {
                  plan.converter = address(0);
                }

                plan.amountCollateralInBorrowAsset36 = plan.collateralAmount * (1e36 * pd.priceCollateral / pd.priceBorrow) / pd.rc10powDec;
                plan.borrowCost36 = Compound3AprLib.getBorrowCost36(_comet, plan.amountToBorrow, p_.countBlocks, controller.blocksPerDay(), pd.rb10powDec);
                plan.rewardsAmountInBorrowAsset36 = Compound3AprLib.getRewardsAmountInBorrowAsset36(_comet, cometRewards, controller, plan.amountToBorrow, p_.countBlocks, controller.blocksPerDay(), pd.rb10powDec);
              }
              break;
            }
          }
        }
      }
    }

    if (plan.converter == address(0)) {
      AppDataTypes.ConversionPlan memory planNotFound;
      return planNotFound;
    } else {
      return plan;
    }
  }

  function _getCometForBorrowAsset(address borrowAsset) internal view returns(address) {
    uint length = comets.length;
    for (uint i; i < length; ++i) {
      IComet _comet = IComet(comets[i]);
      if (_comet.baseToken() == borrowAsset) {
        return address(_comet);
      }
    }
    return address(0);
  }

  function cometsLength() external view returns (uint) {
    return comets.length;
  }
  //endregion Views
}