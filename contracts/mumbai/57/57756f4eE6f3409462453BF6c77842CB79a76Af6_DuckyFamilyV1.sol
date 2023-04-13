// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/AccessControl.sol';

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import '../../../interfaces/IVoucher.sol';
import '../../../interfaces/IDucklings.sol';
import '../Random.sol';
import '../Genome.sol';

contract DuckyFamilyV1 is IVoucher, AccessControl, Random {
	using Genome for uint256;
	using ECDSA for bytes32;

	// errors
	error InvalidMintParams(MintParams mintParams);
	error InvalidMeldParams(MeldParams meldParams);

	error MintingRulesViolated(uint8 collectionId, uint8 amount);
	error MeldingRulesViolated(uint256[] tokenIds);
	error IncorrectGenomesForMelding(uint256[] genomes);

	// events
	event Melded(address owner, uint256[] meldingTokenIds, uint256 meldedTokenId, uint256 chainId);

	// roles
	bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

	// ------- IVoucher -------

	enum VoucherActions {
		MintPack,
		MeldFlock
	}

	struct MintParams {
		address to;
		uint8 size;
		bool isTransferable;
	}

	struct MeldParams {
		address owner;
		uint256[] tokenIds;
		bool isTransferable;
	}

	address public issuer;

	// Store the vouchers to avoid replay attacks
	mapping(bytes32 => bool) internal _usedVouchers;

	// ------- Ducklings Game -------

	// for now, Solidity does not support starting value for enum
	// enum Collections {
	// 	Duckling = 0,
	// 	Zombeak,
	// 	Mythic
	// }

	uint8 internal constant ducklingCollectionId = 0;
	uint8 internal constant zombeakCollectionId = 1;
	uint8 internal constant mythicCollectionId = 2;

	uint8 internal constant RARITIES_NUM = 4;

	enum Rarities {
		Common,
		Rare,
		Epic,
		Legendary
	}

	enum GeneDistributionTypes {
		Even,
		Uneven
	}

	enum GenerativeGenes {
		Collection,
		Rarity,
		Color,
		Family,
		Body,
		Head
	}

	enum MythicGenes {
		Collection,
		UniqId
	}

	// ------- Internal values -------

	uint8 public constant MAX_PACK_SIZE = 50;
	uint8 public constant FLOCK_SIZE = 5;

	uint8 internal constant collectionGeneIdx = Genome.COLLECTION_GENE_IDX;
	uint8 internal constant rarityGeneIdx = 1;
	uint8 internal constant flagsGeneIdx = Genome.FLAGS_GENE_IDX;
	// general genes start after Collection and Rarity
	uint8 internal constant generativeGenesOffset = 2;

	// number of values for each gene for Duckling and Zombeak collections
	uint8[][2] internal collectionsGeneValuesNum = [
		// Duckling genes: (Collection, Rarity), Color, Family, Body, Head, Eyes, Beak, Wings, FirstName, Temper, Skill, Habitat, Breed
		[4, 5, 10, 25, 30, 14, 10, 36, 16, 12, 5, 28],
		// Zombeak genes: (Collection, Rarity), Color, Family, Body, Head, Eyes, Beak, Wings, FirstName, Temper, Skill, Habitat, Breed
		[2, 3, 7, 6, 9, 7, 10, 36, 16, 12, 5, 28]
	];
	// distribution type of each gene for Duckling and Zombeak collections
	uint32[2] internal collectionsGeneDistributionTypes = [
		2940, // reverse(001111101101) = 101101111100
		2940 // reverse(001111101101) = 101101111100
	];

	// peculiarity is a sum of uneven gene values for Ducklings
	uint16 internal maxPeculiarity;
	uint8 internal constant MYTHIC_DISPERSION = 5;
	uint8 internal mythicAmount = 59;

	// chance of a Duckling of a certain rarity to be generated
	uint32[] internal rarityChances = [850, 120, 25, 5]; // per mil

	// chance of a Duckling of certain rarity to mutate to Zombeak while melding
	uint32[] internal collectionMutationChances = [150, 100, 50, 10]; // per mil

	uint32[] internal geneMutationChance = [955, 45]; // 4.5% to mutate gene value
	uint32[] internal geneInheritanceChances = [400, 300, 150, 100, 50]; // per mil

	// ------- Public values -------

	ERC20Burnable public duckiesContract;
	IDucklings public ducklingsContract;
	address public treasureVaultAddress;

	uint256 public mintPrice;
	uint256[RARITIES_NUM] public meldPrices; // [0] - melding Commons, [1] - melding Rares...

	// ------- Initializer -------

	constructor(address duckiesAddress, address ducklingsAddress, address treasureVaultAddress_) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(MAINTAINER_ROLE, msg.sender);

		duckiesContract = ERC20Burnable(duckiesAddress);
		ducklingsContract = IDucklings(ducklingsAddress);
		treasureVaultAddress = treasureVaultAddress_;

		uint256 decimalsMultiplier = 10 ** duckiesContract.decimals();

		mintPrice = 50 * decimalsMultiplier;
		meldPrices = [
			100 * decimalsMultiplier,
			200 * decimalsMultiplier,
			500 * decimalsMultiplier,
			1000 * decimalsMultiplier
		];

		maxPeculiarity = _calcMaxPeculiarity();
	}

	// ------- Vouchers -------

	function setIssuer(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
		issuer = account;
	}

	function useVouchers(Voucher[] calldata vouchers, bytes calldata signature) external {
		_requireCorrectSigner(abi.encode(vouchers), signature, issuer);
		for (uint8 i = 0; i < vouchers.length; i++) {
			_useVoucher(vouchers[i]);
		}
	}

	function useVoucher(Voucher calldata voucher, bytes calldata signature) external {
		_requireCorrectSigner(abi.encode(voucher), signature, issuer);
		_useVoucher(voucher);
	}

	function _useVoucher(Voucher memory voucher) internal {
		_requireValidVoucher(voucher);

		_usedVouchers[voucher.voucherCodeHash] = true;

		// parse & process Voucher
		if (voucher.action == uint8(VoucherActions.MintPack)) {
			MintParams memory mintParams = abi.decode(voucher.encodedParams, (MintParams));

			// mintParams checks
			if (
				mintParams.to == address(0) ||
				mintParams.size == 0 ||
				mintParams.size > MAX_PACK_SIZE
			) revert InvalidMintParams(mintParams);

			_mintPackTo(mintParams.to, mintParams.size, mintParams.isTransferable);
		} else if (voucher.action == uint8(VoucherActions.MeldFlock)) {
			MeldParams memory meldParams = abi.decode(voucher.encodedParams, (MeldParams));

			// meldParams checks
			if (meldParams.owner == address(0) || meldParams.tokenIds.length != FLOCK_SIZE)
				revert InvalidMeldParams(meldParams);

			_meldOf(meldParams.owner, meldParams.tokenIds, meldParams.isTransferable);
		} else {
			revert InvalidVoucher(voucher);
		}

		emit VoucherUsed(
			voucher.beneficiary,
			voucher.action,
			voucher.voucherCodeHash,
			voucher.chainId
		);
	}

	function _requireValidVoucher(Voucher memory voucher) internal view {
		if (_usedVouchers[voucher.voucherCodeHash])
			revert VoucherAlreadyUsed(voucher.voucherCodeHash);

		if (
			voucher.target != address(this) ||
			voucher.beneficiary != msg.sender ||
			block.timestamp > voucher.expire ||
			voucher.chainId != block.chainid
		) revert InvalidVoucher(voucher);
	}

	function _requireCorrectSigner(
		bytes memory encodedData,
		bytes memory signature,
		address signer
	) internal pure {
		address actualSigner = keccak256(encodedData).toEthSignedMessageHash().recover(signature);
		if (actualSigner != signer) revert IncorrectSigner(signer, actualSigner);
	}

	// -------- Config --------

	function setMintPrice(uint256 price) external onlyRole(MAINTAINER_ROLE) {
		mintPrice = price * 10 ** duckiesContract.decimals();
	}

	function getMeldPrices() external view returns (uint256[RARITIES_NUM] memory) {
		return meldPrices;
	}

	function setMeldPrices(
		uint256[RARITIES_NUM] calldata prices
	) external onlyRole(MAINTAINER_ROLE) {
		for (uint8 i = 0; i < RARITIES_NUM; i++) {
			meldPrices[i] = prices[i] * 10 ** duckiesContract.decimals();
		}
	}

	function getCollectionsGeneValues() external view returns (uint8[][2] memory, uint8) {
		return (collectionsGeneValuesNum, mythicAmount);
	}

	function getCollectionsGeneDistributionTypes() external view returns (uint32[2] memory) {
		return collectionsGeneDistributionTypes;
	}

	function setDucklingGeneValues(
		uint8[] memory duckingGeneValuesNum
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		collectionsGeneValuesNum[0] = duckingGeneValuesNum;
		maxPeculiarity = _calcMaxPeculiarity();
	}

	function setDucklingGeneDistributionTypes(
		uint32 ducklingGeneDistrTypes
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		collectionsGeneDistributionTypes[0] = ducklingGeneDistrTypes;
		maxPeculiarity = _calcMaxPeculiarity();
	}

	function setZombeakGeneValues(
		uint8[] memory zombeaksGeneValuesNum
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		collectionsGeneValuesNum[1] = zombeaksGeneValuesNum;
	}

	function setZombeakGeneDistributionTypes(
		uint32 zombeakGeneDistrTypes
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		collectionsGeneDistributionTypes[1] = zombeakGeneDistrTypes;
	}

	function setMythicAmount(uint8 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
		mythicAmount = amount;
	}

	// ------- Mint -------

	function mintPack(uint8 size) external UseRandom {
		duckiesContract.transferFrom(msg.sender, treasureVaultAddress, mintPrice * size);
		_mintPackTo(msg.sender, size, true);
	}

	function _mintPackTo(
		address to,
		uint8 amount,
		bool isTransferable
	) internal returns (uint256[] memory tokenIds) {
		if (amount == 0 || amount > MAX_PACK_SIZE)
			revert MintingRulesViolated(ducklingCollectionId, amount);

		tokenIds = new uint256[](amount);
		uint256[] memory tokenGenomes = new uint256[](amount);

		for (uint256 i = 0; i < amount; i++) {
			tokenGenomes[i] = _generateGenome(ducklingCollectionId).setFlag(
				Genome.FLAG_TRANSFERABLE,
				isTransferable
			);
		}

		tokenIds = ducklingsContract.mintBatchTo(to, tokenGenomes);
	}

	function _generateGenome(uint8 collectionId) internal returns (uint256) {
		if (collectionId != ducklingCollectionId && collectionId != zombeakCollectionId) {
			revert MintingRulesViolated(collectionId, 1);
		}

		uint256 genome;

		genome = genome.setGene(collectionGeneIdx, collectionId);
		genome = genome.setGene(rarityGeneIdx, uint8(_generateRarity()));
		genome = _generateAndSetGenes(genome, collectionId);
		genome = genome.setGene(Genome.MAGIC_NUMBER_GENE_IDX, Genome.BASE_MAGIC_NUMBER);

		return genome;
	}

	function _generateRarity() internal returns (Rarities) {
		return Rarities(_randomWeightedNumber(rarityChances));
	}

	function _generateAndSetGenes(uint256 genome, uint8 collectionId) internal returns (uint256) {
		uint8[] memory geneValuesNum = collectionsGeneValuesNum[collectionId];
		uint32 geneDistributionTypes = collectionsGeneDistributionTypes[collectionId];

		// generate and set each gene
		for (uint8 i = 0; i < geneValuesNum.length; i++) {
			GeneDistributionTypes distrType = _getDistributionType(geneDistributionTypes, i);
			uint8 geneValue;

			if (distrType == GeneDistributionTypes.Even) {
				geneValue = uint8(_randomMaxNumber(geneValuesNum[i]));
			} else {
				geneValue = uint8(_generateUnevenGeneValue(geneValuesNum[i]));
			}

			// gene with value 0 means it is a default value, thus this   \/
			genome = genome.setGene(generativeGenesOffset + i, geneValue + 1);
		}

		// set default values for Ducklings
		if (collectionId == ducklingCollectionId) {
			Rarities rarity = Rarities(genome.getGene(rarityGeneIdx));

			if (rarity == Rarities.Common) {
				genome = genome.setGene(uint8(GenerativeGenes.Body), 0);
				genome = genome.setGene(uint8(GenerativeGenes.Head), 0);
			} else if (rarity == Rarities.Rare) {
				genome = genome.setGene(uint8(GenerativeGenes.Head), 0);
			}
		}

		return genome;
	}

	function _generateMythicGenome(uint256[] memory genomes) internal returns (uint256) {
		uint16 sumPeculiarity = 0;
		uint16 maxSumPeculiarity = maxPeculiarity * uint16(genomes.length);

		for (uint8 i = 0; i < genomes.length; i++) {
			sumPeculiarity += _calcPeculiarity(genomes[i]);
		}

		uint16 maxUniqId = mythicAmount - 1;
		uint16 pivotalUniqId = uint16((uint64(sumPeculiarity) * maxUniqId) / maxSumPeculiarity); // multiply and then divide to avoid float numbers
		uint16 leftEndUniqId;
		uint16 uniqIdSegmentLength;

		if (pivotalUniqId < MYTHIC_DISPERSION) {
			// mythic id range overlaps with left dispersion border
			leftEndUniqId = 0;
			uniqIdSegmentLength = pivotalUniqId + MYTHIC_DISPERSION;
		} else if (maxUniqId < pivotalUniqId + MYTHIC_DISPERSION) {
			// mythic id range overlaps with right dispersion border
			leftEndUniqId = pivotalUniqId - MYTHIC_DISPERSION;
			uniqIdSegmentLength = maxUniqId - pivotalUniqId + MYTHIC_DISPERSION;
		} else {
			// mythic id range does not overlap with dispersion borders
			leftEndUniqId = pivotalUniqId - MYTHIC_DISPERSION;
			uniqIdSegmentLength = 2 * MYTHIC_DISPERSION;
		}

		uint16 uniqId = leftEndUniqId + uint16(Random._randomMaxNumber(uniqIdSegmentLength));

		uint256 genome;
		genome = genome.setGene(collectionGeneIdx, mythicCollectionId);
		genome = genome.setGene(uint8(MythicGenes.UniqId), uint8(uniqId));
		genome = genome.setGene(Genome.MAGIC_NUMBER_GENE_IDX, Genome.MYTHIC_MAGIC_NUMBER);

		return genome;
	}

	// ------- Meld -------

	function meldFlock(uint256[] calldata meldingTokenIds) external UseRandom {
		// assume all tokens have the same rarity. This is checked later.
		uint256 meldPrice = meldPrices[
			ducklingsContract.getGenome(meldingTokenIds[0]).getGene(rarityGeneIdx)
		];
		duckiesContract.transferFrom(msg.sender, treasureVaultAddress, meldPrice);

		_meldOf(msg.sender, meldingTokenIds, true);
	}

	function _meldOf(
		address owner,
		uint256[] memory meldingTokenIds,
		bool isTransferable
	) internal returns (uint256) {
		if (meldingTokenIds.length != FLOCK_SIZE) revert MeldingRulesViolated(meldingTokenIds);
		if (!ducklingsContract.isOwnerOfBatch(owner, meldingTokenIds))
			revert MeldingRulesViolated(meldingTokenIds);

		uint256[] memory meldingGenomes = ducklingsContract.getGenomes(meldingTokenIds);
		_requireGenomesSatisfyMelding(meldingGenomes);

		ducklingsContract.burnBatch(meldingTokenIds);

		uint256 meldedGenome = _meldGenomes(meldingGenomes).setFlag(
			Genome.FLAG_TRANSFERABLE,
			isTransferable
		);
		uint256 meldedTokenId = ducklingsContract.mintTo(owner, meldedGenome);

		emit Melded(owner, meldingTokenIds, meldedTokenId, block.chainid);

		return meldedTokenId;
	}

	function _requireGenomesSatisfyMelding(uint256[] memory genomes) internal pure {
		if (
			// equal collections
			!Genome._geneValuesAreEqual(genomes, collectionGeneIdx) ||
			// Rarities must be the same
			!Genome._geneValuesAreEqual(genomes, rarityGeneIdx) ||
			// not Mythic
			genomes[0].getGene(collectionGeneIdx) == mythicCollectionId
		) revert IncorrectGenomesForMelding(genomes);

		Rarities rarity = Rarities(genomes[0].getGene(rarityGeneIdx));
		bool sameColors = Genome._geneValuesAreEqual(genomes, uint8(GenerativeGenes.Color));
		bool sameFamilies = Genome._geneValuesAreEqual(genomes, uint8(GenerativeGenes.Family));
		bool uniqueFamilies = Genome._geneValuesAreUnique(genomes, uint8(GenerativeGenes.Family));

		// specific melding rules
		if (rarity == Rarities.Common) {
			// Common
			if (
				// cards must have the same Color OR the same Family
				!sameColors && !sameFamilies
			) revert IncorrectGenomesForMelding(genomes);
		} else {
			// Rare, Epic
			if (rarity == Rarities.Rare || rarity == Rarities.Epic) {
				if (
					// cards must have the same Color AND the same Family
					!sameColors || !sameFamilies
				) revert IncorrectGenomesForMelding(genomes);
			} else {
				// Legendary
				if (
					// not Legendary Zombeak
					genomes[0].getGene(collectionGeneIdx) == zombeakCollectionId ||
					// cards must have the same Color AND be of each Family
					!sameColors ||
					!uniqueFamilies
				) revert IncorrectGenomesForMelding(genomes);
			}
		}
	}

	function _meldGenomes(uint256[] memory genomes) internal returns (uint256) {
		uint8 collectionId = genomes[0].getGene(collectionGeneIdx);
		Rarities rarity = Rarities(genomes[0].getGene(rarityGeneIdx));

		// if melding Duckling, they can mutate or evolve into Mythic
		if (collectionId == ducklingCollectionId) {
			if (_isCollectionMutating(rarity)) {
				uint256 zombeakGenome = _generateGenome(zombeakCollectionId);
				return zombeakGenome.setGene(rarityGeneIdx, uint8(rarity));
			}

			if (rarity == Rarities.Legendary) {
				return _generateMythicGenome(genomes);
			}
		}

		uint256 meldedGenome;

		// set the same collection
		meldedGenome = meldedGenome.setGene(collectionGeneIdx, collectionId);
		// increase rarity
		meldedGenome = meldedGenome.setGene(rarityGeneIdx, genomes[0].getGene(rarityGeneIdx) + 1);

		uint8[] memory geneValuesNum = collectionsGeneValuesNum[collectionId];
		uint32 geneDistTypes = collectionsGeneDistributionTypes[collectionId];

		for (uint8 i = 0; i < geneValuesNum.length; i++) {
			uint8 geneValue = _meldGenes(
				genomes,
				generativeGenesOffset + i,
				geneValuesNum[i],
				_getDistributionType(geneDistTypes, i)
			);
			meldedGenome = meldedGenome.setGene(generativeGenesOffset + i, geneValue);
		}

		meldedGenome = meldedGenome.setGene(Genome.MAGIC_NUMBER_GENE_IDX, Genome.BASE_MAGIC_NUMBER);

		return meldedGenome;
	}

	function _isCollectionMutating(Rarities rarity) internal returns (bool) {
		// check if mutating chance for this rarity is present
		if (collectionMutationChances.length <= uint8(rarity)) {
			return false;
		}

		uint32 mutationPercentage = collectionMutationChances[uint8(rarity)];
		// dynamic array is needed for `_randomWeightedNumber()`
		uint32[] memory chances = new uint32[](2);
		chances[0] = mutationPercentage;
		chances[1] = 1000 - mutationPercentage; // 1000 as changes are represented in per mil
		return _randomWeightedNumber(chances) == 0;
	}

	function _meldGenes(
		uint256[] memory genomes,
		uint8 gene,
		uint8 maxGeneValue,
		GeneDistributionTypes geneDistrType
	) internal returns (uint8) {
		// gene mutation
		if (
			geneDistrType == GeneDistributionTypes.Uneven &&
			_randomWeightedNumber(geneMutationChance) == 1
		) {
			uint8 maxPresentGeneValue = Genome._maxGene(genomes, gene);
			return maxPresentGeneValue == maxGeneValue ? maxGeneValue : maxPresentGeneValue + 1;
		}

		// gene inheritance
		uint8 inheritanceIdx = _randomWeightedNumber(geneInheritanceChances);
		return genomes[inheritanceIdx].getGene(gene);
	}

	// ------- Gene distribution -------

	function _getDistributionType(
		uint32 distributionTypes,
		uint8 idx
	) internal pure returns (GeneDistributionTypes) {
		return
			distributionTypes & (1 << idx) == 0
				? GeneDistributionTypes.Even
				: GeneDistributionTypes.Uneven;
	}

	function _generateUnevenGeneValue(uint8 valuesNum) internal returns (uint8) {
		// using quadratic algorithm
		// chance of each gene value to be generated is (N - v)^2 / S
		// N - number of gene values, v - gene value, S - sum of Squared gene values

		uint256 N = uint256(valuesNum);
		uint256 S = (N * (N + 1) * (2 * N + 1)) / 6;
		uint256 num = _randomMaxNumber(S);
		uint256 accumNum = 0;

		for (uint8 i = 0; i < N; i++) {
			accumNum += (N - i) ** 2;

			if (num < accumNum) {
				return i;
			}
		}

		// code execution should never reach this
		return 0;
	}

	function _calcMaxPeculiarity() internal view returns (uint16) {
		uint16 sum = 0;
		uint32 ducklingDistrTypes = collectionsGeneDistributionTypes[ducklingCollectionId];
		uint8[] memory ducklingGeneValuesNum = collectionsGeneValuesNum[ducklingCollectionId];

		for (uint8 i = 0; i < ducklingGeneValuesNum.length; i++) {
			if (_getDistributionType(ducklingDistrTypes, i) == GeneDistributionTypes.Uneven) {
				// add number of values and not actual values as actual values start with 1, which means number of values and actual values are equal
				sum += ducklingGeneValuesNum[i];
			}
		}

		return sum;
	}

	function _calcPeculiarity(uint256 genome) internal view returns (uint16) {
		uint16 sum = 0;
		uint32 ducklingDistrTypes = collectionsGeneDistributionTypes[ducklingCollectionId];

		for (uint8 i = 0; i < collectionsGeneValuesNum[ducklingCollectionId].length; i++) {
			if (_getDistributionType(ducklingDistrTypes, i) == GeneDistributionTypes.Uneven) {
				// add number of values and not actual values as actual values start with 1, which means number of values and actual values are equal
				sum += genome.getGene(i + generativeGenesOffset);
			}
		}

		return sum;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
 * Genome is a number with a special structure that defines Duckling genes.
 * All genes are packed consequently in the reversed order in the Genome, meaning the first gene being stored in the last Genome bits.
 * Each gene takes up the block of 8 bits in genome, thus having 256 possible values.
 *
 * Example of genome, following genes Rarity, Head and Body are defined:
 *
 * 00000001|00000010|00000011
 *   Body    Head     Rarity
 *
 * This genome can be represented in uint24 as 66051.
 * Genes have the following values: Body = 1, Head = 2, Rarity = 3.
 */
library Genome {
	uint8 public constant BITS_PER_GENE = 8;

	uint8 public constant COLLECTION_GENE_IDX = 0;

	// Flags
	uint8 public constant FLAGS_GENE_IDX = 30;
	uint8 public constant FLAG_TRANSFERABLE = 1; // 0b0000_0001

	// Magic number
	uint8 public constant MAGIC_NUMBER_GENE_IDX = 31;
	uint8 public constant BASE_MAGIC_NUMBER = 209; // Ð
	uint8 public constant MYTHIC_MAGIC_NUMBER = 210; // Ð + 1

	function getFlags(uint256 self) internal pure returns (uint8) {
		return getGene(self, FLAGS_GENE_IDX);
	}

	function getFlag(uint256 self, uint8 flag) internal pure returns (bool) {
		return getGene(self, FLAGS_GENE_IDX) & flag > 0;
	}

	function setFlag(uint256 self, uint8 flag, bool value) internal pure returns (uint256) {
		uint8 flags = getGene(self, FLAGS_GENE_IDX);
		if (value) {
			flags |= flag;
		} else {
			flags &= ~flag;
		}
		return setGene(self, FLAGS_GENE_IDX, flags);
	}

	function setGene(
		uint256 self,
		uint8 gene,
		// by specifying uint8 we set maxCap for gene values, which is 256
		uint8 value
	) internal pure returns (uint256) {
		// number of bytes from genome's rightmost and geneBlock's rightmost
		// NOTE: maximum index of a gene is actually uint5
		uint8 shiftingBy = gene * BITS_PER_GENE;

		// remember genes we will shift off
		uint256 shiftedPart = self & ((1 << shiftingBy) - 1);

		// shift right so that genome's rightmost bit is the geneBlock's rightmost
		self >>= shiftingBy;

		// clear previous gene value by shifting it off
		self >>= BITS_PER_GENE;
		self <<= BITS_PER_GENE;

		// update gene's value
		self += value;

		// reserve space for restoring previously shifted off values
		self <<= shiftingBy;

		// restore previously shifted off values
		self += shiftedPart;

		return self;
	}

	function getGene(uint256 self, uint8 gene) internal pure returns (uint8) {
		// number of bytes from genome's rightmost and geneBlock's rightmost
		// NOTE: maximum index of a gene is actually uint5
		uint8 shiftingBy = gene * BITS_PER_GENE;

		uint256 temp = self >> shiftingBy;
		return uint8(temp & ((1 << BITS_PER_GENE) - 1));
	}

	function _maxGene(uint256[] memory genomes, uint8 gene) internal pure returns (uint8) {
		uint8 maxValue = 0;

		for (uint256 i = 0; i < genomes.length; i++) {
			uint8 geneValue = getGene(genomes[i], gene);
			if (maxValue < geneValue) {
				maxValue = geneValue;
			}
		}

		return maxValue;
	}

	function _geneValuesAreEqual(
		uint256[] memory genomes,
		uint8 gene
	) internal pure returns (bool) {
		uint8 geneValue = getGene(genomes[0], gene);

		for (uint256 i = 1; i < genomes.length; i++) {
			if (getGene(genomes[i], gene) != geneValue) {
				return false;
			}
		}

		return true;
	}

	function _geneValuesAreUnique(
		uint256[] memory genomes,
		uint8 gene
	) internal pure returns (bool) {
		uint256 valuesPresentBitfield = 1 << getGene(genomes[0], gene);

		for (uint256 i = 1; i < genomes.length; i++) {
			if (valuesPresentBitfield & (1 << getGene(genomes[i], gene)) != 0) {
				return false;
			}
			valuesPresentBitfield |= 1 << getGene(genomes[i], gene);
		}

		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// chances are represented in per mil, thus uint32
contract Random {
	error InvalidWeights(uint32[] weights);

	bytes32 private salt;
	uint256 private nonce;

	// specifies an external function which uses Random logic
	modifier UseRandom() {
		_;
		_updateSalt();
	}

	function _updateNonce() private {
		unchecked {
			nonce++;
		}
	}

	function _updateSalt() private {
		salt = keccak256(abi.encode(msg.sender, block.timestamp));
	}

	function _randomMaxNumber(uint256 max) internal returns (uint256) {
		_updateNonce();
		return uint256(keccak256(abi.encode(salt, nonce, msg.sender, block.timestamp))) % max;
	}

	function _randomWeightedNumber(uint32[] memory weights) internal returns (uint8) {
		// no sense in empty weights array
		if (weights.length == 0) revert InvalidWeights(weights);

		// generated number should be strictly less than right \/ segment boundary
		uint256 randomNumber = _randomMaxNumber(_sum(weights));

		uint256 segmentRightBoundary = 0;

		for (uint8 i = 0; i < weights.length; i++) {
			segmentRightBoundary += weights[i];
			if (randomNumber < segmentRightBoundary) {
				return i;
			}
		}

		// execution should never reach this
		return uint8(weights.length - 1);
	}

	function _sum(uint32[] memory numbers) internal pure returns (uint256 sum) {
		for (uint256 i = 0; i < numbers.length; i++) sum += numbers[i];
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IDucklings is IERC721Upgradeable {
	error TokenNotTransferable(uint256 tokenId);

	struct Duckling {
		uint256 genome;
		uint64 birthdate;
	}

	// events
	event Minted(address to, uint256 tokenId, uint256 genome, uint64 birthdate, uint256 chainId);

	function isOwnerOf(address account, uint256 tokenIds) external view returns (bool);

	function isOwnerOfBatch(
		address account,
		uint256[] calldata tokenIds
	) external view returns (bool);

	function getGenome(uint256 tokenId) external view returns (uint256);

	function getGenomes(uint256[] calldata tokenIds) external view returns (uint256[] memory);

	function mintTo(address to, uint256 genome) external returns (uint256);

	function mintBatchTo(
		address to,
		uint256[] calldata genomes
	) external returns (uint256[] memory);

	function burn(uint256 tokenId) external;

	function burnBatch(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/**
 * @notice Interface describing Voucher for redeeming game items
 *
 * @dev The Voucher type must have a strict implementation on backend
 *
 * A Voucher is a document signed from the server IssuerKey and allows the execution
 * of actions on the game generally for creating game items, such as Booster Packs, Meld or reward tokens
 *
 */
interface IVoucher {
	/**
	 * @notice Custom error specifying that voucher has already been used.
	 * @param voucherCodeHash Hash of the code of the voucher that has been used.
	 */
	error VoucherAlreadyUsed(bytes32 voucherCodeHash);

	/**
	 * @notice Custom error specifying that voucher has not passed general voucher checks and is invalid.
	 * @param voucher Voucher that is invalid.
	 */
	error InvalidVoucher(Voucher voucher);

	/**
	 * @notice Custom error specifying that the message was expected to be signed by `expected` address, but was signed by `actual`.
	 * @param expected Expected address to have signed the message.
	 * @param actual Actual address that has signed the message.
	 */
	error IncorrectSigner(address expected, address actual);

	/**
	 * @dev Build and encode the Voucher from server side
	 *
	 * Voucher structure will be valid only in chainId until expire timestamp
	 * the beneficiary MUST be the same as the user redeeming the Voucher.
	 *
	 */
	struct Voucher {
		address target; // contract address which the voucher is meant for
		uint8 action; // voucher type defined by the implementation
		address beneficiary; // beneficiary account which voucher will redeem to
		address referrer; // address of the parent
		uint64 expire; // expiration time in seconds UTC
		uint32 chainId; // chain id of the voucher
		bytes32 voucherCodeHash; // hash of voucherCode
		bytes encodedParams; // voucher type specific encoded params
	}

	/**
	 * @notice Use vouchers that were issued and signed by the Back-end to receive game items.
	 * @param vouchers Vouchers issued by the Back-end.
	 * @param signature Vouchers signed by the Back-end.
	 */
	function useVouchers(Voucher[] calldata vouchers, bytes calldata signature) external;

	/**
	 * @notice Use the voucher that was signed by the Back-end to receive game items.
	 * @param voucher Voucher issued by the Back-end.
	 * @param signature Voucher signed by the Back-end.
	 */
	function useVoucher(Voucher calldata voucher, bytes calldata signature) external;

	/**
	 * @notice Event specifying that a voucher has been used.
	 * @param wallet Wallet that used a voucher.
	 * @param action The action of the voucher used.
	 * @param voucherCodeHash The code hash of the voucher used.
	 * @param chainId Id of the chain the voucher was used on.
	 */
	event VoucherUsed(address wallet, uint8 action, bytes32 voucherCodeHash, uint32 chainId);
}