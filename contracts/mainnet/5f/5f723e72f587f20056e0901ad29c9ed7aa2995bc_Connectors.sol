/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/interfaces/IConnector.sol


pragma solidity ^0.8.17;

interface IConnector {
    function NAME() external view returns (string memory);
}


// File contracts/interfaces/IConnectors.sol


pragma solidity ^0.8.17;

interface IConnectors {
    function addConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function updateConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function removeConnectors(string[] calldata _names) external;

    function isConnector(string calldata _name) external view returns (bool isOk, address _connector);
}


// File contracts/interfaces/IAddressesProvider.sol


pragma solidity ^0.8.17;

interface IAddressesProvider {
    function setAddress(bytes32 _id, address _newAddress) external;

    function setRouterImpl(address _newRouterImpl) external;

    function setConfiguratorImpl(address _newConfiguratorImpl) external;

    function getRouter() external view returns (address);

    function getConfigurator() external view returns (address);

    function getACLAdmin() external view returns (address);

    function getACLManager() external view returns (address);

    function getConnectors() external view returns (address);

    function getTreasury() external view returns (address);

    function getAccountImpl() external view returns (address);

    function getAccountProxy() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}


// File contracts/lib/Errors.sol


pragma solidity ^0.8.17;

/**
 * @title Errors library
 * @author FlashFlow
 * @notice Defines the error messages emitted by the different contracts of the FlashFlow protocol
 */
library Errors {
    // The caller of the function is not a account owner
    string public constant CALLER_NOT_ACCOUNT_OWNER = '1';
    // The caller of the function is not a account contract
    string public constant CALLER_NOT_RECEIVER = '2';
    // The caller of the function is not a flash aggregatoor contract
    string public constant CALLER_NOT_FLASH_AGGREGATOR = '3';
    // The caller of the function is not a position owner
    string public constant CALLER_NOT_POSITION_OWNER = '4';
    // The address of the pool addresses provider is invalid
    string public constant INVALID_ADDRESSES_PROVIDER = '5';
    // The initiator of the flashloan is not a account contract
    string public constant INITIATOR_NOT_ACCOUNT = '6';
    // Failed to charge the protocol fee
    string public constant CHARGE_FEE_NOT_COMPLETED = '7';
    // The sender does not have an account
    string public constant ACCOUNT_DOES_NOT_EXIST = '9';
    // Invalid amount to charge fee
    string public constant INVALID_CHARGE_AMOUNT = '10';
    // There is no connector with this name
    string public constant NOT_CONNECTOR = '11';
    // The address of the connector is invalid
    string public constant INVALID_CONNECTOR_ADDRESS = '12';
    // The length of the connector array and their names are different
    string public constant INVALID_CONNECTORS_LENGTH = '13';
    // A connector with this name already exists
    string public constant CONNECTOR_ALREADY_EXIST = '14';
    // A connector with this name does not exist
    string public constant CONNECTOR_DOES_NOT_EXIST = '15';
    // The caller of the function is not a configurator
    string public constant CALLER_NOT_CONFIGURATOR = '16';
    // The fee amount is invalid
    string public constant INVALID_FEE_AMOUNT = '17';
    // The address of the implementation is invalid
    string public constant INVALID_IMPLEMENTATION_ADDRESS = '18';
    // 'ACL admin cannot be set to the zero address'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = '19';
    // 'The caller of the function is not a router admin'
    string public constant CALLER_NOT_ROUTER_ADMIN = '20';
    // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = '21';
    // 'The caller of the function is not an connector admin'
    string public constant CALLER_NOT_CONNECTOR_ADMIN = '22';
    // Address should be not zero address
    string public constant ADDRESS_IS_ZERO = '23';
    // The caller of the function is not a router contract
    string public constant CALLER_NOT_ROUTER = '24';
    // The call to the open/close callback function failed
    string public constant EXECUTE_OPERATION_FAILED = '25';
    // Invalid amount to leverage
    string public constant LEVERAGE_IS_INVALID = '26';
}


// File contracts/Connectors.sol


pragma solidity ^0.8.17;



/**
 * @title Connectors
 * @author FlashFlow
 * @notice Contract to manage and store auxiliary contracts to work with the necessary protocols
 */
contract Connectors is IConnectors {
    /* ============ Immutables ============ */

    // The contract by which all other contact addresses are obtained.
    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    /* ============ State Variables ============ */

    // Enabled Connectors(Connector name => address).
    mapping(string => address) private connectors;

    /* ============ Events ============ */

    /**
     * @dev Emitted when new connector added.
     * @param name Connector name.
     * @param connector Connector contract address.
     */
    event ConnectorAdded(string name, address indexed connector);

    /**
     * @dev Emitted when the router is updated.
     * @param name Connector name.
     * @param oldConnector Old connector contract address.
     * @param newConnector New connector contract address.
     */
    event ConnectorUpdated(string name, address indexed oldConnector, address indexed newConnector);

    /**
     * @dev Emitted when connecter will be removed.
     * @param name Connector name.
     * @param connector Connector contract address.
     */
    event ConnectorRemoved(string name, address indexed connector);

    /* ============ Modifiers ============ */

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     */
    modifier onlyConfigurator() {
        require(ADDRESSES_PROVIDER.getConfigurator() == msg.sender, Errors.CALLER_NOT_CONFIGURATOR);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @param provider The address of the AddressesProvider contract
     */
    constructor(address provider) {
        ADDRESSES_PROVIDER = IAddressesProvider(provider);
    }

    /* ============ External Functions ============ */

    /**
     * @dev Add Connectors
     * @param _names Array of Connector Names.
     * @param _connectors Array of Connector Address.
     */
    function addConnectors(
        string[] calldata _names,
        address[] calldata _connectors
    ) external override onlyConfigurator {
        require(_names.length == _connectors.length, Errors.INVALID_CONNECTORS_LENGTH);

        for (uint i = 0; i < _connectors.length; i++) {
            string memory name = _names[i];
            address connector = _connectors[i];

            require(connectors[name] == address(0), Errors.CONNECTOR_ALREADY_EXIST);
            require(connector != address(0), Errors.INVALID_CONNECTOR_ADDRESS);
            IConnector(connector).NAME();
            connectors[name] = connector;

            emit ConnectorAdded(name, connector);
        }
    }

    /**
     * @dev Update Connectors
     * @param _names Array of Connector Names.
     * @param _connectors Array of Connector Address.
     */
    function updateConnectors(
        string[] calldata _names,
        address[] calldata _connectors
    ) external override onlyConfigurator {
        require(_names.length == _connectors.length, Errors.INVALID_CONNECTORS_LENGTH);

        for (uint i = 0; i < _connectors.length; i++) {
            string memory name = _names[i];
            address connector = _connectors[i];
            address oldConnector = connectors[name];

            require(connectors[name] != address(0), Errors.CONNECTOR_DOES_NOT_EXIST);
            require(connector != address(0), Errors.INVALID_CONNECTOR_ADDRESS);
            IConnector(connector).NAME();
            connectors[name] = connector;

            emit ConnectorUpdated(name, oldConnector, connector);
        }
    }

    /**
     * @dev Remove Connectors
     * @param _names Array of Connector Names.
     */
    function removeConnectors(string[] calldata _names) external override onlyConfigurator {
        for (uint i = 0; i < _names.length; i++) {
            string memory name = _names[i];
            address connector = connectors[name];

            require(connector != address(0), Errors.CONNECTOR_DOES_NOT_EXIST);

            emit ConnectorRemoved(name, connector);
            delete connectors[name];
        }
    }

    /**
     * @dev Check if Connector addresses are enabled.
     * @param _name Connector Name.
     */
    function isConnector(string calldata _name) external view returns (bool isOk, address connector) {
        isOk = true;
        connector = connectors[_name];

        if (connector == address(0)) {
            isOk = false;
        }
    }
}