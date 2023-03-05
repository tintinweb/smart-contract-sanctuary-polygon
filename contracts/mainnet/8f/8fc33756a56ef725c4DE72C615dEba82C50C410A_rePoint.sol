// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRePointToken is IERC20{
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RePointToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("rePointToken", "RPT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiPort {

    address factory;

    constructor(address _factoryAddr) {
        factory = _factoryAddr;
    }

    function distribute(address[] calldata members, uint256[] calldata fractions) public {
        require(msg.sender == factory, "only Factory can distribute");
        uint256 balance = address(this).balance;
        uint256 len = members.length;
        for(uint256 i; i < len; i++) {
            payable(members[i]).transfer(balance * fractions[i]/1000);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MultiPort.sol";

contract OldUsers {

    MultiPort[] _ports_;

    address[] _members_;
    mapping(address => uint256) _fractions_;


    constructor(address[] memory _members, uint256[] memory _fractions, uint256 numPorts) {
        require(
            _members.length == _fractions.length, 
            "_fractions_ and _members_ length difference"
        );
        uint256 denom;
        for(uint256 i; i < _fractions.length; i++) {
            denom += _fractions[i];
            _fractions_[_members[i]] = _fractions[i];
        }
        require(denom == 1000, "wrong denominator sum");
        _members_ = _members;

        for(uint256 i; i < numPorts; i++) {
            _ports_.push(newPort());
        }
    }

    function ports() public view returns(address[] memory temp) {
        uint256 len = _ports_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = address(_ports_[i]);
        }
    }

    function members() public view returns(address[] memory temp) {
        uint256 len = _members_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _members_[i];
        }
    }

    function fractions() public view returns(uint256[] memory temp) {
        uint256 len = _members_.length;
        temp = new uint256[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _fractions_[_members_[i]];
        }
    }

    function newPort() private returns(MultiPort mp) {
        mp = new MultiPort(address(this));
    }

    function changeAddr(address newAddr) public {
        address oldAddr = msg.sender;
        uint256 len = _members_.length;
        bool oldAddrExists;
        uint256 oldIndex;
        
        for(uint256 i; i < len; i++) {
            if (oldAddr == _members_[i]) {
                oldIndex = i;
                oldAddrExists = true;
                break;
            }
        }
        require(oldAddrExists, "you are not exist in the contract");

        _members_[oldIndex] = _members_[len-1];
        _members_.pop();
        _members_.push(newAddr);

        _fractions_[newAddr] = _fractions_[oldAddr];
        delete _fractions_[oldAddr];
    }

    function distribute() public {
        uint256 portsLen = _ports_.length;

        address[] memory _members = _members_; 
        uint256 membersLen = _members_.length;
        uint256[] memory _fractions = new uint256[](membersLen);

        for(uint256 i; i < membersLen; i++) {
            _fractions[i] = _fractions_[_members[i]];
        }

        for(uint256 i; i < portsLen; i++) {
            _ports_[i].distribute(_members, _fractions);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../ERC20/IRePointToken.sol";
import "./EnumerableArrays.sol";
import "./PriceFeed.sol";

import "./LotteryPool/LotteryPool.sol";
import "./ExtraPool/ExtraPool.sol";
import "./SystemPool/SystemPool.sol";


abstract contract DataStorage is EnumerableArrays, PriceFeed {

    IRePointToken RPT;
    LotteryPool public LPool;
    ExtraPool public XPool;
    SystemPool SPool;   

    address payable rewardAddr;
    address payable lotteryAddr;
    address payable extraAddr;
    address payable systemAddr;


    struct NodeData {
        uint24 allUsersLeft;
        uint24 allUsersRight;
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint16 maxPoints;
        uint16 childs;
        uint16 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => uint256) _userAllEarned_USD;
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(string => address) public nameToAddr;
    mapping(address => string) public addrToName;
    mapping(uint256 => string) public idToName;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    uint256 public lastReward24h;
    uint256 public lastReward7d;
    uint256 public lastReward30d;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public todayPointOverflow;
    uint256 public todayEnteredUSD;
    uint256 public allEnteredUSD;
    uint256 maxOld;


    function AllPayments() public view returns(
        uint256 rewardPaymentsMATIC,
        uint256 rewardPaymentsUSD,
        uint256 extraPaymentsMATIC,
        uint256 extraPaymentsUSD,
        uint256 lotteryPaymentsMATIC,
        uint256 lotteryPaymentsUSD
    ) {
        rewardPaymentsMATIC = allPayments_MATIC;
        rewardPaymentsUSD = allPayments_USD;
        extraPaymentsMATIC = XPool.allPayments_MATIC();
        extraPaymentsUSD = XPool.allPayments_USD();
        lotteryPaymentsMATIC = LPool.allPayments_MATIC();
        lotteryPaymentsUSD = LPool.allPayments_USD();
    }

    function dashboard(bool getLists) public view returns(
        uint256 userCount_,
        uint256 pointValue_,
        uint256 extraPointValue_,
        uint256 lotteryPointValue_,
        uint256 todayPoints_,
        uint256 extraPoints_,
        uint256 todayEnteredUSD_,
        uint256 allEnteredUSD_,
        uint256 lotteryTickets_,
        uint256 rewardPoolBalance_,
        uint256 extraPoolBalance_,
        uint256 lotteryPoolBalance_,
        uint256 extraRewardReceiversCount_,
        string[] memory lastLotteryWinners_,
        string[] memory extraRewardReceivers_
    ) {
        userCount_ = userCount;
        pointValue_ = todayEveryPointValue(); 
        extraPointValue_ = XPool.exPointValue(); 
        lotteryPointValue_ = LPool.lotteryFractionValue(); 
        todayPoints_ = todayTotalPoint;
        extraPoints_ = XPool.extraPointCount();
        todayEnteredUSD_ = todayEnteredUSD;
        allEnteredUSD_ = allEnteredUSD;
        lotteryTickets_ = LPool.lotteryTickets();
        rewardPoolBalance_ = balance();
        extraPoolBalance_ = XPool.balance();
        lotteryPoolBalance_ = LPool.balance();
        extraRewardReceiversCount_ = XPool.extraRewardReceiversCount();
        if(getLists) {
            lastLotteryWinners_ = lastLotteryWinners();
            extraRewardReceivers_ = extraRewardReceivers();
        }
    }

    function userDashboard(string calldata username) public view returns(
        uint256 depth,
        uint256 todayPoints,
        uint256 maxPoints,
        uint256 extraPoints,
        uint256 lotteryTickets,
        uint256 todayLeft,
        uint256 todayRight,
        uint256 allTimeLeft,
        uint256 allTimeRight,
        uint256 usersLeft,
        uint256 usersRight,
        uint256 rewardEarned,
        uint256 extraEarned,
        uint256 lotteryEarned
    ) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 points = _todayPoints[dayCounter][userAddr];

        depth = _userData[userAddr].depth;
        todayPoints = _todayPoints[dayCounter][userAddr];
        maxPoints = _userData[userAddr].maxPoints;
        extraPoints = XPool.userExtraPoints(userAddr);
        lotteryTickets = LPool.userTickets(userAddr);
        todayLeft = _userData[userAddr].leftVariance + points;
        todayRight = _userData[userAddr].rightVariance + points;
        allTimeLeft = _userData[userAddr].allLeftDirect;
        allTimeRight = _userData[userAddr].allRightDirect;
        usersLeft = _userData[userAddr].allUsersLeft;
        usersRight = _userData[userAddr].allUsersRight;
        rewardEarned = _userAllEarned_USD[userAddr];
        extraEarned = XPool._userAllEarned_USD(userAddr);
        lotteryEarned = LPool._userAllEarned_USD(userAddr);
    }

    function usernameExists(string calldata username) public view returns(bool) {
        return nameToAddr[username] != address(0);
    }

    function userAddrExists(address userAddr) public view returns(bool) {
        return bytes(addrToName[userAddr]).length != 0;
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayEveryPointValue() public view returns(uint256) {
        uint256 denominator = todayTotalPoint;
        denominator = denominator > 0 ? denominator : 1;
        return address(this).balance / denominator;
    }

    function todayEveryPointValueUSD() public view returns(uint256) {
        return todayEveryPointValue() * MATIC_USD/10**18;
    }

    function userUpReferral(string calldata username) public view returns(string memory) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return addrToName[_userInfo[userAddr].uplineAddress];
    }

    function userChilds(string calldata username)
        public
        view
        returns (string memory left, string memory right)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        left = addrToName[_userInfo[userAddr].leftDirectAddress];
        right = addrToName[_userInfo[userAddr].rightDirectAddress];        
    }

    function userTree(string calldata username, uint256 len) public view returns(string[] memory temp) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        address[] memory addrs = new address[](len + 1 + len % 2);
        temp = new string[](len);

        addrs[0] = userAddr;

        uint256 i = 0;
        uint256 j = 1;
        while(j < len) {
            addrs[j] = _userInfo[addrs[i]].leftDirectAddress;
            addrs[j + 1] = _userInfo[addrs[i]].rightDirectAddress;
            i++;
            j += 2;
        }
        for(uint256 a; a < len; a++) {
            temp[a] = addrToName[addrs[a + 1]];
        }
    } 

    function userChildsCount(string calldata username)
        public
        view
        returns (uint256)
    {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _userData[userAddr].childs;        
    }
    
    function userTodayPoints(string calldata username) public view returns (uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        return _todayPoints[dayCounter][userAddr];
    }

    function userMonthPoints(string calldata username) public view returns(uint256) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 under50 = 
            _monthDirectLeft[monthCounter][userAddr] < _monthDirectRight[monthCounter][userAddr] ?
            _monthDirectLeft[monthCounter][userAddr] : _monthDirectRight[monthCounter][userAddr];
        return XPool.userExtraPoints(userAddr) * 50 + under50;
    }

    function userMonthDirects(string calldata username) public view returns(uint256 directLeft, uint256 directRight) {
        address userAddr = nameToAddr[username];
        require(userAddr != address(0), "DataStorage: user does not exist");
        uint256 monthPoints = XPool.userExtraPoints(userAddr) * 50;
        directLeft = monthPoints + _monthDirectLeft[monthCounter][userAddr];
        directRight = monthPoints + _monthDirectRight[monthCounter][userAddr];
    }

    function extraRewardReceivers() public view returns(string[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function extraRewardReceiversAddr() public view returns(address[] memory temp) {
        address[] memory addrs = XPool.extraRewardReceivers();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }

    function lastLotteryWinners() public view returns(string[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new string[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrToName[addrs[i]];
        }
    }

    function lastLotteryWinnersAddr() public view returns(address[] memory temp) {
        address[] memory addrs = LPool.lastLotteryWinners();
        uint256 len = addrs.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = addrs[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract EnumerableArrays {

    mapping(uint256 => mapping(address => uint256)) _monthDirectLeft;
    mapping(uint256 => mapping(address => uint256)) _monthDirectRight;
    mapping(uint256 => mapping(address => uint16)) _todayPoints;
    mapping(uint256 => address[]) _rewardReceivers;

    uint256 rrIndex;
    uint256 monthCounter;
    uint256 dayCounter;
    
    function _resetRewardReceivers() internal {
        rrIndex++;
    }
    function _resetMonthPoints() internal {
        monthCounter ++;
    }
    function _resetDayPoints() internal {
        dayCounter ++;
    }

    function todayRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _rewardReceivers[rrIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _rewardReceivers[rrIndex][i];
        }
    }

    function todayRewardReceiversCount() public view returns(uint256) {
        return _rewardReceivers[rrIndex].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./XDataStorage.sol";

contract ExtraPool is XDataStorage{

    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        uint256 count = extraRewardReceiversCount();
        uint256 _balance = balance();
        if(count > 0) {
            uint256 balanceUSD = _balance * MATIC_USD/10**18;
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned_USD[userAddr] += earning * MATIC_USD/10**18;
                payable(userAddr).transfer(earning);
            }
            allPayments_USD += balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyrePoint {
        uint256 userPoints = _userExtraPoints[epIndex][userAddr];
        if(userPoints == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        if(userPoints <= 30) {
            extraPointCount ++;
            _userExtraPoints[epIndex][userAddr] ++;
        }
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }

    function version() external pure returns(string memory) {
        return "3.18.3";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract XDataStorage {
    
    uint256 erIndex;
    uint256 epIndex;

    mapping(uint256 => address[]) _extraRewardReceivers;
    mapping(uint256 => mapping(address => uint256)) _userExtraPoints;

    function _resetExtraPoints() internal {
        epIndex ++;
    }
    function _resetExtraRewardReceivers() internal {
        erIndex++;
    }

    function extraRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _extraRewardReceivers[erIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _extraRewardReceivers[erIndex][i];
        }
    }

    function extraRewardReceiversCount() public view returns(uint256) {
        return _extraRewardReceivers[erIndex].length;
    }

    function userExtraPoints(address userAddr) public view returns(uint256) {
        return _userExtraPoints[epIndex][userAddr];
    }

    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;
    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        uint256 denom = extraPointCount;
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract LDataStorage {

    uint256 lcIndex;
    uint256 lwIndex;

    mapping(uint256 => address[]) _lotteryCandidates;
    mapping(uint256 => address[]) _lotteryWinners;

    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }

    function todayLotteryCandidates() public view returns(address[] memory addr) {
        uint256 len = _lotteryCandidates[lcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryCandidates[lcIndex][i];
        }
    }

    function lastLotteryWinners() public view returns(address[] memory addr) {
        uint256 len = _lotteryWinners[lwIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryWinners[lwIndex][i];
        }
    }

    function lotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length;
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length;
    }


    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function lotteryWinnersCount() public view returns(uint256) {
        uint256 count = lotteryCandidatesCount();
        return count % 20 == 0 ? count * 5/100 : count * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        uint256 denom = lotteryWinnersCount();
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }


    uint256 utIndex;
    mapping(uint256 => mapping(address => uint256)) _userTickets;

    uint256 public lotteryTickets;

    function userTickets(address userAddr) public view returns(uint256) {
        return _userTickets[utIndex][userAddr];
    }

    function _resetUserTickets() internal {
        utIndex++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";

contract LotteryPool is LDataStorage {
    
    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 _balance = balance();
        uint256 _balanceUSD = _balance * MATIC_USD/10**18;

        uint256 winnersCount = lotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, MATIC_USD
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            _userAllEarned_USD[winner] += lotteryFraction * MATIC_USD/10**18;
            payable(winner).transfer(lotteryFraction);
        }
        if(balance() < 10 ** 10) {
            allPayments_USD += _balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete lotteryTickets;
        _resetLotteryCandidates();
        _resetUserTickets();
    }

    function addAddr(address userAddr, uint256 numTickets) public payable onlyrePoint {
        require(
           numTickets <= 5, "maximum number of tickets is 5" 
        );
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
        lotteryTickets += numTickets;
        _userTickets[utIndex][userAddr] += numTickets;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }

    function version() external pure returns(string memory) {
        return "3.18.3";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract PriceFeed {
    using Strings for uint256;
    AggregatorInterface immutable AGGREGATOR_MATIC_USD;

    uint256 public MATIC_USD;
    uint256 public USD_MATIC;

    uint256 public lastUpdatePrice;

    constructor(
        address aggregatorAddr
    ) {
        AGGREGATOR_MATIC_USD = AggregatorInterface(aggregatorAddr);
        _updateMaticePrice();
    }

    function USD_MATIC_Multiplier(uint256 num) public view returns(uint256) {
        return num * USD_MATIC;
    }

    function USD_MATIC_Multiplier_String(uint256 num) public view returns(string memory) {
        return string.concat("s", (num * USD_MATIC).toString());
    }

    function get_MATIC_USD() private view returns(uint256) {
        return uint256(AGGREGATOR_MATIC_USD.latestAnswer());
    }

    function _updateMaticePrice() internal {
        uint256 MATIC_USD_8 = get_MATIC_USD();
        MATIC_USD = MATIC_USD_8 * 10 ** 10;
        USD_MATIC = 10 ** 26 / MATIC_USD_8;
    }

    function updateMaticPrice() public {
        require(
            block.timestamp > lastUpdatePrice + 4 hours,
            "time exception"
        );
        lastUpdatePrice = block.timestamp;
        _updateMaticePrice();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DataStorage.sol";
import "./LiteralRegex.sol";

contract rePoint is DataStorage {
    using LiteralRegex for string;

    constructor(
        address RPT_Addr,
        address _aggregator,
        address[] memory _system,
        uint256[] memory _fractions,
        uint256 _maxOld,
        uint256 allPayments_MATIC_,
        uint256 allPayments_USD_,
        uint256 allEnteredUSD_
    ) PriceFeed (_aggregator) {
        address repointAddr = address(this);

        RPT = IRePointToken(RPT_Addr);
        LPool = new LotteryPool(repointAddr);
        XPool = new ExtraPool(repointAddr);
        SPool = new SystemPool(_system, _fractions);

        allPayments_MATIC = allPayments_MATIC_;
        allPayments_USD = allPayments_USD_;
        allEnteredUSD = allEnteredUSD_;        

        lotteryAddr = payable(address(LPool));        
        extraAddr = payable(address(XPool));
        systemAddr = payable(address(SPool));

        maxOld = _maxOld;
        lastReward24h = 1677844800000;
        lastReward7d = 1677671000000;
        lastReward30d = 1677844800000;
    }


    function register(string calldata upReferral, string calldata username) public payable {
        uint256 enterPrice = msg.value;
        address userAddr = msg.sender;
        address upAddr = nameToAddr[upReferral];

        checkCanRegister(upReferral, username, upAddr, userAddr);
        (uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD) = checkEnterPrice(enterPrice);

        _payShares(enterPrice, enterPriceUSD);

        _newUsername(userAddr, username);
        _newNode(userAddr, upAddr, maxPoints, todayPoints);
        _setChilds(userAddr, upAddr);
        _setDirects(userAddr, upAddr, directUp, 1);
    }

    function checkCanRegister(
        string calldata upReferral,
        string calldata username,
        address upAddr,
        address userAddr
    ) internal view returns(bool) {
        require(
            userAddr.code.length == 0,
            "onlyEOAs can register"
        );
        uint256 usernameLen = bytes(username).length;
        require(
            usernameLen >= 4 && usernameLen <= 16,
            "the username must be between 4 and 16 characters" 
        );
        require(
            username.isLiteral(),
            "you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)" 
        );
        require(
            !usernameExists(username),
            "This username is taken!"
        );
        require(
            !userAddrExists(userAddr),
            "This address is already registered!"
        );
        require(
            usernameExists(upReferral),
            "This upReferral does not exist!"
        );
        require(
            _userData[upAddr].childs < 2,
            "This address have two directs and could not accept new members!"
        );
        return true;
    }

    function checkEnterPrice(uint256 enterPrice) public view returns(
        uint16 todayPoints, uint16 maxPoints, uint16 directUp, uint256 enterPriceUSD
    ) {
        if(enterPrice == USD_MATIC_Multiplier(20)) {
            maxPoints = 10;
            directUp = 1;
            enterPriceUSD = 20 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(60)) {
            maxPoints = 30;
            directUp = 3;
            enterPriceUSD = 60 * 10 ** 18;
        } else if(enterPrice == USD_MATIC_Multiplier(100)) {
            todayPoints = 1;
            maxPoints = 50;
            directUp = 5;
            enterPriceUSD = 100 * 10 ** 18;
        } else {
            revert("Wrong enter price");
        }
    }

    function _payShares(uint256 enterPrice, uint256 enterPriceUSD) internal {
        todayEnteredUSD += enterPriceUSD;
        allEnteredUSD += enterPriceUSD;
        
        lotteryAddr.transfer(enterPrice * 15/100);
        extraAddr.transfer(enterPrice * 10/100);
        systemAddr.transfer(enterPrice * 5/100);
    }

    function _newUsername(address userAddr, string memory username) internal {
        nameToAddr[username] = userAddr;
        addrToName[userAddr] = username;
        idToName[userCount] = username;
        userCount++;
    }

    function _newNode(address userAddr, address upAddr, uint16 maxPoints, uint16 todayPoints) internal {
        _userData[userAddr] = NodeData (
            0,
            0,
            0,
            0,
            0,
            0,
            _userData[upAddr].depth + 1,
            maxPoints,
            0,
            _userData[upAddr].childs
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            address(0),
            address(0)
        );
        if(todayPoints == 1) {
            _rewardReceivers[rrIndex].push(userAddr);
            _todayPoints[dayCounter][userAddr] = 1;
            todayTotalPoint ++;
        }
    }

    function _setChilds(address userAddr, address upAddr) internal {

        if (_userData[upAddr].childs == 0) {
            _userInfo[upAddr].leftDirectAddress = userAddr;
        } else {
            _userInfo[upAddr].rightDirectAddress = userAddr;
        }
        _userData[upAddr].childs++;
    }

    function _setDirects(address userAddr, address upAddr, uint16 directUp, uint16 userUp) internal { 
        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        uint256 depth = _userData[userAddr].depth;
        uint16 _pointsOverflow;
        uint16 _totalPoints;
        uint16 points;
        uint16 v;
        uint16 userTodayPoints;
        uint16 userNeededPoints;
        for (uint256 i; i < depth; i++) {
            if (_userData[userAddr].isLeftOrRightChild == 0) {
                if(_userData[upAddr].rightVariance == 0){
                    _userData[upAddr].leftVariance += directUp;
                } else {
                    if(_userData[upAddr].rightVariance < directUp) {
                        v = _userData[upAddr].rightVariance;
                        _userData[upAddr].rightVariance = 0;
                        _userData[upAddr].leftVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].rightVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersLeft += userUp;
                _userData[upAddr].allLeftDirect += directUp;
                _addMonthDirectLeft(upAddr, directUp);
            } else {
                if(_userData[upAddr].leftVariance == 0){
                    _userData[upAddr].rightVariance += directUp;
                } else {
                    if(_userData[upAddr].leftVariance < directUp) {
                        v = _userData[upAddr].leftVariance;
                        _userData[upAddr].leftVariance = 0;
                        _userData[upAddr].rightVariance += directUp - v;
                        points = v;
                    } else {
                        _userData[upAddr].leftVariance -= directUp;
                        points = directUp;
                    }
                }
                _userData[upAddr].allUsersRight += userUp;
                _userData[upAddr].allRightDirect += directUp;
                _addMonthDirectRight(upAddr, directUp);
            }

            if(points > 0) {
                userTodayPoints = _todayPoints[dayCounter][upAddr];
                userNeededPoints = _userData[upAddr].maxPoints - userTodayPoints;
                if(userNeededPoints > 0) {
                    if(userNeededPoints >= points) {
                        if(userTodayPoints == 0){
                            rewardReceivers.push(upAddr);
                        }
                        _todayPoints[dayCounter][upAddr] += points;
                        _totalPoints += points;
                    } else {
                        _todayPoints[dayCounter][upAddr] += userNeededPoints;
                        _totalPoints += userNeededPoints;
                        _pointsOverflow += points - userNeededPoints;
                        delete _userData[upAddr].leftVariance;
                        delete _userData[upAddr].rightVariance;
                    }
                } else {
                    _pointsOverflow += points;
                }
                points = 0;
            }
            userAddr = upAddr;
            upAddr = _userInfo[upAddr].uplineAddress;
        }

        todayTotalPoint += _totalPoints;
        todayPointOverflow += _pointsOverflow;
    }


    function topUp() public payable {
        address userAddr = msg.sender;
        uint256 topUpPrice = msg.value;

        address upAddr = _userInfo[userAddr].uplineAddress;
        (uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD) = _checkTopUpPrice(userAddr, topUpPrice);

        _payShares(topUpPrice, topUpPriceUSD);
        _setDirects(userAddr, upAddr, directUp, 0);
                        
        _userData[userAddr].maxPoints += maxPoints;
    }

    function _checkTopUpPrice(address userAddr, uint256 topUpPrice) internal view returns(
        uint16 maxPoints, uint16 directUp, uint256 topUpPriceUSD
    ) {
        require(
            userAddrExists(userAddr),
            "You have not registered!"
        );

        if(topUpPrice == USD_MATIC_Multiplier(40)) {
            require(
                _userData[userAddr].maxPoints != 50,
                "the highest max point possible is 50"
            );
            maxPoints = 20;
            directUp = 2;
            topUpPriceUSD = 40 * 10 ** 18;
        } else if(topUpPrice == USD_MATIC_Multiplier(80)) {
            require(
                _userData[userAddr].maxPoints == 10,
                "the highest max point is 50"
            );
            maxPoints = 40;
            directUp = 4;
            topUpPriceUSD = 80 * 10 ** 18;
        } else {
            revert("Wrong TopUp price");
        }
    }

    function distribute() public {
        uint256 currentTime = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        require(
            currentTime >= lastReward24h + 24 hours - 5 minutes,
            "The distribute Time Has Not Come"
        );
        lastReward24h = currentTime;
        _reward24h(_MATIC_USD);
        SPool.distribute();
        if(currentTime >= lastReward7d + 7 days - 35 minutes) {
            lastReward7d = currentTime;
            LPool.distribute(_MATIC_USD);
        }
        if(currentTime >= lastReward30d + 30 days - 150 minutes) {
            lastReward30d = currentTime;
            XPool.distribute(_MATIC_USD);
            _resetMonthPoints();
        }
        _updateMaticePrice();

    }

    function _reward24h(uint256 _MATIC_USD) internal {

        uint256 pointValue = todayEveryPointValue();
        uint256 pointValueUSD = pointValue * _MATIC_USD/10**18;

        address[] storage rewardReceivers = _rewardReceivers[rrIndex];

        address userAddr;
        uint256 len = rewardReceivers.length;
        uint256 userPoints;
        for(uint256 i; i < len; i++) {
            userAddr = rewardReceivers[i];
            userPoints = _todayPoints[dayCounter][userAddr];
            _userAllEarned_USD[userAddr] += userPoints * pointValueUSD;
            payable(userAddr).transfer(userPoints * pointValue);
        }

        allPayments_MATIC += todayTotalPoint * pointValue;
        allPayments_USD += todayTotalPoint * pointValueUSD;

        delete todayTotalPoint;
        delete todayPointOverflow;
        delete todayEnteredUSD;
        _resetRewardReceivers();
        _resetDayPoints();
    }

    function _addMonthDirectLeft(address userAddr, uint256 directLeft) internal {
        uint256 neededDirectLeft = 50 - _monthDirectLeft[monthCounter][userAddr];

        if(neededDirectLeft > directLeft) {
            _monthDirectLeft[monthCounter][userAddr] += directLeft;
        } else {
            if(_monthDirectRight[monthCounter][userAddr] < 50) {
                _monthDirectLeft[monthCounter][userAddr] += directLeft;
            } else {
                _monthDirectRight[monthCounter][userAddr] -= 50;
                _monthDirectLeft[monthCounter][userAddr] = directLeft - neededDirectLeft;
                XPool.addAddr(userAddr);
            }
        }
    }

    function _addMonthDirectRight(address userAddr, uint256 directRight) internal {
        uint256 neededDirectRight = 50 - _monthDirectRight[monthCounter][userAddr];

        if(neededDirectRight > directRight) {
            _monthDirectRight[monthCounter][userAddr] += directRight;
        } else {
            if(_monthDirectLeft[monthCounter][userAddr] < 50) {
                _monthDirectRight[monthCounter][userAddr] += directRight;
            } else {
                _monthDirectLeft[monthCounter][userAddr] -= 50;
                _monthDirectRight[monthCounter][userAddr] = directRight - neededDirectRight;
                XPool.addAddr(userAddr);
            }
        }
    }

    function registerInLottery(uint256 rptAmount) public payable {
        address userAddr = msg.sender;
        uint256 paidAmount = msg.value;
        require(
            userAddrExists(userAddr),
            "This address is not registered in rePoint Contract!"
        );
        require(
            rptAmount == 0 || paidAmount == 0,
            "payment by RPT and MATIC in the same time"
        );
        uint256 ticketPrice;
        uint256 numTickets;
        if(rptAmount != 0) {
            ticketPrice = 50 * 10 ** 18;
            require(
                rptAmount >= ticketPrice,
                "minimum lottery enter price is 50 RPTs"
            );
            numTickets = rptAmount / ticketPrice;
            RPT.burnFrom(userAddr, rptAmount);
        } else {
            ticketPrice = 1 * USD_MATIC;
            require(
                paidAmount >= ticketPrice,
                "minimum lottery enter price is 1 USD in MATIC"
            );
            numTickets = paidAmount / ticketPrice;
        }
        require(
            LPool.userTickets(userAddr) + numTickets <= 5,
            "maximum 5 tickets"
        );
        LPool.addAddr{value : paidAmount}(userAddr, numTickets);
    }

    function uploadOldUsers(
        string calldata upReferral,
        string calldata username,
        address userAddr,
        uint16 depth,
        uint16 maxPoints,
        uint8 isLeftOrRightChild,
        uint8 childsCount,
        uint24 allUsersLeft,
        uint24 allUsersRight,
        uint24 allLeftDirect,
        uint24 allRightDirect,
        uint16 leftVariance,
        uint16 rightVariance,
        uint256 rewardEarned,
        uint256 numTickets,
        address childLeft,
        address childRight
    ) public {
        require(userCount < maxOld, "maximum old");
        require(
            !usernameExists(username),
            "This username is taken!"
        );
        require(
            !userAddrExists(userAddr),
            "This address is already registered!"
        );
        if(userCount > 0) {
            require(
                usernameExists(upReferral),
                "This upReferral does not exist!"
            );
        }
        address upAddr = nameToAddr[upReferral];
        _userData[userAddr] = NodeData (
            allUsersLeft,
            allUsersRight,
            allLeftDirect,
            allRightDirect,
            leftVariance,
            rightVariance,
            depth,
            maxPoints,
            childsCount,
            isLeftOrRightChild
        );
        _userInfo[userAddr] = NodeInfo (
            upAddr,
            childLeft,
            childRight
        );
        _userAllEarned_USD[userAddr] = rewardEarned;
        _newUsername(userAddr, username);
        LPool.addAddr{value : 0}(userAddr, numTickets);
    }

    function emergencyMainDistribute() public {
        require(
            block.timestamp >= lastReward24h + 3 days,
            "The Emergency Time Has Not Come"
        );
        lastReward24h = block.timestamp;
        uint256 _MATIC_USD = MATIC_USD;
        _reward24h(_MATIC_USD);
        _updateMaticePrice();
    }

    function emergencyLPoolDistribute() public {
        require(
            block.timestamp >= lastReward7d + 10 days,
            "The Emergency Time Has Not Come"
        );
        lastReward7d = block.timestamp;
        LPool.distribute(MATIC_USD);
    }

    function emergencyXPoolDistribute() public {
        require(
            block.timestamp >= lastReward30d + 33 days,
            "The Emergency Time Has Not Come"
        );
        lastReward30d = block.timestamp;
        XPool.distribute(MATIC_USD);
    }

    function panic7d() public {
        require(
            block.timestamp > lastReward24h + 7 days,
            "The panic situation has not happend"
        );
        XPool.panicWithdraw();
        LPool.panicWithdraw();
        systemAddr.transfer(balance());
    }
    
    receive() external payable{}

    function version() external pure returns(string memory) {
        return "3.18.3";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SystemPool {
    
    address[] _members_;
    mapping(address => uint256) _fractions_;

    constructor (address[] memory _members, uint256[] memory _fractions) {
        require(
            _members.length == _fractions.length, 
            "_fractions_ and _members_ length difference"
        );
        uint256 denom;
        for(uint256 i; i < _fractions.length; i++) {
            denom += _fractions[i];
            _fractions_[_members[i]] = _fractions[i];
        }
        require(denom == 1000, "wrong denominator sum");
        _members_ = _members;
    }

    function members() public view returns(address[] memory temp) {
        uint256 len = _members_.length;
        temp = new address[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _members_[i];
        }
    }

    function fractions() public view returns(uint256[] memory temp) {
        uint256 len = _members_.length;
        temp = new uint256[](len);

        for(uint256 i; i < len; i++) {
            temp[i] = _fractions_[_members_[i]];
        }
    }
    
    function distribute() external {
        uint256 membersLen = _members_.length;
        uint256 balance = address(this).balance;
        address member;

        for(uint256 i; i < membersLen; i++) {
            member = _members_[i];
            payable(member).transfer(balance * _fractions_[member]/1000);
        }
    }

    receive() external payable {}

    function version() external pure returns(string memory) {
        return "3.18.3";
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract DataStorage {

    struct Node {
        uint256 leftDirect;
        uint256 rightDirect;
        uint256 ALLleftDirect;
        uint256 ALLrightDirect;
        uint256 todayCountPoint;
        uint256 depth;
        uint256 childs;
        uint256 leftOrrightUpline;
        address UplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }

    mapping(address => Node) _users;
    mapping(uint256 => address) _allUsersAddress;
    mapping(uint256 => address) Flash_User;

    address owner;
    address tokenAddress;
    address Last_Reward_Order;
    address[] Lottery_candida;
    uint256 _listingNetwork;
    uint256 _lotteryNetwork;
    uint256 _counter_Flash;
    uint256 _userId;
    uint256 lastRun;
    uint256 All_Payment;
    uint256 _count_Lottery_Candidate;
    uint256 Value_LotteryANDFee;
    uint256[] _randomNumbers;
    uint256 Lock = 0;
    uint256 Max_Point;
    uint256 Max_Lottery_Price;
    uint256 Count_Last_Users;
    IERC20 _depositToken;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOldrePoint {
    function User_Upline(address Add_Address) external view returns(address);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) +
            (value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) -
            (value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;

    import "@openzeppelin/contracts/utils/Context.sol";
    import "./SafeERC20.sol";
    import "./DataStorage.sol";


contract Smart_Binary is Context, DataStorage {
    using SafeERC20 for IERC20;

    constructor() {
        owner = _msgSender();
        _listingNetwork = 100 * 10 ** 18;
        _lotteryNetwork = 2500000 * 10 ** 18;
        Max_Point = 50;
        Max_Lottery_Price = 25;
        lastRun = block.timestamp;
        tokenAddress = 0x4DB1B84d1aFcc9c6917B5d5cF30421a2f2Cab4cf; 
        _depositToken = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        Count_Last_Users = 0;
        All_Payment = 26200 * 10 ** 18;
    }

    function Reward_24() public {
        require(Lock == 0, "Proccesing");
        require(
            _users[_msgSender()].todayCountPoint > 0,
            "You Dont Have Any Points Today"
        );

        require(
            block.timestamp > lastRun + 24 hours,
            "The Reward_24 Time Has Not Come"
        );

        Lock = 1;
        Last_Reward_Order = _msgSender();
        All_Payment += _depositToken.balanceOf(address(this));

        uint256 Value_Reward = Price_Point() * 90;
        Value_LotteryANDFee = Price_Point();

        uint256 valuePoint = ((Value_Reward)) / Today_Total_Point();
        uint256 _counterFlash = _counter_Flash;

        uint256 RewardClick = Today_Reward_Writer_Reward() * 10 ** 18;

        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            Node memory TempNode = _users[_allUsersAddress[i]];
            uint256 Point;
            uint256 Result = TempNode.leftDirect <= TempNode.rightDirect
                ? TempNode.leftDirect
                : TempNode.rightDirect;
            if (Result > 0) {
                if (Result > Max_Point) {
                    Point = Max_Point;
                    if (TempNode.leftDirect < Result) {
                        TempNode.leftDirect = 0;
                        TempNode.rightDirect -= Result;
                    } else if (TempNode.rightDirect < Result) {
                        TempNode.leftDirect -= Result;
                        TempNode.rightDirect = 0;
                    } else {
                        TempNode.leftDirect -= Result;
                        TempNode.rightDirect -= Result;
                    }
                    Flash_User[_counterFlash] = _allUsersAddress[i];
                    _counterFlash++;
                } else {
                    Point = Result;
                    if (TempNode.leftDirect < Point) {
                        TempNode.leftDirect = 0;
                        TempNode.rightDirect -= Point;
                    } else if (TempNode.rightDirect < Point) {
                        TempNode.leftDirect -= Point;
                        TempNode.rightDirect = 0;
                    } else {
                        TempNode.leftDirect -= Point;
                        TempNode.rightDirect -= Point;
                    }
                }
                TempNode.todayCountPoint = 0;
                _users[_allUsersAddress[i]] = TempNode;

                if (
                    Point * valuePoint > _depositToken.balanceOf(address(this))
                ) {
                    _depositToken.safeTransfer(
                        _allUsersAddress[i],
                        _depositToken.balanceOf(address(this))
                    );
                } else {
                    _depositToken.safeTransfer(
                        _allUsersAddress[i],
                        Point * valuePoint
                    );
                }

                if (
                    Point * 1000000 * 10 ** 18 <=
                    IERC20(tokenAddress).balanceOf(address(this))
                ) {
                    IERC20(tokenAddress).transfer(
                        _allUsersAddress[i],
                        Point * 1000000 * 10 ** 18
                    );
                }
            }
        }
        _counter_Flash = _counterFlash;
        lastRun = block.timestamp;

        if (RewardClick <= _depositToken.balanceOf(address(this))) {
            _depositToken.safeTransfer(_msgSender(), RewardClick);
        }

        Lottery_Reward();

        _depositToken.safeTransfer(
            owner,
            _depositToken.balanceOf(address(this))
        );

        Lock = 0;
    }

    function X_Emergency_72() public {
        require(_msgSender() == owner, "Just Owner Can Run This Order!");
        require(
            block.timestamp > lastRun + 72 hours,
            "The X_Emergency_72 Time Has Not Come"
        );
        _depositToken.safeTransfer(
            owner,
            _depositToken.balanceOf(address(this))
        );
    }

    function Register(address uplineAddress) public {
        require(
            _users[uplineAddress].childs != 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            _msgSender() != uplineAddress,
            "You can not enter your own address!"
        );
        bool testUser = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == _msgSender()) {
                testUser = true;
                break;
            }
        }
        require(testUser == false, "This address is already registered!");

        bool testUpline = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == uplineAddress) {
                testUpline = true;
                break;
            }
        }
        require(testUpline == true, "This Upline address is Not Exist!");

        _depositToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _listingNetwork
        );       
        _allUsersAddress[_userId] = _msgSender();
        _userId++;
        uint256 depthChild = _users[uplineAddress].depth + 1;
        _users[_msgSender()] = Node(
            0,
            0,
            0,
            0,
            0,
            depthChild,
            0,
            _users[uplineAddress].childs,
            uplineAddress,
            address(0),
            address(0)
        );
        if (_users[uplineAddress].childs == 0) {
            _users[uplineAddress].leftDirect++;
            _users[uplineAddress].ALLleftDirect++;
            _users[uplineAddress].leftDirectAddress = _msgSender();
        } else {
            _users[uplineAddress].rightDirect++;
            _users[uplineAddress].ALLrightDirect++;
            _users[uplineAddress].rightDirectAddress = _msgSender();
        }
        _users[uplineAddress].childs++;
        setTodayPoint(uplineAddress);
        address uplineNode = _users[uplineAddress].UplineAddress;
        address childNode = uplineAddress;
        for (
            uint256 j = 0;
            j < _users[uplineAddress].depth;
            j = unsafe_inc(j)
        ) {
            if (_users[childNode].leftOrrightUpline == 0) {
                _users[uplineNode].leftDirect++;
                _users[uplineNode].ALLleftDirect++;
            } else {
                _users[uplineNode].rightDirect++;
                _users[uplineNode].ALLrightDirect++;
            }
            setTodayPoint(uplineNode);
            childNode = uplineNode;
            uplineNode = _users[uplineNode].UplineAddress;
        }
        IERC20(tokenAddress).transfer(_msgSender(), 100000000 * 10 ** 18);
    }

    function Lottery_Reward() private {
        uint256 Numer_Win = ((Value_LotteryANDFee * 9) / 10 ** 18) /
            Max_Lottery_Price;

        if (Numer_Win != 0 && _count_Lottery_Candidate != 0) {
            if (_count_Lottery_Candidate > Numer_Win) {
                for (
                    uint256 i = 1;
                    i <= _count_Lottery_Candidate;
                    i = unsafe_inc(i)
                ) {
                    _randomNumbers.push(i);
                }

                for (uint256 i = 1; i <= Numer_Win; i = unsafe_inc(i)) {
                    uint256 randomIndex = uint256(
                        keccak256(
                            abi.encodePacked(block.timestamp, msg.sender, i)
                        )
                    ) % _count_Lottery_Candidate;
                    uint256 resultNumber = _randomNumbers[randomIndex];

                    _randomNumbers[randomIndex] = _randomNumbers[
                        _randomNumbers.length - 1
                    ];
                    _randomNumbers.pop();

                    _depositToken.safeTransfer(
                        Lottery_candida[resultNumber - 1],
                        Max_Lottery_Price * 10 ** 18
                    );
                }

                for (
                    uint256 i = 0;
                    i < (_count_Lottery_Candidate - Numer_Win);
                    i = unsafe_inc(i)
                ) {
                    _randomNumbers.pop();
                }
            } else {
                for (
                    uint256 i = 0;
                    i < _count_Lottery_Candidate;
                    i = unsafe_inc(i)
                ) {
                    _depositToken.safeTransfer(
                        Lottery_candida[i],
                        Max_Lottery_Price * 10 ** 18
                    );
                }
            }
        }

        for (uint256 i = 0; i < _count_Lottery_Candidate; i = unsafe_inc(i)) {
            Lottery_candida.pop();
        }

        _count_Lottery_Candidate = 0;
    }

    function Smart_Gift() public {
        require(
            _users[_msgSender()].todayCountPoint < 1,
            "You Have Points Today"
        );
        require(
            IERC20(tokenAddress).balanceOf(_msgSender()) >= _lotteryNetwork,
            "You Dont Have Enough rePoint Token!"
        );

        bool testUser = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == _msgSender()) {
                testUser = true;
                break;
            }
        }
        require(
            testUser == true,
            "This address is not in rePoint Contract!"
        );

        IERC20(tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _lotteryNetwork
        );

        Lottery_candida.push(_msgSender());
        _count_Lottery_Candidate++;
    }

    function Upload_Old_Users(
        address person,
        uint256 leftDirect,
        uint256 rightDirect,
        uint256 ALLleftDirect,
        uint256 ALLrightDirect,
        uint256 depth,
        uint256 childs,
        uint256 leftOrrightUpline,
        address UplineAddress,
        address leftDirectAddress,
        address rightDirectAddress
    ) public {
        require(_msgSender() == owner, "Just Owner Can Run This Order!");
        require(Count_Last_Users <= 262, "The number of old users is over!");

        _allUsersAddress[_userId] = person;
        _users[_allUsersAddress[_userId]] = Node(
            leftDirect,
            rightDirect,
            ALLleftDirect,
            ALLrightDirect,
            0,
            depth,
            childs,
            leftOrrightUpline,
            UplineAddress,
            leftDirectAddress,
            rightDirectAddress
        );
        IERC20(tokenAddress).transfer(person, 100000000 * 10 ** 18);
        Count_Last_Users++;
        _userId++;
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function User_Information(address UserAddress)
        public
        view
        returns (Node memory)
    {
        return _users[UserAddress];
    }

    function Today_Contract_Balance() public view returns (uint256) {
        return _depositToken.balanceOf(address(this)) / 10 ** 18;
    }

    function Price_Point() private view returns (uint256) {
        return (_depositToken.balanceOf(address(this))) / 100;
    }

    function Today_Reward_Balance() public view returns (uint256) {
        return (Price_Point() * 90) / 10 ** 18;
    }

    function Today_Gift_Balance() public view returns (uint256) {
        return (Price_Point() * 9) / 10 ** 18;
    }

    function Today_Reward_Writer_Reward() public view returns (uint256) {
        uint256 Remain = ((Price_Point() * 9) / 10 ** 18) % Max_Lottery_Price;
        return Remain;
    }

    function Number_Of_Gift_Candidate() public view returns (uint256) {
        return _count_Lottery_Candidate;
    }

    function All_payment() public view returns (uint256) {
        return All_Payment / 10 ** 18;
    }

    function X_Old_Users_Counter() public view returns (uint256) {
        return Count_Last_Users;
    }

    function Contract_Address() public view returns (address) {
        return address(this);
    }

    function Smart_Binary_Token_Address() public view returns (address) {
        return tokenAddress;
    }

    function Total_Register() public view returns (uint256) {
        return _userId;
    }

    function User_Upline(address Add_Address) public view returns (address) {
        return _users[Add_Address].UplineAddress;
    }

    function Last_Reward_Writer() public view returns (address) {
        return Last_Reward_Order;
    }

    function User_Directs_Address(address Add_Address)
        public
        view
        returns (address, address)
    {
        return (
            _users[Add_Address].leftDirectAddress,
            _users[Add_Address].rightDirectAddress
        );
    }

    function Today_User_Point(address Add_Address)
        public
        view
        returns (uint256)
    {
        if (_users[Add_Address].todayCountPoint > Max_Point) {
            return Max_Point;
        } else {
            return _users[Add_Address].todayCountPoint;
        }
    }

    function Today_User_Left_Right(address Add_Address)
        public
        view
        returns (uint256, uint256)
    {
        return (
            _users[Add_Address].leftDirect,
            _users[Add_Address].rightDirect
        );
    }

    function All_Time_User_Left_Right(address Add_Address)
        public
        view
        returns (uint256, uint256)
    {
        return (
            _users[Add_Address].ALLleftDirect,
            _users[Add_Address].ALLrightDirect
        );
    }

    function Today_Total_Point() public view returns (uint256) {
        uint256 TPoint;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            uint256 min = _users[_allUsersAddress[i]].leftDirect <=
                _users[_allUsersAddress[i]].rightDirect
                ? _users[_allUsersAddress[i]].leftDirect
                : _users[_allUsersAddress[i]].rightDirect;

            if (min > Max_Point) {
                min = Max_Point;
            }
            TPoint += min;
        }
        return TPoint;
    }

    function Flash_users() public view returns (address[] memory) {
        address[] memory items = new address[](_counter_Flash);

        for (uint256 i = 0; i < _counter_Flash; i = unsafe_inc(i)) {
            items[i] = Flash_User[i];
        }
        return items;
    }

    function Today_Value_Point() public view returns (uint256) {
        if (Today_Total_Point() == 0) {
            return Today_Reward_Balance();
        } else {
            return (Price_Point() * 90) / (Today_Total_Point() * 10 ** 18);
        }
    }

    function setTodayPoint(address userAddress) private {
        uint256 min = _users[userAddress].leftDirect <=
            _users[userAddress].rightDirect
            ? _users[userAddress].leftDirect
            : _users[userAddress].rightDirect;
        if (min > 0) {
            _users[userAddress].todayCountPoint = min;
        }
    }
  
    function User_Exist(address Useraddress)
        public
        view
        returns (string memory)
    {
        bool test = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == Useraddress) {
                test = true;
            }
        }
        if (test) {
            return "YES!";
        } else {
            return "NO!";
        }
    }
}