// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/AppErrors.sol";
import "../libs/AppUtils.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../openzeppelin/EnumerableSet.sol";
import "../interfaces/IPoolAdapter.sol";
import "../interfaces/IConverterController.sol";
import "../interfaces/IDebtMonitor.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IBorrowManager.sol";
import "../interfaces/ITetuConverter.sol";

/// @notice Manage list of open borrow positions
contract DebtMonitor is IDebtMonitor {
  using AppUtils for uint;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct CheckHealthFactorInputParams {
    uint startIndex0;
    uint maxCountToCheck;
    uint maxCountToReturn;
    uint healthFactorThreshold18;
  }

  IConverterController public immutable controller;
  /// @notice Same as controller.borrowManager()
  /// @dev Cached for the gas optimization
  IBorrowManager public immutable borrowManager;

  /// @notice Pool adapters with active borrow positions
  /// @dev All these pool adapters should be enumerated during health-checking
  address[] public positions;

  /// @notice Pool adapter => block number of last call of onOpenPosition
  mapping(address => uint) public positionLastAccess;

  /// @notice List of opened positions for the given set (user, collateral, borrowToken)
  /// @dev PoolAdapterKey(== keccak256(user, collateral, borrowToken)) => poolAdapters
  mapping(uint => address[]) public poolAdapters;

  /// @notice List of opened positions for the given user
  /// @dev User => List of pool adapters
  mapping(address => EnumerableSet.AddressSet) private _poolAdaptersForUser;

  /// @notice Template pool adapter => list of ACTIVE pool adapters created on the base of the template
  /// @dev We need it to prevent removing a pool from the borrow manager when the pool is in use
  mapping(address => EnumerableSet.AddressSet) private _poolAdaptersForConverters;

// Future versions
//  /// @notice threshold for APRs difference, i.e. _thresholdApr100 = 20 for (apr0-apr1)/apr0 > 20%
//  ///         0 - disable the limitation by value of APR difference
//  uint public thresholdAPR;
//
//  /// @notice best-way reconversion is allowed only after passing specified count of blocks since last reconversion
//  ///         0 - disable the limitation by count of blocks passed since last onOpenPosition call
//  uint public thresholdCountBlocks;

  //-----------------------------------------------------
  ///               Events
  //-----------------------------------------------------
//  event OnSetThresholdAPR(uint value100);
//  event OnSetThresholdCountBlocks(uint counbBlocks);
  event OnOpenPosition(address poolAdapter);
  event OnClosePosition(address poolAdapter);
  event OnCloseLiquidatedPosition(address poolAdapter, uint amountToPay);

  //-----------------------------------------------------
  ///       Constructor and initialization
  //-----------------------------------------------------

  constructor(
    address controller_,
    address borrowManager_
//    uint thresholdAPR_,
//    uint thresholdCountBlocks_
  ) {
    require(
      controller_ != address(0)
      && borrowManager_ != address(0),
      AppErrors.ZERO_ADDRESS
    );
    controller = IConverterController(controller_);
    borrowManager = IBorrowManager(borrowManager_);

// Future versions:
//    require(thresholdAPR_ < 100, AppErrors.INCORRECT_VALUE);
//    thresholdAPR = thresholdAPR_;
//
//    // we don't need any restriction for countBlocks_
//    // 0 - means, that the threshold is disabled
//    thresholdCountBlocks = thresholdCountBlocks_;
  }

  //-----------------------------------------------------
  ///               Access rights
  //-----------------------------------------------------


  //-----------------------------------------------------
  ///       Operations with positions
  //-----------------------------------------------------

  /// @notice Check if the pool-adapter-caller has an opened position
  function isPositionOpened() external override view returns (bool) {
    return positionLastAccess[msg.sender] != 0;
  }

  /// @notice Register new borrow position if it's not yet registered
  /// @dev This function is called from a pool adapter after any borrow
  function onOpenPosition() external override {
    require(borrowManager.isPoolAdapter(msg.sender), AppErrors.POOL_ADAPTER_ONLY);

    if (positionLastAccess[msg.sender] == 0) {
      positionLastAccess[msg.sender] = block.number;
      positions.push(msg.sender);

      (address origin,
       address user,
       address collateralAsset,
       address borrowAsset
      ) = IPoolAdapter(msg.sender).getConfig();

      poolAdapters[getPoolAdapterKey(user, collateralAsset, borrowAsset)].push(msg.sender);
      _poolAdaptersForUser[user].add(msg.sender);

      _poolAdaptersForConverters[origin].add(msg.sender);
      emit OnOpenPosition(msg.sender);
    }
  }

  /// @notice Unregister the borrow position if it's completely repaid
  /// @dev This function is called from a pool adapter when the borrow is completely repaid
  function onClosePosition() external override {
    // This method should be called by pool adapters only
    // we check it through positionLastAccess
    require(
      positionLastAccess[msg.sender] != 0,
      AppErrors.BORROW_POSITION_IS_NOT_REGISTERED
    );

    (uint collateralAmount, uint amountToPay,,,,) = IPoolAdapter(msg.sender).getStatus();
    require(collateralAmount == 0 && amountToPay == 0, AppErrors.ATTEMPT_TO_CLOSE_NOT_EMPTY_BORROW_POSITION);

    _closePosition(msg.sender, false);
    emit OnClosePosition(msg.sender);
  }

  /// @notice Remove the pool adapter from all lists of the opened positions
  /// @param poolAdapter_ Pool adapter to be closed
  /// @param markAsDirty_ Mark the pool adapter as "dirty" in borrow manager
  ///                     to exclude the pool adapter from any new borrows
  function _closePosition(address poolAdapter_, bool markAsDirty_) internal {
    positionLastAccess[poolAdapter_] = 0;
    AppUtils.removeItemFromArray(positions, poolAdapter_);
    (address origin, address user, address collateralAsset, address borrowAsset) = IPoolAdapter(poolAdapter_).getConfig();

    AppUtils.removeItemFromArray(poolAdapters[getPoolAdapterKey(user, collateralAsset, borrowAsset)], poolAdapter_);
    _poolAdaptersForUser[user].remove(poolAdapter_);
    _poolAdaptersForConverters[origin].remove(poolAdapter_);

    if (markAsDirty_) {
      // We have dropped away the pool adapter. It cannot be used any more for new borrows
      // Mark the pool adapter as dirty in borrow manager to exclude the pool adapter from any new borrows
      if (poolAdapter_ == borrowManager.getPoolAdapter(origin, user, collateralAsset, borrowAsset)) {
        borrowManager.markPoolAdapterAsDirty(origin, user, collateralAsset, borrowAsset);
      }
    }
  }

  /// @notice Pool adapter has opened borrow, but full liquidation happens and we've lost all collateral
  ///         Close position without paying the debt and never use the pool adapter again.
  function closeLiquidatedPosition(address poolAdapter_) external override {
    require(msg.sender == controller.tetuConverter(), AppErrors.TETU_CONVERTER_ONLY);

    (uint collateralAmount, uint amountToPay,,,,) = IPoolAdapter(poolAdapter_).getStatus();
    require(collateralAmount == 0, AppErrors.CANNOT_CLOSE_LIVE_POSITION);
    _closePosition(poolAdapter_, true);

    emit OnCloseLiquidatedPosition(poolAdapter_, amountToPay);
  }
  //-----------------------------------------------------
  ///           Detect unhealthy positions
  //-----------------------------------------------------

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
  ) external view override returns (
    uint nextIndexToCheck0,
    address[] memory outPoolAdapters,
    uint[] memory outAmountBorrowAsset,
    uint[] memory outAmountCollateralAsset
  ) {
    return _checkHealthFactor(
      CheckHealthFactorInputParams({
        startIndex0: startIndex0,
        maxCountToCheck: maxCountToCheck,
        maxCountToReturn: maxCountToReturn,
        healthFactorThreshold18: uint(controller.minHealthFactor2()) * 10**(18-2)
      })
    );
  }

  function _checkHealthFactor (
    CheckHealthFactorInputParams memory p
  ) internal view returns (
    uint nextIndexToCheck0,
    address[] memory outPoolAdapters,
    uint[] memory outAmountBorrowAsset,
    uint[] memory outAmountCollateralAsset
  ) {
    uint countFoundItems = 0;
    nextIndexToCheck0 = p.startIndex0;

    outPoolAdapters = new address[](p.maxCountToReturn);
    outAmountBorrowAsset = new uint[](p.maxCountToReturn);
    outAmountCollateralAsset = new uint[](p.maxCountToReturn);

    if (p.startIndex0 + p.maxCountToCheck > positions.length) {
      p.maxCountToCheck = positions.length - p.startIndex0;
    }

    // enumerate all pool adapters
    for (uint i = 0; i < p.maxCountToCheck; i = i.uncheckedInc()) {
      nextIndexToCheck0 += 1;

      // check if we need to make reconversion because the health factor is too low/high
      IPoolAdapter pa = IPoolAdapter(positions[p.startIndex0 + i]);

      (uint collateralAmount, uint amountToPay, uint healthFactor18,,,) = pa.getStatus();
      // If full liquidation happens we will have collateralAmount = 0 and amountToPay > 0
      // In this case the open position should be just closed (we lost all collateral)
      // We cannot do it here because it's read-only function.
      // We should call a IKeeperCallback in the same way as for rebalancing, but with requiredAmountCollateralAsset=0

      (,,, address borrowAsset) = pa.getConfig();
      uint healthFactorTarget18 = uint(borrowManager.getTargetHealthFactor2(borrowAsset)) * 10**(18-2);
      if (
        (p.healthFactorThreshold18 < healthFactorTarget18 && healthFactor18 < p.healthFactorThreshold18) // unhealthy
        || (!(p.healthFactorThreshold18 < healthFactorTarget18) && healthFactor18 > p.healthFactorThreshold18) // too healthy
      ) {
        outPoolAdapters[countFoundItems] = positions[p.startIndex0 + i];
        // Health Factor = Collateral Factor * CollateralAmount * Price_collateral
        //                 -------------------------------------------------
        //                               BorrowAmount * Price_borrow
        // => requiredAmountBorrowAsset = BorrowAmount * (HealthFactorCurrent/HealthFactorTarget - 1)
        // => requiredAmountCollateralAsset = CollateralAmount * (HealthFactorTarget/HealthFactorCurrent - 1)
        outAmountBorrowAsset[countFoundItems] = p.healthFactorThreshold18 < healthFactorTarget18
            ? (amountToPay - amountToPay * healthFactor18 / healthFactorTarget18) // unhealthy
            : (amountToPay * healthFactor18 / healthFactorTarget18 - amountToPay); // too healthy
        outAmountCollateralAsset[countFoundItems] = p.healthFactorThreshold18 < healthFactorTarget18
            ? (collateralAmount * healthFactorTarget18 / healthFactor18 - collateralAmount) // unhealthy
            : (collateralAmount - collateralAmount * healthFactorTarget18 / healthFactor18); // too healthy
        countFoundItems += 1;

        if (countFoundItems == p.maxCountToReturn) {
          break;
        }
      }
    }

    if (nextIndexToCheck0 == positions.length) {
      nextIndexToCheck0 = 0; // all items were checked
    }

    // we need to keep only found items in result array and remove others
    return (nextIndexToCheck0,
      countFoundItems == 0
        ? new address[](0)
        : AppUtils.removeLastItems(outPoolAdapters, countFoundItems),
      countFoundItems == 0
        ? new uint[](0)
        : AppUtils.removeLastItems(outAmountBorrowAsset, countFoundItems),
      countFoundItems == 0
        ? new uint[](0)
        : AppUtils.removeLastItems(outAmountCollateralAsset, countFoundItems)
    );
  }

  //-----------------------------------------------------
  ///                   Views
  //-----------------------------------------------------

  /// @notice Get active borrows of the user with given collateral/borrowToken
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositions (
    address user_,
    address collateralToken_,
    address borrowedToken_
  ) external view override returns (
    address[] memory poolAdaptersOut
  ) {
    address[] memory adapters = poolAdapters[getPoolAdapterKey(user_, collateralToken_, borrowedToken_)];
    uint countAdapters = adapters.length;

    poolAdaptersOut = new address[](countAdapters);

    for (uint i = 0; i < countAdapters; i = i.uncheckedInc()) {
      poolAdaptersOut[i] = adapters[i];
    }

    return poolAdaptersOut;
  }

  /// @notice Get active borrows of the given user
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositionsForUser(address user_) external view override returns(
    address[] memory poolAdaptersOut
  ) {
    EnumerableSet.AddressSet storage set = _poolAdaptersForUser[user_];
    uint countAdapters = set.length();

    poolAdaptersOut = new address[](countAdapters);

    for (uint i = 0; i < countAdapters; i = i.uncheckedInc()) {
      poolAdaptersOut[i] = set.at(i);
    }

    return poolAdaptersOut;
  }

  /// @notice Return true if there is a least once active pool adapter created on the base of the {converter_}
  function isConverterInUse(address converter_) external view override returns (bool) {
    return _poolAdaptersForConverters[converter_].length() != 0;
  }

  //-----------------------------------------------------
  ///                     Utils
  //-----------------------------------------------------
  function getPoolAdapterKey(
    address user_,
    address collateral_,
    address borrowToken_
  ) public pure returns (uint){
    return uint(keccak256(abi.encodePacked(user_, collateral_, borrowToken_)));
  }

  //-----------------------------------------------------
  ///               Access to arrays
  //-----------------------------------------------------

  /// @notice Get total count of pool adapters with opened positions
  function getCountPositions() external view override returns (uint) {
    return positions.length;
  }

  function poolAdaptersLength(
    address user_,
    address collateral_,
    address borrowToken_
  ) external view returns (uint) {
    return poolAdapters[getPoolAdapterKey(user_, collateral_, borrowToken_)].length;
  }
}



//-----------------------------------------------------
///     Features for NEXT versions of the app
///         Detect not-optimal positions
///         Check too healthy factor
//-----------------------------------------------------

//  function checkAdditionalBorrow(
//    uint startIndex0,
//    uint maxCountToCheck,
//    uint maxCountToReturn
//  ) external view override returns (
//    uint nextIndexToCheck0,
//    address[] memory outPoolAdapters,
//    uint[] memory outAmountsToBorrow
//  ) {
//    uint16 maxHealthFactor2 = IConverterController(controller).maxHealthFactor2();
//
//    return _checkHealthFactor(startIndex0
//      , maxCountToCheck
//      , maxCountToReturn
//      , uint(maxHealthFactor2) * 10**(18-2)
//    );
//  }

//  function checkBetterBorrowExists(
//    uint startIndex0,
//    uint maxCountToCheck,
//    uint maxCountToReturn,
//    uint periodInBlocks // TODO: this period is set individually for each borrow...
//  ) external view override returns (
//    uint nextIndexToCheck0,
//    address[] memory outPoolAdapters
//  ) {
//    uint countFoundItems = 0;
//    nextIndexToCheck0 = startIndex0;
//
//    ITetuConverter tc = ITetuConverter(controller.tetuConverter());
//    outPoolAdapters = new address[](maxCountToReturn);
//
//    if (startIndex0 + maxCountToCheck > positions.length) {
//      maxCountToCheck = positions.length - startIndex0;
//    }
//
//    // enumerate all pool adapters
//    for (uint i = 0; i < maxCountToCheck; i = i.uncheckedInc()) {
//      nextIndexToCheck0 += 1;
//
//      // check if we need to make reconversion because a MUCH better borrow way exists
//      IPoolAdapter pa = IPoolAdapter(positions[startIndex0 + i]);
//      (uint collateralAmount,,,) = pa.getStatus();
//
//      if (_findBetterBorrowWay(tc, pa, collateralAmount, periodInBlocks)) {
//        outPoolAdapters[countFoundItems] = positions[startIndex0 + i];
//        countFoundItems += 1;
//        if (countFoundItems == maxCountToReturn) {
//          break;
//        }
//      }
//    }
//
//    if (nextIndexToCheck0 == positions.length) {
//      nextIndexToCheck0 = 0; // all items were checked
//    }
//
//    // we need to keep only found items in result array and remove others
//    return (nextIndexToCheck0
//    , countFoundItems == 0
//      ? new address[](0)
//      : AppUtils.removeLastItems(outPoolAdapters, countFoundItems)
//    );
//  }
//
//  function _findBetterBorrowWay(
//    ITetuConverter tc_,
//    IPoolAdapter pa_,
//    uint sourceAmount_,
//    uint periodInBlocks_
//  ) internal view returns (bool) {
//
//    // check if we can re-borrow the asset in different place with higher profit
//    (address origin,, address sourceToken, address targetToken) = pa_.getConfig();
//    (address converter,, int apr18) = tc_.findConversionStrategy(
//      sourceToken, sourceAmount_, targetToken, periodInBlocks_, ITetuConverter.ConversionMode.AUTO_0
//    );
//    int currentApr18 = pa_.getAPR18() * int(periodInBlocks_);
//
//    // make decision if the new conversion-strategy is worth to be used instead current one
//    if (origin != converter) {
//      //1) threshold for APRs difference exceeds threshold, i.e. (apr0-apr1)/apr0 > 20%
//      if (currentApr18 > apr18
//         && (thresholdAPR == 0 || currentApr18 - apr18 > currentApr18 * int(thresholdAPR) / 100)
//      ) {
//        //2) threshold for block number: count blocks since prev rebalancing should exceed the threshold.
//        if (thresholdCountBlocks == 0 || block.number - positionLastAccess[address(pa_)] > thresholdCountBlocks) {
//          return true;
//        }
//      }
//    }
//    return false;
//  }
//
//  function setThresholdAPR(uint value100_) external {
//    _onlyGovernance();
//    require(value100_ < 100, AppErrors.INCORRECT_VALUE);
//    thresholdAPR = value100_;
//    emit OnSetThresholdAPR(value100_);
//  }
//
//  function setThresholdCountBlocks(uint countBlocks_) external {
//    _onlyGovernance();
//    // we don't need any restriction for countBlocks_
//    // 0 - means, that the threshold is disabled
//    thresholdCountBlocks = countBlocks_;
//    emit OnSetThresholdCountBlocks(countBlocks_);
//  }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";

/// @notice Manage list of available lending platforms
///         Manager of pool-adapters.
///         Pool adapter is an instance of a converter provided by the lending platform
///         linked to one of platform's pools, address of user contract, collateral and borrow tokens.
///         The pool adapter is real borrower of funds for AAVE, Compound and other lending protocols.
///         Pool adapters are created using minimal-proxy pattern, see
///         https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
interface IBorrowManager {

  /// @notice Register a pool adapter for (pool, user, collateral) if the adapter wasn't created before
  /// @param user_ Address of the caller contract who requires access to the pool adapter
  /// @return Address of registered pool adapter
  function registerPoolAdapter(
    address converter_,
    address user_,
    address collateral_,
    address borrowToken_
  ) external returns (address);

  /// @notice Get pool adapter or 0 if the pool adapter is not registered
  function getPoolAdapter(
    address converter_,
    address user_,
    address collateral_,
    address borrowToken_
  ) external view returns (address);

  /// @dev Returns true for NORMAL pool adapters and for active DIRTY pool adapters (=== borrow position is opened).
  function isPoolAdapter(address poolAdapter_) external view returns (bool);

  /// @notice Notify borrow manager that the pool adapter with the given params is "dirty".
  ///         The pool adapter should be excluded from the list of ready-to-borrow pool adapters.
  /// @dev "Dirty" means that a liquidation happens inside. The borrow position should be closed during health checking.
  function markPoolAdapterAsDirty (
    address converter_,
    address user_,
    address collateral_,
    address borrowToken_
  ) external;

  /// @notice Register new lending platform with available pairs of assets
  ///         OR add new pairs of assets to the exist lending platform
  /// @param platformAdapter_ Implementation of IPlatformAdapter attached to the specified pool
  /// @param leftAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  /// @param rightAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  function addAssetPairs(
    address platformAdapter_,
    address[] calldata leftAssets_,
    address[] calldata rightAssets_
  ) external;

  /// @notice Remove available pairs of asset from the platform adapter.
  ///         The platform adapter will be unregistered after removing last supported pair of assets
  function removeAssetPairs(
    address platformAdapter_,
    address[] calldata leftAssets_,
    address[] calldata rightAssets_
  ) external;

  /// @notice Set target health factors for the assets.
  ///         If target health factor is not assigned to the asset, target-health-factor from controller is used.
  ///         See explanation of health factor value in IConverterController
  /// @param healthFactors2_ Health factor must be greater or equal then 1, decimals 2
  function setTargetHealthFactors(address[] calldata assets_, uint16[] calldata healthFactors2_) external;

  /// @notice Return target health factor with decimals 2 for the asset
  ///         If there is no custom value for asset, target health factor from the controller should be used
  function getTargetHealthFactor2(address asset) external view returns (uint16);

  /// @notice Reward APR is taken into account with given factor
  ///         Result APR = borrow-apr - supply-apr - [REWARD-FACTOR]/Denominator * rewards-APR
  function setRewardsFactor(uint rewardsFactor_) external;

  /// @notice Find lending pool capable of providing {targetAmount} and having best normalized borrow rate
  ///         Results are ordered in ascending order of APR, so the best available converter is first one.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                  See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  /// @param amountIn_ The meaning depends on entryData kind, see EntryKinds library for details.
  ///         For entry kind = 0: Amount of {sourceToken} to be converted to {targetToken}
  ///         For entry kind = 1: Available amount of {sourceToken}
  ///         For entry kind = 2: Amount of {targetToken} that should be received after conversion
  /// @return converters Result template-pool-adapters
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountsToBorrowOut Amounts that should be borrowed
  /// @return aprs18 Annual Percentage Rates == (total cost - total income) / amount of collateral, decimals 18
  function findConverter(
    bytes memory entryData_,
    address sourceToken_,
    address targetToken_,
    uint amountIn_,
    uint periodInBlocks_
  ) external view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountsToBorrowOut,
    int[] memory aprs18
  );

  /// @notice Get platformAdapter to which the converter belongs
  function getPlatformAdapter(address converter_) external view returns (address);
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

interface IPriceOracle {
  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverterController.sol";

/// @notice Main contract of the TetuConverter application
/// @dev Borrower (strategy) makes all operations via this contract only.
interface ITetuConverter {

  function controller() external view returns (IConverterController);

  /// @notice Find possible borrow strategies and provide "cost of money" as interest for the period for each strategy
  ///         Result arrays of the strategy are ordered in ascending order of APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converters Array of available converters ordered in ascending order of APR.
  ///                    Each item contains a result contract that should be used for conversion; it supports IConverter
  ///                    This address should be passed to borrow-function during conversion.
  ///                    The length of array is always equal to the count of available lending platforms.
  ///                    Last items in array can contain zero addresses (it means they are not used)
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountToBorrowsOut Amounts that should be borrowed
  ///                            This amount is not zero if corresponded converter is not zero.
  /// @return aprs18 Interests on the use of {amountIn_} during the given period, decimals 18
  function findBorrowStrategies(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountToBorrowsOut,
    int[] memory aprs18
  );

  /// @notice Find best swap strategy and provide "cost of money" as interest for the period
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @return converter Result contract that should be used for conversion to be passed to borrow()
  /// @return sourceAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                         It can be different from the {sourceAmount_} for some entry kinds.
  /// @return targetAmountOut Result amount of {targetToken_} after swap
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findSwapStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_
  ) external returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  );

  /// @notice Find best conversion strategy (swap or borrow) and provide "cost of money" as interest for the period.
  ///         It calls both findBorrowStrategy and findSwapStrategy and selects a best strategy.
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR for swapping.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converter Result contract that should be used for conversion to be passed to borrow().
  /// @return collateralAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                             It can be different from the {sourceAmount_} for some entry kinds.
  /// @return amountToBorrowOut Result amount of {targetToken_} after conversion
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findConversionStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external returns (
    address converter,
    uint collateralAmountOut,
    uint amountToBorrowOut,
    int apr18
  );

  /// @notice Convert {collateralAmount_} to {amountToBorrow_} using {converter_}
  ///         Target amount will be transferred to {receiver_}. No re-balancing here.
  /// @dev Transferring of {collateralAmount_} by TetuConverter-contract must be approved by the caller before the call
  ///      Only whitelisted users are allowed to make borrows
  /// @param converter_ A converter received from findBestConversionStrategy.
  /// @param collateralAmount_ Amount of {collateralAsset_} to be converted.
  ///                          This amount must be approved to TetuConverter before the call.
  /// @param amountToBorrow_ Amount of {borrowAsset_} to be borrowed and sent to {receiver_}
  /// @param receiver_ A receiver of borrowed amount
  /// @return borrowedAmountOut Exact borrowed amount transferred to {receiver_}
  function borrow(
    address converter_,
    address collateralAsset_,
    uint collateralAmount_,
    address borrowAsset_,
    uint amountToBorrow_,
    address receiver_
  ) external returns (
    uint borrowedAmountOut
  );

  /// @notice Full or partial repay of the borrow
  /// @dev A user should transfer {amountToRepay_} to TetuConverter before calling repay()
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        You can know exact total amount of debt using {getStatusCurrent}.
  ///        if the amount exceed total amount of the debt:
  ///           - the debt will be fully repaid
  ///           - remain amount will be swapped from {borrowAsset_} to {collateralAsset_}
  ///        This amount should be calculated with taking into account possible debt gap,
  ///        You should call getDebtAmountCurrent(debtGap = true) to get this amount.
  /// @param receiver_ A receiver of the collateral that will be withdrawn after the repay
  ///                  The remained amount of borrow asset will be returned to the {receiver_} too
  /// @return collateralAmountOut Exact collateral amount transferred to {collateralReceiver_}
  ///         If TetuConverter is not able to make the swap, it reverts
  /// @return returnedBorrowAmountOut A part of amount-to-repay that wasn't converted to collateral asset
  ///                                 because of any reasons (i.e. there is no available conversion strategy)
  ///                                 This amount is returned back to the collateralReceiver_
  /// @return swappedLeftoverCollateralOut A part of collateral received through the swapping
  /// @return swappedLeftoverBorrowOut A part of amountToRepay_ that was swapped
  function repay(
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_,
    address receiver_
  ) external returns (
    uint collateralAmountOut,
    uint returnedBorrowAmountOut,
    uint swappedLeftoverCollateralOut,
    uint swappedLeftoverBorrowOut
  );

  /// @notice Estimate result amount after making full or partial repay
  /// @dev It works in exactly same way as repay() but don't make actual repay
  ///      Anyway, the function is write, not read-only, because it makes updateStatus()
  /// @param user_ user whose amount-to-repay will be calculated
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///        This amount should be calculated without possible debt gap.
  ///        In this way it's differ from {repay}
  /// @return collateralAmountOut Total collateral amount to be returned after repay in exchange of {amountToRepay_}
  function quoteRepay(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_
  ) external returns (
    uint collateralAmountOut
  );

  /// @notice Update status in all opened positions
  ///         After this call getDebtAmount will be able to return exact amount to repay
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountCurrent(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice Total amount of borrow tokens that should be repaid to close the borrow completely.
  /// @param user_ user whose debts will be returned
  /// @param useDebtGap_ Calculate exact value of the debt (false) or amount to pay (true)
  ///        Exact value of the debt can be a bit different from amount to pay, i.e. AAVE has dust tokens problem.
  ///        Exact amount of debt should be used to calculate shared price, amount to pay - for repayment
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountStored(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    bool useDebtGap_
  ) external view returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice User needs to redeem some collateral amount. Calculate an amount of borrow token that should be repaid
  /// @param user_ user whose debts will be returned
  /// @param collateralAmountRequired_ Amount of collateral required by the user
  /// @return borrowAssetAmount Borrowed amount that should be repaid to receive back following amount of collateral:
  ///                           amountToReceive = collateralAmountRequired_ - unobtainableCollateralAssetAmount
  /// @return unobtainableCollateralAssetAmount A part of collateral that cannot be obtained in any case
  ///                                           even if all borrowed amount will be returned.
  ///                                           If this amount is not 0, you ask to get too much collateral.
  function estimateRepay(
    address user_,
    address collateralAsset_,
    uint collateralAmountRequired_,
    address borrowAsset_
  ) external view returns (
    uint borrowAssetAmount,
    uint unobtainableCollateralAssetAmount
  );

  /// @notice Transfer all reward tokens to {receiver_}
  /// @return rewardTokensOut What tokens were transferred. Same reward token can appear in the array several times
  /// @return amountsOut Amounts of transferred rewards, the array is synced with {rewardTokens}
  function claimRewards(address receiver_) external returns (
    address[] memory rewardTokensOut,
    uint[] memory amountsOut
  );

  /// @notice Swap {amountIn_} of {assetIn_} to {assetOut_} and send result amount to {receiver_}
  ///         The swapping is made using TetuLiquidator with checking price impact using embedded price oracle.
  /// @param amountIn_ Amount of {assetIn_} to be swapped.
  ///                      It should be transferred on balance of the TetuConverter before the function call
  /// @param receiver_ Result amount will be sent to this address
  /// @param priceImpactToleranceSource_ Price impact tolerance for liquidate-call, decimals = 100_000
  /// @param priceImpactToleranceTarget_ Price impact tolerance for price-oracle-check, decimals = 100_000
  /// @return amountOut The amount of {assetOut_} that has been sent to the receiver
  function safeLiquidate(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    address receiver_,
    uint priceImpactToleranceSource_,
    uint priceImpactToleranceTarget_
  ) external returns (
    uint amountOut
  );

  /// @notice Check if {amountOut_} is too different from the value calculated directly using price oracle prices
  /// @return Price difference is ok for the given {priceImpactTolerance_}
  function isConversionValid(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) external view returns (bool);

  /// @notice Close given borrow and return collateral back to the user, governance only
  /// @dev The pool adapter asks required amount-to-repay from the user internally
  /// @param poolAdapter_ The pool adapter that represents the borrow
  /// @param closePosition Close position after repay
  ///        Usually it should be true, because the function always tries to repay all debt
  ///        false can be used if user doesn't have enough amount to pay full debt
  ///              and we are trying to pay "as much as possible"
  /// @return collateralAmountOut Amount of collateral returned to the user
  /// @return repaidAmountOut Amount of borrow asset repaid to the lending platform
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (
    uint collateralAmountOut,
    uint repaidAmountOut
  );
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity 0.8.17;

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
    bytes32[] memory store = _values(set._inner);
    bytes32[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
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
   * @dev Returns the number of values in the set. O(1).
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