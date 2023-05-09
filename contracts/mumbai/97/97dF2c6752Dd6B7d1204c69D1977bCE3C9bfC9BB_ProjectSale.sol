// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
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
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
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
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
                require(isContract(target), "Address: call to non-contract");
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

import "./IERC165.sol";

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
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
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/allocation/IAllocationProvider.sol";

/**
 * @title AbstractAllocationProvider
 * @author OpenPad
 * @notice Contract implments allocation provider interface assuming that
 * {_calculateAllocation} function is implemented.
 * @dev Derived contracts must implement {_calculateAllocation} function.
 */
abstract contract AbstractAllocationProvider is IAllocationProvider, Ownable, ReentrancyGuard {
    struct Allocation {
        uint8 generation;
        uint256 amount;
    }

    /// @notice Mapping of accounts to allocations
    mapping(address => Allocation) private _allocations;
    /// @notice Total allocation reserved
    uint256 private _totalAllocation;
    /// @notice Current generation
    uint8 private _generation = 1;

    function allocationOf(address _account) public view returns (uint256) {
        Allocation memory allocation = _allocations[_account];
        if (allocation.generation == _generation) {
            return allocation.amount;
        }
        return 0;
    }

    function totalAllocation() public view returns (uint256) {
        return _totalAllocation;
    }

    /**
     * @notice Function to grant an allocation to an account
     * @dev This function's behavior can be customized by overriding the internal _grantAllocation function.
     * @param account to grant allocation to
     * @param amount allocation amount
     */
    function grantAllocation(address account, uint256 amount) public onlyOwner {
        require(
            account != address(0),
            "AbstractAllocationProvider: beneficiary is the zero address"
        );
        require(amount > 0, "AbstractAllocationProvider: amount is 0");
        uint allocation = allocationOf(account) + amount;
        _setAllocation(account, allocation);
    }

    function takeSnapshot(
        address[] memory accounts
    ) public onlyOwner nonReentrant {
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = _calculateAllocation(accounts[i]);
            grantAllocation(accounts[i], amount);
        }
    }

    function reset() public onlyOwner {
        _generation += 1;
        _totalAllocation = 0;
    }

    /**
     * @notice Function to revoke an allocation from an account
     * @dev This function can only be called by the owner.
     * @param account The account to revoke the allocation from
     */
    function revokeAllocation(address account) public onlyOwner {
        require(
            account != address(0),
            "AbstractAllocationProvider: beneficiary is the zero address"
        );
        _setAllocation(account, 0);
    }

    /**
     * @notice Internal function to grant an allocation to an account
     * @dev This function can be overridden to add functionality to the granting of an allocation.
     * @param account The account to grant the allocation to
     */
    function _calculateAllocation(address account) internal view virtual returns (uint256);

    function _setAllocation(address account, uint256 amount) private {
        Allocation memory allocation = _allocations[account];
        if (allocation.generation == _generation) {
            _totalAllocation = _totalAllocation - allocation.amount + amount;
        } else {
            _totalAllocation = _totalAllocation + amount;
        }
        _allocations[account] = Allocation(_generation, amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/allocation/AbstractAllocationProvider.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CreditAllocationProvider
 * @notice Contract that provides an allocation system based on credit token balances
 * @dev This contract is expanded from AbstractAllocationProvider.
 */
contract CreditAllocationProvider is ReentrancyGuard, AbstractAllocationProvider {
    using SafeERC20 for IERC20;

    IERC20 public immutable creditToken;

    constructor(address _creditToken) {
        require(_creditToken != address(0), "Credit token address cannot be 0");
        creditToken = IERC20(_creditToken);
    }

    function _calculateAllocation(address _user) internal view override returns (uint256) {
        return creditToken.balanceOf(_user);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/allocation/AbstractAllocationProvider.sol";

/**
 * @title DirectAllocationProvider
 * @author OpenPad
 */
contract DirectAllocationProvider is AbstractAllocationProvider {

    /**
     * @notice grants allocation to multiple accounts
     * @param accounts accounts to grant allocation to
     * @param allocations allocations to grant
     */
    function grantBatchAllocation(address[] memory accounts, uint256[] memory allocations) external onlyOwner {
        require(accounts.length == allocations.length, "DirectAllocationProvider: accounts and allocations must be the same length");
        for (uint256 i = 0; i < accounts.length; i++) {
            grantAllocation(accounts[i], allocations[i]);
        }
    }

    /**
     * @notice This function is not used in the direct allocation version of allocation provider
     * @param account is the account to calculate in other versions of Allocation providers
     */
    function _calculateAllocation(address account) internal pure override returns (uint256) {
        // ssh - Not used
        account;
        revert("DirectAllocationProvider: cannot calculate allocation on direct allocation provider. Use grantBatchAllocation instead.");
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IAllocationProvider {
    /**
     * @dev Returns allocation in USD of `_account`
     * @param _account Account to check
     * @return Allocation of `_account`
     */
    function allocationOf(address _account) external view returns (uint256);

    /**
     * @dev Returns total allocation in USD
     * @return Total allocation
     */
    function totalAllocation() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IAllocationProxy {
    /**
     * @dev Returns total allocation in USD of `_account`
     * @param _account Account to check
     * @return Allocation of `_account`
     */
    function allocationOf(address _account) external view returns (uint256);

    /**
     * @dev Returns credit allocation in USD
     * @return Credit allocation
     */
    function creditAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns direct allocation in USD
     * @return Direct allocation
     */
    function directAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns relative(staking) allocation in USD
     * @return Relative allocation
     */
    function relativeAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns total allocation in USD
     * @return Total allocation
     */
    function totalAllocation() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/staking/IStaking.sol";
import "contracts/allocation/AbstractAllocationProvider.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title StakingAllocationProvider
 * @author OpenPad
 * @notice grants allocation based on the amount staked, total rewards generated and stake duration
 * @dev The allocation is calculated as the square root of the sum of the following parameters:
 * - Amount staked
 * - Total rewards generated
 * - Stake duration
 * The parameters are weighted by the following multipliers:
 * - Alfa
 * - Beta
 * - Theta
 * The sum of the multipliers must be 1 ether
 */
contract StakingAllocationProvider is AbstractAllocationProvider {
    using SafeERC20 for IERC20;

    /// @notice Staking contract
    IStaking public immutable _staking;

    /// @notice Alfa parameter used for the multiplier of stake amount
    uint256 private _alfa;
    /// @notice Beta parameter used for the multiplier of total rewards generated
    uint256 private _beta;
    /// @notice Teta parameter used for the multiplier of stake duration
    uint256 private _theta;

    /**
     * @notice Constructor of the contract that initializes:
     * - Staking contract
     * - Credit token contract
     * - Alfa parameter
     * - Beta parameter
     * - Teta parameter
     * @param staking_ Staking contract address
     * @param alfa_ Alfa parameter
     * @param beta_ Beta parameter
     * @param theta_ Teta parameter
     */
    constructor(address staking_, uint256 alfa_, uint256 beta_, uint256 theta_) {
        require(staking_ != address(0), "StakingAllocationProvider: Staking address cannot be 0");
        require(
            alfa_ + beta_ + theta_ == 1 ether,
            "StakingAllocationProvider: Alfa, beta and teta must sum 1 ether"
        );
        _staking = IStaking(staking_);
        _alfa = alfa_;
        _beta = beta_;
        _theta = theta_;
    }

    /**
     * @notice Calculate allocation based on amount staked, total rewards generated and stake duration
     * @param account staker
     */
    function _calculateAllocation(address account) internal view override returns (uint256) {
        uint256 param1 = (_staking.stakedOf(account) * _alfa) / 1e18;
        uint256 param2 = (_staking.getTotalRewardsGenerated(account) * _beta) / 1e18;
        uint256 param3 = (_staking.getUserStakeDuration(account) * _theta);

        uint256 quad = sqrt((param1 + param2 + param3) * 1e18);
        return quad;
    }

    /**
     * @notice Function to calculate the square root of a number.
     * @dev This function is based on the Babylonian method.
     * @param y Number to calculate the square root
     * @return z Square root of the number
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IVesting {
    event Claimed(address account, uint256 amount);

    /**
     * @dev Transfers currently claimable tokens to the sender
     * emits {Claimed} event.
     */
    function claim() external;

    /**
     * @notice Sets `_amount` shares to `_account` independent of their previous shares.
     * @dev Even if `_account` has shares, it will be set to `_amount`.
     * @param _account The account to set shares to
     * @param _amount The amount of shares to set
     */
    function setShares(address _account, uint256 _amount) external;

    /**
     * @notice Adds `_amount` shares to `_account`.
     * @dev If `_account` has no shares, it will be added to the list of shareholders.
     * @param _account The account to add shares to
     * @param _amount The amount of shares to add
     */
    function addShares(address _account, uint256 _amount) external;

    /**
     * @notice Removes `_amount` shares from `_account`.
     * @dev If `_account` has no shares, it will be removed from the list of shareholders.
     * @param _account The account to remove shares from
     */
    function removeShares(address _account) external;

    /**
     * @dev Returns amount of tokens that can be claimed by `_account`
     */
    function claimableOf(address _account) external view returns (uint256);

    /**
     * @dev Returns total amount of tokens that can be claimed by `_account`
     */
    function totalClaimableOf(address _account) external view returns (uint256);

    /**
     * @dev Returns amount of tokens that has been claimed by `_account`
     */
    function claimedOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IKYCProvider {
    /**
     * @dev Emitted when `_account` is added to whitelist
     */
    event Whitelisted(address indexed _account, uint256 _timestamp);

    /**
     * @dev Emitted when `_account` is removed from whitelist
     */
    event Blacklisted(address indexed _account, uint256 _timestamp);

    /**
     * @dev Returns true if `_account` is KYC approve
     * @param _account Account to check
     */
    function isWhitelisted(address _account) external view returns (bool);

    /**
     * @dev Adds `_account` to whitelist
     * @param _account Account to add to whitelist
     */
    function addToWhitelist(address _account) external;

    /**
     * @dev Adds `_accounts` to whitelist in a single transaction
     */
    function batchAddToWhitelist(address[] memory _accounts) external;

    /**
     * @dev Removes `_account` from whitelist
     * @param _account Account to remove from whitelist
     */
    function removeFromWhitelist(address _account) external;

    /**
     * @dev Removes `_accounts` from whitelist in a single transaction
     * @param _accounts Accounts to remove from whitelist
     */
    function batchRemoveFromWhitelist(address[] memory _accounts) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "./IProjectSale.sol";

abstract contract AbstractProjectSale is IProjectSale {
    struct SaleTimes {
        uint256 registerStart;
        uint256 registerEnd;
        uint256 stakingRoundStart;
        uint256 stakingRoundEnd;
        uint256 publicRoundStart;
        uint256 publicRoundEnd;
        uint256 vestingStart;
        uint256 vestingEnd;
    }

    SaleTimes public saleTimes;

    /**
     * @dev Throws if block time isn't between `registerStart` and `registerEnd`
     */
    modifier onlyDuringRegisteration() {
        require(
            block.timestamp >= saleTimes.registerStart,
            "ProjectSale: registration period has not started yet"
        );
        require(block.timestamp <= saleTimes.registerEnd, "ProjectSale: registration period has ended");
        _;
    }

    constructor(
        SaleTimes memory _saleTimes
    ) {
        require(
            _saleTimes.registerStart < _saleTimes.registerEnd,
            "ProjectSale: registerStart must be before registerEnd"
        );
        require(
            _saleTimes.registerEnd <= _saleTimes.stakingRoundStart,
            "ProjectSale: registerEnd must be before stakingRoundStart"
        );
        require(
            _saleTimes.stakingRoundStart < _saleTimes.stakingRoundEnd,
            "ProjectSale: stakingRoundStart must be before stakingRoundEnd"
        );
        require(
            _saleTimes.stakingRoundEnd <= _saleTimes.publicRoundStart,
            "ProjectSale: stakingRoundEnd must be before publicRoundStart"
        );
        require(
            _saleTimes.publicRoundStart < _saleTimes.publicRoundEnd,
            "ProjectSale: publicRoundStart must be before publicRoundEnd"
        );
        require(
            _saleTimes.publicRoundEnd <= _saleTimes.vestingStart,
            "ProjectSale: publicRoundEnd must be before vestingStart"
        );
        require(
            _saleTimes.vestingStart < _saleTimes.vestingEnd,
            "ProjectSale: vestingStart must be before vestingEnd"
        );
        saleTimes = _saleTimes;
    }

    /**
     * @notice Function to update the times after setting.
     * Should have admin role.
     *
     * @param _saleTimes The new sale times
     */
    function updateTimes(
        SaleTimes memory _saleTimes
    ) external virtual;

    /**
     * @dev Returns true if time is between staking round
     * @return True if time is between staking round
     */
    function isStakingRound() public view returns (bool) {
        return block.timestamp >= saleTimes.stakingRoundStart && block.timestamp <= saleTimes.stakingRoundEnd;
    }

    /**
     * @dev Returns true if time is between public round
     * @return True if time is between public round
     */
    function isPublicRound() public view returns (bool) {
        return block.timestamp >= saleTimes.publicRoundStart && block.timestamp <= saleTimes.publicRoundEnd;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IProjectSale {
    /**
     * @dev Emitted when `_account` registers to sale
     */
    event Registered(address _account);

    /**
     * @dev Emitted when `_account` deposits `_amount` USD pegged coin
     */
    event Deposit(address _account, uint256 _amount);

    /**
     * @dev Register to sale
     *
     * Emits a {Registered} event.
     */
    function register() external;

    /**
     * @dev Returns true if `_account` is registered
     * @param _account Account to check
     */
    function isRegistered(address _account) external view returns (bool);

    /**
     * @dev Deposit USD
     * @param _amount Amount of USD to deposit.
     *
     * Emits a {Deposit} event.
     */
    function deposit(uint256 _amount) external;

    /**
     * @dev Returns USD deposited by `_account`
     * @param _account Account to check
     */
    function depositedOf(address _account) external view returns (uint256);

    /**
     * @dev Returns credit deposited by `_account`
     * @param _account Account to check
     * @return Credit deposited by `_account`
     */
    function creditDepositedOf(address _account) external view returns (uint256);

    /**
     * @dev Returns depositable USD of `_account`
     * @param _account Account to check
     * @return Depositable USD of `_account`
     */
    function depositableOf(address _account) external view returns (uint256);

    /**
     * @dev Returns credit depositable of an account.
     * @param _account Account to check
     * @return Credit depositable of an account
     */
    function creditDepositableOf(address _account) external view returns (uint256);

    /**
     * @dev Returns current sale value in terms of pegged token
     * @return uint256 current sale value
     */
    function totalSaleValue() external view returns (uint256);

    /**
     * @dev Returns total sale value cap in terms of pegged token
     * @return uint256 total sale value
     */
    function totalSaleValueCap() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/allocation/IAllocationProvider.sol";
import "contracts/kyc/IKYCProvider.sol";
import "contracts/Vesting/Vesting.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "contracts/allocation/IAllocationProxy.sol";
import "contracts/allocation/StakingAllocationProvider.sol";
import "contracts/allocation/CreditAllocationProvider.sol";
import "contracts/allocation/DirectAllocationProvider.sol";
import "contracts/projectSale/AbstractProjectSale.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title ProjectSale contract
 * @author OpenPad
 * @notice This contract is responsible for the sale of a project' tokens.
 * @dev Used with the following contracts:
 * - KYCProvider
 * - SplittedVesting
 * - StakingAllocationProvider
 */
contract ProjectSale is AbstractProjectSale, ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Providers {
        /// @notice External providers for allocation and KYC
        address kycProvider;
        /// @notice allocation provider external contracts
        address allocationProvider;
    }

    /**
     * @notice Sale status enum
     * @dev `NOT_FINALIZED` sale has not been finalized yet
     * @dev `FINALIZED` sale has been finalized
     */
    enum SaleStatus {
        NOT_FINALIZED,
        FINALIZED
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Sale status
    SaleStatus private _saleStatus;
    /// @notice Fee to be taken on public round deposits
    uint8 private constant PUBLIC_ROUND_FEE = 5; // 5%

    /// @notice External providers for allocation, KYC
    Providers public providers;

    /// @notice Splitting vesting contract that handles vesting to multiple users
    Vesting public immutable vestingContract;

    /// @notice Credit reserve address to be used for credit deposits
    address public immutable creditReserve;
    /// @notice Credit token to be used for credit deposits
    IERC20 public immutable creditToken;
    /// @notice USD token to be used for staking and public round deposits
    IERC20 public immutable usdToken;
    /// @notice Project token to be sold
    IERC20 public immutable projectToken;

    /// @notice Total value of tokens to be sold
    uint256 public immutable totalSaleValueCap;
    /// @notice Price of the project token
    uint256 public immutable projectTokenPrice;
    /// @notice Amount of project tokens to be sold
    uint256 public immutable projectTokenAmount;
    /// @notice Address to claim deposited funds
    address public immutable saleClaimAddress;
    /// @notice Address to claim fees
    address public immutable feeClaimAddress;
    /// @notice Total current value of tokens sold
    uint256 public totalSaleValue;

    /// @notice Mapping of deposited values of addresses
    EnumerableMap.AddressToUintMap private _depositBalances;
    /// @notice Mapping of credit deposited values of addresses
    EnumerableMap.AddressToUintMap private _creditDepositBalances;

    /// @notice Mapping of registered addresses
    EnumerableSet.AddressSet private _participants;

    AggregatorV3Interface internal peggedPriceFeed;

    /**
     * @notice Modifier to check if the address is whitelisted or not
     */
    modifier onlyWhiteListed(address _account) {
        require(IKYCProvider(providers.kycProvider).isWhitelisted(_account), "ProjectSale: account is not whitelisted");
        _;
    }

    /**
     * @notice Modifier to make sure the `finalizeSale()` function is only being called once.
     */
    modifier onlyOnce() {
        require(_saleStatus == SaleStatus.NOT_FINALIZED, "ProjectSale: sale is finalized");
        _;
        _saleStatus = SaleStatus.FINALIZED;
    }

    /**
     * @notice Constructor for ProjectSale contract that initializes the sale.
     * @param _saleTimes Sale times
     * @param _providers External providers for allocation and KYC
     * @param _vestingPeriodsInSec Vesting periods in seconds
     * @param _creditReserve Address of credit reserve
     * @param _creditToken Address of credit token
     * @param _usdToken Address of USD token
     * @param _projectToken Address of project token
     * @param _projectTokenPrice Price of project token
     * @param _projectTokenAmount Amount of project tokens to be sold
     * @param _totalSaleValueCap Total value of tokens to be sold
     * @param _saleClaimAddress Address to claim deposited funds
     * @param _feeClaimAddress Address to claim fees
     * @dev _projectTokenPrice * _projectTokenAmount == _totalSaleValueCap
     */
    constructor(
        SaleTimes memory _saleTimes,
        Providers memory _providers,
        uint256 _vestingPeriodsInSec,
        address _creditReserve,
        address _creditToken,
        address _usdToken,
        address _projectToken,
        uint256 _projectTokenPrice,
        uint256 _projectTokenAmount,
        uint256 _totalSaleValueCap,
        address _saleClaimAddress,
        address _feeClaimAddress
    )
        AbstractProjectSale(
            _saleTimes
        )
    {
        require(
            (_projectTokenPrice * _projectTokenAmount) / (10 ** 18) == _totalSaleValueCap,
            "ProjectSale: invalid sale value"
        );
        require(
            address(_providers.allocationProvider) != address(0),
            "ProjectSale: allocation provider cannot be zero address"
        );
        require(address(_providers.kycProvider) != address(0), "ProjectSale: kyc provider cannot be zero address");

        // Sale Details
        creditReserve = _creditReserve;
        creditToken = IERC20(_creditToken);
        usdToken = IERC20(_usdToken);
        projectToken = IERC20(_projectToken);
        totalSaleValueCap = _totalSaleValueCap;
        projectTokenPrice = _projectTokenPrice;
        projectTokenAmount = _projectTokenAmount;
        _saleStatus = SaleStatus.NOT_FINALIZED;

        // External providers for allocation and KYC
        providers = _providers;

        feeClaimAddress = _feeClaimAddress;
        saleClaimAddress = _saleClaimAddress;

        // Create the splitting vesting contract
        uint256 durationInSec = saleTimes.vestingEnd - saleTimes.vestingStart;
        vestingContract = new Vesting(
            address(projectToken),
            saleTimes.vestingStart,
            durationInSec,
            _vestingPeriodsInSec
        );
        vestingContract.grantRole(ADMIN_ROLE, owner());

        peggedPriceFeed = AggregatorV3Interface(
            0x92C09849638959196E976289418e5973CC96d645 //USDT - USD on mumbai
        );
    }

    function updateTimes(
        SaleTimes memory _saleTimes
    ) external override onlyOwner {
        require(_saleStatus == SaleStatus.NOT_FINALIZED, "ProjectSale: sale is finalized");
        require(
            _saleTimes.registerStart < _saleTimes.registerEnd &&
                _saleTimes.stakingRoundStart < _saleTimes.stakingRoundEnd &&
                _saleTimes.publicRoundStart < _saleTimes.publicRoundEnd &&
                _saleTimes.vestingStart < _saleTimes.vestingEnd,
            "ProjectSale: invalid time"
        );
        require(
            _saleTimes.registerStart < _saleTimes.stakingRoundStart &&
                _saleTimes.stakingRoundStart < _saleTimes.publicRoundStart &&
                _saleTimes.publicRoundStart < _saleTimes.vestingStart,
            "ProjectSale: invalid time"
        );

        saleTimes = _saleTimes;
    }

    /**
     * @notice Registers the sender to the sale.
     * @dev Only allowed during registeration period.
     */
    function register() external override nonReentrant whenNotPaused onlyDuringRegisteration {
        require(!isRegistered(msg.sender), "ProjectSale: already registered");
        _participants.add(msg.sender);
        emit Registered(msg.sender);
    }

    /**
     * @notice Registers the given address to the sale.
     * @dev Only allowed before staking period start and by the contract owner.
     * @param _user Address to be registered.
     */
    function adminRegister(address _user) external onlyOwner nonReentrant whenNotPaused {
        require(block.timestamp < saleTimes.stakingRoundStart, "ProjectSale: staking round started");
        require(!isRegistered(_user), "ProjectSale: already registered");
        _participants.add(_user);
        emit Registered(_user);
    }

    /**
     * @notice Function to deposit tokens to the sale.
     * Deposits from whitelisted account are allowed
     * if it is during the staking round and the account is registered or
     * if it is during the public round.
     * @dev Also includes depositable amount from credit token,
     * `creditDeposit()` should be used first if user has credit.
     * @param _amount is the amount of tokens to be deposited
     */
    function deposit(
        uint256 _amount
    )
        external
        override
        nonReentrant
        whenNotPaused
        onlyWhiteListed(msg.sender) //@note Give alloc to staker, registers, whitelist ortak kume
    {
        require(_amount > 0, "ProjectSale: amount is zero");
        require(
            (isStakingRound() && isRegistered(msg.sender)) || isPublicRound(),
            "ProjectSale: not allowed to deposit"
        );
        uint256 depositableAmount = depositableOf(msg.sender);

        uint256 fee;
        if (isPublicRound()) {
            if (_amount > depositableAmount) {
                _amount = depositableAmount;
            }
            //@note add investable amount check
            fee = (_amount * PUBLIC_ROUND_FEE) / 100;
            fee = fee / getPeggedPrice();
        } else {
            require(_amount <= depositableAmount, "ProjectSale: amount exceeds depositable amount");
        }

        (bool found, uint256 _deposited) = _depositBalances.tryGet(msg.sender);
        if (found) {
            _depositBalances.set(msg.sender, _deposited + _amount);
        } else {
            _depositBalances.set(msg.sender, _amount);
        }
        vestingContract.addShares(msg.sender, _amount);

        totalSaleValue += _amount;

        uint256 peggedAmount = _amount / getPeggedPrice();
        usdToken.safeTransferFrom(msg.sender, saleClaimAddress, peggedAmount);
        if (fee > 0) {
            require(
                usdToken.balanceOf(msg.sender) >= fee,
                "ProjectSale: insufficient balance for fee"
            );
            usdToken.safeTransferFrom(msg.sender, feeClaimAddress, fee);
        }
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Function to deposit tokens to the sale from credit token.
     * Deposits from whitelisted account are allowed
     * if it is during the staking round and the account is registered.
     * Public round deposit is not allowed.
     * @param _amount is the amount of tokens to be deposited
     */
    function creditDeposit(
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyWhiteListed(msg.sender) {
        require(_amount > 0, "ProjectSale: amount is zero");
        require(
            isStakingRound() && isRegistered(msg.sender),
            "ProjectSale: credit not allowed to deposit"
        );
        uint256 depositableAmount = creditDepositableOf(msg.sender);
        require(_amount <= depositableAmount, "ProjectSale: amount exceeds depositable amount");

        (bool found, uint256 _deposited) = _creditDepositBalances.tryGet(msg.sender);
        if (found) {
            _creditDepositBalances.set(msg.sender, _deposited + _amount);
        } else {
            _creditDepositBalances.set(msg.sender, _amount);
        }
        vestingContract.addShares(msg.sender, _amount);

        totalSaleValue += _amount;
        creditToken.safeTransferFrom(msg.sender, creditReserve, _amount);
        usdToken.safeTransferFrom(creditReserve, saleClaimAddress, _amount);
    }

    /**
     * @notice Function to finalize sale and transfer tokens to Vesting.
     * @dev Only allowed after the sale is over and only once.
     * Only the owner can call this function.
     * The caller must have the tokens to be transferred to vesting.
     */
    function finalizeSale() external onlyOwner onlyOnce {
        require(block.timestamp > saleTimes.publicRoundEnd, "ProjectSale: sale is not over");
        _pause();

        // Transfer the tokens to the vestingContract
        uint256 tokensSold = totalSaleValue.div(projectTokenPrice).mul(10 ** 18);
        projectToken.safeTransferFrom(msg.sender, vestingContract.getReleaser(), tokensSold);
    }

    /**
     * @notice Function to get the total number of participants.
     * @return uint256 is the total number of participants.
     */
    function participantCount() external view returns (uint256) {
        return _participants.length();
    }

    /**
     * @notice Function to get the participant at the given index.
     * @param index is the index of the participant.
     * @return address is the participant.
     */
    function participantAt(uint256 index) external view returns (address) {
        require(index < _participants.length(), "ProjectSale: index out of bounds");
        return _participants.at(index);
    }

    /**
     * @notice Function to get participants between the given indexes.
     * @param start is the start index.
     * @param end is the end index.
     * @return address[] is the array of participants.
     */
    function participantsBetween(
        uint256 start,
        uint256 end
    ) external view returns (address[] memory) {
        require(start <= end, "ProjectSale: start > end");
        require(end <= _participants.length(), "ProjectSale: index out of bounds");
        address[] memory _participantsArray = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            _participantsArray[i - start] = _participants.at(i);
        }
        return _participantsArray;
    }

    /**
     * @notice Function to view the vesting contract address.
     * @dev If the sale is not finalized, the address is zero.
     * @return bool is if the sale is finalized or not.
     * @return address is the vesting contract address.
     */
    function getVestingContract() external view returns (bool, address) {
        if (_saleStatus == SaleStatus.NOT_FINALIZED) {
            return (false, address(0));
        }
        return (true, address(vestingContract));
    }

    /**
     * @notice Function to see if an address is registered or not.
     * @param _account is the address to check.
     * @return bool is if the address is registered or not.
     */
    function isRegistered(address _account) public view override returns (bool) {
        return _participants.contains(_account);
    }

    /**
     * @notice Function to see total deposited amount of an address.
     * @param _account is the address to check.
     * @return uint256 is the total deposited amount.
     */
    function depositedOf(address _account) public view override returns (uint256) {
        (bool success, uint256 _deposited) = _depositBalances.tryGet(_account);
        if (success) {
            return _deposited;
        }
        return 0;
    }

    function creditDepositedOf(address _account) public view override returns (uint256) {
        (bool success, uint256 _deposited) = _creditDepositBalances.tryGet(_account);
        if (success) {
            return _deposited;
        }
        return 0;
    }

    /**
     * @notice Function to see remaining depositable amount from direct and staking alloction of an address.
     * @dev If its the public round, every address gets the same amount.
     * @param _account is the address to check.
     * @return uint256 is the remaining depositable amount.
     */
    function depositableOf(address _account) public view override returns (uint256) {
        if (!IKYCProvider(providers.kycProvider).isWhitelisted(_account)) {
            return 0;
        } else if (isRegistered(_account) && isStakingRound()) {
            return
                IAllocationProxy(providers.allocationProvider).directAllocationOf(_account) +
                IAllocationProxy(providers.allocationProvider).relativeAllocationOf(_account) -
                depositedOf(_account);
        } else if (isPublicRound()) {
            return totalSaleValueCap - totalSaleValue;
        } else {
            return 0;
        }
    }

    function creditDepositableOf(address _account) public view override returns (uint256) {
        if (!IKYCProvider(providers.kycProvider).isWhitelisted(_account)) {
            return 0;
        } else if (isRegistered(_account) && isStakingRound()) {
            return IAllocationProxy(providers.allocationProvider).creditAllocationOf(_account) - creditDepositedOf(_account);
        } else {
            return 0;
        }
    }

    /**
     * Returns the latest price.
     */
    function getPeggedPrice() internal view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = peggedPriceFeed.latestRoundData();
        return uint256(price);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

/**
 * @dev Interface of OPN Staking.
 */
interface IStaking {
    /**
     * @dev Emitted when a user stakes `_amount` of tokens.
     */
    event Staked(address _from, uint256 _amount);

    /**
     * @dev Emitted when a user withdraws `_amount` of tokens.
     */
    event Withdrawn(address _from, uint256 _amount);

    /**
     * @dev Emitted when a user claims rewards.
     */
    event RewardClaimed(address _from, uint256 _amount);

    /**
     * @dev Stakes `_amount` of tokens.
     * @param _amount Amount of tokens to stake.
     *
     * Emits a {Staked} event.
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Withdraws `_amount` of tokens.
     * @param _amount Amount of tokens to withdraw.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims rewards.
     *
     * Emits a {RewardClaimed} event.
     */
    function claimReward() external;

    /**
     * @dev Returns the amount of tokens staked by `_address`.
     * @param _address Address to check.
     */
    function stakedOf(address _address) external view returns (uint256);

    /**
     * @dev Returns the amount of rewards earned by `_address`.
     * @param _address Address to check.
     */
    function rewardOf(address _address) external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens staked.
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Returns the total amount of rewards a wallet has generated. Including claimed rewards.
     */
    function getTotalRewardsGenerated(address _address) external view returns (uint256);

    /**
     * @dev Returns the total amount of time a wallet has staked. Including withdrawn tokens.
     * This resets when user withdraws all tokens.
     *
     */
    function getUserStakeDuration(address _address) external view returns (uint256);

    /**
     * @dev Returns the number of participants.
     */
    function numberOfParticipants() external view returns (uint256);

    /**
     * @dev Returns the addresses between `_start` and `_end`.
     */
    function addresses(uint256 _start, uint256 _end) external view returns (address[] memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Releaser
 */
contract Releaser is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 private immutable _token;
    uint256 private _erc20Released;
    address private immutable _beneficiary;
    uint256 private immutable _start;
    uint256 private immutable _duration;
    uint256 private immutable _periods;

    event ERC20Released(address _token, uint256 _amount);

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        address erc20Token,
        uint256 startTimestamp,
        uint256 durationSeconds,
        uint256 periodInSeconds
    ) {
        require(erc20Token != address(0), "Releaser: token cannot be the zero address");
        require(beneficiaryAddress != address(0), "Releaser: beneficiary is zero address");
        require(startTimestamp >= block.timestamp, "Releaser: start is before current time");
        require(durationSeconds > 0, "Releaser: duration should be larger than 0");

        _token = IERC20(erc20Token);
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
        _periods = periodInSeconds;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() external virtual {
        uint256 releasable = vestedAmount(block.timestamp) - released();
        _erc20Released += releasable;
        emit ERC20Released(ERC20token(), releasable);
        _token.safeTransfer(beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested.
     */
    function vestedAmount(uint256 timestamp) public view virtual returns (uint256) {
        uint256 residue = timestamp % _periods;
        uint256 scheduled = timestamp - residue;
        return _vestingSchedule(_token.balanceOf(address(this)) + released(), scheduled);
    }

    /**
     * @dev Getter for the token address.
     */
    function ERC20token() public view virtual returns (address) {
        return address(_token);
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Getter for the vesting periods.
     */
    function periods() public view virtual returns (uint256) {
        return _periods;
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view virtual returns (uint256) {
        return _erc20Released;
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) internal view virtual returns (uint256) {
        if (_timestamp < start()) {
            return 0;
        } else if (_timestamp > start() + duration()) {
            return _totalAllocation;
        } else {
            return (_totalAllocation * (_timestamp - start())) / duration();
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/interfaces/IVesting.sol";
import "contracts/Vesting/Releaser.sol";

/**
 * @title Vesting
 */
contract Vesting is IVesting, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PROJECT_SALE = keccak256("PROJECT_SALE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Releaser private immutable releaser;
    IERC20 private immutable token;

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    event SharesAdded(address account, uint256 amount);
    event SharesUpdated(address account, uint256 newShares);
    event PaymentReleased(address to, uint256 amount);

    constructor(
        address _token,
        uint256 _cliff,
        uint256 _durationInSec,
        uint256 _periodInSeconds
    ) {
        require(_token != address(0), "Token address cannot be 0");
        require(_cliff >= block.timestamp, "Cliff cannot be in the past");
        require(_durationInSec > 0, "Duration cannot be 0");

        releaser = new Releaser(address(this), _token, _cliff, _durationInSec, _periodInSeconds);
        token = IERC20(_token);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROJECT_SALE, msg.sender);
    }

    /**
     * @dev See {IVesting-claim}.
     */
    function claim() external whenNotPaused {
        releaser.release();
        uint256 payment = releasable(msg.sender);
        _release(msg.sender);
        emit Claimed(msg.sender, payment);
    }

    // ACCESS CONTROL FUNCTIONS

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev See {IVesting-setShares}.
     */
    function setShares(address _account, uint256 shares_) external onlyRole(ADMIN_ROLE) {
        require(_account != address(0), "Vesting: account is the zero address");
        require(shares_ > 0, "Vesting: shares are 0");

        uint256 oldShares = _shares[_account]; 
        _shares[_account] = shares_;
        _totalShares = _totalShares + shares_ - oldShares;
        emit SharesUpdated(_account, shares_);
    }

    /**
     * @dev See {IVesting-addShares}.
     */
    function addShares(address _account, uint256 _amount) external onlyRole(PROJECT_SALE) {
        require(_account != address(0), "Vesting: account is the zero address");
        require(_amount > 0, "Vesting: shares are 0");

        _shares[_account] += _amount;
        _totalShares += _amount;
        emit SharesAdded(_account, _amount);
    }

    /**
     * @dev See {IVesting-removeShares}.
     */
    function removeShares(address _account) external onlyRole(ADMIN_ROLE) {
        require(_account != address(0), "Vesting: account is the zero address");

        uint256 oldShares = _shares[_account];
        _shares[_account] = 0;
        _totalShares -= oldShares;
        emit SharesUpdated(_account, 0);
    }

    /**
     * @dev See {IVesting-claimableOf}.
     */
    function claimableOf(address _account) external view returns (uint256) {
        return releasable(_account);
    }

    /**
     * @dev See {IVesting-totalClaimableOf}.
     */
    function totalClaimableOf(address _account) external view returns (uint256) {
        uint256 vestingEnd = releaser.start() + releaser.duration();
        uint256 saleAmount = releaser.vestedAmount(vestingEnd);
        return _shareOf(_account, saleAmount);
    }

    /**
     * @dev See {IVesting-claimedOf}.
     */
    function claimedOf(address _account) external view returns (uint256) {
        return _released[_account];
    }

    /**
     * @dev Function to get the vesting releaser contract.
     * @return address of the releaser contract.
     */
    function getReleaser() external view returns (address) {
        return address(releaser);
    }

    /**
     * @dev Function to get the vesting token contract.
     * @return address of the token contract.
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function _release(address account) internal virtual {
        require(_shares[account] > 0, "Vesting: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "Vesting: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        token.safeTransfer(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Getter for the amount of shares in tokens with respect to total amounts.
     * @param _account address of the account.
     * @param _amount amount of total tokens.
     * @return amount of tokens account can receive.
     */
    function _shareOf(address _account, uint256 _amount) internal view returns (uint256) {
        return (_amount * _shares[_account]) / _totalShares;
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address account) internal view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + _totalReleased;
        return _pendingPayment(account, totalReceived, _released[account]);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }
}