/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  .
    .               .            .               .      🛰️     .           .                 *              .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                       . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                                             .                 .           
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                          .             .⠀
    
        CYGNUS FACTORY V1 - `Hangar18`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Dependencies
import {IHangar18} from "./interfaces/IHangar18.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {CygnusPoolAddress} from "./libraries/CygnusPoolAddress.sol";

// Interfaces
import {ICygnusNebulaOracle} from "./interfaces/ICygnusNebulaOracle.sol";
import {IAggregationRouterV5, IAggregationExecutor} from "./interfaces/IAggregationRouterV5.sol";

// Orbiters
import {IDenebOrbiter} from "./interfaces/IDenebOrbiter.sol";
import {IAlbireoOrbiter} from "./interfaces/IAlbireoOrbiter.sol";

/**
 *  @title  Hangar18
 *  @author CygnusDAO
 *  @notice Factory-like contract for CygnusDAO which deploys all borrow/collateral contracts in this chain. There
 *          is only 1 factory contract per chain along with multiple pairs of `orbiters`.
 *
 *          Orbiters are the collateral and borrow deployers contracts which are not not part of the
 *          core contracts, but instead are in charge of deploying the arms of core contracts with each other's
 *          addresses (borrow orbiter deploys the borrow arm with the collateral address, and vice versa).
 *
 *          Orbiters = Strategies for the underlying assets
 *
 *          Each orbiter has the bytecode of the collateral/borrow contracts being deployed, and they may differ
 *          slighlty due to the strategy deployed (for example each masterchef is different, requiring different
 *          harvest strategy, staking mechanism, etc.). The only contract that may differ between core contracts
 *          is the `CygnusCollateralVoid`, where all functions are private or external, meaning no other contract
 *          relies on it and can be left blank.
 *
 *          Ideally there should only be 1 orbiter per DEX (1 borrow && 1 collateral orbiter) or 1 per strategy.
 *
 *          This factory contract contains the records of all shuttles deployed by Cygnus. Every collateral/borrow
 *          contract reports back here to:
 *              - Check admin address (to increase debt ratios, update interest rate model, set void, etc.)
 *              - Check reserves manager address when minting new DAO reserves (in CygnusBorrow.sol) or to add
 *                DAO liquidation fees if any (in CygnusCollateral.sol)
 */
contract Hangar18 is IHangar18, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc IHangar18
     */
    Orbiter[] public override allOrbiters;

    /**
     *  @inheritdoc IHangar18
     */
    Shuttle[] public override allShuttles;

    /**
     *  @inheritdoc IHangar18
     */
    mapping(uint256 => Orbiter) public override getOrbiters;

    /**
     *  @inheritdoc IHangar18
     */
    mapping(address => mapping(uint256 => Shuttle)) public override getShuttles;

    /**
     *  @inheritdoc IHangar18
     */
    ICygnusNebulaOracle[] public override allNebulas;

    /**
     *  @inheritdoc IHangar18
     */
    address public override admin;

    /**
     *  @inheritdoc IHangar18
     */
    address public override pendingAdmin;

    /**
     *  @inheritdoc IHangar18
     */
    address public override daoReserves;

    /**
     *  @inheritdoc IHangar18
     */
    address public override pendingDaoReserves;

    /**
     *  @inheritdoc IHangar18
     */
    address public immutable override usd;

    /**
     *  @inheritdoc IHangar18
     */
    address public immutable override nativeToken;

    /**
     *  @inheritdoc IHangar18
     */
    IAggregationRouterV5 public constant override AGGREGATION_ROUTER_V5 =
        IAggregationRouterV5(0x1111111254EEB25477B68fb85Ed929f73A960582);

    /**
     *  @inheritdoc IHangar18
     */
    address public override cygnusX1Vault;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Sets the important addresses which pools report back here to check for
     *  @param _admin Address of the Cygnus Admin to update important protocol parameters
     *  @param _daoReserves Address of the contract that handles weighted forwarding of Erc20 tokens
     *  @param _usd Address of the borrowable`s underlying (stablecoins USDC, DAI, BUSD, etc.).
     *  @param _nativeToken The address of this chain's native token
     */
    constructor(address _admin, address _daoReserves, address _usd, address _nativeToken) {
        // Assign cygnus admin, has access to special functions
        admin = _admin;

        // Assign reserves manager
        daoReserves = _daoReserves;

        // Address of the native token for this chain (ie WETH)
        nativeToken = _nativeToken;

        // Address of DAI on this factory's chain
        usd = _usd;

        /// @custom:event NewCygnusAdmin
        emit NewCygnusAdmin(address(0), _admin);

        /// @custom:event DaoReserves
        emit NewDaoReserves(address(0), _daoReserves);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier cygnusAdmin Modifier for Cygnus Admin only
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Only Cygnus admins can deploy pools in Cygnus V1
     */
    function isCygnusAdmin() private view {
        /// @custom:error CygnusAdminOnly
        if (msg.sender != admin) {
            revert Hangar18__CygnusAdminOnly({sender: msg.sender, admin: admin});
        }
    }

    /**
     *  @notice Checks if the same pair of collateral & borrowable deployers and oracle we are setting already exist
     *  @param uniqueHash The keccak256 hash of the borrowableInitCodeHash, collateralInitCodeHash and oracle address
     *  @param orbitersLength How many orbiter pairs we have deployed
     */
    function checkOrbitersInternal(bytes32 uniqueHash, uint256 orbitersLength) private view {
        // Load orbiter to memory
        Orbiter[] memory orbiter = allOrbiters;

        // Loop through all orbiters
        for (uint256 i = 0; i < orbitersLength; i++) {
            // Check unique hash
            if (uniqueHash == orbiter[i].uniqueHash) {
                /// @custom:error OrbiterAlreadySet
                revert Hangar18__OrbiterAlreadySet({orbiter: orbiter[i]});
            }
        }
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc IHangar18
     */
    function orbitersDeployed() external view override returns (uint256) {
        // Return how many borrow/collateral orbiters this contract has
        return allOrbiters.length;
    }

    /**
     *  @inheritdoc IHangar18
     */
    function shuttlesDeployed() external view override returns (uint256) {
        // Return how many shuttles this contract has launched
        return allShuttles.length;
    }

    /**
     *  @inheritdoc IHangar18
     */
    function nebulasDeployed() external view override returns (uint256) {
        // Return how many oracles we deployed
        return allNebulas.length;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Creates a record of each shuttle deployed by this contract
     *  @dev Prepares shuttle for deployment and stores the orbiter used for this Shuttle
     *  @param lpTokenPair Address of the LP Token for this shuttle
     *  @param orbiterId The orbiter ID used to deploy this shuttle
     *  @return shuttle Struct of the lending pool being deployed
     */
    function boardShuttle(address lpTokenPair, uint256 orbiterId) private returns (Shuttle storage) {
        // Get the ID for this LP token's shuttle
        bool deployed = getShuttles[lpTokenPair][orbiterId].launched;

        /// @custom:error ShuttleAlreadyDeployed
        if (deployed == true) {
            revert Hangar18__ShuttleAlreadyDeployed({lpTokenPair: lpTokenPair, orbiterId: orbiterId});
        }

        // Create shuttle
        return
            getShuttles[lpTokenPair][orbiterId] = Shuttle(
                false, // False until `deployShuttle` call succeeds
                uint88(allShuttles.length), // Lending pool ID
                address(0), // Borrowable address
                address(0), // Collateral address
                uint96(orbiterId) // The orbiter ID used to launch this shuttle
            );
    }

    /**
     *  @notice Checks if the oracle has been added to our list
     *  @param nebulaOracle The address of the oracle
     */
    function checkOracleInternal(ICygnusNebulaOracle nebulaOracle) internal {
        // All oracles we have
        ICygnusNebulaOracle[] memory oracles = allNebulas;

        // Loop through the array to see if we have added the oracle
        for (uint256 i = 0; i < oracles.length; i++) {
            // Escape
            if (oracles[i] == nebulaOracle) return;
        }

        // If not added add to array of oracles
        allNebulas.push(nebulaOracle);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  Phase1: Orbiter check
     *            - Orbiters (deployers) are active and usable
     *  Phase2: Board shuttle check
     *            - No shuttle with the same LP Token AND Orbiter has been deployed before
     *  Phase3: Deploy Collateral and Borrow contracts
     *            - Calculate address of the collateral and deploy borrow contract with calculated collateral address
     *            - Deploy the collateral contract with the deployed borrow address
     *            - Check that collateral contract address is equal to the calculated collateral address, else revert
     *  Phase4: Price Oracle check:
     *            - Assert price oracle exists for this LP Token pair
     *  Phase5: Initialize shuttle
     *              - Initialize and store record of this shuttle in this contract
     *
     *  @inheritdoc IHangar18
     *  @custom:security non-reentrant only-admin 👽
     */
    function deployShuttle(
        address lpTokenPair,
        uint256 orbiterId
    ) external override nonReentrant cygnusAdmin returns (address borrowable, address collateral) {
        //  ─────────────────────────────── Phase 1 ───────────────────────────────
        // Load orbiter to memory
        Orbiter memory orbiter = getOrbiters[orbiterId];

        /// @custom:error OrbitersAreInactive
        if (!orbiter.status) {
            revert Hangar18__OrbitersAreInactive({orbiter: orbiter});
        }

        //  ─────────────────────────────── Phase 2 ───────────────────────────────
        // Prepare shuttle for deployment, reverts if lpTokenPair already exists
        // Load shuttle to storage
        Shuttle storage shuttle = boardShuttle(lpTokenPair, orbiter.orbiterId);

        //  ─────────────────────────────── Phase 3 ───────────────────────────────
        // Get the pre-determined collateral address for this LP Token (check CygnusPoolAddres library)
        address create2Collateral = CygnusPoolAddress.getCollateralContract(
            lpTokenPair,
            address(this),
            address(orbiter.denebOrbiter),
            orbiter.collateralInitCodeHash
        );

        // Deploy borrow contract
        borrowable = orbiter.albireoOrbiter.deployAlbireo(
            usd,
            create2Collateral,
            address(orbiter.nebulaOracle),
            shuttle.shuttleId
        );

        // Deploy collateral contract
        collateral = orbiter.denebOrbiter.deployDeneb(
            lpTokenPair,
            borrowable,
            address(orbiter.nebulaOracle),
            shuttle.shuttleId
        );

        /// @custom:error CollateralAddressMismatch
        if (collateral != create2Collateral) {
            revert Hangar18__CollateralAddressMismatch({create2Collateral: create2Collateral, collateral: collateral});
        }

        //  ─────────────────────────────── Phase 4 ───────────────────────────────
        // Oracle should never NOT be initialized for this pair. If not initialized, deployment of collateral auto fails
        bool oracleInitialized = orbiter.nebulaOracle.getNebula(lpTokenPair).initialized;

        /// @custom:error LPTokenPairNotSupported
        if (!oracleInitialized) {
            revert Hangar18__LPTokenPairNotSupported({lpTokenPair: lpTokenPair});
        }

        //  ─────────────────────────────── Phase 5 ───────────────────────────────
        // Save addresses to storage and mark as launched. This LP Token with orbiter ID cannot be redeployed
        shuttle.launched = true;

        // Add cygnus borrow contract to record
        shuttle.borrowable = borrowable;

        // Add collateral contract to record
        shuttle.collateral = collateral;

        // Push the lending pool struct to the object array
        allShuttles.push(shuttle);

        /// @custom:event NewShuttleLaunched
        emit NewShuttle(lpTokenPair, orbiterId, shuttle.shuttleId, shuttle.borrowable, shuttle.collateral);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function initializeOrbiter(
        string memory orbiterName,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter,
        ICygnusNebulaOracle nebulaOracle
    ) external override nonReentrant cygnusAdmin {
        // Total orbiters
        uint256 totalOrbiters = allOrbiters.length;

        // Collateral init code hash
        bytes32 collateralInitCodeHash = denebOrbiter.COLLATERAL_INIT_CODE_HASH();

        // Borrowable init code hash
        bytes32 borrowableInitCodeHash = albireoOrbiter.BORROWABLE_INIT_CODE_HASH();

        // Unique hash of both orbiters and oracle
        bytes32 uniqueHash = keccak256(abi.encode(collateralInitCodeHash, borrowableInitCodeHash, nebulaOracle));

        // Check if we already initialized these orbiter pair, reverts if we have
        checkOrbitersInternal(uniqueHash, totalOrbiters);

        // Create storage for orbiters with this ID
        Orbiter storage orbiter = getOrbiters[totalOrbiters];

        // ID for this group of collateral and borrow orbiters
        orbiter.orbiterId = uint88(totalOrbiters);

        // Name of the dex/strategy these orbiters are for or human readable identifier
        orbiter.orbiterName = orbiterName;

        // Collateral orbiter address
        orbiter.denebOrbiter = denebOrbiter;

        // Borrow orbiter address
        orbiter.albireoOrbiter = albireoOrbiter;

        // Assign oracle
        orbiter.nebulaOracle = nebulaOracle;

        // Collateral init code hash
        orbiter.collateralInitCodeHash = collateralInitCodeHash;

        // Borrowable init code hash
        orbiter.borrowableInitCodeHash = borrowableInitCodeHash;

        // Unique hash
        orbiter.uniqueHash = uniqueHash;

        // ID for this group of collateral/borrow orbiters
        orbiter.status = true;

        // Push struct to array
        allOrbiters.push(orbiter);

        // Add oracle to array
        checkOracleInternal(nebulaOracle);

        /// @custom:event InitializeOrbiters
        emit InitializeOrbiters(
            true,
            totalOrbiters,
            albireoOrbiter,
            denebOrbiter,
            nebulaOracle,
            uniqueHash,
            orbiterName
        );
    }

    /**
     *  @notice Reverts future deployments with disabled orbiter
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function switchOrbiterStatus(uint256 orbiterId) external override cygnusAdmin {
        // Get the orbiter by the ID
        IHangar18.Orbiter storage orbiter = allOrbiters[orbiterId];

        /// @custom:error OrbiterNotSet
        if (orbiter.uniqueHash == bytes32(0)) {
            revert Hangar18__OrbitersNotSet({orbiterId: orbiterId});
        }

        // Switch orbiter status. If currently active then future deployments with this orbiter will revert
        orbiter.status = !orbiter.status;

        /// @custom:event SwitchOrbiterStatus
        emit SwitchOrbiterStatus(
            orbiter.status,
            orbiter.orbiterId,
            orbiter.albireoOrbiter,
            orbiter.denebOrbiter,
            orbiter.orbiterName
        );
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setPendingAdmin(address newPendingAdmin) external override cygnusAdmin {
        /// @custom:error AdminAlreadySet
        if (newPendingAdmin == admin) {
            revert Hangar18__AdminAlreadySet({newPendingAdmin: newPendingAdmin, admin: admin});
        }

        // Address of the pending admin until this point
        address oldPendingAdmin = pendingAdmin;

        // Assign the new pending admin as the pending admin
        pendingAdmin = newPendingAdmin;

        /// @custom:event NewPendingCygnusAdmin
        emit NewPendingCygnusAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setNewCygnusAdmin() external override cygnusAdmin {
        /// @custom:error PendingAdminCantBeZero
        if (pendingAdmin == address(0)) {
            revert Hangar18__PendingAdminCantBeZero();
        }

        // Address of the Admin until this point
        address oldAdmin = admin;

        // Assign the pending admin as the new cygnus admin
        admin = pendingAdmin;

        // Gas refund
        delete pendingAdmin;

        // @custom:event NewCygnusAdming
        emit NewCygnusAdmin(oldAdmin, admin);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setPendingDaoReserves(address newPendingDaoReserves) external override cygnusAdmin {
        /// @custom:error DaoReservesAlreadySet
        if (newPendingDaoReserves == daoReserves) {
            revert Hangar18__DaoReservesAlreadySet({
                newPendingDaoReserves: newPendingDaoReserves,
                daoReserves: daoReserves
            });
        }

        // Pending dao reserves until this point
        address oldPendingDaoReserves = pendingDaoReserves;

        // Assign the new pending dao reserves
        pendingDaoReserves = newPendingDaoReserves;

        /// @custom:event NewPendingDaoReserves
        emit NewPendingDaoReserves(oldPendingDaoReserves, pendingDaoReserves);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setNewDaoReserves() external override cygnusAdmin {
        /// @custom:error DaoReservesCantBeZero
        if (pendingDaoReserves == address(0)) {
            revert Hangar18__DaoReservesCantBeZero();
        }

        // Address of the reserves admin up until now
        address oldDaoReserves = daoReserves;

        // Assign the pending admin as admin
        daoReserves = pendingDaoReserves;

        // Gas refund
        delete pendingDaoReserves;

        /// @custom:event DaoReserves
        emit NewDaoReserves(oldDaoReserves, daoReserves);
    }

    /**
     *  @inheritdoc IHangar18
     *  @custom:security only-admin 👽
     */
    function setCygnusX1Vault(address newX1Vault) external override cygnusAdmin {
        /// @custom:error X1VaultCantBeZero
        if (newX1Vault == address(0)) {
            revert Hangar18__X1VaultCantBeZero();
        }

        // Old vault
        address oldVault = cygnusX1Vault;

        // Assign new vault
        cygnusX1Vault = newX1Vault;

        /// @custom:event NewX1Vault
        emit NewX1Vault(oldVault, newX1Vault);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 *  @title Interface for making arbitrary calls during swap
 */
interface IAggregationExecutor {
    /**
     *  @notice Executes calls for `msgSender`
     */
    function execute(address msgSender) external payable; // 0x4b64e492
}

/**
 * @title IAggregationRouterV4 OneInch's Aggregation Router
 */
interface IAggregationRouterV5 {
    /**
     *  @custom:member srcToken The address of the token we are swapping
     *  @custom:member dstToken The address of the token we are receiving
     *  @custom:member srcReceiver The address that is swapping the tokens
     *  @custom:member dstReceiver The address that is receiving the tokens
     *  @custom:member amount Amount of `srcToken` we are swapping
     *  @custom:member minReturnAmount The min return amount of `srcToken`
     *  @custom:member flags Flags for the swap
     */
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /**
     * @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
     * @param caller Aggregation executor that executes calls described in `data`
     * @param desc Swap description
     * @param data Encoded calls that `caller` should execute in between of swaps
     * @param permit Permit data for the swap, we pass LOCAL_BYTES
     * @return returnAmount Resulting token amount
     * @return spentAmount Spent amount from the swap
     */
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/**
 *  @title ICygnusAlbireo The interface the Cygnus borrow deployer
 *  @notice A contract that constructs a Cygnus borrow pool must implement this to pass arguments to the pool
 */
interface IAlbireoOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the borrow contracts avoids setting constructor parameters
     *
     *  @return factory The address of the Cygnus factory assigned to `Hangar18`
     *  @return underlying The address of the underlying borrow token (address of USDC)
     *  @return collateral The address of the Cygnus collateral contract for this borrow contract
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The lending pool ID
     */
    function shuttleParameters()
        external
        returns (address factory, address underlying, address collateral, address oracle, uint256 shuttleId);

    /**
     *  @return BORROW_INIT_CODE_HASH The init code hash of the borrow contract for this deployer
     */
    function BORROWABLE_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
     *
     *  @param underlying The address of the underlying borrow token (address of USDc)
     *  @param collateral The address of the Cygnus collateral contract for this borrow contract
     *  @param shuttleId The ID of the shuttle we are deploying (shared by borrow and collateral)
     *  @return borrowable The address of the new borrow contract
     */
    function deployAlbireo(
        address underlying,
        address collateral,
        address oracle,
        uint256 shuttleId
    ) external returns (address borrowable);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {IERC20} from "./IERC20.sol";

/**
 *  @title ICygnusNebulaOracle Interface to interact with Cygnus' Chainlink oracle
 */
interface ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error PairIsInitialized Reverts when attempting to initialize an already initialized LP Token
     */
    error CygnusNebulaOracle__PairAlreadyInitialized(address lpTokenPair);

    /**
     *  @custom:error PairNotInitialized Reverts when attempting to get the price of an LP Token that is not initialized
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @custom:error MsgSenderNotAdmin Reverts when attempting to access admin only methods
     */
    error CygnusNebulaOracle__MsgSenderNotAdmin(address msgSender);

    /**
     *  @custom:error AdminCantBeZero Reverts when attempting to set the admin if the pending admin is the zero address
     */
    error CygnusNebulaOracle__AdminCantBeZero(address pendingAdmin);

    /**
     *  @custom:error PendingAdminAlreadySet Reverts when attempting to set the same pending admin twice
     */
    error CygnusNebulaOracle__PendingAdminAlreadySet(address pendingAdmin);

    /**
     *  @custom:error NebulaRecordNotInitialized Reverts when getting a record if not initialized
     */
    error CygnusNebulaOracle__NebulaRecordNotInitialized(address lpTokenPair);

    /**
     *  @custom:error NebulaRecordAlreadyInitialized Reverts when re-initializing a record
     */
    error CygnusNebulaOracle__NebulaRecordAlreadyInitialized(address lpTokenPair);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param initialized Whether or not the LP Token is initialized
     *  @param oracleId The ID for this oracle
     *  @param lpTokenPair The address of the LP Token
     *  @custom:event InitializeCygnusNebula Logs when an LP Token pair's price starts being tracked
     */
    event InitializeCygnusNebula(
        bool initialized,
        uint88 oracleId,
        address lpTokenPair,
        IERC20[] poolTokens,
        uint256[] tokenDecimals,
        AggregatorV3Interface[] priceFeeds
    );

    /**
     *  @param oracleCurrentAdmin The address of the current oracle admin
     *  @param oraclePendingAdmin The address of the pending oracle admin
     *  @custom:event NewNebulaPendingAdmin Logs when a new pending admin is set, to be accepted by admin
     */
    event NewOraclePendingAdmin(address oracleCurrentAdmin, address oraclePendingAdmin);

    /**
     *  @param oracleOldAdmin The address of the old oracle admin
     *  @param oracleNewAdmin The address of the new oracle admin
     *  @custom:event NewNebulaAdmin Logs when the pending admin is confirmed as the new oracle admin
     */
    event NewOracleAdmin(address oracleOldAdmin, address oracleNewAdmin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The struct record of each oracle used by Cygnus
     *  @custom:member initialized Whether an LP Token is being tracked or not
     *  @custom:member oracleId The ID of the LP Token tracked by the oracle
     *  @custom:member name User friendly name of the underlying
     *  @custom:member underlying The address of the LP Token
     *  @custom:member poolId The bytes32 of the poolId from the balancer vault
     *  @custom:member poolTokens Array of all the pool tokens
     *  @custom:member tokenDecimals Array of all the pool token decimals
     *  @custom:member priceFeeds Array of all the Chainlink price feeds for the pool tokens
     */
    struct CygnusNebula {
        bool initialized;
        uint88 oracleId;
        string name;
        address underlying;
        IERC20[] poolTokens;
        uint256[] tokenDecimals;
        AggregatorV3Interface[] priceFeeds;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Returns the struct record of each oracle used by Cygnus
     *  @param lpTokenPair The address of the LP Token
     *  @return cygnusNebula Struct of the oracle for the LP Token
     */
    function getNebula(address lpTokenPair) external view returns (CygnusNebula memory cygnusNebula);

    /**
     *  @notice Gets the address of the LP Token that (if) is being tracked by this oracle
     *  @param id The ID of each LP Token that is being tracked by this oracle
     *  @return The address of the LP Token if it is being tracked by this oracle, else returns address zero
     */
    function allNebulas(uint256 id) external view returns (address);

    /**
     *  @return The name for this Cygnus-Chainlink Nebula oracle
     */
    function name() external view returns (string memory);

    /**
     *  @return The symbol for this Cygnus-Chainlink Nebula oracle
     */
    function symbol() external view returns (string memory);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return The version of this oracle
     */
    function version() external view returns (string memory);

    /**
     *  @return SECONDS_PER_YEAR The number of seconds in year assumed by the oracle
     */
    function SECONDS_PER_YEAR() external view returns (uint256);

    /**
     *  @return How many LP Token pairs' prices are being tracked by this oracle
     */
    function nebulaSize() external view returns (uint24);

    /**
     *  @return The denomination token this oracle returns the price in
     */
    function denominationToken() external view returns (IERC20);

    /**
     *  @return The decimals for this Cygnus-Chainlink Nebula oracle
     */
    function decimals() external view returns (uint8);

    /**
     *  @return The address of Chainlink's denomination oracle
     */
    function denominationAggregator() external view returns (AggregatorV3Interface);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The price of the denomination token
     */
    function denominationTokenPrice() external view returns (uint256);

    /**
     *  @notice Gets the latest price of the LP Token denominated in denomination token
     *  @notice LP Token pair must be initialized, else reverts with custom error
     *  @param lpTokenPair The address of the LP Token
     *  @return lpTokenPrice The price of the LP Token denominated in denomination token
     */
    function lpTokenPriceUsd(address lpTokenPair) external view returns (uint256 lpTokenPrice);

    /**
     *  @notice Gets the latest price of the LP Token's token0 and token1 denominated in denomination token
     *  @notice Used by Cygnus Altair contract to calculate optimal amount of leverage
     *  @param lpTokenPair The address of the LP Token
     *  @return tokenPriceA The price of the LP Token's token0 denominated in denomination token
     *  @return tokenPriceB The price of the LP Token's token1 denominated in denomination token
     */
    function assetPricesUsd(address lpTokenPair) external view returns (uint256 tokenPriceA, uint256 tokenPriceB);

    /**
     *  @notice Get the APR given 2 exchange rates and the time elapsed between them. This is helpful for tokens
     *          that meet x*y=k such as UniswapV2 since exchange rates should never decrease (else LPs lose cash).
     *          Uses the natural log to avoid overflowing when we annualize the log difference.
     *  @param exchangeRateLast The previous exchange rate
     *  @param exchangeRateNow The current exchange rate
     *  @param timeElapsed Time elapsed between the exchange rates
     *  @return apr The estimated base rate (APR excluding any token rewards)
     */
    function getAnnualizedBaseRate(
        uint256 exchangeRateLast,
        uint256 exchangeRateNow,
        uint256 timeElapsed
    ) external pure returns (uint256 apr);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Initialize an LP Token pair, only admin
     *  @param lpTokenPair The contract address of the LP Token
     *  @param aggregators Array of Chainlink aggregators for this LP token's tokens
     *  @custom:security non-reentrant
     */
    function initializeNebula(address lpTokenPair, AggregatorV3Interface[] calldata aggregators) external;

    /**
     *  @notice Sets a new pending admin for the Oracle
     *  @param newOraclePendingAdmin Address of the requested Oracle Admin
     */
    function setOraclePendingAdmin(address newOraclePendingAdmin) external;

    /**
     *  @notice Sets a new admin for the Oracle
     */
    function setOracleAdmin() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/**
 *  @title ICygnusDeneb The interface for a contract that is capable of deploying Cygnus collateral pools
 *  @notice A contract that constructs a Cygnus collateral pool must implement this to pass arguments to the pool
 */
interface IDenebOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the collateral contract avoids setting constructor
     *
     *  @return factory The address of the Cygnus factory
     *  @return underlying The address of the underlying LP Token
     *  @return borrowable The address of the Cygnus borrow contract for this collateral
     *  @return oracle The address of the oracle for this lending pool
     *  @return shuttleId The ID of the lending pool
     */
    function shuttleParameters()
        external
        returns (
            address factory,
            address underlying,
            address borrowable,
            address oracle,
            uint256 shuttleId
        );

    /**
     *  @return COLLATERAL_INIT_CODE_HASH The init code hash of the collateral contract for this deployer
     */
    function COLLATERAL_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *
     *  @param underlying The address of the underlying LP Token
     *  @param borrowable The address of the Cygnus borrow contract for this collateral
     *  @param oracle The address of the oracle for this lending pool
     *  @param shuttleId The ID of the lending pool
     *
     *  @return collateral The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(
        address underlying,
        address borrowable,
        address oracle,
        uint256 shuttleId
    ) external returns (address collateral);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title IERC20
/// @author Paul Razvan Berg
/// @notice Implementation for the ERC-20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of ERC-20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the ERC may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IERC20 {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to approve with the zero address as the owner.
    error ERC20_ApproveOwnerZeroAddress();

    /// @notice Thrown when attempting to approve the zero address as the spender.
    error ERC20_ApproveSpenderZeroAddress();

    /// @notice Thrown when attempting to burn tokens from the zero address.
    error ERC20_BurnHolderZeroAddress();

    /// @notice Thrown when attempting to transfer more tokens than there are in the from account.
    error ERC20_FromInsufficientBalance(uint256 senderBalance, uint256 transferAmount);

    /// @notice Thrown when spender attempts to transfer more tokens than the owner had given them allowance for.
    error ERC20_InsufficientAllowance(address owner, address spender, uint256 allowance, uint256 transferAmount);

    /// @notice Thrown when attempting to mint tokens to the zero address.
    error ERC20_MintBeneficiaryZeroAddress();

    /// @notice Thrown when attempting to transfer tokens from the zero address.
    error ERC20_TransferFromZeroAddress();

    /// @notice Thrown when the attempting to transfer tokens to the zero address.
    error ERC20_TransferToZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an approval occurs.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param value The maximum value that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Emitted when a transfer occurs.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets `value` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {IERC20-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `value`.
    function decreaseAllowance(address spender, uint256 value) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` must not be the zero address.
    function increaseAllowance(address spender, uint256 value) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `to` must not be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the ERC. See the note at the beginning of {ERC-20}.
    ///
    /// Requirements:
    ///
    /// - `from` and `to` must not be the zero address.
    /// - `from` must have a balance of at least `amount`.
    /// - The caller must have approved `from` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Orbiters
import {IDenebOrbiter} from "./IDenebOrbiter.sol";
import {IAlbireoOrbiter} from "./IAlbireoOrbiter.sol";

// Oracles
import {ICygnusNebulaOracle} from "./ICygnusNebulaOracle.sol";

// One inch
import {IAggregationRouterV5} from "./IAggregationRouterV5.sol";

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when caller is not Admin
     *
     *  @param sender The address of the account that invoked the function and caused the error
     *  @param admin The address of the Admin that is allowed to perform the function
     *
     *  @custom:error CygnusAdminOnly
     */
    error Hangar18__CygnusAdminOnly(address sender, address admin);

    /**
     *  @dev Reverts when the borrow orbiter already exists
     *
     *  @param orbiter The address of the Orbiter that already exists
     *
     *  @custom:error OrbiterAlreadySet
     */
    error Hangar18__OrbiterAlreadySet(Orbiter orbiter);

    /**
     *  @dev Reverts when trying to deploy a shuttle that already exists
     *
     *  @param lpTokenPair The address of the LP token pair associated with the Shuttle
     *  @param orbiterId The ID of the Orbiter associated with the Shuttle
     *
     *  @custom:error ShuttleAlreadyDeployed
     */
    error Hangar18__ShuttleAlreadyDeployed(address lpTokenPair, uint256 orbiterId);

    /**
     *  @dev Reverts when deploying a shuttle with orbiters that are inactive or dont exist
     *
     *  @param orbiter The address of the inactive or non-existent Orbiter
     *
     *  @custom:error OrbitersAreInactive
     */
    error Hangar18__OrbitersAreInactive(Orbiter orbiter);

    /**
     *  @dev Reverts when predicted collateral address doesn't match with deployed
     *
     *  @param create2Collateral The predicted address of the collateral token
     *  @param collateral The address of the actual deployed collateral token
     *
     *  @custom:error CollateralAddressMismatch
     */
    error Hangar18__CollateralAddressMismatch(address create2Collateral, address collateral);

    /**
     *  @dev Reverts when trying to deploy a shuttle with an unsupported LP Pair
     *
     *  @param lpTokenPair The address of the unsupported LP token pair
     *
     *  @custom:error LPTokenPairNotSupported
     */
    error Hangar18__LPTokenPairNotSupported(address lpTokenPair);

    /**
     *  @dev Reverts when attempting to switch off orbiters that don't exist
     *
     *  @param orbiterId The ID of the non-existent Orbiter
     *
     *  @custom:error OrbitersNotSet
     */
    error Hangar18__OrbitersNotSet(uint256 orbiterId);

    /**
     *  @dev Reverts when the new oracle is the zero address
     *
     *  @custom:error CygnusNebulaCantBeZero
     */
    error Hangar18__CygnusNebulaCantBeZero();

    /**
     *  @dev Reverts when the oracle set is the same as the new one we are assigning
     *
     *  @param priceOracle The address of the existing price oracle
     *  @param newPriceOracle The address of the new price oracle that was attempted to be set
     *
     *  @custom:error CygnusNebulaAlreadySet
     */
    error Hangar18__CygnusNebulaAlreadySet(address priceOracle, address newPriceOracle);

    /**
     *  @dev Reverts when the admin is the same as the new one we are assigning
     *
     *  @param newPendingAdmin The address of the new pending admin
     *  @param admin The address of the existing admin
     *
     *  @custom:error AdminAlreadySet
     */
    error Hangar18__AdminAlreadySet(address newPendingAdmin, address admin);

    /**
     *  @dev Reverts when the pending admin is the same as the new one we are assigning
     *
     *  @param newPendingAdmin The address of the new pending admin
     *  @param pendingAdmin The address of the existing pending admin
     *
     *  @custom:error PendingAdminAlreadySet
     */
    error Hangar18__PendingAdminAlreadySet(address newPendingAdmin, address pendingAdmin);

    /**
     *  @dev Reverts when the pending dao reserves is already the dao reserves
     *
     *  @param newPendingDaoReserves The address of the new pending dao reserves
     *  @param daoReserves The address the current dao reserves
     *
     *  @custom:error DaoReservesAlreadySet
     */
    error Hangar18__DaoReservesAlreadySet(address newPendingDaoReserves, address daoReserves);

    /**
     *  @dev Reverts when the pending address is the same as the new pending
     *
     *  @param newPendingDaoReserves The address of the new pending dao reserves
     *  @param pendingDaoReserves The address of current pending dao reserves
     *
     *  @custom:error PendingDaoReservesAlreadySet
     */
    error Hangar18__PendingDaoReservesAlreadySet(address newPendingDaoReserves, address pendingDaoReserves);

    /**
     *  @dev Reverts when pending Cygnus admin is the zero address
     *
     *  @custom:error PendingCygnusAdmin
     */
    error Hangar18__PendingAdminCantBeZero();

    /**
     *  @dev Reverts when pending reserves contract address is the zero address
     *
     *  @custom:error DaoReservesCantBeZero
     */
    error Hangar18__DaoReservesCantBeZero();

    /**
     *  @dev Reverts when setting a new vault as the 0 address
     *
     *  @custom:error X1VaultCantBeZero
     */
    error Hangar18__X1VaultCantBeZero();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new price oracle is set
     *
     *  @param oldCygnusNebula Address of the old price oracle
     *  @param newCygnusNebula Address of the new confirmed price oracle
     *
     *  @custom:event NewCygnusNebulaOracle
     */
    event NewCygnusNebulaOracle(ICygnusNebulaOracle oldCygnusNebula, ICygnusNebulaOracle newCygnusNebula);

    /**
     *  @dev Logs when a new lending pool is launched
     *
     *  @param lpTokenPair The address of the LP Token pair
     *  @param orbiterId The ID of the orbiter used to deploy this lending pool
     *  @param borrowable The address of the Cygnus borrow contract
     *  @param collateral The address of the Cygnus collateral contract
     *  @param shuttleId The ID of the lending pool
     *
     *  @custom:event NewShuttle
     */
    event NewShuttle(
        address indexed lpTokenPair,
        uint256 indexed shuttleId,
        uint256 orbiterId,
        address borrowable,
        address collateral
    );

    /**
     *  @dev Logs when a new Cygnus admin is requested
     *
     *  @param pendingAdmin Address of the requested admin
     *  @param _admin Address of the present admin
     *
     *  @custom:event NewPendingCygnusAdmin
     */
    event NewPendingCygnusAdmin(address pendingAdmin, address _admin);

    /**
     *  @dev Logs when a new Cygnus admin is confirmed
     *
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     *
     *  @custom:event NewCygnusAdmin
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @dev Logs when a new implementation contract is requested
     *
     *  @param oldPendingdaoReservesContract Address of the current `daoReserves` contract
     *  @param newPendingdaoReservesContract Address of the requested new `daoReserves` contract
     *
     *  @custom:event NewPendingDaoReserves
     */
    event NewPendingDaoReserves(address oldPendingdaoReservesContract, address newPendingdaoReservesContract);

    /**
     *  @dev Logs when a new implementation contract is confirmed
     *
     *  @param oldDaoReserves Address of old `daoReserves` contract
     *  @param daoReserves Address of the new confirmed `daoReserves` contract
     *
     *  @custom:event NewDaoReserves
     */
    event NewDaoReserves(address oldDaoReserves, address daoReserves);

    /**
     *  @dev Logs when orbiters are initialized in the factory
     *
     *  @param status Whether or not these orbiters are active and usable
     *  @param orbitersLength How many orbiter pairs we have (equals the amount of Dexes cygnus is using)
     *  @param borrowOrbiter The address of the borrow orbiter for this dex
     *  @param denebOrbiter The address of the collateral orbiter for this dex
     *  @param nebulaOracle The address of the oracle for this orbiter
     *  @param orbitersName The name of the dex for these orbiters
     *  @param uniqueHash The keccack256 hash of the collateral init code hash and borrowable init code hash
     *
     *  @custom:event InitializeOrbiters
     */
    event InitializeOrbiters(
        bool status,
        uint256 orbitersLength,
        IAlbireoOrbiter borrowOrbiter,
        IDenebOrbiter denebOrbiter,
        ICygnusNebulaOracle nebulaOracle,
        bytes32 uniqueHash,
        string orbitersName
    );

    /**
     *  @dev Logs when admins switch orbiters off for future deployments
     *
     *  @param status Bool representing whether or not these orbiters are usable
     *  @param orbiterId The ID of the collateral & borrow orbiters
     *  @param albireoOrbiter The address of the deleted borrow orbiter
     *  @param denebOrbiter The address of the deleted collateral orbiter
     *  @param orbiterName The name of the dex these orbiters were for
     *
     *  @custom:event SwitchOrbiterStatus
     */
    event SwitchOrbiterStatus(
        bool status,
        uint256 orbiterId,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter,
        string orbiterName
    );

    /**
     *  @dev Logs when a new vault is set which accumulates rewards from lending pools
     *
     *  @param oldVault The address of the old vault
     *  @param newVault The address of the new vault
     *
     *  @custom:event NewX1Vault
     */
    event NewX1Vault(address oldVault, address newVault);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice We write it to interface due to getShuttles return value
     *  @custom:struct Official record of all collateral and borrow deployer contracts, unique per dex
     *  @custom:member status Whether or not these orbiters are active and usable
     *  @custom:member orbiterId The ID for this pair of orbiters
     *  @custom:member albireoOrbiter The address of the borrow deployer contract
     *  @custom:member denebOrbiter The address of the collateral deployer contract
     *  @custom:member orbiterName The name of the dex
     */
    struct Orbiter {
        bool status;
        uint88 orbiterId;
        IAlbireoOrbiter albireoOrbiter;
        IDenebOrbiter denebOrbiter;
        bytes32 borrowableInitCodeHash;
        bytes32 collateralInitCodeHash;
        ICygnusNebulaOracle nebulaOracle;
        bytes32 uniqueHash;
        string orbiterName;
    }

    /**
     *  @custom:struct Shuttle Official record of pools deployed by this factory
     *  @custom:member launched Whether or not the lending pool is initialized
     *  @custom:member shuttleId The ID of the lending pool
     *  @custom:member borrowable The address of the borrowing contract
     *  @custom:member collateral The address of the Cygnus collateral
     *  @custom:member orbiterId The ID of the orbiters used to deploy lending pool
     */
    struct Shuttle {
        bool launched;
        uint88 shuttleId;
        address borrowable;
        address collateral;
        uint96 orbiterId;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Array of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return albireoOrbiter The address of the borrow deployer contract
     *  @return denebOrbiter The address of the collateral deployer contract
     *  @return borrowableInitCodeHash The init code hash of the borrowable
     *  @return collateralInitCodeHash The init code hash of the collateral
     *  @return nebulaOracle The oracle for this orbiter
     *  @return uniqueHash The keccak256 hash of collateralInitCodeHash and borrowableInitCodeHash
     *  @return orbiterName The name of the dex
     */
    function allOrbiters(
        uint256 _orbiterId
    )
        external
        view
        returns (
            bool status,
            uint88 orbiterId,
            IAlbireoOrbiter albireoOrbiter,
            IDenebOrbiter denebOrbiter,
            bytes32 borrowableInitCodeHash,
            bytes32 collateralInitCodeHash,
            ICygnusNebulaOracle nebulaOracle,
            bytes32 uniqueHash,
            string memory orbiterName
        );

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @notice Mapping of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return albireoOrbiter The address of the borrow deployer contract
     *  @return denebOrbiter The address of the collateral deployer contract
     *  @return borrowableInitCodeHash The init code hash of the borrowable
     *  @return collateralInitCodeHash The init code hash of the collateral
     *  @return nebulaOracle The oracle for this orbiter
     *  @return uniqueHash The keccak256 hash of collateralInitCodeHash and borrowableInitCodeHash and oracle address
     *  @return orbiterName The name of the dex
     */
    function getOrbiters(
        uint256 _orbiterId
    )
        external
        view
        returns (
            bool status,
            uint88 orbiterId,
            IAlbireoOrbiter albireoOrbiter,
            IDenebOrbiter denebOrbiter,
            bytes32 borrowableInitCodeHash,
            bytes32 collateralInitCodeHash,
            ICygnusNebulaOracle nebulaOracle,
            bytes32 uniqueHash,
            string memory orbiterName
        );

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function getShuttles(
        address _lpTokenPair,
        uint256 _orbiterId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return pendingAdmin The address of the requested account to be the new Cygnus Admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);

    /**
     *  @return pendingDaoReserves The address of the requested contract to be the new dao reserves
     */
    function pendingDaoReserves() external view returns (address);

    /**
     *  @return cygnusX1Vault The address of the CygnusDAO revenue vault
     */
    function cygnusX1Vault() external view returns (address);

    /**
     * @return cygnusNebulaOracle The address of the Cygnus price oracle
     */
    function allNebulas(uint256 oracleId) external view returns (ICygnusNebulaOracle);

    /**
     *  @return orbitersDeployed The total number of orbiter pairs deployed (1 collateral + 1 borrow = 1 orbiter)
     */
    function orbitersDeployed() external view returns (uint256);

    /**
     *  @return shuttlesDeployed The total number of shuttles deployed
     */
    function shuttlesDeployed() external view returns (uint256);

    /**
     *  @return nebulasDeployed The total number of oracles deployed
     */
    function nebulasDeployed() external view returns (uint256);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /**
     *  @return AGGREGATION_ROUTER_V5 The address of the 1inch router used for the swaps
     */
    function AGGREGATION_ROUTER_V5() external pure returns (IAggregationRouterV5);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Turns off orbiters making them not able for deployment of pools
     *
     *  @param orbiterId The ID of the orbiter pairs we want to switch the status of
     *
     *  @custom:security only-admin
     */
    function switchOrbiterStatus(uint256 orbiterId) external;

    /**
     *  @notice Admin 👽
     *  @notice Initializes both Borrow arms and the collateral arm
     *
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @param orbiterId The ID of the orbiters we want to deploy to (= dex Id)
     *  @return borrowable The address of the Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *
     *  @custom:security non-reentrant only-admin 👽
     */
    function deployShuttle(
        address lpTokenPair,
        uint256 orbiterId
    ) external returns (address borrowable, address collateral);

    /**
     *  @notice Admin 👽
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param albireoOrbiter the address of this orbiter's borrow deployer
     *  @param denebOrbiter The address of this orbiter's collateral deployer
     *  @param nebulaOracle The oracle for this orbiter
     *
     *  @custom:security non-reentrant only-admin
     */
    function initializeOrbiter(
        string memory name,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter,
        ICygnusNebulaOracle nebulaOracle
    ) external;

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for Cygnus
     *
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice Admin 👽
     *  @notice Approves the pending admin and is the new Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setNewCygnusAdmin() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address for the future reserves manger if accepted
     *  @param newDaoReserves The address of the requested contract to be the new daoReserves
     *  @custom:security only-admin
     */
    function setPendingDaoReserves(address newDaoReserves) external;

    /**
     *  @notice Admin 👽
     *  @notice Accepts the new implementation contract
     *
     *  @custom:security only-admin
     */
    function setNewDaoReserves() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new x1 vault which accumulates rewards over time
     *
     *  @custom:security only-admin
     */
    function setCygnusX1Vault(address newX1Vault) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.17;

/**
 *  @title CygnusPoolAddress
 *  @dev Provides functions for deriving Cygnus collateral and borrow addresses deployed by Factory
 */
library CygnusPoolAddress {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Used by CygnusAltair.sol and Cygnus Factory
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))
     *  @param lpTokenPair The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @param denebOrbiter The address of the collateral deployer
     *  @param initCodeHash The keccak256 hash of the initcode of the Cygnus Collateral contracts
     *  @return collateral The calculated address of the Cygnus collateral contract given the salt (`lpTokenPair` and
     *                     `factory` addresses), the msg.sender (Deneb Orbiter) and the init code hash of the
     *                     CygnusCollateral.
     */
    function getCollateralContract(
        address lpTokenPair,
        address factory,
        address denebOrbiter,
        bytes32 initCodeHash
    ) internal pure returns (address collateral) {
        collateral = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            denebOrbiter,
                            keccak256(abi.encode(lpTokenPair, factory)),
                            initCodeHash
                        )
                    )
                )
            )
        );
    }

    /**
     *  @dev Used by CygnusAltair.sol
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))[12:]
     *  @param collateral The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @param borrowDeployer The address of the CygnusAlbireo contract
     *  @return borrow The calculated address of the Cygnus Borrow contract deployed by factory given
     *          `lpTokenPair` and `factory` addresses along with borrowDeployer contract address
     */
    function getBorrowContract(
        address collateral,
        address factory,
        address borrowDeployer,
        bytes32 initCodeHash
    ) internal pure returns (address borrow) {
        borrow = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            borrowDeployer,
                            keccak256(abi.encode(collateral, factory)),
                            initCodeHash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}