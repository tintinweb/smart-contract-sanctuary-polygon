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

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {ITip} from "../interfaces/ITip.sol";
import {LibDIVA} from "../libraries/LibDIVA.sol";
import {LibDIVAStorage} from "../libraries/LibDIVAStorage.sol";

contract TipFacet is ITip, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    function addTip(bytes32 _poolId, uint256 _amount)
        external
        override
        nonReentrant
    {
        _addTip(
            _poolId,
            _amount,
            LibDIVAStorage._poolStorage(),
            LibDIVAStorage._feeClaimStorage()
        );
    }

    function batchAddTip(ArgsBatchAddTip[] calldata _argsBatchAddTip)
        external
        override
        nonReentrant
    {
        uint256 len = _argsBatchAddTip.length;
        for (uint256 i; i < len; ) {
            _addTip(
                _argsBatchAddTip[i].poolId,
                _argsBatchAddTip[i].amount,
                LibDIVAStorage._poolStorage(),
                LibDIVAStorage._feeClaimStorage()
            );
            unchecked {
                ++i;
            }
        }
    }

    function _addTip(
        bytes32 _poolId,
        uint256 _amount,
        LibDIVAStorage.PoolStorage storage _ps,
        LibDIVAStorage.FeeClaimStorage storage _fs
    ) private {
        // Load pool
        LibDIVAStorage.Pool storage _pool = _ps.pools[_poolId];

        // Check if pool exists
        if (!LibDIVA._poolExists(_pool)) revert NonExistentPool();

        // Confirm that no value has been submitted yet
        if (_pool.statusFinalReferenceValue != LibDIVAStorage.Status.Open)
            revert FinalValueAlreadySubmitted();
        
        // Cache collateral token
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // Update claim mapping
        _fs.poolIdToReservedClaim[_poolId] += _amount;

        // Check collateral token balance before and after the transfer to account
        // for potential fees. Transfer approved collateral token from `msg.sender`
        // if no fees are charged. Otherwise, revert.
        uint256 _before = collateralToken.balanceOf(address(this));
        collateralToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = collateralToken.balanceOf(address(this));

        if (_after - _before != _amount) {
            revert FeeTokensNotSupported();
        }

        // Log event
        emit TipAdded(msg.sender, _poolId, address(collateralToken), _amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Position token contract
 * @dev The `PositionToken` contract inherits from ERC20 contract and stores
 * the Id of the pool that the position token is linked to. It implements a
 * `mint` and a `burn` function which can only be called by the `PositionToken`
 * contract owner.
 *
 * Two `PositionToken` contracts are deployed during pool creation process
 * (`createContingentPool`) with Diamond contract being set as the owner.
 * The `mint` function is used during pool creation (`createContingentPool`)
 * and addition of liquidity (`addLiquidity`). Position tokens are burnt
 * during token redemption (`redeemPositionToken`) and removal of liquidity
 * (`removeLiquidity`). The address of the position tokens is stored in the
 * pool parameters within Diamond contract and used to verify the tokens that
 * a user sends back to withdraw collateral.
 *
 * Position tokens have the same number of decimals as the underlying
 * collateral token.
 */
interface IPositionToken is IERC20Upgradeable {
    /**
     * @notice Function to initialize the position token instance
     */
    function initialize(
        string memory symbol_, // name is set equal to symbol
        bytes32 poolId_,
        uint8 decimals_,
        address owner_
    ) external;

    /**
     * @notice Function to mint ERC20 position tokens.
     * @dev Called during  `createContingentPool` and `addLiquidity`.
     * Can only be called by the owner of the position token which
     * is the Diamond contract in the context of DIVA.
     * @param _recipient The account receiving the position tokens.
     * @param _amount The number of position tokens to mint.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @notice Function to burn position tokens.
     * @dev Called within `redeemPositionToken` and `removeLiquidity`.
     * Can only be called by the owner of the position token which
     * is the Diamond contract in the context of DIVA.
     * @param _redeemer Address redeeming positions tokens in return for
     * collateral.
     * @param _amount The number of position tokens to burn.
     */
    function burn(address _redeemer, uint256 _amount) external;

    /**
     * @notice Returns the Id of the contingent pool that the position token is
     * linked to in the context of DIVA.
     * @return The poolId.
     */
    function poolId() external view returns (bytes32);

    /**
     * @notice Returns the owner of the position token (Diamond contract in the
     * context of DIVA).
     * @return The address of the position token owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IPositionTokenFactory {
    /**
     * @notice Creates a clone of the permissionless position token contract.
     * @param _symbol Symbol string of the position token. Name is set equal to symbol.
     * @param _poolId The Id of the contingent pool that the position token belongs to.
     * @param _decimals Decimals of position token (same as collateral token).
     * @param _owner Owner of the position token. Should always be DIVA Protocol address.
     * @param _permissionedERC721Token Address of permissioned ERC721 token.
     * @return clone Returns the address of the clone contract.
     */
    function createPositionToken(
        string memory _symbol,
        bytes32 _poolId,
        uint8 _decimals,
        address _owner,
        address _permissionedERC721Token
    ) external returns (address clone);

    /**
     * @notice Address where the position token implementation contract is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
     */
    function positionTokenImplementation() external view returns (address);

    /**
     * @notice Address where the permissioned position token implementation contract
     * is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
     */
    function permissionedPositionTokenImplementation() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface ITip {
    // Thrown in `addTip` if pool doesn't exist
    error NonExistentPool();

    // Thrown in `addTip` if status of `finalReferenceValue`
    // is no longer "Open"
    error FinalValueAlreadySubmitted();

    // Thrown in `addTip` if the collateral token implements a fee
    error FeeTokensNotSupported();

    // Struct for `batchAddTip` function input
    struct ArgsBatchAddTip {
        bytes32 poolId;
        uint256 amount;
    }

    /**
     * @notice Emitted when a tip is added to a pool.
     * @param tipper Tipper address
     * @param poolId Pool Id tipped
     * @param collateralToken Collateral token address
     * @param amount Tip amount
     */
    event TipAdded(
        address indexed tipper,
        bytes32 indexed poolId,
        address indexed collateralToken,
        uint256 amount
    );

    /**
     * @notice Function to add a tip in collateral token to a specific pool.
     * @dev Requires prior approval from `msg.sender` to transfer the token.
     * Fee-on-transfer tokens are not supported.
     * @param _poolId Id of pool to tip
     * @param _amount Collateral token amount to add as a tip (expressed as
     * an integer with collateral token decimals)
     */
    function addTip(bytes32 _poolId, uint256 _amount) external;

    /**
     * @notice Batch version of `addTip`.
     * @dev Requires prior approval from `msg.sender` to transfer the tokens.
     * @param _argsBatchAddTip Struct array containing poolIds and tip amounts
     * (expressed as an integer with collateral token decimals)
     */
    function batchAddTip(ArgsBatchAddTip[] calldata _argsBatchAddTip) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {IPositionTokenFactory} from "../interfaces/IPositionTokenFactory.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown in `addLiquidity`, `fillOfferAddLiquidity`, `removeLiquidity`,
// and `fillOfferRemoveLiquidity` if pool doesn't exist
error NonExistentPool();

// Thrown in `removeLiquidity` or `redeemPositionToken` if collateral amount
// to be returned to user during exceeds the pool's collateral balance
error AmountExceedsPoolCollateralBalance();

// Thrown in `removeLiquidity` if the fee amount to be allocated exceeds the
// pool's current collateral balance
error FeeAmountExceedsPoolCollateralBalance();

// Thrown in `addLiquidity` if the pool is already expired
error PoolExpired();

// Thrown in `createContingentPool` if the input parameters are invalid
error InvalidInputParamsCreateContingentPool();

// Thrown in `createContingentPool` and `addLiquidity` if the collateral token
// implements a fee
error FeeTokensNotSupported();

// Thrown in `addLiquidity` if adding additional collateral would
// result in the pool capacity being exceeded
error PoolCapacityExceeded();

// Thrown in `removeLiquidity` if return collateral is paused
error ReturnCollateralPaused();

// Thrown in `removeLiquidity` if status of `finalReferenceValue`
// is already "Confirmed"
error FinalValueAlreadyConfirmed();

// Thrown in `removeLiquidity` if a user's short or long position
// token balance is smaller than the indicated amount
error InsufficientShortOrLongBalance();

// Thrown in `removeLiquidity` if `_amount` provided by user results
// in a zero protocol fee amount; user should increase their `_amount`
error ZeroProtocolFee();

// Thrown in `removeLiquidity` if `_amount` provided by user results
// in zero settlement fee amount; user should increase `_amount`
error ZeroSettlementFee();

library LibDIVA {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        address longRecipient;
        address shortRecipient;
        address permissionedERC721Token;
    }

    // Argument for `_createContingentPoolLib` function
    struct CreatePoolParams {
        PoolParams poolParams;
        uint256 collateralAmountMsgSender;
        uint256 collateralAmountMaker;
        address maker;
    }

    // Argument for `_addLiquidityLib` to avoid stack-too-deep error
    struct AddLiquidityParams {
        bytes32 poolId;
        uint256 collateralAmountMsgSender;
        uint256 collateralAmountMaker;
        address maker;
        address longRecipient;
        address shortRecipient;
    }

    // Argument for `_removeLiquidityLib` to avoid stack-too-deep error
    struct RemoveLiquidityParams {
        bytes32 poolId;
        uint256 amount;
        address longTokenHolder;
        address shortTokenHolder;
    }

    /**
     * @notice Emitted when fees are allocated.
     * @dev Collateral token can be looked up via the `getPoolParameters`
     * function using the emitted `poolId`.
     * @param poolId The Id of the pool that the fee applies to.
     * @param recipient Address that is allocated the fees.
     * @param amount Fee amount allocated.
     */
    event FeeClaimAllocated(
        bytes32 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when fees are reserved for data provider in 
     * `removeLiquidity`.
     * @dev Collateral token can be looked up via the `getPoolParameters`
     * function using the emitted `poolId`.
     * @param poolId The Id of the pool that the fee applies to.
     * @param amount Fee amount reserved.
     */
    event FeeClaimReserved(
        bytes32 indexed poolId,
        uint256 amount
    );

    /**
     * @notice Emitted when a new pool is created.
     * @param poolId The Id of the newly created contingent pool.
     * @param longRecipient The address that received the long position tokens.
     * @param shortRecipient The address that received the short position tokens.
     * @param collateralAmount The collateral amount deposited into the pool.
     * @param permissionedERC721Token Address of ERC721 token that the transfer
     * restrictions apply to.
     */
    event PoolIssued(
        bytes32 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount,
        address permissionedERC721Token
    );

    /**
     * @notice Emitted when new collateral is added to an existing pool.
     * @param poolId The Id of the pool that collateral was added to.
     * @param longRecipient The address that received the long position token.
     * @param shortRecipient The address that received the short position token.
     * @param collateralAmount The collateral amount added.
     */
    event LiquidityAdded(
        bytes32 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount
    );

    /**
     * @notice Emitted when collateral is removed from an existing pool.
     * @param poolId The Id of the pool that collateral was removed from.
     * @param longTokenHolder The address of the user that contributed the long token.
     * @param shortTokenHolder The address of the user that contributed the short token.
     * @param collateralAmount The collateral amount removed from the pool.
     */
    event LiquidityRemoved(
        bytes32 indexed poolId,
        address indexed longTokenHolder,
        address indexed shortTokenHolder,
        uint256 collateralAmount
    );

    /**
     * @notice Emitted when tips and reserved fees (the "reserve") have been allocated to the
     * data provider after the final value has been confirmed.
     * @param poolId Id of the pool for which the reserve has been allocated
     * @param recipient Address of the reserve recipient, typically the data provider
     * @param amount Reserve amount allocated (in collateral token)
     */
    event ReservedClaimAllocated(
        bytes32 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;
    uint256 private constant UINT_96_MASK = (1 << 96) - 1;

    function _poolParameters(bytes32 _poolId)
        internal
        view
        returns (LibDIVAStorage.Pool memory)
    {
        return LibDIVAStorage._poolStorage().pools[_poolId];
    }

    function _getPoolCount() internal view returns (uint256) {
        return LibDIVAStorage._poolStorage().nonce;
    }

    function _getClaim(address _collateralToken, address _recipient)
        internal
        view
        returns (uint256)
    {
        return
            LibDIVAStorage._feeClaimStorage().claimableFeeAmount[
                _collateralToken
            ][_recipient];
    }

    function _getReservedClaim(bytes32 _poolId) internal view returns (uint256) {
        return LibDIVAStorage._feeClaimStorage().poolIdToReservedClaim[_poolId];
    }

    /**
     * @dev Internal function to transfer the collateral to the user.
     * Openzeppelin's `safeTransfer` method is used to handle different
     * implementations of the ERC20 standard.
     * @param _pool Pool struct.
     * @param _receiver Recipient address.
     * @param _amount Collateral amount to return.
     */
    function _returnCollateral(
        LibDIVAStorage.Pool storage _pool,
        address _receiver,
        uint256 _amount
    ) internal {
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // That case shouldn't happen, but if it happens unexpectedly, then
        // it will throw here.
        if (_amount > _pool.collateralBalance)
            revert AmountExceedsPoolCollateralBalance();

        _pool.collateralBalance -= _amount;

        collateralToken.safeTransfer(_receiver, _amount);
    }

    /**
     * @notice Internal function to calculate the payoff per long and short token,
     * net of fees, and store it in `payoutLong` and `payoutShort` inside pool
     * parameters.
     * @dev Called inside `redeemPositionToken` and `setFinalReferenceValue`
     * functions after status of final reference value has been confirmed.
     * @param _pool Pool struct.
     * @param _fees Fees struct.
     * @param _collateralTokenDecimals Collateral token decimals. Passed as
     * argument to avoid reading from storage again.
     */
    function _setPayoutAmount(
        LibDIVAStorage.Pool storage _pool,
        LibDIVAStorage.Fees memory _fees,
        uint8 _collateralTokenDecimals
    ) internal {
        // Calculate payoff per short and long token. Output is in collateral
        // token decimals.
        (_pool.payoutShort, _pool.payoutLong) = _calcPayoffs(
            _pool.floor,
            _pool.inflection,
            _pool.cap,
            _pool.gradient,
            _pool.finalReferenceValue,
            _collateralTokenDecimals,
            _fees.protocolFee + _fees.settlementFee
        );
    }

    /**
     * @notice Internal function used within `setFinalReferenceValue` and
     * `redeemPositionToken` to calculate and allocate fee claims to recipient
     * (DIVA Treasury or data provider). Fee is applied to the overall
     * collateral remaining in the pool and allocated in full the first time
     * the respective function is triggered.
     * @dev Fees can be claimed via the `claimFee` function.
     * @param _poolId Pool Id.
     * @param _pool Pool struct.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * @param _recipient Fee recipient address.
     * @param _collateralBalance Current pool collateral balance expressed as
     * an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     */
    function _calcAndAllocateFeeClaim(
        bytes32 _poolId,
        LibDIVAStorage.Pool storage _pool,
        uint96 _fee,
        address _recipient,
        uint256 _collateralBalance,
        uint8 _collateralTokenDecimals
    ) internal {
        uint256 _feeAmount = _calcFee(
            _fee,
            _collateralBalance,
            _collateralTokenDecimals
        );

        _allocateFeeClaim(_poolId, _pool, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to allocate fees to `recipient`.
     * @dev The balance of the recipient is tracked inside the contract and
     * can be claimed via `claimFee` function.
     * @param _poolId Pool Id that the fee applies to.
     * @param _pool Pool struct.
     * @param _recipient Address of the fee recipient.
     * @param _feeAmount Total fee amount expressed as an integer with
     * collateral token decimals.
     */
    function _allocateFeeClaim(
        bytes32 _poolId,
        LibDIVAStorage.Pool storage _pool,
        address _recipient,
        uint256 _feeAmount
    ) internal {
        // Check that fee amount to be allocated doesn't exceed the pool's
        // current `collateralBalance`. This check should never trigger, but
        // kept for safety.
        if (_feeAmount > _pool.collateralBalance)
            revert FeeAmountExceedsPoolCollateralBalance();

        // Reduce `collateralBalance` in pool parameters and increase fee claim
        _pool.collateralBalance -= _feeAmount;
        LibDIVAStorage._feeClaimStorage()
            .claimableFeeAmount[_pool.collateralToken][_recipient] += _feeAmount;

        // Log poolId, recipient and fee amount
        emit FeeClaimAllocated(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to reserve settlement fees accrued during `removeLiquidity`
     * for data provider. The function is very similar to `_allocateFeeClaim`.
     * @dev The fee will be allocated to the actual data provider, which may be
     * either the assigned data provider or the fallback data provider, once the final value
     * has been confirmed. If neither of them reports a value, the reserved fee will be
     * allocated to the treasury.
     * @param _poolId Pool Id that the fee applies to.
     * @param _pool Pool struct.
     * @param _feeAmount Total fee amount expressed as an integer with
     * collateral token decimals.
     */
    function _reserveFeeClaim(
        bytes32 _poolId,
        LibDIVAStorage.Pool storage _pool,
        uint256 _feeAmount
    ) internal {
        // Check that fee amount to be reserved doesn't exceed the pool's
        // current `collateralBalance`. This check should never trigger, but
        // kept for safety.
        if (_feeAmount > _pool.collateralBalance)
            revert FeeAmountExceedsPoolCollateralBalance();
        
        // Reduce `collateralBalance` in pool parameters and increase
        // fee claim reserve
        _pool.collateralBalance -= _feeAmount;
        LibDIVAStorage._feeClaimStorage()
            .poolIdToReservedClaim[_poolId] += _feeAmount;

        // Log poolId and fee amount
        emit FeeClaimReserved(_poolId, _feeAmount);
    }

    /**
     * @notice Internal function to transfer the reserved fee and tip to the data provider when the
     * final reference value is confirmed.
     * @dev `poolIdToReservedClaim` is set to zero and credited to the claimable fee amount.
     * @param _poolId Id of pool.
     * @param _recipient Reserve recipient.
     */
    function _allocateReservedClaim(bytes32 _poolId, address _recipient) internal {
        // Get reference to relevant storage slot
        LibDIVAStorage.FeeClaimStorage storage fs = LibDIVAStorage._feeClaimStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = LibDIVAStorage._poolStorage().pools[_poolId];

        // Get reserve for pool
        uint256 _reserve = fs.poolIdToReservedClaim[_poolId];

        // Credit reserve to the claimable fee amount
        fs.poolIdToReservedClaim[_poolId] = 0;
        fs.claimableFeeAmount[_pool.collateralToken][_recipient] += _reserve;

        // Log event
        emit ReservedClaimAllocated(_poolId, _recipient, _reserve);
    }

    /**
     * @notice Function to calculate the fee amount for a given collateral amount.
     * @dev Output is an integer expressed with collateral token decimals.
     * As fee parameter has 18 decimals but collateral tokens may have
     * less, scaling needs to be applied when using `SafeDecimalMath` library.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * (e.g., 0.25% is 2500000000000000).
     * @param _collateralAmount Collateral amount that is used as the basis for
     * the fee calculation expressed as an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @return The fee amount expressed as an integer with collateral token decimals.
     */
    function _calcFee(
        uint96 _fee,
        uint256 _collateralAmount,
        uint8 _collateralTokenDecimals
    ) internal pure returns (uint256) {

        uint256 _SCALINGFACTOR;
        unchecked {
            // Cannot over-/underflow as collateral token decimals are restricted to
            // a minimum of 6 and a maximum of 18.
            _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        }

        uint256 _feeAmount = uint256(_fee).multiplyDecimal(
            _collateralAmount * _SCALINGFACTOR
        ) / _SCALINGFACTOR;

        return _feeAmount;
    }

    /**
     * @notice Function to calculate the payoffs per long and short token,
     * net of fees.
     * @dev Scaling applied during calculations to handle different decimals.
     * @param _floor Value of underlying at or below which the short token
     * will pay out the max amount and the long token zero. Expressed as an
     * integer with 18 decimals.
     * @param _inflection Value of underlying at which the long token will
     * payout out `_gradient` and the short token `1-_gradient`. Expressed
     * as an integer with 18 decimals.
     * @param _cap Value of underlying at or above which the long token will
     * pay out the max amount and short token zero. Expressed as an integer
     * with 18 decimals.
     * @param _gradient Long token payout at inflection (0 <= _gradient <= 1).
     * Expressed as an integer with collateral token decimals.
     * @param _finalReferenceValue Final value submitted by data provider
     * expressed as an integer with 18 decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @param _fee Fee in percent expressed as an integer with 18 decimals.
     * @return payoffShortNet Payoff per short token (net of fees) expressed
     * as an integer with collateral token decimals.
     * @return payoffLongNet Payoff per long token (net of fees) expressed
     * as an integer with collateral token decimals.
     */
    function _calcPayoffs(
        uint256 _floor,
        uint256 _inflection,
        uint256 _cap,
        uint256 _gradient,
        uint256 _finalReferenceValue,
        uint256 _collateralTokenDecimals,
        uint96 _fee // max value: 1.5% <= 2^96
    ) internal pure returns (uint96 payoffShortNet, uint96 payoffLongNet) {
        uint256 _SCALINGFACTOR;
        unchecked {
            // Cannot over-/underflow as collateral token decimals are restricted to
            // a minimum of 6 and a maximum of 18.
            _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        }
        uint256 _UNIT = SafeDecimalMath.UNIT;
        uint256 _payoffLong;
        uint256 _payoffShort;
        // Note: _gradient * _SCALINGFACTOR not cached for calculations
        // as it would result in a stack-too-deep error

        if (_finalReferenceValue == _inflection) {
            _payoffLong = _gradient * _SCALINGFACTOR;
        } else if (_finalReferenceValue <= _floor) {
            _payoffLong = 0;
        } else if (_finalReferenceValue >= _cap) {
            _payoffLong = _UNIT;
        } else if (_finalReferenceValue < _inflection) {
            _payoffLong = (
                (_gradient * _SCALINGFACTOR).multiplyDecimal(
                    _finalReferenceValue - _floor
                )
            ).divideDecimal(_inflection - _floor);
        } else {
            // Case: cap > _finalReferenceValue > _inflection
            _payoffLong =
                _gradient *
                _SCALINGFACTOR +
                (
                    (_UNIT - _gradient * _SCALINGFACTOR).multiplyDecimal(
                        _finalReferenceValue - _inflection
                    )
                ).divideDecimal(_cap - _inflection);
        }

        unchecked {
            // Underflow not possible: as 0 <= _payoffLong <= _UNIT
            _payoffShort = _UNIT - _payoffLong;

            payoffShortNet = uint96(
                _payoffShort.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
            );
            payoffLongNet = uint96(
                _payoffLong.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
            );
        }        

        return (payoffShortNet, payoffLongNet); // collateral token decimals
    }

    function _createContingentPoolLib(CreatePoolParams memory _createPoolParams)
        internal
        returns (bytes32)
    {
        // Get reference to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Create reference to collateral token corresponding to the provided pool Id
        IERC20Metadata collateralToken = IERC20Metadata(
            _createPoolParams.poolParams.collateralToken
        );

        uint8 _collateralTokenDecimals = collateralToken.decimals();

        // Check validity of input parameters
        if (
            !_validateInputParamsCreateContingentPool(
                _createPoolParams.poolParams,
                _collateralTokenDecimals
            )
        ) revert InvalidInputParamsCreateContingentPool();

        // Increment internal `nonce` every time a new pool is created. Index
        // starts at 1. No overflow risk when using compiler version >= 0.8.0.
        ++ps.nonce;

        // Calculate `poolId` as the hash of pool params, msg.sender and nonce.
        // This is to protect users from malicious pools in the event of chain reorgs.
        bytes32 _poolId = _getPoolId(_createPoolParams, ps);

        // Transfer approved collateral tokens from `msg.sender` to `this`. Note that
        // the transfer will revert for fee tokens.
        // Block scoping applied to avoid stack-too-deep error.
        {
            uint256 _before = collateralToken.balanceOf(address(this));
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                _createPoolParams.collateralAmountMsgSender
            );

            // Transfer approved collateral tokens from maker. Applies only for `fillOfferCreateContingentPool`
            // when makerFillAmount > 0. Requires prior approval from `maker` to execute this transaction.
            if (_createPoolParams.collateralAmountMaker != 0) {
                collateralToken.safeTransferFrom(
                    _createPoolParams.maker,
                    address(this),
                    _createPoolParams.collateralAmountMaker
                );
            }
            uint256 _after = collateralToken.balanceOf(address(this));

            // Revert if a fee was applied during transfer. Throws if `_before > _after`.
            if (_after - _before != _createPoolParams.collateralAmountMsgSender + _createPoolParams.collateralAmountMaker) {
                revert FeeTokensNotSupported();
            }
        }

        // Deploy two `PositionToken` contract clones, one that represents shares in the short
        // and one that represents shares in the long position.
        // Naming convention for short/long token: S13/L13 where 13 is the nonce.
        // Diamond contract (address(this) due to delegatecall) is set as the
        // owner of the position tokens and is the only account that is
        // authorized to call the `mint` and `burn` function therein.
        // Note that position tokens have same number of decimals as collateral token.
        address _shortToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("S", Strings.toString(ps.nonce))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _createPoolParams.poolParams.permissionedERC721Token
            );

        address _longToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("L", Strings.toString(ps.nonce))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _createPoolParams.poolParams.permissionedERC721Token
            );

        (uint48 _indexFees, ) = _getCurrentFees(gs);
        (uint48 _indexSettlementPeriods, ) = _getCurrentSettlementPeriods(gs);

        // Store `Pool` struct in `pools` mapping for the newly generated `poolId`
        ps.pools[_poolId] = LibDIVAStorage.Pool(
            _createPoolParams.poolParams.floor,
            _createPoolParams.poolParams.inflection,
            _createPoolParams.poolParams.cap,
            _createPoolParams.poolParams.gradient,
            _createPoolParams.poolParams.collateralAmount,
            0, // finalReferenceValue
            _createPoolParams.poolParams.capacity,
            block.timestamp,
            _shortToken,
            0, // payoutShort
            _longToken,
            0, // payoutLong
            _createPoolParams.poolParams.collateralToken,
            _createPoolParams.poolParams.expiryTime,
            address(_createPoolParams.poolParams.dataProvider),
            _indexFees,
            _indexSettlementPeriods,
            LibDIVAStorage.Status.Open,
            _createPoolParams.poolParams.referenceAsset
        );

        // Number of position tokens is set equal to the total collateral to
        // standardize the max payout at 1.0. Position tokens are sent to the recipients
        // provided as part of the input parameters.
        IPositionToken(_shortToken).mint(
            _createPoolParams.poolParams.shortRecipient,
            _createPoolParams.poolParams.collateralAmount
        );
        IPositionToken(_longToken).mint(
            _createPoolParams.poolParams.longRecipient,
            _createPoolParams.poolParams.collateralAmount
        );

        // Log pool creation
        emit PoolIssued(
            _poolId,
            _createPoolParams.poolParams.longRecipient,
            _createPoolParams.poolParams.shortRecipient,
            _createPoolParams.poolParams.collateralAmount,
            _createPoolParams.poolParams.permissionedERC721Token
        );

        return _poolId;
    }

    // Return `poolId` which is the hash of create pool parameters, msg.sender and nonce.
    // This is to protect users from depositing into malicious pools in case of chain reorgs.
    function _getPoolId(
        CreatePoolParams memory _createPoolParams,
        LibDIVAStorage.PoolStorage storage _ps
    ) private view returns (bytes32 poolId) {
        // Assembly for more efficient computing:
        // bytes32 _poolId = keccak256(
        //     abi.encode(
        //         keccak256(bytes(_createPoolParams.poolParams.referenceAsset)),
        //         _createPoolParams.poolParams.expiryTime,
        //         _createPoolParams.poolParams.floor,
        //         _createPoolParams.poolParams.inflection,
        //         _createPoolParams.poolParams.cap,
        //         _createPoolParams.poolParams.gradient,
        //         _createPoolParams.poolParams.collateralAmount,
        //         _createPoolParams.poolParams.collateralToken,
        //         _createPoolParams.poolParams.dataProvider,
        //         _createPoolParams.poolParams.capacity,
        //         _createPoolParams.poolParams.longRecipient,
        //         _createPoolParams.poolParams.shortRecipient,
        //         _createPoolParams.poolParams.permissionedERC721Token,
        //         _createPoolParams.collateralAmountMsgSender,
        //         _createPoolParams.collateralAmountMaker,
        //         _createPoolParams.maker,
        //         msg.sender,
        //         ps.nonce
        //     )
        // );
        assembly {
            let mem := mload(0x40)
            // _createPoolParams.poolParams.referenceAsset;
            // Get memory pointer where the `poolParams` struct information is stored.
            let poolParams := mload(_createPoolParams)
            // At the `poolParams` location, get the memory pointer where the length
            // of the `referenceAsset` string is stored.
            let referenceAsset := mload(poolParams)
            // Store the hash of the string at position `mem`. `mload(referenceAsset)` is
            // the string length, `add(referenceAsset, 0x20)` is the location where the
            // actual string starts.
            mstore(
                mem,
                keccak256(add(referenceAsset, 0x20), mload(referenceAsset))
            )
            // _createPoolParams.poolParams.expiryTime;
            mstore(
                add(mem, 0x20),
                and(UINT_96_MASK, mload(add(poolParams, 0x20)))
            )
            // _createPoolParams.poolParams.floor;
            mstore(add(mem, 0x40), mload(add(poolParams, 0x40)))
            // _createPoolParams.poolParams.inflection;
            mstore(add(mem, 0x60), mload(add(poolParams, 0x60)))
            // _createPoolParams.poolParams.cap;
            mstore(add(mem, 0x80), mload(add(poolParams, 0x80)))
            // _createPoolParams.poolParams.gradient;
            mstore(add(mem, 0xA0), mload(add(poolParams, 0xA0)))
            // _createPoolParams.poolParams.collateralAmount;
            mstore(add(mem, 0xC0), mload(add(poolParams, 0xC0)))
            // _createPoolParams.poolParams.collateralToken;
            mstore(add(mem, 0xE0),
                and(ADDRESS_MASK, mload(add(poolParams, 0xE0)))
            )
            // _createPoolParams.poolParams.dataProvider;
            mstore(add(mem, 0x100),
                and(ADDRESS_MASK, mload(add(poolParams, 0x100)))
            )
            // _createPoolParams.poolParams.capacity;
            mstore(add(mem, 0x120), mload(add(poolParams, 0x120)))
            // _createPoolParams.poolParams.longRecipient;
            mstore(add(mem, 0x140),
                and(ADDRESS_MASK, mload(add(poolParams, 0x140)))
            )
            // _createPoolParams.poolParams.shortRecipient;
            mstore(add(mem, 0x160),
                and(ADDRESS_MASK, mload(add(poolParams, 0x160)))
            )
            // _createPoolParams.poolParams.permissionedERC721Token;
            mstore(add(mem, 0x180),
                and(ADDRESS_MASK, mload(add(poolParams, 0x180)))
            )
            // _createPoolParams.collateralAmountMsgSender;
            mstore(add(mem, 0x1A0), mload(add(_createPoolParams, 0x20))) // First slot after poolParams struct reference
            // _createPoolParams.collateralAmountMaker;
            mstore(add(mem, 0x1C0), mload(add(_createPoolParams, 0x40)))
            // _createPoolParams.maker;
            mstore(add(mem, 0x1E0),
                and(ADDRESS_MASK, mload(add(_createPoolParams, 0x60)))
            )
            // msg.sender;
            mstore(add(mem, 0x200), and(ADDRESS_MASK, caller()))
            // ps.nonce
            // IMPORTANT: Assumes `nonce` to be at position zero inside `PoolStorage` struct
            mstore(add(mem, 0x220), sload(_ps.slot))

            poolId := keccak256(mem, 0x240)
        }
    }

    function _validateInputParamsCreateContingentPool(
        PoolParams memory _poolParams,
        uint8 _collateralTokenDecimals
    ) internal view returns (bool) {
        // Expiry time should not be equal to or smaller than `block.timestamp`
        if (_poolParams.expiryTime <= block.timestamp) {
            return false;
        }

        // Reference asset should not be empty string
        if (bytes(_poolParams.referenceAsset).length == 0) {
            return false;
        }

        // Floor should not be greater than inflection
        if (_poolParams.floor > _poolParams.inflection) {
            return false;
        }

        // Cap should not be smaller than inflection
        if (_poolParams.cap < _poolParams.inflection) {
            return false;
        }

        // Cap should not exceed 1e59 to prevent overflow in
        // `LibDIVA._calcPayoffs` in the scenario
        // `cap > finalReferenceValue > inflection`
        if (_poolParams.cap > 1e59) {
            return false;
        }

        // Data provider should not be zero address
        if (_poolParams.dataProvider == address(0)) {
            return false;
        }

        // Gradient should not be greater than 1 (integer in collateral token decimals)
        if (_poolParams.gradient > uint256(10**_collateralTokenDecimals)) {
            return false;
        }

        // Collateral amount should not be greater than pool capacity
        if (_poolParams.collateralAmount > _poolParams.capacity) {
            return false;
        }

        // Collateral token should not have decimals larger than 18 or smaller than 6
        if ((_collateralTokenDecimals > 18) || (_collateralTokenDecimals < 6)) {
            return false;
        }

        return true;
    }

    // Function to transfer collateral from msg.sender/maker to `this` and mint position token
    function _addLiquidityLib(AddLiquidityParams memory addLiquidityParams)
        internal
    {
        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool =
            LibDIVAStorage._poolStorage().pools[addLiquidityParams.poolId];

        // Check if pool exists
        if (!_poolExists(_pool)) revert NonExistentPool();

        // Check that pool has not expired yet
        if (block.timestamp >= _pool.expiryTime) revert PoolExpired();

        // Check that new total pool collateral does not exceed the maximum
        // capacity of the pool
        if ((_pool.collateralBalance + addLiquidityParams.collateralAmountMsgSender + addLiquidityParams.collateralAmountMaker) > _pool.capacity)
            revert PoolCapacityExceeded();

        // Connect to collateral token contract of the given pool Id
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        uint256 _collateralAmountIncr = addLiquidityParams
            .collateralAmountMsgSender +
            addLiquidityParams.collateralAmountMaker;

        // Transfer approved collateral tokens from `msg.sender` (taker in `fillOfferAddLiquidity`) to `this`.
        // Requires prior approval from `msg.sender` to execute this transaction. Note that
        // the transfer will revert for fee tokens.
        // Block scoping applied to avoid stack-too-deep error.
        {
            uint256 _before = collateralToken.balanceOf(address(this));
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                addLiquidityParams.collateralAmountMsgSender
            );

            // Transfer approved collateral tokens from maker. Applies only for `fillOfferAddLiquidity`
            // when makerFillAmount > 0. Requires prior approval from `maker` to execute this transaction.
            if (addLiquidityParams.collateralAmountMaker != 0) {
                collateralToken.safeTransferFrom(
                    addLiquidityParams.maker,
                    address(this),
                    addLiquidityParams.collateralAmountMaker
                );
            }
            uint256 _after = collateralToken.balanceOf(address(this));

            // Revert if a fee was applied during transfer. Throws if `_before > _after`.
            if (_after - _before != _collateralAmountIncr) {
                revert FeeTokensNotSupported();
            }
        }

        // Increase `collateralBalance`
        _pool.collateralBalance += _collateralAmountIncr;

        // Mint long and short position tokens and send to `shortRecipient` and
        // `_longRecipient`, respectively (additional supply equals `_collateralAmountIncr`)
        IPositionToken(_pool.shortToken).mint(
            addLiquidityParams.shortRecipient,
            _collateralAmountIncr
        );
        IPositionToken(_pool.longToken).mint(
            addLiquidityParams.longRecipient,
            _collateralAmountIncr
        );

        // Log addition of collateral
        emit LiquidityAdded(
            addLiquidityParams.poolId,
            addLiquidityParams.longRecipient,
            addLiquidityParams.shortRecipient,
            _collateralAmountIncr
        );
    }

    function _removeLiquidityLib(
        RemoveLiquidityParams memory _removeLiquidityParams,
        LibDIVAStorage.Pool storage _pool
    ) internal returns (uint256 collateralAmountRemovedNet) {        
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Confirm that functionality is not paused
        if (block.timestamp < gs.pauseReturnCollateralUntil)
            revert ReturnCollateralPaused();

        // Check if pool exists
        if (!_poolExists(_pool)) revert NonExistentPool();

        // If status is Confirmed, users should use `redeemPositionToken` function
        // to withdraw collateral
        if (_pool.statusFinalReferenceValue == LibDIVAStorage.Status.Confirmed)
            revert FinalValueAlreadyConfirmed();

        // Create reference to short and long position tokens for the given pool
        IPositionToken shortToken = IPositionToken(_pool.shortToken);
        IPositionToken longToken = IPositionToken(_pool.longToken);

        // Check that `shortTokenHolder` and `longTokenHolder` own the corresponding
        // `_amount` of short and long position tokens. In particular, this check will
        // revert when a user tries to remove an amount that exceeds the overall position token
        // supply which is the maximum amount that a user can own.
        if (
            shortToken.balanceOf(_removeLiquidityParams.shortTokenHolder) <
            _removeLiquidityParams.amount ||
            longToken.balanceOf(_removeLiquidityParams.longTokenHolder) <
            _removeLiquidityParams.amount
        ) revert InsufficientShortOrLongBalance();

        // Get fee parameters applicable for given `_poolId`
        LibDIVAStorage.Fees memory _fees = gs.fees[_pool.indexFees];

        uint256 _protocolFee;
        uint256 _settlementFee;

        if (_fees.protocolFee > 0) {
            // Calculate protocol fees to charge (note that collateral amount
            // to return is equal to `_amount`)
            _protocolFee = _calcFee(
                _fees.protocolFee,
                _removeLiquidityParams.amount,
                IERC20Metadata(_pool.collateralToken).decimals()
            );
            // User has to increase `_amount` if fee is 0
            if (_protocolFee == 0) revert ZeroProtocolFee();
        } // else _protocolFee = 0 (default value for uint256)

        if (_fees.settlementFee > 0) {
            // Calculate settlement fees to charge
            _settlementFee = _calcFee(
                _fees.settlementFee,
                _removeLiquidityParams.amount,
                IERC20Metadata(_pool.collateralToken).decimals()
            );
            // User has to increase `_amount` if fee is 0
            if (_settlementFee == 0) revert ZeroSettlementFee();
        } // else _settlementFee = 0 (default value for uint256)

        // Burn short and long position tokens
        shortToken.burn(
            _removeLiquidityParams.shortTokenHolder,
            _removeLiquidityParams.amount
        );
        longToken.burn(
            _removeLiquidityParams.longTokenHolder,
            _removeLiquidityParams.amount
        );

        // Allocate protocol fee to DIVA treasury. Fee is held within this
        // contract and can be claimed via `claimFee` function.
        // `collateralBalance` is reduced inside `_allocateFeeClaim`.
        _allocateFeeClaim(
            _removeLiquidityParams.poolId,
            _pool,
            _getCurrentTreasury(gs),
            _protocolFee
        );

        // Reserve settlement fee for data provider which is not known at this stage.
        // Fee will be allocated to actual data provider following final value
        // confirmation and afterwards can be claimed via the `claimFee` function.
        _reserveFeeClaim(
            _removeLiquidityParams.poolId,
            _pool,
            _settlementFee
        );
        
        // Collateral amount to return net of fees
        collateralAmountRemovedNet =
            _removeLiquidityParams.amount -
            _protocolFee -
            _settlementFee;

        // Log removal of liquidity
        emit LiquidityRemoved(
            _removeLiquidityParams.poolId,
            _removeLiquidityParams.longTokenHolder,
            _removeLiquidityParams.shortTokenHolder,
            _removeLiquidityParams.amount
        );
    }

    // Returns whether pool exists or not. Uses `collateralToken != address(0)` check
    // to determine the existence of a pool as it's the cheapest among the available
    // options.
    function _poolExists(LibDIVAStorage.Pool storage _pool) internal view returns (bool) {
        return _pool.collateralToken != address(0);
    }

    function _getFeesHistory(
        uint256 _nbrLastUpdates,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (LibDIVAStorage.Fees[] memory) {
        if (_nbrLastUpdates > 0) {
            // Cache length to avoid reading from storage on every loop
            uint256 _len = _gs.fees.length;

            // Cap `_nbrLastUpdates` at max history rather than throwing an error
            _nbrLastUpdates = _nbrLastUpdates > _len ? _len : _nbrLastUpdates;

            // Define the size of the array to be returned
            LibDIVAStorage.Fees[] memory _fees = new LibDIVAStorage.Fees[](
                _nbrLastUpdates
            );

            // Iterate through the fees array starting from the latest item
            for (uint256 i = _len; i > _len - _nbrLastUpdates; ) {
                _fees[_len - i] = _gs.fees[i - 1]; // first element of _fees represents latest fees
                unchecked {
                    --i;
                }
            }
            return _fees;
        } else {
            return new LibDIVAStorage.Fees[](0);
        }
    }

    function _getSettlementPeriodsHistory(
        uint256 _nbrLastUpdates,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (LibDIVAStorage.SettlementPeriods[] memory) {
        if (_nbrLastUpdates > 0) {
            // Cache length to avoid reading from storage on every loop
            uint256 _len = _gs.settlementPeriods.length;

            // Cap `_nbrLastUpdates` at max history rather than throwing an error
            _nbrLastUpdates = _nbrLastUpdates > _len ? _len : _nbrLastUpdates;

            // Define the size of the array to be returned
            LibDIVAStorage.SettlementPeriods[]
                memory _settlementPeriods = new LibDIVAStorage.SettlementPeriods[](
                    _nbrLastUpdates
                );

            // Iterate through the settlement periods array starting from the latest item
            for (uint256 i = _len; i > _len - _nbrLastUpdates; ) {
                _settlementPeriods[_len - i] = _gs.settlementPeriods[i - 1]; // first element of _fees represents latest fees
                unchecked {
                    --i;
                }
            }
            return _settlementPeriods;
        } else {
            return new LibDIVAStorage.SettlementPeriods[](0);
        }
    }

    function _getCurrentFees(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (uint48 index, LibDIVAStorage.Fees memory fees)
    {
        // Get length of `fees` array
        uint256 _len = _gs.fees.length;

        // Load latest fee regime
        LibDIVAStorage.Fees memory _fees = _gs.fees[_len - 1];

        // Return the latest array entry & index if already past activation time,
        // otherwise return the second last entry
        if (_fees.startTime > block.timestamp) {
            index = uint48(_len - 2);
        } else {
            index = uint48(_len - 1);
        }
        fees = _gs.fees[index];
    }

    function _getCurrentSettlementPeriods(
        LibDIVAStorage.GovernanceStorage storage _gs
    )
        internal
        view
        returns (
            uint48 index,
            LibDIVAStorage.SettlementPeriods memory settlementPeriods
        )
    {
        // Get length of `settlementPeriods` array
        uint256 _len = _gs.settlementPeriods.length;

        // Load latest settlement periods regime
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = _gs
            .settlementPeriods[_len - 1];

        // Return the latest array entry & index if already past activation time,
        // otherwise return the second last entry
        if (_settlementPeriods.startTime > block.timestamp) {
            index = uint48(_len - 2);
        } else {
            index = uint48(_len - 1);
        }
        settlementPeriods = _gs.settlementPeriods[index];
    }

    function _getCurrentFallbackDataProvider(
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (address) {
        // Return the new fallback data provider if `block.timestamp` is at or past
        // the activation time, else return the current fallback data provider
        return
            block.timestamp < _gs.startTimeFallbackDataProvider
                ? _gs.previousFallbackDataProvider
                : _gs.fallbackDataProvider;
    }

    function _getCurrentTreasury(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (address)
    {
        // Return the new treasury address if `block.timestamp` is at or past
        // the activation time, else return the current treasury address
        return
            block.timestamp < _gs.startTimeTreasury
                ? _gs.previousTreasury
                : _gs.treasury;
    }

    function _getFallbackDataProviderInfo(
        LibDIVAStorage.GovernanceStorage storage _gs
    )
        internal
        view
        returns (
            address previousFallbackDataProvider,
            address fallbackDataProvider,
            uint256 startTimeFallbackDataProvider
        )
    {
        // Return values
        previousFallbackDataProvider = _gs.previousFallbackDataProvider;
        fallbackDataProvider = _gs.fallbackDataProvider;
        startTimeFallbackDataProvider = _gs.startTimeFallbackDataProvider;
    }

    function _getTreasuryInfo(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (
            address previousTreasury,
            address treasury,
            uint256 startTimeTreasury
        )
    {
        // Return values
        previousTreasury = _gs.previousTreasury;
        treasury = _gs.treasury;
        startTimeTreasury = _gs.startTimeTreasury;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library LibDIVAStorage {
    // The hash for pool storage position, which is:
    // keccak256("diamond.standard.pool.storage")
    bytes32 constant POOL_STORAGE_POSITION =
        0x57b54c9a1067e6ab879c66c176c4e86e41fe1dcf5187b31dc2b93365087c7afb;

    // The hash for governance storage position, which is:
    // keccak256("diamond.standard.governance.storage")
    bytes32 constant GOVERNANCE_STORAGE_POSITION =
        0x898b136e888260ec0628fb6c3ad8f54cb15908878595b2abfc8c9ecda73a4daf;

    // The hash for fee claim storage position, which is:
    // keccak256("diamond.standard.fee.claim.storage")
    bytes32 constant FEE_CLAIM_STORAGE_POSITION =
        0x16b3e63c02e4dfaf74f59b1b7e9e81770bf30c0ed3fd4434b199357859900313;

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor; // Reference asset value at or below which the long token pays out 0 and the short token 1 (max payout), gross of fees (18 decimals)
        uint256 inflection; // Reference asset value at which the long token pays out `gradient` and the short token `1-gradient`, gross of fees (18 decimals)
        uint256 cap; // Reference asset value at or above which the long token pays out 1 (max payout) and the short token 0, gross of fees (18 decimals)
        uint256 gradient; // Long token payout at inflection (value between 0 and 1) (collateral token decimals)
        uint256 collateralBalance; // Current collateral balance of pool (collateral token decimals)
        uint256 finalReferenceValue; // Reference asset value at the time of expiration (18 decimals) - set to 0 at pool creation
        uint256 capacity; // Maximum collateral that the pool can accept (collateral token decimals)
        uint256 statusTimestamp; // Timestamp of status change - set to `block.timestamp` at pool creation and updated on status changes
        address shortToken; // Short position token address
        uint96 payoutShort; // Payout amount per short position token net of fees (collateral token decimals) - set to 0 at pool creation
        address longToken; // Long position token address
        uint96 payoutLong; // Payout amount per long position token net of fees (collateral token decimals) - set to 0 at pool creation
        address collateralToken; // Address of the ERC20 collateral token
        uint96 expiryTime; // Expiration time of the pool (expressed as a unix timestamp in seconds)
        address dataProvider; // Address of data provider
        uint48 indexFees; // Index pointer to the applicable fees inside the Fees struct array
        uint48 indexSettlementPeriods; // Index pointer to the applicable periods inside the SettlementPeriods struct array
        Status statusFinalReferenceValue; // Status of final reference price (0 = Open, 1 = Submitted, 2 = Challenged, 3 = Confirmed) - set to 0 at pool creation
        string referenceAsset; // Reference asset string
    }

    // Collection of settlement related periods
    struct SettlementPeriods {
        uint256 startTime; // Timestamp at which the new set of settlement periods becomes applicable
        uint24 submissionPeriod; // Submission period length in seconds; max value: 15 days <= 2^24
        uint24 challengePeriod; // Challenge period length in seconds; max value: 15 days <= 2^24
        uint24 reviewPeriod; // Review period length in seconds; max value: 15 days <= 2^24
        uint24 fallbackSubmissionPeriod; // Fallback submission period length in seconds; max value: 15 days <= 2^24
    }

    // Collection of fee related parameters
    struct Fees {
        uint256 startTime; // timestamp at which the new set of fees becomes applicable
        uint96 protocolFee; // max value: 15000000000000000 = 1.5% <= 2^56
        uint96 settlementFee; // max value: 15000000000000000 = 1.5% <= 2^56
    }

    // Collection of governance related parameters
    struct GovernanceStorage {
        address previousTreasury; // Previous treasury address
        address treasury; // Pending/current treasury address
        uint256 startTimeTreasury; // Unix timestamp when the new treasury address is activated
        address previousFallbackDataProvider; // Previous fallback data provider address
        address fallbackDataProvider; // Pending/current fallback data provider
        uint256 startTimeFallbackDataProvider; // Unix timestamp when the new fallback provider is activated
        uint256 pauseReturnCollateralUntil; // Unix timestamp until when withdrawals are paused
        Fees[] fees; // Array including the fee regimes set over time
        SettlementPeriods[] settlementPeriods; // Array including the settlement period regimes set over time
    }

    struct FeeClaimStorage {
        mapping(address => mapping(address => uint256)) claimableFeeAmount; // collateralTokenAddress -> RecipientAddress -> amount
        mapping(bytes32 => uint256) poolIdToReservedClaim; // poolId -> reserve amount
    }

    // IMPORTANT: The hash calculation in `LibDIVA._getPoolId()` assumes
    // that the `nonce` variable is stored at slot 0 inside the `PoolStorage` struct
    struct PoolStorage {
        uint256 nonce;
        mapping(bytes32 => Pool) pools; // poolId => Pool struct
        address positionTokenFactory;
    }

    function _poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function _governanceStorage()
        internal
        pure
        returns (GovernanceStorage storage gs)
    {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function _feeClaimStorage()
        internal
        pure
        returns (FeeClaimStorage storage fs)
    {
        bytes32 position = FEE_CLAIM_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.19 where SafeMath is no
 * longer required to handle overflows
 */

library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands
     * as fixed-point decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is
     * evaluated, so that product must be less than 2**256. As this is an
     * integer division, the internal division always rounds down. This helps
     * save on gas. Rounding is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // Divide by UNIT to remove the extra factor introduced by the product
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // Reintroduce the UNIT factor that will be divided out by y
        return (x * UNIT) / y;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IPositionToken} from "./interfaces/IPositionToken.sol";

/**
 * @dev Implementation contract for position token clones
 */
contract PositionToken is IPositionToken, ERC20Upgradeable {

    bytes32 private _poolId;
    address private _owner;
    uint8 private _decimals;

    constructor() {
        /* @dev To prevent the implementation contract from being used, invoke the {_disableInitializers}
         * function in the constructor to automatically lock it when it is deployed.
         * For more information, refer to @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol
         */
        _disableInitializers();
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "PositionToken: caller is not owner"
            );
        _;
    }

    function mint(
        address _recipient,
        uint256 _amount
        ) external override onlyOwner {
        _mint(_recipient, _amount);
    }

    function burn(
        address _redeemer,
        uint256 _amount
        ) external override onlyOwner {
        _burn(_redeemer, _amount);
    }

    function poolId() external view override returns (bytes32) {
        return _poolId;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initialize(
        string memory symbol_,
        bytes32 poolId_,
        uint8 decimals_,
        address owner_
    ) external override initializer {

        __ERC20_init(symbol_, symbol_);

        _owner = owner_;
        _poolId = poolId_;
        _decimals = decimals_;
    }
}