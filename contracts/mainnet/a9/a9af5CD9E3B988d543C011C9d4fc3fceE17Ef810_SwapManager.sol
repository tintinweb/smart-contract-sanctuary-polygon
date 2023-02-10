// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/AppErrors.sol";
import "../libs/AppDataTypes.sol";
import "../libs/SwapLib.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeERC20.sol";
import "../interfaces/ITetuLiquidator.sol";
import "../interfaces/ISwapManager.sol";
import "../interfaces/IController.sol";
import "../interfaces/ISwapConverter.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/ISimulateProvider.sol";
import "../interfaces/ISwapSimulator.sol";
import "../interfaces/IRequireAmountBySwapManagerCallback.sol";

/// @title Contract to find the best swap and make the swap
/// @notice Combines Manager and Converter
/// @author bogdoslav
contract SwapManager is ISwapManager, ISwapConverter, ISimulateProvider, ISwapSimulator {
  using SafeERC20 for IERC20;

  IController public immutable controller;
  /// @notice Same as controller.priceOracle()
  /// @dev Cached for the gas optimization
  IPriceOracle public immutable priceOracle;
  /// @notice Same as controller.tetuLiquidator()
  /// @dev Cached for the gas optimization
  ITetuLiquidator public immutable tetuLiquidator;

  ///////////////////////////////////////////////////////
  ///               Constants
  ///////////////////////////////////////////////////////

  int public constant APR_NUMERATOR = 10**18;

  uint public constant PRICE_IMPACT_NUMERATOR = SwapLib.PRICE_IMPACT_NUMERATOR;
  uint public constant PRICE_IMPACT_TOLERANCE_DEFAULT = SwapLib.PRICE_IMPACT_TOLERANCE_DEFAULT;

  /// @notice Optional price impact tolerance for assets. If not set, PRICE_IMPACT_TOLERANCE_DEFAULT is used.
  ///         asset => price impact tolerance (decimals are set by PRICE_IMPACT_NUMERATOR)
  mapping (address => uint) public priceImpactTolerances;

  ///////////////////////////////////////////////////////
  ///               Events
  ///////////////////////////////////////////////////////
  event OnSwap(address sourceToken,
    uint sourceAmount,
    address targetToken,
    address receiver,
    uint outputAmount
  );

  ///////////////////////////////////////////////////////
  ///               Initialization
  ///////////////////////////////////////////////////////

  constructor (
    address controller_,
    address tetuLiquidator_,
    address priceOracle_
  ) {
    require(
      controller_ != address(0)
      && tetuLiquidator_ != address(0)
      && priceOracle_ != address(0),
      AppErrors.ZERO_ADDRESS
    );
    controller = IController(controller_);
    tetuLiquidator = ITetuLiquidator(tetuLiquidator_);
    priceOracle = IPriceOracle(priceOracle_);
  }

  /// @notice Set custom price impact tolerance for the asset
  /// @param priceImpactTolerance Set 0 to use default price impact tolerance for the {asset}.
  ///                             Decimals = PRICE_IMPACT_NUMERATOR
  function setPriceImpactTolerance(address asset_, uint priceImpactTolerance) external {
    require(msg.sender == controller.governance(), AppErrors.GOVERNANCE_ONLY);
    require(priceImpactTolerance <= PRICE_IMPACT_NUMERATOR, AppErrors.INCORRECT_VALUE);

    priceImpactTolerances[asset_] = priceImpactTolerance;
  }

  ///////////////////////////////////////////////////////
  ///           Return best amount for swap
  ///////////////////////////////////////////////////////

  /// @notice Find a way to convert collateral asset to borrow asset in most efficient way
  ///         The algo to convert source amount S1:
  ///         - make real swap in static-call, get result max-target-amount
  ///         - recalculate max-target-amount to source amount using prices from a PriceOracle = S2
  ///         Result APR = 2 * (S1 - S2) / S1
  /// @dev This is a writable function with read-only behavior
  ///      because to simulate real swap the function should be writable.
  /// @param sourceAmountApprover_ A contract which has approved {sourceAmount_} to TetuConverter
  /// @param sourceAmount_ Amount in terms of {sourceToken_} to be converter to {targetToken_}
  ///                      This amount must be approved by {sourceAmountApprover_} to TetuConverter before the call
  /// @return converter Address of ISwapConverter
  ///         If SwapManager cannot find a conversion way,
  ///         it returns converter == 0 (in the same way as ITetuConverter)
  function getConverter(
    address sourceAmountApprover_,
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_
  ) external override returns (
    address converter,
    uint maxTargetAmount
  ) {
    // there are no restrictions for the msg.sender

    // Simulate real swap of source amount to max target amount
    // We call SwapManager.simulateSwap() here as an external call
    // and than revert all changes back
    // We need additional try because !PRICE error can happen if a price impact is too high
    try ISimulateProvider(address(this)).simulate(
      address(this),
      abi.encodeWithSelector(
        ISwapSimulator.simulateSwap.selector,
        sourceAmountApprover_,
        sourceToken_,
        sourceAmount_,
        targetToken_
      )
    ) returns (bytes memory response) {
      maxTargetAmount = abi.decode(response, (uint));
    } catch {
      // we can have i.e. !PRICE error (the price impact is too high)
      // it means, there is no way to make the conversion with acceptable price impact
      return (address(0), 0);
    }

    return maxTargetAmount == 0
      ? (address(0), 0)
      : (address(this), maxTargetAmount);
  }

  ///////////////////////////////////////////////////////
  ///           ISwapConverter Implementation
  ///////////////////////////////////////////////////////

  function getConversionKind() override external pure returns (AppDataTypes.ConversionKind) {
    return AppDataTypes.ConversionKind.SWAP_1;
  }

  /// @notice Swap {amountIn_} of {sourceToken_} to {targetToken_} and send result amount to {receiver_}
  ///         The swapping is made using TetuLiquidator.
  /// @return amountOut The amount that has been sent to the receiver
  function swap(
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    address receiver_
  ) override external returns (uint amountOut) {
    // there are no restrictions for the msg.sender
    uint targetTokenBalanceBefore = IERC20(targetToken_).balanceOf(address(this));

    IERC20(sourceToken_).safeApprove(address(tetuLiquidator), amountIn_);

    // If price impact is too big, getConverter will return high APR
    // So TetuConverter will select borrow, not swap.
    // If the swap was selected anyway, it is wrong case.
    // liquidate() will revert here and it's ok.

    tetuLiquidator.liquidate(sourceToken_, targetToken_, amountIn_, _getPriceImpactTolerance(sourceToken_));
    amountOut = IERC20(targetToken_).balanceOf(address(this)) - targetTokenBalanceBefore;

    IERC20(targetToken_).safeTransfer(receiver_, amountOut);

    // The result amount cannot be too different from the value calculated directly using price oracle prices
    require(
      SwapLib.isConversionValid(
        priceOracle,
        sourceToken_,
        amountIn_,
        targetToken_,
        amountOut,
        _getPriceImpactTolerance(targetToken_)
      ),
      AppErrors.TOO_HIGH_PRICE_IMPACT
    );
    emit OnSwap(sourceToken_, amountIn_, targetToken_, receiver_, amountOut);
  }

  /// @notice Make real swap to know result amount
  ///         but exclude any additional operations
  ///         like "sending the result amount to a receiver" or "emitting any events".
  /// @dev This function should be called only inside static call to know result amount.
  /// @param sourceAmountApprover_ A contract which has approved source amount to TetuConverter
  ///                              and called a function findSwapStrategy
  /// @param sourceAmount_ Amount in terms of {sourceToken_} to be converter to {targetToken_}
  /// @return amountOut Result amount in terms of {targetToken_} after conversion
  function simulateSwap(
    address sourceAmountApprover_,
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_
  ) external override returns (uint) {
    require(msg.sender == controller.swapManager(), AppErrors.ONLY_SWAP_MANAGER);

    IRequireAmountBySwapManagerCallback(controller.tetuConverter()).onRequireAmountBySwapManager(
      sourceAmountApprover_,
      sourceToken_,
      sourceAmount_
    );

    uint targetTokenBalanceBefore = IERC20(targetToken_).balanceOf(address(this));

    IERC20(sourceToken_).safeApprove(address(tetuLiquidator), sourceAmount_);
    tetuLiquidator.liquidate(sourceToken_, targetToken_, sourceAmount_, _getPriceImpactTolerance(sourceToken_));
    return IERC20(targetToken_).balanceOf(address(this)) - targetTokenBalanceBefore;
  }

  /// @notice Calculate APR using known {sourceToken_} and known {targetAmount_}
  ///         as 2 * loss / sourceAmount
  ///         loss - conversion loss, we use 2 multiplier to take into account losses for there and back conversions.
  /// @param sourceAmount_ Source amount before conversion, in terms of {sourceToken_}
  /// @param targetAmount_ Result of conversion. The amount is in terms of {targetToken_}
  function getApr18(
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_,
    uint targetAmount_
  ) external view override returns (int) {
    uint targetAmountInSourceTokens = SwapLib.convertUsingPriceOracle(
      priceOracle,
      targetToken_,
      targetAmount_,
      sourceToken_
    );

    // calculate result APR
    // we need to multiple one-way-loss on to to get loss for there-and-back conversion
    return 2 * (int(sourceAmount_) - int(targetAmountInSourceTokens)) * APR_NUMERATOR / int(sourceAmount_);
  }

  /// @notice Return custom or default price impact tolerance for the asset
  function getPriceImpactTolerance(address asset_) external view override returns (uint priceImpactTolerance) {
    return _getPriceImpactTolerance(asset_);
  }

  //////////////////////////////////////////////////////////////////////////////
  ///           View functions
  //////////////////////////////////////////////////////////////////////////////
  /// @notice Return custom or default price impact tolerance for the asset
  function _getPriceImpactTolerance(address asset_) internal view returns (uint priceImpactTolerance) {
    priceImpactTolerance = priceImpactTolerances[asset_];
    if (priceImpactTolerance == 0) {
      priceImpactTolerance = PRICE_IMPACT_TOLERANCE_DEFAULT;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  ///           Simulate real swap
  ///           using gnosis simulate() and simulateAndRevert() functions
  ///           They are slightly more efficient than try/catch approach
  ///           see SimulateTesterTest.ts
  /////////////////////////////////////////////////////////////////////////////

  /// Source: https://github.com/gnosis/util-contracts/blob/main/contracts/storage/StorageSimulation.sol
  ///
  /// @dev Performs a delegetecall on a targetContract in the context of self.
  /// Internally reverts execution to avoid side effects (making it static).
  ///
  /// This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
  /// Specifically, the `returndata` after a call to this method will be:
  /// `success:bool || response.length:uint256 || response:bytes`.
  ///
  /// @param targetContract Address of the contract containing the code to execute.
  /// @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
  function simulateAndRevert(
    address targetContract,
    bytes memory calldataPayload
  ) public {
    // there are no restrictions for the msg.sender

    assembly {
      let success := delegatecall(
        gas(),
        targetContract,
        add(calldataPayload, 0x20),
        mload(calldataPayload),
        0,
        0
      )

      mstore(0x00, success)
      mstore(0x20, returndatasize())
      returndatacopy(0x40, 0, returndatasize())
      revert(0, add(returndatasize(), 0x40))
    }
  }

  ///  Source: https://github.com/gnosis/util-contracts/blob/main/contracts/storage/StorageAccessible.sol
  ///  @dev Simulates a delegate call to a target contract in the context of self.
  ///
  ///  Internally reverts execution to avoid side effects (making it static).
  ///  Catches revert and returns encoded result as bytes.
  ///
  ///  @param targetContract Address of the contract containing the code to execute.
  ///  @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
  function simulate(
    address targetContract,
    bytes calldata calldataPayload
  ) external override returns (bytes memory response) {
    // there are no restrictions for the msg.sender

    // Suppress compiler warnings about not using parameters, while allowing
    // parameters to keep names for documentation purposes. This does not
    // generate code.
    targetContract;
    calldataPayload;

    assembly {
      let internalCalldata := mload(0x40)
    // Store `simulateAndRevert.selector`.
      mstore(internalCalldata, "\xb4\xfa\xba\x09")
    // Abuse the fact that both this and the internal methods have the
    // same signature, and differ only in symbol name (and therefore,
    // selector) and copy calldata directly. This saves us approximately
    // 250 bytes of code and 300 gas at runtime over the
    // `abi.encodeWithSelector` builtin.
      calldatacopy(
        add(internalCalldata, 0x04),
        0x04,
        sub(calldatasize(), 0x04)
      )

    // `pop` is required here by the compiler, as top level expressions
    // can't have return values in inline assembly. `call` typically
    // returns a 0 or 1 value indicated whether or not it reverted, but
    // since we know it will always revert, we can safely ignore it.
      pop(call(
        gas(),
        address(),
        0,
        internalCalldata,
        calldatasize(),
        // The `simulateAndRevert` call always reverts, and instead
        // encodes whether or not it was successful in the return data.
        // The first 32-byte word of the return data contains the
        // `success` value, so write it to memory address 0x00 (which is
        // reserved Solidity scratch space and OK to use).
        0x00,
        0x20
      ))


    // Allocate and copy the response bytes, making sure to increment
    // the free memory pointer accordingly (in case this method is
    // called as an internal function). The remaining `returndata[0x20:]`
    // contains the ABI encoded response bytes, so we can just write it
    // as is to memory.
      let responseSize := sub(returndatasize(), 0x20)
      response := mload(0x40)
      mstore(0x40, add(response, responseSize))
      returndatacopy(response, 0x20, responseSize)

      if iszero(mload(0x00)) {
        revert(add(response, 0x20), mload(response))
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Keep and provide addresses of all application contracts
interface IController {
  function governance() external view returns (address);

  /// ********************* Health factor explanation  ****************
  /// For example, a landing platform has: liquidity threshold = 0.85, LTV=0.8, LTV / LT = 1.0625
  /// For collateral $100 we can borrow $80. A liquidation happens if the cost of collateral will reduce below $85.
  /// We set min-health-factor = 1.1, target-health-factor = 1.3
  /// For collateral 100 we will borrow 100/1.3 = 76.92
  ///
  /// Collateral value   100        77            assume that collateral value is decreased at 100/77=1.3 times
  /// Collateral * LT    85         65.45
  /// Borrow value       65.38      65.38         but borrow value is the same as before
  /// Health factor      1.3        1.001         liquidation almost happens here (!)
  ///
  /// So, if we have target factor 1.3, it means, that if collateral amount will decreases at 1.3 times
  /// and the borrow value won't change at the same time, the liquidation happens at that point.
  /// Min health factor marks the point at which a rebalancing must be made asap.
  /// *****************************************************************

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


  ///////////////////////////////////////////////////////
  ///        Core application contracts
  ///////////////////////////////////////////////////////

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  ///////////////////////////////////////////////////////
  ///        External contracts
  ///////////////////////////////////////////////////////
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);

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
  /// @notice Transfer {sourceAmount_} approved by {sourceAmountApprover_} to swap manager
  function onRequireAmountBySwapManager(
    address sourceAmountApprover_,
    address sourceToken_,
    uint sourceAmount_
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Provider of simulate() function
interface ISimulateProvider {
  function simulate(
    address targetContract,
    bytes calldata calldataPayload
  ) external returns (bytes memory response);
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

interface ISwapSimulator {

  /// @notice Make real swap to know result amount
  ///         but exclude any additional operations
  ///         like "sending result amount to receiver" or "emitting any events".
  /// @dev This function should be called only inside static call to know result amount.
  /// @param user_ A strategy which has approved source amount to TetuConverter
  ///              and called a function findSwapStrategy
  /// @param sourceAmount_ Amount in terms of {sourceToken_} to be converter to {targetToken_}
  /// @return amountOut Result amount in terms of {targetToken_} after conversion
  function simulateSwap(
    address user_,
    address sourceToken_,
    uint sourceAmount_,
    address targetToken_
  ) external returns (
    uint amountOut
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
    /// @notice Amount of {sourceToken} to be converted to {targetToken}
    uint collateralAmount;
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
    return (amountOut_ > expectedAmountOut
      ? 0 // we assume here, that higher output amount is not a problem
      : expectedAmountOut - amountOut_
    ) <= expectedAmountOut * priceImpactTolerance_ / SwapLib.PRICE_IMPACT_NUMERATOR;
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