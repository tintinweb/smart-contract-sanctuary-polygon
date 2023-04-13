pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

// copy from Balancer doc https://docs.balancer.finance/smart-contracts/interfaces
interface BPool {
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data);

    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

// copy from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol#L250

interface CErc20Interface {
    // contract CErc20Storage {
    // /**
    //  * @notice Underlying asset for this CToken
    //  */
    // address public underlying;
    // }
    // original definition is above, but change to a function for easier implementation
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol#L119
interface CTokenInterface {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);
}

interface CErc20 is CErc20Interface, CTokenInterface {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { XadeOwnableUpgrade } from "../utils/XadeOwnableUpgrade.sol";
import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { CErc20 } from "./Compound/CTokenInterface.sol";
import { BPool } from "./Balancer/BPool.sol";
import { IExchangeWrapper, Decimal } from "../interface/IExchangeWrapper.sol";
import { DecimalERC20 } from "../utils/DecimalERC20.sol";
import { Decimal, SafeMath } from "../utils/Decimal.sol";

// USDC/USDT decimal 6
// cUSDC/cUSDT decimal 8
contract ExchangeWrapper is XadeOwnableUpgrade, IExchangeWrapper, DecimalERC20 {
    using Decimal for Decimal.decimal;
    using SafeMath for *;

    // default max price slippage is 20% of spot price. 12e17 = (1 + 20%) e18
    uint256 private constant DEFAULT_MAX_PRICE_SLIPPAGE = 12e17;

    //
    // EVENTS
    //
    event ExchangeSwap(uint256 inputTokenAmount, uint256 outputTokenAmount);
    // for debug purpose in the future
    event BalancerSwap(uint256 inAmount, uint256 out);
    event CompoundRedeem(uint256 underlyingAmount, uint256 cTokenAmount);
    event CompoundMint(uint256 underlyingAmount, uint256 cTokenAmount);

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//
    BPool public balancerPool;
    CErc20 public compoundCUsdt;
    IERC20 private cUSD;
    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    function initialize(
        address _balancerPool,
        address _compoundCUsdt,
        address _cUSD
    ) external initializer {
        __Ownable_init();

        cUSD = IERC20(_cUSD);
        setBalancerPool(_balancerPool);
        setCompoundCUsdt(_compoundCUsdt);
    }

    function swapInput(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal calldata _inputTokenSold,
        Decimal.decimal calldata _minOutputTokenBought,
        Decimal.decimal calldata _maxPrice
    ) external override returns (Decimal.decimal memory) {
        return implSwapInput(_inputToken, _outputToken, _inputTokenSold, _minOutputTokenBought, _maxPrice);
    }

    function swapOutput(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal calldata _outputTokenBought,
        Decimal.decimal calldata _maxInputTokeSold,
        Decimal.decimal calldata _maxPrice
    ) external override returns (Decimal.decimal memory) {
        return implSwapOutput(_inputToken, _outputToken, _outputTokenBought, _maxInputTokeSold, _maxPrice);
    }

    function getInputPrice(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal calldata _inputTokenSold
    ) external view override returns (Decimal.decimal memory) {
        Decimal.decimal memory spotPrice = implGetSpotPrice(_inputToken, _outputToken);
        return _inputTokenSold.mulD(spotPrice);
    }

    function getOutputPrice(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal calldata _outputTokenBought
    ) external view override returns (Decimal.decimal memory) {
        Decimal.decimal memory spotPrice = implGetSpotPrice(_inputToken, _outputToken);
        return _outputTokenBought.divD(spotPrice);
    }

    function getSpotPrice(IERC20 _inputToken, IERC20 _outputToken)
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return implGetSpotPrice(_inputToken, _outputToken);
    }

    function approve(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _amount
    ) public onlyOwner {
        _approve(_token, _to, _amount);
    }

    function setBalancerPool(address _balancerPool) public onlyOwner {
        balancerPool = BPool(_balancerPool);
    }

    function setCompoundCUsdt(address _compoundCUsdt) public onlyOwner {
        compoundCUsdt = CErc20(_compoundCUsdt);
        cUSD = IERC20(compoundCUsdt.underlying());

        // approve cUSDT for redeem/redeemUnderlying
        approve(IERC20(address(compoundCUsdt)), address(compoundCUsdt), Decimal.decimal(uint256(-1)));
        approve(cUSD, address(compoundCUsdt), Decimal.decimal(uint256(-1)));
    }

    function setCusd(address _cUSD) public onlyOwner {
        cUSD = IERC20(_cUSD);
        // approve usdt for cUSDT to mint
        approve(cUSD, address(compoundCUsdt), Decimal.decimal(uint256(-1)));
    }

    //
    // INTERNALS
    //

    function implSwapInput(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal memory _inputTokenSold,
        Decimal.decimal memory _minOutputTokenBought,
        Decimal.decimal memory _maxPrice
    ) internal returns (Decimal.decimal memory outTokenAmount) {
        address sender = _msgSender();
        Decimal.decimal memory inTokenAmount = _inputTokenSold;

        //___0. transfer input token to exchangeWrapper
        _transferFrom(_inputToken, sender, address(this), inTokenAmount);

        // mint cUSDT for Balancer if _inputToken is cUSD
        if (isCUSD(_inputToken)) {
            inTokenAmount = compoundMint(inTokenAmount);
        }

        //___1. swap
        IERC20 inToken = balancerAcceptableToken(_inputToken);
        IERC20 outToken = balancerAcceptableToken(_outputToken);
        outTokenAmount = balancerSwapIn(inToken, outToken, inTokenAmount, _minOutputTokenBought, _maxPrice);

        // if _outputToken is cUSD redeem cUSDT to cUSD
        if (isCUSD(_outputToken)) {
            outTokenAmount = compoundRedeem(outTokenAmount);
        }
        emit ExchangeSwap(_inputTokenSold.toUint(), outTokenAmount.toUint());

        //___2. transfer back to sender
        _transfer(_outputToken, sender, outTokenAmount);
    }

    function implSwapOutput(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal memory _outputTokenBought,
        Decimal.decimal memory _maxInputTokenSold,
        Decimal.decimal memory _maxPrice
    ) internal returns (Decimal.decimal memory) {
        address sender = _msgSender();
        Decimal.decimal memory outTokenBought = _outputTokenBought;

        //___0. if _outputToken is cUSD, get cUSDT amount for Balancer
        if (isCUSD(_outputToken)) {
            outTokenBought = compoundCTokenAmount(outTokenBought);
        }

        IERC20 inToken = balancerAcceptableToken(_inputToken);
        IERC20 outToken = balancerAcceptableToken(_outputToken);
        //___1. calc how much input tokens needed by given outTokenBought,
        Decimal.decimal memory expectedTokenInAmount = calcBalancerInGivenOut(
            address(inToken),
            address(outToken),
            outTokenBought
        );
        require(_maxInputTokenSold.cmp(expectedTokenInAmount) >= 0, "max input amount less than expected");

        //___2 transfer input tokens to exchangeWrapper
        // if _inputToken is cUSD, mint cUSDT for Balancer
        if (isCUSD(_inputToken)) {
            Decimal.decimal memory underlyingAmount = compoundUnderlyingAmount(expectedTokenInAmount);
            _transferFrom(_inputToken, sender, address(this), underlyingAmount);
            compoundMint(underlyingAmount);
        } else {
            _transferFrom(_inputToken, sender, address(this), expectedTokenInAmount);
        }

        //___3. swap
        Decimal.decimal memory requiredInAmount = balancerSwapOut(
            inToken,
            outToken,
            outTokenBought,
            _maxInputTokenSold,
            _maxPrice
        );

        // if _outputToken is cUSD, redeem cUSDT to cUSD
        if (isCUSD(_outputToken)) {
            compoundRedeemUnderlying(_outputTokenBought);
        }
        emit ExchangeSwap(requiredInAmount.toUint(), _outputTokenBought.toUint());

        //___4. transfer back to sender
        _transfer(_outputToken, sender, _outputTokenBought);

        return requiredInAmount;
    }

    function balancerSwapIn(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal memory _inputTokenSold,
        Decimal.decimal memory _minOutputTokenBought,
        Decimal.decimal memory _maxPrice
    ) internal returns (Decimal.decimal memory) {
        // if max price is 0, set to (DEFAULT_MAX_PRICE_SLIPPAGE x spot price)
        if (_maxPrice.toUint() == 0) {
            uint256 spotPrice = balancerPool.getSpotPrice(address(_inputToken), address(_outputToken));
            _maxPrice = Decimal.decimal(spotPrice).mulD(Decimal.decimal(DEFAULT_MAX_PRICE_SLIPPAGE));
        }
        _approve(IERC20(_inputToken), address(balancerPool), _inputTokenSold);

        // swap
        uint256 tokeSold = _toUint(_inputToken, _inputTokenSold);
        (uint256 outAmountInSelfDecimals, ) = balancerPool.swapExactAmountIn(
            address(_inputToken),
            tokeSold,
            address(_outputToken),
            _toUint(_outputToken, _minOutputTokenBought),
            _maxPrice.toUint()
        );
        require(outAmountInSelfDecimals > 0, "Balancer exchange error");
        emit BalancerSwap(tokeSold, outAmountInSelfDecimals);

        return _toDecimal(_outputToken, outAmountInSelfDecimals);
    }

    function balancerSwapOut(
        IERC20 _inputToken,
        IERC20 _outputToken,
        Decimal.decimal memory _outputTokenBought,
        Decimal.decimal memory _maxInputTokenSold,
        Decimal.decimal memory _maxPrice
    ) internal returns (Decimal.decimal memory tokenAmountIn) {
        // if max price is 0, set to (DEFAULT_MAX_PRICE_SLIPPAGE x spot price)
        if (_maxPrice.toUint() == 0) {
            uint256 spotPrice = balancerPool.getSpotPrice(address(_inputToken), address(_outputToken));
            _maxPrice = Decimal.decimal(spotPrice).mulD(Decimal.decimal(DEFAULT_MAX_PRICE_SLIPPAGE));
        }
        _approve(IERC20(_inputToken), address(balancerPool), _maxInputTokenSold);

        // swap
        uint256 tokenBought = _toUint(_outputToken, _outputTokenBought);
        uint256 maxTokenSold = _toUint(_inputToken, _maxInputTokenSold);
        (uint256 inAmountInSelfDecimals, ) = balancerPool.swapExactAmountOut(
            address(_inputToken),
            maxTokenSold,
            address(_outputToken),
            tokenBought,
            _maxPrice.toUint()
        );
        require(inAmountInSelfDecimals > 0, "Balancer exchange error");
        emit BalancerSwap(inAmountInSelfDecimals, tokenBought);

        return _toDecimal(_inputToken, inAmountInSelfDecimals);
    }

    function compoundMint(Decimal.decimal memory _underlyingAmount)
        internal
        returns (Decimal.decimal memory mintedAmount)
    {
        // https://compound.finance/docs/ctokens#mint
        uint256 underlyingAmountInSelfDecimals = _toUint(cUSD, _underlyingAmount);
        require(compoundCUsdt.mint(underlyingAmountInSelfDecimals) == 0, "Compound mint error");

        mintedAmount = compoundCTokenAmount(_underlyingAmount);
        uint256 cTokenAmountIn8Decimals = _toUint(IERC20(address(compoundCUsdt)), mintedAmount);
        emit CompoundMint(underlyingAmountInSelfDecimals, cTokenAmountIn8Decimals);
    }

    function compoundRedeem(Decimal.decimal memory _cTokenAmount)
        internal
        returns (Decimal.decimal memory outUnderlyingAmount)
    {
        // https://compound.finance/docs/ctokens#redeem
        uint256 cTokenAmountIn8Decimals = _toUint(IERC20(address(compoundCUsdt)), _cTokenAmount);
        require(compoundCUsdt.redeem(cTokenAmountIn8Decimals) == 0, "Compound redeem error");

        outUnderlyingAmount = compoundUnderlyingAmount(_cTokenAmount);
        uint256 underlyingAmountInSelfDecimals = _toUint(cUSD, outUnderlyingAmount);
        emit CompoundRedeem(underlyingAmountInSelfDecimals, cTokenAmountIn8Decimals);
    }

    function compoundRedeemUnderlying(Decimal.decimal memory _underlyingAmount)
        internal
        returns (Decimal.decimal memory outCTokenAmount)
    {
        // https://compound.finance/docs/ctokens#redeem-underlying
        uint256 underlyingTokenIn6Decimals = _toUint(cUSD, _underlyingAmount);
        require(compoundCUsdt.redeemUnderlying(underlyingTokenIn6Decimals) == 0, "Compound redeemUnderlying error");

        outCTokenAmount = compoundCTokenAmount(_underlyingAmount);
        uint256 cTokenAmountIn8Decimals = _toUint(IERC20(address(compoundCUsdt)), outCTokenAmount);
        emit CompoundRedeem(underlyingTokenIn6Decimals, cTokenAmountIn8Decimals);
    }

    function compoundUnderlyingAmount(Decimal.decimal memory _cTokenAmount)
        internal
        view
        returns (Decimal.decimal memory underlyingAmount)
    {
        // The current exchange rate as an unsigned integer, scaled by 1e18.
        // ** calculation of decimals between tokens is under exchangeRateStored()
        uint256 exchangeRate = compoundCUsdt.exchangeRateStored();
        uint256 cTokenIn8Decimals = _toUint(IERC20(address(compoundCUsdt)), _cTokenAmount);

        // The amount of underlying tokens received is equal to the quantity of cTokens,
        // multiplied by the current Exchange Rate
        Decimal.decimal memory underlyingTokenIn6Decimals = Decimal.decimal(cTokenIn8Decimals).mulD(
            Decimal.decimal(exchangeRate)
        );
        underlyingAmount = _toDecimal(cUSD, underlyingTokenIn6Decimals.toUint());
    }

    function compoundCTokenAmount(Decimal.decimal memory _underlyingAmount)
        internal
        view
        returns (Decimal.decimal memory cTokenAmount)
    {
        // The current exchange rate as an unsigned integer, scaled by 1e18.
        // ** calculation of decimals between tokens is under exchangeRateStored()
        uint256 exchangeRate = compoundCUsdt.exchangeRateStored();
        uint256 underlyingTokenIn6Decimals = _toUint(cUSD, _underlyingAmount);

        // The amount of cTokens is equal to the quantity of underlying tokens received,
        // divided by the current Exchange Rate
        uint256 cTokenIn8Decimals = Decimal
            .decimal(underlyingTokenIn6Decimals)
            .divD(Decimal.decimal(exchangeRate))
            .toUint();
        cTokenAmount = _toDecimal(IERC20(address(compoundCUsdt)), cTokenIn8Decimals);
    }

    function balancerAcceptableToken(IERC20 _token) internal view returns (IERC20) {
        if (isCUSD(_token)) {
            return IERC20(address(compoundCUsdt));
        }
        return _token;
    }

    function calcBalancerInGivenOut(
        address _inToken,
        address _outToken,
        Decimal.decimal memory _givenOutAmount
    ) internal view returns (Decimal.decimal memory) {
        uint256 givenOut = _toUint(IERC20(_outToken), _givenOutAmount);
        uint256 inWeight = balancerPool.getDenormalizedWeight(_inToken);
        uint256 outWeight = balancerPool.getDenormalizedWeight(_outToken);
        uint256 inBalance = balancerPool.getBalance(_inToken);
        uint256 outBalance = balancerPool.getBalance(_outToken);
        uint256 expectedTokenInAmount = balancerPool.calcInGivenOut(
            inBalance,
            inWeight,
            outBalance,
            outWeight,
            givenOut,
            balancerPool.getSwapFee()
        );
        return _toDecimal(IERC20(_inToken), expectedTokenInAmount);
    }

    function implGetSpotPrice(IERC20 _inputToken, IERC20 _outputToken) internal view returns (Decimal.decimal memory) {
        if (_inputToken == _outputToken) return Decimal.one();

        IERC20 inToken = balancerAcceptableToken(_inputToken);
        IERC20 outToken = balancerAcceptableToken(_outputToken);
        uint256 spotPrice = balancerPool.getSpotPrice(address(inToken), address(outToken));

        // the amount returned from getSpotPrice includes decimals difference between tokens.
        // for example, input/output token pair, USDC(8 decimals)/BAT(18 decimals) and 2 USDC buy 1 BAT,
        // it returns 0.5e-10*e18, in the other direction(BAT/USDC), it returns 2e10*e18
        Decimal.decimal memory price = Decimal.decimal(spotPrice);
        uint256 decimalsOfInput = _getTokenDecimals(address(inToken));
        uint256 decimalsOfOutput = _getTokenDecimals(address(outToken));
        if (decimalsOfInput < decimalsOfOutput) {
            price = _toDecimal(inToken, price.toUint());
        } else if (decimalsOfInput > decimalsOfOutput) {
            price = Decimal.decimal(_toUint(outToken, price));
        }

        // compoundUnderlyingAmount gets n underlying tokens by given m cTokens
        // if input token is cUSD, spot price is 0.5(cUSDT/BAT). The price of USDT/BAT would be 0.5 x n
        // if output token is cUSD, spot price is 2(BAT/cUSDT) then price is 2/n
        if (isCUSD(_inputToken)) {
            return price.mulD(compoundUnderlyingAmount(Decimal.one()));
        } else if (isCUSD(_outputToken)) {
            return price.divD(compoundUnderlyingAmount(Decimal.one()));
        }
        return price;
    }

    function isCUSD(IERC20 _token) internal view returns (bool) {
        if (cUSD == _token) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { Decimal } from "../utils/Decimal.sol";
import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IExchangeWrapper {
    function swapInput(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata inputTokenSold,
        Decimal.decimal calldata minOutputTokenBought,
        Decimal.decimal calldata maxPrice
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata outputTokenBought,
        Decimal.decimal calldata maxInputTokeSold,
        Decimal.decimal calldata maxPrice
    ) external returns (Decimal.decimal memory);

    function getInputPrice(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata inputTokenSold
    ) external view returns (Decimal.decimal memory);

    function getOutputPrice(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata outputTokenBought
    ) external view returns (Decimal.decimal memory);

    function getSpotPrice(IERC20 inputToken, IERC20 outputToken) external view returns (Decimal.decimal memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;
    using SafeMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { Decimal } from "./Decimal.sol";

abstract contract DecimalERC20 {
    using SafeMath for uint256;
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private decimalMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // INTERNAL functions
    //

    // CAUTION: do not input _from == _to s.t. this function will always fail
    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, roundedDownValue));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: transfer failed");
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, roundedDownValue));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: transferFrom failed");
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        // to be compatible with some erc20 tokens like USDT
        __approve(_token, _spender, Decimal.zero());
        __approve(_token, _spender, _value);
    }

    //
    // VIEW
    //
    function _allowance(
        IERC20 _token,
        address _owner,
        address _spender
    ) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.allowance(_owner, _spender));
    }

    function _balanceOf(IERC20 _token, address _owner) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.balanceOf(_owner));
    }

    function _totalSupply(IERC20 _token) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.totalSupply());
    }

    function _toDecimal(IERC20 _token, uint256 _number) internal view returns (Decimal.decimal memory) {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return Decimal.decimal(_number.div(10**(tokenDecimals.sub(18))));
        }

        return Decimal.decimal(_number.mul(10**(uint256(18).sub(tokenDecimals))));
    }

    function _toUint(IERC20 _token, Decimal.decimal memory _decimal) internal view returns (uint256) {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return _decimal.toUint().mul(10**(tokenDecimals.sub(18)));
        }
        return _decimal.toUint().div(10**(uint256(18).sub(tokenDecimals)));
    }

    function _getTokenDecimals(address _token) internal view returns (uint256) {
        uint256 tokenDecimals = decimalMap[_token];
        if (tokenDecimals == 0) {
            (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()"));
            require(success && data.length != 0, "DecimalERC20: get decimals failed");
            tokenDecimals = abi.decode(data, (uint256));
        }
        return tokenDecimals;
    }

    //
    // PRIVATE
    //
    function _updateDecimal(address _token) private {
        uint256 tokenDecimals = _getTokenDecimals(_token);
        if (decimalMap[_token] != tokenDecimals) {
            decimalMap[_token] = tokenDecimals;
        }
    }

    function __approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) private {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _toUint(_token, _value)));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: approve failed");
    }

    // To prevent from deflationary token, check receiver's balance is as expectation.
    function _validateBalance(
        IERC20 _token,
        address _to,
        uint256 _roundedDownValue,
        Decimal.decimal memory _balanceBefore
    ) private view {
        require(
            _balanceOf(_token, _to).cmp(_balanceBefore.addD(_toDecimal(_token, _roundedDownValue))) == 0,
            "DecimalERC20: balance inconsistent"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMath for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { ContextUpgradeSafe } from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

// copy from PerpFiOwnableUpgrade, only modify naming
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract XadeOwnableUpgrade is ContextUpgradeSafe {
    address private _owner;
    address private _candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function candidate() public view returns (address) {
        return _candidate;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "XadeOwnableUpgrade: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "XadeOwnableUpgrade: zero address");
        require(newOwner != _owner, "XadeOwnableUpgrade: same as original");
        require(newOwner != _candidate, "XadeOwnableUpgrade: same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "XadeOwnableUpgrade: candidate is zero address");
        require(_candidate == _msgSender(), "XadeOwnableUpgrade: not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    uint256[50] private __gap;
}