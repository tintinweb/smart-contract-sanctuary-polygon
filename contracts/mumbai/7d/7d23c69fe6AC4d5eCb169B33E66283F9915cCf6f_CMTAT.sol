/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}


// File contracts/cmtat/contracts/modules/BaseModule.sol

pragma solidity ^0.8.2;

// required OZ imports here


abstract contract BaseModule is Initializable, ERC20Upgradeable {
    /* Events */
    event Spend (address indexed owner, address indexed spender, uint amount);

    /* Variables */
    uint8 private _decimals;
    string public tokenId;
    string public terms;

    /* Initializers */
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __Base_init(string memory name_, string memory symbol_, uint8 decimals_, string memory tokenId_, string memory terms_) internal initializer {
        __ERC20_init(name_, symbol_);
        _decimals = decimals_;
        tokenId = tokenId_;
        terms = terms_;
    }

    function __Base_init_unchained(uint8 decimals_, string memory tokenId_, string memory terms_) internal initializer {
        _decimals = decimals_;
        tokenId = tokenId_;
        terms = terms_;
    }

    /* Methods */
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return _decimals;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        bool result = super.transferFrom(sender, recipient, amount);
        if (result == true) {
            emit Spend(sender, _msgSender(), amount);
        }

        return result;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount, uint256 currentAllowance) public virtual returns (bool) {
        require(allowance(_msgSender(), spender) == currentAllowance, "CMTAT: current allowance is not right");
        super.approve(spender, amount);
        return true;
    }

    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol

// Licence: MIT

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


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;


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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File contracts/cmtat/contracts/modules/AuthorizationModule.sol

pragma solidity ^0.8.2;

abstract contract AuthorizationModule is AccessControlUpgradeable {
}


// File contracts/cmtat/contracts/modules/BurnModule.sol

pragma solidity ^0.8.2;

abstract contract BurnModule is Initializable {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Burn (address indexed owner, uint amount);
}


// File contracts/cmtat/contracts/modules/MintModule.sol

pragma solidity ^0.8.2;

abstract contract MintModule {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint (address indexed beneficiary, uint amount);
}


// File contracts/cmtat/contracts/modules/EnforcementModule.sol

pragma solidity ^0.8.2;



/**
 * @dev Enforcement module.
 *
 * Allows the issuer to freeze transfers from a given address
 */
abstract contract EnforcementModule is Initializable, ContextUpgradeable, ERC20Upgradeable {

    /**
     * @dev Emitted when an address is frozen.
     */
    event Freeze (address indexed enforcer, address indexed owner);

    /**
     * @dev Emitted when an address is unfrozen.
     */
    event Unfreeze (address indexed enforcer, address indexed owner);

    mapping(address => bool) private _frozen;

    bytes32 public constant ENFORCER_ROLE = keccak256("ENFORCER_ROLE");
    uint8 internal constant TRANSFER_REJECTED_FROZEN = 2;
    string internal constant TEXT_TRANSFER_REJECTED_FROZEN = "All transfers paused";

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Enforcement_init() internal initializer {
        __Context_init_unchained();
        __Enforcement_init_unchained();
    }

    function __Enforcement_init_unchained() internal initializer {
    }

        /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function frozen(address account) public view virtual returns (bool) {
        return _frozen[account];
    }

    /**
     * @dev Freezes an address.
     *
     */
    function _freeze(address account) internal virtual returns (bool) {
        if (_frozen[account]) return false;
        _frozen[account] = true;
        emit Freeze(_msgSender(), account);
        return true;
    }

    /**
     * @dev Unfreezes an address.
     *
     */
    function _unfreeze(address account) internal virtual returns (bool) {
        if (!_frozen[account]) return false;
        _frozen[account] = false;
        emit Unfreeze(_msgSender(), account);
        return true;
    }

    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/cmtat/contracts/modules/PauseModule.sol

pragma solidity ^0.8.2;


/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract PauseModule is Initializable, PausableUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint8 internal constant TRANSFER_REJECTED_PAUSED = 1;
    string internal constant TEXT_TRANSFER_REJECTED_PAUSED = "All transfers paused";
}


// File contracts/cmtat/contracts/interfaces/IRule.sol

pragma solidity ^0.8.2;

interface IRule {
  function isTransferValid(
    address _from, address _to, uint256 _amount)
  external view returns (bool isValid);

  function detectTransferRestriction(
    address _from, address _to, uint256 _amount)
  external view returns (uint8);

  function canReturnTransferRestrictionCode(uint8 _restrictionCode) external view returns (bool);

  function messageForTransferRestriction(uint8 _restrictionCode) external view returns (string memory);
}


// File contracts/cmtat/contracts/interfaces/IRuleEngine.sol

pragma solidity ^0.8.2;

interface IRuleEngine {

  function setRules(IRule[] calldata rules_) external;
  function ruleLength() external view returns (uint256);
  function rule(uint256 ruleId) external view returns (IRule);
  function rules() external view returns(IRule[] memory);

  function validateTransfer(
    address _from,
    address _to,
    uint256 _amount)
  external view returns (bool);

  function detectTransferRestriction (
    address _from,
    address _to,
    uint256 _value)
  external view returns (uint8);

  function messageForTransferRestriction (uint8 _restrictionCode) external view returns (string memory);
}


// File contracts/cmtat/contracts/modules/ValidationModule.sol

pragma solidity ^0.8.2;



/**
 * @dev Validation module.
 *
 * Useful for to restrict and validate transfers
 */
abstract contract ValidationModule is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when a rule engine is set.
     */
    event RuleEngineSet (address indexed newRuleEngine);

    IRuleEngine public ruleEngine;

    /**
     * @dev Initializes the contract with rule engine.
     */
    function __Validation_init(IRuleEngine ruleEngine_) internal initializer {
        __Context_init_unchained();
        __Validation_init_unchained(ruleEngine_);
    }

    function __Validation_init_unchained(IRuleEngine ruleEngine_) internal initializer {
        if (address(ruleEngine_) != address(0)) {
            ruleEngine = ruleEngine_;
            emit RuleEngineSet(address(ruleEngine));
        }
    }

    function _validateTransfer(address from, address to, uint256 amount) internal view returns (bool) {
        return ruleEngine.validateTransfer(from, to, amount);
    }

    function _messageForTransferRestriction(uint8 restrictionCode) internal view returns (string memory) {
        return ruleEngine.messageForTransferRestriction(restrictionCode);
    }

    function _detectTransferRestriction(address from, address to, uint256 amount) internal view returns (uint8) {
        return ruleEngine.detectTransferRestriction(from, to, amount);
    }

    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/metatx/ERC2771ContextUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;


/*
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length-20];
        } else {
            return super._msgData();
        }
    }
    uint256[50] private __gap;
}


// File contracts/cmtat/contracts/modules/MetaTxModule.sol

pragma solidity ^0.8.2;

/**
 * @dev Meta transaction (gasless) module.
 *
 * Useful for to provide UX where the user does not pay gas for token exchange
 */
abstract contract MetaTxModule is ERC2771ContextUpgradeable {
  function __MetaTx_init(address forwarder) internal initializer {
    __Context_init_unchained();
    __ERC2771Context_init_unchained(forwarder);
    __MetaTx_init_unchained();
  }

  function __MetaTx_init_unchained() internal initializer {
  }
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/ArraysUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}


// File contracts/cmtat/contracts/modules/SnapshotModule.sol

pragma solidity ^0.8.2;




/**
 * @dev Snapshot module.
 *
 * Useful to take a snapshot of token holder balance and total supply at a specific time
 */

abstract contract SnapshotModule is Initializable, ContextUpgradeable, ERC20Upgradeable {
  using ArraysUpgradeable for uint256[];

  event SnapshotSchedule(uint256 indexed oldTime, uint256 indexed newTime);
  event SnapshotUnschedule(uint256 indexed time);

  struct Snapshots {
    uint256[] ids;
    uint256[] values;
  }
  
  bytes32 public constant SNAPSHOOTER_ROLE = keccak256("SNAPSHOOTER_ROLE");
  mapping(address => Snapshots) private _accountBalanceSnapshots;
  Snapshots private _totalSupplySnapshots;

  uint256 private _currentSnapshot = 0;

  uint256[] private _scheduledSnapshots;

  function __Snapshot_init() internal initializer {
    __Context_init_unchained();
    __Snapshot_init_unchained();
  }

  function __Snapshot_init_unchained() internal initializer {
  }

  function _scheduleSnapshot (uint256 time) internal returns (uint256) {
    require(block.timestamp < time, "Snapshot scheduled in the past");
    (bool found, ) = _findScheduledSnapshotIndex(time);
    require(!found, "Snapshot already scheduled for this time");
    _scheduledSnapshots.push(time);
    emit SnapshotSchedule(0, time);
    return time;
  }

  function _rescheduleSnapshot (uint256 oldTime, uint256 newTime) internal returns (uint256) {
    require(block.timestamp < oldTime, "Snapshot already done");
    require(block.timestamp < newTime, "Snapshot scheduled in the past");

    (bool foundNew, ) = _findScheduledSnapshotIndex(newTime);
    require(!foundNew, "Snapshot already scheduled for this time");

    (bool foundOld, uint256 index) = _findScheduledSnapshotIndex(oldTime);
    require(foundOld, "Snapshot not found");

    _scheduledSnapshots[index] = newTime;

    emit SnapshotSchedule(oldTime, newTime);
    return newTime;
  }

  function _unscheduleSnapshot (uint256 time) internal returns (uint256) {
    require(block.timestamp < time, "Snapshot already done");
    (bool found, uint256 index) = _findScheduledSnapshotIndex(time);
    require(found, "Snapshot not found");

    _removeScheduledItem(index);

    emit SnapshotUnschedule(time);

    return time;
  }

  function getNextSnapshots () public view returns (uint256[] memory) {
    return _scheduledSnapshots;
  }

  function snapshotBalanceOf (uint256 time, address owner) public view returns (uint256) {
    (bool snapshotted, uint256 value) = _valueAt(time, _accountBalanceSnapshots[owner]);

    return snapshotted ? value : balanceOf(owner);
  }

  function snapshotTotalSupply (uint256 time) public view returns (uint256) {
    (bool snapshotted, uint256 value) = _valueAt(time, _totalSupplySnapshots);

    return snapshotted ? value : totalSupply();
  }

  // Update balance and/or total supply snapshots before the values are modified. This is implemented
  // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    _setCurrentSnapshot();
    if (from != address(0)) {
      // for both burn and transfer
      _updateAccountSnapshot(from);
      if (to != address(0)) {
        // transfer
        _updateAccountSnapshot(to);
        } else {
        // burn
        _updateTotalSupplySnapshot();
      }
    } else {
      // mint
      _updateAccountSnapshot(to);
      _updateTotalSupplySnapshot();
    }
  }

  function _valueAt(uint256 time, Snapshots storage snapshots) private view returns (bool, uint256) {
    // When a valid snapshot is queried, there are three possibilities:
    //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
    //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
    //  to this id is the current one.
    //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
    //  requested id, and its value is the one to return.
    //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
    //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
    //  larger than the requested one.
    //
    // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
    // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
    // exactly this.

    uint256 index = snapshots.ids.findUpperBound(time);

    if (index == snapshots.ids.length) {
      return (false, 0);
    } else {
      return (true, snapshots.values[index]);
    }
  }

  function _updateAccountSnapshot(address account) private {
    _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
  }

  function _updateTotalSupplySnapshot() private {
    _updateSnapshot(_totalSupplySnapshots, totalSupply());
  }

  function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
    uint256 current = _getCurrentSnapshot();
    if (_lastSnapshot(snapshots.ids) < current) {
      snapshots.ids.push(current);
      snapshots.values.push(currentValue);
    }
  }

  function _setCurrentSnapshot() internal {
    (uint256 time) = _findScheduledMostRecentPastSnapshot();
    if (time > 0) {
      _currentSnapshot = time;
      _clearPastScheduled();
    }
  }

  function _getCurrentSnapshot() internal view virtual returns (uint256) {
    return _currentSnapshot;
  }

  function _lastSnapshot(uint256[] storage ids) private view returns (uint256) {
    if (ids.length == 0) {
      return 0;
    } else {
      return ids[ids.length - 1];
    }
  }

  function _findScheduledSnapshotIndex(uint256 time) private view returns (bool, uint256) {
    for (uint256 i=0; i<_scheduledSnapshots.length; i++) {
      if (_scheduledSnapshots[i] == time) {
        return (true, i);
      }
    }
    return (false, 0);
  }

  function _findScheduledMostRecentPastSnapshot() private view returns (uint256) {
    if (_scheduledSnapshots.length == 0) return 0;
    uint256 mostRecent = 0;
    for (uint256 i=0; i<_scheduledSnapshots.length; i++) {
      if (_scheduledSnapshots[i] <= block.timestamp && _scheduledSnapshots[i] > mostRecent) {
        mostRecent = _scheduledSnapshots[i];
      }
    }
    return mostRecent;
  }

  function _clearPastScheduled() private {
    uint256 i = 0;
    while (i < _scheduledSnapshots.length) {
      if (_scheduledSnapshots[i] <= block.timestamp) {
        _removeScheduledItem(i);
      } else {
        i += 1;
      }
    }
  }

  function _removeScheduledItem(uint256 index) private {
    _scheduledSnapshots[index] = _scheduledSnapshots[_scheduledSnapshots.length-1];
    _scheduledSnapshots.pop();
  }
  
  uint256[50] private __gap;
}


// File contracts/cmtat/contracts/CMTAT.sol

pragma solidity ^0.8.2;

// required OZ imports here













contract CMTAT is Initializable, ContextUpgradeable, BaseModule, AuthorizationModule, PauseModule, MintModule, BurnModule, EnforcementModule, ValidationModule, MetaTxModule, SnapshotModule {
  uint8 constant TRANSFER_OK = 0;
  string constant TEXT_TRANSFER_OK = "No restriction";

  function initialize (address owner, address forwarder, string memory name, string memory symbol, string memory tokenId, string memory terms) public initializer {
    __CMTAT_init(owner, forwarder, name, symbol, tokenId, terms);
  }

  /**
    * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
    * account that deploys the contract.
    *
    * See {ERC20-constructor}.
    */
  function __CMTAT_init(address owner, address forwarder, string memory name, string memory symbol, string memory tokenId, string memory terms) internal initializer {
    __Context_init_unchained();
    __Base_init_unchained(0, tokenId, terms);
    __AccessControl_init_unchained();
    __ERC20_init_unchained(name, symbol);
    __Pausable_init_unchained();
    __Enforcement_init_unchained();
    __ERC2771Context_init_unchained(forwarder);
    __MetaTx_init_unchained();
    __Snapshot_init_unchained();
    __CMTAT_init_unchained(owner);
  }

  function __CMTAT_init_unchained(address owner) internal initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setupRole(ENFORCER_ROLE, owner);
    _setupRole(MINTER_ROLE, owner);
    _setupRole(BURNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(SNAPSHOOTER_ROLE, owner);
  }

  /**
  * revokes all init roles from
  */
  function transferOwnership(address _newowner) public onlyRole(DEFAULT_ADMIN_ROLE)  {
    grantRole(DEFAULT_ADMIN_ROLE, _newowner);
    grantRole(ENFORCER_ROLE, _newowner);
    grantRole(MINTER_ROLE, _newowner);
    grantRole(BURNER_ROLE, _newowner);
    grantRole(PAUSER_ROLE, _newowner);
    grantRole(SNAPSHOOTER_ROLE, _newowner);


    renounceRole(ENFORCER_ROLE, _msgSender());
    renounceRole(MINTER_ROLE, _msgSender());
    renounceRole(BURNER_ROLE, _msgSender());
    renounceRole(PAUSER_ROLE, _msgSender());
    renounceRole(SNAPSHOOTER_ROLE, _msgSender());
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
    emit Mint(to, amount);
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
  function burnFrom(address account, uint256 amount) public onlyRole(BURNER_ROLE) {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "CMTAT: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
    emit Burn(account, amount);
  }

  /**
    * @dev Pauses all token transfers.
    *
    * See {ERC20Pausable} and {Pausable-_pause}.
    *
    * Requirements:
    *
    * - the caller must have the `PAUSER_ROLE`.
    */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
    * @dev Unpauses all token transfers.
    *
    * See {ERC20Pausable} and {Pausable-_unpause}.
    *
    * Requirements:
    *
    * - the caller must have the `PAUSER_ROLE`.
    */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
    * @dev Freezes an address.
    *
    */
  function freeze(address account) public onlyRole(ENFORCER_ROLE) returns (bool) {
    return _freeze(account);
  }

  /**
    * @dev Unfreezes an address.
    *
    */
  function unfreeze(address account) public onlyRole(ENFORCER_ROLE) returns (bool) {
    return _unfreeze(account);
  }

  function decimals() public view virtual override(ERC20Upgradeable, BaseModule) returns (uint8) { 
    return super.decimals();
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20Upgradeable, BaseModule) returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

  /**
  * @dev ERC1404 check if _value token can be transferred from _from to _to
  * @param from address The address which you want to send tokens from
  * @param to address The address which you want to transfer to
  * @param amount uint256 the amount of tokens to be transferred
  * @return code of the rejection reason
  */
  function detectTransferRestriction (address from, address to, uint256 amount) public view returns (uint8 code) {
    if (paused()) {
      return TRANSFER_REJECTED_PAUSED;
    } else if (frozen(from)) {
      return TRANSFER_REJECTED_FROZEN;
    } else if (address(ruleEngine) != address(0)) {
      return _detectTransferRestriction(from, to, amount);
    }
    return TRANSFER_OK;
  }

  /**
  * @dev ERC1404 returns the human readable explaination corresponding to the error code returned by detectTransferRestriction
  * @param restrictionCode The error code returned by detectTransferRestriction
  * @return message The human readable explaination corresponding to the error code returned by detectTransferRestriction
  */
  function messageForTransferRestriction (uint8 restrictionCode) external view returns (string memory message) {
    if (restrictionCode == TRANSFER_OK) {
      return TEXT_TRANSFER_OK;
    } else if (restrictionCode == TRANSFER_REJECTED_PAUSED) {
      return TEXT_TRANSFER_REJECTED_PAUSED;
    } else if (restrictionCode == TRANSFER_REJECTED_FROZEN) {
      return TEXT_TRANSFER_REJECTED_FROZEN;
    } else if (address(ruleEngine) != address(0)) {
      return _messageForTransferRestriction(restrictionCode);
    } 
  }

  function scheduleSnapshot (uint256 time) public onlyRole(SNAPSHOOTER_ROLE) returns (uint256) {
    return _scheduleSnapshot(time);
  }

  function rescheduleSnapshot (uint256 oldTime, uint256 newTime) public onlyRole(SNAPSHOOTER_ROLE) returns (uint256) {
    return _rescheduleSnapshot(oldTime, newTime);
  }

  function unscheduleSnapshot (uint256 time) public onlyRole(SNAPSHOOTER_ROLE) returns (uint256) {
    return _unscheduleSnapshot(time);
  }

  function setTokenId (string memory tokenId_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    tokenId = tokenId_;
  }

  function setTerms (string memory terms_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    terms = terms_;
  }

  function kill() public onlyRole(DEFAULT_ADMIN_ROLE) {
    selfdestruct(payable(_msgSender()));
  }

  function setRuleEngine(IRuleEngine ruleEngine_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    ruleEngine = ruleEngine_;
    emit RuleEngineSet(address(ruleEngine_));
  }

  function setTrustedForwarder(address trustedForwarder_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _trustedForwarder = trustedForwarder_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(SnapshotModule, ERC20Upgradeable) {
    require(!paused(), "CMTAT: token transfer while paused");
    require(!frozen(from), "CMTAT: token transfer while frozen");

    super._beforeTokenTransfer(from, to, amount);

    if (address(ruleEngine) != address(0)) {
      require(_validateTransfer(from, to, amount), "CMTAT: transfer rejected by validation module");
    }
  }

  function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address sender) {
    return super._msgSender();
  }

  function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
    return super._msgData();
  }

  uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ├╖ 2 + 1, and for v in (282): v Γêê {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/draft-EIP712Upgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}


// File contracts/cmtat/openzeppelin-contracts-upgradeable/contracts/metatx/MinimalForwarderUpgradeable.sol

// Licence: MIT

pragma solidity ^0.8.0;



/*
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarderUpgradeable is Initializable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant TYPEHASH = keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    function __MinimalForwarder_init() internal initializer {
        __EIP712_init_unchained("MinimalForwarder", "0.0.1");
        __MinimalForwarder_init_unchained();
    }

    function __MinimalForwarder_init_unchained() internal initializer {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(keccak256(abi.encode(
            TYPEHASH,
            req.from,
            req.to,
            req.value,
            req.gas,
            req.nonce,
            keccak256(req.data)
        ))).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature) public payable returns (bool, bytes memory) {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from));
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.gas / 63);

        return (success, returndata);
    }
    uint256[49] private __gap;
}


// File contracts/cmtat/contracts/mocks/MinimalForwarderMock.sol

pragma solidity ^0.8.2;

contract MinimalForwarderMock is MinimalForwarderUpgradeable {
  function initialize() public initializer {
    __MinimalForwarder_init();
  }
}


// File contracts/cmtat/contracts/mocks/RuleMock.sol

pragma solidity ^0.8.2;

contract RuleMock is IRule {
  uint8 constant AMOUNT_TOO_HIGH = 10;
  string constant TEXT_AMOUNT_TOO_HIGH = "Amount too high";
  string constant TEXT_CODE_NOT_FOUND = "Code not found";

  function isTransferValid(
    address _from, address _to, uint256 _amount)
  public pure override returns (bool isValid)
  {
    return detectTransferRestriction(_from, _to, _amount) == 0;
  }

  function detectTransferRestriction(
    address /* _from */, address /* _to */, uint256 _amount)
  public pure override returns (uint8)
  {
    return _amount < 20 ? 0 : AMOUNT_TOO_HIGH;
  }

  function canReturnTransferRestrictionCode(uint8 _restrictionCode) public pure override returns (bool) {
    return _restrictionCode == AMOUNT_TOO_HIGH;
  }

  function messageForTransferRestriction(uint8 _restrictionCode) external pure override returns (string memory) {
    return _restrictionCode == AMOUNT_TOO_HIGH ? TEXT_AMOUNT_TOO_HIGH : TEXT_CODE_NOT_FOUND;
  }
}


// File contracts/cmtat/contracts/mocks/RuleEngineMock.sol

pragma solidity ^0.8.2;



contract RuleEngineMock is IRuleEngine {
  IRule[] internal _rules;

  constructor() {
    _rules.push(new RuleMock());
  }

  function setRules(IRule[] calldata rules_) external override {
    _rules = rules_;
  }

  function ruleLength() external view override returns (uint256) {
    return _rules.length;
  }

  function rule(uint256 ruleId) external view override returns (IRule) {
    return _rules[ruleId];
  }

  function rules() external view override returns(IRule[] memory) {
    return _rules;
  }

  function detectTransferRestriction(
    address _from,
    address _to,
    uint256 _amount)
  public view override returns (uint8)
  {
    for (uint256 i = 0; i < _rules.length; i++) {
      uint8 restriction = _rules[i].detectTransferRestriction(_from, _to, _amount);
      if (restriction > 0) {
        return restriction;
      }
    }
    return 0;
  }

  function validateTransfer(
    address _from,
    address _to,
    uint256 _amount)
  public view override returns (bool)
  {
    return detectTransferRestriction(_from, _to, _amount) == 0;
  }

  function messageForTransferRestriction(uint8 _restrictionCode) public view override returns (string memory) {
    for (uint256 i = 0; i < _rules.length; i++) {
      if (_rules[i].canReturnTransferRestrictionCode(_restrictionCode)) {
        return _rules[i].messageForTransferRestriction(_restrictionCode);
      }
    }
    return "Unknown restriction code";
  }
}