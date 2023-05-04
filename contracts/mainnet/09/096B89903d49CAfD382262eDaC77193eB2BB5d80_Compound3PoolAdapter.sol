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

import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/Initializable.sol";
import "../../libs/AppErrors.sol";
import "../../interfaces/IConverterController.sol";
import "../../interfaces/IPoolAdapter.sol";
import "../../interfaces/IPoolAdapterInitializerWithRewards.sol";
import "../../interfaces/IDebtMonitor.sol";
import "../../integrations/compound3/IComet.sol";
import "../../integrations/compound3/ICometRewards.sol";
import "./Compound3AprLib.sol";

contract Compound3PoolAdapter is IPoolAdapter, IPoolAdapterInitializerWithRewards, Initializable {
  using SafeERC20 for IERC20;

  ///////////////////////////////////////////////////////
  //region Variables
  ///////////////////////////////////////////////////////

  address public collateralAsset;
  address public borrowAsset;
  address public user;
  IComet public comet;
  ICometRewards public cometRewards;
  IConverterController public controller;
  address public originConverter;
  uint public collateralTokensBalance;
  //endregion Variables

  ///////////////////////////////////////////////////////
  //region Events
  ///////////////////////////////////////////////////////

  event OnInitialized(address controller, address pool, address user, address collateralAsset, address borrowAsset, address originConverter);
  event OnBorrow(uint collateralAmount, uint borrowAmount, address receiver, uint resultHealthFactor18);
  event OnBorrowToRebalance(uint borrowAmount, address receiver, uint resultHealthFactor18);
  event OnRepay(uint amountToRepay, address receiver, bool closePosition, uint resultHealthFactor18);
  event OnRepayToRebalance(uint amount, bool isCollateral, uint resultHealthFactor18);
  event OnClaimRewards(address rewardToken, uint amount, address receiver);
  event OnSalvage(address receiver, address token, uint amount);
  //endregion Events

  //-----------------------------------------------------
  //region Data type
  //-----------------------------------------------------
  struct RepayLocalVars {
    IConverterController c;
    IComet comet;
    address assetBorrow;
    address assetCollateral;
  }
  //endregion Data type

  ///////////////////////////////////////////////////////
  //region Initialization and salvage
  ///////////////////////////////////////////////////////

  function initialize(
    address controller_,
    address comet_,
    address cometRewards_,
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    address originConverter_
  ) external initializer {
    require(
      controller_ != address(0)
      && comet_ != address(0)
      && cometRewards_ != address(0)
      && user_ != address(0)
      && collateralAsset_ != address(0)
      && borrowAsset_ != address(0)
      && originConverter_ != address(0),
      AppErrors.ZERO_ADDRESS
    );

    controller = IConverterController(controller_);
    user = user_;
    collateralAsset = collateralAsset_;
    borrowAsset = borrowAsset_;
    originConverter = originConverter_;

    comet = IComet(comet_);
    cometRewards = ICometRewards(cometRewards_);

    // The pool adapter doesn't keep assets on its balance, so it's safe to use infinity approve
    // All approves replaced by infinity-approve were commented in the code below
    IERC20(collateralAsset_).safeApprove(comet_, 2**255); // 2*255 is more gas-efficient than type(uint).max
    IERC20(borrowAsset_).safeApprove(comet_, 2**255);

    emit OnInitialized(controller_, comet_, user_, collateralAsset_, borrowAsset_, originConverter_);
  }

  /// @notice Save any token from balance to {receiver}
  /// @dev Normally this contract doesn't have any tokens on balance
  function salvage(address receiver, address token, uint amount) external {
    require(msg.sender == controller.governance(), AppErrors.GOVERNANCE_ONLY);

    IERC20(token).safeTransfer(receiver, amount);
    emit OnSalvage(receiver, token, amount);
  }
  //endregion Initialization and salvage

  ///////////////////////////////////////////////////////
  //region Modifiers
  ///////////////////////////////////////////////////////

  /// @notice Ensure that the caller is TetuConverter
  function _onlyTetuConverter(IConverterController controller_) internal view {
    require(controller_.tetuConverter() == msg.sender, AppErrors.TETU_CONVERTER_ONLY);
  }
  //endregion Modifiers

  ///////////////////////////////////////////////////////
  //region Views
  ///////////////////////////////////////////////////////

  function getConfig() external view returns (
    address originConverter_,
    address user_,
    address collateralAsset_,
    address borrowAsset_
  ) {
    return (originConverter, user, collateralAsset, borrowAsset);
  }

  function getStatus() external view returns (
    uint collateralAmount,
    uint amountToPay,
    uint healthFactor18,
    bool opened,
    uint collateralAmountLiquidated,
    bool debtGapRequired
  ) {
    (
    uint tokenBalanceOut,
    uint borrowBalanceOut,
    uint collateralAmountBase,
    uint sumBorrowBase,,,
    uint liquidateCollateralFactor
    ) = _getStatus();

    (, healthFactor18) = _getHealthFactor(liquidateCollateralFactor, collateralAmountBase, sumBorrowBase);

    opened = tokenBalanceOut != 0 || borrowBalanceOut != 0;
    collateralAmount = tokenBalanceOut;
    amountToPay = borrowBalanceOut;
    if (collateralTokensBalance > tokenBalanceOut) {
      collateralAmountLiquidated = collateralTokensBalance - tokenBalanceOut;
    }
    debtGapRequired = false;
  }

  /// @notice If we paid {amountToRepay_}, how much collateral would we receive?
  function getCollateralAmountToReturn(uint amountToRepay_, bool closePosition_) external view returns (uint) {
    (uint amount,) = _getCollateralAmountToReturn(comet, collateralAsset, amountToRepay_, closePosition_);
    return amount;
  }

  function getConversionKind() external pure returns (AppDataTypes.ConversionKind) {
    return AppDataTypes.ConversionKind.BORROW_2;
  }
  //endregion Views

  ///////////////////////////////////////////////////////
  //region External logic
  ///////////////////////////////////////////////////////

  function updateStatus() external {
    comet.accrueAccount(address(this));
  }

  function borrow(uint collateralAmount_, uint borrowAmount_, address receiver_) external returns (
    uint borrowedAmountOut
  ) {
    IConverterController c = controller;
    _onlyTetuConverter(c);

    address assetCollateral = collateralAsset;
    address assetBorrow = borrowAsset;

    IERC20(assetCollateral).safeTransferFrom(msg.sender, address(this), collateralAmount_);
    uint tokenBalanceBefore = _supply(assetCollateral, collateralAmount_);

    // make borrow
    uint balanceBorrowAsset0 = _getBalance(assetBorrow);
    comet.withdraw(assetBorrow, borrowAmount_);

    // ensure that we have received required borrowed amount, send the amount to the receiver
    require(
      borrowAmount_ + balanceBorrowAsset0 == IERC20(assetBorrow).balanceOf(address(this)),
      AppErrors.WRONG_BORROWED_BALANCE
    );
    IERC20(assetBorrow).safeTransfer(receiver_, borrowAmount_);

    // register the borrow in DebtMonitor
    IDebtMonitor(c.debtMonitor()).onOpenPosition();

    // ensure that current health factor is greater than min allowed
    (uint healthFactor, uint tokenBalanceAfter) = _validateHealthStatusAfterBorrow(c);
    require(tokenBalanceAfter >= tokenBalanceBefore, AppErrors.WEIRD_OVERFLOW); // overflow below is not possible
    collateralTokensBalance += tokenBalanceAfter - tokenBalanceBefore;

    emit OnBorrow(collateralAmount_, borrowAmount_, receiver_, healthFactor);

    return borrowAmount_;
  }

  function borrowToRebalance(uint borrowAmount_, address receiver_) external returns (
    uint resultHealthFactor18,
    uint borrowedAmountOut
  ) {
    IConverterController c = controller;
    _onlyTetuConverter(c);
    address assetBorrow = borrowAsset;

    // ensure that the position is opened
    require(IDebtMonitor(c.debtMonitor()).isPositionOpened(), AppErrors.BORROW_POSITION_IS_NOT_REGISTERED);

    // make borrow
    uint balanceBorrowAsset0 = _getBalance(assetBorrow);
    comet.withdraw(assetBorrow, borrowAmount_);

    require(
      borrowAmount_ + balanceBorrowAsset0 == IERC20(assetBorrow).balanceOf(address(this)),
      AppErrors.WRONG_BORROWED_BALANCE
    );
    IERC20(assetBorrow).safeTransfer(receiver_, borrowAmount_);

    // ensure that current health factor is greater than min allowed
    (resultHealthFactor18,) = _validateHealthStatusAfterBorrow(c);

    emit OnBorrowToRebalance(borrowAmount_, receiver_, resultHealthFactor18);
    return (resultHealthFactor18, borrowAmount_);
  }

  function repay(uint amountToRepay_, address receiver_, bool closePosition_) external returns (
    uint collateralAmountOut
  ) {
    RepayLocalVars memory vars = RepayLocalVars(controller, comet, borrowAsset, collateralAsset);
    _onlyTetuConverter(vars.c);

    uint bb = vars.comet.borrowBalanceOf(address(this));
    if (amountToRepay_ > bb) {
      IERC20(vars.assetBorrow).safeTransferFrom(msg.sender, receiver_, amountToRepay_ - bb);
      amountToRepay_ = bb;
    }
    IERC20(vars.assetBorrow).safeTransferFrom(msg.sender, address(this), amountToRepay_);

    uint collateralBalanceBefore;
    (collateralAmountOut, collateralBalanceBefore) = _getCollateralAmountToReturn(vars.comet, vars.assetCollateral, amountToRepay_, closePosition_);
    vars.comet.supply(vars.assetBorrow, amountToRepay_);

    vars.comet.withdraw(vars.assetCollateral, collateralAmountOut);

    IERC20(vars.assetCollateral).safeTransfer(receiver_, collateralAmountOut);

    (
    uint collateralBalance,
    uint borrowBalance,
    uint collateralBase,
    uint borrowBase,,,
    uint liquidateCollateralFactor
    ) = _getStatus();

    uint healthFactor18;
    if (collateralBalance == 0 && borrowBalance == 0) {
      IDebtMonitor(vars.c.debtMonitor()).onClosePosition();
    } else {
      require(!closePosition_, AppErrors.CLOSE_POSITION_FAILED);

      (,healthFactor18) = _getHealthFactor(liquidateCollateralFactor, collateralBase, borrowBase);
      _validateHealthFactor(vars.c, healthFactor18);
    }

    require(collateralBalanceBefore >= collateralBalance && collateralTokensBalance >= collateralBalanceBefore - collateralBalance, AppErrors.WEIRD_OVERFLOW);
    collateralTokensBalance -= collateralBalanceBefore - collateralBalance;

    emit OnRepay(amountToRepay_, receiver_, closePosition_, healthFactor18);
  }

  function repayToRebalance(uint amount_, bool isCollateral_) external returns (
    uint resultHealthFactor18
  ) {
    IConverterController c = controller;
    _onlyTetuConverter(c);

    // ensure that the position is opened
    require(IDebtMonitor(c.debtMonitor()).isPositionOpened(), AppErrors.BORROW_POSITION_IS_NOT_REGISTERED);

    uint collateralBalanceBefore;

    if (isCollateral_) {
      address assetCollateral = collateralAsset;
      IERC20(assetCollateral).safeTransferFrom(msg.sender, address(this), amount_);
      collateralBalanceBefore = _supply(assetCollateral, amount_);
    } else {
      address assetBorrow = borrowAsset;
      // ensure, that amount to repay is less then the total debt
      uint borrowBalance;
      (collateralBalanceBefore, borrowBalance,,,,,) = _getStatus();
      require(borrowBalance != 0 && amount_ < borrowBalance, AppErrors.REPAY_TO_REBALANCE_NOT_ALLOWED);

      IERC20(assetBorrow).safeTransferFrom(msg.sender, address(this), amount_);

      comet.supply(assetBorrow, amount_);
    }

    (
    uint collateralBalance,,
    uint collateralBase,
    uint borrowBase,,,
    uint liquidateCollateralFactor
    ) = _getStatus();

    (,resultHealthFactor18) = _getHealthFactor(liquidateCollateralFactor, collateralBase, borrowBase);
    _validateHealthFactor(c, resultHealthFactor18);

    require(collateralBalance >= collateralBalanceBefore, AppErrors.WEIRD_OVERFLOW);
    collateralTokensBalance += collateralBalance - collateralBalanceBefore;

    emit OnRepayToRebalance(amount_, isCollateral_, resultHealthFactor18);
  }

  function claimRewards(address receiver_) external returns (address rewardToken, uint amount) {
    _onlyTetuConverter(controller);

    ICometRewards.RewardConfig memory config = cometRewards.rewardConfig(address(comet));
    rewardToken = config.token;

    cometRewards.claim(address(comet), address(this), true);
    amount = IERC20(rewardToken).balanceOf(address(this));
    if (amount != 0) {
      IERC20(rewardToken).safeTransfer(receiver_, amount);
      emit OnClaimRewards(rewardToken, amount, receiver_);
    }
  }
  //endregion External logic

  ///////////////////////////////////////////////////////
  //region Internal logic
  ///////////////////////////////////////////////////////

  /// @notice Supply collateral to Compound3
  /// @return Collateral token balance before supply
  function _supply(
    address assetCollateral_,
    uint collateralAmount_
  ) internal returns (uint) {
    uint tokenBalanceBefore = comet.userCollateral(address(this), assetCollateral_).balance;
    comet.supply(assetCollateral_, collateralAmount_);
    return tokenBalanceBefore;
  }

  /// @return (Health factor, decimal 18; collateral-token-balance)
  function _validateHealthStatusAfterBorrow(IConverterController controller_) internal view returns (uint, uint) {
    (
    uint tokenBalance,,
    uint collateralBase,
    uint borrowBase,,,
    uint liquidateCollateralFactor
    ) = _getStatus();

    (
    uint sumCollateralSafe,
    uint healthFactor18
    ) = _getHealthFactor(liquidateCollateralFactor, collateralBase, borrowBase);

    require(sumCollateralSafe > borrowBase && borrowBase != 0, AppErrors.INCORRECT_RESULT_LIQUIDITY);

    _validateHealthFactor(controller_, healthFactor18);
    return (healthFactor18, tokenBalance);
  }

  function _validateHealthFactor(IConverterController controller_, uint hf18) internal view {
    require(hf18 > uint(controller_.minHealthFactor2())*10**(18-2), AppErrors.WRONG_HEALTH_FACTOR);
  }

  /// @return tokenBalanceOut Count of collateral tokens on balance
  /// @return borrowBalanceOut Borrow amount [borrow asset units]
  /// @return collateralAmountBase Total collateral in base currency, decimals 8
  /// @return sumBorrowBase Total borrow amount in base currency, decimals 8
  function _getStatus() internal view returns (
    uint tokenBalanceOut,
    uint borrowBalanceOut,
    uint collateralAmountBase,
    uint sumBorrowBase,
    uint collateralAssetPrice,
    uint borrowAssetPrice,
    uint liquidateCollateralFactor
  ) {
    IComet _comet = comet;
    tokenBalanceOut = _comet.userCollateral(address(this), collateralAsset).balance;
    IComet.AssetInfo memory assetInfo = _comet.getAssetInfoByAddress(collateralAsset);
    collateralAssetPrice = Compound3AprLib.getPrice(assetInfo.priceFeed);
    collateralAmountBase = tokenBalanceOut * collateralAssetPrice / 10 ** IERC20Metadata(collateralAsset).decimals();
    borrowBalanceOut = _comet.borrowBalanceOf(address(this));
    borrowAssetPrice = Compound3AprLib.getPrice(comet.baseTokenPriceFeed());
    sumBorrowBase = borrowBalanceOut * borrowAssetPrice / 10 ** IERC20Metadata(borrowAsset).decimals();
    liquidateCollateralFactor = assetInfo.liquidateCollateralFactor;
  }

  function _getHealthFactor(uint liquidateCollateralFactor, uint sumCollateralBase, uint sumBorrowBase) internal pure returns (
    uint sumCollateralSafe,
    uint healthFactor18
  ) {
    sumCollateralSafe = liquidateCollateralFactor * sumCollateralBase / 1e18;
    healthFactor18 = sumBorrowBase == 0 ? type(uint).max : sumCollateralSafe * 1e18 / sumBorrowBase;
  }

  function _getBalance(address asset) internal view returns (uint) {
    return IERC20(asset).balanceOf(address(this));
  }

  /// @notice Get a part of collateral safe to return after repaying {amountToRepay_}
  /// @param amountToRepay_ Amount to be repaid [in borrowed tokens]
  /// @return Amount of collateral [in collateral tokens] to be returned in exchange of {borrowedAmount_}, full balance of collateral tokens
  function _getCollateralAmountToReturn(
    IComet comet_,
    address assetCollateral_,
    uint amountToRepay_,
    bool closePosition_
  ) internal view returns (uint, uint) {
    uint collateralBalance = comet_.userCollateral(address(this), assetCollateral_).balance;
    uint borrowBalance = comet_.borrowBalanceOf(address(this));

    require(borrowBalance != 0, AppErrors.ZERO_BALANCE);

    if (closePosition_) {
      require(borrowBalance <= amountToRepay_, AppErrors.CLOSE_POSITION_PARTIAL);

      return (collateralBalance, collateralBalance);
    } else {
      require(amountToRepay_ <= borrowBalance, AppErrors.WRONG_BORROWED_BALANCE);
    }

    return (collateralBalance * amountToRepay_ / borrowBalance, collateralBalance);
  }
  //endregion Internal logic
}