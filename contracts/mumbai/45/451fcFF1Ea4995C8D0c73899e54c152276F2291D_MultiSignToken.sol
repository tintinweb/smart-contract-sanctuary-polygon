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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface MultiSignAllowance {

    /**
     * @dev Adds an investor to the list of authorized investors
     * @param allowedInvestor The address of the accepted investor
     * @param multiSigId The multisig id
     */
    function whiteList(address tokenAddress, address allowedInvestor, string calldata multiSigId) external;

    /**
     * @dev Add an investor address to the list of banned investors
     * @param bannedInvestor The address of the banned investor
     * @param multiSigId The multisig id
     */
    function blackList(address tokenAddress, address bannedInvestor, string calldata multiSigId) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface MultiSignLiquid{

    /**
     * @dev Increment liquidity
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     * @param multiSigId The multisig id
     */
    function incrementLiquidity(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) external;

    /**
     * @dev Decrement liquidity
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     * @param multiSigId The multisig id
     */
    function decrementLiquidity(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface MultiSignRole {

    /**
     * @dev Returns the role of the account
     * @param account The address of the account
     */
    function getRole(address account) external view returns (bytes32 role);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface MultiSignSupplyUpdate{

    /**
     * @dev Mint amount of token
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     * @param multiSigId The multisig id
     */
    function mint(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) external;

    /**
     * @dev Burn amount of token
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     * @param multiSigId The multisig id
     */
    function burn(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) external;

}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/AccessControl.sol";

import "./interface/MultiSignLiquid.sol";
import "./interface/MultiSignAllowance.sol";
import "./interface/MultiSignSupplyUpdate.sol";
import "./interface/MultiSignRole.sol";
import "../token/Token.sol";

// Signature policy
struct SigPolicy {
    string action;
    bool needOwnerApproval;
    uint256 nbSuperAdminApproval;
    uint256 nbAdminApproval;
    bool setted;
}

// Signature vote
struct SigVote {
    string multiSigId;
    bool ownerApproval;
    uint256 nbSuperAdminApproval;
    uint256 nbAdminApproval;
    bool setted;
}

abstract contract MultiSign is AccessControl, MultiSignLiquid, MultiSignAllowance, MultiSignSupplyUpdate, MultiSignRole {
    bytes32 public constant NONE_ROLE = keccak256("NONE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    mapping(address => bool) private _tokens;
    mapping(string => SigPolicy) private _policies;
    mapping(string => SigVote) private _votes;

    constructor(
        address owner
    ) {
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(SUPER_ADMIN_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(SUPER_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Increment liquidity
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     */
    function incrementLiquidity(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) override external {
        Token(tokenAddress).incrementLiquidity(investor,amount);
        /*
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, investor, "incrementLiquidity", multiSigId)){
            Token(tokenAddress).incrementLiquidity(investor,amount);
        }
        */
    }

    /**
     * @dev Decrement liquidity
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     */
    function decrementLiquidity(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) override external {
        Token(tokenAddress).decrementLiquidity(investor, amount);
        /*
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, investor, "decrementLiquidity", multiSigId)){
            Token(tokenAddress).decrementLiquidity(investor, amount);
        }
        */
    }

    function whiteList(address tokenAddress, address allowedInvestor, string calldata multiSigId) override external {
        Token(tokenAddress).whiteList(allowedInvestor);
        /*
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, allowedInvestor, "whiteList", multiSigId)){
            Token(tokenAddress).whiteList(allowedInvestor);
        }
        */
    }


    function blackList(address tokenAddress, address bannedInvestor, string calldata multiSigId) override external {
        Token(tokenAddress).blackList(bannedInvestor);
        /*
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, bannedInvestor, "blackList", multiSigId)){
            Token(tokenAddress).blackList(bannedInvestor);
        }
        */
    }

    /**
     * @dev Mint amount of token
     * @param tokenAddress The address of the token
     * @param investor The investor address
     * @param amount The amount of token decrement
     * @param multiSigId The multisig id
     */
    function mint(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) override external {
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, investor, "blackList", multiSigId)){
            Token(tokenAddress).mint(investor, amount);
        }
    }

    /**
      * @dev Burn amount of token
      * @param tokenAddress The address of the token
      * @param investor The investor address
      * @param amount The amount of token decrement
      * @param multiSigId The multisig id
      */
    function burn(address tokenAddress, address investor, uint256 amount, string calldata multiSigId) override external {
        checkTokenExists(tokenAddress);
        if(vote(tokenAddress, investor, "blackList", multiSigId)){
            Token(tokenAddress).burn(investor, amount);
        }
    }

    /**
     * @dev return the role of an account
     * @param account The role of the account
     */
    function getRole(address account) override external view returns (bytes32 role){
        if(hasRole(SUPER_ADMIN_ROLE, account)){
            return SUPER_ADMIN_ROLE;
        }
        if(hasRole(ADMIN_ROLE, account)){
            return ADMIN_ROLE;
        }
        if(hasRole(OWNER_ROLE, account)){
            return OWNER_ROLE;
        }
        return NONE_ROLE;
    }

    function addToken(address tokenAddress) external onlyRole(OWNER_ROLE) {
        Ownable(tokenAddress).transferOwnership(address(this));
        _tokens[tokenAddress] = true;
    }

    function removeToken(address tokenAddress) external onlyRole(OWNER_ROLE) {
        Ownable(tokenAddress).transferOwnership(_msgSender());
        _tokens[tokenAddress] = false;
    }

    /**
     * @dev Set role for an account
     * @param action The action to set policy on
     * @param policy The role of the account
     */
    function addPolicy(string calldata action, SigPolicy memory policy) external onlyRole(SUPER_ADMIN_ROLE) {
        policy.setted=true;
        _policies[action] = policy;
    }

    function isGranted(address account) internal view returns (bool role) {
        return hasRole(ADMIN_ROLE, account) || hasRole(SUPER_ADMIN_ROLE, account) || hasRole(OWNER_ROLE, account);
    }

    /**
     * @dev Set vote for an account
     * @param account The address of the account
     * @param multiSigId The id of the multi sig
     */
    function vote(address tokenAddress, address account, string memory action, string calldata multiSigId) internal returns (bool) {
        checkTokenExists(tokenAddress);
        require(isGranted(account) , string(abi.encodePacked("Account ", abi.encodePacked(account)," is not granted. ")));
        require(_policies[action].setted , string(abi.encodePacked("Policy should be defined for ", action ," first. ")));

        SigPolicy memory sigPolicy = _policies[action];
        SigVote memory sigVote = _votes[multiSigId];
        if(!sigVote.setted){
            sigVote.multiSigId=multiSigId;
            sigVote.setted=true;
        }

        if(hasRole(OWNER_ROLE,_msgSender())){
            sigVote.ownerApproval=true;
        }
        else if(hasRole(SUPER_ADMIN_ROLE,_msgSender())){
            sigVote.nbSuperAdminApproval+=1;
        }
        else if(hasRole(ADMIN_ROLE,_msgSender())){
            sigVote.nbAdminApproval+=1;
        }

        return isValidated(sigVote, sigPolicy);
    }

    function isValidated(SigVote memory sigVote, SigPolicy memory sigPolicy) internal returns (bool) {
        bool ownerMatch = sigPolicy.needOwnerApproval && sigVote.ownerApproval || !sigPolicy.needOwnerApproval && !sigVote.ownerApproval;
        return ownerMatch && sigVote.nbAdminApproval >= sigPolicy.nbAdminApproval && sigVote.nbSuperAdminApproval >= sigPolicy.nbSuperAdminApproval;
    }

    function checkTokenExists(address tokenAddress) internal{
        require(_tokens[tokenAddress], string(abi.encodePacked("Token ", abi.encodePacked(tokenAddress)," should be added to MultiSig contract first. ")));
    }
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiSign.sol";

contract MultiSignToken is MultiSign {

    constructor(address owner) MultiSign(owner){
        
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Allowance {

    /**
     * @dev Adds an investor to the list of authorized investors
     * @param allowedInvestor The address of the accepted investor
     */
    function whiteList(address allowedInvestor) external;

    /**
     * @dev Returns the list of authorized investors
     * @param investor The address of the investor
     */
    function isWhiteListed(address investor) external view returns (bool allowed);

    /**
     * @dev Add an investor address to the list of banned investors
     * @param bannedInvestor The address of the banned investor
     */
    function blackList(address bannedInvestor) external;

    /**
     * @dev Returns the list of banned investors
     * @param investor The address of the investor
     */
    function isBlackListed(address investor) external view returns (bool banned);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Liquid{

    /**
     * @dev Returns the total lock up balance
     */
    function totalLockupBalance() external view returns (uint256 balance);

    /**
     * @dev Returns the lock up balance for an investor address
     * @param investor The address of the investor
     */
    function lockupBalance(address investor) external view returns (uint256 balance);

    /**
     * @dev Lock an amount for an investor address
     * @param investor The address of the investor
     */
    function incrementLiquidity(address investor, uint256 amount) external;

    /**
     * @dev Unlock an amount for an investor address
     * @param investor The address of the investor
     */
    function decrementLiquidity(address investor, uint256 amount) external;

    /**
     * @dev Returns the total liquid balance
     */
    function totalLiquidBalance() external view returns (uint256 balance);

    /**
     * @dev Returns the liquid balance for an investor address
     * @param investor The address of the investor
     */
    function liquidBalance(address investor) external view returns (uint256 balance);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SupplyUpdate {

    /**
     * @dev Mint amount of token
     * @param investor The investor address
     * @param amount The amount of token decrement
     */
     function mint(address investor, uint256 amount) external;

     /**
      * @dev Burn amount of token
      * @param investor The investor address
      * @param amount The amount of token decrement
      */
     function burn(address investor, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Strings.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./interface/base/Allowance.sol";
import "./interface/base/SupplyUpdate.sol";
import "./interface/base/Liquid.sol";

abstract contract Token is ERC20, Ownable, Allowance, SupplyUpdate, Liquid {

    mapping(address => bool) private _allowedInvestor;
    mapping(address => bool) private _bannedInvestor;
    mapping(address => uint256) private _lockUp;
    uint256 private _totalLockupBalance;

    constructor(address owner, uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(owner, initialSupply);
        _transferOwnership(owner);
    }

    /**
    * @dev Adds an investor to the list of authorized investors
    * @param investor The address of the investor
    */
    function whiteList(address investor) override external onlyOwner{
        _allowedInvestor[investor] = true;
    }

    /**
    * @dev Returns the list of authorized investors
    * @param investor The address of the investor
    */
    function isWhiteListed(address investor) override external view returns (bool allowed) {
        return _allowedInvestor[investor];
    }

    /**
    * @dev Add an investor address to the list of banned investors
    * @param investor The address of the banned investor
    */
    function blackList(address investor) override external onlyOwner{
        _bannedInvestor[investor] = true;
    }

    /**
    * @dev Returns the list of banned investors
    */
    function isBlackListed(address investor) override external view returns (bool banned){
        return _bannedInvestor[investor];
    }

    function decrementLiquidity(address investor, uint256 amount) override external onlyOwner{
        _decrementLiquidity(investor, amount);
    }

    function _decrementLiquidity(address investor, uint256 amount) internal onlyOwner{
        require(_lockUp[investor] + amount <= balanceOf(investor), string(abi.encodePacked("Investor ", abi.encodePacked(investor)," balance is ", Strings.toString(balanceOf(investor)))));
        require(_totalLockupBalance + amount <= totalSupply(), string(abi.encodePacked("Total lock up balance is ", Strings.toString(_totalLockupBalance),", total supply is ", Strings.toString(totalSupply()))));
        _lockUp[investor] += amount;
        _totalLockupBalance += amount;
    }

    function incrementLiquidity(address investor, uint256 amount) override external onlyOwner{
        require(_lockUp[investor] >= amount, string(abi.encodePacked("Investor ", abi.encodePacked(investor)," lock up amount is only ", Strings.toString(_lockUp[investor]))));
        require(_totalLockupBalance  >= amount, string(abi.encodePacked("Total lock up balance is only", Strings.toString(_totalLockupBalance))));
        _lockUp[investor] -= amount;
        _totalLockupBalance -= amount;
    }

    /**
    * @dev Returns the total lock up balance
    */
    function totalLockupBalance() override external view returns (uint256 balance){
        return _totalLockupBalance;
    }

    /**
    * @dev Returns the lock up balance for an investor address
    * @param investor The address of the investor
    */
    function lockupBalance(address investor) override external view returns (uint256 balance){
        return _lockUp[investor];
    }

    /**
    * @dev Returns the total liquid balance
    */
    function totalLiquidBalance() override external view returns (uint256 balance){
        return totalSupply() - _totalLockupBalance;
    }

    /**
    * @dev Returns the liquid balance for an investor address
    * @param investor The address of the investor
    */
    function liquidBalance(address investor) override external view returns (uint256 balance){
        return _liquidBalance(investor);
    }

    function _liquidBalance(address investor) internal view returns (uint256 balance){
        return balanceOf(investor)-_lockUp[investor];
    }

    /**
    * @dev Destroys `amount` tokens from the caller.
    * @notice The caller should be the owner
    * @param amount The address of the investor
    */
    function burn(address investor, uint256 amount) override external onlyOwner{
        _burn(investor, amount);
    }

    /**
    * @dev Mint `amount` tokens from the caller.
    * @notice The caller should be the owner
    * @param amount The address of the investor
    */
    function mint(address investor, uint256 amount) override external onlyOwner{
        _mint(investor, amount);
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
    ) override internal virtual {
        require(address(0) == from || amount <= _liquidBalance(from), string(abi.encodePacked("Investor ", abi.encodePacked(from)," liquid balance is ", Strings.toString(_liquidBalance(from)))));
    }

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
    ) override internal virtual {
        if(address(0) != from){
            _decrementLiquidity(from, amount);
        }
    }

}