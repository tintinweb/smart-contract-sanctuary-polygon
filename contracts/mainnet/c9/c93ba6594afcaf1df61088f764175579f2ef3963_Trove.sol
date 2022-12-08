// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./IMintableToken.sol";

interface IArbitragePool is IOwnable {
  function collateralToAPToken(address) external returns (IMintableToken);

  function getAPtokenPrice(address _collateralToken) external view returns (uint256);

  function deposit(address _collateralToken, uint256 _amount) external;

  function withdraw(address _collateralToken, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFeeRecipient {
  function baseRate() external view returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  function calcDecayedBaseRate(uint256 _currentBaseRate) external view returns (uint256);

  /**
     @dev is called to make the FeeRecipient contract transfer the fees to itself. It will use transferFrom to get the
     fees from the msg.sender
     @param _amount the amount in Wei of fees to transfer
     */
  function takeFees(uint256 _amount) external returns (bool);

  function increaseBaseRate(uint256 _increase) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";

interface ILiquidationPool {
  function collateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function liqTokenRate() external view returns (uint256);

  function claimCollateralAndDebt(uint256 _unclaimedCollateral, uint256 _unclaimedDebt) external;

  function approveTrove(address _trove) external;

  function unapproveTrove(address _trove) external;

  function liquidate() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";

interface IMintableToken is IERC20, IOwnable {
  function mint(address recipient, uint256 amount) external;

  function burn(uint256 amount) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function approve(address spender, uint256 amount) external override returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./IMintableToken.sol";

interface IMintableTokenOwner is IOwnable {
  function token() external view returns (IMintableToken);

  function mint(address _recipient, uint256 _amount) external;

  function transferTokenOwnership(address _newOwner) external;

  function addMinter(address _newMinter) external;

  function revokeMinter(address _minter) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function getAmountOut(
    uint256 amountIn,
    address token0,
    address token1
  ) external view returns (uint256 amountOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IStabilityPoolBase.sol";

interface IStabilityPool is IStabilityPoolBase {
  function arbitrage(
    uint256 _amountIn,
    address[] calldata _path,
    uint256 _deadline
  ) external;

  function setRouter(address _router) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITroveFactory.sol";
import "./IMintableToken.sol";

interface IStabilityPoolBase {
  function factory() external view returns (ITroveFactory);

  function stableCoin() external view returns (IMintableToken);

  function bonqToken() external view returns (IERC20);

  function totalDeposit() external view returns (uint256);

  function withdraw(uint256 _amount) external;

  function deposit(uint256 _amount) external;

  function redeemReward() external;

  function liquidate() external;

  function setBONQPerMinute(uint256 _bonqPerMinute) external;

  function setBONQAmountForRewards() external;

  function getDepositorBONQGain(address _depositor) external view returns (uint256);

  function getWithdrawableDeposit(address staker) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";

interface ITokenPriceFeed is IOwnable {
  struct TokenInfo {
    address priceFeed;
    uint256 mcr;
    uint256 mrf; // Maximum Redemption Fee
  }

  function tokenPriceFeed(address) external view returns (address);

  function tokenPrice(address _token) external view returns (uint256);

  function mcr(address _token) external view returns (uint256);

  function mrf(address _token) external view returns (uint256);

  function setTokenPriceFeed(
    address _token,
    address _priceFeed,
    uint256 _mcr,
    uint256 _maxRedemptionFeeBasisPoints
  ) external;

  function emitPriceUpdate(
    address _token,
    uint256 _priceAverage,
    uint256 _pricePoint
  ) external;

  event NewTokenPriceFeed(address _token, address _priceFeed, string _name, string _symbol, uint256 _mcr, uint256 _mrf);
  event PriceUpdate(address token, uint256 priceAverage, uint256 pricePoint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";
import "./ITroveFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrove is IOwnable {
  function factory() external view returns (ITroveFactory);

  function token() external view returns (IERC20);

  // solhint-disable-next-line func-name-mixedcase
  function TOKEN_PRECISION() external view returns (uint256);

  function mcr() external view returns (uint256);

  function collateralization() external view returns (uint256);

  function collateralValue() external view returns (uint256);

  function collateral() external view returns (uint256);

  function recordedCollateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function netDebt() external view returns (uint256);

  //  function rewardRatioSnapshot() external view returns (uint256);

  function initialize(
    //    address _factory,
    address _token,
    address _troveOwner
  ) external;

  function increaseCollateral(uint256 _amount, address _newNextTrove) external;

  function decreaseCollateral(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function borrow(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function repay(uint256 _amount, address _newNextTrove) external;

  function redeem(address _recipient, address _newNextTrove)
    external
    returns (uint256 _stableAmount, uint256 _collateralRecieved);

  function setArbitrageParticipation(bool _state) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./ITokenPriceFeed.sol";
import "./IMintableToken.sol";
import "./IMintableTokenOwner.sol";
import "./IFeeRecipient.sol";
import "./ILiquidationPool.sol";
import "./IStabilityPool.sol";
import "./ITrove.sol";

interface ITroveFactory {
  /* view */
  function lastTrove(address _trove) external view returns (address);

  function firstTrove(address _trove) external view returns (address);

  function nextTrove(address _token, address _trove) external view returns (address);

  function prevTrove(address _token, address _trove) external view returns (address);

  function containsTrove(address _token, address _trove) external view returns (bool);

  function stableCoin() external view returns (IMintableToken);

  function tokenOwner() external view returns (IMintableTokenOwner);

  function tokenToPriceFeed() external view returns (ITokenPriceFeed);

  function feeRecipient() external view returns (IFeeRecipient);

  function troveCount(address _token) external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function totalCollateral(address _token) external view returns (uint256);

  function totalDebtForToken(address _token) external view returns (uint256);

  function liquidationPool(address _token) external view returns (ILiquidationPool);

  function stabilityPool() external view returns (IStabilityPool);

  function arbitragePool() external view returns (address);

  function getRedemptionFeeRatio(address _trove) external view returns (uint256);

  function getRedemptionFee(uint256 _feeRatio, uint256 _amount) external pure returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  /* state changes*/
  function createTrove(address _token) external returns (ITrove trove);

  function createTroveAndBorrow(
    address _token,
    uint256 _collateralAmount,
    address _recipient,
    uint256 _borrowAmount,
    address _nextTrove
  ) external;

  function removeTrove(address _token, address _trove) external;

  function insertTrove(address _trove, address _newNextTrove) external;

  function updateTotalCollateral(
    address _token,
    uint256 _amount,
    bool _increase
  ) external;

  function updateTotalDebt(uint256 _amount, bool _borrow) external;

  function setStabilityPool(address _stabilityPool) external;

  function setArbitragePool(address _arbitragePool) external;

  // solhint-disable-next-line var-name-mixedcase
  function setWETH(address _WETH, address _liquidationPool) external;

  function increaseCollateralNative(address _trove, address _newNextTrove) external payable;

  /* utils */
  function emitLiquidationEvent(
    address _token,
    address _trove,
    address stabilityPoolLiquidation,
    uint256 collateral
  ) external;

  function emitTroveCollateralUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization
  ) external;

  function emitTroveDebtUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization,
    uint256 _feePaid
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITroveFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IArbitragePool.sol";
import "./interfaces/IMintableToken.sol";
import "./utils/constants.sol";
import "./interfaces/IFeeRecipient.sol";
import "./utils/BONQMath.sol";

contract Trove is ITrove, Ownable, Initializable, AccessControlEnumerable, Constants {
  using BONQMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  struct ArbitrageState {
    IArbitragePool arbitragePool;
    IMintableToken apToken;
    uint256 lastApPrice;
  }

  ITroveFactory public immutable override factory;
  IERC20 public override token;
  // solhint-disable-next-line var-name-mixedcase
  uint256 public override TOKEN_PRECISION;

  uint256 private _debt;
  uint256 public liquidationReserve;
  uint256 public override recordedCollateral;
  uint256 public liqTokenRateSnapshot;
  bool public arbitrageParticipation;
  ArbitrageState public arbitrageState;

  event Liquidated(address trove, uint256 debt, uint256 collateral);

  /**
   * @dev restrict the call to be from the factory contract
   */
  modifier onlyFactory() {
    require(msg.sender == address(factory), "1210a only callable from factory");
    _;
  }

  modifier onlyTroveOwner() {
    require(hasRole(OWNER_ROLE, msg.sender), "cfa3b address is missing OWNER_ROLE");
    _;
  }

  modifier whenFactoryNotPaused() {
    require(!Pausable(address(factory)).paused(), "cfa4b Trove Factory is paused");
    _;
  }

  constructor(address _factory) {
    factory = ITroveFactory(_factory);
  }

  function initialize(address _token, address _troveOwner) public override initializer {
    //    require(_factory != address(0x0), "41fe68 _factory must not be address 0x0");
    require(_token != address(0x0), "41fe68 _token must not be address 0x0");
    require(_troveOwner != address(0x0), "41fe68 _troveOwner must not be address 0x0");
    //    factory = ITroveFactory(_factory);
    _transferOwnership(_troveOwner);
    _initializeMainOwners(_troveOwner, address(factory));
    token = IERC20(_token);
    TOKEN_PRECISION = 10**(IERC20Metadata(_token).decimals());
    liqTokenRateSnapshot = factory.liquidationPool(_token).liqTokenRate();
    // allow the fee recipient contract to transfer as many tokens as it wants from the trove
    factory.stableCoin().approve(address(factory.feeRecipient()), MAX_INT);
  }

  function owner() public view override(Ownable, IOwnable) returns (address) {
    return Ownable.owner();
  }

  /**
   * @dev the Minimum Collateralisation Ratio for this trove as set in the Token to Price Feed contract.
   */
  function mcr() public view override returns (uint256) {
    return factory.tokenToPriceFeed().mcr(address(token));
  }

  /**
   * @dev the reward in the liquidation pool which has not been claimed yet
   */
  function unclaimedArbitrageReward() public view returns (uint256) {
    uint256 apBalance = arbitrageState.apToken.balanceOf(address(this));
    uint256 newApPrice = arbitrageState.arbitragePool.getAPtokenPrice(address(token));
    uint256 priceChange = newApPrice - arbitrageState.lastApPrice;
    return (apBalance * priceChange) / DECIMAL_PRECISION;
  }

  /**
   * @dev the reward in the liquidation pool which has not been claimed yet
   */
  function unclaimedCollateralRewardAndDebt() public view returns (uint256, uint256) {
    ILiquidationPool pool = factory.liquidationPool(address(token));
    uint256 currentLiqTokenRate = pool.liqTokenRate();
    return _unclaimedCollateralRewardAndDebt(pool, currentLiqTokenRate);
  }

  /**
   * @dev this function will return the actual collateral (balance of the collateral token) including any liquidation rewards from community liquidation
   */
  function collateral() public view override returns (uint256) {
    (uint256 unclaimedCollateral, ) = unclaimedCollateralRewardAndDebt();
    uint256 baseValue = token.balanceOf(address(this)) + unclaimedCollateral;
    if (arbitrageParticipation) {
      uint256 apBalance = arbitrageState.apToken.balanceOf(address(this));
      uint256 newApPrice = arbitrageState.arbitragePool.getAPtokenPrice(address(token));
      return baseValue + (apBalance * newApPrice) / DECIMAL_PRECISION;
    }
    return baseValue;
  }

  /**
   * @dev this function will return the actual debt including any liquidation liabilities from community liquidation
   */
  function debt() public view override returns (uint256) {
    (, uint256 unclaimedDebt) = unclaimedCollateralRewardAndDebt();
    return _debt + unclaimedDebt;
  }

  /**
   * @dev the net debt is the debt minus the liquidation reserve
   */
  function netDebt() public view override returns (uint256) {
    return debt() - liquidationReserve;
  }

  /**
   * @dev the value of the collateral * the current price as returned by the price feed contract for the collateral token
   */
  function collateralValue() public view override returns (uint256) {
    return (collateral() * factory.tokenToPriceFeed().tokenPrice(address(token))) / DECIMAL_PRECISION;
  }

  /**
   * @dev the Individual Collateralisation Ratio (ICR) of the trove
   */
  function collateralization() public view override returns (uint256) {
    uint256 troveDebt = debt();
    if (troveDebt > 0) {
      return (DECIMAL_PRECISION * collateralValue()) / troveDebt;
    } else {
      return MAX_INT;
    }
  }

  /**
   * @dev the Individual Collateralisation Ratio (ICR) of the trove. this private function can be used when it is certain
   * that the _debt state variable has been updated correctly beforehand
   */
  function _collateralization() private view returns (uint256) {
    if (_debt > 0) {
      // the token price is multiplied by DECIMAL_PRECISION
      return (recordedCollateral * factory.tokenToPriceFeed().tokenPrice(address(token))) / _debt;
    } else {
      return MAX_INT;
    }
  }

  /**
   * @dev transfers user's trove ownership after revoking other roles from other addresses
   * @param _newOwner the address of the new owner
   */
  function transferOwnership(address _newOwner) public override(Ownable, IOwnable) {
    Ownable.transferOwnership(_newOwner);
    for (uint256 i = getRoleMemberCount(OWNER_ROLE); i > 0; i--) {
      _revokeRole(OWNER_ROLE, getRoleMember(OWNER_ROLE, i - 1));
    }
    _initializeMainOwners(_newOwner, address(factory));
  }

  /**
   * @dev add an address to the list of owners
   * @param _newOwner the address of the new owner
   */
  function addOwner(address _newOwner) public onlyTroveOwner {
    _grantRole(OWNER_ROLE, _newOwner);
  }

  /**
   * @dev add an address to the list of owners
   * @param _ownerToRemove the address of the new owner
   */
  function removeOwner(address _ownerToRemove) public onlyTroveOwner {
    require(owner() != _ownerToRemove, "604e3 do not remove main owner");
    _revokeRole(OWNER_ROLE, _ownerToRemove);
  }

  /**
   * @dev used to set the OWNER_ROLE for _troveOwner and _factory
   * @param _troveOwner the address of the new owner
   * @param _factory the address of the factory
   */
  function _initializeMainOwners(address _troveOwner, address _factory) private {
    _grantRole(OWNER_ROLE, _troveOwner);
    _grantRole(OWNER_ROLE, _factory);
  }

  /**
   * @dev insert the trove in the factory contract in the right spot of the list of troves with the same token
   * @param _newNextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   */
  function insertTrove(address _newNextTrove) private {
    // insertTrove is only called after updateCollateral has been invoked and the _debt variable has been updated
    require(_collateralization() >= mcr(), "41670 TCR must be > MCR");
    // only call insertTrove if there are more than one troves in the list
    address tokenAddress = address(token);
    if (factory.troveCount(tokenAddress) > 1) {
      factory.insertTrove(tokenAddress, _newNextTrove);
    }
  }

  /**
   * @dev mint some stable coins and pay the issuance fee. The transaction will fail if the resulting ICR < MCR
   * @param _recipient is the address to which the newly minted tokens will be transferred
   * @param _amount the value of the minting
   * @param _newNextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   */
  function borrow(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) public override onlyTroveOwner whenFactoryNotPaused {
    uint256 feeAmount = _borrow(_amount, _newNextTrove);
    IERC20(factory.stableCoin()).safeTransfer(_recipient, _amount);
    // the event is emitted by the factory so that we don't need to spy on each trove to get the system status in PGSQL
    factory.emitTroveDebtUpdate(address(token), _debt, _collateralization(), feeAmount);
  }

  /**
   * @dev mint some stable coins and pay the issuance fee. The transaction will fail if the resulting ICR < MCR
   * @param _recipient is the address to which the newly minted tokens will be transferred
   * @param _amount the value of the minting
   * @param _newNextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   * @param _routerAddress DEX router contract address
   * @param _path DEX router swap path, consists of tokens addresses
   * @param _maxSlippage DEX router max slippage, the minimum value that can be received after swap
   * @param _deadline DEX router operation deadline
   */
  function borrowAndSwap(
    address _recipient,
    uint256 _amount,
    address _newNextTrove,
    address _routerAddress,
    address[] calldata _path,
    uint256 _maxSlippage,
    uint256 _deadline
  ) public onlyTroveOwner {
    uint256 feeAmount = _borrow(_amount, _newNextTrove);
    _swap(_recipient, _amount, _routerAddress, _path, _maxSlippage, _deadline);
    // the event is emitted by the factory so that we don't need to spy on each trove to get the system status in PGSQL
    factory.emitTroveDebtUpdate(address(token), _debt, _collateralization(), feeAmount);
  }

  /**
   * @dev repay a portion of the debt by either sending some stable coins to the trove or allowing the trove to take tokens out of your balance
   * @param _amount the amount of stable coins to reduce the debt with
   * @param _newNextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   */
  function repay(uint256 _amount, address _newNextTrove) public override {
    // updates collateral and debt state variables hence there is no need to call the debt() function later
    _updateCollateral();
    require(_debt > 0, "e37b2 debt must be gt than 0");
    IMintableToken stableCoin = factory.stableCoin();
    uint256 liquidationReserve_cache = liquidationReserve;
    if (_amount > 0) {
      _amount = _amount.min(_debt - liquidationReserve_cache);
      IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), _amount);
    } else {
      _amount = _debt.min(stableCoin.balanceOf(address(this)) - liquidationReserve_cache);
      require(_amount > 0, "e37b2 insufficient funds");
    }

    stableCoin.burn(_amount);
    _debt -= _amount;
    if (_debt == liquidationReserve_cache) {
      stableCoin.burn(liquidationReserve_cache);
      _amount += liquidationReserve_cache;
      _debt = 0;
      liquidationReserve = 0;
    }
    // reduce total debt (false == reduction)
    factory.updateTotalDebt(_amount, false);
    insertTrove(_newNextTrove);

    factory.emitTroveDebtUpdate(address(token), _debt, _collateralization(), 0);
  }

  /**
   * @dev if there have been liquidations since the last time this trove's state was updated, it should fetch the available rewards and debt
   */
  function getLiquidationRewards() internal {
    IERC20 token_cache = token;
    ILiquidationPool pool = factory.liquidationPool(address(token_cache));
    uint256 currentLiqTokenRate = pool.liqTokenRate();
    (uint256 unclaimedCollateral, uint256 unclaimedDebt) = _unclaimedCollateralRewardAndDebt(pool, currentLiqTokenRate);
    if (unclaimedCollateral > 0) {
      pool.claimCollateralAndDebt(unclaimedCollateral, unclaimedDebt);
      recordedCollateral += unclaimedCollateral;
      _debt += unclaimedDebt;
      liqTokenRateSnapshot = currentLiqTokenRate;
      if (arbitrageParticipation) {
        arbitrageState.arbitragePool.deposit(address(token_cache), unclaimedCollateral);
        arbitrageState.lastApPrice = arbitrageState.arbitragePool.getAPtokenPrice(address(token_cache));
      }
    }
  }

  /**
   * @dev mint some stable coins and pay the issuance fee. The transaction will fail if the resulting ICR < MCR
   * @param _amount the value of the minting
   * @param _newNextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   * @param _feeAmount it's the minting fee
   */
  function _borrow(uint256 _amount, address _newNextTrove) private returns (uint256 _feeAmount) {
    require(_amount >= DECIMAL_PRECISION, "cb29c amount must be gt 1 token");
    _updateCollateral();
    IFeeRecipient feeRecipient = factory.feeRecipient();
    _feeAmount = factory.getBorrowingFee(_amount);
    uint256 amountToMint = _amount + _feeAmount;

    if (liquidationReserve == 0) {
      liquidationReserve = LIQUIDATION_RESERVE;
      amountToMint += LIQUIDATION_RESERVE;
    }
    _debt += amountToMint;
    insertTrove(_newNextTrove);
    factory.tokenOwner().mint(address(this), amountToMint);
    feeRecipient.takeFees(_feeAmount);
    // TODO: add debt to the parameters and call emitTroveDebtUpdate from updateTotalDebt to avoid two calls
    factory.updateTotalDebt(amountToMint, true);
  }

  function _swap(
    address _recipient,
    uint256 _amount,
    address _routerAddress,
    address[] memory _path,
    uint256 _maxSlippage,
    uint256 _deadline
  ) private {
    IRouter router = IRouter(_routerAddress);
    factory.stableCoin().approve(_routerAddress, _amount);
    router.swapExactTokensForTokens(_amount, _maxSlippage, _path, _recipient, _deadline);
  }

  /**
   * @dev the reward in the liquidation pool which has not been claimed yet
   */
  function _unclaimedCollateralRewardAndDebt(ILiquidationPool _pool, uint256 _currentLiqTokenRate)
    private
    view
    returns (uint256, uint256)
  {
    uint256 _liqTokenRateSnapshot = liqTokenRateSnapshot;
    // we use the recordedCollateral because the collateralPerStakedToken is computed with the explicitly added collateral only
    uint256 unclaimedCollateral;
    uint256 unclaimedDebt;

    if (_currentLiqTokenRate > _liqTokenRateSnapshot) {
      uint256 poolCollateral = _pool.collateral();
      if (poolCollateral > 0) {
        uint256 recordedCollateralCache = recordedCollateral;

        unclaimedCollateral =
          ((recordedCollateralCache * _currentLiqTokenRate) / _liqTokenRateSnapshot) -
          recordedCollateralCache;
        unclaimedDebt = (_pool.debt() * unclaimedCollateral) / _pool.collateral();
      }
    }
    return (unclaimedCollateral, unclaimedDebt);
  }

  /**
   * @dev update the state variables recordedCollateral and rewardRatioSnapshot and get all the collateral into the trove
   */
  function _updateCollateral() private returns (uint256) {
    getLiquidationRewards();
    uint256 startRecordedCollateral = recordedCollateral;
    // make sure all tokens sent to or transferred out of the contract are taken into account
    IERC20 token_cache = token;
    uint256 newRecordedCollateral;
    if (arbitrageParticipation) {
      uint256 tokenBalance = token_cache.balanceOf(address(this));
      if (tokenBalance > 0) arbitrageState.arbitragePool.deposit(address(token_cache), tokenBalance);
      newRecordedCollateral = arbitrageState.apToken.balanceOf(address(this));
      arbitrageState.lastApPrice = arbitrageState.arbitragePool.getAPtokenPrice(address(token_cache));
    } else {
      newRecordedCollateral = token_cache.balanceOf(address(this));
    }
    recordedCollateral = newRecordedCollateral;
    // getLiquidationRewards updates recordedCollateral

    if (newRecordedCollateral != startRecordedCollateral) {
      factory.updateTotalCollateral(
        address(token_cache),
        newRecordedCollateral.max(startRecordedCollateral) - newRecordedCollateral.min(startRecordedCollateral),
        newRecordedCollateral >= startRecordedCollateral
      );
    }
    return newRecordedCollateral;
  }

  /**
   * @dev there are two options to increase the collateral:
   * 1. transfer the tokens to the trove and call increaseCollateral with amount = 0
   * 2. grant the trove permission to transfer from your account and call increaseCollateral with amount > 0
   * @param _amount a positive amount to transfer from the sender's account or zero
   * @param _newNextTrove once the trove is better collateralised, its position in the list will change, the caller
   * should indicate the new position in order to reduce gas consumption
   */
  function increaseCollateral(uint256 _amount, address _newNextTrove) public override {
    IERC20 token_cache = token;
    if (_amount > 0) {
      token_cache.safeTransferFrom(msg.sender, address(this), _amount);
    }
    uint256 newRecordedCollateral = _updateCollateral();

    if (_debt > 0) {
      insertTrove(_newNextTrove);
    }
    factory.emitTroveCollateralUpdate(address(token_cache), newRecordedCollateral, _collateralization());
  }

  /**
   * @dev send some or all of the balance of the trove to an arbitrary address. Only the owner of the trove can do this
   * as long as the debt is Zero, the transfer is performed without further checks.
   * once the debt is not zero, the trove position in the trove list is changed to keep the list ordered by
   * collateralisation ratio
   * @param _recipient the address which will receive the tokens
   * @param _amount amount of collateral
   * @param _newNextTrove hint for next trove after reorder
   */
  function decreaseCollateral(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) public override onlyTroveOwner {
    // make sure all the tokens are held by the trove before attempting to transfer
    getLiquidationRewards();
    IERC20 token_cache = token;
    if (arbitrageParticipation) {
      uint256 withdrawAmount = (_amount * DECIMAL_PRECISION) /
        arbitrageState.arbitragePool.getAPtokenPrice(address(token_cache));
      arbitrageState.arbitragePool.withdraw(address(token_cache), withdrawAmount);
    }
    /* solhint-disable reentrancy */
    // recordedCollateral is updated by calling _updateCollateral() before borrowing, repaying or increasing collateral.
    // Calling this function in a reentrant way would not allow the attacker to get anything more
    token_cache.safeTransfer(_recipient, _amount);
    uint256 newRecordedCollateral = _updateCollateral();
    /* solhint-disable reentrancy */

    if (_debt > 0) {
      // the ICR will be checked in insertTrove
      insertTrove(_newNextTrove);
    }
    factory.emitTroveCollateralUpdate(address(token_cache), newRecordedCollateral, _collateralization());
  }

  /**
   * @dev is called to redeem StableCoin for token, called by factory when MCR > ICR,
   * amount of StableCoin is taken from balance and must be <= netDebt.
   * uses priceFeed to calculate collateral amount.
   * returns amount of StableCoin used and collateral recieved
   * @param _recipient the address which recieves redeemed token
   * @param _newNextTrove hint for next trove after reorder, if it's not full redemption
   */
  function redeem(address _recipient, address _newNextTrove)
    public
    override
    onlyFactory
    returns (uint256 _stableAmount, uint256 _collateralRecieved)
  {
    getLiquidationRewards();
    require(mcr() <= _collateralization(), "e957f TCR must be gte MCR");
    _stableAmount = factory.stableCoin().balanceOf(address(this)) - liquidationReserve;
    require(
      _newNextTrove == address(0) ? _stableAmount == netDebt() : _stableAmount <= netDebt(),
      "e957f amount != debt and no hint"
    );

    IERC20 token_cache = token;

    uint256 collateralToTransfer = (_stableAmount * DECIMAL_PRECISION) /
      factory.tokenToPriceFeed().tokenPrice(address(token_cache));

    if (arbitrageParticipation) {
      uint256 withdrawAmount = (collateralToTransfer * DECIMAL_PRECISION) /
        arbitrageState.arbitragePool.getAPtokenPrice(address(token_cache));
      arbitrageState.arbitragePool.withdraw(address(token_cache), withdrawAmount);
    }

    token_cache.safeTransfer(_recipient, collateralToTransfer);
    _collateralRecieved = collateralToTransfer;

    repay(0, _newNextTrove); // repays from trove balance transfered before call
    return (_stableAmount, _collateralRecieved);
  }

  /**
   * @dev is called to liquidate the trove, if ICR < MCR then all the collateral is sent to the liquidation pool and the debt is forgiven
   * the msg.sender is allowed to transfer the liquidation reserve out of the trove
   */
  function liquidate() public {
    _updateCollateral();
    require(_collateralization() < mcr(), "454f4 CR must lt MCR");
    IERC20 token_cache = token;
    IStabilityPool stabilityPool = factory.stabilityPool();
    // allow the sender to retrieve the liquidationReserve
    factory.stableCoin().approve(msg.sender, liquidationReserve);
    if (arbitrageParticipation) {
      setArbitrageParticipation(false);
    }
    if (
      !Pausable(address(factory)).paused() &&
      (_collateralization() > DECIMAL_PRECISION) &&
      (stabilityPool.totalDeposit() >= debt())
    ) {
      token_cache.safeApprove(address(stabilityPool), recordedCollateral);
      // the collateral is transferred to the stabilityPool and is not used as collateral anymore
      factory.updateTotalCollateral(address(token_cache), recordedCollateral, false);
      factory.updateTotalDebt(_debt, false);
      stabilityPool.liquidate();
    } else {
      ILiquidationPool pool = factory.liquidationPool(address(token_cache));
      token_cache.safeApprove(address(pool), recordedCollateral);
      pool.liquidate();
      liqTokenRateSnapshot = pool.liqTokenRate();
    }
    _debt -= liquidationReserve;
    emit Liquidated(address(this), _debt, recordedCollateral);
    _debt = 0;
    liquidationReserve = 0;
    recordedCollateral = 0;
    // liquidated troves have no debt and no collateral and should be removed from the list of troves
    factory.removeTrove(address(token_cache), address(this));
  }

  /**
   * @dev security function to make sure that if tokens are sent to the trove by mistake, they're not lost.
   * It will always send the entire balance
   * This function can not be used to transfer the collateral token
   * @param _token the ERC20 to transfer
   * @param _recipient the address the transfer should go to
   */
  function transferToken(address _token, address _recipient) public onlyTroveOwner {
    require(_token != address(token), "7a810 can't transfer collateral");
    require(_token != address(factory.stableCoin()), "7a810 can't transfer stable coin");
    uint256 _amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  /**
   * @dev configuration function to enable or disable collateral participation in ArbitragePool
   * @param _state true/false to turn the state on/off
   */
  function setArbitrageParticipation(bool _state) public override onlyTroveOwner {
    if (arbitrageParticipation == _state) return;
    _updateCollateral();
    IERC20 tokenCache = token;
    arbitrageParticipation = _state;
    IArbitragePool _arbitragePool = IArbitragePool(factory.arbitragePool());
    if (_state) {
      tokenCache.safeApprove(address(_arbitragePool), MAX_INT);
      IMintableToken _apToken = _arbitragePool.collateralToAPToken(address(tokenCache));
      _apToken.approve(address(_arbitragePool), MAX_INT);
      arbitrageState.arbitragePool = _arbitragePool;
      arbitrageState.apToken = _apToken;
      uint256 tokenBalance = tokenCache.balanceOf(address(this));
      if (tokenBalance > 0) _arbitragePool.deposit(address(tokenCache), tokenBalance);
      arbitrageState.lastApPrice = _arbitragePool.getAPtokenPrice(address(tokenCache));
    } else {
      tokenCache.safeApprove(address(_arbitragePool), 0);
      uint256 arbitrageBalance = arbitrageState.apToken.balanceOf(address(this));
      if (arbitrageBalance > 0) arbitrageState.arbitragePool.withdraw(address(tokenCache), arbitrageBalance);
      delete arbitrageState;
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";

library BONQMath {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

  /// @dev return the smaller of two numbers
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /// @dev return the bigger of two numbers
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  /**
   * @dev Multiply two decimal numbers and use normal rounding rules:
   *  -round product up if 19'th mantissa digit >= 5
   *  -round product down if 19'th mantissa digit < 5
   *
   * Used only inside the exponentiation, _decPow().
   */
  function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
    uint256 prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  /**
   * @dev Exponentiation function for 18-digit decimal base, and integer exponent n.
   *
   * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
   *
   * Called by function that represent time in units of minutes:
   * 1) IFeeRecipient.calcDecayedBaseRate
   *
   * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
   * "minutes in 1000 years": 60 * 24 * 365 * 1000
   *
   * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
   * negligibly different from just passing the cap, since:
   * @param _base number to exponentially increase
   * @param _minutes power in minutes passed
   */
  function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
    if (_minutes > 525600000) {
      _minutes = 525600000;
    } // cap to avoid overflow

    if (_minutes == 0) {
      return DECIMAL_PRECISION;
    }

    uint256 y = DECIMAL_PRECISION;
    uint256 x = _base;
    uint256 n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else {
        // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Constants {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant LIQUIDATION_RESERVE = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant PERCENT = (DECIMAL_PRECISION * 1) / 100; // 1%
  uint256 public constant PERCENT10 = PERCENT * 10; // 10%
  uint256 public constant PERCENT_05 = PERCENT / 2; // 0.5%
  uint256 public constant BORROWING_RATE = PERCENT_05;
  uint256 public constant MAX_BORROWING_RATE = (DECIMAL_PRECISION * 5) / 100; // 5%
}