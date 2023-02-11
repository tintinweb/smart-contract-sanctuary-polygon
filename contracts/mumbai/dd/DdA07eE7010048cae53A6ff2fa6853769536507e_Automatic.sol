// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from '../../interfaces/IPool.sol';

contract Automatic {
  address internal _pool;
  address internal _owner;

  modifier onlyOwner() {
    require(_owner == msg.sender, 'caller is not the owner');
    _;
  }

  constructor() {
    _owner = msg.sender;
  }

  function setPool(address newPool) public onlyOwner {
    _pool = newPool;
  }

  function reduxSplit() public {
    IPool(_pool).splitReduxInterest();
  }
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