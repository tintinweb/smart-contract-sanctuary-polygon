// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from './dependencies/openzeppelin/contracts/IERC20.sol';
import { Address } from './dependencies/openzeppelin/contracts/Address.sol';
import { Initializable } from './dependencies/openzeppelin/upgradeability/Initializable.sol';

import { Errors } from './lib/Errors.sol';
import { DataTypes } from './lib/DataTypes.sol';
import { PercentageMath } from './lib/PercentageMath.sol';
import { ConnectorsCall } from './lib/ConnectorsCall.sol';
import { UniversalERC20 } from './lib/UniversalERC20.sol';

import { IRouter } from './interfaces/IRouter.sol';
import { IAccount } from './interfaces/IAccount.sol';
import { IConnectors } from './interfaces/IConnectors.sol';
import { IBaseFlashloan } from './interfaces/IBaseFlashloan.sol';
import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

/**
 * @title Account
 * @author FlashFlow
 * @notice Contract used as implimentation user account.
 * @dev Interaction with contracts is carried out by means of calling the proxy contract.
 */
contract Account is Initializable, IAccount {
    using UniversalERC20 for IERC20;
    using ConnectorsCall for IAddressesProvider;
    using Address for address;
    using PercentageMath for uint256;

    /* ============ Immutables ============ */

    // The contract by which all other contact addresses are obtained.
    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    /* ============ State Variables ============ */

    address private _owner;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the tokens is claimed.
     * @param token The address of the token to withdraw.
     * @param amount The amount of the token to withdraw.
     */
    event ClaimedTokens(address token, address owner, uint256 amount);

    /**
     * @dev Emitted when the account take falshlaon.
     * @param token Flashloan token.
     * @param amount Flashloan amount.
     * @param fee Flashloan fee.
     */
    event Flashloan(address indexed token, uint256 amount, uint256 fee);

    /* ============ Modifiers ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, Errors.CALLER_NOT_ACCOUNT_OWNER);
        _;
    }

    /**
     * @dev Throws if called by any account other than the current contract.
     */
    modifier onlyCallback() {
        require(msg.sender == address(this), Errors.CALLER_NOT_RECEIVER);
        _;
    }

    /**
     * @dev Throws if called by any account other than the router contract.
     */
    modifier onlyRouter() {
        require(msg.sender == address(ADDRESSES_PROVIDER.getRouter()), Errors.CALLER_NOT_ROUTER);
        _;
    }

    /* ============ Initializer ============ */

    /**
     * @dev Constructor.
     * @param provider The address of the AddressesProvider contract
     */
    constructor(address provider) {
        ADDRESSES_PROVIDER = IAddressesProvider(provider);
    }

    /**
     * @dev initialize.
     * @param _user Owner account address.
     * @param _provider The address of the AddressesProvider contract.
     */
    function initialize(address _user, IAddressesProvider _provider) public override initializer {
        require(ADDRESSES_PROVIDER == _provider, Errors.INVALID_ADDRESSES_PROVIDER);
        _owner = _user;
    }

    /* ============ External Functions ============ */

    /**
     * @dev Takes a loan, calls `openPositionCallback` inside the loan, and transfers the commission.
     * @param _position The structure of the current position.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external override onlyRouter {
        require(_position.account == _owner, Errors.CALLER_NOT_POSITION_OWNER);
        IERC20(_position.debt).universalTransferFrom(msg.sender, address(this), _position.amountIn);

        uint256 amount = _position.amountIn.mulTo(_position.leverage - PercentageMath.PERCENTAGE_FACTOR);

        flashloan(_position.debt, amount, _targetName, _data);

        require(chargeFee(_position.amountIn + amount, _position.debt), Errors.CHARGE_FEE_NOT_COMPLETED);
    }

    /**
     * @dev Takes a loan, calls `closePositionCallback` inside the loan.
     * @param _key The key to obtain the current position.
     * @param _token Flashloan token.
     * @param _amount Flashloan amount.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external override onlyRouter {
        (address account, , , , , , ) = getRouter().positions(_key);
        require(account == _owner, Errors.CALLER_NOT_POSITION_OWNER);

        flashloan(_token, _amount, _targetName, _data);
    }

    /**
     * @dev Is called via the caldata within a flashloan.
     * - Swap poisition debt token to collateral token.
     * - Deposit collateral token to the lending protocol.
     * - Borrow debt token to repay flashloan.
     * @param _targetNames The connector name that will be called are.
     * @param _datas Calldata needed to work with the connector `_datas and _targetNames must be with the same index`.
     * @param _customDatas Additional parameters for future use.
     * @param _repayAmount The amount needed to repay the flashloan.
     * @param _repayAddress The amount needed to repay the flashloan.
     */
    function openPositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external override onlyCallback {
        uint256 value = _swap(_targetNames[0], _datas[0]);
        ADDRESSES_PROVIDER.connectorCall(_targetNames[1], abi.encodePacked(_datas[1], value));
        ADDRESSES_PROVIDER.connectorCall(_targetNames[1], abi.encodePacked(_datas[2], _repayAmount));
        DataTypes.Position memory position = getPosition(bytes32(_customDatas[0]));

        position.collateralAmount = value;
        position.borrowAmount = _repayAmount;

        getRouter().updatePosition(position);
        IERC20(position.debt).universalTransfer(_repayAddress, _repayAmount);
    }

    /**
     * @dev Is called via the calldata within a flashloan.
     * - Repay debt token to the lending protocol.
     * - Withdraw collateral token.
     * - Swap poisition collateral token to debt token.
     * @param _targetNames The connector name that will be called are.
     * @param _datas Calldata needed to work with the connector `_datas and _targetNames must be with the same index`.
     * @param _customDatas Additional parameters for future use.
     * @param _repayAmount The amount needed to repay the flashloan.
     * @param _repayAddress The amount needed to repay the flashloan.
     */
    function closePositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external override onlyCallback {
        ADDRESSES_PROVIDER.connectorCall(_targetNames[0], _datas[0]);
        ADDRESSES_PROVIDER.connectorCall(_targetNames[1], _datas[1]);

        uint256 returnedAmt = _swap(_targetNames[2], _datas[2]);

        DataTypes.Position memory position = getPosition(bytes32(_customDatas[0]));

        IERC20(position.debt).universalTransfer(_repayAddress, _repayAmount);
        IERC20(position.debt).universalTransfer(position.account, returnedAmt - _repayAmount);
    }

    /**
     * @dev Takes a loan, and call `callbackFunction` inside the loan.
     * @param _token that was Flashloan.
     * @param _amount Amounts that was Flashloan.
     * @param _fee Loan repayment fee.
     * @param _initiator Address from which the loan was initiated.
     * @param _targetName The connector name that will be called are.
     * @param _params Calldata for the openPositionCallback.
     */
    function executeOperation(
        address _token,
        uint256 _amount,
        uint256 _fee,
        address _initiator,
        string memory _targetName,
        bytes calldata _params
    ) external override {
        require(_initiator == address(this), Errors.INITIATOR_NOT_ACCOUNT);

        address connector = isConnector(_targetName);
        require(connector == msg.sender, Errors.NOT_CONNECTOR);

        bytes memory encodeParams = encodingParams(_params, _amount + _fee, connector);
        address(this).functionCall(encodeParams, Errors.EXECUTE_OPERATION_FAILED);

        emit Flashloan(_token, _amount, _fee);
    }

    /**
     * @dev Owner account claim tokens.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of the token to withdraw.
     */
    function claimTokens(address _token, uint256 _amount) external override onlyOwner {
        _amount = _amount == 0 ? IERC20(_token).universalBalanceOf(address(this)) : _amount;

        IERC20(_token).universalTransfer(_owner, _amount);

        emit ClaimedTokens(_token, _owner, _amount);
    }

    // solhint-disable-next-line
    receive() external payable {}

    /* ============ Private Functions ============ */

    /**
     * @dev Takes a loan, and call `callbackFunction` inside the loan.
     * @param _token Flashloan token.
     * @param _amount Flashloan amount.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function flashloan(address _token, uint256 _amount, string memory _targetName, bytes calldata _data) private {
        address connector = isConnector(_targetName);
        connector.functionCall(abi.encodeWithSelector(IBaseFlashloan.flashLoan.selector, _token, _amount, _data));
    }

    /**
     * @dev Internal function for the exchange, sends tokens to the current contract.
     * @param _name Name of the connector.
     * @param _data Execute calldata.
     * @return value Returns the amount of tokens received.
     */
    function _swap(string memory _name, bytes memory _data) private returns (uint256 value) {
        bytes memory response = ADDRESSES_PROVIDER.connectorCall(_name, _data);
        value = abi.decode(response, (uint256));
    }

    /**
     * @dev Internal function for the charge fee for the using protocol.
     * @param _amount Position amount.
     * @param _token Position token.
     * @return success Returns result of the operation.
     */
    function chargeFee(uint256 _amount, address _token) private returns (bool success) {
        uint256 feeAmount = getRouter().getFeeAmount(_amount);
        success = IERC20(_token).universalTransfer(ADDRESSES_PROVIDER.getTreasury(), feeAmount);
    }

    function isConnector(string memory _name) private view returns (address) {
        address connectors = ADDRESSES_PROVIDER.getConnectors();
        require(connectors != address(0), Errors.ADDRESS_IS_ZERO);

        (bool isOk, address connector) = IConnectors(connectors).isConnector(_name);
        require(isOk, Errors.NOT_CONNECTOR);

        return connector;
    }

    /**
     * @dev Returns the position for the owner.
     * @param _key The key to obtain the current position.
     * @return The structure of the current position.
     */
    function getPosition(bytes32 _key) private view returns (DataTypes.Position memory) {
        (
            address account,
            address debt,
            address collateral,
            uint256 amountIn,
            uint256 sizeDelta,
            uint256 collateralAmount,
            uint256 borrowAmount
        ) = getRouter().positions(_key);
        require(account == _owner, Errors.CALLER_NOT_POSITION_OWNER);
        return DataTypes.Position(account, debt, collateral, amountIn, sizeDelta, collateralAmount, borrowAmount);
    }

    /**
     * @dev Returns an instance of the router class.
     * @return Returns current router contract.
     */
    function getRouter() private view returns (IRouter) {
        return IRouter(ADDRESSES_PROVIDER.getRouter());
    }

    /**
     * @dev Takes a loan, and call `callbackFunction` inside the loan.
     * @param _params parameters for the open and close position callback.
     * @param _amount Loan amount plus loan fee.
     * @param _connector Loan amount plus loan fee.
     * @return encode Merged parameters of the callback and the loan amount.
     */
    function encodingParams(
        bytes memory _params,
        uint256 _amount,
        address _connector
    ) private pure returns (bytes memory encode) {
        (bytes4 selector, string[] memory _targetNames, bytes[] memory _datas, bytes[] memory _customDatas) = abi
            .decode(_params, (bytes4, string[], bytes[], bytes[]));

        encode = abi.encodeWithSelector(selector, _targetNames, _datas, _customDatas, _amount, _connector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControl } from './dependencies/openzeppelin/contracts/AccessControl.sol';

import { IACLManager } from './interfaces/IACLManager.sol';
import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

import { Errors } from './lib/Errors.sol';

/**
 * @title ACLManager
 * @author FlashFlow
 * @notice Access Control List Manager. Main registry of system roles and permissions.
 */
contract ACLManager is AccessControl, IACLManager {
    /* ============ Constants ============ */

    bytes32 public constant ROUTER_ADMIN_ROLE = keccak256('ROUTER_ADMIN_ROLE');
    bytes32 public constant CONNECTOR_ADMIN_ROLE = keccak256('CONNECTOR_ADMIN_ROLE');

    /* ============ Immutables ============ */

    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    /* ============ Constructor ============ */

    /**
     * @dev Constructor
     * @dev The ACL admin should be initialized at the addressesProvider beforehand
     * @param provider The address of the AddressesProvider
     */
    constructor(IAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        address aclAdmin = provider.getACLAdmin();
        require(aclAdmin != address(0), Errors.ACL_ADMIN_CANNOT_BE_ZERO);
        _setupRole(DEFAULT_ADMIN_ROLE, aclAdmin);
    }

    /* ============ External Functions ============ */

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    function addConnectorAdmin(address admin) external override {
        grantRole(CONNECTOR_ADMIN_ROLE, admin);
    }

    function removeConnectorAdmin(address admin) external override {
        revokeRole(CONNECTOR_ADMIN_ROLE, admin);
    }

    function addRouterAdmin(address admin) external override {
        grantRole(ROUTER_ADMIN_ROLE, admin);
    }

    function removeRouterAdmin(address admin) external override {
        revokeRole(ROUTER_ADMIN_ROLE, admin);
    }

    function isConnectorAdmin(address admin) external view override returns (bool) {
        return hasRole(CONNECTOR_ADMIN_ROLE, admin);
    }

    function isRouterAdmin(address admin) external view override returns (bool) {
        return hasRole(ROUTER_ADMIN_ROLE, admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from './dependencies/openzeppelin//contracts/Ownable.sol';
import { InitializableAdminUpgradeabilityProxy } from './dependencies/openzeppelin/upgradeability/InitializableAdminUpgradeabilityProxy.sol';

import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

/**
 * @title AddressesProvider
 * @author FlashFlow
 * @notice Main registry of addresses part of or connected to the protocol
 * @dev Acts as factory of proxies, so with right to change its implementations
 */
contract AddressesProvider is Ownable, IAddressesProvider {
    /* ============ Constants ============ */

    // Main identifiers
    bytes32 private constant ROUTER = 'ROUTER';
    bytes32 private constant ACCOUNT = 'ACCOUNT';
    bytes32 private constant TREASURY = 'TREASURY';
    bytes32 private constant ACL_ADMIN = 'ACL_ADMIN';
    bytes32 private constant CONNECTORS = 'CONNECTORS';
    bytes32 private constant ACL_MANAGER = 'ACL_MANAGER';
    bytes32 private constant CONFIGURATOR = 'CONFIGURATOR';
    bytes32 private constant ACCOUNT_PROXY = 'ACCOUNT_PROXY';
    bytes32 private constant FLASHLOAN_AGGREGATOR = 'FLASHLOAN_AGGREGATOR';

    /* ============ State Variables ============ */

    // Map of registered addresses (identifier => registeredAddress)
    mapping(bytes32 => address) private _addresses;

    /* ============ Events ============ */

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when the router is updated.
     * @param oldAddress The old address of the Router
     * @param newAddress The new address of the Router
     */
    event RouterUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the router configurator is updated.
     * @param oldAddress The old address of the Router
     * @param newAddress The new address of the Router
     */
    event ConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @param _newOwner The owner address of this contract.
     */
    constructor(address _newOwner) {
        transferOwnership(_newOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @dev Set contract address for the current id.
     * @param _id Contract name in bytes32.
     * @param _newAddress New contract address.
     */
    function setAddress(bytes32 _id, address _newAddress) external override onlyOwner {
        address oldAddress = _addresses[_id];
        _addresses[_id] = _newAddress;
        emit AddressSet(_id, oldAddress, _newAddress);
    }

    /**
     * @notice Updates the implementation of the Router, or creates a proxy
     * setting the new `Router` implementation when the function is called for the first time.
     * @param _newRouterImpl The new Router implementation
     */
    function setRouterImpl(address _newRouterImpl) external override onlyOwner {
        address oldRouterImpl = _getProxyImplementation(ROUTER);
        _updateImpl(ROUTER, _newRouterImpl);
        emit RouterUpdated(oldRouterImpl, _newRouterImpl);
    }

    /**
     * @notice Updates the implementation of the Configurator, or creates a proxy
     * setting the new `Configurator` implementation when the function is called for the first time.
     * @param _newConfiguratorImpl The new Configurator implementation
     */
    function setConfiguratorImpl(address _newConfiguratorImpl) external override onlyOwner {
        address oldConfiguratorImpl = _getProxyImplementation(CONFIGURATOR);
        _updateImpl(CONFIGURATOR, _newConfiguratorImpl);
        emit ConfiguratorUpdated(oldConfiguratorImpl, _newConfiguratorImpl);
    }

    /**
     * @notice Returns the address of the Router proxy.
     * @return The Router proxy address
     */
    function getRouter() external view override returns (address) {
        return getAddress(ROUTER);
    }

    /**
     * @notice Returns the address of the Router configurator proxy.
     * @return The Router configurator proxy address
     */
    function getConfigurator() external view override returns (address) {
        return getAddress(CONFIGURATOR);
    }

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view override returns (address) {
        return getAddress(ACL_ADMIN);
    }

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view override returns (address) {
        return getAddress(ACL_MANAGER);
    }

    /**
     * @notice Returns the address of the Connectors proxy.
     * @return The Connectors proxy address
     */
    function getConnectors() external view override returns (address) {
        return getAddress(CONNECTORS);
    }

    /**
     * @notice Returns the address of the Flashloan aggregator proxy.
     * @return The Flashloan aggregator proxy address
     */
    function getFlashloanAggregator() external view override returns (address) {
        return getAddress(FLASHLOAN_AGGREGATOR);
    }

    /**
     * @notice Returns the address of the Treasury proxy.
     * @return The Treasury proxy address
     */
    function getTreasury() external view override returns (address) {
        return getAddress(TREASURY);
    }

    /**
     * @notice Returns the address of the Account implementation.
     * @return The Account implementation address
     */
    function getAccountImpl() external view override returns (address) {
        return getAddress(ACCOUNT);
    }

    /**
     * @notice Returns the address of the Account proxy.
     * @return The Account proxy address
     */
    function getAccountProxy() external view override returns (address) {
        return getAddress(ACCOUNT_PROXY);
    }

    /* ============ Public Functions ============ */

    /**
     * @param _id The key to obtain the address.
     * @return Returns the contract address.
     */
    function getAddress(bytes32 _id) public view override returns (address) {
        return _addresses[_id];
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to update the implementation of a specific proxied component of the protocol.
     * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
     *   as implementation and calls the initialize() function on the proxy
     * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     */
    function _updateImpl(bytes32 id, address newAddress) internal {
        address proxyAddress = _addresses[id];
        InitializableAdminUpgradeabilityProxy proxy;
        bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableAdminUpgradeabilityProxy();
            _addresses[id] = proxyAddress = address(proxy);
            proxy.initialize(newAddress, address(this), params);
            emit ProxyCreated(id, proxyAddress, newAddress);
        } else {
            proxy = InitializableAdminUpgradeabilityProxy(payable(proxyAddress));
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    /**
     * @notice Returns the the implementation contract of the proxy contract by its identifier.
     * @dev It returns ZERO if there is no registered address with the given id
     * @dev It reverts if the registered address with the given id is not `InitializableAdminUpgradeabilityProxy`
     * @param id The id
     * @return The address of the implementation contract
     */
    function _getProxyImplementation(bytes32 id) internal returns (address) {
        address proxyAddress = _addresses[id];
        if (proxyAddress == address(0)) {
            return address(0);
        } else {
            address payable payableProxyAddress = payable(proxyAddress);
            return InitializableAdminUpgradeabilityProxy(payableProxyAddress).implementation();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { VersionedInitializable } from './dependencies/upgradeability/VersionedInitializable.sol';

import { IRouter } from './interfaces/IRouter.sol';
import { IConnectors } from './interfaces/IConnectors.sol';
import { IACLManager } from './interfaces/IACLManager.sol';
import { IConfigurator } from './interfaces/IConfigurator.sol';
import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

import { Errors } from './lib/Errors.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IConnector } from './interfaces/IConnector.sol';
import { IConnectors } from './interfaces/IConnectors.sol';
import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

import { Errors } from './lib/Errors.sol';

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
            IConnector(connector).name();
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
            IConnector(connector).name();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../../dependencies/openzeppelin/contracts/IERC20.sol';

import { IAaveV2Connector } from '../../interfaces/connectors/IAaveV2Connector.sol';
import { ILendingPool } from '../../interfaces/external/aave-v2/ILendingPool.sol';
import { IProtocolDataProvider } from '../../interfaces/external/aave-v2/IProtocolDataProvider.sol';
import { ILendingPoolAddressesProvider } from '../../interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol';

import { UniversalERC20 } from '../../lib/UniversalERC20.sol';

contract AaveV2BaseConnector is IAaveV2Connector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant override name = 'AaveV2';

    /* ============ State Variables ============ */

    ILendingPoolAddressesProvider public immutable aaveProvider;
    IProtocolDataProvider public immutable aaveData;
    uint16 public immutable referralCode;

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @param _aaveProvider The address of the AddressesProvider contract
     * @param _aaveData The address of the DataProvider contract
     * @param _referralCode  The referral code number
     */
    constructor(ILendingPoolAddressesProvider _aaveProvider, IProtocolDataProvider _aaveData, uint16 _referralCode) {
        aaveProvider = _aaveProvider;
        aaveData = _aaveData;
        referralCode = _referralCode;
    }

    /* ============ External Functions ============ */

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v2 for lending / collaterization.
     * @param _token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to deposit. (For max: `type(uint).max`)
     */
    function deposit(address _token, uint256 _amount) external payable override {
        ILendingPool aave = ILendingPool(aaveProvider.getLendingPool());

        IERC20 tokenC = IERC20(_token);

        _amount = _amount == type(uint).max ? tokenC.balanceOf(address(this)) : _amount;

        tokenC.universalApprove(address(aave), _amount);

        aave.deposit(_token, _amount, address(this), referralCode);

        if (!getIsCollateral(_token)) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Aave v2
     * @param _token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to withdraw. (For max: `type(uint).max`)
     */
    function withdraw(address _token, uint256 _amount) external payable override {
        ILendingPool aave = ILendingPool(aaveProvider.getLendingPool());
        IERC20 tokenC = IERC20(_token);

        uint256 initialBal = tokenC.balanceOf(address(this));
        aave.withdraw(_token, _amount, address(this));
        uint256 finalBal = tokenC.balanceOf(address(this));

        _amount = finalBal - initialBal;
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v2
     * @param _token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _rateMode The type of borrow debt. (For Stable: 1, Variable: 2)
     * @param _amount The amount of the token to borrow.
     */
    function borrow(address _token, uint256 _rateMode, uint256 _amount) external payable override {
        ILendingPool aave = ILendingPool(aaveProvider.getLendingPool());

        aave.borrow(_token, _amount, _rateMode, referralCode, address(this));
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param _token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to payback. (For max: `type(uint).max`)
     * @param _rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
     */
    function payback(address _token, uint256 _amount, uint256 _rateMode) external payable override {
        ILendingPool aave = ILendingPool(aaveProvider.getLendingPool());

        IERC20 tokenC = IERC20(_token);

        if (_amount == type(uint).max) {
            uint256 balance = tokenC.balanceOf(address(this));
            uint256 amountDebt = getPaybackBalance(_token, _rateMode, address(this));
            _amount = balance <= amountDebt ? balance : amountDebt;
        }

        tokenC.universalApprove(address(aave), _amount);

        aave.repay(_token, _amount, _rateMode, address(this));
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Get total debt balance & fee for an asset
     * @param _token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _rateMode Borrow rate mode (Stable = 1, Variable = 2)
     * @param _user Address whose balance we get.
     */
    function getPaybackBalance(address _token, uint _rateMode, address _user) public view override returns (uint) {
        (, uint stableDebt, uint variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, _user);
        return _rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param _token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _user Address whose balance we get.
     */
    function getCollateralBalance(address _token, address _user) public view override returns (uint256 balance) {
        (balance, , , , , , , , ) = aaveData.getUserReserveData(_token, _user);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Checks if collateral is enabled for an asset
     * @param _token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getIsCollateral(address _token) internal view returns (bool IsCollateral) {
        (, , , , , , , , IsCollateral) = aaveData.getUserReserveData(_token, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../../dependencies/openzeppelin/contracts/IERC20.sol';

import { IAaveV3Connector } from '../../interfaces/connectors/IAaveV3Connector.sol';
import { IPool } from '../../interfaces/external/aave-v3/IPool.sol';
import { IPoolDataProvider } from '../../interfaces/external/aave-v3/IPoolDataProvider.sol';
import { IPoolAddressesProvider } from '../../interfaces/external/aave-v3/IPoolAddressesProvider.sol';

import { UniversalERC20 } from '../../lib/UniversalERC20.sol';

contract AaveV3BaseConnector is IAaveV3Connector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant override name = 'AaveV3';

    /* ============ State Variables ============ */

    IPoolAddressesProvider public immutable aaveProvider;
    IPoolDataProvider public immutable aaveData;
    uint16 public immutable referralCode;

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @param _aaveProvider The address of the AddressesProvider contract
     * @param _aaveData The address of the DataProvider contract
     * @param _referralCode  The referral code number
     */
    constructor(IPoolAddressesProvider _aaveProvider, IPoolDataProvider _aaveData, uint16 _referralCode) {
        aaveProvider = _aaveProvider;
        aaveData = _aaveData;
        referralCode = _referralCode;
    }

    /* ============ External Functions ============ */

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v3 for lending / collaterization.
     * @param _token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to deposit. (For max: `type(uint).max`)
     */
    function deposit(address _token, uint256 _amount) external payable override {
        IPool aave = IPool(aaveProvider.getPool());

        IERC20 tokenC = IERC20(_token);

        _amount = _amount == type(uint256).max ? tokenC.balanceOf(address(this)) : _amount;

        tokenC.universalApprove(address(aave), _amount);
        aave.supply(_token, _amount, address(this), referralCode);

        if (!getisCollateral(_token)) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Aave v3
     * @param _token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to withdraw. (For max: `type(uint).max`)
     */
    function withdraw(address _token, uint256 _amount) external payable override {
        IPool aave = IPool(aaveProvider.getPool());

        IERC20 tokenC = IERC20(_token);

        uint256 initialBalance = tokenC.balanceOf(address(this));
        aave.withdraw(_token, _amount, address(this));
        uint256 finalBalance = tokenC.balanceOf(address(this));

        _amount = finalBalance - initialBalance;
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v3
     * @param _token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _rateMode The type of debt. (For Stable: 1, Variable: 2)
     * @param _amount The amount of the token to borrow.
     */
    function borrow(address _token, uint256 _rateMode, uint256 _amount) external payable override {
        IPool aave = IPool(aaveProvider.getPool());

        aave.borrow(_token, _amount, _rateMode, referralCode, address(this));
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param _token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to payback. (For max: `type(uint).max`)
     * @param _rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
     */
    function payback(address _token, uint256 _amount, uint256 _rateMode) external payable override {
        IPool aave = IPool(aaveProvider.getPool());

        IERC20 tokenC = IERC20(_token);

        _amount = _amount == type(uint256).max ? getPaybackBalance(_token, address(this), _rateMode) : _amount;

        tokenC.universalApprove(address(aave), _amount);
        aave.repay(_token, _amount, _rateMode, address(this));
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Get total debt balance & fee for an asset
     * @param _token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _recipeint Address whose balance we get.
     * @param _rateMode Borrow rate mode (Stable = 1, Variable = 2)
     */
    function getPaybackBalance(address _token, address _recipeint, uint256 _rateMode) public view returns (uint256) {
        (, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_token, _recipeint);
        return _rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param _token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _recipeint Address whose balance we get.
     */
    function getCollateralBalance(address _token, address _recipeint) public view returns (uint256 balance) {
        (balance, , , , , , , , ) = aaveData.getUserReserveData(_token, _recipeint);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Checks if collateral is enabled for an asset
     * @param _token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getisCollateral(address _token) internal view returns (bool isCollateral) {
        (, , , , , , , , isCollateral) = aaveData.getUserReserveData(_token, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IInchV5Connector } from '../interfaces/connectors/IInchV5Connector.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

contract InchV5Connector is IInchV5Connector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant name = 'OneInchV5';

    /**
     * @dev 1Inch Router v5 Address
     */
    address internal constant oneInchV5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the sender swap tokens.
     * @param account Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amount The amount of the token to sell.
     */
    event LogExchange(address indexed account, address toToken, address fromToken, uint256 amount);

    /* ============ External Functions ============ */

    /**
     * @dev Swap ETH/ERC20_Token using 1Inch.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from 1inch API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount) {
        buyAmount = _swap(_toToken, _fromToken, _amount, _callData);
        emit LogExchange(msg.sender, _toToken, _fromToken, _amount);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Universal approve tokens to inch router and execute calldata.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from 1inch API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function _swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) internal returns (uint256 buyAmount) {
        IERC20(_fromToken).universalApprove(oneInchV5, _amount);

        uint256 value = IERC20(_fromToken).isETH() ? _amount : 0;

        uint256 initalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        (bool success, bytes memory results) = oneInchV5.call{ value: value }(_callData);

        if (!success) {
            revert(string(results));
        }

        uint256 finalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        buyAmount = finalBalalance - initalBalalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IKyber } from '../interfaces/external/kyber/IKyber.sol';
import { IKyberConnector } from '../interfaces/connectors/IKyberConnector.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

contract KyberConnector is IKyberConnector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant name = 'CompoundV3';
    /**
     * @dev Kyber Interface
     */
    IKyber internal constant kyber = IKyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    // TODO change this address
    address internal constant referral = 0x444444Cc7FE267251797d8592C3f4d5EE6888D62;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the sender swap tokens.
     * @param account Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amount The amount of the token to sell.
     */
    event LogExchange(address indexed account, address toToken, address fromToken, uint256 amount);

    /* ============ External Functions ============ */

    /**
     * @dev Sell ETH/ERC20_Token using Kyber.
     * @notice Swap tokens from getting an optimized trade routes
     * @param _toToken The address of the token to buy.
     * @param _fromToken The address of the token to sell.
     * @param _amount The amount of the token to sell.
     * @return buyAmount Returns the amount of tokens received.
     */
    function swap(address _toToken, address _fromToken, uint256 _amount) external payable returns (uint256 buyAmount) {
        buyAmount = _swap(_toToken, _fromToken, _amount);
        emit LogExchange(msg.sender, _toToken, _fromToken, _amount);
    }

    /**
     * @dev Universal approve tokens to uniswap router and execute calldata.
     * @param _toToken The address of the token to buy.
     * @param _fromToken The address of the token to sell.
     * @param _amount The amount of the token to sell.
     * @return buyAmount Returns the amount of tokens received.
     */
    function _swap(address _toToken, address _fromToken, uint256 _amount) internal returns (uint256 buyAmount) {
        IERC20(_fromToken).universalApprove(address(kyber), _amount);

        uint256 value = IERC20(_fromToken).isETH() ? _amount : 0;

        uint256 initalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        kyber.trade{ value: value }(_fromToken, _amount, _toToken, address(this), 0, 0, referral);

        uint256 finalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        buyAmount = finalBalalance - initalBalalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IProtocolDataProvider } from '../../interfaces/external/aave-v2/IProtocolDataProvider.sol';
import { ILendingPoolAddressesProvider } from '../../interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol';

import { AaveV2BaseConnector } from '../base/AaveV2.sol';

contract AaveV2Connector is AaveV2BaseConnector {
    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     */
    constructor()
        AaveV2BaseConnector(
            ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5),
            IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPoolDataProvider } from '../../interfaces/external/aave-v3/IPoolDataProvider.sol';
import { IPoolAddressesProvider } from '../../interfaces/external/aave-v3/IPoolAddressesProvider.sol';

import { AaveV3BaseConnector } from '../base/AaveV3.sol';

contract AaveV3Connector is AaveV3BaseConnector {
    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     */
    constructor()
        AaveV3BaseConnector(
            IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e),
            IPoolDataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../../dependencies/openzeppelin/contracts/IERC20.sol';

import { ICompoundV2Connector } from '../../interfaces/connectors/ICompoundV2Connector.sol';
import { CErc20Interface } from '../../interfaces/external/compound-v2/CTokenInterfaces.sol';
import { ComptrollerInterface } from '../../interfaces/external/compound-v2/ComptrollerInterface.sol';

import { UniversalERC20 } from '../../lib/UniversalERC20.sol';

contract CompoundV2Connector is ICompoundV2Connector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface internal constant troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    string public constant override name = 'CompoundV2';

    /* ============ External Functions ============ */

    /**
     * @dev Deposit ETH/ERC20_Token using the Mapping.
     * @notice Deposit a token to Compound for lending / collaterization.
     * @param _token The address of the token to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to deposit. (For max: `type(uint).max`)
     */
    function deposit(address _token, uint256 _amount) external payable override {
        CErc20Interface cToken = _getCToken(_token);

        enterMarket(address(cToken));

        IERC20 tokenC = IERC20(_token);
        _amount = _amount == type(uint).max ? tokenC.balanceOf(address(this)) : _amount;
        tokenC.universalApprove(address(cToken), _amount);

        CErc20Interface(cToken).mint(_amount);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Compound
     * @param _token The address of the token to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to withdraw. (For max: `type(uint).max`)
     */
    function withdraw(address _token, uint256 _amount) external payable override {
        CErc20Interface cToken = _getCToken(_token);

        if (_amount == type(uint).max) {
            cToken.redeem(cToken.balanceOf(address(this)));
        } else {
            cToken.redeemUnderlying(_amount);
        }
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Compound
     * @param _token The address of the token to borrow. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to borrow.
     */
    function borrow(address _token, uint256 _amount) external payable override {
        CErc20Interface cToken = _getCToken(_token);

        enterMarket(address(cToken));
        CErc20Interface(cToken).borrow(_amount);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param _token The address of the token to payback. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to payback. (For max: `type(uint).max`)
     */
    function payback(address _token, uint256 _amount) external payable override {
        CErc20Interface cToken = _getCToken(_token);

        _amount = _amount == type(uint).max ? cToken.borrowBalanceCurrent(address(this)) : _amount;

        IERC20 tokenC = IERC20(_token);
        require(tokenC.balanceOf(address(this)) >= _amount, 'not enough token');

        tokenC.universalApprove(address(cToken), _amount);
        cToken.repayBorrow(_amount);
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Get total debt balance & fee for an asset
     * @param _token Token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _recipient Address whose balance we get.
     */
    function borrowBalanceOf(address _token, address _recipient) public override returns (uint256) {
        CErc20Interface cToken = _getCToken(_token);
        return cToken.borrowBalanceCurrent(_recipient);
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param _token Token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _recipient Address whose balance we get.
     */
    function collateralBalanceOf(address _token, address _recipient) public override returns (uint256) {
        CErc20Interface cToken = _getCToken(_token);
        return cToken.balanceOfUnderlying(_recipient);
    }

    /**
     * @dev Mapping base token to cToken
     * @param _token Base token address.
     */
    function _getCToken(address _token) public pure override returns (CErc20Interface) {
        if (IERC20(_token).isETH()) {
            // ETH
            return CErc20Interface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        }
        if (_token == 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9) {
            // AAVE
            return CErc20Interface(0xe65cdB6479BaC1e22340E4E755fAE7E509EcD06c);
        }
        if (_token == 0x0D8775F648430679A709E98d2b0Cb6250d2887EF) {
            // BAT
            return CErc20Interface(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E);
        }
        if (_token == 0xc00e94Cb662C3520282E6f5717214004A7f26888) {
            return CErc20Interface(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4);
        }
        if (_token == 0x6B175474E89094C44Da98b954EedeAC495271d0F) {
            // DAI
            return CErc20Interface(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        }
        if (_token == 0x956F47F50A910163D8BF957Cf5846D573E7f87CA) {
            // FEI
            return CErc20Interface(0x7713DD9Ca933848F6819F38B8352D9A15EA73F67);
        }
        if (_token == 0x514910771AF9Ca656af840dff83E8264EcF986CA) {
            // LINK
            return CErc20Interface(0xFAce851a4921ce59e912d19329929CE6da6EB0c7);
        }
        if (_token == 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2) {
            // MAKER
            return CErc20Interface(0x95b4eF2869eBD94BEb4eEE400a99824BF5DC325b);
        }
        if (_token == 0x1985365e9f78359a9B6AD760e32412f4a445E862) {
            // REP
            return CErc20Interface(0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1);
        }
        if (_token == 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359) {
            // SAI
            return CErc20Interface(0xF5DCe57282A584D2746FaF1593d3121Fcac444dC);
        }
        if (_token == 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2) {
            // SUSHI
            return CErc20Interface(0x4B0181102A0112A2ef11AbEE5563bb4a3176c9d7);
        }
        if (_token == 0x0000000000085d4780B73119b644AE5ecd22b376) {
            // TUSD
            return CErc20Interface(0x12392F67bdf24faE0AF363c24aC620a2f67DAd86);
        }
        if (_token == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) {
            // UNI
            return CErc20Interface(0x35A18000230DA775CAc24873d00Ff85BccdeD550);
        }
        if (_token == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
            // USDC
            return CErc20Interface(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
        }
        if (_token == 0x8E870D67F660D95d5be530380D0eC0bd388289E1) {
            // USDP
            return CErc20Interface(0x041171993284df560249B57358F931D9eB7b925D);
        }
        if (_token == 0xdAC17F958D2ee523a2206206994597C13D831ec7) {
            // USDT
            return CErc20Interface(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);
        }
        if (_token == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) {
            // WBTC
            return CErc20Interface(0xccF4429DB6322D5C611ee964527D42E5d685DD6a);
        }
        if (_token == 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e) {
            // YFI
            return CErc20Interface(0x80a2AE356fc9ef4305676f7a3E2Ed04e12C33946);
        }
        if (_token == 0xE41d2489571d322189246DaFA5ebDe1F4699F498) {
            // ZRX
            return CErc20Interface(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407);
        }

        revert('Unsupported token');
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Enter compound market
     */
    function enterMarket(address cToken) internal {
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cToken) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cToken;
            troller.enterMarkets(toEnter);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../../dependencies/openzeppelin/contracts/IERC20.sol';

import { ICompoundV3Connector } from '../../interfaces/connectors/ICompoundV3Connector.sol';
import { IComet } from '../../interfaces/external/compound-v3/IComet.sol';

import { UniversalERC20 } from '../../lib/UniversalERC20.sol';

contract CompoundV3Connector is ICompoundV3Connector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant name = 'CompoundV3';

    /* ============ External Functions ============ */

    /**
     * @dev Deposit base asset or collateral asset supported by the _market.
     * @notice Deposit a token to Compound for lending / collaterization.
     * @param _market The address of the market.
     * @param _token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to deposit. (For max: `type(uint).max`)
     */
    function deposit(address _market, address _token, uint256 _amount) external payable override {
        require(_market != address(0) && _token != address(0), 'invalid market/token address');

        IERC20 tokenC = IERC20(_token);

        if (_token == getBaseToken(_market)) {
            require(IComet(_market).borrowBalanceOf(address(this)) == 0, 'debt not repaid');
        }

        _amount = _amount == type(uint).max ? tokenC.balanceOf(address(this)) : _amount;

        tokenC.universalApprove(_market, _amount);

        IComet(_market).supply(_token, _amount);
    }

    /**
     * @dev Withdraw base/collateral asset.
     * @notice Withdraw base token or deposited token from Compound.
     * @param _market The address of the market.
     * @param _token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to withdraw. (For max: `type(uint).max`)
     */
    function withdraw(address _market, address _token, uint256 _amount) external payable override {
        require(_market != address(0) && _token != address(0), 'invalid market/token address');

        uint256 initialBalance = _getAccountSupplyBalanceOfAsset(address(this), _market, _token);

        if (_token == getBaseToken(_market)) {
            if (_amount == type(uint).max) {
                _amount = initialBalance;
            } else {
                //if there are supplies, ensure withdrawn _amount
                // is not greater than supplied i.e can't borrow using withdraw.
                require(_amount <= initialBalance, 'withdraw-amount-greater-than-supplies');
            }

            //if borrow balance > 0, there are no supplies so no withdraw, borrow instead.
            require(IComet(_market).borrowBalanceOf(address(this)) == 0, 'withdraw-disabled-for-zero-supplies');
        } else {
            _amount = _amount == type(uint).max ? initialBalance : _amount;
        }

        IComet(_market).withdraw(_token, _amount);
    }

    /**
     * @dev Borrow base asset.
     * @notice Borrow base token from Compound.
     * @param _market The address of the market.
     * @param _token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of base token to borrow.
     */
    function borrow(address _market, address _token, uint256 _amount) external payable override {
        require(_market != address(0), 'invalid market address');
        require(_token == getBaseToken(_market), 'invalid token');
        require(IComet(_market).balanceOf(address(this)) == 0, 'borrow-disabled-when-supplied-base');

        IComet(_market).withdraw(_token, _amount);
    }

    /**
     * @dev Repays the borrowed base asset.
     * @notice Repays the borrow of the base asset.
     * @param _market The address of the market.
     * @param _token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount to be repaid.
     */
    function payback(address _market, address _token, uint256 _amount) external payable override {
        require(_market != address(0) && _token != address(0), 'invalid market/token address');
        require(_token == getBaseToken(_market), 'invalid token');

        IERC20 tokenC = IERC20(_token);

        uint256 initialBalance = IComet(_market).borrowBalanceOf(address(this));

        if (_amount == type(uint).max) {
            _amount = initialBalance;
        } else {
            require(_amount <= initialBalance, 'payback-amount-greater-than-borrows');
        }

        //if supply balance > 0, there are no borrowing so no repay, supply instead.
        require(IComet(_market).balanceOf(address(this)) == 0, 'cannot-repay-when-supplied');

        tokenC.universalApprove(_market, _amount);

        IComet(_market).supply(_token, _amount);
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Get total debt balance & fee for an asset
     * @param _market Market contract address.
     * @param _recipient Address whose balance we get.
     */
    function borrowBalanceOf(address _market, address _recipient) public view override returns (uint256) {
        return IComet(_market).borrowBalanceOf(_recipient);
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param _market Market contract address.
     * @param _token Token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _recipient Address whose balance we get.
     */
    function collateralBalanceOf(
        address _market,
        address _recipient,
        address _token
    ) public view override returns (uint256) {
        return IComet(_market).collateralBalanceOf(_recipient, _token);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Get base _token on the current _market
     * @param _market Market contract address.
     */
    function getBaseToken(address _market) internal view returns (address baseToken) {
        baseToken = IComet(_market).baseToken();
    }

    function _getAccountSupplyBalanceOfAsset(
        address account,
        address _market,
        address asset
    ) internal returns (uint256 balance) {
        if (asset == getBaseToken(_market)) {
            //balance in base
            balance = IComet(_market).balanceOf(account);
        } else {
            //balance in asset denomination
            balance = uint256(IComet(_market).userCollateral(account, asset).balance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IAugustusSwapper } from '../interfaces/external/paraswap/IAugustusSwapper.sol';
import { IParaSwapConnector } from '../interfaces/connectors/IParaSwapConnector.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

contract ParaSwapConnector is IParaSwapConnector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant name = 'ParaSwap';

    /**
     * @dev Paraswap Router Address
     */
    address internal constant paraswap = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the sender swap tokens.
     * @param account Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amount The amount of the token to sell.
     */
    event LogExchange(address indexed account, address toToken, address fromToken, uint256 amount);

    /* ============ External Functions ============ */

    /**
     * @dev Swap ETH/ERC20_Token using ParaSwap.
     * @notice Swap tokens from exchanges like kyber, 0x etc, with calculation done off-chain.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from ParaSwap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount) {
        buyAmount = _swap(_toToken, _fromToken, _amount, _callData);
        emit LogExchange(msg.sender, _toToken, _fromToken, _amount);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Universal approve tokens to paraswap router and execute calldata.
     * @param _toToken The address of the token to buy.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _fromToken The address of the token to sell.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _amount The amount of the token to sell.
     * @param _callData Data from ParaSwap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function _swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) internal returns (uint256 buyAmount) {
        address tokenProxy = IAugustusSwapper(paraswap).getTokenTransferProxy();
        IERC20(_fromToken).universalApprove(tokenProxy, _amount);

        uint256 value = IERC20(_fromToken).isETH() ? _amount : 0; // matic have the same address

        uint256 initalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        (bool success, bytes memory results) = paraswap.call{ value: value }(_callData);

        if (!success) {
            revert(string(results));
        }

        uint256 finalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        buyAmount = finalBalalance - initalBalalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IProtocolDataProvider } from '../../interfaces/external/aave-v2/IProtocolDataProvider.sol';
import { ILendingPoolAddressesProvider } from '../../interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol';

import { AaveV2BaseConnector } from '../base/AaveV2.sol';

contract AaveV2Connector is AaveV2BaseConnector {
    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     */
    constructor()
        AaveV2BaseConnector(
            ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744),
            IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPoolDataProvider } from '../../interfaces/external/aave-v3/IPoolDataProvider.sol';
import { IPoolAddressesProvider } from '../../interfaces/external/aave-v3/IPoolAddressesProvider.sol';

import { AaveV3BaseConnector } from '../base/AaveV3.sol';

contract AaveV3Connector is AaveV3BaseConnector {
    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     */
    constructor()
        AaveV3BaseConnector(
            IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb),
            IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654),
            0
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IUniswapConnector } from '../interfaces/connectors/IUniswapConnector.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

contract UniswapConnector is IUniswapConnector {
    using UniversalERC20 for IERC20;

    /* ============ Constants ============ */

    string public constant name = 'UniswapAuto';

    /**
     * @dev UniswapV3 Auto Swap Router Address
     */
    address internal constant uniAutoRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the sender swap tokens.
     * @param account Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amount The amount of the token to sell.
     */
    event LogExchange(address indexed account, address toToken, address fromToken, uint256 amount);

    /* ============ External Functions ============ */

    /**
     * @dev Sell ETH/ERC20_Token using uniswap v3 auto router.
     * @notice Swap tokens from getting an optimized trade routes
     * @param _toToken The address of the token to buy.
     * @param _fromToken The address of the token to sell.
     * @param _amount The amount of the token to sell.
     * @param _callData Data from uniswap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount) {
        buyAmount = _swap(_toToken, _fromToken, _amount, _callData);
        emit LogExchange(msg.sender, _toToken, _fromToken, _amount);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Universal approve tokens to uniswap router and execute calldata.
     * @param _toToken The address of the token to buy.
     * @param _fromToken The address of the token to sell.
     * @param _amount The amount of the token to sell.
     * @param _callData Data from uniswap API.
     * @return buyAmount Returns the amount of tokens received.
     */
    function _swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) internal returns (uint256 buyAmount) {
        IERC20(_fromToken).universalApprove(uniAutoRouter, _amount);

        uint256 initalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        (bool success, bytes memory results) = uniAutoRouter.call(_callData);

        if (!success) {
            revert(string(results));
        }

        uint256 finalBalalance = IERC20(_toToken).universalBalanceOf(address(this));

        buyAmount = finalBalalance - initalBalalance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import './IAccessControl.sol';
import './Context.sol';
import './Strings.sol';
import './ERC165.sol';

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
                        'AccessControl: account ',
                        Strings.toHexString(account),
                        ' is missing role ',
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
        require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
                require(isContract(target), 'Address: call to non-contract');
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import './IERC165.sol';

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './IERC20.sol';
import './IERC20Metadata.sol';
import './Context.sol';

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
        require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
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
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, 'ERC20: transfer amount exceeds balance');
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
        require(account != address(0), 'ERC20: mint to the zero address');

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
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
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
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

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
            require(currentAllowance >= amount, 'ERC20: insufficient allowance');
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import './IERC20.sol';

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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import './Context.sol';

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

pragma solidity ^0.8.0;

import './IERC20.sol';
import './Address.sol';
import './IERC20Permit.sol';

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        require(nonceAfter == nonceBefore + 1, 'SafeERC20: permit did not succeed');
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

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import './Math.sol';

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = '0123456789abcdef';
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
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Emitted when the administration has been transferred.
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     * If it is, it will run the function. Otherwise, it will delegate the call
     * to the implementation.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * Only the current admin can call this function.
     * @param newAdmin Address to transfer proxy administration to.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), 'Cannot change the admin of a proxy to the zero address');
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @return adm The admin slot.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), 'Cannot set a proxy implementation to a non-contract address');

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), 'ERC1167: create failed');
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), 'ERC1167: create2 failed');
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, 'Contract instance has already been initialized');

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
    /**
     * Contract initializer.
     * @param logic address of the initial implementation.
     * @param admin Address of the proxy administrator.
     * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address logic, address admin, bytes memory data) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(logic, data);
        assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
        _setAdmin(admin);
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _beforeFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
        BaseAdminUpgradeabilityProxy._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract initializer.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract constructor.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IFlashReceiver } from '../interfaces/IFlashReceiver.sol';
import { IAaveFlashloan } from '../interfaces/connectors/IAaveFlashloan.sol';

import { ILendingPool } from '../interfaces/external/aave-v2/ILendingPool.sol';
import { IProtocolDataProvider } from '../interfaces/external/aave-v2/IProtocolDataProvider.sol';

import { BaseFlashloan } from './BaseFlashloan.sol';

contract AaveV2Flashloan is BaseFlashloan, IAaveFlashloan {
    /* ============ Constants ============ */

    /**
     * @dev Aave Lending Pool
     */
    ILendingPool internal constant aaveLending = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    IProtocolDataProvider public constant aaveProtocolDataProvider =
        IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    string public constant override name = 'AaveV2Flashloan';

    /* ============ External Functions ============ */

    /**
     * @dev Callback function for aave flashloan.
     * @param _assets list of asset addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets for flashloan.
     * @param _premiums list of premiums/fees for the corresponding addresses for flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _data extra data passed.
     */
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _premiums,
        address _initiator,
        bytes memory _data
    ) external override verifyDataHash(_data) returns (bool) {
        require(_initiator == address(this), 'not same sender');
        require(msg.sender == address(aaveLending), 'not aave sender');

        (address sender, bytes memory data) = abi.decode(_data, (address, bytes));

        address asset = _assets[0];
        uint256 amount = _amounts[0];
        uint256 fee = _premiums[0];

        uint256 initialBalance = getBalance(asset);

        safeApprove(asset, amount + fee, address(aaveLending));
        safeTransfer(asset, amount, sender);

        IFlashReceiver(sender).executeOperation(asset, amount, fee, sender, name, data);

        require(initialBalance + fee <= getBalance(asset), 'amount paid less');

        return true;
    }

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _token token addresses for flashloan.
     * @param _amount list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function flashLoan(address _token, uint256 _amount, bytes calldata _data) external override reentrancy {
        _flashLoan(_token, _amount, _data);
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     */
    function calculateFeeBPS() public view override returns (uint256 bps) {
        bps = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
    }

    /* ============ Internal Functions ============ */

    /**
     * @param _token token address for flashloan.
     * @param _amount amount for the corresponding assets or
     * amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
     */
    function _flashLoan(address _token, uint256 _amount, bytes memory _data) internal {
        bytes memory data = abi.encode(msg.sender, _data);
        _dataHash = bytes32(keccak256(data));

        address[] memory tokens = new address[](1);
        tokens[0] = _token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        aaveLending.flashLoan(address(this), tokens, amounts, modes, address(0), data, 0);
    }

    /**
     * @param _token token address for flashloan.
     * @param _amount amount for the corresponding assets or
     * amount of ether to borrow as collateral for flashloan.
     */
    function getAvailability(address _token, uint256 _amount) external view override returns (bool) {
        (, , , , , , , , bool isActive, ) = aaveProtocolDataProvider.getReserveConfigurationData(_token);
        (address aTokenAddr, , ) = aaveProtocolDataProvider.getReserveTokensAddresses(_token);
        if (isActive == false || IERC20(_token).balanceOf(aTokenAddr) < _amount) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IFlashReceiver } from '../interfaces/IFlashReceiver.sol';
import { IBalancerFlashloan } from '../interfaces/connectors/IBalancerFlashloan.sol';

import { IVault } from '../interfaces/external/balancer/IVault.sol';
import { IFlashLoanRecipient } from '../interfaces/external/balancer/IFlashLoanRecipient.sol';

import { BaseFlashloan } from './BaseFlashloan.sol';

contract BalancerFlashloan is IBalancerFlashloan, BaseFlashloan {
    /* ============ Constants ============ */

    /**
     * @dev Balancer Lending
     */
    IVault internal constant balancerLending = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    string public constant override name = 'BalancerFlashloan';

    /**
     * @dev Fallback function for balancer flashloan.
     * _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function receiveFlashLoan(
        address[] memory,
        uint256[] memory,
        uint256[] memory _fees,
        bytes memory _data
    ) external override verifyDataHash(_data) {
        require(msg.sender == address(balancerLending), 'not balancer sender');

        (address asset, uint256 amount, address sender, bytes memory data) = abi.decode(
            _data,
            (address, uint256, address, bytes)
        );

        uint256 fee = _fees[0];
        uint256 initialBalance = getBalance(asset);

        safeTransfer(asset, amount, sender);
        IFlashReceiver(sender).executeOperation(asset, amount, fee, sender, name, data);

        require(initialBalance + fee <= getBalance(asset), 'amount paid less');

        safeTransfer(asset, amount + fee, address(balancerLending));
    }

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _token token addresses for flashloan.
     * @param _amount list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function flashLoan(address _token, uint256 _amount, bytes calldata _data) external override reentrancy {
        _flashLoan(_token, _amount, _data);
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     */
    function calculateFeeBPS() public view override returns (uint256 bps) {
        bps = (balancerLending.getProtocolFeesCollector().getFlashLoanFeePercentage()) * 100;
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Middle function for route 3.
     * @param _token token addresses for flashloan.
     * @param _amount list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function _flashLoan(address _token, uint256 _amount, bytes memory _data) internal {
        bytes memory data = abi.encode(_token, _amount, msg.sender, _data);
        _dataHash = bytes32(keccak256(data));

        address[] memory tokens = new address[](1);
        tokens[0] = _token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        balancerLending.flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, data);
    }

    function getAvailability(address _token, uint256 _amount) external view override returns (bool) {
        if (IERC20(_token).balanceOf(address(balancerLending)) < _amount) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { IBaseFlashloan } from '../interfaces/IBaseFlashloan.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

abstract contract BaseFlashloan is IBaseFlashloan {
    using UniversalERC20 for IERC20;

    /* ============ State Variables ============ */

    // Has state 1 on the enter flashlaon and state 2 on the callback
    uint256 internal _status;

    // The hash of the date that is sent to the flashloan as an additional calldata
    bytes32 internal _dataHash;

    /* ============ Modifiers ============ */

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
     */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == _dataHash && dataHash_ != bytes32(0), 'invalid-data-hash');
        require(_status == 2, 'already-entered');
        _dataHash = bytes32(0);
        _;
        _status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
     */
    modifier reentrancy() {
        require(_status == 1, 'already-entered');
        _status = 2;
        _;
        require(_status == 1, 'already-entered');
    }

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @notice Sets the status to the default value
     */
    constructor() {
        require(_status == 0, 'cannot call again');
        _status = 1;
    }

    /* ============ External Functions ============ */

    receive() external payable {}

    /* ============ Public Functions ============ */

    /* ============ Internal Functions ============ */

    /**
     * @dev Approves the tokens to the receiver address with allowance (amount + fee).
     * @notice Approves the tokens to the receiver address with allowance (amount + fee).
     * @param _token token address for the respective tokens.
     * @param _amount balance for the respective tokens.
     * @param _receiver address to which tokens have to be approved.
     */
    function safeApprove(address _token, uint256 _amount, address _receiver) internal {
        IERC20(_token).universalApprove(_receiver, _amount);
    }

    /**
     * @dev Transfers the tokens to the receiver address (amount + fee).
     * @notice Transfers the tokens to the receiver address (amount + fee).
     * @param _token token address to calculate balance for.
     * @param _amount balance for the respective tokens.
     * @param _receiver address to which tokens have to be transferred.
     */
    function safeTransfer(address _token, uint256 _amount, address _receiver) internal {
        IERC20(_token).universalTransfer(_receiver, _amount);
    }

    /**
     * @dev Calculates the balances.
     * @notice Calculates the balances of the account passed for the tokens.
     * @param _token token address to calculate balance for.
     */
    function getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).universalBalanceOf(address(this));
    }

    /**
     * @dev Calculate fees for the respective amounts and fee in BPS passed.
     * @notice Calculate fees for the respective amounts and fee in BPS passed. 1 BPS == 0.01%.
     * @param _amount list of amounts.
     * @param _bps fee in BPS.
     */
    function calculateFee(uint256 _amount, uint256 _bps) internal pure returns (uint256) {
        return (_amount * _bps) / (10 ** 4);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IFlashReceiver } from '../interfaces/IFlashReceiver.sol';
import { IMakerFlashloan } from '../interfaces/connectors/IMakerFlashloan.sol';

import { IERC3156FlashLender } from '../interfaces/external/maker/IERC3156FlashLender.sol';
import { IERC3156FlashBorrower } from '../interfaces/external/maker/IERC3156FlashBorrower.sol';

import { BaseFlashloan } from './BaseFlashloan.sol';

contract MakerFlashloan is IMakerFlashloan, BaseFlashloan {
    /* ============ Constants ============ */

    /**
     * @dev Maker Lending
     */
    IERC3156FlashLender internal constant makerLending =
        IERC3156FlashLender(0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853);

    address public constant DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    string public constant override name = 'MakerFlashloan';

    /* ============ External Functions ============ */

    /**
     * @dev Fallback function for makerdao flashloan.
     * @param _initiator initiator address for flashloan.
     * _amount DAI amount for flashloan.
     * _fee fee for the flashloan.
     * @param _data extra data passed(includes route info aswell).
     */
    function onFlashLoan(
        address _initiator,
        address,
        uint256,
        uint256,
        bytes calldata _data
    ) external override verifyDataHash(_data) returns (bytes32) {
        require(_initiator == address(this), 'not same sender');
        require(msg.sender == address(makerLending), 'not maker sender');

        (address asset, uint256 amount, address sender, bytes memory data) = abi.decode(
            _data,
            (address, uint256, address, bytes)
        );

        uint256 fee = calculateFee(amount, calculateFeeBPS());
        uint256 initialBalance = getBalance(asset);

        safeApprove(asset, amount + fee, address(makerLending));
        safeTransfer(asset, amount, sender);

        IFlashReceiver(sender).executeOperation(asset, amount, fee, sender, name, data);

        require(initialBalance + fee <= getBalance(asset), 'amount paid less');

        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _token token addresses for flashloan.
     * @param _amount list of amounts for the corresponding assets.
     * @param _data extra data passed.
     */
    function flashLoan(address _token, uint256 _amount, bytes calldata _data) external override reentrancy {
        _flashLoan(_token, _amount, _data);
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     */
    function calculateFeeBPS() public view override returns (uint256 bps) {
        bps = (makerLending.toll()) / (10 ** 14);
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Middle function for route 2.
     * @param _token token address for flashloan(DAI).
     * @param _amount DAI amount for flashloan.
     * @param _data extra data passed.
     */
    function _flashLoan(address _token, uint256 _amount, bytes memory _data) internal {
        bytes memory data = abi.encode(_token, _amount, msg.sender, _data);
        _dataHash = bytes32(keccak256(data));
        makerLending.flashLoan(IERC3156FlashBorrower(address(this)), _token, _amount, data);
    }

    function getAvailability(address _token, uint256 _amount) external view override returns (bool) {
        if (_token == DAI_TOKEN) {
            return _amount <= makerLending.maxFlashLoan(DAI_TOKEN);
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAaveFlashloan {
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _premiums,
        address _initiator,
        bytes memory _data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAaveV2Connector {
    function name() external returns (string memory);

    function deposit(address _token, uint256 _amount) external payable;

    function withdraw(address _token, uint256 _amount) external payable;

    function borrow(address _token, uint256 _rateMode, uint256 _amount) external payable;

    function payback(address _token, uint256 _amount, uint256 _rateMode) external payable;

    function getPaybackBalance(address _token, uint _rateMode, address _user) external view returns (uint);

    function getCollateralBalance(address _token, address _user) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAaveV3Connector {
    function name() external returns (string memory);

    function deposit(address _token, uint256 _amount) external payable;

    function withdraw(address _token, uint256 _amount) external payable;

    function borrow(address _token, uint256 _rateMode, uint256 _amount) external payable;

    function payback(address _token, uint256 _amount, uint256 _rateMode) external payable;

    function getPaybackBalance(address _token, address _recipeint, uint256 _rateMode) external view returns (uint256);

    function getCollateralBalance(address _token, address _recipeint) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBalancerFlashloan {
    function receiveFlashLoan(address[] memory, uint256[] memory, uint256[] memory _fees, bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { CErc20Interface } from '../external/compound-v2/CTokenInterfaces.sol';

interface ICompoundV2Connector {
    function name() external returns (string memory);

    function deposit(address _token, uint256 _amount) external payable;

    function withdraw(address _token, uint256 _amount) external payable;

    function borrow(address _token, uint256 _amount) external payable;

    function payback(address _token, uint256 _amount) external payable;

    function borrowBalanceOf(address _token, address _recipient) external returns (uint256);

    function collateralBalanceOf(address _token, address _recipient) external returns (uint256);

    function _getCToken(address _token) external pure returns (CErc20Interface);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICompoundV3Connector {
    struct BorrowWithdrawParams {
        address _market;
        address _token;
        address from;
        address to;
        uint256 _amount;
    }

    struct BuyCollateralData {
        address _market;
        address sellToken;
        address buyAsset;
        uint256 unit_amount;
        uint256 baseSell_amount;
    }

    enum Action {
        REPAY,
        DEPOSIT
    }

    function name() external returns (string memory);

    function deposit(address _market, address _token, uint256 _amount) external payable;

    function borrowBalanceOf(address _market, address _recipient) external view returns (uint256);

    function collateralBalanceOf(address _market, address _recipient, address _token) external view returns (uint256);

    function withdraw(address _market, address _token, uint256 _amount) external payable;

    function borrow(address _market, address _token, uint256 _amount) external payable;

    function payback(address _market, address _token, uint256 _amount) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IInchV5Connector {
    function name() external returns (string memory);

    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IKyberConnector {
    function name() external returns (string memory);

    function swap(address _toToken, address _fromToken, uint256 _amount) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMakerFlashloan {
    function onFlashLoan(
        address _initiator,
        address,
        uint256,
        uint256,
        bytes calldata _data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IParaSwapConnector {
    function name() external returns (string memory);

    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapConnector {
    function name() external returns (string memory);

    function swap(
        address _toToken,
        address _fromToken,
        uint256 _amount,
        bytes calldata _callData
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ILendingPoolAddressesProvider } from './ILendingPoolAddressesProvider.sol';
import { DataTypes } from './DataTypes.sol';

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ILendingPoolAddressesProvider } from './ILendingPoolAddressesProvider.sol';

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(
        address asset
    )
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(
        address asset,
        address user
    )
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(
        address asset
    ) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
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

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPoolAddressesProvider } from './IPoolAddressesProvider.sol';
import { DataTypes } from './DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     */
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     */
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     */
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     */
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     * @return The backed amount
     */
    function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     */
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     */
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(
        address user
    )
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
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
     * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to aToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Configures a new category for the eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    /**
     * @notice Returns the data of an eMode category
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
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
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

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
     */
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
     */
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
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
     */
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
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPoolAddressesProvider } from './IPoolAddressesProvider.sol';

/**
 * @title IPoolDataProvider
 * @author Aave
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    /**
     * @notice Returns the address for the PoolAddressesProvider contract.
     * @return The address for the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the list of the existing reserves in the pool.
     * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
     * @return The list of reserves, pairs of symbols and addresses
     */
    function getAllReservesTokens() external view returns (TokenData[] memory);

    /**
     * @notice Returns the list of the existing ATokens in the pool.
     * @return The list of ATokens, pairs of symbols and addresses
     */
    function getAllATokens() external view returns (TokenData[] memory);

    /**
     * @notice Returns the configuration data of the reserve
     * @dev Not returning borrow and supply caps for compatibility, nor pause flag
     * @param asset The address of the underlying asset of the reserve
     * @return decimals The number of decimals of the reserve
     * @return ltv The ltv of the reserve
     * @return liquidationThreshold The liquidationThreshold of the reserve
     * @return liquidationBonus The liquidationBonus of the reserve
     * @return reserveFactor The reserveFactor of the reserve
     * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
     * @return borrowingEnabled True if borrowing is enabled, false otherwise
     * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
     * @return isActive True if it is active, false otherwise
     * @return isFrozen True if it is frozen, false otherwise
     */
    function getReserveConfigurationData(
        address asset
    )
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    /**
     * @notice Returns the efficiency mode category of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The eMode id of the reserve
     */
    function getReserveEModeCategory(address asset) external view returns (uint256);

    /**
     * @notice Returns the caps parameters of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return borrowCap The borrow cap of the reserve
     * @return supplyCap The supply cap of the reserve
     */
    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);

    /**
     * @notice Returns if the pool is paused
     * @param asset The address of the underlying asset of the reserve
     * @return isPaused True if the pool is paused, false otherwise
     */
    function getPaused(address asset) external view returns (bool isPaused);

    /**
     * @notice Returns the siloed borrowing flag
     * @param asset The address of the underlying asset of the reserve
     * @return True if the asset is siloed for borrowing
     */
    function getSiloedBorrowing(address asset) external view returns (bool);

    /**
     * @notice Returns the protocol fee on the liquidation bonus
     * @param asset The address of the underlying asset of the reserve
     * @return The protocol fee on liquidation
     */
    function getLiquidationProtocolFee(address asset) external view returns (uint256);

    /**
     * @notice Returns the unbacked mint cap of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The unbacked mint cap of the reserve
     */
    function getUnbackedMintCap(address asset) external view returns (uint256);

    /**
     * @notice Returns the debt ceiling of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The debt ceiling of the reserve
     */
    function getDebtCeiling(address asset) external view returns (uint256);

    /**
     * @notice Returns the debt ceiling decimals
     * @return The debt ceiling decimals
     */
    function getDebtCeilingDecimals() external pure returns (uint256);

    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return unbacked The amount of unbacked tokens
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalAToken The total supply of the aToken
     * @return totalStableDebt The total stable debt of the reserve
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return stableBorrowRate The stable borrow rate of the reserve
     * @return averageStableBorrowRate The average stable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     */
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    /**
     * @notice Returns the total supply of aTokens for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total supply of the aToken
     */
    function getATokenTotalSupply(address asset) external view returns (uint256);

    /**
     * @notice Returns the total debt for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total debt for asset
     */
    function getTotalDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the user data in a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param user The address of the user
     * @return currentATokenBalance The current AToken balance of the user
     * @return currentStableDebt The current stable debt of the user
     * @return currentVariableDebt The current variable debt of the user
     * @return principalStableDebt The principal stable debt of the user
     * @return scaledVariableDebt The scaled variable debt of the user
     * @return stableBorrowRate The stable borrow rate of the user
     * @return liquidityRate The liquidity rate of the reserve
     * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
     * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
     *         otherwise
     */
    function getUserReserveData(
        address asset,
        address user
    )
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    /**
     * @notice Returns the token addresses of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return aTokenAddress The AToken address of the reserve
     * @return stableDebtTokenAddress The StableDebtToken address of the reserve
     * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
     */
    function getReserveTokensAddresses(
        address asset
    ) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);

    /**
     * @notice Returns the address of the Interest Rate strategy
     * @param asset The address of the underlying asset of the reserve
     * @return irStrategyAddress The address of the Interest Rate strategy
     */
    function getInterestRateStrategyAddress(address asset) external view returns (address irStrategyAddress);

    /**
     * @notice Returns whether the reserve has FlashLoans enabled or disabled
     * @param asset The address of the underlying asset of the reserve
     * @return True if FlashLoans are enabled, false otherwise
     */
    function getFlashLoanEnabled(address asset) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './IFlashLoanRecipient.sol';

interface ProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}

interface IVault {
    // Flash Loans
    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, address indexed token, uint256 amount, uint256 feeAmount);

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);

    function exitMarket(address cToken) external returns (uint);

    function getAssetsIn(address account) external view returns (address[] memory);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);

    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);

    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);

    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external returns (uint);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);

    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ComptrollerInterface.sol';
import './InterestRateModel.sol';
import './EIP20NonStandardInterface.sol';

interface CTokenInterface {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint repayAmount,
        address cTokenCollateral,
        uint seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function exchangeRateCurrent() external returns (uint);

    function exchangeRateStored() external view returns (uint);

    function getCash() external view returns (uint);

    function accrueInterest() external returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function underlying() external returns (address);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);

    function _acceptAdmin() external returns (uint);

    function _setComptroller(ComptrollerInterface newComptroller) external returns (uint);

    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);

    function _reduceReserves(uint reduceAmount) external returns (uint);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint);
}

interface CErc20Interface is CTokenInterface {
    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        CTokenInterface cTokenCollateral
    ) external returns (uint);

    function sweepToken(EIP20NonStandardInterface token) external;

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}

interface CDelegatorInterface {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;
}

interface CDelegateInterface {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
    function isInterestRateModel() external returns (bool);

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactorMantissa
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Compound's Comet Ext Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
interface ICometExtInterface {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function allow(address manager, bool isAllowed) external;

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    function baseTrackingAccrued(address account) external view returns (uint64);

    function baseAccrualScale() external view returns (uint64);

    function baseIndexScale() external view returns (uint64);

    function factorScale() external view returns (uint64);

    function priceScale() external view returns (uint64);

    function maxAssets() external view returns (uint8);

    // function totalsBasic() external view  returns (TotalsBasic memory);

    function version() external view returns (string memory);

    /**
     * ===== ERC20 interfaces =====
     * Does not include the following functions/events, which are defined in `CometMainInterface` instead:
     * - function decimals()  external view returns (uint8)
     * - function totalSupply()  external view returns (uint256)
     * - function transfer(address dst, uint amount)  external returns (bool)
     * - function transferFrom(address src, address dst, uint amount)  external returns (bool)
     * - function balanceOf(address owner)  external view returns (uint256)
     * - event Transfer(address indexed from, address indexed to, uint256 amount)
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
interface IComet is ICometExtInterface {
    function supply(address asset, uint amount) external;

    function supplyTo(address dst, address asset, uint amount) external;

    function supplyFrom(address from, address dst, address asset, uint amount) external;

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function transferAsset(address dst, address asset, uint amount) external;

    function transferAssetFrom(address src, address dst, address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function withdrawTo(address to, address asset, uint amount) external;

    function withdrawFrom(address src, address to, address asset, uint amount) external;

    function approveThis(address manager, address asset, uint amount) external;

    function withdrawReserves(address to, uint amount) external;

    function absorb(address absorber, address[] calldata accounts) external;

    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) external;

    function quoteCollateral(address asset, uint baseAmount) external view returns (uint);

    function getCollateralReserves(address asset) external view returns (uint);

    function getReserves() external view returns (int);

    function getPrice(address priceFeed) external view returns (uint);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external;

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function isAbsorbPaused() external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function accrueAccount(address account) external;

    function getSupplyRate(uint utilization) external view returns (uint64);

    function getBorrowRate(uint utilization) external view returns (uint64);

    function getUtilization() external view returns (uint);

    function governor() external view returns (address);

    function pauseGuardian() external view returns (address);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function extensionDelegate() external view returns (address);

    function userCollateral(address, address) external returns (UserCollateral memory);

    /// @dev uint64
    function supplyKink() external view returns (uint);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint);

    /// @dev uint64
    function borrowKink() external view returns (uint);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint);

    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint);

    /// @dev uint64
    function baseScale() external view returns (uint);

    /// @dev uint64
    function trackingIndexScale() external view returns (uint);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint);

    /// @dev uint104
    function baseMinForRewards() external view returns (uint);

    /// @dev uint104
    function baseBorrowMin() external view returns (uint);

    /// @dev uint104
    function targetReserves() external view returns (uint);

    function numAssets() external view returns (uint8);

    function decimals() external view returns (uint8);

    function initializeStorage() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IKyber {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns (uint);

    function getExpectedRate(address src, address dest, uint srcQty) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './IERC3156FlashBorrower.sol';

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    // state variables
    function toll() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAugustusSwapper {
    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from 'lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DataTypes } from '../lib/DataTypes.sol';

import { IFlashReceiver } from './IFlashReceiver.sol';
import { IAddressesProvider } from './IAddressesProvider.sol';

interface IAccount is IFlashReceiver {
    function initialize(address _user, IAddressesProvider _provider) external;

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

    function openPositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external;

    function closePositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external;

    function claimTokens(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

    function getFlashloanAggregator() external view returns (address);

    function getTreasury() external view returns (address);

    function getAccountImpl() external view returns (address);

    function getAccountProxy() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBaseFlashloan {
    function name() external returns (string memory);

    function flashLoan(address _token, uint256 _amount, bytes calldata _data) external;

    function calculateFeeBPS() external view returns (uint256 bps);

    function getAvailability(address _token, uint256 _amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IConfigurator {
    function setFee(uint256 _fee) external;

    function addConnectors(string[] calldata _names, address[] calldata _addresses) external;

    function updateConnectors(string[] calldata _names, address[] calldata _addresses) external;

    function removeConnectors(string[] calldata _names) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IConnector {
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IConnectors {
    function addConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function updateConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function removeConnectors(string[] calldata _names) external;

    function isConnector(string calldata _name) external view returns (bool isOk, address _connector);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFlashReceiver {
    function executeOperation(
        address _token,
        uint256 _amount,
        uint256 _fee,
        address _initiator,
        string memory _targetName,
        bytes calldata _params
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DataTypes } from '../lib/DataTypes.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Errors } from '../lib/Errors.sol';

import { IConnectors } from '../interfaces/IConnectors.sol';
import { IAddressesProvider } from '../interfaces/IAddressesProvider.sol';

library ConnectorsCall {
    /**
     * @dev They will check if the target is a finite connector, and if it is, they will call it.
     * @param _provider Addresses provider contract address.
     * @param _targetName Name of the connector.
     * @param _data Execute calldata.
     * @return response Returns the result of calling the calldata.
     */
    function connectorCall(
        IAddressesProvider _provider,
        string memory _targetName,
        bytes memory _data
    ) internal returns (bytes memory response) {
        address connectors = _provider.getConnectors();
        require(connectors != address(0), Errors.ADDRESS_IS_ZERO);
        response = _connectorCall(connectors, _targetName, _data);
    }

    /**
     * @dev They will check if the target is a finite connector, and if it is, they will call it.
     * @param _connectors Main connectors contract.
     * @param _targetName Name of the connector.
     * @param _data Execute calldata.
     * @return response Returns the result of calling the calldata.
     */
    function _connectorCall(
        address _connectors,
        string memory _targetName,
        bytes memory _data
    ) private returns (bytes memory response) {
        (bool isOk, address _target) = IConnectors(_connectors).isConnector(_targetName);
        require(isOk, Errors.NOT_CONNECTOR);
        response = _delegatecall(_target, _data);
    }

    /**
     * @dev Delegates the current call to `target`.
     * @param _target Name of the connector.
     * @param _data Execute calldata.
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegatecall(address _target, bytes memory _data) private returns (bytes memory response) {
        require(_target != address(0), Errors.INVALID_CONNECTOR_ADDRESS);
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title PercentageMath library
 * @author FlashFlow
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    function mulTo(uint256 _amount, uint256 _leverage) internal pure returns (uint256 amount) {
        amount = (_amount * _leverage) / PERCENTAGE_FACTOR;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from '../dependencies/openzeppelin/contracts/ERC20.sol';
import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';
import { SafeERC20 } from '../dependencies/openzeppelin/contracts/SafeERC20.sol';

library UniversalERC20 {
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(to).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, 'Wrong useage of ETH.universalTransferFrom()');
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 10000 }(
            abi.encodeWithSignature('decimals()')
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{ gas: 10000 }(abi.encodeWithSignature('DECIMALS()'));
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function universalSymbol(IERC20 token) internal view returns (string memory) {
        if (isETH(token)) {
            return 'ETH';
        } else {
            return ERC20(address(token)).symbol();
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Singleton Factory (EIP-2470)
 * @notice Exposes CREATE2 (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract SingletonFactory {
    /**
     * @notice Deploys `_initCode` using `_salt` for defining the deterministic address.
     * @param _initCode Initialization code.
     * @param _salt Arbitrary value to modify resulting address.
     * @return createdContract Created contract address.
     */
    function deploy(bytes memory _initCode, bytes32 _salt) public returns (address payable createdContract) {
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), _salt)
        }
    }
}
// IV is a value changed to generate the vanity address.
// IV: 6583047

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from '../dependencies/openzeppelin/contracts/ERC20.sol';

contract ERC20Mock is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address initialAccount,
        uint256 initialBalance
    ) payable ERC20(_name, _symbol) {
        _mint(initialAccount, initialBalance);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferInternal(address from, address to, uint256 value) public {
        _transfer(from, to, value);
    }

    function approveInternal(address owner, address spender, uint256 value) public {
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

import { UniversalERC20 } from '../lib/UniversalERC20.sol';

interface IWeth {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

abstract contract EthConverter {
    using UniversalERC20 for IERC20;

    IWeth internal constant wethAddr = IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function convertEthToWeth(address token, uint amount) internal {
        if (IERC20(token).isETH()) {
            wethAddr.deposit{ value: amount }();
        }
    }

    function convertWethToEth(address token, uint amount) internal {
        if (token == address(wethAddr)) {
            IERC20(token).universalApprove(address(wethAddr), amount);
            wethAddr.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';
import { Errors } from './lib/Errors.sol';

/**
 * @title Proxy
 * @author FlashFlow
 * @notice Contract used as proxy for the user account.
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract Proxy {
    // The contract by which all other contact addresses are obtained.
    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    constructor(address _provider) {
        ADDRESSES_PROVIDER = IAddressesProvider(_provider);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Delegates the current call to the address returned by `getImplementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        address _implementation = ADDRESSES_PROVIDER.getAccountImpl();
        require(_implementation != address(0), Errors.INVALID_IMPLEMENTATION_ADDRESS);
        _delegate(_implementation);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `getImplementation()`.
     * Will run if no other function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `getImplementation()`.
     * Will run if call data is empty.
     */
    receive() external payable {
        _fallback();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from './dependencies/openzeppelin/contracts/IERC20.sol';
import { Clones } from './dependencies/openzeppelin/upgradeability/Clones.sol';
import { VersionedInitializable } from './dependencies/upgradeability/VersionedInitializable.sol';

import { Errors } from './lib/Errors.sol';
import { DataTypes } from './lib/DataTypes.sol';
import { ConnectorsCall } from './lib/ConnectorsCall.sol';
import { PercentageMath } from './lib/PercentageMath.sol';
import { UniversalERC20 } from './lib/UniversalERC20.sol';

import { IRouter } from './interfaces/IRouter.sol';
import { IAccount } from './interfaces/IAccount.sol';
import { IConnectors } from './interfaces/IConnectors.sol';
import { IAddressesProvider } from './interfaces/IAddressesProvider.sol';

/**
 * @title Router contract
 * @author FlashFlow
 * @notice Main point of interaction with an FlashFlow protocol
 * - Users can:
 *   # Open position
 *   # Close position
 *   # Swap their tokens
 *   # Create acconut
 */
contract Router is VersionedInitializable, IRouter {
    using UniversalERC20 for IERC20;
    using ConnectorsCall for IAddressesProvider;
    using PercentageMath for uint256;

    /* ============ Immutables ============ */

    // The contract by which all other contact addresses are obtained.
    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    /* ============ Constants ============ */

    uint256 public constant ROUTER_REVISION = 0x2;

    /* ============ State Variables ============ */

    // Fee of the protocol, expressed in bps
    uint256 public override fee;

    // Count of user position
    mapping(address => uint256) public override positionsIndex;

    // Map of key (user address and position index) to position (key => postion)
    mapping(bytes32 => DataTypes.Position) public override positions;

    // Map of users address and their account (userAddress => userAccount)
    mapping(address => address) public override accounts;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the account will be created.
     * @param account The address of the Account contract.
     * @param owner The address of the owner account.
     */
    event AccountCreated(address indexed account, address indexed owner);

    /**
     * @dev Emitted when the sender swap tokens.
     * @param sender Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amountIn The amount of the token to sell.
     * @param amountOut The amount of the token transfer to sender.
     * @param connectorName Conenctor name.
     */
    event SwapTokens(
        address indexed sender,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut,
        string connectorName
    );

    /**
     * @dev Emitted when the user open position.
     * @param key The key to obtain the current position.
     * @param account The address of the owner position.
     * @param index Count current position.
     * @param position The structure of the current position.
     */
    event OpenPosition(bytes32 indexed key, address indexed account, uint256 index, DataTypes.Position position);

    /**
     * @dev Emitted when the user close position.
     * @param key The key to obtain the current position.
     * @param account The address of the owner position.
     * @param position The structure of the current position.
     */
    event ClosePosition(bytes32 indexed key, address indexed account, DataTypes.Position position);

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
     * @param _provider The address of the AddressesProvider contract
     */
    constructor(IAddressesProvider _provider) {
        require(address(_provider) != address(0), Errors.ADDRESS_IS_ZERO);
        ADDRESSES_PROVIDER = _provider;
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the Router.
     * @dev Function is invoked by the proxy contract when the Router contract is added to the
     * AddressesProvider.
     * @dev Caching the address of the AddressesProvider in order to reduce gas consumption on subsequent operations
     * @param _provider The address of the AddressesProvider
     */
    function initialize(address _provider) external virtual initializer {
        require(_provider == address(ADDRESSES_PROVIDER), Errors.INVALID_ADDRESSES_PROVIDER);
        fee = 50; // 0.5%
    }

    /* ============ External Functions ============ */

    /**
     * @notice Set a new fee to the router contract.
     * @param _fee The new amount
     */
    function setFee(uint256 _fee) external override onlyConfigurator {
        require(_fee > 0, Errors.INVALID_FEE_AMOUNT);
        fee = _fee;
    }

    /**
     * @dev Exchanges the input token for the necessary token to create a position and opens it.
     * @param _position The structure of the current position.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     * @param _params The additional parameters needed to the exchange.
     */
    function swapAndOpen(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data,
        SwapParams memory _params
    ) external payable override {
        _position.amountIn = _swap(_params);
        _openPosition(_position, _targetName, _data);
    }

    /**
     * @dev Create a position on the lendings protocol.
     * @param _position The structure of the current position.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external override {
        IERC20(_position.debt).universalTransferFrom(msg.sender, address(this), _position.amountIn);
        _openPosition(_position, _targetName, _data);
    }

    /**
     * @dev Сloses the user's position and deletes it.
     * @param _key The key to obtain the current position.
     * @param _token Flashloan token.
     * @param _amount Flashloan amount.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external override {
        DataTypes.Position memory position = positions[_key];
        require(msg.sender == position.account, Errors.CALLER_NOT_POSITION_OWNER);

        address account = accounts[msg.sender];
        require(account != address(0), Errors.ACCOUNT_DOES_NOT_EXIST);

        IAccount(account).closePosition(_key, _token, _amount, _targetName, _data);

        emit ClosePosition(_key, account, position);
        delete positions[_key];
    }

    /**
     * @dev Exchanges tokens and sends them to the sender, an auxiliary function for the user interface.
     * @param _params parameters required for the exchange.
     */
    function swap(SwapParams memory _params) external payable override {
        uint256 initialBalance = IERC20(_params.toToken).universalBalanceOf(address(this));
        uint256 value = _swap(_params);
        uint256 finalBalance = IERC20(_params.toToken).universalBalanceOf(address(this));
        require(finalBalance - initialBalance == value, 'value is not valid');

        IERC20(_params.toToken).universalTransfer(msg.sender, value);

        emit SwapTokens(msg.sender, _params.fromToken, _params.toToken, _params.amount, value, _params.targetName);
    }

    /**
     * @dev Updates the current positions required for the callback.
     * @param _position The structure of the current position.
     */
    function updatePosition(DataTypes.Position memory _position) external override {
        address account = _position.account;
        require(msg.sender == accounts[account], Errors.CALLER_NOT_ACCOUNT_OWNER);

        bytes32 key = getKey(account, positionsIndex[account]);
        positions[key] = _position;
    }

    // solhint-disable-next-line
    receive() external payable {}

    /* ============ Public Functions ============ */

    /**
     * @dev Checks if the user has an account otherwise creates and initializes it.
     * @param _owner User address.
     * @return Returns of the user account address.
     */
    function getOrCreateAccount(address _owner) public override returns (address) {
        require(_owner == msg.sender, Errors.CALLER_NOT_ACCOUNT_OWNER);
        address _account = address(accounts[_owner]);

        if (_account == address(0)) {
            _account = Clones.cloneDeterministic(
                ADDRESSES_PROVIDER.getAccountProxy(),
                bytes32(abi.encodePacked(_owner))
            );
            accounts[_owner] = _account;
            IAccount(_account).initialize(_owner, ADDRESSES_PROVIDER);
            emit AccountCreated(_account, _owner);
        }

        return _account;
    }

    /**
     * @dev Create position key.
     * @param _account Position account owner.
     * @param _index Position count account owner.
     * @return Returns the position key
     */
    function getKey(address _account, uint256 _index) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    /**
     * @dev Returns the future address of the account created through create2, necessary for the user interface.
     * @param _owner User account address, convert to salt.
     * @return predicted Returns of the user account address.
     */
    function predictDeterministicAddress(address _owner) public view override returns (address predicted) {
        return
            Clones.predictDeterministicAddress(
                ADDRESSES_PROVIDER.getAccountProxy(),
                bytes32(abi.encodePacked(_owner)),
                address(this)
            );
    }

    /**
     * @dev Calculates and returns the current commission depending on the amount.
     * @param _amount Amount
     * @return feeAmount Returns the protocol fee amount.
     */
    function getFeeAmount(uint256 _amount) public view override returns (uint256 feeAmount) {
        require(_amount > 0, Errors.INVALID_CHARGE_AMOUNT);
        feeAmount = _amount.mulTo(fee);
    }

    /* ============ Private Functions ============ */

    /**
     * @dev Create user account if user doesn't have it. Update position index and position state.
     * Call openPosition on the user account proxy contract.
     */
    function _openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) private {
        require(_position.account == msg.sender, Errors.CALLER_NOT_POSITION_OWNER);
        require(_position.leverage > PercentageMath.PERCENTAGE_FACTOR, Errors.LEVERAGE_IS_INVALID);

        address account = getOrCreateAccount(msg.sender);

        address owner = _position.account;
        uint256 index = positionsIndex[owner] += 1;
        positionsIndex[owner] = index;

        bytes32 key = getKey(owner, index);
        positions[key] = _position;

        IERC20(_position.debt).universalApprove(account, _position.amountIn);
        IAccount(account).openPosition(_position, _targetName, _data);

        // Get the position on the key because, update it in the process of creating
        emit OpenPosition(key, account, index, positions[key]);
    }

    /**
     * @dev Internal function for the exchange, sends tokens to the current contract.
     * @param _params parameters required for the exchange.
     * @return value  Returns the amount of tokens received.
     */
    function _swap(SwapParams memory _params) private returns (uint256 value) {
        IERC20(_params.fromToken).universalTransferFrom(msg.sender, address(this), _params.amount);
        bytes memory response = ADDRESSES_PROVIDER.connectorCall(_params.targetName, _params.data);
        value = abi.decode(response, (uint256));
    }

    /**
     * @notice Returns the version of the Router contract.
     * @return The version is needed to update the proxy.
     */
    function getRevision() internal pure override returns (uint256) {
        return ROUTER_REVISION;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}