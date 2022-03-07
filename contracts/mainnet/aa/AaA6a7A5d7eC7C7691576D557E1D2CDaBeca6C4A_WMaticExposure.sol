// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFlashBorrower} from "../interfaces/IFlashBorrower.sol";
import {IFlashLoan} from "../interfaces/IFlashLoan.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {ILeverageStrategy} from "../interfaces/ILeverageStrategy.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {LeverageAccount, LeverageAccountRegistry} from "../account/LeverageAccountRegistry.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {TroveHelpers} from "../helpers/TroveHelpers.sol";

contract WMaticExposure is IFlashBorrower, TroveHelpers {
  using SafeMath for uint256;

  event OpenPosition(uint256 amount, address who);

  address public borrowerOperations;
  address public controller;
  ITroveManager public troveManager;

  IERC20 public immutable arth;
  IERC20 public immutable usdc;
  IERC20 public immutable wmatic;
  IFlashLoan public flashLoan;
  LeverageAccountRegistry public accountRegistry;
  IUniswapV2Router02 public immutable uniswapRouter;

  address private me;

  event Where(address who, uint256 line);

  constructor(
    address _flashloan,
    address _arth,
    address _wmatic,
    address _usdc,
    address _uniswapRouter,
    address _borrowerOperations,
    address _controller,
    address _accountRegistry,
    address _troveManager
  ) {
    flashLoan = IFlashLoan(_flashloan);

    arth = IERC20(_arth);
    usdc = IERC20(_usdc);
    wmatic = IERC20(_wmatic);
    uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    borrowerOperations = _borrowerOperations;
    troveManager = ITroveManager(_troveManager);
    accountRegistry = LeverageAccountRegistry(_accountRegistry);
    controller = _controller;

    me = address(this);
  }

  function getAccount(address who) public view returns (LeverageAccount) {
    return accountRegistry.accounts(who);
  }

  function openPosition(
    uint256 borrowedCollateral,
    uint256 principalCollateral,
    uint256 minExposure,
    uint256 maxBorrowingFee,
    address upperHint,
    address lowerHint,
    address frontEndTag
  ) external {
    // take the principal
    wmatic.transferFrom(msg.sender, address(this), principalCollateral);

    // estimate how much we should flashloan based on how much we want to borrow
    uint256 flashloanAmount = estimateARTHtoSell(borrowedCollateral);

    bytes memory flashloanData = abi.encode(
      msg.sender,
      uint256(0), // action = 0 -> open loan
      maxBorrowingFee,
      principalCollateral,
      minExposure,
      upperHint,
      lowerHint,
      frontEndTag
    );

    arth.approve(address(flashLoan), flashloanAmount);
    flashLoan.flashLoan(address(this), flashloanAmount, flashloanData);
    flush(msg.sender);
  }

  function closePosition() external {
    bytes memory flashloanData = abi.encode(
      msg.sender,
      uint256(1), // action = 0 -> close loan
      uint256(0),
      uint256(0),
      uint256(0),
      address(0),
      address(0),
      address(0)
    );

    uint256 flashloanAmount = troveManager.getTroveDebt(address(getAccount(msg.sender)));

    arth.approve(address(flashLoan), flashloanAmount);
    flashLoan.flashLoan(address(this), flashloanAmount, flashloanData);
    flush(msg.sender);
  }

  function onFlashLoan(
    address initiator,
    uint256 flashloanAmount,
    uint256 fee,
    bytes calldata data
  ) external override returns (bytes32) {
    require(msg.sender == address(flashLoan), "untrusted lender");
    require(initiator == address(this), "not contract");

    // decode the data
    (
      address who,
      uint256 action,
      uint256 maxBorrowingFee,
      uint256 principalCollateral,
      uint256 minExposure,
      address upperHint,
      address lowerHint,
      address frontEndTag
    ) = abi.decode(data, (address, uint256, uint256, uint256, uint256, address, address, address));

    // // open or close the loan position
    if (action == 0) {
      onFlashloanOpenPosition(
        who,
        flashloanAmount,
        principalCollateral,
        maxBorrowingFee,
        minExposure,
        upperHint,
        lowerHint,
        frontEndTag
      );
    } else onFlashloanClosePosition(who, flashloanAmount);

    return keccak256("FlashMinter.onFlashLoan");
  }

  function onFlashloanOpenPosition(
    address who,
    uint256 flashloanAmount,
    uint256 principalCollateral,
    uint256 maxBorrowingFee,
    uint256 minExposure,
    address upperHint,
    address lowerHint,
    address frontEndTag
  ) internal {
    LeverageAccount acct = getAccount(who);

    // 1: sell arth for collateral
    uint256 initCollateralAmount = wmatic.balanceOf(address(acct)).add(principalCollateral);
    if (initCollateralAmount < minExposure) {
      uint256 wmaticNeeded = minExposure.sub(initCollateralAmount);
      sellARTHForExact(wmaticNeeded, flashloanAmount, address(acct));
    }

    // 2: send the collateral to the leverage account
    if (initCollateralAmount > 0) wmatic.transfer(address(acct), initCollateralAmount);

    // 3: open loan using the collateral
    uint256 totalCollateralAmount = wmatic.balanceOf(address(acct));
    openLoan(
      acct,
      borrowerOperations,
      maxBorrowingFee, // borrowing fee
      flashloanAmount.add(10 * 1e18), // debt + liquidation reserve
      totalCollateralAmount, // collateral
      upperHint,
      lowerHint,
      frontEndTag,
      arth,
      wmatic
    );

    // over here we will have a open loan with collateral and leverage account would've
    // send us back the minted arth
    // 4. payback the loan..

    // 5. check if we met the min leverage conditions
    // require(troveManager.getTroveDebt(address(acct)) >= minExposure, "min exposure not met");
  }

  function onFlashloanClosePosition(address who, uint256 flashloanAmount) internal {
    LeverageAccount acct = getAccount(who);

    // 1. send the flashloaned arth to the account
    arth.transfer(address(acct), flashloanAmount);

    // 2. use the flashloan'd ARTH to payback the debt and close the loan
    closeLoan(acct, controller, borrowerOperations, flashloanAmount, arth, wmatic);

    // 3. get the collateral and swap back to arth to back the loan
    uint256 totalCollateralAmount = wmatic.balanceOf(address(this));
    uint256 arthBal = arth.balanceOf(address(this));
    uint256 pendingArth = flashloanAmount.sub(arthBal);

    buyExactARTH(pendingArth, totalCollateralAmount, address(this));

    // 4. payback the loan..
  }

  function sellARTHForExact(
    uint256 amountOut,
    uint256 amountInMax,
    address to
  ) internal returns (uint256) {
    if (amountOut == 0) return 0;

    arth.approve(address(uniswapRouter), amountInMax);

    address[] memory path = new address[](3);
    path[0] = address(arth);
    path[1] = address(usdc);
    path[2] = address(wmatic);

    uint256[] memory amountsOut = uniswapRouter.swapTokensForExactTokens(
      amountOut,
      amountInMax,
      path,
      to,
      block.timestamp
    );

    return amountsOut[amountsOut.length - 1];
  }

  function buyExactARTH(
    uint256 amountOut,
    uint256 amountInMax,
    address to
  ) internal returns (uint256) {
    if (amountOut == 0) return 0;
    wmatic.approve(address(uniswapRouter), amountInMax);

    address[] memory path = new address[](3);
    path[0] = address(wmatic);
    path[1] = address(usdc);
    path[2] = address(arth);

    uint256[] memory amountsOut = uniswapRouter.swapTokensForExactTokens(
      amountOut,
      amountInMax,
      path,
      to,
      block.timestamp
    );

    return amountsOut[amountsOut.length - 1];
  }

  function estimateARTHtoSell(uint256 maticNeeded) public view returns (uint256 arthToSell) {
    if (maticNeeded == 0) return 0;

    address[] memory path = new address[](3);
    path[0] = address(arth);
    path[1] = address(usdc);
    path[2] = address(wmatic);

    uint256[] memory amountsOut = uniswapRouter.getAmountsIn(maticNeeded, path);
    arthToSell = amountsOut[0];
  }

  function estimateARTHtoBuy(uint256 arthNeeded) public view returns (uint256 maticToSell) {
    if (arthNeeded == 0) return 0;

    address[] memory path = new address[](3);
    path[0] = address(wmatic);
    path[1] = address(usdc);
    path[2] = address(arth);

    uint256[] memory amountsOut = uniswapRouter.getAmountsIn(arthNeeded, path);
    maticToSell = amountsOut[0];
  }

  function flush(address to) internal {
    if (arth.balanceOf(me) > 0) arth.transfer(to, arth.balanceOf(me));
    if (usdc.balanceOf(me) > 0) usdc.transfer(to, usdc.balanceOf(me));
    if (wmatic.balanceOf(me) > 0) wmatic.transfer(to, wmatic.balanceOf(me));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

interface IFlashBorrower {
  /**
   * @dev Receive a flash loan.
   * @param initiator The initiator of the loan.
   * @param amount The amount of tokens lent.
   * @param fee The additional amount of tokens to repay.
   * @param data Arbitrary data structure, intended to contain user-defined parameters.
   * @return The keccak256 hash of "IFlashLender.onFlashLoan"
   */
  function onFlashLoan(
    address initiator,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IFlashLoan {
  function flashLoan(
    address receiverAddress,
    uint256 amount,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Common interface for the Trove Manager.
interface ITroveManager {
  function setAddresses(
    address _borrowerOperationsAddress,
    address _activePoolAddress,
    address _defaultPoolAddress,
    address _stabilityPoolAddress,
    address _gasPoolAddress,
    address _collSurplusPoolAddress,
    address _lusdTokenAddress,
    address _sortedTrovesAddress,
    address _governanceAddress,
    address _wethAddress
  ) external;

  function stabilityPool() external view returns (address);

  function lusdToken() external view returns (IERC20);

  function getTroveOwnersCount() external view returns (uint256);

  function getTroveFromTroveOwnersArray(uint256 _index) external view returns (address);

  function getNominalICR(address _borrower) external view returns (uint256);

  function getCurrentICR(address _borrower, uint256 _price) external view returns (uint256);

  function liquidate(address _borrower) external;

  function liquidateTroves(uint256 _n) external;

  function batchLiquidateTroves(address[] calldata _troveArray) external;

  function redeemCollateral(
    uint256 _amount,
    address _firstRedemptionHint,
    address _upperPartialRedemptionHint,
    address _lowerPartialRedemptionHint,
    uint256 _partialRedemptionHintNICR,
    uint256 _maxIterations,
    uint256 _maxFee
  ) external;

  function updateStakeAndTotalStakes(address _borrower) external returns (uint256);

  function updateTroveRewardSnapshots(address _borrower) external;

  function addTroveOwnerToArray(address _borrower) external returns (uint256 index);

  function applyPendingRewards(address _borrower) external;

  function getPendingETHReward(address _borrower) external view returns (uint256);

  function getPendingLUSDDebtReward(address _borrower) external view returns (uint256);

  function hasPendingRewards(address _borrower) external view returns (bool);

  function getEntireDebtAndColl(address _borrower)
    external
    view
    returns (
      uint256 debt,
      uint256 coll,
      uint256 pendingLUSDDebtReward,
      uint256 pendingETHReward
    );

  function closeTrove(address _borrower) external;

  function removeStake(address _borrower) external;

  function getRedemptionRate() external view returns (uint256);

  function getRedemptionRateWithDecay() external view returns (uint256);

  function getRedemptionFeeWithDecay(uint256 ethDrawn) external view returns (uint256);

  function getBorrowingRate() external view returns (uint256);

  function getBorrowingRateWithDecay() external view returns (uint256);

  function getBorrowingFee(uint256 _debt) external view returns (uint256);

  function getBorrowingFeeWithDecay(uint256 _debt) external view returns (uint256);

  function decayBaseRateFromBorrowing() external;

  function getTroveStatus(address _borrower) external view returns (uint256);

  function getTroveStake(address _borrower) external view returns (uint256);

  function getTroveDebt(address _borrower) external view returns (uint256);

  function getTroveFrontEnd(address _borrower) external view returns (address);

  function getTroveColl(address _borrower) external view returns (uint256);

  function setTroveStatus(address _borrower, uint256 num) external;

  function setTroveFrontEndTag(address _borrower, address _frontEndTag) external;

  function increaseTroveColl(address _borrower, uint256 _collIncrease) external returns (uint256);

  function decreaseTroveColl(address _borrower, uint256 _collDecrease) external returns (uint256);

  function increaseTroveDebt(address _borrower, uint256 _debtIncrease) external returns (uint256);

  function decreaseTroveDebt(address _borrower, uint256 _collDecrease) external returns (uint256);

  function getTCR(uint256 _price) external view returns (uint256);

  function checkRecoveryMode(uint256 _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILeverageStrategy {
  function openPosition(
    uint256 borrowAmount,
    uint256 minExposure,
    bytes calldata data
  ) external;

  function closePosition(uint256 borrowAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import {LeverageAccount, LeverageAccountFactory} from "./LeverageAccountFactory.sol";

// This Registry deploys new proxy instances through LeverageAccountFactory.build(address) and keeps a registry of owner => proxy
contract LeverageAccountRegistry {
  mapping(address => LeverageAccount) public accounts;
  LeverageAccountFactory public factory;

  constructor(address factory_) {
    factory = LeverageAccountFactory(factory_);
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable account) {
    account = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable account) {
    // Not allow new proxy if the user already has one and remains being the owner
    require(
      address(accounts[owner]) == address(LeverageAccount(address(0))) ||
        accounts[owner].canExecute(owner),
      "account exists"
    );

    account = factory.build(owner);
    accounts[owner] = LeverageAccount(account);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IBorrowerOperations} from "../interfaces/IBorrowerOperations.sol";
import {IFlashBorrower} from "../interfaces/IFlashBorrower.sol";
import {IFlashLoan} from "../interfaces/IFlashLoan.sol";
import {ILeverageStrategy} from "../interfaces/ILeverageStrategy.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LeverageAccount} from "../account/LeverageAccount.sol";

abstract contract TroveHelpers {
  using SafeMath for uint256;
  bytes4 private constant OPEN_LOAN_SELECTOR =
    bytes4(keccak256("openTrove(uint256,uint256,uint256,address,address,address)"));

  function openLoan(
    LeverageAccount acct,
    address borrowerOperations,
    uint256 maxFee,
    uint256 debt,
    uint256 collateralAmount,
    address upperHint,
    address lowerHint,
    address frontEndTag,
    IERC20 arth,
    IERC20 wmatic
  ) internal {
    bytes memory openLoanData = abi.encodeWithSelector(
      OPEN_LOAN_SELECTOR,
      maxFee,
      debt,
      collateralAmount,
      upperHint,
      lowerHint,
      frontEndTag
    );

    // approve spending
    approveTokenViaAccount(acct, wmatic, borrowerOperations, collateralAmount);

    // open loan using the user's proxy
    acct.callFn(borrowerOperations, openLoanData);

    // send the arth back to the flash loan contract to payback the flashloan
    uint256 arthBal = arth.balanceOf(address(acct));
    if (arthBal > 0) transferTokenViaAccount(acct, arth, address(this), arthBal);
  }

  function closeLoan(
    LeverageAccount acct,
    address controller,
    address borrowerOperations,
    uint256 availableARTH,
    IERC20 arth,
    IERC20 wmatic
  ) internal {
    bytes memory closeLoanData = abi.encodeWithSignature("closeTrove()");

    // approve spending
    if (controller != address(0)) approveTokenViaAccount(acct, arth, controller, availableARTH);

    // close loan using the user's account
    acct.callFn(borrowerOperations, closeLoanData);

    // send the arth back to the flash loan contract to payback the flashloan
    uint256 arthBal = arth.balanceOf(address(acct));
    if (arthBal > 0) transferTokenViaAccount(acct, arth, address(this), arthBal);

    // send the collateral back to the flash loan contract to payback the flashloan
    uint256 collBal = wmatic.balanceOf(address(acct));
    if (collBal > 0) transferTokenViaAccount(acct, wmatic, address(this), collBal);
  }

  function transferTokenViaAccount(
    LeverageAccount acct,
    IERC20 token,
    address who,
    uint256 amount
  ) internal {
    // send tokens back to the contract
    bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", who, amount);
    acct.callFn(address(token), transferData);
  }

  function approveTokenViaAccount(
    LeverageAccount acct,
    IERC20 token,
    address who,
    uint256 amount
  ) internal {
    // send tokens back to the contract
    bytes memory transferData = abi.encodeWithSignature("approve(address,uint256)", who, amount);
    acct.callFn(address(token), transferData);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
  function factory() external returns (address);

  function WETH() external returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LeverageAccount.sol";

// LeverageAccountFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract LeverageAccountFactory {
  event Created(address indexed sender, address indexed owner, address account);
  mapping(address => bool) public isAccount;

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable account) {
    account = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable account) {
    account = payable(address(new LeverageAccount(owner)));
    emit Created(msg.sender, owner, address(account));
    isAccount[account] = true;
  }
}

// SPDX-License-Identifier: GNU-3

pragma solidity ^0.8.0;

import {ILeverageAccount} from "../interfaces/ILeverageAccount.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract LeverageAccount is AccessControl, ILeverageAccount {
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

  constructor(address owner) {
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setRoleAdmin(STRATEGY_ROLE, DEFAULT_ADMIN_ROLE);
  }

  modifier onlyStrategiesOrAdmin() {
    require(_canExecute(msg.sender), "only strategies or owner.");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only owner.");
    _;
  }

  function _canExecute(address who) internal view returns (bool) {
    return hasRole(STRATEGY_ROLE, who) || hasRole(DEFAULT_ADMIN_ROLE, who);
  }

  function canExecute(address who) external view override returns (bool) {
    return _canExecute(who);
  }

  function approveStrategy(address strategy) external override onlyAdmin {
    _grantRole(STRATEGY_ROLE, strategy);
  }

  function revokeStrategy(address strategy) external override onlyAdmin {
    _revokeRole(STRATEGY_ROLE, strategy);
  }

  function callFn(address target, bytes memory signature) external override onlyStrategiesOrAdmin {
    (bool success, ) = target.call(signature);
    require(success, "callFn fail");
  }
}

// SPDX-License-Identifier: GNU-3

pragma solidity ^0.8.0;

interface ILeverageAccount {
  function approveStrategy(address strategy) external;

  function revokeStrategy(address strategy) external;

  function callFn(address target, bytes memory signature) external;

  function canExecute(address who) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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

pragma solidity ^0.8.0;

// Common interface for the Trove Manager.
interface IBorrowerOperations {
  // --- Events ---
  function setAddresses(
    address _troveManagerAddress,
    address _activePoolAddress,
    address _defaultPoolAddress,
    address _stabilityPoolAddress,
    address _gasPoolAddress,
    address _collSurplusPoolAddress,
    address _sortedTrovesAddress,
    address _lusdTokenAddress,
    address _wethAddress,
    address _governanceAddress
  ) external;

  function registerFrontEnd() external;

  function openTrove(
    uint256 _maxFee,
    uint256 _arthAmount,
    uint256 _ethAmount,
    address _upperHint,
    address _lowerHint,
    address _frontEndTag
  ) external;

  function addColl(
    uint256 _ethAmount,
    address _upperHint,
    address _lowerHint
  ) external;

  function moveETHGainToTrove(
    uint256 _ethAmount,
    address _user,
    address _upperHint,
    address _lowerHint
  ) external;

  function withdrawColl(
    uint256 _amount,
    address _upperHint,
    address _lowerHint
  ) external;

  function withdrawLUSD(
    uint256 _maxFee,
    uint256 _amount,
    address _upperHint,
    address _lowerHint
  ) external;

  function repayLUSD(
    uint256 _amount,
    address _upperHint,
    address _lowerHint
  ) external;

  function closeTrove() external;

  function adjustTrove(
    uint256 _maxFee,
    uint256 _collWithdrawal,
    uint256 _debtChange,
    uint256 _ethAmount,
    bool isDebtIncrease,
    address _upperHint,
    address _lowerHint
  ) external;

  function claimCollateral() external;

  function getCompositeDebt(uint256 _debt) external view returns (uint256);
}