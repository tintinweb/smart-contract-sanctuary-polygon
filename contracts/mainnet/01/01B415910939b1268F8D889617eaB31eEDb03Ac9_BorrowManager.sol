// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";
import "../libs/AppErrors.sol";
import "../libs/AppUtils.sol";
import "../openzeppelin/Clones.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/EnumerableSet.sol";
import "../openzeppelin/EnumerableMap.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../interfaces/IPlatformAdapter.sol";
import "../interfaces/IBorrowManager.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IConverterController.sol";
import "../interfaces/IDebtMonitor.sol";
import "../interfaces/ITetuConverter.sol";
import "../integrations/market/ICErc20.sol";

/// @notice Contains list of lending pools. Allow to select most efficient pool for the given collateral/borrow pair
contract BorrowManager is IBorrowManager {
  using SafeERC20 for IERC20;
  using AppUtils for uint;
  using Clones for address;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  /// @notice Reward APR is taken into account with given factor
  ///         Result APR = borrow-apr - supply-apr - Factor/Denominator * rewards-APR
  uint constant public REWARDS_FACTOR_DENOMINATOR_18 = 1e18;

  IConverterController public immutable controller;

  //-----------------------------------------------------
  //region Structs and enums
  //-----------------------------------------------------

  /// @notice Pair of two assets. Asset 1 can be converted to asset 2 and vice versa.
  /// @dev There are no restrictions for {assetLeft} and {assertRight}. Each can be smaller than the other.
  struct AssetPair {
    address assetLeft;
    address assetRight;
  }
  //endregion Structs and enums

  //-----------------------------------------------------
  //region Members
  //-----------------------------------------------------

  /// @notice Reward APR is taken into account with given factor
  /// @dev decimals 18. The value is divided on {REWARDS_FACTOR_DENOMINATOR_18}
  uint public rewardsFactor;

  /// @notice all registered platform adapters
  EnumerableSet.AddressSet private _platformAdapters;

  /// @notice all asset pairs registered for the platform adapter
  /// @dev PlatformAdapter : [key of asset pair]
  mapping(address => EnumerableSet.UintSet) private _platformAdapterPairs;

  /// @notice all platform adapters for which the asset pair is registered
  /// @dev Key of pair asset => [list of platform adapters]
  mapping(uint => EnumerableSet.AddressSet) private _pairsList;

  /// @notice Key of pair asset => Asset pair
  mapping(uint => AssetPair) private _assetPairs;

  /// @notice Default health factors (HF) for assets. Default HF is used if user hasn't provided HF value, decimals 2
  /// @dev asset => Health factor (== collateral / minimum collateral. It should be greater then MIN_HEALTH_FACTOR)
  mapping(address => uint16) public targetHealthFactorsForAssets;

  /// @notice Converter : platform adapter
  mapping(address => address) public converterToPlatformAdapter;

  /// @notice List of pool adapters ready to borrow, i.e. with not-dirty state.
  ///         Any pool adapter with state DIRTY is removed from this list as soon as its dirty-state is detected.
  /// @dev user => PoolAdapterKey(== keccak256(converter, collateral, borrowToken)) => address of the pool adapter
  mapping (address => EnumerableMap.UintToAddressMap) private _poolAdapters;

  /// @notice Pool adapter => (1 + index of the pool adapter in {listPoolAdapters})
  /// @dev This list contains info for all ever created pool adapters (both for not-dirty and dirty ones).
  mapping (address => uint) public poolAdaptersRegistered;

  /// @notice List of addresses of all ever created pool adapters (both for not-dirty and dirty ones).
  /// @dev Allow to get full list of the pool adapter and then filter it by any criteria (asset, user, state, etc)
  address[] public listPoolAdapters;
  //endregion Members

  //-----------------------------------------------------
  //region Events
  //-----------------------------------------------------
  event OnSetTargetHealthFactors(address[] assets, uint16[] healthFactors2);
  event OnSetRewardsFactor(uint rewardsFactor);
  event OnAddAssetPairs(address platformAdapter, address[] leftAssets, address[] rightAssets);
  event OnRemoveAssetPairs(address platformAdapter, address[] leftAssets, address[] rightAssets);
  event OnUnregisterPlatformAdapter(address platformAdapter);
  event OnRegisterPoolAdapter(address poolAdapter, address converter, address user, address collateralAsset, address borrowAsset);
  event OnMarkPoolAdapterAsDirty(address poolAdapter);
  //endregion Events

  //-----------------------------------------------------
  //region Initialization
  //-----------------------------------------------------

  constructor (address controller_, uint rewardsFactor_) {
    require(controller_ != address(0), AppErrors.ZERO_ADDRESS);
    controller = IConverterController(controller_);

    // we assume rewards amount should be downgraded in calcs coz liquidation gaps
    require(rewardsFactor_ < REWARDS_FACTOR_DENOMINATOR_18, AppErrors.INCORRECT_VALUE);
    rewardsFactor = rewardsFactor_;
  }
  //endregion Initialization

  //-----------------------------------------------------
  //region Access rights
  //-----------------------------------------------------

  /// @notice Ensure that msg.sender is registered pool adapter
  function _onlyTetuConverter() internal view {
    require(
      msg.sender == controller.tetuConverter(),
      AppErrors.TETU_CONVERTER_ONLY
    );
  }

  /// @notice Ensure that msg.sender is registered pool adapter
  function _onlyGovernance() internal view {
    require(msg.sender == controller.governance(), AppErrors.GOVERNANCE_ONLY);
  }
  //endregion Access rights

  //-----------------------------------------------------
  //region Configuration
  //-----------------------------------------------------

  /// @notice Set target health factors for the assets.
  ///         If target health factor is not assigned to the asset, target-health-factor from controller is used.
  /// @param healthFactors2_ Health factor must be greater then 1, decimals 2
  function setTargetHealthFactors(address[] calldata assets_, uint16[] calldata healthFactors2_) external override {
    _onlyGovernance();
    uint countItems = assets_.length;
    require(countItems == healthFactors2_.length, AppErrors.WRONG_LENGTHS);

    for (uint i = 0; i < countItems; i = i.uncheckedInc()) {
      require(healthFactors2_[i] >= controller.minHealthFactor2(), AppErrors.WRONG_HEALTH_FACTOR);
      targetHealthFactorsForAssets[assets_[i]] = healthFactors2_[i];
    }

    emit OnSetTargetHealthFactors(assets_, healthFactors2_);
  }

  /// @notice Reward APR is taken into account with given factor
  ///         Result APR = borrow-apr - supply-apr - [REWARD-FACTOR]/Denominator * rewards-APR
  function setRewardsFactor(uint rewardsFactor_) external override {
    _onlyGovernance();
    require(rewardsFactor_ < REWARDS_FACTOR_DENOMINATOR_18, AppErrors.INCORRECT_VALUE);
    rewardsFactor = rewardsFactor_;

    emit OnSetRewardsFactor(rewardsFactor_);
  }

  /// @notice Register new lending platform with available pairs of assets
  ///         OR add new pairs of assets to the exist lending platform
  /// @param platformAdapter_ Implementation of IPlatformAdapter attached to the specified pool
  /// @param leftAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  /// @param rightAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  function addAssetPairs(
    address platformAdapter_,
    address[] calldata leftAssets_,
    address[] calldata rightAssets_
  ) external override {
    _onlyGovernance();

    uint lenAssets = rightAssets_.length;
    require(leftAssets_.length == lenAssets, AppErrors.WRONG_LENGTHS);

    // register new platform adapter if necessary
    _platformAdapters.add(platformAdapter_);

    // register all available template pool adapters
    address[] memory paConverters = IPlatformAdapter(platformAdapter_).converters();
    uint lenConverters = paConverters.length;
    for (uint i = 0; i < lenConverters; i = i.uncheckedInc()) {
      // the relation "platform adapter - converter" is invariant
      address platformAdapterForConverter = converterToPlatformAdapter[paConverters[i]];
      if (platformAdapter_ != platformAdapterForConverter) {
        require(platformAdapterForConverter == address(0), AppErrors.ONLY_SINGLE_PLATFORM_ADAPTER_CAN_USE_CONVERTER);
        converterToPlatformAdapter[paConverters[i]] = platformAdapter_;
      }
    }

    // register all provided asset pairs
    for (uint i = 0; i < lenAssets; i = i.uncheckedInc()) {
      uint assetPairKey = getAssetPairKey(leftAssets_[i], rightAssets_[i]);
      if (_assetPairs[assetPairKey].assetLeft == address(0)) {
        _assetPairs[assetPairKey] = AssetPair({
          assetLeft: leftAssets_[i],
          assetRight: rightAssets_[i]
        });
      }
      _pairsList[assetPairKey].add(platformAdapter_);
      _platformAdapterPairs[platformAdapter_].add(assetPairKey);
    }

    emit OnAddAssetPairs(platformAdapter_, leftAssets_, rightAssets_);
  }

  /// @notice Remove available pairs of asset from the platform adapter.
  ///         The platform adapter will be unregistered after removing last supported pair of assets
  function removeAssetPairs(
    address platformAdapter_,
    address[] calldata leftAssets_,
    address[] calldata rightAssets_
  ) external override {
    _onlyGovernance();

    uint lenAssets = rightAssets_.length;
    require(leftAssets_.length == lenAssets, AppErrors.WRONG_LENGTHS);
    require(_platformAdapters.contains(platformAdapter_), AppErrors.PLATFORM_ADAPTER_NOT_FOUND);
    IDebtMonitor debtMonitor = IDebtMonitor(controller.debtMonitor());

    // unregister the asset pairs
    for (uint i = 0; i < lenAssets; i = i.uncheckedInc()) {
      uint assetPairKey = getAssetPairKey(leftAssets_[i], rightAssets_[i]);
      _pairsList[assetPairKey].remove(platformAdapter_);
      _platformAdapterPairs[platformAdapter_].remove(assetPairKey);
    }

    // if platform adapter doesn't have any asset pairs, we unregister it
    if (_platformAdapterPairs[platformAdapter_].length() == 0) {
      // unregister all template pool adapters
      address[] memory paConverters = IPlatformAdapter(platformAdapter_).converters();
      uint lenConverters = paConverters.length;
      for (uint i = 0; i < lenConverters; i = i.uncheckedInc()) {
        // If there is active pool adapter for the platform adapter, we cannot unregister the platform adapter
        require(!debtMonitor.isConverterInUse(paConverters[i]), AppErrors.PLATFORM_ADAPTER_IS_IN_USE);
        converterToPlatformAdapter[paConverters[i]] = address(0);
      }

      // unregister platform adapter
      _platformAdapters.remove(platformAdapter_);
      emit OnUnregisterPlatformAdapter(platformAdapter_);
    }

    emit OnRemoveAssetPairs(platformAdapter_, leftAssets_, rightAssets_);
  }
  //endregion Configuration

  //-----------------------------------------------------
  //region Find best pool for borrowing
  //-----------------------------------------------------

  /// @notice Find lending pool capable of providing {targetAmount} and having best normalized borrow rate
  ///         Results are ordered in ascending order of APR, so the best available converter is first one.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                  See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  /// @param amountIn_ The meaning depends on entryData kind, see EntryKinds library for details.
  ///         For entry kind = 0: Amount of {sourceToken} to be converted to {targetToken}
  ///         For entry kind = 1: Available amount of {sourceToken}
  ///         For entry kind = 2: Amount of {targetToken} that should be received after conversion
  /// @return convertersOut Result template-pool-adapters
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountsToBorrowOut Amounts that should be borrowed
  /// @return aprs18Out Annual Percentage Rates == (total cost - total income) / amount of collateral, decimals 18
  function findConverter(
    bytes memory entryData_,
    address sourceToken_,
    address targetToken_,
    uint amountIn_,
    uint periodInBlocks_
  ) external view override returns (
    address[] memory convertersOut,
    uint[] memory collateralAmountsOut,
    uint[] memory amountsToBorrowOut,
    int[] memory aprs18Out
  ) {
    AppDataTypes.InputConversionParams memory params = AppDataTypes.InputConversionParams({
    collateralAsset: sourceToken_,
    borrowAsset: targetToken_,
    amountIn: amountIn_,
    countBlocks: periodInBlocks_,
    entryData: entryData_
    });
    return _findConverter(params);
  }

  /// @notice Find lending pool capable of providing {targetAmount} and having best normalized borrow rate
  ///         Results are ordered in ascending order of APR, so the best available converter is first one.
  /// @return convertersOut Result template-pool-adapters
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountsToBorrowOut Amounts that should be borrowed
  /// @return aprs18Out Annual Percentage Rates == (total cost - total income) / amount of collateral, decimals 18
  function _findConverter(AppDataTypes.InputConversionParams memory p_) internal view returns (
    address[] memory convertersOut,
    uint[] memory collateralAmountsOut,
    uint[] memory amountsToBorrowOut,
    int[] memory aprs18Out
  ) {
    // get all platform adapters that support required pair of assets
    EnumerableSet.AddressSet storage pas = _pairsList[getAssetPairKey(p_.collateralAsset, p_.borrowAsset)];

    address[] memory converters;
    uint[] memory collateralAmounts;
    uint[] memory amountsToBorrow;
    int[] memory aprs18;
    uint countFoundItems;
    if (pas.length() != 0) {
      (converters, collateralAmounts, amountsToBorrow, aprs18, countFoundItems) = _findPool(
        pas,
        p_,
        getTargetHealthFactor2(p_.collateralAsset)
      );
    }

    if (countFoundItems > 0) {
      // shrink output arrays to {countFoundItems} items and order results in ascending order of APR
      return AppUtils.shrinkAndOrder(countFoundItems, converters, collateralAmounts, amountsToBorrow, aprs18);
    } else {
      return (convertersOut, collateralAmountsOut, amountsToBorrowOut, aprs18Out);
    }
  }

  /// @notice Enumerate all pools suitable for borrowing and enough liquidity.
  /// General explanation how max-target-amount is calculated in all pool adapters:
  /// Health factor = HF [-], Collateral amount = C [USD]
  /// Source amount that can be used for the collateral = SA [SA], Borrow amount = BS [USD]
  /// Price of the source amount = PS [USD/SA] (1 [SA] = PS[USD])
  /// Price of the target amount = PT [USD/TA] (1 [TA] = PT[USD])
  /// Pool params: Collateral factor of the pool = PCF [-], Available cash in the pool = PTA [TA]
  ///
  /// C = SA * PS, BS = C / HF * PCF
  /// Max target amount capable to be borrowed: ResultTA = BS / PT [TA].
  /// We can use the pool only if ResultTA >= PTA >= required-target-amount
  /// @dev We cannot make this function public because storage-param is used
  /// @return converters All found converters without ordering.
  ///                    The size of array is always equal to the count of available lending platforms.
  ///                    The array is sparse, unused items are zero.
  function _findPool(
    EnumerableSet.AddressSet storage platformAdapters_,
    AppDataTypes.InputConversionParams memory p_,
    uint16 healthFactor2_
  ) internal view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountsToBorrowOut,
    int[] memory aprs18,
    uint countFoundItems
  ) {
    uint lenPools = platformAdapters_.length();

    converters = new address[](lenPools);
    collateralAmountsOut = new uint[](lenPools);
    amountsToBorrowOut = new uint[](lenPools);
    aprs18 = new int[](lenPools);

    for (uint i; i < lenPools; i = i.uncheckedInc()) {
      AppDataTypes.ConversionPlan memory plan = IPlatformAdapter(platformAdapters_.at(i)).getConversionPlan(
        p_,
        healthFactor2_
      );

      if (
        plan.converter != address(0)
        // check if we are able to supply required collateral
        && plan.maxAmountToSupply > p_.amountIn
      ) {
        // combine all costs and incomes and calculate result APR. Rewards are taken with the given weight.
        // Positive value means cost, negative - income
        // APR = (cost - income) / collateralAmount, decimals 18, all amounts are given in terms of borrow asset.
        int planApr18 = (
          int(plan.borrowCost36)
          - int(plan.supplyIncomeInBorrowAsset36)
          - int(plan.rewardsAmountInBorrowAsset36 * rewardsFactor / REWARDS_FACTOR_DENOMINATOR_18)
        )
        * int(1e18)
        / int(plan.amountCollateralInBorrowAsset36);

        if (
          // take only the pool with enough liquidity
          plan.maxAmountToBorrow >= plan.amountToBorrow
        ) {
          converters[countFoundItems] = plan.converter;
          amountsToBorrowOut[countFoundItems] = plan.amountToBorrow;
          collateralAmountsOut[countFoundItems] = plan.collateralAmount;
          aprs18[countFoundItems] = planApr18;
          ++countFoundItems;
        }
      }
    }

    return (converters, collateralAmountsOut, amountsToBorrowOut, aprs18, countFoundItems);
  }
  //endregion Find best pool for borrowing

  //-----------------------------------------------------
  //region Minimal proxy creation
  //-----------------------------------------------------

  /// @notice Register a pool adapter for (pool, user, collateral) if the adapter wasn't created before
  /// @param user_ Address of the caller contract who requires access to the pool adapter
  /// @return Address of registered pool adapter
  function registerPoolAdapter(
    address converter_,
    address user_,
    address collateralAsset_,
    address borrowAsset_
  ) external override returns (address) {
    _onlyTetuConverter();

    uint poolAdapterKey = getPoolAdapterKey(converter_, collateralAsset_, borrowAsset_);
    (bool found, address dest) = _poolAdapters[user_].tryGet(poolAdapterKey);
    if (! found) {
      // pool adapter is not yet registered
      // create a new instance of the pool adapter using minimal proxy pattern, initialize newly created contract
      dest = converter_.clone();
      IPlatformAdapter(getPlatformAdapter(converter_)).initializePoolAdapter(
        converter_,
        dest,
        user_,
        collateralAsset_,
        borrowAsset_
      );

      // register newly created pool adapter in the list of the pool adapters
      _poolAdapters[user_].set(poolAdapterKey, dest);
      uint index = listPoolAdapters.length;
      poolAdaptersRegistered[dest] = index + 1;
      listPoolAdapters.push(dest);

      emit OnRegisterPoolAdapter(dest, converter_, user_, collateralAsset_, borrowAsset_);
    }

    return dest;
  }

  /// @notice Notify borrow manager that the pool adapter with the given params is "dirty".
  ///         The pool adapter should be excluded from the list of ready-to-borrow pool adapters.
  /// @dev "Dirty" means that a liquidation happens inside. The borrow position should be closed during health checking.
  function markPoolAdapterAsDirty(
    address converter_,
    address user_,
    address collateral_,
    address borrowToken_
  ) external override {
    require(
      msg.sender == controller.tetuConverter() || msg.sender == controller.debtMonitor(),
      AppErrors.ACCESS_DENIED
    );
    uint key = getPoolAdapterKey(converter_, collateral_, borrowToken_);

    (bool found, address poolAdapter) = _poolAdapters[user_].tryGet(key);
    require(found, AppErrors.POOL_ADAPTER_NOT_FOUND);

    // Dirty pool adapter is removed from _poolAdapters, so it will never be used for new borrows
    _poolAdapters[user_].remove(key);

    emit OnMarkPoolAdapterAsDirty(poolAdapter);
  }
  //endregion Minimal proxy creation

  //-----------------------------------------------------
  //region Getters - pool adapters
  //-----------------------------------------------------

  /// @dev Returns true for NORMAL pool adapters and for active DIRTY pool adapters (=== borrow position is opened).
  function isPoolAdapter(address poolAdapter_) external view override returns (bool) {
    return poolAdaptersRegistered[poolAdapter_] != 0;
  }

  /// @notice Get pool adapter or 0 if the pool adapter is not registered
  function getPoolAdapter(
    address converter_,
    address user_,
    address collateral_,
    address borrowToken_
  ) external view override returns (address) {
    (bool found, address dest) = _poolAdapters[user_].tryGet(getPoolAdapterKey(converter_, collateral_, borrowToken_));
    return found ? dest : address(0);
  }
  //endregion Getters - pool adapters

  //-----------------------------------------------------
  //region Getters - platform adapters
  //-----------------------------------------------------

  /// @notice Get platformAdapter to which the converter belongs
  function getPlatformAdapter(address converter_) public view override returns (address) {
    address platformAdapter = converterToPlatformAdapter[converter_];
    require(platformAdapter != address(0), AppErrors.PLATFORM_ADAPTER_NOT_FOUND);
    return platformAdapter;
  }
  //endregion Getters - platform adapters

  //-----------------------------------------------------
  //region Getters - health factor
  //-----------------------------------------------------

  /// @notice Return target health factor with decimals 2 for the asset
  ///         If there is no custom value for asset, target health factor from the controller should be used
  function getTargetHealthFactor2(address asset_) public view override returns (uint16) {
    uint16 dest = targetHealthFactorsForAssets[asset_];
    return dest == 0
      ? controller.targetHealthFactor2()
      : dest;
  }
  //endregion Getters - health factor

  //-----------------------------------------------------
  //region keccak256 keys
  //-----------------------------------------------------

  function getPoolAdapterKey(address converter_,
    address collateral_,
    address borrowToken_
  ) public pure returns (uint){
    return uint(keccak256(abi.encodePacked(converter_, collateral_, borrowToken_)));
  }

  function getAssetPairKey(address assetLeft_, address assetRight_) public pure returns (uint) {
    return assetLeft_ < assetRight_
      ? uint(keccak256(abi.encodePacked(assetLeft_, assetRight_)))
      : uint(keccak256(abi.encodePacked(assetRight_, assetLeft_)));
  }
  //endregion keccak256 keys

  //-----------------------------------------------------
  //region Access to arrays
  //-----------------------------------------------------

  function platformAdaptersLength() public view returns (uint) {
    return _platformAdapters.length();
  }

  function platformAdaptersAt(uint index) public view returns (address) {
    return _platformAdapters.at(index);
  }

  function pairsListLength(address token1, address token2) public view returns (uint) {
    return _pairsList[getAssetPairKey(token1, token2)].length();
  }

  function pairsListAt(address token1, address token2, uint index) public view returns (address) {
    return _pairsList[getAssetPairKey(token1, token2)].at(index);
  }

  function platformAdapterPairsLength(address platformAdapter_) public view returns (uint) {
    return _platformAdapterPairs[platformAdapter_].length();
  }

  function platformAdapterPairsAt(address platformAdapter_, uint index) public view returns (AssetPair memory) {
    return _assetPairs[_platformAdapterPairs[platformAdapter_].at(index)];
  }

  function listPoolAdaptersLength() public view returns (uint) {
    return listPoolAdapters.length;
  }
  //endregion Access to arrays
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICErc20 {
  function _acceptAdmin (  ) external returns ( uint );
  function _addReserves ( uint addAmount ) external returns ( uint );
  function _reduceReserves ( uint reduceAmount ) external returns ( uint );
  function _setComptroller ( address newComptroller ) external returns ( uint );
  function _setInterestRateModel ( address newInterestRateModel ) external returns ( uint );
  function _setPendingAdmin ( address newPendingAdmin ) external returns ( uint );
  function _setReserveFactor ( uint newReserveFactorMantissa ) external returns ( uint );
  function accrualBlockNumber (  ) external view returns ( uint );
  function accrueInterest (  ) external returns ( uint );
  function admin (  ) external view returns ( address );
  function allowance ( address owner, address spender ) external view returns ( uint );
  function approve ( address spender, uint amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint );
  function balanceOfUnderlying ( address owner ) external returns ( uint );
  function borrow ( uint borrowAmount ) external returns ( uint );
  function borrowBalanceCurrent ( address account ) external returns ( uint );
  function borrowBalanceStored ( address account ) external view returns ( uint );
  function borrowIndex (  ) external view returns ( uint );
  function borrowRatePerBlock (  ) external view returns ( uint );
  function comptroller (  ) external view returns ( address );
  function decimals (  ) external view returns ( uint8 );
  function exchangeRateCurrent (  ) external returns ( uint );
  function exchangeRateStored (  ) external view returns ( uint );
  function getAccountSnapshot ( address account ) external view returns ( uint, uint, uint, uint );
  function getCash (  ) external view returns ( uint );
  function interestRateModel (  ) external view returns ( address );
  function isCToken (  ) external view returns ( bool );
  function liquidateBorrow ( address borrower, uint repayAmount, address cTokenCollateral ) external returns ( uint );
  function mint ( uint mintAmount ) external returns ( uint );
  function name (  ) external view returns ( string memory);
  function pendingAdmin (  ) external view returns ( address );
  function redeem ( uint redeemTokens ) external returns ( uint );
  function redeemUnderlying ( uint redeemAmount ) external returns ( uint );
  function repayBorrow ( uint repayAmount ) external returns ( uint );
  function repayBorrowBehalf ( address borrower, uint repayAmount ) external returns ( uint );
  function reserveFactorMantissa (  ) external view returns ( uint );
  function seize ( address liquidator, address borrower, uint seizeTokens ) external returns ( uint );
  function supplyRatePerBlock (  ) external view returns ( uint );
  function sweepToken ( address token ) external;
  function symbol (  ) external view returns ( string memory);
  function totalBorrows (  ) external view returns ( uint );
  function totalBorrowsCurrent (  ) external returns ( uint );
  function totalReserves (  ) external view returns ( uint );
  function totalSupply (  ) external view returns ( uint );
  function transfer ( address dst, uint amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint amount ) external returns ( bool );
  function underlying (  ) external view returns ( address );

  function adminFeeMantissa() external view returns (uint256);
  function fuseFeeMantissa() external view returns (uint256);
  function totalAdminFees() external view returns (uint256);
  function totalFuseFees() external view returns (uint256);

}

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
  /// @return swappedAmountOut A part of {collateralAmountOut} that were received by direct swap
  function quoteRepay(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_
  ) external returns (
    uint collateralAmountOut,
    uint swappedAmountOut
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
  /// @return repaidAmountOut Amount of borrow asset paid to the lending platform
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (
    uint collateralAmountOut,
    uint repaidAmountOut
  );

  /// @notice Get active borrows of the user with given collateral/borrowToken
  /// @dev Simple access to IDebtMonitor.getPositions
  /// @return poolAdaptersOut The instances of IPoolAdapter
  function getPositions(address user_, address collateralToken_, address borrowedToken_) external view returns (
    address[] memory poolAdaptersOut
  );

  /// @notice Save token from TC-balance to {receiver}
  /// @dev Normally TetuConverter doesn't have any tokens on balance, they can appear there accidentally only
  function salvage(address receiver, address token, uint amount) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity 0.8.17;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
  function clone(address implementation) internal returns (address instance) {
    /// @solidity memory-safe-assembly
    assembly {
    // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
    // of the `implementation` address with the bytecode before the address.
      mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
    // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
      mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
      instance := create(0, 0x09, 0x37)
    }
    require(instance != address(0), "ERC1167: create failed");
  }

  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
  function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
    /// @solidity memory-safe-assembly
    assembly {
    // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
    // of the `implementation` address with the bytecode before the address.
      mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
    // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
      mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
      instance := create2(0, 0x09, 0x37, salt)
    }
    require(instance != address(0), "ERC1167: create2 failed");
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
  function predictDeterministicAddress(
    address implementation,
    bytes32 salt,
    address deployer
  ) internal pure returns (address predicted) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(add(ptr, 0x38), deployer)
      mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
      mstore(add(ptr, 0x14), implementation)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
      mstore(add(ptr, 0x58), salt)
      mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
      predicted := keccak256(add(ptr, 0x43), 0x55)
    }
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
  function predictDeterministicAddress(address implementation, bytes32 salt)
  internal
  view
  returns (address predicted)
  {
    return predictDeterministicAddress(implementation, salt, address(this));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity 0.8.17;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct Bytes32ToBytes32Map {
    // Storage of keys
    EnumerableSet.Bytes32Set _keys;
    mapping(bytes32 => bytes32) _values;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    bytes32 value
  ) internal returns (bool) {
    map._values[key] = value;
    return map._keys.add(key);
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
    delete map._values[key];
    return map._keys.remove(key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
    return map._keys.contains(key);
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
     */
  function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
    return map._keys.length();
  }

  /**
   * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
    bytes32 key = map._keys.at(index);
    return (key, map._values[key]);
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
    bytes32 value = map._values[key];
    if (value == bytes32(0)) {
      return (contains(map, key), bytes32(0));
    } else {
      return (true, value);
    }
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
    return value;
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), errorMessage);
    return value;
  }

  // UintToUintMap

  struct UintToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    UintToUintMap storage map,
    uint256 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(UintToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key)));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    UintToUintMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key), errorMessage));
  }

  // UintToAddressMap

  struct UintToAddressMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(UintToAddressMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
  }

  // AddressToUintMap

  struct AddressToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    AddressToUintMap storage map,
    address key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(AddressToUintMap storage map, address key) internal returns (bool) {
    return remove(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
    return contains(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(AddressToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (address(uint160(uint256(key))), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    AddressToUintMap storage map,
    address key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
  }

  // Bytes32ToUintMap

  struct Bytes32ToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    Bytes32ToUintMap storage map,
    bytes32 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, key, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
    return remove(map._inner, key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
    return contains(map._inner, key);
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (key, uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, key);
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
    return uint256(get(map._inner, key));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    Bytes32ToUintMap storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, key, errorMessage));
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