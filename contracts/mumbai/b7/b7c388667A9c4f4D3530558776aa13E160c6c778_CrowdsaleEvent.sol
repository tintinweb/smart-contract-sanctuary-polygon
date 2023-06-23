// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";

/**
 * EVE01: Crowdsale does not exist
 * EVE02: Sender is not crowdsale contract
 * EVE03: Sender is not factory crowdsale contract
 */
contract CrowdsaleEvent {
  address public addressRegistry;

  event RegistryAddressUpdated(address newRoleAddress);

  event TokenPurchase(
    address indexed sale,
    bytes32 indexed id,
    address indexed beneficiary,
    address paymentToken,
    address securityToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  );

  event Refund(
    address indexed sale,
    address paymentToken,
    bytes32[] indexed id,
    address[] indexed beneficiary,
    uint256[] paymentAmt
  );
  event Distribute(
    address indexed sale,
    address securityToken,
    bytes32[] indexed id,
    address[] indexed beneficiary,
    uint256[] purchasedAmt
  );

  mapping(address => bool) saleExists;

  constructor(address addressRegistry_) {
    addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  bytes32 public constant CROWDSALE_ADMINISTRATOR_ROLE = keccak256("CROWDSALE_ADMINISTRATOR_ROLE");

  function tokenPurchaseEvent(
    bytes32 id,
    address contributor,
    address paymentToken,
    address securityToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit TokenPurchase(
      msg.sender,
      id,
      contributor,
      paymentToken,
      securityToken,
      purchasedAmt,
      initialPaymentAmt,
      nativePaymentAmt
    );
  }

  function refundEvent(
    address paymentToken,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata nativePaymentAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit Refund(msg.sender, paymentToken, ids, beneficiaries, nativePaymentAmt);
  }

  function distributeEvent(
    address token,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata purchasedAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit Distribute(msg.sender, token, ids, beneficiaries, purchasedAmt);
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function setCrowdsaleExists(address addr) public {
    address crowdsaleFactory = IAddressRegistry(addressRegistry).getCrowdsaleFactAddr();
    require(msg.sender == crowdsaleFactory, "EVE03");
    saleExists[addr] = true;
  }

  function unsetCrowdsaleExists(address addr) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    saleExists[addr] = false;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.7;

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

  function grantRoleByAdministrator(bytes32 role, address account) external;

  function revokeRoleByAdministrator(bytes32 role, address account) external;

  function convertIntoBytes(string memory role) external view returns (bytes32);
}