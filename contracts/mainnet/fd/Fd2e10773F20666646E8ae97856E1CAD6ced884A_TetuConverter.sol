// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";
import "../libs/AppErrors.sol";
import "../libs/AppUtils.sol";
import "../libs/EntryKinds.sol";
import "../libs/SwapLib.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/Math.sol";
import "../interfaces/IBorrowManager.sol";
import "../interfaces/ISwapManager.sol";
import "../interfaces/ITetuConverter.sol";
import "../interfaces/IPlatformAdapter.sol";
import "../interfaces/IPoolAdapter.sol";
import "../interfaces/IConverterController.sol";
import "../interfaces/IDebtMonitor.sol";
import "../interfaces/IConverter.sol";
import "../interfaces/ISwapConverter.sol";
import "../interfaces/IKeeperCallback.sol";
import "../interfaces/ITetuConverterCallback.sol";
import "../interfaces/IRequireAmountBySwapManagerCallback.sol";
import "../interfaces/IPriceOracle.sol";
import "../integrations/tetu/ITetuLiquidator.sol";
import "../proxy/ControllableV3.sol";

/// @notice Main application contract
contract TetuConverter is ControllableV3, ITetuConverter, IKeeperCallback, IRequireAmountBySwapManagerCallback, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using AppUtils for uint;

  //region ----------------------------------------------------- Constants
  string public constant TETU_CONVERTER_VERSION = "1.0.0";
  /// @notice After additional borrow result health factor should be near to target value, the difference is limited.
  uint constant public ADDITIONAL_BORROW_DELTA_DENOMINATOR = 1;
  uint constant internal DEBT_GAP_DENOMINATOR = 100_000;
  /// @dev Absolute value of debt-gap-addon for any token
  /// @notice A value of the debt gap, calculate using debt-gap percent, cannot be less than the following
  uint internal constant MIN_DEBT_GAP_ADDON = 10;
  //endregion ----------------------------------------------------- Constants

  //region ----------------------------------------------------- Data types
  struct RepayLocal {
    address[] poolAdapters;
    uint len;
    uint debtGap;
    IPoolAdapter pa;
    uint totalDebtForPoolAdapter;
    bool debtGapRequired;
    IConverterController controller;
  }

  /// @notice Local vars for {findConversionStrategy}
  struct FindConversionStrategyLocal {
    address[] borrowConverters;
    uint[] borrowSourceAmounts;
    uint[] borrowTargetAmounts;
    int[] borrowAprs18;
    address swapConverter;
    uint swapSourceAmount;
    uint swapTargetAmount;
    int swapApr18;
  }
  //endregion ----------------------------------------------------- Data types

  //region ----------------------------------------------------- Events
  event OnSwap(address signer, address converter, address sourceAsset, uint sourceAmount, address targetAsset, address receiver, uint targetAmountOut);
  event OnBorrow(address poolAdapter, uint collateralAmount, uint amountToBorrow, address receiver, uint borrowedAmountOut);
  event OnRepayBorrow(address poolAdapter, uint amountToRepay, address receiver, bool closePosition);

  /// @notice A part of target amount cannot be repaid or swapped
  ///         so it was just returned back to receiver as is
  event OnRepayReturn(address asset, address receiver, uint amount);
  event OnRequireRepayCloseLiquidatedPosition(address poolAdapter, uint statusAmountToPay);
  event OnRequireRepayRebalancing(address poolAdapter, uint amount, bool isCollateral, uint statusAmountToPay, uint healthFactorAfterRepay18);
  event OnClaimRewards(address poolAdapter, address rewardsToken, uint amount, address receiver);
  event OnSafeLiquidate(address sourceToken, uint sourceAmount, address targetToken, address receiver, uint outputAmount);
  event OnRepayTheBorrow(address poolAdapter, uint collateralOut, uint repaidAmountOut);
  event OnSalvage(address receiver, address token, uint amount);
  //endregion ----------------------------------------------------- Events

  //region ----------------------------------------------------- Initialization
  function init(address controller_) external initializer {
    __Controllable_init(controller_);
  }
  //endregion ----------------------------------------------------- Initialization

  //region ----------------------------------------------------- Access
  function _getControllerWhitelistedOnly() internal view returns (IConverterController controllerOut) {
    controllerOut = IConverterController(controller());
    require(controllerOut.isWhitelisted(msg.sender), AppErrors.OUT_OF_WHITE_LIST);
  }
  function _getControllerGovernanceOnly() internal view returns (IConverterController controllerOut) {
    controllerOut = IConverterController(controller());
    require(msg.sender == controllerOut.governance(), AppErrors.GOVERNANCE_ONLY);
  }
  //endregion ----------------------------------------------------- Access

  //region ----------------------------------------------------- Find best strategy for conversion

  /// @inheritdoc ITetuConverter
  function findConversionStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external override returns (
    address converter,
    uint collateralAmountOut,
    uint amountToBorrowOut,
    int apr18
  ) {
    require(amountIn_ != 0, AppErrors.ZERO_AMOUNT);
    require(periodInBlocks_ != 0, AppErrors.INCORRECT_VALUE);

    IConverterController _controller = _getControllerWhitelistedOnly();

    FindConversionStrategyLocal memory p;
    if (!_controller.paused()) {
      (p.borrowConverters,
        p.borrowSourceAmounts,
        p.borrowTargetAmounts,
        p.borrowAprs18
      ) = IBorrowManager(_controller.borrowManager()).findConverter(entryData_, sourceToken_, targetToken_, amountIn_, periodInBlocks_);

      (p.swapConverter,
        p.swapSourceAmount,
        p.swapTargetAmount,
        p.swapApr18) = _findSwapStrategy(_controller, entryData_, sourceToken_, amountIn_, targetToken_);
    }

    if (p.borrowConverters.length == 0) {
      return (p.swapConverter == address(0))
        ? (address(0), uint(0), uint(0), int(0))
        : (p.swapConverter, p.swapSourceAmount, p.swapTargetAmount, p.swapApr18);
    } else {
      if (p.swapConverter == address(0)) {
        return (p.borrowConverters[0], p.borrowSourceAmounts[0], p.borrowTargetAmounts[0], p.borrowAprs18[0]);
      } else {
        return (p.swapApr18 > p.borrowAprs18[0])
          ? (p.borrowConverters[0], p.borrowSourceAmounts[0], p.borrowTargetAmounts[0], p.borrowAprs18[0])
          : (p.swapConverter, p.swapSourceAmount, p.swapTargetAmount, p.swapApr18);
      }
    }
  }

  /// @inheritdoc ITetuConverter
  function findBorrowStrategies(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external view override returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountToBorrowsOut,
    int[] memory aprs18
  ) {
    require(amountIn_ != 0, AppErrors.ZERO_AMOUNT);
    require(periodInBlocks_ != 0, AppErrors.INCORRECT_VALUE);

    IConverterController _controller = IConverterController(controller());
    return _controller.paused()
      ? (converters, collateralAmountsOut, amountToBorrowsOut, aprs18) // no conversion is available
      : IBorrowManager(_controller.borrowManager()).findConverter(entryData_, sourceToken_, targetToken_, amountIn_, periodInBlocks_);
  }

  /// @inheritdoc ITetuConverter
  function findSwapStrategy(bytes memory entryData_, address sourceToken_, uint amountIn_, address targetToken_) external override returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  ) {
    require(amountIn_ != 0, AppErrors.ZERO_AMOUNT);

    IConverterController _controller = _getControllerWhitelistedOnly();
    return _controller.paused()
      ? (converter, sourceAmountOut, targetAmountOut, apr18) // no conversion is available
      : _findSwapStrategy(_controller, entryData_, sourceToken_, amountIn_, targetToken_);
  }

  /// @notice Calculate amount to swap according to the given {entryData_} and estimate result amount of {targetToken_}
  function _findSwapStrategy(
    IConverterController controller_,
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_
  ) internal returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  ) {
    uint entryKind = EntryKinds.getEntryKind(entryData_);
    if (entryKind == EntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
      // Split {sourceAmount_} on two parts: C1 and C2. Swap C2 => {targetAmountOut}
      // Result cost of {targetAmountOut} and C1 should be equal or almost equal
      // For simplicity we assume here that swap doesn't have any lost:
      // if S1 is swapped to S2 then costs of S1 and S2 are equal
      sourceAmountOut = EntryKinds.getCollateralAmountToConvert(entryData_, amountIn_, 1, 1);
    } else {
      sourceAmountOut = amountIn_;
    }

    ISwapManager swapManager = ISwapManager(controller_.swapManager());
    (converter, targetAmountOut) = swapManager.getConverter(msg.sender, sourceToken_, sourceAmountOut, targetToken_);
    if (converter != address(0)) {
      apr18 = swapManager.getApr18(sourceToken_, sourceAmountOut, targetToken_, targetAmountOut);
    }

    return (converter, sourceAmountOut, targetAmountOut, apr18);
  }
  //endregion ----------------------------------------------------- Find best strategy for conversion

  //region ----------------------------------------------------- Make conversion, open position

  /// @inheritdoc ITetuConverter
  function borrow(
    address converter_,
    address collateralAsset_,
    uint collateralAmount_,
    address borrowAsset_,
    uint amountToBorrow_,
    address receiver_
  ) external override nonReentrant returns (
    uint borrowedAmountOut
  ) {
    IConverterController _controller = _getControllerWhitelistedOnly();
    require(receiver_ != address(0) && converter_ != address(0), AppErrors.ZERO_ADDRESS);
    require(collateralAmount_ != 0 && amountToBorrow_ != 0, AppErrors.ZERO_AMOUNT);

    IERC20(collateralAsset_).safeTransferFrom(msg.sender, address(this), collateralAmount_);
    IBorrowManager borrowManager = IBorrowManager(_controller.borrowManager());

    AppDataTypes.ConversionKind conversionKind = IConverter(converter_).getConversionKind();
    if (conversionKind == AppDataTypes.ConversionKind.BORROW_2) {
      // get exist or register new pool adapter
      address poolAdapter = borrowManager.getPoolAdapter(converter_, msg.sender, collateralAsset_, borrowAsset_);

      if (poolAdapter != address(0)) {
        // the pool adapter can have three possible states:
        // - healthy (normal), it's ok to make new borrow using the pool adapter
        // - unhealthy, health factor is less 1. It means that liquidation happens and the pool adapter is not usable.
        // - unhealthy, health factor is greater 1 but it's less min-allowed-value. It means, that rebalance wasn't made
        (,, uint healthFactor18,,,) = IPoolAdapter(poolAdapter).getStatus();
        if (healthFactor18 < 1e18) {
          // the pool adapter is unhealthy, we should mark it as dirty and create new pool adapter for the borrow
          borrowManager.markPoolAdapterAsDirty(converter_, msg.sender, collateralAsset_, borrowAsset_);
          poolAdapter = address(0);
        } else if (healthFactor18 <= (uint(_controller.minHealthFactor2()) * 10 ** (18 - 2))) {
          // this is not normal situation
          // keeper doesn't work? it's too risky to make new borrow
          revert(AppErrors.REBALANCING_IS_REQUIRED);
        }
      }

      // create new pool adapter if we don't have ready-to-borrow one
      if (poolAdapter == address(0)) {
        poolAdapter = borrowManager.registerPoolAdapter(converter_, msg.sender, collateralAsset_, borrowAsset_);

        // TetuConverter doesn't keep assets on its balance, so it's safe to use infinity approve
        IERC20(collateralAsset_).safeApprove(poolAdapter, 2 ** 255); // 2*255 is more gas-efficient than type(uint).max
        IERC20(borrowAsset_).safeApprove(poolAdapter, 2 ** 255); // 2*255 is more gas-efficient than type(uint).max
      }

      // borrow target-amount and transfer borrowed amount to the receiver, infinity approve is assumed
      borrowedAmountOut = IPoolAdapter(poolAdapter).borrow(collateralAmount_, amountToBorrow_, receiver_);
      emit OnBorrow(poolAdapter, collateralAmount_, amountToBorrow_, receiver_, borrowedAmountOut);
    } else if (conversionKind == AppDataTypes.ConversionKind.SWAP_1) {
      require(converter_ == _controller.swapManager(), AppErrors.INCORRECT_CONVERTER_TO_SWAP);
      borrowedAmountOut = _makeSwap(converter_, collateralAsset_, collateralAmount_, borrowAsset_, receiver_);
    } else {
      revert(AppErrors.UNSUPPORTED_CONVERSION_KIND);
    }
  }

  /// @notice Transfer {sourceAmount_} to swap-converter, make swap, return result target amount
  function _makeSwap(address swapConverter, address sourceAsset_, uint amountIn, address targetAsset_, address receiver_) internal returns (
    uint amountOut
  ) {
    IERC20(sourceAsset_).safeTransfer(swapConverter, amountIn);
    amountOut = ISwapConverter(swapConverter).swap(sourceAsset_, amountIn, targetAsset_, receiver_);
    emit OnSwap(msg.sender, swapConverter, sourceAsset_, amountIn, targetAsset_, receiver_, amountOut);
  }
  //endregion ----------------------------------------------------- Make conversion, open position

  //region ----------------------------------------------------- Make repay, close position

  /// @inheritdoc ITetuConverter
  function repay(address collateralAsset_, address borrowAsset_, uint amountToRepay_, address receiver_) external override nonReentrant returns (
    uint collateralAmountOut,
    uint returnedBorrowAmountOut,
    uint swappedLeftoverCollateralOut,
    uint swappedLeftoverBorrowOut
  ) {
    RepayLocal memory v;

    v.controller = _getControllerWhitelistedOnly();
    require(receiver_ != address(0), AppErrors.ZERO_ADDRESS);

    // ensure that we have received required amount
    require(amountToRepay_ <= IERC20(borrowAsset_).balanceOf(address(this)), AppErrors.WRONG_AMOUNT_RECEIVED);

    // we will decrease amountToRepay_ in the code (to avoid creation additional variable)
    // it shows how much is left to convert from borrow asset to collateral asset

    // we need to repay exact amount using any pool adapters; simplest strategy: use first available pool adapter
    v.poolAdapters = IDebtMonitor(v.controller.debtMonitor()).getPositions(msg.sender, collateralAsset_, borrowAsset_);
    v.len = v.poolAdapters.length;
    v.debtGap = v.controller.debtGap();

    // at first repay debts for any opened positions, repay don't make any rebalancing here
    for (uint i; i < v.len; i = i.uncheckedInc()) {
      if (amountToRepay_ == 0) break;
      v.pa = IPoolAdapter(v.poolAdapters[i]);
      v.pa.updateStatus();

      (, v.totalDebtForPoolAdapter,,,, v.debtGapRequired) = v.pa.getStatus();

      if (v.debtGapRequired) {
        // we assume here, that amountToRepay_ includes all required dept-gaps
        v.totalDebtForPoolAdapter = getAmountWithDebtGap(v.totalDebtForPoolAdapter, v.debtGap);
      }
      uint amountToPayToPoolAdapter = amountToRepay_ >= v.totalDebtForPoolAdapter
        ? v.totalDebtForPoolAdapter
        : amountToRepay_;

      // make repayment, assume infinity approve: IERC20(borrowAsset_).safeApprove(address(pa), amountToPayToPoolAdapter);
      bool closePosition = amountToPayToPoolAdapter == v.totalDebtForPoolAdapter;
      collateralAmountOut += v.pa.repay(amountToPayToPoolAdapter, receiver_, closePosition);
      amountToRepay_ -= amountToPayToPoolAdapter;

      emit OnRepayBorrow(address(v.pa), amountToPayToPoolAdapter, receiver_, closePosition);
    }

    // if all debts were paid but we still have some amount of borrow asset
    // let's swap it to collateral asset and send to collateral-receiver
    if (amountToRepay_ > 0) {
      // getConverter requires the source amount be approved to TetuConverter, but a contract doesn't need to approve itself
      (address converter,) = ISwapManager(v.controller.swapManager()).getConverter(address(this), borrowAsset_, amountToRepay_, collateralAsset_);

      if (converter == address(0)) {
        // there is no swap-strategy to convert remain {amountToPay} to {collateralAsset_}
        // let's return this amount back to the {receiver_}
        returnedBorrowAmountOut = amountToRepay_;
        IERC20(borrowAsset_).safeTransfer(receiver_, amountToRepay_);
        emit OnRepayReturn(borrowAsset_, receiver_, amountToRepay_);
      } else {
        // conversion strategy is found, let's convert all remaining {amountToPay} to {collateralAsset}
        swappedLeftoverCollateralOut = _makeSwap(converter, borrowAsset_, amountToRepay_, collateralAsset_, receiver_);
        swappedLeftoverBorrowOut = amountToRepay_;

        collateralAmountOut += swappedLeftoverCollateralOut;
      }
    }

    return (collateralAmountOut, returnedBorrowAmountOut, swappedLeftoverCollateralOut, swappedLeftoverBorrowOut);
  }

  /// @inheritdoc ITetuConverter
  function quoteRepay(address user_, address collateralAsset_, address borrowAsset_, uint amountToRepay_) external override returns (
    uint collateralAmountOut,
    uint swappedAmountOut
  ) {
    IConverterController _controller = _getControllerWhitelistedOnly();

    address[] memory poolAdapters = IDebtMonitor(_controller.debtMonitor()).getPositions(user_, collateralAsset_, borrowAsset_);
    uint len = poolAdapters.length;
    for (uint i; i < len; i = i.uncheckedInc()) {
      if (amountToRepay_ == 0) break;

      IPoolAdapter pa = IPoolAdapter(poolAdapters[i]);
      pa.updateStatus();

      // debt-gaps are not taken into account here because getCollateralAmountToReturn doesn't take it into account
      (, uint totalDebtForPoolAdapter,,,,) = pa.getStatus();

      bool closePosition = totalDebtForPoolAdapter <= amountToRepay_;
      uint currentAmountToRepay = closePosition ? totalDebtForPoolAdapter : amountToRepay_;
      uint collateralAmountToReceive = pa.getCollateralAmountToReturn(currentAmountToRepay, closePosition);

      amountToRepay_ -= currentAmountToRepay;
      collateralAmountOut += collateralAmountToReceive;
    }

    if (amountToRepay_ > 0) {
      IPriceOracle priceOracle = IPriceOracle(_controller.priceOracle());
      uint priceBorrowAsset = priceOracle.getAssetPrice(borrowAsset_);
      uint priceCollateralAsset = priceOracle.getAssetPrice(collateralAsset_);
      require(priceCollateralAsset != 0 && priceBorrowAsset != 0, AppErrors.ZERO_PRICE);

      swappedAmountOut = amountToRepay_
        * 10 ** IERC20Metadata(collateralAsset_).decimals()
        * priceBorrowAsset
        / priceCollateralAsset
        / 10 ** IERC20Metadata(borrowAsset_).decimals();
    }

    return (collateralAmountOut + swappedAmountOut, swappedAmountOut);
  }
  //endregion ----------------------------------------------------- Make repay, close position

  //region ----------------------------------------------------- IKeeperCallback

  /// @inheritdoc IKeeperCallback
  function requireRepay(
    uint requiredBorrowedAmount_,
    uint requiredCollateralAmount_,
    address poolAdapter_
  ) external nonReentrant override {
    require(IConverterController(controller()).keeper() == msg.sender, AppErrors.KEEPER_ONLY);
    require(requiredBorrowedAmount_ != 0, AppErrors.INCORRECT_VALUE);

    IPoolAdapter pa = IPoolAdapter(poolAdapter_);
    (,address user, address collateralAsset,) = pa.getConfig();
    pa.updateStatus();
    (, uint amountToPay,,,,) = pa.getStatus();

    if (requiredCollateralAmount_ == 0) {
      // Full liquidation happens, we have lost all collateral amount
      // We need to close the position as is and drop away the pool adapter without paying any debt
      IDebtMonitor(IConverterController(controller()).debtMonitor()).closeLiquidatedPosition(address(pa));
      emit OnRequireRepayCloseLiquidatedPosition(address(pa), amountToPay);
    } else {
      // rebalancing
      // we assume here, that requiredBorrowedAmount_ should be less than amountToPay even if it includes the debt-gap
      require(amountToPay != 0 && requiredBorrowedAmount_ < amountToPay, AppErrors.REPAY_TO_REBALANCE_NOT_ALLOWED);

      // for borrowers it's much easier to return collateral asset than borrow asset
      // so ask the borrower to send us collateral asset
      uint balanceBefore = IERC20(collateralAsset).balanceOf(address(this));
      ITetuConverterCallback(user).requirePayAmountBack(collateralAsset, requiredCollateralAmount_);
      uint balanceAfter = IERC20(collateralAsset).balanceOf(address(this));

      // ensure that we have received any amount .. and use it for repayment
      // probably we've received less then expected - it's ok, just let's use as much as possible
      // DebtMonitor will ask to make rebalancing once more if necessary
      require(
        balanceAfter > balanceBefore // smth is wrong
        && balanceAfter - balanceBefore <= requiredCollateralAmount_, // we can receive less amount (partial rebalancing)
        AppErrors.WRONG_AMOUNT_RECEIVED
      );
      uint amount = balanceAfter - balanceBefore;
      // replaced by infinity approve: IERC20(collateralAsset).safeApprove(poolAdapter_, requiredAmountCollateralAsset_);

      uint resultHealthFactor18 = pa.repayToRebalance(amount, true);
      emit OnRequireRepayRebalancing(address(pa), amount, true, amountToPay, resultHealthFactor18);
    }
  }
  //endregion ----------------------------------------------------- IKeeperCallback

  //region ----------------------------------------------------- Close borrow forcibly by governance

  /// @inheritdoc ITetuConverter
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (uint collateralAmountOut, uint repaidAmountOut) {
    IConverterController _controller = _getControllerGovernanceOnly();

    // update internal debts and get actual amount to repay
    IPoolAdapter pa = IPoolAdapter(poolAdapter_);
    (,address user, address collateralAsset, address borrowAsset) = pa.getConfig();
    pa.updateStatus();

    // add debt gap if necessary
    bool debtGapRequired;
    (collateralAmountOut, repaidAmountOut,,,, debtGapRequired) = pa.getStatus();
    if (debtGapRequired) {
      repaidAmountOut = getAmountWithDebtGap(repaidAmountOut, _controller.debtGap());
    }
    require(collateralAmountOut != 0 && repaidAmountOut != 0, AppErrors.REPAY_FAILED);

    // ask the user for the amount-to-repay; use exist balance for safety, normally it should be 0
    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));
    ITetuConverterCallback(user).requirePayAmountBack(borrowAsset, repaidAmountOut - balanceBefore);
    uint balanceAfter = IERC20(borrowAsset).balanceOf(address(this));

    // ensure that we have received required amount fully or partially
    if (closePosition) {
      require(balanceAfter >= balanceBefore + repaidAmountOut, AppErrors.WRONG_AMOUNT_RECEIVED);
    } else {
      require(balanceAfter > balanceBefore, AppErrors.ZERO_BALANCE);
      repaidAmountOut = balanceAfter - balanceBefore;
    }

    // make full repay and close the position
    balanceBefore = IERC20(borrowAsset).balanceOf(user);
    collateralAmountOut = pa.repay(repaidAmountOut, user, closePosition);
    emit OnRepayTheBorrow(poolAdapter_, collateralAmountOut, repaidAmountOut);
    balanceAfter = IERC20(borrowAsset).balanceOf(user);

    address[] memory assets = new address[](2);
    assets[0] = borrowAsset;
    assets[1] = collateralAsset;

    uint[] memory amounts = new uint[](2);
    // repay is able to return small amount of borrow-asset back to the user, we should pass it to onTransferAmounts
    amounts[0] = balanceAfter > balanceBefore ? balanceAfter - balanceBefore : 0;
    if (amounts[0] > 0) { // exclude returned part of the debt gap from repaidAmountOut
      repaidAmountOut = repaidAmountOut > amounts[0]
        ? repaidAmountOut - amounts[0]
        : 0;
    }
    amounts[1] = collateralAmountOut;
    ITetuConverterCallback(user).onTransferAmounts(assets, amounts);

    return (collateralAmountOut, repaidAmountOut);
  }
  //endregion ----------------------------------------------------- Close borrow forcibly by governance

  //region ----------------------------------------------------- Get debt/repay info

  /// @inheritdoc ITetuConverter
  function getDebtAmountCurrent(address user_, address collateralAsset_, address borrowAsset_, bool useDebtGap_) external override nonReentrant returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  ) {
    IConverterController _controller = _getControllerWhitelistedOnly();

    address[] memory poolAdapters = IDebtMonitor(_controller.debtMonitor()).getPositions(user_, collateralAsset_, borrowAsset_);
    uint len = poolAdapters.length;

    uint debtGap = useDebtGap_ ? _controller.debtGap() : 0;

    for (uint i; i < len; i = i.uncheckedInc()) {
      IPoolAdapter pa = IPoolAdapter(poolAdapters[i]);
      pa.updateStatus();
      (totalDebtAmountOut, totalCollateralAmountOut) = _addDebtAmounts(pa, totalDebtAmountOut, totalCollateralAmountOut, debtGap);
    }

    return (totalDebtAmountOut, totalCollateralAmountOut);
  }

  /// @inheritdoc ITetuConverter
  function getDebtAmountStored(address user_, address collateralAsset_, address borrowAsset_, bool useDebtGap_) external view override returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  ) {
    IConverterController _controller = IConverterController(controller());

    address[] memory poolAdapters = IDebtMonitor(_controller.debtMonitor()).getPositions(user_, collateralAsset_, borrowAsset_);
    uint len = poolAdapters.length;

    uint debtGap = useDebtGap_ ? _controller.debtGap() : 0;

    for (uint i; i < len; i = i.uncheckedInc()) {
      IPoolAdapter pa = IPoolAdapter(poolAdapters[i]);
      (totalDebtAmountOut, totalCollateralAmountOut) = _addDebtAmounts(pa, totalDebtAmountOut, totalCollateralAmountOut, debtGap);
    }

    return (totalDebtAmountOut, totalCollateralAmountOut);
  }

  /// @notice A function to reduce contract size (shared code from getDebtAmountCurrent and getDebtAmountStored)
  function _addDebtAmounts(IPoolAdapter pa, uint amountDebt_, uint collateralAmount_, uint debtGap) internal view returns (
    uint debtAmountOut,
    uint collateralAmountOut
  ) {
    (uint collateralAmount, uint totalDebtForPoolAdapter,,,, bool debtGapRequired) = pa.getStatus();
    debtAmountOut = amountDebt_ + (
      (debtGap != 0 && debtGapRequired)
        ? getAmountWithDebtGap(totalDebtForPoolAdapter, debtGap)
        : totalDebtForPoolAdapter
    );
    collateralAmountOut = collateralAmount_ + collateralAmount;
  }


  /// @inheritdoc ITetuConverter
  function estimateRepay(address user_, address collateralAsset_, uint collateralAmountToRedeem_, address borrowAsset_) external view override returns (
    uint borrowAssetAmount,
    uint unobtainableCollateralAssetAmount
  ) {
    IConverterController _controller = IConverterController(controller());

    address[] memory poolAdapters = IDebtMonitor(_controller.debtMonitor()).getPositions(user_, collateralAsset_, borrowAsset_);
    uint len = poolAdapters.length;

    uint collateralAmountRemained = collateralAmountToRedeem_;
    for (uint i; i < len; i = i.uncheckedInc()) {
      if (collateralAmountRemained == 0) break;

      IPoolAdapter pa = IPoolAdapter(poolAdapters[i]);
      (uint collateralAmount, uint borrowedAmount,,,,bool debtGapRequired) = pa.getStatus();
      if (debtGapRequired) {
        borrowedAmount = getAmountWithDebtGap(borrowedAmount, _controller.debtGap());
      }

      if (collateralAmountRemained >= collateralAmount) {
        collateralAmountRemained -= collateralAmount;
        borrowAssetAmount += borrowedAmount;
      } else {
        borrowAssetAmount += borrowedAmount * collateralAmountRemained / collateralAmount;
        collateralAmountRemained = 0;
      }
    }

    return (borrowAssetAmount, collateralAmountRemained);
  }

  /// @inheritdoc ITetuConverter
  function getPositions(address user_, address collateralToken_, address borrowedToken_) external view returns (
    address[] memory poolAdaptersOut
  ) {
    return IDebtMonitor(IConverterController(controller()).debtMonitor()).getPositions(user_, collateralToken_, borrowedToken_);
  }
  //endregion ----------------------------------------------------- Get debt/repay info

  //region ----------------------------------------------------- Check and claim rewards

  /// @inheritdoc ITetuConverter
  function claimRewards(address receiver_) external override nonReentrant returns (
    address[] memory rewardTokensOut,
    uint[] memory amountsOut
  ) {
    // The sender is able to claim his own rewards only, so no need to check sender
    address[] memory poolAdapters = IDebtMonitor(IConverterController(controller()).debtMonitor()).getPositionsForUser(msg.sender);

    uint len = poolAdapters.length;
    address[] memory rewardTokens = new address[](len);
    uint[] memory amounts = new uint[](len);
    uint countPositions = 0;
    for (uint i; i < len; i = i.uncheckedInc()) {
      IPoolAdapter pa = IPoolAdapter(poolAdapters[i]);
      (rewardTokens[countPositions], amounts[countPositions]) = pa.claimRewards(receiver_);
      if (amounts[countPositions] != 0) {
        emit OnClaimRewards(address(pa), rewardTokens[countPositions], amounts[countPositions], receiver_);
        ++countPositions;
      }
    }

    if (countPositions != 0) {
      rewardTokensOut = AppUtils.removeLastItems(rewardTokens, countPositions);
      amountsOut = AppUtils.removeLastItems(amounts, countPositions);
    }

    return (rewardTokensOut, amountsOut);
  }

  /// @inheritdoc ITetuConverter
  function salvage(address receiver, address token, uint amount) external {
    _getControllerGovernanceOnly();

    IERC20(token).safeTransfer(receiver, amount);
    emit OnSalvage(receiver, token, amount);
  }

  //endregion ----------------------------------------------------- Check and claim rewards

  //region ----------------------------------------------------- Simulate swap

  /// @notice Transfer {sourceAmount_} approved by {approver_} to swap manager
  function onRequireAmountBySwapManager(address approver_, address sourceToken_, uint sourceAmount_) external override {
    address swapManager = IConverterController(controller()).swapManager();
    require(swapManager == msg.sender, AppErrors.ONLY_SWAP_MANAGER);

    if (approver_ == address(this)) {
      IERC20(sourceToken_).safeTransfer(swapManager, sourceAmount_);
    } else {
      IERC20(sourceToken_).safeTransferFrom(approver_, swapManager, sourceAmount_);
    }
  }
  //endregion ----------------------------------------------------- Simulate swap

  //region ----------------------------------------------------- Liquidate with checking

  /// @inheritdoc ITetuConverter
  function safeLiquidate(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    address receiver_,
    uint priceImpactToleranceSource_,
    uint priceImpactToleranceTarget_
  ) override external returns (
    uint amountOut
  ) {
    IConverterController _controller = _getControllerWhitelistedOnly();

    ITetuLiquidator tetuLiquidator = ITetuLiquidator(_controller.tetuLiquidator());
    uint targetTokenBalanceBefore = IERC20(assetOut_).balanceOf(address(this));

    IERC20(assetIn_).safeApprove(address(tetuLiquidator), amountIn_);
    tetuLiquidator.liquidate(assetIn_, assetOut_, amountIn_, priceImpactToleranceSource_);

    amountOut = IERC20(assetOut_).balanceOf(address(this)) - targetTokenBalanceBefore;
    IERC20(assetOut_).safeTransfer(receiver_, amountOut);

    require(  // The result amount shouldn't be too different from the value calculated directly using price oracle prices
      SwapLib.isConversionValid(IPriceOracle(_controller.priceOracle()), assetIn_, amountIn_, assetOut_, amountOut, priceImpactToleranceTarget_),
      AppErrors.TOO_HIGH_PRICE_IMPACT
    );
    emit OnSafeLiquidate(assetIn_, amountIn_, assetOut_, receiver_, amountOut);
  }

  /// @inheritdoc ITetuConverter
  function isConversionValid(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) external override view returns (bool) {
    return SwapLib.isConversionValid(
      IPriceOracle(IConverterController(controller()).priceOracle()),
      assetIn_,
      amountIn_,
      assetOut_,
      amountOut_,
      priceImpactTolerance_
    );
  }
  //endregion ----------------------------------------------------- Liquidate with checking

  //region ----------------------------------------------------- Utils
  /// @notice Add {debtGap} to the {amount}
  /// @param debtGap debt-gap percent [0..1), decimals DEBT_GAP_DENOMINATOR
  function getAmountWithDebtGap(uint amount, uint debtGap) public pure returns (uint) {
    // Real value of debt gap in AAVE can be very low but it's greater than zero
    // so, even if the amount is very low, the result debt gap addon must be greater than zero
    // we assume here, that it should be not less than MIN_DEBT_GAP_ADDON
    return Math.max(amount * (DEBT_GAP_DENOMINATOR + debtGap) / DEBT_GAP_DENOMINATOR, amount + MIN_DEBT_GAP_ADDON);
  }
  //endregion ----------------------------------------------------- Utils
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
  function registerPoolAdapter(address converter_, address user_, address collateral_, address borrowToken_) external returns (address);

  /// @notice Get pool adapter or 0 if the pool adapter is not registered
  function getPoolAdapter(address converter_, address user_, address collateral_, address borrowToken_) external view returns (address);

  /// @dev Returns true for NORMAL pool adapters and for active DIRTY pool adapters (=== borrow position is opened).
  function isPoolAdapter(address poolAdapter_) external view returns (bool);

  /// @notice Notify borrow manager that the pool adapter with the given params is "dirty".
  ///         The pool adapter should be excluded from the list of ready-to-borrow pool adapters.
  /// @dev "Dirty" means that a liquidation happens inside. The borrow position should be closed during health checking.
  function markPoolAdapterAsDirty(address converter_, address user_, address collateral_, address borrowToken_) external;

  /// @notice Register new lending platform with available pairs of assets
  ///         OR add new pairs of assets to the exist lending platform
  /// @param platformAdapter_ Implementation of IPlatformAdapter attached to the specified pool
  /// @param leftAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  /// @param rightAssets_  Supported pairs of assets. The pairs are set using two arrays: left and right
  function addAssetPairs(address platformAdapter_, address[] calldata leftAssets_, address[] calldata rightAssets_) external;

  /// @notice Remove available pairs of asset from the platform adapter.
  ///         The platform adapter will be unregistered after removing last supported pair of assets
  function removeAssetPairs(address platformAdapter_, address[] calldata leftAssets_, address[] calldata rightAssets_) external;

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

  /// @notice Count of available platform adapters
  function platformAdaptersLength() external view returns (uint);

  /// @notice Get platform adapter at the given index
  /// @param index [0.. platformAdaptersLength)
  function platformAdaptersAt(uint index) external view returns (address);
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

import "./IConverterControllerProvider.sol";

interface IConverterControllable is IConverterControllerProvider {

  function isController(address _contract) external view returns (bool);

  function isProxyUpdater(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function increaseRevision(address oldLogic) external;

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

interface IConverterControllerProvider {
  function controller() external view returns (address);
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

/// @notice Keeper sends notifications to TetuConverter using following interface
interface IKeeperCallback {

  /// @notice This function is called by a keeper if there is unhealthy borrow
  ///         The called contract should send either collateral-amount or borrowed-amount to TetuConverter
  /// @param requiredAmountBorrowAsset_ The borrower should return given borrowed amount back to TetuConverter
  ///                                   in order to restore health factor to target value
  /// @param requiredAmountCollateralAsset_ The borrower should send given amount of collateral to TetuConverter
  ///                                       in order to restore health factor to target value
  /// @param lendingPoolAdapter_ Address of the pool adapter that has problem health factor
  function requireRepay(
    uint requiredAmountBorrowAsset_,
    uint requiredAmountCollateralAsset_,
    address lendingPoolAdapter_
  ) external;
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

/// @notice TetuConverter supports this interface
///         It's called by SwapManager inside static-call swap simulation
///         to transfer amount approved to TetuConverter by user to SwapManager
///         before calling swap simulation
interface IRequireAmountBySwapManagerCallback {
  /// @notice Transfer {sourceAmount_} approved by {approver_} to swap manager
  function onRequireAmountBySwapManager(address approver_, address sourceToken_, uint sourceAmount_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";
import "./IConverter.sol";

interface ISwapConverter is IConverter {
  function getConversionKind()
  override external pure returns (AppDataTypes.ConversionKind);

  /// @notice Swap {sourceAmount_} of {sourceToken_} to {targetToken_} and send result amount to {receiver_}
  /// @return outputAmount The amount that has been sent to the receiver
  function swap(
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_,
    address receiver_
  ) external returns (uint outputAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/AppDataTypes.sol";

interface ISwapManager {

  /// @notice Find a way to convert collateral asset to borrow asset in most efficient way
  /// @dev This is a writable function with read-only behavior
  ///      because to simulate real swap the function should be writable.
  /// @param sourceAmountApprover_ A contract which has approved {sourceAmount_} to TetuConverter
  /// @param sourceAmount_ Amount in terms of {sourceToken_} to be converter to {targetToken_}
  /// @return converter Address of ISwapConverter
  ///         If SwapManager cannot find a conversion way,
  ///         it returns converter == 0 (in the same way as ITetuConverter)
  function getConverter(
    address sourceAmountApprover_,
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_
  ) external returns (
    address converter,
    uint maxTargetAmount
  );

  /// @notice Calculate APR using known {sourceToken_} and known {targetAmount_}.
  /// @param sourceAmount_ Source amount before conversion, in terms of {sourceToken_}
  /// @param targetAmount_ Result of conversion. The amount is in terms of {targetToken_}
  function getApr18(
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_,
    uint targetAmount_
  ) external view returns (int apr18);

  /// @notice Return custom or default price impact tolerance for the asset
  function getPriceImpactTolerance(address asset_) external view returns (uint priceImpactTolerance);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverterControllerProvider.sol";

/// @notice Main contract of the TetuConverter application
/// @dev Borrower (strategy) makes all operations via this contract only.
interface ITetuConverter is IConverterControllerProvider {

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

/// @notice TetuConverter sends callback notifications to its user via this interface
interface ITetuConverterCallback {
  /// @notice Converters calls this function if user should return some amount back.
  ///         f.e. when the health factor is unhealthy and the converter needs more tokens to fix it.
  ///         or when the full repay is required and converter needs to get full amount-to-repay.
  /// @param asset_ Required asset (either collateral or borrow)
  /// @param amount_ Required amount of the {asset_}
  /// @return amountOut Exact amount that borrower has sent to balance of TetuConverter
  function requirePayAmountBack(address asset_, uint amount_) external returns (uint amountOut);

  /// @notice TetuConverter calls this function when it sends any amount to user's balance
  /// @param assets_ Any asset sent to the balance, i.e. inside repayTheBorrow
  /// @param amounts_ Amount of {asset_} that has been sent to the user's balance
  function onTransferAmounts(address[] memory assets_, uint[] memory amounts_) external;
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

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppErrors.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../interfaces/IPriceOracle.sol";

/// @notice Various swap-related routines
library SwapLib {
  uint public constant PRICE_IMPACT_NUMERATOR = 100_000;
  uint public constant PRICE_IMPACT_TOLERANCE_DEFAULT = PRICE_IMPACT_NUMERATOR * 2 / 100; // 2%


  /// @notice Convert amount of {assetIn_} to the corresponded amount of {assetOut_} using price oracle prices
  /// @return Result amount in terms of {assetOut_}
  function convertUsingPriceOracle(
    IPriceOracle priceOracle_,
    address assetIn_,
    uint amountIn_,
    address assetOut_
  ) internal view returns (uint) {
    uint priceOut = priceOracle_.getAssetPrice(assetOut_);
    uint priceIn = priceOracle_.getAssetPrice(assetIn_);
    require(priceOut != 0 && priceIn != 0, AppErrors.ZERO_PRICE);

    return amountIn_
      * 10**IERC20Metadata(assetOut_).decimals()
      * priceIn
      / priceOut
      / 10**IERC20Metadata(assetIn_).decimals();
  }

  /// @notice Check if {amountOut_} is less than expected more than allowed by {priceImpactTolerance_}
  ///         Expected amount is calculated using embedded price oracle.
  /// @return Price difference is ok for the given {priceImpactTolerance_}
  function isConversionValid(
    IPriceOracle priceOracle_,
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) internal view returns (bool) {
    uint priceOut = priceOracle_.getAssetPrice(assetOut_);
    uint priceIn = priceOracle_.getAssetPrice(assetIn_);
    require(priceOut != 0 && priceIn != 0, AppErrors.ZERO_PRICE);

    uint expectedAmountOut = amountIn_
      * 10**IERC20Metadata(assetOut_).decimals()
      * priceIn
      / priceOut
      / 10**IERC20Metadata(assetIn_).decimals();
    return amountOut_ > expectedAmountOut
      ? true // we assume here, that higher output amount is not a problem
      : (expectedAmountOut - amountOut_) <= expectedAmountOut * priceImpactTolerance_ / SwapLib.PRICE_IMPACT_NUMERATOR;
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.17;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

import "../openzeppelin/Initializable.sol";
import "../libs/SlotsLib.sol";
import "../libs/AppErrors.sol";
import "../interfaces/IConverterControllable.sol";
import "../interfaces/IConverterController.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, IConverterControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public onlyInitializing {
    require(controller_ != address(0), AppErrors.ZERO_ADDRESS);
    require(IConverterController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }
  /// @dev Return true if given address is controller of tetu-contracts-v2 that is allowed to update proxy contracts
  function isProxyUpdater(address _value) public override view returns (bool) {
    return IConverterController(controller()).proxyUpdater() == _value;
  }

  /// @notice Return true if given address is setup as governance in ConverterController
  function isGovernance(address _value) public override view returns (bool) {
    return IConverterController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return ConverterController address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}