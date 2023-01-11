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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LibPoolConfigV1 } from "../libraries/LibPoolConfigV1.sol";
import { PoolOracle } from "../../PoolOracle.sol";
import { PLP } from "../../../tokens/PLP.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

interface GetterFacetInterface {
  function additionalAum() external view returns (uint256);

  function approvedPlugins(
    address user,
    address plugin
  ) external view returns (bool);

  function discountedAum() external view returns (uint256);

  function feeReserveOf(address token) external view returns (uint256);

  function fundingInterval() external view returns (uint64);

  function borrowingRateFactor() external view returns (uint64);

  function getStrategyDeltaOf(
    address token
  ) external view returns (bool, uint256);

  function guaranteedUsdOf(address token) external view returns (uint256);

  function isAllowAllLiquidators() external view returns (bool);

  function isAllowedLiquidators(
    address liquidator
  ) external view returns (bool);

  function isDynamicFeeEnable() external view returns (bool);

  function isLeverageEnable() external view returns (bool);

  function isSwapEnable() external view returns (bool);

  function lastFundingTimeOf(address token) external view returns (uint256);

  function liquidationFeeUsd() external view returns (uint256);

  function liquidityOf(address token) external view returns (uint256);

  function maxLeverage() external view returns (uint64);

  function minProfitDuration() external view returns (uint64);

  function mintBurnFeeBps() external view returns (uint64);

  function oracle() external view returns (PoolOracle);

  function pendingStrategyOf(
    address token
  ) external view returns (StrategyInterface);

  function plp() external view returns (PLP);

  function positionFeeBps() external view returns (uint64);

  function reservedOf(address token) external view returns (uint256);

  function router() external view returns (address);

  function shortSizeOf(address token) external view returns (uint256);

  function shortAveragePriceOf(address token) external view returns (uint256);

  function stableBorrowingRateFactor() external view returns (uint64);

  function stableTaxBps() external view returns (uint64);

  function stableSwapFeeBps() external view returns (uint64);

  function sumBorrowingRateOf(address token) external view returns (uint256);

  function strategyOf(address token) external view returns (StrategyInterface);

  function strategyDataOf(
    address token
  ) external view returns (LibPoolConfigV1.StrategyData memory);

  function swapFeeBps() external view returns (uint64);

  function taxBps() external view returns (uint64);

  function totalOf(address token) external view returns (uint256);

  function tokenMetas(
    address token
  ) external view returns (LibPoolConfigV1.TokenConfig memory);

  function totalTokenWeight() external view returns (uint256);

  function totalUsdDebt() external view returns (uint256);

  function usdDebtOf(address token) external view returns (uint256);

  function getDelta(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime,
    int256 entryFundingRate,
    int256 fundingFeeDebt
  ) external view returns (bool, uint256, int256);

  function getEntryBorrowingRate(
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256);

  function getEntryFundingRate(
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (int256);

  function getBorrowingFee(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    uint256 size,
    uint256 entryBorrowingRate
  ) external view returns (uint256);

  function getFundingFee(
    address indexToken,
    bool isLong,
    uint256 size,
    int256 entryFundingRate
  ) external view returns (int256);

  function getNextShortAveragePrice(
    address indexToken,
    uint256 nextPrice,
    uint256 sizeDelta
  ) external view returns (uint256);

  function getNextShortAveragePriceWithRealizedPnl(
    address indexToken,
    uint256 nextPrice,
    int256 sizeDelta,
    int256 realizedPnl
  ) external view returns (uint256);

  struct GetPositionReturnVars {
    address primaryAccount;
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryBorrowingRate;
    int256 entryFundingRate;
    uint256 reserveAmount;
    uint256 realizedPnl;
    bool hasProfit;
    uint256 lastIncreasedTime;
    int256 fundingFeeDebt;
  }

  function getPoolShortDelta(
    address token
  ) external view returns (bool, uint256);

  function getPosition(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory);

  function getPositionWithSubAccountId(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory);

  function getPositionDelta(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (bool, uint256, int256);

  function getPositionFee(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    uint256 sizeDelta
  ) external view returns (uint256);

  function getPositionLeverage(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256);

  function getPositionNextAveragePrice(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 nextPrice,
    uint256 sizeDelta,
    uint256 lastIncreasedTime
  ) external view returns (uint256);

  function getRedemptionCollateral(
    address token
  ) external view returns (uint256);

  function getRedemptionCollateralUsd(
    address token
  ) external view returns (uint256);

  function getSubAccount(
    address primaryAccount,
    uint256 subAccountId
  ) external pure returns (address);

  function getTargetValue(address token) external view returns (uint256);

  function getAddLiquidityFeeBps(
    address token,
    uint256 value
  ) external view returns (uint256);

  function getAum(bool isUseMaxPrice) external view returns (uint256);

  function getAumE18(bool isUseMaxPrice) external view returns (uint256);

  function getRemoveLiquidityFeeBps(
    address token,
    uint256 value
  ) external view returns (uint256);

  function getSwapFeeBps(
    address tokenIn,
    address tokenOut,
    uint256 usdDebt
  ) external view returns (uint256);

  function getNextBorrowingRate(address token) external view returns (uint256);

  function getNextFundingRate(
    address token
  ) external view returns (int256, int256);

  function openInterestLong(address token) external view returns (uint256);

  function openInterestShort(address token) external view returns (uint256);

  function getFundingFeeAccounting() external view returns (uint256, uint256);

  function convertTokensToUsde30(
    address token,
    uint256 amountTokens,
    bool isUseMaxPrice
  ) external view returns (uint256);

  function convertUsde30ToTokens(
    address token,
    uint256 amountUsd,
    bool isUseMaxPrice
  ) external view returns (uint256);

  function accumFundingRateLong(
    address indexToken
  ) external view returns (int256);

  function accumFundingRateShort(
    address indexToken
  ) external view returns (int256);

  function fundingRateFactor() external view returns (uint64);

  function getDeltaWithoutFundingFee(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime
  ) external view returns (bool, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { FlashLoanBorrowerInterface } from "../../../interfaces/FlashLoanBorrowerInterface.sol";

interface LiquidityFacetInterface {
  function addLiquidity(
    address account,
    address token,
    address receiver
  ) external returns (uint256);

  function removeLiquidity(
    address account,
    address tokenOut,
    address receiver
  ) external returns (uint256);

  function swap(
    address account,
    address tokenIn,
    address tokenOut,
    uint256 minAmountOut,
    address receiver
  ) external returns (uint256);

  function flashLoan(
    FlashLoanBorrowerInterface borrower,
    address[] calldata receivers,
    address[] calldata tokens,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface PerpTradeFacetInterface {
  enum LiquidationState {
    HEALTHY,
    SOFT_LIQUIDATE,
    LIQUIDATE
  }

  function checkLiquidation(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong,
    bool isRevertOnError
  ) external view returns (LiquidationState, uint256, uint256, int256);

  function increasePosition(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    bool isLong
  ) external;

  function decreasePosition(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver
  ) external returns (uint256);

  function liquidate(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong,
    address to
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LinkedList } from "../../../libraries/LinkedList.sol";
import { StrategyInterface } from "../../../interfaces/StrategyInterface.sol";

library LibPoolConfigV1 {
  using LinkedList for LinkedList.List;

  // -------------
  //    Constants
  // -------------
  // keccak256("com.perp88.poolconfigv1.diamond.storage")
  bytes32 internal constant POOL_CONFIG_V1_STORAGE_POSITION =
    0x98a7856657bef7cc5eba088ed024ebd08d8fb7eed7a3fcb52b2c50657b3073e6;

  // -------------
  //    Storage
  // -------------
  struct TokenConfig {
    bool accept;
    bool isStable;
    bool isShortable;
    uint8 decimals;
    uint64 weight;
    uint64 minProfitBps;
    uint256 usdDebtCeiling;
    uint256 shortCeiling;
    uint256 bufferLiquidity;
    uint256 openInterestLongCeiling;
  }

  struct StrategyData {
    uint64 startTimestamp;
    uint64 targetBps;
    uint128 principle;
  }

  struct PoolConfigV1DiamondStorage {
    // --------
    // Treasury
    // --------
    address treasury;
    // --------------------
    // Token Configurations
    // --------------------
    LinkedList.List allowTokens;
    mapping(address => TokenConfig) tokenMetas;
    uint256 totalTokenWeight;
    // --------------------------
    // Liquidation configurations
    // --------------------------
    /// @notice liquidation fee in USD with 1e30 precision
    uint256 liquidationFeeUsd;
    bool isAllowAllLiquidators;
    mapping(address => bool) allowLiquidators;
    // -----------------------
    // Leverage configurations
    // -----------------------
    uint64 maxLeverage;
    // ---------------------------
    // Funding rate configurations
    // ---------------------------
    uint64 fundingInterval;
    uint64 stableBorrowingRateFactor;
    uint64 borrowingRateFactor;
    uint64 fundingRateFactor;
    // ----------------------
    // Fee bps configurations
    // ----------------------
    uint64 mintBurnFeeBps;
    uint64 taxBps;
    uint64 stableTaxBps;
    uint64 swapFeeBps;
    uint64 stableSwapFeeBps;
    uint64 positionFeeBps;
    uint64 flashLoanFeeBps;
    // -----
    // Misc.
    // -----
    uint64 minProfitDuration;
    bool isDynamicFeeEnable;
    bool isSwapEnable;
    bool isLeverageEnable;
    address router;
    // --------
    // Strategy
    // --------
    mapping(address => StrategyInterface) strategyOf;
    mapping(address => StrategyInterface) pendingStrategyOf;
    mapping(address => StrategyData) strategyDataOf;
  }

  function poolConfigV1DiamondStorage()
    internal
    pure
    returns (PoolConfigV1DiamondStorage storage poolConfigV1Ds)
  {
    assembly {
      poolConfigV1Ds.slot := POOL_CONFIG_V1_STORAGE_POSITION
    }
  }

  function fundingInterval() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().fundingInterval;
  }

  function flashLoanFeeBps() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().flashLoanFeeBps;
  }

  function getAllowTokensLength() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().allowTokens.size;
  }

  function getNextAllowTokenOf(address token) internal view returns (address) {
    return poolConfigV1DiamondStorage().allowTokens.getNextOf(token);
  }

  function getStrategyDelta(
    address token
  ) internal view returns (bool, uint256) {
    // Load pool config diamond storage
    PoolConfigV1DiamondStorage
      storage poolConfigV1Ds = poolConfigV1DiamondStorage();

    if (address(poolConfigV1Ds.strategyOf[token]) == address(0))
      return (false, 0);

    return
      poolConfigV1DiamondStorage().strategyOf[token].getStrategyDelta(
        poolConfigV1Ds.strategyDataOf[token].principle
      );
  }

  function getTokenBufferLiquidityOf(
    address token
  ) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].bufferLiquidity;
  }

  function getTokenDecimalsOf(address token) internal view returns (uint8) {
    return poolConfigV1DiamondStorage().tokenMetas[token].decimals;
  }

  function getTokenMinProfitBpsOf(
    address token
  ) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].minProfitBps;
  }

  function getTokenWeightOf(address token) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].weight;
  }

  function getTokenUsdDebtCeilingOf(
    address token
  ) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].usdDebtCeiling;
  }

  function getTokenShortCeilingOf(
    address token
  ) internal view returns (uint256) {
    return poolConfigV1DiamondStorage().tokenMetas[token].shortCeiling;
  }

  function getTokenOpenInterestLongCeilingOf(
    address token
  ) internal view returns (uint256) {
    return
      poolConfigV1DiamondStorage().tokenMetas[token].openInterestLongCeiling;
  }

  function isAcceptToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].accept;
  }

  function isAllowedLiquidators(
    address liquidator
  ) internal view returns (bool) {
    // Load PoolConfigV1 diamond storage
    PoolConfigV1DiamondStorage
      storage poolConfigV1Ds = poolConfigV1DiamondStorage();

    return
      poolConfigV1Ds.isAllowAllLiquidators
        ? true
        : poolConfigV1Ds.allowLiquidators[liquidator];
  }

  function isDynamicFeeEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isDynamicFeeEnable;
  }

  function isLeverageEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isLeverageEnable;
  }

  function isStableToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].isStable;
  }

  function isShortableToken(address token) internal view returns (bool) {
    return poolConfigV1DiamondStorage().tokenMetas[token].isShortable;
  }

  function isSwapEnable() internal view returns (bool) {
    return poolConfigV1DiamondStorage().isSwapEnable;
  }

  function liquidationFeeUsd() internal view returns (uint256) {
    return poolConfigV1DiamondStorage().liquidationFeeUsd;
  }

  function maxLeverage() internal view returns (uint64) {
    return poolConfigV1DiamondStorage().maxLeverage;
  }

  function strategyOf(address token) internal view returns (StrategyInterface) {
    return poolConfigV1DiamondStorage().strategyOf[token];
  }

  function treasury() internal view returns (address) {
    return poolConfigV1DiamondStorage().treasury;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IWNative } from "../../interfaces/IWNative.sol";
import { IPoolOracle } from "../../interfaces/IPoolOracle.sol";
import { GetterFacetInterface } from "./interfaces/GetterFacetInterface.sol";
import { LiquidityFacetInterface } from "./interfaces/LiquidityFacetInterface.sol";
import { PerpTradeFacetInterface } from "./interfaces/PerpTradeFacetInterface.sol";
import { LibPoolConfigV1 } from "./libraries/LibPoolConfigV1.sol";

contract MarketOrderbook is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address payable;

  uint256 public constant BASIS_POINTS_DIVISOR = 10000;

  struct IncreasePositionRequest {
    address account;
    uint256 subAccountId;
    address[] path;
    address indexToken;
    uint256 amountIn;
    uint256 minOut;
    uint256 sizeDelta;
    bool isLong;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 blockNumber;
    uint256 blockTime;
    bool hasCollateralInETH;
  }

  struct DecreasePositionRequest {
    address account;
    uint256 subAccountId;
    address[] path;
    address indexToken;
    uint256 collateralDelta;
    uint256 sizeDelta;
    bool isLong;
    address receiver;
    uint256 acceptablePrice;
    uint256 minOut;
    uint256 executionFee;
    uint256 blockNumber;
    uint256 blockTime;
    bool withdrawETH;
  }

  struct SwapOrderRequest {
    address account;
    address[] path;
    uint256 amountIn;
    uint256 minOut;
    bool shouldUnwrap;
    uint256 executionFee;
    uint256 blockNumber;
    uint256 blockTime;
  }

  address public admin;
  address public pool;
  address public poolOracle;
  address public weth;

  // to prevent using the deposit and withdrawal of collateral as a zero fee swap,
  // there is a small depositFeeBps charged if a collateral deposit results in the decrease
  // of leverage for an existing position
  // increasePositionBufferBps allows for a small amount of decrease of leverage
  uint256 public depositFeeBps;
  uint256 public increasePositionBufferBps;

  mapping(address => uint256) public feeReserves;

  uint256 public minExecutionFee;

  uint256 public minBlockDelayKeeper;
  uint256 public minTimeDelayPublic;
  uint256 public maxTimeDelay;

  bool public isLeverageEnabled;

  bytes32[] public increasePositionRequestKeys;
  bytes32[] public decreasePositionRequestKeys;
  bytes32[] public swapOrderRequestKeys;

  uint256 public increasePositionRequestKeysStart;
  uint256 public decreasePositionRequestKeysStart;
  uint256 public swapOrderRequestKeysStart;

  mapping(address => bool) public isPositionKeeper;

  mapping(address => uint256) public increasePositionsIndex;
  mapping(bytes32 => IncreasePositionRequest) public increasePositionRequests;
  mapping(address => uint256) public decreasePositionsIndex;
  mapping(bytes32 => DecreasePositionRequest) public decreasePositionRequests;
  mapping(address => uint256) public swapOrdersIndex;
  mapping(bytes32 => SwapOrderRequest) public swapOrderRequests;

  event SetDepositFee(uint256 depositFeeBps);
  event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
  event SetAdmin(address admin);
  event WithdrawFees(address token, address receiver, uint256 amount);
  event IncreasePosition(
    address account,
    uint256 subAccountId,
    uint256 sizeDelta,
    uint256 marginFeeBasisPoints
  );
  event DecreasePosition(
    address account,
    uint256 subAccountId,
    uint256 sizeDelta,
    uint256 marginFeeBasisPoints
  );
  event CreateIncreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 amountIn,
    uint256 minOut,
    uint256 sizeDelta,
    bool isLong,
    uint256 acceptablePrice,
    uint256 executionFee,
    uint256 queueIndex,
    uint256 gasPrice
  );
  event ExecuteIncreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 amountIn,
    uint256 minOut,
    uint256 sizeDelta,
    bool isLong,
    uint256 blockGap,
    uint256 timeGap,
    uint256 queueIndex,
    uint256 markPrice
  );
  event CancelIncreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 amountIn,
    uint256 minOut,
    uint256 sizeDelta,
    bool isLong,
    uint256 blockGap,
    uint256 timeGap,
    uint256 index
  );
  event CreateDecreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver,
    uint256 acceptablePrice,
    uint256 minOut,
    uint256 executionFee,
    uint256 queueIndex
  );
  event ExecuteDecreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    uint256 blockGap,
    uint256 timeGap,
    uint256 queueIndex,
    uint256 markPrice
  );
  event CancelDecreasePosition(
    address indexed account,
    uint256 subAccountId,
    address[] path,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    uint256 blockGap,
    uint256 timeGap,
    uint256 index
  );
  event CreateSwapOrder(
    address account,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    bool shouldUnwrap,
    uint256 executionFee,
    uint256 queueIndex
  );
  event ExecuteSwapOrder(
    address account,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    bool shouldUnwrap,
    uint256 executionFee,
    uint256 amountOut,
    uint256 blockGap,
    uint256 timeGap,
    uint256 queueIndex
  );
  event CancelSwapOrder(
    address account,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    bool shouldUnwrap,
    uint256 executionFee,
    uint256 blockGap,
    uint256 timeGap,
    uint256 index
  );
  event SetPositionKeeper(address indexed account, bool isActive);
  event SetMinExecutionFee(uint256 minExecutionFee);
  event SetIsLeverageEnabled(bool isLeverageEnabled);
  event SetDelayValues(
    uint256 minBlockDelayKeeper,
    uint256 minTimeDelayPublic,
    uint256 maxTimeDelay
  );
  event SetRequestKeysStartValues(
    uint256 increasePositionRequestKeysStart,
    uint256 decreasePositionRequestKeysStart,
    uint256 swapOrderRequestKeysStart
  );
  event CollectFee(
    address indexed token,
    uint256 feeAmount,
    uint256 feeReserve
  );

  error InsufficientExecutionFee();
  error IncorrectValueTransferred();
  error InvalidPathLength();
  error InvalidPath();
  error OnlyAdmin();
  error OnlyPositionKeeper();
  error InvalidPriceForExecution();
  error InsufficientAmountOut();
  error Expired();
  error Forbidden();
  error MaxGlobalLongSizesExceeded();
  error MaxGlobalShortSizesExceeded();
  error TooEarly();
  error InvalidAmountIn();
  error OnlyNativeShouldWrap();
  error InvalidSender();

  modifier onlyAdmin() {
    if (msg.sender != admin) revert OnlyAdmin();
    _;
  }

  modifier onlyPositionKeeper() {
    if (!isPositionKeeper[msg.sender]) revert OnlyPositionKeeper();
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _pool,
    address _poolOracle,
    address _weth,
    uint256 _depositFeeBps,
    uint256 _minExecutionFee
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    pool = _pool;
    poolOracle = _poolOracle;
    weth = _weth;
    depositFeeBps = _depositFeeBps;
    minExecutionFee = _minExecutionFee;

    increasePositionBufferBps = 100;
    isLeverageEnabled = true;
  }

  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
    emit SetAdmin(_admin);
  }

  function setDepositFee(uint256 _depositFeeBps) external onlyAdmin {
    depositFeeBps = _depositFeeBps;
    emit SetDepositFee(_depositFeeBps);
  }

  function setIncreasePositionBufferBps(
    uint256 _increasePositionBufferBps
  ) external onlyAdmin {
    increasePositionBufferBps = _increasePositionBufferBps;
    emit SetIncreasePositionBufferBps(_increasePositionBufferBps);
  }

  function withdrawFees(address _token, address _receiver) external onlyAdmin {
    uint256 amount = feeReserves[_token];
    if (amount == 0) {
      return;
    }

    feeReserves[_token] = 0;
    IERC20Upgradeable(_token).safeTransfer(_receiver, amount);

    emit WithdrawFees(_token, _receiver, amount);
  }

  function approve(
    address _token,
    address _spender,
    uint256 _amount
  ) external onlyOwner {
    IERC20Upgradeable(_token).approve(_spender, _amount);
  }

  function sendValue(
    address payable _receiver,
    uint256 _amount
  ) external onlyOwner {
    _receiver.sendValue(_amount);
  }

  function setPositionKeeper(
    address _account,
    bool _isActive
  ) external onlyAdmin {
    isPositionKeeper[_account] = _isActive;
    emit SetPositionKeeper(_account, _isActive);
  }

  function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
    minExecutionFee = _minExecutionFee;
    emit SetMinExecutionFee(_minExecutionFee);
  }

  function setIsLeverageEnabled(bool _isLeverageEnabled) external onlyAdmin {
    isLeverageEnabled = _isLeverageEnabled;
    emit SetIsLeverageEnabled(_isLeverageEnabled);
  }

  function setDelayValues(
    uint256 _minBlockDelayKeeper,
    uint256 _minTimeDelayPublic,
    uint256 _maxTimeDelay
  ) external onlyAdmin {
    minBlockDelayKeeper = _minBlockDelayKeeper;
    minTimeDelayPublic = _minTimeDelayPublic;
    maxTimeDelay = _maxTimeDelay;
    emit SetDelayValues(
      _minBlockDelayKeeper,
      _minTimeDelayPublic,
      _maxTimeDelay
    );
  }

  function setRequestKeysStartValues(
    uint256 _increasePositionRequestKeysStart,
    uint256 _decreasePositionRequestKeysStart,
    uint256 _swapOrderRequestKeysStart
  ) external onlyAdmin {
    increasePositionRequestKeysStart = _increasePositionRequestKeysStart;
    decreasePositionRequestKeysStart = _decreasePositionRequestKeysStart;
    swapOrderRequestKeysStart = _swapOrderRequestKeysStart;

    emit SetRequestKeysStartValues(
      _increasePositionRequestKeysStart,
      _decreasePositionRequestKeysStart,
      _swapOrderRequestKeysStart
    );
  }

  function executeIncreasePositions(
    uint256 _endIndex,
    address payable _executionFeeReceiver
  ) external onlyPositionKeeper {
    uint256 index = increasePositionRequestKeysStart;
    uint256 length = increasePositionRequestKeys.length;

    if (index >= length) {
      return;
    }

    if (_endIndex > length) {
      _endIndex = length;
    }

    while (index < _endIndex) {
      bytes32 key = increasePositionRequestKeys[index];

      // if the request was executed then delete the key from the array
      // if the request was not executed then break from the loop, this can happen if the
      // minimum number of blocks has not yet passed
      // an error could be thrown if the request is too old or if the slippage is
      // higher than what the user specified, or if there is insufficient liquidity for the position
      // in case an error was thrown, cancel the request
      try
        this.executeIncreasePosition(key, _executionFeeReceiver, index)
      returns (bool _wasExecuted) {
        if (!_wasExecuted) {
          break;
        }
      } catch {
        // wrap this call in a try catch to prevent invalid cancels from blocking the loop
        try
          this.cancelIncreasePosition(key, _executionFeeReceiver, index)
        returns (bool _wasCancelled) {
          if (!_wasCancelled) {
            break;
          }
        } catch {}
      }

      delete increasePositionRequestKeys[index];
      index++;
    }

    increasePositionRequestKeysStart = index;
  }

  function executeDecreasePositions(
    uint256 _endIndex,
    address payable _executionFeeReceiver
  ) external onlyPositionKeeper {
    uint256 index = decreasePositionRequestKeysStart;
    uint256 length = decreasePositionRequestKeys.length;

    if (index >= length) {
      return;
    }

    if (_endIndex > length) {
      _endIndex = length;
    }

    while (index < _endIndex) {
      bytes32 key = decreasePositionRequestKeys[index];

      // if the request was executed then delete the key from the array
      // if the request was not executed then break from the loop, this can happen if the
      // minimum number of blocks has not yet passed
      // an error could be thrown if the request is too old
      // in case an error was thrown, cancel the request
      try
        this.executeDecreasePosition(key, _executionFeeReceiver, index)
      returns (bool _wasExecuted) {
        if (!_wasExecuted) {
          break;
        }
      } catch {
        // wrap this call in a try catch to prevent invalid cancels from blocking the loop
        try
          this.cancelDecreasePosition(key, _executionFeeReceiver, index)
        returns (bool _wasCancelled) {
          if (!_wasCancelled) {
            break;
          }
        } catch {}
      }

      delete decreasePositionRequestKeys[index];
      index++;
    }

    decreasePositionRequestKeysStart = index;
  }

  function executeSwapOrders(
    uint256 _endIndex,
    address payable _executionFeeReceiver
  ) external onlyPositionKeeper {
    uint256 index = swapOrderRequestKeysStart;
    uint256 length = swapOrderRequestKeys.length;

    if (index >= length) {
      return;
    }

    if (_endIndex > length) {
      _endIndex = length;
    }

    while (index < _endIndex) {
      bytes32 key = swapOrderRequestKeys[index];

      // if the request was executed then delete the key from the array
      // if the request was not executed then break from the loop, this can happen if the
      // minimum number of blocks has not yet passed
      // an error could be thrown if the request is too old
      // in case an error was thrown, cancel the request
      try this.executeSwapOrder(key, _executionFeeReceiver, index) returns (
        bool _wasExecuted
      ) {
        if (!_wasExecuted) {
          break;
        }
      } catch {
        // wrap this call in a try catch to prevent invalid cancels from blocking the loop
        try this.cancelSwapOrder(key, _executionFeeReceiver, index) returns (
          bool _wasCancelled
        ) {
          if (!_wasCancelled) {
            break;
          }
        } catch {}
      }

      delete swapOrderRequestKeys[index];
      index++;
    }

    swapOrderRequestKeysStart = index;
  }

  function createIncreasePosition(
    uint256 _subAccountId,
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee
  ) external payable nonReentrant returns (bytes32) {
    if (_executionFee < minExecutionFee) revert InsufficientExecutionFee();
    if (msg.value != _executionFee) revert IncorrectValueTransferred();
    if (_path.length != 1 && _path.length != 2) revert InvalidPathLength();

    _transferInETH();

    if (_amountIn > 0) {
      IERC20Upgradeable(_path[0]).safeTransferFrom(
        msg.sender,
        address(this),
        _amountIn
      );
    }

    return
      _createIncreasePosition(
        msg.sender,
        _subAccountId,
        _path,
        _indexToken,
        _amountIn,
        _minOut,
        _sizeDelta,
        _isLong,
        _acceptablePrice,
        _executionFee,
        false
      );
  }

  function createIncreasePositionNative(
    uint256 _subAccountId,
    address[] memory _path,
    address _indexToken,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee
  ) external payable nonReentrant returns (bytes32) {
    if (_executionFee < minExecutionFee) revert InsufficientExecutionFee();
    if (msg.value < _executionFee) revert IncorrectValueTransferred();
    if (_path.length != 1 && _path.length != 2) revert InvalidPathLength();
    if (_path[0] != weth) revert InvalidPath();

    _transferInETH();

    uint256 amountIn = msg.value - _executionFee;

    return
      _createIncreasePosition(
        msg.sender,
        _subAccountId,
        _path,
        _indexToken,
        amountIn,
        _minOut,
        _sizeDelta,
        _isLong,
        _acceptablePrice,
        _executionFee,
        true
      );
  }

  function createDecreasePosition(
    uint256 _subAccountId,
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH
  ) external payable nonReentrant returns (bytes32) {
    if (_executionFee < minExecutionFee) revert InsufficientExecutionFee();
    if (msg.value != _executionFee) revert IncorrectValueTransferred();
    if (_path.length != 1 && _path.length != 2) revert InvalidPathLength();

    if (_withdrawETH) {
      if (_path[_path.length - 1] != weth) {
        revert InvalidPath();
      }
    }

    _transferInETH();

    return
      _createDecreasePosition(
        msg.sender,
        _subAccountId,
        _path,
        _indexToken,
        _collateralDelta,
        _sizeDelta,
        _isLong,
        _receiver,
        _acceptablePrice,
        _minOut,
        _executionFee,
        _withdrawETH
      );
  }

  function createSwapOrder(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _executionFee,
    bool _shouldWrap,
    bool _shouldUnwrap
  ) external payable nonReentrant returns (bytes32) {
    if (_path.length != 1 && _path.length != 2) revert InvalidPathLength();
    if (_path[0] == _path[_path.length - 1]) revert InvalidPath();
    if (_amountIn == 0) revert InvalidAmountIn();
    if (_executionFee < minExecutionFee) revert InsufficientExecutionFee();

    // always need this call because of mandatory executionFee user has to transfer in MATIC
    _transferInETH();

    if (_shouldWrap) {
      if (_path[0] != weth) revert OnlyNativeShouldWrap();
      if (msg.value != _executionFee + _amountIn)
        revert IncorrectValueTransferred();
    } else {
      if (msg.value != _executionFee) revert IncorrectValueTransferred();
      IERC20Upgradeable(_path[0]).safeTransferFrom(
        msg.sender,
        address(this),
        _amountIn
      );
    }

    return
      _createSwapOrder(
        msg.sender,
        _path,
        _amountIn,
        _minOut,
        _shouldUnwrap,
        _executionFee
      );
  }

  function getRequestQueueLengths()
    external
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256)
  {
    return (
      increasePositionRequestKeysStart,
      increasePositionRequestKeys.length,
      decreasePositionRequestKeysStart,
      decreasePositionRequestKeys.length,
      swapOrderRequestKeysStart,
      swapOrderRequestKeys.length
    );
  }

  function executeIncreasePosition(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    IncreasePositionRequest memory request = increasePositionRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldExecute = _validateExecution(
      request.blockNumber,
      request.blockTime,
      request.account
    );
    if (!shouldExecute) {
      return false;
    }

    delete increasePositionRequests[_key];

    if (request.amountIn > 0) {
      uint256 amountIn = request.amountIn;

      if (request.path.length > 1) {
        IERC20Upgradeable(request.path[0]).safeTransfer(pool, request.amountIn);
        amountIn = _swap(
          request.account,
          request.path,
          request.minOut,
          address(this)
        );
      }

      uint256 afterFeeAmount = _collectFees(
        msg.sender,
        request.path,
        amountIn,
        request.indexToken,
        request.isLong,
        request.sizeDelta
      );
      IERC20Upgradeable(request.path[request.path.length - 1]).safeTransfer(
        pool,
        afterFeeAmount
      );
    }

    _increasePosition(
      request.account,
      request.subAccountId,
      request.path[request.path.length - 1],
      request.indexToken,
      request.sizeDelta,
      request.isLong,
      request.acceptablePrice
    );

    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit ExecuteIncreasePosition(
      request.account,
      request.subAccountId,
      request.path,
      request.indexToken,
      request.amountIn,
      request.minOut,
      request.sizeDelta,
      request.isLong,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index,
      request.isLong
        ? IPoolOracle(poolOracle).getMaxPrice(request.indexToken)
        : IPoolOracle(poolOracle).getMinPrice(request.indexToken)
    );

    return true;
  }

  function cancelIncreasePosition(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    IncreasePositionRequest memory request = increasePositionRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldCancel = _validateCancellation(
      request.blockNumber,
      request.blockTime,
      request.account,
      _key,
      index
    );
    if (!shouldCancel) {
      return false;
    }

    delete increasePositionRequests[_key];

    if (request.hasCollateralInETH) {
      _transferOutETHWithGasLimitIgnoreFail(
        request.amountIn,
        payable(request.account)
      );
    } else {
      IERC20Upgradeable(request.path[0]).safeTransfer(
        request.account,
        request.amountIn
      );
    }

    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit CancelIncreasePosition(
      request.account,
      request.subAccountId,
      request.path,
      request.indexToken,
      request.amountIn,
      request.minOut,
      request.sizeDelta,
      request.isLong,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index
    );

    return true;
  }

  function executeDecreasePosition(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    DecreasePositionRequest memory request = decreasePositionRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldExecute = _validateExecution(
      request.blockNumber,
      request.blockTime,
      request.account
    );
    if (!shouldExecute) {
      return false;
    }

    delete decreasePositionRequests[_key];

    uint256 amountOut = _decreasePosition(
      request.account,
      request.subAccountId,
      request.path[0],
      request.indexToken,
      request.collateralDelta,
      request.sizeDelta,
      request.isLong,
      address(this),
      request.acceptablePrice
    );

    if (amountOut > 0) {
      if (request.path.length > 1) {
        IERC20Upgradeable(request.path[0]).safeTransfer(pool, amountOut);
        amountOut = _swap(
          request.account,
          request.path,
          request.minOut,
          address(this)
        );
      }

      if (request.withdrawETH) {
        _transferOutETHWithGasLimitIgnoreFail(
          amountOut,
          payable(request.receiver)
        );
      } else {
        IERC20Upgradeable(request.path[request.path.length - 1]).safeTransfer(
          request.receiver,
          amountOut
        );
      }
    }

    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit ExecuteDecreasePosition(
      request.account,
      request.subAccountId,
      request.path,
      request.indexToken,
      request.collateralDelta,
      request.sizeDelta,
      request.isLong,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index,
      request.isLong
        ? IPoolOracle(poolOracle).getMinPrice(request.indexToken)
        : IPoolOracle(poolOracle).getMaxPrice(request.indexToken)
    );

    return true;
  }

  function cancelDecreasePosition(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    DecreasePositionRequest memory request = decreasePositionRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldCancel = _validateCancellation(
      request.blockNumber,
      request.blockTime,
      request.account,
      _key,
      index
    );
    if (!shouldCancel) {
      return false;
    }

    delete decreasePositionRequests[_key];

    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit CancelDecreasePosition(
      request.account,
      request.subAccountId,
      request.path,
      request.indexToken,
      request.collateralDelta,
      request.sizeDelta,
      request.isLong,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index
    );

    return true;
  }

  function executeSwapOrder(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    SwapOrderRequest memory request = swapOrderRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldExecute = _validateExecution(
      request.blockNumber,
      request.blockTime,
      request.account
    );
    if (!shouldExecute) {
      return false;
    }

    delete swapOrderRequests[_key];

    IERC20Upgradeable(request.path[0]).safeTransfer(pool, request.amountIn);

    uint256 _amountOut;
    if (request.path[request.path.length - 1] == weth && request.shouldUnwrap) {
      _amountOut = _swap(
        request.account,
        request.path,
        request.minOut,
        address(this)
      );
      _transferOutETHWithGasLimitIgnoreFail(
        _amountOut,
        payable(request.account)
      );
    } else {
      _amountOut = _swap(
        request.account,
        request.path,
        request.minOut,
        request.account
      );
    }

    // pay executor
    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit ExecuteSwapOrder(
      request.account,
      request.path,
      request.amountIn,
      request.minOut,
      request.shouldUnwrap,
      request.executionFee,
      _amountOut,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index
    );

    return true;
  }

  function cancelSwapOrder(
    bytes32 _key,
    address payable _executionFeeReceiver,
    uint256 index
  ) public nonReentrant returns (bool) {
    SwapOrderRequest memory request = swapOrderRequests[_key];
    // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
    if (request.account == address(0)) {
      return true;
    }

    bool shouldCancel = _validateCancellation(
      request.blockNumber,
      request.blockTime,
      request.account,
      _key,
      index
    );

    if (!shouldCancel) {
      return false;
    }

    delete swapOrderRequests[_key];

    if (request.path[0] == weth) {
      _transferOutETHWithGasLimitIgnoreFail(
        request.amountIn,
        payable(request.account)
      );
    } else {
      IERC20Upgradeable(request.path[0]).safeTransfer(
        msg.sender,
        request.amountIn
      );
    }

    // pay executor
    _transferOutETHWithGasLimitIgnoreFail(
      request.executionFee,
      _executionFeeReceiver
    );

    emit CancelSwapOrder(
      msg.sender,
      request.path,
      request.amountIn,
      request.minOut,
      request.shouldUnwrap,
      request.executionFee,
      block.number - request.blockNumber,
      block.timestamp - request.blockTime,
      index
    );

    return true;
  }

  function getRequestKey(
    address _account,
    uint256 _index
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account, _index));
  }

  function getIncreasePositionRequestPath(
    bytes32 _key
  ) public view returns (address[] memory) {
    IncreasePositionRequest memory request = increasePositionRequests[_key];
    return request.path;
  }

  function getDecreasePositionRequestPath(
    bytes32 _key
  ) public view returns (address[] memory) {
    DecreasePositionRequest memory request = decreasePositionRequests[_key];
    return request.path;
  }

  function getSwapOrderRequestPath(
    bytes32 _key
  ) public view returns (address[] memory) {
    SwapOrderRequest memory request = swapOrderRequests[_key];
    return request.path;
  }

  function _validateMaxGlobalSize(
    address _indexToken,
    bool _isLong,
    uint256 _sizeDelta
  ) internal view {
    if (_sizeDelta == 0) {
      return;
    }

    LibPoolConfigV1.TokenConfig memory config = GetterFacetInterface(pool)
      .tokenMetas(_indexToken);

    if (_isLong) {
      uint256 openInterestDelta = GetterFacetInterface(pool)
        .convertUsde30ToTokens(_indexToken, _sizeDelta, true);
      uint256 maxGlobalLongSize = config.openInterestLongCeiling;
      if (
        maxGlobalLongSize > 0 &&
        GetterFacetInterface(pool).openInterestLong(_indexToken) +
          openInterestDelta >
        maxGlobalLongSize
      ) {
        revert MaxGlobalLongSizesExceeded();
      }
    } else {
      uint256 maxGlobalShortSize = config.shortCeiling;
      if (
        maxGlobalShortSize > 0 &&
        GetterFacetInterface(pool).shortSizeOf(_indexToken) + _sizeDelta >
        maxGlobalShortSize
      ) {
        revert MaxGlobalShortSizesExceeded();
      }
    }
  }

  function _increasePosition(
    address _account,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _price
  ) internal {
    uint256 markPrice = _isLong
      ? IPoolOracle(poolOracle).getMaxPrice(_indexToken)
      : IPoolOracle(poolOracle).getMinPrice(_indexToken);
    bool isPriceValid = _isLong ? markPrice <= _price : markPrice >= _price;
    if (!isPriceValid) {
      revert InvalidPriceForExecution();
    }

    _validateMaxGlobalSize(_indexToken, _isLong, _sizeDelta);

    PerpTradeFacetInterface(pool).increasePosition(
      _account,
      _subAccountId,
      _collateralToken,
      _indexToken,
      _sizeDelta,
      _isLong
    );

    emit IncreasePosition(
      _account,
      _subAccountId,
      _sizeDelta,
      GetterFacetInterface(pool).positionFeeBps()
    );
  }

  function _decreasePosition(
    address _account,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _price
  ) internal returns (uint256) {
    uint256 markPrice = _isLong
      ? IPoolOracle(poolOracle).getMinPrice(_indexToken)
      : IPoolOracle(poolOracle).getMaxPrice(_indexToken);

    bool isPriceValid = _isLong ? markPrice >= _price : markPrice <= _price;
    if (!isPriceValid) {
      revert InvalidPriceForExecution();
    }

    uint256 amountOut = PerpTradeFacetInterface(pool).decreasePosition(
      _account,
      _subAccountId,
      _collateralToken,
      _indexToken,
      _collateralDelta,
      _sizeDelta,
      _isLong,
      _receiver
    );

    emit DecreasePosition(
      _account,
      _subAccountId,
      _sizeDelta,
      GetterFacetInterface(pool).positionFeeBps()
    );

    return amountOut;
  }

  function _swap(
    address _account,
    address[] memory _path,
    uint256 _minOut,
    address _receiver
  ) internal returns (uint256) {
    if (_path.length == 2) {
      return _poolSwap(_account, _path[0], _path[1], _minOut, _receiver);
    }
    revert InvalidPathLength();
  }

  function _poolSwap(
    address _account,
    address _tokenIn,
    address _tokenOut,
    uint256 _minOut,
    address _receiver
  ) internal returns (uint256) {
    uint256 amountOut = LiquidityFacetInterface(pool).swap(
      _account,
      _tokenIn,
      _tokenOut,
      _minOut,
      _receiver
    );
    if (amountOut < _minOut) {
      revert InsufficientAmountOut();
    }
    return amountOut;
  }

  function _transferInETH() internal {
    if (msg.value != 0) {
      IWNative(weth).deposit{ value: msg.value }();
    }
  }

  function _transferOutETHWithGasLimitIgnoreFail(
    uint256 _amountOut,
    address payable _receiver
  ) internal {
    IWNative(weth).withdraw(_amountOut);

    // use `send` instead of `transfer` to not revert whole transaction in case ETH transfer was failed
    // it has limit of 2300 gas
    // this is to avoid front-running
    _receiver.send(_amountOut);
  }

  function _collectFees(
    address _account,
    address[] memory _path,
    uint256 _amountIn,
    address _indexToken,
    bool _isLong,
    uint256 _sizeDelta
  ) internal returns (uint256) {
    bool shouldDeductFee = _shouldDeductFee(
      _account,
      _path,
      _amountIn,
      _indexToken,
      _isLong,
      _sizeDelta
    );

    if (shouldDeductFee) {
      uint256 afterFeeAmount = (_amountIn *
        (BASIS_POINTS_DIVISOR - depositFeeBps)) / (BASIS_POINTS_DIVISOR);
      uint256 feeAmount = _amountIn - afterFeeAmount;
      address feeToken = _path[_path.length - 1];
      feeReserves[feeToken] = feeReserves[feeToken] + feeAmount;

      emit CollectFee(feeToken, feeAmount, feeReserves[feeToken]);

      return afterFeeAmount;
    }

    return _amountIn;
  }

  function _shouldDeductFee(
    address _account,
    address[] memory _path,
    uint256 _amountIn,
    address _indexToken,
    bool _isLong,
    uint256 _sizeDelta
  ) internal view returns (bool) {
    // if the position is a short, do not charge a fee
    if (!_isLong) {
      return false;
    }

    // if the position size is not increasing, this is a collateral deposit
    if (_sizeDelta == 0) {
      return true;
    }

    address collateralToken = _path[_path.length - 1];

    GetterFacetInterface.GetPositionReturnVars
      memory position = GetterFacetInterface(pool).getPosition(
        _account,
        collateralToken,
        _indexToken,
        _isLong
      );

    // if there is no existing position, do not charge a fee
    if (position.size == 0) {
      return false;
    }

    uint256 nextSize = position.size + _sizeDelta;
    uint256 collateralDelta = GetterFacetInterface(pool).convertTokensToUsde30(
      collateralToken,
      _amountIn,
      false
    );
    uint256 nextCollateral = position.collateral + collateralDelta;

    uint256 prevLeverage = (position.size * (BASIS_POINTS_DIVISOR)) /
      (position.collateral);
    // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
    uint256 nextLeverage = (nextSize *
      (BASIS_POINTS_DIVISOR + increasePositionBufferBps)) / nextCollateral;

    // deduct a fee if the leverage is decreased
    return nextLeverage < prevLeverage;
  }

  function _validateExecution(
    uint256 _positionBlockNumber,
    uint256 _positionBlockTime,
    address _account
  ) internal view returns (bool) {
    if (_positionBlockTime + maxTimeDelay <= block.timestamp) {
      revert Expired();
    }

    bool isKeeperCall = msg.sender == address(this) ||
      isPositionKeeper[msg.sender];

    if (!isLeverageEnabled && !isKeeperCall) {
      revert Forbidden();
    }

    if (isKeeperCall) {
      return _positionBlockNumber + minBlockDelayKeeper <= block.number;
    }

    if (msg.sender != _account) {
      revert Forbidden();
    }

    if (_positionBlockTime + minTimeDelayPublic > block.timestamp) {
      revert TooEarly();
    }

    return true;
  }

  function _validateCancellation(
    uint256 _positionBlockNumber,
    uint256 _positionBlockTime,
    address _account,
    bytes32 _key,
    uint256 _index
  ) internal view returns (bool) {
    bool isKeeperCall = msg.sender == address(this) ||
      isPositionKeeper[msg.sender];

    // Remove validation due to not possible to find personal order index
    // if (getRequestKey(_account, _index) != _key) {
    //   revert Forbidden();
    // }

    if (!isLeverageEnabled && !isKeeperCall) {
      revert Forbidden();
    }

    if (isKeeperCall) {
      return _positionBlockNumber + minBlockDelayKeeper <= block.number;
    }

    if (msg.sender != _account) {
      revert Forbidden();
    }

    if (_positionBlockTime + minTimeDelayPublic > block.timestamp) {
      revert TooEarly();
    }

    return true;
  }

  function _createIncreasePosition(
    address _account,
    uint256 _subAccountId,
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee,
    bool _hasCollateralInETH
  ) internal returns (bytes32) {
    IncreasePositionRequest memory request = IncreasePositionRequest(
      _account,
      _subAccountId,
      _path,
      _indexToken,
      _amountIn,
      _minOut,
      _sizeDelta,
      _isLong,
      _acceptablePrice,
      _executionFee,
      block.number,
      block.timestamp,
      _hasCollateralInETH
    );

    (uint256 index, bytes32 requestKey) = _storeIncreasePositionRequest(
      request
    );
    emit CreateIncreasePosition(
      _account,
      _subAccountId,
      _path,
      _indexToken,
      _amountIn,
      _minOut,
      _sizeDelta,
      _isLong,
      _acceptablePrice,
      _executionFee,
      increasePositionRequestKeys.length - 1,
      tx.gasprice
    );

    return requestKey;
  }

  function _storeIncreasePositionRequest(
    IncreasePositionRequest memory _request
  ) internal returns (uint256, bytes32) {
    address account = _request.account;
    uint256 index = increasePositionsIndex[account] + 1;
    increasePositionsIndex[account] = index;
    bytes32 key = getRequestKey(account, index);

    increasePositionRequests[key] = _request;
    increasePositionRequestKeys.push(key);

    return (index, key);
  }

  function _createDecreasePosition(
    address _account,
    uint256 _subAccountId,
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH
  ) internal returns (bytes32) {
    DecreasePositionRequest memory request = DecreasePositionRequest(
      _account,
      _subAccountId,
      _path,
      _indexToken,
      _collateralDelta,
      _sizeDelta,
      _isLong,
      _receiver,
      _acceptablePrice,
      _minOut,
      _executionFee,
      block.number,
      block.timestamp,
      _withdrawETH
    );

    (uint256 index, bytes32 requestKey) = _storeDecreasePositionRequest(
      request
    );
    emit CreateDecreasePosition(
      request.account,
      request.subAccountId,
      request.path,
      request.indexToken,
      request.collateralDelta,
      request.sizeDelta,
      request.isLong,
      request.receiver,
      request.acceptablePrice,
      request.minOut,
      request.executionFee,
      decreasePositionRequestKeys.length - 1
    );
    return requestKey;
  }

  function _storeDecreasePositionRequest(
    DecreasePositionRequest memory _request
  ) internal returns (uint256, bytes32) {
    address account = _request.account;
    uint256 index = decreasePositionsIndex[account] + 1;
    decreasePositionsIndex[account] = index;
    bytes32 key = getRequestKey(account, index);

    decreasePositionRequests[key] = _request;
    decreasePositionRequestKeys.push(key);

    return (index, key);
  }

  function _createSwapOrder(
    address _account,
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    bool _shouldUnwrap,
    uint256 _executionFee
  ) internal returns (bytes32) {
    SwapOrderRequest memory request = SwapOrderRequest(
      _account,
      _path,
      _amountIn,
      _minOut,
      _shouldUnwrap,
      _executionFee,
      block.number,
      block.timestamp
    );

    (uint256 index, bytes32 requestKey) = _storeSwapOrderRequest(request);

    emit CreateSwapOrder(
      request.account,
      request.path,
      request.amountIn,
      request.minOut,
      request.shouldUnwrap,
      request.executionFee,
      swapOrderRequestKeys.length - 1
    );

    return requestKey;
  }

  function _storeSwapOrderRequest(
    SwapOrderRequest memory _request
  ) internal returns (uint256, bytes32) {
    address account = _request.account;
    uint256 index = swapOrdersIndex[account] + 1;
    swapOrdersIndex[account] = index;
    bytes32 key = getRequestKey(account, index);

    swapOrderRequests[key] = _request;
    swapOrderRequestKeys.push(key);

    return (index, key);
  }

  receive() external payable {
    if (msg.sender != weth) revert InvalidSender();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ChainlinkPriceFeedInterface } from "../interfaces/ChainLinkPriceFeedInterface.sol";
import { ISecondaryPriceFeed } from "../interfaces/ISecondaryPriceFeed.sol";

contract PoolOracle is OwnableUpgradeable {
  using SafeCast for int256;

  error PoolOracle_BadArguments();
  error PoolOracle_PriceFeedNotAvailable();
  error PoolOracle_UnableFetchPrice();

  uint256 internal constant PRICE_PRECISION = 10 ** 30;
  uint256 internal constant ONE_USD = PRICE_PRECISION;
  uint256 internal constant BPS = 10000;

  struct PriceFeedInfo {
    ChainlinkPriceFeedInterface priceFeed;
    uint8 decimals;
    uint64 spreadBps;
    bool isStrictStable;
  }
  mapping(address => PriceFeedInfo) public priceFeedInfo;
  uint80 public roundDepth;
  uint256 public maxStrictPriceDeviation;
  address public secondaryPriceFeed;
  bool public isSecondaryPriceEnabled;

  event SetMaxStrictPriceDeviation(
    uint256 prevMaxStrictPriceDeviation,
    uint256 newMaxStrictPriceDeviation
  );
  event SetPriceFeed(
    address token,
    PriceFeedInfo prevPriceFeedInfo,
    PriceFeedInfo newPriceFeedInfo
  );
  event SetRoundDepth(uint80 prevRoundDepth, uint80 newRoundDepth);
  event SetSecondaryPriceFeed(
    address oldSecondaryPriceFeed,
    address newSecondaryPriceFeed
  );
  event SetIsSecondaryPriceEnabled(bool oldFlag, bool newFlag);

  function initialize(uint80 _roundDepth) external initializer {
    OwnableUpgradeable.__Ownable_init();

    if (_roundDepth < 2) revert PoolOracle_BadArguments();
    roundDepth = _roundDepth;
    isSecondaryPriceEnabled = false;
  }

  function setSecondaryPriceFeed(address newPriceFeed) external onlyOwner {
    emit SetSecondaryPriceFeed(secondaryPriceFeed, newPriceFeed);
    secondaryPriceFeed = newPriceFeed;
  }

  function setIsSecondaryPriceEnabled(bool flag) external onlyOwner {
    emit SetIsSecondaryPriceEnabled(isSecondaryPriceEnabled, flag);
    isSecondaryPriceEnabled = flag;
  }

  function _getPrice(
    address token,
    bool isUseMaxPrice
  ) internal view returns (uint256) {
    uint256 price = _getPrimaryPrice(token, isUseMaxPrice);

    if (isSecondaryPriceEnabled) {
      price = getSecondaryPrice(token, price, isUseMaxPrice);
    }

    // Handle strict stable price deviation.
    // SLOAD
    PriceFeedInfo memory priceFeed = priceFeedInfo[token];
    if (address(priceFeed.priceFeed) == address(0))
      revert PoolOracle_PriceFeedNotAvailable();
    if (priceFeed.isStrictStable) {
      uint256 delta;
      unchecked {
        delta = price > ONE_USD ? price - ONE_USD : ONE_USD - price;
      }

      if (delta <= maxStrictPriceDeviation) return ONE_USD;

      if (isUseMaxPrice && price > ONE_USD) return price;

      if (!isUseMaxPrice && price < ONE_USD) return price;

      return ONE_USD;
    }

    // Handle spreadBasisPoint
    if (isUseMaxPrice) return (price * (BPS + priceFeed.spreadBps)) / BPS;

    return (price * (BPS - priceFeed.spreadBps)) / BPS;
  }

  function _getPrimaryPrice(
    address token,
    bool isUseMaxPrice
  ) internal view returns (uint256) {
    // SLOAD
    PriceFeedInfo memory priceFeed = priceFeedInfo[token];
    if (address(priceFeed.priceFeed) == address(0))
      revert PoolOracle_PriceFeedNotAvailable();

    uint256 price = 0;
    int256 _priceCursor = 0;
    uint256 priceCursor = 0;
    (uint80 latestRoundId, int256 latestAnswer, , , ) = priceFeed
      .priceFeed
      .latestRoundData();

    for (uint80 i = 0; i < roundDepth; i++) {
      if (i >= latestRoundId) break;

      if (i == 0) {
        priceCursor = latestAnswer.toUint256();
      } else {
        (, _priceCursor, , , ) = priceFeed.priceFeed.getRoundData(
          latestRoundId - i
        );
        priceCursor = _priceCursor.toUint256();
      }

      if (price == 0) {
        price = priceCursor;
        continue;
      }

      if (isUseMaxPrice && price < priceCursor) {
        price = priceCursor;
        continue;
      }

      if (!isUseMaxPrice && price > priceCursor) {
        price = priceCursor;
      }
    }

    if (price == 0) revert PoolOracle_UnableFetchPrice();

    return (price * PRICE_PRECISION) / 10 ** priceFeed.decimals;
  }

  function getSecondaryPrice(
    address _token,
    uint256 _referencePrice,
    bool _maximise
  ) public view returns (uint256) {
    if (secondaryPriceFeed == address(0)) {
      return _referencePrice;
    }
    return
      ISecondaryPriceFeed(secondaryPriceFeed).getPrice(
        _token,
        _referencePrice,
        _maximise
      );
  }

  function getLatestPrimaryPrice(
    address token
  ) external view returns (uint256) {
    // SLOAD
    PriceFeedInfo memory priceFeed = priceFeedInfo[token];
    if (address(priceFeed.priceFeed) == address(0))
      revert PoolOracle_PriceFeedNotAvailable();

    (, int256 price, , , ) = priceFeed.priceFeed.latestRoundData();

    if (price == 0) revert PoolOracle_UnableFetchPrice();

    return uint256(price);
  }

  function getPrice(
    address token,
    bool isUseMaxPrice
  ) external view returns (uint256) {
    return _getPrice(token, isUseMaxPrice);
  }

  function getMaxPrice(address token) external view returns (uint256) {
    return _getPrice(token, true);
  }

  function getMinPrice(address token) external view returns (uint256) {
    return _getPrice(token, false);
  }

  function setMaxStrictPriceDeviation(
    uint256 _maxStrictPriceDeviation
  ) external onlyOwner {
    emit SetMaxStrictPriceDeviation(
      maxStrictPriceDeviation,
      _maxStrictPriceDeviation
    );
    maxStrictPriceDeviation = _maxStrictPriceDeviation;
  }

  function setPriceFeed(
    address[] calldata token,
    PriceFeedInfo[] calldata feedInfo
  ) external onlyOwner {
    if (token.length != feedInfo.length) revert PoolOracle_BadArguments();

    for (uint256 i = 0; i < token.length; ) {
      emit SetPriceFeed(token[i], priceFeedInfo[token[i]], feedInfo[i]);

      // Sanity check
      feedInfo[i].priceFeed.latestRoundData();

      priceFeedInfo[token[i]] = feedInfo[i];

      unchecked {
        ++i;
      }
    }
  }

  function setRoundDepth(uint80 _roundDepth) external onlyOwner {
    if (_roundDepth < 2) revert PoolOracle_BadArguments();

    emit SetRoundDepth(roundDepth, _roundDepth);
    roundDepth = _roundDepth;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ChainlinkPriceFeedInterface {
  function decimals() external view returns (uint8);

  function getRoundData(
    uint80 roundId
  ) external view returns (uint80, int256, uint256, uint256, uint80);

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface FlashLoanBorrowerInterface {
  function onFlashLoan(
    address caller,
    address[] calldata tokens,
    uint256[] calldata amounts,
    uint256[] calldata fees,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IPoolOracle {
  function getMaxPrice(address token) external returns (uint256);

  function getMinPrice(address token) external returns (uint256);

  function getPrice(
    address token,
    bool isUseMaxPrice
  ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ISecondaryPriceFeed {
  function getPrice(
    address _token,
    uint256 _referencePrice,
    bool _maximise
  ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWNative {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface StrategyInterface {
  /// @notice Send the tokens to the strategy and call run to perform the actual strategy logic
  function run(uint256 amount) external;

  /// @notice Realized any profits/losses and send them to the caller.
  /// @param principle The amount of tokens that Pool thinks the strategy has
  function realized(uint256 principle) external returns (int256 amountDelta);

  /// @notice Withdraw tokens from the strategy.
  function withdraw(uint256 amount) external returns (uint256 actualAmount);

  /// @notice Withdraw all tokens from the strategy.
  /// @param principle The amount of tokens that Pool thinks the strategy has
  function exit(uint256 principle) external returns (int256 amountDelta);

  function getStrategyDelta(
    uint256 principle
  ) external view returns (bool isProfit, uint256 amountDelta);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library LinkedList {
  error LinkedList_Existed();
  error LinkedList_NotExisted();
  error LinkedList_NotInitialized();
  error LinkedList_WrongPrev();

  address internal constant START = address(1);
  address internal constant END = address(1);
  address internal constant EMPTY = address(0);

  struct List {
    uint256 size;
    mapping(address => address) next;
  }

  function init(List storage list) internal returns (List storage) {
    list.next[START] = END;
    return list;
  }

  function has(List storage list, address addr) internal view returns (bool) {
    return list.next[addr] != EMPTY;
  }

  function add(
    List storage list,
    address addr
  ) internal returns (List storage) {
    // Check
    if (has(list, addr)) revert LinkedList_Existed();

    // Effect
    list.next[addr] = list.next[START];
    list.next[START] = addr;
    list.size++;

    return list;
  }

  function remove(
    List storage list,
    address addr,
    address prevAddr
  ) internal returns (List storage) {
    // Check
    if (!has(list, addr)) revert LinkedList_NotExisted();
    if (list.next[prevAddr] != addr) revert LinkedList_WrongPrev();

    // Effect
    list.next[prevAddr] = list.next[addr];
    list.next[addr] = EMPTY;
    list.size--;

    return list;
  }

  function getAll(List storage list) internal view returns (address[] memory) {
    address[] memory addrs = new address[](list.size);
    address curr = list.next[START];
    for (uint256 i = 0; curr != END; i++) {
      addrs[i] = curr;
      curr = list.next[curr];
    }
    return addrs;
  }

  function getPreviousOf(
    List storage list,
    address addr
  ) internal view returns (address) {
    address curr = list.next[START];
    if (curr == EMPTY) revert LinkedList_NotInitialized();
    for (uint256 i = 0; curr != END; i++) {
      if (list.next[curr] == addr) return curr;
      curr = list.next[curr];
    }
    return END;
  }

  function getNextOf(
    List storage list,
    address curr
  ) internal view returns (address) {
    return list.next[curr];
  }

  function length(List storage list) internal view returns (uint256) {
    return list.size;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PLP is ERC20Upgradeable, OwnableUpgradeable {
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public cooldown;
  mapping(address => bool) public isMinter;
  uint256 public MAX_COOLDOWN_DURATION;
  uint256 public liquidityCooldown;

  event PLP_SetWhitelist(address whitelisted, bool isActive);
  event PLP_SetMinter(address minter, bool prevAllow, bool newAllow);
  event PLP_SetLiquidityCooldown(uint256 oldCooldown, uint256 newCooldown);

  error PLP_BadLiquidityCooldown(uint256 cooldown);
  error PLP_Cooldown(uint256 cooldownExpireAt);
  error PLP_NotMinter();

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert PLP_NotMinter();
    _;
  }

  function initialize(uint256 liquidityCooldown_) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ERC20Upgradeable.__ERC20_init("P88 Liquidity Provider", "PLP");

    MAX_COOLDOWN_DURATION = 48 hours;
    liquidityCooldown = liquidityCooldown_;
  }

  function setLiquidityCooldown(
    uint256 newLiquidityCooldown
  ) external onlyOwner {
    if (newLiquidityCooldown > MAX_COOLDOWN_DURATION)
      revert PLP_BadLiquidityCooldown(newLiquidityCooldown);
    uint256 oldCooldown = liquidityCooldown;
    liquidityCooldown = newLiquidityCooldown;
    emit PLP_SetLiquidityCooldown(oldCooldown, newLiquidityCooldown);
  }

  function setWhitelist(address whitelisted, bool isActive) external onlyOwner {
    whitelist[whitelisted] = isActive;

    emit PLP_SetWhitelist(whitelisted, isActive);
  }

  function setMinter(address minter, bool allow) external onlyOwner {
    isMinter[minter] = allow;
    emit PLP_SetMinter(minter, isMinter[minter], allow);
  }

  function mint(address to, uint256 amount) public onlyMinter {
    cooldown[to] = block.timestamp + liquidityCooldown;
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyMinter {
    _burn(from, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal view override {
    if (whitelist[from] || whitelist[to]) return;

    uint256 cooldownExpireAt = cooldown[from];
    if (amount > 0 && block.timestamp < cooldownExpireAt)
      revert PLP_Cooldown(cooldownExpireAt);
  }
}