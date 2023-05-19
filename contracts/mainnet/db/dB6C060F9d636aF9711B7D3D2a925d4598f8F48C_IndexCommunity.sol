// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title an extension that allows you to stop the operation of functions
abstract contract ExtensionPause {
    /// @notice the event is triggered when the status changes
    event SetPause(bool status);

    /// @notice the error occurs when trying to call a function that is on pause
    error PauseActive();

    bool internal _pause;

    modifier isPause() {
        if (_pause == true) {
            revert PauseActive();
        }
        _;
    }

    /// @notice calling a function suspends or starts functions using the "isPause" modifier
    function _changeStatusPause() internal {
        _pause = _pause ? false : true;
        emit SetPause(_pause);
    }

    /// @notice returns the pause state
    /// @return status true - means that the operation of functions using the "isPause" modifier is stopped
    /// * false- means that the functions using the "isPause" modifier are working
    function _statusPause() internal view returns (bool status) {
        return (_pause);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface IIndex {
    event Initialize(address adminDAO, address admin, address USD, address lp);
    event Rebalance(Asset[] assets, uint256 oldPrice, uint256 newPrice);
    event Init(Asset[] assets, uint256 indexPrice);
    event Stake(address indexed account, uint256 amountUSD, uint256 amountLP);
    event Unstake(address indexed account, uint256 amountLP);
    event SetRebalancePeriod(uint256 period);

    event SetFeeUnStake(uint256 newFee);
    event SetSlippage(uint256 newSlippage);
    event SetFeeStake(uint256 newFee);
    event SetActualToken(address newActualToken);
    event SetName(string name);

    error ZeroAmount();
    error InvalidStake();
    error Initializer();
    error RebalancePrice(uint256 priceAdmin, uint256 priceSM);
    error InvalidMinAmount(uint256 minAmount, uint256 amount);

    error InvalidAsset(address asset);

    struct Asset {
        address asset;
        address[] path;
        uint256 fixedAmount;
        uint256 totalAmount;
        uint256 share;
    }
    struct AssetData {
        address asset;
        address[] path;
        uint256 share;
    }

    /**
     * @notice Stops the work of the contract.
     * Blocks a call to the "stake" method.
     * Users can withdraw their funds
     */
    function setPause() external;

    /**
     * @notice  Set a new index name
     */
    function setNameIndex(string memory name) external;

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeStake(uint256 fee) external;

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeUnStake(uint256 fee) external;

    /**
     * @notice Sets the new address of the token. Used to pay for the index
     * changes will take effect after rebalancing
     */
    function setActualToken(address newToken) external;

    /**
     * @notice Setting the initial assets in the index
     */
    function init(AssetData[] memory newAssets) external;

    /**
     * @notice  Reconfiguring the index
     * @param newAssets - New assets that will be included in the index after rebalancing
     * @param path - Specify the path to exchange "_actualAcceptToken" to "_newAcceptToken".
     * The exchange will take place on quickSwap
     */
    function rebalance(
        AssetData[] memory newAssets,
        address[] memory path,
        uint256 calculatedPrice
    ) external;

    /**
     * @notice Buying an index
     * @param amountLP - The number of indexes that will be purchased
     * @param amountUSD - Number of tokens spent
     */
    function stake(uint256 amountLP, uint256 amountUSD) external;

    /**
     * @notice Buying an index for ETH
     * @param amountLP The number of indexes that will be purchased
     */
    function stakeETH(uint256 amountLP) external payable;

    /**
     * @notice Selling the index
     */
    function unstake(uint256 amountLP, uint256 minAmount) external;

    /// @notice Returns the pause state
    /// @return status True - means that the operation of functions using the "isPause" modifier is stopped
    /// * False- means that the functions using the "isPause" modifier are working
    function getStatusPause() external view returns (bool status);

    /**
     * @notice Returns the index name
     */
    function getNameIndex() external view returns (string memory nameIndex);

    /**
     * @notice Returns the timestamp of the last rebalance
     */
    function getLastRebalance() external view returns (uint256);

    /**
     * @notice Returns a list of assets that will be included in the index after rebalancing
     */
    function getNewAssets() external view returns (address[] memory newAssets);

    /**
     * @notice Returns information about the index
     * @param indexLP LP token address
     * @param maxShare The maximum share of an asset in the index
     * @param rebalancePeriod The time after which the rebalancing takes place
     * @param startPriceIndex Initial index price
     */
    function getDataIndex()
        external
        view
        returns (
            address indexLP,
            uint256 maxShare,
            uint256 rebalancePeriod,
            uint256 startPriceIndex
        );

    /**
     * @notice Returns an array of assets included in the index
     * @return assets An array of assets included in the index with all information about them
     */
    function getActiveAssets() external view returns (Asset[] memory assets);

    /**
     * @notice Returns the LP price
     */
    function getCostLP(
        uint256 amountLP
    ) external view returns (uint256 amountUSD);

    /**
     * @notice Returns commissions
     */
    function getFees()
        external
        view
        returns (uint256 feeStake, uint256 feeUnstake);

    /**
     * @notice Returns the address of the token accepted as payment
     */
    function getAcceptToken()
        external
        view
        returns (address actualAddress, address newAddress);

    /**
     * @notice Returns the number of assets in the rebalancing queue
     */
    function lengthNewAssets() external view returns (uint256 len);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IIndexCommunity {
    /// @notice Initialization of the main parameters
    /// @param adminDAO the address that has the right to call functions with the "DAO_ADMIN_ROLE" role
    /// @param admin the address that has the right to call functions with the "ADMIN_ROLE" role
    /// @param acceptToken the token in which the payment is accepted
    /// @param adapter adapter DEX
    /// @param startPrice initial index price
    /// @param rebalancePeriod the time after which rebalancing occurs (seconds)
    /// @param newAssets array with asset addresses
    /// @param tresuare a commission will be sent to this address
    /// @param partnerProgram partner Program
    /// @param nameIndex name Index
    function initialize(
        address adminDAO,
        address admin,
        address acceptToken,
        address adapter,
        uint256 startPrice,
        uint256 rebalancePeriod,
        address[] memory newAssets,
        address tresuare,
        address partnerProgram,
        address communityDAO,
        string memory nameIndex
    ) external;

    /// @notice Set Rebalance period
    function setRebalancePeriod(uint256 period) external;

    /// @notice Increase the maximum number of assets in the index
    function incrementMaxAssets() external;

    /// @notice Reduces the maximum number of assets in the index
    function decrementMaxAssets() external;

    /// @notice Removes an asset from the list, after rebalancing, this asset will not be
    function excludeAsset(address asset) external;

    /// @notice Adds an asset to the list, after rebalancing this asset will be added to the index
    function includeAsset(address asset) external;

    /// @notice Returns the maximum fraction
    function getMaxAssets() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/interfaces/IWETH.sol";
import "../partnerProgram/IPartnerProgram.sol";
import "./IIndex.sol";
import "contracts/IndexLP.sol";
import "contracts/extension/ExtensionPause.sol";

abstract contract Index is
    AccessControl,
    IIndex,
    ReentrancyGuard,
    ExtensionPause
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private _newAssets;

    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 constant PRECISION = 1e18;
    uint256 constant PRECISION_E6 = 1e6;

    string private _nameIndex;

    uint256 private _feeStake;
    uint256 private _feeUnstake;
    uint256 private _amountTax;
    uint256 private _maxShare;
    uint256 private _rebalancePeriod;
    uint256 private _lastRebalance;
    uint256 private _startPriceIndex;

    address private _indexLP;
    address private _actualAcceptToken;
    address private _adapter;
    address private _treasure;
    address public _wETH;
    address private _newAcceptToken;

    bool private _initializer;
    bool _init;
    uint256 public _slippage;

    IPartnerProgram private _ipartnerProgram;

    Asset[] private _activeAssets;

    modifier isZeroAmount(uint256 amount) {
        if (amount <= 0) {
            revert ZeroAmount();
        }
        _;
    }

    /// @notice The modifier prevents the possibility of reuse
    modifier isInitializer() {
        if (_initializer == true) {
            revert Initializer();
        }
        _;
        _initializer = true;
    }

    /**
     * @notice Stops the work of the contract.
     * Blocks a call to the "stake" method.
     * Users can withdraw their funds
     */
    function setPause() external onlyRole(DAO_ADMIN_ROLE) {
        _changeStatusPause();
    }

    /**
     * @notice  Set a new index name
     */
    function setNameIndex(string memory name) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(DAO_ADMIN_ROLE, msg.sender),
            "InvalidRole"
        );
        _nameIndex = name;
        emit SetName(name);
    }

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeStake(uint256 fee) external onlyRole(DAO_ADMIN_ROLE) {
        require(fee < PRECISION_E6 * 100, "Invalid fee");
        _feeStake = fee;

        emit SetFeeStake(fee);
    }

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeUnStake(uint256 fee) external onlyRole(DAO_ADMIN_ROLE) {
        require(fee < PRECISION_E6 * 100, "Invalid fee");
        _feeUnstake = fee;

        emit SetFeeUnStake(fee);
    }

    /**
     * @notice Sets the new address of the token. Used to pay for the index
     * changes will take effect after rebalancing
     */
    function setActualToken(
        address newToken
    ) external onlyRole(DAO_ADMIN_ROLE) {
        require(newToken != address(0), "Invalid Token");
        _newAcceptToken = newToken;
        emit SetActualToken(newToken);
    }

    /**
     * The _slippage parameter is needed when calling the rebalance function.
     * To compare the cost of 1LP calculated on the backend side and the smart contract
     * @dev Enter data taking into account precision.
     */
    function setSlippage(uint256 slippage) external onlyRole(DAO_ADMIN_ROLE) {
        require(slippage <= PRECISION_E6 * 10, "Invalid fee");
        _slippage = slippage;

        emit SetSlippage(slippage);
    }

    /**
     * @notice Setting the initial assets in the index
     */
    function init(AssetData[] memory newAssets) external onlyRole(ADMIN_ROLE) {
        require(!_init, "already initialized");
        _rebalance(newAssets, _startPriceIndex);

        uint256 firstPriceIndex = _calcCost(1e18);

        _init = true;
        emit Init(_activeAssets, firstPriceIndex);
    }

    /**
     * @notice  Reconfiguring the index
     * @param newAssets - New assets that will be included in the index after rebalancing
     * @param path - Specify the path to exchange "_actualAcceptToken" to "_newAcceptToken".
     * The exchange will take place on quickSwap
     */
    function rebalance(
        AssetData[] memory newAssets,
        address[] memory path,
        uint256 calculatedPrice
    ) external onlyRole(ADMIN_ROLE) {
        require(
            block.timestamp > _lastRebalance + _rebalancePeriod,
            "It is not possible to rebalance"
        );
        uint256 oldPrice = _calcCost(1e18); // calculate the cost of 1 LP
        uint256 usdAmount = _exchangeToUSD(); // the value of all assets in USD

        if (_actualAcceptToken != _newAcceptToken) {
            usdAmount = _changeActualToken(usdAmount, path); //replacement of the accepted token from the user
        }

        // we exchange USD for assets included in the index
        _rebalance(newAssets, usdAmount);
        uint256 newPrice = _calcCost(1e18);

        uint256 discrepancy;
        if (calculatedPrice >= newPrice)
            discrepancy = calculatedPrice - newPrice;
        else discrepancy = newPrice - calculatedPrice;

        uint v = (_slippage * calculatedPrice) / (100 * PRECISION_E6);

        if (v < discrepancy) {
            revert RebalancePrice(calculatedPrice, newPrice);
        }

        emit Rebalance(_activeAssets, oldPrice, newPrice);
    }

    /**
     * @notice Buying an index
     * @param amountLP - The number of indexes that will be purchased
     * @param amountUSD - Number of tokens spent + slippage
     */
    function stake(
        uint256 amountLP,
        uint256 amountUSD
    ) external isZeroAmount(amountLP) isPause {
        // debiting tokens from the user to the contract
        IERC20(_actualAcceptToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountUSD
        );

        _stake(amountLP, amountUSD);
    }

    /**
     * @notice Buying an index for ETH
     * @dev msg.value - Number of tokens spent + slippage
     * @param amountLP The number of indexes that will be purchased
     */
    function stakeETH(
        uint256 amountLP
    ) external payable isZeroAmount(amountLP) isPause nonReentrant {
        require(
            _actualAcceptToken == _wETH,
            "The current accepted token is not ETH"
        );
        IWETH(_wETH).deposit{value: msg.value}();

        _stake(amountLP, msg.value);
    }

    /**
     * @notice Selling the LP
     */
    function unstake(
        uint256 amountLP,
        uint256 minAmount
    ) external isZeroAmount(amountLP) {
        (uint256 amountLPWithoutTax, uint256 tax) = _taxation(
            amountLP,
            _feeUnstake
        ); // calculation of the withdrawal fee
        _amountTax += tax;
        _unstake(amountLPWithoutTax, minAmount);

        IndexLP(_indexLP).burn(msg.sender, amountLP); // burning LP
        IndexLP(_indexLP).mint(_treasure, tax); // mint the tax to the treasure

        emit Unstake(msg.sender, amountLP);
    }

    /// @notice Returns the pause state
    /// @return status True - means that the operation of functions using the "isPause" modifier is stopped.
    /// * False- means that the functions using the "isPause" modifier are working

    function getStatusPause() external view returns (bool status) {
        return _statusPause();
    }

    /**
     * @notice Returns the index name
     */
    function getNameIndex() external view returns (string memory nameIndex) {
        return _nameIndex;
    }

    /**
     * @notice Returns the timestamp of the last rebalance
     */
    function getLastRebalance() external view returns (uint256) {
        return _lastRebalance;
    }

    /**
     * @notice Returns a list of assets that will be included in the index after rebalancing
     */
    function getNewAssets() external view returns (address[] memory newAssets) {
        uint256 len = _newAssets.length();
        newAssets = new address[](len);
        for (uint256 i; i < len; i++) {
            newAssets[i] = _newAssets.at(i);
        }
    }

    /**
     * @notice Returns information about the index
     * @param indexLP LP token address
     * @param maxShare The maximum share of an asset in the index
     * @param rebalancePeriod The time after which the rebalancing takes place
     * @param startPriceIndex Initial index price
     */
    function getDataIndex()
        external
        view
        returns (
            address indexLP,
            uint256 maxShare,
            uint256 rebalancePeriod,
            uint256 startPriceIndex
        )
    {
        return (_indexLP, _maxShare, _rebalancePeriod, _startPriceIndex);
    }

    /**
     * @notice Returns an array of assets included in the index
     * @return assets An array of assets included in the index with all information about them
     */
    function getActiveAssets() external view returns (Asset[] memory assets) {
        return _activeAssets;
    }

    /**
     * @notice Returns the LP price
     */
    function getCostLP(
        uint256 amountLP
    ) external view returns (uint256 amountUSD) {
        return _calcCost(amountLP);
    }

    /**
     * @notice Returns commissions
     */
    function getFees()
        external
        view
        returns (uint256 feeStake, uint256 feeUnstake)
    {
        return (_feeStake, _feeUnstake);
    }

    /**
     * @notice Returns the address of the token accepted as payment
     */
    function getAcceptToken()
        external
        view
        returns (address actualAddress, address newAddress)
    {
        return (_actualAcceptToken, _newAcceptToken);
    }

    function getTax() external view returns (uint256 tax) {
        return _amountTax;
    }

    /**
     * @notice Returns the number of assets in the rebalancing queue
     */
    function lengthNewAssets() public view returns (uint256 len) {
        return _newAssets.length();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IIndex).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice  Set the rebalancing period.
    /// After this time, it will be possible to call the "rebalance" function
    function _setRebalancePeriod(uint256 period) internal {
        _rebalancePeriod = period;

        emit SetRebalancePeriod(period);
    }

    ///@notice initialization of the main parameters
    /// @param adminDAO the address that has the right to call functions with the "DAO_ADMIN_ROLE" role
    /// @param admin the address that has the right to call functions with the "ADMIN_ROLE" role
    /// @param acceptToken the token in which the payment is accepted
    /// @param adapter adapter DEX
    /// @param startPrice initial index price
    /// @param rebalancePeriod the time after which rebalancing occurs (seconds)
    /// @param newAssets array with asset addresses
    /// @param treasure a commission will be sent to this address
    /// @param partnerProgram partner Program
    /// @param nameIndex name Index
    function _initialize(
        address adminDAO,
        address admin,
        address acceptToken,
        address adapter,
        uint256 startPrice,
        uint256 rebalancePeriod,
        address[] memory newAssets,
        address treasure,
        address partnerProgram,
        string memory nameIndex
    ) internal isInitializer {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DAO_ADMIN_ROLE, adminDAO);
        _setupRole(ADMIN_ROLE, admin);

        _actualAcceptToken = acceptToken;
        _newAcceptToken = acceptToken;

        _adapter = adapter;
        _wETH = IUniswapV2Router01(adapter).WETH();
        _startPriceIndex = startPrice;
        _maxShare = 20 * PRECISION_E6;
        _rebalancePeriod = rebalancePeriod;
        _indexLP = _deployIndexLP(partnerProgram);
        _treasure = treasure;
        _ipartnerProgram = IPartnerProgram(partnerProgram);
        _nameIndex = nameIndex;
        _approveDEX(acceptToken);
        _updateNewAssets(newAssets);
        emit Initialize(adminDAO, admin, acceptToken, _indexLP);
    }

    function _stake(uint256 amountLP, uint256 deposit) internal {
        (uint256 amountLPWithoutTax, uint256 tax) = _taxation(
            amountLP,
            _feeStake
        ); //calculation of the commission for "stake"
        _amountTax += tax;

        uint256 stakeCost = _calcStake(amountLP);
        require(deposit >= stakeCost && stakeCost != 0, "InvalidCost");
        _ipartnerProgram.distributeTheReward(msg.sender, amountLP, _indexLP);

        IndexLP(_indexLP).mint(msg.sender, amountLPWithoutTax);
        IndexLP(_indexLP).mint(_treasure, tax);

        uint256 refundAmount = deposit - stakeCost;
        // refund of excess funds
        if (_actualAcceptToken != _wETH) {
            IERC20(_actualAcceptToken).safeTransfer(msg.sender, refundAmount);
        } else {
            IWETH(_wETH).withdraw(refundAmount);
            msg.sender.call{value: refundAmount}("");
        }

        emit Stake(msg.sender, stakeCost, amountLPWithoutTax);
    }

    function _swapDEX(
        uint256 amountForSwap,
        address[] memory path
    ) internal returns (uint256 amount) {
        uint256[] memory amounts = IUniswapV2Router02(_adapter)
            .swapExactTokensForTokens(
                amountForSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
        return amounts[path.length - 1];
    }

    function _swapStake(
        uint256 amountForSwap,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amount, uint256 cost) {
        uint256[] memory amounts = IUniswapV2Router02(_adapter)
            .swapTokensForExactTokens(
                amountForSwap,
                amountInMax,
                path,
                address(this),
                block.timestamp
            );
        return (amounts[path.length - 1], amounts[0]);
    }

    /// @notice we exchange all tokens on the contract for USD
    function _exchangeToUSD() internal returns (uint256 sum) {
        uint256 len = _activeAssets.length;

        for (uint256 i; i < len; i++) {
            if (_activeAssets[i].totalAmount != 0) {
                address[] memory reversPath = _reversArray(
                    _activeAssets[i].path
                );
                uint256 amount = _swapDEX(
                    _activeAssets[i].totalAmount,
                    reversPath
                );

                sum += amount;
            }
        }
    }

    function _updateNewAssets(address[] memory assets) internal {
        uint256 len = assets.length;
        require((PRECISION_E6 * 100) / len <= _maxShare, "Invalid MaxShare");
        for (uint256 i; i < len; i++) {
            _addAssetInNewAssets(assets[i]);
        }
    }

    function _addAssetInNewAssets(address asset) internal {
        _newAssets.add(asset);
    }

    function _removeInNewAssets(address asset) internal {
        _newAssets.remove(asset);
    }

    function _changeActualToken(
        uint256 amount,
        address[] memory path
    ) internal returns (uint256 amountActualAcceptToken) {
        amountActualAcceptToken = _swapDEX(amount, path);
        _actualAcceptToken = _newAcceptToken;
        _approveDEX(_actualAcceptToken);
    }

    function _pushAssetInActive(AssetData memory newAsset) internal {
        Asset memory asset;
        asset.share = newAsset.share;
        asset.path = newAsset.path;
        asset.asset = newAsset.asset;

        _activeAssets.push(asset);
    }

    function _clearNewAssets() internal {
        uint256 len = _newAssets.length();
        for (uint256 i = len; i > 0; --i) {
            _newAssets.remove(_newAssets.at(i - 1));
        }
    }

    function _clearActiveAssets() internal {
        delete (_activeAssets);
    }

    /// @notice Set the maximum index share
    function _setMaxShare(uint256 maxShare) internal {
        _maxShare = maxShare;
    }

    /// @notice we exchange assets for USD to send them to the user
    function _unstake(uint256 amountLP, uint256 minAmount) internal {
        uint256 len = _activeAssets.length;
        uint256 sum;

        for (uint256 i; i < len; i++) {
            address[] memory reversPath = _reversArray(_activeAssets[i].path);
            uint256 amountForSwap = (amountLP * _activeAssets[i].fixedAmount) /
                PRECISION;

            uint256 amount = _swapDEX(amountForSwap, reversPath);
            _activeAssets[i].totalAmount -= amountForSwap;
            sum += amount;
        }
        IERC20(_actualAcceptToken).safeTransfer(msg.sender, sum);
        if (minAmount > sum) {
            revert InvalidMinAmount(minAmount, sum);
        }
    }

    /// @notice  exchange the user's USD for the assets included in the index
    function _calcStake(uint256 amountLP) internal returns (uint256 cost) {
        uint256 len = _activeAssets.length;
        for (uint256 i; i < len; i++) {
            uint256 amountForSwap = (amountLP * _activeAssets[i].fixedAmount) /
                PRECISION;

            (uint256 total, uint256 amountUSD) = _swapStake(
                amountForSwap,
                type(uint256).max,
                _activeAssets[i].path
            );
            _activeAssets[i].totalAmount += total;
            cost += amountUSD;
        }
    }

    function _approveDEX(address asset) internal {
        if (IERC20(asset).allowance(address(this), _adapter) == 0) {
            IERC20(asset).safeApprove(_adapter, type(uint256).max);
        }
    }

    /// @notice we exchange USD for assets included in the index
    function _rebalance(
        AssetData[] memory newAssets,
        uint256 usdAmount
    ) internal virtual {
        _clearActiveAssets(); // clearing the array of active assets
        uint256 totalLP = IERC20(_indexLP).totalSupply();
        uint256 len = newAssets.length;
        require((PRECISION_E6 * 100) / len <= _maxShare, "Invalid MaxShare");
        for (uint256 i; i < len; i++) {
            if (!_newAssets.contains(newAssets[i].asset)) {
                revert InvalidAsset(newAssets[i].asset);
            }
            _pushAssetInActive(newAssets[i]); // updating the array of active assets
            _approveDEX(newAssets[i].asset);
            uint256 amountForSwap = _calcShare(newAssets[i].share, usdAmount); // we get the asset's share in the index
            if (totalLP == 0) {
                uint256[] memory amounts = IUniswapV2Router02(_adapter)
                    .getAmountsOut(amountForSwap, newAssets[i].path);
                _activeAssets[i].fixedAmount = amounts[amounts.length - 1]; // saving the number of tokens in 1 LP
            } else {
                uint256 amount = _swapDEX(amountForSwap, newAssets[i].path); // we exchange asset for DEX
                _activeAssets[i].totalAmount += amount;
                _activeAssets[i].fixedAmount = (amount * PRECISION) / totalLP; // saving the number of tokens in 1 LP
            }
        }

        _setTimeRebalance(); // fixing the rebalance time
    }

    function _setTimeRebalance() internal {
        _lastRebalance = block.timestamp;
    }

    function _deployIndexLP(address partnerProgram) internal returns (address) {
        return address(new IndexLP(partnerProgram));
    }

    function _taxation(
        uint256 amount,
        uint256 fee
    ) internal pure returns (uint256 amountWithoutTax, uint256 tax) {
        tax = (amount * fee) / (100 * PRECISION_E6);
        amountWithoutTax = amount - tax;
    }

    function _isValidStake(
        uint256 cost,
        uint256 amountUSD,
        uint256 slippage
    ) internal pure {
        if (
            cost >
            (amountUSD * (100 * PRECISION_E6 + slippage)) / (100 * PRECISION_E6)
        ) {
            revert InvalidStake();
        }
    }

    /// @notice we calculate the percentage of the issuer in byltrct
    function _calcShare(
        uint256 percent,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * percent) / (100 * PRECISION_E6);
    }

    function _reversArray(
        address[] memory array
    ) internal pure returns (address[] memory reversArray) {
        uint256 len = array.length;
        reversArray = new address[](len);
        for (uint256 i; i <= len - 1; i++) {
            reversArray[i] = array[len - i - 1];
        }
    }

    /// @notice calculating the cost of LP
    function _calcCost(
        uint256 amountLP
    ) internal view returns (uint256 amountUSD) {
        uint256 len = _activeAssets.length;
        for (uint256 i; i < len; i++) {
            amountUSD += _getPrice(
                _activeAssets[i].path,
                (_activeAssets[i].fixedAmount * amountLP) / PRECISION
            );
        }
        // amountUSD += (amountUSD * 10) / PRECISION_E6;
    }

    function _getPrice(
        address[] memory path,
        uint256 amount
    ) public view returns (uint256) {
        uint256[] memory amounts = IUniswapV2Router02(_adapter).getAmountsIn(
            amount,
            path
        );
        return (amounts[0]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../index/Index.sol";
import "../index/IIndexCommunity.sol";

contract IndexCommunity is Index, IIndexCommunity {
    bytes32 public constant DAO_COMMUNITY_ROLE =
        keccak256("DAO_COMMUNITY_ROLE");

    /// @notice triggered when an asset is removed from the list
    event ExcludeAsset(address asset);
    /// @notice triggered when an asset is added to the list
    event IncludeAsset(address asset);
    /// @notice triggered when the "maxAssets" parameter is changed
    event MaxAssets(uint256 maxAssets);

    uint256 private _maxAssets;

    /// @notice Initialization of the main parameters
    /// @param adminDAO the address that has the right to call functions with the "DAO_ADMIN_ROLE" role
    /// @param admin the address that has the right to call functions with the "ADMIN_ROLE" role
    /// @param acceptToken the token in which the payment is accepted
    /// @param adapter adapter DEX
    /// @param startPrice initial index price
    /// @param rebalancePeriod the time after which rebalancing occurs (seconds)
    /// @param newAssets array with asset addresses
    /// @param tresuare a commission will be sent to this address
    /// @param partnerProgram partner Program
    /// @param nameIndex name Index
    function initialize(
        address adminDAO,
        address admin,
        address acceptToken,
        address adapter,
        uint256 startPrice,
        uint256 rebalancePeriod,
        address[] memory newAssets,
        address tresuare,
        address partnerProgram,
        address communityDAO,
        string memory nameIndex
    ) external {
        _setupRole(DAO_COMMUNITY_ROLE, communityDAO);
        _initialize(
            adminDAO,
            admin,
            acceptToken,
            adapter,
            startPrice,
            rebalancePeriod,
            newAssets,
            tresuare,
            partnerProgram,
            nameIndex
        );
        _maxAssets = 10;
    }

    /// @notice Set Rebalance period
    /// @dev Can only be called by a user with the right DAO_COMMUNITY_ROLE
    function setRebalancePeriod(uint256 period)
        external
        onlyRole(DAO_COMMUNITY_ROLE)
    {
        require(period >= 30 days && period <= 365 days, "Invalid period");
        _setRebalancePeriod(period);
    }

    /// @notice Increase the maximum number of assets in the index
    /// @dev Can only be called by a user with the right DAO_COMMUNITY_ROLE

    function incrementMaxAssets() external onlyRole(DAO_COMMUNITY_ROLE) {
        _maxAssets++;
        require(
            _maxAssets <= 10,
            "Overall number of assets couldn't be more than 10."
        );
        emit MaxAssets(_maxAssets);
    }

    /// @notice Reduces the maximum number of assets in the index
    /// @dev Can only be called by a user with the right DAO_COMMUNITY_ROLE
    function decrementMaxAssets() external onlyRole(DAO_COMMUNITY_ROLE) {
        require(
            _maxAssets >= 5,
            "Overall number of assets couldn't be less than 5."
        );
        _maxAssets--;
        emit MaxAssets(_maxAssets);
    }

    /// @notice Removes an asset from the list, after rebalancing, this asset will not be
    /// @dev Can only be called by a user with the right DAO_COMMUNITY_ROLE
    function excludeAsset(address asset) external onlyRole(DAO_COMMUNITY_ROLE) {
        _removeInNewAssets(asset);

        emit ExcludeAsset(asset);
    }

    /// @notice Adds an asset to the list, after rebalancing this asset will be added to the index
    /// @dev Can only be called by a user with the right DAO_COMMUNITY_ROLE
    function includeAsset(address asset) external onlyRole(DAO_COMMUNITY_ROLE) {
        require(lengthNewAssets() < _maxAssets, "Max assets");
        _addAssetInNewAssets(asset);

        emit IncludeAsset(asset);
    }

    /// @notice Returns the maximum fraction
    function getMaxAssets() external view returns (uint256) {
        return (_maxAssets);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IIndexCommunity).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC20BM.sol";

contract IndexLP is ERC20, IERC20BM, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(address partnerProgram) ERC20("Polylastic LP", "ILP") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, partnerProgram);
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IERC20BM {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

pragma solidity 0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPartnerProgram {
    function setupRoleIndex(address index) external;

    function distributeTheReward(
        address referral,
        uint256 amount,
        address token
    ) external returns (uint256 amountWithoutTax);

    /// @notice set the referrer
    /// @param referrer rspecify the referrer address
    function setReferrer(address referrer) external;

    /// @notice Sets the amount of the reward and the number of levels in the referral program
    /// @dev The number of levels depends on the size of the array.
    /// * the data inside the array shows the percentage of reward at each level
    /// * Can only be called by a user with the right DAO_ADMIN_ROLE
    /// @param percentReward the data must be specified taking into account the precission
    /// * the amount of data inside the array is equal to the number of levels
    /// * example [10000000, 5000000] equal first level =10%, second level = 5%
    function setPercentReward(uint256[] memory percentReward) external;
}