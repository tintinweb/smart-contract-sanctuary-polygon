// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IKSwapRouter} from '../Interface/IKSwapRouter.sol';
import {IMockERC20} from './IMockERC20.sol';
import {IPriceOracleGetter} from '../Interface/IPriceOracleGetter.sol';
import {MathUtils} from '../Library/Math/MathUtils.sol';
import {WadRayMath} from '../Library/Math/WadRayMath.sol';

contract MockSwap is IKSwapRouter {
  using WadRayMath for uint256;

  IPriceOracleGetter private _oracle;

  constructor(address oracle) {
    _oracle = IPriceOracleGetter(oracle);
  }

  // NOTE: in mockSwap this function is not used, and is incomplete
  function SwapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address recipient
  ) external override returns (uint256 _amountIn, uint256 _amountOut) {
    IMockERC20(tokenOut).faucet(address(this), amountOut);
    _amountIn = 10**IMockERC20(tokenIn).decimals();
    _amountIn = (_amountIn * amountOut * _oracle.getAssetPrice(tokenOut)) / _oracle.getAssetPrice(tokenIn);
    _amountIn = _amountIn / (10**IMockERC20(tokenOut).decimals());
    _amountOut = amountOut;
    IMockERC20(tokenOut).transfer(recipient, amountOut);
  }

  function SwapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address recipient
  ) external override returns (uint256 _amountIn, uint256 _amountOut) {
    
    _amountOut = 10**IMockERC20(tokenOut).decimals();
    _amountOut = (_amountOut * amountIn * _oracle.getAssetPrice(tokenIn)) / _oracle.getAssetPrice(tokenOut);
    _amountOut = _amountOut / (10**IMockERC20(tokenIn).decimals());
    _amountIn = amountIn;
    IMockERC20(tokenOut).faucet(address(this), _amountOut);
    IMockERC20(tokenOut).transfer(recipient, _amountOut);
  }

  function GetQuote(uint amountA, uint reserveA, uint reserveB)
    external
    view
    override
    returns (uint amountB)
  {

  }

  function GetRelativePrice(
    address tokenA,
    address tokenB
  ) external view override returns (uint256) {

  }

  function GetRelativeTWAP(
    address tokenA,
    address tokenB,
    uint256 timeInterval
  ) external view override returns (uint256) {

  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IKSwapRouter {
  function SwapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address recipient
  ) external returns (uint256 _amountIn, uint256 _amountOut);

  function SwapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address recipient
  ) external returns (uint256 _amountIn, uint256 _amountOut);

  function GetQuote(uint amountA, uint reserveA, uint reserveB) external view returns (uint amountB);

  /**
   * @dev get the relative price of price A / price B, in wad
   * @param tokenA the address of first token
   * @param tokenB the address of second token
   * @return price
   */ 
  function GetRelativePrice(
    address tokenA,
    address tokenB
  ) external view returns (uint256);

  /**
   * @dev get the time-weighted average relative price of price A / price B, in wad
   * @param tokenA the address of first token
   * @param tokenB the address of second token
   * @return price
   */ 
  function GetRelativeTWAP(
    address tokenA,
    address tokenB,
    uint256 timeInterval
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 /**
 *  basic interface of ERC20 token
  */
interface IMockERC20 {
  function mint(address account, uint256 amount) external;
  function faucet(address spender, uint256 amount) external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH (wad)
   */
  function getAssetPrice(address asset) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from '../../Dependency/openzeppelin/SafeMath.sol';
import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp.sub(uint256(lastUpdateTimestamp));

    return (rate.mul(timeDifference) / SECONDS_PER_YEAR).add(WadRayMath.ray());
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

    return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Errors} from '../Helper/Errors.sol';

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

    require(a <= (type(uint256).max - halfWAD) / b, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

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

    require(a <= (type(uint256).max - halfRAY) / b, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));

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
    require(result >= halfRatio, Errors.GetError(Errors.Error.MATH_ADDITION_OVERFLOW));

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW));
    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

import {Strings} from "../../Dependency/openzeppelin/Strings.sol";

library Errors {
    using Strings for uint256;
    enum Error {
        /** KTOKEN, DTOKEN*/
        CALLER_MUST_BE_LENDING_POOL, // 0
        INVALID_BURN_AMOUNT,
        INVALID_MINT_AMOUNT,
        BORROW_ALLOWANCE_NOT_ENOUGH,
        /** Math library */
        MATH_MULTIPLICATION_OVERFLOW,
        MATH_DIVISION_BY_ZERO, // 5
        MATH_ADDITION_OVERFLOW,
        /** Configuration */
        LENDING_POOL_EXIST,
        LENDING_POOL_NONEXIST,
        /** Permission */
        CALLER_NOT_MAIN_ADMIN,
        CALLER_NOT_EMERGENCY_ADMIN, // 10
        /** LP */
        LP_NOT_CONTRACT,
        LP_IS_PAUSED,
        LP_POSITION_IS_PAUSED,
        LPC_RESERVE_LIQUIDITY_NOT_0,
        LPC_INVALID_CONFIGURATION, // 15
        LP_NO_MORE_RESERVES_ALLOWED,
        LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR,
        LP_LIQUIDATION_CALL_FAILED,
        LP_CALLER_MUST_BE_AN_KTOKEN,
        LP_LEVERAGE_INVALID, // 20
        LP_POSITION_INVALID,
        LP_LIQUIDATE_LP,
        LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN,
        /** Reserve Logic */
        RL_LIQUIDITY_INDEX_OVERFLOW,
        RL_BORROW_INDEX_OVERFLOW,
        RL_RESERVE_ALREADY_INITIALIZED, // 25
        RL_LIQUIDITY_RATE_OVERFLOW,
        RL_BORROW_RATE_OVERFLOW,
        /** Validation Logic */
        VL_INVALID_AMOUNT,
        VL_NO_ACTIVE_RESERVE,
        VL_NO_ACTIVE_RESERVE_POSITION, // 30
        VL_POSITION_COLLATERAL_NOT_ENABLED,
        VL_POSITION_LONG_NOT_ENABLED,
        VL_POSITION_SHORT_NOT_ENABLED,
        VL_RESERVE_FROZEN,
        VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE, // 35
        VL_TRANSFER_NOT_ALLOWED,
        VL_BORROWING_NOT_ENABLED,
        VL_INVALID_INTEREST_RATE_MODE_SELECTED,
        VL_COLLATERAL_BALANCE_IS_0,
        VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD, // 40
        VL_COLLATERAL_CANNOT_COVER_NEW_BORROW,
        VL_NO_DEBT_OF_SELECTED_TYPE,
        VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF,
        VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0,
        VL_SUPPLY_ALREADY_IN_USE, // 45
        VL_TRADER_ADDRESS_MISMATCH,
        VL_POSITION_NOT_OPEN,
        VL_POSITION_NOT_UNHEALTHY,
        VL_INCONSISTENT_FLASHLOAN_PARAMS,
        /** Collateral Manager */
        CM_NO_ERROR, // 50
        CM_NO_ACTIVE_RESERVE,
        CM_HEALTH_FACTOR_ABOVE_THRESHOLD,
        CM_COLLATERAL_CANNOT_BE_LIQUIDATED,
        CM_CURRRENCY_NOT_BORROWED,
        CM_NOT_ENOUGH_LIQUIDITY, // 55
        /** Liquidation Logic */
        LL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD,
        LL_COLLATERAL_CANNOT_BE_LIQUIDATED,
        LL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER,
        LL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE,
        LL_NO_ERRORS // 60
    }

    function GetError(Error error) internal pure returns (string memory error_string) {
        error_string = Strings.toString(uint(error));
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