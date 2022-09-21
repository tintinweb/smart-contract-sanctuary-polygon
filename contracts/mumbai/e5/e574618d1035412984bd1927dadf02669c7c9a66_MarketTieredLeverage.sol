// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

// import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../abstract/AccessControlledAndUpgradeable.sol";
import "../../abstract/ProxyNonPayable.sol";

import "../../interfaces/IMarketTieredLeverage.sol";
import "../../interfaces/IOracleManagerFixedEpoch.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/ISyntheticTokenMarketUpgradeable.sol";
import "../../interfaces/IYieldManager.sol";
import "../../interfaces/IGEMS.sol";

import "./MarketStorage.sol";
import "./MarketExtended.sol";

abstract contract MarketTieredLeverageGetters is IMarketTieredLeverage, MarketStorage {
  /// @notice Returns the number of pools of poolType i.e. Long or Short
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @return numberOfPoolsOfType Number of pools of poolType
  function numberOfPoolsOfType(IMarketCommon.PoolType poolType) external view returns (uint256) {
    return _numberOfPoolsOfType[uint8(poolType)];
  }

  /// @notice Returns the interface of OracleManager for the market
  /// @return _oracleManager OracleManager interface
  function oracleManager() external view returns (IOracleManagerFixedEpoch) {
    return _oracleManager;
  }

  /// @notice Returns the address of the YieldManager for the market
  /// @return _yieldManager address of the YieldManager
  function yieldManager() external view returns (address) {
    return _yieldManager;
  }

  /// @notice Returns the deposit action in payment tokens of provided user for the given poolType and poolTier.
  /// @dev Action amounts have a fixed 18 decimals.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return user_paymentToken_depositAction Outstanding deposit action by user for the given poolType and poolTier.
  function user_paymentToken_depositAction(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (IMarketCommon.UserAction memory) {
    return _user_paymentToken_depositAction[user][poolType][poolTier];
  }

  /// @notice Returns the redeem action in synthetic tokens of provided user for the given poolType and poolTier.
  /// @dev Action amounts have a fixed 18 decimals.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return user_syntheticToken_redeemAction Outstanding redeem action by user for the given poolType and poolTier.
  function user_syntheticToken_redeemAction(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (IMarketCommon.UserAction memory) {
    return _user_syntheticToken_redeemAction[user][poolType][poolTier];
  }

  /// @notice Returns the pool struct given poolType and poolTier.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return pools Struct containing information about the pool i.e. value, leverage etc.
  function pools(IMarketCommon.PoolType poolType, uint256 poolTier)
    external
    view
    returns (IMarketCommon.Pool memory)
  {
    return _pools[poolType][poolTier];
  }

  /// @notice Returns the price of the synthetic token given poolType and poolTier.
  /// @dev Prices have a fixed 18 decimals.
  /// @param currentExecutedEpoch Number of epoch that has been executed.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return syntheticToken_priceSnapshot Price of the synthetic tokens in the pool.
  function syntheticToken_priceSnapshot(
    uint32 currentExecutedEpoch,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (uint256) {
    return _syntheticToken_priceSnapshot[currentExecutedEpoch][poolType][poolTier];
  }

  /// @notice Returns the epochInfo struct.
  /// @return _epochInfo Struct containing info about the latest executed epoch and previous epoch.
  function epochInfo() external view returns (IMarketCommon.EpochInfo memory) {
    return _epochInfo;
  }
}

contract MarketTieredLeverageLogic is
  AccessControlledAndUpgradeableModifiers,
  MarketTieredLeverageGetters
{
  using SafeERC20 for IERC20;
  /*╔═════════════════════════════╗
    ║           TYPES             ║
    ╚═════════════════════════════╝*/

  struct PoolId {
    IMarketCommon.PoolType poolType;
    uint8 index;
  }

  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Deposit(
    uint8 indexed poolId,
    uint256 depositAdded,
    address indexed user,
    uint32 indexed epoch
  );

  event Redeem(
    uint8 indexed poolId,
    uint256 synthRedeemed,
    address indexed user,
    uint32 indexed epoch
  );

  // TODO URGENT: think of edge-case where this is in EWT. Maybe just handled by the backend.
  event ExecuteEpochSettlementMintUser(
    uint8 indexed poolId,
    address indexed user,
    uint32 indexed epochSettledUntil
  );

  event ExecuteEpochSettlementRedeemUser(
    uint8 indexed poolId,
    address indexed user,
    uint32 indexed epochSettledUntil
  );

  struct PoolState {
    uint8 poolId;
    uint256 tokenSupply;
    uint256 value;
  }

  event SystemUpdateInfo(
    uint32 indexed epoch,
    uint256 underlyingAssetPrice,
    PoolState[] poolStates
  );

  event OracleUpdated(address oldOracleAddress, address newOracleAddress);

  event MarketDeprecated();

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  function gemCollectingModifierLogic(address user) internal virtual {
    // TODO: fix me - on market deploy, make new market have GEM minter role.
    IGEMS(_gems).gm(user);
  }

  modifier gemCollecting(address user) {
    gemCollectingModifierLogic(user);
    _;
  }

  /// @notice Updates the state of a market to account for the latest oracle price update.
  /// @dev We have to check market not deprecated to avoid changing state once deprecated
  modifier systemStateUpdated() {
    require(!marketDeprecated, "Market deprecated, use exitDeprecatedMarket");
    _updateSystemStateInternal(0);
    _;
  }

  modifier checkMintingNotPaused() {
    require(!mintingPaused, "No minting, market paused");
    _;
  }

  modifier checkMarketNotDeprecated() {
    require(!marketDeprecated, "Market deprecated, use exitDeprecatedMarket");
    _;
  }

  IRegistry immutable _longShort; // original core contract
  address immutable _gems;
  address public immutable _paymentToken;

  constructor(address paymentToken, IRegistry longShort) {
    require(paymentToken != address(0) && address(longShort) != address(0));
    _paymentToken = paymentToken;

    _longShort = longShort; // original core contract
    _gems = longShort.gems();
  }

  /*╔══════════════════════════════╗
    ║       GETTER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  /// @notice - this assumes that we will never have more than 16 tier types, and 16 tiers of a given tier type.
  function packPoolId(IMarketCommon.PoolType poolType, uint8 poolTier)
    internal
    pure
    virtual
    returns (uint8)
  {
    return (uint8(poolType) << 4) | poolTier;
  }

  /// @notice Calculates the conversion rate from synthetic tokens to payment tokens.
  /// @dev Synth tokens have a fixed 18 decimals.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @return syntheticTokenPrice The calculated conversion rate in base 1e18.
  function _getSyntheticTokenPrice(
    uint256 amountPaymentTokenBackingSynth,
    uint256 amountSyntheticToken
  ) internal view virtual returns (uint256 syntheticTokenPrice) {
    return (amountPaymentTokenBackingSynth * 1e18) / amountSyntheticToken;
  }

  /// @notice Converts synth token amounts to payment token amounts at a synth token price.
  /// @dev Price assumed base 1e18.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountPaymentToken The calculated amount of payment tokens in token's lowest denomination.
  function _getAmountPaymentToken(
    uint256 amountSyntheticToken,
    uint256 syntheticTokenPriceInPaymentTokens
  ) public pure virtual returns (uint256 amountPaymentToken) {
    return (amountSyntheticToken * syntheticTokenPriceInPaymentTokens) / 1e18;
  }

  /// @notice Converts payment token amounts to synth token amounts at a synth token price.
  /// @dev  Price assumed base 1e18.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountSyntheticToken The calculated amount of synthetic token in wei.
  function _getAmountSyntheticToken(
    uint256 amountPaymentTokenBackingSynth,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountSyntheticToken) {
    return (amountPaymentTokenBackingSynth * 1e18) / syntheticTokenPriceInPaymentTokens;
  }

  /// @notice Calculates effective liquidity of a pool given its actual liquidity and leverage.
  /// @dev  Value assumed base 1e18.
  /// @param value Actual liquidity of the pool.
  /// @param leverage Leverage of the pool.
  /// @return effectiveLiquidity Calculated as product of actual liquidity and leverage of the pool.
  function _calculateEffectiveLiquidityForPool(uint256 value, uint256 leverage)
    internal
    pure
    returns (uint256 effectiveLiquidity)
  {
    return (value * leverage) / 1e18;
  }

  /// @notice Calculates effective liquidity of each side.
  /// @dev  Value assumed base 1e18.
  /// @return effectiveLiquidityPoolType List of effective liquidity of long and short, the sum of effective liquidity of every pool on each side.
  function calculateEffectiveLiquidity()
    public
    view
    returns (uint256[2] memory effectiveLiquidityPoolType)
  {
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint256 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        effectiveLiquidityPoolType[poolType] += _calculateEffectiveLiquidityForPool(
          _pools[IMarketCommon.PoolType(poolType)][poolTier].value,
          _pools[IMarketCommon.PoolType(poolType)][poolTier].leverage
        );
      }
    }
  }

  // This function is purely for testing and can be removed... @jasoons
  function calculateActualLiquidity() public view returns (uint256 actualLiquidity) {
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint256 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        actualLiquidity += _pools[IMarketCommon.PoolType(poolType)][poolTier].value;
      }
    }
  }

  /// @notice Returns the balance of user actions in epochs which have been executed but not yet distributed to users.
  /// @dev Prices have a fixed 18 decimals.
  /// @param user Address of user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return confirmedButNotSettledBalance Returns balance of user actions in epochs which have been executed but not yet distributed to users.
  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    IMarketCommon.PoolType poolType,
    uint8 poolTier
  ) external view returns (uint256 confirmedButNotSettledBalance) {
    IMarketCommon.UserAction storage userAction = _user_paymentToken_depositAction[user][poolType][
      poolTier
    ];

    if (
      userAction.correspondingEpoch != 0 &&
      userAction.correspondingEpoch <= _epochInfo.latestExecutedEpochIndex
    ) {
      if (userAction.amount > 0) {
        uint256 syntheticTokenPrice = _syntheticToken_priceSnapshot[userAction.correspondingEpoch][
          poolType
        ][poolTier];

        assert(syntheticTokenPrice > 0);
        confirmedButNotSettledBalance = _getAmountSyntheticToken(
          userAction.amount,
          syntheticTokenPrice
        );
      }

      if (
        userAction.nextEpochAmount > 0 &&
        userAction.correspondingEpoch < _epochInfo.latestExecutedEpochIndex // Check that a price exists for the NEXT epoch
      ) {
        uint256 syntheticTokenPrice = _syntheticToken_priceSnapshot[
          userAction.correspondingEpoch + 1
        ][poolType][poolTier];

        assert(syntheticTokenPrice > 0);
        confirmedButNotSettledBalance += _getAmountSyntheticToken(
          userAction.nextEpochAmount,
          syntheticTokenPrice
        );
      }
    }
  }

  /*╔═══════════════════════════════╗
    ║     UPDATING SYSTEM STATE     ║
    ╚═══════════════════════════════╝*/

  /// @notice This calculates the value transfer from the overbalanced to underbalanced side (i.e. the funding rate)
  /// This is a further incentive measure to balanced markets. This may be present on some and not other synthetic markets.
  /// @param _fundingRateMultiplier_e18 A scalar base e18 for the funding rate.
  /// @param overbalancedValue Side with more liquidity.
  /// @param underbalancedValue Side with less liquidity.
  /// @return fundingAmount The amount the overbalanced side needs to pay the underbalanced.
  function _calculateFundingAmount(
    uint256 _fundingRateMultiplier_e18,
    uint256 overbalancedValue,
    uint256 underbalancedValue
  ) internal view virtual returns (uint256 fundingAmount) {
    /*
    overBalanced * (1 - underBalanced/overBalanced)
      = overBalanced * (overBalanced - underBalanced)/overBalanced)
      = overBalanced - underBalanced
      = market imbalance

    funding amount = market imbalance * yearlyMaxFundingRate * epoch_length_in_seconds / (365.25days in seconds base e18)
    */
    fundingAmount =
      ((overbalancedValue - underbalancedValue) *
        _fundingRateMultiplier_e18 *
        _oracleManager.EPOCH_LENGTH()) /
      SECONDS_IN_A_YEAR_e18;
  }

  /// @notice Returns the effective liquidity shift between long and short sides due to observed price change.
  /// @dev gets the value transfer from short to long (positive is a gain for long, negative is a gain for short)
  /// @param effectiveValueLong Effective liquidity of all pools on the Long side.
  /// @param effectiveValueShort Effective liquidity of all pools on the Short side.
  /// @param previousPrice Previous epoch execution price.
  /// @param currentPrice Current epoch execution price.
  /// @return effectiveValueChange Represents the effective liquidity shift between long and short sides due to observed price change.
  function getEffectiveValueChange(
    uint256 effectiveValueLong,
    uint256 effectiveValueShort,
    int256 previousPrice,
    int256 currentPrice
  ) public view virtual returns (int256 effectiveValueChange) {
    int256 priceMovement = (1e18 * (currentPrice - previousPrice)) / previousPrice;
    int256 finalPercentageMovement;
    int256 directionScalar;

    if (priceMovement > 0) {
      directionScalar = 1;
    } else {
      directionScalar = -1;
    }
    finalPercentageMovement =
      directionScalar *
      int256(Math.min(uint256(directionScalar * priceMovement), (maxPercentChange)));

    effectiveValueChange =
      (finalPercentageMovement * int256(Math.min(effectiveValueShort, effectiveValueLong))) /
      1e18;

    if (fundingRateMultiplier_e18 > 0) {
      //  slow drip interest funding payment here.

      if (effectiveValueLong < effectiveValueShort) {
        effectiveValueChange += int256(
          _calculateFundingAmount(
            fundingRateMultiplier_e18,
            effectiveValueShort,
            effectiveValueLong
          )
        );
      } else {
        effectiveValueChange -= int256(
          _calculateFundingAmount(
            fundingRateMultiplier_e18,
            effectiveValueLong,
            effectiveValueShort
          )
        );
      }
    }
  }

  /// @notice Returns the proportionate value change for the pool, given its effective liquidity relative to total effective liquidity of the side.
  /// @param totalEffectiveLiquidity Effective liquidity of all pools on the side.
  /// @param valueChange Effective value change from short to long.
  /// @param poolValue Actual liquidity of the pool.
  /// @param leverage Leverage of the pool.
  /// @return valueChangeForPool Represents the proportionate value change for the pool, due to the price change.
  function getValueChangeForPool(
    uint256 totalEffectiveLiquidity,
    int256 valueChange,
    uint256 poolValue,
    uint256 leverage,
    IMarketCommon.PoolType poolType
  ) public view virtual returns (int256 valueChangeForPool) {
    int256 directionScalar = 1;
    if (poolType == IMarketCommon.PoolType.SHORT) {
      directionScalar = -1;
    }
    valueChangeForPool =
      (int256(_calculateEffectiveLiquidityForPool(poolValue, leverage)) *
        valueChange *
        directionScalar) /
      int256(totalEffectiveLiquidity);
  }

  /// @notice Reblances the pool given the epoch execution information and can also perform batched actions from the epoch.
  /// @param previousPrice Previous epoch execution price.
  /// @param epochToExecute Struct containing execution info for the given epoch.
  /// @param shouldExecuteBatchedOutstandingActions Boolean parameter to decide whether batched actions from the epoch should be performed after rebalancing.
  function _rebalanceMarketPoolsCalculatePriceAndExecuteBatches(
    int256 previousPrice,
    IOracleManagerFixedEpoch.MissedEpochExecutionInfo memory epochToExecute,
    bool shouldExecuteBatchedOutstandingActions
  ) internal {
    uint256[2] memory totalEffectiveLiquidityPoolType = calculateEffectiveLiquidity();

    int256 effectiveValueChange = getEffectiveValueChange(
      totalEffectiveLiquidityPoolType[uint256(IMarketCommon.PoolType.LONG)],
      totalEffectiveLiquidityPoolType[uint256(IMarketCommon.PoolType.SHORT)],
      // this is the previous execution price, not the previous oracle update price
      previousPrice,
      epochToExecute.oraclePrice
    );

    uint256 totalPools;
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      totalPools += _numberOfPoolsOfType[poolType];
    }

    PoolState[] memory poolStates = new PoolState[](totalPools);
    uint8 currentPoolStateIndex;

    // calculate how much to distribute to winning side and extract from losing side (and do save result)
    // IntermediateEpochState memory intermediateEpochState;
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint8 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        int256 valueChangeForPool = getValueChangeForPool(
          totalEffectiveLiquidityPoolType[uint256(IMarketCommon.PoolType(poolType))],
          effectiveValueChange,
          _pools[IMarketCommon.PoolType(poolType)][poolTier].value,
          _pools[IMarketCommon.PoolType(poolType)][poolTier].leverage,
          IMarketCommon.PoolType(poolType)
        );

        _pools[IMarketCommon.PoolType(poolType)][poolTier].value = uint256(
          int256(_pools[IMarketCommon.PoolType(poolType)][poolTier].value) + valueChangeForPool
        );

        uint256 tokenSupply = ISyntheticToken(
          _pools[IMarketCommon.PoolType(poolType)][poolTier].token
        ).totalSupply();

        uint256 price = _getSyntheticTokenPrice(
          _pools[IMarketCommon.PoolType(poolType)][poolTier].value,
          tokenSupply
        );

        if (shouldExecuteBatchedOutstandingActions) {
          _batchConfirmOutstandingPendingActionsPool(
            epochToExecute.associatedEpochIndex,
            IMarketCommon.PoolType(poolType),
            poolTier,
            price
          );
        }

        _syntheticToken_priceSnapshot[epochToExecute.associatedEpochIndex][
          IMarketCommon.PoolType(poolType)
        ][poolTier] = price;

        poolStates[currentPoolStateIndex] = PoolState({
          poolId: packPoolId(IMarketCommon.PoolType(poolType), poolTier),
          tokenSupply: tokenSupply,
          value: _pools[IMarketCommon.PoolType(poolType)][poolTier].value
        });
        currentPoolStateIndex++;
      }
    }

    emit SystemUpdateInfo(
      epochToExecute.associatedEpochIndex,
      uint256(epochToExecute.oraclePrice),
      poolStates
    );
  }

  /// @notice Updates the value of the long and short sides to account for latest oracle price updates and batches all next price actions.
  /// @dev To prevent front-running only executes on price change from an oracle.
  /// @dev We assume the function will be called for each market at least once per price update.
  /// @dev Even if not called on every price update, this won't affect security, it will only affect how closely e synthetic asset actually tracks the underlying asset.
  /// @param specificNumberOfEpochsToUpdate Specific number of epochs to catch up - 0 is used as a default value when any variable number of epochs should be caught up.
  function _updateSystemStateInternal(uint256 specificNumberOfEpochsToUpdate) internal virtual {
    uint256 currentEpochIndex = _oracleManager.getCurrentEpochIndex();
    int256 previousPrice;
    uint32 currentEpochStartTimestamp;
    bool shouldExecuteBatchedOutstandingActions;

    IOracleManagerFixedEpoch.MissedEpochExecutionInfo[] memory epochsToExecute;

    if (specificNumberOfEpochsToUpdate > 2) {
      (currentEpochStartTimestamp, , previousPrice, epochsToExecute) = _oracleManager
        .getOracleInfoForSystemStateUpdate(
          _epochInfo.latestExecutedEpochIndex,
          _epochInfo.previousExecutionPriceOracleIdentifier,
          _epochInfo.previousEpochEndTimestamp,
          specificNumberOfEpochsToUpdate
        );
    } else {
      if (
        (uint256(_epochInfo.latestExecutedEpochIndex) == currentEpochIndex - 1) ||
        (uint256(_epochInfo.latestExecutedEpochIndex) == currentEpochIndex - 2 &&
          _oracleManager.inMewt())
      ) {
        // if the previous epoch has been executed then there is nothing to do
        // if the previous previous epoch has been executed AND we are in EWT then there is nothing to do
        _epochInfo.previousEpochIndex = uint32(currentEpochIndex) - 1;
        _epochInfo.previousEpochEndTimestamp = uint32(_oracleManager.getEpochStartTimestamp());
        return;
      }

      (currentEpochStartTimestamp, , previousPrice, epochsToExecute) = _oracleManager
        .getCompleteOracleInfoForSystemStateUpdate(
          _epochInfo.latestExecutedEpochIndex,
          _epochInfo.previousExecutionPriceOracleIdentifier,
          _epochInfo.previousEpochEndTimestamp
        );
    }

    uint256 numberOfEpochsToExecute = epochsToExecute.length;

    if (numberOfEpochsToExecute == 0) {
      _epochInfo.previousEpochIndex = uint32(currentEpochIndex) - 1;
      _epochInfo.previousEpochEndTimestamp = uint32(_oracleManager.getEpochStartTimestamp());
      return;
    }

    for (
      uint256 epochToExecuteIndex = 0;
      epochToExecuteIndex < numberOfEpochsToExecute;
      epochToExecuteIndex++
    ) {
      IOracleManagerFixedEpoch.MissedEpochExecutionInfo memory epochToExecute = epochsToExecute[
        epochToExecuteIndex
      ];
      if (!epochToExecute.epochHasNoAvailablePrice) {
        // If on the 3rd or more iteration of this loop,we only need to perform value transfer,
        // because pending actions will only exist for first 2 missed epochs.Other pending actions would have triggered upkeep
        if (epochToExecuteIndex < 2) {
          // If length is only one, we need to move the secondary slot into the primary slot.
          shouldExecuteBatchedOutstandingActions = true;
        } else {
          shouldExecuteBatchedOutstandingActions = false;
        }
        _rebalanceMarketPoolsCalculatePriceAndExecuteBatches(
          previousPrice,
          epochToExecute,
          shouldExecuteBatchedOutstandingActions
        );

        previousPrice = epochToExecute.oraclePrice;
      } else {
        _deprecateMarket();
        _epochInfo.latestExecutedEpochIndex += uint32(epochToExecuteIndex);
        _epochInfo.previousEpochIndex = uint32(currentEpochIndex) - 1;
        _epochInfo.previousEpochEndTimestamp = currentEpochStartTimestamp;
        if (epochToExecuteIndex > 0) {
          _epochInfo.previousExecutionPriceOracleIdentifier = epochsToExecute[
            epochToExecuteIndex - 1
          ].oracleUpdateIndex;
        }
        return;
      }
    }

    _epochInfo.latestExecutedEpochIndex += uint32(numberOfEpochsToExecute);
    _epochInfo.previousEpochIndex = uint32(currentEpochIndex) - 1;
    _epochInfo.previousEpochEndTimestamp = currentEpochStartTimestamp;
    _epochInfo.previousExecutionPriceOracleIdentifier = epochsToExecute[numberOfEpochsToExecute - 1]
      .oracleUpdateIndex;
  }

  /// @notice Updates the state of a market to account for the latest oracle price update.
  /// @dev We have to check market not deprecated to avoid changing state once deprecated
  function updateSystemState() external override checkMarketNotDeprecated {
    _updateSystemStateInternal(0);
  }

  /// @notice Updates the state of a market to account for the last n number of epochs.
  /// @dev We have to check market not deprecated to avoid changing state once deprecated
  function updateSystemStateSpecific(uint256 specificNumberOfEpochsToUpdate)
    external
    checkMarketNotDeprecated
  {
    _updateSystemStateInternal(specificNumberOfEpochsToUpdate);
  }

  /*╔═══════════════════════════╗
    ║       MINT POSITION       ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @dev We have to check market not deprecated after system state update because that is the function that determines whether the market should be deprecated.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _mint(
    uint224 amount,
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  )
    internal
    virtual
    checkMintingNotPaused
    gemCollecting(user)
    systemStateUpdated
    checkMarketNotDeprecated
  {
    // Due to _getAmountSyntheticToken we must have amount * 1e18 > syntheticTokenPriceInPaymentTokens
    //   otherwise we get 0
    // In fact, all the decimals of amount * 1e18 that are less than syntheticTokenPriceInPaymentTokens
    //   get cut off
    require(amount >= 1e18, "Min mint amount is 1e18");

    _executePoolOutstandingUserMints(user, poolType, poolTier);

    IERC20(_paymentToken).safeTransferFrom(msg.sender, _yieldManager, amount);

    uint32 currentEpoch = _epochInfo.previousEpochIndex + 1;

    IMarketCommon.UserAction storage userAction = _user_paymentToken_depositAction[user][poolType][
      poolTier
    ];

    if (userAction.amount > 0 && userAction.correspondingEpoch < currentEpoch) {
      userAction.nextEpochAmount += amount;
    } else {
      userAction.amount += amount;
      userAction.correspondingEpoch = currentEpoch;
    }

    if (currentEpoch % 2 == 0) {
      _pools[poolType][poolTier].evenEpoch_batched_amountPaymentToken_deposit += amount;
    } else {
      _pools[poolType][poolTier].oddEpoch_batched_amountPaymentToken_deposit += amount;
    }

    emit Deposit(packPoolId(poolType, uint8(poolTier)), uint256(amount), user, currentEpoch);
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint synthetic assets at next price.
  function mintLong(uint256 poolTier, uint224 amount) external override {
    _mint(amount, msg.sender, IMarketCommon.PoolType.LONG, poolTier);
  }

  /// @notice Allows users to mint short synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint synthetic assets at next price.
  function mintShort(uint256 poolTier, uint224 amount) external override {
    _mint(amount, msg.sender, IMarketCommon.PoolType.SHORT, poolTier);
  }

  /// @notice Allows mint long synthetic assets for a market on behalf of some user. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint synthetic assets at next price.
  /// @param user Address of the user.
  function mintLongFor(
    uint256 poolTier,
    uint224 amount,
    address user
  ) external override {
    _mint(amount, user, IMarketCommon.PoolType.LONG, poolTier);
  }

  /// @notice Allows mint short synthetic assets for a market on behalf of some user. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint synthetic assets at next price.
  /// @param user Address of the user.
  function mintShortFor(
    uint256 poolTier,
    uint224 amount,
    address user
  ) external override {
    _mint(amount, user, IMarketCommon.PoolType.SHORT, poolTier);
  }

  /*╔═══════════════════════════╗
    ║       REDEEM POSITION     ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @dev We have to check market not deprecated after system state update because that is the function that determines whether the market should be deprecated.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _redeem(
    uint224 amount,
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) internal virtual gemCollecting(user) systemStateUpdated checkMarketNotDeprecated {
    require(amount > 0, "Redeem amount == 0"); // Should redeem amount have same 1e18 restriction as mint?

    _executePoolOutstandingUserRedeems(user, poolType, poolTier);

    ISyntheticToken(_pools[poolType][poolTier].token).transferFrom(user, address(this), amount);

    uint32 currentEpoch = _epochInfo.previousEpochIndex + 1;

    IMarketCommon.UserAction storage userAction = _user_syntheticToken_redeemAction[user][poolType][
      poolTier
    ];

    if (userAction.amount > 0 && userAction.correspondingEpoch < currentEpoch) {
      userAction.nextEpochAmount += amount;
    } else {
      userAction.amount += amount;
      userAction.correspondingEpoch = currentEpoch;
    }

    if (currentEpoch % 2 == 0) {
      _pools[poolType][poolTier].evenEpoch_batched_amountSyntheticToken_redeem += amount;
    } else {
      _pools[poolType][poolTier].oddEpoch_batched_amountSyntheticToken_redeem += amount;
    }

    emit Redeem(packPoolId(poolType, uint8(poolTier)), uint256(amount), user, currentEpoch);
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function redeemLong(uint256 poolTier, uint224 amount) external override {
    _redeem(amount, msg.sender, IMarketCommon.PoolType.LONG, poolTier);
  }

  /// @notice Allows users to redeem short synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to redeem synthetic assets at next price.
  function redeemShort(uint256 poolTier, uint224 amount) external override {
    _redeem(amount, msg.sender, IMarketCommon.PoolType.SHORT, poolTier);
  }

  /*╔══════════════════════╗
    ║  EPOCH SETTLEMENTS   ║
    ╚══════════════════════╝*/

  /*╔═════════════════════════════════╗
    ║ BATCHED EPOCH SETTLEMENT ACTION ║
    ╚═════════════════════════════════╝*/

  //Add hook to garuntee upkeep if performed before calling this function
  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their mints during that epoch to that user.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _executePoolOutstandingUserMints(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) internal virtual {
    IMarketCommon.UserAction storage userAction = _user_paymentToken_depositAction[user][poolType][
      poolTier
    ];

    // Primary order =  order in first slot
    // Scondary order = order in mewt in following epoch.

    // Case if the primary order can be executed.
    if (
      userAction.amount > 0 && userAction.correspondingEpoch <= _epochInfo.latestExecutedEpochIndex
    ) {
      uint256 syntheticToken_price = _syntheticToken_priceSnapshot[userAction.correspondingEpoch][
        poolType
      ][poolTier];

      address syntheticToken = _pools[poolType][poolTier].token;

      uint256 amountSyntheticTokenToMint = _getAmountSyntheticToken(
        uint256(userAction.amount),
        syntheticToken_price
      );

      // If user has a mint in MEWT simply bump it one slot.
      if (userAction.nextEpochAmount > 0) {
        uint256 secondaryOrderEpoch = userAction.correspondingEpoch + 1;

        // need to check if we can also execute this
        if (secondaryOrderEpoch <= _epochInfo.latestExecutedEpochIndex) {
          // then also execute
          syntheticToken_price = _syntheticToken_priceSnapshot[secondaryOrderEpoch][poolType][
            poolTier
          ];
          amountSyntheticTokenToMint += _getAmountSyntheticToken(
            userAction.nextEpochAmount,
            syntheticToken_price
          );

          userAction.amount = 0;
          userAction.correspondingEpoch = 0;
        } else {
          userAction.amount = uint224(userAction.nextEpochAmount);
          userAction.correspondingEpoch = uint32(secondaryOrderEpoch);
        }
        // has to zero as either executed or bumped to primary slot
        userAction.nextEpochAmount = 0;
      } else {
        // If user has no pending mints then simply wipe
        userAction.amount = 0;
        userAction.correspondingEpoch = 0;
      }

      ISyntheticToken(syntheticToken).transfer(user, amountSyntheticTokenToMint);

      emit ExecuteEpochSettlementMintUser(
        packPoolId(poolType, uint8(poolTier)),
        user,
        _epochInfo.latestExecutedEpochIndex
      );
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their redeems during that epoch to that user.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _executePoolOutstandingUserRedeems(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) internal virtual {
    IMarketCommon.UserAction storage userAction = _user_syntheticToken_redeemAction[user][poolType][
      poolTier
    ];

    // Primary order =  order in first slot
    // Scondary order = order in mewt in following epoch.

    // Case if the primary order can be executed.
    if (
      userAction.amount > 0 && userAction.correspondingEpoch <= _epochInfo.latestExecutedEpochIndex
    ) {
      uint256 syntheticToken_price = _syntheticToken_priceSnapshot[userAction.correspondingEpoch][
        poolType
      ][poolTier];

      uint256 amountPaymentTokenToSend = _getAmountPaymentToken(
        uint256(userAction.amount),
        syntheticToken_price
      );

      // If user has a redeem in MEWT simply bump it one slot.
      if (userAction.nextEpochAmount > 0) {
        uint256 secondaryOrderEpoch = userAction.correspondingEpoch + 1;

        // need to check if we can also execute this
        if (secondaryOrderEpoch <= _epochInfo.latestExecutedEpochIndex) {
          // then also execute
          syntheticToken_price = _syntheticToken_priceSnapshot[secondaryOrderEpoch][poolType][
            poolTier
          ];
          amountPaymentTokenToSend += _getAmountPaymentToken(
            uint256(userAction.nextEpochAmount),
            syntheticToken_price
          );

          userAction.amount = 0;
          userAction.correspondingEpoch = 0;
        } else {
          userAction.amount = uint224(userAction.nextEpochAmount);
          userAction.correspondingEpoch = uint32(secondaryOrderEpoch);
        }
        // has to zero as either executed or bumped to primary slot
        userAction.nextEpochAmount = 0;
      } else {
        // If user has no pending redeems then simply wipe
        userAction.amount = 0;
        userAction.correspondingEpoch = 0;
      }

      IYieldManager(_yieldManager).transferPaymentTokensToUser(user, amountPaymentTokenToSend);

      emit ExecuteEpochSettlementRedeemUser(
        packPoolId(poolType, uint8(poolTier)),
        user,
        _epochInfo.latestExecutedEpochIndex
      );
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @dev Once the market has updated for the next price, should be guaranteed (through modifiers) to execute for a user before user initiation of new next price actions.
  /// @dev We have to check market not deprecated after system state update because that is the function that determines whether the market should be deprecated.
  /// @param user The address of the user for whom to execute the function.
  function _executeOutstandingEpochSettlements(address user)
    internal
    virtual
    systemStateUpdated
    checkMarketNotDeprecated
  {
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint8 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        _executePoolOutstandingUserMints(user, IMarketCommon.PoolType(poolType), poolTier);
        _executePoolOutstandingUserRedeems(user, IMarketCommon.PoolType(poolType), poolTier);
      }
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @param user The address of the user for whom to execute the function.
  function executeOutstandingEpochSettlementsUser(address user) external override {
    _executeOutstandingEpochSettlements(user);
  }

  /*╔═══════════════════════════════════════════╗
    ║   BATCHED NEXT PRICE SETTLEMENT ACTIONS   ║
    ╚═══════════════════════════════════════════╝*/

  /// @notice Either mints or burns synthetic token supply.
  /// @param synthToken Address of the synthetic token.
  /// @param changeInSyntheticTokensTotalSupply Positive indicates amount to be minted and negative indicates amount to be burned.
  function _handleChangeInSyntheticTokensTotalSupply(
    address synthToken,
    int256 changeInSyntheticTokensTotalSupply
  ) internal virtual {
    if (changeInSyntheticTokensTotalSupply > 0) {
      ISyntheticToken(synthToken).mint(address(this), uint256(changeInSyntheticTokensTotalSupply));
    } else if (changeInSyntheticTokensTotalSupply < 0) {
      ISyntheticToken(synthToken).burn(uint256(-changeInSyntheticTokensTotalSupply));
    }
  }

  /// @notice For a given pool, updates the value depending on the batched deposits and redeems that took place during the epoch
  /// @param associatedEpochIndex Index of epoch where the batched actions were performed.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index.
  /// @param price Price of the synthetic token.
  function _batchConfirmOutstandingPendingActionsPool(
    uint256 associatedEpochIndex,
    IMarketCommon.PoolType poolType,
    uint256 poolTier,
    uint256 price
  ) internal virtual {
    uint256 paymentTokenDepositAmount;
    uint256 syntheticTokenRedeemAmount;

    IMarketCommon.Pool storage pool = _pools[poolType][poolTier];

    if (associatedEpochIndex % 2 == 0) {
      paymentTokenDepositAmount = pool.evenEpoch_batched_amountPaymentToken_deposit;
      pool.evenEpoch_batched_amountPaymentToken_deposit = 0;

      syntheticTokenRedeemAmount = pool.evenEpoch_batched_amountSyntheticToken_redeem;
      pool.evenEpoch_batched_amountSyntheticToken_redeem = 0;
    } else {
      paymentTokenDepositAmount = pool.oddEpoch_batched_amountPaymentToken_deposit;
      pool.oddEpoch_batched_amountPaymentToken_deposit = 0;

      syntheticTokenRedeemAmount = pool.oddEpoch_batched_amountSyntheticToken_redeem;
      pool.oddEpoch_batched_amountSyntheticToken_redeem = 0;
    }

    int256 changeInMarketValue_inPaymentToken = int256(paymentTokenDepositAmount) -
      int256(_getAmountPaymentToken(syntheticTokenRedeemAmount, price));

    int256 changeInSupply_syntheticToken = int256(
      _getAmountSyntheticToken(paymentTokenDepositAmount, price)
    ) - int256(syntheticTokenRedeemAmount);

    pool.value = uint256(int256(pool.value) + changeInMarketValue_inPaymentToken);
    _handleChangeInSyntheticTokensTotalSupply(pool.token, changeInSupply_syntheticToken);
  }

  /*╔═══════════════════════════╗
    ║ DEPRECATED MARKET ACTIONS ║
    ╚═══════════════════════════╝*/

  function _deprecatePools(IMarketCommon.PoolType poolType) internal {
    uint256 maxPoolIndex = _numberOfPoolsOfType[uint256(poolType)];
    for (uint8 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
      address syntheticToken = _pools[poolType][poolIndex].token;
      ISyntheticToken(syntheticToken).deprecateToken();
    }
  }

  function _deprecateMarket() internal {
    marketDeprecated = true;
    mintingPaused = true;
    _deprecatePools(IMarketCommon.PoolType.SHORT);
    _deprecatePools(IMarketCommon.PoolType.LONG);
    emit MarketDeprecated();
  }

  function deprecateMarket() external adminOnly systemStateUpdated {
    _deprecateMarket();
  }

  /// @notice Allows users to exit the market after it has been deprecated
  function _exitDeprecatedMarket(address user, IMarketCommon.PoolType poolType) internal {
    // NOTE we don't want the seeder to redeem because it could lead to division by 0 when the last person exits
    require(
      user != address(0) && user != PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      "User can't be 0 or seeder"
    );

    uint32 lastExecutedEpoch = _epochInfo.latestExecutedEpochIndex;

    IMarketCommon.UserAction memory userAction;
    address syntheticToken;
    uint256 syntheticToken_price;
    uint256 maxPoolIndex;
    uint256 amountPaymentTokenToSend;

    maxPoolIndex = _numberOfPoolsOfType[uint256(poolType)];
    for (uint8 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
      // reverse pending deposits, no dependency on lastExecutedEpoch
      userAction = _user_paymentToken_depositAction[user][poolType][poolIndex];
      if (userAction.amount > 0 || userAction.nextEpochAmount > 0) {
        uint256 amount = userAction.amount;
        uint256 nextEpochAmount = userAction.nextEpochAmount;
        userAction.amount = 0;
        userAction.nextEpochAmount = 0;
        userAction.correspondingEpoch = 0;
        IYieldManager(_yieldManager).transferPaymentTokensToUser(user, amount + nextEpochAmount);
      }

      // then execute outstanding redeems that were executable even before deprecation
      _executePoolOutstandingUserRedeems(user, poolType, poolIndex);

      // then execute those outstanding redeems that do not have associated prices
      //   (just give them the price of the previous executed epoch)
      userAction = _user_syntheticToken_redeemAction[user][poolType][poolIndex];
      if (userAction.amount > 0 || userAction.nextEpochAmount > 0) {
        syntheticToken_price = _syntheticToken_priceSnapshot[lastExecutedEpoch][poolType][
          poolIndex
        ];
        amountPaymentTokenToSend = _getAmountPaymentToken(
          userAction.amount + userAction.nextEpochAmount,
          syntheticToken_price
        );
        userAction.amount = 0;
        userAction.nextEpochAmount = 0;
        userAction.correspondingEpoch = 0;
        IYieldManager(_yieldManager).transferPaymentTokensToUser(user, amountPaymentTokenToSend);
      }

      // redeem all user's synth tokens
      //   (also give the price of the previous executed epoch)
      syntheticToken = _pools[poolType][poolIndex].token;
      uint256 balance = IERC20(syntheticToken).balanceOf(user);
      if (balance > 0) {
        syntheticToken_price = _syntheticToken_priceSnapshot[lastExecutedEpoch][poolType][
          poolIndex
        ];
        amountPaymentTokenToSend = _getAmountPaymentToken(balance, syntheticToken_price);
        ISyntheticToken(syntheticToken).burnWhenDeprecated(user, balance);
        IYieldManager(_yieldManager).transferPaymentTokensToUser(user, amountPaymentTokenToSend);
      }
    }
  }

  /// @notice Allows users to exit the market after it has been deprecated
  function exitDeprecatedMarket(address user) external {
    // NOTE we can't use the modifier 'cause it checks for market deprecation and we have to update
    //   system state to ensure executable epochs before the bad epoch were actually executed
    _updateSystemStateInternal(0);

    // NOTE we check market deprecation after updating system state 'cause it may be that this
    //  particular update is the one that deprecates the market
    require(marketDeprecated, "Market is not deprecated");

    _exitDeprecatedMarket(user, IMarketCommon.PoolType.SHORT);
    _exitDeprecatedMarket(user, IMarketCommon.PoolType.LONG);
  }

  function exitDeprecatedMarket() external {
    // NOTE we can't use the modifier 'cause it checks for market deprecation and we have to update
    //   system state to ensure executable epochs before the bad epoch were actually executed
    _updateSystemStateInternal(0);

    // NOTE we check market deprecation after updating system state 'cause it may be that this
    //  particular update is the one that deprecates the market
    require(marketDeprecated, "Market is not deprecated");

    _exitDeprecatedMarket(msg.sender, IMarketCommon.PoolType.SHORT);
    _exitDeprecatedMarket(msg.sender, IMarketCommon.PoolType.LONG);
  }
}

contract MarketTieredLeverage is MarketTieredLeverageLogic, ProxyNonPayable {
  MarketExtended immutable nonCoreFunctionsDelegatee;

  constructor(
    MarketExtended _nonCoreFunctionsDelegatee,
    address _paymentToken,
    IRegistry _longShort
  ) MarketTieredLeverageLogic(_paymentToken, _longShort) {
    require(address(_nonCoreFunctionsDelegatee) != address(0));
    nonCoreFunctionsDelegatee = _nonCoreFunctionsDelegatee;

    // Add this so that this contract can be detected as a proxy by things such as etherscan.
    StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = address(
      _nonCoreFunctionsDelegatee
    );

    require(_paymentToken == nonCoreFunctionsDelegatee.paymentToken());
    require(_longShort == nonCoreFunctionsDelegatee.longShort());
  }

  /// @dev Required to delegate non-core-function calls to the MarketExtended contract using the OpenZeppelin proxy.
  function _implementation() internal view override returns (address) {
    return address(nonCoreFunctionsDelegatee);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// import "forge-std/console2.sol";

abstract contract AccessControlledAndUpgradeable is
  Initializable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @notice Initializes the contract when called by parent initializers.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init(address initialAdmin) internal onlyInitializing {
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _AccessControlledAndUpgradeable_init_unchained(initialAdmin);
  }

  /// @notice Initializes the contract for contracts that already call both __AccessControl_init
  ///         and _UUPSUpgradeable_init when initializing.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init_unchained(address initialAdmin) internal {
    require(initialAdmin != address(0));
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(UPGRADER_ROLE, initialAdmin);
  }

  /// @notice Authorizes an upgrade to a new address.
  /// @dev Can only be called by addresses wih UPGRADER_ROLE
  function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}
}

contract AccessControlledAndUpgradeableModifiers is AccessControlledAndUpgradeable {
  modifier adminOnly() virtual {
    _checkRole(ADMIN_ROLE, msg.sender);
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/// @notice this is an exact copy/paste of the Proxy contract from the OpenZeppelin library, only difference is that it is NON-PAYABLE!

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract ProxyNonPayable {
  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internal call site, it will return directly to the external caller.
   */
  function _delegate(address implementation) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
   * and {_fallback} should delegate.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates the current call to the address returned by `_implementation()`.
   *
   * This function does not return to its internal call site, it will return directly to the external caller.
   */
  function _fallback() internal virtual {
    _beforeFallback();
    _delegate(_implementation());
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external virtual {
    _fallback();
  }

  /**
   * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
   * call, or as part of the Solidity `fallback` or `receive` functions.
   *
   * If overridden should call `super._beforeFallback()`.
   */
  function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "./IMarketCommon.sol";
import "./IOracleManagerFixedEpoch.sol";

interface IMarketTieredLeverage {
  // Getters
  function numberOfPoolsOfType(IMarketCommon.PoolType) external view returns (uint256);

  function oracleManager() external view returns (IOracleManagerFixedEpoch);

  function pools(IMarketCommon.PoolType, uint256) external view returns (IMarketCommon.Pool memory);

  function yieldManager() external view returns (address);

  function user_paymentToken_depositAction(
    address,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (IMarketCommon.UserAction memory);

  function user_syntheticToken_redeemAction(
    address,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (IMarketCommon.UserAction memory);

  function syntheticToken_priceSnapshot(
    uint32,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (uint256);

  // External calls
  function updateSystemState() external;

  function mintLongFor(
    uint256 pool,
    uint224 amount,
    address user
  ) external;

  function mintShortFor(
    uint256 pool,
    uint224 amount,
    address user
  ) external;

  function redeemLong(uint256 pool, uint224 amount) external;

  function redeemShort(uint256 pool, uint224 amount) external;

  function mintLong(uint256 pool, uint224 amount) external;

  function mintShort(uint256 pool, uint224 amount) external;

  function executeOutstandingEpochSettlementsUser(address user) external;

  function epochInfo() external view returns (IMarketCommon.EpochInfo memory);

  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    IMarketCommon.PoolType poolType,
    uint8 poolTier
  ) external view returns (uint256 confirmedButNotSettledBalance);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "../interfaces/AggregatorV3Interface.sol";

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManagerFixedEpoch {
  struct MissedEpochExecutionInfo {
    uint80 oracleUpdateIndex;
    int256 oraclePrice;
    uint256 timestampPriceUpdated;
    uint32 associatedEpochIndex;
    bool epochHasNoAvailablePrice;
  }

  function chainlinkOracle() external view returns (AggregatorV3Interface);

  function oracleDecimals() external view returns (uint8);

  function initialEpochStartTimestamp() external view returns (uint256);

  function EPOCH_LENGTH() external view returns (uint256);

  function MINIMUM_EXECUTION_WAIT_THRESHOLD() external view returns (uint256);

  function inMewt() external view returns (bool);

  function shouldUpdatePrice(uint32) external view returns (bool);

  function getCurrentEpochIndex() external view returns (uint256);

  function getEpochStartTimestamp() external view returns (uint256);

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

  function priceAtIndex(uint80 index) external view returns (int256 price);

  function latestRoundID() external view returns (uint80);

  function getCompleteOracleInfoForSystemStateUpdate(
    uint32 _latestExecutedEpochIndex,
    uint80 _previousExecutionPriceOracleIdentifier,
    uint32 _previousEpochEndTimestamp
  )
    external
    view
    returns (
      uint32 currentEpochTimestamp,
      uint32 numberOfEpochsSinceLastEpoch, // remove this and use length
      int256 previousPrice,
      MissedEpochExecutionInfo[] memory _missedEpochPriceUpdates
    );

  function getOracleInfoForSystemStateUpdate(
    uint32 _latestExecutedEpochIndex,
    uint80 _previousExecutionPriceOracleIdentifier,
    uint32 _previousEpochEndTimestamp,
    uint256 _numberOfUpdatesToTryFetch
  )
    external
    view
    returns (
      uint32 currentEpochTimestamp,
      uint32 numberOfEpochsSinceLastEpoch, // remove this and use length
      int256 previousPrice,
      MissedEpochExecutionInfo[] memory _missedEpochPriceUpdates
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

interface IRegistry {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event LongShortArctic(address admin);

  event SeparateMarketCreated(string name, string symbol, address market, uint32 marketIndex);

  function separateMarketContracts(uint32) external view returns (address);

  function latestMarket() external view returns (uint32);

  function gems() external view returns (address);

  function marketUpdateIndex(uint32) external view returns (uint256);

  function get_syntheticToken_priceSnapshot(uint32, uint256)
    external
    view
    returns (uint256, uint256);

  function updateSystemStateMulti(uint32[] calldata marketIndex) external;

  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view returns (uint256 confirmedButNotSettledBalance);

  // Utility helper functions so users don't need to remember the address of the separate markets:
  function mintLong(
    uint32 marketIndex,
    uint256 pool,
    uint224 amount
  ) external;

  function mintShort(
    uint32 marketIndex,
    uint256 pool,
    uint224 amount
  ) external;

  /* ══════ User specific ══════ */
  function userNextPrice_currentUpdateIndex(uint32 marketIndex, address user)
    external
    view
    returns (uint256);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_redeemAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_toShiftAwayFrom_marketSide(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "./ISyntheticToken.sol";
import "./IMarketTieredLeverage.sol";
import "./IMarketCommon.sol";

/**
@title SyntheticToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface ISyntheticTokenMarketUpgradeable is ISyntheticToken {
  function initialize(
    IMarketCommon.PoolInfo memory poolInfo,
    address upgrader,
    uint32 _marketIndex,
    uint8 _poolTier
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

/// @notice Manages yield accumulation for the LongShort contract. Each market is deployed with its own yield manager to simplify the bookkeeping, as different markets may share a payment token and yield pool.
interface IYieldManager {
  event ClaimAaveRewardTokenToTreasury(uint256 amount);

  event YieldDistributed(uint256 unrealizedYield);

  /// @dev This is purely saving some gas, but the subgraph will know how much is due for the treasury at all times - no need to include in event.
  event WithdrawTreasuryFunds();

  /// @notice Deposits the given amount of payment tokens into this yield manager.
  /// @param amount Amount of payment token to deposit
  function depositPaymentToken(uint256 amount) external;

  /// @notice Allows the LongShort pay out a user from tokens already withdrawn from Aave
  /// @param user User to recieve the payout
  /// @param amount Amount of payment token to pay to user
  function transferPaymentTokensToUser(address user, uint256 amount) external;

  /// @notice Withdraws the given amount of tokens from this yield manager.
  /// @param amount Amount of payment token to withdraw
  function removePaymentTokenFromMarket(uint256 amount) external;

  /**    
    @notice Calculates and distributes the yield allocation to the treasury
    @dev treasury receives all yield
  */
  function distributeYieldToTreasury() external;

  /// @notice Initializes a specific yield manager to a given market
  function initializeForMarket() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

interface IGEMS {
  function initialize() external;

  function gm(address) external;

  function GEM_ROLE() external returns (bytes32);

  function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../abstract/AccessControlledAndUpgradeable.sol";
import "../../abstract/ProxyNonPayable.sol";

import "../../interfaces/IMarketTieredLeverage.sol";
import "../../interfaces/IOracleManagerFixedEpoch.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/ISyntheticTokenMarketUpgradeable.sol";
import "../../interfaces/IYieldManager.sol";

contract MarketStorage {
  using SafeERC20 for IERC20;

  /*╔═════════════════════════════╗
    ║          VARIABLES          ║
    ╚═════════════════════════════╝*/

  /* ══════ Fixed-precision constants ══════ */
  /// @notice this is the address that permanently locked initial liquidity for markets is held by.
  /// These tokens will never move so market can never have zero liquidity on a side.
  /// @dev f10a7 spells float in hex - for fun - important part is that the private key for this address in not known.
  address constant PERMANENT_INITIAL_LIQUIDITY_HOLDER =
    0xf10A7_F10A7_f10A7_F10a7_F10A7_f10a7_F10A7_f10a7;

  uint256 constant SECONDS_IN_A_YEAR_e18 = 315576e20;

  /// @dev an empty allocation of storage for use in future upgrades - inspiration from OZ:
  ///      https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/10f0f1a95b1b0fd5520351886bae7a03490f1056/contracts/token/ERC20/ERC20Upgradeable.sol#L361
  uint256[45] private __constantsGap;

  /* ══════ Global state ══════ */
  uint32 initialEpochStartTimestamp;

  address _yieldManager;
  IOracleManagerFixedEpoch _oracleManager;

  uint256[45] private __globalStateGap;

  /* ══════ Market specific ══════ */

  IMarketCommon.EpochInfo _epochInfo;

  uint256[44] private __marketStateGap;

  uint256 fundingRateMultiplier_e18;
  // max percent change in price per epoch where 1e18 is 100% price movement.
  uint256 public maxPercentChange;

  // mapping from epoch number -> pooltype -> array of price snapshot
  // TODO - experiment with `uint128[8]` and check gas efficiency.
  mapping(uint256 => mapping(IMarketCommon.PoolType => uint256[8])) _syntheticToken_priceSnapshot;

  uint256[43] private __marketPositonStateGap;

  /* ══════ User specific ══════ */

  //User Address => IMarketCommon.PoolType => UserAction Array
  mapping(address => mapping(IMarketCommon.PoolType => IMarketCommon.UserAction[8])) _user_paymentToken_depositAction;
  //User Address => IMarketCommon.PoolType => UserAction Array
  mapping(address => mapping(IMarketCommon.PoolType => IMarketCommon.UserAction[8])) _user_syntheticToken_redeemAction;

  mapping(IMarketCommon.PoolType => IMarketCommon.Pool[8]) _pools;
  uint256[32] _numberOfPoolsOfType;

  bool mintingPaused;
  bool marketDeprecated;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../abstract/AccessControlledAndUpgradeable.sol";

import "../../interfaces/IOracleManagerFixedEpoch.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/ISyntheticTokenMarketUpgradeable.sol";
import "../../interfaces/IMarketExtended.sol";
import "./MarketStorage.sol";

abstract contract MarketExtendedGetters is IMarketExtended, MarketStorage {
  /// @notice Purely a convenience function to get the synthetic token address. Used in testing.
  function getMiaAddress(IMarketCommon.PoolType poolType, uint256 index)
    external
    view
    returns (address)
  {
    return _pools[poolType][index].token;
  }

  /// @notice Returns the number of pools of poolType i.e. Long or Short
  /// @param isLong true for long, false for short
  function getNumberOfPools(bool isLong) external view returns (uint256) {
    if (isLong) {
      return _numberOfPoolsOfType[uint8(IMarketCommon.PoolType.LONG)];
    } else {
      return _numberOfPoolsOfType[uint8(IMarketCommon.PoolType.SHORT)];
    }
  }

  /// @notice Returns batched deposit amount in payment token for even numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_even_batched_amountPaymentToken_deposit(
    IMarketCommon.PoolType poolType,
    uint256 pool
  ) external view returns (uint256) {
    return uint256(_pools[poolType][pool].evenEpoch_batched_amountPaymentToken_deposit);
  }

  /// @notice Returns batched deposit amount in payment token for odd numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_odd_batched_amountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    return uint256(_pools[poolType][pool].oddEpoch_batched_amountPaymentToken_deposit);
  }

  /// @notice Returns batched redeem amount in synthetic token for even numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_even_batched_amountSyntheticToken_redeem(
    IMarketCommon.PoolType poolType,
    uint256 pool
  ) external view returns (uint256) {
    return uint256(_pools[poolType][pool].evenEpoch_batched_amountSyntheticToken_redeem);
  }

  /// @notice Returns batched redeem amount in synthetic token for odd numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_odd_batched_amountSyntheticToken_redeem(
    IMarketCommon.PoolType poolType,
    uint256 pool
  ) external view returns (uint256) {
    return uint256(_pools[poolType][pool].oddEpoch_batched_amountSyntheticToken_redeem);
  }

  function get_batched_amountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    uint32 currentEpochIndex = uint32(_oracleManager.getCurrentEpochIndex());
    if (currentEpochIndex % 2 == 0) {
      return uint256(_pools[poolType][pool].evenEpoch_batched_amountPaymentToken_deposit);
    } else {
      return uint256(_pools[poolType][pool].oddEpoch_batched_amountPaymentToken_deposit);
    }
  }

  function get_batched_amountSyntheticToken_redeem(IMarketCommon.PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    uint32 currentEpochIndex = uint32(_oracleManager.getCurrentEpochIndex());
    if (currentEpochIndex % 2 == 0) {
      return uint256(_pools[poolType][pool].evenEpoch_batched_amountSyntheticToken_redeem);
    } else {
      return uint256(_pools[poolType][pool].oddEpoch_batched_amountSyntheticToken_redeem);
    }
  }

  /// @notice Returns value of the pool in payment token
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_pool_value(IMarketCommon.PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    return uint256(_pools[poolType][pool].value);
  }

  /// @notice Returns the leverage of the pool
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_pool_leverage(IMarketCommon.PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    return uint256(_pools[poolType][pool].leverage);
  }

  function get_mintingPaused() external view returns (bool) {
    return mintingPaused;
  }

  function get_marketDeprecated() external view returns (bool) {
    return marketDeprecated;
  }
}

/// @notice This contract should ONLY have view/pure functions, else it risks causing bugs that may interfere with the 'core' contract functions.
/// @dev This contract is contains a set of non-core functions for the MarketTieredLeverage contract that are not important enough to be included in the core contract.
contract MarketExtended is AccessControlledAndUpgradeableModifiers, MarketExtendedGetters {
  using SafeERC20 for IERC20;

  IRegistry public immutable longShort; // original core contract
  address public immutable gems;
  address public immutable paymentToken;

  constructor(address _paymentToken, IRegistry _longShort) {
    require(_paymentToken != address(0) && address(_longShort) != address(0));
    paymentToken = _paymentToken;

    longShort = _longShort; // original core contract
    gems = longShort.gems();
  }

  enum ConfigChangeType {
    marketOracleUpdate,
    fundingRateMultiplier
  }

  event ConfigChange(ConfigChangeType configChangeType, uint256 value1, uint256 value2);

  event MintingPauseChange(bool isPaused);

  event SeparateMarketLaunchedAndSeeded(
    uint32 marketIndex,
    IMarketCommon.PoolInfo[] marketTiers,
    uint256 initialSeed,
    address admin,
    address _oracleManager,
    address paymentToken,
    int256 initialAssetPrice
  );

  // Currently unused.
  event TierAdded(IMarketCommon.PoolInfo newTier, uint256 initialSeed);

  /////////////////////////
  // Simple getter functions
  /////////////////////////

  /// @notice Returns the total liquidity in the market
  /// @return totalValueRealizedInMarket total liquidity in all pools on both sides
  function get_total_value_realized_in_market()
    external
    view
    returns (uint256 totalValueRealizedInMarket)
  {
    for (
      uint8 poolType = uint8(IMarketCommon.PoolType.SHORT);
      poolType <= uint8(IMarketCommon.PoolType.LONG);
      poolType++
    ) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint256 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        totalValueRealizedInMarket += _pools[IMarketCommon.PoolType(poolType)][poolTier].value;
      }
    }
  }

  modifier longShortOnly() {
    require(msg.sender == address(longShort), "Not LongShort");
    _;
  }

  /*╔═══════════════════╗
    ║       ADMIN       ║
    ╚═══════════════════╝*/

  /// @notice Initialize epoch info struct
  /// @param _oracleManager Address of the oracle manager.
  /// @return initialAssetPrice the latest price from oracle when epoch info is initialized.
  function initializeEpochInfo(IOracleManagerFixedEpoch _oracleManager) internal returns (int256) {
    _epochInfo.previousEpochIndex = uint32(_oracleManager.getCurrentEpochIndex() - 1);
    _epochInfo.previousEpochEndTimestamp = uint32(_oracleManager.getEpochStartTimestamp());
    _epochInfo.latestExecutedEpochIndex = _epochInfo.previousEpochIndex;

    (uint80 latestRoundId, int256 initialAssetPrice, , , ) = _oracleManager.latestRoundData();
    _epochInfo.previousExecutionPriceOracleIdentifier = latestRoundId;

    return initialAssetPrice;
  }

  /// @notice Initialize pools in the market
  /// @dev Can only be called by longShort contract
  /// @param params struct containing addresses of dependency contracts and other market initialization parameters
  /// @return initializationSuccess bool value indicating whether initialization was successful.
  function initializePools(IMarketExtended.InitializePoolsParams memory params)
    external
    override
    initializer
    longShortOnly
    returns (bool initializationSuccess)
  {
    require(
      // You require at least 1e12 (1 payment token with 12 decimal places) of the underlying payment token to seed the market.
      params.initialEffectiveLiquidityToSeedEachPool >= 1e12,
      "Insufficient market seed"
    );
    require(
      params.seederAndAdmin != address(0) &&
        params.oracleManager != address(0) &&
        params.yieldManager != address(0)
    );
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(params.seederAndAdmin);

    _oracleManager = IOracleManagerFixedEpoch(params.oracleManager);
    _yieldManager = params.yieldManager;

    // marketIndex = _marketIndex;

    int256 initialAssetPrice = initializeEpochInfo(_oracleManager);

    IMarketCommon.PoolInfo[] memory poolInfo = new PoolInfo[](params.initPools.length);
    uint256 amountToLockInYieldManager;
    uint256 seedAmount;

    maxPercentChange = 9999e14; // Ie default max percentage change is 99.99%

    for (uint256 i = 0; i < params.initPools.length; i++) {
      require(params.initPools[i].token != address(0), "Pool token address incorrect");
      require(
        params.initPools[i].leverage >= 1e18 && params.initPools[i].leverage <= 8e18,
        "Pool leverage out of bounds"
      );
      {
        uint256 tierPriceMovementThresholdAbsolute = (1e36 / params.initPools[i].leverage) - 1e14;
        maxPercentChange = Math.min(maxPercentChange, tierPriceMovementThresholdAbsolute);
      }

      // TODO write fuzz test to check (there is already hard-coded test):
      //   - correct value is sent to the YM
      //   - each pool gets seeded with the correct value
      seedAmount = MarketLibrary._calculateLiquidityForPool(
        params.initialEffectiveLiquidityToSeedEachPool,
        params.initPools[i].leverage
      );
      amountToLockInYieldManager += seedAmount;

      ISyntheticTokenMarketUpgradeable(params.initPools[i].token).initialize(
        params.initPools[i],
        params.seederAndAdmin,
        params._marketIndex,
        uint8(_numberOfPoolsOfType[uint256(params.initPools[i].poolType)])
      );
      ISyntheticTokenMarketUpgradeable(params.initPools[i].token).mint(
        PERMANENT_INITIAL_LIQUIDITY_HOLDER,
        seedAmount
      );

      _pools[params.initPools[i].poolType][
        _numberOfPoolsOfType[uint256(params.initPools[i].poolType)]
      ] = Pool({
        token: params.initPools[i].token,
        value: seedAmount,
        leverage: params.initPools[i].leverage,
        evenEpoch_batched_amountPaymentToken_deposit: 0,
        evenEpoch_batched_amountSyntheticToken_redeem: 0,
        oddEpoch_batched_amountPaymentToken_deposit: 0,
        oddEpoch_batched_amountSyntheticToken_redeem: 0
      });

      poolInfo[i] = params.initPools[i];
      _numberOfPoolsOfType[uint256(params.initPools[i].poolType)]++;
    }

    // May only require seeding one tier on long and short sides, but for now we seed all of them
    IERC20(paymentToken).safeTransferFrom(
      params.seederAndAdmin,
      _yieldManager,
      amountToLockInYieldManager
    );

    emit SeparateMarketLaunchedAndSeeded(
      params._marketIndex,
      poolInfo,
      params.initialEffectiveLiquidityToSeedEachPool,
      params.seederAndAdmin,
      address(_oracleManager),
      paymentToken,
      initialAssetPrice
    );

    // Return true to drastically reduce chance of making mistakes with this.
    return true;
  }

  /// @notice Update oracle for a market
  /// @dev Can only be called by the current admin.
  /// @param _newOracleManager Address of the replacement oracle manager.
  function updateMarketOracle(IOracleManagerFixedEpoch _newOracleManager) external adminOnly {
    // NOTE: we could also upgrade this contract to reference the new oracle potentially and have it as immutable
    // If not a oracle contract this would break things.. Test's arn't validating this
    // Ie require isOracle interface - ERC165
    IOracleManagerFixedEpoch previousOracleManager = _oracleManager;
    _oracleManager = _newOracleManager;
    emit ConfigChange(
      ConfigChangeType.marketOracleUpdate,
      uint256(uint160(address(previousOracleManager))),
      uint256(uint160(address(_newOracleManager)))
    );
  }

  /// @notice Update the yearly funding rate multiplier for the market
  /// @dev Can only be called by the current admin.
  /// @param _fundingRateMultiplier_e18 New funding rate multiplier
  function changeMarketFundingRateMultiplier(uint256 _fundingRateMultiplier_e18)
    external
    adminOnly
  {
    require(_fundingRateMultiplier_e18 <= 5e19, "not in range: funding rate <= 5000%");
    uint256 previousFundingRateMultiplier_e18 = fundingRateMultiplier_e18;
    fundingRateMultiplier_e18 = _fundingRateMultiplier_e18;
    emit ConfigChange(
      ConfigChangeType.fundingRateMultiplier,
      previousFundingRateMultiplier_e18,
      fundingRateMultiplier_e18
    );
  }

  /// TODO pack the parameters into a struct in future to be aligned with initializePools function above.
  /// @notice Add a pool to an existing market.
  /// @dev Can only be called by the current admin.
  /// @param initPool initialization info for the new pool
  /// @param initialEffectiveLiquidityForNewPool initial effective liquidity to be added to new pool at initialization
  /// @param seederAndAdmin address of pool seeder and admin
  /// @param _yieldManager address of the yield manager
  /// @param _marketIndex index of the market
  /// @return poolInitializationSuccess bool value indicating whether pool addition was successful
  function addPoolToExistingMarket(
    IMarketCommon.PoolInfo memory initPool,
    uint256 initialEffectiveLiquidityForNewPool,
    address seederAndAdmin,
    uint32 _marketIndex,
    address _yieldManager
  ) external adminOnly returns (bool poolInitializationSuccess) {
    require(
      // You require at least 1e12 (1 payment token with 12 decimal places) of the underlying payment token to seed the market.
      initialEffectiveLiquidityForNewPool >= 1e12,
      "Insufficient market seed"
    );
    require(
      _numberOfPoolsOfType[uint256(initPool.poolType)] < 8,
      "Maximum number of _pools for side exceeded"
    );
    require(seederAndAdmin != address(0));
    require(initPool.token != address(0), "Pool token address incorrect");
    require(initPool.leverage >= 1e18 && initPool.leverage <= 8e18, "Pool leverage out of bounds");

    IMarketCommon.PoolInfo memory poolInfo = initPool;
    uint256 seedAmount;

    uint256 tierPriceMovementThresholdAbsolute = ((1e22) / initPool.leverage) - 1; /* 1e4 multiply by 1e18 since leverage is base 18 */

    maxPercentChange = uint16(
      Math.min(uint256(maxPercentChange), tierPriceMovementThresholdAbsolute)
    );

    seedAmount = MarketLibrary._calculateLiquidityForPool(
      initialEffectiveLiquidityForNewPool,
      initPool.leverage
    );

    ISyntheticTokenMarketUpgradeable(initPool.token).initialize(
      initPool,
      seederAndAdmin,
      _marketIndex,
      uint8(_numberOfPoolsOfType[uint256(initPool.poolType)])
    );

    ISyntheticTokenMarketUpgradeable(initPool.token).mint(
      PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      seedAmount
    );

    _pools[initPool.poolType][_numberOfPoolsOfType[uint256(initPool.poolType)]] = Pool({
      token: initPool.token,
      value: seedAmount,
      leverage: initPool.leverage,
      evenEpoch_batched_amountPaymentToken_deposit: 0,
      evenEpoch_batched_amountSyntheticToken_redeem: 0,
      oddEpoch_batched_amountPaymentToken_deposit: 0,
      oddEpoch_batched_amountSyntheticToken_redeem: 0
    });

    _numberOfPoolsOfType[uint256(initPool.poolType)]++;

    IERC20(paymentToken).safeTransferFrom(seederAndAdmin, _yieldManager, seedAmount);

    emit TierAdded(poolInfo, seedAmount);

    return true;
  }

  function pauseMinting() external adminOnly {
    mintingPaused = true;
    emit MintingPauseChange(mintingPaused);
  }

  function unpauseMinting() external adminOnly {
    require(!marketDeprecated, "can't unpause deprecated market");
    mintingPaused = false;
    emit MintingPauseChange(mintingPaused);
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
                        StringsUpgradeable.toHexString(account),
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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

library MarketLibrary {
  function _calculateLiquidityForPool(uint256 effectiveLiquidity, uint256 leverage)
    internal
    pure
    returns (uint256 liquidity)
  {
    return (effectiveLiquidity * 1e18) / leverage;
  }
}

interface IMarketCommon {
  struct EpochInfo {
    // this is the index of the previous epoch that has finished
    uint32 previousEpochIndex;
    uint32 previousEpochEndTimestamp;
    uint32 latestExecutedEpochIndex;
    // Reference to Chainlink Index
    uint80 previousExecutionPriceOracleIdentifier;
  }

  enum PoolType {
    SHORT,
    LONG,
    LAST // useful for getting last element of enum, commonly used in cpp/c also eg: https://stackoverflow.com/a/2102615
  }

  struct PoolInfo {
    string name;
    string symbol;
    PoolType poolType;
    address token;
    uint256 leverage;
  }

  // TODO think how to pack this more efficiently
  struct Pool {
    address token;
    uint256 value;
    uint256 leverage;
    uint256 evenEpoch_batched_amountPaymentToken_deposit;
    uint256 evenEpoch_batched_amountSyntheticToken_redeem;
    uint256 oddEpoch_batched_amountPaymentToken_deposit;
    uint256 oddEpoch_batched_amountSyntheticToken_redeem;
  }

  // TODO: think how to pack this.
  struct UserAction {
    uint32 correspondingEpoch;
    uint224 amount;
    uint256 nextEpochAmount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

/**
@title SyntheticToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface ISyntheticToken {
  // function MINTER_ROLE() external returns (bytes32);

  function mint(address, uint256) external;

  function totalSupply() external returns (uint256);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function burn(uint256 amount) external;

  function burnWhenDeprecated(address account, uint256 amount) external;

  function deprecateToken() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
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

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
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

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
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

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
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

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
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

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
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

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
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

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
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

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
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

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
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

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
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

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
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

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
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

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
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

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.15;

import "./IMarketCommon.sol";
import "./IOracleManagerFixedEpoch.sol";
import "./IRegistry.sol";

interface IMarketExtended is IMarketCommon {
  // Without this struct we get stack to deep errors. Grouping the data helps!
  struct InitializePoolsParams {
    IMarketCommon.PoolInfo[] initPools;
    uint256 initialEffectiveLiquidityToSeedEachPool;
    address seederAndAdmin;
    uint32 _marketIndex;
    address oracleManager;
    address yieldManager;
  }

  function initializePools(InitializePoolsParams memory params) external returns (bool);

  function paymentToken() external view returns (address);

  function longShort() external view returns (IRegistry);

  function gems() external view returns (address);

  function get_mintingPaused() external view returns (bool);

  function get_marketDeprecated() external view returns (bool);

  // function yieldManager() external view returns (address);

  function updateMarketOracle(IOracleManagerFixedEpoch _newOracleManager) external;
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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