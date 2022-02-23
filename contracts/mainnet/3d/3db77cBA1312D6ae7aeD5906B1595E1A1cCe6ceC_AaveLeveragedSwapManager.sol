//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFlashLoanReceiver.sol";
import "./interfaces/ILendingPool.sol";
import "./AaveLeveragedSwapBase.sol";
import "./utils/PercentageMath.sol";
import "./utils/WadRayMath.sol";
import "./utils/Errors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract AaveLeveragedSwapManager is
  IFlashLoanReceiver,
  ReentrancyGuard,
  Initializable,
  AaveLeveragedSwapBase
{
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableMap for EnumerableMap.AddressToUintsMap;

  function initialize(
    address _addressProvider,
    address _sushiRouter,
    address _nativeETH
  ) external initializer {
    ADDRESSES_PROVIDER = ILendingPoolAddressesProvider(_addressProvider);
    LENDING_POOL = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    DATA_PROVIDER = IProtocolDataProvider(
      ADDRESSES_PROVIDER.getAddress(PROTOCOL_DATA_PROVIDER_ID)
    );
    PRICE_ORACLE = IPriceOracleGetter(ADDRESSES_PROVIDER.getPriceOracle());
    SUSHI_ROUTER = IUniswapV2Router02(_sushiRouter);
    NATIVE_ETH = _nativeETH;
  }

  /**
   * @dev execute a leveraged swap. If fee wasn't sent in, it will be deducted from collaterals
   * @param _targetToken The token that will be borrowed
   * @param _targetAmount The amount of the token
   * @param _pairToken The token that will be swapped to and deposited
   * @param _rateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param _slippage The max slippage allowed during swap
   */
  function swapPreapprovedAssets(
    TokenInfo memory _targetToken,
    uint _targetAmount,
    TokenInfo memory _pairToken,
    uint _rateMode,
    uint _slippage
  ) external payable override nonReentrant {
    vars.user = msg.sender;
    vars.targetToken = _targetToken;
    vars.targetTokenAmount = _targetAmount;
    vars.pairToken = _pairToken;
    vars.borrowRateMode = _rateMode;
    vars.slippage = _slippage;

    SwapVars memory swapVars = checkAndCalculateSwapVars(
      _targetToken,
      _targetAmount,
      _pairToken,
      _slippage,
      msg.value == 0
    );
    require(
      swapVars.loanETH <= swapVars.maxLoanETH,
      Errors.LEVERAGE_COLLATERAL_NOT_ENOUGH
    );

    vars.loanETH = swapVars.loanETH;
    vars.feeETH = swapVars.feeETH;

    uint flashLoanETH = swapVars.flashLoanETH;
    if (msg.value > 0) {
      // uses the native token sent to pay the fees
      _ensureValueSentCanCoverFees(msg.value);
    }
    // calculates the amount we need to flash loan in pairToken
    vars.pairTokenAmount = convertEthToTokenAmount(
      flashLoanETH,
      vars.pairToken
    );

    _doFlashLoan(_pairToken.tokenAddress, vars.pairTokenAmount);

    cleanUpAfterSwap();
  }

  /**
   * @dev deleverage caller's debt position by repaying debt from collaterals. If fee wasn't sent in, it will be deducted from collaterals
   * @param _collaterals The list of collaterals in caller's portfolio
   * @param _collateralAmounts The list of collateral amounts that will be reduced
   * @param _targetToken The token that will be repayed
   * @param _targetAmount The amount of token that will be repayed
   * @param _rateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param _slippage The max slippage allowed during swap
   */
  function repayDebt(
    TokenInfo[] calldata _collaterals,
    uint256[] calldata _collateralAmounts,
    TokenInfo memory _targetToken,
    uint _targetAmount,
    uint _rateMode,
    uint _slippage
  ) external payable override nonReentrant {
    // Intuitively, deleveraging can be realized by withdrawing user's collaterals
    // and repaying her debt positions. However, Aave protocol doesn't allow
    // contract to withdraw on behalf of user. So our strategy still relies on
    // using flash loan to pay down user's debt, then transferring her aTokens
    // to contract for repaying the loan.
    vars.user = msg.sender;
    vars.targetToken = _targetToken;
    vars.targetTokenAmount = _targetAmount;
    vars.borrowRateMode = _rateMode;
    vars.slippage = _slippage;

    // calcuates how much of collaterals we can reduce
    RepayVars memory repayVars = checkAndCalculateRepayVars(
      _collaterals,
      _collateralAmounts,
      _targetToken,
      _targetAmount,
      _rateMode,
      _slippage,
      msg.value == 0
    );

    require(
      repayVars.totalCollateralReducedETH >= repayVars.loanETH,
      Errors.DELEVERAGE_REDUCED_ASSET_NOT_ENOUGH
    );
    require(
      repayVars.expectedHealthFactor > WadRayMath.WAD,
      Errors.DELEVERAGE_HEALTH_FACTOR_BELOW_ONE
    );

    uint[] memory reducedCollateralValues = repayVars.reducedCollateralValues;
    vars.feeETH = repayVars.feeETH;

    // make sure we have a clean map
    assert(assetMap.length() == 0);
    for (uint i = 0; i < _collaterals.length; i++) {
      uint[2] memory values = [
        _collateralAmounts[i],
        reducedCollateralValues[i]
      ];
      require(
        assetMap.set(_collaterals[i].tokenAddress, values),
        Errors.DELEVERAGE_DUPLICATE_ASSET_ENTRY
      );
    }

    if (msg.value > 0) {
      // uses the native token sent in to pay the fees
      _ensureValueSentCanCoverFees(msg.value);
    }

    _doFlashLoan(_targetToken.tokenAddress, _targetAmount);

    cleanUpAfterSwap();
  }

  /**
   * This function is called after your contract has received the flash loaned amount.
   * So it allows reentrancy by design. You need to make sure the LendingPool calling
   * it behaves faithfully.
   */
  function executeOperation(
    address[] calldata _assets,
    uint256[] calldata _amounts,
    uint256[] calldata _premiums,
    address _initiator,
    bytes calldata // params
  ) external override onlyLendingPool returns (bool) {
    // ensures this function is indeed called by the lending pool with
    // correct arguments.
    assert(_assets.length == 1 && _initiator == address(this));
    if (_assets[0] == vars.pairToken.tokenAddress) {
      assert(_amounts[0] == vars.pairTokenAmount);
      return _handleLeverage(vars.pairToken, _amounts[0], _premiums[0]);
    } else {
      assert(
        _assets[0] == vars.targetToken.tokenAddress &&
          _amounts[0] == vars.targetTokenAmount
      );
      return _handleDeleverage(vars.targetToken, _amounts[0], _premiums[0]);
    }
  }

  fallback() external {
    revert(Errors.CONTRACT_FALLBACK_NOT_ALLOWED);
  }

  function _ensureValueSentCanCoverFees(uint _value) private {
    // converts the native token value to ETH
    // factors in the swap slippage and
    uint wethAmount = PRICE_ORACLE.getAssetPrice(NATIVE_ETH).wadMul(_value);
    // verifies that its value is enough to cover the fees
    require(wethAmount >= vars.feeETH, Errors.OPS_FLASH_LOAN_FEE_NOT_ENOUGH);
    vars.feeTokenAmount = _value;
  }

  function _doFlashLoan(address _asset, uint _amount) private {
    address[] memory flashLoanAssets = new address[](1);
    flashLoanAssets[0] = _asset;
    uint[] memory flashLoanAmounts = new uint[](1);
    flashLoanAmounts[0] = _amount;
    uint[] memory flashLoanModes = new uint[](1);
    flashLoanModes[0] = 0; // 0 = no debt
    LENDING_POOL.flashLoan(
      address(this), // receiverAddress
      flashLoanAssets,
      flashLoanAmounts,
      flashLoanModes,
      address(this), // onBehalfOf
      bytes(""), // params
      0 // referralCode
    );
  }

  function _handleLeverage(
    TokenInfo memory _pairToken,
    uint _pairTokenAmount,
    uint _premium
  ) private returns (bool) {
    // deposits the flash loan to increase user's collateral
    IERC20(_pairToken.tokenAddress).safeApprove(
      address(LENDING_POOL),
      _pairTokenAmount.wadToDecimals(_pairToken.decimals)
    );
    LENDING_POOL.deposit(
      _pairToken.tokenAddress,
      _pairTokenAmount,
      vars.user, /*onBehalfOf*/
      0 /*referralCode*/
    );

    // borrows targetToken and sends the amount to this contract,
    // with the debt being incurred by user.
    // user has to delegate vars.targetTokenAmount of targetToken credit
    // to this contract in advance
    try
      LENDING_POOL.borrow(
        vars.targetToken.tokenAddress,
        vars.targetTokenAmount,
        vars.borrowRateMode,
        0, /*referralCode*/
        vars.user /*debt incurred to*/
      )
    {} catch Error(
      string memory /*reason*/
    ) {
      revert(Errors.LEVERAGE_USER_DID_NOT_DELEGATE_BORROW);
    }

    // swaps the borrowed targetToken to pay for flash loan
    uint pairTokenAmount = approveAndSwapExactTokensForTokens(
      vars.targetToken,
      vars.targetTokenAmount,
      vars.pairToken,
      convertEthToTokenAmount(
        vars.loanETH.percentMul(
          PercentageMath.PERCENTAGE_FACTOR - vars.slippage
        ),
        vars.pairToken
      ),
      address(this) /*onBehalfOf*/
    );

    if (vars.feeTokenAmount > 0) {
      // user uses wethToken to cover the fees
      // swap native eth to pay fees
      pairTokenAmount += swapExactETHForTokens(
        vars.feeTokenAmount,
        vars.pairToken,
        convertEthToTokenAmount(vars.feeETH, vars.pairToken).percentMul(
          PercentageMath.PERCENTAGE_FACTOR - vars.slippage
        ),
        address(this) /*onBehalfOf*/
      );
    }

    uint amountOwing = _pairTokenAmount + _premium;
    assert(pairTokenAmount >= amountOwing);
    uint remainPairTokenAmount;
    unchecked {
      remainPairTokenAmount = pairTokenAmount - amountOwing;
    }

    // approves the LendingPool contract allowance to *pull* the owed amount
    IERC20(_pairToken.tokenAddress).safeApprove(
      address(LENDING_POOL),
      amountOwing.wadToDecimals(_pairToken.decimals)
    );

    // transfers the remaining pairToken to the user's account if there is any
    IERC20(_pairToken.tokenAddress).safeTransfer(
      vars.user,
      remainPairTokenAmount.wadToDecimals(_pairToken.decimals)
    );

    emit Leverage(
      vars.targetToken.tokenAddress,
      _pairToken.tokenAddress,
      vars.user,
      vars.targetTokenAmount,
      vars.borrowRateMode,
      vars.slippage,
      remainPairTokenAmount
    );

    return true;
  }

  function _handleDeleverage(
    TokenInfo memory _targetToken,
    uint _targetAmount,
    uint _premium
  ) private returns (bool) {
    // repays the user's debt with the flash loaned targetToken
    IERC20(_targetToken.tokenAddress).safeApprove(
      address(LENDING_POOL),
      _targetAmount.wadToDecimals(_targetToken.decimals)
    );
    LENDING_POOL.repay(
      _targetToken.tokenAddress,
      _targetAmount,
      vars.borrowRateMode,
      vars.user /*onBehalfOf*/
    );

    uint targetTokenAmountConverted;
    // depends on caller to check there's no duplicate entries
    for (uint i = 0; i < assetMap.length(); i++) {
      (address asset, uint[2] memory values) = assetMap.at(i);
      TokenInfo memory assetInfo = getTokenInfo(asset);

      // transfers aToken to this contract for withdraw
      transferUserATokenToContract(
        assetInfo,
        values[0], /*asset amount*/
        vars.user
      );

      // withdraws the asset to this contract
      LENDING_POOL.withdraw(
        asset,
        values[0],
        address(this) /*to address*/
      );

      // swaps the asset to targetToken
      targetTokenAmountConverted += approveAndSwapExactTokensForTokens(
        assetInfo,
        values[0],
        vars.targetToken,
        convertEthToTokenAmount(
          values[1], /*asset value ETH*/
          vars.targetToken
        ).percentMul(PercentageMath.PERCENTAGE_FACTOR - vars.slippage),
        address(this) /*onBehalfOf*/
      );
    }

    if (vars.feeTokenAmount > 0) {
      // swap native eth to pay fees
      targetTokenAmountConverted += swapExactETHForTokens(
        vars.feeTokenAmount,
        vars.targetToken,
        convertEthToTokenAmount(vars.feeETH, vars.targetToken).percentMul(
          PercentageMath.PERCENTAGE_FACTOR - vars.slippage
        ),
        address(this) /*onBehalfOf*/
      );
    }

    uint amountOwing = _targetAmount + _premium;
    assert(targetTokenAmountConverted >= amountOwing);
    uint remainingTargetToken;
    unchecked {
      remainingTargetToken = targetTokenAmountConverted - amountOwing;
    }
    // Approve the LendingPool contract allowance to *pull* the owed amount
    IERC20(_targetToken.tokenAddress).safeApprove(
      address(LENDING_POOL),
      amountOwing.wadToDecimals(_targetToken.decimals)
    );

    // transfer the remaining to user if there's any
    IERC20(_targetToken.tokenAddress).safeTransfer(
      vars.user,
      remainingTargetToken.wadToDecimals(_targetToken.decimals)
    );

    emit Deleverage(
      _targetToken.tokenAddress,
      vars.user,
      _targetAmount,
      vars.borrowRateMode,
      vars.slippage,
      remainingTargetToken
    );

    return true;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external;

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(
    address reserve,
    address rateStrategyAddress
  ) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider()
    external
    view
    returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAaveLeveragedSwapManager.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWeth.sol";
import "./utils/EnumerableMap.sol";
import "./utils/PercentageMath.sol";
import "./utils/WadRayMath.sol";
import "./utils/Errors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract AaveLeveragedSwapBase is IAaveLeveragedSwapManager {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableMap for EnumerableMap.AddressToUintsMap;

  struct FlashLoanVars {
    uint targetTokenAmount;
    uint pairTokenAmount; // leverage only
    uint feeTokenAmount;
    uint loanETH; // leverage only
    uint feeETH;
    uint slippage;
    uint borrowRateMode;
    TokenInfo targetToken;
    TokenInfo pairToken; // leverage only
    address user;
  }

  struct SwapVars {
    uint loanETH;
    uint maxLoanETH;
    uint feeETH;
    uint flashLoanETH;
    uint currentHealthFactor;
    uint expectedHealthFactor;
  }

  struct RepayVars {
    uint loanETH;
    uint feeETH;
    uint totalCollateralReducedETH;
    uint flashLoanETH;
    uint currentHealthFactor;
    uint expectedHealthFactor;
    uint[] reducedCollateralValues;
  }

  uint public constant FLASH_LOAN_FEE_RATE = 9; // 0.09%
  bytes32 public constant PROTOCOL_DATA_PROVIDER_ID = bytes32(uint(1)) << 248; // 0x01

  ILendingPoolAddressesProvider ADDRESSES_PROVIDER;
  ILendingPool LENDING_POOL;
  IProtocolDataProvider DATA_PROVIDER;
  IPriceOracleGetter PRICE_ORACLE;
  IUniswapV2Router02 SUSHI_ROUTER;
  address NATIVE_ETH;

  EnumerableMap.AddressToUintsMap assetMap; // tokens to tokenValueETH map
  FlashLoanVars public vars;

  modifier onlyLendingPool() {
    require(
      msg.sender == address(LENDING_POOL),
      Errors.CONTRACT_ONLY_CALLED_BY_LENDING_POOL
    );
    _;
  }

  function getAssetPositions()
    external
    view
    override
    returns (Position[] memory positions)
  {
    IProtocolDataProvider.TokenData[] memory tokenList = DATA_PROVIDER
      .getAllReservesTokens();
    positions = new Position[](tokenList.length);
    for (uint i = 0; i < tokenList.length; i++) {
      TokenInfo memory tokenInfo = getTokenInfo(tokenList[i].tokenAddress);

      (
        uint aTokenBalance,
        uint stableDebt,
        uint variableDebt,
        uint principalStableDebt,
        uint scaledVariableDebt,
        ,
        ,
        ,
        bool usedAsCollateral
      ) = DATA_PROVIDER.getUserReserveData(
          tokenList[i].tokenAddress,
          msg.sender
        );

      positions[i] = Position(
        tokenList[i].symbol,
        tokenList[i].tokenAddress,
        aTokenBalance,
        stableDebt,
        variableDebt,
        principalStableDebt,
        scaledVariableDebt,
        usedAsCollateral,
        tokenInfo.borrowable,
        tokenInfo.canBeCollateral,
        tokenInfo.stableBorrowRateEnabled
      );
    }
  }

  /**
   * @dev calculate swap variables and do sanity check
   */
  function checkAndCalculateSwapVars(
    TokenInfo memory _targetToken,
    uint _targetTokenAmount,
    TokenInfo memory _pairToken,
    uint _slippage,
    bool _feePaidByCollateral
  ) public view returns (SwapVars memory swapVars) {
    // pairToken should be able to use as collateral
    require(
      _pairToken.canBeCollateral,
      Errors.LEVERAGE_PAIR_TOKEN_NOT_COLLATERABLE
    );
    uint totalCollateralETH;
    uint currentLiquidationThreshold;
    uint userAvailableBorrowsETH;
    uint existDebtETH;
    (
      totalCollateralETH,
      existDebtETH,
      userAvailableBorrowsETH,
      currentLiquidationThreshold,
      ,
      swapVars.currentHealthFactor
    ) = LENDING_POOL.getUserAccountData(msg.sender);

    // targetToken should be borrowable
    require(
      _targetToken.borrowable,
      Errors.LEVERAGE_TARGET_TOKEN_NOT_BORROWABLE
    );

    // calculate the amount in ETH we need to borrow for targetToken
    swapVars.loanETH = PRICE_ORACLE
      .getAssetPrice(_targetToken.tokenAddress)
      .wadMul(_targetTokenAmount);

    swapVars.flashLoanETH = swapVars.loanETH.percentMul(
      PercentageMath.PERCENTAGE_FACTOR - _slippage
    );

    // calculates max loanable after depositing back
    // for details refer to math.md
    uint tempTerm1 = PercentageMath.PERCENTAGE_FACTOR -
      _pairToken.ltv.percentMul(PercentageMath.PERCENTAGE_FACTOR - _slippage);
    if (_feePaidByCollateral) {
      uint tempTerm2 = PercentageMath.PERCENTAGE_FACTOR + FLASH_LOAN_FEE_RATE;
      swapVars.flashLoanETH = swapVars.flashLoanETH.percentDiv(tempTerm2);
      tempTerm1 += FLASH_LOAN_FEE_RATE;
      swapVars.maxLoanETH = userAvailableBorrowsETH
        .percentMul(tempTerm2)
        .percentDiv(tempTerm1);
    } else {
      swapVars.maxLoanETH = userAvailableBorrowsETH.percentDiv(tempTerm1);
    }

    swapVars.feeETH = swapVars.flashLoanETH.percentMul(FLASH_LOAN_FEE_RATE);
    if (!_feePaidByCollateral) {
      // consider the slippage
      swapVars.feeETH = swapVars.feeETH.percentDiv(
        PercentageMath.PERCENTAGE_FACTOR - _slippage
      );
    }
    uint newCollateral = swapVars.flashLoanETH.percentMul(
      _pairToken.liquidationThreshold
    ) + totalCollateralETH.percentMul(currentLiquidationThreshold);
    uint newDebt = existDebtETH + swapVars.loanETH;
    swapVars.expectedHealthFactor = newDebt == 0
      ? type(uint).max
      : newCollateral.wadDiv(newDebt);
  }

  /**
   * @dev calculate repay variables and do sanity check
   */
  function checkAndCalculateRepayVars(
    TokenInfo[] memory _assets,
    uint[] memory _amounts,
    TokenInfo memory _targetToken,
    uint _targetAmount,
    uint _rateMode,
    uint _slippage,
    bool _feePaidByCollateral
  ) public view returns (RepayVars memory repayVars) {
    repayVars.flashLoanETH = _tryGetUserDebtPosition(
      _targetToken,
      _targetAmount,
      _rateMode,
      msg.sender
    );
    uint totalCollateralETH;
    uint currentLiquidationThreshold;
    uint existDebtETH;
    (
      totalCollateralETH,
      existDebtETH,
      ,
      currentLiquidationThreshold,
      ,
      repayVars.currentHealthFactor
    ) = LENDING_POOL.getUserAccountData(msg.sender);

    require(
      _assets.length == _amounts.length,
      Errors.DELEVERAGE_MISMATCHED_ASSETS_AND_AMOUNTS
    );
    repayVars.reducedCollateralValues = new uint[](_assets.length);

    totalCollateralETH = totalCollateralETH.percentMul(
      currentLiquidationThreshold
    );
    // depends on caller to ensure no duplicate entries
    for (uint i = 0; i < _assets.length; i++) {
      (
        uint tokenValueETH,
        bool userUsedAsCollateralEnabled
      ) = _tryGetUserTokenETH(_assets[i], _amounts[i], msg.sender);
      require(
        userUsedAsCollateralEnabled && _assets[i].canBeCollateral,
        Errors.DELEVERAGE_ASSET_TOKEN_CANNOT_BE_COLLATERAL
      );
      repayVars.reducedCollateralValues[i] = tokenValueETH;
      repayVars.totalCollateralReducedETH += tokenValueETH;
      // reuse local variable to avoid stack too deep
      tokenValueETH = tokenValueETH.percentMul(_assets[i].liquidationThreshold);
      // this is possible as (totalCollateralETH * currentLiquidationThreshold)
      // can be a little less than the sum of (tokenValueETH * liquidationThreshold),
      // although totalCollateralETH = sum(tokenValueETH)
      require(
        totalCollateralETH > tokenValueETH,
        Errors.DELEVERAGE_REDUCED_ASSET_EXCCEED_NEEDED
      );
      unchecked {
        totalCollateralETH -= tokenValueETH;
      }
    }
    repayVars.feeETH = repayVars.flashLoanETH.percentMul(FLASH_LOAN_FEE_RATE);
    if (_feePaidByCollateral) {
      repayVars.loanETH = repayVars.flashLoanETH + repayVars.feeETH;
    } else {
      repayVars.loanETH = repayVars.flashLoanETH;
      repayVars.feeETH = repayVars.feeETH.percentDiv(
        PercentageMath.PERCENTAGE_FACTOR - _slippage
      );
    }
    // consider the slippage
    repayVars.loanETH = repayVars.loanETH.percentDiv(
      PercentageMath.PERCENTAGE_FACTOR - _slippage
    );

    if (existDebtETH <= repayVars.flashLoanETH) {
      // user's debt is cleared
      repayVars.expectedHealthFactor = type(uint).max;
    } else {
      unchecked {
        repayVars.expectedHealthFactor = totalCollateralETH.wadDiv(
          existDebtETH - repayVars.flashLoanETH
        );
      }
    }
  }

  function getTokenInfo(address _token)
    public
    view
    returns (TokenInfo memory tokenInfo)
  {
    tokenInfo.tokenAddress = _token;
    bool isActive;
    bool isFrozen;
    (
      tokenInfo.decimals,
      tokenInfo.ltv,
      tokenInfo.liquidationThreshold,
      ,
      ,
      tokenInfo.canBeCollateral,
      tokenInfo.borrowable,
      tokenInfo.stableBorrowRateEnabled,
      isActive,
      isFrozen
    ) = DATA_PROVIDER.getReserveConfigurationData(_token);
    tokenInfo.canBeCollateral =
      tokenInfo.canBeCollateral &&
      (isActive && !isFrozen);
    tokenInfo.borrowable = tokenInfo.borrowable && (isActive && !isFrozen);
  }

  function _tryGetUserTokenETH(
    TokenInfo memory _token,
    uint _amount,
    address _user
  )
    private
    view
    returns (uint tokenValueETH, bool userUsedAsCollateralEnabled)
  {
    uint aTokenBalance;
    (aTokenBalance, , , , , , , , userUsedAsCollateralEnabled) = DATA_PROVIDER
      .getUserReserveData(_token.tokenAddress, _user);
    require(
      aTokenBalance >= _amount,
      Errors.DELEVERAGE_ATOKEN_SPECIFIED_EXCEEDS_OWNED
    );
    tokenValueETH = PRICE_ORACLE.getAssetPrice(_token.tokenAddress).wadMul(
      _amount
    );
  }

  function _tryGetUserDebtPosition(
    TokenInfo memory _targetToken,
    uint _targetTokenAmount,
    uint _borrowRateMode,
    address _user
  ) private view returns (uint) {
    (, uint stableDebt, uint variableDebt, , , , , , ) = DATA_PROVIDER
      .getUserReserveData(_targetToken.tokenAddress, _user);
    if (_borrowRateMode == 1) {
      // stable debt
      require(
        _targetTokenAmount <= stableDebt,
        Errors.DELEVERAGE_STABLE_DEBT_SPECIFIED_EXCEEDS_OWNED
      );
    } else if (_borrowRateMode == 2) {
      // variable debt
      require(
        _targetTokenAmount <= variableDebt,
        Errors.DELEVERAGE_VARIABLE_DEBT_SPECIFIED_EXCEEDS_OWNED
      );
    } else {
      revert("Invalid borrow rate mode!");
    }
    return
      PRICE_ORACLE.getAssetPrice(_targetToken.tokenAddress).wadMul(
        _targetTokenAmount
      );
  }

  function _getSushiSwapTokenPath(address fromToken, address toToken)
    private
    pure
    returns (address[] memory path)
  {
    path = new address[](2);
    path[0] = fromToken;
    path[1] = toToken;

    return path;
  }

  function transferUserATokenToContract(
    TokenInfo memory _token,
    uint _amount,
    address _user
  ) internal {
    // get aToken address
    (address aTokenAddress, , ) = DATA_PROVIDER.getReserveTokensAddresses(
      _token.tokenAddress
    );
    // user must have approved this contract to use their funds in advance
    try
      IERC20(aTokenAddress).transferFrom(
        _user,
        address(this),
        _amount.wadToDecimals(_token.decimals) // converts to token's decimals
      )
    returns (bool succeeded) {
      if (!succeeded) {
        revert(Errors.DELEVERAGE_ATOKEN_TRANSFER_FAILED_WITH_UNKNOWN_REASON);
      }
    } catch Error(
      string memory /*reason*/
    ) {
      revert(Errors.DELEVERAGE_USER_DID_NOT_APPROVE_ATOKEN_TRANSFER);
    }
  }

  function convertEthToTokenAmount(uint valueETH, TokenInfo memory token)
    internal
    view
    returns (uint)
  {
    return valueETH.wadDiv(PRICE_ORACLE.getAssetPrice(token.tokenAddress));
  }

  function swapExactETHForTokens(
    uint amountIn, // wad
    TokenInfo memory outToken,
    uint amountOutMin, // wad
    address onBehalfOf
  ) internal returns (uint) {
    if (NATIVE_ETH == outToken.tokenAddress) {
      IWETH(NATIVE_ETH).deposit{value: amountIn}();
      return amountIn;
    }
    amountOutMin = amountOutMin.wadToDecimals(outToken.decimals);
    try
      SUSHI_ROUTER.swapExactETHForTokens{value: amountIn}(
        amountOutMin,
        _getSushiSwapTokenPath(NATIVE_ETH, outToken.tokenAddress),
        onBehalfOf,
        block.timestamp
      )
    returns (uint[] memory amounts) {
      return amounts[1].decimalsToWad(outToken.decimals);
    } catch Error(
      string memory /*reason*/
    ) {
      revert(Errors.OPS_NOT_ABLE_TO_EXCHANGE_BY_SPECIFIED_SLIPPAGE);
    }
  }

  function approveAndSwapExactTokensForTokens(
    TokenInfo memory inToken,
    uint amountIn, // wad
    TokenInfo memory outToken,
    uint amountOutMin, // wad
    address onBehalfOf
  ) internal returns (uint) {
    if (inToken.tokenAddress == outToken.tokenAddress) {
      return amountIn;
    }
    // converts wad to the token units
    amountIn = amountIn.wadToDecimals(inToken.decimals);
    amountOutMin = amountOutMin.wadToDecimals(outToken.decimals);
    IERC20(inToken.tokenAddress).safeApprove(address(SUSHI_ROUTER), amountIn);

    try
      SUSHI_ROUTER.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        _getSushiSwapTokenPath(inToken.tokenAddress, outToken.tokenAddress),
        onBehalfOf,
        block.timestamp
      )
    returns (uint[] memory amounts) {
      return amounts[1].decimalsToWad(outToken.decimals);
    } catch Error(
      string memory /*reason*/
    ) {
      revert(Errors.OPS_NOT_ABLE_TO_EXCHANGE_BY_SPECIFIED_SLIPPAGE);
    }
  }

  function cleanUpAfterSwap() internal {
    // reset vars
    delete vars;
    // clear the address map
    for (uint i = 0; i < assetMap.length(); i++) {
      (address key, ) = assetMap.at(i);
      assetMap.remove(key);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

import {Errors} from "./Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage)
    internal
    pure
    returns (uint256)
  {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage)
    internal
    pure
    returns (uint256)
  {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

import {Errors} from "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  uint256 internal constant WAD_DECIMALS = 18;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(
      a <= (type(uint256).max - halfWAD) / b,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(
      a <= (type(uint256).max - halfB) / WAD,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(
      a <= (type(uint256).max - halfRAY) / b,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(
      a <= (type(uint256).max - halfB) / RAY,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }

  /**
   * @dev Converts wad up to specified decimals
   * @param a Wad
   * @param decimals Decimal unit
   * @return a converted in decimals
   **/
  function wadToDecimals(uint256 a, uint256 decimals)
    internal
    pure
    returns (uint256)
  {
    uint256 result;
    if (decimals >= WAD_DECIMALS) {
      result = a * (10**(decimals - WAD_DECIMALS));
      require(
        result / 10**(decimals - WAD_DECIMALS) == a,
        Errors.MATH_MULTIPLICATION_OVERFLOW
      );
    } else {
      result = a / (10**(WAD_DECIMALS - decimals));
    }
    return result;
  }

  /**
   * @dev Converts specified decimals to wad
   * @param a Wad
   * @param decimals Decimal unit
   * @return a converted in wad
   **/
  function decimalsToWad(uint256 a, uint256 decimals)
    internal
    pure
    returns (uint256)
  {
    uint256 result;
    if (decimals >= WAD_DECIMALS) {
      result = a / (10**(decimals - WAD_DECIMALS));
    } else {
      result = a * (10**(WAD_DECIMALS - decimals));
      require(
        result / 10**(decimals - WAD_DECIMALS) == a,
        Errors.MATH_MULTIPLICATION_OVERFLOW
      );
    }
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
  string public constant LEVERAGE_COLLATERAL_NOT_ENOUGH = "E1";
  string public constant LEVERAGE_USER_DID_NOT_DELEGATE_BORROW = "E2";
  string public constant LEVERAGE_PAIR_TOKEN_NOT_COLLATERABLE = "E3";
  string public constant LEVERAGE_TARGET_TOKEN_NOT_BORROWABLE = "E4";
  string public constant DELEVERAGE_HEALTH_FACTOR_BELOW_ONE = "E5";
  string public constant DELEVERAGE_DUPLICATE_ASSET_ENTRY = "E6";
  string public constant DELEVERAGE_MISMATCHED_ASSETS_AND_AMOUNTS = "E7";
  string public constant DELEVERAGE_ASSET_TOKEN_CANNOT_BE_COLLATERAL = "E8";
  string public constant DELEVERAGE_REDUCED_ASSET_NOT_ENOUGH = "E9";
  string public constant DELEVERAGE_REDUCED_ASSET_EXCCEED_NEEDED = "E10";
  string public constant DELEVERAGE_ATOKEN_SPECIFIED_EXCEEDS_OWNED = "E11";
  string public constant DELEVERAGE_USER_DID_NOT_APPROVE_ATOKEN_TRANSFER =
    "E12";
  string public constant DELEVERAGE_ATOKEN_TRANSFER_FAILED_WITH_UNKNOWN_REASON =
    "E13";
  string public constant DELEVERAGE_VARIABLE_DEBT_SPECIFIED_EXCEEDS_OWNED =
    "E14";
  string public constant DELEVERAGE_STABLE_DEBT_SPECIFIED_EXCEEDS_OWNED = "E15";
  string public constant OPS_FLASH_LOAN_FEE_NOT_ENOUGH = "E16";
  string public constant OPS_NOT_ABLE_TO_EXCHANGE_BY_SPECIFIED_SLIPPAGE = "E17";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "E18";
  string public constant MATH_ADDITION_OVERFLOW = "E19";
  string public constant MATH_DIVISION_BY_ZERO = "E20";
  string public constant CONTRACT_FALLBACK_NOT_ALLOWED = "E21";
  string public constant CONTRACT_ONLY_CALLED_BY_LENDING_POOL = "E22";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
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

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The interface for AaveLeveragedSwapManager
 */
interface IAaveLeveragedSwapManager {
  /**
   * @dev emitted after a leveraged swap.
   * @param targetToken The address of the token that will be borrowed
   * @param pairToken The address of the token that will be swapped to and deposited
   * @param user The user address
   * @param targetAmount The amount of target token in wei
   * @param borrowRateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param slippage The max slippage allowed during swap
   * @param pairAmountReturned The remaining amount of the pair token in wei that will be returned to user
   */
  event Leverage(
    address indexed targetToken,
    address indexed pairToken,
    address user,
    uint targetAmount,
    uint borrowRateMode,
    uint slippage,
    uint pairAmountReturned
  );

  /**
   * @dev emitted after a deleveraged swap.
   * @param targetToken The address of the token that will be repaid
   * @param user The user address
   * @param targetAmount The amount of target token in wei
   * @param borrowRateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param slippage The max slippage allowed during swap
   * @param targetAmountReturned The remaining amount of the target token in wei that will be returned to user
   */
  event Deleverage(
    address indexed targetToken,
    address user,
    uint targetAmount,
    uint borrowRateMode,
    uint slippage,
    uint targetAmountReturned
  );

  struct TokenInfo {
    address tokenAddress;
    bool borrowable;
    bool canBeCollateral;
    bool stableBorrowRateEnabled;
    uint liquidationThreshold;
    uint ltv;
    uint decimals;
  }

  struct Position {
    string symbol;
    address token;
    uint aTokenBalance;
    uint stableDebt;
    uint variableDebt;
    uint principalStableDebt;
    uint scaledVariableDebt;
    bool usedAsCollateral;
    bool borrowable;
    bool canBeCollateral;
    bool stableBorrowRateEnabled;
  }

  /**
   * @dev Get the asset reserve position list for the caller
   * @return the list of user's asset positions
   */
  function getAssetPositions() external view returns (Position[] memory);

  /**
   * @dev execute a leveraged swap.
   * @param targetToken The token that will be borrowed
   * @param targetAmount The amount of the token in wei
   * @param pairToken The token that will be swapped to and deposited
   * @param rateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param slippage The max slippage allowed during swap
   */
  function swapPreapprovedAssets(
    TokenInfo memory targetToken,
    uint targetAmount,
    TokenInfo memory pairToken,
    uint rateMode,
    uint slippage
  ) external payable;

  /**
   * @dev deleverage caller's debt position by repaying debt from collaterals
   * @param collaterals The list of collaterals in caller's portfolio
   * @param collateralAmounts The list of collateral amounts in wei that will be reduced
   * @param targetToken The token that will be repayed
   * @param targetAmount The amount of token in wei that will be repayed
   * @param rateMode The interest rate mode of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param slippage The max slippage allowed during swap
   */
  function repayDebt(
    TokenInfo[] calldata collaterals,
    uint256[] calldata collateralAmounts,
    TokenInfo memory targetToken,
    uint targetAmount,
    uint rateMode,
    uint slippage
  ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER()
    external
    view
    returns (ILendingPoolAddressesProvider);

  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getAllATokens() external view returns (TokenData[] memory);

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IPriceOracleGetter {
  function getAssetPrice(address _asset) external view returns (uint256);

  function getAssetsPrices(address[] calldata _assets)
    external
    view
    returns (uint256[] memory);

  function getSourceOfAsset(address _asset) external view returns (address);

  function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
  using EnumerableSet for EnumerableSet.AddressSet;

  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct AddressToUintsMap {
    // Storage of keys
    EnumerableSet.AddressSet _keys;
    mapping(address => uint[2]) _values;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    AddressToUintsMap storage map,
    address key,
    uint[2] memory value
  ) internal returns (bool) {
    map._values[key] = value;
    return map._keys.add(key);
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(AddressToUintsMap storage map, address key)
    internal
    returns (bool)
  {
    delete map._values[key];
    return map._keys.remove(key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(AddressToUintsMap storage map, address key)
    internal
    view
    returns (bool)
  {
    return map._keys.contains(key);
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
   */
  function length(AddressToUintsMap storage map)
    internal
    view
    returns (uint256)
  {
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
  function at(AddressToUintsMap storage map, uint256 index)
    internal
    view
    returns (address, uint[2] memory)
  {
    address key = map._keys.at(index);
    return (key, map._values[key]);
  }

  /**
   * @dev Returns the value associated with `key`.  O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(AddressToUintsMap storage map, address key)
    private
    view
    returns (uint[2] memory)
  {
    uint[2] memory value = map._values[key];
    require(contains(map, key), "EnumerableMap: nonexistent key");
    return value;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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