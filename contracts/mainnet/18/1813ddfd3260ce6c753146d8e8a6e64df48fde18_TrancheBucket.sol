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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/ITrancheBucket.sol";
import "./interfaces/IChamberOfCommerce.sol";
import "./interfaces/IERC4626.sol"; // NOTE maybe use a better interface, like of depositToken itsel
import "./interfaces/ITrancheBucketFactory.sol";
import "./interfaces/ITellerKeeper.sol";
import { ITrancheBucketEvents } from "./interfaces/IEvents.sol";

/**
 * @title The TrancheBucket is the contract allows a bondIssuer to tokenize certain ticket sale results.
 * @author https://github.com/kasper-keunen
 */
contract TrancheBucket is ITrancheBucket, ITrancheBucketEvents, ERC20PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // EFM Contracts
    address public factoryAddress;
    address public chamberOfCommerce;
    
    // External contract addresses/instances
    IERC20Upgradeable public fuelToken; // the token de bucketDebt is denominated in (and will be paid in by the backer) -> always GET
    IERC20Upgradeable public yieldToken; // the token the trancheShare owners will receive payment in -> either GET or xGET
    address public tellerKeeper;

    // Offering collateral/bid variables
    uint256 public palletIndex;
    uint256 public bidIdTeller;
    address public eventAddress;

    // Bucket configurations variables
    uint256 public bucketDebt; // in USD 1e18 -> $1 = 1e18
    uint256 public amountFuelReceivedPayment; // amount of fueltoken received (to pay for the ebt)
    uint256 public debtPaymentValuation; // the value of the fueltokens in USD 1e18 so $1 = 1e18
    uint256 public totalYieldCollected; // total amount of performance yield that will be claimable to the TS owners
    uint256 public supplyAtFinalization; // total amount of movable TS tokens on the moment that the performance yield becomes claimable for TS holders
    uint32 public constant marginOfErrorRange = 2000; // 2000 = 20% -> scaled 1e4
    uint256 public getPriceAtFinalization; // the price of the fuelToken, as per the Economics.sol struct, at the moment of finalization
    bool public stakedYield; // if the TS owners will receive stated token (true), or fuelTokens (false)
    uint256 private constant COOLPERIOD = 1 days; // cooldown period (time between new TS mints)
    uint256 public lastMintTimestamp; // timestamp of the most recent TS mint

    // Bucket data structs
    BucketConfiguration public bucketState;
    InventoryTranche public tranche;
    BackingStruct public backing;
    bool public bondBacked;

    constructor() initializer {}

    /**
     * @param _name the name of the ERC20 trancheShare token
     * @param _symbol the symbol of the ERC20 trancheShare token
     * @param _indexes indexes of collateral and teller loan: [0 palletIndex, 1 bidId]
     * @param _addresses addresses of relevant external contracts: [0 safeAddress, 1 chamberOfCommerce, 2 tellerKeeper, 3 fuelAddress, 4 depositTokenAddrss, 5 eventAddress]
     * @param _stakedYield if true, the performance yield will be claimable in xGET, if false, the yield will be in GET
     * TODO check in testing what happens if the offering isn't active here (so there is not bidId/palletIndex registed)
     */
    function initializeBucket(
        string memory _name,
        string memory _symbol,
        uint32 _integratorIndex,
        uint256[2] memory _indexes,
        address[6] memory _addresses,
        bool _stakedYield,
        bool _bondBacked
        ) public initializer  {
            __Ownable_init();
            __ERC20_init(_name, _symbol);
            __ERC20Pausable_init();
            transferOwnership(_addresses[0]);

            factoryAddress = msg.sender;
            palletIndex = _indexes[0];
            bidIdTeller = _indexes[1];

            __ConfigureBucket_init(
                _integratorIndex,
                _addresses,
                _stakedYield,
                _bondBacked
            );
        }

    function __ConfigureBucket_init(
        uint32 _integratorIndex,
        address[6] memory _addresses,
        bool _stakedYield,
        bool _bondBacked
    ) internal onlyInitializing {
        bucketState = BucketConfiguration.CONFIGURABLE;
        backing.verification = BackingVerification.INVALIDATED;
        chamberOfCommerce = _addresses[1];
        tellerKeeper = _addresses[2];
        fuelToken = IERC20Upgradeable(_addresses[3]);
        if(_stakedYield) {
            // yield (so the bucketDebt) will be paid & denominated in the stakeToken (xGET)
            yieldToken = IERC20Upgradeable(_addresses[4]);
        } else {
            // yield (so the bucketDebt) will be paid & denominated in the fuelToken (GET)
            yieldToken = IERC20Upgradeable(_addresses[3]);
        }
        bondBacked = _bondBacked;
        eventAddress = _addresses[5];
        stakedYield = _stakedYield;
        backing.timestampBacking = uint256(block.timestamp);
        backing.integratorIndex = _integratorIndex;
        backing.integratorData = IChamberOfCommerce(chamberOfCommerce).returnIntegratorData(_integratorIndex);
        emit BucketConfigured(_integratorIndex);
    }

    // check if the BucketConfiguration is in a certain state(_checkStatus)
    modifier checkBucketConfiguration(
        BucketConfiguration _checkStatus
    ) {
        require(
            bucketState == _checkStatus,
            "TrancheBucket:Invalid bucket state config"
        );
        _;
    }

    // check if the BucketConfiguration isn't in a certain state(_checkStatusInverse)
    modifier checkBucketConfigurationInverse(
        BucketConfiguration _checkStatusInverse
    ) {
        require(
            bucketState != _checkStatusInverse,
            "TrancheBucket:Invalid bucket state config inverse"
        );
        _;
    }

    // check if the BackingVerification is in a certain state (_checkStatus)
    modifier checkBucketVerification(
        BackingVerification _checkStatus
    ) {
        require(
            backing.verification == _checkStatus,
            "TrancheBucket:Invalid verification state"
        );
        _;
    }

    // check if caller is a DAOController
    modifier isDAOController() {
        require(
            IChamberOfCommerce(chamberOfCommerce).isDAOController(msg.sender),
            "TrancheBucket:Caller not a DAO controller"
        );
        _;
    }

    // check if caller is the TrancheBucketFactory  
    modifier onlyFactory() {
        require(
            msg.sender == factoryAddress,
            "TrancheBucket:Caller not factoryAddress"
        );
        _;
    }

    /**
     * The EFM needs to be very certain that a backer(bucket owner) is indeed a ticketeer. To not put all reposibility in the hands of a the DAO (since they need to verify the configuration) we require the relayerAddress (a key managed by the engine) to call the bucket to attest to the backers identity as a integrator/economics.sol account holder.
     * Since it is possible that a ticketeer/bondIssuer gets its public keys stolen (as they are noobs) this step requires a ticketeer to let engine call this function (this action should be triggered via the dashboard of GET Protocol). Due to this step both engine as the ticketeer need to be hacked for a attacker to be able to attempt to issue a bucket/bond. 
     * @dev This function needs to be called by engine's public key for a certain backer
     */
    function attestRelayer() external 
        checkBucketVerification(BackingVerification.INVALIDATED) {
        // fetch the integratorIndex of the relayerAddress as stored in Economics.sol
        uint32 testIndex_ = IChamberOfCommerce(chamberOfCommerce).returnIntegratorIndexByRelayer(msg.sender);
        // check if the integratorIndex of the caller is similar to the integratorIndex of the backing
        require(
            testIndex_ == backing.integratorIndex,
            "TrancheBucket:IntegratorIndex different as expected"
        );
        // if a backer was lying about the integratorIndex, this step will ensure that they cannot sell/dump trancheShares since they cannot let engine call this attest function as engine will not attest for the wrong integrator.
        backing.relayerAttestation = true;
        emit RelayerAttestation(msg.sender);
    }

    function verifyBackingConfiguration(bool _verify) external 
        checkBucketVerification(BackingVerification.INVALIDATED) 
        checkBucketConfigurationInverse(BucketConfiguration.INVALID_CANCELLED_VOID) 
        isDAOController {
        // check if engines relayer associated with the integratorIndex has called this bucket to attest to the relation
        require(
            backing.relayerAttestation,
            "TrancheBucket:Relayer hasnt attested yet"
        );
        if (_verify) { 
            backing.verification = BackingVerification.VERIFIED;
        } else {
            backing.verification = BackingVerification.INVALIDATED;
            bucketState = BucketConfiguration.INVALID_CANCELLED_VOID;
        }
        emit BackingVerified(_verify);
    }

    /**
     * @dev a TB owner/backer can only cancel a bucket if it is in the CONFIGURABLE state
     * @dev to prevent a bucket owner to cancel a bucket after a bondbuyer has accepted the terms of a bond assuming the tshares where included, we need to check the TellerContract on what the state of the loan is.
     */
    function invalidateBucketManual() external onlyOwner checkBucketConfigurationInverse(BucketConfiguration.INVALID_CANCELLED_VOID) {
        uint256 palletIndex_ = palletIndex;
        //  EXTERNAL CALL TELLER: Check if the bucket is still in CONFIGURABLE state after update of TellerKeeper
        if (_isBucketInInvalidState(palletIndex_, BucketConfiguration.CONFIGURABLE)) {  
            // Bucket is other state than CONFIGURABLE.
            emit FunctionNotFullyExecuted();
            return;
        }
        // share tokens are paused, since we do not want them to be traded anymore
        _pause();
        // set verification to INVALIDATED
        backing.verification = BackingVerification.INVALIDATED;
        // set configuration to INVALID_CANCELLED_VOID
        bucketState = BucketConfiguration.INVALID_CANCELLED_VOID;
        // delete the bucket mapping in the factory
        ITrancheBucketFactory(factoryAddress).processBucketInvalidaton(palletIndex_);
        emit ManualCancel();
    }

    /**
     * @dev function can only be called if the COC has VERIFIED the backer
     * @param _startIndexTranche first nftIndex of the performance range
     * @param _stopIndexTranche lst nftIndex of the performance range
     * @param _averagePriceNFT the estimated average price of the tickets in range. wrong estimation will not cost money for anyboy, only incorrect analytics about how big the kickback per nft is relative to the ticket price. 1000 = $1 dollar in value. 
     * @param _totalNFTInventory the total amount of nfts offered for sale (approximaltion is fine). Similar to _averagePrice it is used to approximate where in the inventory stack the range resides
     * @notice the backer sets the tranches nft range
     */
    function registerPerformanceRangeTranche(
        uint32 _startIndexTranche,
        uint32 _stopIndexTranche,
        uint32 _averagePriceNFT,
        uint32 _totalNFTInventory
        ) external 
            checkBucketVerification(BackingVerification.VERIFIED) 
            checkBucketConfigurationInverse(BucketConfiguration.INVALID_CANCELLED_VOID) 
            onlyOwner {
                // EXTERNAL CALL: Check with Teller if the (external) loan state still allows for modifiying trancheShares :)
                if (_isBucketInInvalidState(palletIndex, BucketConfiguration.CONFIGURABLE)) {
                    // BucketState is in a different state as CONFIGURATBLE -> Do not continue with function
                    emit FunctionNotFullyExecuted();
                    return;
                }
                // check if the inventory input variables make sense
                require(
                    (_stopIndexTranche > _startIndexTranche) && (_totalNFTInventory >= _stopIndexTranche),
                    "TrancheBucket:Invalid inventory ranges"
                );
                tranche.startIndexTranche = _startIndexTranche;
                tranche.stopIndexTranche = _stopIndexTranche;
                tranche.averagePriceNFT = _averagePriceNFT;
                tranche.totalNFTInventory = _totalNFTInventory;
                uint32 usdKickbackPerNft_ = tranche.usdKickbackPerNft; // 1000 = 1e3 = $1,000 = 1 dollar
                // if usdPerInRange is set, it means we have the required data to mint trancheShares
                if (usdKickbackPerNft_ != 0) {
                    // to prevent a borrower to tinker with the shares too much (it is confusing for the offering) we have a cooldown period
                    _checkMintCooldown();
                    // with every edit of the inventory info we burn all trancheShares and remint, this to lower complexity of the code
                    _burnAllShares();
                    // remint the TS them using the already set usdPerInRange and the new range
                    _mintTrancheShares(usdKickbackPerNft_); 
                    lastMintTimestamp = block.timestamp;
                    emit TrancheShareMint(totalSupply());
                    // NOTE: trancheShares can only be claimed after a TellerLoan is accepted.
                }
                emit TrancheFullyRegistered(
                    _startIndexTranche,
                    _stopIndexTranche,
                    _averagePriceNFT,
                    _totalNFTInventory
                );
    }

    /**
     * @param _usdKickbackPerNft the USD amount that will be paid to trancheShare holders, scaled by 1e3
     * @dev this function mints trancheShares to the bucket address
     * @dev this function can be called only once per 24 hours. Also note that it is only possible to call this function when:
     * - The TellerLoan is PENDING (so not yet accepted)
     * - The bucket is verified
     * - The bucket is in the CONFIGURABLE state after TellerKeeper is updated
     * - Can only be called by the backer/owner of the bucket
     */
    function setKickbackPerNFTinTranche(
        uint32 _usdKickbackPerNft // 1000 = 1e3 = $1,000 = 1 dollar
    ) external 
        checkBucketVerification(BackingVerification.VERIFIED)
        checkBucketConfigurationInverse(BucketConfiguration.INVALID_CANCELLED_VOID) 
        onlyOwner {
            // (re)minting trancheShares can only be done once every 24 hours, this as we want backers to think about this config. It would be confusing if the amount of shares would change several times a day. Lenders considering the terms of a bond need to think about the terms and if they change every 10 minutes this is unproductive
            _checkMintCooldown();
            // EXTERNAL CALL TELLER: Check if TellerKeeper is up to date
            if (_isBucketInInvalidState(palletIndex, BucketConfiguration.CONFIGURABLE)) {
                // Bucket is not in the correct state to proceed (not in CONFIGURABLE state)
                emit FunctionNotFullyExecuted();
                return;
            }
            // performance tranche range is not set - so we cannot mint TS yet
            if (totalTicketsInTranche() == 0) {
                return;
            }
            // for clarity all share tokens are burned if there where any before - so we don't need edit supply code. Also it will be on-chain clearer what the performance yield is
            if (totalSupply() > 0) _burnAllShares();
            _mintTrancheShares(_usdKickbackPerNft);
            tranche.usdKickbackPerNft = _usdKickbackPerNft;
            lastMintTimestamp = block.timestamp;
            emit TrancheShareMint(totalSupply());
            // NOTE: trancheShares can only be claimed after a TellerLoan is accepted.
    }

    /**
     * @param _stateToSet the BucketConfiguration that needs to be set
     * @param _toPause bool signalling if the trancheShare needs to be paused after the change of the BucketState
     * @dev can only be called by the TrancheBucketFactory
     */
    function setBucketState(
        BucketConfiguration _stateToSet,
        bool _toPause
    ) external onlyFactory {
        bucketState = _stateToSet;
        /**
         * The point behind pausing the ERC20 TrancheShare in certain stages is to prevent dumping/trading of the shares in periods where there is a high probablity of insidere information to be present.
         */
        if(_toPause) _pause();
        emit StateChange(_stateToSet);
    }

    /**
     * this function allows the address that has loaned to the borrower in the TellerLoan contract to claim their tranchc chares
     */
    function claimTrancheShares() external 
        checkBucketVerification(BackingVerification.VERIFIED) 
        checkBucketConfigurationInverse(BucketConfiguration.INVALID_CANCELLED_VOID) {
        // trancheShares can only be claimed if the bucket is in BUCKET_ACTIVE state -> meaning that the the configuration is complete and the tellerLoan is accepted/bought.
        if (_isBucketInInvalidState(palletIndex, BucketConfiguration.BUCKET_ACTIVE)) {
            // the function is not in the BUCKET_ACTIVE state, so we return the function without doing anything. Thereby ensuring the TellerKeeper remains updated.
            emit FunctionNotFullyExecuted();
            return;
        }
        // only the lender/buyer of the bond (so the entity the funded the loan in Teller) can claim the TrancheShares
        require(
            msg.sender == _returnValidShareClaimer(),
            "TrancheBucket:Claimer of trancheShares must owner or lender"
        );
        uint256 balance_ = balanceOf(address(this));
        // only can be called if there are trancheShares to be claimed in the bucket
        require(
            (balance_ > 0 && balance_ == totalSupply()),
            "TrancheBucket:No trancheShares available to claim"
        );
         // transfer the tranche shares from the bucket to the valid claimer
        _transfer(
            address(this), 
            msg.sender, 
            balance_
        );
        emit SharesClaimed(
            msg.sender, 
            balance_
        );
    }

    function _returnValidShareClaimer() internal view returns(address claimer_) {
        if(!bondBacked) {
            claimer_ = owner();
        } else {
            claimer_ = ITellerKeeper(tellerKeeper).getLoanLender(bidIdTeller);
        }
    }

    function updateDebt() external checkBucketVerification(BackingVerification.VERIFIED) 
        returns(uint256 debt_) {
        debt_ = _updateDebt();
        bucketDebt = debt_;
        emit UpdateDebt(
            debt_,
            block.timestamp
        );
    }

    function currentReturnPerShare() external 
        checkBucketVerification(BackingVerification.VERIFIED) 
        view returns(uint256 returnPerShare_) {
        if (totalSupply() == 0) {
            // if no shares are issues, the return per share is 0
            returnPerShare_ = 0;
        } else {
            returnPerShare_ = _updateDebt() / totalSupply();
        }
    }

    function inRange() external view returns(uint32 inRange_) {
        uint32 ticketsSold_ = IChamberOfCommerce(chamberOfCommerce).nftsIssuedForEvent(eventAddress);
        if(ticketsSold_ <= tranche.startIndexTranche) {
            // the tranche is not 'in range' so the bucketBacker has no debt
            inRange_ = 0;
        } else {
            uint32 stopIndex_ = tranche.stopIndexTranche;
            uint32 inTranche_ = ticketsSold_ >= stopIndex_ ? stopIndex_ : ticketsSold_;
            // the tranche is now 'in range' so there is a debt
            inRange_ = inTranche_ - tranche.startIndexTranche;
        }
    }

    /**
     * When the ticketsale has concluded (or more accurately the bucketDebt cannot change anymore due to ticket sales) the bucket needs to be checkedOut with this function. Since we cannot infer when the sale is over easily on-chain, we have made this function only callable by a DAOcontroller. 
     * NOTE: this function could also be made callable by the bucket owner.
     * After this function is called the bucketDebt (a USD amount) will be finalized. It effectively sets the stage for repayment of the debt. 
     * @dev The main purpose of this function is that it pauses the movement of trancheShares. The thinking here is that we are in a part of the event cycle that inside information is very much possible due to internal communication. We do not want that buyers of TS are duped because the owner knows that the bucket backer isn't going to pay the debt (argubly an edge case but still). 
     */
    function checkOutBucket() external 
        checkBucketVerification(BackingVerification.VERIFIED) 
        checkBucketConfiguration(BucketConfiguration.BUCKET_ACTIVE) 
        isDAOController {
            uint256 debt_ = _updateDebt();
            bucketDebt = debt_;
            bucketState = BucketConfiguration.AT_CHECKOUT;
            // during the payment period the trancheShares cannot be moved or traded, this to prevent insider knowledge trading about if the payment will go through effectively
            _pause();
            emit StateChange(BucketConfiguration.AT_CHECKOUT); 
            emit BucketCheckedOut(debt_);
    }

    /**
     * Function updates the amount of GET received in the contract
     * @dev anybody can call this contract but only when the bucket is in "AT_CHECKOUT" state
     */
    function registerReceivables() public 
        checkBucketVerification(BackingVerification.VERIFIED) 
        checkBucketConfiguration(BucketConfiguration.AT_CHECKOUT) 
        returns(uint256 balance_) {
        balance_ = fuelToken.balanceOf(address(this));
        amountFuelReceivedPayment = balance_;
        emit ReceivablesUpdated(balance_);
    }

    /**
     * Function calculates how much the received fueltokens are worth according to the price in the Economics.sol contract.
     * retrums the value of the received fueltokens scaled by 1e18 - with $1 being 1e18.
     */
    function valueReceived() public view returns(uint256 value_) {
        value_ = amountFuelReceivedPayment * IChamberOfCommerce(chamberOfCommerce).getIntegratorFuelPrice(backing.integratorIndex) / 1e18;
    }
 
    /**
     * If the bucket is configured that the performance yield is paid/denominated in xGET, the GET that now sits in the contract needs to be staked first
     */
    /**
     * Function makes the GET collected in the bucket contract redeemable for share holders
     * @param _checkBalance bool that indicates if the contract should check the priceing of the bucket
     * @dev can only be called by a DAO controller
     */
    function unlockRedemption(
        bool _checkBalance
        ) external 
            checkBucketVerification(BackingVerification.VERIFIED) 
            checkBucketConfiguration(BucketConfiguration.AT_CHECKOUT) 
            isDAOController returns(uint256 balance_) {
            // update the amount of GET received in the bucket
            balance_ = registerReceivables();
            // fetch the price of GET in USD
            uint256 price_ = IChamberOfCommerce(chamberOfCommerce).getIntegratorFuelPrice(backing.integratorIndex);
            getPriceAtFinalization = price_;
            // calculate the dollar value of the GET in the contract, using the GET price as per the Economics contract for the backer in question
            uint256 valueR_ = valueReceived();
            debtPaymentValuation = valueR_;
            // the reasoning the _checkBalance is optional is that i expect that price of GET in the economics contract might be lagging and contested. Even thoug I do believe it is the best price to use, i have added optionality to ensure that this part of the mechanism cannot gridlock the system. In the long term this should absolutely be mandatory.
            if(_checkBalance) {
                require(
                    _checkDebtWithinRange(bucketDebt, valueR_),
                    "TrancheBucket:Too much or too little yield token in bucket"
                );
                emit PaymentApproved();
            }
            // the trancheShares can now be transferred again, since their value is now decided (no more excessive insider trading opportunities)
            _unpause();
            // store the total amount of TrancheShares outstanding at this moment. We store this to storage at this point since it is possible people have burned the token in the meantime. Also we cannot use the current total supply since when people redeem tokens are burned and the totalsupply goes down.
            supplyAtFinalization = totalSupply();
            if (stakedYield) {
                totalYieldCollected = _stakeAll();
            } else {
                // yield is in GET, so store the balance of GET in the bucket to storage
                totalYieldCollected = fuelToken.balanceOf(address(this));
            }
            bucketState = BucketConfiguration.REDEEMABLE;
            emit StateChange(BucketConfiguration.REDEEMABLE);
            emit RedemptionUnlocked(
                balance_, 
                price_, 
                totalYieldCollected
            );
    }

    /**
     * Note this is an emergency function that transfers tokens in the bucket to the owner. It is meant to be used when the bucket receives tokens it shouldn't have (the wrong ones, too much etc).
     * @dev function can only be called by a DAO controller
     */
    function withdrawDepositedTokensManual(
        address _targetTokenAddress, 
        uint256 _amountToWithdraw) external 
        checkBucketConfiguration(BucketConfiguration.AT_CHECKOUT)
        isDAOController {
            address owner_ = owner();
            // owner of bucket must be properly configured to prevent coins are burned
            require(
                owner_ != address(0x0),
                "TrancheBucket:Owner cannot be null address"
            );
            // transfer the tokens to the owner
            IERC20Upgradeable(_targetTokenAddress).safeTransfer(owner_, _amountToWithdraw);
            emit ManualWithdraw(
                _targetTokenAddress,
                _amountToWithdraw
            );
    }

    // when called it becomes impossible to trade/transfer trancheshares
    function pauseShareToken() external isDAOController {
        _pause();
    }

    // when caleld it will enable the transfer/trade/redemtion of trancshares
    function unPauseShareToken() external isDAOController {
        _unpause();
    }

    // NOTE: THIS ONE HAS A CLEAR RE-ENTRANCY RISK!!!! ADD REENTRANCY BOOL THING
    function claimYieldAll() external 
        checkBucketVerification(BackingVerification.VERIFIED) 
        checkBucketConfiguration(BucketConfiguration.REDEEMABLE) {
        // fetch the amount of trancheShare tokens in the wallet of the caller
        uint256 amountClaim_ = balanceOf(msg.sender);
        // (redundant) check if the caller even has tokens
        require(
            amountClaim_ > 0,
            "TrancheBucket:nothing to claim"
        );
        // burn all the trancheShares in the wallet of the caller
        _burn(
            msg.sender, 
            balanceOf(msg.sender)
        );
        // calculate how much xGET the caller should received, based on its trancheShare balance
        uint256 _cut = _calculateAmountOfYield(amountClaim_);
        yieldToken.safeTransfer( 
            msg.sender,
            _cut
        );
        emit Claim(
            amountClaim_,
            _cut
        );
    }

    /**
     * Returns total amount of NFTs in the performance tranche
     */
    function totalTicketsInTranche() public view returns(uint32 _range) {
        _range = tranche.stopIndexTranche - tranche.startIndexTranche;
    }

    /**
     * Returns total USD value of the NFTs in the tranche (full USD price for buyer of ticket)
     */
    function totalValue() public view returns(uint32 _value) {
        _value = totalTicketsInTranche() * tranche.averagePriceNFT;
    }

    /**
     * Returns the total USD performance yield if all NFTs in tranche-range are sold. Meaning 1e18 = $1 max performance yield
     * @param _usdKickbackPerNft the amount of USD per NFT issued in the tranche, scaled by 1e3
     * @return maxYield_ the maximum amount of total debt/yield the bucket can accrue if all NFTs in the tranche are sold
     */
    function maxReturn(uint32 _usdKickbackPerNft) public view returns(uint256 maxYield_) {
        // 1e18 per $1, so scaled by 1e15
        maxYield_ = uint256(totalTicketsInTranche()) * uint256(_usdKickbackPerNft) * 1e15;
    }

    function returnBackingStruct() external view returns(BackingStruct memory backing_) {
        backing_ = backing;
    }

    /**
     * @dev this function checks if the TellerKeeper is up to date. The TellerKeeper is the contract that makes sure that all the EFM contracts are in sync with the teller state. After having checked for sync, this function will check if the bucketState is correct to continue with the function. 
     * @dev it is by design that this function updates bucketState. it is also by design that this function never fails or reverts, since that would mean that an update is undone.
     * @param _palletIndex the palletIndex of the collateral of the bond/loan
     * @param _onlyValidState the state the bucket must be in, for the function to proceed
     */
    function _isBucketInInvalidState(
        uint256 _palletIndex, 
        BucketConfiguration _onlyValidState
        ) internal returns(bool isInInvalidState_) {
        if (!bondBacked) {
            if (_onlyValidState == BucketConfiguration.CONFIGURABLE) {
                if (bucketState != BucketConfiguration.CONFIGURABLE) {
                    return true;
                } else {
                    return false;
                }
            } else {
                // BUCKET_ACTIVE is passed, meaning that the TS are claimed
                bucketState = BucketConfiguration.BUCKET_ACTIVE;
                return false;
            }
        }
        // EXTERNAL CALL TELLER: Check if TellerKeeper is up to date
        if (ITellerKeeper(tellerKeeper).isKeeperUpdateNeeded(_palletIndex)) {
            // Update is needed 
            ITellerKeeper(tellerKeeper).updateByPalletIndex(_palletIndex, true);
            emit BucketUpdate();
        }
        BucketConfiguration bucketState_ = bucketState;
        if(bucketState_ == _onlyValidState) {
            isInInvalidState_ = false;
            // bucketsate is correct to proceed
        } else {
            emit InvalidState(
                bucketState_,
                _onlyValidState
            );
            isInInvalidState_ = true; 
            // the function cannot proceed/continue, since the bucket is in a invalid state
        }
    }

    /**
     * 1 trancheShare (1e18) is worth $1, if the complete tranche range is sold. This makes it easy to value the potential maximum value of the trancheShares in a wallet. Since you can see the stopIndex and one can query the amount of NFTs sold. 
     * In order for this relation to be in place, we need to calculate the maximum theortical return of a trancheBucket. This is done with the maxReturn bucket.
     */
    function _mintTrancheShares(
        uint32 _usdKickbackPerNft
    ) internal {
        uint256 _toMint = maxReturn(_usdKickbackPerNft);
        // trancheShares are minted to the bucket always
        _mint(
            address(this), 
            _toMint
        );
    }

    /**
     * Internal function that burns all the trancheShares in the bucket. In preperpation for a new mint.
     */
    function _burnAllShares() internal {
        if (totalSupply() == 0) {
            return; // there are no shares to burn
        } else {
            _burn(
                address(this),
                balanceOf(address(this))
            );
            emit BurnAll();
        }
    }

    /**
     * Internal function that checks if enough time has passed to do another share mint.
     */
    function _checkMintCooldown() internal view {
        require(
            (lastMintTimestamp + COOLPERIOD) <= block.timestamp,
            "TrancheBucket:TrancheShare minting in cooldown" 
        );
    }

    /**
     * @dev Internal function 
     * totalYieldCollected = total amount of xGET that is to be collected by the TS holders.
     * _rate = the amount of xGET per trancheShare unit
     * _balanceTrancheShare = amount of transcheShares the caller has
    */
    function _calculateAmountOfYield(
        uint256 _balanceTrancheShare
    ) internal view returns(uint256 _proRataAmount) {
        uint256 _rate = (totalYieldCollected * 1e24) / supplyAtFinalization;
        _proRataAmount = (_rate * _balanceTrancheShare) / 1e24;
    }

    /**
     * Internal function that calculates the total abount of USD debt the bucket has accrued.
     * returns the amount of debt scaled 1e18, so $1 = 1e18
     */
    function _updateDebt() internal view returns(uint256 debt_) {
        // fetch the total amount of ticket/NFTs sold for the event according to the oracle
        uint32 ticketsSold_ = IChamberOfCommerce(chamberOfCommerce).nftsIssuedForEvent(eventAddress);
        uint32 startIndex_ = tranche.startIndexTranche;
        // if a tranche is 50-100 - and 50 tickets are sold - then 0 tickets are sold in the tranche since it will count starting from 51 (is 1 in the tranche)
        if(ticketsSold_ <= startIndex_) {
            // the tranche is not 'in range' so the bucketBacker has no debt
            debt_ = 0;
        } else {
            uint32 stopIndex_ = tranche.stopIndexTranche;
            uint32 inTranche_ = ticketsSold_ >= stopIndex_ ? stopIndex_ : ticketsSold_;
            // the tranche is now 'in range' so there is a debt
            uint32 inRange_ = inTranche_ - startIndex_;
            // the debt is the total amount of tickets issued in the range, multiplied by the configured kickback in the range
            // usdKickbackPerNFT is scaled 1e3, so to make the result 1e18 we need to muliply it by 1e15
            debt_ = uint256(inRange_) * uint256(tranche.usdKickbackPerNft) * 1e15;
        }
    }

    /**
     * Internal functon that checks if the value of the received GET tokens is within the margin of error (to both sides).
     * @dev An auditor would notice/comment here that it is technically possible for a bucket to never be approved/pass this check if an 'attacker' would constantly frontrun the checkout function by sending more and more GET to it - that way this check would always fail because it would seem that the backer has overpaid. While this attack is valid and can work technically, it makes no economic sense. Howver it is good to keep in mind. We could add logic that would handle the 'too much GET sent' case more elegantly (by sending change back to the backer forr example)
     */
    function _checkDebtWithinRange(uint256 _debtDue, uint256 _valueReceived) internal pure returns(bool check_) {
        // calculate the difference between the 2 values, ensuring we don't underflow
        uint256 diff_  = _debtDue > _valueReceived ? _debtDue - _valueReceived : _valueReceived - _debtDue;
        // the debt is the exact amount as is expected, return true
        if (diff_ == 0) return true;
        // calcuate the amount of USD that is the buffer/margin 
        uint256 margin_ = (_debtDue * marginOfErrorRange) / 1e4;
        // if the difference is large as the margin this means that the backer either over or underpaid
        check_ = diff_ <= margin_;
    }

    /**
     * Internal function that converts GET that is sent to the bucket into xGET(by staking it).
     * @dev function only runs if the performance yield is coonfigured to be paid out in staked tokens.
     */
    function _stakeAll() internal returns(uint256 shares_) {
        uint256 balance_ = fuelToken.balanceOf(address(this));
        require(
            balance_ > 0, 
            "TrancheBucket:No GET to convert"
        );
        fuelToken.approve(address(yieldToken), balance_);
        IERC4626 stakeContract_ = IERC4626(address(yieldToken));
        shares_ = stakeContract_.deposit(balance_, address(this));
        // check if any shares where returned
        require(
            shares_ > 0, 
            "TrancheBucket:Staking tx didn't work"
        );
        emit AllStaked(
            balance_,
            shares_
        );
    }

    // NOTE Only for testing purposes for now
    function returnTranche() external view returns(InventoryTranche memory tranche_) {
        tranche_ = tranche;
    }

    // NOTE Only for testing purposes for now
    function returnDebtWithinRange(uint256 _debtDue, uint256 _valueReceived) external pure returns(bool check_) {
        check_ = _checkDebtWithinRange(_debtDue, _valueReceived);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes, IEconomicsDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerce is ITellerV2DataTypes, IEconomicsDataTypes {
    function bondCouncil() external view returns(address);
    function fuelToken() external returns(address);
    function depositToken() external returns(address);
    function tellerContract() external returns(address);
    function clearingHouse() external returns(address);
    function ticketSaleOracle() external returns(address);
    function economics() external returns(address);
    function palletRegistry() external returns(address);
    function palletMinter() external returns(address);
    function tellerKeeper() external returns(address);
    function returnPalletLocker(address _safeAddress) external view returns(address _palletLocker);
    function isChamberPaused() external view returns (bool);

    function returnIntegratorData(
        uint32 _integratorIndex
    )  external view returns(IntegratorData memory data_);

    function isAddressBorrower(
        address _addressSafeBorrower
    ) external view returns(bool);

    function isAccountWhitelisted(
        address _addressAccount
    ) external view returns(bool);

    function isAccountBlacklisted(
        address _addressAccount
    ) external view returns(bool);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function viewIntegratorUSDBalance(
        uint32 _integratorIndex
    ) external view returns (uint256 balance_);

    function emergencyMultisig() external view returns(address);

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_);

    function isDAOController(
        address _challenedController
    ) external view returns(bool);

    function isFuelAndCollateralSufficient(
        address _palletIssuerAddress, 
        uint64 _maxAmountInventory, 
        uint64 _averagePriceInventory,
        uint256 _amountPallet) external view returns(bool judgement_);


    function getIntegratorFuelPrice(
        uint32 _integratorIndex
    ) external view returns(uint256 _price);

    function palletIndexToBid(
        uint256 _palletIndex
    ) external view returns(uint256 _bidId);

    // EXTERNALCALL TO ORACLE
    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    // EXTERNALCALL TO ORACLE
    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);

    function returnIntegratorIndex(address _addressAccount) external view returns(uint32 index_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IChamberOfCommerceDataTypes {

    // ChamberOfCommerce
    enum AccountType {
        NOT_SET,
        BORROWER,
        LENDER
    }

    enum AccountStatus {
        NONE,
        REGISTERED,
        WHITELISTED,
        BLACKLIST
    }

    struct ActorAccount {
        uint32 integratorIndex;
        AccountStatus status;
        AccountType accountType;
        address palletLocker;
        address relayerAddress;
        string nickName;
        string uriGeneral;
        string uriTerms;
    }

    struct CreditScore {
        uint256 minimumDeposit;
        uint24 fuelRequirement; // 100% = 1_000_000 = 1e6
    }
}

interface IEventImplementationDataTypes {

    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }
}


interface IBondCouncilDataTypes is IEventImplementationDataTypes {
    /**
     * @notice What happens to the collateral after a certain 'bond state' is a Policy. The Policy struct defines the consequence on the actions of the collateral
     * @param isPolicy bool that tracks 'if a policy exists'. Should always be set to True if a Policy is set
     * @param primaryBlocked if the NFTs can be sold on the primary market if the Policy is active. True means that the NFTs cannot be sold on the primary market.
     * Same principle of True/False relation to possible ticket-actions is the case for the other bools in this struct.
     */
    struct Policy {
        bool isPolicy;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    /**
     * @param verified bool indicating if the TB is verified by the DAO
     * @param eventAddress address of the Event (EventImplementation proxy) 
     * @param policyDuringLoan integer of the Policy that will be executed after the offering is ACCEPTED (so during the duration of the loan/bond)
     * @param policyAfterLiquidation integer of the Policy that will be executed if the offering is LIQUIDATED (so this is the consequence of not repaying the loan/bond)
     * @param flushstruct this is a copy of the EventFinancing struct in EventImplementation. 
     * @dev when a configuration is 'flushed' this means that the flushstruct is pushed to the EventImplementation contract. 
     */
    struct InventoryProcedure {
        bool verified;
        address eventAddress;
        uint256 policyDuringLoan;
        uint256 policyAfterLiquidation;
        EventFinancing flushstruct;
    }

    /**
     * @param INACTIVE TellerLoan does not exist, or is in PENDING state
     * @param DURING TellerLoan is ongoing - collatearization is active
     * @param LIQUIDATED TellerLoan is liquidated - collatearlization should be settled or has been settled
     * @param REPAID TellerLoan is repaid - collatearlization should be settled or has been settled
     */
    enum CollateralizationStage {
        INACTIVE,
        DURING,
        LIQUIDATED,
        REPAID
    }
}

interface IClearingHouseDataTypes {

    /**
     * Struct encoding the status of the collateral/loan/bid offering.
     * @param NONE offering isn't registered at all (doesn't exist)
     * @param READY the pallet is ready to be used as collateral
     * @param ACTIVE the pallet is being used as collateral
     * @param COMPLETED the pallet is returned to the bond issuer (the offering is completed, loan has been repaid)
     * @param DEFAULTED the pallet is sent to the lender because the loan/bond wasn't repaid. The offering isn't active anymore
     */
    enum OfferingStatus {
        NONE,
        READY,
        ACTIVE,
        COMPLETED,
        DEFAULTED
    }
}

interface IEconomicsDataTypes {
    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }
}

interface PalletRegistryDataTypes {

    enum PalletState {
        NON_EXISTANT,
        UN_REGISTERED, // 'pallet is unregistered to an event'
        REGISTERED, // 'pallet is registered to an event'
        VERIFIED, // pallet is now sealed
        DISCARDED // end state
    }

    struct PalletStruct {
        address depositTokenAddress;
        uint64 maxAmountInventory;
        uint64 averagePriceInventory;
        bool fuelAndCollateralCheck;
        address safeAddressIssuer;
        address palletLocker;
        uint256 depositedDepositTokens;
        PalletState palletState;
        address eventAddress;
    }
}

interface ITellerV2DataTypes {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }
    
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }
    
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId;
        bytes32 _metadataURI; // DEPRECIATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
    }
}

interface ITrancheBucketFactoryDataTypes {

    enum BucketType {
        NONE,
        BACKED,
        UN_BACKED
    }
}

interface ITrancheBucketDataTypes is IEconomicsDataTypes {

    /**
     * @param NONE config doesn't exist
     * @param CONFIGURABLE BUCKET IS CONFIGURABLE. it is possible to change the inv range and the kickback per NFT sold (so the bucket is still configuratable)
     * @param BUCKET_ACTIVE BUCKET IS ACTIVE. the bucket is active / in use (the loan/bond has been issued). The bucket CANNOT be configured anymore
     * @param AT_CHECKOUT BUCKET DEBT IS BEING CALCULATED AND PAID. The bond/loan has been repaid / the ticket sale is completed. In a sense the bucket backer is at the checkout of the process (the total bill is made up, and the payment request/process is being run). Look of it as it as the contract being at the checkout at the supermarket, items bought are scanned, creditbard(Economics contract) is charged.
     * @param REDEEMABLE the proceeds/kickback collected in the bucket can now be claimed from the bucket contract. 
     * @param INVALID_CANCELLED_VOID the bucket is invalid. this can have several reasons. The different reasons are listed below.
     * 
     * We have collapsed all these different reasons in a single state because the purpose of this struct is to tell the market what the shares are worth anything. If the bucket is in this state, the value of the shares are 0 (and they are unmovable).
     */

    // stored in: bucketState
    enum BucketConfiguration {
        NONE,
        CONFIGURABLE,
        BUCKET_ACTIVE,
        AT_CHECKOUT,
        REDEEMABLE,
        INVALID_CANCELLED_VOID
    }

    // stored in backing.verification
    enum BackingVerification {
        NONE,
        INVALIDATED,
        VERIFIED
    }

    // stored in tranche
    struct InventoryTranche {
        uint32 startIndexTranche;
        uint32 stopIndexTranche;
        uint32 averagePriceNFT;
        uint32 totalNFTInventory;
        uint32 usdKickbackPerNft; // 10000 = 1e4 = $1,00 = 1 dollar 
    }

    struct BackingStruct {
        bool relayerAttestation;
        BackingVerification verification;
        IntegratorData integratorData;
        uint32 integratorIndex;
        uint256 timestampBacking; // the moment the bucket was deployed and the backing was configured 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A standard for tokenized Vaults with a single underlying ERC-20 token.
interface IERC4626 is IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   `caller_` has exchanged `assets_` for `shares_` and transferred them to `owner_`.
     *         MUST be emitted when assets are deposited via the `deposit` or `mint` methods.
     *  @param caller_ The caller of the function that emitted the `Deposit` event.
     *  @param owner_  The owner of the shares.
     *  @param assets_ The amount of assets deposited.
     *  @param shares_ The amount of shares minted.
     */
    event Deposit(address indexed caller_, address indexed owner_, uint256 assets_, uint256 shares_);

    /**
     *  @dev   `caller_` has exchanged `shares_`, owned by `owner_`, for `assets_`, and transferred them to `receiver_`.
     *         MUST be emitted when assets are withdrawn via the `withdraw` or `redeem` methods.
     *  @param caller_   The caller of the function that emitted the `Withdraw` event.
     *  @param receiver_ The receiver of the assets.
     *  @param owner_    The owner of the shares.
     *  @param assets_   The amount of assets withdrawn.
     *  @param shares_   The amount of shares burned.
     */
    event Withdraw(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 assets_, uint256 shares_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     *  @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /********************************/
    /*** State Changing Functions ***/
    /********************************/

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of the assets cannot be deposited (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  assets_   The amount of assets to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The amount of shares minted.
     */
    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of shares cannot be minted (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  shares_   The amount of shares to mint.
     *  @param  receiver_ The receiver of the shares.
     *  @return assets_   The amount of assets deposited.
     */
    function mint(uint256 shares_, address receiver_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the shares cannot be redeemed (due to insufficient shares, withdrawal limits, slippage, etc).
     *  @param  shares_   The amount of shares to redeem.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the shares.
     *  @return assets_   The amount of assets sent to the receiver.
     */
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the assets cannot be withdrawn (due to insufficient assets, withdrawal limits, slippage, etc).
     *  @param  assets_   The amount of assets to withdraw.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the assets.
     *  @return shares_   The amount of shares burned from the owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    The amount of `assets_` the `shares_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to convert.
     *  @return assets_ The amount of equivalent assets.
     */
    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    The amount of `shares_` the `assets_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to convert.
     *  @return shares_ The amount of equivalent shares.
     */
    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be deposited on behalf of the `receiver_` through a `deposit` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the assets.
     *  @return assets_   The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver_) external view returns (uint256 assets_);

    /**
     *  @dev    Maximum amount of `shares_` that can be minted on behalf of the `receiver_` through a `mint` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The maximum amount of shares that can be minted.
     */
    function maxMint(address receiver_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `shares_` that can be redeemed from the `owner_` through a `redeem` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned shares otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the shares.
     *  @return shares_ The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be withdrawn from the `owner_` through a `withdraw` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned assets otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the assets.
     *  @return assets_ The maximum amount of assets that can be withdrawn.
     */
    function maxWithdraw(address owner_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of shares that would be minted in a `deposit` call in the same transaction.
     *          MUST NOT account for deposit limits like those returned from `maxDeposit` and should always act as though the deposit would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to withdraw.
     *  @return shares_ The amount of shares that would be redeemed.
     */
    function previewWithdraw(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Total amount of the underlying asset that is managed by the Vault.
     *          SHOULD include compounding that occurs from any yields.
     *          MUST NOT revert.
     *  @return totalAssets_ The total amount of assets the Vault manages.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IClearingHouseDataTypes, ITrancheBucketDataTypes, IBondCouncilDataTypes, ITellerV2DataTypes, ITrancheBucketFactoryDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerceEvents {


    event DefaultDepositSet(
        uint256 newDefaultDeposit
    );

    event CreditScoreEdit(
        address safeAddress,
        uint256 minimumDeposit,
        uint24 fuelRequirement
    );

    event EconomicsContractChange(
        address economicsContract
    );

    event DepositTokenChange(address newDepositToken);

    event AccountDeleted(
        address accountAddress
    );

    event RegisterySet(
        address palletRegistry
    );

    event ControllerSet(
        address addressController,
        bool setting
    );

    event ChamberPaused();

    event ChamberUnPaused();

    event AccountRegistered(
        address safeAddress,
        // uint256 actorIndex,
        string nickName
    );

    event AccountApproved(
        address safeAddress
    );

    event AccountWhitelisted(
        address safeAddress
    );

    event AccountBlacklisted(
        address safeAddress
    );

    event ContractsConfigured(
        address palletLockerFactory,
        address bondCouncil,
        address ticketSalesOracle,
        address economics,
        address palletRegistry,
        address clearingHouse,
        address tellerKeeper
    );

    event PalletLockerDeployed(
        address safeAddress,
        address palletLockerAddress
    );

    event StakeLockerDeployed(
        address safeAddress,
        address safeLockerAddress
    );
}

interface IClearingHouseEvents is IClearingHouseDataTypes {

    event BucketUpdate();

    event ManualCancel(uint256 palletIndex);

    event OfferingAccepted(
        uint256 palletIndex
    );

    event ContractConfigured(
        address palletRegistry,
        address tellerKeeper,
        address bondCouncil
    );

    event OfferingRegistered(
        uint256 palletIndex,
        uint256 bidId
    );

    event OfferingCancelled(
        uint256 palletIndex
    );

    event OfferingLiquidated(
        uint256 palletIndex,
        address lenderAddress
    );

    event PalletReclaimed(
        uint256 palletIndex
    );

    event OfferingStatusChange(
        uint256 palletIndex,
        OfferingStatus _status
    );

}

interface IPalletRegistryEvents {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );
    
    event BalanceCheck(
        uint256 palletIndex,
        bool rulingBalance
    );

    event DepositTokenChange(address newDepositToken);

    event PalletUnwindLiquidation(
        uint256 palletIndex,
        address liquidatorAddress
    );

    event PalletUnwindIssuer(
        uint256 palletIndex,
        uint256 depositAmount
    );

    event UnwindIssuer(
        uint256 palletIndex
    );

    event UnwindPallet(
        uint256 palletIndex,
        uint256 amountUnwound,
        address recipientDeposit,
        address lockerAddress
    );

    event PalletMinted(
        uint256 palletIndex,
        address safeAddress,
        uint256 tokensDeposited
    );

    event RegisterEventToPallet (
        uint256 palletIndex,
        address eventAddress
    );

    event DepositTokensAdded(
        uint256 palletIndex,
        uint256 extraDepositTokens
    );

    event PalletBurnedManual(
        uint256 palletIndex
    );

    event WithdrawPalletLocker(
        address depositTokenAddress,
        address toAddress,
        uint256 stakeDepositAmount
    );

    event PalletJudged(
        uint256 palletIndex,
        bool ruling
    );

    event PalletDepositClaimed(
        address claimAddress,
        uint256 palletIndex,
        uint256 depositedStateTokens
    );
}

interface ITrancheBucketEvents is ITrancheBucketDataTypes {

    event PaymentApproved();

    event ManualWithdraw(
        address withdrawTokenAddress,
        uint256 amountWithdrawn
    );

    event FunctionNotFullyExecuted();

    event BucketUpdate();

    event ManualCancel();

    event ClaimNotAllowed();

    event ModificationNotAllowed();

    event TrancheFinalized();

    event TrancheFullyRegistered(
        uint32 startIndex,
        uint32 stopIndex,
        uint32 averagePrice,
        uint32 totalInventory
    );

    event AllStaked(
        uint256 stakedAmount,
        uint256 sharesAmount
    );

    event BucketConfigured(
        uint32 integratorIndex
    );

    event RelayerAttestation(
        address attestationAddress
    );

    event BackingVerified(
        bool ruling
    );

    event TrancheShareMint(
        uint256 totalSupply
    );

    event BurnAll();

    event StateChange(
        BucketConfiguration _status
    );

    event InvalidState(
        BucketConfiguration currentState,
        BucketConfiguration requiredState
    );

    event DAOCancel();

    event StateAlreadyInSync();

    event SharesClaimed(
        address claimerAddress,
        uint256 amountClaimed
    );
    
    event UpdateDebt(
        uint256 currentDebt,
        uint256 timestamp
    );

    event BucketCheckedOut(
        uint256 finalDebt
    );

    event ReceivablesUpdated(
        uint256 balanceOf
    );

    event RedemptionUnlocked(
        uint256 balance,
        uint256 atPrice,
        uint256 totalReward
    );

    event Claim(
        uint256 shares,
        uint256 yield
    );

    event ClaimAmount();
}

interface ITellerKeeperEvents is ITellerV2DataTypes {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );

    error NoOfferingToUpdate(
        uint256 palletIndex,
        string message
    );

    event KeeperUpToDate();

    event NotEnoughFuel();

    event OfferingManualCancel(
        uint256 palletIndex
    );

    event OfferingRegistered(
        uint256 palletIndex
    );

    event TellerLiquidation(
        uint256 palletIndex
    );

    event ContractConfigured(
        address trancheBucketFactory,
        address clearingHouse
    );

    event KeeperReward(
        address rewardRecipient,
        uint256 amountRewarded
    );

    event TellerPaid(
        uint256 palletIndex
    );

    event RewardUpdated(
        uint256 newUpdateReward
    );

    event TellerCancelled(
        uint256 palletIndex
    );

    event TellerAccepted(
        uint256 palletIndex
    );

    event StateUpdateKeeper(
        uint256 bidId,
        uint256 palletIndex,
        BidState currentState
    );
}

interface ITrancheBucketFactoryEvents is ITrancheBucketDataTypes, ITrancheBucketFactoryDataTypes {

    event BucketInvalidated(
        uint256 palletIndex,
        address bucketAddress
    );

    event NewImplementationSet(address newImplementation);

    event BucketAlreadyActive();

    event TrancheBucketDeleted(
        uint256 palletIndex,
        address deletedBucket
    );

   event SetTrancheBucketStateManual(
        uint256 palletIndex,
        address bucketAddress
    );

    event TrancheLockerCreated(
        uint256 palletIndex,
        BucketType bucketType,
        address trancheAddress
    );

    event ContractConfigured(
        address clearingHouse
    );

    event RelayChangeToBucket(
        uint256 palletIndex,
        BucketConfiguration newState
    );
}

interface IBondCouncilEvents is IBondCouncilDataTypes {

    event FlushSwitchOff();

    event FlushSwitch(
        bool flushSwitch
    );

    event ImpossibleState();

    event CancelProcedure(
        uint256 palletIndex
    );

    event ManualFS (
        uint256 palletIndex,
        uint256 policyIndex
    );

    event EditProcedure(
        uint256 palletIndex
    );

    event VerifyProcedure(
        uint256 palletIndex
    );

    event PalletCancellation(
        uint256 palletIndex
    );

    event PalletCollateralization(
        uint256 palletIndex
    );

    event PolicyAdded(
        uint256 policyIndex,
        Policy newpolicy
    );

    event ManualFlush(
        uint256 palletIndex
    );

    event PalletRegistered(
        uint256 palletIndex
    );

    event Flush(
        uint256 palletIndex
    );

    event ContractsConfigured(
        address clearingHouse,
        address palletRegistry
    );

    event ChamberSet(
        address chamberOfCommerce
    );

    event Liquidation(
        uint256 palletIndex
    );

    event Repayment(
        uint256 palletIndex
    );
}

interface IStakeLockerFactoryEvents {

    event StakeLockerDeployed(
        address safeAddress
    );

    event TokensAdded(
        address stakeLocker,
        uint256 tokensAdded
    );

    event BalanceUpdated(
        address stakeLocker,
        uint256 newBalance
    );
    
    event UnstakeRequest(
        address safeAddress,
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestExecuted(
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestRejected(
        address lockerAddress,
        uint256 rejectedAmount
    );

    event EmergencyWithdrawAll(
        address lockerAddress,
        uint256 withdrawAmount
    );

    event LockerSlashed(
        address lockerAddress,
        uint256 slashAmount
    );
}


interface IStakeLockerEvents {

}

interface ITicketSaleOracleEvents {

    event EventCountUpdate(
        address eventAddress,
        uint32 nftsSold
    );

    event EventFinalized(
        address eventAddress
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes } from "./IDataTypes.sol";

interface ITellerKeeper is ITellerV2DataTypes {

    function setUpdateReward(
        uint256 _newUpdateReward
    ) external;

    function fuelForUpdates() external view returns(uint16 updates_);

    function updateByPalletIndex(
        uint256 _palletIndex,
        bool _isEFMContract
    ) external returns(bool update_);

    function bidStateTeller(uint256 _palletIndex) external view returns(BidState state_);

    function registerOffering(uint256 _palletIndex) external;

    function cancelOffering(uint256 _palletIndex) external;

    function isKeeperUpdateNeeded(
        uint256 _palletIndex
    ) external view returns(bool update_);

    function isBucketDeploymentAllowed(
        uint256 _palletIndex
    ) external view returns(bool allowed_);

    function getLoanLender(
        uint256 _bidIdTeller
    ) external view returns (address lender_);

    function getLoanBorrower(
        uint256 _bidIdTeller
    ) external view returns (address borrower_);

    function getStateBidId(
        uint256 _bidIdTeller
    ) external view returns (BidState state_);

    function canRegisterOffering(
        uint256 _bidIdTeller
    ) external view returns(bool canRegister_);

    function canCancelOffering(
        uint256 _palletIndex
    ) external view returns(bool allowed_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITrancheBucketDataTypes } from "./IDataTypes.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITrancheBucket is IERC20Upgradeable, ITrancheBucketDataTypes {
    function initializeBucket(
        string memory _name,
        string memory _symbol,
        uint32 _integratorIndex,
        uint256[2] memory _indexes,
        address[6] memory _addresses,
        bool _stakedYield,
        bool _bondBacked
    ) external;
    function setBucketState(BucketConfiguration _stateToSet, bool _toPause) external;
    function bucketState() external view returns(BucketConfiguration);
    function attestRelayer() external;
    function verifyBackingConfiguration(bool _verify) external;
    function registerPerformanceRangeTranche(
        uint32 _startIndexTranche,
        uint32 _stopIndexTranche,
        uint32 _averagePriceNFT,
        uint32 _totalNFTInventory
    ) external;
    function returnBackingStruct() external view returns(BackingStruct memory backing);
    function totalTicketsInTranche() external view returns(uint32 _range);
    function totalValue() external view returns(uint32 _value);
    function maxReturn(uint32 _usdPerInRange) external view returns(uint256 _max);
    function setKickbackPerNFTinTranche(uint32 _usdPerInRange) external;
    function claimTrancheShares() external;
    function updateDebt() external returns(uint256 debt_);
    function currentReturnPerShare() external view returns(uint256 _return);
    function checkOutBucket() external;
    function registerReceivables() external returns(uint256 balance_);
    function unlockRedemption(bool _checkBalance) external returns(uint256 balance_);
    function claimYieldAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITrancheBucketFactory {
    function tellerKeeper() external view returns(address keeper_);
    function tellerToAccepted(
        uint256 _palletIndex
    ) external;

    function tellerToCancelled(
        uint256 _palletIndex
    ) external;

    function tellerToLiquidated(
        uint256 _palletIndex
    ) external;

    function tellerToPaid(
        uint256 _palletIndex
    ) external;

    function buckets(uint256 _palletIndex) external view returns(address bucket_);

    function doesBucketExist(uint256 _palletIndex) external returns(bool exists_);

    function doesExistAndIsBacked(uint256 _palletIndex) external view returns(bool backed_);

    function processBucketInvalidaton(
        uint256 _palletIndex
    ) external;
}