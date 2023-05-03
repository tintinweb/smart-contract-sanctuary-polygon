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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ISmartEmploymentAgreement.sol";
import "../libraries/SelfientLibrary.sol";

import "./SelfientManager.sol";

/**
 * @title Linear Agreement
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Implementation of the Smart Employment Agreement for linear agreements. Initial deposits
 *         are made by the hirer and can be withdrawn by the talent in linear increments based on the
 *         time passed since the beginning of the agreement.
 */
contract LinearAgreement is AccessControl, ISmartEmploymentAgreement {
  using SafeERC20 for IERC20;

  bytes32 public constant SELFIENT_MANAGER = keccak256("SELFIENT_MANAGER");

  SelfientManager public immutable selfientManager;

  // agreement id => agreement
  mapping(uint256 => Agreement) public agreements;

  // agreement id => is agreement terminated
  mapping(uint256 => bool) public terminatedAgreements;

  // agreement id => total claimed so far
  mapping(uint256 => uint256) public totalClaimed;

  /**
   * @param _superUser User to be assigned the DEFAULT_ADMIN_ROLE role
   * @param _selfientManager The selfient manager which makes calls to this implementation contract and validates tokens
   */
  constructor(address _superUser, address _selfientManager) {
    SelfientLibrary.checkZeroAddress(_superUser, "super user");
    SelfientLibrary.checkZeroAddress(_selfientManager, "selfient manager");
    _grantRole(DEFAULT_ADMIN_ROLE, _superUser);
    _grantRole(SELFIENT_MANAGER, _selfientManager);
    selfientManager = SelfientManager(_selfientManager);
  }

  function createAgreement(
    uint256 _agreementId,
    NewAgreement memory _agreement,
    bytes calldata
  ) external onlyRole(SELFIENT_MANAGER) returns (uint256 _firstDeposit) {
    if (_agreement.amount == 0) {
      revert InvalidFundingAmount();
    }
    if (_agreement.agreementLength < 1 days) {
      revert InvalidAgreementLength();
    }
    if (agreements[_agreementId].agreementId != 0) {
      revert DuplicateAgreementId();
    }

    Agreement memory newAgreement = Agreement(
      _agreementId,
      _agreement.hirer,
      _agreement.talent,
      _agreement.agreementType,
      _agreement.currency,
      _agreement.amount,
      block.timestamp,
      0,
      _agreement.agreementLength,
      _agreement.root
    );

    agreements[_agreementId] = newAgreement;

    emit AgreementCreated(
      newAgreement.hirer,
      newAgreement.talent,
      newAgreement.agreementId,
      newAgreement.startDate
    );

    return _agreement.amount;
  }

  function terminateAgreement(
    uint256 _agreementId
  ) external onlyRole(SELFIENT_MANAGER) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }
    if (terminatedAgreements[_agreementId]) {
      revert TerminateUnavailable();
    }

    emit AgreementTerminated(_agreementId);

    // This violates checks, effects and interactions but is safe because withdrawFunds updates the lastClaimed timestamp, so if this is re-entered the amount of claimable funds will be 0
    withdrawFundsInternal(_agreementId, false);

    terminatedAgreements[_agreementId] = true;

    uint256 hirerFunds = agreements[_agreementId].amount -
      totalClaimed[_agreementId];

    if (hirerFunds > 0) {
      emit FundsWithdrawn(_agreementId, hirerFunds);
      transferFunds(
        agreements[_agreementId].hirer,
        hirerFunds,
        agreements[_agreementId].currency
      );
    }
  }

  /**
   * @notice Reverts as this agreementType does not support further funding
   */
  function depositFunds(
    uint256,
    Milestone memory,
    bytes calldata
  ) external view onlyRole(SELFIENT_MANAGER) {
    revert DepositUnavailable();
  }

  function withdrawFunds(
    uint256 _agreementId
  ) public onlyRole(SELFIENT_MANAGER) {
    withdrawFundsInternal(_agreementId, true);
  }

  function agreementStatus(
    uint256 _agreementId
  ) external view returns (AgreementStatus) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (terminatedAgreements[_agreementId]) {
      return AgreementStatus.TERMINATED;
    }

    uint256 startDate = agreements[_agreementId].startDate;

    uint256 agreementEndDate = startDate +
      agreements[_agreementId].agreementLength;

    if (block.timestamp >= startDate && block.timestamp < agreementEndDate) {
      return AgreementStatus.IN_PROGRESS;
    }

    return AgreementStatus.COMPLETED;
  }

  function claimableValue(uint256 _agreementId) public view returns (uint256) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    uint256 startDate = agreements[_agreementId].startDate;
    uint256 lastClaim = agreements[_agreementId].lastClaim;
    uint256 length = agreements[_agreementId].agreementLength;

    uint256 agreementEndDate = startDate + length;

    if (
      terminatedAgreements[_agreementId] ||
      lastClaim >= agreementEndDate ||
      block.timestamp <= lastClaim ||
      block.timestamp <= startDate
    ) {
      return 0;
    }

    uint256 agreementAmount = agreements[_agreementId].amount;

    if (lastClaim == 0) {
      if (block.timestamp >= agreementEndDate) {
        return agreementAmount;
      }
      return ((block.timestamp - startDate) * agreementAmount) / length;
    }

    if (block.timestamp >= agreementEndDate) {
      return agreementAmount - totalClaimed[_agreementId];
    }

    return ((block.timestamp - lastClaim) * agreementAmount) / length;
  }

  function getTrimmedAgreementFields(
    uint256 _agreementId
  ) external view returns (TrimmedAgreementFields memory agreement) {
    agreement = TrimmedAgreementFields(
      _agreementId,
      agreements[_agreementId].hirer,
      agreements[_agreementId].talent,
      agreements[_agreementId].currency
    );
  }

  /**
   * @notice Reverts as this agreementType does not specifically support early withdrawals
   * @notice Talent can inherently withdraw based on the time since last claim date
   */
  function earlyWithdrawFunds(
    uint256,
    bytes memory,
    bytes memory
  ) external view onlyRole(SELFIENT_MANAGER) {
    revert EarlyWithdrawalUnavailable();
  }

  /**
   * @notice Validate a token is supported by the Selfient Manager and safeTransfer the funds
   * @dev Only supports transferring funds from this contract to another address
   * @param _to The address funds are being transferred to
   * @param _amount The transfer amount
   * @param _tokenAddress The contract address of the token being transferred
   */
  function transferFunds(
    address _to,
    uint256 _amount,
    address _tokenAddress
  ) internal {
    selfientManager.validateToken(_tokenAddress);
    IERC20 _token = IERC20(_tokenAddress);
    _token.safeTransfer(_to, _amount);
  }

  /**
   * @notice This internal helper handles withdrawing of tokens
   * @param _agreementId The agreementId to withdraw funds for
   * @param _revertOnEmptyWithdrawalAmount If the method should revert if there are no funds to be claimed
   */
  function withdrawFundsInternal(
    uint256 _agreementId,
    bool _revertOnEmptyWithdrawalAmount
  ) internal {
    uint256 withdrawalAmount = claimableValue(_agreementId);

    if (withdrawalAmount == 0 && _revertOnEmptyWithdrawalAmount) {
      revert WithdrawalUnavailable();
    }

    agreements[_agreementId].lastClaim = block.timestamp;
    totalClaimed[_agreementId] += withdrawalAmount;

    emit FundsWithdrawn(_agreementId, withdrawalAmount);

    if (withdrawalAmount != 0) {
      transferFunds(
        agreements[_agreementId].talent,
        withdrawalAmount,
        agreements[_agreementId].currency
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/ISmartEmploymentAgreement.sol";
import "../libraries/SelfientLibrary.sol";
import "./SelfientManager.sol";

/**
 * @title Milestone Agreement
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Implementation of the Smart Employment Agreement for milestone agreements.
 *         Milestones are intially defined by the hirer, with funds deposited per milestone,
 *         and can be withdrawn by the talent on a per-milestone basis.
 */
contract MilestoneAgreement is AccessControl, ISmartEmploymentAgreement {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  bytes32 public constant SELFIENT_MANAGER = keccak256("SELFIENT_MANAGER");

  SelfientManager public immutable selfientManager;

  // Agreement ID => Agreement Details
  mapping(uint256 => Agreement) public agreements;

  // agreement id => is agreement terminated
  mapping(uint256 => bool) public terminatedAgreements;

  // Agreement ID => Current Milestone
  mapping(uint256 => Milestone) public currentMilestone;

  // agreement id => total claimed so far
  mapping(uint256 => uint256) public totalClaimed;

  /**
   * @param _superUser User to be assigned the DEFAULT_ADMIN_ROLE role
   * @param _selfientManager The selfient manager which makes calls to this implementation contract and validates tokens
   */
  constructor(address _superUser, address _selfientManager) {
    SelfientLibrary.checkZeroAddress(_superUser, "super user");
    SelfientLibrary.checkZeroAddress(_selfientManager, "selfient manager");
    _grantRole(DEFAULT_ADMIN_ROLE, _superUser);
    _grantRole(SELFIENT_MANAGER, _selfientManager);
    selfientManager = SelfientManager(_selfientManager);
  }

  function createAgreement(
    uint256 _agreementId,
    NewAgreement memory _agreement,
    bytes calldata _data
  ) external onlyRole(SELFIENT_MANAGER) returns (uint256 _firstDeposit) {
    if (_agreement.amount == 0) {
      revert InvalidFundingAmount();
    }
    if (_agreement.agreementLength < 1 days) {
      revert InvalidAgreementLength();
    }
    if (agreements[_agreementId].agreementId != 0) {
      revert DuplicateAgreementId();
    }

    Milestone[] memory milestones = abi.decode(_data, (Milestone[]));

    if (milestones.length == 0) {
      revert NotEnoughMilestones();
    }

    for (uint256 i; i < milestones.length; ) {
      if (milestones[i].milestoneIndex != i) {
        revert InvalidMilestoneIndex();
      } else if (milestones[i].milestoneLength == 0) {
        revert InvalidMilestoneLength();
      } else if (milestones[i].claimed) {
        revert MilestoneAlreadyClaimed();
      }

      unchecked {
        ++i;
      }
    }

    if (
      milestones.length > 1 && computeMerkleRoot(milestones) != _agreement.root
    ) {
      revert InvalidMilestone();
    }

    uint256 startDate = block.timestamp;

    agreements[_agreementId] = Agreement(
      _agreementId,
      _agreement.hirer,
      _agreement.talent,
      _agreement.agreementType,
      _agreement.currency,
      _agreement.amount,
      startDate,
      0,
      _agreement.agreementLength,
      _agreement.root
    );

    currentMilestone[_agreementId] = Milestone(
      milestones[0].milestoneIndex,
      milestones[0].milestoneLength,
      milestones[0].amount,
      false
    );

    emit AgreementCreated(
      _agreement.hirer,
      _agreement.talent,
      _agreementId,
      startDate
    );

    return milestones[0].amount;
  }

  function depositFunds(
    uint256 _agreementId,
    Milestone calldata _milestone,
    bytes calldata _data
  ) external onlyRole(SELFIENT_MANAGER) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (isAgreementTerminated(_agreementId)) {
      revert DepositUnavailable();
    }

    if (
      _milestone.milestoneIndex !=
      currentMilestone[_agreementId].milestoneIndex + 1
    ) {
      revert InvalidMilestoneIndex();
    }

    if (
      !MerkleProof.verify(
        abi.decode(_data, (bytes32[])),
        agreements[_agreementId].root,
        hashMilestone(_milestone)
      )
    ) {
      revert InvalidMilestone();
    }

    if (!currentMilestone[_agreementId].claimed) {
      withdrawFundsInternal(
        _agreementId,
        currentMilestone[_agreementId].amount
      );
    }

    currentMilestone[_agreementId] = Milestone(
      _milestone.milestoneIndex,
      _milestone.milestoneLength,
      _milestone.amount,
      false
    );

    agreements[_agreementId].startDate = block.timestamp;
    emit FundsDeposited(_agreementId, _milestone.amount);
  }

  function claimableValue(uint256 _agreementId) public view returns (uint256) {
    uint256 milestoneEndDate = agreements[_agreementId].startDate +
      currentMilestone[_agreementId].milestoneLength;

    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (currentMilestone[_agreementId].claimed) {
      revert AlreadyClaimed();
    }

    if (block.timestamp < milestoneEndDate) {
      return 0;
    }

    return currentMilestone[_agreementId].amount;
  }

  function withdrawFunds(
    uint256 _agreementId
  ) public onlyRole(SELFIENT_MANAGER) {
    uint256 withdrawalAmount = claimableValue(_agreementId);
    if (withdrawalAmount == 0) {
      revert InsufficientWithdrawAmt();
    }

    withdrawFundsInternal(_agreementId, withdrawalAmount);
  }

  /**
   * @notice This internal helper handles withdrawing of tokens
   * @param _agreementId The agreementId to withdraw funds for
   */
  function withdrawFundsInternal(
    uint256 _agreementId,
    uint256 _amount
  ) internal {
    totalClaimed[_agreementId] += _amount;

    currentMilestone[_agreementId].claimed = true;

    emit FundsWithdrawn(_agreementId, _amount);

    if (_amount != 0) {
      transferFunds(
        agreements[_agreementId].talent,
        _amount,
        agreements[_agreementId].currency
      );
    }
  }

  function terminateAgreement(
    uint256 _agreementId
  ) external onlyRole(SELFIENT_MANAGER) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (isAgreementTerminated(_agreementId)) {
      revert TerminateUnavailable();
    }

    uint256 startDate = agreements[_agreementId].startDate;
    uint256 milestoneEndDate = startDate +
      currentMilestone[_agreementId].milestoneLength;

    if (block.timestamp >= startDate && block.timestamp < milestoneEndDate) {
      revert TerminateUnavailable();
    }

    emit AgreementTerminated(_agreementId);
    terminatedAgreements[_agreementId] = true;
  }

  function agreementStatus(
    uint256 _agreementId
  ) external view returns (AgreementStatus) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (terminatedAgreements[_agreementId]) {
      return AgreementStatus.TERMINATED;
    }

    if (totalClaimed[_agreementId] == agreements[_agreementId].amount) {
      return AgreementStatus.COMPLETED;
    }

    uint256 startDate = agreements[_agreementId].startDate;
    uint256 milestoneEndDate = startDate +
      currentMilestone[_agreementId].milestoneLength;

    if (block.timestamp >= startDate && block.timestamp < milestoneEndDate) {
      return AgreementStatus.IN_PROGRESS;
    }

    if (block.timestamp - milestoneEndDate <= 10 days) {
      return AgreementStatus.PAUSED;
    }

    return AgreementStatus.TERMINATED;
  }

  function earlyWithdrawFunds(
    uint256 _agreementId,
    bytes memory _hirerSignature,
    bytes memory _talentSignature
  ) external onlyRole(SELFIENT_MANAGER) {
    if (agreements[_agreementId].agreementId == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    if (currentMilestone[_agreementId].claimed) {
      revert AlreadyClaimed();
    }

    address talent = agreements[_agreementId].talent;
    address hirer = agreements[_agreementId].hirer;

    bytes32 recreatedMessage = recreateMessage(
      address(this),
      _agreementId,
      hirer,
      talent,
      agreements[_agreementId].amount,
      currentMilestone[_agreementId].milestoneIndex
    );
    verifySignature(recreatedMessage, _hirerSignature, hirer, "hirer");
    verifySignature(recreatedMessage, _talentSignature, talent, "talent");

    uint256 milestoneAmount = currentMilestone[_agreementId].amount;

    withdrawFundsInternal(_agreementId, milestoneAmount);
  }

  function getTrimmedAgreementFields(
    uint256 _agreementId
  ) external view returns (TrimmedAgreementFields memory agreement) {
    agreement = TrimmedAgreementFields(
      _agreementId,
      agreements[_agreementId].hirer,
      agreements[_agreementId].talent,
      agreements[_agreementId].currency
    );
  }

  /**
   * @notice Validate a token is supported by the Selfient Manager and safeTransfer the funds
   * @dev Only supports transferring funds from this contract to another address
   * @param _to The address funds are being transferred to
   * @param _amount The transfer amount
   * @param _tokenAddress The contract address of the token being transferred
   */
  function transferFunds(
    address _to,
    uint256 _amount,
    address _tokenAddress
  ) internal {
    selfientManager.validateToken(_tokenAddress);
    IERC20 _token = IERC20(_tokenAddress);
    _token.safeTransfer(_to, _amount);
  }

  /**
   * @notice Method to recreate the hirer/talent signature on chain
   * @param agreementAddress Address of the implementation contract being called
   * @param agreementId The agreement ID
   * @param hirer The hirer address
   * @param talent The talent address
   * @param amount The amount being deposited into this milestone
   * @param milestoneIndex The index of the upcoming milestone being verified
   */
  function recreateMessage(
    address agreementAddress,
    uint256 agreementId,
    address hirer,
    address talent,
    uint256 amount,
    uint256 milestoneIndex
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          agreementAddress,
          agreementId,
          hirer,
          talent,
          amount,
          milestoneIndex
        )
      ).toEthSignedMessageHash();
  }

  /**
   * @notice Verify an Ethereum signed message
   * @param _message The unsigned message hash
   * @param _signature The signed message
   * @param _signer The signer to check has signed the provided message
   */
  function verifySignature(
    bytes32 _message,
    bytes memory _signature,
    address _signer,
    string memory _signerName
  ) internal pure {
    if (_message.recover(_signature) != _signer) {
      revert InvalidSignature(_signerName);
    }
  }

  /**
   * @notice Checks the provided agreementId to see if it either been terminated or 10 days has passed since the last milestone
   * @param agreementId The agreementId to check if terminated
   * @return Boolean indicating if the agreement is terminated or expired
   */
  function isAgreementTerminated(
    uint256 agreementId
  ) internal view returns (bool) {
    if (terminatedAgreements[agreementId]) {
      return true;
    }

    uint256 milestoneEndDate = agreements[agreementId].startDate +
      currentMilestone[agreementId].milestoneLength;

    if (
      block.timestamp > milestoneEndDate &&
      block.timestamp - milestoneEndDate > 10 days
    ) {
      return true;
    }

    return false;
  }

  /**
   * @notice This method recreates a merkle root given the Milestones
   * @param _milestones The array of milestones for the agreement
   */
  function computeMerkleRoot(
    Milestone[] memory _milestones
  ) internal pure returns (bytes32) {
    // This array will contain the entire merkle tree of hashes
    bytes32[] memory hashes = new bytes32[](2 * _milestones.length - 1);

    for (uint256 i; i < _milestones.length; ) {
      // First populate the last half of the array with the hashed milestones
      hashes[hashes.length - 1 - i] = hashMilestone(_milestones[i]);

      unchecked {
        ++i;
      }
    }

    // Iterate over the hashed milestones to form the parent hashes, all the way up to the final pair
    for (uint256 i = hashes.length - 1 - _milestones.length; i > 0; i--) {
      uint left = i * 2 + 1;
      uint right = left + 1;

      hashes[i] = _hashPair(hashes[left], hashes[right]);
    }

    // Recreate the root by taking it's two direct children and hashing them
    return _hashPair(hashes[1], hashes[2]);
  }

  /**
   * @notice This method takes in a milestone struct and produces a keccak256 hash of the params
   * @param _milestone The milestone to hash
   */
  function hashMilestone(
    Milestone memory _milestone
  ) internal pure returns (bytes32 result) {
    result = keccak256(
      bytes.concat(
        keccak256(
          abi.encode(
            _milestone.milestoneIndex,
            _milestone.milestoneLength,
            _milestone.amount
          )
        )
      )
    );
  }

  /**
   * @notice This method hashes two values together, it also sorts the pair for consistency
   * @param a The first item
   * @param b The second item
   */
  function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
  }

  /**
   * @notice Hashes the two inputs together to create the parent hash. Assembly code allows the hashing to be more gas efficient
   * @param a First item
   * @param b Second item
   */
  function _efficientHash(
    bytes32 a,
    bytes32 b
  ) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/ISelfientAdmin.sol";
import "../interfaces/ISmartEmploymentAgreement.sol";
import "../libraries/SelfientLibrary.sol";

/**
 * @title Selfient Admin
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs administrative functions to facilitate the manager contract functionality including allowlisting
 *         ERC20 payment tokens, registering SEA contracts, and distributing fees
 */
abstract contract SelfientAdmin is ISelfientAdmin, AccessControl {
  using SafeERC20 for IERC20;

  bytes32 public constant SELFIENT_ADMIN = keccak256("SELFIENT_ADMIN");
  uint256 public constant PERCENTAGE_PRECISION = 10 ** 2;
  address public feeWallet;
  uint16 public globalAgreementFee;

  // ERC20 token contract address => is token allowed
  mapping(address => bool) public tokenAllowList;

  // Agreement type => SEA agreement contract implementation
  mapping(uint256 => ISmartEmploymentAgreement)
    public
    override agreementContracts;

  // Hirer wallet address => Hirer fee override
  mapping(address => HirerAgreementFee) public override hirerFees;

  /**
   * @param _superUser User to be assigned the SELFIENT_ADMIN and DEFAULT_ADMIN_ROLE roles
   * @param _feeWallet The wallet address to which fees are distributed
   * @param _agreementFee The global agreement fee percentage to be applied to all agreements
   */
  constructor(address _superUser, address _feeWallet, uint16 _agreementFee) {
    SelfientLibrary.checkZeroAddress(_superUser, "super user");
    SelfientLibrary.checkZeroAddress(_feeWallet, "fee wallet");
    _grantRole(DEFAULT_ADMIN_ROLE, _superUser);
    _grantRole(SELFIENT_ADMIN, _superUser);
    feeWallet = _feeWallet;
    globalAgreementFee = _agreementFee;
  }

  function allowToken(
    address _tokenContract
  ) external onlyRole(SELFIENT_ADMIN) {
    SelfientLibrary.checkZeroAddress(_tokenContract, "token contract");
    if (tokenAllowList[_tokenContract]) {
      revert TokenStatusAlreadySet();
    }
    tokenAllowList[_tokenContract] = true;
    emit TokenAllowed(_tokenContract);
  }

  function revokeToken(
    address _tokenContract
  ) external onlyRole(SELFIENT_ADMIN) {
    SelfientLibrary.checkZeroAddress(_tokenContract, "token contract");
    if (!tokenAllowList[_tokenContract]) {
      revert TokenStatusAlreadySet();
    }
    tokenAllowList[_tokenContract] = false;
    emit TokenRevoked(_tokenContract);
  }

  function validateToken(address _address) public view {
    SelfientLibrary.checkZeroAddress(_address, "token contract");
    if (!tokenAllowList[_address]) {
      revert PaymentTokenNotAllowed();
    }
  }

  function registerSEA(
    address _contractAddress,
    uint8 _contractId
  ) external onlyRole(SELFIENT_ADMIN) {
    SelfientLibrary.checkZeroAddress(_contractAddress, "agreement contract");
    if (address(agreementContracts[_contractId]) != address(0)) {
      revert SEAContractAlreadyRegistered();
    }

    agreementContracts[_contractId] = ISmartEmploymentAgreement(
      _contractAddress
    );
    emit SEARegistered(_contractAddress, _contractId);
  }

  function setAgreementFee(uint16 _fee) external onlyRole(SELFIENT_ADMIN) {
    if (_fee > (100 * PERCENTAGE_PRECISION)) {
      revert InvalidFeePercentage();
    }

    emit AgreementFeeUpdate(globalAgreementFee, _fee);

    globalAgreementFee = _fee;
  }

  function setFeewallet(address _address) external onlyRole(SELFIENT_ADMIN) {
    SelfientLibrary.checkZeroAddress(_address, "fee wallet");

    emit FeeWalletUpdate(feeWallet, _address);

    feeWallet = _address;
  }

  function setHirerAgreementFee(
    address _address,
    uint16 _fee,
    bool _disabled
  ) external onlyRole(SELFIENT_ADMIN) {
    SelfientLibrary.checkZeroAddress(_address, "hirer address");
    if (_fee > 100 * PERCENTAGE_PRECISION) {
      revert InvalidFeePercentage();
    }

    emit HirerAgreementFeeUpdate(_address, _fee, _disabled);

    hirerFees[_address] = HirerAgreementFee({
      agreementFee: _fee,
      feeDisabled: _disabled
    });
  }

  /**
   * @notice Function to distribute the calculated agreement fee to the fee wallet
   * @param _hirer The hirer address to transfer funds from
   * @param _agreementValue The calculated fee value based on agreement amount
   */
  function distributeAgreementFee(
    address _hirer,
    uint256 _agreementValue,
    address _tokenAddress
  ) internal {
    SelfientLibrary.checkZeroAddress(_hirer, "hirer address");
    validateToken(_tokenAddress);

    IERC20 _token = IERC20(_tokenAddress);

    HirerAgreementFee memory hirerFeeSettings = hirerFees[_hirer];

    if (hirerFeeSettings.feeDisabled) return;

    uint16 percentageFee = hirerFeeSettings.agreementFee == 0
      ? globalAgreementFee
      : hirerFeeSettings.agreementFee;

    if (percentageFee == 0) return;

    uint256 fee = (_agreementValue * percentageFee) /
      (PERCENTAGE_PRECISION * 100);

    emit FeeDistributed(fee);
    _token.safeTransferFrom(_hirer, feeWallet, fee);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/ISmartEmploymentAgreement.sol";
import "../interfaces/ISelfientManager.sol";
import "../interfaces/ISelfientAdmin.sol";

import "./SelfientAdmin.sol";
import "./LinearAgreement.sol";

/**
 * @title Selfient Manager
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Manages agreement creation, funding, withdrawals and handles funds distribution
 */
contract SelfientManager is AccessControl, ISelfientManager, SelfientAdmin {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  bytes32 public constant SELFIENT_MANAGER = keccak256("SELFIENT_MANAGER");
  uint256 public agreementCounter = 0;

  // Agreement Id => Agreement Type
  mapping(uint256 => uint8) public agreementTypeById;

  /**
   * @param _superUser User to be assigned the DEFAULT_ADMIN_ROLE role
   * @param _feeWallet The wallet address to which fees are distributed
   * @param _agreementFee The global agreement fee percentage to be applied to all agreements
   */
  constructor(
    address _superUser,
    address _feeWallet,
    uint16 _agreementFee
  ) SelfientAdmin(_superUser, _feeWallet, _agreementFee) {
    SelfientLibrary.checkZeroAddress(_superUser, "super user");
    _grantRole(DEFAULT_ADMIN_ROLE, _superUser);
  }

  function getAgreement(
    uint256 _agreementId
  )
    external
    view
    returns (ISmartEmploymentAgreement.Agreement memory _agreement)
  {
    (
      ,
      ISmartEmploymentAgreement.Agreement memory agreement
    ) = _retrieveAgreement(_agreementId);
    return agreement;
  }

  function createAgreement(
    ISmartEmploymentAgreement.NewAgreement memory _agreement,
    bytes calldata _data
  ) external {
    SelfientLibrary.checkZeroAddress(_agreement.hirer, "hirer");
    SelfientLibrary.checkZeroAddress(_agreement.talent, "talent");

    if (_agreement.hirer == _agreement.talent) {
      revert MatchingHirerTalent();
    }
    if (msg.sender != _agreement.hirer) {
      revert InvalidCaller();
    }

    validateToken(_agreement.currency);

    ISmartEmploymentAgreement agreementContract = agreementContracts[
      _agreement.agreementType
    ];

    SelfientLibrary.checkZeroAddress(
      address(agreementContract),
      "agreementContract"
    );

    bytes32 recreatedMessage = recreateMessage(
      address(agreementContract),
      _agreement.hirer,
      _agreement.talent,
      _agreement.agreementType,
      _agreement.agreementLength,
      _agreement.amount,
      _agreement.currency,
      _agreement.root
    );

    verifySignature(
      recreatedMessage,
      _agreement.hirerSignature,
      _agreement.hirer,
      "hirer"
    );

    verifySignature(
      recreatedMessage,
      _agreement.talentSignature,
      _agreement.talent,
      "talent"
    );

    uint256 newAgreementId = _incrementAgreementCounter();
    agreementTypeById[newAgreementId] = _agreement.agreementType;

    uint256 depositAmount = agreementContract.createAgreement(
      newAgreementId,
      _agreement,
      _data
    );

    distributeAgreementFee(
      _agreement.hirer,
      depositAmount,
      _agreement.currency
    );

    transferFunds(
      _agreement.hirer,
      address(agreementContract),
      depositAmount,
      _agreement.currency
    );
  }

  function depositFunds(
    uint256 _agreementId,
    ISmartEmploymentAgreement.Milestone memory _milestone,
    bytes calldata _data
  ) external {
    ISmartEmploymentAgreement agreementContract = _getAgreementContract(
      _agreementId
    );
    ISmartEmploymentAgreement.TrimmedAgreementFields
      memory agreement = agreementContract.getTrimmedAgreementFields(
        _agreementId
      );

    if (msg.sender != agreement.hirer) {
      revert InvalidCaller();
    }

    agreementContract.depositFunds(_agreementId, _milestone, _data);

    distributeAgreementFee(
      agreement.hirer,
      _milestone.amount,
      agreement.currency
    );

    transferFunds(
      agreement.hirer,
      address(agreementContract),
      _milestone.amount,
      agreement.currency
    );
  }

  function earlyWithdrawFunds(
    uint256 _agreementId,
    bytes memory _hirerSignature,
    bytes memory _talentSignature
  ) external {
    ISmartEmploymentAgreement agreementContract = _getAgreementContract(
      _agreementId
    );

    if (
      msg.sender !=
      agreementContract.getTrimmedAgreementFields(_agreementId).talent
    ) {
      revert InvalidCaller();
    }

    agreementContract.earlyWithdrawFunds(
      _agreementId,
      _hirerSignature,
      _talentSignature
    );
  }

  function withdrawFunds(uint256 _agreementId) external {
    ISmartEmploymentAgreement agreementContract = _getAgreementContract(
      _agreementId
    );

    if (
      msg.sender !=
      agreementContract.getTrimmedAgreementFields(_agreementId).talent
    ) {
      revert InvalidCaller();
    }

    agreementContract.withdrawFunds(_agreementId);
  }

  function terminateAgreement(uint256 _agreementId) external {
    ISmartEmploymentAgreement agreementContract = _getAgreementContract(
      _agreementId
    );

    if (
      msg.sender !=
      agreementContract.getTrimmedAgreementFields(_agreementId).hirer
    ) {
      revert InvalidCaller();
    }

    agreementContract.terminateAgreement(_agreementId);
  }

  /**
   * @notice Validate a token is supported by the Selfient Manager and safeTransfer the funds
   * @dev This is used so that hirers depositing funds into an agreement only have to approve the Selfient Manager once,
   *      rather than having to approve each SEA contract individually.
   * @param _from The address funds are being transferred from
   * @param _to The address funds are being transferred to
   * @param _amount The transfer amount
   * @param _tokenAddress The contract address of the token being transferred
   */
  function transferFunds(
    address _from,
    address _to,
    uint256 _amount,
    address _tokenAddress
  ) internal {
    validateToken(_tokenAddress);
    IERC20 _token = IERC20(_tokenAddress);
    _token.safeTransferFrom(_from, _to, _amount);
  }

  /**
   * @notice Verify an Ethereum signed message
   * @param _message The unsigned message hash
   * @param _signature The signed message
   * @param _signer The signer to check has signed the provided message
   * @param _signerName The name of the signer who is expected to have signed this message (should be either "hirer" or "talent")
   */
  function verifySignature(
    bytes32 _message,
    bytes memory _signature,
    address _signer,
    string memory _signerName
  ) internal pure {
    if (_message.recover(_signature) != _signer) {
      revert InvalidSignature(_signerName);
    }
  }

  /**
   * @notice Method to recreate the hirer/talent signature on chain
   * @param agreementAddress Address of the implementation contract being called
   * @param hirer Hirer's wallet address
   * @param talent Talent's wallet address
   * @param agreementType Type of agreement contract
   * @param length Length of the agreement
   * @param amount Agreed payment amount for the agreement
   * @param currency Payment token address
   * @param merkleRoot Hashed string representing a merkle tree root for milestone agreements
   */
  function recreateMessage(
    address agreementAddress,
    address hirer,
    address talent,
    uint8 agreementType,
    uint40 length,
    uint256 amount,
    address currency,
    bytes32 merkleRoot
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          agreementAddress,
          hirer,
          talent,
          agreementType,
          length,
          amount,
          currency,
          merkleRoot
        )
      ).toEthSignedMessageHash();
  }

  /**
   * @dev This can remain unchecked as it is close to impossible that we would ever reach 2**256 - 1 agreements
   */
  function _incrementAgreementCounter()
    internal
    returns (uint256 incrementedCount)
  {
    incrementedCount = agreementCounter + 1;
    agreementCounter = incrementedCount;
  }

  function _getAgreementContract(
    uint256 _agreementId
  ) internal view returns (ISmartEmploymentAgreement _agreementContract) {
    uint8 _agreementType = agreementTypeById[_agreementId];
    if (_agreementType == 0) {
      revert SelfientLibrary.AgreementNotFound();
    }

    _agreementContract = agreementContracts[_agreementType];
  }

  /**
   * @dev Retrieve the agreement contract and agreement from the agreement id
   * @param _agreementId The agreement id
   * @return _agreementContract The agreement contract
   * @return _agreement The agreement for the agreement id
   */
  function _retrieveAgreement(
    uint256 _agreementId
  )
    internal
    view
    returns (
      ISmartEmploymentAgreement _agreementContract,
      ISmartEmploymentAgreement.Agreement memory _agreement
    )
  {
    _agreementContract = _getAgreementContract(_agreementId);

    (
      uint256 agreementId,
      address hirer,
      address talent,
      uint8 agreementType,
      address currency,
      uint256 amount,
      uint256 startDate,
      uint256 lastClaim,
      uint256 agreementLength,
      bytes32 root
    ) = _agreementContract.agreements(_agreementId);

    _agreement = ISmartEmploymentAgreement.Agreement(
      agreementId,
      hirer,
      talent,
      agreementType,
      currency,
      amount,
      startDate,
      lastClaim,
      agreementLength,
      root
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "./ISmartEmploymentAgreement.sol";

/**
 * @title Interface for Selfient Admin
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs administrative functions to facilitate the manager contract functionality including allowlisting
 *         ERC20 payment tokens, registering SEA contracts, and distributing fees
 */
interface ISelfientAdmin {
  /**
   * @notice Struct defining the properties of the Hirer's agreement fee
   * @param agreementFee The fee value with 2 decimal places precision
   * @param feeDisabled Boolean value representing whether fees are enabled or not for this particular hirer
   */
  struct HirerAgreementFee {
    uint16 agreementFee;
    bool feeDisabled;
  }

  /**
   * @notice Emitted when an ERC-20 token is added to the tokenAllowList
   * @param _tokenAddress The address of the token contract
   */
  event TokenAllowed(address _tokenAddress);

  /**
   * @notice Emitted when an ERC-20 token is removed from the tokenAllowList
   * @param _tokenAddress The address of the token contract
   */
  event TokenRevoked(address _tokenAddress);

  /**
   * @notice Emitted when an SEA is registered with the manager contract
   * @param contractAddress The address of the SEA contract
   * @param contractId The ID assigned to the contract
   */
  event SEARegistered(
    address indexed contractAddress,
    uint256 indexed contractId
  );

  /**
   * @notice Emitted when the agreement fee is updated
   * @param prevValue The previous value
   * @param newValue The new updated value
   */
  event AgreementFeeUpdate(uint256 prevValue, uint256 newValue);

  /**
   * @notice Emitted when the fee wallet is updated
   * @param prevValue The previous value
   * @param newValue The new updated value
   */
  event FeeWalletUpdate(address prevValue, address newValue);

  /**
   * @notice Emitted when the hirer agreement fee is updated
   * @param hirerAddress The address of the hirer
   * @param fee The updated fee for the hirer
   * @param disabled Whether the fee is enabled or disabled
   */
  event HirerAgreementFeeUpdate(
    address indexed hirerAddress,
    uint256 fee,
    bool disabled
  );

  /**
   * @notice Emitted when a fee is distributed by the admin contract
   * @param amount The fee amount being distributed
   */
  event FeeDistributed(uint256 amount);

  /**
   * @notice Thrown if token contract address is invalid
   */
  error InvalidTokenAddress();

  /**
   * @notice Thrown if token allowed status is already set
   */
  error TokenStatusAlreadySet();

  /**
   * @notice Thrown if token contract address being validated externally is not allowlisted
   */
  error PaymentTokenNotAllowed();

  /**
   * @notice Thrown if SEA contract address is already in mapping
   */
  error SEAContractAlreadyRegistered();

  /**
   * @notice Thrown when fee amount passed in is invalid (> 10000)
   */
  error InvalidFeePercentage();

  /**
   * @notice Used to allow an ERC-20 token to be allowlisted for use
   * @dev Specific authorisation function so that this function is idempotent
   * @param _tokenContract The contract of the ERC-20 token to be added
   */
  function allowToken(address _tokenContract) external;

  /**
   * @notice Used to remove an ERC-20 token from the allowed token list
   * @dev Specific authorisation function so that this function is idempotent
   * @param _tokenContract The contract of the ERC-20 token to be removed
   */
  function revokeToken(address _tokenContract) external;

  /**
   * @notice Used to check if a token has been added to the allowed token list, should be called by all functions attempting to transfer tokens to/from escrow contracts
   * @dev Specific verification function so that this function is idempotent
   * @param _address The contract address of the ERC-20 token to be verified
   */
  function validateToken(address _address) external;

  /**
   * @notice Used to register an SEA contract with the manager contract, assigns contract an ID if not assigned
   * @dev Specific registration function so that this function is idempotent
   * @param _contractAddress The SEA contract address to be registered
   * @param _contractId A integer identifying an SEA contract
   */
  function registerSEA(address _contractAddress, uint8 _contractId) external;

  /**
   * @notice Internal function to set the percentage fee taken for the current agreement by Selfient
   * @param _fee The uint16 value to assign the agreement fee to
   */
  function setAgreementFee(uint16 _fee) external;

  /**
   * @notice Internal function to set the wallet for the agreement fee to be accrued into
   * @param _address The address of the external wallet
   */
  function setFeewallet(address _address) external;

  /**
   * @notice Set the hirer agreement fee override
   * @param _address The address of the hirer
   * @param _fee The fee percentage to be set expressed in basis points
   * @param _disabled Bool value representing whether this hirer should pay fees on agreements
   */
  function setHirerAgreementFee(
    address _address,
    uint16 _fee,
    bool _disabled
  ) external;

  /**
   * @dev The decimal precision to preserve for percentage calculations. This has been set to 10**2 so that percentages
   *      are represented in basis points, ie 1000 = 10%
   */
  function PERCENTAGE_PRECISION() external view returns (uint256);

  /**
   * @notice The agreement fee to apply to all agreements unless a hirer agreement fee is specified or disabled
   */
  function globalAgreementFee() external view returns (uint16);

  /**
   * @notice The wallet into which agreement fees are accrued
   */
  function feeWallet() external view returns (address);

  /**
   * @notice Mapping of token contract addresses to whether they have been allowed by a Selfient Admin to be used in the Selfient ecosystem
   * @param _address The address of the token contract to check
   * @return Boolean value representing whether the token is allowed or not
   */
  function tokenAllowList(address _address) external view returns (bool);

  /**
   * @notice Mapping of agreement contract ids (_type) to their implementation contract addresses
   * @param _type The id of the SEA contract to be returned
   * @return The address of the SEA contract
   */
  function agreementContracts(
    uint256 _type
  ) external view returns (ISmartEmploymentAgreement);

  /**
   * @notice Mapping of hirer addresses to their agreement fee override
   * @param _address The address of the hirer to be returned
   * @return agreementFee The fee to override the global fee for this particular hirer
   * @return feeDisabled Boolean value representing whether fees are enabled or not for this particular hirer
   */
  function hirerFees(
    address _address
  ) external view returns (uint16 agreementFee, bool feeDisabled);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "./ISmartEmploymentAgreement.sol";
import "./ISelfientAdmin.sol";
import "../libraries/SelfientLibrary.sol";

/**
 * @title Interface for Selfient Manager
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Manages agreement creation, funding, withdrawals and handles funds distribution
 */
interface ISelfientManager is ISelfientAdmin {
  /**
   * @notice Thrown when no agreement of the given agreementId exists in the mapping
   */
  error AgreementUnavailable();

  /**
   * @notice Thrown when the signed message passed in does not match the recreated message
   * @param _signer The signer who was expected to have created the signature. Used to distinguish between
   *                issues with the hirer and talent signatures
   */
  error InvalidSignature(string _signer);

  /**
   * @notice Thrown when a function is called by an unexpected party
   */
  error InvalidCaller();

  /**
   * @notice Thrown when the hirer wallet doesnt hold sufficient funds to fund agreement + fees
   */
  error InsufficentFunds();

  /**
   * @notice Thrown when the hirer and talent addresses are the same. Agreements should be between two different parties
   */
  error MatchingHirerTalent();

  /**
   * @notice Used to retrieve an agreement from a given SEA contract implementation
   * @param _agreementId The numeric ID of the agreement
   */
  function getAgreement(
    uint256 _agreementId
  )
    external
    view
    returns (ISmartEmploymentAgreement.Agreement memory agreement);

  /**
   * @notice Used to create a new agreement on-chain, while verifying signatures of the two parties
   * @dev Increments the agreementCounter and calls the SEA contract based on the agreementType selected
   * @param _agreement The agreement of a given type to be created
   * @param _data Any extra data required to create the agreement
   */
  function createAgreement(
    ISmartEmploymentAgreement.NewAgreement memory _agreement,
    bytes calldata _data
  ) external;

  /**
   * @notice Fund an agreement that supports further funding (i.e. milestone payments)
   * @dev Calls to the SEA contract implementation to deposit funds
   * @param _agreementId The ID of the agreement funds are being deposited into
   * @param _milestone Milestone struct object denoting the next milestone
   * @param _data Any extra data required to deposit funds
   */
  function depositFunds(
    uint256 _agreementId,
    ISmartEmploymentAgreement.Milestone memory _milestone,
    bytes calldata _data
  ) external;

  /**
   * @notice Used to withdraw funds earlier than the end date if supported by contract
   * @param _agreementId The ID of the agreement funds are being withdrawn from
   * @param _hirerSignature Hirer's signed message containing the function params as encrypted string
   * @param _talentSignature Talents's signed message containing the function params as encrypted string
   */
  function earlyWithdrawFunds(
    uint256 _agreementId,
    bytes memory _hirerSignature,
    bytes memory _talentSignature
  ) external;

  /**
   * @notice Used to withdraw funds based on the agreement type.
   * @dev Check that the agreement is in progress and the claimable value in the agreement is > 0
   * @dev Calls to the SEA contract implementation to withdraw funds.
   * @param _agreementId The ID of the agreement funds are being withdrawn from
   */
  function withdrawFunds(uint256 _agreementId) external;

  /**
   * @notice Used to terminate the current agreement, allowing each party to withdraw their funds
   * @dev Requires the caller address to be the hirer address
   * @param _agreementId The ID of the agreement being terminated
   */
  function terminateAgreement(uint256 _agreementId) external;

  /**
   * Retreives the agreement type id based on the agreement id
   * @param _agreementId The agreement id to check
   * @return The agreement type id in the SEA admin mapping
   */
  function agreementTypeById(
    uint256 _agreementId
  ) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * 
  _________        .__    _____ .__                  __   
 /   _____/  ____  |  | _/ ____\|__|  ____    ____ _/  |_ 
 \_____  \ _/ __ \ |  | \   __\ |  |_/ __ \  /    \\   __\
 /        \\  ___/ |  |__|  |   |  |\  ___/ |   |  \|  |  
/_______  / \___  >|____/|__|   |__| \___  >|___|  /|__|  
        \/      \/                       \/      \/       
 */

import "../libraries/SelfientLibrary.sol";

/**
 * @title Interface for Smart Employment Agreements
 * @author Developed by Labrys on behalf of Selfient
 * @custom:contributor Arjun Menon (arjunmenon.eth)
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice The shared structure for Smart Employement Agreements, allowing the creation,
 *        funding, withdrawal and distribution of agreement funds. Contracts that extend
 *        this interface can be registered via the Selfient Admin contract.
 */
interface ISmartEmploymentAgreement {
  /**
   * @notice Enums describing the progress status of an agreement
   */
  enum AgreementStatus {
    /**
     * The agreement is active and payments can be made
     */
    IN_PROGRESS,
    /**
     * (only applicable for milestone agreements) The agreement is in between milestones
     */
    PAUSED,
    /**
     * The agreement has been completed and no further deposits can be made
     */
    COMPLETED,
    /**
     * The agreement has been terminated and no further deposits can be made.
     * Alternatively, if the agreement has been paused for more than 10 days it is considered terminated
     */
    TERMINATED
  }

  /**
   * @notice Struct that defines components of a new agreement
   * @param hirer Wallet address of the hiring party
   * @param talent Wallet address of the talent
   * @param hirerSignature Hirer's signed message containing the struct params as encrypted string
   * @param talentSignature Talent's signed message containing the struct params as encrypted string
   * @param agreementType Type of employment agreement (linear/milestone/onetime)
   * @param currency The currency the funds will be paid out in
   * @param amount The payment value for the agreement
   * @param agreementLength The length of the contract in SECONDS
   * @param root The merkle tree root
   * @param firstMilestone The first milestone of the agreement. This will not be used for linear style agreements
   */
  struct NewAgreement {
    address hirer;
    address talent;
    bytes hirerSignature;
    bytes talentSignature;
    uint8 agreementType;
    address currency;
    uint256 amount;
    uint40 agreementLength;
    bytes32 root;
  }

  /**
   * @notice Struct that defines components of an on-chain Agreement
   * @param hirer Wallet address of the hiring party
   * @param talent Wallet address of the talent
   * @param agreementType Type of employment agreement (linear/milestone/onetime)
   * @param currency The currency the funds will be paid out in
   * @param amount The payment value for the agreement
   * @param startDate The start date of the employment agreement or the current milestone
   * @param lastClaim The date of the last claimed payment
   * @param agreementLength The length of the contract in SECONDS
   * @param root The merkle tree root
   */
  struct Agreement {
    uint256 agreementId;
    address hirer;
    address talent;
    uint8 agreementType;
    address currency;
    uint256 amount;
    uint256 startDate;
    uint256 lastClaim;
    uint256 agreementLength;
    bytes32 root;
  }

  /**
   * @notice Struct that defines agreement properties for an upcoming or active milestone
   * @param milestoneIndex Index of the milestone
   * @param length Length of the milestone in SECONDS
   * @param amount Payment value for the milestone
   * @param claimed True if payment is claimed, false otherwise
   */
  struct Milestone {
    uint256 milestoneIndex;
    uint256 milestoneLength;
    uint256 amount;
    bool claimed;
  }

  /**
   * @notice This struct type is used to return only a subset of agreement fields for use within the SelfientManager.sol contract
   * @param agreementId The agreementId
   * @param hirer Wallet address of the hiring party
   * @param talent Wallet address of the talent
   * @param currency The currency the funds will be paid out in
   */
  struct TrimmedAgreementFields {
    uint256 agreementId;
    address hirer;
    address talent;
    address currency;
  }

  /**
   * @notice Thrown when an invalid funding amount (amoun <= 0) is entered
   */
  error InvalidFundingAmount();

  /**
   * @notice Thrown when the hirer has insuffienct funds to fund an agreement
   */
  error InsufficientBalance();

  /**
   * @notice Thrown when the chosen currency token is not allowed
   */
  error InvalidFundingCurrency();

  /**
   * @notice Thrown when the agreement length is <= 0
   */
  error InvalidAgreementLength();

  /**
   * @notice Thrown when the merkle proof provided does not contain the supplied leaf
   */
  error InvalidMilestone();

  /**
   * @notice Thrown when 0 milestones are provided when creating agreements
   */
  error NotEnoughMilestones();

  /**
   * @notice Thrown when the incoming milestone index is not the previous milestone index value incremented by 1
   */
  error InvalidMilestoneIndex();

  /**
   * @notice Thrown when the incoming milestone's length is 0
   */
  error InvalidMilestoneLength();

  /**
   * @notice Thrown when creating an agreement and a provided milestone has already been claimed
   */
  error MilestoneAlreadyClaimed();

  /**
   * @notice Thrown when the agreement contains an invalid or missing merkle root property
   */
  error MissingMerkleRoot();

  /**
   * @notice Thrown for the LinearAgreement contract where depositing funds is disabled
   */
  error DepositUnavailable();

  /**
   * @notice Thrown for the LinearAgreement contract where early withdrawals are disabled
   */
  error EarlyWithdrawalUnavailable();

  /**
   * @notice Thrown when no claimable value can be returned when calling the claimableValue method
   */
  error UnclaimableValue();

  /**
   * @notice Thrown when payment for a milestone has been claimed already
   */
  error AlreadyClaimed();

  /**
   * @notice Thrown when funds cannot be withdrawn
   */
  error WithdrawalUnavailable();

  /**
   * @notice Thrown when the required address is not the caller of the contract method
   */
  error InvalidCaller();

  /**
   * @notice Thrown when the withdrawal amount is less than or equal to zero
   */
  error InsufficientWithdrawAmt();

  /**
   * @notice Thrown for the MilestoneAgreement contract where terminating agreements is disabled
   */
  error TerminateUnavailable();

  /**
   * @notice Thrown when the signed message passed in does not match the recreated message
   * @param _signer The signer who was expected to have created the signature. Used to distinguish between
   *                issues with the hirer and talent signatures
   */
  error InvalidSignature(string _signer);

  /**
   * @notice Thrown when an agreement is created with an ID that already exists
   */
  error DuplicateAgreementId();

  /**
   * @notice Emitted by SEA contracts when an agreement is successfully created
   */
  event AgreementCreated(
    address hirer,
    address talent,
    uint256 agreementId,
    uint256 startTime
  );

  /**
   * @notice Emitted when an agreement has been terminated
   */
  event AgreementTerminated(uint256 agreementId);

  /**
   * @notice Emitted when funds have been deposited into the agreement contract
   */
  event FundsDeposited(uint256 agreementId, uint256 amount);

  /**
   * @notice Emitted every time funds have been witdrawn from the agreement contract
   */
  event FundsWithdrawn(uint256 agreementId, uint256 amount);

  /**
   * @notice Used to create a new agreement on-chain, while verifying signatures of the two parties
   * @dev Increments the agreementCounter and calls the SEA contract based on the agreementType selected
   * @param _agreementId The ID of the agreement being created
   * @param _agreement The agreement of a given type to be created
   * @param _data Any extra data required to create an agreement
   * @return _firstDeposit The value of the first deposit for the agreement being created
   */
  function createAgreement(
    uint256 _agreementId,
    NewAgreement calldata _agreement,
    bytes calldata _data
  ) external returns (uint256 _firstDeposit);

  /**
   * @notice Used to terminate the current agreement for linear agreements or the pending agreement for milestone agreements
   * @dev Requires the caller address to be the hirer address
   * @param _agreementId The ID of the agreement being terminated
   */
  function terminateAgreement(uint256 _agreementId) external;

  // /**
  //  * @notice Deposit funds into the escrow contract as a hirer using an ERC20 token to fund a future milestone
  //  * @dev Should verify the merkle proof required to fund the next milestone
  //  * @param _agreementId The ID of the agreement funds are being deposited into
  //  * @param _milestone A struct object denoting the components of the next milestone
  //  * @param _proof The merkle proof containing all the milestones as part of the agreement
  //  */
  // function depositFunds(
  //   uint256 _agreementId,
  //   Milestone memory _milestone,
  //   bytes32[] memory _proof
  // ) external;

  /**
   * @notice Deposit funds into the escrow contract as a hirer using an ERC20 token to fund a future milestone
   * @dev Should verify the merkle proof required to fund the next milestone
   * @param _agreementId The ID of the agreement funds are being deposited into
   * @param _milestone A struct object denoting the components of the next milestone
   * @param _data Any extra data required to handle this
   */
  function depositFunds(
    uint256 _agreementId,
    Milestone memory _milestone,
    bytes calldata _data
  ) external;

  /**
   * @notice Used to withdraw funds from the escrow as a talent.
   * @param _agreementId The ID of the agreement funds are being withdrawn from
   */
  function withdrawFunds(uint256 _agreementId) external;

  /**
   * @notice Used to estimate the talent's remaining claimable amount based on the current block timestamp
   * @param _agreementId The ID of the agreement being checked for claimable value
   * @return The amount of funds that can be claimed by the talent
   */
  function claimableValue(uint256 _agreementId) external view returns (uint256);

  /**
   * @notice Used to withdraw funds earlier than the end date if supported by contract
   * @param _agreementId The ID of the agreement funds are being withdrawn from
   * @param _hirerSignature Hirer's signed message containing the function params as encrypted string
   * @param _talentSignature Talents's signed message containing the function params as encrypted string
   */
  function earlyWithdrawFunds(
    uint256 _agreementId,
    bytes memory _hirerSignature,
    bytes memory _talentSignature
  ) external;

  /**
   * @notice Get the current status of an agreement by agreement ID. The returned status may be:
   * @param _agreementId The ID of the agreement being checked for status
   * @return AgreementStatus The status of the agreement
   */
  function agreementStatus(
    uint256 _agreementId
  ) external returns (AgreementStatus);

  /**
   * @notice Used to retrieve the agreement details from the agreements mapping based on agreementId
   */
  function agreements(
    uint256 _agreementId
  )
    external
    view
    returns (
      uint256 agreementId,
      address hirer,
      address talent,
      uint8 agreementType,
      address currency,
      uint256 amount,
      uint256 startDate,
      uint256 lastClaim,
      uint256 agreementLength,
      bytes32 root
    );

  /**
   * @notice Used to retrive agreement fields that are required in the pass-through methods on SelfientManager.sol. Reduces the gas-cost when fetching an agreement so that it only returns the required fields for those methods.
   */
  function getTrimmedAgreementFields(
    uint256 _agreementId
  ) external view returns (TrimmedAgreementFields memory);

  /**
   * @notice Used to retrieve the total amount of funds claimed by the talent so far
   * @dev After the final claim has been made this should be equal to the total amount for an agreement
   * @param _agreementId The ID of the agreement being checked for total claimed value
   * @return The total amount of funds claimed by the talent
   */
  function totalClaimed(uint256 _agreementId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 *   @notice Helpers for Selfient contracts
 */
library SelfientLibrary {
  /**
   * @dev Thrown whenever a zero-address check fails
   * @param field The name of the field on which the zero-address check failed
   */
  error ZeroAddress(string field);

  /**
   * @notice Thrown when an agreement is not found based on its agreement id
   */
  error AgreementNotFound();

  /**
   * @notice Check if a field is the zero address, if so revert with the field name
   * @param _address The address to check
   * @param _field The name of the field to check
   */
  function checkZeroAddress(
    address _address,
    string memory _field
  ) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }
}