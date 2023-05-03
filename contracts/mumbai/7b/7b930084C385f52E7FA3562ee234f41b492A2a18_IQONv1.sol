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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.10;

/// @dev Importing Openzeppelin stuffs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Extending IERC20 with adding decimals function
interface ExIERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

/// @title The IQON Units v1 ERC20 Token.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
/// @dev importing custom stuffs.
import "./interfaces/ExIERC20.sol";

/// @dev Importing @openzeppelin stuffs.
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @dev Struct that defines the stake details
struct InvestmentDetails {
    /// @param investor: The investor address.
    address investor;
    /// @param amount: The staked amount of the investment.
    uint256 amount;
    /// @param timestamp: The staked timestamp.
    uint256 timestamp;
    /// @param rewardTill: The timestamp till investor can get reward.
    uint256 rewardTill;
    /// @param lastRewardedTime: The last distributed timestamp.
    uint256 lastRewardedTime;
}

/// @dev Struct that defines the reward parameters that are required in the contract
struct RewardInfo {
    /// @dev reward Percentage
    uint256 rewardPercentOnEachStake;
    /// @dev Denominator
    uint256 denominator;
}

contract IQONv1 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev USDT address.
    address public USDT;

    // @dev Verification fee.
    uint256 public verificationFee;

    /// @dev reward Info
    RewardInfo public rewardInfo;

    /**
     * @notice Verified Address
     */
    /// @dev Mapping for verified addresses.
    mapping(address => bool) public isVerifiedAddress;

    /**
     * @notice Stake
     */
    /// @dev Tracking the All active investors for giving reward.
    InvestmentDetails[] public allStakes;

    /// @dev Mapping for tracking how much amount an investor staked.
    /// investorAddress => TotalInvestedAmount.
    mapping(address => uint256) public totalStakedBy;

    /// @dev Mapping for tracking the number to stake done by an investor.
    mapping(address => uint256) public noOfStakesDoneBy;

    /// @dev Mapping for tracking the a particular investment details as per investor & noOfStakes.
    mapping(address => mapping(uint256 => InvestmentDetails))
        public investmentDetailsByInvestorAndId;

    /// @dev Mapping to keep track of token to price
    mapping(address => uint256) public tokenToPrice;

    /// @dev Mapping to keep track of token to isAlreadyMappedOrNot
    mapping(address => bool) public isTokenAlreadyInList;

    /**
     * @notice Distribute Rewards.
     */
    /// @dev Holds the total number of reward distributed till now.
    uint256 public totalRewardDistributed;

    /// @dev Holds the last reward distributed timestamp.
    uint256 public lastRewardDistributedOn;

    /// @dev to Keep track of last stake that completes the timestamp
    uint256 private lastCompletedStake;

    /// @dev To keep the track of the last processed batch
    uint256 private lastProcessedBatchTill;

    /// @dev Events.
    /**
     * `AddressVerifiedUpdated` will be fired when an address get verified or revoked.
     * @param account: The account get verified or get revoked.
     * @param verified: The status of the address if verified or revoked.
     */
    event AddressVerifiedUpdated(address account, bool verified);

    /**
     * @dev `Staked` will be fired when an investor staked into StakePool.
     * @param paymentTokenAddress: The address of the token.
     * @param dollarsAmount: The amount investor staked into this contract.
     * @param usdtAmount: The amount of USDT deposited into contract.
     * @param tokenAmount: The payment token amount deposited into contract.
     */
    event Staked(
        address paymentTokenAddress,
        uint256 dollarsAmount,
        uint256 usdtAmount,
        uint256 tokenAmount
    );

    /**
     * @dev `RewardDistributed` will be fired when an investor get reward.
     * @param amount: The amount investor get as a reward
     */
    event RewardDistributed(uint256 amount);

    /**
     * @dev `TokenAdded` will be fired when Token is added in the staking tokens list.
     * @param _tokenAddress : The Address of the Token
     * @param _price : The USD Value of the token
     */
    event TokenAdded(address _tokenAddress, uint256 _price);

    /**
     * @dev `PriceUpdated` will be fired when price of the token is updated.
     * @param _tokenAddress : The Address of the Token
     * @param _newPrice : The new USD Value of the token
     */
    event PriceUpdated(address _tokenAddress, uint256 _newPrice);

    /**
     * @dev `PriceUpdated` will be fired when token is removed.
     * @param _tokenAddress : The Address of the Token
     */
    event TokensRemoved(address _tokenAddress);

    /**
     * @dev `rewardPercentUpdated` will be fired when reward percent is updated.
     * @param _rewardPercent : The reward percent
     * @param _denominator : The denominator
     */
    event rewardPercentUpdated(uint256 _rewardPercent, uint256 _denominator);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializing the ERC20 contract and minting the `_totalSupply` of tokens.
     * Also Granting roles to caller.
     */
    function initialize() public onlyInitializing {
        __ERC20_init("IQON UNITS", "IQON");
        __Ownable_init();
        __ReentrancyGuard_init();

        /// @dev Adding deployer address as a verified address.
        _setVerifiedAddress(msg.sender, true);

        /// @dev Initializing USDT address.
        /// TESTNET ADDRESS
        USDT = 0x93414869D5E29FfEd0d5E85969615590C1092637;
        /// Mainnet
        // USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        tokenToPrice[USDT] = 1e18; //USDT = $1

        /// @dev Set IQON Price.
        isTokenAlreadyInList[address(this)] = true;
        tokenToPrice[address(this)] = 1e18; // IQON = $1

        /// @dev Initializing reward info 0.27%.
        rewardInfo.rewardPercentOnEachStake = 27;
        rewardInfo.denominator = 100_00;
    }

    /**
     * (PUBLIC)
     * @dev Returns the current version of the contract.
     * @return string: The version in string.
     */
    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * (PUBLIC)
     * @dev Overriding the `decimals` function to get user defined decimals.
     * @return uint8: Decimals value.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * (PUBLIC)
     * @dev Minting tokens to an address.
     * Required: OnlyOwner.
     * @param account: The address to which you want to mint tokens.
     * @param amount: The amount of tokens you want to mint.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        /// @dev Adding account into verified account.
        if (!isVerifiedAddress[account]) _setVerifiedAddress(account, true);
        /// @dev Minting amount to account.
        _mint(account, amount);
    }

    /**
     * (PUBLIC)
     * @dev Burning tokens from an address.
     * Required: OnlyOwner
     * @param account: The address from which you want to burn tokens.
     * @param amount: The amount of tokens you want to burn.
     */
    function burn(address account, uint256 amount) external onlyOwner {
        /// @dev Burning amount from account.
        _burn(account, amount);
    }

    /**
     * (PUBLIC)
     * @dev Staking USDT and Token into StakePool(this) contract.
     * Required: _amount should be multiple of 100.
     * @param _amount: The amount investor wants to stake.
     * @param _tokenAddress: The address of the token that is staked with USDT
     */
    function stake(
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant returns (bool stakeSuccessful) {
        /// @dev Only verified users can stake.
        require(isVerifiedAddress[msg.sender], "OnlyVerifiedAddressCanStake");

        /// @dev Parameter validation.
        _validateAmountIsMultipleOf100(_amount);
        uint256 amountOfUSDT;
        uint256 amountOfTokens;
        /// @dev if token address is USDT address.

        if (_tokenAddress == USDT) {
            /// @dev Then transfer full amount in USDT.
            amountOfUSDT = _amount * 1e6;

            /// @dev Transferring USDT token into contract.
            bool success = IERC20(USDT).transferFrom(
                msg.sender,
                address(this),
                amountOfUSDT
            );
            require(success, "FailedToTransfer");
        }
        /// @dev Else normally run
        else {
            /// @dev If given token address is not into list then revert.
            require(
                isTokenAlreadyInList[_tokenAddress],
                "TokenIsNotInTheStakingTokenList"
            );

            /// @dev Getting the amount of USDT and Tokens to stake
            (amountOfUSDT, amountOfTokens) = _getAmountOfBothStakingTokens(
                _tokenAddress,
                _amount
            );

            /// @dev Transferring both tokens into this contract.
            if (amountOfUSDT > 0 && amountOfTokens > 0) {
                /// @dev Transferring USDT token into contract.
                bool success = IERC20(USDT).transferFrom(
                    msg.sender,
                    address(this),
                    amountOfUSDT
                );
                require(success, "FailedToTransfer");

                /// @dev Transferring TOKEN token into contract.
                success = IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    amountOfTokens
                );
                require(success, "FailedToTransfer");
            }
        }

        /// @dev Getting the current stake id as per investor.
        address _investor = msg.sender;
        uint256 _investorCurrentStakeCount = noOfStakesDoneBy[_investor];

        /// @dev Initializing the InvestmentDetails struct as per _investmentId.
        InvestmentDetails
            storage _currentStakeDetails = investmentDetailsByInvestorAndId[
                _investor
            ][_investorCurrentStakeCount];

        _currentStakeDetails.investor = _investor;
        _currentStakeDetails.amount = _amount;
        _currentStakeDetails.timestamp = block.timestamp;
        _currentStakeDetails.rewardTill = block.timestamp + 780 days;

        /// @dev Additional updating.
        ++noOfStakesDoneBy[_investor];
        totalStakedBy[_investor] += _amount;

        /// @dev Inserting investment details into `allStakes`.
        allStakes.push(_currentStakeDetails);

        /// @dev Emitting event.
        emit Staked(_tokenAddress, _amount, amountOfUSDT, amountOfTokens);

        /// @dev Return stake successful.
        stakeSuccessful = true;
    }

    /**
     * (PUBLIC)
     * @dev Distribute reward IQON(this) token as per reward rate.
     * Required: OnlyOwner.
     * @param batchSize: The batch size for loop.
     */
    function distribute(uint256 batchSize) external onlyOwner nonReentrant {
        /// @dev 7 Days checking.
        require(
            block.timestamp >= (lastRewardDistributedOn + 7 days),
            "YouHaveToWaitTillSevenDaysToDistributeRewardsAgain"
        );

        /// @dev Getting the current length of stake array
        uint256 totalActiveStakes = allStakes.length;
        /// @dev Caching the reward info to save gas.
        RewardInfo memory _rewardInfo = rewardInfo;

        /// @dev Checking if the array is empty or distributed reward to all the staking.
        require(
            totalActiveStakes > 0 && lastCompletedStake < totalActiveStakes,
            "NoActiveStakeToReward"
        );

        /// @dev Tracking the previous distributed amount.
        uint256 prevRewardDistributedAmount = totalRewardDistributed;

        /// @dev To get the no of days to reward
        uint256 noOfDays;

        /// @dev Getting the main starting index.
        uint256 index = (lastProcessedBatchTill == totalActiveStakes)
            ? lastCompletedStake
            : lastProcessedBatchTill;

        /// @dev Loop through all the left staking
        for (
            index;
            index < (lastProcessedBatchTill + batchSize) &&
                (index < totalActiveStakes);
            index++
        ) {
            /// @dev getting the stake at this index
            InvestmentDetails storage _currentInvestmentDetails = allStakes[
                index
            ];

            /// @dev If current time is less than 780 days from the stake.
            if (block.timestamp < _currentInvestmentDetails.rewardTill) {
                /// @dev If stake is getting reward for first time.
                if (_currentInvestmentDetails.lastRewardedTime == 0) {
                    /// If Stake day and reward is not same.
                    if (
                        (block.timestamp -
                            _currentInvestmentDetails.timestamp) >= 1 days
                    ) {
                        /// @dev Then no of days will be current time - stake time
                        noOfDays =
                            (block.timestamp -
                                1 days -
                                _currentInvestmentDetails.timestamp) /
                            1 days;
                    }
                    /// else Stake day and reward is same.
                    else {
                        /// @dev Then no of days will be 0
                        noOfDays = 0;
                    }
                }
                /// @dev Else stake will get reward for 6 days.
                else {
                    /// @dev Then no of days will be 6
                    noOfDays = 6;
                }
            }
            /// @dev If current time is greater than or equal to 780 days from the stake.
            else {
                /// @dev If current time is equal to stake time.
                if (block.timestamp == _currentInvestmentDetails.rewardTill) {
                    /// Then no of days will be normally 6.
                    noOfDays =
                        (block.timestamp -
                            1 days -
                            _currentInvestmentDetails.lastRewardedTime) /
                        1 days;
                }
                /// @dev If current time is greater to stake time also last rewarded time not crossed reward till.
                else if (
                    block.timestamp > _currentInvestmentDetails.rewardTill &&
                    _currentInvestmentDetails.lastRewardedTime <
                    _currentInvestmentDetails.rewardTill
                ) {
                    /// @dev Then no of days will be remaining days.
                    noOfDays =
                        (_currentInvestmentDetails.rewardTill -
                            _currentInvestmentDetails.lastRewardedTime) /
                        1 days;
                }

                /// After completing the 780 days updating the completed stake.
                lastCompletedStake = index + 1;
            }

            /// @dev Calculating the amount of reward to pay based on noOfDays and reward Percentage
            uint256 rewardsToPay = ((_currentInvestmentDetails.amount *
                _rewardInfo.rewardPercentOnEachStake *
                noOfDays) * (10 ** decimals())) / _rewardInfo.denominator;

            /// @dev Directly minting the reward amount to investor address.
            if (rewardsToPay > 0) {
                /// @dev Adding account into verified account.
                if (!isVerifiedAddress[_currentInvestmentDetails.investor])
                    _setVerifiedAddress(
                        _currentInvestmentDetails.investor,
                        true
                    );
                _mint(_currentInvestmentDetails.investor, rewardsToPay);
            }

            /// @dev Updating the last rewarded time to current time.
            _currentInvestmentDetails.lastRewardedTime = block.timestamp;
            /// @dev Updating the total amount of reward distributed.
            totalRewardDistributed += rewardsToPay;
        }

        /// @dev Updating the last processed batch.
        lastProcessedBatchTill = (index == totalActiveStakes)
            ? lastCompletedStake
            : index;

        /// @dev If index reached to last stake.
        if (index == totalActiveStakes) {
            /// @dev Then update the timestamp to block the distribute for 7 days.
            lastRewardDistributedOn = block.timestamp;
        }

        /// @dev emitting event.
        emit RewardDistributed(
            totalRewardDistributed - prevRewardDistributedAmount
        );
    }

    /**
     * (PUBLIC)
     * @dev Updating the verification fee.
     * Required: OnlyOwner.
     * @param _feeInUSDT: The verification fee in 6 decimals or in USDT.
     */
    function setVerificationFee(uint256 _feeInUSDT) external onlyOwner {
        /// Adding into verified list.
        verificationFee = _feeInUSDT;
    }

    /**
     * (PUBLIC)
     * @dev Adding address into verified list.
     * Required: USDT approval.
     */
    function verifyAddress() external nonReentrant {
        /// @dev Paying fee at the time of verification.
        /// @dev Transferring USDT token into contract.
        bool success = IERC20(USDT).transferFrom(
            msg.sender,
            address(this),
            verificationFee
        );
        require(success, "FailedToTransfer");
        /// Adding into verified list.
        _setVerifiedAddress(msg.sender, true);
    }

    /**
     * (PUBLIC)
     * @dev Adding or removing address from verified list.
     * Required: OnlyOwner.
     * @param _address: The address you want to add or remove in verified list.
     * @param _isVerified: The current status of the address.
     */
    function setVerifiedAddress(
        address _address,
        bool _isVerified
    ) external onlyOwner {
        /// Adding into verified list.
        _setVerifiedAddress(_address, _isVerified);
    }

    /**
     * (PUBLIC)
     * @dev Adding or removing address from verified list.
     * Required: OnlyOwner.
     * @param _address:(ARRAY) The addresses you want to add or remove in verified list.
     * @param _isVerified:(ARRAY) The current status of the addresses.
     */
    function setVerifiedAddresses(
        address[] calldata _address,
        bool[] calldata _isVerified
    ) external onlyOwner {
        /// @dev Length checking
        require(_address.length == _isVerified.length, "LengthShouldBeSame");

        /// Adding into verified list.
        for (uint256 i; i < _address.length; i++) {
            _setVerifiedAddress(_address[i], _isVerified[i]);
        }
    }

    /**
     * (PUBLIC)
     * @dev Function to Update the reward percentage
     * Required: OnlyOwner.
     * @param _newRewardPercent: The new reward percentage
     * @param _denominator: The Denominator -> 0.27 -> 10000  : 1.52 -> 10000 : 0.123 -> 100000
     */
    function updateRewardPercentage(
        uint256 _newRewardPercent,
        uint256 _denominator
    ) external onlyOwner nonReentrant {
        /// @dev Parameter validations.
        require(_newRewardPercent != 0, "RewardPercentCannotBeZero");
        require(_denominator % 100 == 0, "DenominatorShouldBeMultipleOf100");

        /// @dev Checking if new values are same as before.
        require(
            _newRewardPercent != rewardInfo.rewardPercentOnEachStake &&
                _denominator != rewardInfo.denominator,
            "SameRewardPercentAsPrevious"
        );

        /// @dev Updating the new percentage.
        rewardInfo.rewardPercentOnEachStake = _newRewardPercent;
        rewardInfo.denominator = _denominator;

        /// @dev Emitting event.
        emit rewardPercentUpdated(_newRewardPercent, _denominator);
    }

    /**
     * (PUBLIC)
     * @dev Function to add new token to the staking token list
     * Required: onlyOwner.
     * @param _tokenAddress: The address of the token
     * @param _usdPrice : The USD price of the token
     */
    function addToken(
        address _tokenAddress,
        uint256 _usdPrice
    ) public onlyOwner nonReentrant {
        /// @dev Parameter validations
        _validateTokenZeroAddress(_tokenAddress);

        /// @dev Checking if address already into token list.
        require(!isTokenAlreadyInList[_tokenAddress], "TokenAlreadyInTheList");
        require(_usdPrice != 0, "AmountCannotBeZero");

        /// @dev Updating the price & add into token list.
        tokenToPrice[_tokenAddress] = _usdPrice;
        isTokenAlreadyInList[_tokenAddress] = true;

        /// @dev Emitting the event.
        emit TokenAdded(_tokenAddress, _usdPrice);
    }

    /**
     * (PUBLIC)
     * @dev Function to remove a token from a list
     * Required: onlyOwner.
     * @param _tokenAddress: The address of the token
     */
    function removeToken(
        address _tokenAddress
    ) external onlyOwner nonReentrant {
        /// @dev Checking if the token address already into list.
        require(isTokenAlreadyInList[_tokenAddress], "TokenIsNotInTheList");

        /// @dev Deleting the token from list & price.
        delete isTokenAlreadyInList[_tokenAddress];
        delete tokenToPrice[_tokenAddress];

        /// @dev Emitting the event.
        emit TokensRemoved(_tokenAddress);
    }

    /**
     * (PUBLIC)_amount
     * @dev Function to update the usd price of the token
     * Required: onlyOwner.
     * @param _tokenAddress: The address of the token
     * @param _newPrice : The new USD price of the token
     */
    function setPrice(
        address _tokenAddress,
        uint256 _newPrice
    ) external onlyOwner nonReentrant {
        /// @dev Checking if the if is in the list and price should not be zero.
        require(_newPrice != 0, "AmountCannotBeZero");
        require(isTokenAlreadyInList[_tokenAddress], "TokenIsNotInTheList");

        /// @dev checking if the token price is same as before.
        require(
            tokenToPrice[_tokenAddress] != _newPrice,
            "AmountIsSameAsPrevious"
        );

        /// @dev Updating the token price.
        tokenToPrice[_tokenAddress] = _newPrice;

        /// @dev Emitting the event.
        emit PriceUpdated(_tokenAddress, _newPrice);
    }

    /**
     * (PUBLIC)
     * @dev Withdraw ERC20 tokens (STAKED) from this contract.
     * Required: OnlyOwner
     * @param _tokenAddress: The token address you want to withdraw.
     * @param _amount: The amount of token.
     */
    function transferAnyERC20(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        /// @dev Parameter validations
        _validateTokenZeroAddress(_tokenAddress);
        require(_amount != 0, "AmountCannotBeZero");

        /// @dev Transferring token.
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "IQON: Not enough balance"
        );
        bool success = IERC20(_tokenAddress).transfer(msg.sender, _amount);
        require(success, "FailedToTransfer");
    }

    /**
     * (INTERNAL)
     * @dev Overriding the beforeTokenTransfer to check transfer happening between verified addresses.
     * @param from: The sender account address.
     * @param to : The receiver account address.
     * @param amount: The amount of tokens wants to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        /// @dev Parameter checking.
        require(amount != 0, "AmountShouldNotBeZero");

        /// @dev Checking if receiver address is a verified address.
        require(
            to != address(0) && isVerifiedAddress[to],
            "CannotTransferToUnverifiedAddress"
        );

        /// @dev If address verified then continue transfer.
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * (PRIVATE)
     * @dev Checking if the given address is zero address.
     * @param _tokenAddress: The address you want to check.
     */
    function _validateTokenZeroAddress(address _tokenAddress) private pure {
        /// @dev Parameter checking.
        require(_tokenAddress != address(0), "TokenAddressCannotBeZero");
    }

    /**
     * (PRIVATE)
     * @dev Adding or removing address from verified list.
     * @param _address: The address you want to add or remove in verified list.
     * @param _isVerified: The current status of the address.
     */
    function _setVerifiedAddress(address _address, bool _isVerified) private {
        /// @dev Parameters check.
        require(_address != address(0), "AddressShouldNotBeZero");
        require(
            isVerifiedAddress[_address] != _isVerified,
            "AddressAlreadySetToValue"
        );

        /// @dev Updating verified mapping.
        isVerifiedAddress[_address] = _isVerified;

        /// @dev Emitting events.
        emit AddressVerifiedUpdated(_address, _isVerified);
    }

    /**
     * (PRIVATE)
     * @dev validating the stake amount i.e. investor wants to stake.
     * Required: _amount should not be zero & multiple of 100.
     * @param _amount: The amount investor wants to stake.
     */
    function _validateAmountIsMultipleOf100(uint256 _amount) private pure {
        /// @dev Parameter checking.
        require(_amount != 0, "InvestmentAmountShouldNotBeZero");
        /// @dev Amount checking ig it is a multiple of 100 VYNC or not.
        require((_amount % 100) == 0, "InvestmentAmountShouldBeMultipleOf100");
    }

    /**
     * (PRIVATE)
     * @dev Returns the no of USDT & Token needed for staking.
     * @param _tokenInstance: The token address which user wants to pay with USDT.
     * @param _amount: The amount user wants to stake (Multiple of 100)
     * @return USDTAmount The USDT amount (IN 6 decimals).
     * @return TOKENAmount The Token amount (IN Token Decimals).
     */
    function _getAmountOfBothStakingTokens(
        address _tokenInstance,
        uint256 _amount
    ) private view returns (uint256 USDTAmount, uint256 TOKENAmount) {
        /// @dev Getting the token decimals.
        uint256 _tokenDecimals = ExIERC20(_tokenInstance).decimals();

        /// @dev Getting the price USDT: $1 and TOKEN: $?
        uint256 USDTprice = 1e18; // $1
        uint256 TokensPrice = tokenToPrice[address(_tokenInstance)];

        /// @dev If user is staking for the first time.
        if (noOfStakesDoneBy[msg.sender] == 0) {
            /// @dev Then USDT amount will be 85% (in dollars)
            /// And Token amount will be 15% (in dollars)
            uint256 _85PercentAmount = (_amount * 85) / 100;
            uint256 _15PercentAmount = (_amount * 15) / 100;

            /// @dev getting the both USDT & TOKEN amount as per price.
            USDTAmount = (USDTprice * _85PercentAmount) / 1e12;
            TOKENAmount = ((_15PercentAmount * 1e18 * (10 ** _tokenDecimals)) /
                TokensPrice);
        }
        /// @dev Else.
        else {
            /// @dev Then USDT amount will be 75% (in dollars)
            /// And Token amount will be 25% (in dollars)
            uint256 _75PercentAmount = (_amount * 75) / 100;
            uint256 _25PercentAmount = (_amount * 25) / 100;

            /// @dev getting the both USDT & TOKEN amount as per price.
            USDTAmount = (USDTprice * _75PercentAmount) / 1e12;
            TOKENAmount = ((_25PercentAmount * 1e18 * (10 ** _tokenDecimals)) /
                TokensPrice);
        }
    }
}