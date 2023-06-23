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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * SETE01: SecurityToken does not exist
 */
contract SettlementEvent {
  address public addressRegistry;

  event DividendDistribution(
    address indexed security,
    address indexed settlementToken,
    address[] beneficiaries,
    uint256[] amounts
  );
  event RegistryAddressUpdated(address newRoleAddress);

  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");

  constructor(address addressRegistry_) {
    addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _accessControlAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require(IAccessControl(_accessControlAddress).hasRole(_role, msg.sender));
    _;
  }

  function settlementDistribution(
    address settlementToken,
    address[] memory beneficiaries,
    uint256[] memory amounts
  ) public {
    address registry = IAddressRegistry(addressRegistry).getTokenRegAddr();
    bool exists = ITokenRegistry(registry).securityTokenExists(msg.sender);
    require(exists, "SETE01");
    emit DividendDistribution(msg.sender, settlementToken, beneficiaries, amounts);
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0) && newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }
}

pragma solidity ^0.8.19;

/**
 * @title IAddressRegistry
 * @dev IAddressRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * ADDR01: Cannot set the same value as new value
 *
 */

interface IAddressRegistry {
  function REGISTRY_MANAGEMENT_ROLE() external view returns (bytes32);

  function getCrowdsaleFactAddr() external view returns (address);

  function getTokenFactAddr() external view returns (address);

  function getCrowdsaleEventAddr() external view returns (address);

  function getSettlementEventAddr() external view returns (address);

  function getStableSwapEvent() external view returns (address);

  function getMarketAddr() external view returns (address);

  function getPriceFeedAddr() external view returns (address);

  function getRoleRegAddr() external view returns (address);

  function getPairFactoryAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function getUserRegAddr() external view returns (address);

  function setCrowdsaleFactAddr(address newAddr) external;

  function setTokenFactAddr(address newAddr) external;

  function setCrowdsaleEventAddr(address newAddr) external;

  function setMarketAddr(address newAddr) external;

  function setPriceFeedAddr(address newAddr) external;

  function setRoleRegAddr(address newAddr) external;

  function setPairFactoryAddr(address newAddr) external;

  function setTokenRegAddr(address newAddr) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ITokenRegistry {
  function ORACLE_ADMIN_ROLE() external view returns (bytes32);

  function add(address key, bool isStab) external;

  function blockListSec(address key) external;

  function blockListStab(address key) external;

  function delSec(address key) external;

  function delStab(address key) external;

  function getSettlementAddr() external view returns (address);

  function securityTokenExists(address key) external view returns (bool);

  function getSec(address key) external view returns (string memory, string memory, bool, bool);

  function getStab(address key) external view returns (string memory, string memory, bool, bool);

  function getTokenAddrAtIndex(uint256 id, bool isStab) external view returns (address);

  function getStabArrSize() external view returns (uint256);

  function pauseSec(address key) external;

  function pauseStab(address key) external;

  function unBlockListSec(address key) external;

  function unBlockListStab(address key) external;

  function unPauseSec(address key) external;

  function unPauseStab(address key) external;

  function getStableAddress(string memory symbol) external view returns (address);

  function getDecimals(address token) external view returns (uint8);
}