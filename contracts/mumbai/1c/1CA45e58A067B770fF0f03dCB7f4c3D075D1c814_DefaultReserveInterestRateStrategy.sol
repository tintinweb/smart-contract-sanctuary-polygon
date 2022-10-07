// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from '../Dependency/openzeppelin/SafeMath.sol';
import {IReserveInterestRateStrategy} from '../Interface/IReserveInterestRateStrategy.sol';
import {WadRayMath} from '../Library/Math/WadRayMath.sol';
import {PercentageMath} from '../Library/Math/PercentageMath.sol';
import {ILendingPoolAddressesProvider} from '../Interface/ILendingPoolAddressesProvider.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * - An instance of this same contract, can't be used across different Aave markets, due to the caching
 *   of the LendingPoolAddressesProvider
 * @author Aave
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
  using WadRayMath for uint256;
  using SafeMath for uint256;
  using PercentageMath for uint256;

  /**
   * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   **/
  uint256 public immutable OPTIMAL_UTILIZATION_RATE;

  /**
   * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
   * 1-optimal utilization rate. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/

  uint256 public immutable EXCESS_UTILIZATION_RATE;

  ILendingPoolAddressesProvider public immutable addressesProvider;

  // Base variable borrow rate when Utilization rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope2;

  constructor(
    ILendingPoolAddressesProvider provider,
    uint256 optimalUtilizationRate,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2
  ) {
    OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
    EXCESS_UTILIZATION_RATE = WadRayMath.ray().sub(optimalUtilizationRate);
    addressesProvider = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
  }

  function variableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function variableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function baseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate.add(_variableRateSlope1).add(_variableRateSlope2);
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param asset The address of the reserve
   * @param liquidityAdded The liquidity added during the operation
   * @param liquidityTaken The liquidity taken during the operation
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate, the stable borrow rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address asset,
    address kToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    override
    returns (
      uint256,
      uint256
    )
  {
    uint256 availableLiquidity = IERC20(asset).balanceOf(kToken);
    //avoid stack too deep
    availableLiquidity = availableLiquidity.add(liquidityAdded).sub(liquidityTaken);

    return
      calculateInterestRates(
        asset,
        availableLiquidity,
        totalVariableDebt,
        reserveFactor
      );
  }

  struct CalcInterestRatesLocalVars {
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 utilizationRate;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations.
   * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
   * New protocol implementation uses the new calculateInterestRates() interface
   * @param asset The address of the reserve
   * @param availableLiquidity The liquidity available in the corresponding kToken
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address asset,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    public
    view
    override
    returns (
      uint256,
      uint256
    )
  {
    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = totalVariableDebt;
    vars.currentVariableBorrowRate = 0;
    vars.currentLiquidityRate = 0;

    vars.utilizationRate = (vars.totalDebt == 0)
      ? 0
      : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));

    if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio =
        vars.utilizationRate.sub(OPTIMAL_UTILIZATION_RATE).rayDiv(EXCESS_UTILIZATION_RATE);

      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(_variableRateSlope1).add(
        _variableRateSlope2.rayMul(excessUtilizationRateRatio)
      );
    } else {
      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(
        vars.utilizationRate.rayMul(_variableRateSlope1).rayDiv(OPTIMAL_UTILIZATION_RATE)
      );
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(
      totalVariableDebt,
      vars.currentVariableBorrowRate
    )
      .rayMul(vars.utilizationRate)
      .percentMul(PercentageMath.PERCENTAGE_FACTOR.sub(reserveFactor));

    return (
      vars.currentLiquidityRate,
      vars.currentVariableBorrowRate
    );
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate
  ) internal pure returns (uint256) {
    uint256 totalDebt = totalVariableDebt;

    if (totalDebt == 0) return 0;

    return currentVariableBorrowRate;
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

interface IReserveInterestRateStrategy {
  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalDebt,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256,
      uint256
    );

  function calculateInterestRates(
    address reserve,
    address kToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256 liquidityRate,
      uint256 borrowRate
    );
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
pragma solidity ^0.8.0;

import {Errors} from '../Helper/Errors.sol';

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW)
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.GetError(Errors.Error.MATH_DIVISION_BY_ZERO));
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.GetError(Errors.Error.MATH_MULTIPLICATION_OVERFLOW)
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress);
  event PoolAdded(address pool_address, address configuratorAddress);
  event LendingPoolUpdated(uint id, address pool, address lending_pool_configurator_address);
  event PoolRemoved(address pool_address);
  event SwapRouterUpdated(address dex);

  function getAllPools() external view returns (address[] memory);

  /**
   * @dev Returns the address of the LendingPool by id
   * @return The LendingPool address, if pool is valid
   **/
  function getLendingPool(uint id) external view returns (address, bool);

  function getLendingPoolID(address pool) external view returns (uint);

  function getLendingPoolConfigurator(address pool) external view returns (address);

  /**
   * @dev Updates the address of the LendingPool
   * @param pool The new LendingPool implementation
   **/
  function setLendingPool(uint id, address pool, address poolConfiguratorAddress) external;

  function addPool(address poolAddress, address poolConfiguratorAddress) external;

  function removePool(address poolAddress) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  function getMainAdmin() external view returns (address);

  function setMainAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracleAddress) external;

  function getSwapRouter() external view returns (address);

  function setSwapRouter(address dex) external;
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