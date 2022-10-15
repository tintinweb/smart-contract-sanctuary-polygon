// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IAlgebraFactory.sol';
import './interfaces/IAlgebraPoolDeployer.sol';
import './interfaces/IDataStorageOperator.sol';
import './libraries/AdaptiveFee.sol';
import './DataStorageOperator.sol';

/**
 * @title Algebra factory
 * @notice Is used to deploy pools and its dataStorages
 */
contract AlgebraFactory is IAlgebraFactory {
  /// @inheritdoc IAlgebraFactory
  address public override owner;

  /// @inheritdoc IAlgebraFactory
  address public immutable override poolDeployer;

  /// @inheritdoc IAlgebraFactory
  address public override farmingAddress;

  /// @inheritdoc IAlgebraFactory
  address public override vaultAddress;

  // values of constants for sigmoids in fee calculation formula
  AdaptiveFee.Configuration public baseFeeConfiguration =
    AdaptiveFee.Configuration(
      3000 - Constants.BASE_FEE, // alpha1
      15000 - 3000, // alpha2
      360, // beta1
      60000, // beta2
      59, // gamma1
      8500, // gamma2
      0, // volumeBeta
      10, // volumeGamma
      Constants.BASE_FEE // baseFee
    );

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /// @inheritdoc IAlgebraFactory
  mapping(address => mapping(address => address)) public override poolByPair;

  constructor(address _poolDeployer, address _vaultAddress) {
    owner = msg.sender;
    emit Owner(msg.sender);

    poolDeployer = _poolDeployer;
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function createPool(address tokenA, address tokenB) external override returns (address pool) {
    require(tokenA != tokenB);
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0));
    require(poolByPair[token0][token1] == address(0));

    IDataStorageOperator dataStorage = new DataStorageOperator(computeAddress(token0, token1));

    dataStorage.changeFeeConfiguration(baseFeeConfiguration);

    pool = IAlgebraPoolDeployer(poolDeployer).deploy(address(dataStorage), address(this), token0, token1);

    poolByPair[token0][token1] = pool; // to avoid future addresses comparing we are populating the mapping twice
    poolByPair[token1][token0] = pool;
    emit Pool(token0, token1, pool);
  }

  /// @inheritdoc IAlgebraFactory
  function setOwner(address _owner) external override onlyOwner {
    require(owner != _owner);
    emit Owner(_owner);
    owner = _owner;
  }

  /// @inheritdoc IAlgebraFactory
  function setFarmingAddress(address _farmingAddress) external override onlyOwner {
    require(farmingAddress != _farmingAddress);
    emit FarmingAddress(_farmingAddress);
    farmingAddress = _farmingAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function setVaultAddress(address _vaultAddress) external override onlyOwner {
    require(vaultAddress != _vaultAddress);
    emit VaultAddress(_vaultAddress);
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function setBaseFeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  ) external override onlyOwner {
    require(uint256(alpha1) + uint256(alpha2) + uint256(baseFee) <= type(uint16).max, 'Max fee exceeded');
    require(gamma1 != 0 && gamma2 != 0 && volumeGamma != 0, 'Gammas must be > 0');

    baseFeeConfiguration = AdaptiveFee.Configuration(alpha1, alpha2, beta1, beta2, gamma1, gamma2, volumeBeta, volumeGamma, baseFee);
    emit FeeConfiguration(alpha1, alpha2, beta1, beta2, gamma1, gamma2, volumeBeta, volumeGamma, baseFee);
  }

  bytes32 internal constant POOL_INIT_CODE_HASH = 0x6ec6c9c8091d160c0aa74b2b14ba9c1717e95093bd3ac085cee99a49aab294a4;

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param token0 first token
  /// @param token1 second token
  /// @return pool The contract address of the Algebra pool
  function computeAddress(address token0, address token1) internal view returns (address pool) {
    pool = address(uint256(keccak256(abi.encodePacked(hex'ff', poolDeployer, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH))));
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for the Algebra Factory
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraFactory {
  /**
   *  @notice Emitted when the owner of the factory is changed
   *  @param newOwner The owner after the owner was changed
   */
  event Owner(address indexed newOwner);

  /**
   *  @notice Emitted when the vault address is changed
   *  @param newVaultAddress The vault address after the address was changed
   */
  event VaultAddress(address indexed newVaultAddress);

  /**
   *  @notice Emitted when a pool is created
   *  @param token0 The first token of the pool by address sort order
   *  @param token1 The second token of the pool by address sort order
   *  @param pool The address of the created pool
   */
  event Pool(address indexed token0, address indexed token1, address pool);

  /**
   *  @notice Emitted when the farming address is changed
   *  @param newFarmingAddress The farming address after the address was changed
   */
  event FarmingAddress(address indexed newFarmingAddress);

  event FeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  );

  /**
   *  @notice Returns the current owner of the factory
   *  @dev Can be changed by the current owner via setOwner
   *  @return The address of the factory owner
   */
  function owner() external view returns (address);

  /**
   *  @notice Returns the current poolDeployerAddress
   *  @return The address of the poolDeployer
   */
  function poolDeployer() external view returns (address);

  /**
   * @dev Is retrieved from the pools to restrict calling
   * certain functions not by a tokenomics contract
   * @return The tokenomics contract address
   */
  function farmingAddress() external view returns (address);

  function vaultAddress() external view returns (address);

  /**
   *  @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
   *  @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
   *  @param tokenA The contract address of either token0 or token1
   *  @param tokenB The contract address of the other token
   *  @return pool The pool address
   */
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);

  /**
   *  @notice Creates a pool for the given two tokens and fee
   *  @param tokenA One of the two tokens in the desired pool
   *  @param tokenB The other of the two tokens in the desired pool
   *  @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
   *  from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
   *  are invalid.
   *  @return pool The address of the newly created pool
   */
  function createPool(address tokenA, address tokenB) external returns (address pool);

  /**
   *  @notice Updates the owner of the factory
   *  @dev Must be called by the current owner
   *  @param _owner The new owner of the factory
   */
  function setOwner(address _owner) external;

  /**
   * @dev updates tokenomics address on the factory
   * @param _farmingAddress The new tokenomics contract address
   */
  function setFarmingAddress(address _farmingAddress) external;

  /**
   * @dev updates vault address on the factory
   * @param _vaultAddress The new vault contract address
   */
  function setVaultAddress(address _vaultAddress) external;

  /**
   * @notice Changes initial fee configuration for new pools
   * @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
   * alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max
   * gammas must be > 0
   * @param alpha1 max value of the first sigmoid
   * @param alpha2 max value of the second sigmoid
   * @param beta1 shift along the x-axis for the first sigmoid
   * @param beta2 shift along the x-axis for the second sigmoid
   * @param gamma1 horizontal stretch factor for the first sigmoid
   * @param gamma2 horizontal stretch factor for the second sigmoid
   * @param volumeBeta shift along the x-axis for the outer volume-sigmoid
   * @param volumeGamma horizontal stretch factor the outer volume-sigmoid
   * @param baseFee minimum possible fee
   */
  function setBaseFeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title An interface for a contract that is capable of deploying Algebra Pools
 * @notice A contract that constructs a pool must implement this to pass arguments to the pool
 * @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
 * of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDeployer {
  /**
   *  @notice Emitted when the factory address is changed
   *  @param factory The factory address after the address was changed
   */
  event Factory(address indexed factory);

  /**
   * @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
   * @dev Called by the pool constructor to fetch the parameters of the pool
   * Returns dataStorage The pools associated dataStorage
   * Returns factory The factory address
   * Returns token0 The first token of the pool by address sort order
   * Returns token1 The second token of the pool by address sort order
   */
  function parameters()
    external
    view
    returns (
      address dataStorage,
      address factory,
      address token0,
      address token1
    );

  /**
   * @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
   * clearing it after deploying the pool.
   * @param dataStorage The pools associated dataStorage
   * @param factory The contract address of the Algebra factory
   * @param token0 The first token of the pool by address sort order
   * @param token1 The second token of the pool by address sort order
   * @return pool The deployed pool's address
   */
  function deploy(
    address dataStorage,
    address factory,
    address token0,
    address token1
  ) external returns (address pool);

  /**
   * @dev Sets the factory address to the poolDeployer for permissioned actions
   * @param factory The address of the Algebra factory
   */
  function setFactory(address factory) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../libraries/AdaptiveFee.sol';

interface IDataStorageOperator {
  event FeeConfiguration(AdaptiveFee.Configuration feeConfig);

  /**
   * @notice Returns data belonging to a certain timepoint
   * @param index The index of timepoint in the array
   * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
   * @return initialized Whether the timepoint has been initialized and the values are safe to use,
   * blockTimestamp The timestamp of the observation,
   * tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
   * secondsPerLiquidityCumulative The seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
   * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp,
   * averageTick Time-weighted average tick,
   * volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(uint32 time, int24 tick) external;

  /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
  /// @return secondsPerLiquidityCumulative The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
  /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
  /// @return volumePerAvgLiquidity The cumulative volume per liquidity value since the pool was first initialized, as of `secondsAgo`
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    );

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
  /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return TWVolatilityAverage The average volatility in the recent range
  /// @return TWVolumePerLiqAverage The average volume per liquidity in the recent range
  function getAverages(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

  /// @notice Writes an dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) external returns (uint16 indexUpdated);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(AdaptiveFee.Configuration calldata feeConfig) external;

  /// @notice Calculates gmean(volume/liquidity) for block
  /// @param liquidity The current in-range pool liquidity
  /// @param amount0 Total amount of swapped token0
  /// @param amount1 Total amount of swapped token1
  /// @return volumePerLiquidity gmean(volume/liquidity) capped by 100000 << 64
  function calculateVolumePerLiquidity(
    uint128 liquidity,
    int256 amount0,
    int256 amount1
  ) external pure returns (uint128 volumePerLiquidity);

  /// @return windowLength Length of window used to calculate averages
  function window() external view returns (uint32 windowLength);

  /// @notice Calculates fee based on combination of sigmoids
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return fee The fee in hundredths of a bip, i.e. 1e-6
  function getFee(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './Constants.sol';

/// @title AdaptiveFee
/// @notice Calculates fee based on combination of sigmoids
library AdaptiveFee {
  // alpha1 + alpha2 + baseFee must be <= type(uint16).max
  struct Configuration {
    uint16 alpha1; // max value of the first sigmoid
    uint16 alpha2; // max value of the second sigmoid
    uint32 beta1; // shift along the x-axis for the first sigmoid
    uint32 beta2; // shift along the x-axis for the second sigmoid
    uint16 gamma1; // horizontal stretch factor for the first sigmoid
    uint16 gamma2; // horizontal stretch factor for the second sigmoid
    uint32 volumeBeta; // shift along the x-axis for the outer volume-sigmoid
    uint16 volumeGamma; // horizontal stretch factor the outer volume-sigmoid
    uint16 baseFee; // minimum possible fee
  }

  /// @notice Calculates fee based on formula:
  /// baseFee + sigmoidVolume(sigmoid1(volatility, volumePerLiquidity) + sigmoid2(volatility, volumePerLiquidity))
  /// maximum value capped by baseFee + alpha1 + alpha2
  function getFee(
    uint88 volatility,
    uint256 volumePerLiquidity,
    Configuration memory config
  ) internal pure returns (uint16 fee) {
    uint256 sumOfSigmoids = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1) +
      sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

    if (sumOfSigmoids > type(uint16).max) {
      // should be impossible, just in case
      sumOfSigmoids = type(uint16).max;
    }

    return uint16(config.baseFee + sigmoid(volumePerLiquidity, config.volumeGamma, uint16(sumOfSigmoids), config.volumeBeta)); // safe since alpha1 + alpha2 + baseFee _must_ be <= type(uint16).max
  }

  /// @notice calculates α / (1 + e^( (β-x) / γ))
  /// that is a sigmoid with a maximum value of α, x-shifted by β, and stretched by γ
  /// @dev returns uint256 for fuzzy testing. Guaranteed that the result is not greater than alpha
  function sigmoid(
    uint256 x,
    uint16 g,
    uint16 alpha,
    uint256 beta
  ) internal pure returns (uint256 res) {
    if (x > beta) {
      x = x - beta;
      if (x >= 6 * uint256(g)) return alpha; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = exp(x, g, g8); // < 155 bits
      res = (alpha * ex) / (g8 + ex); // in worst case: (16 + 155 bits) / 155 bits
      // so res <= alpha
    } else {
      x = beta - x;
      if (x >= 6 * uint256(g)) return 0; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = g8 + exp(x, g, g8); // < 156 bits
      res = (alpha * g8) / ex; // in worst case: (16 + 128 bits) / 156 bits
      // g8 <= ex, so res <= alpha
    }
  }

  /// @notice calculates e^(x/g) * g^8 in a series, since (around zero):
  /// e^x = 1 + x + x^2/2 + ... + x^n/n! + ...
  /// e^(x/g) = 1 + x/g + x^2/(2*g^2) + ... + x^(n)/(g^n * n!) + ...
  function exp(
    uint256 x,
    uint16 g,
    uint256 gHighestDegree
  ) internal pure returns (uint256 res) {
    // calculating:
    // g**8 + x * g**7 + (x**2 * g**6) / 2 + (x**3 * g**5) / 6 + (x**4 * g**4) / 24 + (x**5 * g**3) / 120 + (x**6 * g^2) / 720 + x**7 * g / 5040 + x**8 / 40320

    // x**8 < 152 bits (19*8) and g**8 < 128 bits (8*16)
    // so each summand < 152 bits and res < 155 bits
    uint256 xLowestDegree = x;
    res = gHighestDegree; // g**8

    gHighestDegree /= g; // g**7
    res += xLowestDegree * gHighestDegree;

    gHighestDegree /= g; // g**6
    xLowestDegree *= x; // x**2
    res += (xLowestDegree * gHighestDegree) / 2;

    gHighestDegree /= g; // g**5
    xLowestDegree *= x; // x**3
    res += (xLowestDegree * gHighestDegree) / 6;

    gHighestDegree /= g; // g**4
    xLowestDegree *= x; // x**4
    res += (xLowestDegree * gHighestDegree) / 24;

    gHighestDegree /= g; // g**3
    xLowestDegree *= x; // x**5
    res += (xLowestDegree * gHighestDegree) / 120;

    gHighestDegree /= g; // g**2
    xLowestDegree *= x; // x**6
    res += (xLowestDegree * gHighestDegree) / 720;

    xLowestDegree *= x; // x**7
    res += (xLowestDegree * g) / 5040 + (xLowestDegree * x) / (40320);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IAlgebraFactory.sol';
import './interfaces/IDataStorageOperator.sol';

import './libraries/DataStorage.sol';
import './libraries/Sqrt.sol';
import './libraries/AdaptiveFee.sol';

import './libraries/Constants.sol';

contract DataStorageOperator is IDataStorageOperator {
  uint256 constant UINT16_MODULO = 65536;
  uint128 constant MAX_VOLUME_PER_LIQUIDITY = 100000 << 64; // maximum meaningful ratio of volume to liquidity

  using DataStorage for DataStorage.Timepoint[UINT16_MODULO];

  DataStorage.Timepoint[UINT16_MODULO] public override timepoints;
  AdaptiveFee.Configuration public feeConfig;

  address private immutable pool;
  address private immutable factory;

  modifier onlyPool() {
    require(msg.sender == pool, 'only pool can call this');
    _;
  }

  constructor(address _pool) {
    factory = msg.sender;
    pool = _pool;
  }

  /// @inheritdoc IDataStorageOperator
  function initialize(uint32 time, int24 tick) external override onlyPool {
    return timepoints.initialize(time, tick);
  }

  /// @inheritdoc IDataStorageOperator
  function changeFeeConfiguration(AdaptiveFee.Configuration calldata _feeConfig) external override {
    require(msg.sender == factory || msg.sender == IAlgebraFactory(factory).owner());

    require(uint256(_feeConfig.alpha1) + uint256(_feeConfig.alpha2) + uint256(_feeConfig.baseFee) <= type(uint16).max, 'Max fee exceeded');
    require(_feeConfig.gamma1 != 0 && _feeConfig.gamma2 != 0 && _feeConfig.volumeGamma != 0, 'Gammas must be > 0');

    feeConfig = _feeConfig;
    emit FeeConfiguration(_feeConfig);
  }

  /// @inheritdoc IDataStorageOperator
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    override
    onlyPool
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    )
  {
    uint16 oldestIndex;
    // check if we have overflow in the past
    uint16 nextIndex = index + 1; // considering overflow
    if (timepoints[nextIndex].initialized) {
      oldestIndex = nextIndex;
    }

    DataStorage.Timepoint memory result = timepoints.getSingleTimepoint(time, secondsAgo, tick, index, oldestIndex, liquidity);
    (tickCumulative, secondsPerLiquidityCumulative, volatilityCumulative, volumePerAvgLiquidity) = (
      result.tickCumulative,
      result.secondsPerLiquidityCumulative,
      result.volatilityCumulative,
      result.volumePerLiquidityCumulative
    );
  }

  /// @inheritdoc IDataStorageOperator
  function getTimepoints(
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    override
    onlyPool
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    )
  {
    return timepoints.getTimepoints(time, secondsAgos, tick, index, liquidity);
  }

  /// @inheritdoc IDataStorageOperator
  function getAverages(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view override onlyPool returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) {
    return timepoints.getAverages(time, tick, index, liquidity);
  }

  /// @inheritdoc IDataStorageOperator
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) external override onlyPool returns (uint16 indexUpdated) {
    return timepoints.write(index, blockTimestamp, tick, liquidity, volumePerLiquidity);
  }

  /// @inheritdoc IDataStorageOperator
  function calculateVolumePerLiquidity(
    uint128 liquidity,
    int256 amount0,
    int256 amount1
  ) external pure override returns (uint128 volumePerLiquidity) {
    uint256 volume = Sqrt.sqrtAbs(amount0) * Sqrt.sqrtAbs(amount1);
    uint256 volumeShifted;
    if (volume >= 2**192) volumeShifted = (type(uint256).max) / (liquidity > 0 ? liquidity : 1);
    else volumeShifted = (volume << 64) / (liquidity > 0 ? liquidity : 1);
    if (volumeShifted >= MAX_VOLUME_PER_LIQUIDITY) return MAX_VOLUME_PER_LIQUIDITY;
    else return uint128(volumeShifted);
  }

  /// @inheritdoc IDataStorageOperator
  function window() external pure override returns (uint32) {
    return DataStorage.WINDOW;
  }

  /// @inheritdoc IDataStorageOperator
  function getFee(
    uint32 _time,
    int24 _tick,
    uint16 _index,
    uint128 _liquidity
  ) external view override onlyPool returns (uint16 fee) {
    (uint88 volatilityAverage, uint256 volumePerLiqAverage) = timepoints.getAverages(_time, _tick, _index, _liquidity);

    return AdaptiveFee.getFee(volatilityAverage / 15, volumePerLiqAverage, feeConfig);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q96 = 0x1000000000000000000000000;
  uint256 internal constant Q128 = 0x100000000000000000000000000000000;
  // fee value in hundredths of a bip, i.e. 1e-6
  uint16 internal constant BASE_FEE = 100;
  int24 internal constant TICK_SPACING = 60;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) / TICK_SPACING )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 11505743598341114571880798222544994;

  uint32 internal constant MAX_LIQUIDITY_COOLDOWN = 1 days;
  uint8 internal constant MAX_COMMUNITY_FEE = 250;
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './FullMath.sol';

/// @title DataStorage
/// @notice Provides price, liquidity, volatility data useful for a wide variety of system designs
/// @dev Instances of stored dataStorage data, "timepoints", are collected in the dataStorage array
/// Timepoints are overwritten when the full length of the dataStorage array is populated.
/// The most recent timepoint is available by passing 0 to getSingleTimepoint()
library DataStorage {
  uint32 public constant WINDOW = 1 days;
  uint256 private constant UINT16_MODULO = 65536;
  struct Timepoint {
    bool initialized; // whether or not the timepoint is initialized
    uint32 blockTimestamp; // the block timestamp of the timepoint
    int56 tickCumulative; // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
    uint160 secondsPerLiquidityCumulative; // the seconds per liquidity since the pool was first initialized
    uint88 volatilityCumulative; // the volatility accumulator; overflow after ~34800 years is desired :)
    int24 averageTick; // average tick at this blockTimestamp
    uint144 volumePerLiquidityCumulative; // the gmean(volumes)/liquidity accumulator
  }

  /// @notice Calculates volatility between two sequential timepoints with resampling to 1 sec frequency
  /// @param dt Timedelta between timepoints, must be within uint32 range
  /// @param tick0 The tick at the left timepoint, must be within int24 range
  /// @param tick1 The tick at the right timepoint, must be within int24 range
  /// @param avgTick0 The average tick at the left timepoint, must be within int24 range
  /// @param avgTick1 The average tick at the right timepoint, must be within int24 range
  /// @return volatility The volatility between two sequential timepoints
  /// If the requirements for the parameters are met, it always fits 88 bits
  function _volatilityOnRange(
    int256 dt,
    int256 tick0,
    int256 tick1,
    int256 avgTick0,
    int256 avgTick1
  ) internal pure returns (uint256 volatility) {
    // On the time interval from the previous timepoint to the current
    // we can represent tick and average tick change as two straight lines:
    // tick = k*t + b, where k and b are some constants
    // avgTick = p*t + q, where p and q are some constants
    // we want to get sum of (tick(t) - avgTick(t))^2 for every t in the interval (0; dt]
    // so: (tick(t) - avgTick(t))^2 = ((k*t + b) - (p*t + q))^2 = (k-p)^2 * t^2 + 2(k-p)(b-q)t + (b-q)^2
    // since everything except t is a constant, we need to use progressions for t and t^2:
    // sum(t) for t from 1 to dt = dt*(dt + 1)/2 = sumOfSequence
    // sum(t^2) for t from 1 to dt = dt*(dt+1)*(2dt + 1)/6 = sumOfSquares
    // so result will be: (k-p)^2 * sumOfSquares + 2(k-p)(b-q)*sumOfSequence + dt*(b-q)^2
    int256 K = (tick1 - tick0) - (avgTick1 - avgTick0); // (k - p)*dt
    int256 B = (tick0 - avgTick0) * dt; // (b - q)*dt
    int256 sumOfSquares = (dt * (dt + 1) * (2 * dt + 1)); // sumOfSquares * 6
    int256 sumOfSequence = (dt * (dt + 1)); // sumOfSequence * 2
    volatility = uint256((K**2 * sumOfSquares + 6 * B * K * sumOfSequence + 6 * dt * B**2) / (6 * dt**2));
  }

  /// @notice Transforms a previous timepoint into a new timepoint, given the passage of time and the current tick and liquidity values
  /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
  /// @param last The specified timepoint to be used in creation of new timepoint
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param prevTick The active tick at the time of the last timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param averageTick The average tick at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return Timepoint The newly populated timepoint
  function createNewTimepoint(
    Timepoint memory last,
    uint32 blockTimestamp,
    int24 tick,
    int24 prevTick,
    uint128 liquidity,
    int24 averageTick,
    uint128 volumePerLiquidity
  ) private pure returns (Timepoint memory) {
    uint32 delta = blockTimestamp - last.blockTimestamp;

    last.initialized = true;
    last.blockTimestamp = blockTimestamp;
    last.tickCumulative += int56(tick) * delta;
    last.secondsPerLiquidityCumulative += ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)); // just timedelta if liquidity == 0
    last.volatilityCumulative += uint88(_volatilityOnRange(delta, prevTick, tick, last.averageTick, averageTick)); // always fits 88 bits
    last.averageTick = averageTick;
    last.volumePerLiquidityCumulative += volumePerLiquidity;

    return last;
  }

  /// @notice comparator for 32-bit timestamps
  /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to currentTime
  /// @param a A comparison timestamp from which to determine the relative position of `currentTime`
  /// @param b From which to determine the relative position of `currentTime`
  /// @param currentTime A timestamp truncated to 32 bits
  /// @return res Whether `a` is chronologically <= `b`
  function lteConsideringOverflow(
    uint32 a,
    uint32 b,
    uint32 currentTime
  ) private pure returns (bool res) {
    res = a > currentTime;
    if (res == b > currentTime) res = a <= b; // if both are on the same side
  }

  /// @dev guaranteed that the result is within the bounds of int24
  /// returns int256 for fuzzy tests
  function _getAverageTick(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick,
    uint16 index,
    uint16 oldestIndex,
    uint32 lastTimestamp,
    int56 lastTickCumulative
  ) internal view returns (int256 avgTick) {
    uint32 oldestTimestamp = self[oldestIndex].blockTimestamp;
    int56 oldestTickCumulative = self[oldestIndex].tickCumulative;

    if (lteConsideringOverflow(oldestTimestamp, time - WINDOW, time)) {
      if (lteConsideringOverflow(lastTimestamp, time - WINDOW, time)) {
        index -= 1; // considering underflow
        Timepoint storage startTimepoint = self[index];
        avgTick = startTimepoint.initialized
          ? (lastTickCumulative - startTimepoint.tickCumulative) / (lastTimestamp - startTimepoint.blockTimestamp)
          : tick;
      } else {
        Timepoint memory startOfWindow = getSingleTimepoint(self, time, WINDOW, tick, index, oldestIndex, 0);

        //    current-WINDOW  last   current
        // _________*____________*_______*_
        //           ||||||||||||
        avgTick = (lastTickCumulative - startOfWindow.tickCumulative) / (lastTimestamp - time + WINDOW);
      }
    } else {
      avgTick = (lastTimestamp == oldestTimestamp) ? tick : (lastTickCumulative - oldestTickCumulative) / (lastTimestamp - oldestTimestamp);
    }
  }

  /// @notice Fetches the timepoints beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
  /// The result may be the same timepoint, or adjacent timepoints.
  /// @dev The answer must be contained in the array, used when the target is located within the stored timepoint
  /// boundaries: older than the most recent timepoint and younger, or the same age as, the oldest timepoint
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param target The timestamp at which the reserved timepoint should be for
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @param oldestIndex The index of the oldest timepoint in the timepoints array
  /// @return beforeOrAt The timepoint recorded before, or at, the target
  /// @return atOrAfter The timepoint recorded at, or after, the target
  function binarySearch(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 target,
    uint16 lastIndex,
    uint16 oldestIndex
  ) private view returns (Timepoint storage beforeOrAt, Timepoint storage atOrAfter) {
    uint256 left = oldestIndex; // oldest timepoint
    uint256 right = lastIndex >= oldestIndex ? lastIndex : lastIndex + UINT16_MODULO; // newest timepoint considering one index overflow
    uint256 current = (left + right) >> 1; // "middle" point between the boundaries

    do {
      beforeOrAt = self[uint16(current)]; // checking the "middle" point between the boundaries
      (bool initializedBefore, uint32 timestampBefore) = (beforeOrAt.initialized, beforeOrAt.blockTimestamp);
      if (initializedBefore) {
        if (lteConsideringOverflow(timestampBefore, target, time)) {
          // is current point before or at `target`?
          atOrAfter = self[uint16(current + 1)]; // checking the next point after "middle"
          (bool initializedAfter, uint32 timestampAfter) = (atOrAfter.initialized, atOrAfter.blockTimestamp);
          if (initializedAfter) {
            if (lteConsideringOverflow(target, timestampAfter, time)) {
              // is the "next" point after or at `target`?
              return (beforeOrAt, atOrAfter); // the only fully correct way to finish
            }
            left = current + 1; // "next" point is before the `target`, so looking in the right half
          } else {
            // beforeOrAt is initialized and <= target, and next timepoint is uninitialized
            // should be impossible if initial boundaries and `target` are correct
            return (beforeOrAt, beforeOrAt);
          }
        } else {
          right = current - 1; // current point is after the `target`, so looking in the left half
        }
      } else {
        // we've landed on an uninitialized timepoint, keep searching higher
        // should be impossible if initial boundaries and `target` are correct
        left = current + 1;
      }
      current = (left + right) >> 1; // calculating the new "middle" point index after updating the bounds
    } while (true);

    atOrAfter = beforeOrAt; // code is unreachable, to suppress compiler warning
    assert(false);
  }

  /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param self The stored dataStorage array
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param oldestIndex The index of the oldest timepoint
  /// @param liquidity The current in-range pool liquidity
  /// @return targetTimepoint desired timepoint or it's approximation
  function getSingleTimepoint(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint16 oldestIndex,
    uint128 liquidity
  ) internal view returns (Timepoint memory targetTimepoint) {
    uint32 target = time - secondsAgo;

    // if target is newer than last timepoint
    if (secondsAgo == 0 || lteConsideringOverflow(self[index].blockTimestamp, target, time)) {
      Timepoint memory last = self[index];
      if (last.blockTimestamp == target) {
        return last;
      } else {
        // otherwise, we need to add new timepoint
        int24 avgTick = int24(_getAverageTick(self, time, tick, index, oldestIndex, last.blockTimestamp, last.tickCumulative));
        int24 prevTick = tick;
        {
          if (index != oldestIndex) {
            Timepoint memory prevLast;
            Timepoint storage _prevLast = self[index - 1]; // considering index underflow
            prevLast.blockTimestamp = _prevLast.blockTimestamp;
            prevLast.tickCumulative = _prevLast.tickCumulative;
            prevTick = int24((last.tickCumulative - prevLast.tickCumulative) / (last.blockTimestamp - prevLast.blockTimestamp));
          }
        }
        return createNewTimepoint(last, target, tick, prevTick, liquidity, avgTick, 0);
      }
    }

    require(lteConsideringOverflow(self[oldestIndex].blockTimestamp, target, time), 'OLD');
    (Timepoint memory beforeOrAt, Timepoint memory atOrAfter) = binarySearch(self, time, target, index, oldestIndex);

    if (target == atOrAfter.blockTimestamp) {
      return atOrAfter; // we're at the right boundary
    }

    if (target != beforeOrAt.blockTimestamp) {
      // we're in the middle
      uint32 timepointTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
      uint32 targetDelta = target - beforeOrAt.blockTimestamp;

      // For gas savings the resulting point is written to beforeAt
      beforeOrAt.tickCumulative += ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / timepointTimeDelta) * targetDelta;
      beforeOrAt.secondsPerLiquidityCumulative += uint160(
        (uint256(atOrAfter.secondsPerLiquidityCumulative - beforeOrAt.secondsPerLiquidityCumulative) * targetDelta) / timepointTimeDelta
      );
      beforeOrAt.volatilityCumulative += ((atOrAfter.volatilityCumulative - beforeOrAt.volatilityCumulative) / timepointTimeDelta) * targetDelta;
      beforeOrAt.volumePerLiquidityCumulative +=
        ((atOrAfter.volumePerLiquidityCumulative - beforeOrAt.volumePerLiquidityCumulative) / timepointTimeDelta) *
        targetDelta;
    }

    // we're at the left boundary or at the middle
    return beforeOrAt;
  }

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
  /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    internal
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    )
  {
    tickCumulatives = new int56[](secondsAgos.length);
    secondsPerLiquidityCumulatives = new uint160[](secondsAgos.length);
    volatilityCumulatives = new uint112[](secondsAgos.length);
    volumePerAvgLiquiditys = new uint256[](secondsAgos.length);

    uint16 oldestIndex;
    // check if we have overflow in the past
    uint16 nextIndex = index + 1; // considering overflow
    if (self[nextIndex].initialized) {
      oldestIndex = nextIndex;
    }

    Timepoint memory current;
    for (uint256 i = 0; i < secondsAgos.length; i++) {
      current = getSingleTimepoint(self, time, secondsAgos[i], tick, index, oldestIndex, liquidity);
      (tickCumulatives[i], secondsPerLiquidityCumulatives[i], volatilityCumulatives[i], volumePerAvgLiquiditys[i]) = (
        current.tickCumulative,
        current.secondsPerLiquidityCumulative,
        current.volatilityCumulative,
        current.volumePerLiquidityCumulative
      );
    }
  }

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return volatilityAverage The average volatility in the recent range
  /// @return volumePerLiqAverage The average volume per liquidity in the recent range
  function getAverages(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) internal view returns (uint88 volatilityAverage, uint256 volumePerLiqAverage) {
    uint16 oldestIndex;
    Timepoint storage oldest = self[0];
    uint16 nextIndex = index + 1; // considering overflow
    if (self[nextIndex].initialized) {
      oldest = self[nextIndex];
      oldestIndex = nextIndex;
    }

    Timepoint memory endOfWindow = getSingleTimepoint(self, time, 0, tick, index, oldestIndex, liquidity);

    uint32 oldestTimestamp = oldest.blockTimestamp;
    if (lteConsideringOverflow(oldestTimestamp, time - WINDOW, time)) {
      Timepoint memory startOfWindow = getSingleTimepoint(self, time, WINDOW, tick, index, oldestIndex, liquidity);
      return (
        (endOfWindow.volatilityCumulative - startOfWindow.volatilityCumulative) / WINDOW,
        uint256(endOfWindow.volumePerLiquidityCumulative - startOfWindow.volumePerLiquidityCumulative) >> 57
      );
    } else if (time != oldestTimestamp) {
      uint88 _oldestVolatilityCumulative = oldest.volatilityCumulative;
      uint144 _oldestVolumePerLiquidityCumulative = oldest.volumePerLiquidityCumulative;
      return (
        (endOfWindow.volatilityCumulative - _oldestVolatilityCumulative) / (time - oldestTimestamp),
        uint256(endOfWindow.volumePerLiquidityCumulative - _oldestVolumePerLiquidityCumulative) >> 57
      );
    }
  }

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param self The stored dataStorage array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick
  ) internal {
    require(!self[0].initialized);
    self[0].initialized = true;
    self[0].blockTimestamp = time;
    self[0].averageTick = tick;
  }

  /// @notice Writes an dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param self The stored dataStorage array
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  function write(
    Timepoint[UINT16_MODULO] storage self,
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) internal returns (uint16 indexUpdated) {
    Timepoint storage _last = self[index];
    // early return if we've already written an timepoint this block
    if (_last.blockTimestamp == blockTimestamp) {
      return index;
    }
    Timepoint memory last = _last;

    // get next index considering overflow
    indexUpdated = index + 1;

    uint16 oldestIndex;
    // check if we have overflow in the past
    if (self[indexUpdated].initialized) {
      oldestIndex = indexUpdated;
    }

    int24 avgTick = int24(_getAverageTick(self, blockTimestamp, tick, index, oldestIndex, last.blockTimestamp, last.tickCumulative));
    int24 prevTick = tick;
    if (index != oldestIndex) {
      Timepoint storage _prevLast = self[index - 1]; // considering index underflow
      uint32 _prevLastBlockTimestamp = _prevLast.blockTimestamp;
      int56 _prevLastTickCumulative = _prevLast.tickCumulative;
      prevTick = int24((last.tickCumulative - _prevLastTickCumulative) / (last.blockTimestamp - _prevLastBlockTimestamp));
    }

    self[indexUpdated] = createNewTimepoint(last, blockTimestamp, tick, prevTick, liquidity, avgTick, volumePerLiquidity);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0 || ^0.8.0;

library Sqrt {
  /// @notice Gets the square root of the absolute value of the parameter
  function sqrtAbs(int256 _x) internal pure returns (uint256 result) {
    // get abs value
    int256 mask = _x >> (256 - 1);
    uint256 x = uint256((_x ^ mask) - mask);
    if (x == 0) result = 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) {
        xx >>= 128;
        r <<= 64;
      }
      if (xx >= 0x10000000000000000) {
        xx >>= 64;
        r <<= 32;
      }
      if (xx >= 0x100000000) {
        xx >>= 32;
        r <<= 16;
      }
      if (xx >= 0x10000) {
        xx >>= 16;
        r <<= 8;
      }
      if (xx >= 0x100) {
        xx >>= 8;
        r <<= 4;
      }
      if (xx >= 0x10) {
        xx >>= 4;
        r <<= 2;
      }
      if (xx >= 0x8) {
        r <<= 1;
      }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // @dev Seven iterations should be enough.
      uint256 r1 = x / r;
      result = r < r1 ? r : r1;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.0 || ^0.5.0 || ^0.6.0 || ^0.7.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0 = a * b; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    // Subtract 256 bit remainder from 512 bit number
    assembly {
      let remainder := mulmod(a, b, denominator)
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    uint256 twos = -denominator & denominator;
    // Divide denominator by power of two
    assembly {
      denominator := div(denominator, twos)
    }

    // Divide [prod1 prod0] by the factors of two
    assembly {
      prod0 := div(prod0, twos)
    }
    // Shift in bits from prod1 into prod0. For this we need
    // to flip `twos` such that it is 2**256 / twos.
    // If twos is zero, then it becomes one
    assembly {
      twos := add(div(sub(0, twos), twos), 1)
    }
    prod0 |= prod1 * twos;

    // Invert denominator mod 2**256
    // Now that denominator is an odd number, it has an inverse
    // modulo 2**256 such that denominator * inv = 1 mod 2**256.
    // Compute the inverse by starting with a seed that is correct
    // correct for four bits. That is, denominator * inv = 1 mod 2**4
    uint256 inv = (3 * denominator) ^ 2;
    // Now use Newton-Raphson iteration to improve the precision.
    // Thanks to Hensel's lifting lemma, this also works in modular
    // arithmetic, doubling the correct bits in each step.
    inv *= 2 - denominator * inv; // inverse mod 2**8
    inv *= 2 - denominator * inv; // inverse mod 2**16
    inv *= 2 - denominator * inv; // inverse mod 2**32
    inv *= 2 - denominator * inv; // inverse mod 2**64
    inv *= 2 - denominator * inv; // inverse mod 2**128
    inv *= 2 - denominator * inv; // inverse mod 2**256

    // Because the division is now exact we can divide by multiplying
    // with the modular inverse of denominator. This will give us the
    // correct result modulo 2**256. Since the preconditions guarantee
    // that the outcome is less than 2**256, this is the final result.
    // We don't need to compute the high bits of the result and prod1
    // is no longer required.
    result = prod0 * inv;
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    if (a == 0 || ((result = a * b) / a == b)) {
      require(denominator > 0);
      assembly {
        result := add(div(result, denominator), gt(mod(result, denominator), 0))
      }
    } else {
      result = mulDiv(a, b, denominator);
      if (mulmod(a, b, denominator) > 0) {
        require(result < type(uint256).max);
        result++;
      }
    }
  }

  /// @notice Returns ceil(x / y)
  /// @dev division by 0 has unspecified behavior, and must be checked externally
  /// @param x The dividend
  /// @param y The divisor
  /// @return z The quotient, ceil(x / y)
  function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := add(div(x, y), gt(mod(x, y), 0))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma abicoder v2;

import '../../interfaces/IAlgebraFactory.sol';
import '../../interfaces/IAlgebraPoolDeployer.sol';
import '../../interfaces/IDataStorageOperator.sol';
import '../../libraries/AdaptiveFee.sol';
import '../../DataStorageOperator.sol';

/**
 * @title Algebra factory for simulation
 * @notice Is used to deploy pools and its dataStorages
 */
contract SimulationTimeFactory is IAlgebraFactory {
  /// @inheritdoc IAlgebraFactory
  address public override owner;

  /// @inheritdoc IAlgebraFactory
  address public immutable override poolDeployer;

  /// @inheritdoc IAlgebraFactory
  address public override farmingAddress;

  /// @inheritdoc IAlgebraFactory
  address public override vaultAddress;

  // values of constants for sigmoids in fee calculation formula
  AdaptiveFee.Configuration public baseFeeConfiguration =
    AdaptiveFee.Configuration(
      3000 - Constants.BASE_FEE, // alpha1
      15000 - 3000, // alpha2
      360, // beta1
      60000, // beta2
      59, // gamma1
      8500, // gamma2
      0, // volumeBeta
      10, // volumeGamma
      Constants.BASE_FEE // baseFee
    );

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /// @inheritdoc IAlgebraFactory
  mapping(address => mapping(address => address)) public override poolByPair;

  constructor(address _poolDeployer, address _vaultAddress) {
    owner = msg.sender;
    emit Owner(msg.sender);

    poolDeployer = _poolDeployer;
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function createPool(address tokenA, address tokenB) external override returns (address pool) {
    require(tokenA != tokenB);
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0));
    require(poolByPair[token0][token1] == address(0));

    IDataStorageOperator dataStorage = new DataStorageOperator(computeAddress(token0, token1));

    dataStorage.changeFeeConfiguration(baseFeeConfiguration);

    pool = IAlgebraPoolDeployer(poolDeployer).deploy(address(dataStorage), address(this), token0, token1);

    poolByPair[token0][token1] = pool; // to avoid future addresses comparing we are populating the mapping twice
    poolByPair[token1][token0] = pool;
    emit Pool(token0, token1, pool);
  }

  /// @inheritdoc IAlgebraFactory
  function setOwner(address _owner) external override onlyOwner {
    require(owner != _owner);
    emit Owner(_owner);
    owner = _owner;
  }

  /// @inheritdoc IAlgebraFactory
  function setFarmingAddress(address _farmingAddress) external override onlyOwner {
    require(farmingAddress != _farmingAddress);
    emit FarmingAddress(_farmingAddress);
    farmingAddress = _farmingAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function setVaultAddress(address _vaultAddress) external override onlyOwner {
    require(vaultAddress != _vaultAddress);
    emit VaultAddress(_vaultAddress);
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAlgebraFactory
  function setBaseFeeConfiguration(
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 gamma1,
    uint16 gamma2,
    uint32 volumeBeta,
    uint16 volumeGamma,
    uint16 baseFee
  ) external override onlyOwner {
    require(uint256(alpha1) + uint256(alpha2) + uint256(baseFee) <= type(uint16).max, 'Max fee exceeded');
    require(gamma1 != 0 && gamma2 != 0 && volumeGamma != 0, 'Gammas must be > 0');

    baseFeeConfiguration = AdaptiveFee.Configuration(alpha1, alpha2, beta1, beta2, gamma1, gamma2, volumeBeta, volumeGamma, baseFee);
    emit FeeConfiguration(alpha1, alpha2, beta1, beta2, gamma1, gamma2, volumeBeta, volumeGamma, baseFee);
  }

  bytes32 internal constant POOL_INIT_CODE_HASH = 0x900bf8d45a06958144a51da8749d15e2a339e87243bd50bc88d46815c9ec888d;

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param token0 first token
  /// @param token1 second token
  /// @return pool The contract address of the Algebra pool
  function computeAddress(address token0, address token1) internal view returns (address pool) {
    pool = address(uint256(keccak256(abi.encodePacked(hex'ff', poolDeployer, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH))));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/AdaptiveFee.sol';
import '../libraries/Constants.sol';

contract AdaptiveFeeTest {
  AdaptiveFee.Configuration public feeConfig =
    AdaptiveFee.Configuration(
      3000 - Constants.BASE_FEE, // alpha1
      15000 - 3000, // alpha2
      360, // beta1
      60000, // beta2
      59, // gamma1
      8500, // gamma2
      0, // volumeBeta
      10, // volumeGamma
      Constants.BASE_FEE // baseFee
    );

  function getFee(uint88 volatility, uint256 volumePerLiquidity) external view returns (uint256 fee) {
    return AdaptiveFee.getFee(volatility, volumePerLiquidity, feeConfig);
  }

  function getGasCostOfGetFee(uint88 volatility, uint256 volumePerLiquidity) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    AdaptiveFee.getFee(volatility, volumePerLiquidity, feeConfig);
    return gasBefore - gasleft();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/FullMath.sol';
import '../libraries/TokenDeltaMath.sol';
import '../libraries/PriceMovementMath.sol';
import '../libraries/Constants.sol';

contract TokenDeltaMathEchidnaTest {
  function mulDivRoundingUpInvariants(
    uint256 x,
    uint256 y,
    uint256 z
  ) external pure {
    require(z > 0);
    uint256 notRoundedUp = FullMath.mulDiv(x, y, z);
    uint256 roundedUp = FullMath.mulDivRoundingUp(x, y, z);
    assert(roundedUp >= notRoundedUp);
    assert(roundedUp - notRoundedUp < 2);
    if (roundedUp - notRoundedUp == 1) {
      assert(mulmod(x, y, z) > 0);
    } else {
      assert(mulmod(x, y, z) == 0);
    }
  }

  function getNextSqrtPriceFromInputInvariants(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountIn,
    bool zeroToOne
  ) external pure {
    uint160 sqrtQ = PriceMovementMath.getNewPriceAfterInput(sqrtP, liquidity, amountIn, zeroToOne);

    if (zeroToOne) {
      assert(sqrtQ <= sqrtP);
      assert(amountIn >= TokenDeltaMath.getToken0Delta(sqrtQ, sqrtP, liquidity, true));
    } else {
      assert(sqrtQ >= sqrtP);
      assert(amountIn >= TokenDeltaMath.getToken1Delta(sqrtP, sqrtQ, liquidity, true));
    }
  }

  function getNextSqrtPriceFromOutputInvariants(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountOut,
    bool zeroToOne
  ) external pure {
    uint160 sqrtQ = PriceMovementMath.getNewPriceAfterOutput(sqrtP, liquidity, amountOut, zeroToOne);

    if (zeroToOne) {
      assert(sqrtQ <= sqrtP);
      assert(amountOut <= TokenDeltaMath.getToken1Delta(sqrtQ, sqrtP, liquidity, false));
    } else {
      assert(sqrtQ > 0); // this has to be true, otherwise we need another require
      assert(sqrtQ >= sqrtP);
      assert(amountOut <= TokenDeltaMath.getToken0Delta(sqrtP, sqrtQ, liquidity, false));
    }
  }

  function getNextSqrtPriceFromAmount0RoundingUpInvariants(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) external pure {
    require(sqrtPX96 > 0);
    require(liquidity > 0);

    uint160 sqrtQX96;

    if (add) {
      sqrtQX96 = PriceMovementMath.getNewPriceAfterInput(sqrtPX96, liquidity, amount, true);
    } else {
      sqrtQX96 = PriceMovementMath.getNewPriceAfterOutput(sqrtPX96, liquidity, amount, false);
    }

    if (add) {
      assert(sqrtQX96 <= sqrtPX96);
    } else {
      assert(sqrtQX96 >= sqrtPX96);
    }

    if (amount == 0) {
      assert(sqrtPX96 == sqrtQX96);
    }
  }

  function getNextSqrtPriceFromAmount1RoundingDownInvariants(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) external pure {
    require(sqrtPX96 > 0);
    require(liquidity > 0);
    uint160 sqrtQX96;

    if (add) {
      sqrtQX96 = PriceMovementMath.getNewPriceAfterInput(sqrtPX96, liquidity, amount, false);
    } else {
      sqrtQX96 = PriceMovementMath.getNewPriceAfterOutput(sqrtPX96, liquidity, amount, true);
    }

    if (add) {
      assert(sqrtQX96 >= sqrtPX96);
    } else {
      assert(sqrtQX96 <= sqrtPX96);
    }

    if (amount == 0) {
      assert(sqrtPX96 == sqrtQX96);
    }
  }

  function getToken0DeltaInvariants(
    uint160 sqrtP,
    uint160 sqrtQ,
    uint128 liquidity
  ) external pure {
    require(sqrtP > 0 && sqrtQ > 0);
    if (sqrtP < sqrtQ) (sqrtP, sqrtQ) = (sqrtQ, sqrtP);
    uint256 amount0Down = TokenDeltaMath.getToken0Delta(sqrtQ, sqrtP, liquidity, false);

    uint256 amount0Up = TokenDeltaMath.getToken0Delta(sqrtQ, sqrtP, liquidity, true);

    assert(amount0Down <= amount0Up);
    // diff is 0 or 1
    assert(amount0Up - amount0Down < 2);
  }

  // ensure that chained division is always equal to the full-precision case for
  // liquidity * (sqrt(P) - sqrt(Q)) / (sqrt(P) * sqrt(Q))
  function getToken0DeltaEquivalency(
    uint160 sqrtP,
    uint160 sqrtQ,
    uint128 liquidity,
    bool roundUp
  ) external pure {
    require(sqrtP >= sqrtQ);
    require(sqrtP > 0 && sqrtQ > 0);
    require((sqrtP * sqrtQ) / sqrtP == sqrtQ);

    uint256 numerator1 = uint256(liquidity) << Constants.RESOLUTION;
    uint256 numerator2 = sqrtP - sqrtQ;
    uint256 denominator = uint256(sqrtP) * sqrtQ;

    uint256 safeResult = roundUp
      ? FullMath.mulDivRoundingUp(numerator1, numerator2, denominator)
      : FullMath.mulDiv(numerator1, numerator2, denominator);
    uint256 fullResult = TokenDeltaMath.getToken0Delta(sqrtQ, sqrtP, liquidity, roundUp);

    assert(safeResult == fullResult);
  }

  function getToken1DeltaInvariants(
    uint160 sqrtP,
    uint160 sqrtQ,
    uint128 liquidity
  ) external pure {
    require(sqrtP > 0 && sqrtQ > 0);
    if (sqrtP > sqrtQ) (sqrtP, sqrtQ) = (sqrtQ, sqrtP);

    uint256 amount1Down = TokenDeltaMath.getToken1Delta(sqrtP, sqrtQ, liquidity, false);

    uint256 amount1Up = TokenDeltaMath.getToken1Delta(sqrtP, sqrtQ, liquidity, true);

    assert(amount1Down <= amount1Up);
    // diff is 0 or 1
    assert(amount1Up - amount1Down < 2);
  }

  function getToken0DeltaSignedInvariants(
    uint160 sqrtP,
    uint160 sqrtQ,
    int128 liquidity
  ) external pure {
    require(sqrtP > 0 && sqrtQ > 0);

    int256 amount0 = TokenDeltaMath.getToken0Delta(sqrtQ, sqrtP, liquidity);
    if (liquidity < 0) assert(amount0 <= 0);
    if (liquidity > 0) {
      if (sqrtP == sqrtQ) assert(amount0 == 0);
      else assert(amount0 > 0);
    }
    if (liquidity == 0) assert(amount0 == 0);
  }

  function getToken1DeltaSignedInvariants(
    uint160 sqrtP,
    uint160 sqrtQ,
    int128 liquidity
  ) external pure {
    require(sqrtP > 0 && sqrtQ > 0);

    int256 amount1 = TokenDeltaMath.getToken1Delta(sqrtP, sqrtQ, liquidity);
    if (liquidity < 0) assert(amount1 <= 0);
    if (liquidity > 0) {
      if (sqrtP == sqrtQ) assert(amount1 == 0);
      else assert(amount1 > 0);
    }
    if (liquidity == 0) assert(amount1 == 0);
  }

  function getOutOfRangeMintInvariants(
    uint160 sqrtA,
    uint160 sqrtB,
    int128 liquidity
  ) external pure {
    require(sqrtA > 0 && sqrtB > 0);
    require(liquidity > 0);

    int256 amount0 = TokenDeltaMath.getToken0Delta(sqrtA, sqrtB, liquidity);
    int256 amount1 = TokenDeltaMath.getToken1Delta(sqrtA, sqrtB, liquidity);

    if (sqrtA == sqrtB) {
      assert(amount0 == 0);
      assert(amount1 == 0);
    } else {
      assert(amount0 > 0);
      assert(amount1 > 0);
    }
  }

  function getInRangeMintInvariants(
    uint160 sqrtLower,
    uint160 sqrtCurrent,
    uint160 sqrtUpper,
    int128 liquidity
  ) external pure {
    require(sqrtLower > 0);
    require(sqrtLower < sqrtUpper);
    require(sqrtLower <= sqrtCurrent && sqrtCurrent <= sqrtUpper);
    require(liquidity > 0);

    int256 amount0 = TokenDeltaMath.getToken0Delta(sqrtCurrent, sqrtUpper, liquidity);
    int256 amount1 = TokenDeltaMath.getToken1Delta(sqrtLower, sqrtCurrent, liquidity);

    assert(amount0 > 0 || amount1 > 0);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './Constants.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library TokenDeltaMath {
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;

  /// @notice Gets the token0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper)
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up or down
  /// @return token0Delta Amount of token0 required to cover a position of size liquidity between the two passed prices
  function getToken0Delta(
    uint160 priceLower,
    uint160 priceUpper,
    uint128 liquidity,
    bool roundUp
  ) internal pure returns (uint256 token0Delta) {
    uint256 priceDelta = priceUpper - priceLower;
    require(priceDelta < priceUpper); // forbids underflow and 0 priceLower
    uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

    token0Delta = roundUp
      ? FullMath.divRoundingUp(FullMath.mulDivRoundingUp(priceDelta, liquidityShifted, priceUpper), priceLower)
      : FullMath.mulDiv(priceDelta, liquidityShifted, priceUpper) / priceLower;
  }

  /// @notice Gets the token1 delta between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up, or down
  /// @return token1Delta Amount of token1 required to cover a position of size liquidity between the two passed prices
  function getToken1Delta(
    uint160 priceLower,
    uint160 priceUpper,
    uint128 liquidity,
    bool roundUp
  ) internal pure returns (uint256 token1Delta) {
    require(priceUpper >= priceLower);
    uint256 priceDelta = priceUpper - priceLower;
    token1Delta = roundUp ? FullMath.mulDivRoundingUp(priceDelta, liquidity, Constants.Q96) : FullMath.mulDiv(priceDelta, liquidity, Constants.Q96);
  }

  /// @notice Helper that gets signed token0 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token0 delta
  /// @return token0Delta Amount of token0 corresponding to the passed liquidityDelta between the two prices
  function getToken0Delta(
    uint160 priceLower,
    uint160 priceUpper,
    int128 liquidity
  ) internal pure returns (int256 token0Delta) {
    token0Delta = liquidity >= 0
      ? getToken0Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
      : -getToken0Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
  }

  /// @notice Helper that gets signed token1 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token1 delta
  /// @return token1Delta Amount of token1 corresponding to the passed liquidityDelta between the two prices
  function getToken1Delta(
    uint160 priceLower,
    uint160 priceUpper,
    int128 liquidity
  ) internal pure returns (int256 token1Delta) {
    token1Delta = liquidity >= 0
      ? getToken1Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
      : -getToken1Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './FullMath.sol';
import './TokenDeltaMath.sol';

/// @title Computes the result of price movement
/// @notice Contains methods for computing the result of price movement within a single tick price range.
library PriceMovementMath {
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;

  /// @notice Gets the next sqrt price given an input amount of token0 or token1
  /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
  /// @param price The starting Q64.96 sqrt price, i.e., before accounting for the input amount
  /// @param liquidity The amount of usable liquidity
  /// @param input How much of token0, or token1, is being swapped in
  /// @param zeroToOne Whether the amount in is token0 or token1
  /// @return resultPrice The Q64.96 sqrt price after adding the input amount to token0 or token1
  function getNewPriceAfterInput(
    uint160 price,
    uint128 liquidity,
    uint256 input,
    bool zeroToOne
  ) internal pure returns (uint160 resultPrice) {
    return getNewPrice(price, liquidity, input, zeroToOne, true);
  }

  /// @notice Gets the next sqrt price given an output amount of token0 or token1
  /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
  /// @param price The starting Q64.96 sqrt price before accounting for the output amount
  /// @param liquidity The amount of usable liquidity
  /// @param output How much of token0, or token1, is being swapped out
  /// @param zeroToOne Whether the amount out is token0 or token1
  /// @return resultPrice The Q64.96 sqrt price after removing the output amount of token0 or token1
  function getNewPriceAfterOutput(
    uint160 price,
    uint128 liquidity,
    uint256 output,
    bool zeroToOne
  ) internal pure returns (uint160 resultPrice) {
    return getNewPrice(price, liquidity, output, zeroToOne, false);
  }

  function getNewPrice(
    uint160 price,
    uint128 liquidity,
    uint256 amount,
    bool zeroToOne,
    bool fromInput
  ) internal pure returns (uint160 resultPrice) {
    require(price > 0);
    require(liquidity > 0);

    if (zeroToOne == fromInput) {
      // rounding up or down
      if (amount == 0) return price;
      uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

      if (fromInput) {
        uint256 product;
        if ((product = amount * price) / amount == price) {
          uint256 denominator = liquidityShifted + product;
          if (denominator >= liquidityShifted) return uint160(FullMath.mulDivRoundingUp(liquidityShifted, price, denominator)); // always fits in 160 bits
        }

        return uint160(FullMath.divRoundingUp(liquidityShifted, (liquidityShifted / price).add(amount)));
      } else {
        uint256 product;
        require((product = amount * price) / amount == price); // if the product overflows, we know the denominator underflows
        require(liquidityShifted > product); // in addition, we must check that the denominator does not underflow
        return FullMath.mulDivRoundingUp(liquidityShifted, price, liquidityShifted - product).toUint160();
      }
    } else {
      // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
      // in both cases, avoid a mulDiv for most inputs
      if (fromInput) {
        return
          uint256(price)
            .add(amount <= type(uint160).max ? (amount << Constants.RESOLUTION) / liquidity : FullMath.mulDiv(amount, Constants.Q96, liquidity))
            .toUint160();
      } else {
        uint256 quotient = amount <= type(uint160).max
          ? FullMath.divRoundingUp(amount << Constants.RESOLUTION, liquidity)
          : FullMath.mulDivRoundingUp(amount, Constants.Q96, liquidity);

        require(price > quotient);
        return uint160(price - quotient); // always fits 160 bits
      }
    }
  }

  function getTokenADelta01(
    uint160 to,
    uint160 from,
    uint128 liquidity
  ) internal pure returns (uint256) {
    return TokenDeltaMath.getToken0Delta(to, from, liquidity, true);
  }

  function getTokenADelta10(
    uint160 to,
    uint160 from,
    uint128 liquidity
  ) internal pure returns (uint256) {
    return TokenDeltaMath.getToken1Delta(from, to, liquidity, true);
  }

  function getTokenBDelta01(
    uint160 to,
    uint160 from,
    uint128 liquidity
  ) internal pure returns (uint256) {
    return TokenDeltaMath.getToken1Delta(to, from, liquidity, false);
  }

  function getTokenBDelta10(
    uint160 to,
    uint160 from,
    uint128 liquidity
  ) internal pure returns (uint256) {
    return TokenDeltaMath.getToken0Delta(from, to, liquidity, false);
  }

  /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
  /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
  /// @param currentPrice The current Q64.96 sqrt price of the pool
  /// @param targetPrice The Q64.96 sqrt price that cannot be exceeded, from which the direction of the swap is inferred
  /// @param liquidity The usable liquidity
  /// @param amountAvailable How much input or output amount is remaining to be swapped in/out
  /// @param fee The fee taken from the input amount, expressed in hundredths of a bip
  /// @return resultPrice The Q64.96 sqrt price after swapping the amount in/out, not to exceed the price target
  /// @return input The amount to be swapped in, of either token0 or token1, based on the direction of the swap
  /// @return output The amount to be received, of either token0 or token1, based on the direction of the swap
  /// @return feeAmount The amount of input that will be taken as a fee
  function movePriceTowardsTarget(
    bool zeroToOne,
    uint160 currentPrice,
    uint160 targetPrice,
    uint128 liquidity,
    int256 amountAvailable,
    uint16 fee
  )
    internal
    pure
    returns (
      uint160 resultPrice,
      uint256 input,
      uint256 output,
      uint256 feeAmount
    )
  {
    function(uint160, uint160, uint128) pure returns (uint256) getAmountA = zeroToOne ? getTokenADelta01 : getTokenADelta10;

    if (amountAvailable >= 0) {
      // exactIn or not
      uint256 amountAvailableAfterFee = FullMath.mulDiv(uint256(amountAvailable), 1e6 - fee, 1e6);
      input = getAmountA(targetPrice, currentPrice, liquidity);
      if (amountAvailableAfterFee >= input) {
        resultPrice = targetPrice;
        feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
      } else {
        resultPrice = getNewPriceAfterInput(currentPrice, liquidity, amountAvailableAfterFee, zeroToOne);
        if (targetPrice != resultPrice) {
          input = getAmountA(resultPrice, currentPrice, liquidity);

          // we didn't reach the target, so take the remainder of the maximum input as fee
          feeAmount = uint256(amountAvailable) - input;
        } else {
          feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
        }
      }

      output = (zeroToOne ? getTokenBDelta01 : getTokenBDelta10)(resultPrice, currentPrice, liquidity);
    } else {
      function(uint160, uint160, uint128) pure returns (uint256) getAmountB = zeroToOne ? getTokenBDelta01 : getTokenBDelta10;

      output = getAmountB(targetPrice, currentPrice, liquidity);
      amountAvailable = -amountAvailable;
      if (uint256(amountAvailable) >= output) resultPrice = targetPrice;
      else {
        resultPrice = getNewPriceAfterOutput(currentPrice, liquidity, uint256(amountAvailable), zeroToOne);

        if (targetPrice != resultPrice) {
          output = getAmountB(resultPrice, currentPrice, liquidity);
        }

        // cap the output amount to not exceed the remaining output amount
        if (output > uint256(amountAvailable)) {
          output = uint256(amountAvailable);
        }
      }

      input = getAmountA(resultPrice, currentPrice, liquidity);
      feeAmount = FullMath.mulDivRoundingUp(input, fee, 1e6 - fee);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y);
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x + y) >= x == (y >= 0));
  }

  /// @notice Returns x - y, reverts if overflows or underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x - y) <= x == (y >= 0));
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add128(uint128 x, uint128 y) internal pure returns (uint128 z) {
    require((z = x + y) >= x);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TokenDeltaMath.sol';
import '../libraries/PriceMovementMath.sol';

contract TokenDeltaMathTest {
  function getNewPriceAfterInput(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountIn,
    bool zeroToOne
  ) external pure returns (uint160 sqrtQ) {
    return PriceMovementMath.getNewPriceAfterInput(sqrtP, liquidity, amountIn, zeroToOne);
  }

  function getGasCostOfGetNewPriceAfterInput(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountIn,
    bool zeroToOne
  ) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    PriceMovementMath.getNewPriceAfterInput(sqrtP, liquidity, amountIn, zeroToOne);
    return gasBefore - gasleft();
  }

  function getNewPriceAfterOutput(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountOut,
    bool zeroToOne
  ) external pure returns (uint160 sqrtQ) {
    return PriceMovementMath.getNewPriceAfterOutput(sqrtP, liquidity, amountOut, zeroToOne);
  }

  function getGasCostOfGetNewPriceAfterOutput(
    uint160 sqrtP,
    uint128 liquidity,
    uint256 amountOut,
    bool zeroToOne
  ) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    PriceMovementMath.getNewPriceAfterOutput(sqrtP, liquidity, amountOut, zeroToOne);
    return gasBefore - gasleft();
  }

  function getToken0Delta(
    uint160 sqrtLower,
    uint160 sqrtUpper,
    uint128 liquidity,
    bool roundUp
  ) external pure returns (uint256 amount0) {
    return TokenDeltaMath.getToken0Delta(sqrtLower, sqrtUpper, liquidity, roundUp);
  }

  function getToken1Delta(
    uint160 sqrtLower,
    uint160 sqrtUpper,
    uint128 liquidity,
    bool roundUp
  ) external pure returns (uint256 amount1) {
    return TokenDeltaMath.getToken1Delta(sqrtLower, sqrtUpper, liquidity, roundUp);
  }

  function getGasCostOfGetToken0Delta(
    uint160 sqrtLower,
    uint160 sqrtUpper,
    uint128 liquidity,
    bool roundUp
  ) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TokenDeltaMath.getToken0Delta(sqrtLower, sqrtUpper, liquidity, roundUp);
    return gasBefore - gasleft();
  }

  function getGasCostOfGetToken1Delta(
    uint160 sqrtLower,
    uint160 sqrtUpper,
    uint128 liquidity,
    bool roundUp
  ) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TokenDeltaMath.getToken1Delta(sqrtLower, sqrtUpper, liquidity, roundUp);
    return gasBefore - gasleft();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/FullMath.sol';

contract UnsafeMathEchidnaTest {
  function checkDivRoundingUp(uint256 x, uint256 d) external pure {
    require(d > 0);
    uint256 z = FullMath.divRoundingUp(x, d);
    uint256 diff = z - (x / d);
    if (x % d == 0) {
      assert(diff == 0);
    } else {
      assert(diff == 1);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../libraries/FullMath.sol';
import '../libraries/Constants.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
  /// @notice Downcasts uint256 to uint128
  /// @param x The uint258 to be downcasted
  /// @return y The passed value, downcasted to uint128
  function toUint128(uint256 x) private pure returns (uint128 y) {
    require((y = uint128(x)) == x);
  }

  /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
  /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount0 The amount0 being sent in
  /// @return liquidity The amount of returned liquidity
  function getLiquidityForAmount0(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, Constants.Q96);
    return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
  /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount1 The amount1 being sent in
  /// @return liquidity The amount of returned liquidity
  function getLiquidityForAmount1(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount1
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    return toUint128(FullMath.mulDiv(amount1, Constants.Q96, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
  /// pool prices and the prices at the tick boundaries
  /// @param sqrtRatioX96 A sqrt price representing the current pool prices
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param amount0 The amount of token0 being sent in
  /// @param amount1 The amount of token1 being sent in
  /// @return liquidity The maximum amount of liquidity received
  function getLiquidityForAmounts(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0,
    uint256 amount1
  ) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
      uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

      liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    } else {
      liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
    }
  }

  /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount of token0
  function getAmount0ForLiquidity(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount0) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    return FullMath.mulDiv(uint256(liquidity) << Constants.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96) / sqrtRatioAX96;
  }

  /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount1 The amount of token1
  function getAmount1ForLiquidity(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Constants.Q96);
  }

  /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
  /// pool prices and the prices at the tick boundaries
  /// @param sqrtRatioX96 A sqrt price representing the current pool prices
  /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
  /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount of token0
  /// @return amount1 The amount of token1
  function getAmountsForLiquidity(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity
  ) internal pure returns (uint256 amount0, uint256 amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
      amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
    } else {
      amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/IERC20Minimal.sol';

import '../libraries/SafeCast.sol';
import '../libraries/TickMath.sol';

import '../interfaces/callback/IAlgebraMintCallback.sol';
import '../interfaces/callback/IAlgebraSwapCallback.sol';
import '../interfaces/callback/IAlgebraFlashCallback.sol';

import '../interfaces/IAlgebraPool.sol';

import './LiquidityAmounts.sol';

contract TestAlgebraCallee is IAlgebraMintCallback, IAlgebraSwapCallback, IAlgebraFlashCallback {
  using SafeCast for uint256;

  function swapExact0For1(
    address pool,
    uint256 amount0In,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swap(recipient, true, amount0In.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swapExact0For1SupportingFee(
    address pool,
    uint256 amount0In,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swapSupportingFeeOnInputTokens(msg.sender, recipient, true, amount0In.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swap0ForExact1(
    address pool,
    uint256 amount1Out,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swap(recipient, true, -amount1Out.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swapExact1For0(
    address pool,
    uint256 amount1In,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swap(recipient, false, amount1In.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swapExact1For0SupportingFee(
    address pool,
    uint256 amount1In,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swapSupportingFeeOnInputTokens(msg.sender, recipient, false, amount1In.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swap1ForExact0(
    address pool,
    uint256 amount0Out,
    address recipient,
    uint160 limitSqrtPrice
  ) external {
    IAlgebraPool(pool).swap(recipient, false, -amount0Out.toInt256(), limitSqrtPrice, abi.encode(msg.sender));
  }

  function swapToLowerSqrtPrice(
    address pool,
    uint160 price,
    address recipient
  ) external {
    IAlgebraPool(pool).swap(recipient, true, type(int256).max, price, abi.encode(msg.sender));
  }

  function swapToHigherSqrtPrice(
    address pool,
    uint160 price,
    address recipient
  ) external {
    IAlgebraPool(pool).swap(recipient, false, type(int256).max, price, abi.encode(msg.sender));
  }

  event SwapCallback(int256 amount0Delta, int256 amount1Delta);

  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external override {
    address sender = abi.decode(data, (address));

    emit SwapCallback(amount0Delta, amount1Delta);

    if (amount0Delta > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, uint256(amount0Delta));
    } else if (amount1Delta > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, uint256(amount1Delta));
    } else {
      // if both are not gt 0, both must be 0.
      assert(amount0Delta == 0 && amount1Delta == 0);
    }
  }

  event MintResult(uint256 amount0Owed, uint256 amount1Owed, uint256 resultLiquidity);

  function mint(
    address pool,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  )
    external
    returns (
      uint256 amount0Owed,
      uint256 amount1Owed,
      uint256 resultLiquidity
    )
  {
    (amount0Owed, amount1Owed, resultLiquidity) = IAlgebraPool(pool).mint(msg.sender, recipient, bottomTick, topTick, amount, abi.encode(msg.sender));
    emit MintResult(amount0Owed, amount1Owed, resultLiquidity);
  }

  event MintCallback(uint256 amount0Owed, uint256 amount1Owed);

  function algebraMintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
  ) external override {
    address sender = abi.decode(data, (address));

    if (amount0Owed > 0) IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, amount0Owed);
    if (amount1Owed > 0) IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, amount1Owed);

    emit MintCallback(amount0Owed, amount1Owed);
  }

  event FlashCallback(uint256 fee0, uint256 fee1);

  function flash(
    address pool,
    address recipient,
    uint256 amount0,
    uint256 amount1,
    uint256 pay0,
    uint256 pay1
  ) external {
    IAlgebraPool(pool).flash(recipient, amount0, amount1, abi.encode(msg.sender, pay0, pay1));
  }

  function algebraFlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external override {
    emit FlashCallback(fee0, fee1);

    (address sender, uint256 pay0, uint256 pay1) = abi.decode(data, (address, uint256, uint256));

    if (pay0 > 0) IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, pay0);
    if (pay1 > 0) IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, pay1);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Algebra
/// @notice Contains a subset of the full ERC20 interface that is used in Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IERC20Minimal {
  /// @notice Returns the balance of a token
  /// @param account The account for which to look up the number of tokens it has, i.e. its balance
  /// @return The number of tokens held by the account
  function balanceOf(address account) external view returns (uint256);

  /// @notice Transfers the amount of token from the `msg.sender` to the recipient
  /// @param recipient The account that will receive the amount transferred
  /// @param amount The number of tokens to send from the sender to the recipient
  /// @return Returns true for a successful transfer, false for an unsuccessful transfer
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @notice Returns the current allowance given to a spender by an owner
  /// @param owner The account of the token owner
  /// @param spender The account of the token spender
  /// @return The current allowance granted by `owner` to `spender`
  function allowance(address owner, address spender) external view returns (uint256);

  /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
  /// @param spender The account which will be allowed to spend a given amount of the owners tokens
  /// @param amount The amount of tokens allowed to be used by `spender`
  /// @return Returns true for a successful approval, false for unsuccessful
  function approve(address spender, uint256 amount) external returns (bool);

  /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
  /// @param sender The account from which the transfer will be initiated
  /// @param recipient The recipient of the transfer
  /// @param amount The amount of the transfer
  /// @return Returns true for a successful transfer, false for unsuccessful
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
  /// @param from The account from which the tokens were sent, i.e. the balance decreased
  /// @param to The account to which the tokens were sent, i.e. the balance increased
  /// @param value The amount of tokens that were transferred
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
  /// @param owner The account that approved spending of its tokens
  /// @param spender The account for which the spending allowance was modified
  /// @param value The new allowance from the owner to the spender
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
    // get abs value
    int24 mask = tick >> (24 - 1);
    uint256 absTick = uint256((tick ^ mask) - mask);
    require(absTick <= uint256(MAX_TICK), 'T');

    uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = type(uint256).max / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    price = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param price The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(price >= MIN_SQRT_RATIO && price < MAX_SQRT_RATIO, 'R');
    uint256 ratio = uint256(price) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    assembly {
      let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(5, gt(r, 0xFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(4, gt(r, 0xFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(3, gt(r, 0xFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(2, gt(r, 0xF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(1, gt(r, 0x3))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := gt(r, 0x1)
      msb := or(msb, f)
    }

    if (msb >= 128) r = ratio >> (msb - 127);
    else r = ratio << (127 - msb);

    int256 log_2 = (int256(msb) - 128) << 64;

    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(63, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(62, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(61, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(60, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(59, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(58, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(57, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(56, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(55, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(54, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(53, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(52, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(51, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(50, f))
    }

    int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

    int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

    tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#mint
/// @notice Any contract that calls IAlgebraPoolActions#mint must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraMintCallback {
  /// @notice Called to `msg.sender` after minting liquidity to a position from IAlgebraPool#mint.
  /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
  /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
  /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#mint call
  function algebraMintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 *  @title Callback for IAlgebraPoolActions#flash
 *  @notice Any contract that calls IAlgebraPoolActions#flash must implement this interface
 *  @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 *  https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraFlashCallback {
  /**
   *  @notice Called to `msg.sender` after transferring to the recipient from IAlgebraPool#flash.
   *  @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
   *  The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
   *  @param fee0 The fee amount in token0 due to the pool by the end of the flash
   *  @param fee1 The fee amount in token1 due to the pool by the end of the flash
   *  @param data Any data passed through by the caller via the IAlgebraPoolActions#flash call
   */
  function algebraFlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../IDataStorageOperator.sol';

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /**
   * @notice The contract that stores all the timepoints and can perform actions with them
   * @return The operator address
   */
  function dataStorageOperator() external view returns (address);

  /**
   * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
   * @return The contract address
   */
  function factory() external view returns (address);

  /**
   * @notice The first of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token0() external view returns (address);

  /**
   * @notice The second of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token1() external view returns (address);

  /**
   * @notice The pool tick spacing
   * @dev Ticks can only be used at multiples of this value
   * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
   * This value is an int24 to avoid casting even though it is always positive.
   * @return The tick spacing
   */
  function tickSpacing() external view returns (int24);

  /**
   * @notice The maximum amount of position liquidity that can use any tick in the range
   * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
   * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
   * @return The max amount of liquidity per tick
   */
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /**
   * @notice The globalState structure in the pool stores many values but requires only one slot
   * and is exposed as a single method to save gas when accessed externally.
   * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
   * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
   * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
   * boundary;
   * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
   * Returns timepointIndex The index of the last written timepoint;
   * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
   * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
   * Returns unlocked Whether the pool is currently locked to reentrancy;
   */
  function globalState()
    external
    view
    returns (
      uint160 price,
      int24 tick,
      uint16 fee,
      uint16 timepointIndex,
      uint8 communityFeeToken0,
      uint8 communityFeeToken1,
      bool unlocked
    );

  /**
   * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth0Token() external view returns (uint256);

  /**
   * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth1Token() external view returns (uint256);

  /**
   * @notice The currently in range liquidity available to the pool
   * @dev This value has no relationship to the total liquidity across all ticks.
   * Returned value cannot exceed type(uint128).max
   */
  function liquidity() external view returns (uint128);

  /**
   * @notice Look up information about a specific tick in the pool
   * @dev This is a public structure, so the `return` natspec tags are omitted.
   * @param tick The tick to look up
   * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
   * tick upper;
   * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
   * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
   * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
   * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
   * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
   * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
   * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
   * otherwise equal to false. Outside values can only be used if the tick is initialized.
   * In addition, these values are only relative and must be used only in comparison to previous snapshots for
   * a specific position.
   */
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int56 outerTickCumulative,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool initialized
    );

  /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
  function tickTable(int16 wordPosition) external view returns (uint256);

  /**
   * @notice Returns the information about a position by the position's key
   * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
   * @return liquidityAmount The amount of liquidity in the position;
   * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
   * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
   * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
   * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
   * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
   */
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 liquidityAmount,
      uint32 lastLiquidityAddTimestamp,
      uint256 innerFeeGrowth0Token,
      uint256 innerFeeGrowth1Token,
      uint128 fees0,
      uint128 fees1
    );

  /**
   * @notice Returns data about a specific timepoint index
   * @param index The element of the timepoints array to fetch
   * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
   * ago, rather than at a specific index in the array.
   * This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @return initialized whether the timepoint has been initialized and the values are safe to use;
   * Returns blockTimestamp The timestamp of the timepoint;
   * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
   * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
   * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
   * Returns averageTick Time-weighted average tick;
   * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /**
   * @notice Returns the information about active incentive
   * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
   * @return virtualPool The address of a virtual pool associated with the current active incentive
   */
  function activeIncentive() external view returns (address virtualPool);

  /**
   * @notice Returns the lock time for added liquidity
   */
  function liquidityCooldown() external view returns (uint32 cooldownInSeconds);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDerivedState {
  /**
   * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
   * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
   * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
   * you must call it with secondsAgos = [3600, 0].
   * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
   * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
   * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
   * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
   * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
   * from the current block timestamp
   * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
   * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
   */
  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /**
   * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
   * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
   * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
   * snapshot is taken and the second snapshot is taken.
   * @param bottomTick The lower tick of the range
   * @param topTick The upper tick of the range
   * @return innerTickCumulative The snapshot of the tick accumulator for the range
   * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
   * @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
   */
  function getInnerCumulatives(int24 bottomTick, int24 topTick)
    external
    view
    returns (
      int56 innerTickCumulative,
      uint160 innerSecondsSpentPerLiquidity,
      uint32 innerSecondsSpent
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /**
   * @notice Sets the initial price for the pool
   * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
   * @param price the initial sqrt price of the pool as a Q64.96
   */
  function initialize(uint160 price) external;

  /**
   * @notice Adds liquidity for the given recipient/bottomTick/topTick position
   * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
   * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
   * on bottomTick, topTick, the amount of liquidity, and the current price.
   * @param sender The address which will receive potential surplus of paid tokens
   * @param recipient The address for which the liquidity will be created
   * @param bottomTick The lower tick of the position in which to add liquidity
   * @param topTick The upper tick of the position in which to add liquidity
   * @param amount The desired amount of liquidity to mint
   * @param data Any data that should be passed through to the callback
   * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return liquidityActual The actual minted amount of liquidity
   */
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    );

  /**
   * @notice Collects tokens owed to a position
   * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
   * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
   * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
   * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
   * @param recipient The address which should receive the fees collected
   * @param bottomTick The lower tick of the position for which to collect fees
   * @param topTick The upper tick of the position for which to collect fees
   * @param amount0Requested How much token0 should be withdrawn from the fees owed
   * @param amount1Requested How much token1 should be withdrawn from the fees owed
   * @return amount0 The amount of fees collected in token0
   * @return amount1 The amount of fees collected in token1
   */
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /**
   * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
   * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
   * @dev Fees must be collected separately via a call to #collect
   * @param bottomTick The lower tick of the position for which to burn liquidity
   * @param topTick The upper tick of the position for which to burn liquidity
   * @param amount How much liquidity to burn
   * @return amount0 The amount of token0 sent to the recipient
   * @return amount1 The amount of token1 sent to the recipient
   */
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0
   * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
   * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
   * @param sender The address called this function (Comes from the Router)
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or tokenomics
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolPermissionedActions {
  /**
   * @notice Set the community's % share of the fees. Cannot exceed 25% (250)
   * @param communityFee0 new community fee percent for token0 of the pool in thousandths (1e-3)
   * @param communityFee1 new community fee percent for token1 of the pool in thousandths (1e-3)
   */
  function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

  /**
   * @notice Sets an active incentive
   * @param virtualPoolAddress The address of a virtual pool associated with the incentive
   */
  function setIncentive(address virtualPoolAddress) external;

  /**
   * @notice Sets new lock time for added liquidity
   * @param newLiquidityCooldown The time in seconds
   */
  function setLiquidityCooldown(uint32 newLiquidityCooldown) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /**
   * @notice Emitted exactly once by a pool when #initialize is first called on the pool
   * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
   * @param price The initial sqrt price of the pool, as a Q64.96
   * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
   */
  event Initialize(uint160 price, int24 tick);

  /**
   * @notice Emitted when liquidity is minted for a given position
   * @param sender The address that minted the liquidity
   * @param owner The owner of the position and recipient of any minted liquidity
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity minted to the position range
   * @param amount0 How much token0 was required for the minted liquidity
   * @param amount1 How much token1 was required for the minted liquidity
   */
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /**
   * @notice Emitted when fees are collected by the owner of a position
   * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
   * @param owner The owner of the position for which fees are collected
   * @param recipient The address that received fees
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param amount0 The amount of token0 fees collected
   * @param amount1 The amount of token1 fees collected
   */
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /**
   * @notice Emitted when a position's liquidity is removed
   * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
   * @param owner The owner of the position for which liquidity is removed
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity to remove
   * @param amount0 The amount of token0 withdrawn
   * @param amount1 The amount of token1 withdrawn
   */
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /**
   * @notice Emitted by the pool for any swaps between token0 and token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the output of the swap
   * @param amount0 The delta of the token0 balance of the pool
   * @param amount1 The delta of the token1 balance of the pool
   * @param price The sqrt(price) of the pool after the swap, as a Q64.96
   * @param liquidity The liquidity of the pool after the swap
   * @param tick The log base 1.0001 of price of the pool after the swap
   */
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /**
   * @notice Emitted by the pool for any flashes of token0/token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the tokens from flash
   * @param amount0 The amount of token0 that was flashed
   * @param amount1 The amount of token1 that was flashed
   * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
   * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
   */
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /**
   * @notice Emitted when the community fee is changed by the pool
   * @param communityFee0New The updated value of the token0 community fee percent
   * @param communityFee1New The updated value of the token1 community fee percent
   */
  event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

  /**
   * @notice Emitted when new activeIncentive is set
   * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
   */
  event Incentive(address indexed virtualPoolAddress);

  /**
   * @notice Emitted when the fee changes
   * @param fee The value of the token fee
   */
  event Fee(uint16 fee);

  /**
   * @notice Emitted when the LiquidityCooldown changes
   * @param liquidityCooldown The value of locktime for added liquidity
   */
  event LiquidityCooldown(uint32 liquidityCooldown);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/IERC20Minimal.sol';

import '../interfaces/callback/IAlgebraSwapCallback.sol';
import '../interfaces/callback/IAlgebraMintCallback.sol';
import '../interfaces/IAlgebraPool.sol';

contract TestAlgebraSwapPay is IAlgebraSwapCallback, IAlgebraMintCallback {
  function swap(
    address pool,
    address recipient,
    bool zeroToOne,
    uint160 price,
    int256 amountSpecified,
    uint256 pay0,
    uint256 pay1
  ) external {
    IAlgebraPool(pool).swap(recipient, zeroToOne, amountSpecified, price, abi.encode(msg.sender, pay0, pay1));
  }

  function swapSupportingFee(
    address pool,
    address recipient,
    bool zeroToOne,
    uint160 price,
    int256 amountSpecified,
    uint256 pay0,
    uint256 pay1
  ) external {
    IAlgebraPool(pool).swapSupportingFeeOnInputTokens(msg.sender, recipient, zeroToOne, amountSpecified, price, abi.encode(msg.sender, pay0, pay1));
  }

  function algebraSwapCallback(
    int256,
    int256,
    bytes calldata data
  ) external override {
    (address sender, uint256 pay0, uint256 pay1) = abi.decode(data, (address, uint256, uint256));

    if (pay0 > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, uint256(pay0));
    } else if (pay1 > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, uint256(pay1));
    }
  }

  function mint(
    address pool,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    uint256 pay0,
    uint256 pay1
  )
    external
    returns (
      uint256 amount0Owed,
      uint256 amount1Owed,
      uint256 resultLiquidity
    )
  {
    (amount0Owed, amount1Owed, resultLiquidity) = IAlgebraPool(pool).mint(
      msg.sender,
      recipient,
      bottomTick,
      topTick,
      amount,
      abi.encode(msg.sender, pay0, pay1)
    );
  }

  function algebraMintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
  ) external override {
    (address sender, uint256 pay0, uint256 pay1) = abi.decode(data, (address, uint256, uint256));

    if (amount0Owed > 0) IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, pay0);
    if (amount1Owed > 0) IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, pay1);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IAlgebraPool.sol';
import './interfaces/IDataStorageOperator.sol';
import './interfaces/IAlgebraVirtualPool.sol';

import './base/PoolState.sol';
import './base/PoolImmutables.sol';

import './libraries/TokenDeltaMath.sol';
import './libraries/PriceMovementMath.sol';
import './libraries/TickManager.sol';
import './libraries/TickTable.sol';

import './libraries/LowGasSafeMath.sol';
import './libraries/SafeCast.sol';

import './libraries/FullMath.sol';
import './libraries/Constants.sol';
import './libraries/TransferHelper.sol';
import './libraries/TickMath.sol';
import './libraries/LiquidityMath.sol';

import './interfaces/IAlgebraPoolDeployer.sol';
import './interfaces/IAlgebraFactory.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/callback/IAlgebraMintCallback.sol';
import './interfaces/callback/IAlgebraSwapCallback.sol';
import './interfaces/callback/IAlgebraFlashCallback.sol';

contract AlgebraPool is PoolState, PoolImmutables, IAlgebraPool {
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;
  using LowGasSafeMath for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;
  using TickTable for mapping(int16 => uint256);
  using TickManager for mapping(int24 => TickManager.Tick);

  struct Position {
    uint128 liquidity; // The amount of liquidity concentrated in the range
    uint32 lastLiquidityAddTimestamp; // Timestamp of last adding of liquidity
    uint256 innerFeeGrowth0Token; // The last updated fee growth per unit of liquidity
    uint256 innerFeeGrowth1Token;
    uint128 fees0; // The amount of token0 owed to a LP
    uint128 fees1; // The amount of token1 owed to a LP
  }

  /// @inheritdoc IAlgebraPoolState
  mapping(bytes32 => Position) public override positions;

  /// @dev Restricts everyone calling a function except factory owner
  modifier onlyFactoryOwner() {
    require(msg.sender == IAlgebraFactory(factory).owner());
    _;
  }

  modifier onlyValidTicks(int24 bottomTick, int24 topTick) {
    require(topTick < TickMath.MAX_TICK + 1, 'TUM');
    require(topTick > bottomTick, 'TLU');
    require(bottomTick > TickMath.MIN_TICK - 1, 'TLM');
    _;
  }

  constructor() PoolImmutables(msg.sender) {
    globalState.fee = Constants.BASE_FEE;
  }

  function balanceToken0() private view returns (uint256) {
    return IERC20Minimal(token0).balanceOf(address(this));
  }

  function balanceToken1() private view returns (uint256) {
    return IERC20Minimal(token1).balanceOf(address(this));
  }

  /// @inheritdoc IAlgebraPoolState
  function timepoints(uint256 index)
    external
    view
    override
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    )
  {
    return IDataStorageOperator(dataStorageOperator).timepoints(index);
  }

  struct Cumulatives {
    int56 tickCumulative;
    uint160 outerSecondPerLiquidity;
    uint32 outerSecondsSpent;
  }

  /// @inheritdoc IAlgebraPoolDerivedState
  function getInnerCumulatives(int24 bottomTick, int24 topTick)
    external
    view
    override
    onlyValidTicks(bottomTick, topTick)
    returns (
      int56 innerTickCumulative,
      uint160 innerSecondsSpentPerLiquidity,
      uint32 innerSecondsSpent
    )
  {
    Cumulatives memory lower;
    {
      TickManager.Tick storage _lower = ticks[bottomTick];
      (lower.tickCumulative, lower.outerSecondPerLiquidity, lower.outerSecondsSpent) = (
        _lower.outerTickCumulative,
        _lower.outerSecondsPerLiquidity,
        _lower.outerSecondsSpent
      );
      require(_lower.initialized);
    }

    Cumulatives memory upper;
    {
      TickManager.Tick storage _upper = ticks[topTick];
      (upper.tickCumulative, upper.outerSecondPerLiquidity, upper.outerSecondsSpent) = (
        _upper.outerTickCumulative,
        _upper.outerSecondsPerLiquidity,
        _upper.outerSecondsSpent
      );

      require(_upper.initialized);
    }

    (int24 currentTick, uint16 currentTimepointIndex) = (globalState.tick, globalState.timepointIndex);

    if (currentTick < bottomTick) {
      return (
        lower.tickCumulative - upper.tickCumulative,
        lower.outerSecondPerLiquidity - upper.outerSecondPerLiquidity,
        lower.outerSecondsSpent - upper.outerSecondsSpent
      );
    }

    if (currentTick < topTick) {
      uint32 globalTime = _blockTimestamp();
      (int56 globalTickCumulative, uint160 globalSecondsPerLiquidityCumulative, , ) = _getSingleTimepoint(
        globalTime,
        0,
        currentTick,
        currentTimepointIndex,
        liquidity
      );
      return (
        globalTickCumulative - lower.tickCumulative - upper.tickCumulative,
        globalSecondsPerLiquidityCumulative - lower.outerSecondPerLiquidity - upper.outerSecondPerLiquidity,
        globalTime - lower.outerSecondsSpent - upper.outerSecondsSpent
      );
    }

    return (
      upper.tickCumulative - lower.tickCumulative,
      upper.outerSecondPerLiquidity - lower.outerSecondPerLiquidity,
      upper.outerSecondsSpent - lower.outerSecondsSpent
    );
  }

  /// @inheritdoc IAlgebraPoolDerivedState
  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    override
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    )
  {
    return
      IDataStorageOperator(dataStorageOperator).getTimepoints(
        _blockTimestamp(),
        secondsAgos,
        globalState.tick,
        globalState.timepointIndex,
        liquidity
      );
  }

  /// @inheritdoc IAlgebraPoolActions
  function initialize(uint160 initialPrice) external override {
    require(globalState.price == 0, 'AI');
    // getTickAtSqrtRatio checks validity of initialPrice inside
    int24 tick = TickMath.getTickAtSqrtRatio(initialPrice);

    uint32 timestamp = _blockTimestamp();
    IDataStorageOperator(dataStorageOperator).initialize(timestamp, tick);

    globalState.price = initialPrice;
    globalState.unlocked = true;
    globalState.tick = tick;

    emit Initialize(initialPrice, tick);
  }

  /**
   * @notice Increases amounts of tokens owed to owner of the position
   * @param _position The position object to operate with
   * @param liquidityDelta The amount on which to increase\decrease the liquidity
   * @param innerFeeGrowth0Token Total fee token0 fee growth per 1/liquidity between position's lower and upper ticks
   * @param innerFeeGrowth1Token Total fee token1 fee growth per 1/liquidity between position's lower and upper ticks
   */
  function _recalculatePosition(
    Position storage _position,
    int128 liquidityDelta,
    uint256 innerFeeGrowth0Token,
    uint256 innerFeeGrowth1Token
  ) internal {
    (uint128 currentLiquidity, uint32 lastLiquidityAddTimestamp) = (_position.liquidity, _position.lastLiquidityAddTimestamp);

    if (liquidityDelta == 0) {
      require(currentLiquidity > 0, 'NP'); // Do not recalculate the empty ranges
    } else {
      if (liquidityDelta < 0) {
        uint32 _liquidityCooldown = liquidityCooldown;
        if (_liquidityCooldown > 0) {
          require((_blockTimestamp() - lastLiquidityAddTimestamp) >= _liquidityCooldown);
        }
      }

      // change position liquidity
      uint128 liquidityNext = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
      (_position.liquidity, _position.lastLiquidityAddTimestamp) = (
        liquidityNext,
        liquidityNext > 0 ? (liquidityDelta > 0 ? _blockTimestamp() : lastLiquidityAddTimestamp) : 0
      );
    }

    // update the position
    uint256 _innerFeeGrowth0Token = _position.innerFeeGrowth0Token;
    uint256 _innerFeeGrowth1Token = _position.innerFeeGrowth1Token;
    uint128 fees0;
    if (innerFeeGrowth0Token != _innerFeeGrowth0Token) {
      _position.innerFeeGrowth0Token = innerFeeGrowth0Token;
      fees0 = uint128(FullMath.mulDiv(innerFeeGrowth0Token - _innerFeeGrowth0Token, currentLiquidity, Constants.Q128));
    }
    uint128 fees1;
    if (innerFeeGrowth1Token != _innerFeeGrowth1Token) {
      _position.innerFeeGrowth1Token = innerFeeGrowth1Token;
      fees1 = uint128(FullMath.mulDiv(innerFeeGrowth1Token - _innerFeeGrowth1Token, currentLiquidity, Constants.Q128));
    }

    // To avoid overflow owner has to collect fee before it
    if (fees0 | fees1 != 0) {
      _position.fees0 += fees0;
      _position.fees1 += fees1;
    }
  }

  struct UpdatePositionCache {
    uint160 price; // The square root of the current price in Q64.96 format
    int24 tick; // The current tick
    uint16 timepointIndex; // The index of the last written timepoint
  }

  /**
   * @dev Updates position's ticks and its fees
   * @return position The Position object to operate with
   * @return amount0 The amount of token0 the caller needs to send, negative if the pool needs to send it
   * @return amount1 The amount of token1 the caller needs to send, negative if the pool needs to send it
   */
  function _updatePositionTicksAndFees(
    address owner,
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta
  )
    private
    returns (
      Position storage position,
      int256 amount0,
      int256 amount1
    )
  {
    UpdatePositionCache memory cache = UpdatePositionCache(globalState.price, globalState.tick, globalState.timepointIndex);

    position = getOrCreatePosition(owner, bottomTick, topTick);

    (uint256 _totalFeeGrowth0Token, uint256 _totalFeeGrowth1Token) = (totalFeeGrowth0Token, totalFeeGrowth1Token);

    bool toggledBottom;
    bool toggledTop;
    if (liquidityDelta != 0) {
      uint32 time = _blockTimestamp();
      (int56 tickCumulative, uint160 secondsPerLiquidityCumulative, , ) = _getSingleTimepoint(time, 0, cache.tick, cache.timepointIndex, liquidity);

      if (
        ticks.update(
          bottomTick,
          cache.tick,
          liquidityDelta,
          _totalFeeGrowth0Token,
          _totalFeeGrowth1Token,
          secondsPerLiquidityCumulative,
          tickCumulative,
          time,
          false // isTopTick
        )
      ) {
        toggledBottom = true;
        tickTable.toggleTick(bottomTick);
      }

      if (
        ticks.update(
          topTick,
          cache.tick,
          liquidityDelta,
          _totalFeeGrowth0Token,
          _totalFeeGrowth1Token,
          secondsPerLiquidityCumulative,
          tickCumulative,
          time,
          true // isTopTick
        )
      ) {
        toggledTop = true;
        tickTable.toggleTick(topTick);
      }
    }

    (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks.getInnerFeeGrowth(
      bottomTick,
      topTick,
      cache.tick,
      _totalFeeGrowth0Token,
      _totalFeeGrowth1Token
    );

    _recalculatePosition(position, liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

    if (liquidityDelta != 0) {
      // if liquidityDelta is negative and the tick was toggled, it means that it should not be initialized anymore, so we delete it
      if (liquidityDelta < 0) {
        if (toggledBottom) delete ticks[bottomTick];
        if (toggledTop) delete ticks[topTick];
      }

      int128 globalLiquidityDelta;
      (amount0, amount1, globalLiquidityDelta) = _getAmountsForLiquidity(bottomTick, topTick, liquidityDelta, cache.tick, cache.price);
      if (globalLiquidityDelta != 0) {
        uint128 liquidityBefore = liquidity;
        uint16 newTimepointIndex = _writeTimepoint(cache.timepointIndex, _blockTimestamp(), cache.tick, liquidityBefore, volumePerLiquidityInBlock);
        if (cache.timepointIndex != newTimepointIndex) {
          globalState.fee = _getNewFee(_blockTimestamp(), cache.tick, newTimepointIndex, liquidityBefore);
          globalState.timepointIndex = newTimepointIndex;
          volumePerLiquidityInBlock = 0;
        }
        liquidity = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
      }
    }
  }

  function _getAmountsForLiquidity(
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta,
    int24 currentTick,
    uint160 currentPrice
  )
    private
    pure
    returns (
      int256 amount0,
      int256 amount1,
      int128 globalLiquidityDelta
    )
  {
    // If current tick is less than the provided bottom one then only the token0 has to be provided
    if (currentTick < bottomTick) {
      amount0 = TokenDeltaMath.getToken0Delta(TickMath.getSqrtRatioAtTick(bottomTick), TickMath.getSqrtRatioAtTick(topTick), liquidityDelta);
    } else if (currentTick < topTick) {
      amount0 = TokenDeltaMath.getToken0Delta(currentPrice, TickMath.getSqrtRatioAtTick(topTick), liquidityDelta);
      amount1 = TokenDeltaMath.getToken1Delta(TickMath.getSqrtRatioAtTick(bottomTick), currentPrice, liquidityDelta);

      globalLiquidityDelta = liquidityDelta;
    }
    // If current tick is greater than the provided top one then only the token1 has to be provided
    else {
      amount1 = TokenDeltaMath.getToken1Delta(TickMath.getSqrtRatioAtTick(bottomTick), TickMath.getSqrtRatioAtTick(topTick), liquidityDelta);
    }
  }

  /**
   * @notice This function fetches certain position object
   * @param owner The address owing the position
   * @param bottomTick The position's bottom tick
   * @param topTick The position's top tick
   * @return position The Position object
   */
  function getOrCreatePosition(
    address owner,
    int24 bottomTick,
    int24 topTick
  ) private view returns (Position storage) {
    bytes32 key;
    assembly {
      key := or(shl(24, or(shl(24, owner), and(bottomTick, 0xFFFFFF))), and(topTick, 0xFFFFFF))
    }
    return positions[key];
  }

  /// @inheritdoc IAlgebraPoolActions
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 liquidityDesired,
    bytes calldata data
  )
    external
    override
    lock
    onlyValidTicks(bottomTick, topTick)
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    )
  {
    require(liquidityDesired > 0, 'IL');
    {
      (int256 amount0Int, int256 amount1Int, ) = _getAmountsForLiquidity(
        bottomTick,
        topTick,
        int256(liquidityDesired).toInt128(),
        globalState.tick,
        globalState.price
      );

      amount0 = uint256(amount0Int);
      amount1 = uint256(amount1Int);
    }

    uint256 receivedAmount0;
    uint256 receivedAmount1;
    {
      if (amount0 > 0) receivedAmount0 = balanceToken0();
      if (amount1 > 0) receivedAmount1 = balanceToken1();
      IAlgebraMintCallback(msg.sender).algebraMintCallback(amount0, amount1, data);
      if (amount0 > 0) require((receivedAmount0 = balanceToken0() - receivedAmount0) > 0, 'IIAM');
      if (amount1 > 0) require((receivedAmount1 = balanceToken1() - receivedAmount1) > 0, 'IIAM');
    }

    liquidityActual = liquidityDesired;
    if (receivedAmount0 < amount0) {
      liquidityActual = uint128(FullMath.mulDiv(uint256(liquidityActual), receivedAmount0, amount0));
    }
    if (receivedAmount1 < amount1) {
      uint128 liquidityForRA1 = uint128(FullMath.mulDiv(uint256(liquidityActual), receivedAmount1, amount1));
      if (liquidityForRA1 < liquidityActual) {
        liquidityActual = liquidityForRA1;
      }
    }

    require(liquidityActual > 0, 'IIL2');

    {
      (, int256 amount0Int, int256 amount1Int) = _updatePositionTicksAndFees(recipient, bottomTick, topTick, int256(liquidityActual).toInt128());

      require((amount0 = uint256(amount0Int)) <= receivedAmount0, 'IIAM2');
      require((amount1 = uint256(amount1Int)) <= receivedAmount1, 'IIAM2');
    }

    if (receivedAmount0 > amount0) {
      TransferHelper.safeTransfer(token0, sender, receivedAmount0 - amount0);
    }
    if (receivedAmount1 > amount1) {
      TransferHelper.safeTransfer(token1, sender, receivedAmount1 - amount1);
    }
    emit Mint(msg.sender, recipient, bottomTick, topTick, liquidityActual, amount0, amount1);
  }

  /// @inheritdoc IAlgebraPoolActions
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external override lock returns (uint128 amount0, uint128 amount1) {
    Position storage position = getOrCreatePosition(msg.sender, bottomTick, topTick);
    (uint128 positionFees0, uint128 positionFees1) = (position.fees0, position.fees1);

    amount0 = amount0Requested > positionFees0 ? positionFees0 : amount0Requested;
    amount1 = amount1Requested > positionFees1 ? positionFees1 : amount1Requested;

    if (amount0 | amount1 != 0) {
      position.fees0 = positionFees0 - amount0;
      position.fees1 = positionFees1 - amount1;

      if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
      if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);
    }

    emit Collect(msg.sender, recipient, bottomTick, topTick, amount0, amount1);
  }

  /// @inheritdoc IAlgebraPoolActions
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external override lock onlyValidTicks(bottomTick, topTick) returns (uint256 amount0, uint256 amount1) {
    (Position storage position, int256 amount0Int, int256 amount1Int) = _updatePositionTicksAndFees(
      msg.sender,
      bottomTick,
      topTick,
      -int256(amount).toInt128()
    );

    amount0 = uint256(-amount0Int);
    amount1 = uint256(-amount1Int);

    if (amount0 | amount1 != 0) {
      (position.fees0, position.fees1) = (position.fees0.add128(uint128(amount0)), position.fees1.add128(uint128(amount1)));
    }

    emit Burn(msg.sender, bottomTick, topTick, amount, amount0, amount1);
  }

  /// @dev Returns new fee according combination of sigmoids
  function _getNewFee(
    uint32 _time,
    int24 _tick,
    uint16 _index,
    uint128 _liquidity
  ) private returns (uint16 newFee) {
    newFee = IDataStorageOperator(dataStorageOperator).getFee(_time, _tick, _index, _liquidity);
    emit Fee(newFee);
  }

  function _payCommunityFee(address token, uint256 amount) private {
    address vault = IAlgebraFactory(factory).vaultAddress();
    TransferHelper.safeTransfer(token, vault, amount);
  }

  function _writeTimepoint(
    uint16 timepointIndex,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidityInBlock
  ) private returns (uint16 newTimepointIndex) {
    return IDataStorageOperator(dataStorageOperator).write(timepointIndex, blockTimestamp, tick, liquidity, volumePerLiquidityInBlock);
  }

  function _getSingleTimepoint(
    uint32 blockTimestamp,
    uint32 secondsAgo,
    int24 startTick,
    uint16 timepointIndex,
    uint128 liquidityStart
  )
    private
    view
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    )
  {
    return IDataStorageOperator(dataStorageOperator).getSingleTimepoint(blockTimestamp, secondsAgo, startTick, timepointIndex, liquidityStart);
  }

  function _swapCallback(
    int256 amount0,
    int256 amount1,
    bytes calldata data
  ) private {
    IAlgebraSwapCallback(msg.sender).algebraSwapCallback(amount0, amount1, data);
  }

  /// @inheritdoc IAlgebraPoolActions
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external override returns (int256 amount0, int256 amount1) {
    uint160 currentPrice;
    int24 currentTick;
    uint128 currentLiquidity;
    uint256 communityFee;
    // function _calculateSwapAndLock locks globalState.unlocked and does not release
    (amount0, amount1, currentPrice, currentTick, currentLiquidity, communityFee) = _calculateSwapAndLock(zeroToOne, amountRequired, limitSqrtPrice);

    if (zeroToOne) {
      if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1)); // transfer to recipient

      uint256 balance0Before = balanceToken0();
      _swapCallback(amount0, amount1, data); // callback to get tokens from the caller
      require(balance0Before.add(uint256(amount0)) <= balanceToken0(), 'IIA');
    } else {
      if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0)); // transfer to recipient

      uint256 balance1Before = balanceToken1();
      _swapCallback(amount0, amount1, data); // callback to get tokens from the caller
      require(balance1Before.add(uint256(amount1)) <= balanceToken1(), 'IIA');
    }

    if (communityFee > 0) {
      _payCommunityFee(zeroToOne ? token0 : token1, communityFee);
    }

    emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
    globalState.unlocked = true; // release after lock in _calculateSwapAndLock
  }

  /// @inheritdoc IAlgebraPoolActions
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external override returns (int256 amount0, int256 amount1) {
    // Since the pool can get less tokens then sent, firstly we are getting tokens from the
    // original caller of the transaction. And change the _amountRequired_
    require(globalState.unlocked, 'LOK');
    globalState.unlocked = false;
    if (zeroToOne) {
      uint256 balance0Before = balanceToken0();
      _swapCallback(amountRequired, 0, data);
      require((amountRequired = int256(balanceToken0().sub(balance0Before))) > 0, 'IIA');
    } else {
      uint256 balance1Before = balanceToken1();
      _swapCallback(0, amountRequired, data);
      require((amountRequired = int256(balanceToken1().sub(balance1Before))) > 0, 'IIA');
    }
    globalState.unlocked = true;

    uint160 currentPrice;
    int24 currentTick;
    uint128 currentLiquidity;
    uint256 communityFee;
    // function _calculateSwapAndLock locks 'globalState.unlocked' and does not release
    (amount0, amount1, currentPrice, currentTick, currentLiquidity, communityFee) = _calculateSwapAndLock(zeroToOne, amountRequired, limitSqrtPrice);

    // only transfer to the recipient
    if (zeroToOne) {
      if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));
      // return the leftovers
      if (amount0 < amountRequired) TransferHelper.safeTransfer(token0, sender, uint256(amountRequired.sub(amount0)));
    } else {
      if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));
      // return the leftovers
      if (amount1 < amountRequired) TransferHelper.safeTransfer(token1, sender, uint256(amountRequired.sub(amount1)));
    }

    if (communityFee > 0) {
      _payCommunityFee(zeroToOne ? token0 : token1, communityFee);
    }

    emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
    globalState.unlocked = true; // release after lock in _calculateSwapAndLock
  }

  struct SwapCalculationCache {
    uint256 communityFee; // The community fee of the selling token, uint256 to minimize casts
    uint128 volumePerLiquidityInBlock;
    int56 tickCumulative; // The global tickCumulative at the moment
    uint160 secondsPerLiquidityCumulative; // The global secondPerLiquidity at the moment
    bool computedLatestTimepoint; //  if we have already fetched _tickCumulative_ and _secondPerLiquidity_ from the DataOperator
    int256 amountRequiredInitial; // The initial value of the exact input\output amount
    int256 amountCalculated; // The additive amount of total output\input calculated trough the swap
    uint256 totalFeeGrowth; // The initial totalFeeGrowth + the fee growth during a swap
    uint256 totalFeeGrowthB;
    IAlgebraVirtualPool.Status incentiveStatus; // If there is an active incentive at the moment
    bool exactInput; // Whether the exact input or output is specified
    uint16 fee; // The current dynamic fee
    int24 startTick; // The tick at the start of a swap
    uint16 timepointIndex; // The index of last written timepoint
  }

  struct PriceMovementCache {
    uint160 stepSqrtPrice; // The Q64.96 sqrt of the price at the start of the step
    int24 nextTick; // The tick till the current step goes
    bool initialized; // True if the _nextTick is initialized
    uint160 nextTickPrice; // The Q64.96 sqrt of the price calculated from the _nextTick
    uint256 input; // The additive amount of tokens that have been provided
    uint256 output; // The additive amount of token that have been withdrawn
    uint256 feeAmount; // The total amount of fee earned within a current step
  }

  /// @notice For gas optimization, locks 'globalState.unlocked' and does not release.
  function _calculateSwapAndLock(
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice
  )
    private
    returns (
      int256 amount0,
      int256 amount1,
      uint160 currentPrice,
      int24 currentTick,
      uint128 currentLiquidity,
      uint256 communityFeeAmount
    )
  {
    uint32 blockTimestamp;
    SwapCalculationCache memory cache;
    {
      // load from one storage slot
      currentPrice = globalState.price;
      currentTick = globalState.tick;
      cache.fee = globalState.fee;
      cache.timepointIndex = globalState.timepointIndex;
      uint256 _communityFeeToken0 = globalState.communityFeeToken0;
      uint256 _communityFeeToken1 = globalState.communityFeeToken1;
      bool unlocked = globalState.unlocked;

      globalState.unlocked = false; // lock will not be released in this function
      require(unlocked, 'LOK');

      require(amountRequired != 0, 'AS');
      (cache.amountRequiredInitial, cache.exactInput) = (amountRequired, amountRequired > 0);

      (currentLiquidity, cache.volumePerLiquidityInBlock) = (liquidity, volumePerLiquidityInBlock);

      if (zeroToOne) {
        require(limitSqrtPrice < currentPrice && limitSqrtPrice > TickMath.MIN_SQRT_RATIO, 'SPL');
        cache.totalFeeGrowth = totalFeeGrowth0Token;
        cache.communityFee = _communityFeeToken0;
      } else {
        require(limitSqrtPrice > currentPrice && limitSqrtPrice < TickMath.MAX_SQRT_RATIO, 'SPL');
        cache.totalFeeGrowth = totalFeeGrowth1Token;
        cache.communityFee = _communityFeeToken1;
      }

      cache.startTick = currentTick;

      blockTimestamp = _blockTimestamp();

      if (activeIncentive != address(0)) {
        IAlgebraVirtualPool.Status _status = IAlgebraVirtualPool(activeIncentive).increaseCumulative(blockTimestamp);
        if (_status == IAlgebraVirtualPool.Status.NOT_EXIST) {
          activeIncentive = address(0);
        } else if (_status == IAlgebraVirtualPool.Status.ACTIVE) {
          cache.incentiveStatus = IAlgebraVirtualPool.Status.ACTIVE;
        } else if (_status == IAlgebraVirtualPool.Status.NOT_STARTED) {
          cache.incentiveStatus = IAlgebraVirtualPool.Status.NOT_STARTED;
        }
      }

      uint16 newTimepointIndex = _writeTimepoint(
        cache.timepointIndex,
        blockTimestamp,
        cache.startTick,
        currentLiquidity,
        cache.volumePerLiquidityInBlock
      );

      // new timepoint appears only for first swap in block
      if (newTimepointIndex != cache.timepointIndex) {
        cache.timepointIndex = newTimepointIndex;
        cache.volumePerLiquidityInBlock = 0;
        cache.fee = _getNewFee(blockTimestamp, currentTick, newTimepointIndex, currentLiquidity);
      }
    }

    PriceMovementCache memory step;
    // swap until there is remaining input or output tokens or we reach the price limit
    while (true) {
      step.stepSqrtPrice = currentPrice;

      (step.nextTick, step.initialized) = tickTable.nextTickInTheSameRow(currentTick, zeroToOne);

      step.nextTickPrice = TickMath.getSqrtRatioAtTick(step.nextTick);

      // calculate the amounts needed to move the price to the next target if it is possible or as much as possible
      (currentPrice, step.input, step.output, step.feeAmount) = PriceMovementMath.movePriceTowardsTarget(
        zeroToOne,
        currentPrice,
        (zeroToOne == (step.nextTickPrice < limitSqrtPrice)) // move the price to the target or to the limit
          ? limitSqrtPrice
          : step.nextTickPrice,
        currentLiquidity,
        amountRequired,
        cache.fee
      );

      if (cache.exactInput) {
        amountRequired -= (step.input + step.feeAmount).toInt256(); // decrease remaining input amount
        cache.amountCalculated = cache.amountCalculated.sub(step.output.toInt256()); // decrease calculated output amount
      } else {
        amountRequired += step.output.toInt256(); // increase remaining output amount (since its negative)
        cache.amountCalculated = cache.amountCalculated.add((step.input + step.feeAmount).toInt256()); // increase calculated input amount
      }

      if (cache.communityFee > 0) {
        uint256 delta = (step.feeAmount.mul(cache.communityFee)) / Constants.COMMUNITY_FEE_DENOMINATOR;
        step.feeAmount -= delta;
        communityFeeAmount += delta;
      }

      if (currentLiquidity > 0) cache.totalFeeGrowth += FullMath.mulDiv(step.feeAmount, Constants.Q128, currentLiquidity);

      if (currentPrice == step.nextTickPrice) {
        // if the reached tick is initialized then we need to cross it
        if (step.initialized) {
          // once at a swap we have to get the last timepoint of the observation
          if (!cache.computedLatestTimepoint) {
            (cache.tickCumulative, cache.secondsPerLiquidityCumulative, , ) = _getSingleTimepoint(
              blockTimestamp,
              0,
              cache.startTick,
              cache.timepointIndex,
              currentLiquidity // currentLiquidity can be changed only after computedLatestTimepoint
            );
            cache.computedLatestTimepoint = true;
            cache.totalFeeGrowthB = zeroToOne ? totalFeeGrowth1Token : totalFeeGrowth0Token;
          }
          // every tick cross is needed to be duplicated in a virtual pool
          if (cache.incentiveStatus != IAlgebraVirtualPool.Status.NOT_EXIST) {
            IAlgebraVirtualPool(activeIncentive).cross(step.nextTick, zeroToOne);
          }
          int128 liquidityDelta;
          if (zeroToOne) {
            liquidityDelta = -ticks.cross(
              step.nextTick,
              cache.totalFeeGrowth, // A == 0
              cache.totalFeeGrowthB, // B == 1
              cache.secondsPerLiquidityCumulative,
              cache.tickCumulative,
              blockTimestamp
            );
          } else {
            liquidityDelta = ticks.cross(
              step.nextTick,
              cache.totalFeeGrowthB, // B == 0
              cache.totalFeeGrowth, // A == 1
              cache.secondsPerLiquidityCumulative,
              cache.tickCumulative,
              blockTimestamp
            );
          }

          currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
        }

        currentTick = zeroToOne ? step.nextTick - 1 : step.nextTick;
      } else if (currentPrice != step.stepSqrtPrice) {
        // if the price has changed but hasn't reached the target
        currentTick = TickMath.getTickAtSqrtRatio(currentPrice);
        break; // since the price hasn't reached the target, amountRequired should be 0
      }

      // check stop condition
      if (amountRequired == 0 || currentPrice == limitSqrtPrice) {
        break;
      }
    }

    (amount0, amount1) = zeroToOne == cache.exactInput // the amount to provide could be less then initially specified (e.g. reached limit)
      ? (cache.amountRequiredInitial - amountRequired, cache.amountCalculated) // the amount to get could be less then initially specified (e.g. reached limit)
      : (cache.amountCalculated, cache.amountRequiredInitial - amountRequired);

    (globalState.price, globalState.tick, globalState.fee, globalState.timepointIndex) = (currentPrice, currentTick, cache.fee, cache.timepointIndex);

    (liquidity, volumePerLiquidityInBlock) = (
      currentLiquidity,
      cache.volumePerLiquidityInBlock + IDataStorageOperator(dataStorageOperator).calculateVolumePerLiquidity(currentLiquidity, amount0, amount1)
    );

    if (zeroToOne) {
      totalFeeGrowth0Token = cache.totalFeeGrowth;
    } else {
      totalFeeGrowth1Token = cache.totalFeeGrowth;
    }
  }

  /// @inheritdoc IAlgebraPoolActions
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external override lock {
    uint128 _liquidity = liquidity;
    require(_liquidity > 0, 'L');

    uint16 _fee = globalState.fee;

    uint256 fee0;
    uint256 balance0Before = balanceToken0();
    if (amount0 > 0) {
      fee0 = FullMath.mulDivRoundingUp(amount0, _fee, 1e6);
      TransferHelper.safeTransfer(token0, recipient, amount0);
    }

    uint256 fee1;
    uint256 balance1Before = balanceToken1();
    if (amount1 > 0) {
      fee1 = FullMath.mulDivRoundingUp(amount1, _fee, 1e6);
      TransferHelper.safeTransfer(token1, recipient, amount1);
    }

    IAlgebraFlashCallback(msg.sender).algebraFlashCallback(fee0, fee1, data);

    address vault = IAlgebraFactory(factory).vaultAddress();

    uint256 paid0 = balanceToken0();
    require(balance0Before.add(fee0) <= paid0, 'F0');
    paid0 -= balance0Before;

    if (paid0 > 0) {
      uint8 _communityFeeToken0 = globalState.communityFeeToken0;
      uint256 fees0;
      if (_communityFeeToken0 > 0) {
        fees0 = (paid0 * _communityFeeToken0) / Constants.COMMUNITY_FEE_DENOMINATOR;
        TransferHelper.safeTransfer(token0, vault, fees0);
      }
      totalFeeGrowth0Token += FullMath.mulDiv(paid0 - fees0, Constants.Q128, _liquidity);
    }

    uint256 paid1 = balanceToken1();
    require(balance1Before.add(fee1) <= paid1, 'F1');
    paid1 -= balance1Before;

    if (paid1 > 0) {
      uint8 _communityFeeToken1 = globalState.communityFeeToken1;
      uint256 fees1;
      if (_communityFeeToken1 > 0) {
        fees1 = (paid1 * _communityFeeToken1) / Constants.COMMUNITY_FEE_DENOMINATOR;
        TransferHelper.safeTransfer(token1, vault, fees1);
      }
      totalFeeGrowth1Token += FullMath.mulDiv(paid1 - fees1, Constants.Q128, _liquidity);
    }

    emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external override lock onlyFactoryOwner {
    require((communityFee0 <= Constants.MAX_COMMUNITY_FEE) && (communityFee1 <= Constants.MAX_COMMUNITY_FEE));
    (globalState.communityFeeToken0, globalState.communityFeeToken1) = (communityFee0, communityFee1);
    emit CommunityFee(communityFee0, communityFee1);
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setIncentive(address virtualPoolAddress) external override {
    require(msg.sender == IAlgebraFactory(factory).farmingAddress());
    activeIncentive = virtualPoolAddress;

    emit Incentive(virtualPoolAddress);
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setLiquidityCooldown(uint32 newLiquidityCooldown) external override onlyFactoryOwner {
    require(newLiquidityCooldown <= Constants.MAX_LIQUIDITY_COOLDOWN && liquidityCooldown != newLiquidityCooldown);
    liquidityCooldown = newLiquidityCooldown;
    emit LiquidityCooldown(newLiquidityCooldown);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IAlgebraVirtualPool {
  enum Status {
    NOT_EXIST,
    ACTIVE,
    NOT_STARTED
  }

  /**
   * @dev This function is called by the main pool when an initialized tick is crossed there.
   * If the tick is also initialized in a virtual pool it should be crossed too
   * @param nextTick The crossed tick
   * @param zeroToOne The direction
   */
  function cross(int24 nextTick, bool zeroToOne) external;

  /**
   * @dev This function is called from the main pool before every swap To increase seconds per liquidity
   * cumulative considering previous timestamp and liquidity. The liquidity is stored in a virtual pool
   * @param currentTimestamp The timestamp of the current swap
   * @return Status The status of virtual pool
   */
  function increaseCumulative(uint32 currentTimestamp) external returns (Status);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import '../interfaces/pool/IAlgebraPoolState.sol';
import '../libraries/TickManager.sol';

abstract contract PoolState is IAlgebraPoolState {
  struct GlobalState {
    uint160 price; // The square root of the current price in Q64.96 format
    int24 tick; // The current tick
    uint16 fee; // The current fee in hundredths of a bip, i.e. 1e-6
    uint16 timepointIndex; // The index of the last written timepoint
    uint8 communityFeeToken0; // The community fee represented as a percent of all collected fee in thousandths (1e-3)
    uint8 communityFeeToken1;
    bool unlocked; // True if the contract is unlocked, otherwise - false
  }

  /// @inheritdoc IAlgebraPoolState
  uint256 public override totalFeeGrowth0Token;
  /// @inheritdoc IAlgebraPoolState
  uint256 public override totalFeeGrowth1Token;
  /// @inheritdoc IAlgebraPoolState
  GlobalState public override globalState;

  /// @inheritdoc IAlgebraPoolState
  uint128 public override liquidity;
  uint128 internal volumePerLiquidityInBlock;

  /// @inheritdoc IAlgebraPoolState
  uint32 public override liquidityCooldown;
  /// @inheritdoc IAlgebraPoolState
  address public override activeIncentive;

  /// @inheritdoc IAlgebraPoolState
  mapping(int24 => TickManager.Tick) public override ticks;
  /// @inheritdoc IAlgebraPoolState
  mapping(int16 => uint256) public override tickTable;

  /// @dev Reentrancy protection. Implemented in every function of the contract since there are checks of balances.
  modifier lock() {
    require(globalState.unlocked, 'LOK');
    globalState.unlocked = false;
    _;
    globalState.unlocked = true;
  }

  /// @dev This function is created for testing by overriding it.
  /// @return A timestamp converted to uint32
  function _blockTimestamp() internal view virtual returns (uint32) {
    return uint32(block.timestamp); // truncation is desired
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import '../interfaces/pool/IAlgebraPoolImmutables.sol';
import '../interfaces/IAlgebraPoolDeployer.sol';
import '../libraries/Constants.sol';

abstract contract PoolImmutables is IAlgebraPoolImmutables {
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override dataStorageOperator;

  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override factory;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override token0;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override token1;

  /// @inheritdoc IAlgebraPoolImmutables
  function tickSpacing() external pure override returns (int24) {
    return Constants.TICK_SPACING;
  }

  /// @inheritdoc IAlgebraPoolImmutables
  function maxLiquidityPerTick() external pure override returns (uint128) {
    return Constants.MAX_LIQUIDITY_PER_TICK;
  }

  constructor(address deployer) {
    (dataStorageOperator, factory, token0, token1) = IAlgebraPoolDeployer(deployer).parameters();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './LiquidityMath.sol';
import './Constants.sol';

/// @title TickManager
/// @notice Contains functions for managing tick processes and relevant calculations
library TickManager {
  using LowGasSafeMath for int256;
  using SafeCast for int256;

  // info stored for each initialized individual tick
  struct Tick {
    uint128 liquidityTotal; // the total position liquidity that references this tick
    int128 liquidityDelta; // amount of net liquidity added (subtracted) when tick is crossed left-right (right-left),
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 outerFeeGrowth0Token;
    uint256 outerFeeGrowth1Token;
    int56 outerTickCumulative; // the cumulative tick value on the other side of the tick
    uint160 outerSecondsPerLiquidity; // the seconds per unit of liquidity on the _other_ side of current tick, (relative meaning)
    uint32 outerSecondsSpent; // the seconds spent on the other side of the current tick, only has relative meaning
    bool initialized; // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
  }

  /// @notice Retrieves fee growth data
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param bottomTick The lower tick boundary of the position
  /// @param topTick The upper tick boundary of the position
  /// @param currentTick The current tick
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @return innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
  /// @return innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
  function getInnerFeeGrowth(
    mapping(int24 => Tick) storage self,
    int24 bottomTick,
    int24 topTick,
    int24 currentTick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token
  ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
    Tick storage lower = self[bottomTick];
    Tick storage upper = self[topTick];

    if (currentTick < topTick) {
      if (currentTick >= bottomTick) {
        innerFeeGrowth0Token = totalFeeGrowth0Token - lower.outerFeeGrowth0Token;
        innerFeeGrowth1Token = totalFeeGrowth1Token - lower.outerFeeGrowth1Token;
      } else {
        innerFeeGrowth0Token = lower.outerFeeGrowth0Token;
        innerFeeGrowth1Token = lower.outerFeeGrowth1Token;
      }
      innerFeeGrowth0Token -= upper.outerFeeGrowth0Token;
      innerFeeGrowth1Token -= upper.outerFeeGrowth1Token;
    } else {
      innerFeeGrowth0Token = upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
      innerFeeGrowth1Token = upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
    }
  }

  /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be updated
  /// @param currentTick The current tick
  /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @param secondsPerLiquidityCumulative The all-time seconds per max(1, liquidity) of the pool
  /// @param tickCumulative The all-time global cumulative tick
  /// @param time The current block timestamp cast to a uint32
  /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
  /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
  function update(
    mapping(int24 => Tick) storage self,
    int24 tick,
    int24 currentTick,
    int128 liquidityDelta,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    int56 tickCumulative,
    uint32 time,
    bool upper
  ) internal returns (bool flipped) {
    Tick storage data = self[tick];

    int128 liquidityDeltaBefore = data.liquidityDelta;
    uint128 liquidityTotalBefore = data.liquidityTotal;

    uint128 liquidityTotalAfter = LiquidityMath.addDelta(liquidityTotalBefore, liquidityDelta);
    require(liquidityTotalAfter < Constants.MAX_LIQUIDITY_PER_TICK + 1, 'LO');

    // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
    data.liquidityDelta = upper
      ? int256(liquidityDeltaBefore).sub(liquidityDelta).toInt128()
      : int256(liquidityDeltaBefore).add(liquidityDelta).toInt128();

    data.liquidityTotal = liquidityTotalAfter;

    flipped = (liquidityTotalAfter == 0);
    if (liquidityTotalBefore == 0) {
      flipped = !flipped;
      // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
      if (tick <= currentTick) {
        data.outerFeeGrowth0Token = totalFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token;
        data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative;
        data.outerTickCumulative = tickCumulative;
        data.outerSecondsSpent = time;
      }
      data.initialized = true;
    }
  }

  /// @notice Transitions to next tick as needed by price movement
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The destination tick of the transition
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @param secondsPerLiquidityCumulative The current seconds per liquidity
  /// @param tickCumulative The all-time global cumulative tick
  /// @param time The current block.timestamp
  /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
  function cross(
    mapping(int24 => Tick) storage self,
    int24 tick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    int56 tickCumulative,
    uint32 time
  ) internal returns (int128 liquidityDelta) {
    Tick storage data = self[tick];

    data.outerSecondsSpent = time - data.outerSecondsSpent;
    data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative - data.outerSecondsPerLiquidity;
    data.outerTickCumulative = tickCumulative - data.outerTickCumulative;

    data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
    data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;

    return data.liquidityDelta;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './Constants.sol';
import './TickMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTable {
  /// @notice Toggles the initialized state for a given tick from false to true, or vice versa
  /// @param self The mapping in which to toggle the tick
  /// @param tick The tick to toggle
  function toggleTick(mapping(int16 => uint256) storage self, int24 tick) internal {
    require(tick % Constants.TICK_SPACING == 0, 'tick is not spaced'); // ensure that the tick is spaced
    tick /= Constants.TICK_SPACING; // compress tick
    int16 rowNumber;
    uint8 bitNumber;

    assembly {
      bitNumber := and(tick, 0xFF)
      rowNumber := shr(8, tick)
    }
    self[rowNumber] ^= 1 << bitNumber;
  }

  /// @notice get position of single 1-bit
  /// @dev it is assumed that word contains exactly one 1-bit, otherwise the result will be incorrect
  /// @param word The word containing only one 1-bit
  function getSingleSignificantBit(uint256 word) internal pure returns (uint8 singleBitPos) {
    assembly {
      singleBitPos := iszero(and(word, 0x5555555555555555555555555555555555555555555555555555555555555555))
      singleBitPos := or(singleBitPos, shl(7, iszero(and(word, 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(6, iszero(and(word, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(5, iszero(and(word, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(4, iszero(and(word, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))))
      singleBitPos := or(singleBitPos, shl(3, iszero(and(word, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))))
      singleBitPos := or(singleBitPos, shl(2, iszero(and(word, 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F))))
      singleBitPos := or(singleBitPos, shl(1, iszero(and(word, 0x3333333333333333333333333333333333333333333333333333333333333333))))
    }
  }

  /// @notice get position of most significant 1-bit (leftmost)
  /// @dev it is assumed that before the call, a check will be made that the argument (word) is not equal to zero
  /// @param word The word containing at least one 1-bit
  function getMostSignificantBit(uint256 word) internal pure returns (uint8 mostBitPos) {
    assembly {
      word := or(word, shr(1, word))
      word := or(word, shr(2, word))
      word := or(word, shr(4, word))
      word := or(word, shr(8, word))
      word := or(word, shr(16, word))
      word := or(word, shr(32, word))
      word := or(word, shr(64, word))
      word := or(word, shr(128, word))
      word := sub(word, shr(1, word))
    }
    return (getSingleSignificantBit(word));
  }

  /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
  /// to the left (less than or equal to) or right (greater than) of the given tick
  /// @param self The mapping in which to compute the next initialized tick
  /// @param tick The starting tick
  /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
  /// @return nextTick The next initialized or uninitialized tick up to 256 ticks away from the current tick
  /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
  function nextTickInTheSameRow(
    mapping(int16 => uint256) storage self,
    int24 tick,
    bool lte
  ) internal view returns (int24 nextTick, bool initialized) {
    {
      int24 tickSpacing = Constants.TICK_SPACING;
      // compress and round towards negative infinity if negative
      assembly {
        tick := sub(sdiv(tick, tickSpacing), and(slt(tick, 0), not(iszero(smod(tick, tickSpacing)))))
      }
    }

    if (lte) {
      // unpacking not made into a separate function for gas and contract size savings
      int16 rowNumber;
      uint8 bitNumber;
      assembly {
        bitNumber := and(tick, 0xFF)
        rowNumber := shr(8, tick)
      }
      uint256 _row = self[rowNumber] << (255 - bitNumber); // all the 1s at or to the right of the current bitNumber

      if (_row != 0) {
        tick -= int24(255 - getMostSignificantBit(_row));
        return (uncompressAndBoundTick(tick), true);
      } else {
        tick -= int24(bitNumber);
        return (uncompressAndBoundTick(tick), false);
      }
    } else {
      // start from the word of the next tick, since the current tick state doesn't matter
      tick += 1;
      int16 rowNumber;
      uint8 bitNumber;
      assembly {
        bitNumber := and(tick, 0xFF)
        rowNumber := shr(8, tick)
      }

      // all the 1s at or to the left of the bitNumber
      uint256 _row = self[rowNumber] >> (bitNumber);

      if (_row != 0) {
        tick += int24(getSingleSignificantBit(-_row & _row)); // least significant bit
        return (uncompressAndBoundTick(tick), true);
      } else {
        tick += int24(255 - bitNumber);
        return (uncompressAndBoundTick(tick), false);
      }
    }
  }

  function uncompressAndBoundTick(int24 tick) private pure returns (int24 boundedTick) {
    boundedTick = tick * Constants.TICK_SPACING;
    if (boundedTick < TickMath.MIN_TICK) {
      boundedTick = TickMath.MIN_TICK;
    } else if (boundedTick > TickMath.MAX_TICK) {
      boundedTick = TickMath.MAX_TICK;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TransferHelper {
  /// @notice Transfers tokens from msg.sender to a recipient
  /// @dev Calls transfer on token contract, errors with TF if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param value The value of the transfer
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LiquidityMath {
  /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
  /// @param x The liquidity before change
  /// @param y The delta by which liquidity should be changed
  /// @return z The liquidity delta
  function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
    if (y < 0) {
      require((z = x - uint128(-y)) < x, 'LS');
    } else {
      require((z = x + uint128(y)) >= x, 'LA');
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../../AlgebraPool.sol';

// used for testing time dependent behavior
contract SimulationTimeAlgebraPool is AlgebraPool {
  // Monday, October 5, 2020 9:00:00 AM GMT-05:00
  uint256 public time = 1601906400;

  function advanceTime(uint256 by) external {
    time += by;
  }

  function _blockTimestamp() internal view override returns (uint32) {
    return uint32(time);
  }

  function getAverages() external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) {
    (TWVolatilityAverage, TWVolumePerLiqAverage) = IDataStorageOperator(dataStorageOperator).getAverages(
      _blockTimestamp(),
      globalState.fee,
      globalState.timepointIndex,
      liquidity
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import '../../interfaces/IAlgebraPoolDeployer.sol';
import './SimulationTimeAlgebraPool.sol';

contract SimulationTimePoolDeployer is IAlgebraPoolDeployer {
  struct Parameters {
    address dataStorage;
    address factory;
    address token0;
    address token1;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  Parameters public override parameters;

  address private factory;
  address private owner;

  modifier onlyFactory() {
    require(msg.sender == factory);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function setFactory(address _factory) external override onlyOwner {
    require(_factory != address(0));
    require(factory == address(0));
    emit Factory(_factory);
    factory = _factory;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function deploy(
    address dataStorage,
    address _factory,
    address token0,
    address token1
  ) external override onlyFactory returns (address pool) {
    parameters = Parameters({dataStorage: dataStorage, factory: _factory, token0: token0, token1: token1});
    pool = address(new SimulationTimeAlgebraPool{salt: keccak256(abi.encode(token0, token1))}());
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IAlgebraPoolDeployer.sol';

import './MockTimeAlgebraPool.sol';
import '../DataStorageOperator.sol';

contract MockTimeAlgebraPoolDeployer {
  struct Parameters {
    address dataStorage;
    address factory;
    address token0;
    address token1;
  }

  Parameters public parameters;

  event PoolDeployed(address pool);

  AdaptiveFee.Configuration baseFeeConfiguration =
    AdaptiveFee.Configuration(
      3000 - Constants.BASE_FEE, // alpha1
      15000 - 3000, // alpha2
      360, // beta1
      60000, // beta2
      59, // gamma1
      8500, // gamma2
      0, // volumeBeta
      10, // volumeGamma
      Constants.BASE_FEE // baseFee
    );

  function deployMock(
    address factory,
    address token0,
    address token1
  ) external returns (address pool) {
    bytes32 initCodeHash = keccak256(type(MockTimeAlgebraPool).creationCode);
    DataStorageOperator dataStorage = (new DataStorageOperator(computeAddress(initCodeHash, token0, token1)));

    dataStorage.changeFeeConfiguration(baseFeeConfiguration);

    parameters = Parameters({dataStorage: address(dataStorage), factory: factory, token0: token0, token1: token1});
    pool = address(new MockTimeAlgebraPool{salt: keccak256(abi.encode(token0, token1))}());
    emit PoolDeployed(pool);
  }

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param token0 first token
  /// @param token1 second token
  /// @return pool The contract address of the V3 pool
  function computeAddress(
    bytes32 initCodeHash,
    address token0,
    address token1
  ) internal view returns (address pool) {
    pool = address(uint256(keccak256(abi.encodePacked(hex'ff', address(this), keccak256(abi.encode(token0, token1)), initCodeHash))));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../AlgebraPool.sol';

// used for testing time dependent behavior
contract MockTimeAlgebraPool is AlgebraPool {
  // Monday, October 5, 2020 9:00:00 AM GMT-05:00
  uint256 public time = 1601906400;

  function setTotalFeeGrowth0Token(uint256 _totalFeeGrowth0Token) external {
    totalFeeGrowth0Token = _totalFeeGrowth0Token;
  }

  function setTotalFeeGrowth1Token(uint256 _totalFeeGrowth1Token) external {
    totalFeeGrowth1Token = _totalFeeGrowth1Token;
  }

  function advanceTime(uint256 by) external {
    time += by;
  }

  function _blockTimestamp() internal view override returns (uint32) {
    return uint32(time);
  }

  function checkBlockTimestamp() external view returns (bool) {
    require(super._blockTimestamp() == uint32(block.timestamp));
    return true;
  }

  function getAverages() external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) {
    (TWVolatilityAverage, TWVolumePerLiqAverage) = IDataStorageOperator(dataStorageOperator).getAverages(
      _blockTimestamp(),
      globalState.fee,
      globalState.timepointIndex,
      liquidity
    );
  }

  function getPrevTick() external view returns (int24 tick, int24 currentTick) {
    if (globalState.timepointIndex > 2) {
      (, uint32 lastTsmp, int56 tickCum, , , , ) = IDataStorageOperator(dataStorageOperator).timepoints(globalState.timepointIndex);
      (, uint32 plastTsmp, int56 ptickCum, , , , ) = IDataStorageOperator(dataStorageOperator).timepoints(globalState.timepointIndex - 1);
      tick = int24((tickCum - ptickCum) / (lastTsmp - plastTsmp));
    }
    currentTick = globalState.tick;
  }

  function getFee() external view returns (uint16 fee) {
    return IDataStorageOperator(dataStorageOperator).getFee(_blockTimestamp(), globalState.tick, globalState.timepointIndex, liquidity);
  }

  function getKeyForPosition(
    address owner,
    int24 bottomTick,
    int24 topTick
  ) external pure returns (bytes32 key) {
    assembly {
      key := or(shl(24, or(shl(24, owner), and(bottomTick, 0xFFFFFF))), and(topTick, 0xFFFFFF))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IAlgebraPoolDeployer.sol';
import './AlgebraPool.sol';

contract AlgebraPoolDeployer is IAlgebraPoolDeployer {
  struct Parameters {
    address dataStorage;
    address factory;
    address token0;
    address token1;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  Parameters public override parameters;

  address private factory;
  address private owner;

  modifier onlyFactory() {
    require(msg.sender == factory);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function setFactory(address _factory) external override onlyOwner {
    require(_factory != address(0));
    require(factory == address(0));
    emit Factory(_factory);
    factory = _factory;
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function deploy(
    address dataStorage,
    address _factory,
    address token0,
    address token1
  ) external override onlyFactory returns (address pool) {
    parameters = Parameters({dataStorage: dataStorage, factory: _factory, token0: token0, token1: token1});
    pool = address(new AlgebraPool{salt: keccak256(abi.encode(token0, token1))}());
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/SafeCast.sol';
import '../libraries/TickMath.sol';

import '../interfaces/IERC20Minimal.sol';
import '../interfaces/callback/IAlgebraSwapCallback.sol';
import '../interfaces/IAlgebraPool.sol';

contract TestAlgebraRouter is IAlgebraSwapCallback {
  using SafeCast for uint256;

  // flash swaps for an exact amount of token0 in the output pool
  function swapForExact0Multi(
    address recipient,
    address poolInput,
    address poolOutput,
    uint256 amount0Out
  ) external {
    address[] memory pools = new address[](1);
    pools[0] = poolInput;
    IAlgebraPool(poolOutput).swap(recipient, false, -amount0Out.toInt256(), TickMath.MAX_SQRT_RATIO - 1, abi.encode(pools, msg.sender));
  }

  // flash swaps for an exact amount of token1 in the output pool
  function swapForExact1Multi(
    address recipient,
    address poolInput,
    address poolOutput,
    uint256 amount1Out
  ) external {
    address[] memory pools = new address[](1);
    pools[0] = poolInput;
    IAlgebraPool(poolOutput).swap(recipient, true, -amount1Out.toInt256(), TickMath.MIN_SQRT_RATIO + 1, abi.encode(pools, msg.sender));
  }

  event SwapCallback(int256 amount0Delta, int256 amount1Delta);

  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) public override {
    emit SwapCallback(amount0Delta, amount1Delta);

    (address[] memory pools, address payer) = abi.decode(data, (address[], address));

    if (pools.length == 1) {
      // get the address and amount of the token that we need to pay
      address tokenToBePaid = amount0Delta > 0 ? IAlgebraPool(msg.sender).token0() : IAlgebraPool(msg.sender).token1();
      int256 amountToBePaid = amount0Delta > 0 ? amount0Delta : amount1Delta;

      bool zeroToOne = tokenToBePaid == IAlgebraPool(pools[0]).token1();
      IAlgebraPool(pools[0]).swap(
        msg.sender,
        zeroToOne,
        -amountToBePaid,
        zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
        abi.encode(new address[](0), payer)
      );
    } else {
      if (amount0Delta > 0) {
        IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(payer, msg.sender, uint256(amount0Delta));
      } else {
        IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(payer, msg.sender, uint256(amount1Delta));
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/IERC20Minimal.sol';

contract TestERC20 is IERC20Minimal {
  mapping(address => uint256) public override balanceOf;
  mapping(address => mapping(address => uint256)) public override allowance;

  constructor(uint256 amountToMint) {
    mint(msg.sender, amountToMint);
  }

  function mint(address to, uint256 amount) public {
    uint256 balanceNext = balanceOf[to] + amount;
    require(balanceNext >= amount, 'overflow balance');
    balanceOf[to] = balanceNext;
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    uint256 balanceBefore = balanceOf[msg.sender];
    require(balanceBefore >= amount, 'insufficient balance');
    balanceOf[msg.sender] = balanceBefore - amount;

    uint256 balanceRecipient = balanceOf[recipient];
    require(balanceRecipient + amount >= balanceRecipient, 'recipient balance overflow');
    if (!isDeflationary) {
      balanceOf[recipient] = balanceRecipient + amount;
    } else {
      balanceOf[recipient] = balanceRecipient + (amount - (amount * 5) / 100);
    }

    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  bool isDeflationary = false;

  function setDefl() external {
    isDeflationary = true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    uint256 allowanceBefore = allowance[sender][msg.sender];
    require(allowanceBefore >= amount, 'allowance insufficient');

    allowance[sender][msg.sender] = allowanceBefore - amount;

    uint256 balanceRecipient = balanceOf[recipient];
    require(balanceRecipient + amount >= balanceRecipient, 'overflow balance recipient');
    if (!isDeflationary) {
      balanceOf[recipient] = balanceRecipient + amount;
    } else {
      balanceOf[recipient] = balanceRecipient + (amount - (amount * 5) / 100);
    }
    uint256 balanceSender = balanceOf[sender];
    require(balanceSender >= amount, 'underflow balance sender');
    balanceOf[sender] = balanceSender - amount;

    emit Transfer(sender, recipient, amount);
    return true;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/IERC20Minimal.sol';

import '../interfaces/callback/IAlgebraSwapCallback.sol';
import '../interfaces/IAlgebraPool.sol';

contract AlgebraPoolSwapTest is IAlgebraSwapCallback {
  int256 private _amount0Delta;
  int256 private _amount1Delta;

  function getSwapResult(
    address pool,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice
  )
    external
    returns (
      int256 amount0Delta,
      int256 amount1Delta,
      uint160 nextSqrtRatio
    )
  {
    (amount0Delta, amount1Delta) = IAlgebraPool(pool).swap(address(0), zeroToOne, amountSpecified, limitSqrtPrice, abi.encode(msg.sender));

    (nextSqrtRatio, , , , , , ) = IAlgebraPool(pool).globalState();
  }

  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external override {
    address sender = abi.decode(data, (address));

    if (amount0Delta > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(sender, msg.sender, uint256(amount0Delta));
    } else if (amount1Delta > 0) {
      IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(sender, msg.sender, uint256(amount1Delta));
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickMath.sol';

contract TickMathTest {
  function getSqrtRatioAtTick(int24 tick) external pure returns (uint160) {
    return TickMath.getSqrtRatioAtTick(tick);
  }

  function getGasCostOfGetSqrtRatioAtTick(int24 tick) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TickMath.getSqrtRatioAtTick(tick);
    return gasBefore - gasleft();
  }

  function getTickAtSqrtRatio(uint160 price) external pure returns (int24) {
    return TickMath.getTickAtSqrtRatio(price);
  }

  function getGasCostOfGetTickAtSqrtRatio(uint160 price) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TickMath.getTickAtSqrtRatio(price);
    return gasBefore - gasleft();
  }

  function MIN_SQRT_RATIO() external pure returns (uint160) {
    return TickMath.MIN_SQRT_RATIO;
  }

  function MAX_SQRT_RATIO() external pure returns (uint160) {
    return TickMath.MAX_SQRT_RATIO;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickMath.sol';

contract TickMathEchidnaTest {
  // uniqueness and increasing order
  function checkGetSqrtRatioAtTickInvariants(int24 tick) external pure {
    uint160 ratio = TickMath.getSqrtRatioAtTick(tick);
    assert(TickMath.getSqrtRatioAtTick(tick - 1) < ratio && ratio < TickMath.getSqrtRatioAtTick(tick + 1));
    assert(ratio >= TickMath.MIN_SQRT_RATIO);
    assert(ratio <= TickMath.MAX_SQRT_RATIO);
  }

  // the ratio is always between the returned tick and the returned tick+1
  function checkGetTickAtSqrtRatioInvariants(uint160 ratio) external pure {
    int24 tick = TickMath.getTickAtSqrtRatio(ratio);
    assert(ratio >= TickMath.getSqrtRatioAtTick(tick) && ratio < TickMath.getSqrtRatioAtTick(tick + 1));
    assert(tick >= TickMath.MIN_TICK);
    assert(tick < TickMath.MAX_TICK);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickMath.sol';

import '../interfaces/callback/IAlgebraSwapCallback.sol';

import '../interfaces/IAlgebraPool.sol';

contract TestAlgebraReentrantCallee is IAlgebraSwapCallback {
  string private constant expectedReason = 'LOK';

  function swapToReenter(address pool) external {
    IAlgebraPool(pool).swap(address(0), false, 1, TickMath.MAX_SQRT_RATIO - 1, new bytes(0));
  }

  function algebraSwapCallback(
    int256,
    int256,
    bytes calldata
  ) external override {
    // try to reenter swap
    try IAlgebraPool(msg.sender).swap(address(0), false, 1, 0, new bytes(0)) {} catch Error(string memory reason) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    // try to reenter swap supporting fee
    try IAlgebraPool(msg.sender).swapSupportingFeeOnInputTokens(address(0), address(0), false, 1, 0, new bytes(0)) {} catch Error(
      string memory reason
    ) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    // try to reenter mint
    try IAlgebraPool(msg.sender).mint(address(0), address(0), 0, 0, 0, new bytes(0)) {} catch Error(string memory reason) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    // try to reenter collect
    try IAlgebraPool(msg.sender).collect(address(0), 0, 0, 0, 0) {} catch Error(string memory reason) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    // try to reenter burn
    try IAlgebraPool(msg.sender).burn(0, 0, 0) {} catch Error(string memory reason) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    // try to reenter flash
    try IAlgebraPool(msg.sender).flash(address(0), 0, 0, new bytes(0)) {} catch Error(string memory reason) {
      require(keccak256(abi.encode(reason)) == keccak256(abi.encode(expectedReason)));
    }

    require(false, 'Unable to reenter');
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickTable.sol';

contract TickTableTest {
  using TickTable for mapping(int16 => uint256);

  mapping(int16 => uint256) public bitmap;

  function toggleTick(int24 tick) external {
    bitmap.toggleTick(tick);
  }

  function getGasCostOfFlipTick(int24 tick) external returns (uint256) {
    uint256 gasBefore = gasleft();
    bitmap.toggleTick(tick);
    return gasBefore - gasleft();
  }

  function nextTickInTheSameRow(int24 tick, bool lte) external view returns (int24 next, bool initialized) {
    return bitmap.nextTickInTheSameRow(tick, lte);
  }

  function getGasCostOfNextTickInTheSameRow(int24 tick, bool lte) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    bitmap.nextTickInTheSameRow(tick, lte);
    return gasBefore - gasleft();
  }

  // returns whether the given tick is initialized
  function isInitialized(int24 tick) external view returns (bool) {
    (int24 next, bool initialized) = bitmap.nextTickInTheSameRow(tick, true);
    return next == tick ? initialized : false;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickTable.sol';

contract TickTableEchidnaTest {
  using TickTable for mapping(int16 => uint256);

  mapping(int16 => uint256) private bitmap;

  // returns whether the given tick is initialized
  function isInitialized(int24 tick) private view returns (bool) {
    (int24 next, bool initialized) = bitmap.nextTickInTheSameRow(tick, true);
    return next == tick ? initialized : false;
  }

  function toggleTick(int24 tick) external {
    tick = (tick / 60);
    tick = tick * 60;
    require(tick >= -887272);
    require(tick <= 887272);
    require(tick % 60 == 0);
    bool before = isInitialized(tick);
    bitmap.toggleTick(tick);
    assert(isInitialized(tick) == !before);
  }

  function checkNextInitializedTickWithinOneWordInvariants(int24 tick, bool lte) external view {
    tick = (tick / 60);
    tick = tick * 60;

    require(tick % 60 == 0);
    require(tick >= -887272);
    require(tick <= 887272);

    (int24 next, bool initialized) = bitmap.nextTickInTheSameRow(tick, lte);
    if (lte) {
      // type(int24).min + 256
      assert(next <= tick);
      assert(tick - next < 256 * 60);
      // all the ticks between the input tick and the next tick should be uninitialized
      for (int24 i = tick; i > next; i -= 60) {
        assert(!isInitialized(i));
      }
      assert(isInitialized(next) == initialized);
    } else {
      // type(int24).max - 256
      require(tick < 887272);
      assert(next > tick);
      assert(next - tick <= 256 * 60);
      // all the ticks between the input tick and the next tick should be uninitialized
      for (int24 i = tick + 60; i < next; i += 60) {
        assert(!isInitialized(i));
      }
      assert(isInitialized(next) == initialized);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickTable.sol';

contract BitMathTest {
  function mostSignificantBit(uint256 x) external pure returns (uint8 r) {
    return TickTable.getMostSignificantBit(x);
  }

  function getGasCostOfMostSignificantBit(uint256 x) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TickTable.getMostSignificantBit(x);
    return gasBefore - gasleft();
  }

  function leastSignificantBit(uint256 x) external pure returns (uint8 r) {
    return TickTable.getSingleSignificantBit(-x & x);
  }

  function getGasCostOfLeastSignificantBit(uint256 x) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    TickTable.getSingleSignificantBit(-x & x);
    return gasBefore - gasleft();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickTable.sol';

contract BitMathEchidnaTest {
  function mostSignificantBitInvariant(uint256 input) external pure {
    require(input > 0);
    uint8 msb = TickTable.getMostSignificantBit(input);
    assert(input >= (uint256(2)**msb));
    assert(msb == 255 || input < uint256(2)**(msb + 1));
  }

  function leastSignificantBitInvariant(uint256 input) external pure {
    require(input > 0);
    uint8 lsb = TickTable.getSingleSignificantBit(-input & input);
    assert(input & (uint256(2)**lsb) != 0);
    assert(input & (uint256(2)**lsb - 1) == 0);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/LowGasSafeMath.sol';
import '../libraries/SafeCast.sol';

contract SafeMathTest {
  function add(uint256 x, uint256 y) external pure returns (uint256 z) {
    return LowGasSafeMath.add(x, y);
  }

  function sub(uint256 x, uint256 y) external pure returns (uint256 z) {
    return LowGasSafeMath.sub(x, y);
  }

  function mul(uint256 x, uint256 y) external pure returns (uint256 z) {
    return LowGasSafeMath.mul(x, y);
  }

  function addInt(int256 x, int256 y) external pure returns (int256 z) {
    return LowGasSafeMath.add(x, y);
  }

  function subInt(int256 x, int256 y) external pure returns (int256 z) {
    return LowGasSafeMath.sub(x, y);
  }

  function add128(uint128 x, uint128 y) external pure returns (uint128 z) {
    return LowGasSafeMath.add128(x, y);
  }

  function toUint160(uint256 y) external pure returns (uint160 z) {
    return SafeCast.toUint160(y);
  }

  function toInt128(int256 y) external pure returns (int128 z) {
    return SafeCast.toInt128(y);
  }

  function toInt256(uint256 y) external pure returns (int256 z) {
    return SafeCast.toInt256(y);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/LowGasSafeMath.sol';

contract LowGasSafeMathEchidnaTest {
  function checkAdd(uint256 x, uint256 y) external pure {
    uint256 z = LowGasSafeMath.add(x, y);
    assert(z == x + y);
    assert(z >= x && z >= y);
  }

  function checkSub(uint256 x, uint256 y) external pure {
    uint256 z = LowGasSafeMath.sub(x, y);
    assert(z == x - y);
    assert(z <= x);
  }

  function checkMul(uint256 x, uint256 y) external pure {
    uint256 z = LowGasSafeMath.mul(x, y);
    assert(z == x * y);
    assert(x == 0 || y == 0 || (z >= x && z >= y));
  }

  function checkAddi(int256 x, int256 y) external pure {
    int256 z = LowGasSafeMath.add(x, y);
    assert(z == x + y);
    assert(y < 0 ? z < x : z >= x);
  }

  function checkSubi(int256 x, int256 y) external pure {
    int256 z = LowGasSafeMath.sub(x, y);
    assert(z == x - y);
    assert(y < 0 ? z > x : z <= x);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import '../libraries/TickManager.sol';

contract TickTest {
  using TickManager for mapping(int24 => TickManager.Tick);

  mapping(int24 => TickManager.Tick) public ticks;

  function setTick(int24 tick, TickManager.Tick memory data) external {
    ticks[tick] = data;
  }

  function getInnerFeeGrowth(
    int24 bottomTick,
    int24 topTick,
    int24 currentTick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token
  ) external view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
    return ticks.getInnerFeeGrowth(bottomTick, topTick, currentTick, totalFeeGrowth0Token, totalFeeGrowth1Token);
  }

  function update(
    int24 tick,
    int24 currentTick,
    int128 liquidityDelta,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    int56 tickCumulative,
    uint32 time,
    bool upper
  ) external returns (bool flipped) {
    return
      ticks.update(
        tick,
        currentTick,
        liquidityDelta,
        totalFeeGrowth0Token,
        totalFeeGrowth1Token,
        secondsPerLiquidityCumulative,
        tickCumulative,
        time,
        upper
      );
  }

  function clear(int24 tick) external {
    delete ticks[tick];
  }

  function cross(
    int24 tick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    int56 tickCumulative,
    uint32 time
  ) external returns (int128 liquidityDelta) {
    return ticks.cross(tick, totalFeeGrowth0Token, totalFeeGrowth1Token, secondsPerLiquidityCumulative, tickCumulative, time);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickManager.sol';

contract TickOverflowSafetyEchidnaTest {
  using TickManager for mapping(int24 => TickManager.Tick);

  int24 private constant MIN_TICK = -16;
  int24 private constant MAX_TICK = 16;
  uint128 private constant MAX_LIQUIDITY = type(uint128).max / 32;

  mapping(int24 => TickManager.Tick) private ticks;
  int24 private tick = 0;

  // used to track how much total liquidity has been added. should never be negative
  int256 totalLiquidity = 0;
  // half the cap of fee growth has happened, this can overflow
  uint256 private totalFeeGrowth0Token = type(uint256).max / 2;
  uint256 private totalFeeGrowth1Token = type(uint256).max / 2;
  // how much total growth has happened, this cannot overflow
  uint256 private totalGrowth0 = 0;
  uint256 private totalGrowth1 = 0;

  function increaseTotalFeeGrowth0Token(uint256 amount) external {
    require(totalGrowth0 + amount > totalGrowth0); // overflow check
    totalFeeGrowth0Token += amount; // overflow desired
    totalGrowth0 += amount;
  }

  function increaseTotalFeeGrowth1Token(uint256 amount) external {
    require(totalGrowth1 + amount > totalGrowth1); // overflow check
    totalFeeGrowth1Token += amount; // overflow desired
    totalGrowth1 += amount;
  }

  function setPosition(
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta
  ) external {
    require(bottomTick > MIN_TICK);
    require(topTick < MAX_TICK);
    require(bottomTick < topTick);
    bool flippedLower = ticks.update(
      bottomTick,
      tick,
      liquidityDelta,
      totalFeeGrowth0Token,
      totalFeeGrowth1Token,
      0,
      0,
      uint32(block.timestamp),
      false
    );
    bool flippedUpper = ticks.update(topTick, tick, liquidityDelta, totalFeeGrowth0Token, totalFeeGrowth1Token, 0, 0, uint32(block.timestamp), true);

    if (flippedLower) {
      if (liquidityDelta < 0) {
        assert(ticks[bottomTick].liquidityTotal == 0);
        delete ticks[bottomTick];
      } else assert(ticks[bottomTick].liquidityTotal > 0);
    }

    if (flippedUpper) {
      if (liquidityDelta < 0) {
        assert(ticks[topTick].liquidityTotal == 0);
        delete ticks[topTick];
      } else assert(ticks[topTick].liquidityTotal > 0);
    }

    totalLiquidity += liquidityDelta;
    // requires should have prevented this
    assert(totalLiquidity >= 0);

    if (totalLiquidity == 0) {
      totalGrowth0 = 0;
      totalGrowth1 = 0;
    }
  }

  function moveToTick(int24 target) external {
    require(target > MIN_TICK);
    require(target < MAX_TICK);
    while (tick != target) {
      if (tick < target) {
        if (ticks[tick + 1].liquidityTotal > 0) ticks.cross(tick + 1, totalFeeGrowth0Token, totalFeeGrowth1Token, 0, 0, uint32(block.timestamp));
        tick++;
      } else {
        if (ticks[tick].liquidityTotal > 0) ticks.cross(tick, totalFeeGrowth0Token, totalFeeGrowth1Token, 0, 0, uint32(block.timestamp));
        tick--;
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/LiquidityMath.sol';

contract LiquidityMathTest {
  function addDelta(uint128 x, int128 y) external pure returns (uint128 z) {
    return LiquidityMath.addDelta(x, y);
  }

  function getGasCostOfAddDelta(uint128 x, int128 y) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    LiquidityMath.addDelta(x, y);
    return gasBefore - gasleft();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/IAlgebraVirtualPool.sol';

contract MockTimeVirtualPool is IAlgebraVirtualPool {
  uint32 public timestamp;

  bool private isExist = true;
  bool private isStarted = true;

  int24 public currentTick;

  function setIsExist(bool _isExist) external {
    isExist = _isExist;
  }

  function setIsStarted(bool _isStarted) external {
    isStarted = _isStarted;
  }

  function increaseCumulative(uint32 currentTimestamp) external override returns (Status) {
    if (!isExist) return Status.NOT_EXIST;
    if (!isStarted) return Status.NOT_STARTED;

    timestamp = currentTimestamp;
    return Status.ACTIVE;
  }

  function cross(int24 nextTick, bool zeroToOne) external override {
    zeroToOne;
    require(isExist, 'Virtual pool not exist');
    currentTick = nextTick;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/FullMath.sol';

contract FullMathTest {
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 z
  ) external pure returns (uint256) {
    return FullMath.mulDiv(x, y, z);
  }

  function mulDivRoundingUp(
    uint256 x,
    uint256 y,
    uint256 z
  ) external pure returns (uint256) {
    return FullMath.mulDivRoundingUp(x, y, z);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/FullMath.sol';

contract FullMathEchidnaTest {
  function checkMulDivRounding(
    uint256 x,
    uint256 y,
    uint256 d
  ) external pure {
    require(d > 0);

    uint256 ceiled = FullMath.mulDivRoundingUp(x, y, d);
    uint256 floored = FullMath.mulDiv(x, y, d);

    if (mulmod(x, y, d) > 0) {
      assert(ceiled - floored == 1);
    } else {
      assert(ceiled == floored);
    }
  }

  function checkMulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) external pure {
    require(d > 0);
    uint256 z = FullMath.mulDiv(x, y, d);
    if (x == 0 || y == 0) {
      assert(z == 0);
      return;
    }

    // recompute x and y via mulDiv of the result of floor(x*y/d), should always be less than original inputs by < d
    uint256 x2 = FullMath.mulDiv(z, d, y);
    uint256 y2 = FullMath.mulDiv(z, d, x);
    assert(x2 <= x);
    assert(y2 <= y);

    assert(x - x2 < d);
    assert(y - y2 < d);
  }

  function checkMulDivRoundingUp(
    uint256 x,
    uint256 y,
    uint256 d
  ) external pure {
    require(d > 0);
    uint256 z = FullMath.mulDivRoundingUp(x, y, d);
    if (x == 0 || y == 0) {
      assert(z == 0);
      return;
    }

    // recompute x and y via mulDiv of the result of floor(x*y/d), should always be less than original inputs by < d
    uint256 x2 = FullMath.mulDiv(z, d, y);
    uint256 y2 = FullMath.mulDiv(z, d, x);
    assert(x2 >= x);
    assert(y2 >= y);

    assert(x2 - x < d);
    assert(y2 - y < d);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import '../libraries/DataStorage.sol';

contract DataStorageTest {
  uint256 private constant UINT16_MODULO = 65536;
  using DataStorage for DataStorage.Timepoint[UINT16_MODULO];

  DataStorage.Timepoint[UINT16_MODULO] public timepoints;

  uint32 public time;
  int24 public tick;
  uint128 public liquidity;
  uint16 public index;

  struct InitializeParams {
    uint32 time;
    int24 tick;
    uint128 liquidity;
  }

  function initialize(InitializeParams calldata params) external {
    time = params.time;
    tick = params.tick;
    liquidity = params.liquidity;
    timepoints.initialize(params.time, tick);
  }

  function advanceTime(uint32 by) public {
    time += by;
  }

  struct UpdateParams {
    uint32 advanceTimeBy;
    int24 tick;
    uint128 liquidity;
  }

  // write an timepoint, then change tick and liquidity
  function update(UpdateParams calldata params) external {
    advanceTime(params.advanceTimeBy);
    index = timepoints.write(index, time, tick, liquidity, 0); //TODO: fix for testing
    tick = params.tick;
    liquidity = params.liquidity;
  }

  function batchUpdate(UpdateParams[] calldata params) external {
    // sload everything
    int24 _tick = tick;
    uint128 _liquidity = liquidity;
    uint16 _index = index;
    uint32 _time = time;

    for (uint256 i = 0; i < params.length; i++) {
      _time += params[i].advanceTimeBy;
      _index = timepoints.write(_index, _time, _tick, _liquidity, 0);
      _tick = params[i].tick;
      _liquidity = params[i].liquidity;
    }

    // sstore everything
    tick = _tick;
    liquidity = _liquidity;
    index = _index;
    time = _time;
  }

  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    )
  {
    return timepoints.getTimepoints(time, secondsAgos, tick, index, liquidity);
  }

  function getGasCostOfGetPoints(uint32[] calldata secondsAgos) external view returns (uint256) {
    (uint32 _time, int24 _tick, uint128 _liquidity, uint16 _index) = (time, tick, liquidity, index);
    uint256 gasBefore = gasleft();
    timepoints.getTimepoints(_time, secondsAgos, _tick, _index, _liquidity);
    return gasBefore - gasleft();
  }

  function volatilityOnRange(
    uint32 dt,
    int24 tick0,
    int24 tick1,
    int24 avgTick0,
    int24 avgTick1
  ) external pure returns (uint256) {
    return DataStorage._volatilityOnRange(dt, tick0, tick1, avgTick0, avgTick1);
  }

  function getAverageTick() external view returns (int256) {
    uint32 lastTimestamp = timepoints[index].blockTimestamp;
    int56 lastTickCumulative = timepoints[index].tickCumulative;

    uint16 oldestIndex;
    if (timepoints[index + 1].initialized) {
      oldestIndex = index + 1;
    }

    (uint32 _time, int24 _tick, uint16 _index) = (time, tick, index);
    return timepoints._getAverageTick(_time, _tick, _index, oldestIndex, lastTimestamp, lastTickCumulative);
  }

  function window() external pure returns (uint256) {
    return DataStorage.WINDOW;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import './DataStorageTest.sol';

contract DataStorageEchidnaTest {
  DataStorageTest private dataStorage;

  bool private initialized;
  uint32 private timePassed;

  constructor() {
    dataStorage = new DataStorageTest();
  }

  function initialize(
    uint32 time,
    int24 tick,
    uint128 liquidity
  ) external {
    require(tick % 60 == 0);
    dataStorage.initialize(DataStorageTest.InitializeParams({time: time, tick: tick, liquidity: liquidity}));
    initialized = true;
  }

  function limitTimePassed(uint32 by) private {
    require(timePassed + by >= timePassed);
    timePassed += by;
  }

  function advanceTime(uint32 by) public {
    limitTimePassed(by);
    dataStorage.advanceTime(by);
  }

  // write an timepoint, then change tick and liquidity
  function update(
    uint32 advanceTimeBy,
    int24 tick,
    uint128 liquidity
  ) external {
    require(initialized);
    limitTimePassed(advanceTimeBy);
    dataStorage.update(DataStorageTest.UpdateParams({advanceTimeBy: advanceTimeBy, tick: tick, liquidity: liquidity}));
  }

  function checkTimeWeightedResultAssertions(uint32 secondsAgo0, uint32 secondsAgo1) private view {
    require(secondsAgo0 != secondsAgo1);
    require(initialized);
    // secondsAgo0 should be the larger one
    if (secondsAgo0 < secondsAgo1) (secondsAgo0, secondsAgo1) = (secondsAgo1, secondsAgo0);

    uint32 timeElapsed = secondsAgo0 - secondsAgo1;

    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = secondsAgo0;
    secondsAgos[1] = secondsAgo1;

    (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulatives, , ) = dataStorage.getTimepoints(secondsAgos);
    int56 timeWeightedTick = (tickCumulatives[1] - tickCumulatives[0]) / timeElapsed;
    uint256 timeWeightedHarmonicMeanLiquidity = (uint256(timeElapsed) * type(uint160).max) /
      (uint256(secondsPerLiquidityCumulatives[1] - secondsPerLiquidityCumulatives[0]) << 32);
    assert(timeWeightedHarmonicMeanLiquidity <= type(uint128).max);
    assert(timeWeightedTick <= type(int24).max);
    assert(timeWeightedTick >= type(int24).min);
  }

  function echidna_indexAlwaysLtCardinality() external view returns (bool) {
    return dataStorage.index() < 65536 || !initialized;
  }

  function echidna_avgTickNotOverflows() external view returns (bool) {
    int256 res = dataStorage.getAverageTick();
    return (res <= type(int24).max && res >= type(int24).min);
  }

  function echidna_canAlwaysGetPoints0IfInitialized() external view returns (bool) {
    if (!initialized) {
      return true;
    }
    uint32[] memory arr = new uint32[](1);
    arr[0] = 0;
    (bool success, ) = address(dataStorage).staticcall(abi.encodeWithSelector(DataStorageTest.getTimepoints.selector, arr));
    return success;
  }

  function checkVolatilityOnRangeNotOverflowUint88(
    uint32 dt,
    int24 tick0,
    int24 tick1,
    int24 avgTick0,
    int24 avgTick1
  ) external view {
    uint256 res = dataStorage.volatilityOnRange(dt, tick0, tick1, avgTick0, avgTick1);
    assert(res <= type(uint88).max);
  }

  function checkTwoAdjacentTimepointsTickCumulativeModTimeElapsedAlways0(uint16 index) external view {
    // check that the timepoints are initialized, and that the index is not the oldest timepoint
    require(index < 65536 && index != (dataStorage.index() + 1) % 65536);

    (bool initialized0, uint32 blockTimestamp0, int56 tickCumulative0, , , , ) = dataStorage.timepoints(index == 0 ? 65536 - 1 : index - 1);
    (bool initialized1, uint32 blockTimestamp1, int56 tickCumulative1, , , , ) = dataStorage.timepoints(index);

    require(initialized0);
    require(initialized1);

    uint32 timeElapsed = blockTimestamp1 - blockTimestamp0;
    assert(timeElapsed > 0);
    assert((tickCumulative1 - tickCumulative0) % timeElapsed == 0);
  }

  function checkTimeWeightedAveragesAlwaysFitsType(uint32 secondsAgo) external view {
    require(initialized);
    require(secondsAgo > 0);
    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = secondsAgo;
    secondsAgos[1] = 0;
    (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives, //TODO: volumePerLiq
      ,

    ) = dataStorage.getTimepoints(secondsAgos);

    // compute the time weighted tick, rounded towards negative infinity
    int56 numerator = tickCumulatives[1] - tickCumulatives[0];
    int56 timeWeightedTick = numerator / int56(secondsAgo);
    if (numerator < 0 && numerator % int56(secondsAgo) != 0) {
      timeWeightedTick--;
    }

    // the time weighted averages fit in their respective accumulated types
    assert(timeWeightedTick <= type(int24).max && timeWeightedTick >= type(int24).min);

    uint256 timeWeightedHarmonicMeanLiquidity = (uint256(secondsAgo) * type(uint160).max) /
      (uint256(secondsPerLiquidityCumulatives[1] - secondsPerLiquidityCumulatives[0]) << 32);
    assert(timeWeightedHarmonicMeanLiquidity <= type(uint128).max);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/PriceMovementMath.sol';

contract PriceMovementMathTest {
  function movePriceTowardsTarget(
    uint160 sqrtP,
    uint160 sqrtPTarget,
    uint128 liquidity,
    int256 amountRemaining,
    uint16 feePips
  )
    external
    pure
    returns (
      uint160 sqrtQ,
      uint256 amountIn,
      uint256 amountOut,
      uint256 feeAmount
    )
  {
    return PriceMovementMath.movePriceTowardsTarget(sqrtPTarget < sqrtP, sqrtP, sqrtPTarget, liquidity, amountRemaining, feePips);
  }

  function getGasCostOfmovePriceTowardsTarget(
    uint160 sqrtP,
    uint160 sqrtPTarget,
    uint128 liquidity,
    int256 amountRemaining,
    uint16 feePips
  ) external view returns (uint256) {
    uint256 gasBefore = gasleft();
    PriceMovementMath.movePriceTowardsTarget(sqrtPTarget < sqrtP, sqrtP, sqrtPTarget, liquidity, amountRemaining, feePips);
    return gasBefore - gasleft();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/PriceMovementMath.sol';

contract PriceMovementMathEchidnaTest {
  function checkmovePriceTowardsTargetInvariants(
    uint160 sqrtPriceRaw,
    uint160 sqrtPriceTargetRaw,
    uint128 liquidity,
    int256 amountRemaining,
    uint16 feePips
  ) external pure {
    require(sqrtPriceRaw > 0);
    require(sqrtPriceTargetRaw > 0);
    require(feePips > 0);
    require(feePips < 1e6);

    (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = PriceMovementMath.movePriceTowardsTarget(
      sqrtPriceTargetRaw <= sqrtPriceRaw,
      sqrtPriceRaw,
      sqrtPriceTargetRaw,
      liquidity,
      amountRemaining,
      feePips
    );

    assert(amountIn <= type(uint256).max - feeAmount);

    if (amountRemaining < 0) {
      assert(amountOut <= uint256(-amountRemaining));
    } else {
      assert(amountIn + feeAmount <= uint256(amountRemaining));
    }

    if (sqrtPriceRaw == sqrtPriceTargetRaw) {
      assert(amountIn == 0);
      assert(amountOut == 0);
      assert(feeAmount == 0);
      assert(sqrtQ == sqrtPriceTargetRaw);
    }

    // didn't reach price target, entire amount must be consumed
    if (sqrtQ != sqrtPriceTargetRaw) {
      if (amountRemaining < 0) assert(amountOut == uint256(-amountRemaining));
      else assert(amountIn + feeAmount == uint256(amountRemaining));
    }

    // next price is between price and price target
    if (sqrtPriceTargetRaw <= sqrtPriceRaw) {
      assert(sqrtQ <= sqrtPriceRaw);
      assert(sqrtQ >= sqrtPriceTargetRaw);
    } else {
      assert(sqrtQ >= sqrtPriceRaw);
      assert(sqrtQ <= sqrtPriceTargetRaw);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/AdaptiveFee.sol';

contract AdaptiveFeeEchidnaTest {
  function expInvariants(uint256 x, uint16 gamma) external pure {
    require(gamma != 0);
    if (x >= 6 * gamma) return;
    uint256 g8 = uint256(gamma)**8;
    uint256 exp = AdaptiveFee.exp(x, gamma, g8);
    assert(exp < 2**137);
  }

  function sigmoidInvariants(
    uint256 x,
    uint16 gamma,
    uint16 alpha,
    uint256 beta
  ) external pure {
    require(gamma != 0);
    uint256 res = AdaptiveFee.sigmoid(x, gamma, alpha, beta);
    assert(res <= type(uint16).max);
    assert(res <= alpha);
  }

  function getFeeInvariants(
    uint88 volatility,
    uint256 volumePerLiquidity,
    uint16 gamma1,
    uint16 gamma2,
    uint16 alpha1,
    uint16 alpha2,
    uint32 beta1,
    uint32 beta2,
    uint16 volumeGamma,
    uint32 volumeBeta,
    uint16 baseFee
  ) external pure returns (uint256 fee) {
    require(uint256(alpha1) + uint256(alpha2) + uint256(baseFee) <= type(uint16).max, 'Max fee exceeded');
    require(gamma1 != 0 && gamma2 != 0 && volumeGamma != 0, 'Gammas must be > 0');

    uint256 sigm1 = AdaptiveFee.sigmoid(volatility, gamma1, alpha1, beta1);
    uint256 sigm2 = AdaptiveFee.sigmoid(volatility, gamma2, alpha2, beta2);

    assert(sigm1 + sigm2 <= type(uint16).max);

    fee = baseFee + AdaptiveFee.sigmoid(volumePerLiquidity, volumeGamma, uint16(sigm1 + sigm2), volumeBeta);
    assert(fee <= type(uint16).max);
  }
}