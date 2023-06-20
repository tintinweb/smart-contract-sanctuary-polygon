// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../contracts/interfaces/IAuth.sol";

contract AuthMock {
    bytes32 private constant _MASTER_ROLE = 0x00;
    bytes32 private constant _GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 private constant _INTEGRATOR_ADMIN_ROLE = keccak256("INTEGRATOR_ADMIN_ROLE");
    bytes32 private constant _EVENT_FACTORY_ROLE = keccak256("EVENT_FACTORY_ROLE");
    bytes32 private constant _EVENT_ROLE = keccak256("EVENT_ROLE");
    bytes32 private constant _FUEL_DISTRIBUTOR_ROLE = keccak256("FUEL_DISTRIBUTOR_ROLE");
    bytes32 private constant _RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant _TOP_UP_ROLE = keccak256("TOP_UP_ROLE");
    bytes32 private constant _CUSTODIAL_TOP_UP_ROLE = keccak256("CUSTODIAL_TOP_UP_ROLE");
    bytes32 private constant _PRICE_ORACLE_ROLE = keccak256("PRICE_ORACLE_ROLE");
    bytes32 private constant _ROUTER_REGISTRY_ROLE = keccak256("_ROUTER_REGISTRY_ROLE");
    bytes32 private constant _ECONOMICS_FACTORY_ROLE = keccak256("_ECONOMICS_FACTORY_ROLE");
    bytes32 private constant _FUEL_ROUTER_ROLE = keccak256("FUEL_ROUTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /**
     * @dev Filters out accounts without a specific role in question
     * @param role Role being checked for
     * @param sender Account under scrutiny
     */
    modifier senderHasRole(bytes32 role, address sender) {
        _;
    }

    function senderProtected(bytes32 _roleId) external view {}

    /**
     * @notice Checks for a _GOVERNANCE_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasGovernanceRole(address _sender) external view {}

    /**
     * @notice Checks for an _INTEGRATOR_ADMIN_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasIntegratorAdminRole(address _sender) external view {}

    /**
     * @notice Checks for a _EVENT_FACTORY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEventFactoryRole(address _sender) external view {}

    /**
     * @notice Checks for a _ECONOMICS_FACTORY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEconomicsFactoryRole(address _sender) external view {}

    /**
     * @notice Checks for a _RELAYER_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasRelayerRole(address _sender) external view {}

    /**
     * @notice Checks for an _EVENT_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasEventRole(address _sender) external view {}

    /**
     * @notice Checks for a _TOP_UP_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasTopUpRole(address _sender) external view {}

    /**
     * @notice Checks for a _CUSTODIAL_TOP_UP_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasCustodialTopUpRole(address _sender) external view {}

    /**
     * @notice Checks for a _PRICE_ORACLE_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasPriceOracleRole(address _sender) external view {}

    /**
     * @notice Checks for a _FUEL_DISTRIBUTOR_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasFuelDistributorRole(address _sender) external view {}

    /**
     * @notice Checks for a _FUEL_ROUTER_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasFuelRouterRole(address _sender) external view {}

    /**
     * @notice Checks for a _ROUTER_REGISTRY_ROLE on an address
     * @param _sender address under scrutiny
     */
    function hasRouterRegistryRole(address _sender) external view {}

    /**
     * @notice Grants an address an _EVENT_ROLE
     * @dev Only Event contracts are granted an _EVENT_ROLE
     * @param _event Event contract address
     */
    function grantEventRole(address _event) public {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IAuth is IAccessControlUpgradeable {
    function addIntegratorAdminToIndex(address, uint256) external;

    function removeIntegratorAdmin(address) external;

    function hasProtocolDAORole(address) external view;

    function hasEconomicsConfigurationRole(address, uint256) external view;

    function hasEventFinancingConfigurationRole(address, uint256) external view;

    function hasIntegratorAdminRole(address) external view;

    function hasEventFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasFuelDistributorRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function grantEventRole(address) external;

    function hasRouterRegistryRole(address) external view;

    function hasFuelRouterRole(address) external view;

    function hasEconomicsFactoryRole(address _sender) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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