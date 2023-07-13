// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.9;

contract ListenerAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        require(
            admins[msg.sender],
            "LegendAccessControl: Only admins can perform this action"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _externalOwner
    ) {
        symbol = _symbol;
        name = _name;
        admins[_externalOwner] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != msg.sender, "Cannot remove yourself as admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./ListenerAccessControl.sol";

contract ListenerDB {
    string public name;
    string public symbol;
    string private _pkpAssignedPublicKey;
    address private _pkpAssignedAddress;
    uint256 private _pkpAssignedTokenId;
    ListenerAccessControl private _listenerAccessControl;

    struct Circuit {
        string _id;
        string _circuitInformation;
        string _status;
        address _instantiatorAddress;
    }

    modifier onlyAdmin(address _sender) {
        require(
            _listenerAccessControl.isAdmin(_sender),
            "Only Admin can update the assigned PKP Address."
        );
        _;
    }

    modifier onlyPKP(address _sender) {
        require(
            _sender == _pkpAssignedAddress,
            "Only assigned PKP can perform this function."
        );
        _;
    }

    // address to Circuit and Log strings
    mapping(address => mapping(string => Circuit)) private _addressIdToCircuit;
    mapping(address => mapping(string => string[])) private _addressIdToLogs;

    event PKPSet(
        address indexed oldPKPAddress,
        address indexed newPKPAddress,
        address updater
    );

    event LogAdded(
        string indexed circuitId,
        string[] stringifiedLogs,
        address instantiatorAddress
    );

    event CircuitAdded(
        string indexed circuitId,
        string circuitInformation,
        address instantiatorAddress
    );

    event CircuitInterrupted(
        string indexed circuitId,
        address instantiatorAddress
    );

    event CircuitCompleted(
        string indexed circuitId,
        address instantiatorAddress
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _pkpPublicKey,
        address _listenerAccessControlAddress,
        address _pkpAddress,
        uint256 _pkpTokenId
    ) {
        name = _name;
        symbol = _symbol;
        _listenerAccessControl = ListenerAccessControl(
            _listenerAccessControlAddress
        );
        _pkpAssignedAddress = _pkpAddress;
        _pkpAssignedPublicKey = _pkpPublicKey;
        _pkpAssignedTokenId = _pkpTokenId;
    }

    function addCircuitOnChain(
        string memory _circuitId,
        string memory _circuitInformation,
        address _instantiatorAddress
    ) external onlyPKP(msg.sender) {
        Circuit memory newCircuit = Circuit({
            _id: _circuitId,
            _circuitInformation: _circuitInformation,
            _status: "running",
            _instantiatorAddress: _instantiatorAddress
        });

        _addressIdToCircuit[_instantiatorAddress][_circuitId] = (newCircuit);

        emit CircuitAdded(
            _circuitId,
            _circuitInformation,
            _instantiatorAddress
        );
    }

    function addLogToCircuit(
        address _instantiatorAddress,
        string memory _circuitId,
        string[] memory _stringifiedLogs
    ) external onlyPKP(msg.sender) {
        for (uint256 i; i < _stringifiedLogs.length; i++) {
            _addressIdToLogs[_instantiatorAddress][_circuitId].push(
                _stringifiedLogs[i]
            );
        }

        emit LogAdded(_circuitId, _stringifiedLogs, _instantiatorAddress);
    }

    function interruptCircuit(
        string memory _circuitId,
        address _instantiatorAddress
    ) external onlyPKP(msg.sender) {
        _addressIdToCircuit[_instantiatorAddress][_circuitId]
            ._status = "interrupted";

        emit CircuitInterrupted(_circuitId, _instantiatorAddress);
    }

    function completeCircuit(
        string memory _circuitId,
        address _instantiatorAddress
    ) external onlyPKP(msg.sender) {
        _addressIdToCircuit[_instantiatorAddress][_circuitId]
            ._status = "completed";

        emit CircuitCompleted(_circuitId, _instantiatorAddress);
    }

    function getPKPAssignedAddress() public view returns (address) {
        return (_pkpAssignedAddress);
    }

    function getPKPAssignedPublicKey() public view returns (string memory) {
        return (_pkpAssignedPublicKey);
    }

    function getPKPAssignedTokenId() public view returns (uint256) {
        return (_pkpAssignedTokenId);
    }

    function getListenerAccessControl() public view returns (address) {
        return (address(_listenerAccessControl));
    }

    function getCircuitStatus(
        string memory _circuitId,
        address _instantiatorAddress
    ) public view returns (string memory) {
        return (_addressIdToCircuit[_instantiatorAddress][_circuitId]._status);
    }

    function getCircuitInformation(
        string memory _circuitId,
        address _instantiatorAddress
    ) public view returns (string memory) {
        return (
            _addressIdToCircuit[_instantiatorAddress][_circuitId]
                ._circuitInformation
        );
    }

    function getCircuitLogs(
        string memory _circuitId,
        address _instantiatorAddress
    ) public view returns (string[] memory) {
        return (_addressIdToLogs[_instantiatorAddress][_circuitId]);
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./ListenerAccessControl.sol";
import "./ListenerDB.sol";

contract ListenerFactory {
    string public name;
    string public symbol;

    event AccessControlSet(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event ListenerFactoryDeployed(
        address pkpAddress,
        address listenerAccessControlAddress,
        address listenerDBAddress,
        address indexed deployer,
        uint256 timestamp
    );

    mapping(address => address[]) private _deployedListenerAccessControl;
    mapping(address => address[]) private _mintedPKPs;
    mapping(address => address[]) private _deployedListenerDB;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function deployFromFactory(
        address _mintedPKPAddress,
        string memory _mintedPKPPublicKey,
        uint256 _mintedPKPTokenId
    ) public {
        address _instantiatorAddress = msg.sender;

        // Deploy ListenerAccessControl
        ListenerAccessControl newListenerAccessControl = new ListenerAccessControl(
                "ListenerAccessControl",
                "LAC",
                _instantiatorAddress
            );

        // Deploy ListenerDB
        ListenerDB newListenerDB = new ListenerDB(
            "ListenerDB",
            "LDB",
            _mintedPKPPublicKey,
            address(newListenerAccessControl),
            _mintedPKPAddress,
            _mintedPKPTokenId
        );

        _mintedPKPs[_instantiatorAddress].push(_mintedPKPAddress);
        _deployedListenerDB[_instantiatorAddress].push(address(newListenerDB));
        _deployedListenerAccessControl[_instantiatorAddress].push(
            address(newListenerAccessControl)
        );

        emit ListenerFactoryDeployed(
            _mintedPKPAddress,
            address(newListenerAccessControl),
            address(newListenerDB),
            msg.sender,
            block.timestamp
        );
    }

    function getMintedPKPs(
        address _deployerAddress
    ) public view returns (address[] memory) {
        return _mintedPKPs[_deployerAddress];
    }

    function getDeployedListenerAccessControl(
        address _deployerAddress
    ) public view returns (address[] memory) {
        return _deployedListenerAccessControl[_deployerAddress];
    }

    function getDeployedListenerDB(
        address _deployerAddress
    ) public view returns (address[] memory) {
        return _deployedListenerDB[_deployerAddress];
    }
}