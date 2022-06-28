// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Oracle.sol";

contract TestOracle is Oracle {

    constructor(
        bytes32 oracleName,
        address registry
    )
        Oracle(oracleName, registry)
    { }

    function request(uint256 requestId, bytes calldata input) external override onlyQuery {
        // decode oracle input data
        (uint256 input_value) = abi.decode(input, (uint256));

        // obtain data from oracle given the request data (input_value)
        // for off chain oracles this happens outside the request
        // call in a separate asynchronous transaction
        bool isLossEvent = _oracleCalculation(input_value);
        respond(requestId, isLossEvent);
    }

    // usually called by off-chain oracle (and not internally) 
    // in which case the function modifier should be changed 
    // to external
    function respond(uint256 requestId, bool isLossEvent) 
        internal
    {
        // encode data obtained from oracle
        bytes memory output = abi.encode(bool(isLossEvent));

        // trigger inherited response handling
        _respond(requestId, output);
    }

    // dummy implementation
    // "real" oracles will get the output from some off-chain
    // component providing the outcome of the business logic
    function _oracleCalculation(uint256 value) internal returns (bool isLossEvent) {
        isLossEvent = (value % 2 == 1);
    }    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Component.sol";
import "IComponent.sol";
import "IOracle.sol";
import "IOracleService.sol";

abstract contract Oracle is
    IOracle, 
    Component 
{    
    event LogOracleCreated (address oracleAddress);
    event LogOracleProposed (uint256 id);
    event LogOracleApproved (uint256 id);
    event LogOracleDeclined (uint256 id);

    IOracleService private _oracleService;

    modifier onlyQuery {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:ORA-001:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address registry
    )
        Component(name, ComponentType.Oracle, registry)
    {
        _oracleService = IOracleService(_getContractAddress("OracleService"));
        emit LogOracleCreated(address(this));
    }

    // default callback function implementations
    function _afterApprove() internal override { 
        uint256 id = getId();
        // TODO figure out what the ... is wrong here
        // plugging id into the event let spin brownie console
        // with history[-1].info() ...
        // plugging in a fixed value eg 999 works fine????
        emit LogOracleApproved(999); 
    }

    function _afterPropose() internal override { emit LogOracleProposed(getId()); }
    function _afterDecline() internal override { emit LogOracleDeclined(getId()); }

    function _respond(uint256 requestId, bytes memory data) internal {
        _oracleService.respond(requestId, data);
    }    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IComponent.sol";
import "IAccess.sol";
import "IComponentEvents.sol";
import "IRegistry.sol";
import "IComponentOwnerService.sol";
import "Ownable.sol";


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/GUIDELINES.md#style-guidelines
abstract contract Component is 
    IComponent,
    IComponentEvents,
    Ownable 
{
    bytes32 private _componentName;
    uint256 private _componentId;
    ComponentType private _componentType;
    ComponentStatus private _componentStatus;

    bytes32 private _requiredRole;

    IRegistry private _registry;
    IAccess private _access;
    IComponentOwnerService private _componentOwnerService;

    event LogComponentCreated (
        bytes32 componentName,
        ComponentType componentType,
        address componentAddress,
        address registryAddress);

    modifier onlyInstanceOperatorService() {
        require(
             _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:CMP-001:NOT_INSTANCE_OPERATOR_SERVICE");
        _;
    }

    modifier onlyComponent() {
        require(
             _msgSender() == _getContractAddress("Component"),
            "ERROR:CMP-002:NOT_COMPONENT");
        _;
    }

    modifier onlyComponentOwnerService() {
        require(
             _msgSender() == address(_componentOwnerService),
            "ERROR:CMP-002:NOT_COMPONENT_OWNER_SERVICE");
        _;
    }

    constructor(
        bytes32 name,
        ComponentType componentType,
        address registry
    )
        Ownable()
    {
        require(registry != address(0), "ERROR:CMP-003:REGISTRY_ADDRESS_ZERO");

        _registry = IRegistry(registry);
        _access = _getAccess();
        _componentOwnerService = _getComponentOwnerService();

        _componentName = name;
        _componentType = componentType;
        _componentStatus = ComponentStatus.Created;
        _requiredRole = _getRequiredRole();

        emit LogComponentCreated(
            _componentName, 
            _componentType, 
            address(this), 
            address(_registry));
    }

    function setId(uint256 id) external onlyComponent { _componentId = id; }
    function setStatus(ComponentStatus status) external onlyComponent { _componentStatus = status; }

    function getName() public view returns(bytes32) { return _componentName; }
    function getId() public view returns(uint256) { return _componentId; }
    function getType() public view returns(ComponentType) { return _componentType; }
    function getStatus() public view returns(ComponentStatus) { return _componentStatus; }
    function getOwner() external view returns(address) { return owner(); }

    function isProduct() public view returns(bool) { return _componentType == ComponentType.Product; }
    function isOracle() public view returns(bool) { return _componentType == ComponentType.Oracle; }
    function isRiskpool() public view returns(bool) { return _componentType == ComponentType.Riskpool; }

    function getRequiredRole() public view override returns(bytes32) { return _requiredRole; }

    function proposalCallback() public override onlyComponent { _afterPropose(); }
    function approvalCallback() public override onlyComponent { _afterApprove(); }
    function declineCallback() public override onlyComponent { _afterDecline(); }
    function suspendCallback() public override onlyComponent { _afterSuspend(); }
    function resumeCallback() public override onlyComponent { _afterResume(); }
    function pauseCallback() public override onlyComponent { _afterPause(); }
    function unpauseCallback() public override onlyComponent { _afterUnpause(); }

    // these functions are intended to be overwritten to implement
    // component specific notification handling
    function _afterPropose() internal virtual {}
    function _afterApprove() internal virtual {}
    function _afterDecline() internal virtual {}
    function _afterSuspend() internal virtual {}
    function _afterResume() internal virtual {}
    function _afterPause() internal virtual {}
    function _afterUnpause() internal virtual {}

    function _getRequiredRole() private returns (bytes32) {
        if (isProduct()) { return _access.productOwnerRole(); }
        if (isOracle()) { return _access.oracleProviderRole(); }
        if (isRiskpool()) { return _access.riskpoolKeeperRole(); }
    }

    function _getAccess() internal returns (IAccess) {
        return IAccess(_getContractAddress("Access"));        
    }

    function _getComponentOwnerService() internal returns (IComponentOwnerService) {
        return IComponentOwnerService(_getContractAddress("ComponentOwnerService"));        
    }

    function _getContractAddress(bytes32 contractName) internal returns (address) { 
        return _registry.getContract(contractName);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

enum ComponentType {
    Oracle,
    Product,
    Riskpool
}

enum ComponentStatus {
    Created,
    Proposed,
    Declined,
    Active,
    Paused,
    Suspended
}

interface IComponent {

    function setId(uint256 id) external;
    function setStatus(ComponentStatus status) external;

    function getName() external view returns(bytes32);
    function getId() external view returns(uint256);
    function getType() external view returns(ComponentType);
    function getStatus() external view returns(ComponentStatus);
    function getOwner() external view returns(address);

    function getRequiredRole() external view returns(bytes32 role);

    function isProduct() external view returns(bool);
    function isOracle() external view returns(bool);
    function isRiskpool() external view returns(bool);

    function proposalCallback() external;
    function approvalCallback() external; 
    function declineCallback() external;
    function suspendCallback() external;
    function resumeCallback() external;
    function pauseCallback() external;
    function unpauseCallback() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IAccess {
    function productOwnerRole() external view returns(bytes32 role);
    function oracleProviderRole() external view returns(bytes32 role);
    function riskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns(bool);

    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;
    function renounceRole(bytes32 role, address principal) external;

    function enforceProductOwnerRole(address account) external view;
    function enforceOracleProviderRole(address account) external view;
    function enforceRiskpoolKeeperRole(address account) external view;
    function enforceRole(bytes32 role, address account) external view;
    
    function addRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IComponent.sol";

interface IComponentEvents {

    event LogComponentProposed (
        bytes32 componentName,
        ComponentType componentType,
        address componentAddress,
        uint256 id);
    
    event LogComponentApproved (uint256 id);
    event LogComponentDeclined (uint256 id);

    event LogComponentSuspended (uint256 id);
    event LogComponentResumed (uint256 id);

    event LogComponentPaused (uint256 id);
    event LogComponentUnpaused (uint256 id);

    event LogComponentStateChanged (uint256 id, ComponentStatus statusOld, ComponentStatus statusNew);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IComponent.sol";

interface IComponentOwnerService {

    function propose(IComponent component) external;

    function stake(uint256 id) external;
    function withdraw(uint256 id) external;

    function pause(uint256 id) external; 
    function unpause(uint256 id) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOracle {
    function request(uint256 requestId, bytes calldata input) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOracleService {

    function respond(uint256 requestId, bytes calldata data) external;
}