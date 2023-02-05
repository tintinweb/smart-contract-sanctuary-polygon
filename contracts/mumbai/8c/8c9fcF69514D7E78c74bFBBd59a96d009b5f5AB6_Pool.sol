// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {PoolStorage} from './PoolStorage.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {PoolLogic} from '../libraries/logic/PoolLogic.sol';
import {SupplyLogic} from '../libraries/logic/SupplyLogic.sol';
import {BorrowLogic} from '../libraries/logic/BorrowLogic.sol';
import {GeneralLogic} from '../libraries/logic/GeneralLogic.sol';
import {ParticularLogic} from '../libraries/logic/ParticularLogic.sol';
import {LiquidationLogic} from '../libraries/logic/LiquidationLogic.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPrxyTreasury} from '../../interfaces/IPrxyTreasury.sol';
import {UserListLogic} from '../libraries/logic/UserListLogic.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';

contract Pool is VersionedInitializable, PoolStorage, IPool {
  using GPv2SafeERC20 for IERC20;
  using UserListLogic for DataTypes.UserList;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;
  uint256 internal _reduxInterval;

  uint256 public constant POOL_REVISION = 0x4;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // address[] _borrowersList;
  // mapping(address => uint256) _borrowerIds;

  /**
   * @dev Only pool configurator can call functions marked by this modifier.
   **/
  modifier onlyPoolConfigurator() {
    _onlyPoolConfigurator();
    _;
  }

  /**
   * @dev Only pool re-supplier can call functions marked by this modifier.
   **/
  modifier onlyPoolReSupplier() {
    _onlyPoolReSupplier();
    _;
  }

  function _onlyPoolConfigurator() internal view virtual {
    require(
      ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender,
      Errors.CALLER_NOT_POOL_CONFIGURATOR
    );
  }

  function _onlyPoolReSupplier() internal view virtual {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(aclManager.isPoolSupplier(msg.sender), Errors.CALLER_NOT_POOL_RESUPPLIER);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return POOL_REVISION;
  }



  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    
  }

  /**
   * @notice Initializes the Pool.
   * @dev Function is invoked by the proxy contract when the Pool contract is added to the
   * PoolAddressesProvider of the market.
   * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
   * @param provider The address of the PoolAddressesProvider
   **/
  function initialize(IPoolAddressesProvider provider) external virtual initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
    _reduxInterval = 1 days;
  }

  /// @inheritdoc IPool
  function initReserve(
    address supplyingAsset,
    uint256 borrowRate,
    uint256 prxyRate,
    uint256 splitRate,
    address pTokenAddress
  ) external virtual override onlyPoolConfigurator {
    if (
      PoolLogic.executeInitReserve(
        _reserves,
        _reservesList,
        DataTypes.InitReserveParams({
          supplyingAsset: supplyingAsset,
          borrowRate: borrowRate,
          prxyRate: prxyRate,
          splitRate: splitRate,
          pTokenAddress: pTokenAddress,
          reservesCount: _reservesCount,
          maxNumberReserves: MAX_NUMBER_RESERVES()
        })
      )
    ) {
      _reservesCount++;
    }
  }

  /// @inheritdoc IPool
  function addFund(
    address asset,
    uint256 amount
  ) public virtual override onlyPoolReSupplier {
    IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
  }

  /// @inheritdoc IPool
  function removeFund(
    address asset,
    uint256 amount
  ) public virtual override onlyPoolReSupplier {
    IERC20(asset).safeTransfer(msg.sender, amount);
  }

  /// @inheritdoc IPool
  function supply(
    address asset,
    uint256 amount,
    uint16 referralCode
  ) public virtual override {
    SupplyLogic.executeSupply(
      _reserves,
      _reservesList,
      DataTypes.ExecuteSupplyParams({
        asset: asset,
        amount: amount,
        referralCode: referralCode,
        reservesCount: _reservesCount
      })
    );
    if(amount > 0) supplierList[asset].addUser(msg.sender);
  }

  /// @inheritdoc IPool
  function borrow(
    address asset,
    address borrowingAsset,
    uint256 amount,
    uint16 referralCode
  ) public virtual override {
    BorrowLogic.executeBorrow(
      _reserves,
      _reservesList,
      DataTypes.ExecuteBorrowParams({
        asset: asset,
        borrowingAsset: borrowingAsset,
        amount: amount,
        referralCode: referralCode,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        reservesCount: _reservesCount
      })
    );
  }

  /// @inheritdoc IPool
  function withdraw(
    address asset,
    uint256 amount
  ) public virtual override returns (uint256) {
    (uint256 withdrawAmount, uint256 userSupplyBalance) = SupplyLogic.executeWithdraw(
      _reserves,
      _reservesList,
      DataTypes.ExecuteWithdrawParams({
        asset: asset,
        amount: amount,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        reservesCount: _reservesCount
      })
    );
    if(userSupplyBalance == 0) supplierList[asset].removeUser(msg.sender);
    return withdrawAmount;
  }

  /// @inheritdoc IPool
  function repay(
    address asset,
    address borrowingAsset,
    uint256 amount
  ) public virtual override returns (uint256) {
    (uint256 repayAmount, uint256 userBorrowBalance) = BorrowLogic.executeRepay(
        _reserves,
        _reservesList,
        DataTypes.ExecuteRepayParams({
          asset: asset,
          borrowingAsset: borrowingAsset,
          amount: amount,
          reservesCount: _reservesCount
        })
      );
    return repayAmount;
  }

  /// @inheritdoc IPool
  function liquidationCall(
    address user,
    address asset
  ) public virtual override {
    LiquidationLogic.executeLiquidationCall(
      _reserves,
      _reservesList,
      DataTypes.ExecuteLiquidationCallParams({
        user: user,
        asset: asset,
        oracle: ADDRESSES_PROVIDER.getPriceOracle(),
        reservesCount: _reservesCount
      })
    );
    supplierList[asset].removeUser(user);
  }

  /// @inheritdoc IPool
  function checkAndLiquidate(address asset) public virtual override {
    address[] storage suppliers = supplierList[asset].list;
    uint256 i = 0;
    while(i < suppliers.length) {
      address user = suppliers[i];
      bool isLiquidated = LiquidationLogic.executeLiquidateWhenReached(
        _reserves,
        _reservesList,
        DataTypes.ExecuteLiquidationCallParams({
          user: user,
          asset: asset,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          reservesCount: _reservesCount
        })
      );
      if (isLiquidated) supplierList[asset].removeUser(user);
      else ++i;
    }
  }

  /// @inheritdoc IPool
  function claimPrxy(
    address asset,
    uint256 amount
  ) public virtual override {
    ParticularLogic.executeClaimPrxy(
      _reserves,
      DataTypes.ExecuteClaimPrxyParams({
        asset: asset,
        amount: amount,
        prxyTreasury: ADDRESSES_PROVIDER.getPrxyTreasury()
      })
    );
  }

  /// @inheritdoc IPool
  function splitReduxInterest() public virtual override {
    uint256 currentTime = block.timestamp;
    require(currentTime >= _reduxInterval + _reduxLastTimestamp, Errors.EARLY_REDUX_SPLIT);

    uint256 elapsedTime = currentTime - _reduxLastTimestamp;
    if(_reduxLastTimestamp == 0) elapsedTime = _reduxInterval;
    _reduxLastTimestamp = currentTime;

    for(uint256 i = 0; i < _reservesCount; i++) {
      address asset = _reservesList[i];
      ParticularLogic.executeSplitReduxInterest(
        _reserves,
        _reservesList,
        supplierList[asset],
        DataTypes.ExecuteSplitReduxInterestParams({
          asset: asset,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          reservesCount: _reservesCount,
          elapsedTime: elapsedTime
        })
      );
    }

    ParticularLogic.clearReduxInterest(_reserves, _reservesList, _reservesCount);
  }

  /// @inheritdoc IPool
  function switchSupplyMode(address asset) public virtual override {
    require(supplierList[asset].hasUser(msg.sender), Errors.USER_NOT_SUPPLIER);
    ParticularLogic.executeSwitchSupplyMode(
      _reserves,
      DataTypes.ExecuteSwitchSupplyModeParams({
        asset: asset
      })
    );
  }

  /// @inheritdoc IPool
  function MAX_NUMBER_RESERVES() public view virtual override returns (uint16) {
    return ReserveConfiguration.MAX_RESERVES_COUNT;
  }

  /// @inheritdoc IPool
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external
    virtual
    override
    onlyPoolConfigurator
  {
    require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    require(_reserves[asset].id != 0 || _reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
    _reserves[asset].configuration = configuration;
  }

  /// @inheritdoc IPool
  function getConfiguration(address asset)
    external
    view
    virtual
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    return _reserves[asset].configuration;
  }

  /// @inheritdoc IPool
  function getReserveData(address asset)
    external
    view
    virtual
    override
    returns (DataTypes.ReserveData memory)
  {
    return _reserves[asset];
  }

  /// @inheritdoc IPool
  function setReserveInterestRates(address asset, uint256 borrowRate, uint256 prxyRate) external virtual override onlyPoolConfigurator {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    reserve.borrowRate = borrowRate;
    reserve.prxyRate = prxyRate;
  }

  /// @inheritdoc IPool
  function setReserveSplitRate(address asset, uint256 splitRate) external virtual override onlyPoolConfigurator {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    reserve.splitRate = splitRate;
  }

  /// @inheritdoc IPool
  function setReduxInterval(uint256 reduxInterval) external virtual override onlyPoolConfigurator {
    _reduxInterval = reduxInterval;
  }

  /// @inheritdoc IPool
  function getReservesList() external view virtual override returns (address[] memory) {
    uint256 reservesListCount = _reservesCount;
    uint256 droppedReservesCount = 0;
    address[] memory reservesList = new address[](reservesListCount);

    for (uint256 i = 0; i < reservesListCount; i++) {
      if (_reservesList[i] != address(0)) {
        reservesList[i - droppedReservesCount] = _reservesList[i];
      } else {
        droppedReservesCount++;
      }
    }

    // Reduces the length of the reserves array by `droppedReservesCount`
    assembly {
      mstore(reservesList, sub(reservesListCount, droppedReservesCount))
    }
    return reservesList;
  }

  /// @inheritdoc IPool
  function getPrxyInterestRate(address supplyingAsset) 
    external view override 
    returns(uint256)
  {
    uint256 rate = _reserves[supplyingAsset].prxyRate * WadRayMath.RAY;
    rate /= SECONDS_PER_YEAR * GeneralLogic.RATE_PRECISION;

    IPriceOracleGetter priceOracle = (IPriceOracleGetter)(ADDRESSES_PROVIDER.getPriceOracle());
    IPrxyTreasury prxyTreasury = (IPrxyTreasury)(ADDRESSES_PROVIDER.getPrxyTreasury());
    address prxyAsset = prxyTreasury.getPrxyToken();
    
    uint256 supplyingAssetPrice = priceOracle.getAssetPrice(supplyingAsset);
    uint256 prxyAssetPrice = priceOracle.getAssetPrice(prxyAsset);
    uint8 supplyingDecimals = IERC20Detailed(supplyingAsset).decimals();
    uint8 prxyDecimals = IERC20Detailed(prxyAsset).decimals();
    uint256 supplyingUnit = 10 ** supplyingDecimals;
    uint256 prxyUnit = 10 ** prxyDecimals;

    rate = rate * (prxyUnit * supplyingAssetPrice) / (supplyingUnit * prxyAssetPrice);
    return rate;
  }

  /// @inheritdoc IPool
  function getBorrowInterestRate(address supplyingAsset, address borrowingAsset) 
    external view override 
    returns(uint256)
  {
    uint256 rate = _reserves[borrowingAsset].borrowRate * WadRayMath.RAY;
    rate /= SECONDS_PER_YEAR * GeneralLogic.RATE_PRECISION;

    IPriceOracleGetter priceOracle = (IPriceOracleGetter)(ADDRESSES_PROVIDER.getPriceOracle());
    
    uint256 supplyingAssetPrice = priceOracle.getAssetPrice(supplyingAsset);
    uint256 borrowingAssetPrice = priceOracle.getAssetPrice(borrowingAsset);
    uint8 supplyingDecimals = IERC20Detailed(supplyingAsset).decimals();
    uint8 borrowingDecimals = IERC20Detailed(borrowingAsset).decimals();
    uint256 supplyingUnit = 10 ** supplyingDecimals;
    uint256 borrowingUnit = 10 ** borrowingDecimals;

    rate = rate * (supplyingUnit * borrowingAssetPrice) / (borrowingUnit * supplyingAssetPrice);
    return rate;
  }

  // @inheritdoc IPool
  function getCollateralRate(address supplyingAsset, address borrowingAsset) external view override returns (uint256) {
    uint256 collateralRate = 10000 * WadRayMath.RAY / _reserves[supplyingAsset].configuration.getLtv();

    IPriceOracleGetter priceOracle = (IPriceOracleGetter)(ADDRESSES_PROVIDER.getPriceOracle());
    uint256 supplyingAssetPrice = priceOracle.getAssetPrice(supplyingAsset);
    uint256 borrowingAssetPrice = priceOracle.getAssetPrice (borrowingAsset);
    uint8 supplyingDecimals = IERC20Detailed(supplyingAsset).decimals();
    uint8 borrowingDecimals = IERC20Detailed(borrowingAsset).decimals();
    uint256 supplyingUnit = 10 ** supplyingDecimals;
    uint256 borrowingUnit = 10 ** borrowingDecimals;

    collateralRate = collateralRate * (supplyingUnit * borrowingAssetPrice) / (borrowingUnit * supplyingAssetPrice);
    return collateralRate;
  }

  /// @inheritdoc IPool
  function getUserAccountData(address user, address asset)
    external
    view
    virtual
    override
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    return
      PoolLogic.executeGetUserAccountData(
        _reserves,
        _reservesList,
        DataTypes.CalculateUserAccountDataParams({
          user: user,
          asset: asset,
          oracle: ADDRESSES_PROVIDER.getPriceOracle(),
          reservesCount: _reservesCount
        })
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @notice Returns the revision number of the contract
   * @dev Needs to be defined in the inherited class as a constant.
   * @return The revision number
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @notice Returns true if and only if the function is running in the constructor
   * @return True if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_PTOKEN = '11'; // 'The caller of the function is not an PToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant SAME_BLOCK_BORROW_REPAY = '48'; // 'Borrow and repay in same block is not allowed'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant PTOKEN_SUPPLY_NOT_ZERO = '54'; // 'PToken supply is not zero'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
  string public constant INVALID_USER_BALANCE = '91'; // Invalid user balance
  string public constant INVALID_TOTAL_BALANCE = '92'; // Invalid total balance
  string public constant INSUFFICIENT_USER_SUPPLY_BALANCE = '93'; // Insufficient user supply balance
  string public constant INSUFFICIENT_USER_BORROW_BALANCE = '94'; // Insufficient user borrow balance
  string public constant INSUFFICIENT_USER_PRXY_BALANCE = '95'; // Insufficient user prxy balance
  string public constant INSUFFICIENT_TOTAL_SUPPLY_BALANCE = '96'; // Insufficient total supply balance
  string public constant INSUFFICIENT_TOTAL_BORROW_BALANCE = '97'; // Insufficient total borrow balance
  string public constant INSUFFICIENT_TOTAL_PRXY_BALANCE = '98'; // Insufficient total prxy balance
  string public constant INVALID_REFERRAL_CODE = '99'; // Invalid referral code
  string public constant INCORRECT_REFERRAL_CODE = '100'; // Referral code must be equal to the referral code of first supply 
  string public constant MUST_ZERO_BORROW_BALANCE = '101'; // Must zero borrow balance
  string public constant EARLY_REDUX_SPLIT = '102'; // Early redux split
  string public constant USER_NOT_SUPPLIER = '103'; // User isn't supplier
  string public constant CALLER_NOT_POOL_RESUPPLIER = '104'; // Caller isn't pool re-supplier
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {

  /**
   * @notice Initializes a reserve, activating it, assigning an pToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param supplyingAsset The address of the supplying asset of the reserve
   * @param borrowRate The borrowing rate
   * @param prxyRate The prxy interest rate
   * @param splitRate The split rate
   * @param pTokenAddress The address of the pToken that will be assigned to the reserve
   **/
  function initReserve(
    address supplyingAsset,
    uint256 borrowRate,
    uint256 prxyRate,
    uint256 splitRate,
    address pTokenAddress
  ) external;

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying pTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 pUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * - E.g. User borrows 100 USDC passing, receiving the 100 USDC in his wallet
   * @param asset The address of the underlying asset to borrow
   * @param borrowingAsset The address of the borrowing asset to borrow
   * @param amount The amount to be borrowed
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   **/
  function borrow(
    address asset,
    address borrowingAsset,
    uint256 amount,
    uint16 referralCode
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent pTokens owned
   * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole pToken balance
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount
  ) external returns(uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param borrowingAsset The address of the borrowinging asset
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    address borrowingAsset,
    uint256 amount
  ) external returns(uint256);

  /**
   * @notice Function to claim the prxy interest
   * @param asset The address of the underlying asset used as collateral
   * @param amount The amount to claim
   **/
  function claimPrxy(
    address asset,
    uint256 amount
  ) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * @param user The address of user for liquidation
   * @param asset The address of the underlying asset used as collateral, to receive as result of the liquidation
   **/
  function liquidationCall(
    address user,
    address asset
  ) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1 from keeper
   * @param asset The address of the underlying asset used as collateral, to receive as result of the liquidation
   **/
  function checkAndLiquidate(
    address asset
  ) external;

  /**
   * @notice Function to split the redux interest
   **/
  function splitReduxInterest() external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);
  
  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Sets the interest rates of the reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param borrowRate The borrow rate
   * @param prxyRate The prxy rate
   **/
  function setReserveInterestRates(address asset, uint256 borrowRate, uint256 prxyRate) external;

  /**
   * @notice Sets the split rate of the reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param splitRate The split rate
   **/
  function setReserveSplitRate(address asset, uint256 splitRate) external;


  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the borrow interest rate
   * @param supplyingAsset The address of the supplying asset of the reserve
   * @param borrowingAsset The address of the borrowing asset of the reserve
   * @return The borrowing interest rate of the reserve
   **/
  function getBorrowInterestRate(address supplyingAsset, address borrowingAsset) external view returns(uint256);

  /**
   * @notice Returns the prxy interest rate
   * @param supplyingAsset The address of the supplying asset of the reserve
   * @return The prxy interest rate of the reserve
   **/
  function getPrxyInterestRate(address supplyingAsset) external view returns(uint256);

  /**
   * @notice Returns the collateral rate
   * @param supplyingAsset The address of the supplying asset of the reserve
   * @param borrowingAsset The address of the borrowing asset of the reserve
   * @return The collateral rate of the reserve
   **/
  function getCollateralRate(address supplyingAsset, address borrowingAsset) external view returns (uint256);

  /**
   * @notice Returns the user account data of the asset
   * @param user The address of the user
   * @param asset The address of the asset
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user, address asset)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
  
  /**
   * @notice Sets the redux interval
   * @dev Only callable by the PoolConfigurator contract
   * @param reduxInterval The redux interval 
   */
  function setReduxInterval(uint256 reduxInterval) external;

  /**
   * @notice Function to switch the supply mode
   * @param asset The address of the underlying asset used as collateral
   **/
  function switchSupplyMode(address asset) external;

  /**
   * @notice Function to add the fund
   * @param asset The address of the underlying asset used as collateral
   * @param amount The amount to add
   **/
  function addFund(
    address asset,
    uint256 amount
  ) external;

  /**
   * @notice Function to remove the fund
   * @param asset The address of the underlying asset used as collateral
   * @param amount The amount to remove
   **/
  function removeFund(
    address asset,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

// import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';

/**
 * @title PoolStorage
 * @author Aave
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // List of reserves as a map (underlyingAssetOfReserve => reserveData).
  mapping(address => DataTypes.ReserveData) internal _reserves;

  // List of reserves as a map (reserveId => reserve).
  // It is structured as a mapping for gas savings reasons, using the reserve id as index
  mapping(uint256 => address) internal _reservesList;

  // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
  uint16 internal _reservesCount;
  
  uint256 internal _reduxLastTimestamp;

  mapping(address => DataTypes.UserList) internal supplierList;
  mapping(address => DataTypes.UserList) internal borrowerList;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Pool Re-Supply role
   * @return The id of the Pool Re-Supply role
   */
  function POOL_RESUPPLY_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Pool Supplier
   * @param supplier The address of the new pool supplier
   */
  function addPoolSupplier(address supplier) external;

  /**
   * @notice Removes an address as Pool Supplier
   * @param supplier The address of the pool supplier to remove
   */
  function removePoolSupplier(address supplier) external;

  /**
   * @notice Returns true if the address is Pool Supplier, false otherwise
   * @param supplier The address to check
   * @return True if the given address is Pool Supplier, false otherwise
   */
  function isPoolSupplier(address supplier) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the prxy treasury is updated.
   * @param oldAddress The old address of the PrxyTreasury
   * @param newAddress The new address of the PrxyTreasury
   */
  event PrxyTreasuryUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the trading wallet is updated.
   * @param oldAddress The old address of the trading wallet
   * @param newAddress The new address of the trading wallet
   */
  event TradingWalletUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;

  /**
   * @notice Returns the address of the prxy treasury.
   * @return The address of the PrxyTreasury
   */
  function getPrxyTreasury() external view returns (address);

  /**
   * @notice Updates the address of the prxy treasury.
   * @param newPrxyTreasury The address of the new PrxyTreasury
   **/
  function setPrxyTreasury(address newPrxyTreasury) external;

  /**
   * @notice Returns the address of the trading wallet.
   * @return The address of the trading wallet
   */
  function getTradingWallet() external view returns (address);

  /**
   * @notice Updates the address of the trading wallet.
   * @param newTradingWallet The address of the trading wallet
   **/
  function setTradingWallet(address newTradingWallet) external;

  /**
   * @notice Returns the address of the dao wallet.
   * @return The address of the dao wallet
   */
  function getDaoWallet() external view returns (address);

  /**
   * @notice Updates the address of the dao wallet.
   * @param newDaoWallet The address of the dao wallet
   **/
  function setDaoWallet(address newDaoWallet) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  /// @dev bit 63 reserved

  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint256 internal constant MAX_VALID_LTV = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
  uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   **/
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   **/
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   **/
  function setBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self, bool borrowable)
    internal
    pure
  {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   **/
  function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   **/
  function setSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self, bool siloed)
    internal
    pure
  {
    self.data =
      (self.data & SILOED_BORROWING_MASK) |
      (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   **/
  function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   **/
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap)
    internal
    pure
  {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   **/
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   **/
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap)
    internal
    pure
  {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   **/
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   **/
  function setDebtCeiling(DataTypes.ReserveConfigurationMap memory self, uint256 ceiling)
    internal
    pure
  {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   **/
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   **/
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   **/
  function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   **/
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   **/
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   **/
  function setEModeCategory(DataTypes.ReserveConfigurationMap memory self, uint256 category)
    internal
    pure
  {
    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.INVALID_EMODE_CATEGORY);

    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   **/
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing paused
   **/
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   **/
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   **/
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library DataTypes {
  struct ReserveData {
    // stores the reserve configuration
    ReserveConfigurationMap configuration;
    // supplying asset address
    address supplyingAsset;
    // prxy asset address
    address prxyAsset;
    // the supply rate.
    uint256 supplyRate;   // Dynamic Rate
    // the borrow rate.
    uint256 borrowRate;   // Fixed Rate
    // the prxy rate.
    uint256 prxyRate;     // Fixed Rate
    // the split rate.
    uint256 splitRate;    // Fixed Rate
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //pToken address
    address pTokenAddress;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused
    uint256 data;
  }

  struct UserList {
    address[] list;
    mapping(address => uint256) ids;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    uint16 referralCode;
    uint256 reservesCount;
  }

  struct ExecuteBorrowParams {
    address asset;
    address borrowingAsset;
    uint256 amount;
    uint16 referralCode;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteRepayParams {
    address asset;
    address borrowingAsset;
    uint256 amount;
    uint256 reservesCount;
  }

  struct ExecuteLiquidationCallParams {
    address user;
    address asset;
    address oracle;
    uint256 reservesCount;
  }

  struct InitReserveParams {
    address supplyingAsset;
    uint256 borrowRate;
    uint256 prxyRate;
    uint256 splitRate;
    address pTokenAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }

  struct CalculateUserAccountDataParams {
    address user;
    address asset;
    address oracle;
    uint256 reservesCount;
  }

  struct ExecuteSplitReduxInterestParams {
    address asset;
    address oracle;
    uint256 reservesCount;
    uint256 elapsedTime;
  }

  struct ExecuteClaimPrxyParams {
    address asset;
    uint256 amount;
    address prxyTreasury;
  }

  struct ExecuteSwitchSupplyModeParams {
    address asset;
  }

  struct ExecuteAddFundParams {
    address asset;
    uint256 amount;
  }

  struct ExecuteRemoveFundParams {
    address asset;
    uint256 amount;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Address} from '../../../dependencies/openzeppelin/contracts/Address.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {Errors} from '../helpers/Errors.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GeneralLogic} from './GeneralLogic.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';

/**
 * @title PoolLogic library
 * @author Aave
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;

  /**
   * @notice Initialize an asset reserve and add the reserve to the list of reserves
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param params Additional parameters needed for initiation
   * @return true if appended, false if inserted at existing empty spot
   **/
  function executeInitReserve(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.InitReserveParams memory params
  ) external returns (bool) {
    require(Address.isContract(params.supplyingAsset), Errors.NOT_CONTRACT);
    
    address asset = params.supplyingAsset;
    reservesData[asset].init(
      params.supplyingAsset,
      params.borrowRate,
      params.prxyRate,
      params.splitRate,
      params.pTokenAddress
    );

    bool reserveAlreadyAdded = reservesData[asset].id != 0 ||
      reservesList[0] == asset;
    require(!reserveAlreadyAdded, Errors.RESERVE_ALREADY_ADDED);

    for (uint16 i = 0; i < params.reservesCount; i++) {
      if (reservesList[i] == address(0)) {
        reservesData[asset].id = i;
        reservesList[i] = asset;
        return false;
      }
    }

    require(params.reservesCount < params.maxNumberReserves, Errors.NO_MORE_RESERVES_ALLOWED);
    reservesData[asset].id = params.reservesCount;
    reservesList[params.reservesCount] = asset;
    return true;
  }

  /**
   * @notice Returns the user account data
   * @param reservesData The state of all the reserves
   * @param reservesList The state of the reserve list
   * @param params Additional params needed for the calculation
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function executeGetUserAccountData(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.CalculateUserAccountDataParams memory params
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    uint256 collateralAmount = IPToken(reserve.pTokenAddress).balanceOf(params.user);
    totalCollateralBase = GeneralLogic.getUserBalanceInBaseCurrency(reserve.supplyingAsset, collateralAmount, params.oracle);
    totalDebtBase = 0;

    for(uint256 i = 0; i < params.reservesCount; i++) {
      address borrowingAsset = reservesList[i];
      uint256 debtAmount = IPToken(reserve.pTokenAddress).borrowBalanceOf(params.user, borrowingAsset);
      totalDebtBase += GeneralLogic.getUserBalanceInBaseCurrency(borrowingAsset, debtAmount, params.oracle);
    }

    availableBorrowsBase = totalCollateralBase.percentMul(reserve.configuration.getLtv());
    availableBorrowsBase = (availableBorrowsBase < totalDebtBase) ? 0 : availableBorrowsBase - totalDebtBase;

    currentLiquidationThreshold = reserve.configuration.getLiquidationThreshold();
    ltv = (totalCollateralBase == 0) ? 0 : totalDebtBase * 10000 / totalCollateralBase;
    healthFactor = (totalDebtBase == 0) ? type(uint256).max : totalCollateralBase * currentLiquidationThreshold / totalDebtBase;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from '../types/DataTypes.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';

/**
 * @title SupplyLogic library
 * @author Aave
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
  using GPv2SafeERC20 for IERC20;

  event Supply(
    address indexed reserve,
    address user,
    uint256 amount,
    uint16 indexed referralCode
  );

  event Withdraw(
    address indexed reserve, 
    address indexed user, 
    uint256 amount
  );

  event AddFund(
    address indexed reserve, 
    address indexed user, 
    uint256 amount
  );

  event RemoveFund(
    address indexed reserve, 
    address indexed user, 
    uint256 amount
  );
  
  /**
   * @notice Implements the supply feature. Through `supply()`, users supply assets to the Aave protocol.
   * @dev Emits the `Supply()` event.
   * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
   * collateral.
   * @param reservesData The state of all the reserves
   * @param reservesList The state of the reserves list
   * @param params The additional parameters needed to execute the supply function
   */
  function executeSupply(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteSupplyParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    ValidationLogic.validateSupply(reserve, params.amount);

    IPToken(reserve.pTokenAddress).supply(msg.sender, params.amount, params.referralCode);
    IERC20(params.asset).safeTransferFrom(msg.sender, reserve.pTokenAddress, params.amount);

    emit Supply(params.asset, msg.sender, params.amount, params.referralCode);
  }

  /**
   * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their pTokens for the underlying asset
   * previously supplied in the Aave protocol.
   * @dev Emits the `Withdraw()` event.
   * @param reservesData The state of all the reserves
   * @param reservesList The list of all the reserves
   * @param params The additional parameters needed to execute the withdraw function
   * @return The actual amount withdrawn
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (uint256, uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    uint256 userBalance = IPToken(reserve.pTokenAddress).balanceOf(msg.sender);
    uint256 amountToWithdraw = params.amount;

    if (amountToWithdraw > userBalance || params.amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(reserve, reservesList, params.reservesCount, amountToWithdraw, params.oracle);
    IPToken(reserve.pTokenAddress).withdraw(msg.sender, amountToWithdraw);
    IPToken(reserve.pTokenAddress).transferUnderlyingTo(msg.sender, amountToWithdraw);

    uint256 userBalanceUpdate = IPToken(reserve.pTokenAddress).balanceOf(msg.sender);
    emit Withdraw(params.asset, msg.sender, amountToWithdraw);
    return (amountToWithdraw, userBalanceUpdate);
  }

  /**
   * @notice Implements the addFund feature. Through `addFund()`, users add their funds for the underlying asset
   * @dev Emits the `AddFund()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the addFund function
   */
  function executeAddFund(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteAddFundParams memory params
  ) external returns (uint256, uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];

    IERC20(params.asset).safeTransferFrom(msg.sender, reserve.pTokenAddress, params.amount);
    emit AddFund(params.asset, msg.sender, params.amount);
  }

  /**
   * @notice Implements the removeFund feature. Through `removeFund()`, users remove their funds for the underlying asset
   * @dev Emits the `RemoveFund()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the removeFund function
   */
  function executeRemoveFund(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteRemoveFundParams memory params
  ) external returns (uint256, uint256) {
    // DataTypes.ReserveData storage reserve = reservesData[params.asset];
    // uint256 userFundBalance = IPToken(reserve.pTokenAddress).fundBalanceOf(msg.sender);
    // uint256 amountToRemove = params.amount;

    // if (amountToRemove > userFundBalance || params.amount == type(uint256).max) {
    //   amountToRemove = userFundBalance;
    // }

    // IPToken(reserve.pTokenAddress).removeFund(msg.sender, amountToRemove);
    // IPToken(reserve.pTokenAddress).transferUnderlyingTo(msg.sender, amountToRemove);
    // emit RemoveFund(params.asset, msg.sender, amountToRemove);
  }

  
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';

library BorrowLogic {
  using GPv2SafeERC20 for IERC20;

  event Borrow(
    address indexed reserve,
    address user,
    uint256 amount,
    uint16 indexed referralCode
  );

  event Repay(
    address indexed reserve,
    address indexed user,
    uint256 amount
  );
  
  /**
   * @notice Implements the borrow feature. Through `borrow()`, users borrow assets to the Aave protocol.
   * @dev Emits the `Borrow()` event.
   * @param reservesData The state of all the reserves
   * @param reservesList The list of all the reserves
   * @param params The additional parameters needed to execute the borrow function
   */
  function executeBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteBorrowParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveData storage reserveB = reservesData[params.borrowingAsset];
    ValidationLogic.validateBorrow(reserve, reserveB, reservesList, params.reservesCount, params.borrowingAsset, params.amount, params.oracle);
    IPToken(reserve.pTokenAddress).borrow(msg.sender, params.borrowingAsset, params.amount);
    IPToken(reserveB.pTokenAddress).transferUnderlyingTo(msg.sender, params.amount);

    emit Borrow(params.asset, msg.sender, params.amount, params.referralCode);
  }

  /**
   * @notice Implements the repay feature.
   * @dev  Emits the `Repay()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The list of all the reserves
   * @param params The additional parameters needed to execute the repay function
   * @return The actual amount being repaid
   */
  function executeRepay(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteRepayParams memory params
  ) external returns (uint256, uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveData storage reserveB = reservesData[params.borrowingAsset];
    
    uint256 userBorrowBalance = IPToken(reserve.pTokenAddress).borrowBalanceOf(msg.sender, params.borrowingAsset);

    uint256 paybackAmount = params.amount;
    if (paybackAmount > userBorrowBalance || params.amount == type(uint256).max) {
      paybackAmount = userBorrowBalance;
    }

    // ValidationLogic.validateRepay(reserve, params.borrowingAsset, paybackAmount);

    IPToken(reserve.pTokenAddress).repay(msg.sender, params.borrowingAsset, paybackAmount);
    IERC20(params.borrowingAsset).safeTransferFrom(msg.sender, reserveB.pTokenAddress, paybackAmount);
    uint256 userBorrowBalanceUpdated = IPToken(reserve.pTokenAddress).borrowBalanceOf(msg.sender, params.borrowingAsset);

    emit Repay(params.asset, msg.sender, paybackAmount);
    return (paybackAmount, userBorrowBalanceUpdated);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title GeneralLogic library
 * @author Aave
 * @notice Implements the logic for General specific functions
 */
library GeneralLogic{
  uint256 internal constant RATE_PRECISION = 1000000;

  function getUserBalanceInBaseCurrency(address asset, uint256 amount, address oracle) external view returns (uint256) {
    if(amount == 0) return 0;
    uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(asset);
    uint8 decimals = IERC20Detailed(asset).decimals();
    uint256 assetUnit = 10 ** decimals;
    return amount * assetPrice / assetUnit;
  }

  function getBaseCurrencyInBalance(address asset, uint256 baseCurrency, address oracle) external view returns (uint256) {
    if(baseCurrency == 0) return 0;
    uint256 assetPrice = IPriceOracleGetter(oracle).getAssetPrice(asset);
    uint8 decimals = IERC20Detailed(asset).decimals();
    uint256 assetUnit = 10 ** decimals;
    return baseCurrency * assetUnit /  assetPrice;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from '../types/DataTypes.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';
import {IPrxyTreasury} from '../../../interfaces/IPrxyTreasury.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {GeneralLogic} from './GeneralLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';

library ParticularLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  event ReduxInterestSplit(
    address indexed collateralAsset,
    uint256 totalRewardAmount,
    uint256 totalUncollateralAmount
  );

  event ClaimPrxy(
    address indexed collateralAsset,
    address indexed user,
    uint256 claimAmount
  );

  event SwitchedSupplyMode(
    address indexed collateralAsset,
    address indexed user,
    uint16 supplyMode
  );

  /**
   * @notice Function to transfer the redux interest to the treasury. The caller (liquidator)
   * @dev Emits the `ReduxInterestToTreasuryCall()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The list of all the reserves
   * @param supplierList The list of all the suppliers
   * @param params The additional parameters needed to execute the ReduxInterestToTreausry function
   **/
  function executeSplitReduxInterest(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserList storage supplierList,
    DataTypes.ExecuteSplitReduxInterestParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    uint256 totalRewardBaseCurrency = 0;
    for(uint256 i = 0; i < params.reservesCount; i++) {
      address supplyingAsset = reservesList[i];
      DataTypes.ReserveData storage reserveX = reservesData[supplyingAsset];
      uint256 rewardAmount = reserveX.splitRate * IPToken(reserveX.pTokenAddress).getReduxInterestOf(params.asset) / GeneralLogic.RATE_PRECISION;
      totalRewardBaseCurrency += GeneralLogic.getUserBalanceInBaseCurrency(supplyingAsset, rewardAmount, params.oracle);
    }

    uint256 totalRewardAmount = GeneralLogic.getBaseCurrencyInBalance(params.asset, totalRewardBaseCurrency, params.oracle);
    IPToken(reserve.pTokenAddress).reduxInterestSplit(reserve.splitRate);

    if (totalRewardAmount == 0) {
      reserve.supplyRate = 0;
      return;
    }
    
    address[] storage suppliers = supplierList.list;
    uint256 totalUncollateralAmount = 0;
    for (uint256 i = 0; i < suppliers.length; i++) totalUncollateralAmount += _calcUncollateralAmount(reserve, suppliers[i]);
    if(totalUncollateralAmount == 0) {
      reserve.supplyRate = 0;
      return;
    }
    reserve.supplyRate = totalRewardAmount * MathUtils.SECONDS_PER_YEAR * GeneralLogic.RATE_PRECISION / (totalUncollateralAmount * params.elapsedTime);
   
    uint256 realTotalReward = totalRewardAmount;
    totalRewardAmount = 0;
    for (uint256 i = 0; i < suppliers.length; i++) {
      uint256 uncollateralAmount = _calcUncollateralAmount(reserve, suppliers[i]);
      uint256 userRewardAmount = realTotalReward * uncollateralAmount / totalUncollateralAmount;
      totalRewardAmount += userRewardAmount;
      _supplyReward(reserve, suppliers[i], userRewardAmount);
    }

    IERC20(params.asset).transfer(reserve.pTokenAddress, totalRewardAmount);
    emit ReduxInterestSplit(params.asset, totalRewardAmount, totalUncollateralAmount);
  }

  function _supplyReward(DataTypes.ReserveData storage reserve, address user, uint256 userRewardAmount) internal{
    uint16 mode = IPToken(reserve.pTokenAddress).supplyMode(user);
    IPToken(reserve.pTokenAddress).supply(user, userRewardAmount, mode);
  }

  function _calcUncollateralAmount (
    DataTypes.ReserveData storage reserve,
    address user
  ) internal returns(uint256) {
    if(IPToken(reserve.pTokenAddress).supplyMode(user) != 0) return 0;
    uint256 userSupplyBalance = IPToken(reserve.pTokenAddress).balanceOf(user);
    uint256 userCollateralBalance = IPToken(reserve.pTokenAddress).collateralBalanceOf(user);
    return userSupplyBalance - userCollateralBalance;
  }
  /**
   * @notice Function to claim the prxy interest
   * @dev Emits the `ClaimPrxy()` event
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the claimprxy function
   **/
  function executeClaimPrxy(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteClaimPrxyParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];

    uint256 userPrxyBalance = IPToken(reserve.pTokenAddress).prxyBalanceOf(msg.sender);
    uint256 amountToClaim = params.amount;

    if (amountToClaim > userPrxyBalance || params.amount == type(uint256).max) {
      amountToClaim = userPrxyBalance;
    }

    ValidationLogic.validateClaimPrxyCall(reserve, amountToClaim);
    IPToken(reserve.pTokenAddress).claimPrxy(msg.sender, amountToClaim);
    IPrxyTreasury(params.prxyTreasury).transferPrxyTo(msg.sender, amountToClaim);
    emit ClaimPrxy(params.asset, msg.sender, amountToClaim);
  }

  /**
   * @notice Function to switch the supply mode
   * @dev Emits the `SwitchedSupplyMode()` event
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the switchSupplyMode function
   **/
  function executeSwitchSupplyMode(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteSwitchSupplyModeParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];

    IPToken(reserve.pTokenAddress).switchSupplyMode(msg.sender);
    uint16 currentSupplyMode = IPToken(reserve.pTokenAddress).supplyMode(msg.sender);
    emit SwitchedSupplyMode(params.asset, msg.sender, currentSupplyMode);
  }

  function clearReduxInterest(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    uint256 reservesCount
  ) external {
    for(uint256 i = 0; i < reservesCount; i++) {
      address supplyingAsset = reservesList[i];
      DataTypes.ReserveData storage reserve = reservesData[supplyingAsset];
      IPToken(reserve.pTokenAddress).clearReduxInterest();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';
import {ValidationLogic} from './ValidationLogic.sol';

/**
 * @title LiquidationLogic library
 * @author Aave
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 **/
library LiquidationLogic {
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed user,
    uint256 liquidatedCollateralAmount
  );

  /**
   * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
   * @dev Emits the `LiquidationCall()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The List of all the reserves
   * @param params The additional parameters needed to execute the liquidation function
   **/
  function executeLiquidationCall(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    uint256 userBalance = IPToken(reserve.pTokenAddress).balanceOf(params.user);

    ValidationLogic.validateLiquidationCall(reserve, reservesList, params.reservesCount, params.user, params.oracle);

    IPToken(reserve.pTokenAddress).liquidate(params.user);

    emit LiquidationCall(
      params.asset,
      params.user,
      userBalance
    );
  }

  /**
   * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
   * @dev Emits the `LiquidationCall()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The List of all the reserves
   * @param params The additional parameters needed to execute the liquidation function
   * @return if liquidated true else false
   **/
  function executeLiquidateWhenReached(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) external returns (bool) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    uint256 userBalance = IPToken(reserve.pTokenAddress).balanceOf(params.user);

    bool liquidated = ValidationLogic.hasReachedLiquidation(reserve, reservesList, params.reservesCount, params.user, params.oracle);

    if(liquidated) {
      IPToken(reserve.pTokenAddress).liquidate(params.user);
      emit LiquidationCall(
        params.asset,
        params.user,
        userBalance
      );
    }
    
    return liquidated;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPrxyTreasury
 * @author USDC-Redux
 * @notice Interface for the Prxy Treasury.
 **/
interface IPrxyTreasury {
  /**
   * @notice Returns the address of the proxy token
   * @return Address of the prxy token
   **/
  function getPrxyToken() external view returns(address);

  /**
   * @notice Set the address of the proxy token
   * @param prxyToken The address of the prxy token
   **/
  function setPrxyToken(address prxyToken) external;

  /**
   * @notice Deposit the proxy token
   * @param amount The prxy amount to deposit
   **/
  function depositPrxy(uint256 amount) external;

  /**
   * @notice Transfer the prxy token to target
   * @param target The address of the target
   * @param amount The prxy amount to transfer
   **/
  function transferPrxyTo(address target, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {DataTypes} from '../types/DataTypes.sol';

library UserListLogic {
  function addUser(DataTypes.UserList storage self, address userAddress) internal {
    if(self.ids[userAddress] == 0) {
      self.list.push(userAddress);
      self.ids[userAddress] = self.list.length;
    }
  }

  function hasUser(DataTypes.UserList storage self, address userAddress) internal view returns(bool) {
    return self.ids[userAddress] != 0;
  }

  function removeUser(DataTypes.UserList storage self, address userAddress) internal {
    uint256 id = self.ids[userAddress];
    if(id > 0) {
      self.ids[userAddress] = 0;
      if(id != self.list.length) {
        address last = self.list[self.list.length - 1];
        self.list[id - 1] = last;
        self.ids[last] = id;
      }
      self.list.pop();
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from '../../openzeppelin/contracts/IERC20.sol';

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
  /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
  /// also when the token returns `false`.
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transfer.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transfer');
  }

  /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
  /// reverts also when the token returns `false`.
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transferFrom.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 68), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transferFrom');
  }

  /// @dev Verifies that the last return was a successful `transfer*` call.
  /// This is done by checking that the return data is either empty, or
  /// is a valid ABI encoded boolean.
  function getLastTransferResult(IERC20 token) private view returns (bool success) {
    // NOTE: Inspecting previous return data requires assembly. Note that
    // we write the return data to memory 0 in the case where the return
    // data size is 32, this is OK since the first 64 bytes of memory are
    // reserved by Solidy as a scratch space that can be used within
    // assembly blocks.
    // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
    // solhint-disable-next-line no-inline-assembly
    assembly {
      /// @dev Revert with an ABI encoded Solidity error with a message
      /// that fits into 32-bytes.
      ///
      /// An ABI encoded Solidity error has the following memory layout:
      ///
      /// ------------+----------------------------------
      ///  byte range | value
      /// ------------+----------------------------------
      ///  0x00..0x04 |        selector("Error(string)")
      ///  0x04..0x24 |      string offset (always 0x20)
      ///  0x24..0x44 |                    string length
      ///  0x44..0x64 | string value, padded to 32-bytes
      function revertWithMessage(length, message) {
        mstore(0x00, '\x08\xc3\x79\xa0')
        mstore(0x04, 0x20)
        mstore(0x24, length)
        mstore(0x44, message)
        revert(0x00, 0x64)
      }

      switch returndatasize()
      // Non-standard ERC20 transfer without return.
      case 0 {
        // NOTE: When the return data size is 0, verify that there
        // is code at the address. This is done in order to maintain
        // compatibility with Solidity calling conventions.
        // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
        if iszero(extcodesize(token)) {
          revertWithMessage(20, 'GPv2: not a contract')
        }

        success := 1
      }
      // Standard ERC20 transfer returning boolean success value.
      case 32 {
        returndatacopy(0, 0, returndatasize())

        // NOTE: For ABI encoding v1, any non-zero value is accepted
        // as `true` for a boolean. In order to stay compatible with
        // OpenZeppelin's `SafeERC20` library which is known to work
        // with the existing ERC20 implementation we care about,
        // make sure we return success for any non-zero return value
        // from the `transfer*` call.
        success := iszero(iszero(mload(0)))
      }
      default {
        revertWithMessage(31, 'GPv2: malformed transfer result')
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;


  /**
   * @notice Initializes a reserve.
   * @param reserve The reserve object
   * @param supplyingAsset The address of the supplying asset
   * @param borrowRate The borrowing rate
   * @param prxyRate The prxy rate
   * @param pTokenAddress The address of the overlying ptoken contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address supplyingAsset,
    uint256 borrowRate,
    uint256 prxyRate,
    uint256 splitRate,
    address pTokenAddress
  ) internal {
    require(reserve.pTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

    reserve.supplyingAsset = supplyingAsset;
    reserve.borrowRate = borrowRate;
    reserve.prxyRate = prxyRate;
    reserve.splitRate = splitRate;
    reserve.pTokenAddress = pTokenAddress;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {WadRayMath} from './WadRayMath.sol';

/**
 * @title MathUtils library
 * @author Aave
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
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
    uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
    unchecked {
      result = result / SECONDS_PER_YEAR;
    }

    return WadRayMath.RAY + result;
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
   * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
   * error per different time periods
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
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.RAY;
    }

    uint256 expMinusOne;
    uint256 expMinusTwo;
    uint256 basePowerTwo;
    uint256 basePowerThree;
    unchecked {
      expMinusOne = exp - 1;

      expMinusTwo = exp > 2 ? exp - 2 : 0;

      basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
      basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
    }

    uint256 secondTerm = exp * expMinusOne * basePowerTwo;
    unchecked {
      secondTerm /= 2;
    }
    uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
    unchecked {
      thirdTerm /= 6;
    }

    return WadRayMath.RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IInitializablePToken} from './IInitializablePToken.sol';

/**
 * @title IPToken
 * @author Aave
 * @notice Defines the basic interface for an PToken.
 **/
interface IPToken is IERC20Detailed, IInitializablePToken {
  /**
   * @notice Returns the total amount of the borrowing asset of this pToken
   * @return The total amount of the borrowing asset 
   **/
  function totalBorrow(address asset) external view returns (uint256);

  /**
   * @notice Returns the total amount of the prxy interest of this pToken
   * @return The total amount of the prxy interest 
   **/
  function totalPrxy() external view returns (uint256);

  /**
   * @notice Returns the balance of the borrowing asset of user
   * @return The user balance of the borrowing asset
   **/
  function borrowBalanceOf(address user, address asset) external view returns (uint256);

  /**
   * @notice Returns the collateral balance of the borrowing assets of user
   * @return The user collateral balance of the borrowing assets
   **/
  function collateralBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the balance of the prxy interest of user
   * @return The user balance of the prxy interest
   **/
  function prxyBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the supply mode of the user
   * @return The supply mode
   **/
  function supplyMode(address user) external view returns (uint16);

  /**
   * @notice Returns the last update timestamp of this pToken
   * @return The last update timestamp of this pToken
   **/
  function lastUpdateTimestamp() external view returns (uint40);

  /** 
   * @notice Returns the last update timestamp of the user
   * @return The last update timestamp of user
   **/
  function lastUpdateTimestampOf(address user) external view returns (uint40);

  /** 
   * @notice Returns the decimals of the supplying asset
   * @return The decimals of the supplying asset
   **/
  function supplyDecimals() external view returns (uint8);

  /**
   * @notice Handle the switch supply mode action of the user
   * @param user The address of supplier
   **/
  function switchSupplyMode(address user) external;

  /**
   * @notice Hanlde the supply action of the user
   * @param user The address of supplier
   * @param amount The supplying amount
   **/
  function supply(address user, uint256 amount, uint16 referralCode) external;

  /**
   * @notice Handle the borrow action of the user
   * @param user The address of borrower
   * @param amount The borrowing amount
   **/
  function borrow(address user, address asset, uint256 amount) external;

  /**
   * @notice Handle the withdraw action of the user
   * @param user The address of withdrawer
   * @param amount The withdrawing amount
   **/
  function withdraw(address user, uint256 amount) external;

  /**
   * @notice Handle the repayment action of the user
   * @param user The address of repayer
   * @param amount The repaying amount
   **/
  function repay(address user, address assset, uint256 amount) external;

  /**
   * @notice Handle the liquidation action of the user
   * @param user The address of liquidator
   **/
  function liquidate(address user) external;

  /**
   * @notice Transfer the redux interest to treasury
   * @param split The split rate
   **/
  function reduxInterestSplit(uint256 split) external;

  /**
   * @notice Get the redux interest amount
   * @return The redux interest amount
   **/
  function getReduxInterest() external view returns(uint256);

  /**
   * @notice Get the redux interest amount of asset
   * @param asset The addresss of asset
   * @return The redux interest amount and elapsed time of asset
   **/
  function getReduxInterestOf(address asset) external view returns(uint256);

  /**
   * @notice Clear the redux interest
   **/
  function clearReduxInterest() external;

  /**
   * @notice Handle the claim prxy action of the user
   * @param user The address of claimer
   * @param amount The amount of prxy token
   **/
  function claimPrxy(address user, uint256 amount) external;

  /**
   * @notice Transfers the underlying asset to `target`.
   * @dev Used by the Pool to transfer assets in borrow(), withdraw()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external;

  /**
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
  // Maximum percentage factor (100.00%)
  uint256 internal constant PERCENTAGE_FACTOR = 1e4;

  // Half percentage factor (50.00%)
  uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

  /**
   * @notice Executes a percentage multiplication
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return result value percentmul percentage
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
    // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
    assembly {
      if iszero(
        or(
          iszero(percentage),
          iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage)))
        )
      ) {
        revert(0, 0)
      }

      result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
    }
  }

  /**
   * @notice Executes a percentage division
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return result value percentdiv percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
    // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
    assembly {
      if or(
        iszero(percentage),
        iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
      ) {
        revert(0, 0)
      }

      result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPool} from './IPool.sol';

/**
 * @title IInitializablePToken
 * @author Aave
 * @notice Interface for the initialize function on PToken
 **/
interface IInitializablePToken {
  /**
   * @dev Emitted when an pToken is initialized
   * @param supplyingAsset The address of the supplying asset
   * @param pool The address of the associated pool
   * @param pTokenDecimals The decimals of the underlying
   * @param pTokenName The name of the pToken
   * @param pTokenSymbol The symbol of the pToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed supplyingAsset,
    address indexed pool,
    uint8 pTokenDecimals,
    string pTokenName,
    string pTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the pToken
   * @param pool The pool contract that is initializing this contract
   * @param supplyingAsset The address of the supplying asset of this pToken
   * @param pTokenDecimals The decimals of the pToken, same as the supplying asset's
   * @param pTokenName The name of the pToken
   * @param pTokenSymbol The symbol of the pToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address supplyingAsset,
    uint8 pTokenDecimals,
    string calldata pTokenName,
    string calldata pTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GeneralLogic} from './GeneralLogic.sol';
import {IPToken} from '../../../interfaces/IPToken.sol';
import {Errors} from '../helpers/Errors.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @notice Validates a supply action.
   * @param reserve The data of the reserve
   * @param amount The amount to be supplied
   */
  function validateSupply(DataTypes.ReserveData storage reserve, uint256 amount)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , bool isPaused) = reserve.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    uint256 supplyCap = reserve.configuration.getSupplyCap();
    require(
      supplyCap == 0 ||
        (IPToken(reserve.pTokenAddress).totalSupply() + amount) <=
        supplyCap * (10 ** IPToken(reserve.pTokenAddress).supplyDecimals()),
      Errors.SUPPLY_CAP_EXCEEDED
    );
  }

  /**
   * @notice Validates a borrow action.
   * @param reserve The data of the reserve
   * @param reserveB The data of the reserveB
   * @param reservesList The list of the reserve
   * @param reservesCount The count of the reserves list
   * @param asset The address of borrowing asset
   * @param amount The amount to be borrowed
   * @param oracle The address of price oracle
   */
  function validateBorrow(DataTypes.ReserveData storage reserve, DataTypes.ReserveData storage reserveB, mapping(uint256 => address) storage reservesList, uint256 reservesCount, address asset, uint256 amount, address oracle)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, bool borrowingEnabled, bool isPaused) = reserveB.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);
    require(borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

    uint256 ltv = reserve.configuration.getLtv();
    uint256 supplyBalance = IPToken(reserve.pTokenAddress).balanceOf(msg.sender);
    uint256 userSupplyInBaseCurrency = GeneralLogic.getUserBalanceInBaseCurrency(reserve.supplyingAsset, supplyBalance, oracle);
    uint256 userBorrowInBaseCurrency = _getUserBorrowInBaseCurrency(reserve.pTokenAddress, reservesList, reservesCount, msg.sender, oracle);
    userBorrowInBaseCurrency += GeneralLogic.getUserBalanceInBaseCurrency(asset, amount, oracle);

    require(userBorrowInBaseCurrency * 10000 <= userSupplyInBaseCurrency * ltv, Errors.LTV_VALIDATION_FAILED);
  }

  /**
   * @notice Validates a withdraw action.
   * @param reserve The data of the reserve
   * @param reservesList The list of the reserve
   * @param reservesCount The count of the reserves list
   * @param amount The amount to be withdrawn
   * @param oracle The address of price oracle
   */
  function validateWithdraw(DataTypes.ReserveData storage reserve, mapping(uint256 => address) storage reservesList, uint256 reservesCount, uint256 amount, address oracle)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , bool isPaused) = reserve.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    uint256 maxLtv = reserve.configuration.getLiquidationThreshold();
    uint256 supplyBalance = IPToken(reserve.pTokenAddress).balanceOf(msg.sender) - amount;
    

    uint256 userSupplyInBaseCurrency = GeneralLogic.getUserBalanceInBaseCurrency(reserve.supplyingAsset, supplyBalance, oracle);
    uint256 userBorrowInBaseCurrency = _getUserBorrowInBaseCurrency(reserve.pTokenAddress, reservesList, reservesCount, msg.sender, oracle);

    require(userBorrowInBaseCurrency * 10000 <= userSupplyInBaseCurrency * maxLtv, Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD);
  }

  /**
   * @notice Validates a repay action.
   * @param reserve The data of the reserve
   * @param amount The amount to be repayed
   */
  function validateRepay(DataTypes.ReserveData storage reserve, uint256 amount)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, bool borrowingEnabled, bool isPaused) = reserve.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);
    require(borrowingEnabled, Errors.BORROWING_NOT_ENABLED);
  }

  /**
   * @notice Validates a liquidate action.
   * @param reserve The data of the reserve
   * @param reservesList The list of the reserve
   * @param reservesCount The count of the reserves list
   * @param user The address of the user
   * @param oracle The address of price oracle
   */
  function validateLiquidationCall(DataTypes.ReserveData storage reserve, mapping(uint256 => address) storage reservesList, uint256 reservesCount, address user, address oracle)
    internal
    view
  {
    (bool isActive, bool isFrozen, , bool isPaused) = reserve.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    uint256 maxLtv = reserve.configuration.getLiquidationThreshold();
    uint256 supplyBalance = IPToken(reserve.pTokenAddress).balanceOf(user);

    uint256 userSupplyInBaseCurrency = GeneralLogic.getUserBalanceInBaseCurrency(reserve.supplyingAsset, supplyBalance, oracle);
    uint256 userBorrowInBaseCurrency = _getUserBorrowInBaseCurrency(reserve.pTokenAddress, reservesList, reservesCount, user, oracle);

    require(userBorrowInBaseCurrency * 10000 > userSupplyInBaseCurrency * maxLtv, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
  }

  /**
   * @notice Validates a liquidate action.
   * @param reserve The data of the reserve
   * @param reservesList The list of the reserve
   * @param reservesCount The count of the reserves list
   * @param user The address of the user
   * @param oracle The address of price oracle
   * @return liquidation is possible or not
   */
  function hasReachedLiquidation(DataTypes.ReserveData storage reserve, mapping(uint256 => address) storage reservesList, uint256 reservesCount, address user, address oracle) internal view returns (bool) {
    (bool isActive, bool isFrozen, , bool isPaused) = reserve.configuration.getFlags();
    if(!isActive || isPaused || isFrozen) return false;

    uint256 maxLtv = reserve.configuration.getLiquidationThreshold();
    uint256 supplyBalance = IPToken(reserve.pTokenAddress).balanceOf(user);

    uint256 userSupplyInBaseCurrency = GeneralLogic.getUserBalanceInBaseCurrency(reserve.supplyingAsset, supplyBalance, oracle);
    uint256 userBorrowInBaseCurrency = _getUserBorrowInBaseCurrency(reserve.pTokenAddress, reservesList, reservesCount, user, oracle);

    return (userBorrowInBaseCurrency * 10000 > userSupplyInBaseCurrency * maxLtv);
  }

  /**
   * @notice Validates a claim prxy action.
   * @param reserve The data of the reserve
   * @param amount The amount to claim
   */
  function validateClaimPrxyCall(DataTypes.ReserveData storage reserve, uint256 amount)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , bool isPaused) = reserve.configuration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);
  }

  function _getUserBorrowInBaseCurrency(address pToken, mapping(uint256 => address) storage reservesList, uint256 reservesCount, address user, address oracle) 
  internal view returns(uint256)
  {
    uint256 userBorrowInBaseCurrency = 0;
    for(uint256 i = 0; i < reservesCount; i++) {
      uint256 borrowBalance = IPToken(pToken).borrowBalanceOf(user, reservesList[i]);
      userBorrowInBaseCurrency += GeneralLogic.getUserBalanceInBaseCurrency(reservesList[i], borrowBalance, oracle);
    }
    return userBorrowInBaseCurrency;
  }
}