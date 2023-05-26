/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/dependencies/upgradeability/VersionedInitializable.sol


pragma solidity ^0.8.17;

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
     */
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     */
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


// File contracts/lib/DataTypes.sol


pragma solidity ^0.8.17;

library DataTypes {
    struct Position {
        address account;
        address debt;
        address collateral;
        uint256 amountIn;
        uint256 leverage;
        uint256 collateralAmount;
        uint256 borrowAmount;
    }
}


// File contracts/interfaces/IRouter.sol


pragma solidity ^0.8.17;

interface IRouter {
    struct SwapParams {
        address fromToken;
        address toToken;
        uint256 amount;
        string targetName;
        bytes data;
    }

    function fee() external view returns (uint256);

    function positionsIndex(address _account) external view returns (uint256);

    function positions(
        bytes32 _key
    ) external view returns (address, address, address, uint256, uint256, uint256, uint256);

    function accounts(address _owner) external view returns (address);

    function setFee(uint256 _fee) external;

    function swapAndOpen(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data,
        SwapParams memory _params
    ) external payable;

    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function swap(SwapParams memory _params) external payable;

    function updatePosition(DataTypes.Position memory _position) external;

    function getOrCreateAccount(address _owner) external returns (address);

    function getKey(address _account, uint256 _index) external pure returns (bytes32);

    function predictDeterministicAddress(address _owner) external view returns (address predicted);

    function getFeeAmount(uint256 _amount) external view returns (uint256 feeAmount);
}


// File contracts/interfaces/IConnectors.sol


pragma solidity ^0.8.17;

interface IConnectors {
    function addConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function updateConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function removeConnectors(string[] calldata _names) external;

    function isConnector(string calldata _name) external view returns (bool isOk, address _connector);
}


// File contracts/interfaces/IACLManager.sol


pragma solidity ^0.8.17;

interface IACLManager {
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    function addConnectorAdmin(address _admin) external;

    function removeConnectorAdmin(address _admin) external;

    function addRouterAdmin(address _admin) external;

    function removeRouterAdmin(address _admin) external;

    function isConnectorAdmin(address _admin) external view returns (bool);

    function isRouterAdmin(address _admin) external view returns (bool);
}


// File contracts/interfaces/IConfigurator.sol


pragma solidity ^0.8.17;

interface IConfigurator {
    function setFee(uint256 _fee) external;

    function addConnectors(string[] calldata _names, address[] calldata _addresses) external;

    function updateConnectors(string[] calldata _names, address[] calldata _addresses) external;

    function removeConnectors(string[] calldata _names) external;
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


// File contracts/Configurator.sol


pragma solidity ^0.8.17;





/**
 * @title Configurator
 * @author FlashFlow
 * @dev Implements the configuration methods for the FlashFlow protocol
 */
contract Configurator is VersionedInitializable, IConfigurator {
    /* ============ Constants ============ */

    uint256 public constant CONFIGURATOR_REVISION = 0x1;

    /* ============ State Variables ============ */

    IRouter internal _router;
    IConnectors internal _connectors;
    IAddressesProvider internal _addressesProvider;

    /* ============ Events ============ */

    /**
     * @dev Emitted when set new router fee.
     * @param oldFee The old fee, expressed in bps
     * @param newFee The new fee, expressed in bps
     */
    event ChangeRouterFee(uint256 oldFee, uint256 newFee);

    /* ============ Modifiers ============ */

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     */
    modifier onlyRouterAdmin() {
        _onlyRouterAdmin();
        _;
    }

    /**
     * @dev Only connector admin can call functions marked by this modifier.
     */
    modifier onlyConnectorAdmin() {
        _onlyConnectorAdmin();
        _;
    }

    /* ============ Initializer ============ */

    function initialize(IAddressesProvider provider) public initializer {
        _addressesProvider = provider;
        _router = IRouter(_addressesProvider.getRouter());
        _connectors = IConnectors(_addressesProvider.getConnectors());
    }

    /* ============ External Functions ============ */

    /**
     * @notice Set a new fee to the router contract.
     * @param _fee The new amount
     */
    function setFee(uint256 _fee) external onlyRouterAdmin {
        uint256 currentFee = _router.fee();
        _router.setFee(_fee);
        emit ChangeRouterFee(currentFee, _fee);
    }

    /**
     * @dev Add Connectors to the connectors contract
     * @param _names Array of Connector Names.
     * @param _addresses Array of Connector Address.
     */
    function addConnectors(string[] calldata _names, address[] calldata _addresses) external onlyConnectorAdmin {
        _connectors.addConnectors(_names, _addresses);
    }

    /**
     * @dev Update Connectors on the connectors contract
     * @param _names Array of Connector Names.
     * @param _addresses Array of Connector Address.
     */
    function updateConnectors(string[] calldata _names, address[] calldata _addresses) external onlyConnectorAdmin {
        _connectors.updateConnectors(_names, _addresses);
    }

    /**
     * @dev Remove Connectors on the connectors contract
     * @param _names Array of Connector Names.
     */
    function removeConnectors(string[] calldata _names) external onlyConnectorAdmin {
        _connectors.removeConnectors(_names);
    }

    /* ============ Internal Functions ============ */

    function _onlyRouterAdmin() internal view {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(aclManager.isRouterAdmin(msg.sender), Errors.CALLER_NOT_ROUTER_ADMIN);
    }

    function _onlyConnectorAdmin() internal view {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(aclManager.isConnectorAdmin(msg.sender), Errors.CALLER_NOT_CONNECTOR_ADMIN);
    }

    /**
     * @notice Returns the version of the Configurator contract.
     * @return The version is needed to update the proxy.
     */
    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }
}