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
import "../registry/IAddressRegistry.sol";

/**
 * EVE01: Crowdsale does not exist
 * EVE02: Sender is not crowdsale contract
 * EVE03: Sender is not factory crowdsale contract
 */
contract CrowdsaleEvent {
  address internal  addressRegistry;

  event RegistryAddressUpdated(address newRoleAddress);
  event TokenPurchase(
    bool            isFiatPayment,
    address indexed sale,
    address indexed securityToken,
    address indexed beneficiary,
    uint256         purchasedAmt,
    uint256         paymentAmt
  );
  event Distribution(
    address indexed sale,
    address indexed securityToken,
    address[]       beneficiaries,
    uint256[]       purchasedAmt,
    uint256[]       investeAmt
  );
  event Refund(
    address indexed sale,
    address[]       beneficiaries,
    uint256[]       amounts
  );

  event RefundAmountFor(
    address sale,
    address beneficiary,
    uint256 amount
  );

  mapping(address => bool) saleExists;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  constructor(address addressRegistry_) {
     addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _accessControlAddress = getRoleAddr();
    require(IAccessControl(_accessControlAddress).hasRole(_role, msg.sender));
    _;
  }

  modifier onlyCrowdsale() {
    require(saleExists[msg.sender], "EVE01");
    _;
  }

  function tokenPurchaseEvent(
    bool paymentType,
    address securityToken,
    address beneficiary,
    uint256 purchasedAmt,
    uint256 paymentAmt
  ) public onlyCrowdsale(){
    emit TokenPurchase(
      paymentType,
      msg.sender,
      securityToken,
      beneficiary,
      purchasedAmt,
      paymentAmt
    );
  }
  function distributionEvent(
    address securityToken,
    address[] memory beneficiaries,
    uint256[] memory purchasedAmt,
    uint256[] memory investedAmt
  ) public onlyCrowdsale(){
    emit Distribution(
      securityToken,
      msg.sender,
      beneficiaries,
      purchasedAmt,
      investedAmt
    );
  }
  function refundEvent(
    address[] memory beneficiaries,
    uint256[] memory amount
  ) public onlyCrowdsale(){
    emit Refund(
      msg.sender,
      beneficiaries,
      amount
    );
  }

  function refundAmountFor(
    address beneficiary,
    uint256 amount
  ) public onlyCrowdsale(){
    emit RefundAmountFor(
      msg.sender,
      beneficiary,
      amount
    );
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(
    address newAddress
  ) external onlyRole(MANAGER_ROLE) {
    require(newAddress != address(0) && newAddress !=  addressRegistry);
     addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function setCrowdsaleExists(
    address addr,
    bool choice
    ) external {
      address _accessControlAddress = getRoleAddr();
      require(_isFactory() || IAccessControl(_accessControlAddress).hasRole(MANAGER_ROLE, msg.sender));
      saleExists[addr] = choice;
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry( addressRegistry).getRoleRegAddr();
  }

  function getCrowdsaleFactAddr() public view returns (address) {
    return IAddressRegistry( addressRegistry).getCrowdsaleFactAddr();
  }

  function _isFactory() internal view returns (bool) {
    return msg.sender == getCrowdsaleFactAddr();
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

  function getCrowdsaleFactAddr() external view returns (address);

  function getTokenFactAddr() external view returns (address);

  function getCrowdsaleEventAddr() external view returns (address);
  
  function getDividendEventAddr() external view returns (address);

  function getRoleRegAddr() external view returns (address);

  function setCrowdsaleFactAddr(address newAddr) external;

  function setTokenFactAddr(address newAddr) external;

  function setCrowdsaleEventAddr(address newAddr) external;
  
  function setDividendEventAddr(address newAddr) external;

  function setRoleRegAddr(address newAddr) external;

}