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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IAddressesProvider.sol";
import "./RewardsDistributor.sol";
import "./AssetPriceOracle.sol";
import "./interfaces/IAccessManager.sol";
import "./interfaces/ICommissionsDistributor.sol";
import "./KycStore.sol";
import "./interfaces/IChainLinkPrice.sol";

contract Asset is IAsset, Initializable, ERC20Upgradeable {
    IAddressesProvider public addressesProvider;

    using SafeERC20 for ERC20;
    ERC20 public buyToken;

    AssetInfo public info;
    AssetLocationData public locationData;
    Document[] public documents;
    Status public status;

    uint256 public maxTotalSupply;
    uint256 public leftToBuy;
    uint256 public buyTokenDecimals;
    address[] public buyers;
    mapping(address => bool) private _isBuyer;
    uint256 public savedPrice;
    IChainLinkPrice public chainLinkPrice;
    uint256 public saleEndDate;
    PaymentTokenRange public paymentTokenRange;

    modifier onlySuperOracle() {
        IAccessManager accessManager = IAccessManager(addressesProvider.getAccessManager());
        require(accessManager.canDoWith(msg.sender, IAccessManager.Action.ManageAsset, address(this)), "Permission denied: ManageAsset");
        _;
    }

    function __Asset_init(
        address _addressesProvider,
        address _chainLinkPrice,
        string memory name,
        string memory symbol,
        uint256 _maxTotalSupply,
        uint256 _saleEndDate,
        ERC20 _buyToken
    ) public initializer {
        __ERC20_init(name, symbol);
        require(_maxTotalSupply > 0, "maxTotalSupply must be greater than 0");
        require(_saleEndDate > block.timestamp, "saleEndDate must be greater than current timestamp");
        require(address(_buyToken) != address(0), "buyToken must be a valid address");
        addressesProvider = IAddressesProvider(_addressesProvider);
        chainLinkPrice = IChainLinkPrice(_chainLinkPrice);
        maxTotalSupply = _maxTotalSupply;
        leftToBuy = _maxTotalSupply;
        buyToken = _buyToken;
        buyTokenDecimals = 10 ** _buyToken.decimals();
        status = Status.New;
        saleEndDate = _saleEndDate;
        paymentTokenRange = PaymentTokenRange(99000000, 101000000);
    }

    function getVersion() external pure returns (uint256) {
        return 3;
    }

    function buyersLength() external view override returns (uint256) {
        return buyers.length;
    }

    function getBuyers() external view override returns (address[] memory) {
        return buyers;
    }

    function isBuyer(address buyer) external view override returns (bool) {
        return _isBuyer[buyer];
    }

    function getDocuments() external view override returns (Document[] memory) {
        return documents;
    }

    function getAssetInfo() external view returns (AssetInfo memory) {
        return info;
    }

    function getAssetLocation() external view returns (AssetLocationData memory) {
        return locationData;
    }

    function setPaymentTokenRange(PaymentTokenRange memory _paymentTokenRange) external override onlySuperOracle {
        paymentTokenRange = _paymentTokenRange;
    }

    function setChainLinkPrice(address _chainLinkPrice) external override onlySuperOracle {
        chainLinkPrice = IChainLinkPrice(_chainLinkPrice);
    }

    function confirmSelling(address seller) external override onlySuperOracle {
        require(status == Status.SoldOut, "Asset is not sold out");
        require(seller != address(0), "seller must be a valid address");
        _payCommission(buyToken.balanceOf(address(this)));
        buyToken.safeTransfer(seller, buyToken.balanceOf(address(this)));
        _setStatus(Status.Confirmed);
        emit Confirmed();
    }

    function rejectSelling(uint256 startIndex, uint256 endIndex) external override onlySuperOracle {
        require((status == Status.Active) || (status == Status.NotSoldOut), "Asset is not active or not sold out");
        require((startIndex <= endIndex), "startIndex must be less or equal to endIndex");
        require(endIndex <= buyers.length, "endIndex must be less than or equal to buyers.length");
        address[] memory _buyers = buyers;
        for (uint256 i = startIndex; i < endIndex; i++) {
            address buyer = _buyers[i];
            uint256 buyerBalance = balanceOf(buyer);
            if (buyerBalance == 0) {
                continue;
            }
            uint256 totalBuyTokenAmount = buyToken.balanceOf(address(this));
            uint256 buyTokenAmount = (buyerBalance * totalBuyTokenAmount) / totalSupply();
            leftToBuy += buyerBalance;
            _burn(buyer, buyerBalance);
            buyToken.safeTransfer(buyer, buyTokenAmount);
        }
        _setStatus(Status.NotSoldOut);
        emit Rejected();
    }

    function rejectSellingUser() external override {
        require((status == Status.Active), "Asset is not active");
        require((block.timestamp > saleEndDate), "SaleEndDate must be less than current timestamp");
        require((_isBuyer[msg.sender]), "You are not the buyer");
        uint256 buyerBalance = balanceOf(msg.sender);
        uint256 totalBuyTokenAmount = buyToken.balanceOf(address(this));
        uint256 buyTokenAmount = (buyerBalance * totalBuyTokenAmount) / totalSupply();
        unchecked {
            leftToBuy += buyerBalance;
        }
        _burn(msg.sender, buyerBalance);
        buyToken.safeTransfer(msg.sender, buyTokenAmount);
        emit Rejected();
    }

    function updateAssetInfo(AssetInfo memory assetInfo) external override onlySuperOracle {
        info = AssetInfo({
            entityType: assetInfo.entityType > 0 ? assetInfo.entityType : info.entityType,
            name: bytes(assetInfo.name).length > 0 ? assetInfo.name : info.name,
            creation: assetInfo.creation > 0 ? assetInfo.creation : info.creation,
            closingCost: bytes(assetInfo.closingCost).length > 0 ? assetInfo.closingCost : info.closingCost,
            underlyingPrice: bytes(assetInfo.underlyingPrice).length > 0 ? assetInfo.underlyingPrice : info.underlyingPrice
        });
        emit AssetInfoUpdated(block.timestamp);
    }

    function updateAssetLocationData(AssetLocationData memory location) external override onlySuperOracle {
        locationData = location;
        emit AssetLocationUpdated(block.timestamp);
    }

    function addDocument(Document memory document) external override onlySuperOracle {
        documents.push(document);
        emit DocumentAdded(document.name, document.hash, block.timestamp);
    }

    function updateDocument(uint256 documentIndex, Document memory document) external override onlySuperOracle {
        require(documentIndex < documents.length, "documentIndex must be less than documents.length");
        documents[documentIndex] = document;
        emit DocumentUpdated(documentIndex, document.name, document.hash, block.timestamp);
    }

    function getRewardDistribution() public view returns (RewardsDistributor) {
        return RewardsDistributor(addressesProvider.getRewardsDistributor());
    }

    function getAssetPriceOracle() public view returns (AssetPriceOracle) {
        return AssetPriceOracle(addressesProvider.getAssetPriceOracle());
    }

    function getKycStore() public view returns (KycStore) {
        return KycStore(addressesProvider.getKycStore());
    }

    function invest(address recipient, uint256 amount) external override {
        require(status == Status.Active || status == Status.Confirmed, "Asset is not active");
        _invest(recipient, amount);
    }

    function investWithAmbassador(address recipient, uint256 amount, address ambassador) external override {
        require(status == Status.PreSale || status == Status.Active || status == Status.Confirmed, "Asset is not active or pre sale");
        require(ambassador != address(0), "ambassador must be a valid address");
        _invest(recipient, amount);
        emit InvestWithAmbassador(recipient, ambassador, amount, block.timestamp);
    }

    function investWithReferrer(address recipient, uint256 amount, address referrer) external override {
      require(status == Status.Active || status == Status.Confirmed, "Asset is not active");
      require(referrer != address(0), "referrer must be a valid address");
      _invest(recipient, amount);
      emit InvestWithReferrer(recipient, referrer, amount, block.timestamp);
    }

    function _invest(address recipient, uint256 amount) private {
        if (address(chainLinkPrice) != address(0)) {
            int256 _latestPrice = _getLatestPriceBuyToken();
            require(
                _latestPrice <= paymentTokenRange.max && _latestPrice >= paymentTokenRange.min,
                "Reached the limit of latest buy token price"
            );
        }
        if (leftToBuy > 10 ** decimals()) {
            require(amount >= 10 ** decimals(), "amount must be greater than 1");
        }
        require(amount <= leftToBuy, "amount must be less or equal to leftToBuy");
        RewardsDistributor rewardsDistributor = getRewardDistribution();
        require(address(rewardsDistributor) != address(0), "rewardsDistributor must be set");
        AssetPriceOracle oracle = getAssetPriceOracle();
        require(address(oracle) != address(0), "oracle must be set");
        KycStore kycStore = getKycStore();
        require(kycStore.isOperable(msg.sender), "sender, please complete KYC");
        require(kycStore.isOperable(recipient), "recipient, please complete KYC");
        if (savedPrice == 0) {
            uint256 price = oracle.latestPrice(address(this));
            require(price > 0, "price must be greater than 0");
            savedPrice = price;
        }
        uint256 buyTokenAmount = (amount * savedPrice) / (10 ** decimals());
        buyToken.safeTransferFrom(msg.sender, address(this), buyTokenAmount);
        _mint(recipient, amount);
        unchecked {
            leftToBuy -= amount;
        }
        uint256 recipientBalance = balanceOf(recipient);
        rewardsDistributor.onUserBalanceChanged(recipient, recipientBalance);

        if (leftToBuy == 0) {
            _setStatus(Status.SoldOut);
            emit Sold();
        }
        emit Bought(recipient, amount, block.timestamp, savedPrice, buyTokenAmount);
    }

    function setSaleEndDate(uint256 _saleEndDate) public override onlySuperOracle {
        require(_saleEndDate > block.timestamp, "saleEndDate must be greater than current timestamp");
        saleEndDate = _saleEndDate;
    }

    function setStatus(Status _status) public override onlySuperOracle {
        if (_status == status) {
            return;
        }

        if (_status == Status.Inactive || _status == Status.Disabled) {
            if (status == Status.New || status == Status.Upcoming || (status == Status.Active && leftToBuy == maxTotalSupply)) {
                _setStatus(_status);
                return;
            }
        }
        if (_status == Status.Upcoming) {
            if (status == Status.New) {
                _setStatus(_status);
                return;
            }
        }
        if (_status == Status.Active || _status == Status.PreSale) {
            if (status == Status.Upcoming || status == Status.New || status == Status.PreSale) {
                _setStatus(_status);
                return;
            }
        }
        if (_status == Status.NotSoldOut && leftToBuy < maxTotalSupply && leftToBuy > 0) {
            if (status == Status.Active) {
                _setStatus(_status);
                return;
            }
        }
        revert("Invalid status transition");
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(amount > 0, "amount must be greater than 0");
        KycStore kycStore = getKycStore();
        require(kycStore.isOperable(recipient), "recipient, please complete KYC");

        super._transfer(sender, recipient, amount);
    }

    function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 senderBalance = balanceOf(sender);
        uint256 recipientBalance = balanceOf(recipient);
        if (_isBuyer[recipient] == false && recipient != address(0)) {
            buyers.push(recipient);
            _isBuyer[recipient] = true;
        }
        if (senderBalance == 0) {
            for (uint256 i = 0; i < buyers.length; i++) {
                if (buyers[i] == sender) {
                    buyers[i] = buyers[buyers.length - 1];
                    buyers.pop();
                    break;
                }
            }
            _isBuyer[sender] = false;
        }
        RewardsDistributor rewardsDistributor = getRewardDistribution();
        if (address(rewardsDistributor) == address(0)) {
            return;
        }
        if (sender != address(0)) {
            rewardsDistributor.onUserBalanceChanged(sender, senderBalance);
        }
        if (recipient != address(0)) {
            rewardsDistributor.onUserBalanceChanged(recipient, recipientBalance);
        }
    }

    function _getLatestPriceBuyToken() private view returns (int256) {
        return chainLinkPrice.latestAnswer();
    }

    function _setStatus(Status _status) private {
        Status oldStatus = status;
        status = _status;
        emit StatusChanged(oldStatus, _status, block.timestamp);
    }

    function _payCommission(uint256 amount) private {
        address commissionDistributorAddress = addressesProvider.getCommissionsDistributor();
        require(commissionDistributorAddress != address(0), "commissionDistributorAddress must be set");
        ICommissionsDistributor commissionDistributor = ICommissionsDistributor(commissionDistributorAddress);
        uint256 commission = commissionDistributor.getInvestmentsCommissionAmount(address(this), amount);
        buyToken.safeApprove(address(commissionDistributor), commission);
        commissionDistributor.payInvestmentsCommission(address(buyToken), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardsDistributor.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/IAccessManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AssetPriceOracle is Initializable {
    struct Price {
        uint256 price;
        uint256 timestamp;
    }

    IAddressesProvider public addressesProvider;
    mapping(address => Price) public assetPrice;

    event AssetAdded(address asset, uint256 price, uint256 timestamp);
    event AssetPriceUpdated(address asset, uint256 price, uint256 timestamp);
    event AssetRemoved(address asset);

    modifier onlySuperOracle() {
        IAccessManager accessManager = IAccessManager(addressesProvider.getAccessManager());
        require(accessManager.isSuperOracle(msg.sender), "AssetPriceOracle: The caller must be a super oracle");
        _;
    }

    function initialize(address _addressesProvider) public initializer {
        addressesProvider = IAddressesProvider(_addressesProvider);
    }

    function getVersion() external pure returns (uint256) {
        return 1;
    }

    function latestPrice(address asset) external view returns (uint256) {
        return assetPrice[asset].price;
    }

    function latestTimestamp(address asset) external view returns (uint256) {
        return assetPrice[asset].timestamp;
    }

    function setAssetPrice(address asset, uint256 price) public onlySuperOracle {
        require(price > 0, "AssetPriceOracle: price must be greater than 0");
        assetPrice[asset].price = price;
        assetPrice[asset].timestamp = block.timestamp;
        emit AssetPriceUpdated(asset, price, block.timestamp);
    }

    function setAssetPrices(address[] memory assets, uint256[] memory prices) external onlySuperOracle {
        require(assets.length == prices.length, "assets and prices must have the same length");
        for (uint256 i = 0; i < assets.length; i++) {
            setAssetPrice(assets[i], prices[i]);
        }
    }

    function addAsset(address asset, uint256 price) public onlySuperOracle {
        require(assetPrice[asset].timestamp == 0, "AssetPriceOracle: asset already exists");
        assetPrice[asset].price = price;
        assetPrice[asset].timestamp = block.timestamp;
        emit AssetAdded(asset, price, block.timestamp);
    }

    function addAssets(address[] memory assets, uint256[] memory prices) external onlySuperOracle {
        require(assets.length == prices.length, "assets and prices must have the same length");
        for (uint256 i = 0; i < assets.length; i++) {
            addAsset(assets[i], prices[i]);
        }
    }

    function removeAsset(address asset) external onlySuperOracle {
        require(assetPrice[asset].timestamp != 0, "AssetPriceOracle: asset does not exist");
        delete assetPrice[asset];
        emit AssetRemoved(asset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessManager {
    enum Action {
      ManageUsdtf,
      ConfigureApp,
      ManageKycList,
      ManageAsset
    }

    event SuperOracleAdded(address user);
    event SuperOracleRemoved(address user);
    event KycOracleAdded(address user);
    event KycOracleRemoved(address user);

    function isSuperOracle(address user) external view returns (bool);

    function addSuperOracle(address user) external;

    function removeSuperOracle(address user) external;

    function isKycOracle(address user) external view returns (bool);

    function addKycOracle(address user) external;

    function removeKycOracle(address user) external;

    function can(address user, Action action) external view returns (bool);
    function canDoWith(address user, Action action, address target) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressesProvider {
    event AddressSet(bytes32 id, address indexed newAddress);
    event RewardDistributorUpdated(address indexed newAddress);
    event AssetPriceOracleUpdated(address indexed newAddress);
    event RewardDistributorAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PropertyFactoryUpdated(address indexed newAddress);
    event PropertyFactoryAdminUpdated(address indexed newAddress);
    event CoreManagerUpdated(address indexed newAddress);
    event CoreManagerAdminUpdated(address indexed newAddress);
    event AccessManagerUpdated(address indexed newAddress);
    event CommissionsDistributorUpdated(address indexed newAddress);
    event KycStoreUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getRewardsDistributor() external view returns (address);

    function setRewardsDistributor(address _rewardDistributor) external;

    function getAssetPriceOracle() external view returns (address);

    function setAssetPriceOracle(address _assetPriceOracle) external;

    function getRewardsDistributorAdmin() external view returns (address);

    function setRewardsDistributorAdmin(address _rewardDistributorAdmin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address _emergencyAdmin) external;

    function getPropertyFactory() external view returns (address);

    function setPropertyFactory(address _propertyFactory) external;

    function getPropertyFactoryAdmin() external view returns (address);

    function setPropertyFactoryAdmin(address _propertyFactoryAdmin) external;

    function getCoreManager() external view returns (address);

    function setCoreManager(address _coreManager) external;

    function setAccessManager(address _accessManager) external;

    function getAccessManager() external view returns (address);

    function setCommissionsDistributor(address _commissionsDistributor) external;

    function getCommissionsDistributor() external view returns (address);

    function setKycStore(address _address) external;

    function getKycStore() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAsset {
    enum Status {
        New,
        Upcoming,
        Active,
        Inactive,
        SoldOut,
        NotSoldOut,
        Disabled,
        Confirmed,
        PreSale
    }

    struct AssetLocationData {
        string country;
        string state;
        string city;
        string postalCode;
        string addressLine;
        string coordinates;
    }

    struct AssetInfo {
        uint16 entityType;
        uint64 creation;
        string name;
        string closingCost;
        string underlyingPrice;
    }

    struct Document {
        string name;
        string hash;
    }

    struct PaymentTokenRange {
        int256 min;
        int256 max;
    }

    struct AssetInfoAndLocation {
        AssetInfo info;
        AssetLocationData location;
    }

    event Bought(address indexed buyer, uint256 amount, uint256 timestamp, uint256 price, uint256 amountInUsd);
    event InvestWithAmbassador(address indexed buyer, address indexed ambassador, uint256 amount, uint256 timestamp);
    event InvestWithReferrer(address indexed buyer, address indexed referrer, uint256 amount, uint256 timestamp);
    event Sold();
    event Confirmed();
    event Rejected();
    event StatusChanged(Status oldStatus, Status newStatus, uint256 timestamp);
    event DocumentAdded(string name, string hash, uint256 timestamp);
    event DocumentUpdated(uint256 index, string name, string hash, uint256 timestamp);
    event AssetLocationUpdated(uint256 timestamp);
    event AssetInfoUpdated(uint256 timestamp);

    function buyersLength() external view returns (uint256);

    function getBuyers() external view returns (address[] memory);

    function isBuyer(address buyer) external view returns (bool);

    function invest(address recipient, uint256 amount) external;

    function investWithAmbassador(address recipient, uint256 amount, address ambassador) external;

    function investWithReferrer(address recipient, uint256 amount, address referrer) external;

    function setStatus(Status _status) external;

    function setSaleEndDate(uint256 _saleEndDate) external;

    function setPaymentTokenRange(PaymentTokenRange memory _paymentTokenRange) external;

    function setChainLinkPrice(address _chainLinkPrice) external;

    function confirmSelling(address seller) external;

    function rejectSelling(uint256 offset, uint256 skip) external;

    function rejectSellingUser() external;

    function updateAssetInfo(AssetInfo memory assetInfo) external;

    function updateAssetLocationData(AssetLocationData memory assetLocationData) external;

    function addDocument(Document memory document) external;

    function updateDocument(uint256 documentIndex, Document memory document) external;

    function getDocuments() external view returns (Document[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChainLinkPrice {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommissionsDistributor {
    // if percent is not set(0), it is used fixed amount of commission
    struct CommissionInfo {
        address destination; // address to send commission to
        uint32 percent; // 1000000 = 100% | 100000 = 10% | 10000 = 1% | 1000 = 0.1%
        uint256 fixedAmount; // with decimals
    }

    event InvestmentCommissionPaid(address indexed asset, uint256 amount);
    event RentCommissionPaid(address indexed asset, uint256 amount);

    function getInvestmentsCommission(address asset) external view returns (CommissionInfo[] memory);

    function getRentCommission(address asset) external view returns (CommissionInfo[] memory);

    function setInvestmentsCommission(address _asset, CommissionInfo[] memory _commissions) external;

    function setPayForRentCommission(address _asset, CommissionInfo[] memory _commissions) external;

    function getPayForRentCommissionAmount(address propertyToken, uint256 totalAmount) external view returns (uint256);

    function payRentCommission(address propertyToken, address commissionToken, uint256 totalAmount) external returns (uint256);

    function getInvestmentsCommissionAmount(address asset, uint256 totalAmount) external view returns (uint256);

    function payInvestmentsCommission(address commissionToken, uint256 totalAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardsDistributor {
    event UserBalanceUpdated(address indexed asset, address indexed user, uint256 balance);
    event Claimed(address indexed user, uint256 amount, uint256 timestamp);
    event PoolAdded(address indexed asset, uint256 totalSupply);
    event PoolInitialized(address indexed asset);
    event PaidRent(address indexed user, address indexed asset, uint256 amount, uint128 startTime, uint128 endTime, uint256 timestamp);

    struct UserInfo {
        uint256 amount; // tokens user own
        uint256 rewardDebt; // needed for a SushiSwap's formula... https://dev.to/heymarkkop/understanding-sushiswaps-masterchef-staking-rewards-1m6f
        uint256 baseClaimable; // on user token balance change - we save amount of money available for a claim at that moment
        uint256 lastEmissionPoint; // an array index
        uint256 claimed;
    }

    struct PoolInfo {
        uint256 totalSupply;
        uint256 decimals;
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12.
        uint256 currentEmissionPoint;
        bool isInitialized;
    }

    struct EmissionPoint {
        uint128 startTime;
        uint128 endTime;
        uint256 rewardsPerSecond;
    }

    function getRewardToken() external view returns (address);

    function getPoolInfo(address asset) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);

    function emissionScheduleLength(address _token) external view returns (uint256);

    function getEmissionPoints(address _token, uint256 startIndex) external view returns (EmissionPoint[] memory emissionPoints);

    function calculateActualEmissionPointPerPool(address _token) external view returns (uint256);

    function claim(address user, address[] calldata _tokens) external;

    function onUserBalanceChanged(address _user, uint256 _balance) external;

    function addPool(address _token, uint256 _decimals, uint256 _totalSupply) external;

    function initializePool(address _token) external;

    function payForRent(address _asset, uint256 _amount, uint128 _startTime, uint128 _endTime) external;

    function claimableRewards(address _user, address[] calldata _tokens) external view returns (uint256[] memory);

    function getUserRewards(address _user) external view returns (address[] memory);

    function getUserInfo(address _user, address _token) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IAccessManager.sol";
import "./interfaces/IAddressesProvider.sol";

contract KycStore is Initializable {
    mapping(address => bool) public users;
    mapping(address => string) public userCountries;
    mapping(address => uint) public approvedAt;
    mapping(address => uint) public disabledAt;
    IAddressesProvider public addressesProvider;
    bool public isKycEnabledInTheApp;
    mapping(string => bool) public restrictedIso3Countries;

    event Approve(address user, uint timestamp);
    event Disable(address user, uint timestamp);
    event KycEnabledInTheAppChanged(bool isKycEnabledInTheApp);
    event DeniedCountryAdded(string iso3Country);
    event AllowedCountryAdded(string iso3Country);

    modifier onlyKycAdmin() {
        IAccessManager accessManager = IAccessManager(addressesProvider.getAccessManager());
        require(accessManager.can(msg.sender, IAccessManager.Action.ManageKycList), "Permission denied: ManageKycList");
        _;
    }

    modifier onlyAppConfigurator() {
        IAccessManager accessManager = IAccessManager(addressesProvider.getAccessManager());
        require(accessManager.can(msg.sender, IAccessManager.Action.ConfigureApp), "Permission denied: ConfigureApp");
        _;
    }

    function initialize(address _addressesProvider) external initializer {
        addressesProvider = IAddressesProvider(_addressesProvider);
        isKycEnabledInTheApp = true;
    }

    function getVersion() external pure returns (uint256) {
        return 5;
    }

    function isOperable(address userAddress) public view returns (bool) {
        if (!isKycEnabledInTheApp) {
            return true;
        }
        return users[userAddress] && !restrictedIso3Countries[userCountries[userAddress]];
    }

    function approveWithCountry(address userAddress, string calldata country) public onlyKycAdmin {
        users[userAddress] = true;
        userCountries[userAddress] = country;
        approvedAt[userAddress] = block.timestamp;
        emit Approve(userAddress, block.timestamp);
    }

    function disable(address userAddress) public onlyKycAdmin {
        users[userAddress] = false;
        disabledAt[userAddress] = block.timestamp;
        emit Disable(userAddress, block.timestamp);
    }

    function setIsKycEnabledInTheApp(bool _isEnabledInTheApp) public onlyAppConfigurator {
        isKycEnabledInTheApp = _isEnabledInTheApp;
        emit KycEnabledInTheAppChanged(_isEnabledInTheApp);
    }

    function denyIso3Country(string calldata countryIso3) public onlyAppConfigurator {
        restrictedIso3Countries[countryIso3] = true;
        emit DeniedCountryAdded(countryIso3);
    }

    function allowIso3Country(string calldata countryIso3) public onlyAppConfigurator {
        restrictedIso3Countries[countryIso3] = false;
        emit AllowedCountryAdded(countryIso3);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IAddressesProvider.sol";
import "./interfaces/ICommissionsDistributor.sol";

contract RewardsDistributor is IRewardsDistributor, Initializable {
    using SafeERC20 for IERC20;
    uint256 private constant COMMISSION_PRECISION = 10000; // 100%
    IAddressesProvider public addressesProvider;
    IERC20 public rewardToken;
    uint256 public immutable rewardTokenDecimals = 1e6;

    address[] public registeredAssets;

    // token => Pool Info for that token.
    mapping(address => PoolInfo) public poolInfo;

    // token => Array of Emission point structs.
    mapping(address => EmissionPoint[]) public emissionSchedule;

    // token => user => Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;

    // user => assets
    mapping(address => address[]) public userToRewards;
    // user => token => hasOrNot
    mapping(address => mapping(address => bool)) public userToRewardUniq;

    modifier onlyOwner() {
        require(msg.sender == addressesProvider.getRewardsDistributorAdmin(), "RewardsDistributor: caller is not the RewardsDistributorAdmin");
        _;
    }

    function initialize(IERC20 _rewardToken, IAddressesProvider _addressesProvider) public initializer {
        require(address(_addressesProvider) != address(0), "RewardsDistributor: addresses provider is the zero address");
        require(address(_rewardToken) != address(0), "RewardsDistributor: reward token is the zero address");
        addressesProvider = _addressesProvider;
        rewardToken = _rewardToken;
    }

    function getVersion() external pure returns (uint256) {
        return 2;
    }

    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    function getPoolInfo(address _token) external view override returns (PoolInfo memory) {
        return poolInfo[_token];
    }

    function poolLength() external view override returns (uint256) {
        return registeredAssets.length;
    }

    function emissionScheduleLength(address _token) external view override returns (uint256) {
        return emissionSchedule[_token].length;
    }

    function getEmissionPoints(address _token, uint256 startIndex) external view override returns (EmissionPoint[] memory emissionPoints) {
        uint256 length = emissionSchedule[_token].length;
        emissionPoints = new EmissionPoint[](length - startIndex);
        for (uint256 i = 0; i < length - startIndex; i++) {
            emissionPoints[i] = emissionSchedule[_token][i + startIndex];
        }
    }

    function claimableRewards(address _user, address[] calldata _tokens) external view override returns (uint256[] memory) {
        uint256[] memory claimable = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            PoolInfo memory pool = poolInfo[token];
            uint256 firstEmissionPoint = pool.currentEmissionPoint;
            uint256 lastEmissionPoint = calculateActualEmissionPointPerPool(token);
            if (emissionSchedule[token].length == 0) {
                continue;
            }
            if (firstEmissionPoint == 0 && emissionSchedule[token][firstEmissionPoint].startTime > block.timestamp) {
                pool.lastRewardTime = block.timestamp;
                continue;
            }
            if (firstEmissionPoint == lastEmissionPoint) {
                EmissionPoint memory emissionPoint = emissionSchedule[token][pool.currentEmissionPoint];
                uint256 startTime = emissionPoint.startTime > pool.lastRewardTime ? emissionPoint.startTime : pool.lastRewardTime;
                uint256 endTime = emissionPoint.endTime > block.timestamp ? block.timestamp : emissionPoint.endTime;
                uint256 duration = startTime > endTime ? 0 : endTime - startTime;
                uint256 reward = duration * emissionPoint.rewardsPerSecond;
                pool.accRewardPerShare = pool.accRewardPerShare + ((reward * 1e12) / ((pool.totalSupply * rewardTokenDecimals) / pool.decimals));
                pool.lastRewardTime = endTime;
            } else {
                for (uint256 j = firstEmissionPoint; j <= lastEmissionPoint; j++) {
                    EmissionPoint memory emissionPoint = emissionSchedule[token][j];
                    uint256 startTime = emissionPoint.startTime > pool.lastRewardTime ? emissionPoint.startTime : pool.lastRewardTime;
                    uint256 endTime = emissionPoint.endTime > block.timestamp ? block.timestamp : emissionPoint.endTime;
                    uint256 duration = startTime > endTime ? 0 : endTime - startTime;
                    uint256 reward = duration * emissionPoint.rewardsPerSecond;
                    pool.accRewardPerShare =
                        pool.accRewardPerShare +
                        ((reward * 1e12) / ((pool.totalSupply * rewardTokenDecimals) / pool.decimals));
                    pool.lastRewardTime = endTime;
                }
            }
            UserInfo memory user = userInfo[token][_user];
            claimable[i] = (((user.amount * rewardTokenDecimals) / pool.decimals) * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        }
        return claimable;
    }

    function addPool(address _token, uint256 decimals, uint256 _totalSupply) external override onlyOwner {
        require(poolInfo[_token].lastRewardTime == 0, "Pool already exists");
        registeredAssets.push(_token);
        poolInfo[_token] = PoolInfo({
            totalSupply: _totalSupply,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            currentEmissionPoint: 0,
            isInitialized: false,
            decimals: 10 ** decimals
        });
        emit PoolAdded(_token, _totalSupply);
    }

    function getUserRewards(address _user) external view override returns (address[] memory) {
        return userToRewards[_user];
    }

    function getUserInfo(address _token, address _user) external view override returns (UserInfo memory) {
        return userInfo[_token][_user];
    }

    function initializePool(address _token) public override onlyOwner {
        require(!poolInfo[_token].isInitialized, "Pool already initialized");
        poolInfo[_token].isInitialized = true;
        emit PoolInitialized(_token);
    }

    function onUserBalanceChanged(address _user, uint256 _balance) external override {
        // note: msg.sender here is token's address
        PoolInfo storage pool = poolInfo[msg.sender];
        require(pool.lastRewardTime > 0, "Pool not found");
        _updatePool(msg.sender);
        UserInfo storage user = userInfo[msg.sender][_user];

        if (!userToRewardUniq[_user][msg.sender]) {
            userToRewards[_user].push(msg.sender);
            userToRewardUniq[_user][msg.sender] = true;
        }

        if (user.amount > 0) {
            uint256 pending = (((user.amount * rewardTokenDecimals) / pool.decimals) * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
            if (pending > 0) {
                user.baseClaimable += pending;
            }
        }
        user.amount = _balance;
        user.rewardDebt = (((_balance * rewardTokenDecimals) / pool.decimals) * pool.accRewardPerShare) / 1e12;

        emit UserBalanceUpdated(msg.sender, _user, _balance);
    }

    function claim(address _user, address[] calldata _tokens) external override {
        uint256 pending;
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "Pool not found");
            _updatePool(_tokens[i]);

            UserInfo storage user = userInfo[_tokens[i]][_user];
            uint256 currentRewardDebt = (((user.amount * rewardTokenDecimals) / pool.decimals) * pool.accRewardPerShare) / 1e12;
            uint rewardFromThisAsset = (currentRewardDebt - user.rewardDebt) + user.baseClaimable;
            user.claimed += rewardFromThisAsset;
            pending = pending + rewardFromThisAsset;
            user.baseClaimable = 0;
            user.rewardDebt = currentRewardDebt;
        }
        safeRewardTokenTransfer(_user, pending);
        emit Claimed(_user, pending, block.timestamp);
    }

    function calculateActualEmissionPointPerPool(address _token) public view override returns (uint256) {
        uint256 currentEmissionPoint = poolInfo[_token].currentEmissionPoint;
        EmissionPoint[] storage schedule = emissionSchedule[_token];
        if (schedule.length == 0) {
            return 0;
        }
        for (uint256 i = currentEmissionPoint; i < schedule.length; i++) {
            if (schedule[i].startTime <= block.timestamp && block.timestamp < schedule[i].endTime) {
                return i;
            }
        }
        return schedule.length - 1;
    }

    function payForRent(address token, uint256 amount, uint128 startTime, uint128 endTime) public override onlyOwner {
        require(poolInfo[token].isInitialized, "Pool not initialized");
        require(amount > 0, "Asset: amount must be greater than 0");
        require(startTime < endTime, "Asset: startTime must be less than endTime");
        if (emissionSchedule[token].length != 0) {
            require(
                emissionSchedule[token][emissionSchedule[token].length - 1].endTime <= startTime,
                "Asset: startTime must be greater or equal to last emission endTime"
            );
        }
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        ICommissionsDistributor commissionDistributor = ICommissionsDistributor(addressesProvider.getCommissionsDistributor());
        uint256 commission = commissionDistributor.getPayForRentCommissionAmount(token, amount);
        rewardToken.safeApprove(address(commissionDistributor), commission);
        uint256 totalCommission = commissionDistributor.payRentCommission(token, address(rewardToken), amount);
        uint128 duration = endTime - startTime;
        uint256 rewardsPerSecond = (amount - totalCommission) / duration;
        EmissionPoint memory emissionPoint = EmissionPoint(startTime, endTime, rewardsPerSecond);
        emissionSchedule[token].push(emissionPoint);
        _updatePool(token);
        emit PaidRent(msg.sender, token, amount, startTime, endTime, block.timestamp);
    }

    function _updatePool(address _token) internal {
        PoolInfo storage pool = poolInfo[_token];
        if (block.timestamp <= pool.lastRewardTime || !pool.isInitialized || emissionSchedule[_token].length == 0) {
            return;
        }
        uint256 firstEmissionPoint = pool.currentEmissionPoint;
        uint256 lastEmissionPoint = calculateActualEmissionPointPerPool(_token);
        if (firstEmissionPoint == 0 && emissionSchedule[_token][firstEmissionPoint].startTime > block.timestamp) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (firstEmissionPoint == lastEmissionPoint) {
            EmissionPoint memory emissionPoint = emissionSchedule[_token][pool.currentEmissionPoint];
            uint256 startTime = emissionPoint.startTime > pool.lastRewardTime ? emissionPoint.startTime : pool.lastRewardTime;
            uint256 endTime = emissionPoint.endTime > block.timestamp ? block.timestamp : emissionPoint.endTime;
            uint256 duration = startTime > endTime ? 0 : endTime - startTime;
            uint256 reward = duration * emissionPoint.rewardsPerSecond;
            pool.accRewardPerShare = pool.accRewardPerShare + ((reward * 1e12) / ((pool.totalSupply * rewardTokenDecimals) / pool.decimals));
            pool.lastRewardTime = endTime;
        } else {
            for (uint256 i = firstEmissionPoint; i <= lastEmissionPoint; i++) {
                EmissionPoint memory emissionPoint = emissionSchedule[_token][i];
                uint256 endTime = emissionPoint.endTime > block.timestamp ? block.timestamp : emissionPoint.endTime;
                uint256 startTime = emissionPoint.startTime > pool.lastRewardTime ? emissionPoint.startTime : pool.lastRewardTime;
                uint256 duration = startTime > endTime ? 0 : endTime - startTime;
                uint256 reward = duration * emissionPoint.rewardsPerSecond;
                pool.accRewardPerShare = pool.accRewardPerShare + ((reward * 1e12) / ((pool.totalSupply * rewardTokenDecimals) / pool.decimals));
                pool.lastRewardTime = endTime;
            }
            pool.currentEmissionPoint = lastEmissionPoint;
        }
    }

    function safeRewardTokenTransfer(address _to, uint256 _amount) private {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            rewardToken.safeTransfer(_to, rewardTokenBalance);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}