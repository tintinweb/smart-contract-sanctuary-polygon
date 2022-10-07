// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {MathUtils} from '../Library/Math/MathUtils.sol';
import {WadRayMath} from '../Library/Math/WadRayMath.sol';
import {PercentageMath} from '../Library/Math/PercentageMath.sol';
import {IDToken} from '../Interface/IDToken.sol';
import {IKToken} from '../Interface/IKToken.sol';
import {ILendingPool} from '../Interface/ILendingPool.sol';
import {IPriceOracleGetter} from '../Interface/IPriceOracleGetter.sol';
import {IDataProvider} from '../Interface/IDataProvider.sol';
import {Errors} from '../Library/Helper/Errors.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {IERC20Detailed} from '../Dependency/openzeppelin/IERC20Detailed.sol';
import {Address} from '../Dependency/openzeppelin/Address.sol';
import {SafeMath} from '../Dependency/openzeppelin/SafeMath.sol';
import {SafeERC20} from '../Dependency/openzeppelin/SafeERC20.sol';
import {ILendingPoolAddressesProvider} from '../Interface/ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../Library/Type/DataTypes.sol';
import {GenericLogic} from '../Library/Logic/GenericLogic.sol';
import {ValidationLogic} from '../Library/Logic/ValidationLogic.sol';
import {ReserveLogic} from '../Library/Logic/ReserveLogic.sol';

contract DataProvider is IDataProvider {
  using WadRayMath for uint256;

  ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  constructor(ILendingPoolAddressesProvider addressesProvider) {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  function getAllPoolData() external view override returns (PoolData[] memory) {
    address[] memory pools = ADDRESSES_PROVIDER.getAllPools();
    PoolData[] memory poolsData = new PoolData[](pools.length);
    for (uint i = 0; i < pools.length; i++) {
      address pool_address = pools[i];
      poolsData[i] = PoolData(
          pool_address,
          ADDRESSES_PROVIDER.getLendingPoolID(pool_address),
          ILendingPool(pool_address).name(),
          ILendingPool(pool_address).paused()
        );
    }
    return poolsData;
  }

  function getAddressesProvider() external view override returns (ILendingPoolAddressesProvider) {
    return ADDRESSES_PROVIDER;
  }

  function getAllReservesTokens(uint id) external view override returns (TokenData[] memory) {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    ILendingPool pool = ILendingPool(pool_address);
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory reservesTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      reservesTokens[i] = TokenData({
        symbol: IERC20Detailed(reserves[i]).symbol(),
        tokenAddress: reserves[i]
      });
    }
    return reservesTokens;
  }

  function getAllKTokens(uint id) external view override returns (TokenData[] memory) {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    ILendingPool pool = ILendingPool(pool_address);
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory kTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
      kTokens[i] = TokenData({
        symbol: IERC20Detailed(reserveData.kTokenAddress).symbol(),
        tokenAddress: reserveData.kTokenAddress
      });
    }
    return kTokens;
  }

  function getReserveConfigurationData(uint id, address asset)
    external
    view
    override
    returns (
      DataTypes.ReserveConfiguration memory configuration
    )
  {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    configuration =
      ILendingPool(pool_address).getConfiguration(asset);
  }

  function getReserveData(uint id, address asset)
    external
    view
    override
    returns (
      DataTypes.ReserveData memory
    )
  {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    DataTypes.ReserveData memory reserve =
      ILendingPool(pool_address).getReserveData(asset);
    return reserve;
  }

  function getAllReserveData(uint id)
    external
    view
    override
    returns (
      DataTypes.ReserveData[] memory
    )
  {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    ILendingPool pool = ILendingPool(pool_address);
    address[] memory reserves = pool.getReservesList();

    DataTypes.ReserveData[] memory reservesData = new DataTypes.ReserveData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      reservesData[i] = pool.getReserveData(reserves[i]);
    }

    return reservesData;
  }

  function getUserReserveData(uint id, address asset, address user)
    external
    view
    override
    returns (
      uint256 currentKTokenBalance,
      uint256 currentVariableDebt,
      uint256 scaledVariableDebt,
      uint256 liquidityRate,
      bool usageAsCollateralEnabled
    )
  {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    DataTypes.ReserveData memory reserve =
      ILendingPool(pool_address).getReserveData(asset);

    (bool isUsingAsCollateral,) =
      ILendingPool(pool_address).getUserConfiguration(user, reserve.id);

    currentKTokenBalance = IERC20Detailed(reserve.kTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Detailed(reserve.dTokenAddress).balanceOf(user);
    scaledVariableDebt = IDToken(reserve.dTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    usageAsCollateralEnabled = isUsingAsCollateral;
  }

  function getReserveTokensAddresses(uint id, address asset)
    external
    view
    override
    returns (
      address kTokenAddress,
      address variableDebtTokenAddress
    )
  {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    DataTypes.ReserveData memory reserve =
      ILendingPool(pool_address).getReserveData(asset);

    return (
      reserve.kTokenAddress,
      reserve.dTokenAddress
    );
  }

  function getTraderPositions(uint id, address trader) external view override returns (DataTypes.TraderPosition[] memory positions) {
    (address pool_address,) = ADDRESSES_PROVIDER.getLendingPool(id);
    ILendingPool pool = ILendingPool(pool_address);
    return pool.getTraderPositions(trader);
  }

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

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';

interface IDToken is IERC20, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param onBehalfOf The address of the user on which behalf minting has been performed
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;
    event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address asset,
    uint256 amount
  );

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../Dependency/openzeppelin/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';

interface IKToken is IERC20, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` kTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after kTokens are burned
   * @param from The owner of the kTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the kTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints kTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers kTokens in the event of a borrow being liquidated, in case the liquidators reclaims the kToken
   * @param from The address getting liquidated, current owner of the kTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the kToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the underlying asset of this kToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from '../Library/Type/DataTypes.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {IAggregationRouterV4} from './1inch/IAggregationRouterV4.sol';

interface ILendingPool {
  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the kTokens
   * @param amount The amount supplied
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of kTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate
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
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

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
   * @param receivekToken `true` if the liquidators wants to receive the collateral kTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receivekToken
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

  event OpenPosition(
    address trader,
    address collateralTokenAddress,
    address shortTokenAddress,
    uint256 collateralAmount,
    uint256 shortAmount,
    uint256 liquidationThreshold,
    uint id
  );

  event ClosePosition(
    uint256 id,
    address traderAddress,
    address collateralTokenAddress,
    uint256 collateralAmount,
    address shortTokenAddress,
    uint256 shortAmount
  );

  event LiquidationCallPosition(
    uint256 id,
    address liquidator,
    address traderAddress,
    address collateralTokenAddress,
    uint256 collateralAmount,
    address shortTokenAddress,
    uint256 shortAmount
  );

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  /**
   * @dev Supply an `amount` of underlying asset into the reserve, receiving in return overlying kTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 kUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the kTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of kTokens
   *   is a different wallet
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent kTokens owned
   * E.g. User has 100 kUSDC, calls withdraw() and receives 100 USDC, burning the 100 kUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole kToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
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
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral `true` if the user wants to use the supply as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receivekToken `true` if the liquidators wants to receive the collateral kTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receivekToken
  ) external;

  /**
   * @dev Open a position, supply margin and borrow from pool. Traders should 
   * approve pools at first for the transfer of their assets
   * @param collateralAsset The address of asset the trader supply as margin
   * @param shortAsset The address of asset the trader would like to borrow at a leverage
   * @param longAsset The address of asset the pool will hold after swap
   * @param collateralAmount The amount of margin the trader transfers in margin decimals
   * @param leverage The leverage specified by user in ray
   **/
  function openPosition(
    address collateralAsset,
    address shortAsset,
    address longAsset,
    uint256 collateralAmount,
    uint256 leverage,
    uint256 minLongAmountOut,
    address onBehalfOf
  )
    external
    returns (
      DataTypes.TraderPosition memory position
    );

  /**
   * @dev Close a position, swap all margin / pnl into paymentAsset
   * @param positionId The id of position
   * @return paymentAmount The amount of asset to payback user 
   * @return pnl The pnl in ETH (wad)
   **/
  function closePosition(
    uint256 positionId,
    address to,
    uint256 minLongToShortAmountOut,
    uint256 minShortToCollateralAmountOut,
    uint256 minCollateralToShortAmountOut
  )
    external
    returns (
      uint256 paymentAmount,
      int256 pnl
    );

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
  
  /**
   * @dev Close a position, swap all margin / pnl into paymentAsset
   * @param id The id of position
   **/
  function liquidationCallPosition(uint id) external;

  function initReserve(
    address reserve,
    address kTokenAddress,
    address dTokenAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, DataTypes.ReserveConfiguration memory configuration) external;

  function setPositionConfiguration(
    address asset,
    DataTypes.ReservePositionConfiguration calldata positionConfig
  ) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfiguration memory);
  
  function getPositionConfiguration(address asset)
    external
    view
    returns (DataTypes.ReservePositionConfiguration memory);

  function getUserConfiguration(address user, uint256 reserve_id)
    external
    view
    returns (bool reserve_is_collateral, bool reserve_for_borrowing);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized debt
   */
  function getReserveNormalizedDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
  
  function getReservesList() external view returns (address[] memory);

  function getUsersList() external view returns (address[] memory);

  function getTradersList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);

  function name() external view returns (string memory);

  function getTraderPositions(address trader) external view returns (DataTypes.TraderPosition[] memory positions);

  function getPositionData(uint256 id) external view returns (int256 pnl, uint256 healthFactor);
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
pragma experimental ABIEncoderV2;

import {DataTypes} from '../Library/Type/DataTypes.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';

interface IDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  struct PoolData {
    address pool;
    uint id;
    string name;
    bool paused;
  }

  function getAllPoolData() external view returns (PoolData[] memory);
  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);
  function getAllReservesTokens(uint id) external view returns (TokenData[] memory);
  function getAllKTokens(uint id) external view returns (TokenData[] memory);
  function getReserveConfigurationData(uint id, address asset)
    external
    view
    returns (
      DataTypes.ReserveConfiguration memory configuration
    );
  
  function getReserveData(uint id, address asset)
    external
    view
    returns (
      DataTypes.ReserveData memory
    );
  
  function getAllReserveData(uint id)
    external
    view
    returns (
      DataTypes.ReserveData[] memory
    );
  
  function getUserReserveData(uint id, address asset, address user)
    external
    view
    returns (
      uint256 currentKTokenBalance,
      uint256 currentVariableDebt,
      uint256 scaledVariableDebt,
      uint256 liquidityRate,
      bool usageAsCollateralEnabled
    );
  
  function getReserveTokensAddresses(uint id, address asset)
    external
    view
    returns (
      address kTokenAddress,
      address variableDebtTokenAddress
    );

  function getTraderPositions(uint id, address trader)
    external
    view
    returns (DataTypes.TraderPosition[] memory positions);
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

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    ReserveConfiguration configuration;
    ReservePositionConfiguration positionConfiguration;
    // the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    // (variable) borrow index. Expressed in ray
    uint128 borrowIndex;
    // the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    // the current borrow rate. Expressed in ray
    uint128 currentBorrowRate;
    // the timestamp 
    uint40 lastUpdateTimestamp;
    // interest token address
    address kTokenAddress;
    // debt token address
    address dTokenAddress;
    // address of the interest rate strategy
    address interestRateStrategyAddress;
    // the id of the reserve
    uint256 id;
  }

  struct ReserveConfiguration {
    // loan-to-value
    uint256 ltv;
    // the liquidation threshold
    uint256 liquidationThreshold;
    // the liquidation bonus
    uint256 liquidationBonus;
    // the decimals
    uint8 decimals;
    // reserve is active
    bool active;
    // reserve is frozen
    bool frozen;
    // borrowing is enabled
    bool borrowingEnabled;
    // reserve factor
    uint256 reserveFactor;
  }

  struct UserConfigurationMap {
    // uint256 data;
    mapping(uint256 => bool) isUsingAsCollateral;
    mapping(uint256 => bool) isBorrowing;
  }

  struct ReservePositionConfiguration {
    // position-related is active
    bool active;
    // position collateral is enabled
    bool collateralEnabled;
    // position long is enabled
    bool longEnabled;
    // position short is enabled
    bool shortEnabled;
  }

  struct TraderPosition {
    // the trader
    address traderAddress;
    // the token as margin
    address collateralTokenAddress;
    // the token to borrow
    address shortTokenAddress;
    // the token held
    address longTokenAddress;
    // the amount of provided margin
    uint256 collateralAmount;
    // the amount of borrowed asset
    uint256 shortAmount;
    // the amount of held asset
    uint256 longAmount;
    // the liquidationThreshold at trade
    uint256 liquidationThreshold;
    // the id of position
    uint256 id;
    // position is open
    bool isOpen;
  }

  enum InterestRateMode {NONE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../Dependency/openzeppelin/IERC20.sol';
import {SafeMath} from '../../Dependency/openzeppelin/SafeMath.sol';
import {SafeERC20} from '../../Dependency/openzeppelin/SafeERC20.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {WadRayMath} from '../Math/WadRayMath.sol';
import {PercentageMath} from '../Math/PercentageMath.sol';
import {IPriceOracleGetter} from '../../Interface/IPriceOracleGetter.sol';
import {IAggregationRouterV4} from '../../Interface/1inch/IAggregationRouterV4.sol';
import {DataTypes} from '../Type/DataTypes.sol';

library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether; // 1e18

  struct balanceDecreaseAllowedLocalVars {
    uint256 decimals;
    uint256 liquidationThreshold;
    uint256 totalCollateralInETH;
    uint256 totalDebtInETH;
    uint256 avgLiquidationThreshold;
    uint256 amountToDecreaseInETH;
    uint256 collateralBalanceAfterDecrease;
    uint256 liquidationThresholdAfterDecrease;
    uint256 healthFactorAfterDecrease;
    bool reserveUsageAsCollateralEnabled;
  }

  function calculateAmountToShort(
    address supplyTokenAddress,
    address borrowTokenAddress,
    uint256 supplyTokenAmount,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address oracle
  ) external view returns (uint256 amountToShort) {
    IPriceOracleGetter _oracle = IPriceOracleGetter(oracle);
    uint256 supplyUnitPrice = _oracle.getAssetPrice(supplyTokenAddress);
    uint8 supplyDecimals = reservesData[supplyTokenAddress].configuration.decimals;
    uint256 shortUnitPrice = _oracle.getAssetPrice(borrowTokenAddress);
    uint8 shortDecimals = reservesData[borrowTokenAddress].configuration.decimals;

    amountToShort = supplyTokenAmount.mul(supplyUnitPrice).mul(10**shortDecimals);
    amountToShort = amountToShort.div(shortUnitPrice).div(10**supplyDecimals);
  }

  function getPnL(
    DataTypes.TraderPosition storage position,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address oracle
  )
    external
    view
    returns (int256 pnl)
  {
    IPriceOracleGetter _oracle = IPriceOracleGetter(oracle);
    uint256 shortUnitPrice = _oracle.getAssetPrice(position.shortTokenAddress);
    uint8 shortDecimals = reservesData[position.shortTokenAddress].configuration.decimals;
    uint256 shortValue = shortUnitPrice.mul(position.shortAmount).div(10**shortDecimals);

    uint256 longUnitPrice = _oracle.getAssetPrice(position.longTokenAddress);
    uint8 longDecimals = reservesData[position.longTokenAddress].configuration.decimals;
    uint256 longValue = longUnitPrice.mul(position.longAmount).div(10**longDecimals);
    
    pnl = int256(longValue) - int256(shortValue);
  }

  // returns health factor in wad
  // NOTE: since liquidation call's asset is not directly swapped using the DEX,
  // we use chainlink price
  function calculatePositionHealthFactor(
    DataTypes.TraderPosition storage position,
    uint256 positionLiquidationThreshold,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address oracle
  )
    external
    view
    returns (uint256 healthFactor)
  {
    uint256 shortValue;
    uint256 longValue;
    uint256 marginValue;
    IPriceOracleGetter _oracle = IPriceOracleGetter(oracle);
    {
      uint256 shortUnitPrice = _oracle.getAssetPrice(position.shortTokenAddress);
      uint8 shortDecimals = reservesData[position.shortTokenAddress].configuration.decimals;
      shortValue = shortUnitPrice.mul(position.shortAmount).div(10**shortDecimals);
    }
    {    
      uint256 longUnitPrice = _oracle.getAssetPrice(position.longTokenAddress);
      uint8 longDecimals = reservesData[position.longTokenAddress].configuration.decimals;
      longValue = longUnitPrice.mul(position.longAmount).div(10**longDecimals);
    }
    {
      uint256 marginUnitPrice = _oracle.getAssetPrice(position.collateralTokenAddress);
      uint8 marginDecimals = reservesData[position.collateralTokenAddress].configuration.decimals;
      marginValue = marginUnitPrice.mul(position.collateralAmount).div(10**marginDecimals);
    }
    healthFactor = marginValue.add(longValue).sub(shortValue);
    healthFactor = healthFactor.wadDiv(marginValue.rayMul(positionLiquidationThreshold));
  }

  /**
   * @dev Checks if a specific balance decrease is allowed
   * (i.e. doesn't bring the user borrow position health factor under HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @param amount The amount to decrease
   * @param reservesData The data of all the reserves
   * @param userConfig The user configuration
   * @param reserves The list of all the active reserves
   * @param oracle The address of the oracle contract
   * @return true if the decrease of the balance is allowed
   **/
  function balanceDecreaseAllowed(
    address asset,
    address user,
    uint256 amount,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves,
    uint256 reservesCount,
    address oracle
  ) external view returns (bool) {
    {
      bool isBorrowingAny = false;
      for (uint i = 0; i < reservesCount; i++) {
        if (userConfig.isBorrowing[i] == true) {
          isBorrowingAny = true;
          break;
        }
      }
      if (!isBorrowingAny || !userConfig.isUsingAsCollateral[reservesData[asset].id]) {
        return true;
      }
    }

    balanceDecreaseAllowedLocalVars memory vars;

    vars.liquidationThreshold = reservesData[asset].configuration.liquidationThreshold;
    vars.decimals = reservesData[asset].configuration.decimals;

    if (vars.liquidationThreshold == 0) {
      return true;
    }

    (
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      ,
      vars.avgLiquidationThreshold,

    ) = calculateUserAccountData(user, reservesData, userConfig, reserves, reservesCount, oracle);

    if (vars.totalDebtInETH == 0) {
      return true;
    }

    vars.amountToDecreaseInETH = IPriceOracleGetter(oracle).getAssetPrice(asset).mul(amount).div(
      10**vars.decimals
    );

    vars.collateralBalanceAfterDecrease = vars.totalCollateralInETH.sub(vars.amountToDecreaseInETH);

    //if there is a borrow, there can't be 0 collateral
    if (vars.collateralBalanceAfterDecrease == 0) {
      return false;
    }

    vars.liquidationThresholdAfterDecrease = vars
      .totalCollateralInETH
      .mul(vars.avgLiquidationThreshold)
      .sub(vars.amountToDecreaseInETH.mul(vars.liquidationThreshold))
      .div(vars.collateralBalanceAfterDecrease);

    uint256 healthFactorAfterDecrease =
      calculateHealthFactorFromBalances(
        vars.collateralBalanceAfterDecrease,
        vars.totalDebtInETH,
        vars.liquidationThresholdAfterDecrease
      );

    return healthFactorAfterDecrease >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
  }

  struct CalculateUserAccountDataVars {
    uint256 reserveUnitPrice;
    uint256 tokenUnit;
    uint256 compoundedLiquidityBalance;
    uint256 compoundedBorrowBalance;
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 i;
    uint256 healthFactor;
    uint256 totalCollateralInETH;
    uint256 totalDebtInETH;
    uint256 avgLtv;
    uint256 avgLiquidationThreshold;
    uint256 reservesLength;
    bool healthFactorBelowThreshold;
    address currentReserveAddress;
    bool usageAsCollateralEnabled;
    bool userUsesReserveAsCollateral;
  }

  /**
   * @dev Calculates the user data across the reserves.
   * this includes the total liquidity/collateral/borrow balances in ETH,
   * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
   * @param user The address of the user
   * @param reservesData Data of all the reserves
   * @param userConfig The configuration of the user
   * @param reserves The list of the available reserves
   * @param oracle The price oracle address
   * @return The total collateral and total debt of the user in ETH, the avg ltv, liquidation threshold and the HF
   **/
  function calculateUserAccountData(
    address user,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves,
    uint256 reservesCount,
    address oracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    {
      bool isEmpty = true;
      for (uint i = 0; i < reservesCount; i++) {
        if (userConfig.isUsingAsCollateral[i] == true || userConfig.isBorrowing[i] == true) {
          isEmpty = false;
          break;
        }
      }
      if (isEmpty) {
        return (0, 0, 0, 0, type(uint256).max);
      }
    }

    CalculateUserAccountDataVars memory vars;
    for (vars.i = 0; vars.i < reservesCount; vars.i++) {
      if (!(userConfig.isUsingAsCollateral[vars.i] || userConfig.isBorrowing[vars.i])) {
        continue;
      }

      vars.currentReserveAddress = reserves[vars.i];
      DataTypes.ReserveData memory currentReserve = reservesData[vars.currentReserveAddress];

      vars.ltv = currentReserve.configuration.ltv;
      vars.liquidationThreshold = currentReserve.configuration.liquidationThreshold;
      vars.decimals = currentReserve.configuration.decimals;

      vars.tokenUnit = 10**vars.decimals;
      vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(vars.currentReserveAddress);

      if (vars.liquidationThreshold != 0 && userConfig.isUsingAsCollateral[vars.i]) {
        vars.compoundedLiquidityBalance = IERC20(currentReserve.kTokenAddress).balanceOf(user);

        uint256 liquidityBalanceETH =
          vars.reserveUnitPrice.mul(vars.compoundedLiquidityBalance).div(vars.tokenUnit);

        vars.totalCollateralInETH = vars.totalCollateralInETH.add(liquidityBalanceETH);

        vars.avgLtv = vars.avgLtv.add(liquidityBalanceETH.mul(vars.ltv));
        vars.avgLiquidationThreshold = vars.avgLiquidationThreshold.add(
          liquidityBalanceETH.mul(vars.liquidationThreshold)
        );
      }

      if (userConfig.isBorrowing[vars.i]) {
        vars.compoundedBorrowBalance = 
          IERC20(currentReserve.dTokenAddress).balanceOf(user);

        vars.totalDebtInETH = vars.totalDebtInETH.add(
          vars.reserveUnitPrice.mul(vars.compoundedBorrowBalance).div(vars.tokenUnit)
        );
      }
    }

    vars.avgLtv = vars.totalCollateralInETH > 0 ? vars.avgLtv.div(vars.totalCollateralInETH) : 0;
    vars.avgLiquidationThreshold = vars.totalCollateralInETH > 0
      ? vars.avgLiquidationThreshold.div(vars.totalCollateralInETH)
      : 0;

    vars.healthFactor = calculateHealthFactorFromBalances(
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      vars.avgLiquidationThreshold
    );
    return (
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      vars.avgLtv,
      vars.avgLiquidationThreshold,
      vars.healthFactor
    );
  }

  /**
   * @dev Calculates the health factor from the corresponding balances
   * @param totalCollateralInETH The total collateral in ETH
   * @param totalDebtInETH The total debt in ETH
   * @param liquidationThreshold The avg liquidation threshold
   * @return The health factor calculated from the balances provided
   **/
  function calculateHealthFactorFromBalances(
    uint256 totalCollateralInETH,
    uint256 totalDebtInETH,
    uint256 liquidationThreshold
  ) internal pure returns (uint256) {
    if (totalDebtInETH == 0) return type(uint256).max;

    return (totalCollateralInETH.percentMul(liquidationThreshold)).wadDiv(totalDebtInETH);
  }

  /**
   * @dev Calculates the equivalent amount in ETH that an user can borrow, depending on the available collateral and the
   * average Loan To Value
   * @param totalCollateralInETH The total collateral in ETH
   * @param totalDebtInETH The total borrow balance
   * @param ltv The average loan to value
   * @return the amount available to borrow in ETH for the user
   **/

  function calculateAvailableBorrowsETH(
    uint256 totalCollateralInETH,
    uint256 totalDebtInETH,
    uint256 ltv
  ) internal pure returns (uint256) {
    uint256 availableBorrowsETH = totalCollateralInETH.percentMul(ltv);

    if (availableBorrowsETH < totalDebtInETH) {
      return 0;
    }

    availableBorrowsETH = availableBorrowsETH.sub(totalDebtInETH);
    return availableBorrowsETH;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {Errors} from '../Helper/Errors.sol';
import {IERC20} from '../../Dependency/openzeppelin/IERC20.sol';
import {SafeMath} from '../../Dependency/openzeppelin/SafeMath.sol';
import {SafeERC20} from '../../Dependency/openzeppelin/SafeERC20.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {WadRayMath} from '../Math/WadRayMath.sol';
import {PercentageMath} from '../Math/PercentageMath.sol';
import {DataTypes} from '../Type/DataTypes.sol';

library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  function validateOpenPosition(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveData storage shortReserve,
    DataTypes.ReserveData storage longReserve,
    uint256 collateralAmount,
    uint256 amountToShort
  ) external view {
    require(collateralAmount != 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));
    require(collateralReserve.configuration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));
    require(!collateralReserve.configuration.frozen, Errors.GetError(Errors.Error.VL_RESERVE_FROZEN));
    require(collateralReserve.positionConfiguration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE_POSITION));
    require(collateralReserve.positionConfiguration.collateralEnabled, Errors.GetError(Errors.Error.VL_POSITION_COLLATERAL_NOT_ENABLED));

    require(longReserve.configuration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));
    require(!longReserve.configuration.frozen, Errors.GetError(Errors.Error.VL_RESERVE_FROZEN));
    require(longReserve.positionConfiguration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE_POSITION));
    require(longReserve.positionConfiguration.longEnabled, Errors.GetError(Errors.Error.VL_POSITION_LONG_NOT_ENABLED));

    require(shortReserve.configuration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));
    require(!shortReserve.configuration.frozen, Errors.GetError(Errors.Error.VL_RESERVE_FROZEN));
    require(amountToShort != 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));
    require(shortReserve.positionConfiguration.active, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE_POSITION));
    require(shortReserve.positionConfiguration.shortEnabled, Errors.GetError(Errors.Error.VL_POSITION_SHORT_NOT_ENABLED));
    require(shortReserve.configuration.borrowingEnabled, Errors.GetError(Errors.Error.VL_BORROWING_NOT_ENABLED));
  }

  function validateClosePosition(
    address traderAddress,
    DataTypes.TraderPosition storage position
  ) external view {
    address positionTrader = position.traderAddress;

    require(positionTrader == traderAddress, Errors.GetError(Errors.Error.VL_TRADER_ADDRESS_MISMATCH));
    require(position.isOpen == true, Errors.GetError(Errors.Error.VL_POSITION_NOT_OPEN));
  }

  function validateLiquidationCallPosition(
    DataTypes.TraderPosition storage position,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address oracle
  ) external view {
    require(position.isOpen == true, Errors.GetError(Errors.Error.VL_POSITION_NOT_OPEN));
    uint256 positionLiquidationThreshold = position.liquidationThreshold;
    uint256 healthFactor = GenericLogic
      .calculatePositionHealthFactor(
        position,
        positionLiquidationThreshold,
        reservesData,
        oracle
      );
    require(healthFactor < GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.GetError(Errors.Error.VL_POSITION_NOT_UNHEALTHY));
  }

  /**
   * @dev Validates a supply action
   * @param reserve The reserve object on which the user is supplying
   * @param amount The amount to be supplied
   */
  function validateSupply(DataTypes.ReserveData storage reserve, uint256 amount) external view {
    bool isActive = reserve.configuration.active;
    bool isFrozen = reserve.configuration.frozen;

    require(amount != 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));
    require(isActive, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));
    require(!isFrozen, Errors.GetError(Errors.Error.VL_RESERVE_FROZEN));
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveAddress The address of the reserve
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   * @param reservesData The reserves state
   * @param userConfig The user configuration
   * @param reserves The addresses of the reserves
   * @param reservesCount The number of reserves
   * @param oracle The price oracle
   */
  function validateWithdraw(
    address reserveAddress,
    uint256 amount,
    uint256 userBalance,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves,
    uint256 reservesCount,
    address oracle
  ) external view {
    require(amount != 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));
    require(amount <= userBalance, Errors.GetError(Errors.Error.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE));

    bool isActive = reservesData[reserveAddress].configuration.active;
    require(isActive, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));

    require(
      GenericLogic.balanceDecreaseAllowed(
        reserveAddress,
        msg.sender,
        amount,
        reservesData,
        userConfig,
        reserves,
        reservesCount,
        oracle
      ),
      Errors.GetError(Errors.Error.VL_TRANSFER_NOT_ALLOWED)
    );
  }

  struct ValidateBorrowCallVars {
    address asset;
    address userAddress;
    uint256 amount;
    uint256 amountInETH;
    uint256 interestRateMode;
    uint256 reservesCount;
    address oracleAddress;
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeededETH;
    uint256 userCollateralBalanceETH;
    uint256 userBorrowBalanceETH;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
  }

  /**
   * @dev Validates a borrow action
   * @param reserve The reserve state from which the user is borrowing
   * @param reservesData The state of all the reserves
   * @param userConfig The state of the user for the specific reserve
   * @param reserves The addresses of all the active reserves
   */

  function validateBorrow(
    ValidateBorrowCallVars memory callVars,
    DataTypes.ReserveData storage reserve,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves
  ) external view {
    ValidateBorrowLocalVars memory vars;

    vars.isActive = reserve.configuration.active;
    vars.isFrozen = reserve.configuration.frozen;
    vars.borrowingEnabled = reserve.configuration.borrowingEnabled;

    require(vars.isActive, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));
    require(!vars.isFrozen, Errors.GetError(Errors.Error.VL_RESERVE_FROZEN));
    require(callVars.amount != 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));

    require(vars.borrowingEnabled, Errors.GetError(Errors.Error.VL_BORROWING_NOT_ENABLED));

    //validate interest rate mode
    require(
      uint256(DataTypes.InterestRateMode.VARIABLE) == callVars.interestRateMode,
      Errors.GetError(Errors.Error.VL_INVALID_INTEREST_RATE_MODE_SELECTED)
    );

    (
      vars.userCollateralBalanceETH,
      vars.userBorrowBalanceETH,
      vars.currentLtv,
      vars.currentLiquidationThreshold,
      vars.healthFactor
    ) = GenericLogic.calculateUserAccountData(
      callVars.userAddress,
      reservesData,
      userConfig,
      reserves,
      callVars.reservesCount,
      callVars.oracleAddress
    );

    require(vars.userCollateralBalanceETH > 0, Errors.GetError(Errors.Error.VL_COLLATERAL_BALANCE_IS_0));

    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.GetError(Errors.Error.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD)
    );

    // add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.amountOfCollateralNeededETH = vars.userBorrowBalanceETH.add(callVars.amountInETH).percentDiv(
      vars.currentLtv
    ); // LTV is calculated in percentage

    require(
      vars.amountOfCollateralNeededETH <= vars.userCollateralBalanceETH,
      Errors.GetError(Errors.Error.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW)
    );
  }

  /**
   * @dev Validates a repay action
   * @param reserve The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserve,
    uint256 amountSent,
    DataTypes.InterestRateMode rateMode,
    address onBehalfOf,
    uint256 variableDebt
  ) external view {
    bool isActive = reserve.configuration.active;

    require(isActive, Errors.GetError(Errors.Error.VL_NO_ACTIVE_RESERVE));

    require(amountSent > 0, Errors.GetError(Errors.Error.VL_INVALID_AMOUNT));

    require(
      variableDebt > 0 && DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.VARIABLE,
      Errors.GetError(Errors.Error.VL_NO_DEBT_OF_SELECTED_TYPE)
    );

    require(
      (amountSent != type(uint256).max) || (msg.sender == onBehalfOf),
      Errors.GetError(Errors.Error.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF)
    );
  }

  /**
   * @dev Validates a flashloan action
   * @param assets The assets being flashborrowed
   * @param amounts The amounts for each asset being borrowed
   **/
  function validateFlashloan(address[] memory assets, uint256[] memory amounts) internal pure {
    require(assets.length == amounts.length, Errors.GetError(Errors.Error.VL_INCONSISTENT_FLASHLOAN_PARAMS));
  }

  /**
   * @dev Validates the action of setting an asset as collateral
   * @param reserve The state of the reserve that the user is enabling or disabling as collateral
   * @param reserveAddress The address of the reserve
   * @param reservesData The data of all the reserves
   * @param userConfig The state of the user for the specific reserve
   * @param reserves The addresses of all the active reserves
   * @param oracle The price oracle
   */
  function validateSetUseReserveAsCollateral(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    bool useAsCollateral,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves,
    uint256 reservesCount,
    address oracle
  ) external view {
    uint256 underlyingBalance = IERC20(reserve.kTokenAddress).balanceOf(msg.sender);

    require(underlyingBalance > 0, Errors.GetError(Errors.Error.VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0));

    require(
      useAsCollateral ||
        GenericLogic.balanceDecreaseAllowed(
          reserveAddress,
          msg.sender,
          underlyingBalance,
          reservesData,
          userConfig,
          reserves,
          reservesCount,
          oracle
        ),
      Errors.GetError(Errors.Error.VL_SUPPLY_ALREADY_IN_USE)
    );
  }

  /**
   * @dev Validates the liquidation action
   * @param collateralReserve The reserve data of the collateral
   * @param principalReserve The reserve data of the principal
   * @param userConfig The user configuration
   * @param userHealthFactor The user's health factor
   * @param userVariableDebt Total variable debt balance of the user
   **/
  function validateLiquidationCall(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveData storage principalReserve,
    DataTypes.UserConfigurationMap storage userConfig,
    uint256 userHealthFactor,
    uint256 userVariableDebt
  ) internal view returns (Errors.Error, Errors.Error) {
    if (
      !collateralReserve.configuration.active || !principalReserve.configuration.active
    ) {
      return (
        Errors.Error.CM_NO_ACTIVE_RESERVE,
        Errors.Error.VL_NO_ACTIVE_RESERVE
      );
    }

    if (userHealthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
      return (
        Errors.Error.CM_HEALTH_FACTOR_ABOVE_THRESHOLD,
        Errors.Error.LL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
      );
    }

    bool isCollateralEnabled =
      collateralReserve.configuration.liquidationThreshold > 0 &&
        userConfig.isUsingAsCollateral[collateralReserve.id];

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    if (!isCollateralEnabled) {
      return (
        Errors.Error.CM_COLLATERAL_CANNOT_BE_LIQUIDATED,
        Errors.Error.LL_COLLATERAL_CANNOT_BE_LIQUIDATED
      );
    }

    if (userVariableDebt == 0) {
      return (
        Errors.Error.CM_CURRRENCY_NOT_BORROWED,
        Errors.Error.LL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
      );
    }

    return (Errors.Error.CM_NO_ERROR, Errors.Error.LL_NO_ERRORS);
  }

  /**
   * @dev Validates an kToken transfer
   * @param from The user from which the kTokens are being transferred
   * @param reservesData The state of all the reserves
   * @param userConfig The state of the user for the specific reserve
   * @param reserves The addresses of all the active reserves
   * @param oracle The price oracle
   */
  function validateTransfer(
    address from,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(uint256 => address) storage reserves,
    uint256 reservesCount,
    address oracle
  ) internal view {
    (, , , , uint256 healthFactor) =
      GenericLogic.calculateUserAccountData(
        from,
        reservesData,
        userConfig,
        reserves,
        reservesCount,
        oracle
      );

    require(
      healthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.GetError(Errors.Error.VL_TRANSFER_NOT_ALLOWED)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from '../../Dependency/openzeppelin/SafeMath.sol';
import {IKToken} from '../../Interface/IKToken.sol';
import {IDToken} from '../../Interface/IDToken.sol';
import {IReserveInterestRateStrategy} from '../../Interface/IReserveInterestRateStrategy.sol';
import {MathUtils} from '../Math/MathUtils.sol';
import {WadRayMath} from '../Math/WadRayMath.sol';
import {PercentageMath} from '../Math/PercentageMath.sol';
import {Errors} from '../Helper/Errors.sol';
import {DataTypes} from '../Type/DataTypes.sol';

library ReserveLogic {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  /**
   * @dev Emitted when the state of a reserve is updated
   * @param asset The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param borrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param borrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256 liquidityRate,
    uint256 borrowRate,
    uint256 liquidityIndex,
    uint256 borrowIndex
  );

  using ReserveLogic for DataTypes.ReserveData;

  /**
   * @dev Returns the ongoing normalized income for the reserve
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return the normalized income. expressed in ray
   **/
  function getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    }

    uint256 cumulated =
      MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
        reserve.liquidityIndex
      );

    return cumulated;
  }

  /**
   * @dev Returns the ongoing normalized variable debt for the reserve
   * A value of 1e27 means there is no debt. As time passes, the income is accrued
   * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt. expressed in ray
   **/
  function getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.borrowIndex;
    }

    uint256 cumulated =
      MathUtils.calculateCompoundedInterest(reserve.currentBorrowRate, timestamp).rayMul(
        reserve.borrowIndex
      );

    return cumulated;
  }

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateState(DataTypes.ReserveData storage reserve) internal {
    uint256 scaledDebt =
      IDToken(reserve.dTokenAddress).scaledTotalSupply();
    uint256 previousVariableBorrowIndex = reserve.borrowIndex;
    uint256 previousLiquidityIndex = reserve.liquidityIndex;
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

    (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) =
      _updateIndexes(
        reserve,
        scaledDebt,
        previousLiquidityIndex,
        previousVariableBorrowIndex,
        lastUpdatedTimestamp
      );

    _mintToTreasury(
      reserve,
      scaledDebt,
      previousVariableBorrowIndex,
      newLiquidityIndex,
      newVariableBorrowIndex
    );
  }

  /**
   * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example to accumulate
   * the flashloan fee to the reserve, and spread it between all the suppliers
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accomulate
   **/
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal {
    uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

    uint256 result = amountToLiquidityRatio.add(WadRayMath.ray());

    result = result.rayMul(reserve.liquidityIndex);
    require(result <= type(uint128).max, Errors.GetError(Errors.Error.RL_LIQUIDITY_INDEX_OVERFLOW));

    reserve.liquidityIndex = uint128(result);
  }

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param kTokenAddress The address of the overlying kToken contract
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address kTokenAddress,
    address dTokenAddress,
    address interestRateStrategyAddress
  ) external {
    require(reserve.kTokenAddress == address(0), Errors.GetError(Errors.Error.RL_RESERVE_ALREADY_INITIALIZED));

    reserve.liquidityIndex = uint128(WadRayMath.ray());
    reserve.borrowIndex = uint128(WadRayMath.ray());
    reserve.kTokenAddress = kTokenAddress;
    reserve.dTokenAddress = dTokenAddress;
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 newLiquidityRate;
    uint256 newBorrowRate;
    uint256 totalVariableDebt;
  }

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (withdraw or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    address kTokenAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    //calculates the total variable debt locally using the scaled total supply instead
    //of totalSupply(), as it's noticeably cheaper. Also, the index has been
    //updated by the previous updateState() call
    vars.totalVariableDebt = IDToken(reserve.dTokenAddress)
      .scaledTotalSupply()
      .rayMul(reserve.borrowIndex);

    (
      vars.newLiquidityRate,
      vars.newBorrowRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      reserveAddress,
      kTokenAddress,
      liquidityAdded,
      liquidityTaken,
      vars.totalVariableDebt,
      reserve.configuration.reserveFactor
    );
    require(vars.newLiquidityRate <= type(uint128).max, Errors.GetError(Errors.Error.RL_LIQUIDITY_RATE_OVERFLOW));
    require(vars.newBorrowRate <= type(uint128).max, Errors.GetError(Errors.Error.RL_BORROW_RATE_OVERFLOW));

    reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
    reserve.currentBorrowRate = uint128(vars.newBorrowRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.newLiquidityRate,
      vars.newBorrowRate,
      reserve.liquidityIndex,
      reserve.borrowIndex
    );
  }

  struct MintToTreasuryLocalVars {
    uint256 currentDebt;
    uint256 previousDebt;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint256 reserveFactor;
  }

  /**
   * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
   * specific asset.
   * @param reserve The reserve reserve to be updated
   * @param scaledDebt The current scaled total variable debt
   * @param previousBorrowIndex The variable borrow index before the last accumulation of the interest
   * @param newLiquidityIndex The new liquidity index
   * @param newBorrowIndex The variable borrow index after the last accumulation of the interest
   **/
  function _mintToTreasury(
    DataTypes.ReserveData storage reserve,
    uint256 scaledDebt,
    uint256 previousBorrowIndex,
    uint256 newLiquidityIndex,
    uint256 newBorrowIndex
  ) internal {
    MintToTreasuryLocalVars memory vars;

    vars.reserveFactor = reserve.configuration.reserveFactor;

    if (vars.reserveFactor == 0) {
      return;
    }

    //calculate the last principal variable debt
    vars.previousDebt = scaledDebt.rayMul(previousBorrowIndex);

    //calculate the new total supply after accumulation of the index
    vars.currentDebt = scaledDebt.rayMul(newBorrowIndex);

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars
      .currentDebt
      .sub(vars.previousDebt);

    vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

    if (vars.amountToMint != 0) {
      IKToken(reserve.kTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
    }
  }

  /**
   * @dev Updates the reserve indexes and the timestamp of the update
   * @param reserve The reserve reserve to be updated
   * @param scaledDebt The scaled variable debt
   * @param liquidityIndex The last stored liquidity index
   * @param borrowIndex The last stored variable borrow index
   **/
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    uint256 scaledDebt,
    uint256 liquidityIndex,
    uint256 borrowIndex,
    uint40 timestamp
  ) internal returns (uint256, uint256) {
    uint256 currentLiquidityRate = reserve.currentLiquidityRate;

    uint256 newLiquidityIndex = liquidityIndex;
    uint256 newVariableBorrowIndex = borrowIndex;

    //only cumulating if there is any income being produced
    if (currentLiquidityRate > 0) {
      uint256 cumulatedLiquidityInterest =
        MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
      newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
      require(newLiquidityIndex <= type(uint128).max, Errors.GetError(Errors.Error.RL_LIQUIDITY_INDEX_OVERFLOW));

      reserve.liquidityIndex = uint128(newLiquidityIndex);

      // as the liquidity rate might come only from flash loans, we need to ensure
      // that there is actual variable debt before accumulating
      if (scaledDebt != 0) {
        uint256 cumulatedVariableBorrowInterest =
          MathUtils.calculateCompoundedInterest(reserve.currentBorrowRate, timestamp);
        newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(borrowIndex);
        require(
          newVariableBorrowIndex <= type(uint128).max,
          Errors.GetError(Errors.Error.RL_BORROW_INDEX_OVERFLOW)
        );
        reserve.borrowIndex = uint128(newVariableBorrowIndex);
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    return (newLiquidityIndex, newVariableBorrowIndex);
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
pragma solidity ^0.8.0;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "../../Dependency/openzeppelin/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IAggregationRouterV4  {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    event Swapped(
        address sender,
        IERC20 srcToken,
        IERC20 dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    );


    /// @notice Performs a swap and burns chi tokens to get gas refund
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function discountedSwap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft, uint256 chiSpent);

    /// @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

    function rescueFunds(IERC20 token, uint256 amount) external;

    function destroy() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGasDiscountExtension} from "./IGasDiscountExtension.sol";

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor is IGasDiscountExtension {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IChi} from "./IChi.sol";

/// @title Interface for calculating CHI discounts
interface IGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IChi, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../../Dependency/openzeppelin/IERC20.sol";

/// @title Interface for CHI gas token
interface IChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
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