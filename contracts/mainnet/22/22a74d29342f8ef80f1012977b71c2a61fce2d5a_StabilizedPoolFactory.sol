// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../Permissions.sol";
import "./StabilizedPool.sol";
import "../interfaces/ITransferService.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";
import "../interfaces/IStabilizedPoolUpdater.sol";
import "../DataFeed/MaltDataLab.sol";
import "../StabilityPod/SwingTraderManager.sol";
import "../StabilityPod/ImpliedCollateralService.sol";
import "../StabilityPod/StabilizerNode.sol";
import "../StabilityPod/ProfitDistributor.sol";
import "../StabilityPod/LiquidityExtension.sol";
import "../DexHandlers/UniswapHandler.sol";
import "../RewardSystem/RewardOverflowPool.sol";
import "../RewardSystem/LinearDistributor.sol";
import "../RewardSystem/VestingDistributor.sol";
import "../RewardSystem/RewardThrottle.sol";
import "../Auction/Auction.sol";
import "../Auction/AuctionEscapeHatch.sol";
import "../Staking/Bonding.sol";
import "../Staking/ForfeitHandler.sol";
import "../Staking/MiningService.sol";
import "../Staking/ERC20VestedMine.sol";
import "../Staking/RewardMineBase.sol";
import "../Staking/RewardReinvestor.sol";
import "../Token/PoolTransferVerification.sol";
import "../Token/Malt.sol";
import "../ops/UniV2PoolKeeper.sol";

/// @title Stabilized Pool Factory
/// @author 0xScotch <[email protected]>
/// @notice A factory that can deploy all the contracts for a given pool
contract StabilizedPoolFactory is Permissions {
  address public immutable malt;

  bytes32 public immutable POOL_UPDATER_ROLE;

  address public timekeeper;
  IGlobalImpliedCollateralService public globalIC;
  ITransferService public transferService;

  address[] public pools;
  mapping(address => StabilizedPool) public stabilizedPools;

  event NewStabilizedPool(address indexed pool);
  event SetTimekeeper(address timekeeper);

  constructor(
    address _repository,
    address initialAdmin,
    address _malt,
    address _globalIC,
    address _transferService,
    address _timekeeper
  ) {
    malt = _malt;

    require(_repository != address(0), "pod: repository");
    require(_malt != address(0), "pod: malt");
    require(initialAdmin != address(0), "pod: admin");
    require(_globalIC != address(0), "pod: globalIC");
    require(_timekeeper != address(0), "pod: timekeeper");
    require(_transferService != address(0), "pod: xfer");

    POOL_UPDATER_ROLE = 0xb70e81d43273d7b57d823256e2fd3d6bb0b670e5f5e1253ffd1c5f776a989c34;
    _initialSetup(_repository);
    _roleSetup(
      0xb70e81d43273d7b57d823256e2fd3d6bb0b670e5f5e1253ffd1c5f776a989c34,
      initialAdmin
    );

    timekeeper = _timekeeper;
    globalIC = IGlobalImpliedCollateralService(_globalIC);
    transferService = ITransferService(_transferService);
  }

  function setCurrentPool(address pool, StabilizedPool memory currentPool)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    StabilizedPool storage existingPool = stabilizedPools[pool];
    require(currentPool.pool != address(0), "Addr(0)");
    require(currentPool.pool == existingPool.pool, "Unknown pool");

    if (
      currentPool.updater != address(0) &&
      existingPool.updater != address(0) &&
      currentPool.updater != existingPool.updater
    ) {
      _transferRole(
        currentPool.updater,
        existingPool.updater,
        POOL_UPDATER_ROLE
      );
      existingPool.updater = currentPool.updater;
    }

    if (
      currentPool.core.impliedCollateralService != address(0) &&
      existingPool.core.impliedCollateralService != address(0) &&
      currentPool.core.impliedCollateralService !=
      existingPool.core.impliedCollateralService
    ) {
      globalIC.setPoolUpdater(pool, currentPool.core.impliedCollateralService);
    }

    if (
      currentPool.periphery.transferVerifier != address(0) &&
      existingPool.periphery.transferVerifier != address(0) &&
      currentPool.periphery.transferVerifier !=
      existingPool.periphery.transferVerifier
    ) {
      transferService.removeVerifier(pool);
      transferService.addVerifier(pool, currentPool.periphery.transferVerifier);
    }

    if (
      currentPool.core.auctionEscapeHatch != address(0) &&
      existingPool.core.auctionEscapeHatch != address(0) &&
      currentPool.core.auctionEscapeHatch !=
      existingPool.core.auctionEscapeHatch
    ) {
      Malt(malt).removeMinter(existingPool.core.auctionEscapeHatch);
      Malt(malt).addMinter(currentPool.core.auctionEscapeHatch);
    }

    if (
      currentPool.core.liquidityExtension != address(0) &&
      existingPool.core.liquidityExtension != address(0) &&
      currentPool.core.liquidityExtension !=
      existingPool.core.liquidityExtension
    ) {
      Malt(malt).removeBurner(existingPool.core.liquidityExtension);
      Malt(malt).addBurner(currentPool.core.liquidityExtension);
    }

    if (
      currentPool.core.stabilizerNode != address(0) &&
      existingPool.core.stabilizerNode != address(0) &&
      currentPool.core.stabilizerNode != existingPool.core.stabilizerNode
    ) {
      Malt(malt).removeMinter(existingPool.core.stabilizerNode);
      Malt(malt).addMinter(currentPool.core.stabilizerNode);
    }

    existingPool.core = currentPool.core;
    existingPool.staking = currentPool.staking;
    existingPool.rewardSystem = currentPool.rewardSystem;
    existingPool.periphery = currentPool.periphery;
  }

  function initializeStabilizedPool(
    address pool,
    string memory name,
    address collateralToken,
    address updater
  ) external onlyRoleMalt(ADMIN_ROLE, "Must have admin role") {
    require(pool != address(0), "addr(0)");
    require(collateralToken != address(0), "addr(0)");
    StabilizedPool storage currentPool = stabilizedPools[pool];
    require(currentPool.collateralToken == address(0), "already initialized");
    require(updater != address(0), "addr(0)");

    currentPool.collateralToken = collateralToken;
    currentPool.name = name;
    currentPool.updater = updater;
    currentPool.pool = pool;
    _setupRole(POOL_UPDATER_ROLE, updater);

    pools.push(pool);

    emit NewStabilizedPool(pool);
  }

  function setupUniv2StabilizedPool(address pool)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];
    require(currentPool.collateralToken != address(0), "Unknown pool");
    require(currentPool.updater != address(0), "updater");

    IStabilizedPoolUpdater(currentPool.updater).validatePoolDeployment(pool);

    _setup(pool);

    transferService.addVerifier(pool, currentPool.periphery.transferVerifier);
    Malt(malt).addMinter(currentPool.core.auctionEscapeHatch);
    Malt(malt).addMinter(currentPool.core.stabilizerNode);
    Malt(malt).addBurner(currentPool.core.liquidityExtension);
    globalIC.setPoolUpdater(pool, currentPool.core.impliedCollateralService);
  }

  function setTimekeeper(address _timekeeper)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_timekeeper != address(0), "addr(0)");

    Malt(malt).removeMinter(timekeeper);
    Malt(malt).addMinter(_timekeeper);

    timekeeper = _timekeeper;
    emit SetTimekeeper(_timekeeper);
  }

  function seedFromOldFactory(address pool, address oldFactory)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];
    require(currentPool.collateralToken == address(0), "already active");

    StabilizedPool memory oldPool = StabilizedPoolFactory(oldFactory)
      .getStabilizedPool(pool);
    require(oldPool.collateralToken != address(0), "Unknown pool");

    currentPool.name = oldPool.name;
    currentPool.collateralToken = oldPool.collateralToken;
    currentPool.updater = oldPool.updater;
    currentPool.core = oldPool.core;
    currentPool.staking = oldPool.staking;
    currentPool.rewardSystem = oldPool.rewardSystem;
    currentPool.periphery = oldPool.periphery;
  }

  function getStabilizedPool(address pool)
    external
    view
    returns (StabilizedPool memory)
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];
    return currentPool;
  }

  function getCoreContracts(address pool)
    external
    view
    returns (
      address auction,
      address auctionEscapeHatch,
      address impliedCollateralService,
      address liquidityExtension,
      address profitDistributor,
      address stabilizerNode,
      address swingTrader,
      address swingTraderManager
    )
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];

    return (
      currentPool.core.auction,
      currentPool.core.auctionEscapeHatch,
      currentPool.core.impliedCollateralService,
      currentPool.core.liquidityExtension,
      currentPool.core.profitDistributor,
      currentPool.core.stabilizerNode,
      currentPool.core.swingTrader,
      currentPool.core.swingTraderManager
    );
  }

  function getStakingContracts(address pool)
    external
    view
    returns (
      address bonding,
      address miningService,
      address vestedMine,
      address forfeitHandler,
      address linearMine,
      address reinvestor
    )
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];

    return (
      currentPool.staking.bonding,
      currentPool.staking.miningService,
      currentPool.staking.vestedMine,
      currentPool.staking.forfeitHandler,
      currentPool.staking.linearMine,
      currentPool.staking.reinvestor
    );
  }

  function getRewardSystemContracts(address pool)
    external
    view
    returns (
      address vestingDistributor,
      address linearDistributor,
      address rewardOverflow,
      address rewardThrottle
    )
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];

    return (
      currentPool.rewardSystem.vestingDistributor,
      currentPool.rewardSystem.linearDistributor,
      currentPool.rewardSystem.rewardOverflow,
      currentPool.rewardSystem.rewardThrottle
    );
  }

  function getPeripheryContracts(address pool)
    external
    view
    returns (
      address dataLab,
      address dexHandler,
      address transferVerifier,
      address keeper,
      address dualMA
    )
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];

    return (
      currentPool.periphery.dataLab,
      currentPool.periphery.dexHandler,
      currentPool.periphery.transferVerifier,
      currentPool.periphery.keeper,
      currentPool.periphery.dualMA
    );
  }

  function getPool(address pool)
    external
    view
    returns (
      address collateralToken,
      address updater,
      string memory name
    )
  {
    StabilizedPool storage currentPool = stabilizedPools[pool];

    return (currentPool.collateralToken, currentPool.updater, currentPool.name);
  }

  function _setup(address pool) internal {
    StabilizedPool storage currentPool = stabilizedPools[pool];
    address localGlobalIC = address(globalIC); // gas

    Auction(currentPool.core.auction).setupContracts(
      currentPool.collateralToken,
      currentPool.core.liquidityExtension,
      currentPool.core.stabilizerNode,
      currentPool.periphery.dataLab,
      currentPool.periphery.dexHandler,
      currentPool.core.auctionEscapeHatch,
      currentPool.core.profitDistributor,
      pool
    );
    AuctionEscapeHatch(currentPool.core.auctionEscapeHatch).setupContracts(
      malt,
      currentPool.collateralToken,
      currentPool.core.auction,
      currentPool.periphery.dexHandler,
      pool
    );
    ImpliedCollateralService(currentPool.core.impliedCollateralService)
      .setupContracts(
        currentPool.collateralToken,
        malt,
        pool,
        currentPool.core.auction,
        currentPool.rewardSystem.rewardOverflow,
        currentPool.core.swingTraderManager,
        currentPool.core.liquidityExtension,
        currentPool.periphery.dataLab,
        currentPool.core.stabilizerNode,
        localGlobalIC
      );
    LiquidityExtension(currentPool.core.liquidityExtension).setupContracts(
      currentPool.core.auction,
      currentPool.collateralToken,
      malt,
      currentPool.periphery.dexHandler,
      currentPool.periphery.dataLab,
      currentPool.core.swingTrader,
      pool
    );
    ProfitDistributor(currentPool.core.profitDistributor).setupContracts(
      malt,
      currentPool.collateralToken,
      localGlobalIC,
      currentPool.rewardSystem.rewardThrottle,
      currentPool.core.swingTrader,
      currentPool.core.liquidityExtension,
      currentPool.core.auction,
      currentPool.periphery.dataLab,
      currentPool.core.impliedCollateralService,
      pool
    );
    StabilizerNode(currentPool.core.stabilizerNode).setupContracts(
      malt,
      currentPool.collateralToken,
      currentPool.periphery.dexHandler,
      currentPool.periphery.dataLab,
      currentPool.core.impliedCollateralService,
      currentPool.core.auction,
      currentPool.core.swingTraderManager,
      currentPool.core.profitDistributor,
      pool
    );
    SwingTrader(currentPool.core.swingTrader).setupContracts(
      currentPool.collateralToken,
      malt,
      currentPool.periphery.dexHandler,
      currentPool.core.swingTraderManager,
      currentPool.periphery.dataLab,
      currentPool.core.profitDistributor,
      pool
    );
    SwingTraderManager(currentPool.core.swingTraderManager).setupContracts(
      currentPool.collateralToken,
      malt,
      currentPool.core.stabilizerNode,
      currentPool.periphery.dataLab,
      currentPool.core.swingTrader,
      currentPool.rewardSystem.rewardOverflow,
      pool
    );
    Bonding(currentPool.staking.bonding).setupContracts(
      malt,
      currentPool.collateralToken,
      pool,
      currentPool.staking.miningService,
      currentPool.periphery.dexHandler,
      currentPool.periphery.dataLab,
      currentPool.rewardSystem.vestingDistributor,
      currentPool.rewardSystem.linearDistributor
    );
    MiningService(currentPool.staking.miningService).setupContracts(
      currentPool.staking.reinvestor,
      currentPool.staking.bonding,
      currentPool.staking.vestedMine,
      currentPool.staking.linearMine,
      pool
    );
    ERC20VestedMine(currentPool.staking.vestedMine).setupContracts(
      currentPool.staking.miningService,
      currentPool.rewardSystem.vestingDistributor,
      currentPool.staking.bonding,
      currentPool.collateralToken,
      pool
    );
    ForfeitHandler(currentPool.staking.forfeitHandler).setupContracts(
      currentPool.collateralToken,
      currentPool.core.swingTrader,
      pool
    );
    RewardMineBase(currentPool.staking.linearMine).setupContracts(
      currentPool.staking.miningService,
      currentPool.rewardSystem.linearDistributor,
      currentPool.staking.bonding,
      currentPool.collateralToken,
      pool
    );
    RewardReinvestor(currentPool.staking.reinvestor).setupContracts(
      malt,
      currentPool.collateralToken,
      currentPool.periphery.dexHandler,
      currentPool.staking.bonding,
      pool,
      currentPool.staking.miningService
    );
    VestingDistributor(currentPool.rewardSystem.vestingDistributor)
      .setupContracts(
        currentPool.collateralToken,
        currentPool.staking.vestedMine,
        currentPool.rewardSystem.rewardThrottle,
        currentPool.staking.forfeitHandler,
        pool
      );
    LinearDistributor(currentPool.rewardSystem.linearDistributor)
      .setupContracts(
        currentPool.collateralToken,
        currentPool.staking.linearMine,
        currentPool.rewardSystem.rewardThrottle,
        currentPool.staking.forfeitHandler,
        currentPool.rewardSystem.vestingDistributor,
        pool
      );
    RewardOverflowPool(currentPool.rewardSystem.rewardOverflow).setupContracts(
      currentPool.collateralToken,
      malt,
      currentPool.periphery.dexHandler,
      currentPool.core.swingTraderManager,
      currentPool.periphery.dataLab,
      currentPool.core.profitDistributor,
      currentPool.rewardSystem.rewardThrottle,
      pool
    );
    RewardThrottle(currentPool.rewardSystem.rewardThrottle).setupContracts(
      currentPool.collateralToken,
      currentPool.rewardSystem.rewardOverflow,
      currentPool.staking.bonding,
      pool
    );
    MaltDataLab(currentPool.periphery.dataLab).setupContracts(
      malt,
      currentPool.collateralToken,
      pool,
      currentPool.periphery.dualMA,
      currentPool.periphery.swingTraderMaltRatioMA,
      currentPool.core.impliedCollateralService,
      currentPool.core.swingTraderManager,
      localGlobalIC,
      currentPool.periphery.keeper
    );

    address[] memory buyers = new address[](4);
    buyers[0] = currentPool.staking.reinvestor;
    buyers[1] = currentPool.core.swingTrader;
    buyers[2] = currentPool.rewardSystem.rewardOverflow;
    buyers[3] = currentPool.core.liquidityExtension;
    address[] memory sellers = new address[](4);
    sellers[0] = currentPool.core.auctionEscapeHatch;
    sellers[1] = currentPool.core.swingTrader;
    sellers[2] = currentPool.rewardSystem.rewardOverflow;
    sellers[3] = currentPool.core.stabilizerNode;
    address[] memory adders = new address[](1);
    adders[0] = currentPool.staking.reinvestor;
    address[] memory removers = new address[](1);
    removers[0] = currentPool.staking.bonding;

    IDexHandler(currentPool.periphery.dexHandler).setupContracts(
      malt,
      currentPool.collateralToken,
      pool,
      currentPool.periphery.dataLab,
      buyers,
      sellers,
      adders,
      removers
    );
    PoolTransferVerification(currentPool.periphery.transferVerifier)
      .setupContracts(
        currentPool.periphery.dataLab,
        pool,
        currentPool.periphery.dexHandler,
        currentPool.core.stabilizerNode
      );
    IKeeperCompatibleInterface(currentPool.periphery.keeper).setupContracts(
      currentPool.periphery.dataLab,
      currentPool.periphery.dexHandler,
      currentPool.rewardSystem.vestingDistributor,
      currentPool.rewardSystem.rewardThrottle,
      pool,
      currentPool.core.stabilizerNode,
      currentPool.core.auction,
      currentPool.core.swingTraderManager
    );
  }

  function proposeNewFactory(address pool, address _factory)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    StabilizedPool memory currentPool = stabilizedPools[pool];
    require(_factory != address(0), "Not addr(0)");
    require(currentPool.collateralToken != address(0), "Unknown pool");

    globalIC.proposeNewUpdaterManager(_factory);
    transferService.proposeNewVerifierManager(_factory);
    Malt(malt).proposeNewManager(_factory);
  }

  function acceptFactoryPosition(address pool)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    StabilizedPool memory currentPool = stabilizedPools[pool];
    require(currentPool.collateralToken != address(0), "Unknown pool");

    globalIC.acceptUpdaterManagerRole();
    transferService.acceptVerifierManagerRole();
    Malt(malt).acceptManagerRole();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IRepository.sol";

/// @title Permissions
/// @author 0xScotch <[email protected]>
/// @notice Inherited by almost all Malt contracts to provide access control
contract Permissions is AccessControl, ReentrancyGuard {
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE =
    0xf66846415d2bf9eabda9e84793ff9c0ea96d87f50fc41e66aa16469c6a442f05;
  bytes32 public constant ADMIN_ROLE =
    0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
  bytes32 public constant INTERNAL_WHITELIST_ROLE =
    0xe5b3f2579db3f05863c923698749c1a62f6272567d652899a476ff0172381367;

  IRepository public repository;

  function _initialSetup(address _repository) internal {
    require(_repository != address(0), "Perm: Repo setup 0x0");
    _setRoleAdmin(TIMELOCK_ROLE, TIMELOCK_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(INTERNAL_WHITELIST_ROLE, ADMIN_ROLE);

    repository = IRepository(_repository);
  }

  function grantRoleMultiple(bytes32 role, address[] calldata addresses)
    external
    onlyRoleMalt(getRoleAdmin(role), "Only role admin")
  {
    uint256 length = addresses.length;
    for (uint256 i; i < length; ++i) {
      address account = addresses[i];
      require(account != address(0), "0x0");
      _grantRole(role, account);
    }
  }

  function emergencyWithdrawGAS(address payable destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of the Gas token to destination
    (bool success, ) = destination.call{value: address(this).balance}("");
    require(success, "emergencyWithdrawGAS error");
  }

  function emergencyWithdraw(address _token, address destination)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    (bool success, ) = destination.call{value: amount}("");
    require(success, "partialWithdrawGAS error");
  }

  function partialWithdraw(
    address _token,
    address destination,
    uint256 amount
  ) external onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role") {
    require(destination != address(0), "Withdraw: addr(0)");
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  function hasRole(bytes32 role, address account)
    public
    view
    override
    returns (bool)
  {
    if (super.hasRole(role, account)) {
      return true;
    }

    if (address(repository) == address(0)) {
      return false;
    }
    return repository.hasRole(role, account);
  }

  /*
   * INTERNAL METHODS
   */
  function _transferRole(
    address newAccount,
    address oldAccount,
    bytes32 role
  ) internal {
    _revokeRole(role, oldAccount);
    _grantRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _grantRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRoleMalt(bytes32 role, string memory reason) internal view {
    require(hasRole(role, _msgSender()), reason);
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRoleMalt(bytes32 role, string memory reason) {
    _onlyRoleMalt(role, reason);
    _;
  }

  // verifies that the caller is not a contract.
  modifier onlyEOA() {
    require(
      hasRole(INTERNAL_WHITELIST_ROLE, _msgSender()) || msg.sender == tx.origin,
      "Perm: Only EOA"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct Core {
  address auction;
  address auctionEscapeHatch;
  address impliedCollateralService;
  address liquidityExtension;
  address profitDistributor;
  address stabilizerNode;
  address swingTrader;
  address swingTraderManager;
}

struct Staking {
  address bonding;
  address forfeitHandler;
  address linearMine;
  address miningService;
  address reinvestor;
  address vestedMine;
}

struct RewardSystem {
  address linearDistributor;
  address rewardOverflow;
  address rewardThrottle;
  address vestingDistributor;
}

struct Periphery {
  address dataLab;
  address dexHandler;
  address dualMA;
  address keeper;
  address swingTraderMaltRatioMA;
  address transferVerifier;
}

struct StabilizedPool {
  address collateralToken;
  Core core;
  string name;
  Periphery periphery;
  address pool;
  RewardSystem rewardSystem;
  Staking staking;
  address updater;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITransferService {
  function verifyTransfer(
    address,
    address,
    uint256
  )
    external
    view
    returns (
      bool,
      string memory,
      address[2] memory,
      bytes[2] memory
    );

  function verifyTransferAndCall(
    address,
    address,
    uint256
  ) external returns (bool, string memory);

  function numberOfVerifiers() external view returns (uint256);

  function addVerifier(address, address) external;

  function removeVerifier(address) external;

  function proposeNewVerifierManager(address) external;

  function acceptVerifierManagerRole() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StabilityPod/PoolCollateral.sol";

interface IGlobalImpliedCollateralService {
  function sync(PoolCollateral memory) external;

  function syncArbTokens(address, uint256) external;

  function totalPhantomMalt() external view returns (uint256);

  function totalCollateral() external view returns (uint256);

  function totalSwingTraderCollateral() external view returns (uint256);

  function totalSwingTraderMalt() external view returns (uint256);

  function totalArbTokens() external view returns (uint256);

  function collateralRatio() external view returns (uint256);

  function swingTraderCollateralRatio() external view returns (uint256);

  function swingTraderCollateralDeficit() external view returns (uint256);

  function setPoolUpdater(address, address) external;

  function proposeNewUpdaterManager(address) external;

  function acceptUpdaterManagerRole() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IStabilizedPoolUpdater {
  function validatePoolDeployment(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";

import "../interfaces/IDualMovingAverage.sol";
import "../interfaces/IMovingAverage.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../interfaces/IImpliedCollateralService.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";
import "../interfaces/ISwingTrader.sol";

import "../libraries/uniswap/IUniswapV2Pair.sol";
import "../libraries/SafeBurnMintableERC20.sol";
import "../libraries/uniswap/FixedPoint.sol";
import "../libraries/ABDKMath64x64.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/ImpliedCollateralServiceExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderManagerExtension.sol";
import "../StabilizedPoolExtensions/GlobalICExtension.sol";

/// @title Malt Data Lab
/// @author 0xScotch <[email protected]>
/// @notice The central source of all of Malt protocol's internal data needs
/// @dev Over time usage of MovingAverage will likely be replaced with more reliable oracles
contract MaltDataLab is
  StabilizedPoolUnit,
  ImpliedCollateralServiceExtension,
  SwingTraderManagerExtension,
  GlobalICExtension
{
  using FixedPoint for *;
  using ABDKMath64x64 for *;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  bytes32 public immutable UPDATER_ROLE;

  // The dual values will be the pool price and the square root of the invariant k
  IDualMovingAverage public poolMA;
  IMovingAverage public ratioMA;

  uint256 public priceTarget = 10**18; // $1
  uint256 public maltPriceLookback = 10 minutes;
  uint256 public reserveLookback = 15 minutes;
  uint256 public kLookback = 30 minutes;
  uint256 public maltRatioLookback = 4 hours;

  uint256 public z = 20;
  uint256 public swingTraderLowBps = 1000; // 10%
  uint256 public auctionLowBps = 7000; // 70%
  uint256 public breakpointBps = 5000; // 50%

  uint256 public maltPriceCumulativeLast;
  uint256 public maltPriceTimestampLast;

  event TrackPool(uint256 price, uint256 rootK);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    UPDATER_ROLE = 0x73e573f9566d61418a34d5de3ff49360f9c51fec37f7486551670290f6285dab;
  }

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _stakeToken,
    address _poolMA,
    address _ratioMA,
    address _impliedCollateralService,
    address _swingTraderManager,
    address _globalIC,
    address _trustedUpdater
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(!contractActive, "MaltDataLab: Already setup");
    require(_malt != address(0), "MaltDataLab: Malt addr(0)");
    require(_collateralToken != address(0), "MaltDataLab: Col addr(0)");
    require(_stakeToken != address(0), "MaltDataLab: LP Token addr(0)");
    require(_poolMA != address(0), "MaltDataLab: PoolMA addr(0)");
    require(
      _impliedCollateralService != address(0),
      "MaltDataLab: ImpColSvc addr(0)"
    );
    require(
      _swingTraderManager != address(0),
      "MaltDataLab: STManager addr(0)"
    );
    require(_globalIC != address(0), "MaltDataLab: GlobalIC addr(0)");
    require(_ratioMA != address(0), "MaltDataLab: RatioMA addr(0)");

    contractActive = true;

    _roleSetup(UPDATER_ROLE, _trustedUpdater);

    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
    stakeToken = IUniswapV2Pair(_stakeToken);
    poolMA = IDualMovingAverage(_poolMA);
    impliedCollateralService = IImpliedCollateralService(
      _impliedCollateralService
    );
    swingTraderManager = ISwingTrader(_swingTraderManager);
    globalIC = IGlobalImpliedCollateralService(_globalIC);
    ratioMA = IMovingAverage(_ratioMA);

    (, address updater, ) = poolFactory.getPool(_stakeToken);
    _setPoolUpdater(updater);
  }

  function smoothedMaltPrice() public view returns (uint256 price) {
    (price, ) = poolMA.getValueWithLookback(maltPriceLookback);
  }

  function smoothedK() public view returns (uint256) {
    (, uint256 rootK) = poolMA.getValueWithLookback(kLookback);
    return rootK * rootK;
  }

  function smoothedReserves()
    public
    view
    returns (uint256 maltReserves, uint256 collateralReserves)
  {
    // Malt reserves = sqrt(k / malt price)
    (uint256 price, uint256 rootK) = poolMA.getValueWithLookback(
      reserveLookback
    );
    uint256 unity = 10**collateralToken.decimals();

    // maltReserves = sqrt(k * 1 / price);
    maltReserves = Babylonian.sqrt((rootK * rootK * unity) / price);
    collateralReserves = (maltReserves * price) / unity;
  }

  function smoothedMaltRatio() public view returns (uint256) {
    return ratioMA.getValueWithLookback(maltRatioLookback);
  }

  function maltPriceAverage(uint256 _lookback)
    public
    view
    returns (uint256 price)
  {
    (price, ) = poolMA.getValueWithLookback(_lookback);
  }

  function kAverage(uint256 _lookback) public view returns (uint256) {
    (, uint256 rootK) = poolMA.getValueWithLookback(_lookback);
    return rootK * rootK;
  }

  function poolReservesAverage(uint256 _lookback)
    public
    view
    returns (uint256 maltReserves, uint256 collateralReserves)
  {
    // Malt reserves = sqrt(k / malt price)
    (uint256 price, uint256 rootK) = poolMA.getValueWithLookback(_lookback);

    uint256 unity = 10**collateralToken.decimals();

    // maltReserves = sqrt(k * 1 / price);
    maltReserves = Babylonian.sqrt((rootK * rootK * unity) / price);
    collateralReserves = (maltReserves * price) / unity;
  }

  function lastMaltPrice()
    public
    view
    returns (uint256 price, uint64 timestamp)
  {
    (timestamp, , , , , price, ) = poolMA.getLiveSample();
  }

  function lastPoolReserves()
    public
    view
    returns (
      uint256 maltReserves,
      uint256 collateralReserves,
      uint64 timestamp
    )
  {
    // Malt reserves = sqrt(k / malt price)
    (uint64 timestamp, , , , , uint256 price, uint256 rootK) = poolMA
      .getLiveSample();

    uint256 unity = 10**collateralToken.decimals();

    // maltReserves = sqrt(k * 1 / price);
    maltReserves = Babylonian.sqrt((rootK * rootK * unity) / price);
    collateralReserves = (maltReserves * price) / unity;
  }

  function lastK() public view returns (uint256 kLast, uint64 timestamp) {
    // Malt reserves = sqrt(k / malt price)
    (uint64 timestamp, , , , , , uint256 rootK) = poolMA.getLiveSample();

    kLast = rootK * rootK;
  }

  function realValueOfLPToken(uint256 amount) external view returns (uint256) {
    (uint256 maltPrice, uint256 rootK) = poolMA.getValueWithLookback(
      reserveLookback
    );

    uint256 unity = 10**collateralToken.decimals();

    // TODO MaltDataLab.sol will this work with other decimals? Sat 22 Oct 2022 18:44:07 BST

    // maltReserves = sqrt(k * 1 / price);
    uint256 maltReserves = Babylonian.sqrt((rootK * rootK * unity) / maltPrice);
    uint256 collateralReserves = (maltReserves * maltPrice) / unity;

    if (maltReserves == 0) {
      return 0;
    }

    uint256 totalLPSupply = stakeToken.totalSupply();

    uint256 maltValue = (amount * maltReserves) / totalLPSupply;
    uint256 rewardValue = (amount * collateralReserves) / totalLPSupply;

    return rewardValue + ((maltValue * maltPrice) / unity);
  }

  function getRealBurnBudget(uint256 maxBurnSpend, uint256 premiumExcess)
    external
    view
    returns (uint256)
  {
    if (maxBurnSpend > premiumExcess) {
      uint256 diff = maxBurnSpend - premiumExcess;

      int128 stMaltRatioInt = ABDKMath64x64
        .fromUInt(swingTraderManager.calculateSwingTraderMaltRatio())
        .div(ABDKMath64x64.fromUInt(10**collateralToken.decimals()))
        .mul(ABDKMath64x64.fromUInt(100));
      int128 purchaseParityInt = ABDKMath64x64.fromUInt(z);

      if (stMaltRatioInt >= purchaseParityInt) {
        return maxBurnSpend;
      }

      uint256 bps = stMaltRatioInt
        .div(purchaseParityInt)
        .mul(ABDKMath64x64.fromUInt(10000))
        .toUInt();
      uint256 additional = (diff * bps) / 10000;

      return premiumExcess + additional;
    }

    return maxBurnSpend;
  }

  function maltToRewardDecimals(uint256 maltAmount)
    public
    view
    returns (uint256)
  {
    uint256 rewardDecimals = collateralToken.decimals();
    uint256 maltDecimals = malt.decimals();

    if (rewardDecimals == maltDecimals) {
      return maltAmount;
    } else if (rewardDecimals > maltDecimals) {
      uint256 diff = rewardDecimals - maltDecimals;
      return maltAmount * (10**diff);
    } else {
      uint256 diff = maltDecimals - rewardDecimals;
      return maltAmount / (10**diff);
    }
  }

  function rewardToMaltDecimals(uint256 amount) public view returns (uint256) {
    uint256 rewardDecimals = collateralToken.decimals();
    uint256 maltDecimals = malt.decimals();

    if (rewardDecimals == maltDecimals) {
      return amount;
    } else if (rewardDecimals > maltDecimals) {
      uint256 diff = rewardDecimals - maltDecimals;
      return amount / (10**diff);
    } else {
      uint256 diff = maltDecimals - rewardDecimals;
      return amount * (10**diff);
    }
  }

  /*
   * Public mutation methods
   */
  function trackPool() external onlyActive returns (bool) {
    (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast) = stakeToken
      .getReserves();

    if (blockTimestampLast < maltPriceTimestampLast) {
      // stale data
      return false;
    }

    uint256 kLast = reserve0 * reserve1;

    uint256 rootK = Babylonian.sqrt(kLast);

    uint256 price;
    uint256 priceCumulative;

    if (address(malt) < address(collateralToken)) {
      priceCumulative = stakeToken.price0CumulativeLast();
    } else {
      priceCumulative = stakeToken.price1CumulativeLast();
    }

    if (
      blockTimestampLast > maltPriceTimestampLast &&
      maltPriceCumulativeLast != 0
    ) {
      uint256 priceDelta;
      unchecked {
        priceDelta = priceCumulative - maltPriceCumulativeLast;
      }
      price = FixedPoint
        .uq112x112(
          uint224(priceDelta / (blockTimestampLast - maltPriceTimestampLast))
        )
        .mul(priceTarget)
        .decode144();
    } else if (
      maltPriceCumulativeLast > 0 && priceCumulative == maltPriceCumulativeLast
    ) {
      (, , , , , price, ) = poolMA.getLiveSample();
    }

    if (price != 0) {
      // Use rootK to slow down growth of cumulativeValue
      poolMA.update(price, rootK);
      emit TrackPool(price, rootK);
    }

    maltPriceCumulativeLast = priceCumulative;
    maltPriceTimestampLast = blockTimestampLast;

    return true;
  }

  function getSwingTraderEntryPrice()
    external
    view
    returns (uint256 stEntryPrice)
  {
    /*
     * Note that in this method there are two separate units in play
     *
     * 1. Values from other contracts are uint256 denominated in collateralToken.decimals()
     * 2. int128 values are ABDKMath64x64 values. These can be thought of as regular decimals
     *
     * This means that all the values denominated in collateralToken.decimals need to be divided by
     * that decimal value to turn them into "real" decimals. This is why the conversion between
     * the two always contains a "unityInt" value (either division when going to 64x64 and
     * multiplication when going to collateralToken.decimal() value)
     */

    /*
     * Get all the values we need
     */
    uint256 unity = 10**collateralToken.decimals();
    uint256 icTotal = maltToRewardDecimals(globalIC.collateralRatio());

    if (icTotal == 0) {
      return 0;
    }

    if (icTotal >= unity) {
      // No need to do math here. Just return priceTarget
      return priceTarget;
    }

    uint256 stMaltRatio = swingTraderManager.calculateSwingTraderMaltRatio();
    uint256 swingTraderBottomPrice = (icTotal * (10000 - swingTraderLowBps)) /
      10000;

    /*
     * Convert all to 64x64
     */
    int128 unityInt = ABDKMath64x64.fromUInt(unity);
    int128 icTotalInt = ABDKMath64x64.fromUInt(icTotal).div(unityInt);
    int128 stMaltRatioInt = ABDKMath64x64
      .fromUInt(stMaltRatio)
      .div(unityInt)
      .mul(ABDKMath64x64.fromUInt(100));
    int128 oneInt = ABDKMath64x64.fromUInt(1);
    int128 swingTraderBottomPriceInt = ABDKMath64x64
      .fromUInt(swingTraderBottomPrice)
      .div(unityInt);

    /*
     * Do all the math (all these values are in 64x64)
     */
    int128 decayRate;
    {
      // to avoid stack to deep error

      int128 lnSwingTraderBottomDelta = ABDKMath64x64.ln(
        icTotalInt.sub(swingTraderBottomPriceInt)
      );
      int128 lnTradingHeadroom = ABDKMath64x64.ln(
        oneInt.sub(swingTraderBottomPriceInt)
      );
      int128 purchaseParityInt = ABDKMath64x64.fromUInt(z);
      decayRate = ABDKMath64x64.div(
        lnSwingTraderBottomDelta.sub(lnTradingHeadroom),
        purchaseParityInt
      );
    }

    int128 cooefficient = ABDKMath64x64.sub(oneInt, swingTraderBottomPriceInt);
    int128 exponent = decayRate.mul(stMaltRatioInt);

    int128 stEntryPriceInt = cooefficient.mul(ABDKMath64x64.exp(exponent)).add(
      swingTraderBottomPriceInt
    );

    // Convert back to collateralToken.decimals and return the value
    return stEntryPriceInt.mul(ABDKMath64x64.fromUInt(priceTarget)).toUInt();
  }

  function getActualPriceTarget() external view returns (uint256) {
    uint256 unity = 10**collateralToken.decimals();
    uint256 icTotal = maltToRewardDecimals(globalIC.collateralRatio());

    if (icTotal > unity) {
      icTotal = unity;
    }

    /*
     * Convert all to 64x64
     */
    int128 unityInt = ABDKMath64x64.fromUInt(unity);
    int128 icTotalInt = ABDKMath64x64.fromUInt(icTotal).div(unityInt);
    int128 stMaltRatioInt = ABDKMath64x64
      .fromUInt(smoothedMaltRatio())
      .div(unityInt)
      .mul(ABDKMath64x64.fromUInt(100));
    int128 purchaseParityInt = ABDKMath64x64.fromUInt(z);
    int128 breakpointInt = ABDKMath64x64.div(
      ABDKMath64x64.mul(
        purchaseParityInt,
        ABDKMath64x64.fromUInt(breakpointBps)
      ),
      ABDKMath64x64.fromUInt(10000)
    );
    int128 oneInt = ABDKMath64x64.fromUInt(1);

    int128 m = (icTotalInt.sub(oneInt)).div(
      purchaseParityInt.sub(breakpointInt)
    );

    int128 actualTarget64 = (
      oneInt.add(m.mul(stMaltRatioInt)).sub(m.mul(breakpointInt))
    );

    uint256 localTarget = priceTarget; // gas

    if (actualTarget64.toInt() < 0) {
      return (icTotal * localTarget) / unity;
    }

    uint256 actualTarget = actualTarget64.mul(unityInt).toUInt();
    uint256 normActualTarget = (actualTarget * localTarget) / unity;

    if (normActualTarget > localTarget) {
      return localTarget;
    } else if (actualTarget < icTotal && icTotal < localTarget) {
      return (icTotal * localTarget) / unity;
    }

    return normActualTarget;
  }

  function trackSwingTraderMaltRatio() external {
    uint256 maltRatio = swingTraderManager.calculateSwingTraderMaltRatio();
    ratioMA.update(maltRatio);
  }

  /*
   * PRIVILEDGED METHODS
   */
  function trustedTrackPool(
    uint256 price,
    uint256 rootK,
    uint256 priceCumulative,
    uint256 blockTimestampLast
  ) external onlyRoleMalt(UPDATER_ROLE, "Must have updater role") {
    require(
      priceCumulative >= maltPriceCumulativeLast,
      "trustedTrackPool: priceCumulative"
    );

    if (price != 0) {
      poolMA.update(price, rootK);
      emit TrackPool(price, rootK);
    }

    maltPriceCumulativeLast = priceCumulative;
    maltPriceTimestampLast = blockTimestampLast;
  }

  function trustedTrackMaltRatio(uint256 maltRatio)
    external
    onlyRoleMalt(UPDATER_ROLE, "Must have updater role")
  {
    ratioMA.update(maltRatio);
  }

  function setPriceTarget(uint256 _price)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_price > 0, "Cannot have 0 price");
    _setPriceTarget(_price);
  }

  // This will get used when price target is set dynamically via external oracle
  function _setPriceTarget(uint256 _price) internal {
    priceTarget = _price;
    impliedCollateralService.syncGlobalCollateral();
  }

  function setMaltPriceLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_lookback > 0, "Cannot have 0 lookback");
    maltPriceLookback = _lookback;
  }

  function setReserveLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_lookback > 0, "Cannot have 0 lookback");
    reserveLookback = _lookback;
  }

  function setKLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_lookback > 0, "Cannot have 0 lookback");
    kLookback = _lookback;
  }

  function setMaltRatioLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_lookback > 0, "Cannot have 0 lookback");
    maltRatioLookback = _lookback;
  }

  function setMaltPoolAverageContract(address _poolMA)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_poolMA != address(0), "Cannot use 0 address");
    poolMA = IDualMovingAverage(_poolMA);
  }

  function setMaltRatioAverageContract(address _ratioMA)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_ratioMA != address(0), "Cannot use 0 address");
    ratioMA = IMovingAverage(_ratioMA);
  }

  function setZ(uint256 _z)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_z != 0, "Cannot have 0 for Z");
    require(_z <= 100, "Cannot be over 100");
    z = _z;
  }

  function setSwingTraderLowBps(uint256 _swingTraderLowBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_swingTraderLowBps != 0, "Cannot have 0 Swing Trader Low BPS");
    require(
      _swingTraderLowBps <= 10000,
      "Cannot have a Swing Trader Low BPS greater than 10,000"
    );
    swingTraderLowBps = _swingTraderLowBps;
  }

  function setBreakpointBps(uint256 _breakpointBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_breakpointBps != 0, "Cannot have 0 breakpoint BPS");
    require(_breakpointBps < 10000, "Cannot have a breakpoint BPS >= 10,000");
    breakpointBps = _breakpointBps;
  }

  function _accessControl()
    internal
    override(
      ImpliedCollateralServiceExtension,
      SwingTraderManagerExtension,
      GlobalICExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";
import "../interfaces/ISwingTrader.sol";
import "../interfaces/IMaltDataLab.sol";

struct SwingTraderData {
  uint256 id;
  uint256 index; // index into the activeTraders array
  address traderContract;
  string name;
  bool active;
}

/// @title Swing Trader Manager
/// @author 0xScotch <[email protected]>
/// @notice The contract simply orchestrates SwingTrader instances. Initially there will only be a single
/// Swing Trader. But over time there may be others with different strategies that can be balanced / orchestrated
/// by this contract.
contract SwingTraderManager is
  StabilizedPoolUnit,
  ISwingTrader,
  DataLabExtension,
  StabilizerNodeExtension
{
  using SafeERC20 for ERC20;

  bytes32 public immutable CAPITAL_DELEGATE_ROLE;

  mapping(uint256 => SwingTraderData) public swingTraders;
  mapping(address => bool) public existingTraderContracts;
  uint256[] public activeTraders;
  uint256 public totalProfit;
  uint256 public dustThreshold = 1e18; // $1

  event ToggleTraderActive(uint256 traderId, bool active);
  event AddSwingTrader(
    uint256 traderId,
    string name,
    bool active,
    address swingTrader
  );
  event Delegation(uint256 amount, address destination, address delegate);
  event BuyMalt(uint256 capitalUsed);
  event SellMalt(uint256 amountSold, uint256 profit);
  event SetDustThreshold(uint256 threshold);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    CAPITAL_DELEGATE_ROLE = 0x6b525fb9eaf138d3dc2ac8323126c54cad39e34e800f9605cb60df858920b17b;
    _roleSetup(
      0x6b525fb9eaf138d3dc2ac8323126c54cad39e34e800f9605cb60df858920b17b,
      timelock
    );
  }

  function setupContracts(
    address _collateralToken,
    address _malt,
    address _stabilizerNode,
    address _maltDataLab,
    address _swingTrader,
    address _rewardOverflow,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "SwingTraderManager: Already setup");
    require(
      _collateralToken != address(0),
      "SwingTraderManager: ColToken addr(0)"
    );
    require(_malt != address(0), "SwingTraderManager: Malt addr(0)");
    require(
      _stabilizerNode != address(0),
      "SwingTraderManager: StabNode addr(0)"
    );
    require(
      _maltDataLab != address(0),
      "SwingTraderManager: MaltDataLab addr(0)"
    );
    require(
      _swingTrader != address(0),
      "SwingTraderManager: SwingTrader addr(0)"
    );
    require(
      _rewardOverflow != address(0),
      "SwingTraderManager: Overflow addr(0)"
    );

    contractActive = true;

    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    maltDataLab = IMaltDataLab(_maltDataLab);
    stabilizerNode = IStabilizerNode(_stabilizerNode);

    // Internal SwingTrader
    swingTraders[1] = SwingTraderData({
      id: 1,
      index: 0,
      traderContract: _swingTrader,
      name: "CoreSwingTrader",
      active: true
    });
    activeTraders.push(1);
    existingTraderContracts[_swingTrader] = true;

    // RewardOverflow is secondary swing trader
    swingTraders[2] = SwingTraderData({
      id: 2,
      index: 1,
      traderContract: _rewardOverflow,
      name: "CoreSwingTrader",
      active: true
    });
    existingTraderContracts[_rewardOverflow] = true;

    activeTraders.push(2);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function _beforeSetStabilizerNode(address _stabilizerNode) internal override {
    _transferRole(
      _stabilizerNode,
      address(stabilizerNode),
      STABILIZER_NODE_ROLE
    );
  }

  function buyMalt(uint256 maxCapital)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must have stabilizer node privs")
    onlyActive
    returns (uint256 capitalUsed)
  {
    if (maxCapital == 0) {
      return 0;
    }
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;

    uint256 totalCapital;
    uint256[] memory traderCapital = new uint256[](length);

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];

      if (!trader.active) {
        continue;
      }

      uint256 traderBalance = collateralToken.balanceOf(trader.traderContract);
      totalCapital += traderBalance;
      traderCapital[i] = traderBalance;
    }

    if (totalCapital == 0) {
      return 0;
    }

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      uint256 share = (maxCapital * traderCapital[i]) / totalCapital;

      if (share == 0) {
        continue;
      }

      uint256 used = ISwingTrader(trader.traderContract).buyMalt(share);
      capitalUsed += used;

      if (capitalUsed >= maxCapital) {
        break;
      }
    }

    emit BuyMalt(capitalUsed);

    return capitalUsed;
  }

  function sellMalt(uint256 maxAmount)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must have stabilizer node privs")
    onlyActive
    returns (uint256 amountSold)
  {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;
    uint256 profit;

    uint256 totalMalt;
    uint256[] memory traderMalt = new uint256[](length);

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];

      if (!trader.active) {
        continue;
      }

      uint256 traderMaltBalance = malt.balanceOf(trader.traderContract);
      totalMalt += traderMaltBalance;
      traderMalt[i] = traderMaltBalance;
    }

    if (totalMalt == 0) {
      return 0;
    }

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      uint256 share = (maxAmount * traderMalt[i]) / totalMalt;

      if (share == 0) {
        continue;
      }

      uint256 initialProfit = ISwingTrader(trader.traderContract).totalProfit();
      try ISwingTrader(trader.traderContract).sellMalt(share) returns (
        uint256 sold
      ) {
        uint256 finalProfit = ISwingTrader(trader.traderContract).totalProfit();
        profit += (finalProfit - initialProfit);
        amountSold += sold;
      } catch {
        // if it fails just continue
      }

      if (amountSold >= maxAmount) {
        break;
      }
    }

    totalProfit += profit;
    emit SellMalt(amountSold, profit);

    if (amountSold + dustThreshold >= maxAmount) {
      return maxAmount;
    }
  }

  function costBasis() public view returns (uint256 cost, uint256 decimals) {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;
    decimals = collateralToken.decimals();

    uint256 totalMaltBalance;
    uint256 totalDeployedCapital;

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      totalDeployedCapital += ISwingTrader(trader.traderContract)
        .deployedCapital();
      totalMaltBalance += malt.balanceOf(trader.traderContract);
    }

    if (totalDeployedCapital == 0 || totalMaltBalance == 0) {
      return (0, decimals);
    }

    totalMaltBalance = maltDataLab.maltToRewardDecimals(totalMaltBalance);

    return (
      (totalDeployedCapital * (10**decimals)) / totalMaltBalance,
      decimals
    );
  }

  function calculateSwingTraderMaltRatio()
    public
    view
    returns (uint256 maltRatio)
  {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;
    uint256 decimals = collateralToken.decimals();
    uint256 maltDecimals = malt.decimals();
    uint256 totalMaltBalance;
    uint256 totalCollateralBalance;

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      totalMaltBalance += malt.balanceOf(trader.traderContract);
      totalCollateralBalance += collateralToken.balanceOf(
        trader.traderContract
      );
    }

    totalMaltBalance = maltDataLab.maltToRewardDecimals(totalMaltBalance);

    uint256 stMaltValue = ((totalMaltBalance * maltDataLab.priceTarget()) /
      (10**decimals));

    uint256 netBalance = totalCollateralBalance + stMaltValue;

    if (netBalance > 0) {
      maltRatio = ((stMaltValue * (10**decimals)) / netBalance);
    } else {
      maltRatio = 0;
    }
  }

  function getTokenBalances()
    external
    view
    returns (uint256 maltBalance, uint256 collateralBalance)
  {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      maltBalance += malt.balanceOf(trader.traderContract);
      collateralBalance += collateralToken.balanceOf(trader.traderContract);
    }
  }

  function delegateCapital(uint256 amount, address destination)
    external
    onlyRoleMalt(CAPITAL_DELEGATE_ROLE, "Must have capital delegation privs")
    onlyActive
  {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;

    uint256 totalCapital;
    uint256[] memory traderCapital = new uint256[](length);

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];

      if (!trader.active) {
        continue;
      }

      uint256 traderBalance = collateralToken.balanceOf(trader.traderContract);
      totalCapital += traderBalance;
      traderCapital[i] = traderBalance;
    }

    if (totalCapital == 0) {
      return;
    }

    uint256 capitalUsed;

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      uint256 share = (amount * traderCapital[i]) / totalCapital;

      if (capitalUsed + share > amount) {
        share = amount - capitalUsed;
      }

      if (share == 0) {
        continue;
      }

      capitalUsed += share;
      ISwingTrader(trader.traderContract).delegateCapital(share, destination);
    }

    emit Delegation(amount, destination, msg.sender);
  }

  function deployedCapital() external view returns (uint256 deployed) {
    uint256[] memory traderIds = activeTraders;
    uint256 length = traderIds.length;

    for (uint256 i; i < length; ++i) {
      SwingTraderData memory trader = swingTraders[activeTraders[i]];
      deployed += ISwingTrader(trader.traderContract).deployedCapital();
    }

    return deployed;
  }

  function addSwingTrader(
    uint256 traderId,
    address _swingTrader,
    bool active,
    string calldata name
  ) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    SwingTraderData storage trader = swingTraders[traderId];
    require(traderId > 2 && trader.id == 0, "TraderId already used");
    require(_swingTrader != address(0), "addr(0)");
    require(!existingTraderContracts[_swingTrader], "Trader already exists");

    swingTraders[traderId] = SwingTraderData({
      id: traderId,
      index: active ? activeTraders.length : 0,
      traderContract: _swingTrader,
      name: name,
      active: active
    });
    existingTraderContracts[_swingTrader] = true;

    if (active) {
      activeTraders.push(traderId);
    }

    emit AddSwingTrader(traderId, name, active, _swingTrader);
  }

  function toggleTraderActive(uint256 traderId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    SwingTraderData storage trader = swingTraders[traderId];
    require(trader.id == traderId, "Unknown trader");

    bool active = !trader.active;
    trader.active = active;

    if (active) {
      // setting it to active so add to activeTraders
      trader.index = activeTraders.length;
      activeTraders.push(traderId);
    } else {
      // Becoming inactive so remove from activePools
      uint256 index = trader.index;
      uint256 lastTrader = activeTraders[activeTraders.length - 1];

      activeTraders[index] = lastTrader;
      activeTraders.pop();

      swingTraders[lastTrader].index = index;
      trader.index = 0;
    }

    emit ToggleTraderActive(traderId, active);
  }

  function setDustThreshold(uint256 _dust)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    dustThreshold = _dust;
    emit SetDustThreshold(_dust);
  }

  function _accessControl()
    internal
    override(DataLabExtension, StabilizerNodeExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderManagerExtension.sol";
import "../StabilizedPoolExtensions/LiquidityExtensionExtension.sol";
import "../StabilizedPoolExtensions/RewardOverflowExtension.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";
import "../StabilizedPoolExtensions/GlobalICExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IOverflow.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../interfaces/ISwingTrader.sol";
import "../interfaces/ILiquidityExtension.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IStabilizerNode.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";
import "../libraries/uniswap/IUniswapV2Pair.sol";
import "./PoolCollateral.sol";

/// @title Implied Collateral Service
/// @author 0xScotch <[email protected]>
/// @notice A contract that provides an abstraction above individual implied collateral sources
contract ImpliedCollateralService is
  StabilizedPoolUnit,
  DataLabExtension,
  SwingTraderManagerExtension,
  LiquidityExtensionExtension,
  RewardOverflowExtension,
  AuctionExtension,
  GlobalICExtension,
  StabilizerNodeExtension
{
  using SafeERC20 for ERC20;

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {}

  function setupContracts(
    address _collateralToken,
    address _malt,
    address _stakeToken,
    address _auction,
    address _rewardOverflow,
    address _swingTraderManager,
    address _liquidityExtension,
    address _maltDataLab,
    address _stabilizerNode,
    address _globalIC
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "ImpCol: Already setup");
    require(_auction != address(0), "ImpCol: Auction addr(0)");
    require(_rewardOverflow != address(0), "ImpCol: Overflow addr(0)");
    require(_swingTraderManager != address(0), "ImpCol: Swing addr(0)");
    require(_liquidityExtension != address(0), "ImpCol: LE addr(0)");
    require(_maltDataLab != address(0), "ImpCol: DataLab addr(0)");
    require(_stabilizerNode != address(0), "ImpCol: StablizerNode addr(0)");
    require(_globalIC != address(0), "ImpCol: GlobalIC addr(0)");
    require(_collateralToken != address(0), "ImpCol: ColToken addr(0)");
    require(_malt != address(0), "ImpCol: Malt addr(0)");
    require(_stakeToken != address(0), "ImpCol: Stake Token addr(0)");

    contractActive = true;

    auction = IAuction(_auction);
    overflowPool = IOverflow(_rewardOverflow);
    swingTraderManager = ISwingTrader(_swingTraderManager);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    maltDataLab = IMaltDataLab(_maltDataLab);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    globalIC = IGlobalImpliedCollateralService(_globalIC);
    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    stakeToken = IUniswapV2Pair(_stakeToken);

    (, address updater, ) = poolFactory.getPool(_stakeToken);
    _setPoolUpdater(updater);
  }

  function syncGlobalCollateral() public onlyActive {
    globalIC.sync(getCollateralizedMalt());
  }

  function getCollateralizedMalt() public view returns (PoolCollateral memory) {
    uint256 target = maltDataLab.priceTarget();

    uint256 unity = 10**collateralToken.decimals();

    // Convert all balances to be denominated in units of Malt target price
    uint256 overflowBalance = maltDataLab.rewardToMaltDecimals(
      (collateralToken.balanceOf(address(overflowPool)) * unity) / target
    );
    uint256 liquidityExtensionBalance = (collateralToken.balanceOf(
      address(liquidityExtension)
    ) * unity) / target;
    (
      uint256 swingTraderMaltBalance,
      uint256 swingTraderBalance
    ) = swingTraderManager.getTokenBalances();
    swingTraderBalance = (swingTraderBalance * unity) / target;

    return
      PoolCollateral({
        lpPool: address(stakeToken),
        // Note that swingTraderBalance also includes the overflowBalance
        // Therefore the total doesn't need to include overflowBalance explicitly
        total: maltDataLab.rewardToMaltDecimals(
          liquidityExtensionBalance + swingTraderBalance
        ),
        rewardOverflow: overflowBalance,
        liquidityExtension: maltDataLab.rewardToMaltDecimals(
          liquidityExtensionBalance
        ),
        // This swingTraderBalance value isn't just the capital in the swingTrader
        // contract but also includes what is in the overflow so we subtract that
        swingTrader: maltDataLab.rewardToMaltDecimals(swingTraderBalance) -
          overflowBalance,
        swingTraderMalt: swingTraderMaltBalance,
        arbTokens: maltDataLab.rewardToMaltDecimals(
          (auction.unclaimedArbTokens() * unity) / target
        )
      });
  }

  function totalUsefulCollateral() public view returns (uint256 collateral) {
    uint256 liquidityExtensionBalance = collateralToken.balanceOf(
      address(liquidityExtension)
    );
    (, uint256 swingTraderBalances) = swingTraderManager.getTokenBalances();

    return liquidityExtensionBalance + swingTraderBalances;
  }

  function collateralRatio() external view returns (uint256 icTotal) {
    uint256 decimals = collateralToken.decimals();
    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();

    uint256 maltInPool = address(malt) < address(collateralToken)
      ? maltDataLab.maltToRewardDecimals(reserve0)
      : maltDataLab.maltToRewardDecimals(reserve1);

    icTotal = ((totalUsefulCollateral() * (10**decimals)) / maltInPool);
  }

  function swingTraderCollateralRatio()
    external
    view
    returns (uint256 icTotal)
  {
    uint256 decimals = collateralToken.decimals();
    uint256 overflowBalance = collateralToken.balanceOf(address(overflowPool));

    // SwingTraderManager will return balance in swing trader as well as overflow
    // So we need to subtract the overflow balance from the swingTraderBalance
    (, uint256 swingTraderBalance) = swingTraderManager.getTokenBalances();
    swingTraderBalance = swingTraderBalance - overflowBalance;

    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();

    uint256 maltInPool = address(malt) < address(collateralToken)
      ? maltDataLab.maltToRewardDecimals(reserve0)
      : maltDataLab.maltToRewardDecimals(reserve1);

    icTotal = ((swingTraderBalance * (10**decimals)) / maltInPool);
  }

  function _accessControl()
    internal
    override(
      DataLabExtension,
      SwingTraderManagerExtension,
      LiquidityExtensionExtension,
      RewardOverflowExtension,
      AuctionExtension,
      GlobalICExtension,
      StabilizerNodeExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/Pausable.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/ProfitDistributorExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderManagerExtension.sol";
import "../StabilizedPoolExtensions/ImpliedCollateralServiceExtension.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/ITimekeeper.sol";
import "../interfaces/IRewardThrottle.sol";
import "../interfaces/IImpliedCollateralService.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/ISwingTrader.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../interfaces/ISupplyDistributionController.sol";
import "../interfaces/IAuctionStartController.sol";
import "../interfaces/IProfitDistributor.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";

/// @title Stabilizer Node
/// @author 0xScotch <[email protected]>
/// @notice The backbone of the Malt stability system. In charge of triggering actions to stabilize price
contract StabilizerNode is
  StabilizedPoolUnit,
  AuctionExtension,
  DexHandlerExtension,
  DataLabExtension,
  ProfitDistributorExtension,
  SwingTraderManagerExtension,
  ImpliedCollateralServiceExtension,
  Pausable
{
  using SafeERC20 for ERC20;

  uint256 internal stabilizeWindowEnd;
  uint256 public stabilizeBackoffPeriod = 5 * 60; // 5 minutes
  uint256 public upperStabilityThresholdBps = 100; // 1%
  uint256 public lowerStabilityThresholdBps = 100;
  uint256 public priceAveragePeriod = 5 minutes;
  uint256 public fastAveragePeriod = 30; // 30 seconds
  uint256 public overrideDistanceBps = 200; // 2%
  uint256 public callerRewardCutBps = 30; // 0.3%

  uint256 public expansionDampingFactor = 1;

  uint256 public defaultIncentive = 100; // in Malt
  uint256 public trackingIncentive = 20; // in 100ths of a Malt

  uint256 public upperBandLimitBps = 100000; // 1000%
  uint256 public lowerBandLimitBps = 1000; // 10%
  uint256 public sampleSlippageBps = 2000; // 20%
  uint256 public skipAuctionThreshold;
  uint256 public preferAuctionThreshold;

  uint256 public lastStabilize;
  uint256 public lastTracking;
  uint256 public trackingBackoff = 30; // 30 seconds
  uint256 public primedBlock;
  uint256 public primedWindow = 10; // blocks

  bool internal trackAfterStabilize = true;
  bool public onlyStabilizeToPeg = false;
  bool public usePrimedWindow;

  address public supplyDistributionController;
  address public auctionStartController;

  event MintMalt(uint256 amount);
  event Stabilize(uint256 timestamp, uint256 exchangeRate);
  event SetStabilizeBackoff(uint256 period);
  event SetDefaultIncentive(uint256 incentive);
  event SetTrackingIncentive(uint256 incentive);
  event SetExpansionDamping(uint256 amount);
  event SetPriceAveragePeriod(uint256 period);
  event SetOverrideDistance(uint256 distance);
  event SetFastAveragePeriod(uint256 period);
  event SetStabilityThresholds(uint256 upper, uint256 lower);
  event SetSupplyDistributionController(address _controller);
  event SetAuctionStartController(address _controller);
  event SetBandLimits(uint256 _upper, uint256 _lower);
  event SetSlippageBps(uint256 _slippageBps);
  event SetSkipAuctionThreshold(uint256 _skipAuctionThreshold);
  event SetEmergencyMintThresholdBps(uint256 thresholdBps);
  event SetTrackingBackoff(uint256 backoff);
  event SetCallerCut(uint256 callerCutBps);
  event SetPreferAuctionThreshold(uint256 preferAuctionThreshold);
  event SetTrackAfterStabilize(bool track);
  event SetOnlyStabilizeToPeg(bool stabilize);
  event SetPrimedWindow(uint256 primedWindow);
  event SetUsePrimedWindow(bool usePrimedWindow);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _skipAuctionThreshold,
    uint256 _preferAuctionThreshold
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    skipAuctionThreshold = _skipAuctionThreshold;
    preferAuctionThreshold = _preferAuctionThreshold;

    lastStabilize = block.timestamp;
  }

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _dexHandler,
    address _maltDataLab,
    address _impliedCollateralService,
    address _auction,
    address _swingTraderManager,
    address _profitDistributor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "StabilizerNode: Already setup");
    require(_malt != address(0), "StabilizerNode: Malt addr(0)");
    require(_collateralToken != address(0), "StabilizerNode: Col addr(0)");
    require(_dexHandler != address(0), "StabilizerNode: DexHandler addr(0)");
    require(_maltDataLab != address(0), "StabilizerNode: DataLab addr(0)");
    require(
      _swingTraderManager != address(0),
      "StabilizerNode: Swing Manager addr(0)"
    );
    require(
      _impliedCollateralService != address(0),
      "StabilizerNode: ImpCol addr(0)"
    );
    require(_auction != address(0), "StabilizerNode: Auction addr(0)");
    require(
      _profitDistributor != address(0),
      "StabilizerNode: ProfitDistributor addr(0)"
    );

    contractActive = true;

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    dexHandler = IDexHandler(_dexHandler);
    maltDataLab = IMaltDataLab(_maltDataLab);
    swingTraderManager = ISwingTrader(_swingTraderManager);
    impliedCollateralService = IImpliedCollateralService(
      _impliedCollateralService
    );
    auction = IAuction(_auction);
    profitDistributor = IProfitDistributor(_profitDistributor);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function stabilize() external nonReentrant onlyEOA onlyActive whenNotPaused {
    // Ensure data consistency
    maltDataLab.trackPool();
    lastTracking = block.timestamp;

    // Finalize auction if possible before potentially starting a new one
    auction.checkAuctionFinalization();
    // Ensure global IC data is live
    impliedCollateralService.syncGlobalCollateral();

    require(
      block.timestamp >= stabilizeWindowEnd || _stabilityWindowOverride(),
      "Can't call stabilize"
    );
    stabilizeWindowEnd = block.timestamp + stabilizeBackoffPeriod;

    // used in 3 location.
    uint256 exchangeRate = maltDataLab.maltPriceAverage(priceAveragePeriod);
    bool stabilizeToPeg = onlyStabilizeToPeg; // gas
    (bool shouldAdjust, uint256 priceTarget) = _shouldAdjustSupply(
      exchangeRate,
      stabilizeToPeg
    );

    if (!shouldAdjust) {
      lastStabilize = block.timestamp;
      impliedCollateralService.syncGlobalCollateral();
      return;
    }

    emit Stabilize(block.timestamp, exchangeRate);

    (uint256 livePrice, ) = dexHandler.maltMarketPrice();

    // The upper and lower bands here avoid any issues with price
    // descrepency between the TWAP and live market price.
    // This avoids starting auctions too quickly into a big selloff
    // and also reduces risk of flashloan vectors
    address sender = _msgSender();
    if (exchangeRate > priceTarget) {
      if (
        !hasRole(ADMIN_ROLE, sender) &&
        !hasRole(INTERNAL_WHITELIST_ROLE, sender)
      ) {
        uint256 upperBand = exchangeRate +
          ((exchangeRate * upperBandLimitBps) / 10000);
        uint256 latestSample = maltDataLab.maltPriceAverage(0);
        require(
          latestSample > priceTarget,
          "Stabilize: Latest sample < target"
        );
        uint256 minThreshold = latestSample -
          (((latestSample - priceTarget) * sampleSlippageBps) / 10000);

        require(livePrice < upperBand, "Stabilize: Beyond upper bound");
        require(livePrice > minThreshold, "Stabilize: Slippage threshold");
      }

      _distributeSupply(livePrice, priceTarget, stabilizeToPeg);
    } else {
      if (
        !hasRole(ADMIN_ROLE, sender) &&
        !hasRole(INTERNAL_WHITELIST_ROLE, sender)
      ) {
        uint256 lowerBand = exchangeRate -
          ((exchangeRate * lowerBandLimitBps) / 10000);
        require(livePrice > lowerBand, "Stabilize: Beyond lower bound");
      }

      uint256 stEntryPrice = maltDataLab.getSwingTraderEntryPrice();
      if (exchangeRate <= stEntryPrice) {
        if (_validateSwingTraderTrigger(livePrice, stEntryPrice)) {
          // Reset primedBlock
          primedBlock = 0;
          _triggerSwingTrader(priceTarget, livePrice);
        }
      } else {
        _startAuction(priceTarget);
      }
    }

    if (trackAfterStabilize) {
      maltDataLab.trackPool();
    }
    impliedCollateralService.syncGlobalCollateral();
    lastStabilize = block.timestamp;
  }

  function endAuctionEarly() external onlyActive whenNotPaused {
    // This call reverts if the auction isn't ended
    auction.endAuctionEarly();

    // It hasn't reverted so the auction was ended. Pay the incentive
    malt.mint(msg.sender, defaultIncentive * (10**malt.decimals()));
    emit MintMalt(defaultIncentive * (10**malt.decimals()));
  }

  function trackPool() external onlyActive {
    require(block.timestamp >= lastTracking + trackingBackoff, "Too early");
    bool success = maltDataLab.trackPool();
    require(success, "Too early");
    malt.mint(msg.sender, (trackingIncentive * (10**malt.decimals())) / 100); // div 100 because units are cents
    lastTracking = block.timestamp;
  }

  function primedWindowData() public view returns (bool, uint256) {
    return (usePrimedWindow, primedBlock + primedWindow);
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _stabilityWindowOverride() internal view returns (bool) {
    address sender = _msgSender();
    if (
      hasRole(ADMIN_ROLE, sender) || hasRole(INTERNAL_WHITELIST_ROLE, sender)
    ) {
      // Admin can always stabilize
      return true;
    }
    // Must have elapsed at least one period of the moving average before we stabilize again
    if (block.timestamp < lastStabilize + fastAveragePeriod) {
      return false;
    }

    uint256 priceTarget = maltDataLab.getActualPriceTarget();
    uint256 exchangeRate = maltDataLab.maltPriceAverage(fastAveragePeriod);

    uint256 upperThreshold = (priceTarget * (10000 + overrideDistanceBps)) /
      10000;

    return exchangeRate >= upperThreshold;
  }

  function _shouldAdjustSupply(uint256 exchangeRate, bool stabilizeToPeg)
    internal
    view
    returns (bool, uint256)
  {
    uint256 priceTarget;

    if (stabilizeToPeg) {
      priceTarget = maltDataLab.priceTarget();
    } else {
      priceTarget = maltDataLab.getActualPriceTarget();
    }

    uint256 upperThreshold = (priceTarget * upperStabilityThresholdBps) / 10000;
    uint256 lowerThreshold = (priceTarget * lowerStabilityThresholdBps) / 10000;

    return (
      (exchangeRate <= (priceTarget - lowerThreshold) &&
        !auction.auctionExists(auction.currentAuctionId())) ||
        exchangeRate >= (priceTarget + upperThreshold),
      priceTarget
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _validateSwingTraderTrigger(uint256 livePrice, uint256 entryPrice)
    internal
    returns (bool)
  {
    if (usePrimedWindow) {
      if (livePrice > entryPrice) {
        return false;
      }

      if (block.number > primedBlock + primedWindow) {
        primedBlock = block.number;
        malt.mint(msg.sender, defaultIncentive * (10**malt.decimals()));
        emit MintMalt(defaultIncentive * (10**malt.decimals()));
        return false;
      }

      if (primedBlock == block.number) {
        return false;
      }
    }

    return true;
  }

  function _triggerSwingTrader(uint256 priceTarget, uint256 exchangeRate)
    internal
  {
    uint256 decimals = collateralToken.decimals();
    uint256 unity = 10**decimals;
    IGlobalImpliedCollateralService globalIC = maltDataLab.globalIC();
    uint256 icTotal = maltDataLab.maltToRewardDecimals(
      globalIC.collateralRatio()
    );

    if (icTotal >= unity) {
      icTotal = unity;
    }

    uint256 originalPriceTarget = priceTarget;

    if (exchangeRate < icTotal) {
      priceTarget = icTotal;
    }

    uint256 purchaseAmount = dexHandler.calculateBurningTradeSize(priceTarget);

    if (purchaseAmount > preferAuctionThreshold) {
      uint256 capitalUsed = swingTraderManager.buyMalt(purchaseAmount);

      uint256 callerCut = (capitalUsed * callerRewardCutBps) / 10000;

      if (callerCut != 0) {
        malt.mint(msg.sender, callerCut);
        emit MintMalt(callerCut);
      }
    } else {
      _startAuction(originalPriceTarget);
    }
  }

  function _distributeSupply(
    uint256 livePrice,
    uint256 priceTarget,
    bool stabilizeToPeg
  ) internal {
    if (supplyDistributionController != address(0)) {
      bool success = ISupplyDistributionController(supplyDistributionController)
        .check();
      if (!success) {
        return;
      }
    }

    uint256 pegPrice = maltDataLab.priceTarget();

    uint256 lowerThreshold = (pegPrice * lowerStabilityThresholdBps) / 10000;
    if (stabilizeToPeg || livePrice >= pegPrice - lowerThreshold) {
      priceTarget = pegPrice;
    }

    uint256 tradeSize = dexHandler.calculateMintingTradeSize(priceTarget) /
      expansionDampingFactor;

    if (tradeSize == 0) {
      return;
    }

    uint256 swingAmount = swingTraderManager.sellMalt(tradeSize);

    if (swingAmount >= tradeSize) {
      return;
    }

    tradeSize = tradeSize - swingAmount;

    malt.mint(address(dexHandler), tradeSize);
    emit MintMalt(tradeSize);
    // Transfer verification ensure any attempt to
    // sandwhich will trigger stabilize first
    uint256 rewards = dexHandler.sellMalt(tradeSize, 10000);

    uint256 callerCut = (rewards * callerRewardCutBps) / 10000;

    if (callerCut != 0) {
      rewards -= callerCut;
      collateralToken.safeTransfer(msg.sender, callerCut);
    }

    collateralToken.safeTransfer(address(profitDistributor), rewards);

    profitDistributor.handleProfit(rewards);
  }

  function _startAuction(uint256 priceTarget) internal {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController)
        .checkForStart();
      if (!success) {
        return;
      }
    }

    uint256 purchaseAmount = dexHandler.calculateBurningTradeSize(priceTarget);

    if (purchaseAmount < skipAuctionThreshold) {
      return;
    }

    bool success = auction.triggerAuction(priceTarget, purchaseAmount);

    if (success) {
      malt.mint(msg.sender, defaultIncentive * (10**malt.decimals()));
      emit MintMalt(defaultIncentive * (10**malt.decimals()));
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */

  function setStabilizeBackoff(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Must be greater than 0");
    stabilizeBackoffPeriod = _period;
    emit SetStabilizeBackoff(_period);
  }

  function setDefaultIncentive(uint256 _incentive)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_incentive != 0 && _incentive <= 1000, "Incentive out of range");

    defaultIncentive = _incentive;

    emit SetDefaultIncentive(_incentive);
  }

  function setTrackingIncentive(uint256 _incentive)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    // Priced in cents. Must be less than 1000 Malt
    require(_incentive != 0 && _incentive <= 100000, "Incentive out of range");

    trackingIncentive = _incentive;

    emit SetTrackingIncentive(_incentive);
  }

  /// @notice Only callable by Admin address.
  /// @dev Sets the Expansion Damping units.
  /// @param amount: Amount to set Expansion Damping units to.
  function setExpansionDamping(uint256 amount)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(amount > 0, "No negative damping");

    expansionDampingFactor = amount;
    emit SetExpansionDamping(amount);
  }

  function setStabilityThresholds(uint256 _upper, uint256 _lower)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_upper != 0 && _lower != 0, "Must be above 0");
    require(_lower < 10000, "Lower to large");

    upperStabilityThresholdBps = _upper;
    lowerStabilityThresholdBps = _lower;
    emit SetStabilityThresholds(_upper, _lower);
  }

  function setSupplyDistributionController(address _controller)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    supplyDistributionController = _controller;
    emit SetSupplyDistributionController(_controller);
  }

  function setAuctionStartController(address _controller)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setPriceAveragePeriod(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    priceAveragePeriod = _period;
    emit SetPriceAveragePeriod(_period);
  }

  function setOverrideDistance(uint256 _distance)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(
      _distance != 0 && _distance < 10000,
      "Override must be between 0-100%"
    );
    overrideDistanceBps = _distance;
    emit SetOverrideDistance(_distance);
  }

  function setFastAveragePeriod(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    fastAveragePeriod = _period;
    emit SetFastAveragePeriod(_period);
  }

  function setBandLimits(uint256 _upper, uint256 _lower)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_upper != 0 && _lower != 0, "Cannot have 0 band limit");
    upperBandLimitBps = _upper;
    lowerBandLimitBps = _lower;
    emit SetBandLimits(_upper, _lower);
  }

  function setSlippageBps(uint256 _slippageBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_slippageBps <= 10000, "slippage: Must be <= 100%");
    sampleSlippageBps = _slippageBps;
    emit SetSlippageBps(_slippageBps);
  }

  function setSkipAuctionThreshold(uint256 _skipAuctionThreshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    skipAuctionThreshold = _skipAuctionThreshold;
    emit SetSkipAuctionThreshold(_skipAuctionThreshold);
  }

  function setPreferAuctionThreshold(uint256 _preferAuctionThreshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    preferAuctionThreshold = _preferAuctionThreshold;
    emit SetPreferAuctionThreshold(_preferAuctionThreshold);
  }

  function setTrackingBackoff(uint256 _backoff)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_backoff != 0, "Cannot be 0");
    trackingBackoff = _backoff;
    emit SetTrackingBackoff(_backoff);
  }

  function setTrackAfterStabilize(bool _track)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    trackAfterStabilize = _track;
    emit SetTrackAfterStabilize(_track);
  }

  function setOnlyStabilizeToPeg(bool _stabilize)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    onlyStabilizeToPeg = _stabilize;
    emit SetOnlyStabilizeToPeg(_stabilize);
  }

  function setCallerCut(uint256 _callerCut)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_callerCut <= 1000, "Must be less than 10%");
    callerRewardCutBps = _callerCut;
    emit SetCallerCut(_callerCut);
  }

  function togglePause()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function setPrimedWindow(uint256 _primedWindow)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_primedWindow != 0, "Cannot be 0");
    primedWindow = _primedWindow;
    emit SetPrimedWindow(_primedWindow);
  }

  function setUsePrimedWindow(bool _usePrimedWindow)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    usePrimedWindow = _usePrimedWindow;
    emit SetUsePrimedWindow(_usePrimedWindow);
  }

  function _accessControl()
    internal
    override(
      AuctionExtension,
      DexHandlerExtension,
      DataLabExtension,
      ProfitDistributorExtension,
      SwingTraderManagerExtension,
      ImpliedCollateralServiceExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRewardThrottle.sol";
import "../interfaces/ILiquidityExtension.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";
import "../interfaces/IImpliedCollateralService.sol";
import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/LiquidityExtensionExtension.sol";
import "../StabilizedPoolExtensions/RewardThrottleExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderExtension.sol";
import "../StabilizedPoolExtensions/ImpliedCollateralServiceExtension.sol";
import "../StabilizedPoolExtensions/GlobalICExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";

/// @title Profit Distributor
/// @author 0xScotch <[email protected]>
/// @notice Any profit generated by the pool is pushed here and then sent to where it needs to go
contract ProfitDistributor is
  StabilizedPoolUnit,
  LiquidityExtensionExtension,
  RewardThrottleExtension,
  SwingTraderExtension,
  ImpliedCollateralServiceExtension,
  GlobalICExtension,
  DataLabExtension,
  AuctionExtension
{
  using SafeERC20 for ERC20;

  address public dao;
  address payable public treasury;

  uint256 public daoRewardCutBps;
  uint256 public distributeBps = 9200; // 92%
  uint256 public swingTraderPreferenceBps = 8000; // 80% to ST when pool is underperforming
  uint256 public lpThrottleBps = 2500; // 25%

  uint256 public maxLEContributionBps = 7000;

  event SetDaoCut(uint256 daoCut);
  event SetDao(address dao);
  event RewardDistribution(
    uint256 swingTraderCut,
    uint256 lpCut,
    uint256 daoCut,
    uint256 treasuryCut
  );
  event SetTreasury(address newTreasury);
  event SetMaxContribution(uint256 maxContribution);
  event SetLpThrottleBps(uint256 bps);
  event SetSwingTraderPreferenceBps(uint256 bps);
  event SetDistributeBps(uint256 bps);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address _dao,
    address payable _treasury
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    require(_treasury != address(0), "StabilizerNode: Treasury addr(0)");
    require(_dao != address(0), "StabilizerNode: DAO addr(0)");

    treasury = _treasury;
    dao = _dao;
  }

  /// @notice Admin only method that can only be called once and will set up all the initial contract properties
  /// @param _malt The address of an instance of Malt token
  /// @param _collateralToken The address of an instance of Collateral Token ERC20
  /// @param _globalIC The address of an instance of GlobalImpliedCollateralService
  /// @param _rewardThrottle The address of an instance of RewardThrottle
  /// @param _swingTrader The address of an instance of SwingTrader
  /// @param _liquidityExtension The address of an instance of LiquidityExtension
  /// @param _auction The address of an instance of Auction
  /// @param _maltDataLab The address of an instance of MaltDataLab
  /// @param _impliedCollateralService The address of an instance of ImpliedCollateralService
  function setupContracts(
    address _malt,
    address _collateralToken,
    address _globalIC,
    address _rewardThrottle,
    address _swingTrader,
    address _liquidityExtension,
    address _auction,
    address _maltDataLab,
    address _impliedCollateralService,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "StabilizerNode: Already setup");
    require(_malt != address(0), "ProfitDist: Malt addr(0)");
    require(_collateralToken != address(0), "ProfitDist: Reward addr(0)");
    require(_globalIC != address(0), "ProfitDist: GlobalIC addr(0)");
    require(_rewardThrottle != address(0), "StabilizerNode: Throttle addr(0)");
    require(_swingTrader != address(0), "StabilizerNode: Swing addr(0)");
    require(_liquidityExtension != address(0), "StabilizerNode: LE addr(0)");
    require(_auction != address(0), "StabilizerNode: Auction addr(0)");
    require(_maltDataLab != address(0), "StabilizerNode: MaltDataLab addr(0)");
    require(
      _impliedCollateralService != address(0),
      "StabilizerNode: ImpColSvc addr(0)"
    );

    contractActive = true;

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    globalIC = IGlobalImpliedCollateralService(_globalIC);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    swingTrader = ISwingTrader(_swingTrader);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    auction = IAuction(_auction);
    maltDataLab = IMaltDataLab(_maltDataLab);
    impliedCollateralService = IImpliedCollateralService(
      _impliedCollateralService
    );

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  /// @notice Handles distributing collateralToken profit to LPs etc
  /// @param profit The amount of profit to be distributed
  /// @dev It is assumed that the profit is sent here first before handleProfit is called. The balance is verified before proceeding
  function handleProfit(uint256 profit) external onlyActive {
    uint256 balance = collateralToken.balanceOf(address(this));
    require(profit <= balance, "ProfitDist: Insufficient balance");

    _distributeProfit(profit);
  }

  function _distributeProfit(uint256 rewarded) internal {
    if (rewarded == 0) {
      return;
    }
    rewarded = _replenishLiquidityExtension(rewarded);
    if (rewarded == 0) {
      return;
    }
    // Ensure starting at 0
    collateralToken.safeApprove(address(auction), 0);
    collateralToken.safeApprove(address(auction), rewarded);
    rewarded = auction.allocateArbRewards(rewarded);
    // Reset approval
    collateralToken.safeApprove(address(auction), 0);

    if (rewarded == 0) {
      return;
    }

    uint256 distributeCut = (rewarded * distributeBps) / 10000;
    uint256 daoCut = (distributeCut * daoRewardCutBps) / 10000;
    distributeCut -= daoCut;

    // globaIC value comes back in malt.decimals(). Convert to collateralToken.decimals
    uint256 globalSwingTraderDeficit = (maltDataLab.maltToRewardDecimals(
      globalIC.swingTraderCollateralDeficit()
    ) * maltDataLab.priceTarget()) / (10**collateralToken.decimals());

    // this is already in collateralToken.decimals()
    uint256 lpCut;
    uint256 swingTraderCut;

    if (globalSwingTraderDeficit == 0) {
      lpCut = distributeCut;
    } else {
      uint256 runwayDeficit = rewardThrottle.runwayDeficit();

      if (runwayDeficit == 0) {
        swingTraderCut = distributeCut;
      } else {
        uint256 totalDeficit = runwayDeficit + globalSwingTraderDeficit;

        uint256 globalSwingTraderRatio = maltDataLab.maltToRewardDecimals(
          globalIC.swingTraderCollateralRatio()
        );

        // Already in collateralToken.decimals
        uint256 poolSwingTraderRatio = impliedCollateralService
          .swingTraderCollateralRatio();

        if (poolSwingTraderRatio < globalSwingTraderRatio) {
          swingTraderCut = (distributeCut * swingTraderPreferenceBps) / 10000;
          lpCut = distributeCut - swingTraderCut;
        } else {
          lpCut =
            (((distributeCut * runwayDeficit) / totalDeficit) *
              (10000 - lpThrottleBps)) /
            10000;
          swingTraderCut = distributeCut - lpCut;
        }
      }
    }

    // Treasury gets paid after everyone else
    uint256 treasuryCut = rewarded - daoCut - lpCut - swingTraderCut;

    assert(treasuryCut <= rewarded);

    if (swingTraderCut > 0) {
      collateralToken.safeTransfer(address(swingTrader), swingTraderCut);
    }

    if (treasuryCut > 0) {
      collateralToken.safeTransfer(treasury, treasuryCut);
    }

    if (daoCut > 0) {
      collateralToken.safeTransfer(dao, daoCut);
    }

    if (lpCut > 0) {
      collateralToken.safeTransfer(address(rewardThrottle), lpCut);
      rewardThrottle.handleReward();
    }

    emit RewardDistribution(swingTraderCut, lpCut, daoCut, treasuryCut);
  }

  function _replenishLiquidityExtension(uint256 rewards)
    internal
    returns (uint256 remaining)
  {
    if (rewards == 0) {
      return rewards;
    }

    (uint256 deficit, ) = liquidityExtension.collateralDeficit();

    if (deficit == 0) {
      return rewards;
    }

    uint256 maxContrib = (rewards * maxLEContributionBps) / 10000;

    if (deficit >= maxContrib) {
      collateralToken.safeTransfer(address(liquidityExtension), maxContrib);
      return rewards - maxContrib;
    }

    collateralToken.safeTransfer(address(liquidityExtension), deficit);

    return rewards - deficit;
  }

  /// @notice Admin only method for setting the cut of profit that goes to the DAO
  /// @param _daoCut The % of profit to be sent to the DAO. Denominated in basis points ie 100 = 1%
  function setDaoCut(uint256 _daoCut)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_daoCut <= 10000, "Reward cut must be <= 100%");
    daoRewardCutBps = _daoCut;

    emit SetDaoCut(_daoCut);
  }

  /// @notice Admin only method for setting the preference for sending to swing trader when local pool collateral ratio is less than global ratio
  /// @param _pref The % of profit to be sent to SwingTrader. Represented in basis points ie 100 = 1%
  function setSwingTraderPreferenceBps(uint256 _pref)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_pref <= 10000, "Must be <= 100%");
    swingTraderPreferenceBps = _pref;

    emit SetSwingTraderPreferenceBps(_pref);
  }

  /// @notice Admin only method for setting the amount LP share of profit should be throttled
  /// @dev The lp throttle is used to skew system in favor of replenishing SwingTrader when all else is equal
  /// @param _bps The % of LP profit that should be throttled represented in basis points ie 100 = 1%
  function setLpThrottleBps(uint256 _bps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_bps <= 10000, "Must be <= 100%");
    lpThrottleBps = _bps;

    emit SetLpThrottleBps(_bps);
  }

  /// @notice Admin only method for setting the amount of profit that should be distributed vs retained for protocol development
  /// @param _bps The % of profit that should be distributed represented in basis points ie 100 = 1%
  function setDistributeBps(uint256 _bps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_bps <= 10000, "Must be <= 100%");
    distributeBps = _bps;

    emit SetDistributeBps(_bps);
  }

  /// @notice Admin only method for setting max % of profit that can be used to replenish LiquidityExtension
  /// @param _maxContribution The % of profit that can be used represented in basis points ie 100 = 1%
  function setMaxLEContribution(uint256 _maxContribution)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(
      _maxContribution != 0 && _maxContribution <= 10000,
      "Must be between 0 and 100"
    );

    maxLEContributionBps = _maxContribution;
    emit SetMaxContribution(_maxContribution);
  }

  /*
   * Contract Pointers
   */
  /// @notice Admin only method for setting the address of the Malt DAO
  /// @param _dao The contract address of the Malt DAO
  function setDAO(address _dao)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    require(_dao != address(0), "Not address 0");
    dao = _dao;
    emit SetDao(_dao);
  }

  /// @notice Admin only method for setting the address of the treasury
  /// @param _newTreasury The address of the treasury multisig
  function setTreasury(address payable _newTreasury)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    treasury = _newTreasury;
    emit SetTreasury(_newTreasury);
  }

  function _accessControl()
    internal
    override(
      LiquidityExtensionExtension,
      RewardThrottleExtension,
      SwingTraderExtension,
      ImpliedCollateralServiceExtension,
      GlobalICExtension,
      DataLabExtension,
      AuctionExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../libraries/uniswap/Babylonian.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/SwingTraderExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IBurnMintableERC20.sol";

/// @title Liquidity Extension
/// @author 0xScotch <[email protected]>
/// @notice In charge of facilitating a premium with net supply contraction during auctions
contract LiquidityExtension is
  StabilizedPoolUnit,
  SwingTraderExtension,
  DexHandlerExtension,
  DataLabExtension,
  AuctionExtension
{
  using SafeERC20 for ERC20;

  uint256 public minReserveRatioBps = 2500; // 25%

  event SetMinReserveRatio(uint256 ratio);
  event BurnMalt(uint256 purchased);
  event AllocateBurnBudget(uint256 amount);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {}

  function setupContracts(
    address _auction,
    address _collateralToken,
    address _malt,
    address _dexHandler,
    address _maltDataLab,
    address _swingTrader,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "LE: Already setup");
    require(_auction != address(0), "LE: Auction addr(0)");
    require(_collateralToken != address(0), "LE: Col addr(0)");
    require(_malt != address(0), "LE: Malt addr(0)");
    require(_dexHandler != address(0), "LE: DexHandler addr(0)");
    require(_maltDataLab != address(0), "LE: DataLab addr(0)");
    require(_swingTrader != address(0), "LE: SwingTrader addr(0)");

    contractActive = true;

    _setupRole(AUCTION_ROLE, _auction);

    auction = IAuction(_auction);
    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    dexHandler = IDexHandler(_dexHandler);
    maltDataLab = IMaltDataLab(_maltDataLab);
    swingTrader = ISwingTrader(_swingTrader);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  /*
   * PUBLIC VIEW METHODS
   */
  function hasMinimumReserves() public view returns (bool) {
    (uint256 rRatio, uint256 decimals) = reserveRatio();
    return rRatio >= (minReserveRatioBps * (10**decimals)) / 10000;
  }

  function collateralDeficit()
    public
    view
    returns (uint256 deficit, uint256 decimals)
  {
    // Returns the amount of collateral token required to reach minimum reserves
    // Returns 0 if liquidity extension contains minimum reserves.
    uint256 balance = collateralToken.balanceOf(address(this));
    uint256 collateralDecimals = collateralToken.decimals();

    uint256 k = maltDataLab.smoothedK();

    if (k == 0) {
      (k, ) = maltDataLab.lastK();
      if (k == 0) {
        return (0, collateralDecimals);
      }
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    uint256 fullCollateral = Babylonian.sqrt(
      (k * (10**collateralDecimals)) / priceTarget
    );

    uint256 minReserves = (fullCollateral * minReserveRatioBps) / 10000;

    if (minReserves > balance) {
      return (minReserves - balance, collateralDecimals);
    }

    return (0, collateralDecimals);
  }

  function reserveRatio() public view returns (uint256, uint256) {
    uint256 balance = collateralToken.balanceOf(address(this));
    uint256 collateralDecimals = collateralToken.decimals();

    uint256 k = maltDataLab.smoothedK();

    if (k == 0) {
      return (0, collateralDecimals);
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    uint256 fullCollateral = Babylonian.sqrt(
      (k * (10**collateralDecimals)) / priceTarget
    );

    uint256 rRatio = (balance * (10**collateralDecimals)) / fullCollateral;
    return (rRatio, collateralDecimals);
  }

  function reserveRatioAverage(uint256 lookback)
    public
    view
    returns (uint256, uint256)
  {
    uint256 balance = collateralToken.balanceOf(address(this));
    uint256 collateralDecimals = collateralToken.decimals();

    uint256 k = maltDataLab.kAverage(lookback);
    uint256 priceTarget = maltDataLab.priceTarget();

    uint256 fullCollateral = Babylonian.sqrt(
      (k * (10**collateralDecimals)) / priceTarget
    );

    uint256 rRatio = (balance * (10**collateralDecimals)) / fullCollateral;
    return (rRatio, collateralDecimals);
  }

  /*
   * PRIVILEDGED METHODS
   */
  function purchaseAndBurn(uint256 amount)
    external
    onlyRoleMalt(AUCTION_ROLE, "Must have auction privs")
    onlyActive
    returns (uint256 purchased)
  {
    require(
      collateralToken.balanceOf(address(this)) >= amount,
      "LE: Insufficient balance"
    );
    collateralToken.safeTransfer(address(dexHandler), amount);
    purchased = dexHandler.buyMalt(amount, 10000); // 100% allowable slippage
    malt.burn(address(this), purchased);

    emit BurnMalt(purchased);
  }

  function allocateBurnBudget(uint256 amount)
    external
    onlyRoleMalt(AUCTION_ROLE, "Must have auction privs")
    onlyActive
    returns (uint256 purchased)
  {
    // Send the burnable amount to the swing trader so it can be used to burn more malt if required
    require(
      collateralToken.balanceOf(address(this)) >= amount,
      "LE: Insufficient balance"
    );
    collateralToken.safeTransfer(address(swingTrader), amount);

    emit AllocateBurnBudget(amount);
  }

  function setMinReserveRatio(uint256 _ratio)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_ratio != 0 && _ratio <= 10000, "Must be between 0 and 100");
    minReserveRatioBps = _ratio;
    emit SetMinReserveRatio(_ratio);
  }

  function _accessControl()
    internal
    override(
      SwingTraderExtension,
      DexHandlerExtension,
      DataLabExtension,
      AuctionExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../libraries/uniswap/IUniswapV2Router02.sol";
import "../libraries/uniswap/Babylonian.sol";
import "../libraries/uniswap/FullMath.sol";
import "../libraries/SafeBurnMintableERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../libraries/UniswapV2Library.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/IMaltDataLab.sol";
import "../libraries/uniswap/IUniswapV2Pair.sol";

/// @title Uniswap Interaction Handler
/// @author 0xScotch <[email protected]>
/// @notice A simple contract to make interacting with UniswapV2 pools easier.
/// @notice The buyMalt method is locked down to avoid circumventing recovery mode
/// @dev Makes use of UniswapV2Router02. Would be more efficient to go direct
contract UniswapHandler is StabilizedPoolUnit, IDexHandler, DataLabExtension {
  using SafeERC20 for ERC20;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  bytes32 public immutable BUYER_ROLE;
  bytes32 public immutable SELLER_ROLE;
  bytes32 public immutable LIQUIDITY_ADDER_ROLE;
  bytes32 public immutable LIQUIDITY_REMOVER_ROLE;

  IUniswapV2Router02 public router;

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address _router
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    require(_router != address(0), "DexHandler: Router addr(0)");

    BUYER_ROLE = 0xf8cd32ed93fc2f9fc78152a14807c9609af3d99c5fe4dc6b106a801aaddfe90e;
    SELLER_ROLE = 0x43f25613eb2f15fb17222a5d424ca2655743e71265d98e4b93c05e5fb589ecde;
    LIQUIDITY_ADDER_ROLE = 0x03945f6c3051ab5ab2572e79ed50d335b86d27b15a2bde4e36c0cd1cd4e01197;
    LIQUIDITY_REMOVER_ROLE = 0xd47674765c67c9966091faf903d963f52df2a50d25ad1c519d46975de025d006;
    _setRoleAdmin(
      0xf8cd32ed93fc2f9fc78152a14807c9609af3d99c5fe4dc6b106a801aaddfe90e,
      0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    );
    _setRoleAdmin(
      0x43f25613eb2f15fb17222a5d424ca2655743e71265d98e4b93c05e5fb589ecde,
      0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    );
    _setRoleAdmin(
      0x03945f6c3051ab5ab2572e79ed50d335b86d27b15a2bde4e36c0cd1cd4e01197,
      0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    );
    _setRoleAdmin(
      0xd47674765c67c9966091faf903d963f52df2a50d25ad1c519d46975de025d006,
      0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    );

    router = IUniswapV2Router02(_router);
  }

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _stakeToken,
    address _maltDataLab,
    address[] memory initialBuyers,
    address[] memory initialSellers,
    address[] memory initialLiquidityAdders,
    address[] memory initialLiquidityRemovers
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(address(malt) == address(0), "UniswapHandler: Already setup");
    require(_malt != address(0), "UniswapHandler: Malt addr(0)");
    require(_collateralToken != address(0), "UniswapHandler: Col addr(0)");
    require(_stakeToken != address(0), "UniswapHandler: LP Token addr(0)");
    require(_maltDataLab != address(0), "UniswapHandler: MaltDataLab addr(0)");

    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
    stakeToken = IUniswapV2Pair(_stakeToken);
    maltDataLab = IMaltDataLab(_maltDataLab);

    for (uint256 i; i < initialBuyers.length; ++i) {
      _grantRole(BUYER_ROLE, initialBuyers[i]);
    }
    for (uint256 i; i < initialSellers.length; ++i) {
      _grantRole(SELLER_ROLE, initialSellers[i]);
    }
    for (uint256 i; i < initialLiquidityAdders.length; ++i) {
      _grantRole(LIQUIDITY_ADDER_ROLE, initialLiquidityAdders[i]);
    }
    for (uint256 i; i < initialLiquidityRemovers.length; ++i) {
      _grantRole(LIQUIDITY_REMOVER_ROLE, initialLiquidityRemovers[i]);
    }

    (, address updater, ) = poolFactory.getPool(_stakeToken);
    _setPoolUpdater(updater);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function calculateMintingTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256)
  {
    return
      _calculateTradeSize(address(malt), address(collateralToken), priceTarget);
  }

  function calculateBurningTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256)
  {
    uint256 unity = 10**collateralToken.decimals();
    return
      _calculateTradeSize(
        address(collateralToken),
        address(malt),
        (unity * unity) / priceTarget
      );
  }

  function reserves()
    public
    view
    returns (uint256 maltSupply, uint256 rewardSupply)
  {
    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();
    (maltSupply, rewardSupply) = address(malt) < address(collateralToken)
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  function maltMarketPrice()
    public
    view
    returns (uint256 price, uint256 decimals)
  {
    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();
    (uint256 maltReserves, uint256 rewardReserves) = address(malt) <
      address(collateralToken)
      ? (reserve0, reserve1)
      : (reserve1, reserve0);

    if (maltReserves == 0 || rewardReserves == 0) {
      price = 0;
      decimals = 18;
      return (price, decimals);
    }

    maltReserves = maltDataLab.maltToRewardDecimals(maltReserves);

    decimals = collateralToken.decimals();
    price = (rewardReserves * (10**decimals)) / maltReserves;
  }

  function getOptimalLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidityB
  ) external view returns (uint256 liquidityA) {
    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();
    (uint256 reservesA, uint256 reservesB) = tokenA < tokenB
      ? (reserve0, reserve1)
      : (reserve1, reserve0);

    liquidityA = UniswapV2Library.quote(liquidityB, reservesB, reservesA);
  }

  /*
   * MUTATION FUNCTIONS
   */
  function buyMalt(uint256 amount, uint256 slippageBps)
    external
    onlyRoleMalt(BUYER_ROLE, "Must have buyer privs")
    returns (uint256 purchased)
  {
    require(
      amount <= collateralToken.balanceOf(address(this)),
      "buy: insufficient"
    );

    if (amount == 0) {
      return 0;
    }

    // Just make sure starting from 0
    collateralToken.safeApprove(address(router), 0);
    collateralToken.safeApprove(address(router), amount);

    address[] memory path = new address[](2);
    path[0] = address(collateralToken);
    path[1] = address(malt);

    uint256 maltPrice = maltDataLab.maltPriceAverage(0);

    uint256 initialBalance = malt.balanceOf(address(this));

    router.swapExactTokensForTokens(
      amount,
      (amount * (10**collateralToken.decimals()) * (10000 - slippageBps)) /
        maltPrice /
        10000, // amountOutMin
      path,
      address(this),
      block.timestamp
    );

    // Reset approval
    collateralToken.safeApprove(address(router), 0);

    purchased = malt.balanceOf(address(this)) - initialBalance;
    malt.safeTransfer(msg.sender, purchased);
  }

  function sellMalt(uint256 amount, uint256 slippageBps)
    external
    onlyRoleMalt(SELLER_ROLE, "Must have seller privs")
    returns (uint256 rewards)
  {
    require(amount <= malt.balanceOf(address(this)), "sell: insufficient");

    if (amount == 0) {
      return 0;
    }

    // Just make sure starting from 0
    malt.safeApprove(address(router), 0);
    malt.safeApprove(address(router), amount);

    address[] memory path = new address[](2);
    path[0] = address(malt);
    path[1] = address(collateralToken);

    uint256 maltPrice = maltDataLab.maltPriceAverage(0);
    uint256 initialBalance = collateralToken.balanceOf(address(this));

    router.swapExactTokensForTokens(
      amount,
      (amount * maltPrice * (10000 - slippageBps)) /
        (10**collateralToken.decimals()) /
        10000, // amountOutMin
      path,
      address(this),
      block.timestamp
    );

    // Reset approval
    malt.safeApprove(address(router), 0);

    rewards = collateralToken.balanceOf(address(this)) - initialBalance;
    collateralToken.safeTransfer(msg.sender, rewards);
  }

  function addLiquidity(
    uint256 maltBalance,
    uint256 rewardBalance,
    uint256 slippageBps
  )
    external
    onlyRoleMalt(LIQUIDITY_ADDER_ROLE, "Must have liq add privs")
    returns (
      uint256 maltUsed,
      uint256 rewardUsed,
      uint256 liquidityCreated
    )
  {
    // Thid method assumes the caller does the required checks on token ratios etc
    uint256 initialMalt = malt.balanceOf(address(this));
    uint256 initialReward = collateralToken.balanceOf(address(this));

    require(maltBalance <= initialMalt, "Add liquidity: malt");
    require(rewardBalance <= initialReward, "Add liquidity: reward");

    if (maltBalance == 0 || rewardBalance == 0) {
      return (0, 0, 0);
    }

    (maltUsed, rewardUsed, liquidityCreated) = _executeAddLiquidity(
      maltBalance,
      rewardBalance,
      slippageBps
    );

    if (maltUsed < initialMalt) {
      malt.safeTransfer(msg.sender, initialMalt - maltUsed);
    }

    if (rewardUsed < initialReward) {
      collateralToken.safeTransfer(msg.sender, initialReward - rewardUsed);
    }
  }

  function removeLiquidity(uint256 liquidityBalance, uint256 slippageBps)
    external
    onlyRoleMalt(LIQUIDITY_REMOVER_ROLE, "Must have liq remove privs")
    returns (uint256 amountMalt, uint256 amountReward)
  {
    require(
      liquidityBalance <= stakeToken.balanceOf(address(this)),
      "remove: Insufficient"
    );

    if (liquidityBalance == 0) {
      return (0, 0);
    }

    (amountMalt, amountReward) = _executeRemoveLiquidity(
      liquidityBalance,
      slippageBps
    );

    if (amountMalt == 0 || amountReward == 0) {
      liquidityBalance = stakeToken.balanceOf(address(this));
      ERC20(address(stakeToken)).safeTransfer(msg.sender, liquidityBalance);
      return (amountMalt, amountReward);
    }
  }

  /*
   * INTERNAL METHODS
   */
  function _executeAddLiquidity(
    uint256 maltBalance,
    uint256 rewardBalance,
    uint256 slippageBps
  )
    internal
    returns (
      uint256 maltUsed,
      uint256 rewardUsed,
      uint256 liquidityCreated
    )
  {
    // Make sure starting from 0
    collateralToken.safeApprove(address(router), 0);
    malt.safeApprove(address(router), 0);

    collateralToken.safeApprove(address(router), rewardBalance);
    malt.safeApprove(address(router), maltBalance);

    (maltUsed, rewardUsed, liquidityCreated) = router.addLiquidity(
      address(malt),
      address(collateralToken),
      maltBalance,
      rewardBalance,
      (maltBalance * (10000 - slippageBps)) / 10000,
      (rewardBalance * (10000 - slippageBps)) / 10000,
      msg.sender, // transfer LP tokens to sender
      block.timestamp
    );

    // Reset approval
    collateralToken.safeApprove(address(router), 0);
    malt.safeApprove(address(router), 0);
  }

  function _executeRemoveLiquidity(
    uint256 liquidityBalance,
    uint256 slippageBps
  ) internal returns (uint256 amountMalt, uint256 amountReward) {
    uint256 totalLPSupply = stakeToken.totalSupply();

    // Make sure starting from 0
    ERC20(address(stakeToken)).safeApprove(address(router), 0);
    ERC20(address(stakeToken)).safeApprove(address(router), liquidityBalance);

    (uint256 maltReserves, uint256 collateralReserves) = maltDataLab
      .poolReservesAverage(0);

    uint256 maltValue = (maltReserves * liquidityBalance) / totalLPSupply;
    uint256 collateralValue = (collateralReserves * liquidityBalance) /
      totalLPSupply;

    (amountMalt, amountReward) = router.removeLiquidity(
      address(malt),
      address(collateralToken),
      liquidityBalance,
      (maltValue * (10000 - slippageBps)) / 10000,
      (collateralValue * (10000 - slippageBps)) / 10000,
      address(this),
      block.timestamp
    );

    // Reset approval
    ERC20(address(stakeToken)).safeApprove(address(router), 0);

    malt.safeTransfer(msg.sender, amountMalt);
    collateralToken.safeTransfer(msg.sender, amountReward);
  }

  /*
   * PRIVATE METHODS
   */
  function _calculateTradeSize(
    address sellToken,
    address buyToken,
    uint256 priceTarget
  ) private view returns (uint256) {
    (uint256 sellReserves, uint256 invariant) = _getTradePoolData(
      sellToken,
      buyToken
    );

    uint256 buyBase = 10**uint256(ERC20(buyToken).decimals());

    uint256 leftSide = Babylonian.sqrt(
      FullMath.mulDiv(invariant * 1000, buyBase, priceTarget * 997)
    );

    uint256 rightSide = (sellReserves * 1000) / 997;

    if (leftSide < rightSide) return 0;

    return leftSide - rightSide;
  }

  function _getTradePoolData(address sellToken, address buyToken)
    private
    view
    returns (uint256 sellReserves, uint256 invariant)
  {
    (uint256 reserve0, uint256 reserve1, ) = stakeToken.getReserves();
    sellReserves = sellToken < buyToken ? reserve0 : reserve1;

    invariant = reserve1 * reserve0;
  }

  function addBuyer(address _buyer)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    require(_buyer != address(0), "No addr(0)");
    _grantRole(BUYER_ROLE, _buyer);
  }

  function removeBuyer(address _buyer)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    _revokeRole(BUYER_ROLE, _buyer);
  }

  function addSeller(address _seller)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    require(_seller != address(0), "No addr(0)");
    _grantRole(SELLER_ROLE, _seller);
  }

  function removeSeller(address _seller)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    _revokeRole(SELLER_ROLE, _seller);
  }

  function addLiquidityAdder(address _adder)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    require(_adder != address(0), "No addr(0)");
    _grantRole(LIQUIDITY_ADDER_ROLE, _adder);
  }

  function removeLiquidityAdder(address _adder)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    _revokeRole(LIQUIDITY_ADDER_ROLE, _adder);
  }

  function addLiquidityRemover(address _remover)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    require(_remover != address(0), "No addr(0)");
    _grantRole(LIQUIDITY_REMOVER_ROLE, _remover);
  }

  function removeLiquidityRemover(address _remover)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must be pool updater")
  {
    _revokeRole(LIQUIDITY_REMOVER_ROLE, _remover);
  }

  function _accessControl() internal override(DataLabExtension) {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilityPod/SwingTrader.sol";
import "../StabilizedPoolExtensions/RewardThrottleExtension.sol";

/// @title Reward Overflow Pool
/// @author 0xScotch <[email protected]>
/// @notice Allows throttler contract to request capital when the current epoch underflows desired reward
contract RewardOverflowPool is SwingTrader, RewardThrottleExtension {
  using SafeERC20 for ERC20;

  uint256 public maxFulfillmentBps = 5000; // 50%

  event FulfilledRequest(uint256 amount);
  event SetMaxFulfillment(uint256 maxBps);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) SwingTrader(timelock, repository, poolFactory) {}

  function setupContracts(
    address _collateralToken,
    address _malt,
    address _dexHandler,
    address _swingTraderManager,
    address _maltDataLab,
    address _profitDistributor,
    address _rewardThrottle,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "Overflow: Already setup");

    require(_collateralToken != address(0), "Overflow: ColToken addr(0)");
    require(_malt != address(0), "Overflow: Malt addr(0)");
    require(_dexHandler != address(0), "Overflow: DexHandler addr(0)");
    require(_swingTraderManager != address(0), "Overflow: Manager addr(0)");
    require(_maltDataLab != address(0), "Overflow: MaltDataLab addr(0)");
    require(_rewardThrottle != address(0), "Overflow: RewardThrottle addr(0)");

    contractActive = true;

    _setupRole(MANAGER_ROLE, _swingTraderManager);

    _setupRole(CAPITAL_DELEGATE_ROLE, _swingTraderManager);
    _setupRole(REWARD_THROTTLE_ROLE, _rewardThrottle);

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    dexHandler = IDexHandler(_dexHandler);
    maltDataLab = IMaltDataLab(_maltDataLab);
    profitDistributor = IProfitDistributor(_profitDistributor);
    rewardThrottle = IRewardThrottle(_rewardThrottle);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function requestCapital(uint256 amount)
    external
    onlyRoleMalt(REWARD_THROTTLE_ROLE, "Must have Reward throttle privs")
    onlyActive
    returns (uint256 fulfilledAmount)
  {
    uint256 balance = collateralToken.balanceOf(address(this));

    if (balance == 0) {
      return 0;
    }

    // This is the max amount allowable
    fulfilledAmount = (balance * maxFulfillmentBps) / 10000;

    if (amount <= fulfilledAmount) {
      fulfilledAmount = amount;
    }

    collateralToken.safeTransfer(address(rewardThrottle), fulfilledAmount);

    emit FulfilledRequest(fulfilledAmount);

    return fulfilledAmount;
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setMaxFulfillment(uint256 _maxFulfillment)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_maxFulfillment != 0, "Can't have 0 max fulfillment");
    require(_maxFulfillment <= 10000, "Can't have above 100% max fulfillment");

    maxFulfillmentBps = _maxFulfillment;
    emit SetMaxFulfillment(_maxFulfillment);
  }

  function _beforeSetRewardThrottle(address _rewardThrottle) internal override {
    _transferRole(
      _rewardThrottle,
      address(rewardThrottle),
      REWARD_THROTTLE_ROLE
    );
  }

  function _accessControl()
    internal
    override(SwingTrader, RewardThrottleExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/RewardThrottleExtension.sol";
import "../interfaces/IForfeit.sol";
import "../interfaces/IRewardMine.sol";
import "../interfaces/IDistributor.sol";

/// @title Linear Distributor
/// @author 0xScotch <[email protected]>
/// @notice The contract in charge of implementing the linear distribution of rewards in line with the vesting APR
contract LinearDistributor is
  StabilizedPoolUnit,
  IDistributor,
  RewardThrottleExtension
{
  using SafeERC20 for ERC20;

  bytes32 public immutable REWARDER_ROLE;
  bytes32 public immutable REWARD_MINE_ROLE;

  IRewardMine public rewardMine;
  IForfeit public forfeitor;
  IVestingDistributor public vestingDistributor;

  uint256 public bufferTime = 1 days;

  uint256 internal previouslyVested;
  uint256 internal previouslyVestedTimestamp;

  uint256 internal declaredBalance;
  uint256 internal collateralBalance;

  event DeclareReward(
    uint256 totalAmount,
    uint256 usedAmount,
    address collateralToken
  );
  event Forfeit(uint256 forfeited);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    REWARDER_ROLE = 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6;
    REWARD_MINE_ROLE = 0x9afd8e1abbfc72925a0e12f641b707c835ffa0861d61e98c38d65713ba5e2aff;
  }

  function setupContracts(
    address _collateralToken,
    address _rewardMine,
    address _rewardThrottle,
    address _forfeitor,
    address _vestingDistributor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "Distributor: Setup already done");
    require(_collateralToken != address(0), "Distributor: Col addr(0)");
    require(_rewardMine != address(0), "Distributor: RewardMine addr(0)");
    require(_rewardThrottle != address(0), "Distributor: Throttler addr(0)");
    require(_forfeitor != address(0), "Distributor: Forfeitor addr(0)");
    require(
      _vestingDistributor != address(0),
      "Distributor: VestingDist addr(0)"
    );

    contractActive = true;

    _roleSetup(REWARDER_ROLE, _rewardThrottle);
    _roleSetup(REWARD_MINE_ROLE, _rewardMine);

    collateralToken = ERC20(_collateralToken);
    rewardMine = IRewardMine(_rewardMine);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    forfeitor = IForfeit(_forfeitor);
    vestingDistributor = IVestingDistributor(_vestingDistributor);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  /* PUBLIC VIEW FUNCTIONS */
  function totalDeclaredReward() public view returns (uint256) {
    return declaredBalance;
  }

  function bondedValue() public view returns (uint256) {
    return rewardMine.valueOfBonded();
  }

  /*
   * PRIVILEDGED METHODS
   */
  function declareReward(uint256 amount)
    external
    onlyRoleMalt(REWARDER_ROLE, "Only rewarder role")
    onlyActive
  {
    _rewardCheck(amount);

    if (rewardMine.totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it
      _forfeit(amount);
      return;
    }

    uint256 vestingBondedValue = vestingDistributor.bondedValue();
    uint256 currentlyVested = vestingDistributor.getCurrentlyVested();

    uint256 netVest = currentlyVested - previouslyVested;
    uint256 netTime = block.timestamp - previouslyVestedTimestamp;

    if (netVest == 0 || vestingBondedValue == 0) {
      return;
    }

    uint256 linearBondedValue = rewardMine.valueOfBonded();

    uint256 distributed = (linearBondedValue * netVest) / vestingBondedValue;
    uint256 balance = collateralBalance; // gas

    if (distributed > balance) {
      distributed = balance;
      currentlyVested =
        (distributed * vestingBondedValue) /
        linearBondedValue +
        previouslyVested;
    }

    if (distributed > 0) {
      // Send vested amount to liquidity mine
      balance -= distributed;
      collateralToken.safeTransfer(address(rewardMine), distributed);
      rewardMine.releaseReward(distributed);
    }

    uint256 buf = bufferTime; // gas
    uint256 bufferRequirement;

    if (netTime < buf) {
      bufferRequirement = (distributed * buf) / netTime;
    } else {
      bufferRequirement = distributed;
    }

    if (balance > bufferRequirement) {
      // We have more than the buffer required. Forfeit the rest
      uint256 net = balance - bufferRequirement;
      _forfeit(net);
    }

    previouslyVested = currentlyVested;
    previouslyVestedTimestamp = block.timestamp;
    collateralBalance = balance;

    emit DeclareReward(amount, distributed, address(collateralToken));
  }

  function decrementRewards(uint256 amount)
    external
    onlyRoleMalt(REWARD_MINE_ROLE, "Only reward mine")
  {
    require(
      amount <= declaredBalance,
      "Can't decrement more than total reward balance"
    );

    if (amount > 0) {
      declaredBalance = declaredBalance - amount;
    }
  }

  /* INTERNAL FUNCTIONS */
  function _rewardCheck(uint256 reward) internal {
    require(reward > 0, "Cannot declare 0 reward");

    declaredBalance = declaredBalance + reward;
    collateralBalance = collateralBalance + reward;

    uint256 totalReward = collateralToken.balanceOf(address(this)) +
      rewardMine.totalReleasedReward();

    require(declaredBalance <= totalReward, "Insufficient balance");
  }

  function _forfeit(uint256 forfeited) internal {
    require(forfeited <= declaredBalance, "Cannot forfeit more than declared");

    declaredBalance = declaredBalance - forfeited;
    collateralBalance = collateralBalance - forfeited;

    collateralToken.safeTransfer(address(forfeitor), forfeited);
    forfeitor.handleForfeit();

    uint256 totalReward = collateralToken.balanceOf(address(this)) +
      rewardMine.totalReleasedReward();

    require(declaredBalance <= totalReward, "Insufficient balance");

    emit Forfeit(forfeited);
  }

  function _beforeSetRewardThrottle(address _rewardThrottle) internal override {
    _transferRole(_rewardThrottle, address(rewardThrottle), REWARDER_ROLE);
  }

  function sweepExtraCollateral(address _destination)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_destination != address(0), "Cannot send to addr(0)");

    uint256 balance = collateralToken.balanceOf(address(this));
    uint256 collateral = collateralBalance;
    if (balance > collateral) {
      collateralToken.safeTransfer(_destination, balance - collateral);
    }
  }

  function setRewardMine(address _rewardMine)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_rewardMine != address(0), "Cannot set 0 address as rewardMine");
    _transferRole(_rewardMine, address(rewardMine), REWARD_MINE_ROLE);
    rewardMine = IRewardMine(_rewardMine);
  }

  function setForfeitor(address _forfeitor)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater privs")
  {
    require(_forfeitor != address(0), "Cannot set 0 address as forfeitor");
    forfeitor = IForfeit(_forfeitor);
  }

  function setVestingDistributor(address _vestingDistributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_vestingDistributor != address(0), "SetVestDist: No addr(0)");
    vestingDistributor = IVestingDistributor(_vestingDistributor);

    previouslyVested = vestingDistributor.getCurrentlyVested();
  }

  function setBufferTime(uint256 _bufferTime)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    bufferTime = _bufferTime;
  }

  function _accessControl() internal override(RewardThrottleExtension) {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/RewardThrottleExtension.sol";
import "../interfaces/IBonding.sol";
import "../interfaces/IForfeit.sol";
import "../interfaces/IRewardMine.sol";

struct FocalPoint {
  uint256 id;
  uint256 focalLength;
  uint256 endTime;
  uint256 rewarded;
  uint256 vested;
  uint256 lastVestingTime;
}

/// @title Reward Vesting Distributor
/// @author 0xScotch <[email protected]>
/// @notice The contract in charge of implementing the focal vesting scheme for rewards
contract VestingDistributor is StabilizedPoolUnit, RewardThrottleExtension {
  using SafeERC20 for ERC20;

  uint256 public focalID = 1; // Avoid issues with defaulting to 0
  uint256 public focalLength = 5 days;

  bytes32 public immutable REWARDER_ROLE;
  bytes32 public immutable REWARD_MINE_ROLE;
  bytes32 public immutable FOCAL_LENGTH_UPDATER_ROLE;

  IRewardMine public rewardMine;
  IForfeit public forfeitor;

  uint256 internal declaredBalance;
  uint256 internal vestedAccumulator;
  FocalPoint[] internal focalPoints;

  event DeclareReward(uint256 amount, address collateralToken);
  event Forfeit(address account, address collateralToken, uint256 forfeited);
  event RewardFocal(
    uint256 id,
    uint256 focalLength,
    uint256 endTime,
    uint256 rewarded
  );

  constructor(
    address timelock,
    address initialAdmin,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    REWARDER_ROLE = 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6;
    REWARD_MINE_ROLE = 0x9afd8e1abbfc72925a0e12f641b707c835ffa0861d61e98c38d65713ba5e2aff;
    FOCAL_LENGTH_UPDATER_ROLE = 0xfc161c35c622d802db78fe6212c2776c085a08e7a072c2d974d3764312eb42ab;

    _roleSetup(
      0xfc161c35c622d802db78fe6212c2776c085a08e7a072c2d974d3764312eb42ab,
      initialAdmin
    );

    focalPoints.push();
    focalPoints.push();
  }

  function setupContracts(
    address _collateralToken,
    address _rewardMine,
    address _rewardThrottle,
    address _forfeitor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "Distributor: Setup already done");
    require(_collateralToken != address(0), "Distributor: Col addr(0)");
    require(_rewardMine != address(0), "Distributor: RewardMine addr(0)");
    require(_rewardThrottle != address(0), "Distributor: Throttler addr(0)");
    require(_forfeitor != address(0), "Distributor: Forfeitor addr(0)");

    contractActive = true;

    _roleSetup(REWARDER_ROLE, _rewardThrottle);
    _roleSetup(REWARD_MINE_ROLE, _rewardMine);

    rewardMine = IRewardMine(_rewardMine);
    forfeitor = IForfeit(_forfeitor);

    collateralToken = ERC20(_collateralToken);
    rewardThrottle = IRewardThrottle(_rewardThrottle);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function vest() public {
    if (declaredBalance == 0) {
      return;
    }
    uint256 vestedReward = 0;
    uint256 balance = collateralToken.balanceOf(address(this));

    FocalPoint storage vestingFocal = _getVestingFocal();
    FocalPoint storage activeFocal = _updateAndGetActiveFocal();

    vestedReward = _getVestableQuantity(vestingFocal);
    uint256 activeReward = _getVestableQuantity(activeFocal);

    vestedReward = vestedReward + activeReward;

    if (vestedReward > balance) {
      vestedReward = balance;
    }

    if (vestedReward > 0) {
      if (rewardMine.totalBonded() == 0) {
        // There is no accounts to distribute the rewards to so forfeit it
        _forfeit(vestedReward);
        return;
      }
      // Send vested amount to liquidity mine
      vestedAccumulator += vestedReward;
      collateralToken.safeTransfer(address(rewardMine), vestedReward);
      rewardMine.releaseReward(vestedReward);
    }

    // increment focalID if time is past the halfway mark
    // through a focal period
    if (block.timestamp >= _getNextFocalStart(activeFocal)) {
      _incrementFocalPoint();
    }
  }

  /* PUBLIC VIEW FUNCTIONS */
  function totalDeclaredReward() public view returns (uint256) {
    return declaredBalance;
  }

  function getCurrentlyVested() public view returns (uint256) {
    return vestedAccumulator;
  }

  function bondedValue() public view returns (uint256) {
    return rewardMine.valueOfBonded();
  }

  function getAllFocalUnvestedBps()
    public
    view
    returns (uint256 currentUnvestedBps, uint256 vestingUnvestedBps)
  {
    uint256 currentId = focalID;

    FocalPoint storage currentFocal = focalPoints[_getFocalIndex(currentId)];
    FocalPoint storage vestingFocal = focalPoints[
      _getFocalIndex(currentId + 1)
    ];

    return (
      _getFocalUnvestedBps(currentFocal),
      _getFocalUnvestedBps(vestingFocal)
    );
  }

  function getFocalUnvestedBps(uint256 id)
    public
    view
    returns (uint256 unvestedBps)
  {
    FocalPoint storage currentFocal = focalPoints[_getFocalIndex(id)];

    return _getFocalUnvestedBps(currentFocal);
  }

  /* INTERNAL VIEW FUNCTIONS */
  function _getFocalUnvestedBps(FocalPoint memory focal)
    internal
    view
    returns (uint256)
  {
    uint256 periodLength = focal.focalLength;
    uint256 vestingEndTime = focal.endTime;

    if (block.timestamp >= vestingEndTime) {
      return 0;
    }

    return ((vestingEndTime - block.timestamp) * 10000) / periodLength;
  }

  function _getFocalIndex(uint256 id) internal pure returns (uint8 index) {
    return uint8(id % 2);
  }

  function _getVestingFocal() internal view returns (FocalPoint storage) {
    // Can add 1 as the modulo ensures we wrap correctly
    uint8 index = _getFocalIndex(focalID + 1);
    return focalPoints[index];
  }

  /* INTERNAL FUNCTIONS */
  function _updateAndGetActiveFocal() internal returns (FocalPoint storage) {
    uint8 index = _getFocalIndex(focalID);
    FocalPoint storage focal = focalPoints[index];

    if (focal.id != focalID) {
      // If id is not focalID then reinitialize the struct
      _resetFocalPoint(focalID, block.timestamp + focalLength);
    }

    return focal;
  }

  function _rewardCheck(uint256 reward) internal {
    require(reward > 0, "Cannot declare 0 reward");

    declaredBalance = declaredBalance + reward;

    uint256 totalReward = collateralToken.balanceOf(address(this)) +
      rewardMine.totalReleasedReward();

    require(declaredBalance <= totalReward, "Insufficient balance");
  }

  function _forfeit(uint256 forfeited) internal {
    require(forfeited <= declaredBalance, "Cannot forfeit more than declared");

    declaredBalance = declaredBalance - forfeited;

    _decrementFocalRewards(forfeited);

    collateralToken.safeTransfer(address(forfeitor), forfeited);
    forfeitor.handleForfeit();

    uint256 totalReward = collateralToken.balanceOf(address(this)) +
      rewardMine.totalReleasedReward();

    require(declaredBalance <= totalReward, "Insufficient balance");

    emit Forfeit(msg.sender, address(collateralToken), forfeited);
  }

  function _decrementFocalRewards(uint256 amount) internal {
    FocalPoint storage vestingFocal = _getVestingFocal();
    uint256 remainingVest = vestingFocal.rewarded - vestingFocal.vested;

    if (remainingVest >= amount) {
      vestingFocal.rewarded -= amount;
    } else {
      vestingFocal.rewarded -= remainingVest;
      remainingVest = amount - remainingVest;

      FocalPoint storage activeFocal = _updateAndGetActiveFocal();

      if (activeFocal.rewarded >= remainingVest) {
        activeFocal.rewarded -= remainingVest;
      } else {
        activeFocal.rewarded = 0;
      }
    }
  }

  function _resetFocalPoint(uint256 id, uint256 endTime) internal {
    uint8 index = _getFocalIndex(id);
    FocalPoint storage newFocal = focalPoints[index];

    newFocal.id = id;
    newFocal.focalLength = focalLength;
    newFocal.endTime = endTime;
    newFocal.rewarded = 0;
    newFocal.vested = 0;
    newFocal.lastVestingTime = endTime - focalLength;
  }

  function _incrementFocalPoint() internal {
    FocalPoint storage oldFocal = _updateAndGetActiveFocal();

    // This will increment every 24 hours so overflow on uint256
    // isn't an issue.
    focalID = focalID + 1;

    // Emit event that documents the focalPoint that has just ended
    emit RewardFocal(
      oldFocal.id,
      oldFocal.focalLength,
      oldFocal.endTime,
      oldFocal.rewarded
    );

    uint256 newEndTime = oldFocal.endTime + focalLength / 2;

    _resetFocalPoint(focalID, newEndTime);
  }

  function _getNextFocalStart(FocalPoint storage focal)
    internal
    view
    returns (uint256)
  {
    return focal.endTime - (focal.focalLength / 2);
  }

  function _getVestableQuantity(FocalPoint storage focal)
    internal
    returns (uint256 vestedReward)
  {
    uint256 currentTime = block.timestamp;

    if (focal.lastVestingTime >= currentTime) {
      return 0;
    }

    if (currentTime > focal.endTime) {
      currentTime = focal.endTime;
    }

    // Time in between last vesting call and end of focal period
    uint256 timeRemaining = focal.endTime - focal.lastVestingTime;

    if (timeRemaining == 0) {
      return 0;
    }

    // Time since last vesting call
    uint256 vestedTime = currentTime - focal.lastVestingTime;

    uint256 remainingReward = focal.rewarded - focal.vested;

    vestedReward = (remainingReward * vestedTime) / timeRemaining;

    focal.vested = focal.vested + vestedReward;
    focal.lastVestingTime = currentTime;

    return vestedReward;
  }

  /*
   * PRIVILEDGED METHODS
   */
  function declareReward(uint256 amount)
    external
    onlyRoleMalt(REWARDER_ROLE, "Only rewarder role")
  {
    _rewardCheck(amount);

    if (rewardMine.totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it
      _forfeit(amount);
      return;
    }

    // Vest current reward before adding new reward to ensure
    // Everything is up to date before we add new reward
    vest();

    FocalPoint storage activeFocal = _updateAndGetActiveFocal();
    activeFocal.rewarded = activeFocal.rewarded + amount;

    rewardMine.declareReward(amount);

    emit DeclareReward(amount, address(collateralToken));
  }

  function forfeit(uint256 amount)
    external
    onlyRoleMalt(REWARD_MINE_ROLE, "Only reward mine")
  {
    if (amount > 0) {
      _forfeit(amount);
    }
  }

  function decrementRewards(uint256 amount)
    external
    onlyRoleMalt(REWARD_MINE_ROLE, "Only reward mine")
  {
    require(
      amount <= declaredBalance,
      "Can't decrement more than total reward balance"
    );

    if (amount > 0) {
      declaredBalance = declaredBalance - amount;
    }
  }

  function setFocalLength(uint256 _focalLength)
    external
    onlyRoleMalt(FOCAL_LENGTH_UPDATER_ROLE, "Only focal length updater")
  {
    // Cannot have focal length under 1 hour
    require(_focalLength >= 3600, "Focal length too small");
    focalLength = _focalLength;
  }

  function _beforeSetRewardThrottle(address _rewardThrottle) internal override {
    _transferRole(_rewardThrottle, address(rewardThrottle), REWARDER_ROLE);
  }

  function setRewardMine(address _rewardMine)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_rewardMine != address(0), "Cannot set 0 address as rewardMine");
    _transferRole(_rewardMine, address(rewardMine), REWARD_MINE_ROLE);
    rewardMine = IRewardMine(_rewardMine);
  }

  function setForfeitor(address _forfeitor)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater privs")
  {
    require(_forfeitor != address(0), "Cannot set 0 address as forfeitor");
    forfeitor = IForfeit(_forfeitor);
  }

  function addFocalLengthUpdater(address _updater)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(
      _updater != address(0),
      "Cannot set 0 address as focal length updater"
    );
    _roleSetup(FOCAL_LENGTH_UPDATER_ROLE, _updater);
  }

  function removeFocalLengthUpdater(address _updater)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    _revokeRole(FOCAL_LENGTH_UPDATER_ROLE, _updater);
  }

  function _accessControl() internal override(RewardThrottleExtension) {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/utils/math/Math.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/BondingExtension.sol";
import "../StabilizedPoolExtensions/RewardOverflowExtension.sol";
import "../interfaces/ITimekeeper.sol";
import "../interfaces/IOverflow.sol";
import "../interfaces/IBonding.sol";
import "../interfaces/IDistributor.sol";

struct State {
  uint256 profit;
  uint256 rewarded;
  uint256 bondedValue;
  uint256 epochsPerYear;
  uint256 desiredAPR;
  uint256 cumulativeCashflowApr;
  uint256 cumulativeApr;
  bool active;
}

/// @title Reward Throttle
/// @author 0xScotch <[email protected]>
/// @notice The contract in charge of smoothing out rewards and attempting to find a steady APR
contract RewardThrottle is
  StabilizedPoolUnit,
  BondingExtension,
  RewardOverflowExtension
{
  using SafeERC20 for ERC20;

  ITimekeeper public timekeeper;

  // Admin updatable params
  uint256 public smoothingPeriod = 24; // 24 epochs = 12 hours
  uint256 public desiredRunway = 15778800; // 6 months
  // uint256 public desiredRunway = 2629800; // 1 months
  uint256 public aprCap = 5000; // 50%
  uint256 public aprFloor = 200; // 2%
  uint256 public aprUpdatePeriod = 2 hours;
  uint256 public cushionBps = 10000; // 100%
  uint256 public maxAdjustment = 50; // 0.5%
  uint256 public proportionalGainBps = 1000; // 10% ie proportional gain factor of 0.1

  // Not externally updatable
  uint256 public targetAPR = 1500; // 15%
  uint256 public aprLastUpdated;

  uint256 public activeEpoch;
  mapping(uint256 => State) public state;

  event RewardOverflow(uint256 epoch, uint256 overflow);
  event HandleReward(uint256 epoch, uint256 amount);
  event UpdateDesiredAPR(uint256 apr);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address _timekeeper
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    require(_timekeeper != address(0), "Throttle: Timekeeper addr(0)");

    timekeeper = ITimekeeper(_timekeeper);
    aprLastUpdated = block.timestamp;
  }

  function setupContracts(
    address _collateralToken,
    address _overflowPool,
    address _bonding,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "RewardThrottle: Already setup");
    require(_collateralToken != address(0), "RewardThrottle: Col addr(0)");
    require(_overflowPool != address(0), "RewardThrottle: Overflow addr(0)");
    require(_bonding != address(0), "RewardThrottle: Bonding addr(0)");

    contractActive = true;

    collateralToken = ERC20(_collateralToken);
    overflowPool = IOverflow(_overflowPool);
    bonding = IBonding(_bonding);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function handleReward() external onlyActive {
    updateDesiredAPR();

    uint256 balance = collateralToken.balanceOf(address(this));

    uint256 epoch = timekeeper.epoch();

    uint256 _activeEpoch = activeEpoch; // gas

    state[_activeEpoch].profit = state[_activeEpoch].profit + balance;

    // Fetch targetAPR before we update current epoch state
    uint256 aprTarget = targetAPR; // gas

    // Distribute balance to the correct places
    if (aprTarget > 0 && _epochAprGivenReward(epoch, balance) > aprTarget) {
      uint256 remainder = _getRewardOverflow(balance, aprTarget, _activeEpoch);
      emit RewardOverflow(_activeEpoch, remainder);

      if (remainder > 0) {
        collateralToken.safeTransfer(address(overflowPool), remainder);

        if (balance > remainder) {
          balance -= remainder;
        } else {
          balance = 0;
        }
      }
    }

    if (balance > 0) {
      _sendToDistributor(balance, _activeEpoch);
    }

    emit HandleReward(epoch, balance);
  }

  function updateDesiredAPR() public onlyActive {
    checkRewardUnderflow();

    if (aprLastUpdated + aprUpdatePeriod > block.timestamp) {
      // Too early to update
      return;
    }

    uint256 cashflowAverageApr = averageCashflowAPR(smoothingPeriod);

    uint256 newAPR = targetAPR; // gas
    uint256 adjustmentCap = maxAdjustment; // gas
    uint256 targetCashflowApr = (newAPR * (10000 + cushionBps)) / 10000;

    if (cashflowAverageApr > targetCashflowApr) {
      uint256 delta = cashflowAverageApr - targetCashflowApr;
      uint256 adjustment = (delta * proportionalGainBps) / 10000;

      if (adjustment > adjustmentCap) {
        adjustment = adjustmentCap;
      }

      newAPR = newAPR + adjustment;
    } else if (cashflowAverageApr < targetCashflowApr) {
      uint256 deficit = runwayDeficit();

      if (deficit != 0) {
        uint256 delta = targetCashflowApr - cashflowAverageApr;
        uint256 adjustment = (delta * proportionalGainBps) / 10000;

        if (adjustment > adjustmentCap) {
          adjustment = adjustmentCap;
        }

        if (newAPR < adjustment) {
          newAPR = adjustment;
        }

        newAPR -= adjustment;
      }
    }

    uint256 cap = aprCap; // gas
    uint256 floor = aprFloor; // gas
    if (newAPR > cap) {
      newAPR = cap;
    } else if (newAPR < floor) {
      newAPR = floor;
    }

    targetAPR = newAPR;
    aprLastUpdated = block.timestamp;
    emit UpdateDesiredAPR(newAPR);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function epochAPR(uint256 epoch) public view returns (uint256) {
    // This returns an implied APR based on the distributed rewards and bonded LP at the given epoch
    State memory epochState = state[epoch];

    uint256 bondedValue = epochState.bondedValue;
    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
      if (bondedValue == 0) {
        return 0;
      }
    }

    uint256 epochsPerYear = epochState.epochsPerYear;

    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    // 10000 = 100%
    return (epochState.rewarded * 10000 * epochsPerYear) / bondedValue;
  }

  function averageCashflowAPR(uint256 averagePeriod)
    public
    view
    returns (uint256 apr)
  {
    uint256 currentEpoch = activeEpoch; // gas
    uint256 endEpoch = currentEpoch; // previous epoch
    uint256 startEpoch;

    if (endEpoch < averagePeriod) {
      averagePeriod = currentEpoch;
    } else {
      startEpoch = endEpoch - averagePeriod;
    }

    if (startEpoch == endEpoch || averagePeriod == 0) {
      return epochCashflowAPR(endEpoch);
    }

    State memory startEpochState = state[startEpoch];
    State memory endEpochState = state[endEpoch];

    if (
      startEpochState.cumulativeCashflowApr >=
      endEpochState.cumulativeCashflowApr
    ) {
      return 0;
    }

    uint256 delta = endEpochState.cumulativeCashflowApr -
      startEpochState.cumulativeCashflowApr;

    apr = delta / averagePeriod;
  }

  function averageCashflowAPR(uint256 startEpoch, uint256 endEpoch)
    public
    view
    returns (uint256 apr)
  {
    require(startEpoch <= endEpoch, "Start cannot be before the end");

    if (startEpoch == endEpoch) {
      return epochCashflowAPR(endEpoch);
    }

    uint256 averagePeriod = endEpoch - startEpoch;

    State memory startEpochState = state[startEpoch];
    State memory endEpochState = state[endEpoch];

    if (
      startEpochState.cumulativeCashflowApr >=
      endEpochState.cumulativeCashflowApr
    ) {
      return 0;
    }

    uint256 delta = endEpochState.cumulativeCashflowApr -
      startEpochState.cumulativeCashflowApr;

    apr = delta / averagePeriod;
  }

  function epochCashflow(uint256 epoch) public view returns (uint256 cashflow) {
    State memory epochState = state[epoch];

    cashflow = epochState.profit;

    if (epochState.rewarded > cashflow) {
      cashflow = epochState.rewarded;
    }
  }

  function epochCashflowAPR(uint256 epoch)
    public
    view
    returns (uint256 cashflowAPR)
  {
    State memory epochState = state[epoch];

    uint256 cashflow = epochState.profit;

    if (epochState.rewarded > cashflow) {
      cashflow = epochState.rewarded;
    }

    uint256 bondedValue = epochState.bondedValue;
    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
      if (bondedValue == 0) {
        return 0;
      }
    }

    uint256 epochsPerYear = epochState.epochsPerYear;

    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    // 10000 = 100%
    return (cashflow * 10000 * epochsPerYear) / bondedValue;
  }

  function averageAPR(uint256 startEpoch, uint256 endEpoch)
    public
    view
    returns (uint256 apr)
  {
    require(startEpoch <= endEpoch, "Start cannot be before the end");

    if (startEpoch == endEpoch) {
      return epochAPR(startEpoch);
    }

    uint256 averagePeriod = endEpoch - startEpoch;

    State memory startEpochState = state[startEpoch];
    State memory endEpochState = state[endEpoch];

    if (startEpochState.cumulativeApr >= endEpochState.cumulativeApr) {
      return 0;
    }

    uint256 delta = endEpochState.cumulativeApr - startEpochState.cumulativeApr;

    apr = delta / averagePeriod;
  }

  function targetEpochProfit() public view returns (uint256) {
    uint256 epoch = timekeeper.epoch();
    (, uint256 epochProfitTarget) = getTargets(epoch);
    return epochProfitTarget;
  }

  function getTargets(uint256 epoch)
    public
    view
    returns (uint256 aprTarget, uint256 profitTarget)
  {
    State memory epochState = state[epoch];

    aprTarget = epochState.desiredAPR;

    if (aprTarget == 0) {
      aprTarget = targetAPR;
    }

    uint256 bondedValue = epochState.bondedValue;
    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
    }

    uint256 epochsPerYear = epochState.epochsPerYear;
    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    profitTarget = (aprTarget * bondedValue) / epochsPerYear / 10000;

    return (aprTarget, profitTarget);
  }

  function runwayDeficit() public view returns (uint256) {
    uint256 overflowBalance = collateralToken.balanceOf(address(overflowPool));

    uint256 epochTargetProfit = targetEpochProfit();
    // 31557600 is seconds in a year
    uint256 runwayEpochs = (timekeeper.epochsPerYear() * desiredRunway) /
      31557600;
    uint256 requiredProfit = epochTargetProfit * runwayEpochs;

    if (overflowBalance < requiredProfit) {
      return requiredProfit - overflowBalance;
    }

    return 0;
  }

  /// @notice Returns the number of epochs of APR we have in runway
  function runway()
    external
    view
    returns (uint256 runwayEpochs, uint256 runwayDays)
  {
    uint256 overflowBalance = collateralToken.balanceOf(address(overflowPool));
    uint256 epochTargetProfit = targetEpochProfit();
    // 86400 seconds in a day
    uint256 epochsPerDay = 86400 / timekeeper.epochLength();

    if (epochTargetProfit == 0 || epochsPerDay == 0) {
      return (0, 0);
    }

    runwayEpochs = overflowBalance / epochTargetProfit;
    runwayDays = runwayEpochs / epochsPerDay;
  }

  function epochState(uint256 epoch) public view returns (State memory) {
    return state[epoch];
  }

  function epochData(uint256 epoch)
    public
    view
    returns (
      uint256 profit,
      uint256 rewarded,
      uint256 bondedValue,
      uint256 desiredAPR,
      uint256 epochsPerYear,
      uint256 cumulativeCashflowApr,
      uint256 cumulativeApr
    )
  {
    return (
      state[epoch].profit,
      state[epoch].rewarded,
      state[epoch].bondedValue,
      state[epoch].desiredAPR,
      state[epoch].epochsPerYear,
      state[epoch].cumulativeCashflowApr,
      state[epoch].cumulativeApr
    );
  }

  function checkRewardUnderflow() public onlyActive {
    uint256 epoch = timekeeper.epoch();

    uint256 _activeEpoch = activeEpoch; // gas

    // Fill in gaps so we have a fresh foundation to calculate from
    _fillInEpochGaps(epoch);

    if (epoch > _activeEpoch) {
      for (uint256 i = _activeEpoch; i < epoch; ++i) {
        uint256 underflow = _getRewardUnderflow(i);

        if (underflow > 0) {
          uint256 balance = overflowPool.requestCapital(underflow);

          _sendToDistributor(balance, i);
        }
      }
    }
  }

  function checkRewardUnderflow(uint256 epoch) public onlyActive {
    uint256 _activeEpoch = activeEpoch; // gas
    require(epoch > _activeEpoch, "Epoch must be in the future");

    // Fill in gaps so we have a fresh foundation to calculate from
    _fillInEpochGaps(epoch);

    if (epoch > _activeEpoch) {
      for (uint256 i = _activeEpoch; i < epoch; ++i) {
        uint256 underflow = _getRewardUnderflow(i);

        if (underflow > 0) {
          uint256 balance = overflowPool.requestCapital(underflow);

          _sendToDistributor(balance, i);
        }
      }
    }
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _epochAprGivenReward(uint256 epoch, uint256 reward)
    internal
    view
    returns (uint256)
  {
    // This returns an implied APR based on the distributed rewards and bonded LP at the given epoch
    State memory epochState = state[epoch];
    uint256 bondedValue = epochState.bondedValue;

    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
      if (bondedValue == 0) {
        return 0;
      }
    }

    uint256 epochsPerYear = epochState.epochsPerYear;

    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    // 10000 = 100%
    return
      ((epochState.rewarded + reward) * 10000 * epochsPerYear) / bondedValue;
  }

  function _getRewardOverflow(
    uint256 declaredReward,
    uint256 desiredAPR,
    uint256 epoch
  ) internal view returns (uint256 remainder) {
    State memory epochState = state[epoch];

    if (desiredAPR == 0) {
      // If desired APR is zero then just allow all rewards through
      return 0;
    }

    uint256 epochsPerYear = epochState.epochsPerYear;

    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    uint256 bondedValue = epochState.bondedValue;

    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
    }

    uint256 targetProfit = (desiredAPR * bondedValue) / epochsPerYear / 10000;

    if (targetProfit <= epochState.rewarded) {
      return declaredReward;
    }

    uint256 undeclaredReward = targetProfit - epochState.rewarded;

    if (undeclaredReward >= declaredReward) {
      // Declared reward doesn't make up for the difference yet
      return 0;
    }

    remainder = declaredReward - undeclaredReward;
  }

  function _getRewardUnderflow(uint256 epoch)
    internal
    view
    returns (uint256 amount)
  {
    State memory epochState = state[epoch];

    uint256 epochsPerYear = epochState.epochsPerYear;

    if (epochsPerYear == 0) {
      epochsPerYear = timekeeper.epochsPerYear();
    }

    uint256 bondedValue = epochState.bondedValue;

    if (bondedValue == 0) {
      bondedValue = bonding.averageBondedValue(epoch);
    }

    uint256 targetProfit = (epochState.desiredAPR * bondedValue) /
      epochsPerYear /
      10000;

    if (targetProfit <= epochState.rewarded) {
      // Rewarded more than target already. 0 underflow
      return 0;
    }

    return targetProfit - epochState.rewarded;
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _sendToDistributor(uint256 amount, uint256 epoch) internal {
    uint256 rewarded;
    if (amount != 0) {
      (
        uint256[] memory poolIds,
        uint256[] memory allocations,
        address[] memory distributors
      ) = bonding.poolAllocations();

      uint256 length = poolIds.length;
      uint256 balance = collateralToken.balanceOf(address(this));

      for (uint256 i; i < length; ++i) {
        uint256 share = (amount * allocations[i]) / 1e18;

        if (share == 0) {
          continue;
        }

        if (share > balance) {
          share = balance;
        }

        collateralToken.safeTransfer(distributors[i], share);
        IDistributor(distributors[i]).declareReward(share);
        balance -= share;
        rewarded += share;

        if (balance == 0) {
          break;
        }
      }
    }

    state[epoch].rewarded = state[epoch].rewarded + rewarded;
    state[epoch + 1].cumulativeCashflowApr =
      state[epoch].cumulativeCashflowApr +
      epochCashflowAPR(epoch);
    state[epoch + 1].cumulativeApr =
      state[epoch].cumulativeApr +
      epochAPR(epoch);
    state[epoch].bondedValue = bonding.averageBondedValue(epoch);
  }

  function _fillInEpochGaps(uint256 epoch) internal {
    uint256 epochsPerYear = timekeeper.epochsPerYear();
    uint256 _activeEpoch = activeEpoch; // gas

    state[_activeEpoch].bondedValue = bonding.averageBondedValue(_activeEpoch);
    state[_activeEpoch].epochsPerYear = epochsPerYear;
    state[_activeEpoch].desiredAPR = targetAPR;

    if (_activeEpoch > 0) {
      state[_activeEpoch].cumulativeCashflowApr =
        state[_activeEpoch - 1].cumulativeCashflowApr +
        epochCashflowAPR(_activeEpoch - 1);
      state[_activeEpoch].cumulativeApr =
        state[_activeEpoch - 1].cumulativeApr +
        epochAPR(_activeEpoch - 1);
    }

    // Avoid issues if gap between rewards is greater than one epoch
    for (uint256 i = _activeEpoch + 1; i <= epoch; ++i) {
      if (!state[i].active) {
        state[i].bondedValue = bonding.averageBondedValue(i);
        state[i].profit = 0;
        state[i].rewarded = 0;
        state[i].epochsPerYear = epochsPerYear;
        state[i].desiredAPR = targetAPR;
        state[i].cumulativeCashflowApr =
          state[i - 1].cumulativeCashflowApr +
          epochCashflowAPR(i - 1);
        state[i].cumulativeApr = state[i - 1].cumulativeApr + epochAPR(i - 1);
        state[i].active = true;
      }
    }

    activeEpoch = epoch;
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function populateFromPreviousThrottle(address previousThrottle, uint256 epoch)
    external
    onlyRoleMalt(ADMIN_ROLE, "Only admin role")
  {
    RewardThrottle previous = RewardThrottle(previousThrottle);
    uint256 _activeEpoch = activeEpoch; // gas

    for (uint256 i = _activeEpoch; i < epoch; ++i) {
      (
        uint256 profit,
        uint256 rewarded,
        uint256 bondedValue,
        uint256 desiredAPR,
        uint256 epochsPerYear,
        uint256 cumulativeCashflowApr,
        uint256 cumulativeApr
      ) = previous.epochData(i);

      state[i].bondedValue = bondedValue;
      state[i].profit = profit;
      state[i].rewarded = rewarded;
      state[i].epochsPerYear = epochsPerYear;
      state[i].desiredAPR = desiredAPR;
      state[i].cumulativeCashflowApr = cumulativeCashflowApr;
      state[i].cumulativeApr = cumulativeApr;
    }

    activeEpoch = epoch;
  }

  function setSmoothingPeriod(uint256 _smoothingPeriod)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_smoothingPeriod > 0, "No zero smoothing period");
    smoothingPeriod = _smoothingPeriod;
  }

  function setDesiredRunway(uint256 _runway)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_runway > 604800, "Runway must be > 1 week");
    desiredRunway = _runway;
  }

  function setAprCap(uint256 _aprCap)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_aprCap != 0, "Cap cannot be 0");
    aprCap = _aprCap;
  }

  function setAprFloor(uint256 _aprFloor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_aprFloor != 0, "Floor cannot be 0");
    aprFloor = _aprFloor;
  }

  function setUpdatePeriod(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_period >= timekeeper.epochLength(), "< 1 epoch");
    aprUpdatePeriod = _period;
  }

  function setCushionBps(uint256 _cushionBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_cushionBps != 0, "Cannot be 0");
    cushionBps = _cushionBps;
  }

  function setMaxAdjustment(uint256 _max)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_max != 0, "Cannot be 0");
    maxAdjustment = _max;
  }

  function setProportionalGain(uint256 _gain)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_gain != 0 && _gain < 10000, "Between 1-9999 inc");
    proportionalGainBps = _gain;
  }

  function _accessControl()
    internal
    override(BondingExtension, RewardOverflowExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/math/Math.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/LiquidityExtensionExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/ProfitDistributorExtension.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/ILiquidityExtension.sol";
import "../interfaces/IAuctionStartController.sol";

struct AccountCommitment {
  uint256 commitment;
  uint256 redeemed;
  uint256 maltPurchased;
  uint256 exited;
}

struct AuctionData {
  // The full amount of commitments required to return to peg
  uint256 fullRequirement;
  // total maximum desired commitments to this auction
  uint256 maxCommitments;
  // Quantity of sale currency committed to this auction
  uint256 commitments;
  // Quantity of commitments that have been exited early
  uint256 exited;
  // Malt purchased and burned using current commitments
  uint256 maltPurchased;
  // Desired starting price for the auction
  uint256 startingPrice;
  // Desired lowest price for the arbitrage token
  uint256 endingPrice;
  // Price of arbitrage tokens at conclusion of auction. This is either
  // when the duration elapses or the maxCommitments is reached
  uint256 finalPrice;
  // The peg price for the liquidity pool
  uint256 pegPrice;
  // Time when auction started
  uint256 startingTime;
  uint256 endingTime;
  // The reserve ratio at the start of the auction
  uint256 preAuctionReserveRatio;
  // The amount of arb tokens that have been executed and are now claimable
  uint256 claimableTokens;
  // The finally calculated realBurnBudget
  uint256 finalBurnBudget;
  // Is the auction currently accepting commitments?
  bool active;
  // Has this auction been finalized? Meaning any additional stabilizing
  // has been done
  bool finalized;
  // A map of all commitments to this auction by specific accounts
  mapping(address => AccountCommitment) accountCommitments;
}

/// @title Malt Arbitrage Auction
/// @author 0xScotch <[email protected]>
/// @notice The under peg Malt mechanism of dutch arbitrage auctions is implemented here
contract Auction is
  StabilizedPoolUnit,
  LiquidityExtensionExtension,
  StabilizerNodeExtension,
  DataLabExtension,
  DexHandlerExtension,
  ProfitDistributorExtension
{
  using SafeERC20 for ERC20;

  bytes32 public immutable AUCTION_AMENDER_ROLE;
  bytes32 public immutable PROFIT_ALLOCATOR_ROLE;

  address public amender;

  uint256 public unclaimedArbTokens;
  uint256 public replenishingAuctionId;
  uint256 public currentAuctionId;
  uint256 public claimableArbitrageRewards;
  uint256 public nextCommitmentId;
  uint256 public auctionLength = 600; // 10 minutes
  uint256 public arbTokenReplenishSplitBps = 7000; // 70%
  uint256 public maxAuctionEndBps = 9000; // 90% of target price
  uint256 public auctionEndReserveBps = 9000; // 90% of collateral
  uint256 public priceLookback = 0;
  uint256 public reserveRatioLookback = 30; // 30 seconds
  uint256 public dustThreshold = 1e15;
  uint256 public earlyEndThreshold;
  uint256 public costBufferBps = 1000;
  uint256 private _replenishLimit = 10;

  address public auctionStartController;

  mapping(uint256 => AuctionData) internal idToAuction;
  mapping(address => uint256[]) internal accountCommitmentEpochs;

  event AuctionCommitment(
    uint256 commitmentId,
    uint256 auctionId,
    address indexed account,
    uint256 commitment,
    uint256 purchased
  );

  event ClaimArbTokens(
    uint256 auctionId,
    address indexed account,
    uint256 amountTokens
  );

  event AuctionEnded(
    uint256 id,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 maltPurchased
  );

  event AuctionStarted(
    uint256 id,
    uint256 maxCommitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 startingTime,
    uint256 endingTime
  );

  event ArbTokenAllocation(
    uint256 replenishingAuctionId,
    uint256 maxArbAllocation
  );

  event SetAuctionLength(uint256 length);
  event SetAuctionEndReserveBps(uint256 bps);
  event SetDustThreshold(uint256 threshold);
  event SetReserveRatioLookback(uint256 lookback);
  event SetPriceLookback(uint256 lookback);
  event SetMaxAuctionEnd(uint256 maxEnd);
  event SetTokenReplenishSplit(uint256 split);
  event SetAuctionStartController(address controller);
  event SetAuctionReplenishId(uint256 id);
  event SetEarlyEndThreshold(uint256 threshold);
  event SetCostBufferBps(uint256 costBuffer);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _auctionLength,
    uint256 _earlyEndThreshold
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    auctionLength = _auctionLength;
    earlyEndThreshold = _earlyEndThreshold;

    // keccak256("AUCTION_AMENDER_ROLE")
    AUCTION_AMENDER_ROLE = 0x7cfd4d3ca87651951a5df4ff76005c956036fd9aa4b22e6e574caaa56f487f68;
    // keccak256("PROFIT_ALLOCATOR_ROLE")
    PROFIT_ALLOCATOR_ROLE = 0x00ed6845b200b0f3e6539c45853016f38cb1b785c1d044aea74da930e58c7c4c;
  }

  function setupContracts(
    address _collateralToken,
    address _liquidityExtension,
    address _stabilizerNode,
    address _maltDataLab,
    address _dexHandler,
    address _amender,
    address _profitDistributor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(!contractActive, "Auction: Already setup");
    require(_collateralToken != address(0), "Auction: Col addr(0)");
    require(_liquidityExtension != address(0), "Auction: LE addr(0)");
    require(_stabilizerNode != address(0), "Auction: StabNode addr(0)");
    require(_maltDataLab != address(0), "Auction: DataLab addr(0)");
    require(_dexHandler != address(0), "Auction: DexHandler addr(0)");
    require(_amender != address(0), "Auction: Amender addr(0)");
    require(_profitDistributor != address(0), "Auction: ProfitDist addr(0)");

    contractActive = true;

    _roleSetup(AUCTION_AMENDER_ROLE, _amender);
    _roleSetup(PROFIT_ALLOCATOR_ROLE, _profitDistributor);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);

    collateralToken = ERC20(_collateralToken);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    maltDataLab = IMaltDataLab(_maltDataLab);
    dexHandler = IDexHandler(_dexHandler);
    amender = _amender;
    profitDistributor = IProfitDistributor(_profitDistributor);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function _beforeSetStabilizerNode(address _stabilizerNode) internal override {
    _transferRole(
      _stabilizerNode,
      address(stabilizerNode),
      STABILIZER_NODE_ROLE
    );
  }

  function _beforeSetProfitDistributor(address _profitDistributor)
    internal
    override
  {
    _transferRole(
      _profitDistributor,
      address(profitDistributor),
      PROFIT_ALLOCATOR_ROLE
    );
  }

  /*
   * PUBLIC METHODS
   */
  function purchaseArbitrageTokens(uint256 amount, uint256 minPurchased)
    external
    nonReentrant
    onlyActive
  {
    uint256 currentAuction = currentAuctionId;
    require(auctionActive(currentAuction), "No auction running");
    require(amount != 0, "purchaseArb: 0 amount");

    uint256 oldBalance = collateralToken.balanceOf(address(liquidityExtension));

    collateralToken.safeTransferFrom(
      msg.sender,
      address(liquidityExtension),
      amount
    );

    uint256 realAmount = collateralToken.balanceOf(
      address(liquidityExtension)
    ) - oldBalance;

    require(realAmount <= amount, "Invalid amount");

    uint256 realCommitment = _capCommitment(currentAuction, realAmount);
    require(realCommitment != 0, "ArbTokens: Real Commitment 0");

    uint256 purchased = liquidityExtension.purchaseAndBurn(realCommitment);
    require(purchased >= minPurchased, "ArbTokens: Insufficient output");

    AuctionData storage auction = idToAuction[currentAuction];

    require(
      auction.startingTime <= block.timestamp,
      "Auction hasn't started yet"
    );
    require(auction.endingTime > block.timestamp, "Auction is already over");
    require(auction.active == true, "Auction is not active");

    auction.commitments = auction.commitments + realCommitment;

    if (auction.accountCommitments[msg.sender].commitment == 0) {
      accountCommitmentEpochs[msg.sender].push(currentAuction);
    }
    auction.accountCommitments[msg.sender].commitment =
      auction.accountCommitments[msg.sender].commitment +
      realCommitment;
    auction.accountCommitments[msg.sender].maltPurchased =
      auction.accountCommitments[msg.sender].maltPurchased +
      purchased;
    auction.maltPurchased = auction.maltPurchased + purchased;

    emit AuctionCommitment(
      nextCommitmentId,
      currentAuction,
      msg.sender,
      realCommitment,
      purchased
    );

    nextCommitmentId = nextCommitmentId + 1;

    if (auction.commitments + auction.pegPrice >= auction.maxCommitments) {
      _endAuction(currentAuction);
    }
  }

  function claimArbitrage(uint256 _auctionId) external nonReentrant onlyActive {
    uint256 amountTokens = userClaimableArbTokens(msg.sender, _auctionId);

    require(amountTokens > 0, "No claimable Arb tokens");

    AuctionData storage auction = idToAuction[_auctionId];

    require(!auction.active, "Cannot claim tokens on an active auction");

    AccountCommitment storage commitment = auction.accountCommitments[
      msg.sender
    ];

    uint256 redemption = (amountTokens * auction.finalPrice) / auction.pegPrice;
    uint256 remaining = commitment.commitment -
      commitment.redeemed -
      commitment.exited;

    if (redemption > remaining) {
      redemption = remaining;
    }

    commitment.redeemed = commitment.redeemed + redemption;

    // Unclaimed represents total outstanding, but not necessarily
    // claimable yet.
    // claimableArbitrageRewards represents total amount that is now
    // available to be claimed
    if (amountTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountTokens;
    }

    if (amountTokens > claimableArbitrageRewards) {
      claimableArbitrageRewards = 0;
    } else {
      claimableArbitrageRewards = claimableArbitrageRewards - amountTokens;
    }

    uint256 totalBalance = collateralToken.balanceOf(address(this));
    if (amountTokens + dustThreshold >= totalBalance) {
      amountTokens = totalBalance;
    }

    collateralToken.safeTransfer(msg.sender, amountTokens);

    emit ClaimArbTokens(_auctionId, msg.sender, amountTokens);
  }

  function endAuctionEarly() external onlyActive {
    uint256 currentId = currentAuctionId;
    AuctionData storage auction = idToAuction[currentId];
    require(
      auction.active && block.timestamp >= auction.startingTime,
      "No auction running"
    );
    require(
      auction.commitments >= (auction.maxCommitments - earlyEndThreshold),
      "Too early to end"
    );

    _endAuction(currentId);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function isAuctionFinished(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return
      auction.endingTime > 0 &&
      (block.timestamp >= auction.endingTime ||
        auction.finalPrice > 0 ||
        auction.commitments + auction.pegPrice >= auction.maxCommitments);
  }

  function auctionActive(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.active && block.timestamp >= auction.startingTime;
  }

  function isAuctionFinalized(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];
    return auction.finalized;
  }

  function userClaimableArbTokens(address account, uint256 auctionId)
    public
    view
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[auctionId];

    if (
      auction.claimableTokens == 0 ||
      auction.finalPrice == 0 ||
      auction.commitments == 0
    ) {
      return 0;
    }

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 totalTokens = (auction.commitments * auction.pegPrice) /
      auction.finalPrice;

    uint256 claimablePerc = (auction.claimableTokens * auction.pegPrice) /
      totalTokens;

    uint256 amountTokens = (commitment.commitment * auction.pegPrice) /
      auction.finalPrice;
    uint256 redeemedTokens = (commitment.redeemed * auction.pegPrice) /
      auction.finalPrice;
    uint256 exitedTokens = (commitment.exited * auction.pegPrice) /
      auction.finalPrice;

    uint256 amountOut = ((amountTokens * claimablePerc) / auction.pegPrice) -
      redeemedTokens -
      exitedTokens;

    // Avoid leaving dust behind
    if (amountOut < dustThreshold) {
      return 0;
    }

    return amountOut;
  }

  function balanceOfArbTokens(uint256 _auctionId, address account)
    public
    view
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[_auctionId];

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 remaining = commitment.commitment -
      commitment.redeemed -
      commitment.exited;

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(_auctionId);
    }

    return (remaining * auction.pegPrice) / price;
  }

  function averageMaltPrice(uint256 _id) external view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.maltPurchased == 0) {
      return 0;
    }

    return (auction.commitments * auction.pegPrice) / auction.maltPurchased;
  }

  function currentPrice(uint256 _id) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.startingTime == 0) {
      return maltDataLab.priceTarget();
    }

    uint256 secondsSinceStart = 0;

    if (block.timestamp > auction.startingTime) {
      secondsSinceStart = block.timestamp - auction.startingTime;
    }

    uint256 auctionDuration = auction.endingTime - auction.startingTime;

    if (secondsSinceStart >= auctionDuration) {
      return auction.endingPrice;
    }

    uint256 totalPriceDelta = auction.startingPrice - auction.endingPrice;

    uint256 currentPriceDelta = (totalPriceDelta * secondsSinceStart) /
      auctionDuration;

    return auction.startingPrice - currentPriceDelta;
  }

  function getAuctionCommitments(uint256 _id)
    public
    view
    returns (uint256 commitments, uint256 maxCommitments)
  {
    AuctionData storage auction = idToAuction[_id];

    return (auction.commitments, auction.maxCommitments);
  }

  function getAuctionPrices(uint256 _id)
    public
    view
    returns (
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (auction.startingPrice, auction.endingPrice, auction.finalPrice);
  }

  function auctionExists(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.startingTime > 0;
  }

  function auctionLive() public view returns (bool) {
    return auctionExists(currentAuctionId);
  }

  function getAccountCommitments(address account)
    external
    view
    returns (
      uint256[] memory auctions,
      uint256[] memory commitments,
      uint256[] memory awardedTokens,
      uint256[] memory redeemedTokens,
      uint256[] memory exitedTokens,
      uint256[] memory finalPrice,
      uint256[] memory claimable,
      bool[] memory finished
    )
  {
    uint256[] memory epochCommitments = accountCommitmentEpochs[account];

    auctions = new uint256[](epochCommitments.length);
    commitments = new uint256[](epochCommitments.length);
    awardedTokens = new uint256[](epochCommitments.length);
    redeemedTokens = new uint256[](epochCommitments.length);
    exitedTokens = new uint256[](epochCommitments.length);
    finalPrice = new uint256[](epochCommitments.length);
    claimable = new uint256[](epochCommitments.length);
    finished = new bool[](epochCommitments.length);

    for (uint256 i = 0; i < epochCommitments.length; ++i) {
      AuctionData storage auction = idToAuction[epochCommitments[i]];

      AccountCommitment storage commitment = auction.accountCommitments[
        account
      ];

      uint256 price = auction.finalPrice;

      if (auction.finalPrice == 0) {
        price = currentPrice(epochCommitments[i]);
      }

      auctions[i] = epochCommitments[i];
      commitments[i] = commitment.commitment;
      awardedTokens[i] = (commitment.commitment * auction.pegPrice) / price;
      redeemedTokens[i] = (commitment.redeemed * auction.pegPrice) / price;
      exitedTokens[i] = (commitment.exited * auction.pegPrice) / price;
      finalPrice[i] = price;
      claimable[i] = userClaimableArbTokens(account, epochCommitments[i]);
      finished[i] = isAuctionFinished(epochCommitments[i]);
    }
  }

  function getAccountCommitmentAuctions(address account)
    external
    view
    returns (uint256[] memory)
  {
    return accountCommitmentEpochs[account];
  }

  function getAuctionParticipationForAccount(address account, uint256 auctionId)
    external
    view
    returns (
      uint256 commitment,
      uint256 redeemed,
      uint256 maltPurchased,
      uint256 exited
    )
  {
    AccountCommitment storage _commitment = idToAuction[auctionId]
      .accountCommitments[account];

    return (
      _commitment.commitment,
      _commitment.redeemed,
      _commitment.maltPurchased,
      _commitment.exited
    );
  }

  function hasOngoingAuction() external view returns (bool) {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return auction.startingTime > 0 && !auction.finalized;
  }

  function getActiveAuction()
    external
    view
    returns (
      uint256 auctionId,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget
    )
  {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return (
      currentAuctionId,
      auction.maxCommitments,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget
    );
  }

  function getAuction(uint256 _id)
    public
    view
    returns (
      uint256 fullRequirement,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 exited
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (
      auction.fullRequirement,
      auction.maxCommitments,
      auction.commitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.exited
    );
  }

  function getAuctionCore(uint256 _id)
    public
    view
    returns (
      uint256 auctionId,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 preAuctionReserveRatio,
      bool active
    )
  {
    AuctionData storage auction = idToAuction[_id];

    return (
      _id,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.preAuctionReserveRatio,
      auction.active
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _triggerAuction(
    uint256 pegPrice,
    uint256 rRatio,
    uint256 purchaseAmount
  ) internal returns (bool) {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController)
        .checkForStart();
      if (!success) {
        return false;
      }
    }
    uint256 _auctionIndex = currentAuctionId;

    (uint256 startingPrice, uint256 endingPrice) = _calculateAuctionPricing(
      rRatio,
      purchaseAmount
    );

    AuctionData storage auction = idToAuction[_auctionIndex];

    uint256 decimals = collateralToken.decimals();
    uint256 maxCommitments = _calcRealMaxRaise(
      purchaseAmount,
      rRatio,
      decimals
    );

    if (maxCommitments == 0) {
      return false;
    }

    auction.fullRequirement = purchaseAmount; // fullRequirement
    auction.maxCommitments = maxCommitments;
    auction.startingPrice = startingPrice;
    auction.endingPrice = endingPrice;
    auction.pegPrice = pegPrice;
    auction.startingTime = block.timestamp; // startingTime
    auction.endingTime = block.timestamp + auctionLength; // endingTime
    auction.active = true; // active
    auction.preAuctionReserveRatio = rRatio; // preAuctionReserveRatio
    auction.finalized = false; // finalized

    require(
      auction.endingTime == uint256(uint64(auction.endingTime)),
      "ending not eq"
    );

    emit AuctionStarted(
      _auctionIndex,
      auction.maxCommitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.startingTime,
      auction.endingTime
    );
    return true;
  }

  function _capCommitment(uint256 _id, uint256 _commitment)
    internal
    view
    returns (uint256 realCommitment)
  {
    AuctionData storage auction = idToAuction[_id];

    realCommitment = _commitment;

    if (auction.commitments + _commitment >= auction.maxCommitments) {
      realCommitment = auction.maxCommitments - auction.commitments;
    }
  }

  function _endAuction(uint256 _id) internal {
    AuctionData storage auction = idToAuction[_id];

    require(auction.active == true, "Auction is already over");

    auction.active = false;
    auction.finalPrice = currentPrice(_id);

    uint256 amountArbTokens = (auction.commitments * auction.pegPrice) /
      auction.finalPrice;
    unclaimedArbTokens = unclaimedArbTokens + amountArbTokens;

    emit AuctionEnded(
      _id,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.maltPurchased
    );
  }

  function _finalizeAuction(uint256 auctionId) internal {
    (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    ) = _setupAuctionFinalization(auctionId);

    if (commitments >= fullRequirement) {
      return;
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    // priceTarget - preAuctionReserveRatio represents maximum deficit per token
    // priceTarget divided by the max deficit is equivalent to 1 over the max deficit given we are in uint decimal
    // (commitments * 1/maxDeficit) - commitments
    uint256 maxBurnSpend = (commitments * priceTarget) /
      (priceTarget - preAuctionReserveRatio) -
      commitments;

    uint256 totalTokens = (commitments * priceTarget) / finalPrice;

    uint256 premiumExcess = 0;

    // The assumption here is that each token will be worth 1 Malt when redeemed.
    // Therefore if totalTokens is greater than the malt purchased then there is a net supply growth
    // After the tokens are repaid. We want this process to be neutral to supply at the very worst.
    if (totalTokens > maltPurchased) {
      // This also assumes current purchase price of Malt is $1, which is higher than it will be in practice.
      // So the premium excess will actually ensure slight net negative supply growth.
      premiumExcess = totalTokens - maltPurchased;
    }

    uint256 realBurnBudget = maltDataLab.getRealBurnBudget(
      maxBurnSpend,
      premiumExcess
    );

    if (realBurnBudget > 0) {
      AuctionData storage auction = idToAuction[auctionId];

      auction.finalBurnBudget = realBurnBudget;
      liquidityExtension.allocateBurnBudget(realBurnBudget);
    }
  }

  function _setupAuctionFinalization(uint256 auctionId)
    internal
    returns (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    )
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.startingTime > 0, "No auction available for the given id");

    auction.finalized = true;

    if (auction.maltPurchased > 0) {
      avgMaltPrice =
        (auction.commitments * auction.pegPrice) /
        auction.maltPurchased;
    }

    return (
      avgMaltPrice,
      auction.commitments,
      auction.fullRequirement,
      auction.maltPurchased,
      auction.finalPrice,
      auction.preAuctionReserveRatio
    );
  }

  function _calcRealMaxRaise(
    uint256 purchaseAmount,
    uint256 rRatio,
    uint256 decimals
  ) internal pure returns (uint256) {
    uint256 unity = 10**decimals;
    uint256 realBurn = (purchaseAmount * Math.min(rRatio, unity)) / unity;

    if (purchaseAmount > realBurn) {
      return purchaseAmount - realBurn;
    }

    return 0;
  }

  function _calculateAuctionPricing(uint256 rRatio, uint256 maxCommitments)
    internal
    view
    returns (uint256 startingPrice, uint256 endingPrice)
  {
    uint256 priceTarget = maltDataLab.priceTarget();
    if (rRatio > priceTarget) {
      rRatio = priceTarget;
    }
    startingPrice = maltDataLab.maltPriceAverage(priceLookback);
    uint256 liquidityExtensionBalance = collateralToken.balanceOf(
      address(liquidityExtension)
    );

    (uint256 latestPrice, ) = maltDataLab.lastMaltPrice();
    uint256 expectedMaltCost = priceTarget;
    if (latestPrice < priceTarget) {
      expectedMaltCost =
        latestPrice +
        ((priceTarget - latestPrice) * (5000 + costBufferBps)) /
        10000;
    }

    // rRatio should never be large enough for this to overflow
    // uint256 absoluteBottom = rRatio * auctionEndReserveBps / 10000;

    // Absolute bottom is the lowest price
    uint256 decimals = collateralToken.decimals();
    uint256 unity = 10**decimals;
    uint256 absoluteBottom = (maxCommitments * unity) /
      (liquidityExtensionBalance +
        ((maxCommitments * unity) / expectedMaltCost));

    uint256 idealBottom = 1; // 1wei just to avoid any issues with it being 0

    if (expectedMaltCost > rRatio) {
      idealBottom = expectedMaltCost - rRatio;
    }

    // price should never go below absoluteBottom
    if (idealBottom < absoluteBottom) {
      idealBottom = absoluteBottom;
    }

    // price should never start above the peg price
    if (startingPrice > priceTarget) {
      startingPrice = priceTarget;
    }

    if (idealBottom < startingPrice) {
      endingPrice = idealBottom;
    } else if (absoluteBottom < startingPrice) {
      endingPrice = absoluteBottom;
    } else {
      // There are no bottom prices that work with
      // the startingPrice so set start and end to
      // the absoluteBottom
      startingPrice = absoluteBottom;
      endingPrice = absoluteBottom;
    }

    // priceTarget should never be large enough to overflow here
    uint256 maxPrice = (priceTarget * maxAuctionEndBps) / 10000;

    if (endingPrice > maxPrice && maxPrice > absoluteBottom) {
      endingPrice = maxPrice;
    }
  }

  function _checkAuctionFinalization() internal {
    uint256 currentAuction = currentAuctionId;

    if (isAuctionFinished(currentAuction)) {
      if (auctionActive(currentAuction)) {
        _endAuction(currentAuction);
      }

      if (!isAuctionFinalized(currentAuction)) {
        _finalizeAuction(currentAuction);
      }
      currentAuctionId = currentAuction + 1;
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function checkAuctionFinalization()
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    onlyActive
  {
    _checkAuctionFinalization();
  }

  function accountExit(
    address account,
    uint256 auctionId,
    uint256 amount
  )
    external
    onlyRoleMalt(AUCTION_AMENDER_ROLE, "Only auction amender")
    onlyActive
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(
      auction.accountCommitments[account].commitment >= amount,
      "amend: amount underflows"
    );

    if (auction.finalPrice == 0) {
      return;
    }

    auction.exited += amount;
    auction.accountCommitments[account].exited += amount;

    uint256 amountArbTokens = (amount * auction.pegPrice) / auction.finalPrice;

    if (amountArbTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens - amountArbTokens;
    }
  }

  function allocateArbRewards(uint256 rewarded)
    external
    onlyRoleMalt(PROFIT_ALLOCATOR_ROLE, "Must be profit allocator node")
    onlyActive
    returns (uint256)
  {
    AuctionData storage auction;
    uint256 replenishingId = replenishingAuctionId; // gas
    uint256 absorbedCapital;
    uint256 count = 1;
    uint256 maxArbAllocation = (rewarded * arbTokenReplenishSplitBps) / 10000;

    // Limit iterations to avoid unbounded loops
    while (count < _replenishLimit) {
      auction = idToAuction[replenishingId];

      if (
        auction.finalPrice == 0 ||
        auction.startingTime == 0 ||
        !auction.finalized
      ) {
        // if finalPrice or startingTime are not set then this auction has not happened yet
        // So we are at the end of the journey
        break;
      }

      if (auction.commitments > 0) {
        uint256 totalTokens = (auction.commitments * auction.pegPrice) /
          auction.finalPrice;

        if (auction.claimableTokens < totalTokens) {
          uint256 requirement = totalTokens - auction.claimableTokens;

          uint256 usable = maxArbAllocation - absorbedCapital;

          if (absorbedCapital + requirement < maxArbAllocation) {
            usable = requirement;
          }

          auction.claimableTokens = auction.claimableTokens + usable;
          rewarded = rewarded - usable;
          claimableArbitrageRewards = claimableArbitrageRewards + usable;

          absorbedCapital += usable;

          emit ArbTokenAllocation(replenishingId, usable);

          if (auction.claimableTokens < totalTokens) {
            break;
          }
        }
      }

      replenishingId += 1;
      count += 1;
    }

    replenishingAuctionId = replenishingId;

    if (absorbedCapital != 0) {
      collateralToken.safeTransferFrom(
        address(profitDistributor),
        address(this),
        absorbedCapital
      );
    }

    return rewarded;
  }

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    onlyRoleMalt(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    onlyActive
    returns (bool)
  {
    if (purchaseAmount == 0 || auctionExists(currentAuctionId)) {
      return false;
    }

    // Data is consistent here as this method as the stabilizer
    // calls maltDataLab.trackPool at the start of stabilize
    (uint256 rRatio, ) = liquidityExtension.reserveRatioAverage(
      reserveRatioLookback
    );

    return _triggerAuction(pegPrice, rRatio, purchaseAmount);
  }

  function setAuctionLength(uint256 _length)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_length > 0, "Length must be larger than 0");
    auctionLength = _length;
    emit SetAuctionLength(_length);
  }

  function setAuctionReplenishId(uint256 _id)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    replenishingAuctionId = _id;
    emit SetAuctionReplenishId(_id);
  }

  function setAuctionAmender(address _amender)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater privilege")
  {
    require(_amender != address(0), "Cannot set 0 address");
    _transferRole(_amender, amender, AUCTION_AMENDER_ROLE);
    amender = _amender;
  }

  function setAuctionStartController(address _controller)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setTokenReplenishSplit(uint256 _split)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_split != 0 && _split <= 10000, "Must be between 0-100%");
    arbTokenReplenishSplitBps = _split;
    emit SetTokenReplenishSplit(_split);
  }

  function setMaxAuctionEnd(uint256 _maxEnd)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_maxEnd != 0 && _maxEnd <= 10000, "Must be between 0-100%");
    maxAuctionEndBps = _maxEnd;
    emit SetMaxAuctionEnd(_maxEnd);
  }

  function setPriceLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    priceLookback = _lookback;
    emit SetPriceLookback(_lookback);
  }

  function setReserveRatioLookback(uint256 _lookback)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    reserveRatioLookback = _lookback;
    emit SetReserveRatioLookback(_lookback);
  }

  function setAuctionEndReserveBps(uint256 _bps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_bps != 0 && _bps < 10000, "Must be between 0-100%");
    auctionEndReserveBps = _bps;
    emit SetAuctionEndReserveBps(_bps);
  }

  function setDustThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    dustThreshold = _threshold;
    emit SetDustThreshold(_threshold);
  }

  function setEarlyEndThreshold(uint256 _threshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    earlyEndThreshold = _threshold;
    emit SetEarlyEndThreshold(_threshold);
  }

  function setCostBufferBps(uint256 _costBuffer)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_costBuffer != 0 && _costBuffer <= 5000, "Must be > 0 && <= 5000");
    costBufferBps = _costBuffer;
    emit SetCostBufferBps(_costBuffer);
  }

  function adminEndAuction()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    uint256 currentId = currentAuctionId;
    require(auctionActive(currentId), "No auction running");
    _endAuction(currentId);
  }

  function setReplenishLimit(uint256 _limit)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_limit != 0, "Not 0");
    _replenishLimit = _limit;
  }

  function _accessControl()
    internal
    override(
      LiquidityExtensionExtension,
      StabilizerNodeExtension,
      DataLabExtension,
      DexHandlerExtension,
      ProfitDistributorExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/math/Math.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "./Auction.sol";

struct EarlyExitData {
  uint256 exitedEarly;
  uint256 earlyExitReturn;
  uint256 maltUsed;
}

struct AuctionExits {
  uint256 exitedEarly;
  uint256 earlyExitReturn;
  uint256 maltUsed;
  mapping(address => EarlyExitData) accountExits;
}

/// @title Auction Escape Hatch
/// @author 0xScotch <[email protected]>
/// @notice Functionality to reduce risk profile of holding arbitrage tokens by allowing early exit
contract AuctionEscapeHatch is
  StabilizedPoolUnit,
  AuctionExtension,
  DexHandlerExtension
{
  using SafeERC20 for ERC20;

  uint256 public maxEarlyExitBps = 2000; // 20%
  uint256 public cooloffPeriod = 60 * 60 * 24; // 24 hours

  mapping(uint256 => AuctionExits) internal auctionEarlyExits;

  event EarlyExit(address account, uint256 amount, uint256 received);
  event SetEarlyExitBps(uint256 earlyExitBps);
  event SetCooloffPeriod(uint256 period);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {}

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _auction,
    address _dexHandler,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(!contractActive, "EscapeHatch: Already setup");
    require(_malt != address(0), "EscapeHatch: Malt addr(0)");
    require(_collateralToken != address(0), "EscapeHatch: Col addr(0)");
    require(_auction != address(0), "EscapeHatch: Auction addr(0)");
    require(_dexHandler != address(0), "EscapeHatch: DexHandler addr(0)");

    contractActive = true;

    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
    auction = IAuction(_auction);
    dexHandler = IDexHandler(_dexHandler);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function exitEarly(
    uint256 _auctionId,
    uint256 amount,
    uint256 minOut
  ) external nonReentrant onlyActive {
    AuctionExits storage auctionExits = auctionEarlyExits[_auctionId];

    (, uint256 maltQuantity, uint256 newAmount) = earlyExitReturn(
      msg.sender,
      _auctionId,
      amount
    );

    require(maltQuantity > 0, "ExitEarly: Insufficient output");

    malt.mint(address(dexHandler), maltQuantity);
    // Early exits happen below peg in recovery mode
    // So risk of sandwich is very low
    uint256 amountOut = dexHandler.sellMalt(maltQuantity, 5000);

    require(amountOut >= minOut, "EarlyExit: Insufficient output");

    auctionExits.exitedEarly += newAmount;
    auctionExits.earlyExitReturn += amountOut;
    auctionExits.maltUsed += maltQuantity;
    auctionExits.accountExits[msg.sender].exitedEarly += newAmount;
    auctionExits.accountExits[msg.sender].earlyExitReturn += amountOut;
    auctionExits.accountExits[msg.sender].maltUsed += maltQuantity;

    auction.accountExit(msg.sender, _auctionId, newAmount);

    collateralToken.safeTransfer(msg.sender, amountOut);
    emit EarlyExit(msg.sender, newAmount, amountOut);
  }

  function earlyExitReturn(
    address account,
    uint256 _auctionId,
    uint256 amount
  )
    public
    view
    returns (
      uint256 exitAmount,
      uint256 maltValue,
      uint256 usedAmount
    )
  {
    // We don't need all the values
    (
      ,
      ,
      ,
      ,
      ,
      uint256 pegPrice,
      ,
      uint256 auctionEndTime,
      ,
      bool active
    ) = auction.getAuctionCore(_auctionId);

    // Cannot exit within 10% of the cooloffPeriod
    if (
      active ||
      block.timestamp < auctionEndTime + (cooloffPeriod * 10000) / 100000
    ) {
      return (0, 0, amount);
    }

    (uint256 maltQuantity, uint256 newAmount) = _getEarlyExitMaltQuantity(
      account,
      _auctionId,
      amount
    );

    if (maltQuantity == 0) {
      return (0, 0, newAmount);
    }

    // Reading direct from pool for this isn't bad as recovery
    // Mode avoids price being manipulated upwards
    (uint256 currentPrice, ) = dexHandler.maltMarketPrice();
    require(currentPrice != 0, "Price should be more than zero");

    uint256 fullReturn = (maltQuantity * currentPrice) / pegPrice;

    // setCooloffPeriod guards against cooloffPeriod ever being 0
    uint256 progressionBps = ((block.timestamp - auctionEndTime) * 10000) /
      cooloffPeriod;
    if (progressionBps > 10000) {
      progressionBps = 10000;
    }

    if (fullReturn > newAmount) {
      // Allow a % of profit to be realised
      // Add additional * 10,000 then / 10,000 to increase precision
      uint256 maxProfit = ((fullReturn - newAmount) *
        ((maxEarlyExitBps * 10000 * progressionBps) / 10000)) /
        10000 /
        10000;
      fullReturn = newAmount + maxProfit;
    }

    return (fullReturn, (fullReturn * pegPrice) / currentPrice, newAmount);
  }

  function accountEarlyExitReturns(address account)
    external
    view
    returns (uint256[] memory auctions, uint256[] memory earlyExitAmount)
  {
    auctions = auction.getAccountCommitmentAuctions(account);
    uint256 length = auctions.length;

    earlyExitAmount = new uint256[](length);

    for (uint256 i; i < length; ++i) {
      (uint256 commitment, uint256 redeemed, , uint256 exited) = auction
        .getAuctionParticipationForAccount(account, auctions[i]);
      uint256 amount = commitment - redeemed - exited;
      (uint256 exitAmount, , ) = earlyExitReturn(account, auctions[i], amount);
      earlyExitAmount[i] = exitAmount;
    }
  }

  function accountAuctionExits(address account, uint256 auctionId)
    external
    view
    returns (
      uint256 exitedEarly,
      uint256 earlyExitReturn,
      uint256 maltUsed
    )
  {
    EarlyExitData storage accountExits = auctionEarlyExits[auctionId]
      .accountExits[account];

    return (
      accountExits.exitedEarly,
      accountExits.earlyExitReturn,
      accountExits.maltUsed
    );
  }

  function globalAuctionExits(uint256 auctionId)
    external
    view
    returns (
      uint256 exitedEarly,
      uint256 earlyExitReturn,
      uint256 maltUsed
    )
  {
    AuctionExits storage auctionExits = auctionEarlyExits[auctionId];

    return (
      auctionExits.exitedEarly,
      auctionExits.earlyExitReturn,
      auctionExits.maltUsed
    );
  }

  /*
   * INTERNAL METHODS
   */
  function _calculateMaltRequiredForExit(
    uint256 _auctionId,
    uint256 amount,
    uint256 exitedEarly
  ) internal returns (uint256, uint256) {}

  function _getEarlyExitMaltQuantity(
    address account,
    uint256 _auctionId,
    uint256 amount
  ) internal view returns (uint256 maltQuantity, uint256 newAmount) {
    (
      uint256 userCommitment,
      uint256 userRedeemed,
      uint256 userMaltPurchased,
      uint256 earlyExited
    ) = auction.getAuctionParticipationForAccount(account, _auctionId);

    uint256 exitedEarly = auctionEarlyExits[_auctionId]
      .accountExits[account]
      .exitedEarly;

    // This should never overflow due to guards in redemption code
    uint256 userOutstanding = userCommitment - userRedeemed - exitedEarly;

    if (amount > userOutstanding) {
      amount = userOutstanding;
    }

    if (amount == 0) {
      return (0, 0);
    }

    newAmount = amount;

    maltQuantity = (userMaltPurchased * amount) / userCommitment;
  }

  /*
   * PRIVILEDGED METHODS
   */
  function setEarlyExitBps(uint256 _earlyExitBps)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(
      _earlyExitBps != 0 && _earlyExitBps <= 10000,
      "Must be between 0-100%"
    );
    maxEarlyExitBps = _earlyExitBps;
    emit SetEarlyExitBps(_earlyExitBps);
  }

  function setCooloffPeriod(uint256 _period)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_period != 0, "Cannot have 0 cool-off period");
    cooloffPeriod = _period;
    emit SetCooloffPeriod(_period);
  }

  function _accessControl()
    internal
    override(AuctionExtension, DexHandlerExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITimekeeper.sol";
import "../interfaces/IMiningService.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IBondExtension.sol";
import "../libraries/SafeBurnMintableERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/MiningServiceExtension.sol";

struct UserState {
  uint256 bonded;
  uint256 bondedEpoch;
}

struct EpochState {
  uint256 lastTotalBonded;
  uint256 lastUpdateTime;
  uint256 cumulativeTotalBonded;
}

struct RewardPool {
  uint256 id;
  uint256 index; // index into the activePools array
  uint256 totalBonded;
  address distributor;
  bytes32 accessRole;
  bool active;
  string name;
}

/// @title LP Bonding
/// @author 0xScotch <[email protected]>
/// @notice The contract which LP tokens are bonded to to make a user eligible for protocol rewards
contract Bonding is
  StabilizedPoolUnit,
  DexHandlerExtension,
  DataLabExtension,
  MiningServiceExtension
{
  using SafeERC20 for ERC20;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  bytes32 public immutable LINEAR_RECIEVER_ROLE;

  ERC20 public lpToken;
  ITimekeeper public timekeeper;
  IBondExtension public bondExtension;

  uint256 internal _globalBonded;
  uint256 internal _currentEpoch;
  mapping(uint256 => RewardPool) public rewardPools;
  mapping(uint256 => mapping(address => UserState)) internal userState;
  mapping(uint256 => EpochState) internal epochState;
  uint256[] public activePools;
  uint256 public stakeTokenDecimals;

  event Bond(address indexed account, uint256 indexed poolId, uint256 value);
  event Unbond(address indexed account, uint256 indexed poolId, uint256 value);
  event UnbondAndBreak(
    address indexed account,
    uint256 indexed poolId,
    uint256 amountLPToken,
    uint256 amountMalt,
    uint256 amountReward
  );
  event NewBondingRole(string name, bytes32 role);
  event TogglePoolActive(uint256 indexed poolId, bool active);
  event AddRewardPool(
    uint256 indexed poolId,
    string name,
    bool active,
    bytes32 accessRole
  );
  event SetPoolDistributor(uint256 indexed poolId, address distributor);
  event SetBondExtension(address extension);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address _timekeeper
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    require(_timekeeper != address(0), "Bonding: Timekeeper addr(0)");

    LINEAR_RECIEVER_ROLE = 0xc4d3376b5b3c3e729e4e96e641ab90a69629a483775e55f8b2db81b64a522420;
    _setRoleAdmin(
      0xc4d3376b5b3c3e729e4e96e641ab90a69629a483775e55f8b2db81b64a522420,
      ADMIN_ROLE
    );

    timekeeper = ITimekeeper(_timekeeper);
  }

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _lpToken,
    address _miningService,
    address _dexHandler,
    address _maltDataLab,
    address _vestingDistributor,
    address _linearDistributor
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "Bonding: Already setup");
    require(_malt != address(0), "Bonding: Malt addr(0)");
    require(_collateralToken != address(0), "Bonding: RewardToken addr(0)");
    require(_lpToken != address(0), "Bonding: lpToken addr(0)");
    require(_miningService != address(0), "Bonding: MiningSvc addr(0)");
    require(_dexHandler != address(0), "Bonding: DexHandler addr(0)");
    require(_maltDataLab != address(0), "Bonding: DataLab addr(0)");

    contractActive = true;

    lpToken = ERC20(_lpToken);
    stakeTokenDecimals = lpToken.decimals();
    miningService = IMiningService(_miningService);
    dexHandler = IDexHandler(_dexHandler);
    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
    maltDataLab = IMaltDataLab(_maltDataLab);

    rewardPools[0] = RewardPool({
      id: 0,
      index: 0,
      totalBonded: 0,
      distributor: _vestingDistributor,
      accessRole: bytes32(0),
      active: true,
      name: "Vesting"
    });

    // Will be used in the future
    rewardPools[1] = RewardPool({
      id: 1,
      index: 1,
      totalBonded: 0,
      distributor: _linearDistributor, // Will set in future
      accessRole: LINEAR_RECIEVER_ROLE,
      active: false,
      name: "Linear"
    });

    activePools.push(0);

    (, address updater, ) = poolFactory.getPool(_lpToken);
    _setPoolUpdater(updater);
  }

  function bond(uint256 poolId, uint256 amount) external {
    bondToAccount(msg.sender, poolId, amount);
  }

  function bondToAccount(
    address account,
    uint256 poolId,
    uint256 amount
  ) public nonReentrant onlyActive {
    require(account != address(0), "Bonding: 0x0");
    require(amount > 0, "Cannot bond 0");

    RewardPool memory pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown Pool");
    require(pool.active, "Pool is not active");
    require(pool.distributor != address(0), "Pool not configured");

    if (pool.accessRole != bytes32(0)) {
      // This throws if msg.sender doesn't have correct role
      _onlyRoleMalt(pool.accessRole, "Not allowed to bond to this pool");
    }

    miningService.onBond(account, poolId, amount);

    _bond(account, poolId, amount);
  }

  function unbond(uint256 poolId, uint256 amount)
    external
    nonReentrant
    onlyActive
  {
    require(amount > 0, "Cannot unbond 0");

    uint256 bondedBalance = balanceOfBonded(poolId, msg.sender);

    require(bondedBalance > 0, "< bonded balance");
    require(amount <= bondedBalance, "< bonded balance");

    // Avoid leaving dust behind
    if (amount + (10**(stakeTokenDecimals - 2)) > bondedBalance) {
      amount = bondedBalance;
    }

    miningService.onUnbond(msg.sender, poolId, amount);

    _unbond(poolId, amount);
  }

  function unbondAndBreak(
    uint256 poolId,
    uint256 amount,
    uint256 slippageBps
  ) external nonReentrant onlyActive {
    require(amount > 0, "Cannot unbond 0");

    uint256 bondedBalance = balanceOfBonded(poolId, msg.sender);

    require(bondedBalance > 0, "< bonded balance");
    require(amount <= bondedBalance, "< bonded balance");

    // Avoid leaving dust behind
    if (amount + (10**(stakeTokenDecimals - 2)) > bondedBalance) {
      amount = bondedBalance;
    }

    miningService.onUnbond(msg.sender, poolId, amount);

    _unbondAndBreak(poolId, amount, slippageBps);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function averageBondedValue(uint256 epoch) public view returns (uint256) {
    EpochState storage state = epochState[epoch];
    uint256 epochLength = timekeeper.epochLength();
    uint256 timeElapsed = epochLength;
    uint256 epochStartTime = timekeeper.getEpochStartTime(epoch);
    uint256 diff;
    uint256 lastUpdateTime = state.lastUpdateTime;
    uint256 lastTotalBonded = state.lastTotalBonded;

    if (lastUpdateTime == 0) {
      lastUpdateTime = epochStartTime;
    }

    if (lastTotalBonded == 0) {
      lastTotalBonded = _globalBonded;
    }

    if (block.timestamp < epochStartTime) {
      return 0;
    }

    if (epochStartTime + epochLength <= lastUpdateTime) {
      return
        maltDataLab.realValueOfLPToken(
          (state.cumulativeTotalBonded) / epochLength
        );
    }

    if (epochStartTime + epochLength < block.timestamp) {
      // The desired epoch is in the past
      diff = (epochStartTime + epochLength) - lastUpdateTime;
    } else {
      diff = block.timestamp - lastUpdateTime;
      timeElapsed = block.timestamp - epochStartTime;
    }

    if (timeElapsed == 0) {
      // Only way timeElapsed should == 0 is when block.timestamp == epochStartTime
      // Therefore just return the lastTotalBonded value
      return maltDataLab.realValueOfLPToken(lastTotalBonded);
    }

    uint256 endValue = state.cumulativeTotalBonded + (lastTotalBonded * diff);
    return maltDataLab.realValueOfLPToken((endValue) / timeElapsed);
  }

  function totalBonded() public view returns (uint256) {
    return _globalBonded;
  }

  function totalBondedByPool(uint256 poolId) public view returns (uint256) {
    return rewardPools[poolId].totalBonded;
  }

  function valueOfBonded(uint256 poolId) public view returns (uint256) {
    return maltDataLab.realValueOfLPToken(rewardPools[poolId].totalBonded);
  }

  function allActivePools()
    public
    view
    returns (
      uint256[] memory ids,
      uint256[] memory bondedTotals,
      address[] memory distributors,
      bytes32[] memory accessRoles,
      string[] memory names
    )
  {
    uint256[] memory poolIds = activePools;
    uint256 length = poolIds.length;

    ids = new uint256[](length);
    bondedTotals = new uint256[](length);
    distributors = new address[](length);
    accessRoles = new bytes32[](length);
    names = new string[](length);

    for (uint256 i; i < length; ++i) {
      ids[i] = rewardPools[poolIds[i]].id;
      bondedTotals[i] = rewardPools[poolIds[i]].totalBonded;
      distributors[i] = rewardPools[poolIds[i]].distributor;
      accessRoles[i] = rewardPools[poolIds[i]].accessRole;
      names[i] = rewardPools[poolIds[i]].name;
    }

    return (ids, bondedTotals, distributors, accessRoles, names);
  }

  function balanceOfBonded(uint256 poolId, address account)
    public
    view
    returns (uint256)
  {
    return userState[poolId][account].bonded;
  }

  function bondedEpoch(uint256 poolId, address account)
    public
    view
    returns (uint256)
  {
    return userState[poolId][account].bondedEpoch;
  }

  function epochData(uint256 epoch)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      epochState[epoch].lastTotalBonded,
      epochState[epoch].lastUpdateTime,
      epochState[epoch].cumulativeTotalBonded
    );
  }

  function poolAllocations()
    public
    view
    returns (
      uint256[] memory poolIds,
      uint256[] memory allocations,
      address[] memory distributors
    )
  {
    uint256 totalBonded = _globalBonded;

    uint256[] memory poolIds = activePools;
    uint256 length = poolIds.length;
    uint256[] memory allocations = new uint256[](length);
    address[] memory distributors = new address[](length);

    if (totalBonded == 0) {
      return (poolIds, allocations, distributors);
    }

    for (uint256 i; i < length; ++i) {
      RewardPool memory pool = rewardPools[poolIds[i]];
      allocations[i] = (pool.totalBonded * 1e18) / totalBonded;
      distributors[i] = pool.distributor;
    }

    return (poolIds, allocations, distributors);
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _balanceCheck() internal view {
    require(
      lpToken.balanceOf(address(this)) >= totalBonded(),
      "Balance inconsistency"
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _bond(
    address account,
    uint256 poolId,
    uint256 amount
  ) internal {
    uint256 oldBalance = lpToken.balanceOf(address(this));
    lpToken.safeTransferFrom(msg.sender, address(this), amount);
    amount = lpToken.balanceOf(address(this)) - oldBalance;

    _addToBonded(account, poolId, amount);

    _balanceCheck();

    if (address(bondExtension) != address(0)) {
      bondExtension.onBond(account, poolId, amount);
    }

    emit Bond(account, poolId, amount);
  }

  function _unbond(uint256 poolId, uint256 amountLPToken) internal {
    _removeFromBonded(msg.sender, poolId, amountLPToken);
    lpToken.safeTransfer(msg.sender, amountLPToken);

    _balanceCheck();

    if (address(bondExtension) != address(0)) {
      bondExtension.onUnbond(msg.sender, poolId, amountLPToken);
    }

    emit Unbond(msg.sender, poolId, amountLPToken);
  }

  function _unbondAndBreak(
    uint256 poolId,
    uint256 amountLPToken,
    uint256 slippageBps
  ) internal {
    _removeFromBonded(msg.sender, poolId, amountLPToken);

    lpToken.safeTransfer(address(dexHandler), amountLPToken);
    uint256 initialBalance = lpToken.balanceOf(address(this));

    (uint256 amountMalt, uint256 amountReward) = dexHandler.removeLiquidity(
      amountLPToken,
      slippageBps
    );

    // Send any excess back
    uint256 currentBalance = lpToken.balanceOf(address(this));
    if (currentBalance > initialBalance) {
      lpToken.safeTransfer(msg.sender, currentBalance - initialBalance);
    }

    malt.safeTransfer(msg.sender, amountMalt);
    collateralToken.safeTransfer(msg.sender, amountReward);

    _balanceCheck();

    if (address(bondExtension) != address(0)) {
      bondExtension.onUnbond(msg.sender, poolId, amountLPToken);
    }

    emit UnbondAndBreak(
      msg.sender,
      poolId,
      amountLPToken,
      amountMalt,
      amountReward
    );
  }

  function _addToBonded(
    address account,
    uint256 poolId,
    uint256 amount
  ) internal {
    userState[poolId][account].bonded += amount;
    rewardPools[poolId].totalBonded += amount;

    _updateEpochState(_globalBonded + amount);

    if (userState[poolId][account].bondedEpoch == 0) {
      userState[poolId][account].bondedEpoch = timekeeper.epoch();
    }
  }

  function _removeFromBonded(
    address account,
    uint256 poolId,
    uint256 amount
  ) internal {
    userState[poolId][account].bonded -= amount;
    rewardPools[poolId].totalBonded -= amount;

    _updateEpochState(_globalBonded - amount);
  }

  function _updateEpochState(uint256 newTotalBonded) internal {
    EpochState storage state = epochState[_currentEpoch];
    uint256 epoch = timekeeper.epoch();
    uint256 epochStartTime = timekeeper.getEpochStartTime(_currentEpoch);
    uint256 lastUpdateTime = state.lastUpdateTime;
    uint256 lengthOfEpoch = timekeeper.epochLength();
    uint256 epochEndTime = epochStartTime + lengthOfEpoch;

    if (lastUpdateTime == 0) {
      lastUpdateTime = epochStartTime;
    }

    if (lastUpdateTime > epochEndTime) {
      lastUpdateTime = epochEndTime;
    }

    if (epoch == _currentEpoch) {
      // We are still in the same epoch. Just update
      uint256 finalTime = block.timestamp;
      if (block.timestamp > epochEndTime) {
        // We are past the end of the epoch so cap to end of epoch
        finalTime = epochEndTime;
      }

      if (finalTime > lastUpdateTime) {
        uint256 diff = finalTime - lastUpdateTime;

        state.cumulativeTotalBonded =
          state.cumulativeTotalBonded +
          (state.lastTotalBonded * diff);

        state.lastUpdateTime = finalTime;
        state.lastTotalBonded = newTotalBonded;
      }
    } else {
      // We have crossed at least 1 epoch boundary

      // Won't underflow due to check on lastUpdateTime above
      uint256 diff = epochEndTime - lastUpdateTime;

      state.cumulativeTotalBonded =
        state.cumulativeTotalBonded +
        (state.lastTotalBonded * diff);
      state.lastUpdateTime = epochEndTime;
      state.lastTotalBonded = _globalBonded;

      for (uint256 i = _currentEpoch + 1; i <= epoch; i += 1) {
        state = epochState[i];
        epochStartTime = timekeeper.getEpochStartTime(i);
        epochEndTime = epochStartTime + lengthOfEpoch;
        state.lastTotalBonded = _globalBonded;

        if (epochEndTime < block.timestamp) {
          // The desired epoch is in the past
          diff = lengthOfEpoch;
          state.lastUpdateTime = epochEndTime;
        } else {
          diff = block.timestamp - epochStartTime;
          state.lastUpdateTime = block.timestamp;
        }

        state.cumulativeTotalBonded = state.lastTotalBonded * diff;
      }

      state.lastTotalBonded = newTotalBonded;
      _currentEpoch = epoch;
    }

    _globalBonded = newTotalBonded;
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setCurrentEpoch(uint256 _epoch)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    _currentEpoch = _epoch;
  }

  function addNewRole(string memory roleName)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    bytes32 role = keccak256(abi.encodePacked(roleName));
    _setRoleAdmin(role, ADMIN_ROLE);
    emit NewBondingRole(roleName, role);
  }

  function addRewardPool(
    uint256 poolId,
    bytes32 accessRole,
    bool active,
    address distributor,
    string calldata name
  ) external onlyRoleMalt(ADMIN_ROLE, "Must have admin privs") {
    RewardPool storage pool = rewardPools[poolId];
    require(poolId > 1 && pool.id == 0, "Pool already used");
    require(distributor != address(0), "addr(0)");

    rewardPools[poolId] = RewardPool({
      id: poolId,
      index: activePools.length,
      distributor: distributor,
      totalBonded: 0,
      accessRole: accessRole,
      active: active,
      name: name
    });

    activePools.push(poolId);

    emit AddRewardPool(poolId, name, active, accessRole);
  }

  function togglePoolActive(uint256 poolId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    RewardPool storage pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown pool");

    bool active = !pool.active;
    pool.active = active;

    if (active) {
      // setting it to active so add to activePools
      pool.index = activePools.length;
      activePools.push(poolId);
    } else {
      // Becoming inactive so remove from activePools
      uint256 index = pool.index;
      uint256 lastPool = activePools[activePools.length - 1];
      activePools[index] = lastPool;
      activePools.pop();

      rewardPools[lastPool].index = index;
    }

    emit TogglePoolActive(poolId, active);
  }

  function setPoolDistributor(uint256 poolId, address distributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    RewardPool storage pool = rewardPools[poolId];
    require(pool.id == poolId, "Unknown pool");

    pool.distributor = distributor;

    emit SetPoolDistributor(poolId, distributor);
  }

  function setBondExtension(address extension)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    bondExtension = IBondExtension(extension);
    emit SetBondExtension(extension);
  }

  function _accessControl()
    internal
    override(DexHandlerExtension, DataLabExtension, MiningServiceExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/SwingTraderExtension.sol";

/// @title Forfeit Handler
/// @author 0xScotch <[email protected]>
/// @notice When a user unbonds, their unvested rewards are forfeited. This contract decides what to do with those funds
contract ForfeitHandler is StabilizedPoolUnit, SwingTraderExtension {
  using SafeERC20 for ERC20;

  address public treasury;

  uint256 public swingTraderRewardCutBps = 5000;

  event Forfeit(address sender, uint256 amount);
  event SetRewardCut(uint256 swingTraderCut);
  event SetTreasury(address treasury);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address _treasury
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    require(_treasury != address(0), "ForfeitHandler: Treasury addr(0)");

    treasury = _treasury;
  }

  function setupContracts(
    address _collateralToken,
    address _swingTrader,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "ForfeitHandler: Already setup");
    require(_collateralToken != address(0), "ForfeitHandler: Col addr(0)");

    contractActive = true;

    collateralToken = ERC20(_collateralToken);
    swingTrader = ISwingTrader(_swingTrader);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function handleForfeit() external onlyActive {
    uint256 balance = collateralToken.balanceOf(address(this));

    if (balance == 0) {
      return;
    }

    uint256 swingTraderCut = (balance * swingTraderRewardCutBps) / 10000;
    uint256 treasuryCut = balance - swingTraderCut;

    if (swingTraderCut > 0) {
      collateralToken.safeTransfer(address(swingTrader), swingTraderCut);
    }

    if (treasuryCut > 0) {
      collateralToken.safeTransfer(treasury, treasuryCut);
    }

    emit Forfeit(msg.sender, balance);
  }

  /*
   * PRIVILEDGED METHODS
   */
  function setRewardCut(uint256 _swingTraderCut)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_swingTraderCut <= 10000, "Reward cut must add to 100%");

    swingTraderRewardCutBps = _swingTraderCut;

    emit SetRewardCut(_swingTraderCut);
  }

  function setTreasury(address _treasury)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    require(_treasury != address(0), "Cannot set 0 address");

    treasury = _treasury;

    emit SetTreasury(_treasury);
  }

  function _accessControl() internal override(SwingTraderExtension) {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/utils/structs/EnumerableSet.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

import "../StabilizedPoolExtensions/BondingExtension.sol";
import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../interfaces/IRewardMine.sol";
import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";

/// @title Malt Mining Service
/// @author 0xScotch <[email protected]>
/// @notice A contract that abstracts one or more implementations of AbstractRewardMine
contract MiningService is StabilizedPoolUnit, BondingExtension {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(uint256 => EnumerableSet.AddressSet) internal poolMineSet;

  address public reinvestor;

  bytes32 public immutable REINVESTOR_ROLE;
  bytes32 public immutable BONDING_ROLE;

  event AddRewardMine(address mine, uint256 poolId);
  event RemoveRewardMine(address mine, uint256 poolId);
  event ChangePoolFactory(address factory);
  event ProposePoolFactory(address factory);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    REINVESTOR_ROLE = 0x5baaf2a93ec32c22b06ca868bfe5159678eb5056b8e9706fe8a4e94b5f28f293;
    BONDING_ROLE = 0x360f1ba4dc07a42c6671063d838f69946ccc4187f391399e06fd8ed4605900f3;
  }

  function setupContracts(
    address _reinvestor,
    address _bonding,
    address vestedMine,
    address linearMine,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory privs") {
    require(!contractActive, "MiningSvc: Already setup");
    require(_reinvestor != address(0), "MiningSvc: Reinvestor addr(0)");
    require(_bonding != address(0), "MiningSvc: Bonding addr(0)");

    contractActive = true;

    _roleSetup(REINVESTOR_ROLE, _reinvestor);
    _roleSetup(BONDING_ROLE, _bonding);

    bonding = IBonding(_bonding);
    reinvestor = _reinvestor;

    poolMineSet[0].add(vestedMine);
    poolMineSet[1].add(linearMine);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function withdrawAccountRewards(uint256 poolId, uint256 amount)
    external
    nonReentrant
  {
    _withdrawMultiple(msg.sender, poolId, amount);
  }

  function balanceOfRewards(address account, uint256 poolId)
    public
    view
    returns (uint256)
  {
    uint256 total;
    uint256 length = poolMineSet[poolId].length();
    for (uint256 i = 0; i < length; i = i + 1) {
      total += IRewardMine(poolMineSet[poolId].at(i)).balanceOfRewards(account);
    }

    return total;
  }

  function allMines(uint256 poolId) external view returns (address[] memory) {
    return poolMineSet[poolId].values();
  }

  function mines(uint256 poolId, uint256 index)
    external
    view
    returns (address)
  {
    return poolMineSet[poolId].at(index);
  }

  function netRewardBalance(address account, uint256 poolId)
    public
    view
    returns (uint256)
  {
    uint256 total;
    uint256 length = poolMineSet[poolId].length();
    for (uint256 i = 0; i < length; i = i + 1) {
      total += IRewardMine(poolMineSet[poolId].at(i)).netRewardBalance(account);
    }

    return total;
  }

  function numberOfMines(uint256 poolId) public view returns (uint256) {
    return poolMineSet[poolId].length();
  }

  function isMineActive(address mine, uint256 poolId)
    public
    view
    returns (bool)
  {
    return poolMineSet[poolId].contains(mine);
  }

  function earned(address account, uint256 poolId)
    public
    view
    returns (uint256)
  {
    uint256 total;
    uint256 length = poolMineSet[poolId].length();

    for (uint256 i = 0; i < length; i = i + 1) {
      total += IRewardMine(poolMineSet[poolId].at(i)).earned(account);
    }

    return total;
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function onBond(
    address account,
    uint256 poolId,
    uint256 amount
  ) external onlyRoleMalt(BONDING_ROLE, "Must have bonding privs") {
    uint256 length = poolMineSet[poolId].length();
    for (uint256 i = 0; i < length; i = i + 1) {
      IRewardMine mine = IRewardMine(poolMineSet[poolId].at(i));
      mine.onBond(account, amount);
    }
  }

  function onUnbond(
    address account,
    uint256 poolId,
    uint256 amount
  ) external onlyRoleMalt(BONDING_ROLE, "Must have bonding privs") {
    uint256 length = poolMineSet[poolId].length();
    for (uint256 i = 0; i < length; i = i + 1) {
      IRewardMine mine = IRewardMine(poolMineSet[poolId].at(i));
      mine.onUnbond(account, amount);
    }
  }

  function setReinvestor(address _reinvestor)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool factory privs")
  {
    require(_reinvestor != address(0), "Cannot use address 0");
    _transferRole(_reinvestor, reinvestor, REINVESTOR_ROLE);
    reinvestor = _reinvestor;
  }

  function _beforeSetBonding(address _bonding) internal override {
    _transferRole(_bonding, address(bonding), BONDING_ROLE);
  }

  function addRewardMine(address mine, uint256 poolId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(mine != address(0), "Cannot use address 0");

    if (poolMineSet[poolId].contains(mine)) {
      return;
    }

    poolMineSet[poolId].add(mine);

    emit AddRewardMine(mine, poolId);
  }

  function removeRewardMine(address mine, uint256 poolId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(mine != address(0), "Cannot use address 0");

    poolMineSet[poolId].remove(mine);

    emit RemoveRewardMine(mine, poolId);
  }

  function withdrawRewardsForAccount(
    address account,
    uint256 poolId,
    uint256 amount
  ) external onlyRoleMalt(REINVESTOR_ROLE, "Must have reinvestor privs") {
    _withdrawMultiple(account, poolId, amount);
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _withdrawMultiple(
    address account,
    uint256 poolId,
    uint256 amount
  ) internal {
    uint256 length = poolMineSet[poolId].length();
    for (uint256 i = 0; i < length; i = i + 1) {
      uint256 withdrawnAmount = IRewardMine(poolMineSet[poolId].at(i))
        .withdrawForAccount(account, amount, msg.sender);

      amount = amount - withdrawnAmount;

      if (amount == 0) {
        break;
      }
    }
  }

  function _accessControl() internal override(BondingExtension) {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "./AbstractRewardMine.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IBonding.sol";
import "../StabilizedPoolExtensions/BondingExtension.sol";

struct SharesAndDebt {
  uint256 totalImpliedReward;
  uint256 totalDebt;
  uint256 perShareReward;
  uint256 perShareDebt;
}

/// @title ERC20 Vested Mine
/// @author 0xScotch <[email protected]>
/// @notice An implementation of AbstractRewardMine to handle rewards being vested by the RewardDistributor
contract ERC20VestedMine is AbstractRewardMine, BondingExtension {
  IVestingDistributor public vestingDistributor;

  uint256 internal shareUnity;

  mapping(uint256 => SharesAndDebt) internal focalSharesAndDebt;
  mapping(uint256 => mapping(address => SharesAndDebt))
    internal accountFocalSharesAndDebt;

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _poolId
  ) AbstractRewardMine(timelock, repository, poolFactory) {
    poolId = _poolId;
    _grantRole(REWARD_PROVIDER_ROLE, timelock);
  }

  function setupContracts(
    address _miningService,
    address _vestingDistributor,
    address _bonding,
    address _collateralToken,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "VestedMine: Already setup");
    require(_miningService != address(0), "VestedMine: MiningSvc addr(0)");
    require(
      _vestingDistributor != address(0),
      "VestedMine: Distributor addr(0)"
    );
    require(_bonding != address(0), "VestedMine: Bonding addr(0)");
    require(_collateralToken != address(0), "VestedMine: RewardToken addr(0)");

    contractActive = true;

    vestingDistributor = IVestingDistributor(_vestingDistributor);
    bonding = IBonding(_bonding);
    shareUnity = 10**bonding.stakeTokenDecimals();

    _initialSetup(_collateralToken, _miningService, _vestingDistributor);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function onUnbond(address account, uint256 amount)
    external
    override
    onlyRoleMalt(MINING_SERVICE_ROLE, "Must having mining service privilege")
  {
    // Withdraw all current rewards
    // Done now before we change stake padding below
    uint256 rewardEarned = earned(account);
    _handleWithdrawForAccount(account, rewardEarned, account);

    uint256 bondedBalance = balanceOfBonded(account);

    if (bondedBalance == 0) {
      return;
    }

    _checkForForfeit(account, amount, bondedBalance);

    uint256 lessStakePadding = (balanceOfStakePadding(account) * amount) /
      bondedBalance;

    _reconcileWithdrawn(account, amount, bondedBalance);
    _removeFromStakePadding(account, lessStakePadding);
  }

  function totalBonded() public view override returns (uint256) {
    return bonding.totalBondedByPool(poolId);
  }

  function valueOfBonded() public view override returns (uint256) {
    return bonding.valueOfBonded(poolId);
  }

  function balanceOfBonded(address account)
    public
    view
    override
    returns (uint256)
  {
    return bonding.balanceOfBonded(poolId, account);
  }

  /*
   * totalReleasedReward and totalDeclaredReward will often be the same. However, in the case
   * of vesting rewards they are different. In that case totalDeclaredReward is total
   * reward, including unvested. totalReleasedReward is just the rewards that have completed
   * the vesting schedule.
   */
  function totalDeclaredReward() public view override returns (uint256) {
    return vestingDistributor.totalDeclaredReward();
  }

  function declareReward(uint256 amount)
    external
    virtual
    onlyRoleMalt(REWARD_PROVIDER_ROLE, "Only reward provider role")
  {
    uint256 bonded = totalBonded();

    if (amount == 0 || bonded == 0) {
      return;
    }

    uint256 focalId = vestingDistributor.focalID();

    uint256 localShareUnity = shareUnity; // gas saving

    SharesAndDebt storage globalActiveFocalShares = focalSharesAndDebt[focalId];

    /*
     * normReward is normalizing the reward as if the reward was declared
     * at the very start of the focal period.
     * Eg if $100 reward comes in 33% towards the end of the vesting period
     * then that will look the same as $150 of rewards vesting from the very
     * beginning of the vesting period. However, to ensure that only $100
     * rewards are actual given out we accrue $50 of 'vesting debt'.
     *
     * To calculate how much has vested you first calculate what %
     * of the vesting period has elapsed. Then take that % of the
     * normReward and then subtract of normDebt.
     *
     * Using the above $100 at 33% into the vesting period as an example.
     * If we are 50% through the vesting period then 50% of the $150
     * normReward has vested = $75. Now subtract the $50 debt and
     * we are left with $25 of rewards.
     * This is correct as the $100 came in at 33.33% and we are now
     * 50% in, so we have moved 16.66% towards the 66.66% of the
     * remaining time. 16.66 is 25% of 66.66 so 25% of the $100 should
     * have vested.
     *
     * By normalizing rewards to always start and end vesting at the start
     * and end of the focal periods the math becomes significantly easier.
     * We also normalize the full normReward and normDebt to be per share
     * currently bonded which makes other math easier down the line.
     */

    uint256 unvestedBps = vestingDistributor.getFocalUnvestedBps(focalId);

    if (unvestedBps == 0) {
      return;
    }

    uint256 normReward = (amount * 10000) / unvestedBps;
    uint256 normDebt = normReward - amount;

    uint256 normRewardPerShare = (normReward * localShareUnity) / bonded;
    uint256 normDebtPerShare = (normDebt * localShareUnity) / bonded;

    focalSharesAndDebt[focalId].totalImpliedReward += normReward;
    focalSharesAndDebt[focalId].totalDebt += normDebt;
    focalSharesAndDebt[focalId].perShareReward += normRewardPerShare;
    focalSharesAndDebt[focalId].perShareDebt += normDebtPerShare;
  }

  function earned(address account)
    public
    view
    override
    returns (uint256 earnedReward)
  {
    uint256 totalAccountReward = balanceOfRewards(account);
    uint256 unvested = _getAccountUnvested(account);

    uint256 vested;

    if (totalAccountReward > unvested) {
      vested = totalAccountReward - unvested;
    }

    if (vested > _userWithdrawn[account]) {
      earnedReward = vested - _userWithdrawn[account];
    }

    uint256 balance = collateralToken.balanceOf(address(this));

    if (earnedReward > balance) {
      earnedReward = balance;
    }
  }

  function accountUnvested(address account) public view returns (uint256) {
    return _getAccountUnvested(account);
  }

  function getFocalShares(uint256 focalId)
    external
    view
    returns (
      uint256 totalImpliedReward,
      uint256 totalDebt,
      uint256 perShareReward,
      uint256 perShareDebt
    )
  {
    SharesAndDebt storage focalShares = focalSharesAndDebt[focalId];

    return (
      focalShares.totalImpliedReward,
      focalShares.totalDebt,
      focalShares.perShareReward,
      focalShares.perShareDebt
    );
  }

  function getAccountFocalDebt(address account, uint256 focalId)
    external
    view
    returns (uint256, uint256)
  {
    SharesAndDebt storage accountFocalDebt = accountFocalSharesAndDebt[focalId][
      account
    ];

    return (accountFocalDebt.perShareReward, accountFocalDebt.perShareDebt);
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _getAccountUnvested(address account)
    internal
    view
    returns (uint256 unvested)
  {
    // focalID starts at 1 so vesting can't underflow
    uint256 activeFocalId = vestingDistributor.focalID();
    uint256 vestingFocalId = activeFocalId - 1;
    uint256 userBonded = balanceOfBonded(account);

    uint256 activeUnvestedPerShare = _getFocalUnvestedPerShare(
      activeFocalId,
      account
    );
    uint256 vestingUnvestedPerShare = _getFocalUnvestedPerShare(
      vestingFocalId,
      account
    );

    unvested =
      ((activeUnvestedPerShare + vestingUnvestedPerShare) * userBonded) /
      shareUnity;
  }

  function _getFocalUnvestedPerShare(uint256 focalId, address account)
    internal
    view
    returns (uint256 unvestedPerShare)
  {
    SharesAndDebt storage globalActiveFocalShares = focalSharesAndDebt[focalId];
    SharesAndDebt storage accountActiveFocalShares = accountFocalSharesAndDebt[
      focalId
    ][account];
    uint256 bonded = totalBonded();

    if (globalActiveFocalShares.perShareReward == 0 || bonded == 0) {
      return 0;
    }

    uint256 unvestedBps = vestingDistributor.getFocalUnvestedBps(focalId);
    uint256 vestedBps = 10000 - unvestedBps;

    uint256 totalRewardPerShare = globalActiveFocalShares.perShareReward -
      globalActiveFocalShares.perShareDebt;
    uint256 totalUserDebtPerShare = accountActiveFocalShares.perShareReward -
      accountActiveFocalShares.perShareDebt;

    uint256 rewardPerShare = ((globalActiveFocalShares.perShareReward *
      vestedBps) / 10000) - globalActiveFocalShares.perShareDebt;
    uint256 userDebtPerShare = ((accountActiveFocalShares.perShareReward *
      vestedBps) / 10000) - accountActiveFocalShares.perShareDebt;

    uint256 userTotalPerShare;
    if (totalRewardPerShare > totalUserDebtPerShare) {
      userTotalPerShare = totalRewardPerShare - totalUserDebtPerShare;
    }

    uint256 userVestedPerShare;
    if (rewardPerShare > userDebtPerShare) {
      userVestedPerShare = rewardPerShare - userDebtPerShare;
    }

    if (userTotalPerShare > userVestedPerShare) {
      unvestedPerShare = userTotalPerShare - userVestedPerShare;
    }
  }

  function _afterBond(address account, uint256 amount) internal override {
    uint256 focalId = vestingDistributor.focalID();
    uint256 vestingFocalId = focalId - 1;

    uint256 initialUserBonded = balanceOfBonded(account);
    uint256 userTotalBonded = initialUserBonded + amount;

    SharesAndDebt memory currentShares = focalSharesAndDebt[focalId];
    SharesAndDebt memory vestingShares = focalSharesAndDebt[vestingFocalId];

    uint256 perShare = accountFocalSharesAndDebt[focalId][account]
      .perShareReward;
    uint256 vestingPerShare = accountFocalSharesAndDebt[vestingFocalId][account]
      .perShareReward;

    if (
      currentShares.perShareReward == 0 && vestingShares.perShareReward == 0
    ) {
      return;
    }

    uint256 debt = accountFocalSharesAndDebt[focalId][account].perShareDebt;
    uint256 vestingDebt = accountFocalSharesAndDebt[vestingFocalId][account]
      .perShareDebt;

    // Pro-rata it down according to old bonded value
    perShare = (perShare * initialUserBonded) / userTotalBonded;
    debt = (debt * initialUserBonded) / userTotalBonded;

    vestingPerShare = (vestingPerShare * initialUserBonded) / userTotalBonded;
    vestingDebt = (vestingDebt * initialUserBonded) / userTotalBonded;

    // Now add on the new pro-ratad perShare values
    perShare += (currentShares.perShareReward * amount) / userTotalBonded;
    debt += (currentShares.perShareDebt * amount) / userTotalBonded;

    vestingPerShare +=
      (vestingShares.perShareReward * amount) /
      userTotalBonded;
    vestingDebt += (vestingShares.perShareDebt * amount) / userTotalBonded;

    accountFocalSharesAndDebt[focalId][account].perShareReward = perShare;
    accountFocalSharesAndDebt[focalId][account].perShareDebt = debt;

    accountFocalSharesAndDebt[vestingFocalId][account]
      .perShareReward = vestingPerShare;
    accountFocalSharesAndDebt[vestingFocalId][account]
      .perShareDebt = vestingDebt;
  }

  function _checkForForfeit(
    address account,
    uint256 amount,
    uint256 bondedBalance
  ) internal {
    // The user is unbonding so we should reduce declaredReward
    // proportional to the unbonded amount
    // At any given point in time, every user has rewards allocated
    // to them. balanceOfRewards(account) will tell you this value.
    // If a user unbonds x% of their LP then declaredReward should
    // reduce by exactly x% of that user's allocated rewards

    // However, this has to be done in 2 parts. First forfeit x%
    // Of unvested rewards. This decrements declaredReward automatically.
    // Then we call decrementRewards using x% of rewards that have
    // already been released. The net effect is declaredReward decreases
    // by x% of the users allocated reward

    uint256 unvested = _getAccountUnvested(account);

    uint256 forfeitReward = (unvested * amount) / bondedBalance;

    // A full withdrawn happens before this method is called.
    // So we can safely say _userWithdrawn is in fact all of the
    // currently vested rewards for the bonded LP
    uint256 declaredRewardDecrease = (_userWithdrawn[account] * amount) /
      bondedBalance;

    if (forfeitReward > 0) {
      vestingDistributor.forfeit(forfeitReward);
    }

    if (declaredRewardDecrease > 0) {
      vestingDistributor.decrementRewards(declaredRewardDecrease);
    }
  }

  function _beforeWithdraw(address account, uint256 amount) internal override {
    // Vest rewards before withdrawing to make sure all capital is available
    vestingDistributor.vest();
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setVestingDistributor(address _vestingDistributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    vestingDistributor = IVestingDistributor(_vestingDistributor);
  }

  function _accessControl()
    internal
    override(MiningServiceExtension, BondingExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "./AbstractRewardMine.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IBonding.sol";
import "../StabilizedPoolExtensions/BondingExtension.sol";

/// @title Reward Mine Base
/// @author 0xMojo7
/// @notice An implementation of AbstractRewardMine to accept rewards.
contract RewardMineBase is AbstractRewardMine, BondingExtension {
  using SafeERC20 for IERC20;

  IERC20 public lpToken;
  IDistributor public linearDistributor;

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _poolId
  ) AbstractRewardMine(timelock, repository, poolFactory) {
    poolId = _poolId;
    _grantRole(REWARD_PROVIDER_ROLE, timelock);
  }

  function setupContracts(
    address _miningService,
    address _distributor,
    address _bonding,
    address _collateralToken,
    address _lpToken
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "RewardBase: Already setup");
    require(_miningService != address(0), "RewardBase: MiningSvc addr(0)");
    require(_distributor != address(0), "RewardBase: Distributor addr(0)");
    require(_bonding != address(0), "RewardBase: Bonding addr(0)");
    require(_lpToken != address(0), "RewardBase: lpToken addr(0)");
    require(_collateralToken != address(0), "RewardBase: RewardToken addr(0)");

    contractActive = true;

    bonding = IBonding(_bonding);
    lpToken = IERC20(_lpToken);
    linearDistributor = IDistributor(_distributor);

    _initialSetup(_collateralToken, _miningService, _distributor);

    (, address updater, ) = poolFactory.getPool(_lpToken);
    _setPoolUpdater(updater);
  }

  function onUnbond(address account, uint256 amount)
    external
    override
    onlyRoleMalt(MINING_SERVICE_ROLE, "Must having mining service privilege")
  {
    _beforeUnbond(account, amount);
    // Withdraw all current rewards
    // Done now before we change stake padding below
    uint256 rewardEarned = earned(account);
    _handleWithdrawForAccount(account, rewardEarned, account);

    uint256 bondedBalance = balanceOfBonded(account);

    if (bondedBalance == 0) {
      return;
    }

    // A full withdraw happens before this method is called.
    // So we can safely say _userWithdrawn is in fact all of the
    // currently vested rewards for the bonded LP
    uint256 declaredRewardDecrease = (_userWithdrawn[account] * amount) /
      bondedBalance;

    if (declaredRewardDecrease > 0) {
      linearDistributor.decrementRewards(declaredRewardDecrease);
    }

    uint256 lessStakePadding = (balanceOfStakePadding(account) * amount) /
      bondedBalance;

    _reconcileWithdrawn(account, amount, bondedBalance);
    _removeFromStakePadding(account, lessStakePadding);
    _afterUnbond(account, amount);
  }

  /*
   * MASTER CHEF FUNCTIONS
   */
  function deposit(uint256 _amount) external {
    require(msg.sender != address(0), "Depositer cannot be addr(0)");
    lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    lpToken.safeApprove(address(bonding), _amount);
    bonding.bondToAccount(msg.sender, poolId, _amount);
    lpToken.safeApprove(address(bonding), 0);
  }

  function userInfo(address _user)
    external
    view
    returns (uint256 balanceBonded, uint256 balanceStakePadding)
  {
    balanceBonded = balanceOfBonded(_user);
    balanceStakePadding = balanceOfStakePadding(_user);
  }

  function pending(address _user) external view returns (uint256) {
    return earned(_user);
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */

  function totalDeclaredReward() public view override returns (uint256) {
    return _globalReleased;
  }

  function totalBonded() public view virtual override returns (uint256) {
    return bonding.totalBondedByPool(poolId);
  }

  function valueOfBonded() public view virtual override returns (uint256) {
    return bonding.valueOfBonded(poolId);
  }

  function balanceOfBonded(address account)
    public
    view
    override
    returns (uint256)
  {
    return bonding.balanceOfBonded(poolId, account);
  }

  function _accessControl()
    internal
    override(MiningServiceExtension, BondingExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }

  function setLinearDistributor(address _distributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    require(_distributor != address(0), "No addr(0)");
    linearDistributor = IDistributor(_distributor);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IDexHandler.sol";
import "../interfaces/IBonding.sol";
import "../interfaces/IMiningService.sol";
import "../libraries/uniswap/Babylonian.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/SafeBurnMintableERC20.sol";
import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/BondingExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/MiningServiceExtension.sol";

/// @title Reward Reinvestor
/// @author 0xScotch <[email protected]>
/// @notice Provide a way to programmatically reinvest Malt rewards
contract RewardReinvestor is
  StabilizedPoolUnit,
  BondingExtension,
  DexHandlerExtension,
  MiningServiceExtension
{
  using SafeERC20 for ERC20;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  ERC20 public lpToken;

  event ProvideReinvest(
    address indexed account,
    uint256 reward,
    uint256 poolId
  );
  event SplitReinvest(
    address indexed account,
    uint256 amountReward,
    uint256 poolId
  );

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {}

  function setupContracts(
    address _malt,
    address _collateralToken,
    address _dexHandler,
    address _bonding,
    address _lpToken,
    address _miningService
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "Reinvestor: Already setup");
    require(_malt != address(0), "Reinvestor: Malt addr(0)");
    require(_collateralToken != address(0), "Reinvestor: Col addr(0)");
    require(_dexHandler != address(0), "Reinvestor: DexHandler addr(0)");
    require(_bonding != address(0), "Reinvestor: Bonding addr(0)");
    require(_miningService != address(0), "Reinvestor: MiningSvc addr(0)");

    contractActive = true;

    malt = IBurnMintableERC20(_malt);
    collateralToken = ERC20(_collateralToken);
    lpToken = ERC20(_lpToken);
    dexHandler = IDexHandler(_dexHandler);
    bonding = IBonding(_bonding);
    miningService = IMiningService(_miningService);

    (, address updater, ) = poolFactory.getPool(_lpToken);
    _setPoolUpdater(updater);
  }

  function provideReinvest(
    uint256 poolId,
    uint256 rewardLiquidity,
    uint256 maltLiquidity,
    uint256 slippageBps
  ) external nonReentrant onlyActive {
    uint256 rewardBalance = _retrieveReward(rewardLiquidity, poolId);

    // Transfer the remaining Malt required
    malt.safeTransferFrom(msg.sender, address(this), maltLiquidity);

    _bondAccount(msg.sender, poolId, maltLiquidity, rewardBalance, slippageBps);

    emit ProvideReinvest(msg.sender, rewardBalance, poolId);
  }

  function splitReinvest(
    uint256 poolId,
    uint256 rewardLiquidity,
    uint256 rewardReserves,
    uint256 slippageBps
  ) external nonReentrant onlyActive {
    uint256 rewardBalance = _retrieveReward(rewardLiquidity, poolId);
    uint256 swapAmount = _optimalLiquiditySwap(rewardBalance, rewardReserves);

    collateralToken.safeTransfer(address(dexHandler), swapAmount);
    uint256 amountMalt = dexHandler.buyMalt(swapAmount, slippageBps);

    _bondAccount(
      msg.sender,
      poolId,
      amountMalt,
      rewardBalance - swapAmount,
      slippageBps
    );

    emit SplitReinvest(msg.sender, rewardLiquidity, poolId);
  }

  function _retrieveReward(uint256 rewardLiquidity, uint256 poolId)
    internal
    returns (uint256)
  {
    require(rewardLiquidity > 0, "Cannot reinvest 0");

    miningService.withdrawRewardsForAccount(
      msg.sender,
      poolId,
      rewardLiquidity
    );

    return collateralToken.balanceOf(address(this));
  }

  function _bondAccount(
    address account,
    uint256 poolId,
    uint256 amountMalt,
    uint256 amountReward,
    uint256 slippageBps
  ) internal {
    // It is assumed that the calling functions have ensured
    // The token balances are correct
    malt.safeTransfer(address(dexHandler), amountMalt);
    collateralToken.safeTransfer(address(dexHandler), amountReward);

    (, , uint256 liquidityCreated) = dexHandler.addLiquidity(
      amountMalt,
      amountReward,
      slippageBps
    );

    require(liquidityCreated > 0, "Reinvestor: No liquidity created");

    // Ensure starting from 0
    lpToken.safeApprove(address(bonding), 0);
    lpToken.safeApprove(address(bonding), liquidityCreated);

    bonding.bondToAccount(account, poolId, liquidityCreated);

    // Reset approval
    lpToken.safeApprove(address(bonding), 0);

    // If there is any carry / left overs then send back to user
    uint256 maltBalance = malt.balanceOf(address(this));
    uint256 rewardTokenBalance = collateralToken.balanceOf(address(this));

    if (maltBalance > 0) {
      malt.safeTransfer(account, maltBalance);
    }

    if (rewardTokenBalance > 0) {
      collateralToken.safeTransfer(account, rewardTokenBalance);
    }
  }

  function _optimalLiquiditySwap(uint256 amountA, uint256 reserveA)
    internal
    pure
    returns (uint256)
  {
    // assumes 0.3% fee
    return ((Babylonian.sqrt(
      reserveA * ((amountA * 3988000) + (reserveA * 3988009))
    ) - (reserveA * 1997)) / 1994);
  }

  function _accessControl()
    internal
    override(BondingExtension, DexHandlerExtension, MiningServiceExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IStabilizerNode.sol";
import "../interfaces/IAuction.sol";
import "../Permissions.sol";
import "./AbstractTransferVerification.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";

/// @title Pool Transfer Verification
/// @author 0xScotch <[email protected]>
/// @notice Implements ability to block Malt transfers
contract PoolTransferVerification is
  AbstractTransferVerification,
  StabilizerNodeExtension,
  DataLabExtension
{
  uint256 public upperThresholdBps;
  uint256 public lowerThresholdBps;
  uint256 public priceLookbackBelow;
  uint256 public priceLookbackAbove;

  bool public paused = true;
  bool internal killswitch = true;

  mapping(address => bool) public whitelist;
  mapping(address => bool) public killswitchAllowlist;

  event AddToWhitelist(address indexed _address);
  event RemoveFromWhitelist(address indexed _address);
  event AddToKillswitchAllowlist(address indexed _address);
  event RemoveFromKillswitchAllowlist(address indexed _address);
  event SetPriceLookbacks(uint256 lookbackUpper, uint256 lookbackLower);
  event SetThresholds(uint256 newUpperThreshold, uint256 newLowerThreshold);
  event SetPaused(bool paused);
  event SetKillswitch(bool killswitch);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    uint256 _lowerThresholdBps,
    uint256 _upperThresholdBps,
    uint256 _lookbackAbove,
    uint256 _lookbackBelow
  ) AbstractTransferVerification(timelock, repository, poolFactory) {
    lowerThresholdBps = _lowerThresholdBps;
    upperThresholdBps = _upperThresholdBps;
    priceLookbackAbove = _lookbackAbove;
    priceLookbackBelow = _lookbackBelow;
  }

  function setupContracts(
    address _maltDataLab,
    address _stakeToken,
    address _initialWhitelist,
    address _stabilizerNode
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role") {
    require(!contractActive, "XferVerifier: Already setup");
    require(_maltDataLab != address(0), "XferVerifier: DataLab addr(0)");
    require(_stakeToken != address(0), "XferVerifier: StakeToken addr(0)");
    require(_stabilizerNode != address(0), "XferVerifier: StabNode addr(0)");

    contractActive = true;

    maltDataLab = IMaltDataLab(_maltDataLab);
    stakeToken = IUniswapV2Pair(_stakeToken);
    stabilizerNode = IStabilizerNode(_stabilizerNode);

    if (_initialWhitelist != address(0)) {
      whitelist[_initialWhitelist] = true;
    }

    (, address updater, ) = poolFactory.getPool(_stakeToken);
    _setPoolUpdater(updater);
  }

  function verifyTransfer(
    address from,
    address to,
    uint256 amount
  )
    external
    view
    override
    returns (
      bool,
      string memory,
      address,
      bytes memory
    )
  {
    if (killswitch) {
      if (killswitchAllowlist[from] || killswitchAllowlist[to]) {
        return (true, "", address(0), "");
      }
      return (false, "Malt: Pool transfers have been paused", address(0), "");
    }

    if (paused) {
      // This pauses any transfer verifiers. In essence allowing all Malt Txs
      return (true, "", address(0), "");
    }

    if (from != address(stakeToken)) {
      return (true, "", address(0), "");
    }

    if (whitelist[to]) {
      return (true, "", address(0), "");
    }

    return _belowPegCheck();
  }

  function _belowPegCheck()
    internal
    view
    returns (
      bool,
      string memory,
      address,
      bytes memory
    )
  {
    bool result;

    (bool usePrimedWindow, uint256 windowEndBlock) = stabilizerNode
      .primedWindowData();

    if (usePrimedWindow) {
      if (block.number > windowEndBlock) {
        result = true;
      }
    } else {
      uint256 priceTarget = maltDataLab.getActualPriceTarget();

      result =
        maltDataLab.maltPriceAverage(priceLookbackBelow) >
        (priceTarget * (10000 - lowerThresholdBps)) / 10000;
    }

    return (result, "Malt: BELOW PEG", address(0), "");
  }

  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  function isAllowlisted(address _address) public view returns (bool) {
    return killswitchAllowlist[_address];
  }

  /*
   * PRIVILEDGED METHODS
   */
  function setThresholds(uint256 newUpperThreshold, uint256 newLowerThreshold)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(
      newUpperThreshold != 0 && newUpperThreshold < 10000,
      "Upper threshold must be between 0-100%"
    );
    require(
      newLowerThreshold != 0 && newLowerThreshold < 10000,
      "Lower threshold must be between 0-100%"
    );
    upperThresholdBps = newUpperThreshold;
    lowerThresholdBps = newLowerThreshold;
    emit SetThresholds(newUpperThreshold, newLowerThreshold);
  }

  function setPriceLookback(uint256 lookbackAbove, uint256 lookbackBelow)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(lookbackAbove != 0 && lookbackBelow != 0, "Cannot have 0 lookback");
    priceLookbackAbove = lookbackAbove;
    priceLookbackBelow = lookbackBelow;
    emit SetPriceLookbacks(lookbackAbove, lookbackBelow);
  }

  function addToWhitelist(address _address)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    whitelist[_address] = true;
    emit AddToWhitelist(_address);
  }

  function removeFromWhitelist(address _address)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    if (!whitelist[_address]) {
      return;
    }
    whitelist[_address] = false;
    emit RemoveFromWhitelist(_address);
  }

  function addToAllowlist(address _address)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    killswitchAllowlist[_address] = true;
    emit AddToKillswitchAllowlist(_address);
  }

  function removeFromAllowlist(address _address)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    if (!killswitchAllowlist[_address]) {
      return;
    }
    killswitchAllowlist[_address] = false;
    emit RemoveFromKillswitchAllowlist(_address);
  }

  function togglePause()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    bool localPaused = paused;
    paused = !localPaused;
    emit SetPaused(localPaused);
  }

  function toggleKillswitch()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    bool localKillswitch = killswitch;
    killswitch = !localKillswitch;
    emit SetKillswitch(!localKillswitch);
  }

  function _accessControl()
    internal
    override(DataLabExtension, StabilizerNodeExtension)
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20Permit.sol";
import "../Permissions.sol";
import "../interfaces/ITransferService.sol";
import "../interfaces/IGlobalImpliedCollateralService.sol";

/// @title Malt V2 Token
/// @author 0xScotch <[email protected]>
/// @notice The ERC20 token contract for Malt V2
contract Malt is ERC20Permit, Permissions {
  // Can mint/burn Malt
  bytes32 public immutable MONETARY_MINTER_ROLE;
  bytes32 public immutable MONETARY_BURNER_ROLE;
  bytes32 public immutable MONETARY_MANAGER_ROLE;

  ITransferService public transferService;
  IGlobalImpliedCollateralService public globalImpliedCollateral;

  bool internal initialSetup;
  address public proposedManager;
  address public monetaryManager;
  address internal immutable deployer;

  string private __name;
  string private __ticker;

  event SetTransferService(address service);
  event SetGlobalImpliedCollateralService(address service);
  event AddBurner(address burner);
  event AddMinter(address minter);
  event RemoveBurner(address burner);
  event RemoveMinter(address minter);
  event ChangeMonetaryManager(address manager);
  event ProposeMonetaryManager(address manager);
  event NewName(string name, string ticker);

  constructor(
    string memory name,
    string memory ticker,
    address _repository,
    address _transferService,
    address _deployer
  ) ERC20Permit(name, ticker) {
    require(_repository != address(0), "Malt: Repo addr(0)");
    require(_transferService != address(0), "Malt: XferSvc addr(0)");
    _initialSetup(_repository);

    MONETARY_MINTER_ROLE = 0x264fdff7d4ea2a3fb35856e2af3bd6f38e90e6c378f1161af7f84f529e94bf2a;
    MONETARY_BURNER_ROLE = 0xd584181ebe1991e362d5d6203c152ec1f1401c6e1f04cf8f89206dc82e0bddf1;
    MONETARY_MANAGER_ROLE = 0x8d0a7a26d784bd81e4cc5cff08474890ceb6d51b1bb1f416caff0e31cd01d8d2;

    // These roles aren't set up using _roleSetup as ADMIN_ROLE
    // should not be the admin of these roles like it is for all
    // other roles
    _setRoleAdmin(
      0x264fdff7d4ea2a3fb35856e2af3bd6f38e90e6c378f1161af7f84f529e94bf2a,
      TIMELOCK_ROLE
    );
    _setRoleAdmin(
      0xd584181ebe1991e362d5d6203c152ec1f1401c6e1f04cf8f89206dc82e0bddf1,
      TIMELOCK_ROLE
    );
    _setRoleAdmin(
      0x8d0a7a26d784bd81e4cc5cff08474890ceb6d51b1bb1f416caff0e31cd01d8d2,
      TIMELOCK_ROLE
    );

    deployer = _deployer;
    __name = name;
    __ticker = ticker;

    transferService = ITransferService(_transferService);
    emit SetTransferService(_transferService);
  }

  function totalSupply() public view override returns (uint256) {
    return super.totalSupply() - globalImpliedCollateral.totalPhantomMalt();
  }

  /// @dev Returns the name of the token.
  function name() public view override returns (string memory) {
    return __name;
  }

  /// @dev Returns the symbol of the token, usually a shorter version of the name.
  function symbol() public view override returns (string memory) {
    return __ticker;
  }

  function setupContracts(
    address _globalIC,
    address _manager,
    address[] memory minters,
    address[] memory burners
  ) external {
    // This should only be called once
    require(msg.sender == deployer, "Only deployer");
    require(!initialSetup, "Malt: Already setup");
    require(_globalIC != address(0), "Malt: GlobalIC addr(0)");
    require(_manager != address(0), "Malt: Manager addr(0)");
    initialSetup = true;

    globalImpliedCollateral = IGlobalImpliedCollateralService(_globalIC);

    _grantRole(MONETARY_MANAGER_ROLE, _manager);
    monetaryManager = _manager;

    for (uint256 i = 0; i < minters.length; i = i + 1) {
      require(minters[i] != address(0), "Malt: Minter addr(0)");
      _setupRole(MONETARY_MINTER_ROLE, minters[i]);
    }
    for (uint256 i = 0; i < burners.length; i = i + 1) {
      require(burners[i] != address(0), "Malt: Burner addr(0)");
      _setupRole(MONETARY_BURNER_ROLE, burners[i]);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    (bool success, string memory reason) = transferService
      .verifyTransferAndCall(from, to, amount);
    require(success, reason);
  }

  function mint(address to, uint256 amount)
    external
    onlyRoleMalt(MONETARY_MINTER_ROLE, "Must have monetary minter role")
  {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount)
    external
    onlyRoleMalt(MONETARY_BURNER_ROLE, "Must have monetary burner role")
  {
    _burn(from, amount);
  }

  function addBurner(address _burner)
    external
    onlyRoleMalt(MONETARY_MANAGER_ROLE, "Must have manager role")
  {
    require(_burner != address(0), "No addr(0)");
    _grantRole(MONETARY_BURNER_ROLE, _burner);
    emit AddBurner(_burner);
  }

  function addMinter(address _minter)
    external
    onlyRoleMalt(MONETARY_MANAGER_ROLE, "Must have manager role")
  {
    require(_minter != address(0), "No addr(0)");
    _grantRole(MONETARY_MINTER_ROLE, _minter);
    emit AddMinter(_minter);
  }

  function removeBurner(address _burner)
    external
    onlyRoleMalt(MONETARY_MANAGER_ROLE, "Must have manager role")
  {
    _revokeRole(MONETARY_BURNER_ROLE, _burner);
    emit RemoveBurner(_burner);
  }

  function removeMinter(address _minter)
    external
    onlyRoleMalt(MONETARY_MANAGER_ROLE, "Must have manager role")
  {
    _revokeRole(MONETARY_MINTER_ROLE, _minter);
    emit RemoveMinter(_minter);
  }

  /// @notice Privileged method changing the name and ticker of the token
  /// @param _name The new full name of the token
  /// @param _ticker The new ticker for the token
  /// @dev Only callable via the timelock contract
  function setNewName(string memory _name, string memory _ticker)
    external
    onlyRoleMalt(TIMELOCK_ROLE, "Must have timelock role")
  {
    __name = _name;
    __ticker = _ticker;
    emit NewName(_name, _ticker);
  }

  /// @notice Privileged method for proposing a new monetary manager
  /// @param _manager The address of the newly proposed manager contract
  /// @dev Only callable via the existing monetary manager contract
  function proposeNewManager(address _manager)
    external
    onlyRoleMalt(MONETARY_MANAGER_ROLE, "Must have monetary manager role")
  {
    require(_manager != address(0), "Cannot use addr(0)");
    proposedManager = _manager;
    emit ProposeMonetaryManager(_manager);
  }

  /// @notice Method for a proposed verifier manager contract to accept the role
  /// @dev Only callable via the proposedManager
  function acceptManagerRole() external {
    require(msg.sender == proposedManager, "Must be proposedManager");
    _transferRole(proposedManager, monetaryManager, MONETARY_MANAGER_ROLE);
    proposedManager = address(0);
    monetaryManager = msg.sender;
    emit ChangeMonetaryManager(msg.sender);
  }

  function setTransferService(address _service)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_service != address(0), "Cannot use address 0 as transfer service");
    transferService = ITransferService(_service);
    emit SetTransferService(_service);
  }

  function setGlobalImpliedCollateralService(address _service)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_service != address(0), "Cannot use address 0 as global ic");
    globalImpliedCollateral = IGlobalImpliedCollateralService(_service);
    emit SetGlobalImpliedCollateralService(_service);
  }
}

pragma solidity 0.8.11;

import "../libraries/uniswap/Babylonian.sol";
import "../libraries/uniswap/IUniswapV2Pair.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/RewardThrottleExtension.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/AuctionExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderManagerExtension.sol";
import "../StabilizedPoolExtensions/StabilizerNodeExtension.sol";
import "../interfaces/IKeeperCompatibleInterface.sol";
import "../interfaces/IMaltDataLab.sol";
import "../interfaces/IDexHandler.sol";
import "../interfaces/ITimekeeper.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IRewardThrottle.sol";
import "../interfaces/IStabilizerNode.sol";
import "../interfaces/IMovingAverage.sol";
import "../interfaces/ISwingTrader.sol";

/// @title Pool Keeper
/// @author 0xScotch <[email protected]>
/// @notice A chainlink keeper compatible contract to upkeep a Malt pool
contract UniV2PoolKeeper is
  StabilizedPoolUnit,
  AuctionExtension,
  IKeeperCompatibleInterface,
  RewardThrottleExtension,
  DataLabExtension,
  DexHandlerExtension,
  SwingTraderManagerExtension,
  StabilizerNodeExtension
{
  using SafeERC20 for ERC20;
  bytes32 public immutable KEEPER_ROLE;

  IVestingDistributor public vestingDistributor;
  ITimekeeper public timekeeper;

  bool public paused = true;
  bool public upkeepVesting = true;
  bool public upkeepStability = true;
  bool public upkeepTracking = true;

  address payable treasury;

  uint256 public minInterval = 10;
  uint256 internal lastTimestamp;
  uint256 internal lastUpdateMaltRatio;

  event SetMinInterval(uint256 interval);
  event SetUpkeepVesting(bool upkeepVesting);
  event SetUpkeepTracking(bool upkeepTracking);
  event SetUpkeepStability(bool upkeepStability);
  event SetVestingDistributor(address distributor);
  event SetPaused(bool paused);
  event UpdateTreasury(address treasury);

  constructor(
    address timelock,
    address repository,
    address poolFactory,
    address keeperRegistry,
    address _timekeeper,
    address payable _treasury
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    KEEPER_ROLE = 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab;
    _grantRole(
      0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab,
      keeperRegistry
    );

    timekeeper = ITimekeeper(_timekeeper);
    treasury = _treasury;
  }

  function setupContracts(
    address _maltDataLab,
    address _dexHandler,
    address _vestingDistributor,
    address _rewardThrottle,
    address pool,
    address _stabilizerNode,
    address _auction,
    address _swingTraderManager
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Must be pool factory") {
    require(address(maltDataLab) == address(0), "Keeper: Already setup");
    require(_maltDataLab != address(0), "Keeper: MaltDataLab addr(0)");
    require(_dexHandler != address(0), "Keeper: DexHandler addr(0)");
    require(_rewardThrottle != address(0), "Keeper: RewardThrottle addr(0)");
    require(_vestingDistributor != address(0), "Keeper: VestinDist addr(0)");
    require(_stabilizerNode != address(0), "Keeper: StabNode addr(0)");
    require(_auction != address(0), "Keeper: Auction addr(0)");
    require(_swingTraderManager != address(0), "Keeper: Auction addr(0)");

    maltDataLab = IMaltDataLab(_maltDataLab);
    dexHandler = IDexHandler(_dexHandler);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    vestingDistributor = IVestingDistributor(_vestingDistributor);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    auction = IAuction(_auction);
    swingTraderManager = ISwingTrader(_swingTraderManager);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    if (paused) {
      return (false, abi.encode(""));
    }
    uint256 currentEpoch = timekeeper.epoch();

    uint256 nextEpochStart = timekeeper.getEpochStartTime(currentEpoch + 1);

    bool shouldAdvance = block.timestamp >= nextEpochStart;

    (
      uint256 price,
      uint256 rootK,
      uint256 priceCumulative,
      uint256 blockTimestampLast
    ) = _getPoolState();

    uint256 swingTraderMaltRatio = swingTraderManager
      .calculateSwingTraderMaltRatio();

    IMovingAverage ratioMA = maltDataLab.ratioMA();
    uint256 sampleLength = ratioMA.sampleLength() / 2;

    performData = abi.encode(
      shouldAdvance,
      upkeepVesting,
      upkeepTracking,
      upkeepStability && _shouldAdjustSupply(price),
      (block.timestamp - lastUpdateMaltRatio) > sampleLength,
      price,
      rootK,
      priceCumulative,
      blockTimestampLast,
      swingTraderMaltRatio
    );
    upkeepNeeded = (block.timestamp - lastTimestamp) > minInterval;
  }

  function _shouldAdjustSupply(uint256 livePrice) internal view returns (bool) {
    bool stabilizeToPeg = stabilizerNode.onlyStabilizeToPeg();
    uint256 exchangeRate = maltDataLab.maltPriceAverage(
      stabilizerNode.priceAveragePeriod()
    );
    ERC20 collateralToken = ERC20(maltDataLab.collateralToken());
    uint256 decimals = collateralToken.decimals();
    uint256 pegPrice = maltDataLab.priceTarget();
    uint256 priceTarget = pegPrice;

    if (!stabilizeToPeg) {
      priceTarget = maltDataLab.getActualPriceTarget();
    }

    uint256 upperThreshold = (priceTarget *
      stabilizerNode.upperStabilityThresholdBps()) / 10000;
    uint256 lowerThreshold = (priceTarget *
      stabilizerNode.lowerStabilityThresholdBps()) / 10000;

    (uint256 livePrice, ) = dexHandler.maltMarketPrice();

    if (
      livePrice >=
      (pegPrice -
        (pegPrice * stabilizerNode.lowerStabilityThresholdBps()) /
        10000)
    ) {
      priceTarget = pegPrice;
    }

    uint256 currentAuctionId = auction.currentAuctionId();

    if (auction.isAuctionFinished(currentAuctionId)) {
      return true;
    }

    return ((exchangeRate <= (priceTarget - lowerThreshold) &&
      livePrice <= (priceTarget - lowerThreshold) &&
      !auction.auctionExists(currentAuctionId)) ||
      (exchangeRate >= (priceTarget + upperThreshold) &&
        livePrice >= (priceTarget + upperThreshold)));
  }

  function _getPoolState()
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    address collateralToken = maltDataLab.collateralToken();
    address malt = maltDataLab.malt();
    address stakeToken = maltDataLab.stakeToken();

    (
      uint256 reserve0,
      uint256 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(stakeToken).getReserves();

    uint256 kLast = reserve0 * reserve1;
    uint256 rootK = Babylonian.sqrt(kLast);

    uint256 priceCumulative;

    if (malt < collateralToken) {
      priceCumulative = IUniswapV2Pair(stakeToken).price0CumulativeLast();
    } else {
      priceCumulative = IUniswapV2Pair(stakeToken).price1CumulativeLast();
    }

    (uint256 price, ) = dexHandler.maltMarketPrice();

    return (price, rootK, priceCumulative, blockTimestampLast);
  }

  function performUpkeep(bytes calldata performData)
    external
    onlyRoleMalt(KEEPER_ROLE, "Must have keeper role")
  {
    (
      bool shouldAdvance,
      bool shouldVest,
      bool shouldTrackPool,
      bool shouldStabilize,
      bool shouldTrackMaltRatio,
      uint256 price,
      uint256 rootK,
      uint256 priceCumulative,
      uint256 blockTimestampLast,
      uint256 swingTraderMaltRatio
    ) = abi.decode(
        performData,
        (
          bool,
          bool,
          bool,
          bool,
          bool,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256
        )
      );

    if (shouldVest) {
      vestingDistributor.vest();
    }

    if (shouldTrackPool) {
      // This keeper should be whitelisted to make updates
      maltDataLab.trustedTrackPool(
        price,
        rootK,
        priceCumulative,
        blockTimestampLast
      );
    }

    if (shouldAdvance) {
      timekeeper.advance();
    }

    if (shouldStabilize) {
      try stabilizerNode.stabilize() {} catch (bytes memory error) {
        // do nothing if it fails
      }
    }

    if (shouldTrackMaltRatio) {
      maltDataLab.trustedTrackMaltRatio(swingTraderMaltRatio);
      lastUpdateMaltRatio = block.timestamp;
    }

    rewardThrottle.updateDesiredAPR();

    // send any proceeds to the treasury
    ERC20 collateralToken = ERC20(maltDataLab.collateralToken());
    uint256 balance = collateralToken.balanceOf(address(this));

    if (balance > 0) {
      collateralToken.safeTransfer(treasury, balance);
    }

    ERC20 malt = ERC20(maltDataLab.malt());
    balance = malt.balanceOf(address(this));

    if (balance > 0) {
      malt.safeTransfer(treasury, balance);
    }

    lastTimestamp = block.timestamp;
  }

  function setVestingDistributor(address _distributor)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    require(_distributor != address(0), "Cannot use 0 address");
    vestingDistributor = IVestingDistributor(_distributor);
    emit SetVestingDistributor(_distributor);
  }

  function setMinInterval(uint256 _interval)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    minInterval = _interval;
    emit SetMinInterval(_interval);
  }

  function setUpkeepVesting(bool _upkeepVesting)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    upkeepVesting = _upkeepVesting;
    emit SetUpkeepVesting(_upkeepVesting);
  }

  function setUpkeepStability(bool _upkeepStability)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    upkeepStability = _upkeepStability;
    emit SetUpkeepStability(_upkeepStability);
  }

  function setUpkeepTracking(bool _upkeepTracking)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    upkeepTracking = _upkeepTracking;
    emit SetUpkeepTracking(_upkeepTracking);
  }

  function setTreasury(address payable _treasury)
    external
    onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role")
  {
    treasury = _treasury;
    emit UpdateTreasury(_treasury);
  }

  function togglePaused()
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin role")
  {
    bool localPaused = paused;
    paused = !localPaused;
    emit SetPaused(localPaused);
  }

  function _accessControl()
    internal
    view
    override(
      RewardThrottleExtension,
      DataLabExtension,
      DexHandlerExtension,
      AuctionExtension,
      SwingTraderManagerExtension,
      StabilizerNodeExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRepository {
  function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct CoreCollateral {
  uint256 total;
  uint256 rewardOverflow;
  uint256 liquidityExtension;
  uint256 swingTrader;
  uint256 swingTraderMalt;
  uint256 arbTokens;
}

struct PoolCollateral {
  address lpPool;
  uint256 total;
  uint256 rewardOverflow;
  uint256 liquidityExtension;
  uint256 swingTrader;
  uint256 swingTraderMalt;
  uint256 arbTokens;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDualMovingAverage {
  function getValue() external view returns (uint256, uint256);

  function getValueWithLookback(uint256 _lookbackTime)
    external
    view
    returns (uint256, uint256);

  function getLiveSample()
    external
    view
    returns (
      uint64,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function update(uint256 newValue, uint256 newValueTwo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMovingAverage {
  function getValue() external view returns (uint256);

  function getValueWithLookback(uint256 _lookbackTime)
    external
    view
    returns (uint256);

  function getLiveSample()
    external
    view
    returns (
      uint64,
      uint256,
      uint256,
      uint256
    );

  function update(uint256 newValue) external;

  function sampleLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBurnMintableERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint256);

  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
pragma solidity ^0.8.11;

import "../StabilityPod/PoolCollateral.sol";

interface IImpliedCollateralService {
  function collateralRatio() external view returns (uint256 icTotal);

  function syncGlobalCollateral() external;

  function getCollateralizedMalt()
    external
    view
    returns (PoolCollateral memory);

  function totalUsefulCollateral() external view returns (uint256);

  function swingTraderCollateralRatio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwingTrader {
  function buyMalt(uint256 maxCapital) external returns (uint256 capitalUsed);

  function sellMalt(uint256 maxAmount) external returns (uint256 amountSold);

  function costBasis() external view returns (uint256 cost, uint256 decimals);

  function calculateSwingTraderMaltRatio()
    external
    view
    returns (uint256 maltRatio);

  function delegateCapital(uint256 amount, address destination) external;

  function deployedCapital() external view returns (uint256);

  function getTokenBalances()
    external
    view
    returns (uint256 maltBalance, uint256 collateralBalance);

  function totalProfit() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../interfaces/IBurnMintableERC20.sol";
import "openzeppelin/utils/math/SafeMath.sol";
import "openzeppelin/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBurnMintableERC20 for IBurnMintableERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBurnMintableERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IBurnMintableERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IBurnMintableERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IBurnMintableERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IBurnMintableERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IBurnMintableERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IBurnMintableERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IBurnMintableERC20 token, bytes memory data)
    private
  {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

import "./FullMath.sol";
import "./Babylonian.sol";
import "./BitMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint256 _x;
  }

  uint8 public constant RESOLUTION = 112;
  uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000; // 2**224
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint256 y)
    internal
    pure
    returns (uq144x112 memory)
  {
    uint256 z = 0;
    require(
      y == 0 || (z = self._x * y) / y == self._x,
      "FixedPoint::mul: overflow"
    );
    return uq144x112(z);
  }

  // multiply a UQ112x112 by an int and decode, returning an int
  // reverts on overflow
  function muli(uq112x112 memory self, int256 y)
    internal
    pure
    returns (int256)
  {
    uint256 z = FullMath.mulDivRoundingUp(
      self._x,
      uint256(y < 0 ? -y : y),
      Q112
    );
    require(z < 2**255, "FixedPoint::muli: overflow");
    return y < 0 ? -int256(z) : int256(z);
  }

  // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
  // lossy
  function muluq(uq112x112 memory self, uq112x112 memory other)
    internal
    pure
    returns (uq112x112 memory)
  {
    if (self._x == 0 || other._x == 0) {
      return uq112x112(0);
    }
    uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
    uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
    uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
    uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

    // partial products
    uint224 upper = uint224(upper_self) * upper_other; // * 2^0
    uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
    uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
    uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

    // so the bit shift does not overflow
    require(upper <= type(uint112).max, "FixedPoint::muluq: upper overflow");

    // this cannot exceed 256 bits, all values are 224 bits
    uint256 sum = uint256(upper << RESOLUTION) +
      uppers_lowero +
      uppero_lowers +
      (lower >> RESOLUTION);

    // so the cast does not overflow
    require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

    return uq112x112(uint224(sum));
  }

  // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
  function divuq(uq112x112 memory self, uq112x112 memory other)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(other._x > 0, "FixedPoint::divuq: division by zero");
    if (self._x == other._x) {
      return uq112x112(uint224(Q112));
    }
    if (self._x <= type(uint144).max) {
      uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
      require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
      return uq112x112(uint224(value));
    }

    uint256 result = FullMath.mulDivRoundingUp(Q112, self._x, other._x);
    require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
    return uq112x112(uint224(result));
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // can be lossy
  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= type(uint144).max) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDivRoundingUp(numerator, Q112, denominator);
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }

  // take the reciprocal of a UQ112x112
  // reverts on overflow
  // lossy
  function reciprocal(uq112x112 memory self)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
    require(self._x != 1, "FixedPoint::reciprocal: overflow");
    return uq112x112(uint224(Q224 / self._x));
  }

  // square root of a UQ112x112
  // lossy between 0/1 and 40 bits
  function sqrt(uq112x112 memory self)
    internal
    pure
    returns (uq112x112 memory)
  {
    if (self._x <= type(uint144).max) {
      return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
    }

    uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
    safeShiftBits -= safeShiftBits % 2;
    return
      uq112x112(
        uint224(
          Babylonian.sqrt(uint256(self._x) << safeShiftBits) <<
            ((112 - safeShiftBits) / 2)
        )
      );
  }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.11;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt(int256 x) internal pure returns (int128) {
    unchecked {
      require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128(x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt(int128 x) internal pure returns (int64) {
    unchecked {
      return int64(x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt(uint256 x) internal pure returns (int128) {
    unchecked {
      require(x <= 0x7FFFFFFFFFFFFFFF);
      return int128(int256(x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt(int128 x) internal pure returns (uint64) {
    unchecked {
      require(x >= 0);
      return uint64(uint128(x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128(int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128(int128 x) internal pure returns (int256) {
    unchecked {
      return int256(x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = (int256(x) * y) >> 64;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli(int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require(
          y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000
        );
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu(x, uint256(y));
        if (negativeResult) {
          require(
            absoluteResult <=
              0x8000000000000000000000000000000000000000000000000000000000000000
          );
          return -int256(absoluteResult); // We rely on overflow behavior here
        } else {
          require(
            absoluteResult <=
              0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          );
          return int256(absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu(int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require(x >= 0);

      uint256 lo = (uint256(int256(x)) *
        (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256(int256(x)) * (y >> 128);

      require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require(
        hi <=
          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
            lo
      );
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);
      int256 result = (int256(x) << 64) / y;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi(int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu(uint256(x), uint256(y));
      if (negativeResult) {
        require(absoluteResult <= 0x80000000000000000000000000000000);
        return -int128(absoluteResult); // We rely on overflow behavior here
      } else {
        require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128(absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu(uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require(y != 0);
      uint128 result = divuu(x, y);
      require(result <= uint128(MAX_64x64));
      return int128(result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv(int128 x) internal pure returns (int128) {
    unchecked {
      require(x != 0);
      int256 result = int256(0x100000000000000000000000000000000) / x;
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128((int256(x) + int256(y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg(int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256(x) * int256(y);
      require(m >= 0);
      require(
        m < 0x4000000000000000000000000000000000000000000000000000000000000000
      );
      return int128(sqrtu(uint256(m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow(int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128(x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x2 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x4 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          if (y & 0x8 != 0) {
            absResult = (absResult * absX) >> 127;
          }
          absX = (absX * absX) >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) {
          absX <<= 32;
          absXShift -= 32;
        }
        if (absX < 0x10000000000000000000000000000) {
          absX <<= 16;
          absXShift -= 16;
        }
        if (absX < 0x1000000000000000000000000000000) {
          absX <<= 8;
          absXShift -= 8;
        }
        if (absX < 0x10000000000000000000000000000000) {
          absX <<= 4;
          absXShift -= 4;
        }
        if (absX < 0x40000000000000000000000000000000) {
          absX <<= 2;
          absXShift -= 2;
        }
        if (absX < 0x80000000000000000000000000000000) {
          absX <<= 1;
          absXShift -= 1;
        }

        uint256 resultShift = 0;
        while (y != 0) {
          require(absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = (absResult * absX) >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = (absX * absX) >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
            absX >>= 1;
            absXShift += 1;
          }

          y >>= 1;
        }

        require(resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256(absResult) : int256(absResult);
      require(result >= MIN_64x64 && result <= MAX_64x64);
      return int128(result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt(int128 x) internal pure returns (int128) {
    unchecked {
      require(x >= 0);
      return int128(sqrtu(uint256(int256(x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2(int128 x) internal pure returns (int128) {
    unchecked {
      require(x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) {
        xc >>= 64;
        msb += 64;
      }
      if (xc >= 0x100000000) {
        xc >>= 32;
        msb += 32;
      }
      if (xc >= 0x10000) {
        xc >>= 16;
        msb += 16;
      }
      if (xc >= 0x100) {
        xc >>= 8;
        msb += 8;
      }
      if (xc >= 0x10) {
        xc >>= 4;
        msb += 4;
      }
      if (xc >= 0x4) {
        xc >>= 2;
        msb += 2;
      }
      if (xc >= 0x2) msb += 1; // No need to shift xc anymore

      int256 result = (msb - 64) << 64;
      uint256 ux = uint256(int256(x)) << uint256(127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256(b);
      }

      return int128(result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln(int128 x) internal pure returns (int128) {
    unchecked {
      require(x > 0);

      return
        int128(
          int256(
            (uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >>
              128
          )
        );
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2(int128 x) internal pure returns (int128) {
    unchecked {
      require(x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
      if (x & 0x4000000000000000 > 0)
        result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
      if (x & 0x2000000000000000 > 0)
        result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
      if (x & 0x1000000000000000 > 0)
        result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
      if (x & 0x800000000000000 > 0)
        result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
      if (x & 0x400000000000000 > 0)
        result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
      if (x & 0x200000000000000 > 0)
        result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
      if (x & 0x100000000000000 > 0)
        result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
      if (x & 0x80000000000000 > 0)
        result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
      if (x & 0x40000000000000 > 0)
        result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
      if (x & 0x20000000000000 > 0)
        result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
      if (x & 0x10000000000000 > 0)
        result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
      if (x & 0x8000000000000 > 0)
        result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
      if (x & 0x4000000000000 > 0)
        result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
      if (x & 0x2000000000000 > 0)
        result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
      if (x & 0x1000000000000 > 0)
        result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
      if (x & 0x800000000000 > 0)
        result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
      if (x & 0x400000000000 > 0)
        result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
      if (x & 0x200000000000 > 0)
        result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
      if (x & 0x100000000000 > 0)
        result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
      if (x & 0x80000000000 > 0)
        result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
      if (x & 0x40000000000 > 0)
        result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
      if (x & 0x20000000000 > 0)
        result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
      if (x & 0x10000000000 > 0)
        result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
      if (x & 0x8000000000 > 0)
        result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
      if (x & 0x4000000000 > 0)
        result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
      if (x & 0x2000000000 > 0)
        result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
      if (x & 0x1000000000 > 0)
        result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
      if (x & 0x800000000 > 0)
        result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
      if (x & 0x400000000 > 0)
        result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
      if (x & 0x200000000 > 0)
        result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
      if (x & 0x100000000 > 0)
        result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
      if (x & 0x80000000 > 0)
        result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
      if (x & 0x40000000 > 0)
        result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
      if (x & 0x20000000 > 0)
        result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
      if (x & 0x10000000 > 0)
        result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
      if (x & 0x8000000 > 0)
        result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
      if (x & 0x4000000 > 0)
        result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
      if (x & 0x2000000 > 0)
        result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
      if (x & 0x1000000 > 0)
        result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
      if (x & 0x800000 > 0)
        result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
      if (x & 0x400000 > 0)
        result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
      if (x & 0x200000 > 0)
        result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
      if (x & 0x100000 > 0)
        result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
      if (x & 0x80000 > 0)
        result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
      if (x & 0x40000 > 0)
        result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
      if (x & 0x20000 > 0)
        result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
      if (x & 0x10000 > 0)
        result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
      if (x & 0x8000 > 0)
        result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
      if (x & 0x4000 > 0)
        result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
      if (x & 0x2000 > 0)
        result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
      if (x & 0x1000 > 0)
        result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
      if (x & 0x800 > 0)
        result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
      if (x & 0x400 > 0)
        result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
      if (x & 0x200 > 0)
        result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
      if (x & 0x100 > 0)
        result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
      if (x & 0x80 > 0)
        result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
      if (x & 0x40 > 0)
        result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
      if (x & 0x20 > 0)
        result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
      if (x & 0x10 > 0)
        result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
      if (x & 0x8 > 0)
        result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
      if (x & 0x4 > 0)
        result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
      if (x & 0x2 > 0)
        result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
      if (x & 0x1 > 0)
        result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

      result >>= uint256(int256(63 - (x >> 64)));
      require(result <= uint256(int256(MAX_64x64)));

      return int128(int256(result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp(int128 x) internal pure returns (int128) {
    unchecked {
      require(x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return
        exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu(uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require(y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) {
          xc >>= 32;
          msb += 32;
        }
        if (xc >= 0x10000) {
          xc >>= 16;
          msb += 16;
        }
        if (xc >= 0x100) {
          xc >>= 8;
          msb += 8;
        }
        if (xc >= 0x10) {
          xc >>= 4;
          msb += 4;
        }
        if (xc >= 0x4) {
          xc >>= 2;
          msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert(xh == hi >> 128);

        result += xl / y;
      }

      require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128(result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu(uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
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
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128(r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../Permissions.sol";
import "../interfaces/IBurnMintableERC20.sol";
import "../libraries/uniswap/IUniswapV2Pair.sol";
import "../interfaces/IStabilizedPoolFactory.sol";

/// @title Pool Unit
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that are part of a stabilized pool deployment
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract StabilizedPoolUnit is Permissions {
  bytes32 public immutable POOL_FACTORY_ROLE;
  bytes32 public immutable POOL_UPDATER_ROLE;
  bytes32 public immutable STABILIZER_NODE_ROLE;
  bytes32 public immutable LIQUIDITY_MINE_ROLE;
  bytes32 public immutable AUCTION_ROLE;
  bytes32 public immutable REWARD_THROTTLE_ROLE;

  bool internal contractActive;

  /* Permanent Members */
  IBurnMintableERC20 public malt;
  ERC20 public collateralToken;
  IUniswapV2Pair public stakeToken;

  /* Updatable */
  IStabilizedPoolFactory public poolFactory;

  event SetPoolUpdater(address updater);

  constructor(
    address _timelock,
    address _repository,
    address _poolFactory
  ) {
    require(_timelock != address(0), "Timelock addr(0)");
    require(_repository != address(0), "Repo addr(0)");
    _initialSetup(_repository);

    POOL_FACTORY_ROLE = 0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74;
    POOL_UPDATER_ROLE = 0xb70e81d43273d7b57d823256e2fd3d6bb0b670e5f5e1253ffd1c5f776a989c34;
    STABILIZER_NODE_ROLE = 0x9aebf7c4e2f9399fa54d66431d5afb53d5ce943832be8ebbced058f5450edf1b;
    LIQUIDITY_MINE_ROLE = 0xb8fddb29c347bbf5ee0bb24db027d53d603215206359b1142519846b9c87707f;
    AUCTION_ROLE = 0xc5e2d1653feba496cf5ce3a744b90ea18acf0df3d036aba9b2f85992a1467906;
    REWARD_THROTTLE_ROLE = 0x0beda4984192b677bceea9b67542fab864a133964c43188171c1c68a84cd3514;
    _roleSetup(
      0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74,
      _poolFactory
    );
    _setupRole(
      0x598cee9ad6a01a66130d639a08dbc750d4a51977e842638d2fc97de81141dc74,
      _timelock
    );
    _roleSetup(
      0x9aebf7c4e2f9399fa54d66431d5afb53d5ce943832be8ebbced058f5450edf1b,
      _timelock
    );
    _roleSetup(
      0xb8fddb29c347bbf5ee0bb24db027d53d603215206359b1142519846b9c87707f,
      _timelock
    );
    _roleSetup(
      0xc5e2d1653feba496cf5ce3a744b90ea18acf0df3d036aba9b2f85992a1467906,
      _timelock
    );
    _roleSetup(
      0x0beda4984192b677bceea9b67542fab864a133964c43188171c1c68a84cd3514,
      _timelock
    );

    poolFactory = IStabilizedPoolFactory(_poolFactory);
  }

  function setPoolUpdater(address _updater)
    internal
    onlyRoleMalt(POOL_FACTORY_ROLE, "Must have pool factory role")
  {
    _setPoolUpdater(_updater);
  }

  function setPoolFactory(address _poolFactory)
    internal
    onlyRoleMalt(getRoleAdmin(POOL_FACTORY_ROLE), "Must be pool factory admin role")
  {
    _transferRole(_poolFactory, address(poolFactory), POOL_FACTORY_ROLE);
    poolFactory = IStabilizedPoolFactory(_poolFactory);
  }

  function _setPoolUpdater(address _updater) internal {
    require(_updater != address(0), "Cannot use addr(0)");
    _grantRole(POOL_UPDATER_ROLE, _updater);
    emit SetPoolUpdater(_updater);
  }

  modifier onlyActive() {
    require(contractActive, "Contract not active");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IImpliedCollateralService.sol";

/// @title Implied Collateral Service Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the ImpliedCollateralService
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract ImpliedCollateralServiceExtension {
  IImpliedCollateralService public impliedCollateralService;

  event SetImpliedCollateralService(address impliedCollataeralService);

  /// @notice Method for setting the address of the impliedCollateralService
  /// @param _impliedCollateralService The address of the ImpliedCollateralService instance
  /// @dev Only callable via the PoolUpdater contract
  function setImpliedCollateralService(address _impliedCollateralService)
    external
  {
    _accessControl();
    require(_impliedCollateralService != address(0), "Cannot use addr(0)");
    _beforeSetImpliedCollateralService(_impliedCollateralService);
    impliedCollateralService = IImpliedCollateralService(
      _impliedCollateralService
    );
    emit SetImpliedCollateralService(_impliedCollateralService);
  }

  function _beforeSetImpliedCollateralService(address _impliedCollateralService)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ISwingTrader.sol";

/// @title Swing Trader Manager Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the SwingTrader
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract SwingTraderManagerExtension {
  ISwingTrader public swingTraderManager;

  event SetSwingTraderManager(address swingTraderManager);

  /// @notice Method for setting the address of the swingTraderManager
  /// @param _swingTraderManager The contract address of the SwingTraderManager instance
  /// @dev Only callable via the PoolUpdater contract
  function setSwingTraderManager(address _swingTraderManager) external {
    _accessControl();
    require(_swingTraderManager != address(0), "Cannot use addr(0)");
    _beforeSetSwingTraderManager(_swingTraderManager);
    swingTraderManager = ISwingTrader(_swingTraderManager);
    emit SetSwingTraderManager(_swingTraderManager);
  }

  function _beforeSetSwingTraderManager(address _swingTraderManager)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IGlobalImpliedCollateralService.sol";

/// @title Global Implied Collateral Service Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the GlobalImpliedCollateralService
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract GlobalICExtension {
  IGlobalImpliedCollateralService public globalIC;

  event SetGlobalIC(address globalIC);

  /// @notice Privileged method for setting the address of the globalIC
  /// @param _globalIC The contract address of the GlobalImpliedCollateralService instance
  /// @dev Only callable via the PoolUpdater contract
  function setGlobalIC(address _globalIC) external {
    _accessControl();
    require(_globalIC != address(0), "Cannot use addr(0)");
    _beforeSetGlobalIC(_globalIC);
    globalIC = IGlobalImpliedCollateralService(_globalIC);
    emit SetGlobalIC(_globalIC);
  }

  function _beforeSetGlobalIC(address _globalIC) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IMaltDataLab.sol";

/// @title Malt Data Lab Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the MaltDataLab
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract DataLabExtension {
  IMaltDataLab public maltDataLab;

  event SetMaltDataLab(address maltDataLab);

  /// @notice Privileged method for setting the address of the maltDataLab
  /// @param _maltDataLab The contract address of the MaltDataLab instance
  /// @dev Only callable via the PoolUpdater contract
  function setMaltDataLab(address _maltDataLab) external {
    _accessControl();
    require(_maltDataLab != address(0), "Cannot use addr(0)");
    _beforeSetMaltDataLab(_maltDataLab);
    maltDataLab = IMaltDataLab(_maltDataLab);
    emit SetMaltDataLab(_maltDataLab);
  }

  function _beforeSetMaltDataLab(address _maltDataLab) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IStabilizerNode.sol";

/// @title Stabilizer Node Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the StabilizerNode
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract StabilizerNodeExtension {
  IStabilizerNode public stabilizerNode;

  event SetStablizerNode(address stabilizerNode);

  /// @notice Privileged method for setting the address of the stabilizerNode
  /// @param _stabilizerNode The contract address of the StabilizerNode instance
  /// @dev Only callable via the PoolUpdater contract
  function setStablizerNode(address _stabilizerNode) external {
    _accessControl();
    require(_stabilizerNode != address(0), "Cannot use addr(0)");
    _beforeSetStabilizerNode(_stabilizerNode);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    emit SetStablizerNode(_stabilizerNode);
  }

  function _beforeSetStabilizerNode(address _stabilizerNode) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IGlobalImpliedCollateralService.sol";
import "./IMovingAverage.sol";

interface IMaltDataLab {
  function priceTarget() external view returns (uint256);

  function smoothedMaltPrice() external view returns (uint256);

  function globalIC() external view returns (IGlobalImpliedCollateralService);

  function smoothedK() external view returns (uint256);

  function smoothedReserves() external view returns (uint256);

  function maltPriceAverage(uint256 _lookback) external view returns (uint256);

  function kAverage(uint256 _lookback) external view returns (uint256);

  function poolReservesAverage(uint256 _lookback)
    external
    view
    returns (uint256, uint256);

  function lastMaltPrice() external view returns (uint256, uint64);

  function lastPoolReserves()
    external
    view
    returns (
      uint256,
      uint256,
      uint64
    );

  function lastK() external view returns (uint256, uint64);

  function realValueOfLPToken(uint256 amount) external view returns (uint256);

  function trackPool() external returns (bool);

  function trustedTrackPool(
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function collateralToken() external view returns (address);

  function malt() external view returns (address);

  function stakeToken() external view returns (address);

  function getInternalAuctionEntryPrice()
    external
    view
    returns (uint256 auctionEntryPrice);

  function getSwingTraderEntryPrice()
    external
    view
    returns (uint256 stPriceTarget);

  function getActualPriceTarget() external view returns (uint256);

  function getRealBurnBudget(uint256, uint256) external view returns (uint256);

  function maltToRewardDecimals(uint256 maltAmount)
    external
    view
    returns (uint256);

  function rewardToMaltDecimals(uint256 amount) external view returns (uint256);

  function smoothedMaltRatio() external view returns (uint256);

  function ratioMA() external view returns (IMovingAverage);

  function trustedTrackMaltRatio(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ILiquidityExtension.sol";

/// @title Liquidity Extension Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the LiquidityExtension
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract LiquidityExtensionExtension {
  ILiquidityExtension public liquidityExtension;

  event SetLiquidityExtension(address liquidityExtension);

  /// @notice Method for setting the address of the liquidityExtension
  /// @param _liquidityExtension The contract address of the LiquidityExtension instance
  /// @dev Only callable via the PoolUpdater contract
  function setLiquidityExtension(address _liquidityExtension) external {
    _accessControl();
    require(_liquidityExtension != address(0), "Cannot use addr(0)");
    _beforeSetLiquidityExtension(_liquidityExtension);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    emit SetLiquidityExtension(_liquidityExtension);
  }

  function _beforeSetLiquidityExtension(address _liquidityExtension)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IOverflow.sol";

/// @title Reward Overflow Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the RewardOverflowPool
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract RewardOverflowExtension {
  IOverflow public overflowPool;

  event SetOverflowPool(address overflowPool);

  /// @notice Method for setting the address of the overflowPool
  /// @param _overflowPool The contract address of the RewardOverflowPool instance
  /// @dev Only callable via the PoolUpdater contract
  function setOverflowPool(address _overflowPool) external {
    _accessControl();
    require(_overflowPool != address(0), "Cannot use addr(0)");
    _beforeSetOverflowPool(_overflowPool);
    overflowPool = IOverflow(_overflowPool);
    emit SetOverflowPool(_overflowPool);
  }

  function _beforeSetOverflowPool(address _overflowPool) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IAuction.sol";

/// @title Auction Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the Auction
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract AuctionExtension {
  IAuction public auction;

  event SetAuction(address auction);

  /// @notice Method for setting the address of the auction
  /// @param _auction The address of the Auction instance
  /// @dev Only callable via the PoolUpdater contract
  function setAuction(address _auction) external {
    _accessControl();
    require(_auction != address(0), "Cannot use addr(0)");
    _beforeSetAuction(_auction);
    auction = IAuction(_auction);
    emit SetAuction(_auction);
  }

  function _beforeSetAuction(address _auction) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAuction {
  function unclaimedArbTokens() external view returns (uint256);

  function replenishingAuctionId() external view returns (uint256);

  function currentAuctionId() external view returns (uint256);

  function purchaseArbitrageTokens(uint256 amount, uint256 minPurchased)
    external;

  function claimArbitrage(uint256 _auctionId) external;

  function isAuctionFinished(uint256 _id) external view returns (bool);

  function auctionActive(uint256 _id) external view returns (bool);

  function isAuctionFinalized(uint256 _id) external view returns (bool);

  function userClaimableArbTokens(address account, uint256 auctionId)
    external
    view
    returns (uint256);

  function balanceOfArbTokens(uint256 _auctionId, address account)
    external
    view
    returns (uint256);

  function averageMaltPrice(uint256 _id) external view returns (uint256);

  function currentPrice(uint256 _id) external view returns (uint256);

  function getAuctionCommitments(uint256 _id)
    external
    view
    returns (uint256 commitments, uint256 maxCommitments);

  function getAuctionPrices(uint256 _id)
    external
    view
    returns (
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice
    );

  function auctionExists(uint256 _id) external view returns (bool);

  function getAccountCommitments(address account)
    external
    view
    returns (
      uint256[] memory auctions,
      uint256[] memory commitments,
      uint256[] memory awardedTokens,
      uint256[] memory redeemedTokens,
      uint256[] memory finalPrice,
      uint256[] memory claimable,
      uint256[] memory exitedTokens,
      bool[] memory finished
    );

  function getAccountCommitmentAuctions(address account)
    external
    view
    returns (uint256[] memory);

  function hasOngoingAuction() external view returns (bool);

  function getActiveAuction()
    external
    view
    returns (
      uint256 auctionId,
      uint256 maxCommitments,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 finalPurchased
    );

  function getAuction(uint256 _id)
    external
    view
    returns (
      uint256 maxCommitments,
      uint256 commitments,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 finalBurnBudget,
      uint256 finalPurchased
    );

  function getAuctionCore(uint256 _id)
    external
    view
    returns (
      uint256 auctionId,
      uint256 commitments,
      uint256 maltPurchased,
      uint256 startingPrice,
      uint256 finalPrice,
      uint256 pegPrice,
      uint256 startingTime,
      uint256 endingTime,
      uint256 preAuctionReserveRatio,
      bool active
    );

  function checkAuctionFinalization() external;

  function allocateArbRewards(uint256 rewarded) external returns (uint256);

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    returns (bool);

  function getAuctionParticipationForAccount(address account, uint256 auctionId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function accountExit(
    address account,
    uint256 auctionId,
    uint256 amount
  ) external;

  function endAuctionEarly() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IOverflow {
  function requestCapital(uint256 amount)
    external
    returns (uint256 fulfilledAmount);

  function purchaseArbitrageTokens(uint256 maxAmount)
    external
    returns (uint256 remaining);

  function claim() external;

  function outstandingArbTokens() external view returns (uint256 outstanding);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ILiquidityExtension {
  function hasMinimumReserves() external view returns (bool);

  function collateralDeficit() external view returns (uint256, uint256);

  function reserveRatio() external view returns (uint256, uint256);

  function reserveRatioAverage(uint256)
    external
    view
    returns (uint256, uint256);

  function purchaseAndBurn(uint256 amount) external returns (uint256 purchased);

  function allocateBurnBudget(uint256 amount) external;

  function buyBack(uint256 maltAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IAuction.sol";

interface IStabilizerNode {
  function stabilize() external;

  function auction() external view returns (IAuction);

  function priceAveragePeriod() external view returns (uint256);

  function upperStabilityThresholdBps() external view returns (uint256);

  function lowerStabilityThresholdBps() external view returns (uint256);

  function onlyStabilizeToPeg() external view returns (bool);

  function primedWindowData() external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IDexHandler.sol";

/// @title Dex Handler Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the DexHandler
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract DexHandlerExtension {
  IDexHandler public dexHandler;

  event SetDexHandler(address dexHandler);

  /// @notice Privileged method for setting the address of the dexHandler
  /// @param _dexHandler The contract address of the DexHandler instance
  /// @dev Only callable via the PoolUpdater contract
  function setDexHandler(address _dexHandler) external {
    _accessControl();
    require(_dexHandler != address(0), "Cannot use addr(0)");
    _beforeSetDexHandler(_dexHandler);
    dexHandler = IDexHandler(_dexHandler);
    emit SetDexHandler(_dexHandler);
  }

  function _beforeSetDexHandler(address _dexHandler) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IProfitDistributor.sol";

/// @title Profit Distributor Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the ProfitDistributor
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract ProfitDistributorExtension {
  IProfitDistributor public profitDistributor;

  event SetProfitDistributor(address profitDistributor);

  /// @notice Privileged method for setting the address of the profitDistributor
  /// @param _profitDistributor The contract address of the ProfitDistributor instance
  /// @dev Only callable via the PoolUpdater contract
  function setProfitDistributor(address _profitDistributor) external {
    _accessControl();
    require(_profitDistributor != address(0), "Cannot use addr(0)");
    _beforeSetProfitDistributor(_profitDistributor);
    profitDistributor = IProfitDistributor(_profitDistributor);
    emit SetProfitDistributor(_profitDistributor);
  }

  function _beforeSetProfitDistributor(address _profitDistributor)
    internal
    virtual
  {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITimekeeper {
  function epoch() external view returns (uint256);

  function epochLength() external view returns (uint256);

  function genesisTime() external view returns (uint256);

  function getEpochStartTime(uint256 _epoch) external view returns (uint256);

  function epochsPerYear() external view returns (uint256);

  function advance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRewardThrottle {
  function handleReward() external;

  function epochAPR(uint256 epoch) external view returns (uint256);

  function targetAPR() external view returns (uint256);

  function epochData(uint256 epoch)
    external
    view
    returns (
      uint256 profit,
      uint256 rewarded,
      uint256 bondedValue,
      uint256 throttle
    );

  function checkRewardUnderflow() external;

  function runwayDeficit() external view returns (uint256);

  function updateDesiredAPR() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDexHandler {
  function buyMalt(uint256, uint256) external returns (uint256 purchased);

  function sellMalt(uint256, uint256) external returns (uint256 rewards);

  function addLiquidity(
    uint256,
    uint256,
    uint256
  )
    external
    returns (
      uint256 maltUsed,
      uint256 rewardUsed,
      uint256 liquidityCreated
    );

  function removeLiquidity(uint256, uint256)
    external
    returns (uint256 amountMalt, uint256 amountReward);

  function calculateMintingTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256);

  function calculateBurningTradeSize(uint256 priceTarget)
    external
    view
    returns (uint256);

  function reserves()
    external
    view
    returns (uint256 maltSupply, uint256 rewardSupply);

  function maltMarketPrice()
    external
    view
    returns (uint256 price, uint256 decimals);

  function getOptimalLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidityB
  ) external view returns (uint256 liquidityA);

  function setupContracts(
    address,
    address,
    address,
    address,
    address[] memory,
    address[] memory,
    address[] memory,
    address[] memory
  ) external;

  function addBuyer(address) external;

  function removeBuyer(address) external;

  function addSeller(address) external;

  function removeSeller(address) external;

  function addLiquidityAdder(address) external;

  function removeLiquidityAdder(address) external;

  function addLiquidityRemover(address) external;

  function removeLiquidityRemover(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISupplyDistributionController {
  function check() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAuctionStartController {
  function checkForStart() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IProfitDistributor {
  function handleProfit(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IRewardThrottle.sol";

/// @title Reward Throttle Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the RewardThrottle
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract RewardThrottleExtension {
  IRewardThrottle public rewardThrottle;

  event SetRewardThrottle(address rewardThrottle);

  /// @notice Privileged method for setting the address of the rewardThrottle
  /// @param _rewardThrottle The contract address of the RewardThrottle instance
  /// @dev Only callable via the PoolUpdater contract
  function setRewardThrottle(address _rewardThrottle) external {
    _accessControl();
    require(_rewardThrottle != address(0), "Cannot use addr(0)");
    _beforeSetRewardThrottle(_rewardThrottle);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    emit SetRewardThrottle(_rewardThrottle);
  }

  function _beforeSetRewardThrottle(address _rewardThrottle) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ISwingTrader.sol";

/// @title Swing Trader Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the SwingTrader
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract SwingTraderExtension {
  ISwingTrader public swingTrader;

  event SetSwingTrader(address swingTrader);

  /// @notice Method for setting the address of the swingTrader
  /// @param _swingTrader The contract address of the SwingTrader instance
  /// @dev Only callable via the PoolUpdater contract
  function setSwingTrader(address _swingTrader) external {
    _accessControl();
    require(_swingTrader != address(0), "Cannot use addr(0)");
    _beforeSetSwingTrader(_swingTrader);
    swingTrader = ISwingTrader(_swingTrader);
    emit SetSwingTrader(_swingTrader);
  }

  function _beforeSetSwingTrader(address _swingTrader) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
  // credit for this implementation goes to
  // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint256 x) internal pure returns (uint256) {
    if (x == 0) return 0;
    // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
    // however that code costs significantly more gas
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
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint256 r1 = x / r;
    return (r < r1 ? r : r1);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Contains 512-bit math functions
 * @notice Facilitates multiplication and division
 *              that can have overflow of an intermediate value without any loss of precision
 * @dev Handles "phantom overflow" i.e.,
 *      allows multiplication and division where an intermediate value overflows 256 bits
 */

library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision.
  ///         Throws if result overflows a uint256 or denominator == 0
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
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0, "FullMath: denominator should be more zero ");
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    uint256 twos = (~denominator + 1) & denominator;
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
      prod0 := add(prod0, mul(prod1, twos))
    }

    // Invert denominator mod 2**256
    // Now that denominator is an odd number, it has an inverse
    // modulo 2**256 such that denominator * inv = 1 mod 2**256.
    // Compute the inverse by starting with a seed that is correct
    // correct for four bits. That is, denominator * inv = 1 mod 2**4
    uint256 inv = (3 * denominator) ^ 2;
    // Now use Newton-Raphson iteration to improve the precision.
    // Thanks to Hensel's lifting lemma, this also works in modular
    // arithmetic, doubling the correct bits in each step.
    assembly {
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
      inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result := mul(prod0, inv)
    }

    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision.
  ////        Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint256).max);
      result++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./uniswap/IUniswapV2Pair.sol";

import "openzeppelin/utils/math/SafeMath.sol";

library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/DataLabExtension.sol";
import "../StabilizedPoolExtensions/ProfitDistributorExtension.sol";
import "../StabilizedPoolExtensions/DexHandlerExtension.sol";
import "../StabilizedPoolExtensions/SwingTraderManagerExtension.sol";
import "../libraries/SafeBurnMintableERC20.sol";

/// @title Swing Trader
/// @author 0xScotch <[email protected]>
/// @notice The sole aim of this contract is to defend peg and try to profit in the process.
/// @dev It does so from a privileged internal position where it is allowed to purchase on the AMM even in recovery mode
contract SwingTrader is
  StabilizedPoolUnit,
  DataLabExtension,
  ProfitDistributorExtension,
  DexHandlerExtension,
  SwingTraderManagerExtension
{
  using SafeERC20 for ERC20;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  bytes32 public immutable CAPITAL_DELEGATE_ROLE;
  bytes32 public immutable MANAGER_ROLE;

  uint256 public deployedCapital;
  uint256 public totalProfit;

  event Delegation(uint256 amount, address destination, address delegate);
  event BuyMalt(uint256 amount);
  event SellMalt(uint256 amount, uint256 profit);

  constructor(
    address timelock,
    address repository,
    address poolFactory
  ) StabilizedPoolUnit(timelock, repository, poolFactory) {
    CAPITAL_DELEGATE_ROLE = 0x6b525fb9eaf138d3dc2ac8323126c54cad39e34e800f9605cb60df858920b17b;
    MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08;
    _roleSetup(
      0x6b525fb9eaf138d3dc2ac8323126c54cad39e34e800f9605cb60df858920b17b,
      timelock
    );
  }

  function setupContracts(
    address _collateralToken,
    address _malt,
    address _dexHandler,
    address _swingTraderManager,
    address _maltDataLab,
    address _profitDistributor,
    address pool
  ) external onlyRoleMalt(POOL_FACTORY_ROLE, "Only pool factory role") {
    require(!contractActive, "SwingTrader: Already setup");

    require(_collateralToken != address(0), "SwingTrader: ColToken addr(0)");
    require(_malt != address(0), "SwingTrader: Malt addr(0)");
    require(_dexHandler != address(0), "SwingTrader: DexHandler addr(0)");
    require(_swingTraderManager != address(0), "SwingTrader: Manager addr(0)");
    require(_maltDataLab != address(0), "SwingTrader: MaltDataLab addr(0)");

    contractActive = true;

    _setupRole(MANAGER_ROLE, _swingTraderManager);

    _setupRole(CAPITAL_DELEGATE_ROLE, _swingTraderManager);

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    dexHandler = IDexHandler(_dexHandler);
    maltDataLab = IMaltDataLab(_maltDataLab);
    profitDistributor = IProfitDistributor(_profitDistributor);
    swingTraderManager = ISwingTrader(_swingTraderManager);

    (, address updater, ) = poolFactory.getPool(pool);
    _setPoolUpdater(updater);
  }

  function _beforeSetSwingTraderManager(address _swingTraderManager)
    internal
    override
  {
    _transferRole(
      _swingTraderManager,
      address(swingTraderManager),
      MANAGER_ROLE
    );
    _transferRole(
      _swingTraderManager,
      address(swingTraderManager),
      CAPITAL_DELEGATE_ROLE
    );
  }

  function buyMalt(uint256 maxCapital)
    external
    onlyRoleMalt(MANAGER_ROLE, "Must have swing trader manager privs")
    onlyActive
    returns (uint256 capitalUsed)
  {
    if (maxCapital == 0) {
      return 0;
    }

    uint256 balance = collateralToken.balanceOf(address(this));

    if (balance == 0) {
      return 0;
    }

    if (maxCapital < balance) {
      balance = maxCapital;
    }

    collateralToken.safeTransfer(address(dexHandler), balance);
    dexHandler.buyMalt(balance, 10000); // 100% allowable slippage

    deployedCapital = deployedCapital + balance;

    emit BuyMalt(balance);

    return balance;
  }

  function sellMalt(uint256 maxAmount)
    external
    onlyRoleMalt(MANAGER_ROLE, "Must have swing trader manager privs")
    onlyActive
    returns (uint256 amountSold)
  {
    if (maxAmount == 0) {
      return 0;
    }

    uint256 totalMaltBalance = malt.balanceOf(address(this));

    if (totalMaltBalance == 0) {
      return 0;
    }

    (uint256 basis, ) = costBasis();

    if (maxAmount > totalMaltBalance) {
      maxAmount = totalMaltBalance;
    }

    malt.safeTransfer(address(dexHandler), maxAmount);
    uint256 rewards = dexHandler.sellMalt(maxAmount, 10000);

    uint256 profit = _calculateProfit(basis, maxAmount, rewards);

    uint256 deployed = deployedCapital; // gas

    if (rewards <= deployed && maxAmount < totalMaltBalance) {
      // If all malt is spent we want to reset deployed capital
      deployedCapital = deployed - rewards + profit;
    } else {
      deployedCapital = 0;
    }

    _handleProfitDistribution(profit);

    totalProfit += profit;

    emit SellMalt(maxAmount, profit);

    return maxAmount;
  }

  function _handleProfitDistribution(uint256 profit) internal virtual {
    if (profit != 0) {
      collateralToken.safeTransfer(address(profitDistributor), profit);
      profitDistributor.handleProfit(profit);
    }
  }

  function costBasis() public view returns (uint256 cost, uint256 decimals) {
    // Always returns using the decimals of the collateralToken as that is the
    // currency costBasis is calculated in
    decimals = collateralToken.decimals();
    uint256 maltBalance = maltDataLab.maltToRewardDecimals(
      malt.balanceOf(address(this))
    );
    uint256 deployed = deployedCapital; // gas

    if (deployed == 0 || maltBalance == 0) {
      return (0, decimals);
    }

    return ((deployed * (10**decimals)) / maltBalance, decimals);
  }

  function _calculateProfit(
    uint256 costBasis,
    uint256 soldAmount,
    uint256 recieved
  ) internal returns (uint256 profit) {
    if (costBasis == 0) {
      return 0;
    }
    uint256 decimals = collateralToken.decimals();
    uint256 maltDecimals = malt.decimals();
    soldAmount = maltDataLab.maltToRewardDecimals(soldAmount);
    uint256 soldBasis = (costBasis * soldAmount) / (10**decimals);

    require(recieved > soldBasis, "Not profitable trade");
    profit = recieved - soldBasis;
  }

  function calculateSwingTraderMaltRatio()
    external
    view
    returns (uint256 maltRatio)
  {
    uint256 decimals = collateralToken.decimals();
    uint256 maltDecimals = malt.decimals();

    uint256 stCollateralBalance = collateralToken.balanceOf(address(this));
    uint256 stMaltBalance = maltDataLab.maltToRewardDecimals(
      malt.balanceOf(address(this))
    );

    uint256 stMaltValue = (stMaltBalance * maltDataLab.priceTarget()) /
      (10**decimals);

    uint256 netBalance = stCollateralBalance + stMaltValue;

    if (netBalance > 0) {
      maltRatio = ((stMaltValue * (10**decimals)) / netBalance);
    } else {
      maltRatio = 0;
    }
  }

  function getTokenBalances()
    external
    view
    returns (uint256 maltBalance, uint256 collateralBalance)
  {
    maltBalance = malt.balanceOf(address(this));
    collateralBalance = collateralToken.balanceOf(address(this));
  }

  function delegateCapital(uint256 amount, address destination)
    external
    onlyRoleMalt(CAPITAL_DELEGATE_ROLE, "Must have capital delegation privs")
    onlyActive
  {
    collateralToken.safeTransfer(destination, amount);
    emit Delegation(amount, destination, msg.sender);
  }

  function _accessControl()
    internal
    virtual
    override(
      DataLabExtension,
      ProfitDistributorExtension,
      DexHandlerExtension,
      SwingTraderManagerExtension
    )
  {
    _onlyRoleMalt(POOL_UPDATER_ROLE, "Must have pool updater role");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IForfeit {
  function handleForfeit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRewardMine {
  function collateralToken() external view returns (address);

  function onBond(address account, uint256 amount) external;

  function onUnbond(address account, uint256 amount) external;

  function withdrawAll() external;

  function withdraw(uint256 rewardAmount) external;

  function totalBonded() external view returns (uint256);

  function balanceOfBonded(address account) external view returns (uint256);

  function totalDeclaredReward() external view returns (uint256);

  function totalReleasedReward() external view returns (uint256);

  function totalStakePadding() external view returns (uint256);

  function balanceOfStakePadding(address account)
    external
    view
    returns (uint256);

  function getRewardOwnershipFraction(address account)
    external
    view
    returns (uint256 numerator, uint256 denominator);

  function balanceOfRewards(address account) external view returns (uint256);

  function netRewardBalance(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256 earnedReward);

  function withdrawForAccount(
    address account,
    uint256 amount,
    address to
  ) external returns (uint256);

  function declareReward(uint256 amount) external;

  function releaseReward(uint256) external;

  function valueOfBonded() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDistributor {
  function totalDeclaredReward() external view returns (uint256);

  function declareReward(uint256 amount) external;

  function bondedValue() external view returns (uint256);

  function decrementRewards(uint256 amount) external;
}

interface IVestingDistributor is IDistributor {
  function vest() external;

  function forfeit(uint256 amount) external;

  function focalID() external view returns (uint256);

  function getAllFocalUnvestedBps() external view returns (uint256, uint256);

  function getFocalUnvestedBps(uint256) external view returns (uint256);

  function getCurrentlyVested() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBonding {
  function bond(uint256 poolId, uint256 amount) external;

  function bondToAccount(
    address account,
    uint256 poolId,
    uint256 amount
  ) external;

  function unbond(uint256 poolId, uint256 amount) external;

  function unbondAndBreak(
    uint256 poolId,
    uint256 amount,
    uint256 slippageBps
  ) external;

  function totalBonded() external view returns (uint256);

  function totalBondedByPool(uint256) external view returns (uint256);

  function balanceOfBonded(uint256 poolId, address account)
    external
    view
    returns (uint256);

  function averageBondedValue(uint256 epoch) external view returns (uint256);

  function stakeToken() external view returns (address);

  function stakeTokenDecimals() external view returns (uint256);

  function poolAllocations()
    external
    view
    returns (
      uint256[] memory poolIds,
      uint256[] memory allocations,
      address[] memory distributors
    );

  function valueOfBonded(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IBonding.sol";

/// @title Bonding Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the Bonding
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract BondingExtension {
  IBonding public bonding;

  event SetBonding(address bonding);

  /// @notice Method for setting the address of the bonding
  /// @param _bonding The contract address of the Bonding instance
  /// @dev Only callable via the PoolUpdater contract
  function setBonding(address _bonding) external {
    _accessControl();
    require(_bonding != address(0), "Cannot use addr(0)");
    _beforeSetBonding(_bonding);
    bonding = IBonding(_bonding);
    emit SetBonding(_bonding);
  }

  function _beforeSetBonding(address _bonding) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMiningService {
  function withdrawAccountRewards(uint256 poolId, uint256 amount) external;

  function balanceOfRewards(address account, uint256 poolId)
    external
    view
    returns (uint256);

  function earned(address account, uint256 poolId)
    external
    view
    returns (uint256);

  function onBond(
    address account,
    uint256 poolId,
    uint256 amount
  ) external;

  function onUnbond(
    address account,
    uint256 poolId,
    uint256 amount
  ) external;

  function withdrawRewardsForAccount(
    address account,
    uint256 poolId,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBondExtension {
  function onBond(
    address,
    uint256,
    uint256
  ) external;

  function onUnbond(
    address,
    uint256,
    uint256
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IMiningService.sol";

/// @title Mining Service Extension
/// @author 0xScotch <[email protected]>
/// @notice An abstract contract inherited by all contracts that need access to the MiningService
/// @dev This helps reduce boilerplate across the codebase declaring all the other contracts in the pool
abstract contract MiningServiceExtension {
  IMiningService public miningService;

  event SetMiningService(address miningService);

  /// @notice Privileged method for setting the address of the miningService
  /// @param _miningService The contract address of the MiningService instance
  /// @dev Only callable via the PoolUpdater contract
  function setMiningService(address _miningService) external {
    _accessControl();
    require(_miningService != address(0), "Cannot use addr(0)");
    _beforeSetMiningService(_miningService);
    miningService = IMiningService(_miningService);
    emit SetMiningService(_miningService);
  }

  function _beforeSetMiningService(address _miningService) internal virtual {}

  function _accessControl() internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";
import "../StabilizedPoolExtensions/MiningServiceExtension.sol";

/// @title Abstract Reward Mine
/// @author 0xScotch <[email protected]>
/// @notice The base functionality for tracking user reward ownership, withdrawals etc
/// @dev The contract is abstract so needs to be inherited
abstract contract AbstractRewardMine is
  StabilizedPoolUnit,
  MiningServiceExtension
{
  using SafeERC20 for ERC20;

  bytes32 public immutable REWARD_MANAGER_ROLE;
  bytes32 public immutable MINING_SERVICE_ROLE;
  bytes32 public immutable REWARD_PROVIDER_ROLE;

  uint256 public poolId;

  uint256 internal _globalStakePadding;
  uint256 internal _globalWithdrawn;
  uint256 internal _globalReleased;
  mapping(address => uint256) internal _userStakePadding;
  mapping(address => uint256) internal _userWithdrawn;

  event Withdraw(address indexed account, uint256 rewarded, address indexed to);
  event SetPoolId(uint256 _poolId);

  constructor(
    address timelock,
    address initialAdmin,
    address poolFactory
  ) StabilizedPoolUnit(timelock, initialAdmin, poolFactory) {
    REWARD_MANAGER_ROLE = 0x0f51adb3f49e4a9bbb17b3783f025995eaf8c24be2c8eefff214bdfda05ef94d;
    MINING_SERVICE_ROLE = 0x946341637d150f85502674c6b415a62cb11e7566d5cfeb8b2f092551dc44a49c;
    REWARD_PROVIDER_ROLE = 0xf1f0183ef0e4c6c02c1d4fe58f4f2ffeae0c949e3f0bba2d690f5cb39aee89af;
  }

  function onBond(address account, uint256 amount)
    external
    virtual
    onlyRoleMalt(MINING_SERVICE_ROLE, "Must having mining service privilege")
  {
    _beforeBond(account, amount);
    _handleStakePadding(account, amount);
    _afterBond(account, amount);
  }

  function onUnbond(address account, uint256 amount)
    external
    virtual
    onlyRoleMalt(MINING_SERVICE_ROLE, "Must having mining service privilege")
  {
    _beforeUnbond(account, amount);
    // Withdraw all current rewards
    // Done now before we change stake padding below
    uint256 rewardEarned = earned(account);
    _handleWithdrawForAccount(account, rewardEarned, account);

    uint256 bondedBalance = balanceOfBonded(account);

    if (bondedBalance == 0) {
      return;
    }

    uint256 lessStakePadding = (balanceOfStakePadding(account) * amount) /
      bondedBalance;

    _reconcileWithdrawn(account, amount, bondedBalance);
    _removeFromStakePadding(account, lessStakePadding);
    _afterUnbond(account, amount);
  }

  function _initialSetup(
    address _collateralToken,
    address _miningService,
    address _rewardProvider
  ) internal {
    _roleSetup(MINING_SERVICE_ROLE, _miningService);
    _roleSetup(REWARD_MANAGER_ROLE, _miningService);
    _roleSetup(REWARD_PROVIDER_ROLE, _rewardProvider);

    collateralToken = ERC20(_collateralToken);
    miningService = IMiningService(_miningService);
  }

  function _addRewardProviders(address[] memory accounts) internal {
    uint256 length = accounts.length;

    for (uint256 i; i < length; ++i) {
      _grantRole(REWARD_PROVIDER_ROLE, accounts[i]);
    }
  }

  function withdrawAll() external nonReentrant {
    uint256 rewardEarned = earned(msg.sender);

    _handleWithdrawForAccount(msg.sender, rewardEarned, msg.sender);
  }

  function withdraw(uint256 rewardAmount) external nonReentrant {
    uint256 rewardEarned = earned(msg.sender);

    require(rewardAmount <= rewardEarned, "< earned");

    _handleWithdrawForAccount(msg.sender, rewardAmount, msg.sender);
  }

  /*
   * METHODS TO OVERRIDE
   */
  function totalBonded() public view virtual returns (uint256);

  function valueOfBonded() public view virtual returns (uint256);

  function balanceOfBonded(address account)
    public
    view
    virtual
    returns (uint256);

  /*
   * totalReleasedReward and totalDeclaredReward will often be the same. However, in the case
   * of vesting rewards they are different. In that case totalDeclaredReward is total
   * reward, including unvested. totalReleasedReward is just the rewards that have completed
   * the vesting schedule.
   */
  function totalDeclaredReward() public view virtual returns (uint256);

  function totalReleasedReward() public view virtual returns (uint256) {
    return _globalReleased;
  }

  function releaseReward(uint256 amount)
    external
    virtual
    onlyRoleMalt(REWARD_PROVIDER_ROLE, "Only reward provider role")
  {
    _globalReleased += amount;
    require(
      collateralToken.balanceOf(address(this)) + _globalWithdrawn >=
        _globalReleased,
      "RewardAssertion"
    );
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function totalStakePadding() public view returns (uint256) {
    return _globalStakePadding;
  }

  function balanceOfStakePadding(address account)
    public
    view
    returns (uint256)
  {
    return _userStakePadding[account];
  }

  function totalWithdrawn() public view returns (uint256) {
    return _globalWithdrawn;
  }

  function withdrawnBalance(address account) public view returns (uint256) {
    return _userWithdrawn[account];
  }

  function getRewardOwnershipFraction(address account)
    public
    view
    returns (uint256 numerator, uint256 denominator)
  {
    numerator = balanceOfRewards(account);
    denominator = totalDeclaredReward();
  }

  function balanceOfRewards(address account) public view returns (uint256) {
    /*
     * This represents the rewards allocated to a given account but does not
     * mean all these rewards are unlocked yet. The earned method will
     * fetch the balance that is unlocked for an account
     */
    uint256 balanceOfRewardedWithStakePadding = _getFullyPaddedReward(account);

    uint256 stakePaddingBalance = balanceOfStakePadding(account);

    if (balanceOfRewardedWithStakePadding > stakePaddingBalance) {
      return balanceOfRewardedWithStakePadding - stakePaddingBalance;
    }
    return 0;
  }

  function netRewardBalance(address account) public view returns (uint256) {
    uint256 rewards = balanceOfRewards(account);
    uint256 withdrawn = _userWithdrawn[account];

    if (rewards > withdrawn) {
      return rewards - withdrawn;
    }
    return 0;
  }

  function earned(address account)
    public
    view
    virtual
    returns (uint256 earnedReward)
  {
    (
      uint256 rewardNumerator,
      uint256 rewardDenominator
    ) = getRewardOwnershipFraction(account);

    if (rewardDenominator > 0) {
      earnedReward =
        (totalReleasedReward() * rewardNumerator) /
        rewardDenominator;

      if (earnedReward > _userWithdrawn[account]) {
        earnedReward -= _userWithdrawn[account];
      } else {
        earnedReward = 0;
      }
    }

    uint256 balance = collateralToken.balanceOf(address(this));

    if (earnedReward > balance) {
      earnedReward = balance;
    }
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _getFullyPaddedReward(address account)
    internal
    view
    returns (uint256)
  {
    uint256 globalBondedTotal = totalBonded();
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = totalDeclaredReward() +
      totalStakePadding();

    return
      (totalRewardedWithStakePadding * balanceOfBonded(account)) /
      globalBondedTotal;
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _withdraw(
    address account,
    uint256 amountReward,
    address to
  ) internal {
    uint256 balance = collateralToken.balanceOf(address(this));

    if (amountReward > balance) {
      amountReward = balance;
    }

    _userWithdrawn[account] += amountReward;
    _globalWithdrawn += amountReward;
    collateralToken.safeTransfer(to, amountReward);

    emit Withdraw(account, amountReward, to);
  }

  function _handleStakePadding(address account, uint256 amount) internal {
    uint256 totalBonded = totalBonded();

    uint256 newStakePadding = totalBonded == 0
      ? totalDeclaredReward() == 0 ? amount * 1e6 : 0
      : ((totalDeclaredReward() + totalStakePadding()) * amount) / totalBonded;

    _addToStakePadding(account, newStakePadding);
  }

  function _addToStakePadding(address account, uint256 amount) internal {
    _userStakePadding[account] = _userStakePadding[account] + amount;

    _globalStakePadding = _globalStakePadding + amount;
  }

  function _removeFromStakePadding(address account, uint256 amount) internal {
    _userStakePadding[account] = _userStakePadding[account] - amount;

    _globalStakePadding = _globalStakePadding - amount;
  }

  function _reconcileWithdrawn(
    address account,
    uint256 amount,
    uint256 bondedBalance
  ) internal {
    uint256 withdrawDiff = (_userWithdrawn[account] * amount) / bondedBalance;
    _userWithdrawn[account] -= withdrawDiff;
    _globalWithdrawn -= withdrawDiff;
    _globalReleased -= withdrawDiff;
  }

  function _handleWithdrawForAccount(
    address account,
    uint256 rewardAmount,
    address to
  ) internal {
    _beforeWithdraw(account, rewardAmount);

    _withdraw(account, rewardAmount, to);

    _afterWithdraw(account, rewardAmount);
  }

  /*
   * HOOKS
   */
  function _beforeWithdraw(address account, uint256 amount) internal virtual {
    // hook
  }

  function _afterWithdraw(address account, uint256 amount) internal virtual {
    // hook
  }

  function _beforeBond(address account, uint256 amount) internal virtual {
    // hook
  }

  function _afterBond(address account, uint256 amount) internal virtual {
    // hook
  }

  function _beforeUnbond(address account, uint256 amount) internal virtual {
    // hook
  }

  function _afterUnbond(address account, uint256 amount) internal virtual {
    // hook
  }

  /*
   * PRIVILEDGED METHODS
   */
  function withdrawForAccount(
    address account,
    uint256 amount,
    address to
  )
    external
    onlyRoleMalt(REWARD_MANAGER_ROLE, "Must have reward manager privs")
    returns (uint256)
  {
    uint256 rewardEarned = earned(account);

    if (rewardEarned < amount) {
      amount = rewardEarned;
    }

    _handleWithdrawForAccount(account, amount, to);

    return amount;
  }

  function _beforeSetMiningService(address _miningService) internal override {
    _transferRole(_miningService, address(miningService), MINING_SERVICE_ROLE);
    _transferRole(_miningService, address(miningService), REWARD_MANAGER_ROLE);
  }

  function setPoolId(uint256 _poolId)
    external
    onlyRoleMalt(ADMIN_ROLE, "Must have admin privs")
  {
    poolId = _poolId;

    emit SetPoolId(_poolId);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StabilizedPoolExtensions/StabilizedPoolUnit.sol";

/// @title AbstractTransferVerification
/// @author 0xScotch <[email protected]>
/// @notice Implements a single method that can block a particular transfer
abstract contract AbstractTransferVerification is StabilizedPoolUnit {
  constructor(
    address timelock,
    address initialAdmin,
    address poolFactory
  ) StabilizedPoolUnit(timelock, initialAdmin, poolFactory) {}

  function verifyTransfer(
    address from,
    address to,
    uint256 amount
  )
    external
    virtual
    returns (
      bool,
      string memory,
      address,
      bytes memory
    )
  {
    return (true, "", address(0), "");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/cryptography/draft-EIP712.sol";

interface ITransferReceiver {
  function onTokenTransfer(
    address,
    uint256,
    bytes calldata
  ) external returns (bool);
}

interface IApprovalReceiver {
  function onTokenApproval(
    address,
    uint256,
    bytes calldata
  ) external returns (bool);
}

contract ERC20Permit is ERC20, EIP712, IERC20Permit {
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
  bytes32 public constant TRANSFER_TYPEHASH =
    keccak256(
      "Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)"
    );

  /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
  mapping(address => uint256) public override nonces;

  constructor(string memory name, string memory ticker)
    ERC20(name, ticker)
    EIP712(name, "1")
  {}

  function DOMAIN_SEPARATOR() public view override returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// Requirements:
  ///   - `deadline` must be timestamp in future.
  ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
  ///   - the signature must use `owner` account's current nonce (see {nonces}).
  ///   - the signer cannot be zero address and must be `owner` account.
  function permit(
    address target,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(block.timestamp <= deadline, "ERC20Permit: Expired permit");

    bytes32 hashStruct = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        target,
        spender,
        value,
        nonces[target]++,
        deadline
      )
    );

    require(
      verifyEIP712(target, hashStruct, v, r, s) ||
        verifyPersonalSign(target, hashStruct, v, r, s),
      "invalide EIP712 #1"
    );

    _approve(target, spender, value);
  }

  function transferWithPermit(
    address target,
    address to,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (bool) {
    require(block.timestamp <= deadline, "ERC20Permit: Expired permit");

    bytes32 hashStruct = keccak256(
      abi.encode(
        TRANSFER_TYPEHASH,
        target,
        to,
        value,
        nonces[target]++,
        deadline
      )
    );

    require(
      verifyEIP712(target, hashStruct, v, r, s) ||
        verifyPersonalSign(target, hashStruct, v, r, s),
      "invalid EIP712 #2"
    );

    require(to != address(0) && to != address(this), "invalide to address #1");

    uint256 balance = balanceOf(target);
    require(balance >= value, "ERC20Permit: transfer amount exceeds balance");

    _transfer(target, to, value);

    return true;
  }

  function verifyEIP712(
    address target,
    bytes32 hashStruct,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    bytes32 hash = keccak256(
      abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct)
    );

    address signer = ecrecover(hash, v, r, s);
    return (signer != address(0) && signer == target);
  }

  function verifyPersonalSign(
    address target,
    bytes32 hashStruct,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (bool) {
    bytes32 hash = prefixed(hashStruct);
    address signer = ecrecover(hash, v, r, s);
    return (signer != address(0) && signer == target);
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function approveAndCall(
    address spender,
    uint256 value,
    bytes calldata data
  ) external returns (bool) {
    _approve(msg.sender, spender, value);

    return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool) {
    require(to != address(0) && to != address(this), "invalid to address #2");

    uint256 balance = balanceOf(msg.sender);
    require(balance >= value, "ERC20Permit: transfer amount exceeds balance");

    _transfer(msg.sender, to, value);

    return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
  }
}

pragma solidity 0.8.11;

interface IKeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData)
    external
    returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;

  function setupContracts(
    address,
    address,
    address,
    address,
    address,
    address,
    address,
    address
  ) external;

  function setTreasury(address payable) external;

  function togglePaused() external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

library BitMath {
  // returns the 0 indexed position of the most significant bit of the input x
  // s.t. x >= 2**msb and x < 2**(msb+1)
  function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
    require(x > 0, "BitMath::mostSignificantBit: zero");

    if (x >= 0x100000000000000000000000000000000) {
      x >>= 128;
      r += 128;
    }
    if (x >= 0x10000000000000000) {
      x >>= 64;
      r += 64;
    }
    if (x >= 0x100000000) {
      x >>= 32;
      r += 32;
    }
    if (x >= 0x10000) {
      x >>= 16;
      r += 16;
    }
    if (x >= 0x100) {
      x >>= 8;
      r += 8;
    }
    if (x >= 0x10) {
      x >>= 4;
      r += 4;
    }
    if (x >= 0x4) {
      x >>= 2;
      r += 2;
    }
    if (x >= 0x2) r += 1;
  }

  // returns the 0 indexed position of the least significant bit of the input x
  // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
  // i.e. the bit at the index is set and the mask of all lower bits is 0
  function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
    require(x > 0, "BitMath::leastSignificantBit: zero");

    r = 255;
    if (x & type(uint128).max > 0) {
      r -= 128;
    } else {
      x >>= 128;
    }
    if (x & type(uint64).max > 0) {
      r -= 64;
    } else {
      x >>= 64;
    }
    if (x & type(uint32).max > 0) {
      r -= 32;
    } else {
      x >>= 32;
    }
    if (x & type(uint16).max > 0) {
      r -= 16;
    } else {
      x >>= 16;
    }
    if (x & type(uint8).max > 0) {
      r -= 8;
    } else {
      x >>= 8;
    }
    if (x & 0xf > 0) {
      r -= 4;
    } else {
      x >>= 4;
    }
    if (x & 0x3 > 0) {
      r -= 2;
    } else {
      x >>= 2;
    }
    if (x & 0x1 > 0) r -= 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StabilizedPool/StabilizedPool.sol";

interface IStabilizedPoolFactory {
  function getPool(address pool)
    external
    view
    returns (
      address collateralToken,
      address updater,
      string memory name
    );

  function getPeripheryContracts(address pool)
    external
    view
    returns (
      address dataLab,
      address dexHandler,
      address transferVerifier,
      address keeper,
      address dualMA
    );

  function getRewardSystemContracts(address pool)
    external
    view
    returns (
      address vestingDistributor,
      address linearDistributor,
      address rewardOverflow,
      address rewardThrottle
    );

  function getStakingContracts(address pool)
    external
    view
    returns (
      address bonding,
      address miningService,
      address vestedMine,
      address forfeitHandler,
      address linearMine,
      address reinvestor
    );

  function getCoreContracts(address pool)
    external
    view
    returns (
      address auction,
      address auctionEscapeHatch,
      address impliedCollateralService,
      address liquidityExtension,
      address profitDistributor,
      address stabilizerNode,
      address swingTrader,
      address swingTraderManager
    );

  function getStabilizedPool(address)
    external
    view
    returns (StabilizedPool memory);

  function setCurrentPool(address, StabilizedPool memory) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

interface IUniswapV2Router01 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 * Strings of arbitrary length can be optimized if they are short enough by
 * the addition of a storage variable used as fallback.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}