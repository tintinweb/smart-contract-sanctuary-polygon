// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "QueryStorageModel.sol";
import "IQueryController.sol";
import "ModuleController.sol";
import "IOracle.sol";

contract QueryController is IQueryController, QueryStorageModel, ModuleController {
    bytes32 public constant NAME = "QueryController";

    modifier isResponsibleOracle(uint256 _requestId, address _responder) {
        require(
            oracles[oracleRequests[_requestId].responsibleOracleId]
                .oracleContract == _responder,
            "ERROR:QUC-001:NOT_RESPONSIBLE_ORACLE"
        );
        _;
    }

    constructor(address _registry) WithRegistry(_registry) {}

    function proposeOracleType(
        bytes32 _oracleTypeName,
        string calldata _inputFormat,
        string calldata _callbackFormat
    ) external override onlyOracleOwner {
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Uninitialized,
            "ERROR:QUC-002:ORACLE_TYPE_ALREADY_EXISTS"
        );

        oracleTypes[_oracleTypeName] = OracleType(
            _inputFormat,
            _callbackFormat,
            OracleTypeState.Proposed,
            0
        );

        oracleTypeNamesCount += 1;
        oracleTypeNames[oracleTypeNamesCount] = _oracleTypeName;

        emit LogOracleTypeProposed(
            _oracleTypeName,
            _inputFormat,
            _callbackFormat
        );
    }

    function approveOracleType(bytes32 _oracleTypeName)
        external
        override
        onlyInstanceOperator
    {
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Proposed,
            "ERROR:QUC-003:ORACLE_TYPE_NOT_PROPOSED"
        );
        require(
            oracleTypes[_oracleTypeName].state != OracleTypeState.Approved,
            "ERROR:QUC-004:ORACLE_TYPE_ALREADY_APPROVED"
        );

        oracleTypes[_oracleTypeName].state = OracleTypeState.Approved;

        emit LogOracleTypeApproved(_oracleTypeName);
    }

    function disapproveOracleType(bytes32 _oracleTypeName)
        external
        override
        onlyInstanceOperator
    {
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Approved,
            "ERROR:QUC-006:ORACLE_TYPE_NOT_ACTIVE"
        );
        require(
            oracleTypes[_oracleTypeName].activeOracles == 0,
            "ERROR:QUC-007:ORACLE_TYPE_HAS_ACTIVE_ORACLES"
        );

        oracleTypes[_oracleTypeName].state = OracleTypeState.Proposed;

        emit LogOracleTypeDisapproved(_oracleTypeName);
    }

    function proposeOracle(bytes32 _name, address _oracleContract)
        external
        override
        onlyOracleOwner
        returns (uint256 _oracleId)
    {
        require(
            oracleIdByAddress[_oracleContract] == 0,
            "ERROR:QUC-008:ORACLE_ALREADY_EXISTS"
        );

        oracleCount += 1;
        _oracleId = oracleCount;

        oracles[_oracleId] = Oracle(
            _name,
            _oracleContract,
            OracleState.Proposed,
            0
        );
        oracleIdByAddress[_oracleContract] = _oracleId;

        emit LogOracleProposed(_oracleId, _name, _oracleContract);
    }

    function updateOracleContract(address _newOracleContract, uint256 _oracleId)
        external
        override
        onlyOracleOwner
    {
        require(
            oracleIdByAddress[_newOracleContract] == 0,
            "ERROR:QUC-009:ORACLE_ALREADY_EXISTS"
        );

        address prevContract = oracles[_oracleId].oracleContract;

        oracleIdByAddress[oracles[_oracleId].oracleContract] = 0;
        oracles[_oracleId].oracleContract = _newOracleContract;
        oracleIdByAddress[_newOracleContract] = _oracleId;

        emit LogOracleContractUpdated(
            _oracleId,
            prevContract,
            _newOracleContract
        );
    }

    function setOracleState(uint256 _oracleId, OracleState _state) internal {
        require(
            oracles[_oracleId].oracleContract != address(0),
            "ERROR:QUC-011:ORACLE_DOES_NOT_EXIST"
        );
        oracles[_oracleId].state = _state;
        emit LogOracleSetState(_oracleId, _state);
    }

    function approveOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Approved);
    }

    function pauseOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Paused);
    }

    function disapproveOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Proposed);
    }

    function proposeOracleToOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external override onlyOracleOwner {
        require(
            oracles[_oracleId].oracleContract != address(0),
            "ERROR:QUC-017:ORACLE_DOES_NOT_EXIST"
        );
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Approved,
            "ERROR:QUC-018:ORACLE_TYPE_NOT_APPROVED"
        );
        require(
            assignedOracles[_oracleTypeName][_oracleId] ==
                OracleAssignmentState.Unassigned,
            "ERROR:QUC-019:ORACLE_ALREADY_PROPOSED_OR_ASSIGNED"
        );

        assignedOracles[_oracleTypeName][_oracleId] = OracleAssignmentState
            .Proposed;

        emit LogOracleProposedToOracleType(_oracleTypeName, _oracleId);
    }

    function revokeOracleFromOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external override onlyOracleOwner {
        require(
            oracles[_oracleId].oracleContract != address(0),
            "ERROR:QUC-021:ORACLE_DOES_NOT_EXIST"
        );
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Approved,
            "ERROR:QUC-022:ORACLE_TYPE_NOT_APPROVED"
        );
        require(
            assignedOracles[_oracleTypeName][_oracleId] !=
                OracleAssignmentState.Unassigned,
            "ERROR:QUC-023:ORACLE_NOT_PROPOSED_OR_ASSIGNED"
        );

        assignedOracles[_oracleTypeName][_oracleId] = OracleAssignmentState
            .Unassigned;
        oracleTypes[_oracleTypeName].activeOracles -= 1;
        oracles[_oracleId].activeOracleTypes -= 1;

        emit LogOracleRevokedFromOracleType(_oracleTypeName, _oracleId);
    }

    function assignOracleToOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external override onlyInstanceOperator {
        require(
            oracleTypes[_oracleTypeName].state == OracleTypeState.Approved,
            "ERROR:QUC-024:ORACLE_TYPE_NOT_APPROVED"
        );

        require(
            oracles[_oracleId].oracleContract != address(0),
            "ERROR:QUC-025:ORACLE_DOES_NOT_EXIST"
        );
        require(
            assignedOracles[_oracleTypeName][_oracleId] ==
                OracleAssignmentState.Proposed,
            "ERROR:QUC-026:ORACLE_NOT_PROPOSED"
        );

        assignedOracles[_oracleTypeName][_oracleId] = OracleAssignmentState
            .Assigned;
        oracleTypes[_oracleTypeName].activeOracles += 1;
        oracles[_oracleId].activeOracleTypes += 1;

        emit LogOracleAssignedToOracleType(_oracleTypeName, _oracleId);
    }

    /* Oracle Request */
    // 1->1
    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        bytes32 _oracleTypeName,
        uint256 _responsibleOracleId
    ) 
        external 
        override 
        onlyPolicyFlow("Query") 
        returns (uint256 _requestId) 
    {
        // todo: validate

        _requestId = oracleRequests.length;
        oracleRequests.push();

        // todo: get token from product

        OracleRequest storage req = oracleRequests[_requestId];
        req.bpKey = _bpKey;
        req.data = _input;
        req.callbackMethodName = _callbackMethodName;
        req.callbackContractAddress = _callbackContractAddress;
        req.oracleTypeName = _oracleTypeName;
        req.responsibleOracleId = _responsibleOracleId;
        req.createdAt = block.timestamp;

        IOracle(oracles[_responsibleOracleId].oracleContract).request(
            _requestId,
            _input
        );

        emit LogOracleRequested(_bpKey, _requestId, _responsibleOracleId);
    }

    /* Oracle Response */
    function respond(
        uint256 _requestId,
        address _responder,
        bytes calldata _data
    ) external override onlyOracleService isResponsibleOracle(_requestId, _responder) {
        OracleRequest storage req = oracleRequests[_requestId];

        (bool status, ) =
            req.callbackContractAddress.call(
                abi.encodeWithSignature(
                    string(
                        abi.encodePacked(
                            req.callbackMethodName,
                            "(uint256,bytes32,bytes)"
                        )
                    ),
                    _requestId,
                    req.bpKey,
                    _data
                )
            );

        // todo: send reward

        emit LogOracleResponded(req.bpKey, _requestId, _responder, status);
    }

    function getOracleRequestCount() public view returns (uint256 _count) {
        return oracleRequests.length;
    }

    function getOracleTypeCount() external override view returns (uint256) {
        return oracleTypeNamesCount;
    }

    function getOracleCount() external override view returns (uint256) {
        return oracleCount;
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IQuery.sol";

contract QueryStorageModel is IQuery {
    // Oracle types
    // OracleTypeName => OracleType
    mapping(bytes32 => OracleType) public oracleTypes;
    // OracleTypeName => OracleId => OracleAssignmentState
    mapping(bytes32 => mapping(uint256 => OracleAssignmentState))
        public assignedOracles;
    // OracleTypeName Index => OracleTypeName
    mapping(uint256 => bytes32) public oracleTypeNames;
    uint256 public oracleTypeNamesCount;

    // Oracles
    mapping(uint256 => Oracle) public oracles;
    mapping(address => uint256) public oracleIdByAddress;
    uint256 public oracleCount;

    // Requests
    OracleRequest[] public oracleRequests;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IQuery {
    enum OracleTypeState {Uninitialized, Proposed, Approved}
    enum OracleState {Proposed, Approved, Paused}
    enum OracleAssignmentState {Unassigned, Proposed, Assigned}

    struct OracleType {
        string inputFormat; // e.g. '(uint256 longitude,uint256 latitude)'
        string callbackFormat; // e.g. '(uint256 longitude,uint256 latitude)'
        OracleTypeState state;
        uint256 activeOracles;
    }

    struct Oracle {
        bytes32 name;
        address oracleContract;
        OracleState state;
        uint256 activeOracleTypes;
    }

    struct OracleRequest {
        bytes data;
        bytes32 bpKey;
        string callbackMethodName;
        address callbackContractAddress;
        bytes32 oracleTypeName;
        uint256 responsibleOracleId;
        uint256 createdAt;
    }

    /* Logs */
    event LogOracleTypeProposed(
        bytes32 oracleTypeName,
        string inputFormat,
        string callbackFormat
    );
    event LogOracleTypeApproved(bytes32 oracleTypeName);
    event LogOracleTypeDisapproved(bytes32 oracleTypeName);
    event LogOracleProposed(
        uint256 oracleId,
        bytes32 name,
        address oracleContract
    );
    event LogOracleSetState(uint256 oracleId, OracleState state);
    event LogOracleContractUpdated(
        uint256 oracleId,
        address oldContract,
        address newContract
    );
    event LogOracleProposedToOracleType(
        bytes32 oracleTypeName,
        uint256 oracleId
    );
    event LogOracleRevokedFromOracleType(
        bytes32 oracleTypeName,
        uint256 oracleId
    );
    event LogOracleAssignedToOracleType(
        bytes32 oracleTypeName,
        uint256 oracleId
    );
    event LogOracleRequested(
        bytes32 bpKey,
        uint256 requestId,
        uint256 responsibleOracleId
    );
    event LogOracleResponded(
        bytes32 bpKey,
        uint256 requestId,
        address responder,
        bool status
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IQuery.sol";

interface IQueryController {
    function proposeOracleType(
        bytes32 _oracleTypeName,
        string calldata _inputFormat,
        string calldata _callbackFormat
    ) external;

    function approveOracleType(bytes32 _oracleTypeName) external;

    function disapproveOracleType(bytes32 _oracleTypeName) external;

    function proposeOracle(bytes32 _name, address _oracleContract)
        external
        returns (uint256 _oracleId);

    function updateOracleContract(address _newOracleContract, uint256 _oracleId)
        external;

    function approveOracle(uint256 _oracleId) external;
    function pauseOracle(uint256 _oracleId) external;

    function disapproveOracle(uint256 _oracleId) external;

    function proposeOracleToOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external;

    function revokeOracleFromOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external;

    function assignOracleToOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external;

    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        bytes32 _oracleTypeName,
        uint256 _responsibleOracleId
    ) external returns (uint256 _requestId);

    function respond(
        uint256 _requestId,
        address _responder,
        bytes calldata _data
    ) external;

    function getOracleTypeCount() 
        external 
        view 
        returns (uint256 _oracleTypes);

    function getOracleCount() 
        external 
        view 
        returns (uint256 _oracles);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "BaseModuleController.sol";
import "WithRegistry.sol";

abstract contract ModuleController is WithRegistry, BaseModuleController {
    /* solhint-disable payable-fallback */
    fallback() external {
        revert("ERROR:MOC-001:FALLBACK_FUNCTION_NOW_ALLOWED");
    }

    /* solhint-enable payable-fallback */

    function assignStorage(address _storage) external onlyInstanceOperator {
        _assignStorage(_storage);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract BaseModuleController {
    address public delegator;

    function _assignStorage(address _storage) internal {
        delegator = _storage;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IRegistryController.sol";
import "AccessModifiers.sol";

contract WithRegistry is AccessModifiers {
    IRegistryController public registry;

    constructor(address _registry) {
        registry = IRegistryController(_registry);
    }

    function assignRegistry(address _registry) external onlyInstanceOperator {
        registry = IRegistryController(_registry);
    }

    function getContractFromRegistry(bytes32 _contractName)
        public
        override
        view
        returns (address _addr)
    {
        _addr = registry.getContract(_contractName);
    }

    function getContractInReleaseFromRegistry(bytes32 _release, bytes32 _contractName)
        internal
        view
        returns (address _addr)
    {
        _addr = registry.getContractInRelease(_release, _contractName);
    }

    function getReleaseFromRegistry() internal view returns (bytes32 _release) {
        _release = registry.getRelease();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryController {
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IRegistryAccess.sol";


abstract contract AccessModifiers is IRegistryAccess {

    // change visibility to public to allow access from withhin this contract
    function getContractFromRegistry(bytes32 _contractName)
        public
        view
        virtual
        override
        returns (address _addr);

    modifier onlyInstanceOperator() {
        require(
            msg.sender == getContractFromRegistry("InstanceOperatorService"),
            "ERROR:ACM-001:NOT_INSTANCE_OPERATOR"
        );
        _;
    }

    modifier onlyPolicyFlow(bytes32 _module) {
        // Allow only from delegator
        require(
            address(this) == getContractFromRegistry(_module),
            "ERROR:ACM-002:NOT_ON_STORAGE"
        );

        // Allow only ProductService (it delegates to PolicyFlow)
        require(
            msg.sender == getContractFromRegistry("ProductService"),
            "ERROR:ACM-003:NOT_PRODUCT_SERVICE"
        );
        _;
    }

    modifier onlyOracleService() {
        require(
            msg.sender == getContractFromRegistry("OracleService"),
            "ERROR:ACM-004:NOT_ORACLE_SERVICE"
        );
        _;
    }

    modifier onlyOracleOwner() {
        require(
            msg.sender == getContractFromRegistry("OracleOwnerService"),
            "ERROR:ACM-005:NOT_ORACLE_OWNER"
        );
        _;
    }

    modifier onlyProductOwner() {
        require(
            msg.sender == getContractFromRegistry("ProductOwnerService"),
            "ERROR:ACM-006:NOT_PRODUCT_OWNER"
        );
        _;
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryAccess {
    
    function getContractFromRegistry(bytes32 _contractName) 
        external 
        view 
        returns (address _contractAddress);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// If this interface is changed, the respective interface in the GIF Core Contracts package needs to be changed as well.
interface IOracle {
    function request(uint256 _requestId, bytes calldata _input) external;
}