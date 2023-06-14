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
// Uniswap Multicall.sol: https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol

pragma solidity ^0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/ISystemPause.sol";

abstract contract AbstractSystemPause {
    /// bool to store system status
    bool public systemPaused;
    /// System pause interface
    ISystemPause system;

    /* ========== ERROR STATEMENTS ========== */

    error UnauthorisedAccess();
    error SystemPaused();

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */
    modifier onlySystemPauseContract() {
        if (address(system) != msg.sender) revert UnauthorisedAccess();
        _;
    }

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */

    modifier whenSystemNotPaused() {
        if (systemPaused) revert SystemPaused();
        _;
    }

    function pauseSystem() external virtual onlySystemPauseContract {
        systemPaused = true;
    }

    function unpauseSystem() external virtual onlySystemPauseContract {
        systemPaused = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/IAccess.sol";
import "../../interfaces/ISystemPause.sol";

import "./AbstractSystemPause.sol";
import "../Multicall.sol";

/**
@title  System Pause contract 
 */
contract SystemPause is ISystemPause, Multicall {
    /* ========== STATE DECLARATIONS ========== */

    /* ========== STATE VARIABLES ========== */

    /// Main access contract
    IAccess access;

    /// mapping of active smart contract modules
    struct moduleData {
        address add;
        string name;
    }
    uint public moduleId = 0;
    /// mapping module id => module implementation address
    mapping(uint => moduleData) moduleDataById;
    /// mapping module implementation address => module id
    mapping(address => uint) moduleIdByAddress;
    /// mapping module name => module id
    mapping(string => uint) moduleIdByName;

    /// StakingManager address
    address stakingManager;

    /* ========== MODIFIERS ========== */

    modifier onlyEmergencyRole() {
        access.onlyEmergencyRole(msg.sender);
        _;
    }

    modifier onlyDeployerOrStakingManager() {
        if (stakingManager == address(0)) revert UpdateStakingManagerAddress();
        require(
            access.userHasRole(access.deployer(), msg.sender) ||
                msg.sender == stakingManager,
            "Unauthorised Access"
        );
        _;
    }

    modifier onlyDeployer() {
        if (!access.userHasRole(access.deployer(), msg.sender))
            revert UnauthorisedAccess();
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _accessAddress) {
        access = IAccess(_accessAddress);
    }

    /* ========== EXTERNAL ========== */

    /**
     * @dev Sets the address of the staking manager smart contract
     * @param _stakingManagerAddress the contract address to set
     */
    function setStakingManager(
        address _stakingManagerAddress
    ) external virtual override onlyDeployer {
        if (_stakingManagerAddress == address(0)) revert InvalidAddress();
        stakingManager = _stakingManagerAddress;
    }

    // pauses active or expired pools
    // isActive = true will pause active pools
    // isActive = false, will pause expired pools
    function pausePools(bool isActive) external onlyEmergencyRole {
        if (isActive) {
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewActivePools();
            for (uint256 i; i < pools.length; i++) {
                (bool success, ) = pools[i].call(
                    abi.encodeWithSignature("systemPause()")
                );
                if (!success) revert CallUnsuccessful(pools[i]);
            }
        } else {
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewExpiredPoolsArray();
            for (uint256 i; i < pools.length; i++) {
                (bool success, ) = pools[i].call(
                    abi.encodeWithSignature("systemPause()")
                );
                if (!success) revert CallUnsuccessful(pools[i]);
            }
        }
    }

    // unpauses active or expired pools
    // isActive = true will unpause active pools
    // isActive = false, will unpause expired pools
    function unPausePools(bool isActive) external onlyEmergencyRole {
        if (isActive) {
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewActivePools();
            for (uint256 i; i < pools.length; i++) {
                (bool success, ) = pools[i].call(
                    abi.encodeWithSignature("systemUnpause()")
                );
                if (!success) revert CallUnsuccessful(pools[i]);
            }
        } else {
            address[] memory pools = StakingManagerPeriphery(stakingManager)
                .viewExpiredPoolsArray();
            for (uint256 i; i < pools.length; i++) {
                (bool success, ) = pools[i].call(
                    abi.encodeWithSignature("systemUnpause()")
                );
                if (!success) revert CallUnsuccessful(pools[i]);
            }
        }
    }

    // pauses an individual pool
    function pausePool(address _pool) external onlyEmergencyRole {
        require(
            StakingManagerPeriphery(stakingManager).poolChecker(_pool),
            "The address is not an intialised pool"
        );
        (bool success, ) = _pool.call(abi.encodeWithSignature("systemPause()"));
        if (!success) revert CallUnsuccessful(_pool);
    }

    // unpauses an individual pool
    function unPausePool(address _pool) external onlyEmergencyRole {
        require(
            StakingManagerPeriphery(stakingManager).poolChecker(_pool),
            "The address is not an intialised pool"
        );
        (bool success, ) = _pool.call(
            abi.encodeWithSignature("systemUnpause()")
        );
        if (!success) revert CallUnsuccessful(_pool);
    }

    /**
     * @dev Pauses modules, such as governance, staking manager/factory
     * and others.
     * Calls the pauseSystem function in the module smart contract
     * When Staking manager module is paused, it will do the cascading
     * for pause and unpause
     * i.e., pause active and expired staking pools
     * managed by staking manager itself
     * @param id the module id to pause
     */
    function pauseModule(uint id) external override onlyEmergencyRole {
        bool paused = true;

        (bool success, ) = moduleDataById[id].add.call(
            abi.encodeWithSignature("pauseSystem()")
        );
        if (!success) revert CallUnsuccessful(moduleDataById[id].add);

        emit PauseStatus(id, paused);
    }

    /**
     * @dev Reverts the action of the pause function.
     * Unpauses a module. Calls the unpauseSystem function in the module
     * smart contract
     * @param id the module id to unpause
     */
    function unPauseModule(uint id) external override onlyEmergencyRole {
        bool paused = false;

        (bool success, ) = moduleDataById[id].add.call(
            abi.encodeWithSignature("unpauseSystem()")
        );
        if (!success) revert CallUnsuccessful(moduleDataById[id].add);

        emit PauseStatus(id, paused);
    }

    /**
     * @dev Creates a new module and maps the contract address to the
     * assigned module name and id for uniqueness.
     * @param name the name of the module, e.g., MODULEID__STAKINGMANAGER
     * @param _contractAddress the address of the module's smart contract
     */
    function createModule(
        string memory name,
        address _contractAddress
    ) external override onlyDeployerOrStakingManager {
        moduleId++;
        if (_contractAddress == address(0)) revert InvalidAddress();
        if (bytes(name).length == 0) revert InvalidModuleName();
        require(
            bytes(moduleDataById[moduleId].name).length == 0,
            "Module already exists with id"
        );
        require(moduleIdByName[name] == 0, "Module already exists with name");

        moduleDataById[moduleId].add = _contractAddress;
        moduleDataById[moduleId].name = name;
        moduleIdByAddress[_contractAddress] = moduleId;
        moduleIdByName[name] = moduleId;

        emit NewModule(moduleId, _contractAddress, name);
    }

    /**
     * @dev Updates the contract address mapped to an already created module id.
     * This will revert if the module has not been created.
     * Or if the existing module is not paused
     * @param id the module id
     * @param _contractAddress the new smart contract address for the module
     */
    function updateModule(
        uint id,
        address _contractAddress
    ) external override onlyDeployerOrStakingManager {
        if (_contractAddress == address(0)) revert InvalidAddress();
        // revert if current implementation is not zero address
        // and is not paused
        require(!getModuleStatusWithId(id), "Existing module not paused");

        moduleDataById[id].add = _contractAddress;
        moduleIdByAddress[_contractAddress] = id;

        emit UpdatedModule(id, _contractAddress, moduleDataById[id].name);
    }

    /**
     * @dev Returns the status of a module, i.e., whether it is active or not active.
     * If the module has been paused, this will return false (inactive) else
     * it will return true.
     * @param id the module id
     * @return isActive
     */
    function getModuleStatusWithId(
        uint id
    ) public view override returns (bool isActive) {
        isActive = !AbstractSystemPause(moduleDataById[id].add).systemPaused();
    }

    /**
     * @dev Returns the status of a module, i.e., whether it is active or not active.
     * If the module has been paused, this will return false (inactive) else
     * it will return true.
     * @param _contractAddress the module smart contract address
     * @return isActive
     */
    function getModuleStatusWithAddress(
        address _contractAddress
    ) public view override returns (bool isActive) {
        isActive = !AbstractSystemPause(_contractAddress).systemPaused();
    }

    /**
     * @dev Returns the smart contract address of a module
     * given the module id.
     * @param id the module id
     * @return module the smart contract address of the module
     */
    function getModuleAddressWithId(
        uint id
    ) external view override returns (address module) {
        module = moduleDataById[id].add;
    }

    /**
     * @dev Returns the module name assigned to a given module id.
     * @param id the module id
     * @return name the name assigned to the module
     */
    function getModuleNameWithId(
        uint id
    ) external view override returns (string memory name) {
        name = moduleDataById[id].name;
    }

    /**
     * @dev Returns the module id assigned to a given module address.
     * @param _contractAddress the module address
     * @return id the module id assigned to the given address
     */
    function getModuleIdWithAddress(
        address _contractAddress
    ) external view override returns (uint id) {
        id = moduleIdByAddress[_contractAddress];
    }

    /**
     * @dev Returns the module id assigned to a given module name.
     * @param name the module name
     * @return id the module id assigned to the name
     */
    function getModuleIdWithName(
        string memory name
    ) external view override returns (uint id) {
        id = moduleIdByName[name];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

interface StakingManagerPeriphery {
    function poolChecker(address _pool) external view returns (bool);

    function viewActivePools() external view returns (address[] memory pools);

    function viewExpiredPoolsArray()
        external
        view
        returns (address[] memory pools);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Access interface
/// @notice Access is the main contract which stores the roles
abstract contract IAccess is ERC165 {
    /* ========== FUNCTIONS ========== */

    function userHasRole(bytes32 _role, address _address)
        external
        view
        virtual
        returns (bool);

    function onlyGovernanceRole(address _caller) external view virtual;

    function onlyEmergencyRole(address _caller) external view virtual;

    function onlyTokenRole(address _caller) external view virtual;

    function onlyBoostRole(address _caller) external view virtual;

    function onlyRewardDropRole(address _caller) external view virtual;

    function onlyStakingRole(address _caller) external view virtual;

    function onlyStakingPauserRole(address _caller) external view virtual;

    function onlyStakingFactoryRole(address _caller) external view virtual;

    function onlyStakingManagerRole(address _caller) external view virtual;

    function executive() public pure virtual returns (bytes32);

    function admin() public pure virtual returns (bytes32);

    function deployer() public pure virtual returns (bytes32);

    function emergencyRole() public pure virtual returns (bytes32);

    function tokenRole() public pure virtual returns (bytes32);

    function pauseRole() public pure virtual returns (bytes32);

    function governanceRole() public pure virtual returns (bytes32);

    function boostRole() public pure virtual returns (bytes32);

    function stakingRole() public pure virtual returns (bytes32);

    function rewardDropRole() public pure virtual returns (bytes32);

    function stakingFactoryRole() public pure virtual returns (bytes32);

    function stakingManagerRole() public pure virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Pause interface
abstract contract ISystemPause is ERC165 {
    /* ========== REVERT STATEMENTS ========== */

    error SystemPaused();
    error UnauthorisedAccess();
    error InvalidAddress();
    error InvalidModuleName();
    error UpdateStakingManagerAddress();
    error CallUnsuccessful(address contractAddress);

    /* ========== EVENTS ========== */

    event PauseStatus(uint indexed moduleId, bool isPaused);
    event NewModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );
    event UpdatedModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );

    /* ========== FUNCTIONS ========== */

    function setStakingManager(address _stakingManagerAddress) external virtual;

    function pauseModule(uint id) external virtual;

    function unPauseModule(uint id) external virtual;

    function createModule(
        string memory name,
        address _contractAddress
    ) external virtual;

    function updateModule(uint id, address _contractAddress) external virtual;

    function getModuleStatusWithId(
        uint id
    ) external view virtual returns (bool isActive);

    function getModuleStatusWithAddress(
        address _contractAddress
    ) external view virtual returns (bool isActive);

    function getModuleAddressWithId(
        uint id
    ) external view virtual returns (address module);

    function getModuleIdWithAddress(
        address _contractAddress
    ) external view virtual returns (uint id);

    function getModuleIdWithName(
        string memory name
    ) external view virtual returns (uint id);

    function getModuleNameWithId(
        uint id
    ) external view virtual returns (string memory name);
}