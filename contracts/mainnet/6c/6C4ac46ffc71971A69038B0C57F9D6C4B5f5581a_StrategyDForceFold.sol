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
pragma solidity 0.8.4;


import "../../strategies/dforce/DForceFoldStrategyBase.sol";

contract StrategyDForceFold is DForceFoldStrategyBase {

  address private constant DF = 0x08C15FA26E519A78a666D19CE5C646D55047e0a3;
  address[] private _poolRewards = [DF];
  address[] private _assets;

  constructor(
    address _controller,
    address _vault,
    address _underlying,
    address _iToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator
  ) DForceFoldStrategyBase(
    _controller,
    _underlying,
    _vault,
    _poolRewards,
    _borrowTargetFactorNumerator,
    _collateralFactorNumerator,
    _iToken
  ) {
    require(_underlying != address(0), "zero underlying");
    _assets.push(_underlying);
  }

  // assets should reflect underlying tokens need to investing
  function assets() external override view returns (address[] memory) {
    return _assets;
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

pragma solidity 0.8.4;

import "@tetu_io/tetu-contracts/contracts/base/strategies/FoldingBase.sol";
import "../../third_party/IWmatic.sol";
import "../../third_party/dforce/IiToken.sol";
import "../../third_party/dforce/IRewardDistributorV3.sol";
import "../../third_party/dforce/IDForcePriceOracle.sol";

/// @title Abstract contract for dForce lending strategy implementation with folding functionality
/// @author belbix
abstract contract DForceFoldStrategyBase is FoldingBase {
  using SafeERC20 for IERC20;

  // ************ CONSTANTS **********************

  /// @notice Version of the contract
  /// @dev Should be incremented when contract is changed
  string public constant VERSION = "1.0.0";
  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "DForceFoldStrategyBase";
  /// @dev Placeholder, for non full buyback need to implement liquidation
  uint private constant _BUY_BACK_RATIO = 100_00;

  /// @dev precision for the folding profitability calculation
  uint private constant _PRECISION = 10 ** 18;
  /// @dev approximate number of seconds per year
  uint private constant _SECONDS_PER_YEAR = 365 days;

  address public constant W_MATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  IRewardDistributorV3 public constant REWARD_DISTRIBUTOR = IRewardDistributorV3(0x47C19A2ab52DA26551A22e2b2aEED5d19eF4022F);
  IDForcePriceOracle public constant PRICE_ORACLE = IDForcePriceOracle(payable(0x9E8B68E17441413b26C2f18e741EAba69894767c));
  address public constant DF_USDC_PAIR = 0x84c6B5b5CB47f117ff442C44d25E379e06Df5d8a;

  // ************ VARIABLES **********************

  IiToken public iToken;

  /// @notice Contract constructor using on strategy implementation
  constructor(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    uint _borrowTargetFactorNumerator,
    uint _collateralFactorNumerator,
    address _iToken
  ) FoldingBase(
    _controller,
    _underlying,
    _vault,
    __rewardTokens,
    _BUY_BACK_RATIO,
    _borrowTargetFactorNumerator,
    _collateralFactorNumerator
  ) {
    iToken = IiToken(_iToken);
  }

  /////////////////////////////////////////////
  ////////////BASIC STRATEGY FUNCTIONS/////////
  /////////////////////////////////////////////

  /// @notice Return approximately amount of reward tokens ready to claim in AAVE Lending pool
  /// @dev Don't use it in any internal logic, only for statistical purposes
  /// @return Array with amounts ready to claim
  function readyToClaim() external view override returns (uint[] memory) {
    uint[] memory rewards = new uint[](1);
    rewards[0] = REWARD_DISTRIBUTOR.reward(address(this));
    return rewards;
  }

  /// @notice TVL of the underlying in the aToken contract
  /// @dev Only for statistic
  /// @return Pool TVL
  function poolTotalAmount() external view override returns (uint) {
    return iToken.getCash() + iToken.totalBorrows() - iToken.totalReserves();
  }

  /// @dev Do something useful with farmed rewards
  function liquidateReward() internal override {
    liquidateRewardDefault();
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  ///////////// internal functions require specific implementation for each platforms ///
  ///////////////////////////////////////////////////////////////////////////////////////

  function _getInvestmentData() internal override returns (uint supplied, uint borrowed){
    supplied = iToken.balanceOfUnderlying(address(this));
    borrowed = iToken.borrowBalanceCurrent(address(this));
  }

  /// @dev Return true if we can gain profit with folding
  function _isFoldingProfitable() internal view override returns (bool) {
    (uint supplyRewardsInUSDC,
    uint borrowRewardsInUSDC,
    uint supplyUnderlyingProfitInUSDC,
    uint debtUnderlyingCostInUSDC) = totalRewardPredictionInUSDC();

    uint foldingProfitPerToken = supplyRewardsInUSDC + borrowRewardsInUSDC + supplyUnderlyingProfitInUSDC;
    return foldingProfitPerToken > debtUnderlyingCostInUSDC;
  }

  /// @dev Claim distribution rewards
  function _claimReward() internal override {
    address[] memory holders = new address[](1);
    holders[0] = address(this);
    address[] memory rts = new address[](1);
    rts[0] = address(iToken);
    REWARD_DISTRIBUTOR.claimReward(holders, rts);
  }

  function _supply(uint amount) internal override {
    amount = Math.min(IERC20(_underlyingToken).balanceOf(address(this)), amount);
    if (_isMatic()) {
      revert("S: ETH Not supported");
      //      wmaticWithdraw(amount);
      //      iTokenEth.mint{value : amount}();
    } else {
      IERC20(_underlyingToken).safeApprove(address(iToken), 0);
      IERC20(_underlyingToken).safeApprove(address(iToken), amount);
      iToken.mintForSelfAndEnterMarket(amount);
    }
  }

  function _borrow(uint amountUnderlying) internal override {
    iToken.borrow(amountUnderlying);
    if (_isMatic()) {
      revert("S: ETH Not supported");
      //      IWmatic(W_MATIC).deposit{value : address(this).balance}();
    }
  }

  function _redeemUnderlying(uint amountUnderlying) internal override {
    amountUnderlying = Math.min(amountUnderlying, _maxRedeem());
    if (amountUnderlying > 0) {
      iToken.redeemUnderlying(address(this), amountUnderlying);
      if (_isMatic()) {
        revert("S: ETH Not supported");
        //        IWmatic(W_MATIC).deposit{value : address(this).balance}();
      }
    }
  }

  function _repay(uint amountUnderlying) internal override {
    if (amountUnderlying != 0) {
      if (_isMatic()) {
        revert("S: ETH Not supported");
        //        wmaticWithdraw(amountUnderlying);
        //        IRMatic(rToken).repayBorrow{value : amountUnderlying}();
      } else {
        IERC20(_underlyingToken).safeApprove(address(iToken), 0);
        IERC20(_underlyingToken).safeApprove(address(iToken), amountUnderlying);
        iToken.repayBorrow(amountUnderlying);
      }
    }
  }

  /// @dev Redeems the maximum amount of underlying. Either all of the balance or all of the available liquidity.
  function _redeemMaximumWithLoan() internal override {
    uint supplied = iToken.balanceOfUnderlying(address(this));
    uint borrowed = iToken.borrowBalanceCurrent(address(this));
    uint balance = supplied - borrowed;
    _redeemPartialWithLoan(balance);

    // we have a little amount of supply after full exit
    // better to redeem rToken amount for avoid rounding issues
    uint iTokenBalance = iToken.balanceOf(address(this));
    if (iTokenBalance > 0) {
      iToken.redeem(address(this), iTokenBalance);
    }
  }

  /////////////////////////////////////////////
  ////////////SPECIFIC INTERNAL FUNCTIONS//////
  /////////////////////////////////////////////

  function decimals() private view returns (uint8) {
    return iToken.decimals();
  }

  function underlyingDecimals() private view returns (uint8) {
    return IERC20Extended(_underlyingToken).decimals();
  }

  /// @notice returns forecast of all rewards
  function totalRewardPrediction() private view returns (
    uint supplyRewards,
    uint borrowRewards,
    uint supplyUnderlyingProfit,
    uint debtUnderlyingCost
  ){
    // get reward per token for both - suppliers and borrowers
    uint rewardSpeed = REWARD_DISTRIBUTOR.distributionSpeed(address(iToken));
    // get total supply, cash and borrows, and normalize them to 18 decimals
    uint totalSupply = iToken.totalSupply() * 1e18 / (10 ** decimals());
    uint totalBorrows = iToken.totalBorrows() * 1e18 / (10 ** underlyingDecimals());
    if (totalSupply == 0 || totalBorrows == 0) {
      return (0, 0, 0, 0);
    }

    // exchange rate between iToken and underlyingToken
    uint iTokenExchangeRate = iToken.exchangeRateStored() * (10 ** decimals()) / (10 ** underlyingDecimals());

    // amount of reward tokens per block for 1 supplied underlyingToken
    supplyRewards = rewardSpeed * 1e18 / iTokenExchangeRate * 1e18 / totalSupply;
    // amount of reward tokens per block for 1 borrowed underlyingToken
    borrowRewards = rewardSpeed * 1e18 / totalBorrows;
    supplyUnderlyingProfit = iToken.supplyRatePerBlock();
    debtUnderlyingCost = iToken.borrowRatePerBlock();
    return (supplyRewards, borrowRewards, supplyUnderlyingProfit, debtUnderlyingCost);
  }

  function getRewardTokenUsdPrice() internal view returns (uint) {
    return getPriceFromLp(DF_USDC_PAIR, _rewardTokens[0]);
  }

  function getPriceFromLp(address lpAddress, address token) internal view returns (uint256) {
    IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
    address token0 = pair.token0();
    address token1 = pair.token1();
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 token0Decimals = IERC20Extended(token0).decimals();
    uint256 token1Decimals = IERC20Extended(token1).decimals();

    // both reserves should have the same decimals
    reserve0 = reserve0 * 1e18 / (10 ** token0Decimals);
    reserve1 = reserve1 * 1e18 / (10 ** token1Decimals);

    if (token == token0) {
      return reserve1 * 1e18 / reserve0;
    } else if (token == token1) {
      return reserve0 * 1e18 / reserve1;
    } else {
      revert("S: Token not in lp");
    }
  }

  /// @notice returns forecast of all rewards (ICE and underlying)
  ///         for the given period of time in USDC token using ICE price oracle
  function totalRewardPredictionInUSDC() private view returns (
    uint supplyRewardsInUSDC,
    uint borrowRewardsInUSDC,
    uint supplyUnderlyingProfitInUSDC,
    uint debtUnderlyingCostInUSDC
  ){
    uint rewardTokenUSDC = getRewardTokenUsdPrice();
    uint iTokenUSDC = iTokenUnderlyingPrice();
    (uint supplyRewards,
    uint borrowRewards,
    uint supplyUnderlyingProfit,
    uint debtUnderlyingCost) = totalRewardPrediction();

    supplyRewardsInUSDC = supplyRewards * rewardTokenUSDC / _PRECISION;
    borrowRewardsInUSDC = borrowRewards * rewardTokenUSDC / _PRECISION;
    supplyUnderlyingProfitInUSDC = supplyUnderlyingProfit * iTokenUSDC / _PRECISION;
    debtUnderlyingCostInUSDC = debtUnderlyingCost * iTokenUSDC / _PRECISION;
  }

  /// @dev Return iToken price from Oracle solution. Can be used on-chain safely
  function iTokenUnderlyingPrice() public view returns (uint){
    uint _iTokenPrice = PRICE_ORACLE.getUnderlyingPrice(address(iToken));
    // normalize token price to 1e18
    if (underlyingDecimals() < 18) {
      _iTokenPrice = _iTokenPrice / (10 ** (18 - underlyingDecimals()));
    }
    return _iTokenPrice;
  }

  function wmaticWithdraw(uint amount) private {
    require(IERC20(W_MATIC).balanceOf(address(this)) >= amount, "S: Not enough wmatic");
    IWmatic(W_MATIC).withdraw(amount);
  }

  function _isMatic() internal pure returns (bool) {
    // not yet implemented
    return false;
  }

  function platform() external override pure returns (IStrategy.Platform) {
    // todo change in the main repo
    return IStrategy.Platform.SLOT_39;
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

pragma solidity 0.8.4;

import "./StrategyBase.sol";
import "../interface/ISmartVault.sol";
import "../../third_party/IERC20Extended.sol";
import "../interface/strategies/IFoldStrategy.sol";

/// @title Abstract contract for folding strategy
/// @author JasperS13
/// @author belbix
abstract contract FoldingBase is StrategyBase, IFoldStrategy {
  using SafeERC20 for IERC20;

  // ************ VARIABLES **********************
  /// @dev Maximum folding loops
  uint256 public constant MAX_DEPTH = 3;
  /// @notice Denominator value for the both above mentioned ratios
  uint256 public _FACTOR_DENOMINATOR = 10000;
  uint256 public _BORROW_FACTOR = 9900;

  /// @notice Numerator value for the targeted borrow rate
  uint256 public override borrowTargetFactorNumeratorStored;
  uint256 public override borrowTargetFactorNumerator;
  /// @notice Numerator value for the asset market collateral value
  uint256 public override collateralFactorNumerator;
  /// @notice Use folding
  bool public override fold = true;
  /// @dev 0 - default mode, 1 - always enable, 2 - always disable
  uint public override foldState;

  /// @notice Strategy balance parameters to be tracked
  uint256 public override suppliedInUnderlying;
  uint256 public override borrowedInUnderlying;

  event FoldStateChanged(uint value);
  event FoldStopped();
  event FoldStarted(uint256 borrowTargetFactorNumerator);
  event MaxDepthReached();
  event NoMoneyForLiquidateUnderlying();
  event UnderlyingLiquidationFailed();
  event Rebalanced(uint256 supplied, uint256 borrowed, uint256 borrowTarget);
  event BorrowTargetFactorNumeratorChanged(uint256 value);
  event CollateralFactorNumeratorChanged(uint256 value);

  modifier updateSupplyInTheEnd() {
    _;
    (suppliedInUnderlying, borrowedInUnderlying) = _getInvestmentData();
  }

  constructor(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    uint256 __buyBackRatio,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator
  ) StrategyBase(_controller, _underlying, _vault, __rewardTokens, __buyBackRatio) {
    require(_collateralFactorNumerator < _FACTOR_DENOMINATOR, "FS: Collateral factor cannot be this high");
    collateralFactorNumerator = _collateralFactorNumerator;

    require(_borrowTargetFactorNumerator == 0 || _borrowTargetFactorNumerator < collateralFactorNumerator, "FS: Target should be lower than collateral limit");
    borrowTargetFactorNumeratorStored = _borrowTargetFactorNumerator;
    borrowTargetFactorNumerator = _borrowTargetFactorNumerator;
  }

  ///////////// internal functions require specific implementation for each platforms

  function _getInvestmentData() internal virtual returns (uint256 supplied, uint256 borrowed);

  function _isFoldingProfitable() internal view virtual returns (bool);

  function _claimReward() internal virtual;

  //////////// require update balance in the end

  function _supply(uint256 amount) internal virtual;

  function _borrow(uint256 amountUnderlying) internal virtual;

  function _redeemUnderlying(uint256 amountUnderlying) internal virtual;

  function _repay(uint256 amountUnderlying) internal virtual;

  function _redeemMaximumWithLoan() internal virtual;

  // ************* VIEW **********************

  /// @dev Return true if we can gain profit with folding
  function isFoldingProfitable() public view override returns (bool) {
    return _isFoldingProfitable();
  }

  function _isAutocompound() internal view virtual returns (bool) {
    return _buyBackRatio != _BUY_BACK_DENOMINATOR;
  }

  // ************* GOV ACTIONS **************

  function claimReward() external hardWorkers {
    _claimReward();
  }

  /// @dev Liquidate rewards and do underlying compound
  function compound() external hardWorkers updateSupplyInTheEnd {
    if (_isAutocompound()) {
      _autocompound();
    } else {
      _compound();
    }
  }

  /// @dev Set folding state
  /// @param _state 0 - default mode, 1 - always enable, 2 - always disable
  function setFold(uint _state) external override restricted {
    require(_state != foldState, "FB: The same folding state");
    if (_state == 0) {
      if (!isFoldingProfitable() && fold) {
        _stopFolding();
      } else if (isFoldingProfitable() && !fold) {
        _startFolding();
      }
    } else if (_state == 1) {
      _startFolding();
    } else if (_state == 2) {
      _stopFolding();
    } else {
      revert("FB: Wrong folding state");
    }
    foldState = _state;
    emit FoldStateChanged(_state);
  }

  /// @dev Rebalances the borrow ratio
  function rebalance() external override hardWorkers {
    _rebalance();
  }

  /// @dev Check fold state and rebalance if needed
  function checkFold() external hardWorkers {
    if (foldState == 0) {
      if (!isFoldingProfitable() && fold) {
        _stopFolding();
      } else if (isFoldingProfitable() && !fold) {
        _startFolding();
      } else {
        _rebalance();
      }
    } else {
      _rebalance();
    }
  }

  /// @dev Set borrow rate target
  function setBorrowTargetFactorNumeratorStored(uint256 _target) external override restricted {
    _setBorrowTargetFactorNumeratorStored(_target);
  }

  function stopFolding() external override restricted {
    _stopFolding();
  }

  function startFolding() external override restricted {
    _startFolding();
  }

  /// @dev Set collateral rate for asset market
  function setCollateralFactorNumerator(uint256 _target) external override restricted {
    require(_target < _FACTOR_DENOMINATOR, "FS: Collateral factor cannot be this high");
    collateralFactorNumerator = _target;
    emit CollateralFactorNumeratorChanged(_target);
  }

  /// @dev Set buy back denominator
  function setBuyBack(uint256 _value) external restricted {
    require(_value <= _BUY_BACK_DENOMINATOR, "FS: Too high");
    _buyBackRatio = _value;
  }

  function manualRedeem(uint amount) external restricted updateSupplyInTheEnd {
    _redeemUnderlying(amount);
  }

  function manualRepay(uint amount) external restricted updateSupplyInTheEnd {
    _repay(amount);
  }

  function manualSupply(uint amount) external restricted updateSupplyInTheEnd {
    _supply(amount);
  }

  function manualBorrow(uint amount) external restricted updateSupplyInTheEnd {
    _borrow(amount);
  }

  /// @dev This function should be used in emergency case when not enough gas for redeem all in one tx
  function manualRedeemMax() external hardWorkers updateSupplyInTheEnd {
    _redeemMaxPossible();
  }

  //////////////////////////////////////////////////////
  //////////// STRATEGY FUNCTIONS IMPLEMENTATIONS //////
  //////////////////////////////////////////////////////

  /// @notice Strategy balance supplied minus borrowed
  /// @return bal Balance amount in underlying tokens
  function rewardPoolBalance() public override view returns (uint256) {
    return suppliedInUnderlying - borrowedInUnderlying;
  }

  /// @notice Claim rewards from external project and send them to FeeRewardForwarder
  function doHardWork()  external onlyNotPausedInvesting virtual override hardWorkers updateSupplyInTheEnd {
    // don't invest underlying for reduce cas consumption
    _claimReward();
    if (_isAutocompound()) {
      _autocompound();
    } else {
      _compound();
    }
    // supply underlying for avoiding liquidation in case of reward is the same as underlying
    if (underlyingBalance() > 0) {
      _supply(underlyingBalance());
    }
    liquidateReward();
    // don't rebalance, it should be done as separate tx
  }

  /// @dev Withdraw underlying from Iron MasterChef finance
  /// @param amount Withdraw amount
  function withdrawAndClaimFromPool(uint256 amount) internal override updateSupplyInTheEnd {
    // don't claim rewards on withdraw action for reducing gas usage
    //    _claimReward();
    _redeemPartialWithLoan(amount);
  }

  /// @dev Exit from external project without caring about rewards
  ///      For emergency cases only!
  function emergencyWithdrawFromPool() internal override updateSupplyInTheEnd {
    _redeemMaximumWithLoan();
  }

  /// @dev Should withdraw all available assets
  function exitRewardPool() internal override updateSupplyInTheEnd {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      // _claimReward();
      _redeemMaximumWithLoan();
      // reward liquidation can ruin transaction, do it in hard work process
    }
  }

  //////////////////////////////////////////////////////
  //////////// INTERNAL GOV FUNCTIONS //////////////////
  //////////////////////////////////////////////////////

  /// @dev Rebalances the borrow ratio
  function _rebalance() internal updateSupplyInTheEnd {
    (uint256 supplied, uint256 borrowed) = _getInvestmentData();
    uint256 borrowTarget = _borrowTarget();
    if (borrowed > borrowTarget) {
      _redeemPartialWithLoan(0);
    } else if (borrowed < borrowTarget) {
      depositToPool(0);
    }
    emit Rebalanced(supplied, borrowed, borrowTarget);
  }

  /// @dev Set borrow rate target
  function _setBorrowTargetFactorNumeratorStored(uint256 _target) internal {
    require(_target == 0 || _target < collateralFactorNumerator, "FS: Target should be lower than collateral limit");
    borrowTargetFactorNumeratorStored = _target;
    if (fold) {
      borrowTargetFactorNumerator = _target;
    }
    emit BorrowTargetFactorNumeratorChanged(_target);
  }

  function _stopFolding() internal {
    borrowTargetFactorNumerator = 0;
    fold = false;
    _rebalance();
    emit FoldStopped();
  }

  function _startFolding() internal {
    borrowTargetFactorNumerator = borrowTargetFactorNumeratorStored;
    fold = true;
    _rebalance();
    emit FoldStarted(borrowTargetFactorNumeratorStored);
  }

  //////////////////////////////////////////////////////
  //////////// FOLDING LOGIC FUNCTIONS /////////////////
  //////////////////////////////////////////////////////

  function _maxRedeem() internal returns (uint){
    (uint supplied, uint borrowed) = _getInvestmentData();
    if (collateralFactorNumerator == 0) {
      return supplied;
    }
    uint256 requiredCollateral = borrowed * _FACTOR_DENOMINATOR / collateralFactorNumerator;
    if (supplied < requiredCollateral) {
      return 0;
    }
    return supplied - requiredCollateral;
  }

  function _borrowTarget() internal returns (uint256) {
    (uint256 supplied, uint256 borrowed) = _getInvestmentData();
    uint256 balance = supplied - borrowed;
    return balance * borrowTargetFactorNumerator
    / (_FACTOR_DENOMINATOR - borrowTargetFactorNumerator);
  }

  /// @dev Deposit underlying to rToken contract
  /// @param amount Deposit amount
  function depositToPool(uint256 amount) internal override updateSupplyInTheEnd {
    if (amount > 0) {
      _supply(amount);
      if (!_isAutocompound()) {
        // we need to sell excess in non hardWork function for keeping ppfs ~1
        _liquidateExcessUnderlying();
      }
    }
    if (foldState == 2 || !fold) {
      return;
    }
    (uint256 supplied, uint256 borrowed) = _getInvestmentData();
    uint256 borrowTarget = _borrowTarget();
    uint256 i = 0;
    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget - borrowed;
      uint256 maxBorrow = (supplied * collateralFactorNumerator / _FACTOR_DENOMINATOR) - borrowed;
      // need to reduce max borrow for keep a gap for negative balance fluctuation
      maxBorrow = maxBorrow * _BORROW_FACTOR / _FACTOR_DENOMINATOR;
      _borrow(Math.min(wantBorrow, maxBorrow));
      uint256 _underlyingBalance = IERC20(_underlyingToken).balanceOf(address(this));
      if (_underlyingBalance > 0) {
        _supply(_underlyingBalance);
      }
      // need to update local balances
      (supplied, borrowed) = _getInvestmentData();

      // we can move the market and make folding unprofitable
      if (!_isFoldingProfitable()) {
        // rollback the last action
        _redeemUnderlying(_underlyingBalance);
        _underlyingBalance = IERC20(_underlyingToken).balanceOf(address(this));
        _repay(_underlyingBalance);
        break;
      }

      i++;
      if (i == MAX_DEPTH) {
        emit MaxDepthReached();
        break;
      }
    }
  }

  /// @dev Redeems a set amount of underlying tokens while keeping the borrow ratio healthy.
  ///      This function must not revert transaction
  function _redeemPartialWithLoan(uint256 amount) internal updateSupplyInTheEnd {
    (uint256 supplied, uint256 borrowed) = _getInvestmentData();
    uint256 oldBalance = supplied - borrowed;
    uint256 newBalance = 0;
    if (amount < oldBalance) {
      newBalance = oldBalance - amount;
    }
    uint256 newBorrowTarget = newBalance * borrowTargetFactorNumerator / (_FACTOR_DENOMINATOR - borrowTargetFactorNumerator);
    uint256 _underlyingBalance = 0;
    uint256 i = 0;
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed * _FACTOR_DENOMINATOR / collateralFactorNumerator;
      uint256 toRepay = borrowed - newBorrowTarget;
      if (supplied < requiredCollateral) {
        break;
      }
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied - requiredCollateral, amount + toRepay);
      _redeemUnderlying(toRedeem);
      // now we can repay our borrowed amount
      _underlyingBalance = IERC20(_underlyingToken).balanceOf(address(this));
      toRepay = Math.min(toRepay, _underlyingBalance);
      if (toRepay == 0) {
        // in case of we don't have money for repaying we can't do anything
        break;
      }
      _repay(toRepay);
      // update the parameters
      (supplied, borrowed) = _getInvestmentData();
      i++;
      // don't check MAX_DEPTH
      // we should able to withdraw as much as possible
    }
    _underlyingBalance = IERC20(_underlyingToken).balanceOf(address(this));
    if (_underlyingBalance < amount) {
      uint toRedeem = amount - _underlyingBalance;
      if (toRedeem != 0) {
        // redeem the most we can redeem
        _redeemUnderlying(toRedeem);
      }
    }
    // supply excess underlying balance in the end
    _underlyingBalance = IERC20(_underlyingToken).balanceOf(address(this));
    if (_underlyingBalance > amount) {
      _supply(_underlyingBalance - amount);
    }
  }

  function _redeemMaxPossible() internal updateSupplyInTheEnd {
    // assume that _maxRedeem() will be called inside _redeemUnderlying()
    _redeemUnderlying(type(uint256).max);
    (,uint borrowed) = _getInvestmentData();
    uint toRepay = Math.min(borrowed, IERC20(_underlyingToken).balanceOf(address(this)));
    _repay(toRepay);
  }

  //////////////////////////////////////////////////////
  ///////////////// LIQUIDATION ////////////////////////
  //////////////////////////////////////////////////////

  function _autocompound() internal {
    require(_isAutocompound(), "FB: Must use compound");
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      address rt = _rewardTokens[i];
      // a little threshold
      if (amount > 1000) {
        uint toDistribute = amount * _buyBackRatio / _BUY_BACK_DENOMINATOR;
        uint toCompound = amount - toDistribute;
        address forwarder = IController(controller()).feeRewardForwarder();
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, amount);
        IFeeRewardForwarder(forwarder).liquidate(rt, _underlyingToken, toCompound);
        try IFeeRewardForwarder(forwarder).distribute(toDistribute, _underlyingToken, _smartVault)
        returns (uint256 targetTokenEarned) {
          if (targetTokenEarned > 0) {
            IBookkeeper(IController(controller()).bookkeeper()).registerStrategyEarned(targetTokenEarned);
          }
        } catch {
          emit UnderlyingLiquidationFailed();
        }
      }
    }

  }

  function _compound() internal {
    require(!_isAutocompound(), "FB: Must use autocompound");
    (suppliedInUnderlying, borrowedInUnderlying) = _getInvestmentData();
    uint256 ppfs = ISmartVault(_smartVault).getPricePerFullShare();
    uint256 ppfsPeg = ISmartVault(_smartVault).underlyingUnit();

    // in case of negative ppfs compound all profit to underlying
    if (ppfs < ppfsPeg) {
      for (uint256 i = 0; i < _rewardTokens.length; i++) {
        uint256 amount = rewardBalance(i);
        address rt = _rewardTokens[i];
        // it will sell reward token to Target Token and send back
        if (amount != 0) {
          address forwarder = IController(controller()).feeRewardForwarder();
          IERC20(rt).safeApprove(forwarder, 0);
          IERC20(rt).safeApprove(forwarder, amount);
          uint256 underlyingProfit = IFeeRewardForwarder(forwarder).liquidate(rt, _underlyingToken, amount);
          // supply profit for correct ppfs calculation
          if (underlyingProfit != 0) {
            _supply(underlyingProfit);
          }
        }
      }
    }
    _liquidateExcessUnderlying();
  }

  /// @dev We should keep PPFS ~1
  ///      This function must not ruin transaction
  function _liquidateExcessUnderlying() internal updateSupplyInTheEnd {
    // update balances for accurate ppfs calculation
    (suppliedInUnderlying, borrowedInUnderlying) = _getInvestmentData();

    address forwarder = IController(controller()).feeRewardForwarder();
    uint256 ppfs = ISmartVault(_smartVault).getPricePerFullShare();
    uint256 ppfsPeg = ISmartVault(_smartVault).underlyingUnit();

    if (ppfs > ppfsPeg) {
      uint256 totalUnderlyingBalance = ISmartVault(_smartVault).underlyingBalanceWithInvestment();
      if (totalUnderlyingBalance == 0
      || IERC20Extended(_smartVault).totalSupply() == 0
      || totalUnderlyingBalance < IERC20Extended(_smartVault).totalSupply()
        || totalUnderlyingBalance - IERC20Extended(_smartVault).totalSupply() < 2) {
        // no actions in case of no money
        emit NoMoneyForLiquidateUnderlying();
        return;
      }
      // ppfs = 1 if underlying balance = total supply
      // -1 for avoiding problem with rounding
      uint256 toLiquidate = (totalUnderlyingBalance - IERC20Extended(_smartVault).totalSupply()) - 1;
      if (underlyingBalance() < toLiquidate) {
        _redeemPartialWithLoan(toLiquidate);
      }
      toLiquidate = Math.min(underlyingBalance(), toLiquidate);
      if (toLiquidate != 0) {
        IERC20(_underlyingToken).safeApprove(forwarder, 0);
        IERC20(_underlyingToken).safeApprove(forwarder, toLiquidate);

        // it will sell reward token to Target Token and distribute it to SmartVault and PS
        // we must not ruin transaction in any case
        //slither-disable-next-line unused-return,variable-scope,uninitialized-local
        try IFeeRewardForwarder(forwarder).distribute(toLiquidate, _underlyingToken, _smartVault)
        returns (uint256 targetTokenEarned) {
          if (targetTokenEarned > 0) {
            IBookkeeper(IController(controller()).bookkeeper()).registerStrategyEarned(targetTokenEarned);
          }
        } catch {
          emit UnderlyingLiquidationFailed();
        }
      }
    }
  }

  receive() external payable {} // this is needed for the native token unwrapping
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IiToken {
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  event Borrow(
    address borrower,
    uint256 borrowAmount,
    uint256 accountBorrows,
    uint256 accountInterestIndex,
    uint256 totalBorrows
  );
  event Flashloan(
    address loaner,
    uint256 loanAmount,
    uint256 flashloanFee,
    uint256 protocolFee,
    uint256 timestamp
  );
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address iTokenCollateral,
    uint256 seizeTokens
  );
  event Mint(
    address sender,
    address recipient,
    uint256 mintAmount,
    uint256 mintTokens
  );
  event NewController(address oldController, address newController);
  event NewFlashloanFee(
    uint256 oldFlashloanFeeRatio,
    uint256 newFlashloanFeeRatio,
    uint256 oldProtocolFeeRatio,
    uint256 newProtocolFeeRatio
  );
  event NewFlashloanFeeRatio(
    uint256 oldFlashloanFeeRatio,
    uint256 newFlashloanFeeRatio
  );
  event NewInterestRateModel(
    address oldInterestRateModel,
    address newInterestRateModel
  );
  event NewOwner(address indexed previousOwner, address indexed newOwner);
  event NewPendingOwner(
    address indexed oldPendingOwner,
    address indexed newPendingOwner
  );
  event NewProtocolFeeRatio(
    uint256 oldProtocolFeeRatio,
    uint256 newProtocolFeeRatio
  );
  event NewReserveRatio(uint256 oldReserveRatio, uint256 newReserveRatio);
  event Redeem(
    address from,
    address recipient,
    uint256 redeemiTokenAmount,
    uint256 redeemUnderlyingAmount
  );
  event RepayBorrow(
    address payer,
    address borrower,
    uint256 repayAmount,
    uint256 accountBorrows,
    uint256 accountInterestIndex,
    uint256 totalBorrows
  );
  event ReservesWithdrawn(
    address admin,
    uint256 amount,
    uint256 newTotalReserves,
    uint256 oldTotalReserves
  );
  event Transfer(address indexed from, address indexed to, uint256 value);
  event UpdateInterest(
    uint256 currentBlockNumber,
    uint256 interestAccumulated,
    uint256 borrowIndex,
    uint256 cash,
    uint256 totalBorrows,
    uint256 totalReserves
  );

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function _acceptOwner() external;

  function _setController(address _newController) external;

  function _setInterestRateModel(address _newInterestRateModel) external;

  function _setNewFlashloanFeeRatio(uint256 _newFlashloanFeeRatio) external;

  function _setNewProtocolFeeRatio(uint256 _newProtocolFeeRatio) external;

  function _setNewReserveRatio(uint256 _newReserveRatio) external;

  function _setPendingOwner(address newPendingOwner) external;

  function _withdrawReserves(uint256 _withdrawAmount) external;

  function accrualBlockNumber() external view returns (uint256);

  function allowance(address, address) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function balanceOfUnderlying(address _account) external returns (uint256);

  function borrow(uint256 _borrowAmount) external;

  function borrowBalanceCurrent(address _account) external returns (uint256);

  function borrowBalanceStored(address _account)
  external
  view
  returns (uint256);

  function borrowIndex() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function borrowSnapshot(address _account)
  external
  view
  returns (uint256, uint256);

  function controller() external view returns (address);

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue)
  external
  returns (bool);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function flashloanFeeRatio() external view returns (uint256);

  function getCash() external view returns (uint256);

  function increaseAllowance(address spender, uint256 addedValue)
  external
  returns (bool);

  function initialize(
    address _underlyingToken,
    string memory _name,
    string memory _symbol,
    address _controller,
    address _interestRateModel
  ) external;

  function interestRateModel() external view returns (address);

  function isSupported() external view returns (bool);

  function isiToken() external pure returns (bool);

  function liquidateBorrow(
    address _borrower,
    uint256 _repayAmount,
    address _assetCollateral
  ) external;

  function mint(address _recipient, uint256 _mintAmount) external;

  function mintForSelfAndEnterMarket(uint256 _mintAmount) external;

  function name() external view returns (string memory);

  function nonces(address) external view returns (uint256);

  function owner() external view returns (address);

  function pendingOwner() external view returns (address);

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function protocolFeeRatio() external view returns (uint256);

  function redeem(address _from, uint256 _redeemiToken) external;

  function redeemUnderlying(address _from, uint256 _redeemUnderlying)
  external;

  function repayBorrow(uint256 _repayAmount) external;

  function repayBorrowBehalf(address _borrower, uint256 _repayAmount)
  external;

  function reserveRatio() external view returns (uint256);

  function seize(
    address _liquidator,
    address _borrower,
    uint256 _seizeTokens
  ) external;

  function supplyRatePerBlock() external view returns (uint256);

  function symbol() external view returns (string memory);

  function totalBorrows() external view returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function totalReserves() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function transfer(address _recipient, uint256 _amount)
  external
  returns (bool);

  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool);

  function underlying() external view returns (address);

  function updateInterest() external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IRewardDistributorV3 {
  event DistributionBorrowSpeedUpdated(address iToken, uint256 borrowSpeed);
  event DistributionSupplySpeedUpdated(address iToken, uint256 supplySpeed);
  event GlobalDistributionSpeedsUpdated(
    uint256 borrowSpeed,
    uint256 supplySpeed
  );
  event NewDistributionFactor(
    address iToken,
    uint256 oldDistributionFactorMantissa,
    uint256 newDistributionFactorMantissa
  );
  event NewOwner(address indexed previousOwner, address indexed newOwner);
  event NewPendingOwner(
    address indexed oldPendingOwner,
    address indexed newPendingOwner
  );
  event NewRecipient(address iToken, uint256 distributionFactor);
  event NewRewardToken(address oldRewardToken, address newRewardToken);
  event Paused(bool paused);
  event RewardDistributed(
    address iToken,
    address account,
    uint256 amount,
    uint256 accountIndex
  );

  function _acceptOwner() external;

  function _addRecipient(address _iToken, uint256 _distributionFactor)
  external;

  function _pause() external;

  function _setDistributionBorrowSpeeds(
    address[] memory _iTokens,
    uint256[] memory _borrowSpeeds
  ) external;

  function _setDistributionSpeeds(
    address[] memory _borrowiTokens,
    uint256[] memory _borrowSpeeds,
    address[] memory _supplyiTokens,
    uint256[] memory _supplySpeeds
  ) external;

  function _setDistributionSupplySpeeds(
    address[] memory _iTokens,
    uint256[] memory _supplySpeeds
  ) external;

  function _setPendingOwner(address newPendingOwner) external;

  function _setRewardToken(address _newRewardToken) external;

  function _unpause(
    address[] memory _borrowiTokens,
    uint256[] memory _borrowSpeeds,
    address[] memory _supplyiTokens,
    uint256[] memory _supplySpeeds
  ) external;

  function claimAllReward(address[] memory _holders) external;

  function claimReward(address[] memory _holders, address[] memory _iTokens)
  external;

  function claimRewards(
    address[] memory _holders,
    address[] memory _suppliediTokens,
    address[] memory _borrowediTokens
  ) external;

  function controller() external view returns (address);

  function distributionBorrowState(address)
  external
  view
  returns (uint256 index, uint256 _block);

  function distributionBorrowerIndex(address, address)
  external
  view
  returns (uint256);

  function distributionFactorMantissa(address)
  external
  view
  returns (uint256);

  function distributionSpeed(address) external view returns (uint256);

  function distributionSupplierIndex(address, address)
  external
  view
  returns (uint256);

  function distributionSupplySpeed(address) external view returns (uint256);

  function distributionSupplyState(address)
  external
  view
  returns (uint256 index, uint256 _block);

  function globalDistributionSpeed() external view returns (uint256);

  function globalDistributionSupplySpeed() external view returns (uint256);

  function initialize(address _controller) external;

  function owner() external view returns (address);

  function paused() external view returns (bool);

  function pendingOwner() external view returns (address);

  function reward(address) external view returns (uint256);

  function rewardToken() external view returns (address);

  function updateDistributionState(address _iToken, bool _isBorrow) external;

  function updateReward(
    address _iToken,
    address _account,
    bool _isBorrow
  ) external;

  function updateRewardBatch(
    address[] memory _holders,
    address[] memory _iTokens
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IDForcePriceOracle {
  event CappedPricePosted(
    address asset,
    uint256 requestedPriceMantissa,
    uint256 anchorPriceMantissa,
    uint256 cappedPriceMantissa
  );
  event Failure(uint256 error, uint256 info, uint256 detail);
  event NewAnchorAdmin(address oldAnchorAdmin, address newAnchorAdmin);
  event NewPendingAnchor(
    address anchorAdmin,
    address asset,
    uint256 oldScaledPrice,
    uint256 newScaledPrice
  );
  event NewPendingAnchorAdmin(
    address oldPendingAnchorAdmin,
    address newPendingAnchorAdmin
  );
  event NewPoster(address oldPoster, address newPoster);
  event OracleFailure(
    address msgSender,
    address asset,
    uint256 error,
    uint256 info,
    uint256 detail
  );
  event PricePosted(
    address asset,
    uint256 previousPriceMantissa,
    uint256 requestedPriceMantissa,
    uint256 newPriceMantissa
  );
  event ReaderPosted(
    address asset,
    address oldReader,
    address newReader,
    int256 decimalsDifference
  );
  event SetAssetAggregator(address asset, address aggregator);
  event SetAssetStatusOracle(address asset, address statusOracle);
  event SetExchangeRate(
    address asset,
    address exchangeRateModel,
    uint256 exchangeRate,
    uint256 maxSwingRate,
    uint256 maxSwingDuration
  );
  event SetMaxSwing(uint256 maxSwing);
  event SetMaxSwingForAsset(address asset, uint256 maxSwing);
  event SetMaxSwingRate(
    address asset,
    uint256 oldMaxSwingRate,
    uint256 newMaxSwingRate,
    uint256 maxSwingDuration
  );
  event SetPaused(bool newState);

  function MAXIMUM_SWING() external view returns (uint256);

  function MINIMUM_SWING() external view returns (uint256);

  function SECONDS_PER_WEEK() external view returns (uint256);

  function _acceptAnchorAdmin() external returns (uint256);

  function _assetPrices(address) external view returns (uint256 mantissa);

  function _disableAssetAggregator(address _asset) external returns (uint256);

  function _disableAssetAggregatorBatch(address[] memory _assets) external;

  function _disableAssetStatusOracle(address _asset)
  external
  returns (uint256);

  function _disableAssetStatusOracleBatch(address[] memory _assets) external;

  function _disableExchangeRate(address _asset) external returns (uint256);

  function _setAssetAggregator(address _asset, address _aggregator)
  external
  returns (uint256);

  function _setAssetAggregatorBatch(
    address[] memory _assets,
    address[] memory _aggregators
  ) external;

  function _setAssetStatusOracle(address _asset, address _statusOracle)
  external
  returns (uint256);

  function _setAssetStatusOracleBatch(
    address[] memory _assets,
    address[] memory _statusOracles
  ) external;

  function _setMaxSwing(uint256 _maxSwing) external returns (uint256);

  function _setMaxSwingForAsset(address _asset, uint256 _maxSwing)
  external
  returns (uint256);

  function _setMaxSwingForAssetBatch(
    address[] memory _assets,
    uint256[] memory _maxSwings
  ) external;

  function _setPaused(bool _requestedState) external returns (uint256);

  function _setPendingAnchor(address _asset, uint256 _newScaledPrice)
  external
  returns (uint256);

  function _setPendingAnchorAdmin(address _newPendingAnchorAdmin)
  external
  returns (uint256);

  function _setPoster(address _newPoster) external returns (uint256);

  function aggregator(address) external view returns (address);

  function anchorAdmin() external view returns (address);

  function anchors(address)
  external
  view
  returns (uint256 period, uint256 priceMantissa);

  function exchangeRates(address)
  external
  view
  returns (
    address exchangeRateModel,
    uint256 exchangeRate,
    uint256 maxSwingRate,
    uint256 maxSwingDuration
  );

  function getAssetAggregatorPrice(address _asset)
  external
  view
  returns (uint256);

  function getAssetPrice(address _asset) external view returns (uint256);

  function getAssetPriceStatus(address _asset) external view returns (bool);

  function getExchangeRateInfo(address _asset, uint256 _interval)
  external
  view
  returns (
    uint256,
    address,
    address,
    uint256,
    uint256,
    uint256
  );

  function getReaderPrice(address _asset) external view returns (uint256);

  function getUnderlyingPrice(address _asset) external view returns (uint256);

  function getUnderlyingPriceAndStatus(address _asset)
  external
  view
  returns (uint256, bool);

  function maxSwing() external view returns (uint256 mantissa);

  function maxSwingMantissa() external view returns (uint256);

  function maxSwings(address) external view returns (uint256 mantissa);

  function numBlocksPerPeriod() external view returns (uint256);

  function paused() external view returns (bool);

  function pendingAnchorAdmin() external view returns (address);

  function pendingAnchors(address) external view returns (uint256);

  function poster() external view returns (address);

  function readers(address)
  external
  view
  returns (address asset, int256 decimalsDifference);

  function setExchangeRate(
    address _asset,
    address _exchangeRateModel,
    uint256 _maxSwingDuration
  ) external returns (uint256);

  function setMaxSwingRate(address _asset, uint256 _maxSwingDuration)
  external
  returns (uint256);

  function setPrice(address _asset, uint256 _requestedPriceMantissa)
  external
  returns (uint256);

  function setPrices(
    address[] memory _assets,
    uint256[] memory _requestedPriceMantissas
  ) external returns (uint256[] memory);

  function setReaders(address _asset, address _readAsset)
  external
  returns (uint256);

  function statusOracle(address) external view returns (address);

  receive() external payable;
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
pragma solidity 0.8.4;

import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/Math.sol";
import "../interface/IStrategy.sol";
import "../governance/Controllable.sol";
import "../interface/IFeeRewardForwarder.sol";
import "../interface/IBookkeeper.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../third_party/uniswap/IUniswapV2Router02.sol";
import "../interface/ISmartVault.sol";

/// @title Abstract contract for base strategy functionality
/// @author belbix
abstract contract StrategyBase is IStrategy, Controllable {
  using SafeERC20 for IERC20;

  uint256 internal constant _BUY_BACK_DENOMINATOR = 100_00;
  uint256 internal constant _TOLERANCE_DENOMINATOR = 1000;
  uint256 internal constant _TOLERANCE_NUMERATOR = 999;

  //************************ VARIABLES **************************
  address internal _underlyingToken;
  address internal _smartVault;
  mapping(address => bool) internal _unsalvageableTokens;
  /// @dev Buyback numerator - reflects but does not guarantee that this percent of the profit will go to distribution
  uint256 internal _buyBackRatio;
  /// @dev When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.
  bool public override pausedInvesting = false;
  address[] internal _rewardTokens;


  //************************ MODIFIERS **************************

  /// @dev Only for linked Vault or Governance/Controller.
  ///      Use for functions that should have strict access.
  modifier restricted() {
    require(msg.sender == _smartVault
    || msg.sender == address(controller())
      || isGovernance(msg.sender),
      "SB: Not Gov or Vault");
    _;
  }

  /// @dev Extended strict access with including HardWorkers addresses
  ///      Use for functions that should be called by HardWorkers
  modifier hardWorkers() {
    require(msg.sender == _smartVault
    || msg.sender == address(controller())
    || IController(controller()).isHardWorker(msg.sender)
      || isGovernance(msg.sender),
      "SB: Not HW or Gov or Vault");
    _;
  }

  /// @dev This is only used in `investAllUnderlying()`
  ///      The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting, "SB: Paused");
    _;
  }

  /// @notice Contract constructor using on Base Strategy implementation
  /// @param _controller Controller address
  /// @param _underlying Underlying token address
  /// @param _vault SmartVault address that will provide liquidity
  /// @param __rewardTokens Reward tokens that the strategy will farm
  /// @param _bbRatio Buy back ratio
  constructor(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    uint256 _bbRatio
  ) {
    Controllable.initializeControllable(_controller);
    _underlyingToken = _underlying;
    _smartVault = _vault;
    _rewardTokens = __rewardTokens;
    require(_bbRatio <= _BUY_BACK_DENOMINATOR, "SB: Too high buyback ratio");
    _buyBackRatio = _bbRatio;

    // prohibit the movement of tokens that are used in the main logic
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _unsalvageableTokens[_rewardTokens[i]] = true;
    }
    _unsalvageableTokens[_underlying] = true;
  }

  // *************** VIEWS ****************

  /// @notice Reward tokens of external project
  /// @return Reward tokens array
  function rewardTokens() public view override returns (address[] memory) {
    return _rewardTokens;
  }

  /// @notice Strategy underlying, the same in the Vault
  /// @return Strategy underlying token
  function underlying() external view override returns (address) {
    return _underlyingToken;
  }

  /// @notice Underlying balance of this contract
  /// @return Balance of underlying token
  function underlyingBalance() public view override returns (uint256) {
    return IERC20(_underlyingToken).balanceOf(address(this));
  }

  /// @notice SmartVault address linked to this strategy
  /// @return Vault address
  function vault() external view override returns (address) {
    return _smartVault;
  }

  /// @notice Return true for tokens that governance can't touch
  /// @return True if given token unsalvageable
  function unsalvageableTokens(address token) external override view returns (bool) {
    return _unsalvageableTokens[token];
  }

  /// @notice Strategy buy back ratio. Currently stubbed to 100%
  /// @return Buy back ratio
  function buyBackRatio() external view override returns (uint256) {
    return _buyBackRatio;
  }

  /// @notice Balance of given token on this contract
  /// @return Balance of given token
  function rewardBalance(uint256 rewardTokenIdx) public view returns (uint256) {
    return IERC20(_rewardTokens[rewardTokenIdx]).balanceOf(address(this));
  }

  /// @notice Return underlying balance + balance in the reward pool
  /// @return Sum of underlying balances
  function investedUnderlyingBalance() external override view returns (uint256) {
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance() + underlyingBalance();
  }

  //******************** GOVERNANCE *******************


  /// @notice In case there are some issues discovered about the pool or underlying asset
  ///         Governance can exit the pool properly
  ///         The function is only used for emergency to exit the pool
  ///         Pause investing
  function emergencyExit() external override onlyControllerOrGovernance {
    emergencyExitRewardPool();
    pausedInvesting = true;
  }

  /// @notice Pause investing into the underlying reward pools
  function pauseInvesting() external override onlyControllerOrGovernance {
    pausedInvesting = true;
  }

  /// @notice Resumes the ability to invest into the underlying reward pools
  function continueInvesting() external override onlyControllerOrGovernance {
    pausedInvesting = false;
  }

  /// @notice Controller can claim coins that are somehow transferred into the contract
  ///         Note that they cannot come in take away coins that are used and defined in the strategy itself
  /// @param recipient Recipient address
  /// @param recipient Token address
  /// @param recipient Token amount
  function salvage(address recipient, address token, uint256 amount)
  external override onlyController {
    // To make sure that governance cannot come in and take away the coins
    require(!_unsalvageableTokens[token], "SB: Not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /// @notice Withdraws all the asset to the vault
  function withdrawAllToVault() external override hardWorkers {
    exitRewardPool();
    IERC20(_underlyingToken).safeTransfer(_smartVault, underlyingBalance());
  }

  /// @notice Withdraws some asset to the vault
  /// @param amount Asset amount
  function withdrawToVault(uint256 amount) external override hardWorkers {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    if (amount > underlyingBalance()) {
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount - underlyingBalance();
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      withdrawAndClaimFromPool(toWithdraw);
    }
    uint amountAdjusted = Math.min(amount, underlyingBalance());
    require(amountAdjusted > amount * toleranceNumerator() / _TOLERANCE_DENOMINATOR, "SB: Withdrew too low");
    IERC20(_underlyingToken).safeTransfer(_smartVault, amountAdjusted);
  }

  /// @notice Stakes everything the strategy holds into the reward pool
  function investAllUnderlying() public override hardWorkers onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if (underlyingBalance() > 0) {
      depositToPool(underlyingBalance());
    }
  }

  // ***************** INTERNAL ************************

  /// @dev Tolerance to difference between asked and received values on user withdraw action
  ///      Where 0 is full tolerance, and range of 1-999 means how many % of tokens do you expect as minimum
  function toleranceNumerator() internal pure virtual returns (uint){
    return _TOLERANCE_NUMERATOR;
  }

  /// @dev Withdraw everything from external pool
  function exitRewardPool() internal virtual {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      withdrawAndClaimFromPool(bal);
    }
  }

  /// @dev Withdraw everything from external pool without caring about rewards
  function emergencyExitRewardPool() internal {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      emergencyWithdrawFromPool();
    }
  }

  /// @dev Default implementation of liquidation process
  ///      Send all profit to FeeRewardForwarder
  function liquidateRewardDefault() internal {
    _liquidateReward(true);
  }

  function liquidateRewardSilently() internal {
    _liquidateReward(false);
  }

  function _liquidateReward(bool revertOnErrors) internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    uint targetTokenEarnedTotal = 0;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, amount);
        // it will sell reward token to Target Token and distribute it to SmartVault and PS
        uint256 targetTokenEarned = 0;
        if (revertOnErrors) {
          targetTokenEarned = IFeeRewardForwarder(forwarder).distribute(amount, rt, _smartVault);
        } else {
          //slither-disable-next-line unused-return,variable-scope,uninitialized-local
          try IFeeRewardForwarder(forwarder).distribute(amount, rt, _smartVault) returns (uint r) {
            targetTokenEarned = r;
          } catch {}
        }
        targetTokenEarnedTotal += targetTokenEarned;
      }
    }
    if (targetTokenEarnedTotal > 0) {
      IBookkeeper(IController(controller()).bookkeeper()).registerStrategyEarned(targetTokenEarnedTotal);
    }
  }

  /// @dev Liquidate rewards and buy underlying asset
  function autocompound() internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio) / _BUY_BACK_DENOMINATOR;
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);
        IFeeRewardForwarder(forwarder).liquidate(rt, _underlyingToken, toCompound);
      }
    }
  }

  /// @dev Default implementation of auto-compounding for swap pairs
  ///      Liquidate rewards, buy assets and add to liquidity pool
  function autocompoundLP(address _router) internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio) / _BUY_BACK_DENOMINATOR;
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);

        IUniswapV2Pair pair = IUniswapV2Pair(_underlyingToken);
        if (rt != pair.token0()) {
          uint256 token0Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token0(), toCompound / 2);
          require(token0Amount != 0, "SB: Token0 zero amount");
        }
        if (rt != pair.token1()) {
          uint256 token1Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token1(), toCompound / 2);
          require(token1Amount != 0, "SB: Token1 zero amount");
        }
        addLiquidity(_underlyingToken, _router);
      }
    }
  }

  /// @dev Add all available tokens to given pair
  function addLiquidity(address _pair, address _router) internal {
    IUniswapV2Router02 router = IUniswapV2Router02(_router);
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    address _token0 = pair.token0();
    address _token1 = pair.token1();

    uint256 amount0 = IERC20(_token0).balanceOf(address(this));
    uint256 amount1 = IERC20(_token1).balanceOf(address(this));

    IERC20(_token0).safeApprove(_router, 0);
    IERC20(_token0).safeApprove(_router, amount0);
    IERC20(_token1).safeApprove(_router, 0);
    IERC20(_token1).safeApprove(_router, amount1);
    //slither-disable-next-line unused-return
    router.addLiquidity(
      _token0,
      _token1,
      amount0,
      amount1,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  //******************** VIRTUAL *********************
  // This functions should be implemented in the strategy contract

  function rewardPoolBalance() public virtual override view returns (uint256 bal);

  //slither-disable-next-line dead-code
  function depositToPool(uint256 amount) internal virtual;

  //slither-disable-next-line dead-code
  function withdrawAndClaimFromPool(uint256 amount) internal virtual;

  //slither-disable-next-line dead-code
  function emergencyWithdrawFromPool() internal virtual;

  //slither-disable-next-line dead-code
  function liquidateReward() internal virtual;

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

pragma solidity 0.8.4;

interface ISmartVault {

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account)
  external
  view
  returns (uint256);

  function earnedWithBoost(address rt, address account)
  external
  view
  returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt)
  external
  view
  returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(
    address _rewardToken,
    uint256 _amount
  ) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount)
  external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address)
  external
  view
  returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder)
  external
  view
  returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address)
  external
  view
  returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20Extended {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);


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

pragma solidity 0.8.4;

interface IFoldStrategy {

  function borrowTargetFactorNumeratorStored() external view returns (uint);

  function borrowTargetFactorNumerator() external view returns (uint);

  function collateralFactorNumerator() external view returns (uint);

  function fold() external view returns (bool);

  function foldState() external view returns (uint);

  function suppliedInUnderlying() external view returns (uint);

  function borrowedInUnderlying() external view returns (uint);

  function isFoldingProfitable() external view returns (bool);

  function setFold(uint value) external;

  function rebalance() external;

  function setBorrowTargetFactorNumeratorStored(uint value) external;

  function stopFolding() external;

  function startFolding() external;

  function setCollateralFactorNumerator(uint value) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
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
    return a / b + (a % b == 0 ? 0 : 1);
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

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT, //26
    BEETHOVEN, //27
    IMPERMAX, //28
    TETU_SF, //29
    ALPACA, //30
    MARKET, //31
    UNIVERSE, //32
    MAI_BAL, //33
    UMA, //34
    SPHERE, //35
    BALANCER, //36
    OTTERCLAM, //37
    MESH, //38
    SLOT_39, //39
    SLOT_40, //40
    SLOT_41, //41
    SLOT_42, //42
    SLOT_43, //43
    SLOT_44, //44
    SLOT_45, //45
    SLOT_46, //46
    SLOT_47, //47
    SLOT_48, //48
    SLOT_49, //49
    SLOT_50 //50
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
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

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
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

pragma solidity 0.8.4;

interface IFeeRewardForwarder {

  function DEFAULT_UNI_FEE_DENOMINATOR() external view returns (uint256);

  function DEFAULT_UNI_FEE_NUMERATOR() external view returns (uint256);

  function LIQUIDITY_DENOMINATOR() external view returns (uint256);

  function MINIMUM_AMOUNT() external view returns (uint256);

  function ROUTE_LENGTH_MAX() external view returns (uint256);

  function SLIPPAGE_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function liquidityRouter() external view returns (address);

  function liquidityNumerator() external view returns (uint);

  function addBlueChipsLps(address[] memory _lps) external;

  function addLargestLps(address[] memory _tokens, address[] memory _lps)
  external;

  function blueChipsTokens(address) external view returns (bool);

  function distribute(
    uint256 _amount,
    address _token,
    address _vault
  ) external returns (uint256);

  function fund() external view returns (address);

  function fundToken() external view returns (address);

  function getBalData()
  external
  view
  returns (
    address balToken,
    address vault,
    bytes32 pool,
    address tokenOut
  );

  function initialize(address _controller) external;

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external returns (uint256);

  function notifyCustomPool(
    address,
    address,
    uint256
  ) external pure returns (uint256);

  function notifyPsPool(address, uint256) external pure returns (uint256);

  function psVault() external view returns (address);

  function setBalData(
    address balToken,
    address vault,
    bytes32 pool,
    address tokenOut
  ) external;

  function setLiquidityNumerator(uint256 _value) external;

  function setLiquidityRouter(address _value) external;

  function setSlippageNumerator(uint256 _value) external;

  function setUniPlatformFee(
    address _factory,
    uint256 _feeNumerator,
    uint256 _feeDenominator
  ) external;

  function slippageNumerator() external view returns (uint256);

  function tetu() external view returns (address);

  function uniPlatformFee(address)
  external
  view
  returns (uint256 numerator, uint256 denominator);

  function largestLps(address _token) external view returns (
    address lp,
    address token,
    address oppositeToken
  );

  function blueChipsLps(address _token0, address _token1) external view returns (
    address lp,
    address token,
    address oppositeToken
  );
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

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

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
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
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

pragma solidity 0.8.4;

interface IController {


  function VERSION() external view returns (string memory);

  function addHardWorker(address _worker) external;

  function addStrategiesToSplitter(
    address _splitter,
    address[] memory _strategies
  ) external;

  function addStrategy(address _strategy) external;

  function addVaultsAndStrategies(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function announcer() external view returns (address);

  function bookkeeper() external view returns (address);

  function changeWhiteListStatus(address[] memory _targets, bool status)
  external;

  function controllerTokenMove(
    address _recipient,
    address _token,
    uint256 _amount
  ) external;

  function dao() external view returns (address);

  function distributor() external view returns (address);

  function doHardWork(address _vault) external;

  function feeRewardForwarder() external view returns (address);

  function fund() external view returns (address);

  function fundDenominator() external view returns (uint256);

  function fundKeeperTokenMove(
    address _fund,
    address _token,
    uint256 _amount
  ) external;

  function fundNumerator() external view returns (uint256);

  function fundToken() external view returns (address);

  function governance() external view returns (address);

  function hardWorkers(address) external view returns (bool);

  function initialize() external;

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function mintAndDistribute(uint256 totalAmount, bool mintAllAvailable)
  external;

  function mintHelper() external view returns (address);

  function psDenominator() external view returns (uint256);

  function psNumerator() external view returns (uint256);

  function psVault() external view returns (address);

  function pureRewardConsumers(address) external view returns (bool);

  function rebalance(address _strategy) external;

  function removeHardWorker(address _worker) external;

  function rewardDistribution(address) external view returns (bool);

  function rewardToken() external view returns (address);

  function setAnnouncer(address _newValue) external;

  function setBookkeeper(address newValue) external;

  function setDao(address newValue) external;

  function setDistributor(address _distributor) external;

  function setFeeRewardForwarder(address _feeRewardForwarder) external;

  function setFund(address _newValue) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setFundToken(address _newValue) external;

  function setGovernance(address newValue) external;

  function setMintHelper(address _newValue) external;

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setPsVault(address _newValue) external;

  function setPureRewardConsumers(address[] memory _targets, bool _flag)
  external;

  function setRewardDistribution(
    address[] memory _newRewardDistribution,
    bool _flag
  ) external;

  function setRewardToken(address _newValue) external;

  function setVaultController(address _newValue) external;

  function setVaultStrategyBatch(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function strategies(address) external view returns (bool);

  function strategyTokenMove(
    address _strategy,
    address _token,
    uint256 _amount
  ) external;

  function upgradeTetuProxyBatch(
    address[] memory _contracts,
    address[] memory _implementations
  ) external;

  function vaultController() external view returns (address);

  function vaults(address) external view returns (bool);

  function whiteList(address) external view returns (bool);
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

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}