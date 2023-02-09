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
pragma solidity ^0.8.11;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library SphereMath {
  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function to224(uint256 a) internal pure returns (uint224 c) {
    require(a <= type(uint224).max, "WmxMath: uint224 Overflow");
    c = uint224(a);
  }

  function to128(uint256 a) internal pure returns (uint128 c) {
    require(a <= type(uint128).max, "WmxMath: uint128 Overflow");
    c = uint128(a);
  }

  function to112(uint256 a) internal pure returns (uint112 c) {
    require(a <= type(uint112).max, "WmxMath: uint112 Overflow");
    c = uint112(a);
  }

  function to96(uint256 a) internal pure returns (uint96 c) {
    require(a <= type(uint96).max, "WmxMath: uint96 Overflow");
    c = uint96(a);
  }

  function to32(uint256 a) internal pure returns (uint32 c) {
    require(a <= type(uint32).max, "WmxMath: uint32 Overflow");
    c = uint32(a);
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library SphereMath32 {
  function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
    c = a - b;
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint112.
library SphereMath112 {
  function add(uint112 a, uint112 b) internal pure returns (uint112 c) {
    c = a + b;
  }

  function sub(uint112 a, uint112 b) internal pure returns (uint112 c) {
    c = a - b;
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library SphereMath224 {
  function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
    c = a + b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SphereMath, SphereMath32, SphereMath112, SphereMath224} from "../lib/SphereMath.sol";

interface IRewardStaking {
  function stakeFor(address, uint256) external;
}

interface IAutocompounder {
  function autocompound(
    address _account,
    address _token,
    bytes calldata _data,
    address _oneInchRouter
  ) external;
}

/**
 * @title   SphereLocker
 * @author  Sphere Finance
 * @notice  Effectively allows for rolling 16 week lockups of Sphere, and provides balances available
 *          at each epoch (1 week).
 * @dev     Invdividual and delegatee vote power lookups both use independent accounting mechanisms.
 */
contract SphereLocker is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SphereMath for uint256;
  using SphereMath224 for uint224;
  using SphereMath112 for uint112;
  using SphereMath32 for uint32;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /* ==========     STRUCTS     ========== */

  struct RewardData {
    /// Timestamp for current period finish
    uint32 periodFinish;
    /// Last time any user took action
    uint32 lastUpdateTime;
    /// RewardRate for the rest of the period
    uint96 rewardRate;
    /// Ever increasing rewardPerToken rate, based on % of total supply
    uint96 rewardPerTokenStored;
  }

  struct UserData {
    uint128 rewardPerTokenPaid;
    uint128 rewards;
  }

  struct EarnedData {
    address token;
    uint256 amount;
  }

  struct Balances {
    uint112 locked;
    uint32 nextUnlockIndex;
  }

  struct LockedBalance {
    uint112 amount;
    uint32 unlockTime;
  }

  struct Epoch {
    uint224 supply;
    uint32 date; //epoch start date
  }

  struct DelegateeCheckpoint {
    uint224 votes;
    uint32 epochStart;
  }

  /* ========== STATE VARIABLES ========== */

  // Rewards
  address[] public rewardTokens;
  mapping(address => uint256) public queuedRewards;
  uint256 public constant NEW_REWARD_RATIO = 830;
  //     Core reward data
  mapping(address => RewardData) public rewardData;
  //     Reward token -> distributor -> is approved to add rewards
  mapping(address => mapping(address => bool)) public rewardDistributors;
  //     User -> reward token -> amount
  mapping(address => mapping(address => UserData)) public userData;
  //     Duration that rewards are streamed over
  uint256 public constant REWARDS_DURATION = 86400 * 7;
  //     Duration of lock/earned penalty period
  uint256 public constant LOCK_DURATION = REWARDS_DURATION * 17;

  // Balances
  //     Supplies and historic supply
  uint256 public lockedSupply;
  //     Epochs contains only the tokens that were locked at that epoch, not a cumulative supply
  Epoch[] public epochs;
  //     Mappings for balance data
  mapping(address => Balances) public balances;
  mapping(address => LockedBalance[]) public userLocks;

  address public penaltyReceiver;

  // Voting
  //     Stored delegations
  mapping(address => address) private _delegates;
  //     Checkpointed votes
  mapping(address => DelegateeCheckpoint[]) private _checkpointedVotes;
  //     Delegatee balances (user -> unlock timestamp -> amount)
  mapping(address => mapping(uint256 => uint256)) public delegateeUnlocks;

  // Config
  //     Blacklisted smart contract interactions
  mapping(address => bool) public blacklist;
  //     Tokens
  IERC20Upgradeable public stakingToken;
  //     Denom for calcs
  uint256 public constant DENOMINATOR = 10000;
  //     Incentives
  uint256 public kickRewardPerEpoch;
  uint256 public kickRewardEpochDelay;
  //     Shutdown
  bool public isShutdown;
  //     Cap
  uint256 public cappedSupply;

  // Basic token data
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  mapping(address => bool) public whitelist;
  mapping(address => Balances) public ragequitBalances;
  bool allow;
  address public matic;
  address public autocompound;

  /* ========== EVENTS ========== */

  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateCheckpointed(address indexed delegate);

  event Recovered(address _token, uint256 _amount);
  event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
  event Staked(address indexed _user, uint256 _paidAmount, uint256 _lockedAmount);
  event Withdrawn(address indexed _user, uint256 _amount, bool _relocked);
  event WithdrawnWithPenalty(address indexed _user, uint256 _amount);
  event KickReward(address indexed _user, address indexed _kicked, uint256 _reward);
  event RewardAdded(address indexed _token, uint256 _reward);

  event BlacklistModified(address account, bool blacklisted);
  event KickIncentiveSet(uint256 rate, uint256 delay);
  event Shutdown();
  event PenaltyReceiverUpdated(address indexed _penaltyReceiver);

  event AddReward(address indexed rewardsToken, address indexed distributor);
  event ApproveRewardDistributor(address indexed rewardsToken, address indexed distributor, bool approved);
  event CappedSupplyUpdated(uint256 _newCap);
  event WhitelistModified(address account, bool whitelisted);

  /***************************************
                    CONSTRUCTOR
    ****************************************/

  /**
   * @dev Initializes the contract.
   * @param _nameArg The name of the token.
   * @param _symbolArg The symbol of the token.
   * @param _stakingToken The address of the staking token.
   * @param _penaltyReceiver The address to receive penalties.
   */
  function __SphereLocker_init(
    string memory _nameArg,
    string memory _symbolArg,
    address _stakingToken,
    address _penaltyReceiver
  ) internal initializer {
    __Ownable_init_unchained();
    _name = _nameArg;
    _symbol = _symbolArg;
    _decimals = 18;
    kickRewardPerEpoch = 100;
    kickRewardEpochDelay = 3;
    penaltyReceiver = _penaltyReceiver;
    cappedSupply = 1e6 * 1e18;
    whitelist[msg.sender] = true;

    stakingToken = IERC20Upgradeable(_stakingToken);

    // Determine the current epoch and create the first epoch with a supply of zero
    uint256 currentEpoch = block.timestamp.div(REWARDS_DURATION).mul(REWARDS_DURATION);
    epochs.push(Epoch({supply: 0, date: uint32(currentEpoch)}));
  }

  /***************************************
                    MODIFIER
    ****************************************/

  /**
   * @dev Updates the reward data for the given account.
   * @param _account Account to update the reward data for.
   */
  modifier updateReward(address _account) {
    {
      // Get the balance data for the user
      Balances storage userBalance = balances[_account];
      // Iterate through the reward tokens
      uint256 rewardTokensLength = rewardTokens.length;
      for (uint256 i = 0; i < rewardTokensLength; i++) {
        address token = rewardTokens[i];
        // Update the reward per token and last update time for the reward token
        uint256 newRewardPerToken = _rewardPerToken(token);
        rewardData[token].rewardPerTokenStored = newRewardPerToken.to96();
        rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to32();
        // If the user is not the zero address, update the user's reward data
        if (_account != address(0)) {
          userData[_account][token] = UserData({
            rewardPerTokenPaid: newRewardPerToken.to128(),
            rewards: _earned(_account, token, userBalance.locked).to128()
          });
        }
      }
    }
    _;
  }

  /**
   * @dev Ensures that the sender and receiver are not blacklisted.
   * @param _sender Sender of the message.
   * @param _receiver Receiver of the message.
   */
  modifier notBlacklisted(address _sender, address _receiver) {
    // Ensure that the sender is not blacklisted
    require(!blacklist[_sender], "blacklisted");

    // If the sender and receiver are different addresses, ensure that the receiver is not blacklisted
    if (_sender != _receiver) {
      require(!blacklist[_receiver], "blacklisted");
    }

    _;
  }

  /***************************************
                    ADMIN
    ****************************************/

  /**
   * @notice Modifies the blacklist status of the given account.
   * @param _account Account to modify the blacklist status for.
   * @param _blacklisted Whether the account should be blacklisted or not.
   * @dev Can only be called by the contract owner. The account must be a contract.
   * @dev Modifies the blacklist status of the account and emits the BlacklistModified event.
   */
  function modifyBlacklist(address _account, bool _blacklisted) external onlyOwner {
    // Ensure that the account is a contract
    uint256 cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(_account)
    }
    require(cs != 0, "Must be contract");

    // Modify the blacklist status of the account
    blacklist[_account] = _blacklisted;
    // Emit the BlacklistModified event
    emit BlacklistModified(_account, _blacklisted);
  }

  /**
   * @notice Adds a new reward token and allows the given distributor to add rewards for it.
   * @param _rewardsToken Address of the reward token to add.
   * @param _distributor Address of the distributor that will be able to add rewards for the token.
   * @dev Only the contract owner can call this function. _rewardsToken cannot be the staking token.
   * @dev The number of reward tokens must be less than 100. _rewardsToken must not already have reward data.
   * @dev Adds _rewardsToken to the list of reward tokens, initializes the reward data,
   * and allows the given distributor to add rewards. Emits the AddReward event.
   */
  function addReward(address _rewardsToken, address _distributor) external onlyOwner {
    // Ensure that the reward token does not already have reward data
    require(rewardData[_rewardsToken].lastUpdateTime == 0, "Reward already exists");
    // Ensure that the reward token is not the staking token
    require(_rewardsToken != address(stakingToken), "Cannot add StakingToken as reward");
    // Ensure that the number of reward tokens is less than 100
    require(rewardTokens.length < 100, "Max rewards length");

    // Add the reward token to the list of reward tokens and initialize the reward data
    rewardTokens.push(_rewardsToken);
    rewardData[_rewardsToken].lastUpdateTime = uint32(block.timestamp);
    rewardData[_rewardsToken].periodFinish = uint32(block.timestamp);
    // Allow the distributor to add rewards for the reward token
    rewardDistributors[_rewardsToken][_distributor] = true;

    // Emit the AddReward event
    emit AddReward(_rewardsToken, _distributor);
  }

  /**
   * @notice Modifies the approval for an address to call `notifyRewardAmount`.
   * @param _rewardsToken Address of the reward token.
   * @param _distributor Address to modify the approval for.
   * @param _approved True to approve, false to unapprove.
   * @dev Only the contract owner can call this function. _rewardsToken must have reward data.
   * @dev Modifies the approval for the given address to call `notifyRewardAmount` for the given reward token.
   * Emits the ApproveRewardDistributor event.
   */
  function approveRewardDistributor(
    address _rewardsToken,
    address _distributor,
    bool _approved
  ) external onlyOwner {
    // Ensure that the reward token has reward data
    require(rewardData[_rewardsToken].lastUpdateTime > 0, "Reward does not exist");
    // Modify the approval for the distributor
    rewardDistributors[_rewardsToken][_distributor] = _approved;
    // Emit the ApproveRewardDistributor event
    emit ApproveRewardDistributor(_rewardsToken, _distributor, _approved);
  }

  /**
   * @notice Sets the kick incentive rate and delay.
   * @param _rate Incentive rate to set. Must be less than or equal to 500 (5% per epoch).
   * @param _delay Incentive delay to set. Must be greater than or equal to 2 (2 epochs of grace).
   * @dev Only the contract owner can call this function.
   * @dev Sets the kick incentive rate and delay. Emits the KickIncentiveSet event.
   */
  function setKickIncentive(uint256 _rate, uint256 _delay) external onlyOwner {
    // Ensure that the rate is less than or equal to 500 (5% per epoch)
    require(_rate <= 500, "over max rate");
    // Ensure that the delay is greater than or equal to 2 (2 epochs of grace)
    require(_delay >= 2, "min delay");
    // Set the kick incentive rate and delay
    kickRewardPerEpoch = _rate;
    kickRewardEpochDelay = _delay;
    // Emit the KickIncentiveSet event
    emit KickIncentiveSet(_rate, _delay);
  }

  /**
   * @notice Shuts down the contract.
   * @dev Only the contract owner can call this function. Sets the `isShutdown` state variable to
   * true and emits the Shutdown event.
   */
  function shutdown() external onlyOwner {
    // Set the isShutdown state variable to true
    isShutdown = true;
    // Emit the Shutdown event
    emit Shutdown();
  }

  function setAutocompoundData(address _matic, address _autocompound) external onlyOwner {
    // Set the matic token address
    matic = _matic;
    autocompound = _autocompound;
  }

  /**
   * @notice Recovers ERC20 tokens from the contract.
   * @param _tokenAddress Address of the ERC20 token to recover.
   * @param _tokenAmount Amount of the ERC20 token to recover.
   * @dev Only the contract owner can call this function. _tokenAddress cannot be the staking token or a reward token.
   * @dev Recovers the specified amount of the ERC20 token from the contract. Emits the Recovered event.
   */
  function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    // Ensure that the token address is not the staking token
    require(_tokenAddress != address(stakingToken), "Cannot withdraw staking token");
    // Ensure that the token address is not a reward token
    require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
    // Recover the ERC20 token from the contract
    IERC20Upgradeable(_tokenAddress).safeTransfer(owner(), _tokenAmount);
    // Emit the Recovered event
    emit Recovered(_tokenAddress, _tokenAmount);
  }

  /***************************************
                    ACTIONS
    ****************************************/

  /**
   * @notice Locks tokens to receive staking rewards.
   * @param _account Address to lock tokens for.
   * @param _amount Amount of tokens to lock.
   * @dev Transfers the specified amount of tokens from the caller to the contract,
   * then locks the tokens for the given account.
   * @dev Calls the `_lock` function, which is marked as internal and non-reentrant.
   * @dev Calls the `updateReward` modifier for the given account.
   */
  function lock(address _account, uint256 _amount) external nonReentrant updateReward(_account) {
    // Transfer the specified amount of tokens from the caller to the contract
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    // Lock the tokens for the given account
    _lock(_account, _amount);
  }

  function lockFromAutocompound(address _account, uint256 _amount) external updateReward(_account) {
    require(msg.sender == address(autocompound), "only autocompound");
    // Transfer the specified amount of tokens from the caller to the contract
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    // Lock the tokens for the given account
    _lock(_account, _amount);
  }

  /**
   * @notice Locks all the caller's staking tokens in the contract.
   * @dev The caller's staking token balance is transferred to the contract and locked.
   * The caller's reward data is updated. Non-reentrant.
   */
  function lockAll() external nonReentrant updateReward(msg.sender) {
    // Get the caller's staking token balance
    uint256 balance = stakingToken.balanceOf(msg.sender);
    // Transfer the balance to the contract
    stakingToken.safeTransferFrom(msg.sender, address(this), balance);
    // Lock the balance in the contract for the caller
    _lock(msg.sender, balance);
  }

  /**
   * @notice Locks all the caller's staking tokens in the contract for the given account.
   * @param _account Account to lock the tokens for.
   * @dev The caller's staking token balance is transferred to the contract and locked for the given account.
   * The given account's reward data is updated. Non-reentrant.
   */
  function lockAllFor(address _account) external nonReentrant updateReward(_account) {
    // Get the caller's staking token balance
    uint256 balance = stakingToken.balanceOf(msg.sender);
    // Transfer the balance to the contract
    stakingToken.safeTransferFrom(msg.sender, address(this), balance);
    // Lock the balance in the contract for the given account
    _lock(_account, balance);
  }

  /**
   * @notice Locks a specific amount of tokens.
   * @param _account Address of the account to lock the tokens from.
   * @param _amount Amount of tokens to lock.
   * @dev Must not be shutdown. _account and msg.sender must not be blacklisted.
   * @dev Checkpoints the epoch and adds the lock to the user's balance and to the epoch's supply.
   * @dev If the user is a delegate, also updates the delegate's balance. Emits the Staked event.
   */
  function _lock(address _account, uint256 _amount) internal notBlacklisted(msg.sender, _account) {
    // Ensure that the amount to lock is greater than zero
    require(_amount > 0, "Cannot stake 0");
    // Ensure that the contract is not in the shutdown state
    require(!isShutdown, "shutdown");
    require(allow, "not yet");

    // Get the balance data for the user
    Balances storage bal = balances[_account];

    // Checkpoint the epoch to ensure that the delegate's vote power is properly accounted for
    _checkpointEpoch();

    // Add the locked amount to the user's balance
    uint112 lockAmount = _amount.to112();
    bal.locked = bal.locked + (lockAmount);

    // Add the locked amount to the total locked supply
    lockedSupply = lockedSupply + (_amount);

    // Determine the current epoch and the unlock time for the locked tokens
    uint256 currentEpoch = (block.timestamp / (REWARDS_DURATION)) * (REWARDS_DURATION);
    uint256 unlockTime = currentEpoch + (LOCK_DURATION);

    // If the user has no existing locks or the unlock time for their most recent lock is earlier
    // than the current unlock time, add a new lock record for the user
    uint256 idx = userLocks[_account].length;
    if (idx == 0 || userLocks[_account][idx - 1].unlockTime < unlockTime) {
      userLocks[_account].push(LockedBalance({amount: lockAmount, unlockTime: uint32(unlockTime)}));
    } else {
      // Otherwise, add the locked amount to the user's most recent lock record
      LockedBalance storage userL = userLocks[_account][idx - 1];
      userL.amount = userL.amount + (lockAmount);
    }

    //    // If the user is a delegate, update the delegate's balance and checkpoint the delegate's vote power
    //    address delegatee = delegates(_account);
    //    if (delegatee != address(0)) {
    //      delegateeUnlocks[delegatee][unlockTime] += lockAmount;
    //      _checkpointDelegate(delegatee, lockAmount, 0);
    //    }

    // Add the locked amount to the current epoch's supply
    Epoch storage e = epochs[epochs.length - 1];
    e.supply = e.supply + (lockAmount);

    // Emit the Staked event
    emit Staked(_account, lockAmount, lockAmount);
  }

  function getReward(address _account) external {
    getReward(_account, false, false, "", address(0), address(0));
  }

  function getRewardAndAutoCompound(
    address _account,
    bool _autocompound,
    bytes calldata _data,
    address _oneInchRouter,
    address _autocompounder
  ) external {
    getReward(_account, false, _autocompound, _data, _oneInchRouter, _autocompounder);
  }

  /**
   * @notice Claims all pending rewards for the given account.
   * @param _account Address to claim rewards for.
   * @dev Calls the `updateReward` modifier for the given account.
   * @dev Iterates over the reward tokens and claims any pending rewards for the given account.
   * @dev Emits the RewardPaid event.
   */
  function getReward(
    address _account,
    bool _stake,
    bool _autocompound,
    bytes memory _data,
    address _oneInchRouter,
    address _autocompounder
  ) public nonReentrant updateReward(_account) {
    // Get the number of reward tokens
    uint256 rewardTokensLength = rewardTokens.length;
    // Iterate over the reward tokens
    for (uint256 i; i < rewardTokensLength; i++) {
      // Get the current reward token
      address _rewardsToken = rewardTokens[i];
      // Get the pending rewards for the given account for the current reward token
      uint256 reward = userData[_account][_rewardsToken].rewards;
      // If there are pending rewards
      if (reward > 0) {
        userData[_account][_rewardsToken].rewards = 0;
        // Checks if the reward token is the Sphere token and if the user is staking
        if (_rewardsToken == address(stakingToken) && _stake && _account == msg.sender) {
          // Lock the rewards for the given account
          _lock(_account, reward);
        } else if (_rewardsToken == matic && _autocompound == true && _account == msg.sender) {
          IERC20Upgradeable(_rewardsToken).safeTransfer(_autocompounder, reward);
          IAutocompounder(_autocompounder).autocompound(_account, matic, _data, _oneInchRouter);
        } else {
          // Transfer the rewards to the given account
          IERC20Upgradeable(_rewardsToken).safeTransfer(_account, reward);
        }
        // Emit the RewardPaid event
        emit RewardPaid(_account, _rewardsToken, reward);
      }
    }
  }

  /**
   * @notice Claims rewards for the given account, skipping specified reward tokens.
   * @param _account Address to claim rewards for.
   * @param _skipIdx Array of booleans indicating which reward tokens to skip.
   * @dev This function is marked as non-reentrant and calls the `updateReward` modifier for the given account.
   * @dev Iterates over the reward tokens, skipping any specified in the `_skipIdx` array.
   * If the reward amount for the current reward token is greater than 0,
   * it is transferred to the given account and the `RewardPaid` event is emitted.
   */
  function getReward(address _account, bool[] calldata _skipIdx) external nonReentrant updateReward(_account) {
    // Get the length of the reward tokens array
    uint256 rewardTokensLength = rewardTokens.length;
    // Require that the length of the _skipIdx array is the same as the length of the reward tokens array
    require(_skipIdx.length == rewardTokensLength, "!arr");
    // Iterate over the reward tokens
    for (uint256 i; i < rewardTokensLength; i++) {
      // If the current reward token should be skipped, skip it
      if (_skipIdx[i]) continue;
      // Get the address of the current reward token
      address _rewardsToken = rewardTokens[i];
      // Get the reward amount for the current reward token and the given account
      uint256 reward = userData[_account][_rewardsToken].rewards;
      // If the reward amount is greater than 0
      if (reward > 0) {
        // Set the reward amount to 0
        userData[_account][_rewardsToken].rewards = 0;
        // Transfer the reward amount to the given account
        IERC20Upgradeable(_rewardsToken).safeTransfer(_account, reward);
        // Emit the RewardPaid event
        emit RewardPaid(_account, _rewardsToken, reward);
      }
    }
  }

  /**
   * @notice Checkpoints the current epoch, storing the votes of each delegatee and their current epoch start date.
   * @dev Calls the `_checkpointEpoch` function, which is marked as internal.
   */
  function checkpointEpoch() external {
    _checkpointEpoch();
  }

  /**
   * @dev Inserts a new epoch if needed, filling in any gaps.
   * @dev The `currentEpoch` is calculated by dividing the current block timestamp by the rewards duration,
   * then multiplying by the rewards duration. If the `nextEpochDate` is less than the `currentEpoch`,
   * a loop is entered that adds the rewards duration to the `nextEpochDate` and pushes a new `Epoch` struct
   * with a supply of 0 and the `nextEpochDate` as the date to the `epochs` array
   * until the `nextEpochDate` is equal to the `currentEpoch`.
   */
  function _checkpointEpoch() internal {
    // Calculate the current epoch
    uint256 currentEpoch = block.timestamp.div(REWARDS_DURATION).mul(REWARDS_DURATION);
    // Get the date of the next epoch
    uint256 nextEpochDate = uint256(epochs[epochs.length - 1].date);
    // If the next epoch date is less than the current epoch
    if (nextEpochDate < currentEpoch) {
      // Enter a loop
      while (nextEpochDate != currentEpoch) {
        // Add the rewards duration to the next epoch date
        nextEpochDate = nextEpochDate + (REWARDS_DURATION);
        // Push a new Epoch struct with a supply of 0 and the next epoch date as the date to the epochs array
        epochs.push(Epoch({supply: 0, date: uint32(nextEpochDate)}));
      }
    }
  }

  /**
   * @notice Withdraws all currently locked tokens without checkpointing or accruing any rewards,
   * providing the system is shutdown.
   * @dev Requires that the system is shutdown. Sets the locked balance of the caller to 0,
   * the next unlock index of the caller to the length of the user's lock history,
   * and decreases the locked supply by the amount withdrawn. Transfers the withdrawn tokens to the caller.
   */
  function emergencyWithdraw() external nonReentrant {
    require(isShutdown, "Must be shutdown");

    LockedBalance[] memory locks = userLocks[msg.sender];
    Balances storage userBalance = balances[msg.sender];

    uint256 amt = userBalance.locked;
    require(amt > 0, "Nothing locked");

    userBalance.locked = 0;
    userBalance.nextUnlockIndex = locks.length.to32();
    lockedSupply -= amt;

    emit Withdrawn(msg.sender, amt, false);

    stakingToken.safeTransfer(msg.sender, amt);
  }

  /**
   * @notice Withdraws all currently locked tokens where the unlock time has passed.
   * @param _relock Whether to relock the withdrawn tokens.
   */
  function processExpiredLocks(bool _relock) external nonReentrant {
    _processExpiredLocks(msg.sender, _relock, msg.sender, 0);
  }

  /**
   * @notice Kicks the expired locks for the given account and distributes the kicked tokens to the kicker.
   * @param _account Address to kick expired locks for.
   */
  function kickExpiredLocks(address _account) external nonReentrant {
    //allow kick after grace period of 'kickRewardEpochDelay'
    _processExpiredLocks(_account, false, msg.sender, REWARDS_DURATION.mul(kickRewardEpochDelay));
  }

  // Withdraw all currently locked tokens where the unlock time has passed
  function _processExpiredLocks(
    address _account,
    bool _relock,
    address _rewardAddress,
    uint256 _checkDelay
  ) internal updateReward(_account) {
    LockedBalance[] storage locks = userLocks[_account];
    Balances storage userBalance = balances[_account];
    uint112 locked;
    uint256 length = locks.length;
    uint256 reward = 0;
    uint256 expiryTime = _checkDelay == 0 && _relock
      ? block.timestamp + (REWARDS_DURATION)
      : block.timestamp - (_checkDelay);
    require(length > 0, "no locks");
    // e.g. now = 16
    // if contract is shutdown OR latest lock unlock time (e.g. 17) <= now - (1)
    // e.g. 17 <= (16 + 1)
    if (isShutdown || locks[length - 1].unlockTime <= expiryTime) {
      //if time is beyond last lock, can just bundle everything together
      locked = userBalance.locked;

      //dont delete, just set next index
      userBalance.nextUnlockIndex = length.to32();

      //check for kick reward
      //this wont have the exact reward rate that you would get if looped through
      //but this section is supposed to be for quick and easy low gas processing of all locks
      //we'll assume that if the reward was good enough someone would have processed at an earlier epoch
      if (_checkDelay > 0) {
        uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(REWARDS_DURATION).mul(REWARDS_DURATION);
        uint256 epochsover = currentEpoch.sub(uint256(locks[length - 1].unlockTime)).div(REWARDS_DURATION);
        uint256 rRate = SphereMath.min(kickRewardPerEpoch.mul(epochsover + 1), DENOMINATOR);
        reward = uint256(locked).mul(rRate).div(DENOMINATOR);
      }
    } else {
      //use a processed index(nextUnlockIndex) to not loop as much
      //deleting does not change array length
      uint32 nextUnlockIndex = userBalance.nextUnlockIndex;
      for (uint256 i = nextUnlockIndex; i < length; i++) {
        //unlock time must be less or equal to time
        if (locks[i].unlockTime > expiryTime) break;

        //add to cumulative amounts
        locked = locked + (locks[i].amount);

        //check for kick reward
        //each epoch over due increases reward
        if (_checkDelay > 0) {
          uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(REWARDS_DURATION).mul(REWARDS_DURATION);
          uint256 epochsover = currentEpoch.sub(uint256(locks[i].unlockTime)).div(REWARDS_DURATION);
          uint256 rRate = SphereMath.min(kickRewardPerEpoch.mul(epochsover + 1), DENOMINATOR);
          reward = reward.add(uint256(locks[i].amount).mul(rRate).div(DENOMINATOR));
        }
        //set next unlock index
        nextUnlockIndex++;
      }
      //update next unlock index
      userBalance.nextUnlockIndex = nextUnlockIndex;
    }
    require(locked > 0, "no exp locks");

    //update user balances and total supplies
    userBalance.locked = userBalance.locked - (locked);
    lockedSupply = lockedSupply - (locked);

    //checkpoint the delegatee
    //    _checkpointDelegate(delegates(_account), 0, 0);

    emit Withdrawn(_account, locked, _relock);

    //send process incentive
    if (reward > 0) {
      //reduce return amount by the kick reward
      locked = locked - (reward.to112());

      //transfer reward
      stakingToken.safeTransfer(_rewardAddress, reward);
      emit KickReward(_rewardAddress, _account, reward);
    }

    //relock or return to user
    if (_relock) {
      _lock(_account, locked);
    } else {
      stakingToken.safeTransfer(_account, locked);
    }
  }

  function isLocked(address _account) external view returns (bool) {
    LockedBalance[] memory locks = userLocks[_account];
    return locks.length > 0 && locks[locks.length - 1].unlockTime > block.timestamp;
  }

  /**
   * @dev Retrieve the `totalSupply` at the end of `timestamp`. Note, this value is the sum of all balances.
   * It is but NOT the sum of all the delegated votes!
   */
  function getPastTotalSupply(uint256 timestamp) external view returns (uint256) {
    require(timestamp < block.timestamp, "ERC20Votes: block not yet mined");
    return totalSupplyAtEpoch(findEpochId(timestamp));
  }

  /**
   * @dev Lookup a value in a list of (sorted) checkpoints.
   *      Copied from oz/ERC20Votes.sol
   */
  function _checkpointsLookup(DelegateeCheckpoint[] storage ckpts, uint256 epochStart)
    private
    view
    returns (DelegateeCheckpoint memory)
  {
    uint256 high = ckpts.length;
    uint256 low = 0;
    while (low < high) {
      uint256 mid = SphereMath.average(low, high);
      if (ckpts[mid].epochStart > epochStart) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return high == 0 ? DelegateeCheckpoint(0, 0) : ckpts[high - 1];
  }

  /***************************************
                VIEWS - BALANCES
    ****************************************/

  // Balance of an account which only includes properly locked tokens as of the most recent eligible epoch
  function balanceOf(address _user) external view returns (uint256 amount) {
    return balanceAtEpochOf(findEpochId(block.timestamp), _user);
  }

  // Balance of an account which only includes properly locked tokens at the given epoch
  function balanceAtEpochOf(uint256 _epoch, address _user) public view returns (uint256 amount) {
    uint256 epochStart = uint256(epochs[0].date).add(uint256(_epoch).mul(REWARDS_DURATION));
    require(epochStart < block.timestamp, "Epoch is in the future");

    uint256 cutoffEpoch = epochStart - (LOCK_DURATION);

    LockedBalance[] storage locks = userLocks[_user];

    //need to add up since the range could be in the middle somewhere
    //traverse inversely to make more current queries more gas efficient
    uint256 locksLength = locks.length;
    for (uint256 i = locksLength; i > 0; i--) {
      uint256 lockEpoch = uint256(locks[i - 1].unlockTime) - (LOCK_DURATION);
      //lock epoch must be less or equal to the epoch we're basing from.
      //also not include the current epoch
      if (lockEpoch < epochStart) {
        if (lockEpoch > cutoffEpoch) {
          amount = amount + (locks[i - 1].amount);
        } else {
          //stop now as no futher checks matter
          break;
        }
      }
    }

    return amount;
  }

  // Information on a user's locked balances
  function lockedBalances(address _user)
    external
    view
    returns (
      uint256 total,
      uint256 unlockable,
      uint256 locked,
      LockedBalance[] memory lockData
    )
  {
    LockedBalance[] storage locks = userLocks[_user];
    Balances storage userBalance = balances[_user];
    uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
    uint256 idx;
    for (uint256 i = nextUnlockIndex; i < locks.length; i++) {
      if (locks[i].unlockTime > block.timestamp) {
        if (idx == 0) {
          lockData = new LockedBalance[](locks.length - i);
        }
        lockData[idx] = locks[i];
        idx++;
        locked = locked + (locks[i].amount);
      } else {
        unlockable = unlockable + (locks[i].amount);
      }
    }
    return (userBalance.locked, unlockable, locked, lockData);
  }

  // Supply of all properly locked balances at most recent eligible epoch
  function totalSupply() external view returns (uint256 supply) {
    return totalSupplyAtEpoch(findEpochId(block.timestamp));
  }

  // Supply of all properly locked balances at the given epoch
  function totalSupplyAtEpoch(uint256 _epoch) public view returns (uint256 supply) {
    uint256 epochStart = uint256(epochs[0].date).add(uint256(_epoch).mul(REWARDS_DURATION));
    require(epochStart < block.timestamp, "Epoch is in the future");

    uint256 cutoffEpoch = epochStart.sub(LOCK_DURATION);
    uint256 lastIndex = epochs.length - 1;

    uint256 epochIndex = _epoch > lastIndex ? lastIndex : _epoch;

    for (uint256 i = epochIndex + 1; i > 0; i--) {
      Epoch memory e = epochs[i - 1];
      if (e.date == epochStart) {
        continue;
      } else if (e.date <= cutoffEpoch) {
        break;
      } else {
        supply += e.supply;
      }
    }
  }

  // Get an epoch index based on timestamp
  function findEpochId(uint256 _time) public view returns (uint256 epoch) {
    return _time.sub(epochs[0].date).div(REWARDS_DURATION);
  }

  /***************************************
                VIEWS - GENERAL
    ****************************************/

  // Number of epochs
  function epochCount() external view returns (uint256) {
    return epochs.length;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /***************************************
                VIEWS - REWARDS
    ****************************************/

  // Address and claimable amount of all reward tokens for the given account
  function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards) {
    userRewards = new EarnedData[](rewardTokens.length);
    Balances storage userBalance = balances[_account];
    uint256 userRewardsLength = userRewards.length;
    for (uint256 i = 0; i < userRewardsLength; i++) {
      address token = rewardTokens[i];
      userRewards[i].token = token;
      userRewards[i].amount = _earned(_account, token, userBalance.locked);
    }
    return userRewards;
  }

  function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256) {
    return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
  }

  function rewardPerToken(address _rewardsToken) external view returns (uint256) {
    return _rewardPerToken(_rewardsToken);
  }

  function _earned(
    address _user,
    address _rewardsToken,
    uint256 _balance
  ) internal view returns (uint256) {
    UserData memory data = userData[_user][_rewardsToken];
    return _balance.mul(_rewardPerToken(_rewardsToken).sub(data.rewardPerTokenPaid)).div(1e18).add(data.rewards);
  }

  function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns (uint256) {
    return SphereMath.min(block.timestamp, _finishTime);
  }

  function _rewardPerToken(address _rewardsToken) internal view returns (uint256) {
    if (lockedSupply == 0) {
      return rewardData[_rewardsToken].rewardPerTokenStored;
    }
    return
      uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
        _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish)
          .sub(rewardData[_rewardsToken].lastUpdateTime)
          .mul(rewardData[_rewardsToken].rewardRate)
          .mul(1e18)
          .div(lockedSupply)
      );
  }

  /***************************************
                REWARD FUNDING
    ****************************************/

  function queueNewRewards(address _rewardsToken, uint256 _rewards) internal {
    require(rewardDistributors[_rewardsToken][msg.sender], "!authorized");
    require(_rewards > 0, "No reward");

    RewardData storage rdata = rewardData[_rewardsToken];

    uint256 balanceBefore = IERC20Upgradeable(_rewardsToken).balanceOf(address(this));
    IERC20Upgradeable(_rewardsToken).safeTransferFrom(msg.sender, address(this), _rewards);

    _rewards = IERC20Upgradeable(_rewardsToken).balanceOf(address(this)).sub(balanceBefore);

    _rewards = _rewards.add(queuedRewards[_rewardsToken]);
    require(_rewards < 1e25, "!rewards");

    if (block.timestamp >= rdata.periodFinish) {
      _notifyReward(_rewardsToken, _rewards);
      queuedRewards[_rewardsToken] = 0;
      return;
    }

    //et = now - (finish-duration)
    uint256 elapsedTime = block.timestamp.sub(rdata.periodFinish.sub(REWARDS_DURATION.to32()));
    //current at now: rewardRate * elapsedTime
    uint256 currentAtNow = rdata.rewardRate * elapsedTime;
    uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
    if (queuedRatio < NEW_REWARD_RATIO) {
      _notifyReward(_rewardsToken, _rewards);
      queuedRewards[_rewardsToken] = 0;
    } else {
      queuedRewards[_rewardsToken] = _rewards;
    }
  }

  function queueNewRewardsSingle(address _rewardsToken, uint256 _rewards) external nonReentrant {
    queueNewRewards(_rewardsToken, _rewards);
  }

  function queueMultisigNewRewards() external nonReentrant {
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20Upgradeable(token).balanceOf(msg.sender);
      if (balance > 0) {
        if (rewardDistributors[token][msg.sender]) {
          queueNewRewards(token, balance);
        }
      }
    }
  }

  function _notifyReward(address _rewardsToken, uint256 _reward) internal updateReward(address(0)) {
    RewardData storage rdata = rewardData[_rewardsToken];

    if (block.timestamp >= rdata.periodFinish) {
      rdata.rewardRate = _reward.div(REWARDS_DURATION).to96();
    } else {
      uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
      uint256 leftover = remaining.mul(rdata.rewardRate);
      rdata.rewardRate = _reward.add(leftover).div(REWARDS_DURATION).to96();
    }

    // Equivalent to 10 million tokens over a weeks duration
    require(rdata.rewardRate < 1e20, "!rewardRate");
    require(lockedSupply >= 1e20, "!balance");

    rdata.lastUpdateTime = block.timestamp.to32();
    rdata.periodFinish = block.timestamp.add(REWARDS_DURATION).to32();

    emit RewardAdded(_rewardsToken, _reward);
  }

  function userLocksLen(address _account) external view returns (uint256) {
    return userLocks[_account].length;
  }

  function rewardTokensLen() external view returns (uint256) {
    return rewardTokens.length;
  }

  function rewardTokensList() external view returns (address[] memory) {
    return rewardTokens;
  }
}