// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * @custom:storage-size 52
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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
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

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";

/**
 * EVE01: Crowdsale does not exist
 * EVE02: Sender is not crowdsale contract
 * EVE03: Sender is not factory crowdsale contract
 */
contract CrowdsaleEvent {
  address public addressRegistry;

  event RegistryAddressUpdated(address newRoleAddress);

  event TokenPurchase(
    address indexed sale,
    bytes32 indexed id,
    address indexed beneficiary,
    address paymentToken,
    address securityToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  );

  event Refund(
    address indexed sale,
    address paymentToken,
    bytes32[] indexed id,
    address[] indexed beneficiary,
    uint256[] paymentAmt
  );
  event Distribute(
    address indexed sale,
    address securityToken,
    bytes32[] indexed id,
    address[] indexed beneficiary,
    uint256[] purchasedAmt
  );

  mapping(address => bool) saleExists;

  constructor(address addressRegistry_) {
    addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  bytes32 public constant CROWDSALE_ADMINISTRATOR_ROLE = keccak256("CROWDSALE_ADMINISTRATOR_ROLE");

  function tokenPurchaseEvent(
    bytes32 id,
    address contributor,
    address paymentToken,
    address securityToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit TokenPurchase(
      msg.sender,
      id,
      contributor,
      paymentToken,
      securityToken,
      purchasedAmt,
      initialPaymentAmt,
      nativePaymentAmt
    );
  }

  function refundEvent(
    address paymentToken,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata nativePaymentAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit Refund(msg.sender, paymentToken, ids, beneficiaries, nativePaymentAmt);
  }

  function distributeEvent(
    address token,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata purchasedAmt
  ) public {
    require(saleExists[msg.sender], "EVE01");
    emit Distribute(msg.sender, token, ids, beneficiaries, purchasedAmt);
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function setCrowdsaleExists(address addr) public {
    address crowdsaleFactory = IAddressRegistry(addressRegistry).getCrowdsaleFactAddr();
    require(msg.sender == crowdsaleFactory, "EVE03");
    saleExists[addr] = true;
  }

  function unsetCrowdsaleExists(address addr) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    saleExists[addr] = false;
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ICrowdsaleEvent {
  function tokenPurchaseEvent(
    bytes32 id,
    address beneficiary,
    address paymentToken,
    address securityToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  ) external;

  function refundEvent(
    address paymentToken,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata nativePaymentAmt
  ) external;

  function distributeEvent(
    address token,
    bytes32[] calldata ids,
    address[] calldata beneficiaries,
    uint256[] calldata purchasedAmt
  ) external;

  function setCrowdsaleExists(address sale) external;

  function removeInvestment(address contributor) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ISettlementEvent {
  function settlementDistribution(address token, address[] memory beneficiary, uint256[] memory amount) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IStableSwapEvent {
  function setPairExists(address pair) external;

  function swapEvent(
    address initiator,
    address tokenA,
    address tokenB,
    uint256 paidAmount,
    uint256 receivedAmount
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * SETE01: SecurityToken does not exist
 */
contract SettlementEvent {
  address public addressRegistry;

  event DividendDistribution(
    address indexed security,
    address indexed settlementToken,
    address[] beneficiaries,
    uint256[] amounts
  );
  event RegistryAddressUpdated(address newRoleAddress);

  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");

  constructor(address addressRegistry_) {
    addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _accessControlAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require(IAccessControl(_accessControlAddress).hasRole(_role, msg.sender));
    _;
  }

  function settlementDistribution(
    address settlementToken,
    address[] memory beneficiaries,
    uint256[] memory amounts
  ) public {
    address registry = IAddressRegistry(addressRegistry).getTokenRegAddr();
    bool exists = ITokenRegistry(registry).securityTokenExists(msg.sender);
    require(exists, "SETE01");
    emit DividendDistribution(msg.sender, settlementToken, beneficiaries, amounts);
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0) && newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * SSW01: Pair does not exist
 */
contract StableSwapEvent {
  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");
  address public addressRegistry;

  mapping(address => bool) pairExists;

  event RegistryAddressUpdated(address newRoleAddress);
  event Swap(
    address indexed pair,
    address initiator,
    address indexed tokenA,
    address indexed tokenB,
    uint256 paidAmount,
    uint256 receivedAmount
  );
  event SetPairExists(address pairAddress);
  event UnsetPairExists(address pairAddress);

  constructor(address addressRegistry_) {
    addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _accessControlAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require(IAccessControl(_accessControlAddress).hasRole(_role, msg.sender));
    _;
  }

  function swapEvent(
    address initiator,
    address tokenA,
    address tokenB,
    uint256 paidAmount,
    uint256 receivedAmount
  ) public {
    require(pairExists[msg.sender], "EVE01");
    emit Swap(msg.sender, initiator, tokenA, tokenB, paidAmount, receivedAmount);
  }

  // -----------------------------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0) && newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function setPairExists(address addr) public {
    address pairFactory = IAddressRegistry(addressRegistry).getPairFactoryAddr();
    require(msg.sender == pairFactory, "EVE03");
    pairExists[addr] = true;
    emit SetPairExists(addr);
  }

  function unsetCrowdsaleExists(address addr) public onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    pairExists[addr] = false;
    emit UnsetPairExists(addr);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../registry/interface/IAddressRegistry.sol";

contract Faucet {
  using SafeERC20 for IERC20;
  IERC20 public usdt;
  IERC20 public kchf;
  IERC20 public kusd;
  IERC20 public keur;

  uint256 public allowedAmt;
  address public addressRegistry;
  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");

  mapping(address => uint256) lastCallTime;

  event SendTokens();
  event SetAmountallowed(uint256 val);
  event RegistryAddressUpdated(address val);

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  constructor(
    address addressRegistry_,
    address usdt_,
    address kchf_,
    address kusd_,
    address keur_,
    uint256 allowedAmt_
  ) {
    addressRegistry = addressRegistry_;
    allowedAmt = allowedAmt_;
    usdt = IERC20(usdt_);
    kchf = IERC20(kchf_);
    kusd = IERC20(kusd_);
    keur = IERC20(keur_);
  }

  function claim(address claimer) public {
    require(canClaim(claimer));
    usdt.safeTransfer(claimer, allowedAmt * getDecimalMul(address(usdt)));
    kchf.safeTransfer(claimer, allowedAmt * getDecimalMul(address(kchf)));
    kusd.safeTransfer(claimer, allowedAmt * getDecimalMul(address(kusd)));
    keur.safeTransfer(claimer, allowedAmt * getDecimalMul(address(keur)));
    lastCallTime[claimer] = block.timestamp;
    emit SendTokens();
  }

  function canClaim(address claimer) public view returns (bool) {
    (uint256 usdtBalClaimer, uint256 kchfBalClaimer, uint256 kusdBalClaimer, uint256 keurBalClaimer) = getBalance(
      claimer
    );
    (uint256 usdtBalThis, uint256 kchfBalThis, uint256 kusdBalThis, uint256 keurBalThis) = getBalance(address(this));
    bool req1 = lastCallTime[claimer] + 1 hours <= block.timestamp;
    bool req2 = usdtBalThis >= getAllowedAmt(address(usdt)) &&
      kchfBalThis >= getAllowedAmt(address(kchf)) &&
      kusdBalThis >= getAllowedAmt(address(kusd)) &&
      keurBalThis >= getAllowedAmt(address(keur));
    bool req3 = usdtBalClaimer <= allowedAmt / 2 ||
      kchfBalClaimer <= allowedAmt / 2 ||
      kusdBalClaimer <= allowedAmt / 2 ||
      keurBalClaimer <= allowedAmt / 2;
    return req1 && req2 && req3;
  }

  function setAmountallowed(uint256 val) public onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(val != allowedAmt);
    allowedAmt = val;
    emit SetAmountallowed(val);
  }

  function setNewRegistryAddress(address val) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(val != address(0) && val != addressRegistry);
    addressRegistry = val;
    emit RegistryAddressUpdated(val);
  }

  function getDecimalMul(address token) internal view returns (uint256) {
    return 10 ** IERC20Metadata(token).decimals();
  }

  function getAllowedAmt(address token) internal view returns (uint256) {
    return allowedAmt * getDecimalMul(token);
  }

  function getBalance(address caller) public view returns (uint256, uint256, uint256, uint256) {
    return (usdt.balanceOf(caller), kchf.balanceOf(caller), kusd.balanceOf(caller), keur.balanceOf(caller));
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getRoleRegAddr();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MarketEvent {
  event RegistryAddressUpdated(address newRoleAddress);
  event LogItemUpdate(uint id);
  event LogTrade(
    address indexed securityToken,
    address indexed paymentToken,
    uint256 securityAmount,
    uint256 paymentAmount
  );

  event LogMake(
    bytes32 indexed id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    uint256 securityAmount,
    uint256 paymentAmount,
    uint64 timestamp
  );

  event LogTake(
    bytes32 id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    address indexed taker,
    uint256 takeAmt,
    uint256 giveAmt,
    uint64 timestamp
  );

  event LogCanceled(
    uint256 indexed id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    uint256 takeAmt,
    uint256 giveAmt,
    uint64 timestamp
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./event/MarketEvent.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * MAR01: Sender is missing role
 * MAR02: Sender is missing role to buy
 * MAR03: Sender is missing role to cancel
 * MAR04: Sender is blocklisted nor missing role
 * MAR05: Token does not exist
 * MAR06: Token is paused nor blocklisted
 * MAR07: Offer is flagged as deleted
 */

contract Market is MarketEvent {
  using SafeERC20 for IERC20Permit;
  using SafeERC20 for IERC20;

  uint256 public last_offer_id;

  address internal _addressRegistry;

  mapping(uint256 => OfferInfo) public offers;

  bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");
  bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

  bool locked;

  struct OfferInfo {
    address owner;
    address securityToken;
    uint256 securityAmount;
    address paymentToken;
    uint256 paymentAmount;
    uint256 timestamp;
    bool canceled;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  modifier synchronized() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }

  modifier can_buy(uint256 id) {
    require(isCanceled(id), "MAR07");
    require(isActive(id));
    _;
  }

  modifier can_cancel(uint id) {
    require(isCanceled(id), "MAR07");
    require(isActive(id));
    require(getOwner(id) == msg.sender || hasRole(MARKET_ADMIN_ROLE), "MAR02");
    _;
  }

  modifier can_offer() {
    require(!hasRole(BLOCKLISTED_ROLE) || hasRole(MARKET_ADMIN_ROLE), "MAR04");
    _;
  }

  constructor(address addressRegistry_) {
    _addressRegistry = addressRegistry_;
  }

  // -----------------------------------------
  // Main functions MAKE ( offer ) / TAKE ( buy ) / KILL - CANCEL
  // -----------------------------------------
  function makeOffer(
    address owner,
    address secToken,
    uint256 secAmt,
    address payToken,
    uint256 payAmt,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public can_offer synchronized returns (uint id) {
    require(payAmt > 0);
    require(payToken != address(0));
    require(secAmt > 0);
    require(payToken != address(0));
    require(payToken != secToken);

    uint256 secVal = _convertInDecimal(secToken, secAmt);
    uint256 payVal = _convertInDecimal(payToken, payAmt);

    _checkSecTok(secToken);
    _checkPayTok(payToken);

    // check signature
    _checkApproval(secToken, owner, address(this), secVal, deadline, v, r, s);

    OfferInfo memory info;
    info.owner = owner;
    info.securityToken = secToken;
    info.securityAmount = secVal;
    info.paymentToken = payToken;
    info.paymentAmount = payVal;
    info.timestamp = uint64(block.timestamp);
    id = _next_id();
    offers[id] = info;

    IERC20(secToken).safeTransferFrom(owner, address(this), secAmt);

    emit LogItemUpdate(id);
    emit LogMake(
      bytes32(id),
      keccak256(abi.encodePacked(secToken, payToken)),
      msg.sender,
      secToken,
      payToken,
      secVal,
      payVal,
      uint64(block.timestamp)
    );
  }

  function buy(
    address buyer,
    uint256 id,
    uint256 quantity,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public can_buy(id) synchronized returns (bool) {
    OfferInfo memory offer = offers[id];
    uint256 spend = (quantity * offer.securityAmount) / offer.paymentAmount;

    if (quantity == 0 || quantity > offer.securityAmount || spend > offer.paymentAmount) {
      return false;
    }

    // check signature
    _checkApproval(offers[id].paymentToken, buyer, address(this), spend, deadline, v, r, s);

    offers[id].securityAmount = offer.securityAmount - quantity;
    offers[id].paymentAmount = offer.paymentAmount - spend;

    IERC20(offers[id].paymentToken).safeTransferFrom(buyer, offers[id].owner, spend);
    IERC20(offers[id].securityToken).safeTransfer(buyer, quantity);

    emit LogItemUpdate(id);
    emit LogTake(
      bytes32(id),
      keccak256(abi.encodePacked(offer.securityToken, offer.paymentToken)),
      offer.owner,
      offer.securityToken,
      offer.paymentToken,
      buyer,
      quantity,
      spend,
      uint64(block.timestamp)
    );
    emit LogTrade(offer.securityToken, offer.paymentToken, quantity, spend);

    return true;
  }

  function cancel(uint256 id) public can_cancel(id) synchronized returns (bool success) {
    offers[id].canceled = true;

    OfferInfo memory offer = offers[id];

    IERC20(offer.securityToken).safeTransfer(offer.owner, offer.securityAmount);

    emit LogItemUpdate(id);
    emit LogCanceled(
      id,
      keccak256(abi.encodePacked(offer.securityToken, offer.paymentToken)),
      offer.owner,
      offer.securityToken,
      offer.paymentToken,
      offer.securityAmount,
      offer.paymentAmount,
      uint64(block.timestamp)
    );

    success = true;
  }

  // ------------------  // -----------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(MARKET_ADMIN_ROLE) {
    require(newAddress != address(0));
    require(newAddress != _addressRegistry);
    _addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  // ---- Public entrypoints ---- //

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getTokenRegAddr();
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  // function getEventAddr() public view returns (address) {
  //   return IAddressRegistry(_addressRegistry).getEventRegAddr();
  // }

  // ---- Internal Utils ---- //
  function _checkApproval(
    address token,
    address owner,
    address spender,
    uint256 val,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    IERC20Permit(token).safePermit(owner, spender, val, deadline, v, r, s);
  }

  function _checkPayTok(address token) internal view {
    address registryAddr = getTokenRegAddr();
    (string memory name, , bool isPaused, bool isBlocklisted) = ITokenRegistry(registryAddr).getStab(token);
    require(bytes(name).length != 0, "MAR05");
    require(!isPaused && isBlocklisted, "MAR06");
  }

  function _checkSecTok(address token) internal view {
    address registryAddr = getTokenRegAddr();
    (string memory name, , bool isPaused, bool isBlocklisted) = ITokenRegistry(registryAddr).getSec(token);
    require(bytes(name).length != 0, "MAR05");
    require(!isPaused && isBlocklisted, "MAR06");
  }

  function _next_id() internal returns (uint) {
    last_offer_id++;
    return last_offer_id;
  }

  function _convertInDecimal(address _token, uint256 _val) internal view returns (uint256) {
    return _val * 10 ** IERC20Metadata(_token).decimals();
  }

  // ---- Public  Utils ---- //

  function getAllOffersFor(address owner) public view returns (uint256[] memory id) {}

  function hasRole(bytes32 role) public view returns (bool) {
    address _rolesAddress = getRoleAddr();
    return IAccessControl(_rolesAddress).hasRole(role, msg.sender);
  }

  function isCanceled(uint256 id) public view returns (bool deleted) {
    return offers[id].canceled;
  }

  function isActive(uint256 id) public view returns (bool active) {
    return offers[id].timestamp > 0;
  }

  function getOwner(uint256 id) public view returns (address owner) {
    return offers[id].owner;
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IPairFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IPriceFeed {
  function ORACLE_ADMIN_ROLE() external view returns (bytes32);

  function getLatestPrice(address token0, address token1) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";
import "../roles/interface/IAccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// debug
import "hardhat/console.sol";

/**
 * Price feed address Mainnet
 * KEUR/KUSD 0x73366Fe0AA0Ded304479862808e02506FE556a98 ok
 * KCHF/KUSD 0xc76f762CedF0F78a439727861628E0fdfE1e70c2 ok
 * KEUR/KCHF cross-rate EUR/CHF = (EUR/USD) / (CHF/USD)
 * Price feed address Mumbai
 * KEUR/KUSD 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A ( EUR/USD ) ok
 * KCHF/KUSD 0x0000000000000000000000000000000000000000 ( EUR/USD ) No provided for testnet = 1.1
 * KEUR/KCHF cross-rate EUR/CHF = (EUR/USD) / (CHF/USD)
 */

contract PriceFeed {
  using SafeCast for int256;
  using SafeMath for uint256;

  AggregatorV3Interface internal keur_kusd_price_feed;
  AggregatorV3Interface internal kchf_kusd_price_feed;

  address private addressRegistry;
  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

  struct Pair {
    address token0;
    address token1;
    bytes4 func;
  }
  mapping(bytes32 => Pair) pairHash;

  event InitializePriceFeed();
  event SetNewKeurKusdPriceFeedAddr();
  event SetKchfKusdPriceFeedAddr();

  constructor(address addressRegistry_, address keur_kusd_, address kchf_kusd_) {
    addressRegistry = addressRegistry_;
    keur_kusd_price_feed = AggregatorV3Interface(keur_kusd_);
    kchf_kusd_price_feed = AggregatorV3Interface(kchf_kusd_);
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  /** Setters */

  function setKeurKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    keur_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetNewKeurKusdPriceFeedAddr();
  }

  function setKchfKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    kchf_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetKchfKusdPriceFeedAddr();
  }

  /** getters */

  function getLatestPrice(address tokenA, address tokenB) public view returns (uint256) {
    bytes4 func = pairHash[keccak256(abi.encodePacked(tokenA, tokenB))].func;
    (bool success, bytes memory data) = address(this).staticcall(abi.encodeWithSelector(func));
    require(success, "Call failed");
    return abi.decode(data, (uint256));
  }

  function getSelector(string memory func) public pure returns (bytes4) {
    return bytes4(keccak256(bytes(func)));
  }

  function getKeurKusd() public view returns (uint256) {
    require(address(keur_kusd_price_feed) != address(0), "getKeurKusd error provider address");
    (, int price, , , ) = keur_kusd_price_feed.latestRoundData();
    return price.toUint256();
  }

  function getKchfKusd() public view returns (uint256) {
    uint256 rate;
    if (address(kchf_kusd_price_feed) == address(0)) {
      rate = 110000000;
    } else {
      (, int price, , , ) = kchf_kusd_price_feed.latestRoundData();
      rate = price.toUint256();
    }
    return rate;
  }

  function getKeurKchf() public view returns (uint256) {
    // EUR/CHF = (EUR/USD) / (CHF/USD)
    uint256 KEUR_KUSD = getKeurKusd();
    uint256 KCHF_KUSD = getKchfKusd();
    return KEUR_KUSD.mul(10 ** 8).div(KCHF_KUSD);
  }

  /** Inverse */

  function getKusdKeur() public view returns (uint256) {
    uint256 KEUR_KUSD = getKeurKusd();
    return uint256(10 ** 16).div(KEUR_KUSD);
  }

  function getKusdKchf() public view returns (uint256) {
    uint256 KCHF_KUSD = getKchfKusd();
    return uint256(10 ** 16).div(KCHF_KUSD);
  }

  function getKchfKeur() public view returns (uint256) {
    uint256 KEUR_KCHF = getKeurKchf();
    return uint256(10 ** 16).div(KEUR_KCHF);
  }

  /** Initializer */

  function _chainlink_priceFeed__init() external onlyRole(ORACLE_ADMIN_ROLE) {
    // init pairHash
    address tokenReg = IAddressRegistry(addressRegistry).getTokenRegAddr();
    require(tokenReg != address(0), "Address cannot be null");
    address keur = ITokenRegistry(tokenReg).getStableAddress("EUR");
    address kusd = ITokenRegistry(tokenReg).getStableAddress("USD");
    address kchf = ITokenRegistry(tokenReg).getStableAddress("CHF");
    //getKeurKusd
    pairHash[keccak256(abi.encodePacked(keur, kusd))] = Pair(keur, kusd, getSelector("getKeurKusd()"));
    //getKchfKusd
    pairHash[keccak256(abi.encodePacked(kchf, kusd))] = Pair(kchf, kusd, getSelector("getKchfKusd()"));
    //getKeurKchf
    pairHash[keccak256(abi.encodePacked(keur, kchf))] = Pair(keur, kchf, getSelector("getKeurKchf()"));
    //getKusdKeur
    pairHash[keccak256(abi.encodePacked(kusd, keur))] = Pair(kusd, keur, getSelector("getKusdKeur()"));
    //getKusdKchf
    pairHash[keccak256(abi.encodePacked(kusd, kchf))] = Pair(kusd, kchf, getSelector("getKusdKchf()"));
    //getKchfKeur
    pairHash[keccak256(abi.encodePacked(kchf, keur))] = Pair(kchf, keur, getSelector("getKchfKeur()"));
    emit InitializePriceFeed();
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";
import "../roles/interface/IAccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// debug
import "hardhat/console.sol";

contract PriceFeedHardhat {
  using SafeCast for int256;
  using SafeMath for uint256;

  AggregatorV3Interface internal keur_kusd_price_feed;
  AggregatorV3Interface internal kchf_kusd_price_feed;

  address private addressRegistry;
  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

  struct Pair {
    address token0;
    address token1;
    bytes4 func;
  }
  mapping(bytes32 => Pair) pairHash;

  event InitializePriceFeed();
  event SetNewKeurKusdPriceFeedAddr();
  event SetKchfKusdPriceFeedAddr();

  constructor(address addressRegistry_, address keur_kusd_, address kchf_kusd_) {
    addressRegistry = addressRegistry_;
    keur_kusd_price_feed = AggregatorV3Interface(keur_kusd_);
    kchf_kusd_price_feed = AggregatorV3Interface(kchf_kusd_);
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  /** Setters */

  function setKeurKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    keur_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetNewKeurKusdPriceFeedAddr();
  }

  function setKchfKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    kchf_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetKchfKusdPriceFeedAddr();
  }

  /** getters */

  function getLatestPrice(address tokenA, address tokenB) public view returns (uint256) {
    // bytes32 pairHashKey = keccak256(abi.encodePacked(tokenA, tokenB));
    // bytes4 func = pairHash[pairHashKey].func;

    // (bool success, bytes memory data) = address(this).staticcall(abi.encodeWithSelector(func));
    // require(success, "Call failed");
    // return abi.decode(data, (uint256));
    return 100000000;
  }

  function getSelector(string memory func) public pure returns (bytes4) {
    return bytes4(keccak256(bytes(func)));
  }

  function getKeurKusd() public view returns (uint256) {
    require(address(keur_kusd_price_feed) != address(0), "getKeurKusd error provider address");
    uint256 rate;
    if (address(keur_kusd_price_feed) == address(0)) {
      rate = 98000000;
    } else {
      (, int price, , , ) = keur_kusd_price_feed.latestRoundData();
      rate = price.toUint256();
    }
    return rate;
  }

  function getKchfKusd() public view returns (uint256) {
    uint256 rate;
    if (address(kchf_kusd_price_feed) == address(0)) {
      rate = 100000000;
    } else {
      (, int price, , , ) = kchf_kusd_price_feed.latestRoundData();
      rate = price.toUint256();
    }
    return rate;
  }

  function getKeurKchf() public view returns (uint256) {
    // EUR/CHF = (EUR/USD) / (CHF/USD)
    uint256 KEUR_KUSD = getKeurKusd();
    uint256 KCHF_KUSD = getKchfKusd();
    return KEUR_KUSD.mul(10 ** 8).div(KCHF_KUSD);
  }

  /** Inverse */

  function getKusdKeur() public view returns (uint256) {
    uint256 KEUR_KUSD = getKeurKusd();
    return uint256(10 ** 16).div(KEUR_KUSD);
  }

  function getKusdKchf() public view returns (uint256) {
    uint256 KCHF_KUSD = getKchfKusd();
    return uint256(10 ** 16).div(KCHF_KUSD);
  }

  function getKchfKeur() public view returns (uint256) {
    uint256 KEUR_KCHF = getKeurKchf();
    return uint256(10 ** 16).div(KEUR_KCHF);
  }

  /** Initializer */

  function _chainlink_priceFeed__init() external onlyRole(ORACLE_ADMIN_ROLE) {
    // init pairHash
    address tokenReg = IAddressRegistry(addressRegistry).getTokenRegAddr();
    require(tokenReg != address(0));
    address keur = ITokenRegistry(tokenReg).getStableAddress("EUR");
    address kusd = ITokenRegistry(tokenReg).getStableAddress("USD");
    address kchf = ITokenRegistry(tokenReg).getStableAddress("CHF");
    //getKeurKusd
    pairHash[keccak256(abi.encodePacked(keur, kusd))] = Pair(keur, kusd, getSelector("getKeurKusd()"));
    //getKchfKusd
    pairHash[keccak256(abi.encodePacked(kchf, kusd))] = Pair(kchf, kusd, getSelector("getKchfKusd()"));
    //getKeurKchf
    pairHash[keccak256(abi.encodePacked(keur, kchf))] = Pair(keur, kchf, getSelector("getKeurKchf()"));
    //getKusdKeur
    pairHash[keccak256(abi.encodePacked(kusd, keur))] = Pair(kusd, keur, getSelector("getKusdKeur()"));
    //getKusdKchf
    pairHash[keccak256(abi.encodePacked(kusd, kchf))] = Pair(kusd, kchf, getSelector("getKusdKchf()"));
    //getKchfKeur
    pairHash[keccak256(abi.encodePacked(kchf, keur))] = Pair(kchf, keur, getSelector("getKchfKeur()"));
    emit InitializePriceFeed();
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

// import "./event/PriceFeedEvent.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "../roles/interface/IAccessControl.sol";
// import "../registry/interface/IAddressRegistry.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// /**
//  * PCF01: convAmt() Rate is not defined
//  * PCF02: getLatestPrice() Rate is not defined
//  */

// /**
//  * Price feed address Mainnet
//  * KEUR/KUSD 0x73366Fe0AA0Ded304479862808e02506FE556a98
//  * KCHF/KUSD 0xc76f762CedF0F78a439727861628E0fdfE1e70c2
//  * KEUR/KCHF cross-rate EUR/CHF = (EUR/USD) / (CHF/USD)
//  * Price feed address Mumbai
//  * KEUR/KUSD 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A ( EUR/USD ) ok
//  * KEUR/KCHF 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A ( EUR/USD ) No provided
//  * KCHF/KUSD 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A ( EUR/USD ) No provided for testnet = 1
//  */

// // debug
// import "hardhat/console.sol";

// contract PriceFeedOld is PriceFeedEvent {
//   Mode public mode = Mode.CHAINLINK;

//   struct TokenRate {
//     address token0;
//     address token1;
//     uint256 rate;
//     uint256 timeStamp;
//   }

//   enum Mode {
//     CHAINLINK,
//     CUSTOM
//   }

//   mapping(bytes32 => TokenRate) public customRate;

//   address private _addressRegistry;
//   bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

//   event SetMode(uint modeChoice);

//   constructor(address addressRegistry_) {
//     _addressRegistry = addressRegistry_;
//   }

//   modifier onlyRole(bytes32 _role) {
//     address _roleAddress = IAddressRegistry(_addressRegistry).getRoleRegAddr();
//     require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
//     _;
//   }

//   // ---- Public manager restricted entrypoints ---- //

//   function setMode(uint choice) public onlyRole(ORACLE_ADMIN_ROLE) {
//     require(choice == uint(Mode.CHAINLINK) || choice == uint(Mode.CUSTOM), "setMode: Wrong val");
//     if (uint(Mode.CHAINLINK) == choice) {
//       mode = Mode.CHAINLINK;
//     } else if (uint(Mode.CUSTOM) == choice) {
//       mode = Mode.CUSTOM;
//     }
//     emit SetMode(choice);
//   }

//   // ---- Custom price feed ---- //

//   function defineRate(address token0, address token1, uint256 rate) public onlyRole(ORACLE_ADMIN_ROLE) {
//     require(token0 != address(0) && token0 != address(0), "Invalid token address");
//     require(rate > 0, "Rate must be grater than zero");
//     customRate[keccak256(abi.encodePacked(token0, token1))] = TokenRate(token0, token1, rate, block.timestamp);
//     emit UpdateRate(token0, token1, rate, block.timestamp);
//   }

//   function delRate(address token0, address token1) public onlyRole(ORACLE_ADMIN_ROLE) {
//     require(token0 != address(0) && token0 != address(0), "Invalid token address");
//     customRate[keccak256(abi.encodePacked(token0, token1))] = TokenRate(token0, token1, 0, block.timestamp);
//     emit DelRate(token0, token1, block.timestamp);
//   }

//   function setNewRegistryAddress(address newAddress) external onlyRole(ORACLE_ADMIN_ROLE) {
//     require(newAddress != address(0));
//     require(newAddress != _addressRegistry, "New address is the same as the current one");
//     _addressRegistry = newAddress;
//     emit RegistryAddressUpdated(newAddress);
//   }

//   // ---- Public view entrypoints ---- //

//   function getLatestPrice(address token0, address token1) public view returns (uint256) {
//     uint256 rate = customRate[keccak256(abi.encodePacked(token0, token1))].rate;
//     require(rate > 0, "PCF02");
//     return rate;
//   }

//   function getCurrentTimeStamp(address token0, address token1) public view returns (uint256) {
//     return customRate[keccak256(abi.encodePacked(token0, token1))].timeStamp;
//   }

//   function getStateMode() public view returns (uint) {
//     return uint(mode);
//   }
// }

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";
import "../roles/interface/IAccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * Price feed address Mainnet
 * KEUR/KUSD 0x73366Fe0AA0Ded304479862808e02506FE556a98 ok
 * KCHF/KUSD 0xc76f762CedF0F78a439727861628E0fdfE1e70c2 ok
 * KEUR/KCHF cross-rate EUR/CHF = (EUR/USD) / (CHF/USD)
 * Price feed address Mumbai
 * KEUR/KUSD 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A ( EUR/USD ) ok
 * KCHF/KUSD 0x0000000000000000000000000000000000000000 ( EUR/USD ) No provided for testnet = 1.1
 * KEUR/KCHF cross-rate EUR/CHF = (EUR/USD) / (CHF/USD)
 */

// debug
import "hardhat/console.sol";

contract PriceFeedTest {
  using SafeCast for int256;
  using SafeMath for uint256;

  AggregatorV3Interface internal keur_kusd_price_feed;
  AggregatorV3Interface internal kchf_kusd_price_feed;

  address private addressRegistry;
  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

  struct Pair {
    address token0;
    address token1;
    bytes4 func;
  }
  mapping(bytes32 => Pair) pairHash;

  event InitializePriceFeed();
  event SetNewKeurKusdPriceFeedAddr();
  event SetKchfKusdPriceFeedAddr();

  constructor(address addressRegistry_, address keur_kusd_, address kchf_kusd_) {
    addressRegistry = addressRegistry_;
    keur_kusd_price_feed = AggregatorV3Interface(keur_kusd_);
    kchf_kusd_price_feed = AggregatorV3Interface(kchf_kusd_);
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  /** Setters */

  function setKeurKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    keur_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetNewKeurKusdPriceFeedAddr();
  }

  function setKchfKusdPriceFeedAddr(address newAddr) external onlyRole(ORACLE_ADMIN_ROLE) {
    require(newAddr != address(keur_kusd_price_feed), "ChainlinkPriceFeed: wrong val");
    kchf_kusd_price_feed = AggregatorV3Interface(newAddr);
    emit SetKchfKusdPriceFeedAddr();
  }

  /** getters */

  function getLatestPrice(address tokenA, address tokenB) public view returns (uint256) {
    bytes32 pairHashKey = keccak256(abi.encodePacked(tokenA, tokenB));
    bytes4 func = pairHash[pairHashKey].func;

    (bool success, bytes memory data) = address(this).staticcall(abi.encodeWithSelector(func));
    require(success, "Call failed");
    return abi.decode(data, (uint256));
  }

  function getSelector(string memory func) public pure returns (bytes4) {
    return bytes4(keccak256(bytes(func)));
  }

  function getKeurKusd() public view returns (uint256) {
    require(address(keur_kusd_price_feed) != address(0), "getKeurKusd error provider address");
    uint256 rate;
    if (address(keur_kusd_price_feed) == address(0)) {
      rate = 98000000;
    } else {
      (, int price, , , ) = keur_kusd_price_feed.latestRoundData();
      rate = price.toUint256();
    }
    return rate;
  }

  function getKchfKusd() public view returns (uint256) {
    uint256 rate;
    if (address(kchf_kusd_price_feed) == address(0)) {
      rate = 110000000;
    } else {
      (, int price, , , ) = kchf_kusd_price_feed.latestRoundData();
      rate = price.toUint256();
    }
    return rate;
  }

  function getKeurKchf() public view returns (uint256) {
    // EUR/CHF = (EUR/USD) / (CHF/USD)
    uint256 KEUR_KUSD = getKeurKusd();
    uint256 KCHF_KUSD = getKchfKusd();
    return KEUR_KUSD.mul(10 ** 8).div(KCHF_KUSD);
  }

  /** Inverse */

  function getKusdKeur() public view returns (uint256) {
    uint256 KEUR_KUSD = getKeurKusd();
    return uint256(10 ** 16).div(KEUR_KUSD);
  }

  function getKusdKchf() public view returns (uint256) {
    uint256 KCHF_KUSD = getKchfKusd();
    return uint256(10 ** 16).div(KCHF_KUSD);
  }

  function getKchfKeur() public view returns (uint256) {
    uint256 KEUR_KCHF = getKeurKchf();
    return uint256(10 ** 16).div(KEUR_KCHF);
  }

  /** Initializer */

  function _chainlink_priceFeed__init() external onlyRole(ORACLE_ADMIN_ROLE) {
    // init pairHash
    address tokenReg = IAddressRegistry(addressRegistry).getTokenRegAddr();
    require(tokenReg != address(0));
    address keur = ITokenRegistry(tokenReg).getStableAddress("EUR");
    address kusd = ITokenRegistry(tokenReg).getStableAddress("USD");
    address kchf = ITokenRegistry(tokenReg).getStableAddress("CHF");
    //getKeurKusd
    pairHash[keccak256(abi.encodePacked(keur, kusd))] = Pair(keur, kusd, getSelector("getKeurKusd()"));
    //getKchfKusd
    pairHash[keccak256(abi.encodePacked(kchf, kusd))] = Pair(kchf, kusd, getSelector("getKchfKusd()"));
    //getKeurKchf
    pairHash[keccak256(abi.encodePacked(keur, kchf))] = Pair(keur, kchf, getSelector("getKeurKchf()"));
    //getKusdKeur
    pairHash[keccak256(abi.encodePacked(kusd, keur))] = Pair(kusd, keur, getSelector("getKusdKeur()"));
    //getKusdKchf
    pairHash[keccak256(abi.encodePacked(kusd, kchf))] = Pair(kusd, kchf, getSelector("getKusdKchf()"));
    //getKchfKeur
    pairHash[keccak256(abi.encodePacked(kchf, keur))] = Pair(kchf, keur, getSelector("getKchfKeur()"));
    emit InitializePriceFeed();
  }
}

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interface/IAddressRegistry.sol";

/**
 * @title AddressRegistry
 * @dev AddressRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * ADDR01: Cannot be null
 * ADDR02: Cannot set the same value as new value
 *
 */
// debug
import "hardhat/console.sol";

contract AddressRegistryLogs {
  event InitAllAddr();
  event SetTokenRegAddr(address newVal);
  event SetRoleRegAddr(address newVal);
  event SetStableSwapEventAddr(address newVal);
  event SetSettlementEventAddr(address newVal);
  event SetCrowdsaleEventAddr(address newVal);

  event SetPriceFeedAddr(address newVal);
  event SetPairFactoryAddr(address newVal);

  event SetMarketAddr(address newVal);
  event SetCrowdsaleFactAddr(address newVal);
  event SetTokenFactAddr(address newVal);

  event SetUserRegAddr(address newVal);
}

contract AddressRegistry is IAddressRegistry, AddressRegistryLogs {
  address internal _roleRegAddr;
  address internal _tokenRegAddr;
  address internal _userRegAddr;
  address internal _stableSwapEvent;
  address internal _settlementEvent;
  address internal _crowdsaleEvent;
  address internal _priceFeedAddr;
  address internal _crowdsaleFactAddr;
  address internal _tokenFactAddr;
  address internal _marketAddr;
  address internal _pairFactoryAddr;

  bytes32 public constant REGISTRY_MANAGEMENT_ROLE = keccak256("REGISTRY_MANAGEMENT_ROLE");

  modifier onlyRole(bytes32 _role) {
    require((IAccessControl(_roleRegAddr).hasRole(_role, msg.sender)));
    _;
  }

  constructor(address roleRegAddress_) {
    _roleRegAddr = roleRegAddress_;
  }

  // ---- Restricted setters ---- //

  function initAllAddr(
    address tokenRegAddr,
    address userRegAddr,
    address stableSwapEvent,
    address settlementEvent,
    address crowdsaleEvent,
    address priceFeedAddr,
    address crowdsaleFactAddr,
    address tokenFactAddr,
    address marketAddr,
    address pairFactoryAddr
  ) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    address[10] memory addresses = [
      tokenRegAddr,
      userRegAddr,
      stableSwapEvent,
      settlementEvent,
      crowdsaleEvent,
      priceFeedAddr,
      crowdsaleFactAddr,
      tokenFactAddr,
      marketAddr,
      pairFactoryAddr
    ];

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "ADDR01");
    }

    _tokenRegAddr = tokenRegAddr;
    _userRegAddr = userRegAddr;
    _stableSwapEvent = stableSwapEvent;
    _settlementEvent = settlementEvent;
    _crowdsaleEvent = crowdsaleEvent;
    _priceFeedAddr = priceFeedAddr;
    _marketAddr = marketAddr;
    _crowdsaleFactAddr = crowdsaleFactAddr;
    _tokenFactAddr = tokenFactAddr;
    _pairFactoryAddr = pairFactoryAddr;
    emit InitAllAddr();
  }

  function setTokenRegAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _tokenRegAddr, "ADDR02");
    _tokenRegAddr = newAddr;
    emit SetTokenRegAddr(newAddr);
  }

  function setStableSwapEventAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _stableSwapEvent, "ADDR02");
    _stableSwapEvent = newAddr;
    emit SetStableSwapEventAddr(newAddr);
  }

  function setSettlementEventAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _settlementEvent, "ADDR02");
    _settlementEvent = newAddr;
    emit SetSettlementEventAddr(newAddr);
  }

  function setRoleRegAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _roleRegAddr, "ADDR02");
    _roleRegAddr = newAddr;
    emit SetRoleRegAddr(newAddr);
  }

  function setCrowdsaleEventAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _crowdsaleEvent, "ADDR02");
    _crowdsaleEvent = newAddr;
    emit SetCrowdsaleEventAddr(newAddr);
  }

  function setPriceFeedAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _priceFeedAddr, "ADDR02");
    _priceFeedAddr = newAddr;
    emit SetPriceFeedAddr(newAddr);
  }

  function setPairFactoryAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _pairFactoryAddr, "ADDR02");
    _pairFactoryAddr = newAddr;
    emit SetPairFactoryAddr(newAddr);
  }

  function setMarketAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _marketAddr, "ADDR02");
    _marketAddr = newAddr;
    emit SetMarketAddr(newAddr);
  }

  function setUserRegAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _marketAddr, "ADDR02");
    _userRegAddr = newAddr;
    emit SetUserRegAddr(newAddr);
  }

  function setCrowdsaleFactAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _crowdsaleFactAddr, "ADDR02");
    _crowdsaleFactAddr = newAddr;
    emit SetCrowdsaleFactAddr(newAddr);
  }

  function setTokenFactAddr(address newAddr) external onlyRole(REGISTRY_MANAGEMENT_ROLE) {
    require(newAddr != _tokenFactAddr, "ADDR02");
    _tokenFactAddr = newAddr;
    emit SetTokenFactAddr(newAddr);
  }

  // ---- Public getters ---- //

  function getRoleRegAddr() public view returns (address) {
    return _roleRegAddr;
  }

  function getTokenRegAddr() public view returns (address) {
    return _tokenRegAddr;
  }

  function getSettlementEventAddr() public view returns (address) {
    return _settlementEvent;
  }

  function getStableSwapEvent() public view returns (address) {
    return _stableSwapEvent;
  }

  function getCrowdsaleEventAddr() public view returns (address) {
    return _crowdsaleEvent;
  }

  function getPriceFeedAddr() public view returns (address) {
    return _priceFeedAddr;
  }

  function getMarketAddr() public view returns (address) {
    return _marketAddr;
  }

  function getCrowdsaleFactAddr() public view returns (address) {
    return _crowdsaleFactAddr;
  }

  function getTokenFactAddr() public view returns (address) {
    return _tokenFactAddr;
  }

  function getUserRegAddr() public view returns (address) {
    return _userRegAddr;
  }

  function getPairFactoryAddr() public view returns (address) {
    return _pairFactoryAddr;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract TokenRegistryEvent {
  event TokenAddressUpdated(address newTokenAddress);
  event RolesAddressUpdated(address newRoleAddress);
  event RegistryAddressUpdated(address newRoleAddress);
  event SetSettlementToken(address settlementToken);

  // ---- TokenRegistry ---- //

  event AddTokenInReg(address key, string symbol);
  event DelTokenInReg(address key);
  event PauseTokenInReg(address key);
  event UnPauseTokenInReg(address key);
  event BlockListToken(address key);
  event UnBlockListToken(address key);
}

pragma solidity ^0.8.19;

/**
 * @title IAddressRegistry
 * @dev IAddressRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * ADDR01: Cannot set the same value as new value
 *
 */

interface IAddressRegistry {
  function REGISTRY_MANAGEMENT_ROLE() external view returns (bytes32);

  function getCrowdsaleFactAddr() external view returns (address);

  function getTokenFactAddr() external view returns (address);

  function getCrowdsaleEventAddr() external view returns (address);

  function getSettlementEventAddr() external view returns (address);

  function getStableSwapEvent() external view returns (address);

  function getMarketAddr() external view returns (address);

  function getPriceFeedAddr() external view returns (address);

  function getRoleRegAddr() external view returns (address);

  function getPairFactoryAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function getUserRegAddr() external view returns (address);

  function setCrowdsaleFactAddr(address newAddr) external;

  function setTokenFactAddr(address newAddr) external;

  function setCrowdsaleEventAddr(address newAddr) external;

  function setMarketAddr(address newAddr) external;

  function setPriceFeedAddr(address newAddr) external;

  function setRoleRegAddr(address newAddr) external;

  function setPairFactoryAddr(address newAddr) external;

  function setTokenRegAddr(address newAddr) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ITokenRegistry {
  function ORACLE_ADMIN_ROLE() external view returns (bytes32);

  function add(address key, bool isStab) external;

  function blockListSec(address key) external;

  function blockListStab(address key) external;

  function delSec(address key) external;

  function delStab(address key) external;

  function getSettlementAddr() external view returns (address);

  function securityTokenExists(address key) external view returns (bool);

  function getSec(address key) external view returns (string memory, string memory, bool, bool);

  function getStab(address key) external view returns (string memory, string memory, bool, bool);

  function getTokenAddrAtIndex(uint256 id, bool isStab) external view returns (address);

  function getStabArrSize() external view returns (uint256);

  function pauseSec(address key) external;

  function pauseStab(address key) external;

  function unBlockListSec(address key) external;

  function unBlockListStab(address key) external;

  function unPauseSec(address key) external;

  function unPauseStab(address key) external;

  function getStableAddress(string memory symbol) external view returns (address);

  function getDecimals(address token) external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IUserRegistry {
  function CROWDSALE_CONTRACT() external view returns (bytes32);

  function USER_MANAGEMENT_ROLE() external view returns (bytes32);

  function addInvestment(address crowdsale, address investor, uint256 purchasedAmt, uint256 paidAmt) external;

  function flagUserAsDeleted(bytes32 id) external;

  function getAddressById(bytes32 id) external view returns (address[] memory);

  function getContribLimitFor(bytes32 id) external view returns (uint256);

  function getContribSize() external view returns (uint256);

  function getCurrentPeriodInvestmentFor(bytes32 id) external view returns (uint256);

  function getInvestorAtId(uint256 i) external view returns (bytes32);

  function getKycLevelFor(bytes32 id) external view returns (uint256);

  function getPaidAmtForAddress(address crowdsale, address account) external view returns (uint256);

  function getPurchasedAmtForAddress(address crowdsale, address account) external view returns (uint256);

  function getRemainingInvestAmtOf(bytes32 id) external view returns (uint256);

  function getRoleAddr() external view returns (address);

  function getSaleFactAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function getIdByAddress(address account) external view returns (bytes32);

  function removeInvestment(address crowdsale, address investor) external;

  function setNewContributionLimits(uint256[] memory values) external;

  function setNewRegistryAddress(address newAddress) external;

  function unWhitelistAddress(bytes32 id, address investor) external;

  function unflagUserAsDeleted(bytes32 id) external;

  function updateKycLevelFor(bytes32 id, uint256 level) external;

  function whitelistAddress(bytes32 id, address investor) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./event/TokenRegistryEvent.sol";
import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import { ItMapStable } from "./utils/ItMapStable.sol";
import { ItMapSecTok } from "./utils/ItMapSecTok.sol";

/**
 * TOKR01: Invalid token address
 */
contract TokenRegistry is TokenRegistryEvent {
  using ItMapSecTok for ItMapSecTok.SecTokMap;
  using ItMapStable for ItMapStable.StabMap;

  ItMapSecTok.SecTokMap private secTokMap;
  ItMapStable.StabMap private stabMap;

  address private _addressRegistry;
  address private settlementToken;

  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

  constructor(
    address addressRegistry_,
    address settlementToken_,
    address kchf_,
    address keur_,
    address kusd_,
    address usdt_
  ) {
    _addressRegistry = addressRegistry_;
    settlementToken = settlementToken_;
    _add(kchf_, true);
    _add(keur_, true);
    _add(kusd_, true);
    _add(usdt_, true);
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  // ---- Public manager restricted entrypoints ---- //

  function add(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    _add(key, isStab);
  }

  function remove(address key, string memory symbol, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.del(key, symbol) : secTokMap.del(key);
    emit DelTokenInReg(key);
  }

  function pause(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    require(key != address(0), "TOKR01");
    isStab ? stabMap.pause(key) : secTokMap.pause(key);
    emit PauseTokenInReg(key);
  }

  function unPause(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.unPause(key) : secTokMap.unPause(key);
    emit UnPauseTokenInReg(key);
  }

  function blockList(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.blockList(key) : secTokMap.blockList(key);
    emit BlockListToken(key);
  }

  function unBlockList(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.unBlockList(key) : secTokMap.unBlockList(key);
    emit UnBlockListToken(key);
  }

  function setSettlementTokenAddress(address addr) public onlyRole(ORACLE_ADMIN_ROLE) {
    _setSettlementTokenAddress(addr);
  }

  // ---- Public view entrypoints ---- //

  function getTokenState(address key, bool isStab) public view returns (bool, bool) {
    return isStab ? stabMap.getTokenState(key) : secTokMap.getTokenState(key);
  }

  function securityTokenExists(address key) public view returns (bool) {
    return secTokMap.tokenExists(key);
  }

  function getSettlementAddr() public view returns (address) {
    return settlementToken;
  }

  function getTokenAddrAtIndex(uint256 id, bool isStab) public view returns (address) {
    return isStab ? stabMap.getKeyAtIndex(id) : secTokMap.getKeyAtIndex(id);
  }

  function getStabArrSize(bool isStab) public view returns (uint256) {
    return isStab ? stabMap.size() : secTokMap.size();
  }

  function getStableAddress(string calldata symbol) public view returns (address) {
    return stabMap.getBySymbol(symbol);
  }

  function getDecimals(address token) public view returns (uint8) {
    uint8 decimals = IERC20Metadata(token).decimals();
    return decimals;
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  function _setSettlementTokenAddress(address addr) private {
    settlementToken = addr;
    emit SetSettlementToken(addr);
  }

  function _add(address key, bool isStab) private {
    require(key != address(0), "TOKR01");
    // convert in bytes32 = keccak
    // After more easily and gas saver to call ( like roles )
    string memory symbol = IERC20Metadata(key).symbol();
    isStab ? stabMap.add(key, symbol) : secTokMap.add(key);
    emit AddTokenInReg(key, symbol);
  }
}

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interface/IAddressRegistry.sol";
import "./interface/ITokenRegistry.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../tokensale/interfaces/ICrowdsaleFactory.sol";
import { ItMapUser } from "./utils/ItMapUser.sol";

/**
 * @title UserRegistry
 * @dev UserRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * USR01: Caller is missing role
 * USR02: Sale does not exist
 * USR03: Sender is not the crowdsale contract
 * USR04: Sender is not Kyced
 */
// debug
import "hardhat/console.sol";

contract UserRegistry {
  using ItMapUser for ItMapUser.UserMap;

  ItMapUser.UserMap private userMap;

  bytes32 public constant USER_MANAGEMENT_ROLE = keccak256("USER_MANAGEMENT_ROLE");
  bytes32 public constant CROWDSALE_CONTRACT = keccak256("CROWDSALE_CONTRACT");

  address private _addressRegistry;
  uint256 private _startDate = 1672527600; // Sun Jan 01 2023
  uint256[] contributionLimits = [0, 15_000, 100_000, 1_000_000, 10_000_000]; // make special limit for KYB etc
  event RegistryAddressUpdated(address newRoleAddress);
  event ContributionLimitsUpdated(uint256[] newValues);
  event FlagUserAsDeleted(bytes32 id);
  event UnflagUserAsDeleted(bytes32 id);

  mapping(address => address) sales;

  constructor(address addressRegistry_) {
    _addressRegistry = addressRegistry_;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require(IAccessControl(_roleAddress).hasRole(_role, msg.sender), "USR: Caller has not rights");
    _;
  }

  modifier onlyIfSaleExists() {
    address factory = getSaleFactAddr();
    require(ICrowdsaleFactory(factory).saleExists(msg.sender), "USR: Sale does not exist");
    _;
  }

  function addInvestment(
    address crowdsale,
    address investor,
    uint256 purchasedAmt,
    uint256 paidAmt
  ) public onlyIfSaleExists {
    uint currentPeriod = _periodsince();
    userMap.addInvest(crowdsale, investor, currentPeriod, purchasedAmt, paidAmt);
  }

  function removeInvestment(address crowdsale, address investor) public onlyIfSaleExists {
    uint currentPeriod = _periodsince();
    userMap.removeInvestment(crowdsale, investor, currentPeriod);
  }

  // -----------------------------------------
  // KYCLevel - Whitelisting
  // -----------------------------------------

  function updateKycLevelFor(bytes32 id, uint level) public onlyRole(USER_MANAGEMENT_ROLE) {
    userMap.updateKycLevelFor(id, level);
  }

  function whitelistAddress(bytes32 id, address investor) public onlyRole(USER_MANAGEMENT_ROLE) {
    userMap.whitelistAddress(id, investor);
  }

  function unWhitelistAddress(bytes32 id, address investor) public onlyRole(USER_MANAGEMENT_ROLE) {
    userMap.unWhitelistAddress(id, investor);
  }

  // -----------------------------------------
  // Flag as deleted
  // -----------------------------------------

  function flagUserAsDeleted(bytes32 id) public onlyRole(USER_MANAGEMENT_ROLE) {
    userMap.flagUserAsDeleted(id);
    emit FlagUserAsDeleted(id);
  }

  function unflagUserAsDeleted(bytes32 id) public onlyRole(USER_MANAGEMENT_ROLE) {
    userMap.unflagUserAsDeleted(id);
    emit UnflagUserAsDeleted(id);
  }

  // -----------------------------------------
  // Setters
  // -----------------------------------------

  function setNewContributionLimits(uint256[] memory values) external onlyRole(USER_MANAGEMENT_ROLE) {
    contributionLimits = values;
    emit ContributionLimitsUpdated(values);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(USER_MANAGEMENT_ROLE) {
    require(newAddress != address(0) && newAddress != _addressRegistry, "New address is null or the same");
    _addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  // -----------------------------------------
  // Getters
  // -----------------------------------------

  function getCurrentPeriodInvestmentFor(bytes32 id) public view returns (uint256) {
    uint month = _periodsince();
    return userMap.getInvestedAmtByMonth(id, month);
  }

  function getInvestorAtId(uint256 i) public view returns (bytes32) {
    return userMap.getKeyAtIndex(i);
  }

  function getAddressById(bytes32 id) public view returns (address[] memory) {
    return userMap.getAddressById(id);
  }

  function getIdByAddress(address account) public view returns (bytes32) {
    return userMap.getIdByAddress(account);
  }

  function getKycLevelFor(bytes32 id) public view returns (uint) {
    return userMap.getKycLevelFor(id);
  }

  // -----------------------------------------
  // Getters contributions
  // -----------------------------------------

  function getPurchasedAmtForAddress(address crowdsale, address account) public view returns (uint256) {
    return userMap.getPurchasedAmtForAddress(crowdsale, account);
  }

  function getPaidAmtForAddress(address crowdsale, address account) public view returns (uint256) {
    return userMap.getPaidAmtForAddress(crowdsale, account);
  }

  function getContribLimitFor(bytes32 id) public view returns (uint) {
    (, uint8 decimals) = getKCHF();
    return contributionLimits[userMap.getKycLevelFor(id)] * 10 ** decimals;
  }

  function getKCHF() public view returns (address, uint8) {
    address tokenReg = getTokenRegAddr();
    address kchfAddr = ITokenRegistry(tokenReg).getStableAddress("CHF");
    uint8 decimals = ITokenRegistry(tokenReg).getDecimals(kchfAddr);
    return (kchfAddr, decimals);
  }

  function getContributionLimitsForIndex(uint index) public view returns (uint256) {
    return contributionLimits[index];
  }

  function getContribSize() public view returns (uint256) {
    return userMap.size();
  }

  function getRemainingInvestAmtOf(bytes32 id) public view returns (uint256) {
    uint level = getKycLevelFor(id);
    require(level != 0, "Not Kyced");
    uint month = _periodsince();
    uint256 invested = userMap.getInvestedAmtByMonth(id, month);
    (, uint8 decimals) = getKCHF();
    uint256 limit = contributionLimits[level] * 10 ** decimals;
    return limit - invested;
  }

  function getRemainingInvestAmtConvert(address tokenOut, bytes32 id) public view returns (uint256) {
    uint256 kchfVal = getRemainingInvestAmtOf(id); // in kchf
    address priceFeedAddr = getPriceFeedAddr();
    (address kchfAddr, ) = getKCHF();
    uint256 getPrice = IPriceFeed(priceFeedAddr).getLatestPrice(kchfAddr, tokenOut);
    uint256 conv = (kchfVal * getPrice) / 10 ** 8;
    return conv;
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------
  function getPriceFeedAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getPriceFeedAddr();
  }

  function getSaleFactAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getCrowdsaleFactAddr();
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getTokenRegAddr();
  }

  // -----------------------------------------
  // Utils
  // -----------------------------------------

  function _periodsince() internal view returns (uint) {
    uint period = ((block.timestamp - _startDate) / 60 / 60 / 24) / 30;
    return period;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library ItMapSecTok {
  struct SecTokMap {
    address[] keys;
    mapping(address => bool) isPaused;
    mapping(address => bool) isBlocklisted;
    mapping(address => uint256) indexOf;
    mapping(address => bool) isExists;
  }

  function add(SecTokMap storage map, address key) public {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
        map.isExists[key] = true;
      }
    }
  }

  function del(SecTokMap storage map, address key) public {
    if (map.indexOf[key] == 0) {
      return;
    }
    delete map.isPaused[key];
    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];
    map.indexOf[lastKey] = index;
    delete map.indexOf[key];
    map.keys[index] = lastKey;
    map.keys.pop();
    map.isExists[key] = false;
  }

  function pause(SecTokMap storage map, address key) public {
    map.isPaused[key] = true;
  }

  function unPause(SecTokMap storage map, address key) public {
    map.isPaused[key] = false;
  }

  function blockList(SecTokMap storage map, address key) public {
    map.isBlocklisted[key] = true;
  }

  function unBlockList(SecTokMap storage map, address key) public {
    map.isBlocklisted[key] = false;
  }

  function tokenExists(SecTokMap storage map, address key) public view returns (bool) {
    return map.isExists[key];
  }

  function getTokenState(SecTokMap storage map, address key) public view returns (bool isPaused, bool isBlocklisted) {
    isPaused = map.isPaused[key];
    isBlocklisted = map.isBlocklisted[key];

    return (isPaused, isBlocklisted);
  }

  function getIndexOfKey(SecTokMap storage map, address key) public view returns (int) {
    if (map.indexOf[key] == 0) {
      return -1;
    }
    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(SecTokMap storage map, uint256 index) public view returns (address) {
    return map.keys[index];
  }

  function size(SecTokMap storage map) public view returns (uint256) {
    return map.keys.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library ItMapStable {
  struct StabMap {
    address[] keys;
    mapping(string => address) symbol; // to easily find stable
    mapping(address => bool) isPaused;
    mapping(address => bool) isBlocklisted;
    mapping(address => uint256) indexOf;
  }

  function add(StabMap storage map, address key, string memory symbol) public {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
      }
    }
    map.symbol[symbol] = key;
  }

  function del(StabMap storage map, address key, string memory symbol) public {
    if (map.indexOf[key] == 0) {
      return;
    }
    delete map.symbol[symbol];
    delete map.isPaused[key];
    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];
    map.indexOf[lastKey] = index;
    delete map.indexOf[key];
    map.keys[index] = lastKey;
    map.keys.pop();
  }

  function update(StabMap storage map, address key, string memory symbol) public {
    map.symbol[symbol] = key;
  }

  function pause(StabMap storage map, address key) public {
    map.isPaused[key] = true;
  }

  function unPause(StabMap storage map, address key) public {
    map.isPaused[key] = false;
  }

  function blockList(StabMap storage map, address key) public {
    map.isBlocklisted[key] = true;
  }

  function unBlockList(StabMap storage map, address key) public {
    map.isBlocklisted[key] = false;
  }

  function getTokenState(StabMap storage map, address key) public view returns (bool isPaused, bool isBlocklisted) {
    isPaused = map.isPaused[key];
    isBlocklisted = map.isBlocklisted[key];

    return (isPaused, isBlocklisted);
  }

  function getBySymbol(StabMap storage map, string memory symbol) external view returns (address) {
    return map.symbol[symbol];
  }

  function getIndexOfKey(StabMap storage map, address key) public view returns (int) {
    if (map.indexOf[key] == 0) {
      return -1;
    }
    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(StabMap storage map, uint256 index) public view returns (address) {
    return map.keys[index];
  }

  function size(StabMap storage map) public view returns (uint256) {
    return map.keys.length;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

// debug
import "hardhat/console.sol";

library ItMapUser {
  struct UserMap {
    bytes32[] ids;
    mapping(address => bytes32) addressId;
    mapping(bytes32 => uint256) indexOf;
    mapping(bytes32 => address[]) userAcc;
    mapping(bytes32 => bool) flaggedAsdeleted;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) buy;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) pay;
    mapping(bytes32 => uint) kycLevel;
    mapping(bytes32 => mapping(uint => uint256)) investedAmtByMonth;
  }

  function addInvest(
    UserMap storage map,
    address crowdsaleAddr,
    address account,
    uint currentPeriod,
    uint256 buyAmt,
    uint256 paidAmt
  ) external {
    bytes32 id = getIdByAddress(map, account);
    if (map.indexOf[id] == 0) {
      if (map.ids.length == 0 || map.ids[0] != id) {
        map.indexOf[id] = map.ids.length;
        map.ids.push(id);
      }
    }
    map.buy[id][crowdsaleAddr][account] += buyAmt;
    map.pay[id][crowdsaleAddr][account] += paidAmt;
    map.investedAmtByMonth[id][currentPeriod] += paidAmt;
  }

  function removeInvestment(UserMap storage map, address crowdsaleAddr, address account, uint currentPeriod) external {
    bytes32 id = getIdByAddress(map, account);
    uint256 current = map.pay[id][crowdsaleAddr][account];
    map.buy[id][crowdsaleAddr][account] = 0;
    map.pay[id][crowdsaleAddr][account] = 0;
    map.investedAmtByMonth[id][currentPeriod] -= current;
  }

  function flagUserAsDeleted(UserMap storage map, bytes32 id) external {
    map.flaggedAsdeleted[id] = true;
  }

  function unflagUserAsDeleted(UserMap storage map, bytes32 id) external {
    map.flaggedAsdeleted[id] = false;
  }

  // -----------------------------------------
  // KYC
  // -----------------------------------------

  function updateKycLevelFor(UserMap storage map, bytes32 id, uint level) external {
    map.kycLevel[id] = level;
  }

  // -----------------------------------------
  // Whitelisting address
  // -----------------------------------------

  function whitelistAddress(UserMap storage map, bytes32 id, address account) external {
    require(map.addressId[account] != id, "Already whitelisted");
    map.addressId[account] = id;
    map.userAcc[id].push(account);
  }

  function unWhitelistAddress(UserMap storage map, bytes32 id, address account) external {
    require(map.addressId[account] == id, "Already unwhitelisted");

    for (uint i = 0; i < map.userAcc[id].length; i++) {
      if (map.userAcc[id][i] == account) {
        map.userAcc[id][i] = map.userAcc[id][map.userAcc[id].length - 1];
        delete map.userAcc[id][map.userAcc[id].length - 1];
      }
    }
    delete map.addressId[account];
  }

  // -----------------------------------------
  // Getters
  // -----------------------------------------

  function getAddressById(UserMap storage map, bytes32 id) external view returns (address[] memory) {
    return map.userAcc[id];
  }

  function getIdByAddress(UserMap storage map, address account) public view returns (bytes32) {
    return map.addressId[account];
  }

  function getInvestedAmtByMonth(UserMap storage map, bytes32 id, uint period) external view returns (uint256) {
    return map.investedAmtByMonth[id][period];
  }

  function getKycLevelFor(UserMap storage map, bytes32 id) external view returns (uint) {
    return map.kycLevel[id];
  }

  function getPaidAmtForAddress(
    UserMap storage map,
    address crowdsaleAddr,
    address account
  ) external view returns (uint256) {
    bytes32 id = getIdByAddress(map, account);
    return map.pay[id][crowdsaleAddr][account];
  }

  function getPurchasedAmtForAddress(
    UserMap storage map,
    address crowdsaleAddr,
    address account
  ) external view returns (uint256) {
    bytes32 id = getIdByAddress(map, account);
    return map.buy[id][crowdsaleAddr][account];
  }

  // -----------------------------------------
  // Utils
  // -----------------------------------------

  function getIndexOfKey(UserMap storage map, bytes32 id) external view returns (int) {
    if (map.indexOf[id] == 0) {
      return -1;
    }
    return int(map.indexOf[id]);
  }

  function getKeyAtIndex(UserMap storage map, uint256 index) public view returns (bytes32) {
    return map.ids[index];
  }

  function size(UserMap storage map) external view returns (uint) {
    return map.ids.length;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.7;

import "./interface/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

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
    bytes32 role;
    bool exists;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant USER_MANAGEMENT_ROLE = keccak256("USER_MANAGEMENT_ROLE");
  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");
  bytes32 public constant CROWDSALE_ADMINISTRATOR_ROLE = keccak256("CROWDSALE_ADMINISTRATOR_ROLE");
  bytes32 public constant REGISTRY_MANAGEMENT_ROLE = keccak256("REGISTRY_MANAGEMENT_ROLE");
  bytes32 public constant SWAP_ADMINISTRATOR_ROLE = keccak256("SWAP_ADMINISTRATOR_ROLE");
  bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");
  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");
  bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

  event RoleAdded(bytes32 role);
  event RoleRemoved(bytes32 role);

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
    return _roles[role].role;
  }

  function createRole(bytes32 role) public onlyRole(ADMINISTRATOR_ROLE) {
    _addRole(role);
  }

  function removeRole(bytes32 role) public onlyRole(ADMINISTRATOR_ROLE) {
    _removeRole(role);
  }

  function grantRoleByAdministrator(bytes32 role, address user) public override onlyRole(ADMINISTRATOR_ROLE) {
    require(role != DEFAULT_ADMIN_ROLE, "Cannot grant default admin role.");
    require(roleExists(role), "Please create the role before you grant it.");
    _grantRole(role, user);
  }

  function revokeRoleByAdministrator(bytes32 role, address user) public override onlyRole(ADMINISTRATOR_ROLE) {
    require(role != DEFAULT_ADMIN_ROLE, "Cannot revoke default admin role.");
    _revokeRole(role, user);
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
    require(roleExists(role), "Please create the role before you grant it.");
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

  function roleExists(bytes32 roleId) public view returns (bool) {
    return (_roles[roleId].exists);
  }

  function convertIntoBytes(string memory role) public pure returns (bytes32) {
    bytes32 converted = keccak256(abi.encodePacked(role));
    return converted;
  }

  function _addRole(bytes32 role) internal virtual {
    require(!roleExists(role), "Role already exists.");
    RoleData storage r = _roles[role];
    r.exists = true;
    emit RoleAdded(role);
  }

  function _removeRole(bytes32 roleId) internal virtual {
    require(roleExists(roleId), "Role doesn't exist.");

    delete _roles[roleId];
    emit RoleRemoved(roleId);
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
    _roles[role].role = adminRole;
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

  /**
   * @dev Revokes `role` from `administrator`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRoleByAdministrator(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.7;

import "./interface/IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
    return _roleMembers[role].at(index);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
    return _roleMembers[role].length();
  }

  /**
   * @dev Overload {_grantRole} to track enumerable memberships
   */
  function _grantRole(bytes32 role, address account) internal virtual override {
    super._grantRole(role, account);
    _roleMembers[role].add(account);
  }

  /**
   * @dev Overload {_revokeRole} to track enumerable memberships
   */
  function _revokeRole(bytes32 role, address account) internal virtual override {
    super._revokeRole(role, account);
    _roleMembers[role].remove(account);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.7;

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

  function grantRoleByAdministrator(bytes32 role, address account) external;

  function revokeRoleByAdministrator(bytes32 role, address account) external;

  function convertIntoBytes(string memory role) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// contracts/Roles.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AccessControlEnumerable.sol";

contract Roles is AccessControlEnumerable {
  constructor(address _sender) {
    _addRole(DEFAULT_ADMIN_ROLE);
    _addRole(ADMINISTRATOR_ROLE);
    _addRole(CREATOR_ROLE);
    _addRole(USER_MANAGEMENT_ROLE);
    _addRole(MARKET_ADMIN_ROLE);
    _addRole(REGISTRY_MANAGEMENT_ROLE);
    _addRole(SWAP_ADMINISTRATOR_ROLE);

    _addRole(ORACLE_ADMIN_ROLE);
    _addRole(TOKEN_ADMINISTRATOR_ROLE);
    _addRole(CROWDSALE_ADMINISTRATOR_ROLE);

    _addRole(BLOCKLISTED_ROLE);

    _grantRole(DEFAULT_ADMIN_ROLE, _sender);
    _grantRole(ADMINISTRATOR_ROLE, _sender);
    _grantRole(CREATOR_ROLE, _sender);
    _grantRole(USER_MANAGEMENT_ROLE, _sender);
    _grantRole(MARKET_ADMIN_ROLE, _sender);
    _grantRole(REGISTRY_MANAGEMENT_ROLE, _sender);
    _grantRole(SWAP_ADMINISTRATOR_ROLE, _sender);

    _grantRole(ORACLE_ADMIN_ROLE, _sender);
    _grantRole(TOKEN_ADMINISTRATOR_ROLE, _sender);
    _grantRole(CROWDSALE_ADMINISTRATOR_ROLE, _sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20Permit {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IPairFactory {
  function SWAP_ADMINISTRATOR_ROLE() external view returns (bytes32);

  function createPair(address token0, address token1) external returns (address cloneAddr);

  function getPairAddress(address token0, address token1) external view returns (address);

  function getRoleAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function setNewImplementation(address newImpl) external;

  function setNewRegistryAddress(address newAddress) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface IPairSwap {
  function SWAP_ADMINISTRATOR_ROLE() external view returns (bytes32);

  function __PairSwap_init(address addressRegistry_, address token0_, address token1_, uint256 fee_) external;

  function addLiquidityPermit(
    uint256 _amount,
    bool _isToken0,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 shares);

  function addLiquidity(
    uint256 _amount,
    bool _isToken0,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 shares);

  function balanceOf(address) external view returns (uint256);

  function fee() external view returns (uint256);

  function getPriceFeedAddr() external view returns (address);

  function getRoleAddr() external view returns (address);

  function estimateAmtOut(address, uint256) external view returns (uint256);

  function getRequiredAmtOfTokensFor(address, uint256) external view returns (uint256);

  function removeLiquidity(uint256 _shares, address _token) external returns (uint256 amount);

  function reserve0() external view returns (uint256);

  function reserve1() external view returns (uint256);

  function setFee(uint256 newFee) external;

  function setNewRegistryAddress(address newAddress) external;

  function swap(address _tokenIn, uint256 _amountOut, uint256 _minAmountOut) external returns (uint256);

  function swapAmountOut(address _tokenIn, uint256 _amountOut, uint256 _amountInMax) external returns (uint256);

  function convertAmtEstim(address _tokenIn, address _tokenOut, uint256 _amountOut) external view returns (uint256);

  function swapPermit(
    address _tokenIn,
    uint256 _amountIn,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (bool);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "./PairSwap.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../events/interfaces/IStableSwapEvent.sol";
import "../registry/interface/IAddressRegistry.sol";

/**
 * PAF01: Parameters cannot be null
 * PAF02: Cannot set same value
 */

contract PairFactory {
  address private _addressRegistry;
  address private _implementation;
  uint256 private _baseFee;
  bytes32 public constant SWAP_ADMINISTRATOR_ROLE = keccak256("SWAP_ADMINISTRATOR_ROLE");

  event PairSwapDeployed(address pairAddr);
  event SetNewImplementation(address newImpl);
  event RegistryAddressUpdated(address newAddr);

  mapping(bytes32 => address) pairSwap;

  constructor(address addressRegistry_, address implementation_, uint256 fee_) {
    _addressRegistry = addressRegistry_;
    _implementation = implementation_;
    _baseFee = fee_;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  function createPair(
    address token0,
    address token1
  ) external onlyRole(SWAP_ADMINISTRATOR_ROLE) returns (address cloneAddr) {
    require(token0 != address(0) && token1 != address(0), "PAF01");
    cloneAddr = Clones.clone(_implementation);
    PairSwap(cloneAddr).__PairSwap_init(_addressRegistry, token0, token1, _baseFee);
    bytes32 concat = keccak256(abi.encodePacked(token0, token1));
    bytes32 inverse = keccak256(abi.encodePacked(token1, token0));
    pairSwap[concat] = cloneAddr;
    pairSwap[inverse] = cloneAddr;
    address eventAddr = IAddressRegistry(_addressRegistry).getStableSwapEvent();
    IStableSwapEvent(eventAddr).setPairExists(cloneAddr);
    emit PairSwapDeployed(address(cloneAddr));
    return address(cloneAddr);
  }

  // ---- Setters ---- //

  function setNewImplementation(address newImpl) public onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    require(newImpl != _implementation, "PAF02");
    _implementation = newImpl;
    emit SetNewImplementation(newImpl);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != _addressRegistry);
    _addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  // ---- Getters ---- //

  function getPairAddress(address token0, address token1) public view returns (address) {
    bytes32 concat = keccak256(abi.encodePacked(token0, token1));
    return pairSwap[concat];
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getTokenRegAddr();
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../registry/interface/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../events/interfaces/IStableSwapEvent.sol";

// debug
import "hardhat/console.sol";

contract PairSwap is Initializable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20Permit;
  using SafeERC20 for IERC20;

  using SafeMath for uint256;

  address registryAddress;
  address public token0;
  address public token1;

  uint256 public reserve0;
  uint256 public reserve1;
  uint256 public fee;

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;

  bytes32 public constant SWAP_ADMINISTRATOR_ROLE = keccak256("SWAP_ADMINISTRATOR_ROLE");

  event SetNewFee(address pair, uint256 fee);
  event RegistryAddressUpdated(address newAddr);

  event AddLiquidity(address sender, address token, uint256 amount);

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  function __PairSwap_init(
    address addressRegistry_,
    address token0_,
    address token1_,
    uint256 fee_
  ) public initializer {
    registryAddress = addressRegistry_;
    require(_isFactory(msg.sender), "PairSwap: Initializer is not factory");
    token0 = token0_;
    token1 = token1_;
    fee = fee_;
  }

  function swapAmountOutPermit(
    address _tokenIn,
    uint256 _amountOut,
    uint256 _amountInMax,
    uint256 approvedAmt,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused returns (uint256) {
    IERC20Permit(_tokenIn).safePermit(msg.sender, address(this), approvedAmt, deadline, v, r, s);
    return swapAmountOut(_tokenIn, _amountOut, _amountInMax);
  }

  function swapPermit(
    address _tokenIn,
    uint256 _amountIn,
    uint256 _amountOutMin,
    uint256 approvedAmt,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused returns (uint256) {
    IERC20Permit(_tokenIn).safePermit(msg.sender, address(this), approvedAmt, deadline, v, r, s);
    return swap(_tokenIn, _amountIn, _amountOutMin);
  }

  function swapAmountOut(
    address _tokenIn,
    uint256 _amountOut,
    uint256 _amountInMax
  ) public whenNotPaused returns (uint256) {
    require(_tokenIn == token0 || _tokenIn == token1, "PairSwap: Invalid token");
    require(_amountOut > 0, "PairSwap: Invalid amount");

    bool isToken0 = _tokenIn == token0;
    (address tokenIn, address tokenOut, uint256 resIn, uint256 resOut) = isToken0
      ? (token0, token1, reserve0, reserve1)
      : (token1, token0, reserve1, reserve0);
    uint256 initialBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 requiredAmt = getRequiredAmtOfTokensFor(tokenOut, _amountOut);
    require(_amountInMax >= requiredAmt, "PairSwap: Insufficient amountInMax");
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), requiredAmt);
    uint256 newBalance = IERC20(tokenIn).balanceOf(address(this));
    require(newBalance.sub(initialBalance) == requiredAmt, "PairSwap: Transfer failed");

    uint256 res0 = isToken0 ? resIn.add(requiredAmt) : resOut.sub(_amountOut);
    uint256 res1 = isToken0 ? resOut.sub(_amountOut) : resIn.add(requiredAmt);

    _update(res0, res1);
    IERC20(tokenOut).safeTransfer(msg.sender, _amountOut);

    address ev = getEventAddr();
    IStableSwapEvent(ev).swapEvent(msg.sender, tokenIn, tokenOut, requiredAmt, _amountOut);
    return _amountOut;
  }

  function swap(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) public whenNotPaused returns (uint256) {
    require(_tokenIn == token0 || _tokenIn == token1, "Invalid token");
    require(_amountIn > 0, "Invalid amount");
    uint256 liquidity = getLiquidityTokenFor(_tokenIn);
    require(_amountIn <= liquidity, "Insufficient liquidity");

    bool isToken0 = _tokenIn == token0;
    (address tokenIn, address tokenOut, uint256 resIn, uint256 resOut) = isToken0
      ? (token0, token1, reserve0, reserve1)
      : (token1, token0, reserve1, reserve0);
    uint256 initialBalance = IERC20(tokenIn).balanceOf(address(this));
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
    uint256 newBalance = IERC20(tokenIn).balanceOf(address(this));
    require(newBalance - initialBalance == _amountIn, "Transfer failed");
    uint256 amountOut = convertAmtEstim(tokenIn, tokenOut, _amountIn);
    require(amountOut >= _amountOutMin, "PairSwap: Expected amount is less than minAmountOut ");

    uint256 res0 = isToken0 ? resIn.add(_amountIn) : resOut.sub(amountOut);
    uint256 res1 = isToken0 ? resOut.sub(amountOut) : resIn.add(_amountIn);

    _update(res0, res1);
    IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

    address ev = getEventAddr();
    IStableSwapEvent(ev).swapEvent(msg.sender, tokenIn, tokenOut, _amountIn, amountOut);
    return amountOut;
  }

  // ---- Add liquidity ---- //
  function addLiquidity(uint256 _amount, bool _isToken0) public whenNotPaused nonReentrant returns (uint256 shares) {
    require(_amount > 0, "_amount must be greater than 0");
    address token = _isToken0 ? token0 : token1;
    IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 bal0 = IERC20(token0).balanceOf(address(this));
    uint256 bal1 = IERC20(token1).balanceOf(address(this));
    uint256 reserveSum = reserve0.add(reserve1);

    if (totalSupply > 0) {
      shares = (_amount.mul(totalSupply)).div(reserveSum);
    } else {
      shares = _amount;
    }
    require(shares > 0, "shares = 0");
    _mint(msg.sender, shares);
    _update(bal0, bal1);
    emit AddLiquidity(msg.sender, token, _amount);
  }

  function addLiquidityPermit(
    uint256 _amount,
    bool _isToken0,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external whenNotPaused nonReentrant returns (uint256 shares) {
    address token = _isToken0 ? token0 : token1;
    IERC20Permit(token).safePermit(msg.sender, address(this), _amount, deadline, v, r, s);
    return addLiquidity(_amount, _isToken0);
  }

  function removeLiquidity(
    uint256 _shares,
    address _token
  ) external whenNotPaused nonReentrant returns (uint256 amount) {
    require(_shares > 0, "_shares must be greater than 0");
    require(_token == address(token0) || _token == address(token1), "invalid token");

    uint256 _totalSupply = totalSupply;
    uint256 _reserve0 = reserve0;
    uint256 _reserve1 = reserve1;
    bool isToken0 = _token == address(token0);

    uint256 _bal = isToken0 ? _reserve0 : _reserve1;
    amount = (_bal.mul(_shares)).div(_totalSupply);

    _burn(msg.sender, _shares);

    uint256 newReserve0 = isToken0 ? _reserve0.sub(amount) : _reserve0;
    uint256 newReserve1 = !isToken0 ? _reserve1.sub(amount) : _reserve1;
    _update(newReserve0, newReserve1);

    IERC20(_token).safeTransfer(msg.sender, amount);
  }

  // ---- Admin ---- //

  function setFee(uint256 newFee) public onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    require(newFee != fee, "PairSwap: New fee should be different");
    fee = newFee;
    emit SetNewFee(address(this), newFee);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != registryAddress);
    registryAddress = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function pause() external whenNotPaused onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    _pause();
  }

  function unPause() external whenPaused onlyRole(SWAP_ADMINISTRATOR_ROLE) {
    _unpause();
  }

  // ---- Getters ---- //

  function convertAmtEstim(address tokenIn, address tokenOut, uint256 amtIn) public view returns (uint256 amountOut) {
    uint256 price = getPriceFor(tokenIn, tokenOut);
    (uint256 tokenInDecimals, uint256 tokenOutDecimals) = (getDecimal(tokenIn), getDecimal(tokenOut));
    uint256 amount = (amtIn.mul(price).div(10 ** 8));
    amount -= _getFeeAmount(amount);
    if (tokenInDecimals == tokenOutDecimals) {
      return amount;
    } else {
      if (tokenInDecimals > tokenOutDecimals) {
        return amount.div(10 ** (tokenInDecimals - tokenOutDecimals));
      } else {
        return amount.mul(10 ** (tokenOutDecimals - tokenInDecimals));
      }
    }
  }

  function getRequiredAmtOfTokensFor(
    address _tokenOut,
    uint256 amountRequested
  ) public view returns (uint256 amountIn) {
    bool isToken0 = _tokenOut == token1;
    (address tokenIn, address tokenOut) = isToken0 ? (token0, token1) : (token1, token0);
    (uint256 tokenInDecimals, uint256 tokenOutDecimals) = (getDecimal(tokenIn), getDecimal(tokenOut));
    uint256 price = getPriceFor(tokenIn, tokenOut);
    uint256 amount = (amountRequested * 10 ** 8).div(price);
    amount += _getFeeAmount(amount);
    if (tokenInDecimals == tokenOutDecimals) {
      return amount;
    } else {
      if (tokenInDecimals > tokenOutDecimals) {
        return amount.mul(10 ** (tokenOutDecimals - tokenInDecimals));
      } else {
        return amount.div(10 ** (tokenOutDecimals - tokenInDecimals));
      }
    }
  }

  function getLiquidityTokenFor(address _tokenIn) public view returns (uint256) {
    return IERC20(_tokenIn).balanceOf(address(this));
  }

  // ---- Getters address ---- //

  function getEventAddr() public view returns (address) {
    return IAddressRegistry(registryAddress).getStableSwapEvent();
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(registryAddress).getRoleRegAddr();
  }

  function getPriceFeedAddr() public view returns (address) {
    return IAddressRegistry(registryAddress).getPriceFeedAddr();
  }

  // --- internal ---- //

  function getPriceFor(address tokenIn, address tokenOut) internal view returns (uint256) {
    address _priceFeedAddress = getPriceFeedAddr();
    return IPriceFeed(_priceFeedAddress).getLatestPrice(tokenIn, tokenOut);
  }

  // ---- Utils function ---- //

  function _getFeeAmount(uint256 amount) internal view returns (uint256) {
    return (amount * fee) / 10000;
  }

  function getDecimal(address token) internal view returns (uint) {
    return IERC20Metadata(token).decimals();
  }

  function _isFactory(address sender) internal view returns (bool) {
    return sender == IAddressRegistry(registryAddress).getPairFactoryAddr();
  }

  // ---- Private function ---- //

  function _mint(address _to, uint256 _amount) private {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
  }

  function _burn(address _from, uint256 _amount) private {
    balanceOf[_from] -= _amount;
    totalSupply -= _amount;
  }

  function _update(uint256 _res0, uint256 _res1) private {
    reserve0 = _res0;
    reserve1 = _res1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract CHF is ERC20, ERC20Permit {
  constructor(address[] memory acc, uint256 length) ERC20("CHF", "CHF") ERC20Permit("CHF") {
    for (uint i = 0; i <= length; ) {
      _mint(acc[i], 10000000 * 10 ** decimals());
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract EUR is ERC20, ERC20Permit {
  constructor(address[] memory acc, uint256 length) ERC20("EUR", "EUR") ERC20Permit("EUR") {
    for (uint i = 0; i <= length; ) {
      _mint(acc[i], 10000000 * 10 ** decimals());
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract USD is ERC20, ERC20Permit {
  constructor(address[] memory acc, uint256 length) ERC20("USD", "USD") ERC20Permit("USD") {
    for (uint i = 0; i <= length; ) {
      _mint(acc[i], 10000000 * 10 ** decimals());
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract USDT is ERC20, ERC20Permit {
  constructor(address[] memory acc, uint256 length) ERC20("USDT", "USDT") ERC20Permit("USDT") {
    for (uint i = 0; i <= length; ) {
      _mint(acc[i], 10000000 * 10 ** decimals());
      unchecked {
        ++i;
      }
    }
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./SecurityToken.sol";
import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * SEF01: Caller is missing role
 * SEF02: Value can't be null
 */
// debug
import "hardhat/console.sol";

contract SecurityFactory {
  address public addressRegistry;
  address private implementation;

  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");

  event TokenDeployed(address tokenAddress);
  event SetNewRegistryAddress(address registryAddress);
  event SetNewTokenImplementation(address implementationAddress);

  constructor(address addressRegistry_, address implementation_) {
    addressRegistry = addressRegistry_;
    implementation = implementation_;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  function createSecurityToken(
    string calldata _name,
    string calldata _symbol,
    string calldata _docUUID
  ) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) returns (address cloneAddr) {
    require(
      keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")) &&
        keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("")) &&
        keccak256(abi.encodePacked(_docUUID)) != keccak256(abi.encodePacked("")),
      "SEF02"
    );
    address _tokenRegistry = getTokenRegAddr();
    cloneAddr = Clones.clone(implementation);
    SecurityToken(cloneAddr).__SecurityToken_init(addressRegistry, _name, _symbol, _docUUID);
    ITokenRegistry(_tokenRegistry).add(address(cloneAddr), false);
    emit TokenDeployed(address(cloneAddr));
    return address(cloneAddr);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit SetNewRegistryAddress(newAddress);
  }

  function setNewTokenImplementation(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != implementation);
    implementation = newAddress;
    emit SetNewTokenImplementation(newAddress);
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getTokenImplementationAddr() public view onlyRole(TOKEN_ADMINISTRATOR_ROLE) returns (address) {
    return implementation;
  }

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getTokenRegAddr();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";
import "../events/interfaces/ISettlementEvent.sol";
// debug
import "hardhat/console.sol";
import { ItMapHolder } from "./utils/ItMapHolder.sol";

contract SecurityToken is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  ERC20PermitUpgradeable
{
  using SafeERC20 for IERC20;
  using ItMapHolder for ItMapHolder.HolderMap;

  ItMapHolder.HolderMap private holderMap;

  string[] _docUUID;
  address internal _addressRegistry;
  uint256 public excludeFromSettlementValue;

  mapping(address => bool) excludedFromSettlement;
  mapping(string => Document) internal _documents;
  mapping(string => uint32) internal _docIndexes;

  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");
  bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

  event DistributeDividends(address[] holders, uint256[] amount);
  event DocumentRemoved(string _uuid);
  event DocumentUpdated(string _uuid);
  event SetNewRegistryAddress(address newAddress);
  event EmergencyWithdrawal(uint256 val);
  event RedeemAll();
  event ExcludeFromDividend(address account);
  event IncludeInDividends(address account);

  struct Document {
    uint32 docIndex;
    uint64 lastModified;
    string uri;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(_addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  function __SecurityToken_init(
    address addressRegistry_,
    string memory name_,
    string memory symbol_,
    string memory docUUID_
  ) public initializer {
    _addressRegistry = addressRegistry_;
    require(_isFactory(msg.sender), "SecurityToken: initializer != factory");
    __ERC20_init(name_, symbol_);
    __ERC20Burnable_init();
    __Pausable_init();
    __ERC20Permit_init(name_);
    _setDocument(docUUID_);
  }

  function mint(address to, uint256 amount) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _mint(to, amount);
  }

  function burn(address to, uint256 amount) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _burn(to, amount);
  }

  function pause() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _unpause();
  }

  function redeemOne(address _account, address _dest) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    uint256 balance = this.balanceOf(_account);
    require(balance > 0, "Balance is 0");
    _transfer(_account, _dest, balance);
  }

  function redeemAll(
    uint256 _startIndex,
    uint256 _endIndex,
    address _dest
  ) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    uint256 maxIndex = holderMap.holderSize() - 1;

    if (_endIndex > maxIndex) _endIndex = maxIndex;
    require(_startIndex <= maxIndex, "Start index exceeds the total number of investors");
    require(_startIndex <= _endIndex, "Start index greater than end");

    for (uint256 i = _startIndex; i <= _endIndex; i++) {
      address key = holderMap.getAddressAtIndex(i);
      uint256 balance = holderMap.getBalanceOf(key);
      _transfer(key, _dest, balance);
    }
    emit RedeemAll();
  }

  function distributeSettlement(
    uint256 _startIndex,
    uint256 _endIndex,
    uint256 totalSettlementVal
  ) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) whenPaused {
    require(totalSettlementVal > 0, "Settlement value is zero");

    uint256 maxIndex = getTotalInvestors() - 1;

    if (_endIndex > maxIndex) _endIndex = maxIndex;

    require(_startIndex <= maxIndex, "Start index exceeds the total number of investors");
    require(_startIndex <= _endIndex, "Start index greater than end");

    address[] memory investorsAddress = new address[](_endIndex - _startIndex + 1);
    uint256[] memory settlementValues = new uint256[](_endIndex - _startIndex + 1);

    uint256 totalSupply = getEligibleToDividendSupply();

    uint256 startIndex = _startIndex;

    address settlementToken = getSettlementTokenAddress();

    for (uint256 i = startIndex; i <= _endIndex; i++) {
      address key = holderMap.getAddressAtIndex(i);
      if (!excludedFromSettlement[key]) {
        uint256 balance = holderMap.getBalanceOf(key);
        uint256 value = (balance * totalSettlementVal) / totalSupply;
        IERC20(settlementToken).safeTransfer(key, value);
        investorsAddress[i - startIndex] = key;
        settlementValues[i - startIndex] = value;
      }
    }
    address eventAddr = IAddressRegistry(_addressRegistry).getSettlementEventAddr();
    ISettlementEvent(eventAddr).settlementDistribution(settlementToken, investorsAddress, settlementValues);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != _addressRegistry);
    _addressRegistry = newAddress;
    emit SetNewRegistryAddress(newAddress);
  }

  function setDocument(string calldata _UUID) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _setDocument(_UUID);
  }

  function removeDocument(string calldata _UUID) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(_documents[_UUID].lastModified != uint64(0), "Document should exist");
    uint32 index = _documents[_UUID].docIndex - 1;
    if (index != _docUUID.length - 1) {
      _docUUID[index] = _docUUID[_docUUID.length - 1];
      _documents[_docUUID[index]].docIndex = index + 1;
    }
    _docUUID.pop();
    emit DocumentRemoved(_documents[_UUID].uri);
    delete _documents[_UUID];
  }

  function excludeFromDividend(address account) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(!excludedFromSettlement[account], "Account is excludedFromSettlement");
    excludedFromSettlement[account] = true;
    uint256 bal = this.balanceOf(account);
    excludeFromSettlementValue += bal;
    emit ExcludeFromDividend(account);
  }

  function includeInDividends(address account) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(excludedFromSettlement[account], "Account is not excludedFromSettlement");
    excludedFromSettlement[account] = false;
    uint256 bal = this.balanceOf(account);
    excludeFromSettlementValue -= bal;
    emit IncludeInDividends(account);
  }

  function emergencyWithdrawSettlement() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    address settlement = getSettlementTokenAddress();
    uint256 balance = IERC20(settlement).balanceOf(address(this));
    require(balance != 0, "No token in contract");
    IERC20(settlement).safeTransfer(msg.sender, balance);
    emit EmergencyWithdrawal(balance);
  }

  // -----------------------------------------
  // withdraw Stuck Tokens
  // -----------------------------------------

  function withdrawStuckMATIC() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(address(this).balance > 0, "withdrawStuckMATIC: There are no ETH in the contract");
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawStuckERC20Tokens(address token, address to) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(IERC20(token).balanceOf(address(this)) > 0, "stuckErc20Tokens: There are no tokens in the contract");
    require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
  }

  // -----------------------------------------
  // Getters
  // -----------------------------------------

  function getDocument(string calldata _UUID) external view returns (string memory, uint256) {
    return (_documents[_UUID].uri, uint256(_documents[_UUID].lastModified));
  }

  function getAllDocuments() external view returns (string[] memory) {
    return _docUUID;
  }

  function getDocumentCount() external view returns (uint256) {
    return _docUUID.length;
  }

  function getDocumentName(uint256 _index) external view returns (string memory) {
    require(_index < _docUUID.length, "Index out of bounds");
    return _docUUID[_index];
  }

  function getBalanceOf(address _account) public view returns (uint256) {
    return holderMap.getBalanceOf(_account);
  }

  function getTotalInvestors() public view returns (uint256) {
    return holderMap.holderSize();
  }

  function getEligibleToDividendSupply() public view returns (uint256) {
    uint256 ts = this.totalSupply();
    return ts - excludeFromSettlementValue;
  }

  function getHoldersArr() public view returns (address[] memory) {
    return holderMap.getArr();
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getSettlementTokenAddress() public view returns (address) {
    address registry = IAddressRegistry(_addressRegistry).getTokenRegAddr();
    return ITokenRegistry(registry).getSettlementAddr();
  }

  // -----------------------------------------
  // Internal function
  // -----------------------------------------

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable) whenNotPaused {
    address _roleAddress = IAddressRegistry(_addressRegistry).getRoleRegAddr();
    bool isBlocklisted = IAccessControl(_roleAddress).hasRole(BLOCKLISTED_ROLE, from);
    bool isAdmin = IAccessControl(_roleAddress).hasRole(TOKEN_ADMINISTRATOR_ROLE, to);

    require(!isBlocklisted || (isBlocklisted && isAdmin), "Blocklisted");
    super._beforeTokenTransfer(from, to, amount);
    // update balance
    if (from == address(0)) {
      // mint
      // update to
      if (excludedFromSettlement[to]) {
        excludeFromSettlementValue += amount;
      }
    } else if (to == address(0)) {
      // burn
      // update from
      if (excludedFromSettlement[from]) {
        excludeFromSettlementValue -= amount;
      }
    } else {
      // transfer
      if (excludedFromSettlement[from] && !excludedFromSettlement[to]) {
        excludeFromSettlementValue -= amount;
      }
      if (!excludedFromSettlement[from] && excludedFromSettlement[to]) {
        excludeFromSettlementValue += amount;
      }
    }
  }

  function _afterTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
    super._afterTokenTransfer(from, to, amount);
    if (from == address(0)) {
      // mint
      // update to
      uint256 balReceiver = this.balanceOf(to);
      balReceiver == 0 ? _remove(to) : _updateBalance(to, balReceiver);
    } else if (to == address(0)) {
      // burn
      // update from
      uint256 balSender = this.balanceOf(from);
      balSender == 0 ? _remove(from) : _updateBalance(from, balSender);
    } else {
      // transfer
      uint256 balSender = this.balanceOf(from);
      uint256 balReceiver = this.balanceOf(to);
      balSender == 0 ? _remove(from) : _updateBalance(from, balSender);
      balReceiver == 0 ? _remove(to) : _updateBalance(to, balReceiver);
    }
  }

  function _updateBalance(address account, uint256 amount) internal {
    holderMap.updateBalance(account, amount);
  }

  function _remove(address account) internal {
    holderMap.remove(account);
  }

  function _setDocument(string memory _UUID) internal {
    require(bytes(_UUID).length > 0, "Should not be a empty uri");
    if (_documents[_UUID].lastModified == uint64(0)) {
      _docUUID.push(_UUID);
      _documents[_UUID].docIndex = uint32(_docUUID.length);
    }
    _documents[_UUID] = Document(_documents[_UUID].docIndex, uint64(block.timestamp), _UUID);
    emit DocumentUpdated(_UUID);
  }

  function _isFactory(address sender) internal view returns (bool) {
    return sender == IAddressRegistry(_addressRegistry).getTokenFactAddr();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import { ItMapHolder } from "./utils/ItMapHolder.sol";

contract SettlementToken is ERC20, ERC20Permit, ERC20Burnable, Pausable {
  using ItMapHolder for ItMapHolder.HolderMap;

  ItMapHolder.HolderMap private holderMap;
  address private _addressRegistry;

  bytes32 public constant TOKEN_ADMINISTRATOR_ROLE = keccak256("TOKEN_ADMINISTRATOR_ROLE");
  bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

  event RegistryAddressUpdated(address newAddress);
  event RedeemAll();

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address addressRegistry_
  ) ERC20(name_, symbol_) ERC20Permit(name_) {
    _addressRegistry = addressRegistry_;
  }

  function mint(address to, uint256 amount) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _mint(to, amount);
  }

  function pause() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    _unpause();
  }

  function redeemOne(address _account, address _dest) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    uint256 balance = this.balanceOf(_account);
    require(balance > 0, "Balance is 0");
    _transfer(_account, _dest, balance);
  }

  function redeemAll(
    uint256 _startIndex,
    uint256 _endIndex,
    address _dest
  ) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    uint256 maxIndex = holderMap.holderSize() - 1;

    if (_endIndex > maxIndex) _endIndex = maxIndex;
    require(_startIndex <= maxIndex, "Start index exceeds the total number of investors");
    require(_startIndex <= _endIndex, "Start index greater than end");

    for (uint256 i = _startIndex; i <= _endIndex; i++) {
      address key = holderMap.getAddressAtIndex(i);
      uint256 balance = holderMap.getBalanceOf(key);
      _transfer(key, _dest, balance);
    }
    emit RedeemAll();
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != _addressRegistry);
    _addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  // -----------------------------------------
  // withdraw Stuck Tokens
  // -----------------------------------------

  function withdrawStuckMATIC() external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(address(this).balance > 0, "withdrawStuckMATIC: There are no ETH in the contract");
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawStuckERC20Tokens(address token, address to) external onlyRole(TOKEN_ADMINISTRATOR_ROLE) {
    require(IERC20(token).balanceOf(address(this)) > 0, "stuckErc20Tokens: There are no tokens in the contract");
    require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
  }

  function getBalanceOf(address _account) public view returns (uint256) {
    return holderMap.getBalanceOf(_account);
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
    address roleAddr = getRoleAddr();
    bool isBlocklisted = IAccessControl(roleAddr).hasRole(BLOCKLISTED_ROLE, from);
    bool isAdmin = IAccessControl(roleAddr).hasRole(TOKEN_ADMINISTRATOR_ROLE, to);
    require(!isBlocklisted || (isBlocklisted && isAdmin), "Blocklisted");
    super._beforeTokenTransfer(from, to, amount);
  }

  function _afterTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
    super._afterTokenTransfer(from, to, amount);
    if (from == address(0)) {
      // mint
      // update to
      uint256 balReceiver = this.balanceOf(to);
      balReceiver == 0 ? _remove(to) : _updateBalance(to, balReceiver);
    } else if (to == address(0)) {
      // burn
      // update from
      uint256 balSender = this.balanceOf(from);
      balSender == 0 ? _remove(from) : _updateBalance(from, balSender);
    } else {
      // transfer
      uint256 balSender = this.balanceOf(from);
      uint256 balReceiver = this.balanceOf(to);
      balSender == 0 ? _remove(from) : _updateBalance(from, balSender);
      balReceiver == 0 ? _remove(to) : _updateBalance(to, balReceiver);
    }
  }

  function _updateBalance(address account, uint256 amount) internal {
    holderMap.updateBalance(account, amount);
  }

  function _remove(address account) internal {
    holderMap.remove(account);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

library ItMapHolder {
  struct HolderMap {
    address[] keys;
    mapping(address => uint256) balance;
    mapping(address => uint256) indexOf;
  }

  function updateBalance(HolderMap storage map, address key, uint256 balance) external {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
      }
    }
    map.balance[key] = balance;
  }

  function remove(HolderMap storage map, address key) public {
    delete map.balance[key];
    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];
    map.indexOf[lastKey] = index;
    delete map.indexOf[key];
    map.keys[index] = lastKey;
    map.keys.pop();
  }

  function getArr(HolderMap storage map) external view returns (address[] memory) {
    return map.keys;
  }

  function getBalanceOf(HolderMap storage map, address key) external view returns (uint256) {
    return map.balance[key];
  }

  function getAddressAtIndex(HolderMap storage map, uint256 index) external view returns (address) {
    return map.keys[index];
  }

  function holderSize(HolderMap storage map) external view returns (uint256) {
    return map.keys.length;
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

// debug
import "hardhat/console.sol";

import "./types/CappedCrowdsale.sol";
import "./types/UncappedCrowdsale.sol";
import "./types/BatchDrivenCrowdsale.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/ICrowdsaleConfig.sol";
import "../registry/interface/IAddressRegistry.sol";
import { ItMapSale } from "./utils/ItMapSale.sol";

/**
 * CRF01: Cannot be null / equal to zero
 * CRF02: Inversion
 * CRF03: Same address
 */

contract CrowdsaleFactory is ICrowdsaleConfig {
  using ItMapSale for ItMapSale.SaleMap;

  ItMapSale.SaleMap private saleMap;

  bytes32 public constant CROWDSALE_ADMINISTRATOR_ROLE = keccak256("CROWDSALE_ADMINISTRATOR_ROLE");

  address public addressRegistry;

  address public beneficiary;

  address private _cappedImpl;
  address private _uncappedImpl;
  address private _batchImpl;

  event CrowdsaleCreated(string classType, address indexed crowdsaleAddress);
  event SetNewCappedImpl(address newImpl);
  event SetNewUnCappedImpl(address newImpl);
  event SetNewBatchedImpl(address newImpl);
  event SetNewBeneficiary(address newAddress);

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = IAddressRegistry(addressRegistry).getRoleRegAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  constructor(
    address addressRegistry_,
    address beneficiary_,
    address cappedImpl_,
    address uncappedImpl_,
    address batchImpl_
  ) {
    addressRegistry = addressRegistry_;
    beneficiary = beneficiary_;
    _cappedImpl = cappedImpl_;
    _uncappedImpl = uncappedImpl_;
    _batchImpl = batchImpl_;
  }

  function createCappedCrowdsale(
    address _token,
    address _crowdsaleCurrency,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _tokenPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _softcap,
    uint256 _hardcap
  ) public returns (address cloneAddr) {
    require(beneficiary != address(0), "Setting of beneficiary required");
    require(
      _token != address(0) &&
        _crowdsaleCurrency != address(0) &&
        _executionValueMin > 0 &&
        _maxTokenPerOrder > 0 &&
        _tokenPrice > 0 &&
        _startTime > 0 &&
        _endTime > 0 &&
        _softcap > 0 &&
        _hardcap > 0,
      "CreateCappedCrowdsale: Wrong param"
    );
    require(
      _executionValueMin < _maxTokenPerOrder && _startTime < _endTime && _softcap < _hardcap,
      "CreateCappedCrowdsale: Wrong param"
    );

    uint saleType = 0;
    uint256 executionValueMin = _convertInDecimal(_token, _executionValueMin);
    uint256 maxTokenPerOrder = _convertInDecimal(_token, _maxTokenPerOrder);
    uint256 softcap = _convertInDecimal(_token, _softcap);
    uint256 hardcap = _convertInDecimal(_token, _hardcap);

    CappedCrowdsaleConfig memory config = CappedCrowdsaleConfig(
      beneficiary,
      _token,
      _crowdsaleCurrency,
      addressRegistry,
      executionValueMin,
      maxTokenPerOrder,
      _tokenPrice,
      _startTime,
      _endTime,
      softcap,
      hardcap
    );
    cloneAddr = Clones.clone(_cappedImpl);
    CappedCrowdsale(cloneAddr).__CappedCrowdsale_init(config);
    saleMap.add(cloneAddr, _token, _crowdsaleCurrency, saleType);
    address eventAddr = getEventAddr();
    ICrowdsaleEvent(eventAddr).setCrowdsaleExists(cloneAddr);
    emit CrowdsaleCreated("CappedCrowdsale", cloneAddr);
    return cloneAddr;
  }

  function createUncappedCrowdsale(
    address _token,
    address _crowdsaleCurrency,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _tokenPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _hardcap
  ) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) returns (address cloneAddr) {
    require(beneficiary != address(0), "Setting of beneficiary required");
    require(
      _token != address(0) &&
        _crowdsaleCurrency != address(0) &&
        _executionValueMin > 0 &&
        _maxTokenPerOrder > 0 &&
        _tokenPrice > 0 &&
        _startTime > 0 &&
        _endTime > 0 &&
        _hardcap > 0,
      "CRF01"
    );
    require(_executionValueMin < _maxTokenPerOrder && _startTime < _endTime, "CRF02");

    uint saleType = 1;
    uint256 executionValueMin = _convertInDecimal(_token, _executionValueMin);
    uint256 maxTokenPerOrder = _convertInDecimal(_token, _maxTokenPerOrder);
    UncappedCrowdsaleConfig memory config = UncappedCrowdsaleConfig(
      beneficiary,
      _token,
      _crowdsaleCurrency,
      addressRegistry,
      executionValueMin,
      maxTokenPerOrder,
      _tokenPrice,
      _startTime,
      _endTime
    );
    cloneAddr = Clones.clone(_uncappedImpl);
    UncappedCrowdsale(cloneAddr).__UncappedCrowdsale_init(config);
    saleMap.add(cloneAddr, _token, _crowdsaleCurrency, saleType);
    address eventAddr = getEventAddr();
    ICrowdsaleEvent(eventAddr).setCrowdsaleExists(cloneAddr);
    emit CrowdsaleCreated("UncappedCrowdsale", cloneAddr);
    return cloneAddr;
  }

  function createBatchDrivenCrowdsale(
    address _token,
    address _crowdsaleCurrency,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _tokenPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _batchSize,
    uint256 _numberOfBatch
  ) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) returns (address cloneAddr) {
    require(beneficiary != address(0), "Setting of beneficiary required");
    require(
      _token != address(0) &&
        _crowdsaleCurrency != address(0) &&
        _executionValueMin > 0 &&
        _maxTokenPerOrder > 0 &&
        _tokenPrice > 0 &&
        _startTime > 0 &&
        _endTime > 0 &&
        _batchSize > 0 &&
        _numberOfBatch > 0,
      "CRF01"
    );
    require(_executionValueMin < _maxTokenPerOrder, "CRF02");

    uint saleType = 2;
    uint256 executionValueMin = _convertInDecimal(_token, _executionValueMin);
    uint256 maxTokenPerOrder = _convertInDecimal(_token, _maxTokenPerOrder);
    BatchDrivenCrowdsaleConfig memory config = BatchDrivenCrowdsaleConfig(
      beneficiary,
      _token,
      _crowdsaleCurrency,
      addressRegistry,
      executionValueMin,
      maxTokenPerOrder,
      _tokenPrice,
      _startTime,
      _endTime,
      _batchSize,
      _numberOfBatch
    );
    cloneAddr = Clones.clone(_batchImpl);
    BatchDrivenCrowdsale(cloneAddr).__BatchDrivenCrowdsale_init(config);
    saleMap.add(cloneAddr, _token, _crowdsaleCurrency, saleType);
    address eventAddr = getEventAddr();
    ICrowdsaleEvent(eventAddr).setCrowdsaleExists(cloneAddr);
    emit CrowdsaleCreated("BatchDrivenCrowdsale", address(cloneAddr));
    return cloneAddr;
  }

  // -----------------------------------------
  // Setters implementation
  // -----------------------------------------

  function setNewBeneficiary(address newAddress) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newAddress != beneficiary, "CRF03");
    beneficiary = newAddress;
    emit SetNewBeneficiary(newAddress);
  }

  function setNewCappedImpl(address newImpl) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newImpl != _cappedImpl, "CRF03");
    _cappedImpl = newImpl;
    emit SetNewCappedImpl(newImpl);
  }

  function setNewUnCappedImpl(address newImpl) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newImpl != _uncappedImpl, "CRF03");
    _uncappedImpl = newImpl;
    emit SetNewUnCappedImpl(newImpl);
  }

  function setNewBatchedImpl(address newImpl) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newImpl != _batchImpl, "CRF03");
    _batchImpl = newImpl;
    emit SetNewBatchedImpl(newImpl);
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getEventAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getCrowdsaleEventAddr();
  }

  function getPriceFeedAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getPriceFeedAddr();
  }

  function saleExists(address key) public view returns (bool) {
    return saleMap.saleExists(key);
  }

  // -----------------------------------------
  // Util
  // -----------------------------------------

  function _convertInDecimal(address _token, uint256 _val) internal view returns (uint256) {
    return _val * 10 ** IERC20Metadata(_token).decimals();
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ICrowdsaleConfig {
  struct CappedCrowdsaleConfig {
    address beneficiary;
    address tokenAddress;
    address crowdsaleCurrency;
    address addressRegistry;
    uint256 executionValueMin;
    uint256 maxTokenPerOrder;
    uint256 tokenPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 softcap;
    uint256 hardcap;
  }

  struct UncappedCrowdsaleConfig {
    address beneficiary;
    address tokenAddress;
    address crowdsaleCurrency;
    address addressRegistry;
    uint256 executionValueMin;
    uint256 maxTokenPerOrder;
    uint256 tokenPrice;
    uint256 startTime;
    uint256 endTime;
  }

  struct BatchDrivenCrowdsaleConfig {
    address beneficiary;
    address tokenAddress;
    address crowdsaleCurrency;
    address addressRegistry;
    uint256 executionValueMin;
    uint256 maxTokenPerOrder;
    uint256 tokenPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 batchSize;
    uint256 numberOfBatch;
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ICrowdsaleFactory {
  function CROWDSALE_ADMINISTRATOR_ROLE() external view returns (bytes32);

  function batchDrivenCrowdsales(
    address
  )
    external
    view
    returns (
      address tokenAddress,
      address rolesAddress,
      address eventAddress,
      uint256 executionValueMin,
      uint256 maxTokenPerOrder,
      uint256 rate,
      uint256 batchSize
    );

  function cappedCrowdsales(
    address
  )
    external
    view
    returns (
      address tokenAddress,
      address rolesAddress,
      address eventAddress,
      uint256 executionValueMin,
      uint256 maxTokenPerOrder,
      uint256 rate,
      uint256 startTime,
      uint256 endTime,
      uint256 softcap,
      uint256 hardcap
    );

  function createBatchDrivenCrowdsale(
    address _token,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _rate,
    uint256 _batchSize
  ) external returns (address cloneAddr);

  function createCappedCrowdsale(
    address _token,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _rate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _softcap,
    uint256 _hardcap
  ) external returns (address cloneAddr);

  function createUncappedCrowdsale(
    address _token,
    uint256 _executionValueMin,
    uint256 _maxTokenPerOrder,
    uint256 _rate,
    uint256 _startTime,
    uint256 _endTime
  ) external returns (address cloneAddr);

  function getRolesAddress() external view returns (address);

  function setRolesAddress(address _addr) external;

  function uncappedCrowdsales(
    address
  )
    external
    view
    returns (
      address tokenAddress,
      address rolesAddress,
      address eventAddress,
      uint256 executionValueMin,
      uint256 maxTokenPerOrder,
      uint256 rate,
      uint256 startTime,
      uint256 endTime
    );

  function saleExists(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20Permit {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../registry/interface/ITokenRegistry.sol";
import "../../../registry/interface/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../../events/interfaces/ICrowdsaleEvent.sol";
import "../../../oracle/interfaces/IPriceFeed.sol";
import "../../../registry/interface/IUserRegistry.sol";
import "../../../stableSwap/interfaces/IPairFactory.sol";
import "../../../stableSwap/interfaces/IPairSwap.sol";
// debug
import "hardhat/console.sol";

/**
 * todo: refactor
 * CRW01: Value can't be null nor equal to zero
 * CRW02: New value equal to old value
 */
contract Crowdsale is Pausable, Initializable, ReentrancyGuard {
  using SafeERC20 for IERC20Permit;
  using SafeERC20 for IERC20;

  using SafeMath for uint256;

  address public beneficiary;
  address public securityTokenAddress;
  address public baseCurrency;
  address public addressRegistry;

  uint256 public executionValueMin;
  uint256 public maxTokenPerOrder;
  uint256 public tokenPrice;
  uint256 public totalRaised;
  uint256 public totalTokensSold;
  uint256 public totalRefundedToken;

  uint public saleType;

  bytes32 public constant CROWDSALE_ADMINISTRATOR_ROLE = keccak256("CROWDSALE_ADMINISTRATOR_ROLE");

  event TokenAddressUpdated(address newAddress);
  event RolesAddressUpdated(address newAddress);
  event RegistryAddressUpdated(address newAddress);
  event BeneficiaryUpdated(address newAddress);
  event RemoveInvestment(address sale, address investor);

  // ---- Crowdsale ---- //

  event MinPurchaseUpdated(uint256 newVal);
  event MaxPurchaseUpdated(uint256 newVal);
  event TokenPriceUpdated(address crowdsale, address token, uint256 newVal);

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  struct Contribution {
    bytes32 id;
    address investor;
    uint256 buyAmt;
    uint256 paidAmt;
  }

  mapping(address => uint256) contributionIndex;

  Contribution[] public contributions;

  function buyTokensPermit(
    address investor,
    address paymentToken,
    uint256 purchasedAmount,
    uint256 approvedAmt,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external nonReentrant whenNotPaused {
    uint256 decimalPurchase = toDecimal(baseCurrency, purchasedAmount);

    _preValidatePurchase(investor, paymentToken, purchasedAmount);

    bytes32 id = _getIdByAddress(investor);

    uint256 requiredAmountToBePaid = _getFinalAmt(paymentToken, decimalPurchase); // convert in sale currency
    uint256 purchaseCost = decimalPurchase * tokenPrice;

    _remInvest(id, purchaseCost); // check rem' invest in KCHF
    _forwardFundsPermit(investor, paymentToken, purchaseCost, approvedAmt, deadline, v, r, s); // convert/take funds into this contract
    _processPurchase(investor, decimalPurchase); // process purchase
    _updateSaleStateAdd(decimalPurchase, purchaseCost); // update sale state
    _updateUserContribState(id, investor, decimalPurchase, purchaseCost); // update contrib
    _emitEvent(id, investor, paymentToken, decimalPurchase, requiredAmountToBePaid, purchaseCost);
  }

  function buyTokens(
    address investor,
    address paymentToken,
    uint256 purchasedAmount
  ) external nonReentrant whenNotPaused {
    uint256 decimalPurchase = toDecimal(baseCurrency, purchasedAmount);

    _preValidatePurchase(investor, paymentToken, decimalPurchase);

    bytes32 id = _getIdByAddress(investor);

    uint256 requiredAmountToBePaid = _getFinalAmt(paymentToken, decimalPurchase); // convert in sale currency
    uint256 purchaseCost = decimalPurchase * tokenPrice;

    _remInvest(id, purchaseCost); // check rem' invest in KCHF
    _forwardFunds(investor, paymentToken, purchaseCost); // convert/take funds into this contract
    _processPurchase(investor, decimalPurchase); // process purchase
    _updateSaleStateAdd(decimalPurchase, purchaseCost); // update sale state
    _updateUserContribState(id, investor, decimalPurchase, purchaseCost); // update contrib
    _emitEvent(id, investor, paymentToken, decimalPurchase, requiredAmountToBePaid, purchaseCost);
  }

  function addInvestmentManually(
    address investor,
    address paymentToken,
    uint256 purchasedAmount
  ) external nonReentrant whenNotPaused onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    uint256 decimalPurchase = toDecimal(baseCurrency, purchasedAmount);

    _preValidatePurchase(investor, paymentToken, decimalPurchase);

    bytes32 id = _getIdByAddress(investor);

    uint256 requiredAmountToBePaid = _getFinalAmt(paymentToken, decimalPurchase); // convert in sale currency
    uint256 purchaseCost = decimalPurchase * tokenPrice;

    _remInvest(id, purchaseCost); // check rem' invest in KCHF
    _processPurchase(investor, decimalPurchase); // process purchase
    _updateSaleStateAdd(decimalPurchase, purchaseCost); // update sale state
    _updateUserContribState(id, investor, decimalPurchase, purchaseCost); // update contrib
    _emitEvent(id, investor, paymentToken, decimalPurchase, requiredAmountToBePaid, purchaseCost);
  }

  function removeAllInvestments(address investor) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    uint256 buy = contributions[contributionIndex[investor]].buyAmt;
    uint256 paid = contributions[contributionIndex[investor]].paidAmt;
    _updateSaleStateSub(buy, paid);
    delete contributions[contributionIndex[investor]];
    address userRegistry = getUserRegAddr();
    IUserRegistry(userRegistry).removeInvestment(address(this), investor);
    emit RemoveInvestment(address(this), investor);
  }

  function emergencyWithdrawSecurity() public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    uint256 balance = IERC20(securityTokenAddress).balanceOf(address(this));
    IERC20(securityTokenAddress).safeTransfer(msg.sender, balance);
  }

  // -----------------------------------------
  // Setters of crowdsale contract restricted to onlyRole(CROWDSALE_ADMINISTRATOR_ROLE)
  // -----------------------------------------

  function setNewBeneficiary(address newAddress) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0), "CRW01");
    require(newAddress != securityTokenAddress, "CRW02");
    beneficiary = newAddress;
    emit BeneficiaryUpdated(newAddress);
  }

  function setNewPrice(uint256 newVal) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newVal > 0, "CRW01");
    require(newVal != tokenPrice, "CRW02");
    tokenPrice = newVal;
    emit TokenPriceUpdated(address(this), securityTokenAddress, newVal);
  }

  function setNewRegistryAddress(address newAddress) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newAddress != address(0));
    require(newAddress != addressRegistry);
    addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  function setMinPurchase(uint256 minVal) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(minVal != executionValueMin);
    executionValueMin = minVal;
    emit MinPurchaseUpdated(minVal);
  }

  function setMaxPurchase(uint256 maxVal) external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(maxVal != maxTokenPerOrder);
    maxTokenPerOrder = maxVal;
    emit MaxPurchaseUpdated(maxVal);
  }

  function pause() external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    _unpause();
  }

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getTokenRegAddr();
  }

  function getUserRegAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getUserRegAddr();
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getRoleRegAddr();
  }

  function getEventAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getCrowdsaleEventAddr();
  }

  function getPriceFeedAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getPriceFeedAddr();
  }

  function getPairFactoryAddr() public view returns (address) {
    return IAddressRegistry(addressRegistry).getPairFactoryAddr();
  }

  // -----------------------------------------
  // Investor getters
  // -----------------------------------------

  function getPaidAmtForAddress(address account) public view returns (uint256) {
    address userRegistry = getUserRegAddr();
    return IUserRegistry(userRegistry).getPaidAmtForAddress(address(this), account);
  }

  function getPurchasedAmtForAddress(address account) public view returns (uint256) {
    address userRegistry = getUserRegAddr();
    return IUserRegistry(userRegistry).getPurchasedAmtForAddress(address(this), account);
  }

  function getFinalAmt(address pay_tok, uint256 amt) public view returns (uint256 pay_amt) {
    require(pay_tok != address(0), "_getFinalAmt: Invalid pay_tok address");
    uint256 convertToDecimal = toDecimal(pay_tok, amt);
    return _getFinalAmt(pay_tok, convertToDecimal);
  }

  // -----------------------------------------
  // Internal utils
  // -----------------------------------------

  function toDecimal(address token, uint256 amount) public view returns (uint256) {
    uint256 decimals = IERC20Metadata(token).decimals();
    uint256 calc = amount * 10 ** decimals;
    return calc;
  }

  function _preValidatePurchase(address investor, address paymentToken, uint256 amount) internal view virtual {
    // todo: replace string error
    require(investor != address(0), "_preValidatePurchase: Investor address cannot be 0");
    require(paymentToken != address(0), "_preValidatePurchase address cannot be 0");
    require(amount != 0, "_preValidatePurchase: amount can't be null");
    require(amount >= executionValueMin, "_preValidatePurchase: amount < executionValueMin");
    require(amount <= maxTokenPerOrder, "_preValidatePurchase: amount > maxTokenPerOrder");
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  function __Crowdsale_init(
    uint saleType_,
    address beneficiary_,
    address token_,
    address crowdsaleCurrency_,
    address addressRegistry_,
    uint256 minPurchase_,
    uint256 maxPurchase_,
    uint256 tokenPrice_
  ) internal onlyInitializing {
    require(
      beneficiary_ != address(0) && token_ != address(0) && crowdsaleCurrency_ != address(0) && tokenPrice_ > 0,
      "CRW01"
    );
    saleType = saleType_;
    (beneficiary, securityTokenAddress, baseCurrency, tokenPrice) = (
      beneficiary_,
      token_,
      crowdsaleCurrency_,
      tokenPrice_
    );
    (addressRegistry, executionValueMin, maxTokenPerOrder) = (addressRegistry_, minPurchase_, maxPurchase_);
  }

  function _getIdByAddress(address investor) internal view returns (bytes32) {
    address userRegistry = getUserRegAddr();
    bytes32 id = IUserRegistry(userRegistry).getIdByAddress(investor);
    require(id != bytes32(0), "_getIdByAddress: id not found");
    return id;
  }

  function _remInvest(bytes32 id, uint256 purchaseCost) internal view {
    uint256 val;

    address tokenReg = getTokenRegAddr();
    address priceFeed = getPriceFeedAddr();
    address userRegistry = getUserRegAddr();
    address KCHF = ITokenRegistry(tokenReg).getStableAddress("CHF");
    bool isKCHF = baseCurrency == KCHF;
    uint256 remainingInvestmentInKCHF = IUserRegistry(userRegistry).getRemainingInvestAmtOf(id);

    if (isKCHF) {
      val = purchaseCost;
    } else {
      // if not a KCHF's crowdsale
      uint256 price = IPriceFeed(priceFeed).getLatestPrice(baseCurrency, KCHF);
      val = purchaseCost.mul(price).div(10 ** 8);
    }
    require(val <= remainingInvestmentInKCHF, "_remInvest: Wrong Purchase Amt");
  }

  function _deliverTokens(address investor, uint256 purchasedAmt) internal virtual {
    require(IERC20(securityTokenAddress).balanceOf(address(this)) >= purchasedAmt, "Not enough token in SC");
    IERC20(securityTokenAddress).safeTransfer(investor, purchasedAmt);
  }

  function _processPurchase(address investor, uint256 purchasedAmt) internal virtual {
    _deliverTokens(investor, purchasedAmt);
  }

  // -----------------------------------------
  // Internal
  // -----------------------------------------

  function _forwardFundsPermit(
    address investor,
    address pay_tok,
    uint256 purchaseCost,
    uint256 approvedAmt,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns (uint256) {
    IERC20Permit(pay_tok).safePermit(investor, address(this), approvedAmt, deadline, v, r, s);
    return _forwardFunds(investor, pay_tok, purchaseCost);
  }

  function _forwardFunds(address investor, address pay_tok, uint256 purchaseCost) internal returns (uint256) {
    address receiver = saleType == 1 ? beneficiary : address(this);
    if (pay_tok == baseCurrency) {
      return _transferFunds(investor, receiver, pay_tok, purchaseCost);
    } else {
      uint256 finalAmount = _getFinalAmt(pay_tok, purchaseCost);
      return _swapIntoCrowdsaleCurrency(investor, receiver, pay_tok, purchaseCost, finalAmount);
    }
  }

  function _transferFunds(
    address investor,
    address receiver,
    address pay_tok,
    uint256 pay_amt
  ) private returns (uint256) {
    IERC20(pay_tok).safeTransferFrom(investor, receiver, pay_amt);
    return pay_amt;
  }

  function _swapIntoCrowdsaleCurrency(
    address investor,
    address receiver,
    address pay_tok,
    uint256 desiredAmt,
    uint256 requiredAmt
  ) private returns (uint256) {
    address factory = getPairFactoryAddr();
    address pair = IPairFactory(factory).getPairAddress(pay_tok, baseCurrency);
    IERC20(pay_tok).safeTransferFrom(investor, address(this), requiredAmt);
    IERC20(pay_tok).approve(pair, requiredAmt);
    uint256 am = IPairSwap(pair).swapAmountOut(pay_tok, desiredAmt, requiredAmt);
    IERC20(baseCurrency).safeTransfer(receiver, am);
    return am;
  }

  function _emitEvent(
    bytes32 id,
    address investor,
    address paymentToken,
    uint256 purchasedAmt,
    uint256 initialPaymentAmt,
    uint256 nativePaymentAmt
  ) internal {
    address _event = getEventAddr();
    ICrowdsaleEvent(_event).tokenPurchaseEvent(
      id,
      investor,
      paymentToken,
      securityTokenAddress,
      purchasedAmt,
      initialPaymentAmt,
      nativePaymentAmt
    );
  }

  // -----------------------------------------
  // Internal state management
  // -----------------------------------------

  function _updateSaleStateAdd(uint256 buy, uint256 paid) internal {
    totalTokensSold += buy;
    totalRaised += paid;
  }

  function _updateSaleStateSub(uint256 buy, uint256 paid) internal {
    totalTokensSold -= buy;
    totalRaised -= paid;
  }

  function _updateUserContribState(bytes32 id, address investor, uint256 purchasedAmt, uint256 paidAmt) internal {
    address userRegistry = getUserRegAddr();
    contributions.push(Contribution(id, investor, purchasedAmt, paidAmt));
    contributionIndex[investor] = contributions.length - 1;
    IUserRegistry(userRegistry).addInvestment(address(this), investor, purchasedAmt, paidAmt);
  }

  // -----------------------------------------
  // Internal getters utils
  // -----------------------------------------

  function _getFinalAmt(address pay_tok, uint256 amt) internal view returns (uint256 pay_amt) {
    if (pay_tok == baseCurrency) {
      pay_amt = amt * tokenPrice;
    } else {
      pay_amt = _swapConvertEstimationOut(pay_tok, baseCurrency, amt * tokenPrice);
    }
    return pay_amt;
  }

  function _swapConvertEstimationOut(
    address pay_tok,
    address base,
    uint256 amountOut // Amt wanted in output
  ) internal view returns (uint256) {
    address factory = getPairFactoryAddr();
    address pair = IPairFactory(factory).getPairAddress(pay_tok, base);
    return IPairSwap(pair).getRequiredAmtOfTokensFor(base, amountOut);
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "./base/Crowdsale.sol";
import "./validation/BatchedValidation.sol";
import "./validation/TimedValidation.sol";
import "../interfaces/ICrowdsaleConfig.sol";
import "../../registry/interface/IAddressRegistry.sol";

/**
 * 1. Check batch validty
 *
 */

contract BatchDrivenCrowdsale is Crowdsale, TimedValidation, BatchedValidation, ICrowdsaleConfig {
  enum State {
    Active,
    Refunding,
    Distribution,
    Finished
  }
  State internal _state;

  function state() public view returns (State) {
    return _state;
  }

  // -----------------------------------------
  // Overrides
  // -----------------------------------------

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale, BatchedValidation, TimedValidation) {
    require(_state == State.Active, "Not opened");
    super._preValidatePurchase(investor, paymentToken, amount);
  }

  function _processPurchase(address investor, uint256 purchasedAmt) internal override(BatchedValidation, Crowdsale) {
    super._processPurchase(investor, purchasedAmt);
    if (restToSell == 0) {
      _state == State.Distribution;
    }
  }

  // -----------------------------------------
  // Utils
  // -----------------------------------------

  function _isFactory(address sender, address registry) internal view returns (bool) {
    return sender == IAddressRegistry(registry).getCrowdsaleFactAddr();
  }

  // function distributeToken(uint256 startIndex, uint256 endIndex) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
  //   require(_state == State.Distribution, "Not in distribution phase");
  //   for (uint i = startIndex; i <= endIndex; i++) {
  //     address investor = contributions[i].investor;
  //     uint256 buyAmt = contributions[i].buyAmt;
  //     IERC20(_tokenAddress).transfer(investor, buyAmt);
  //     contributions[i].buyAmt = 0;
  //   }
  // }

  // function refund(uint256 startIndex, uint256 endIndex) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
  //   require(_state == State.Refunding, "Not in refunding phase");
  //   for (uint i = startIndex; i <= endIndex; i++) {
  //     address investor = contributions[i].investor;
  //     uint256 buyAmt = contributions[i].buyAmt;
  //     IERC20(_tokenAddress).transfer(investor, buyAmt);
  //     contributions[i].buyAmt = 0;
  //   }
  // }

  function __BatchDrivenCrowdsale_init(BatchDrivenCrowdsaleConfig memory config) public initializer {
    require(_isFactory(msg.sender, config.addressRegistry), "Caller is not factory");
    Crowdsale.__Crowdsale_init(
      2,
      config.beneficiary,
      config.tokenAddress,
      config.crowdsaleCurrency,
      config.addressRegistry,
      config.executionValueMin,
      config.maxTokenPerOrder,
      config.tokenPrice
    );
    TimedValidation.__TimedValidation_init(config.startTime, config.endTime);

    (uint256 batchSize, uint256 numberOfBatch) = (config.batchSize * 10 ** 18, config.numberOfBatch);
    BatchedValidation.__BatchedValidation_init(batchSize, numberOfBatch);
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "./base/Crowdsale.sol";
import "./validation/CappedValidation.sol";
import "./distribution/FinalizableCrowdsale.sol";
import "../interfaces/ICrowdsaleConfig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../registry/interface/IAddressRegistry.sol";
// debug
import "hardhat/console.sol";

/**
 * CAP02: startIndex is higher than endIndex
 */
contract CappedCrowdsale is Initializable, Crowdsale, FinalizableCrowdsale, CappedValidation, ICrowdsaleConfig {
  enum State {
    Active,
    Refunding,
    Closed
  }
  using SafeERC20 for IERC20;

  event RefundsClosed();
  event RefundsEnabled();

  State internal _state;

  mapping(address => bool) addressRefunded;
  mapping(bytes32 => bool) userRefunded;
  mapping(address => bool) addressClaimed;
  mapping(bytes32 => bool) userClaimed;

  function state() public view returns (State) {
    return _state;
  }

  function distributeToken(uint256 startIndex, uint256 endIndex) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(_state == State.Closed, "Not closed");
    require(finalized, "Not finalized");
    require(endIndex >= startIndex, "Crowdsale: endIndex must be greater than or equal to startIndex");

    uint256 lastIndex = contributions.length - 1;
    if (endIndex > lastIndex) {
      endIndex = lastIndex;
    }
    bytes32[] memory ids = new bytes32[](endIndex - startIndex + 1);
    address[] memory beneficiaries = new address[](endIndex - startIndex + 1);
    uint256[] memory purchasedAmt = new uint256[](endIndex - startIndex + 1);

    for (uint i = startIndex; i <= endIndex; i++) {
      uint256 buyAmt = contributions[i].buyAmt;
      if (buyAmt > 0) {
        bytes32 id = contributions[i].id;
        address beneficiary = contributions[i].investor;
        IERC20(securityTokenAddress).safeTransfer(beneficiary, buyAmt);
        ids[i - startIndex] = id;
        beneficiaries[i - startIndex] = beneficiary;
        purchasedAmt[i - startIndex] = buyAmt;
        contributions[i].buyAmt = 0;
      }
    }
    address _event = getEventAddr();
    ICrowdsaleEvent(_event).distributeEvent(securityTokenAddress, ids, beneficiaries, purchasedAmt);
  }

  function refund(uint256 startIndex, uint256 endIndex) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(_state == State.Refunding, "Crowdsale: Not in refunding state");
    require(endIndex >= startIndex, "Crowdsale: endIndex must be greater than or equal to startIndex");

    uint256 lastIndex = contributions.length - 1;
    if (endIndex > lastIndex) {
      endIndex = lastIndex;
    }
    bytes32[] memory ids = new bytes32[](endIndex - startIndex + 1);
    address[] memory beneficiaries = new address[](endIndex - startIndex + 1);
    uint256[] memory paidAmts = new uint256[](endIndex - startIndex + 1);

    for (uint i = startIndex; i <= endIndex; i++) {
      uint256 paidAmt = contributions[i].paidAmt;
      if (paidAmt > 0) {
        bytes32 id = contributions[i].id;
        address beneficiary = contributions[i].investor;

        IERC20(baseCurrency).safeTransfer(beneficiary, paidAmt);

        ids[i - startIndex] = id;
        beneficiaries[i - startIndex] = beneficiary;
        paidAmts[i - startIndex] = paidAmt;
      }
    }
    address _event = getEventAddr();
    ICrowdsaleEvent(_event).refundEvent(baseCurrency, ids, beneficiaries, paidAmts);
  }

  // -----------------------------------------
  // Internal
  // -----------------------------------------

  function _finalization() internal override {
    if (hardCapReached()) {
      closeAndWithdraw();
    } else if (softCapReached() && hasClosed()) {
      closeAndWithdraw();
    } else if (!softCapReached() && hasClosed()) {
      _enableRefunds();
    }
    super._finalization();
  }

  function _enableRefunds() internal {
    require(_state == State.Active, "Crowdsale: Not in Active state");
    _state = State.Refunding;
    emit RefundsEnabled();
  }

  function _close() internal {
    require(_state == State.Active, "Crowdsale: Not in Active state");
    _state = State.Closed;
    emit RefundsClosed();
  }

  // Success
  function _beneficiaryWithdraw() internal {
    require(_state == State.Closed, "Crowdsale: Not in closed state");
    uint256 balance = IERC20(baseCurrency).balanceOf(address(this));
    IERC20(baseCurrency).transfer(beneficiary, balance);
  }

  function closeAndWithdraw() private {
    _close();
    _beneficiaryWithdraw();
  }

  // -----------------------------------------
  // Overrides
  // -----------------------------------------

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale, TimedValidation, CappedValidation) {
    super._preValidatePurchase(investor, paymentToken, amount);
  }

  function _processPurchase(address investor, uint256 purchasedAmt) internal override(Crowdsale) {}

  // -----------------------------------------
  // Utils
  // -----------------------------------------

  function _isFactory(address sender, address registry) internal view returns (bool) {
    return sender == IAddressRegistry(registry).getCrowdsaleFactAddr();
  }

  // function claim(bytes32 id) public {
  //   require(_state == State.Closed);
  //   if (finalized()) revert NotFinalized();
  //   // user has already claim?
  //   if (userClaimed[id]) revert IdHasAlreadyClaimed();

  //   address userRegistry = getUserRegAddr();
  //   address[] memory userAddress = IUserRegistry(userRegistry).getAddressById(
  //     id
  //   );
  //   for (uint i = 0; i < userAddress.length; i++) {
  //     if (!addressClaimed[userAddress[i]]) {
  //       uint256 amount = IUserRegistry(userRegistry).getPurchasedAmtForAddress(
  //         address(this),
  //         userAddress[i]
  //       );
  //       IERC20(_tokenAddress).transfer(userAddress[i], amount);
  //       addressClaimed[userAddress[i]] = true;
  //     }
  //   }
  //   userClaimed[id] = true;
  // }

  // Failure
  // function refundId(bytes32 id) public {
  //   require(_state == State.Refunding);
  //   require(!goalReached() && finalized());
  //   if (userRefunded[id]) revert IdHasAlreadyRefunded();

  //   address userRegistry = getUserRegAddr();
  //   address[] memory userAddress = IUserRegistry(userRegistry).getAddressById(
  //     id
  //   );

  //   for (uint i = 0; i < userAddress.length; i++) {
  //     if (!addressRefunded[userAddress[i]]) {
  //       uint256 amount = IUserRegistry(userRegistry).getPaidAmtForAddress(
  //         address(this),
  //         userAddress[i]
  //       );
  //       IERC20(_crowdsaleCurrency).transfer(userAddress[i], amount);
  //       addressRefunded[userAddress[i]] = true;
  //     }
  //   }
  //   userRefunded[id] = true;
  // }
  function __CappedCrowdsale_init(CappedCrowdsaleConfig memory config) public initializer {
    require(_isFactory(msg.sender, config.addressRegistry));
    _state = State.Active;
    Crowdsale.__Crowdsale_init(
      0,
      config.beneficiary,
      config.tokenAddress,
      config.crowdsaleCurrency,
      config.addressRegistry,
      config.executionValueMin,
      config.maxTokenPerOrder,
      config.tokenPrice
    );
    FinalizableCrowdsale.__finalizableCrowdsale_init(config.startTime, config.endTime);
    CappedValidation.__CappedValidation_init(config.softcap, config.hardcap);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../validation/TimedValidation.sol";

abstract contract FinalizableCrowdsale is TimedValidation {
  bool public finalized;

  event CrowdsaleFinalized();

  function __finalizableCrowdsale_init(uint256 openingTime, uint256 closingTime) public onlyInitializing {
    finalized = false;
    TimedValidation.__TimedValidation_init(openingTime, closingTime);
  }

  function finalize() public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(!finalized, "FinalizableCrowdsale: already finalized");
    finalized = true;
    _finalization();
    emit CrowdsaleFinalized();
  }

  function _finalization() internal virtual {
    // solhint-disable-previous-line no-empty-blocks
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "./base/Crowdsale.sol";
import "./validation/TimedValidation.sol";
import "../interfaces/ICrowdsaleConfig.sol";
import "../../registry/interface/IAddressRegistry.sol";

contract UncappedCrowdsale is Crowdsale, TimedValidation, ICrowdsaleConfig {
  enum State {
    Active,
    Closed
  }

  State internal _state;

  function state() public view returns (State) {
    return _state;
  }

  // -----------------------------------------
  // Internal
  // -----------------------------------------

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale, TimedValidation) {
    super._preValidatePurchase(investor, paymentToken, amount);
  }

  function _isFactory(address sender, address registry) internal view returns (bool) {
    return sender == IAddressRegistry(registry).getCrowdsaleFactAddr();
  }

  function __UncappedCrowdsale_init(UncappedCrowdsaleConfig memory config) public initializer {
    require(_isFactory(msg.sender, config.addressRegistry), "Caller is not factory");
    _state = State.Active;
    Crowdsale.__Crowdsale_init(
      1,
      config.beneficiary,
      config.tokenAddress,
      config.crowdsaleCurrency,
      config.addressRegistry,
      config.executionValueMin,
      config.maxTokenPerOrder,
      config.tokenPrice
    );
    TimedValidation.__TimedValidation_init(config.startTime, config.endTime);
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "../base/Crowdsale.sol";

contract BatchedValidation is Crowdsale {
  uint256 public batchSize;
  uint256 public numberOfBatch;
  uint256 public currentBatchId;
  uint256 public restToSell;

  function __BatchedValidation_init(uint256 size_, uint256 numberOfBatch_) public onlyInitializing {
    require(size_ > 0, "__BatchedValidation_init: Value can't be null");
    require(numberOfBatch_ > 0, "__BatchedValidation_init: Value can't be null");
    (batchSize, numberOfBatch, currentBatchId, restToSell) = (size_, numberOfBatch_, 0, size_);
  }

  // -----------------------------------------
  // Overrides
  // -----------------------------------------

  function _processPurchase(address /*investor*/, uint256 purchasedAmt) internal virtual override(Crowdsale) {
    restToSell -= purchasedAmt;
  }

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale) {
    require(restToSell >= amount, "Not enough to sell in this batch");
    super._preValidatePurchase(investor, paymentToken, amount);
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "../base/Crowdsale.sol";

contract CappedValidation is Crowdsale {
  uint256 public softcap;
  uint256 public hardcap;

  event SetNewSoftCap(uint256 prevSoftCap, uint256 newSoftCap);
  event SetNewHardCap(uint256 prevHardCap, uint256 newHardCap);

  function __CappedValidation_init(uint256 softcap_, uint256 hardCap_) public onlyInitializing {
    require(softcap_ < hardCap_ && hardCap_ > 0, "CappedValidation: softCap is bigger than hardCap or null");
    (softcap, hardcap) = (softcap_, hardCap_);
  }

  function setSoftCap(uint256 newVal) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newVal != softcap && newVal < hardcap, "CappedValidation: wrong new val");
    softcap = newVal;
    emit SetNewSoftCap(softcap, newVal);
  }

  function setHardCap(uint256 newVal) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newVal != hardcap && newVal > softcap, "CappedValidation: newVal is not valid");
    softcap = newVal;
    emit SetNewSoftCap(hardcap, newVal);
  }

  function softCapReached() public view returns (bool) {
    return totalRaised >= softcap;
  }

  function hardCapReached() public view returns (bool) {
    return totalRaised >= hardcap;
  }

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale) {
    require((totalRaised + amount) <= hardcap, "_preValidatePurchase: cap exceeded");
    super._preValidatePurchase(investor, paymentToken, amount);
  }
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

import "../base/Crowdsale.sol";

contract TimedValidation is Crowdsale {
  uint256 public openingTime;
  uint256 public closingTime;

  event TimedValidationSetOpening(uint256 prevOpeningTime, uint256 newOpeningTime);
  event TimedValidationSetClosing(uint256 prevClosingTime, uint256 newClosingTime);

  modifier onlyWhileOpen() {
    require(isOpen(), "TimedValidation: not open");
    _;
  }

  function __TimedValidation_init(uint256 openingTime_, uint256 closingTime_) public onlyInitializing {
    require(openingTime_ >= block.timestamp, "TimedValidation: opening time is before current time");
    require(closingTime_ > openingTime_, "TimedValidation: closing time is before opening time");
    (openingTime, closingTime) = (openingTime_, closingTime_);
  }

  function setNewOpeningTime(uint256 newVal) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newVal < closingTime, "TimedValidation: wrong val");
    closingTime = newVal;
    emit TimedValidationSetOpening(openingTime, newVal);
  }

  function setNewClosingTime(uint256 newVal) public onlyRole(CROWDSALE_ADMINISTRATOR_ROLE) {
    require(newVal > openingTime, "TimedValidation: wrong val");
    closingTime = newVal;
    emit TimedValidationSetClosing(closingTime, newVal);
  }

  function isOpen() public view returns (bool) {
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

  function _preValidatePurchase(
    address investor,
    address paymentToken,
    uint256 amount
  ) internal view virtual override(Crowdsale) {
    super._preValidatePurchase(investor, paymentToken, amount);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library ItMapSale {
  struct SaleMap {
    address[] keys;
    mapping(address => uint) saleType;
    mapping(address => address) currency;
    mapping(address => address) token;
    mapping(address => uint256) indexOf;
  }

  function getTypeOf(SaleMap storage map, address key) external view returns (uint) {
    return map.saleType[key];
  }

  function getIndexOfKey(SaleMap storage map, address key) external view returns (int) {
    if (map.indexOf[key] == 0) {
      return -1;
    }
    return int(map.indexOf[key]);
  }

  function getAllSales(SaleMap storage map) external view returns (address[] memory) {
    return map.keys;
  }

  function saleExists(SaleMap storage map, address key) external view returns (bool) {
    return map.token[key] != address(0);
  }

  function getKeyAtIndex(SaleMap storage map, uint256 index) external view returns (address) {
    return map.keys[index];
  }

  function size(SaleMap storage map) public view returns (uint) {
    return map.keys.length;
  }

  function add(SaleMap storage map, address key, address token, address currency, uint saleType) external {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
      }
    }
    map.currency[key] = currency;
    map.saleType[key] = saleType;
    map.token[key] = token;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}