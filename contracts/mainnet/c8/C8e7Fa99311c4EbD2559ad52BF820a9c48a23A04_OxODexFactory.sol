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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

interface IOxODexFactory {
    function createPool(address token) external returns (address vault);
    function allPoolsLength() external view returns (uint);
    function getPool(address token) external view returns (address);
    function allPools(uint256) external view returns (address);

    function token() external view returns (address);
    function managerAddress() external view returns (address);
    function treasurerAddress() external view returns (address);
    function fee() external view returns (uint256);
    function tokenFee() external view returns (uint256);
    function relayerFee() external view returns (uint256);
    function maxRelayerGasCharge(address) external view returns (uint256);
    function paused() external view returns (bool);

    function setManager(address _manager) external;
    function setTreasurerAddress(address _treasurerAddress) external;
    function setToken(address _token) external;
    function setTokenFeeDiscountPercent(uint256 _value) external;
    function setTokenFee(uint256 _fee) external;
    function setFee(uint256 _fee) external;
    function setRelayerFee(uint256 _fee) external;
 
    function getTokenFeeDiscountLimit() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

interface IOxODexTokenPool {
    function initialize(address _token, address _factory) external;
    function withdraw(
        address payable recipient, uint256 amountToken, uint256 ringIndex,
        uint256 c0, uint256[2] memory keyImage, uint256[] memory s
    ) external;
    function deposit(uint _amount, uint256[4] memory publicKey) external;
    function getBalance() external view returns (uint256);
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256);
    function getRingMaxParticipants() external pure
        returns (uint256);
    function getParticipant(uint packedData) external view returns (uint256);
    function getWParticipant(uint packedData) external view returns (uint256);
    function getRingPackedData(uint packedData) external view returns (uint256, uint256, uint256);
    function getPublicKeys(uint256 amountToken, uint256 index) external view
        returns (bytes32[2][5] memory);
    function getPoolBalance() external view returns (uint256);
    function swapTokenForToken(
        address tokenOut, 
        address router,
        bytes memory params, 
        uint256[4] memory publicKey, 
        uint256 amountToken, 
        uint256 ringIndex,
        uint256 c0, 
        uint256[2] memory keyImage, 
        uint256[] memory s
    ) external;
    function getFeeForAmount(uint256 amount) external view returns(uint256);
    function getRelayerFeeForAmount(uint256 amount) external view returns(uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

interface IOxODexTokenPool {
    function initialize(address _token, address _factory) external;
    function withdraw(
        address payable recipient, uint256 amountToken, uint256 ringIndex,
        uint256 c0, uint256[2] memory keyImage, uint256[] memory s
    ) external;
    function deposit(uint _amount, uint256[4] memory publicKey) external;
    function getBalance() external view returns (uint256);
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256);
    function getRingMaxParticipants() external pure
        returns (uint256);
    function getParticipant(uint packedData) external view returns (uint256);
    function getWParticipant(uint packedData) external view returns (uint256);
    function getRingPackedData(uint packedData) external view returns (uint256, uint256, uint256);
    function getPublicKeys(uint256 amountToken, uint256 index) external view
        returns (bytes32[2][5] memory);
    function getPoolBalance() external view returns (uint256);
    function swapTokenForToken(
        address tokenOut, 
        address router,
        bytes memory params, 
        uint256[4] memory publicKey, 
        uint256 amountToken, 
        uint256 ringIndex,
        uint256 c0, 
        uint256[2] memory keyImage, 
        uint256[] memory s
    ) external;
    function getFeeForAmount(uint256 amount) external view returns(uint256);
    function getRelayerFeeForAmount(uint256 amount) external view returns(uint256);
}

pragma solidity ^0.8.5;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

// https://github.com/ethereum/py_ecc/blob/master/py_ecc/bn128/bn128_curve.py


library AltBn128 {    
    // https://github.com/ethereum/py_ecc/blob/master/py_ecc/bn128/bn128_curve.py
    uint256 constant public G1x = uint256(0x01);
    uint256 constant public G1y = uint256(0x02);

    // Number of elements in the field (often called `q`)
    // n = n(u) = 36u^4 + 36u^3 + 18u^2 + 6u + 1
    uint256 constant public N = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    // p = p(u) = 36u^4 + 36u^3 + 24u^2 + 6u + 1
    // Field Order
    uint256 constant public P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // (p+1) / 4
    uint256 constant public A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
    

    /* ECC Functions */
    function ecAdd(uint256[2] memory p0, uint256[2] memory p1) public view
        returns (uint256[2] memory retP)
    {
        uint256[4] memory i = [p0[0], p0[1], p1[0], p1[1]];
        
        assembly {
            // call ecadd precompile
            // inputs are: x1, y1, x2, y2
            if iszero(staticcall(not(0), 0x06, i, 0x80, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMul(uint256[2] memory p, uint256 s) public view
        returns (uint256[2] memory retP)
    {
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory i = [p[0], p[1], s];
        
        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            if iszero(staticcall(not(0), 0x07, i, 0x60, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMulG(uint256 s) public view
        returns (uint256[2] memory retP)
    {
        return ecMul([G1x, G1y], s);
    }

    function powmod(uint256 base, uint256 e, uint256 m) public view
        returns (uint256 o)
    {
        // returns pow(base, e) % m
        assembly {
            // define pointer
            let p := mload(0x40)

            // Store data assembly-favouring ways
            mstore(p, 0x20)             // Length of Base
            mstore(add(p, 0x20), 0x20)  // Length of Exponent
            mstore(add(p, 0x40), 0x20)  // Length of Modulus
            mstore(add(p, 0x60), base)  // Base
            mstore(add(p, 0x80), e)     // Exponent
            mstore(add(p, 0xa0), m)     // Modulus

            // call modexp precompile! -- old school gas handling
            let success := staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)

            // gas fiddling
            switch success case 0 {
                revert(0, 0)
            }

            // data
            o := mload(p)
        }
    }

    // Keep everything contained within this lib
    function addmodn(uint256 x, uint256 n) public pure
        returns (uint256)
    {
        return addmod(x, n, N);
    }

    function modn(uint256 x) public pure
        returns (uint256)
    {
        return x % N;
    }

    /*
       Checks if the points x, y exists on alt_bn_128 curve
    */
    function onCurve(uint256 x, uint256 y) public pure
        returns(bool)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        return onCurveBeta(beta, y);
    }

    function onCurveBeta(uint256 beta, uint256 y) public pure
        returns(bool)
    {
        return beta == mulmod(y, y, P);
    }

    /*
    * Calculates point y value given x
    */
    function evalCurve(uint256 x) public view
        returns (uint256, uint256)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        uint256 y = powmod(beta, A, P);

        // require(beta == mulmod(y, y, P), "Invalid x for evalCurve");
        return (beta, y);
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "./AltBn128.sol";

/*
Linkable Spontaneous Anonymous Groups
https://eprint.iacr.org/2004/027.pdf
*/

library LSAG {
    // abi.encodePacked is the "concat" or "serialization"
    // of all supplied arguments into one long bytes value
    // i.e. abi.encodePacked :: [a] -> bytes

    /**
    * Converts an integer to an elliptic curve point
    */
    function intToPoint(uint256 _x) public view
        returns (uint256[2] memory)
    {
        uint256 x = _x;
        uint256 y;
        uint256 beta;

        while (true) {
            (beta, y) = AltBn128.evalCurve(x);

            if (AltBn128.onCurveBeta(beta, y)) {
                return [x, y];
            }

            x = AltBn128.addmodn(x, 1);
        }
    }

    /**
    * Returns an integer representation of the hash
    * of the input
    */
    function H1(bytes memory b) public pure
        returns (uint256)
    {
        return AltBn128.modn(uint256(keccak256(b)));
    }

    /**
    * Returns elliptic curve point of the integer representation
    * of the hash of the input
    */
    function H2(bytes memory b) public view
        returns (uint256[2] memory)
    {
        return intToPoint(H1(b));
    }

    /**
    * Helper function to calculate Z1
    * Avoids stack too deep problem
    */
    function ringCalcZ1(
        uint256[2] memory pubKey,
        uint256 c,
        uint256 s
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMulG(s),
            AltBn128.ecMul(pubKey, c)
        );
    }

    /**
    * Helper function to calculate Z2
    * Avoids stack too deep problem
    */
    function ringCalcZ2(
        uint256[2] memory keyImage,
        uint256[2] memory h,
        uint256 s,
        uint256 c
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMul(h, s),
            AltBn128.ecMul(keyImage, c)
        );
    }


    /**
    * Verifies the ring signature
    * Section 4.2 of the paper https://eprint.iacr.org/2004/027.pdf
    */
    function verify(
        bytes memory message,
        uint256 c0,
        uint256[2] memory keyImage,
        uint256[] memory s,
        uint256[2][] memory publicKeys
    ) public view
        returns (bool)
    {
        require(publicKeys.length >= 2, "Signature size too small");
        require(publicKeys.length == s.length, "Signature sizes do not match!");

        uint256 c = c0;
        uint256 i = 0;

        // Step 1
        // Extract out public key bytes
        bytes memory hBytes = "";

        for (i = 0; i < publicKeys.length; i++) {
            hBytes = abi.encodePacked(
                hBytes,
                publicKeys[i]
            );
        }

        uint256[2] memory h = H2(hBytes);

        // Step 2
        uint256[2] memory z_1;
        uint256[2] memory z_2;


        for (i = 0; i < publicKeys.length; i++) {
            z_1 = ringCalcZ1(publicKeys[i], c, s[i]);
            z_2 = ringCalcZ2(keyImage, h, s[i], c);

            if (i != publicKeys.length - 1) {
                c = H1(
                    abi.encodePacked(
                        hBytes,
                        keyImage,
                        message,
                        z_1,
                        z_2
                    )
                );
            }
        }

        return c0 == H1(
            abi.encodePacked(
                hBytes,
                keyImage,
                message,
                z_1,
                z_2
            )
        );
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import { Context } from "./Context.sol";

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "./OxODexTokenPool.sol";
import "./interfaces/IOxODexTokenPool.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "./lib/Pausable.sol";

contract OxODexFactory is Pausable {

    enum FeeType {
        TOKEN,
        POOL,
        DISCOUNT_PERCENT,
        RELAYER_PERCENT,
        RELAYER_GAS_CHARGE
    } 

    /// Errors
    error PoolExists();
    error ZeroAddress();
    error Forbidden();

    /// Events
    event PoolCreated(address indexed token, address poolAddress);
    event ManagerChanged(address indexed newManager);
    event FeeChanged(uint256 newFee, FeeType feeType); 
    event TokenChanged(address indexed newToken);
    event TreasurerChanged(address indexed newTreasurer);

    address[] public allPools;
    address public managerAddress = 0x0000000000000000000000000000000000000000;
    address public treasurerAddress = 0x0000000000000000000000000000000000000000;
    address public token = 0x0000000000000000000000000000000000000000;
    uint256 public tokenFeeDiscountPercent = 100; // 0.1% of total supply  

    uint256 public fee = 90; // 0.9% fee
    uint256 public tokenFee = 45; // 0.45% fee
    uint256 public relayerFee = 30; // 0.3% fee

    
    /// token => pool
    mapping(address => address) public pools;
    mapping(address => uint256) public maxRelayerGasCharge;

    constructor(address _managerAddress, address _treasurerAddress, address _token) Pausable() {
        if(_managerAddress == address(0)) revert ZeroAddress();
        if(_treasurerAddress == address(0)) revert ZeroAddress();
        if(_token == address(0)) revert ZeroAddress();

        managerAddress = _managerAddress;
        treasurerAddress = _treasurerAddress;
        token = _token;
    }

    
    /// @notice Creates a new pool for the given token
    /// @param _token The token to create the pool for
    /// @return vault The address of the new pool
    function createPool(address _token, uint256 _relayerGasCharge) external onlyManager returns (address vault) {
        if (_token == address(0)) revert ZeroAddress();
        if(pools[_token] != address(0)) revert PoolExists();

        bytes memory bytecode = type(OxODexTokenPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));

        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IOxODexTokenPool(vault).initialize(_token, address(this));

        pools[_token] = vault;
        allPools.push(vault);

        maxRelayerGasCharge[vault] = _relayerGasCharge;

        emit PoolCreated(_token, vault);
    }

    /// @notice Returns the pool address for the given token
    /// @param _token The token to get the pool for
    /// @return The address of the pool
    function getPool(address _token) external view returns (address) {
        return pools[_token];
    }

    /// @notice Returns the address of the pool for the given token
    /// @return The length of all pools
    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    modifier onlyManager() {
        if (msg.sender != managerAddress) revert Forbidden();
        _;
    }

    modifier limitFee(uint256 _fee) {
        require(_fee <= 300, "Fee too high");
        _;
    }

    /// @notice set the relayer fixed fee for ETH to cover gas
    /// @param _fee the fee to set
    function setETHRelayerGasCharge(uint256 _fee) external onlyManager {
        maxRelayerGasCharge[address(0)] = _fee;
        emit FeeChanged(_fee, FeeType.RELAYER_GAS_CHARGE);
    }

    /// @notice set the relayer fixed fee to cover gas
    /// @param _token the token to set the fee for
    /// @param _fee the fee to set
    function setRelayerGasCharge(address _token, uint256 _fee) external onlyManager {
        address poolAddress = pools[_token];
        if(poolAddress == address(0)) revert ZeroAddress();

        maxRelayerGasCharge[poolAddress] = _fee;
        emit FeeChanged(_fee, FeeType.RELAYER_GAS_CHARGE);
    }

    /// @notice Sets the manager address
    /// @param _managerAddress The new manager address
    function setManager(address _managerAddress) external onlyManager {
        if(_managerAddress == address(0)) revert ZeroAddress();
        managerAddress = _managerAddress;

        emit ManagerChanged(_managerAddress);
    }

    /// @notice Sets the treasurer address
    /// @param _treasurerAddress The new treasurer address
    function setTreasurerAddress(address _treasurerAddress) external onlyManager {
        if(_treasurerAddress == address(0)) revert ZeroAddress();
        treasurerAddress = _treasurerAddress;

        emit TreasurerChanged(_treasurerAddress);
    }

    /// @notice Sets the token address
    /// @param _token The new token address
    function setToken(address _token) external onlyManager {
        if(_token == address(0)) revert ZeroAddress();
        token = _token;
        
        emit TokenChanged(_token);
    }

    /// @notice Set the percentage threshold for fee free transactions
    /// @param _value the new percentage threshold
    function setTokenFeeDiscountPercent(uint256 _value) external onlyManager {
        tokenFeeDiscountPercent = _value;

        emit FeeChanged(_value, FeeType.DISCOUNT_PERCENT);
    }

    /// @notice Set token fee
    /// @param _fee the new percentage threshold
    function setTokenFee(uint256 _fee) external onlyManager limitFee(_fee){
        tokenFee = _fee;

        emit FeeChanged(_fee, FeeType.TOKEN);
    }

    /// @notice Sets the fee
    /// @param _fee The new fee
    function setFee(uint256 _fee) external onlyManager limitFee(_fee){
        fee = _fee;

        emit FeeChanged(_fee, FeeType.POOL);
    }

    /// @notice Sets the relayer fee
    /// @param _fee The new fee
    function setRelayerFee(uint256 _fee) external onlyManager limitFee(_fee){
        relayerFee = _fee;

        emit FeeChanged(_fee, FeeType.RELAYER_PERCENT);
    }

    /// @dev Pauses functionality for all pools
    function pause() external onlyManager {
        _pause();
    }

    /// @dev Unpauses functionality for all pools
    function unpause() external onlyManager {
        _unpause();
    }

    function getTokenFeeDiscountLimit() external view returns (uint256) {
        return (ERC20(token).totalSupply() * tokenFeeDiscountPercent) / 100_000;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./lib/AltBn128.sol";
import "./lib/LSAG.sol";
import "./interfaces/IOxODexFactory.sol";
import "./interfaces/IOxODexPool.sol";
import "./interfaces/IWETH9.sol";

library Types {

    enum WithdrawalType {
        Direct,
        Swap
    }
}

contract OxODexPool is Initializable {

    // =============================================================
    //                           ERRORS
    // =============================================================
    
    error AlreadyInitialized();
    error NotInitialized();

    // =============================================================
    //                           EVENTS
    // =============================================================
    
    event Deposit(address, uint256 tokenAmount, uint256 ringIndex);
    event Withdraw(address, uint256 tokenAmount, uint256 ringIndex);
    event Swap(address indexed tokenOut, uint256 tokenAmountIn, uint256 tokenAmountOut);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Maximum number of participants in a ring It can be changed to a higher value, 
    /// but it will increase the gas cost.
    uint256 constant MAX_RING_PARTICIPANT = 2;


    /// The participant value would use 16 bits
    uint256 constant _BITWIDTH_PARTICIPANTS = 16;

    /// The Block value would use 16 bits
    uint256 constant _BITWIDTH_BLOCK_NUM = 32;

    /// Bitmask for `numberOfParticipants`
    uint256 constant _BITMASK_PARTICIPANTS = (1 << _BITWIDTH_PARTICIPANTS) -1;

    /// Bitmask for `blockNumber`
    uint256 constant _BITMASK_BLOCK_NUM = (1 << _BITWIDTH_BLOCK_NUM) -1;


    // =============================================================
    //                           STORAGE
    // =============================================================

    struct Ring {
        /// The total amount deposited in the ring
        uint256 amountDeposited;

        /// Bits Layout:
        /// - [0..32]    `initiatedBlockNumber` 
        /// - [32..48]   `numberOfParticipants`
        /// - [48..64]   `numberOfWithdrawnParticipants`
        uint256 packedRingData; 

        /// The public keys of the participants
        mapping (uint256 => uint256[2]) publicKeys;

        /// The key images from successfully withdrawn participants
        /// NOTE: This is used to prevent double spending
        mapping (uint256 => uint256[2]) keyImages;
        bytes32 ringHash;
    }

    struct WithdrawalData {
        /// The amount to withdraw`
        uint256 amount;

        /// The index of the ring
        uint256 ringIndex;

        /// Signed message parameters
        uint256 c0;
        uint256[2] keyImage;
        uint256[] s;
        Types.WithdrawalType wType;
    }

    address payable public wethAddress;
    address public factory;
    address public token;

    uint256 private _lastWithdrawal;

    /// tokenAmount => ringIndex
    mapping(uint256 => uint256) public ringsNumber;

    /// tokenAmount => ringIndex => Ring
    mapping (uint256 => mapping(uint256 => Ring)) public rings;

    function initialize(address _factory, address payable _wethAddress) public initializer {
        require(_wethAddress != address(0), "ZERO_ADDRESS");
        require(_factory != address(0), "ZERO_ADDRESS");
        wethAddress = _wethAddress;
        factory = _factory;
    }

    modifier whenNotPaused(){
        require(!IOxODexFactory(factory).paused(), "PAUSED");
        _;
    }

    /// @notice Deposit value into the pool
    /// @param _publicKey The public key of the participant
    function deposit(uint _amount, uint256[4] memory _publicKey) external payable whenNotPaused {
        require(_amount > 0, "AMOUNT_MUST_BE_GREATER_THAN_ZERO");
        require(msg.value >= _amount, "INSUFFICIENT_ETHER_SENT");

        IOxODexFactory factoryContract = IOxODexFactory(factory);

        if(ERC20(factoryContract.token()).balanceOf(msg.sender) < factoryContract.getTokenFeeDiscountLimit()) {
            uint256 fee = getFeeForAmount(_amount);
            require(msg.value >= _amount+fee, "FUNDS_NOT_ENOUGH_FOR_FEE");

            /// Transfer the fee to the treasurer
            (bool sent,) = factoryContract.treasurerAddress().call{value: fee}("");
            require(sent, "FAILED_TO_SEND_ETHER_FOR_FEE");
        }else{
            uint256 fee = getDiscountFeeForAmount(_amount);

            if(fee > 0) {
                /// Transfer the fee to the treasurer
                (bool sent,) = factoryContract.treasurerAddress().call{value: fee}("");
                require(sent, "FAILED_TO_SEND_ETHER_FOR_FEE");
            }
        }
        
        if (!AltBn128.onCurve(uint256(_publicKey[0]), uint256(_publicKey[1]))) {
            revert("PK_NOT_ON_CURVE");
        }

        /// Gets the current ring for the amounts
        uint256 ringIndex = ringsNumber[_amount];
        Ring storage ring = rings[_amount][ringIndex];

        (uint wParticipants,
        uint participants, uint blockNum) = getRingPackedData(ring.packedRingData);

        /// Making sure no duplicate public keys are added
        for (uint256 i = 0; i < participants;) {
            if (ring.publicKeys[i][0] == _publicKey[0] &&
                ring.publicKeys[i][1] == _publicKey[1]) {
                revert("PK_ALREADY_IN_RING");
            }

            if (ring.publicKeys[i][0] == _publicKey[2] &&
                ring.publicKeys[i][1] == _publicKey[3]) {
                revert("PK_ALREADY_IN_RING");
            }

            unchecked {
                i++;
            }
        }

        if (participants == 0) {
            blockNum = block.number - 1;
        }

        ring.publicKeys[participants] = [_publicKey[0], _publicKey[1]];
        ring.publicKeys[participants + 1] = [_publicKey[2], _publicKey[3]];
        ring.amountDeposited += _amount;
        unchecked {
            participants += 2;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        packedData = (packedData << _BITWIDTH_BLOCK_NUM) | blockNum;
        ring.packedRingData = packedData;

        /// If the ring is full, start a new ring
        if (participants >= MAX_RING_PARTICIPANT) {
            ring.ringHash = hashRing(_amount, ringIndex);
            
            /// Add new Ring pool
            ringsNumber[_amount] += 1;
        }

        emit Deposit(msg.sender, _amount, ringIndex);
    }

    modifier chargeForGas(uint256 relayerGasCharge) {
        require(relayerGasCharge <= IOxODexFactory(factory).maxRelayerGasCharge(address(0)) , "RELAYER_FEE_TOO_HIGH");
        _;
        if(relayerGasCharge > 0) {
            (bool sent, ) = msg.sender.call{value: relayerGasCharge}("");
            require(sent, "FAILED_TO_SEND_ETHER_FOR_RELAYER_GAS_CHARGE");
        }
    }

    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param withdrawalData The data for the withdrawal
    /// @param relayerGasCharge The gas fee to pay the relayer
    function withdraw(
        address payable recipient, 
        WithdrawalData memory withdrawalData,
        uint256 relayerGasCharge
    ) public whenNotPaused chargeForGas(relayerGasCharge)
    {
        Ring storage ring = rings[withdrawalData.amount][withdrawalData.ringIndex];

        if(withdrawalData.amount > ring.amountDeposited) {
            revert("AMOUNT_EXCEEDS_DEPOSITED");
        }

        if(withdrawalData.amount < relayerGasCharge) {
            revert("RELAYER_GAS_CHARGE_TOO_HIGH");
        }

        (uint wParticipants,
        uint participants,) = getRingPackedData(ring.packedRingData);

        if (recipient == address(0)) {
            revert("ZERO_ADDRESS");
        }
        
        if (wParticipants >= MAX_RING_PARTICIPANT) {
            revert("ALL_FUNDS_WITHDRAWN");
        }

        if (ring.ringHash == bytes32(0x00)) {
            revert("RING_NOT_CLOSED");
        }

        uint256[2][] memory publicKeys = new uint256[2][](MAX_RING_PARTICIPANT);

        for (uint256 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];
            unchecked {
                i++;
            }
        }
    
        /// Attempts to verify ring signature
        bool signatureVerified = LSAG.verify(
            abi.encodePacked(ring.ringHash, recipient), // Convert to bytes
            withdrawalData.c0,
            withdrawalData.keyImage,
            withdrawalData.s,
            publicKeys
        );

        if (!signatureVerified) {
            revert("INVALID_SIGNATURE");
        }

        /// Confirm key image is not already used (no double spends)
        for (uint i = 0; i < wParticipants;) {
            if (ring.keyImages[i][0] == withdrawalData.keyImage[0] &&
                ring.keyImages[i][1] == withdrawalData.keyImage[1]) {
                revert("USED_SIGNATURE");
            }

            unchecked {
                i++;
            }
        }    

        ring.keyImages[wParticipants] = withdrawalData.keyImage;
        unchecked {
            wParticipants = MAX_RING_PARTICIPANT;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        ring.packedRingData = (packedData << _BITWIDTH_BLOCK_NUM) | 0; // blockNum set to zero;  

        // Transfer tokens to recipient
        // If recipient is the contract, don't transfer. Used in swap
        if(withdrawalData.wType == Types.WithdrawalType.Direct){
            // Transfer tokens to recipient
            _sendFundsWithRelayerFee(withdrawalData.amount - relayerGasCharge, recipient);
        }else{
            _lastWithdrawal = withdrawalData.amount - relayerGasCharge;
        }

        emit Withdraw(recipient, withdrawalData.amount, withdrawalData.ringIndex);
    }

    /// @notice Calculate the fee for a given amount
    /// @param amount The amount to calculate the fee for
    function getFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * IOxODexFactory(factory).fee()) / 10_000;
    }

    /// @notice Calculate and send the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    function _sendFundsWithRelayerFee(uint256 _amount, address payable _recipient) private returns(uint256 relayerFee){
        relayerFee = getRelayerFeeForAmount(_amount);
        (bool sent, bytes memory data) = msg.sender.call{value: relayerFee}("");
        require(sent, "FAILED_TO_SEND_RELAYER_FEE");

        (sent, data) = _recipient.call{value: _amount - relayerFee}("");
        require(sent, "FAILED_TO_SEND_FUNDS");
    }

    /// @notice Calculate the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    function getRelayerFeeForAmount(uint256 _amount) public view returns(uint256 relayerFee){
        relayerFee = (_amount * IOxODexFactory(factory).relayerFee()) / 10_000;
    }
    
    /// @notice Get the fee for Discount holders
    /// @param amount The amount to calculate the fee for
    function getDiscountFeeForAmount(uint256 amount) internal view returns(uint256){
        return (amount * IOxODexFactory(factory).tokenFee()) / 10_000;
    }

    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param relayerGasCharge The gas fee to send to the relayer
    /// @param withdrawalData The data for the withdrawal
    function swapOnWithdrawal(
        address tokenOut,
        address router,
        bytes memory params, 
        address payable recipient,
        uint256 relayerGasCharge, 
        WithdrawalData memory withdrawalData
    ) external {
        require(recipient != address(0), "ZERO_ADDRESS");

        withdraw(
            recipient, 
            withdrawalData,
            relayerGasCharge
        );

        uint _lastW = _lastWithdrawal;
        uint relayerFee = getRelayerFeeForAmount(_lastW);

        (bool sent, ) = msg.sender.call{value: relayerFee}("");
        require(sent, "FAILED_TO_SEND_RELAYER_FEE");

        _lastW -= relayerFee;
        
        // convert withdrawan eth to weth
        IWETH9(wethAddress).deposit{ value: _lastW }();

        // approve the weth or swapping
        IWETH9(wethAddress).approve(router, _lastW);

        (bool success, bytes memory data) = address(router).call(params);

        if (success == false) {
            assembly {
                // Copy the returned error string to memory
                // and revert with it.
                revert(add(data,32),mload(data))
            }
        }

        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).transfer(recipient, amountOut);

        emit Swap(tokenOut, withdrawalData.amount, _lastW);
    }

    /// @notice Generates a hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function hashRing(uint256 _amountToken, uint256 _ringIndex) internal view
        returns (bytes32)
    {
        uint256[2][MAX_RING_PARTICIPANT] memory publicKeys;
        uint256 receivedToken = _amountToken;

        Ring storage ring = rings[receivedToken][_ringIndex];

        for (uint8 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];

            unchecked {
                i++;
            }
        }

        (uint participants,, uint blockNum) = getRingPackedData(ring.packedRingData);

        bytes memory b = abi.encodePacked(
            blockhash(block.number - 1),
            blockNum,
            ring.amountDeposited,
            participants,
            publicKeys
        );

        return keccak256(b);
    }

    /// @notice Gets the hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function getRingHash(uint256 _amountToken, uint256 _ringIndex) public view
        returns (bytes32)
    {
        uint256 receivedToken = _amountToken;
        return rings[receivedToken][_ringIndex].ringHash;
    }

    /// @notice Gets the total amount of `token` in the ring
    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // =============================================================
    //                           UTILITIES
    // =============================================================


    /// @notice Gets the public keys of the ring
    /// @param amountToken The amount of `token` in the ring
    /// @param ringIndex The index of the ring
    function getPublicKeys(uint256 amountToken, uint256 ringIndex) public view
        returns (bytes32[2][MAX_RING_PARTICIPANT] memory)
    {
        bytes32[2][MAX_RING_PARTICIPANT] memory publicKeys;

        for (uint i = 0; i < MAX_RING_PARTICIPANT; i++) {
            publicKeys[i][0] = bytes32(rings[amountToken][ringIndex].publicKeys[i][0]);
            publicKeys[i][1] = bytes32(rings[amountToken][ringIndex].publicKeys[i][1]);
        }

        return publicKeys;
    }

    /// @notice Gets the unpacked, packed ring data
    /// @param packedData The packed ring data
    function getRingPackedData(uint packedData) public pure returns (uint256, uint256, uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return (
            p >> _BITWIDTH_PARTICIPANTS,
            p & _BITMASK_PARTICIPANTS,
            packedData & _BITMASK_BLOCK_NUM
        );
    }

    /// @notice Gets the number of participants that have withdrawn from the ring
    /// @param packedData The packed ring data
    function getWParticipant(uint256 packedData) public pure returns (uint256){
        return (packedData >> _BITWIDTH_BLOCK_NUM) >> _BITWIDTH_PARTICIPANTS;
    }

    /// @notice Gets the number of participants in the ring
    /// @param packedData The packed ring data
    function getParticipant(uint256 packedData) public pure returns (uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return p & _BITMASK_PARTICIPANTS;
    }

    /// @notice Gets the maximum number of participants in any ring
    function getRingMaxParticipants() external pure
        returns (uint256)
    {
        return MAX_RING_PARTICIPANT;
    }

    /// @notice Gets the lates ring index for `amountToken`
    /// @param amountToken The amount of `token` in the ring
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256)
    {
        return ringsNumber[amountToken];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/AltBn128.sol";
import "./lib/LSAG.sol";
import "./interfaces/IOxODexFactory.sol";
import "./interfaces/IOxODexTokenPool.sol";
import { Types } from "./OxODexPool.sol";


contract OxODexTokenPool {

    // =============================================================
    //                           ERRORS
    // =============================================================
    
    error AlreadyInitialized();
    error NotInitialized();

    // =============================================================
    //                           EVENTS
    // =============================================================
    
    event Deposit(address, uint256 tokenAmount, uint256 ringIndex);
    event Withdraw(address, uint256 tokenAmount, uint256 ringIndex);
    event Swap(address indexed tokenOut, uint256 tokenAmountIn, uint256 tokenAmountOut);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Maximum number of participants in a ring It can be changed to a higher value, 
    /// but it will increase the gas cost.
    uint256 constant MAX_RING_PARTICIPANT = 2;


    /// The participant value would use 16 bits
    uint256 constant _BITWIDTH_PARTICIPANTS = 16;

    /// The Block value would use 16 bits
    uint256 constant _BITWIDTH_BLOCK_NUM = 32;

    /// Bitmask for `numberOfParticipants`
    uint256 constant _BITMASK_PARTICIPANTS = (1 << _BITWIDTH_PARTICIPANTS) -1;

    /// Bitmask for `blockNumber`
    uint256 constant _BITMASK_BLOCK_NUM = (1 << _BITWIDTH_BLOCK_NUM) -1;


    // =============================================================
    //                           STORAGE
    // =============================================================

    struct Ring {
        /// The total amount deposited in the ring
        uint256 amountDeposited;

        /// Bits Layout:
        /// - [0..32]    `initiatedBlockNumber` 
        /// - [32..48]   `numberOfParticipants`
        /// - [48..64]   `numberOfWithdrawnParticipants`
        uint256 packedRingData; 

        /// The public keys of the participants
        mapping (uint256 => uint256[2]) publicKeys;

        /// The key images from successfully withdrawn participants
        /// NOTE: This is used to prevent double spending
        mapping (uint256 => uint256[2]) keyImages;
        bytes32 ringHash;
    }

    struct WithdrawalData {
        /// The amount to withdraw`
        uint256 amount;

        /// The index of the ring
        uint256 ringIndex;

        /// Signed message parameters
        uint256 c0;
        uint256[2] keyImage;
        uint256[] s;
        Types.WithdrawalType wType;
    }

    address public token;
    uint256 public tokenDecimals;
    address public factory;

    /// tokenAmount => ringIndex
    mapping(uint256 => uint256) public ringsNumber;

    /// tokenAmount => ringIndex => Ring
    mapping (uint256 => mapping(uint256 => Ring)) public rings;

    constructor() {}

    modifier whenNotPaused(){
        require(!IOxODexFactory(factory).paused(), "PAUSED");
        _;
    }

    /// @notice Initialize the vault to use and accept `token`
    /// @param _token The address of the token to use
    function initialize(address _token, address _factory) external {
        require(_token != address(0), "ZERO_ADDRESS");
        require(_factory != address(0), "ZERO_ADDRESS");

        if (token != address(0)) revert AlreadyInitialized();
        factory = _factory;
        token = _token;
        tokenDecimals = ERC20(_token).decimals();
    }

    /// @notice Deposit `amount` of `token` into the vault
    /// @param _amount The amount of `token` to deposit
    /// @param _publicKey The public key of the participant
    function deposit(uint _amount, uint256[4] memory _publicKey) external whenNotPaused {
        require(_amount > 0, "AMOUNT_MUST_BE_GREATER_THAN_ZERO");

        IOxODexFactory factoryContract = IOxODexFactory(factory);

        if(ERC20(factoryContract.token()).balanceOf(msg.sender) < factoryContract.getTokenFeeDiscountLimit()) {
            uint256 fee = getFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            /// Transfer the fee to the treasurer
            ERC20(token).transfer(factoryContract.treasurerAddress(), fee);   
        }else{
            uint256 fee = getDiscountFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            if(fee > 0) {
                /// Transfer the fee to the treasurer
                ERC20(token).transfer(factoryContract.treasurerAddress(), fee);  
            }
        }
        
        if (!AltBn128.onCurve(uint256(_publicKey[0]), uint256(_publicKey[1]))) {
            revert("PK_NOT_ON_CURVE");
        }

        /// Gets the current ring for the amounts
        uint256 ringIndex = ringsNumber[_amount];
        Ring storage ring = rings[_amount][ringIndex];

        (uint wParticipants,
        uint participants, uint blockNum) = getRingPackedData(ring.packedRingData);

        /// Making sure no duplicate public keys are added
        for (uint256 i = 0; i < participants;) {
            if (ring.publicKeys[i][0] == _publicKey[0] &&
                ring.publicKeys[i][1] == _publicKey[1]) {
                revert("PK_ALREADY_IN_RING");
            }

            if (ring.publicKeys[i][0] == _publicKey[2] &&
                ring.publicKeys[i][1] == _publicKey[3]) {
                revert("PK_ALREADY_IN_RING");
            }

            unchecked {
                i++;
            }
        }

        if (participants == 0) {
            blockNum = block.number - 1;
        }

        ring.publicKeys[participants] = [_publicKey[0], _publicKey[1]];
        ring.publicKeys[participants + 1] = [_publicKey[2], _publicKey[3]];
        ring.amountDeposited += _amount;
        unchecked {
            participants += 2;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        packedData = (packedData << _BITWIDTH_BLOCK_NUM) | blockNum;
        ring.packedRingData = packedData;

        /// If the ring is full, start a new ring
        if (participants >= MAX_RING_PARTICIPANT) {
            ring.ringHash = hashRing(_amount, ringIndex);
            
            /// Add new Ring pool
            ringsNumber[_amount] += 1;
        }

        emit Deposit(msg.sender, _amount, ringIndex);
    }

    modifier chargeForGas(uint256 relayerFee) {
        require(relayerFee <= IOxODexFactory(factory).maxRelayerGasCharge(address(this)) , "RELAYER_FEE_TOO_HIGH");
        _;
        if(relayerFee > 0) {
            ERC20(token).transfer(msg.sender, relayerFee);
        }
    }


    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param withdrawalData The data for the withdrawal
    /// @param relayerFee The fee to pay the relayer
    function withdraw(
        address recipient, 
        WithdrawalData memory withdrawalData,
        uint256 relayerFee
    ) public whenNotPaused chargeForGas(relayerFee)
    {
        Ring storage ring = rings[withdrawalData.amount][withdrawalData.ringIndex];

        if(withdrawalData.amount > ring.amountDeposited) {
            revert("AMOUNT_EXCEEDS_DEPOSITED");
        }

        if(withdrawalData.amount < relayerFee) {
            revert("RELAYER_FEE_TOO_HIGH");
        }

        (uint wParticipants,
        uint participants,) = getRingPackedData(ring.packedRingData);

        if (recipient == address(0)) {
            revert("ZERO_ADDRESS");
        }
        
        if (wParticipants >= MAX_RING_PARTICIPANT) {
            revert("ALL_FUNDS_WITHDRAWN");
        }

        if (ring.ringHash == bytes32(0x00)) {
            revert("RING_NOT_CLOSED");
        }

        uint256[2][] memory publicKeys = new uint256[2][](MAX_RING_PARTICIPANT);

        for (uint256 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];
            unchecked {
                i++;
            }
        }
    
        /// Attempts to verify ring signature
        bool signatureVerified = LSAG.verify(
            abi.encodePacked(ring.ringHash, recipient), // Convert to bytes
            withdrawalData.c0,
            withdrawalData.keyImage,
            withdrawalData.s,
            publicKeys
        );

        if (!signatureVerified) {
            revert("INVALID_SIGNATURE");
        }

        /// Confirm key image is not already used (no double spends)
        for (uint i = 0; i < wParticipants;) {
            if (ring.keyImages[i][0] == withdrawalData.keyImage[0] &&
                ring.keyImages[i][1] == withdrawalData.keyImage[1]) {
                revert("USED_SIGNATURE");
            }

            unchecked {
                i++;
            }
        }    

        ring.keyImages[wParticipants] = withdrawalData.keyImage;
        unchecked {
            wParticipants++;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        ring.packedRingData = (packedData << _BITWIDTH_BLOCK_NUM) | 0; // blockNum set to zero;  

        // Transfer tokens to recipient
        // If recipient is the contract, don't transfer. Used in swap
        if(withdrawalData.wType == Types.WithdrawalType.Direct){
            // Transfer amount to recipient
            _sendFundsWithRelayerFee(withdrawalData.amount - relayerFee, token, recipient);
        }

        emit Withdraw(recipient, withdrawalData.amount, withdrawalData.ringIndex);
    }

    /// @notice Calculate the fee for a given amount
    /// @param amount The amount to calculate the fee for
    function getFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * IOxODexFactory(factory).fee()) / 10_000;
    }

    /// @notice Calculate and send the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    /// @param _token The token to send the fee in
    function _sendFundsWithRelayerFee(uint256 _amount, address _token, address _recipient) private returns(uint256 relayerFee){
        relayerFee = getRelayerFeeForAmount(_amount);
        IERC20(_token).transfer(msg.sender, relayerFee);
        IERC20(_token).transfer(_recipient, _amount - relayerFee);
    }

    /// @notice Calculate the relayer fee for a given amount
    /// @param _amount The amount to calculate the fee for
    function getRelayerFeeForAmount(uint256 _amount) public view returns(uint256 relayerFee){
        relayerFee = (_amount * IOxODexFactory(factory).relayerFee()) / 10_000;
    }
    
    /// @notice Get the fee for Discount holders
    /// @param amount The amount to calculate the fee for
    function getDiscountFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * IOxODexFactory(factory).tokenFee()) / 10_000;
    }

    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param relayerFee The fee to send to the relayer
    /// @param withdrawalData The data for the withdrawal
    function swapOnWithdrawal(
        address tokenOut,
        address router,
        bytes memory params, 
        address payable recipient,
        uint256 relayerFee, 
        WithdrawalData memory withdrawalData
    ) external {
        require(recipient != address(0), "ZERO_ADDRESS");

        withdraw(
            recipient, 
            withdrawalData,
            relayerFee
        );
        IERC20(token).approve(router, withdrawalData.amount - relayerFee);

        (bool success, bytes memory data) = address(router).call(params);

        if (success == false) {
            assembly {
                // Copy the returned error string to memory
                // and revert with it.
                revert(add(data,32),mload(data))
            }
        }

        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        _sendFundsWithRelayerFee(amountOut, tokenOut, recipient);

        emit Swap(tokenOut, withdrawalData.amount, amountOut);
    }

    /// @notice Generates a hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function hashRing(uint256 _amountToken, uint256 _ringIndex) internal view
        returns (bytes32)
    {
        uint256[2][MAX_RING_PARTICIPANT] memory publicKeys;
        uint256 receivedToken = _amountToken;

        Ring storage ring = rings[receivedToken][_ringIndex];

        for (uint8 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];

            unchecked {
                i++;
            }
        }

        (uint participants,, uint blockNum) = getRingPackedData(ring.packedRingData);

        bytes memory b = abi.encodePacked(
            blockhash(block.number - 1),
            blockNum,
            ring.amountDeposited,
            participants,
            publicKeys
        );

        return keccak256(b);
    }

    /// @notice Gets the hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function getRingHash(uint256 _amountToken, uint256 _ringIndex) public view
        returns (bytes32)
    {
        uint256 receivedToken = _amountToken;
        return rings[receivedToken][_ringIndex].ringHash;
    }

    /// @notice Gets the total amount of `token` in the ring
    function getPoolBalance() external view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    // =============================================================
    //                           UTILITIES
    // =============================================================


    /// @notice Gets the public keys of the ring
    /// @param amountToken The amount of `token` in the ring
    /// @param ringIndex The index of the ring
    function getPublicKeys(uint256 amountToken, uint256 ringIndex) public view
        returns (bytes32[2][MAX_RING_PARTICIPANT] memory)
    {
        bytes32[2][MAX_RING_PARTICIPANT] memory publicKeys;

        for (uint i = 0; i < MAX_RING_PARTICIPANT; i++) {
            publicKeys[i][0] = bytes32(rings[amountToken][ringIndex].publicKeys[i][0]);
            publicKeys[i][1] = bytes32(rings[amountToken][ringIndex].publicKeys[i][1]);
        }

        return publicKeys;
    }

    /// @notice Gets the unpacked, packed ring data
    /// @param packedData The packed ring data
    function getRingPackedData(uint packedData) public pure returns (uint256, uint256, uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return (
            p >> _BITWIDTH_PARTICIPANTS,
            p & _BITMASK_PARTICIPANTS,
            packedData & _BITMASK_BLOCK_NUM
        );
    }

    /// @notice Gets the number of participants that have withdrawn from the ring
    /// @param packedData The packed ring data
    function getWParticipant(uint256 packedData) public pure returns (uint256){
        return (packedData >> _BITWIDTH_BLOCK_NUM) >> _BITWIDTH_PARTICIPANTS;
    }

    /// @notice Gets the number of participants in the ring
    /// @param packedData The packed ring data
    function getParticipant(uint256 packedData) public pure returns (uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return p & _BITMASK_PARTICIPANTS;
    }

    /// @notice Gets the maximum number of participants in any ring
    function getRingMaxParticipants() external pure
        returns (uint256)
    {
        return MAX_RING_PARTICIPANT;
    }

    /// @notice Gets the lates ring index for `amountToken`
    /// @param amountToken The amount of `token` in the ring
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256)
    {
        return ringsNumber[amountToken];
    }
}