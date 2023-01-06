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

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (game/Energy.sol)
pragma solidity ^0.8.17;

import "../interfaces/IPOK.sol";

/**
 * @title Energy
 * @author Mathieu Bour
 * @notice Allow to recharge energy by spending $POK tokens and native currency.
 */
contract Energy {
  /// Price per energy point in native currency.
  uint256 public constant UNIT_NAT = 0.012e18;
  /// Price per energy point in $POK tokens.
  uint256 public constant UNIT_POK = 0.321e18;

  IPOK immutable pok;
  address immutable treasury;

  /// Emitted when the energy has been recharged.
  event EnergyRecharged(address account, uint8 amount);

  /// Thrown when the transaction exceeds the maximum value.
  error ExcessiveValue(uint256 maximum, uint256 actual);
  /// Thrown when the sender does own enough $POK tokens.
  error InsufficientPOK(uint256 expected, uint256 actual);
  /// Thrown when the native transfer has failed.
  error TransferFailed(address recipient, uint256 amount);

  constructor(IPOK _pok, address _treasury) {
    pok = _pok;
    treasury = _treasury;
  }

  /**
   * @notice Recharge the energy by spending $POK tokens and native currency.
   * @dev Split is determined by the message value in native currency.
   * Requirements:
   * - msg.value must not exceed the amount multiplied by the UNIT_NAT.
   * - sender should own enough $POK tokens.
   */
  function recharge(uint8 amount) external payable {
    uint256 amountNAT = msg.value / UNIT_NAT;
    if (amountNAT > amount) {
      revert ExcessiveValue(amount * UNIT_NAT, msg.value);
    }

    uint256 amountPOK = (amount - amountNAT) * UNIT_POK;
    if (amountPOK > pok.balanceOf(msg.sender)) {
      revert InsufficientPOK(amountPOK, pok.balanceOf(msg.sender));
    }

    if (amountPOK > 0) {
      pok.burn(msg.sender, amountPOK);
    }
    if (amountNAT > 0) {
      (bool sent, ) = address(treasury).call{ value: amountNAT }("");
      if (!sent) {
        revert TransferFailed(msg.sender, amountNAT);
      }
    }

    emit EnergyRecharged(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IPOK.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IPOK
 * @author Mathieu Bour
 * @notice Minimal $POK ERC20 token interface.
 */
interface IPOK is IAccessControl, IERC20 {
  /**
   * @notice Mint an arbitrary amount of $POK to an account.
   * @dev Requirements:
   * - only MINTER role can mint $POK tokens
   */
  function mint(address to, uint256 amount) external;

  /**
   * @notice Burn an arbitrary amount of $POK of an sender account.
   * It is acknowledged that burning directly from the user wallet is anti-pattern
   * but since $POK is soulbounded, this allow to skip the ERC20 approve call.
   * @dev Requirements:
   * - only BURNER role can burn $POK tokens
   */
  function burn(address to, uint256 amount) external;
}