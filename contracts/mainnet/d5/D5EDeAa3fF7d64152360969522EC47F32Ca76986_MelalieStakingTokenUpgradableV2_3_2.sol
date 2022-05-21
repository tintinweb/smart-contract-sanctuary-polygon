/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/child/MelalieDistributionPool.sol

pragma solidity ^0.8.0;

contract MelalieDistributionPool  {

    receive() payable external {}
    

}


// File contracts/child/MelalieStakingTokenUpgradableV2_3_2.sol

pragma solidity ^0.8.1;






contract MelalieStakingTokenUpgradableV2_3_2 is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public childChainManagerProxy;
    address public distributionPoolContract;
    uint256 public minimumStake;
    uint256 public totalDistributions;
    address private deployer;

    //staking
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    //events
    event StakeCreated(address indexed _from, uint256 _stake);
    event StakeRemoved(address indexed _from, uint256 _stake);
    event RewardsDistributed(uint256 _distributionAmount);
    event RewardWithdrawn(address indexed _from, uint256 _stake);

    //new variable v2
    bool private _upgradedV2;
    address private rewardDistributor; //now deprecated since v2_2 - removed function updateRewardDistribution / distributeRewards
    bool public autostake;

    //new variable v2_1
    bool private _upgradedV2_1;
    
    //new variable v2_2
    bool private _upgradedV2_2;
    uint256 public lastDistributionTimestamp; 

    //new variable v2_3
    bool private _upgradedV2_3;
    struct Stake{
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => Stake[]) internal stake_times; //time when last stake was created by stake holder
    
    //new variable v2_3_1
    bool private _upgradedV2_3_1;
    //new variable v2_3_2
    bool private _upgradedV2_3_2;
   
   function upgradeV2_3_2() public {
      require(!_upgradedV2_3_2, "MelalieStakingTokenUpgradableV2_3_2: already upgraded");

        //remove all stake_times from 0xB94a1473F2C418AAa06bf664C76D13685c559362 because he withdrew before v1 upgrade
        delete stake_times[0xB94a1473F2C418AAa06bf664C76D13685c559362];
        
        //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  receives for 11 days rewards: 3.33333333333333333 from amount: 1000.0 apy:20 (179 days old)
        rewards[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 3333333333333333330;
        stake_times[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5].push(Stake(1636683576,1000000000000000000000)); //Fri Nov 12 2021 07:19:36 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xA27B52456fb9CE5d3f2608CebDE10599A97961D5  receives for 11 days rewards: 333.33333333333333333 from amount: 100000.0 apy:20 (173 days old)
        rewards[address(0xA27B52456fb9CE5d3f2608CebDE10599A97961D5)] = 333333333333333333330;
        stake_times[0xA27B52456fb9CE5d3f2608CebDE10599A97961D5].push(Stake(1637219266,100000000000000000000000)); //Thu Nov 18 2021 12:07:46 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8Bb9ac4086df14f7977DA0537367E312618A1480  receives for 11 days rewards: 0.000000000000024 from amount: 0.0000000000072 apy:20 (181 days old)
        rewards[address(0x8Bb9ac4086df14f7977DA0537367E312618A1480)] = 24000;
        stake_times[0x8Bb9ac4086df14f7977DA0537367E312618A1480].push(Stake(1636532063,7200000)); //Wed Nov 10 2021 13:14:23 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 1.318597415488844478 from amount: 395.579224646653344534 apy:20 (238 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 1318597415488844478;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1631607492,395579224646653344534)); //Tue Sep 14 2021 13:18:12 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 4.943239187191549332 from amount: 1482.9717561574648 apy:20 (215 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 4943239187191549332;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1633597897,1482971756157464800000)); //Thu Oct 07 2021 14:11:37 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 3.833333333333333328 from amount: 1150.0 apy:20 (214 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 3833333333333333328;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1633699021,1150000000000000000000)); //Fri Oct 08 2021 18:17:01 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 3.399999999999999996 from amount: 1020.0 apy:20 (166 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 3399999999999999996;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1637829648,1020000000000000000000)); //Thu Nov 25 2021 13:40:48 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 33.33333333333333333 from amount: 10000.0 apy:20 (139 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 33333333333333333330;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1640154928,10000000000000000000000)); //Wed Dec 22 2021 11:35:28 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D  receives for 11 days rewards: 4.266666666666666666 from amount: 1280.0 apy:20 (113 days old)
        rewards[address(0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D)] = 4266666666666666666;
        stake_times[0x8b2bA74999a4822AA6721F00A5d616e3779d0B1D].push(Stake(1642420255,1280000000000000000000)); //Mon Jan 17 2022 16:50:55 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E  receives for 11 days rewards: 0.000000000000026664 from amount: 0.000000000008 apy:20 (156 days old)
        rewards[address(0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E)] = 26664;
        stake_times[0x6E20ac4E3B238eF9d9F6DfdB057b553eB9d28f6E].push(Stake(1638660503,8000000)); //Sun Dec 05 2021 04:28:23 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x29F6e022bBEB70400EBEF313d92D4D466ee9AaE0  receives for 11 days rewards: 0.003268392538705344 from amount: 0.980517761611603472 apy:20 (217 days old)
        rewards[address(0x29F6e022bBEB70400EBEF313d92D4D466ee9AaE0)] = 3268392538705344;
        stake_times[0x29F6e022bBEB70400EBEF313d92D4D466ee9AaE0].push(Stake(1633460363,980517761611603472)); //Tue Oct 05 2021 23:59:23 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x573252aA84d6AE1745A419AF903BDe40Abcb2225  receives for 11 days rewards: 0.000000002262969564 from amount: 0.000000678890869358 apy:20 (245 days old)
        rewards[address(0x573252aA84d6AE1745A419AF903BDe40Abcb2225)] = 2262969564;
        stake_times[0x573252aA84d6AE1745A419AF903BDe40Abcb2225].push(Stake(1630968360,678890869358)); //Tue Sep 07 2021 03:46:00 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xe7D272bb27CF524b5222bE9E8d9eecdd7c24B50f  receives for 11 days rewards: 197.876666666666666664 from amount: 59363.0 apy:20 (226 days old)
        rewards[address(0xe7D272bb27CF524b5222bE9E8d9eecdd7c24B50f)] = 197876666666666666664;
        stake_times[0xe7D272bb27CF524b5222bE9E8d9eecdd7c24B50f].push(Stake(1632627243,59363000000000000000000)); //Sun Sep 26 2021 08:34:03 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xfde531E7a82A122f09294Db2fDa7188dBfcA3B98  receives for 11 days rewards: 7.360559066666666664 from amount: 2208.16772 apy:20 (217 days old)
        rewards[address(0xfde531E7a82A122f09294Db2fDa7188dBfcA3B98)] = 7360559066666666664;
        stake_times[0xfde531E7a82A122f09294Db2fDa7188dBfcA3B98].push(Stake(1633444645,2208167720000000000000)); //Tue Oct 05 2021 19:37:25 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xcEd2A0e1C3d5B96D8cbeAd377b897f050b980574  receives for 11 days rewards: 0.002485481290024728 from amount: 0.745644387007419077 apy:20 (172 days old)
        rewards[address(0xcEd2A0e1C3d5B96D8cbeAd377b897f050b980574)] = 2485481290024728;
        stake_times[0xcEd2A0e1C3d5B96D8cbeAd377b897f050b980574].push(Stake(1637326175,745644387007419077)); //Fri Nov 19 2021 17:49:35 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xE343D1d52E3801F0484192fD9426608Ba640ec54  receives for 11 days rewards: 87.943863861587176596 from amount: 26383.159158476152979395 apy:20 (170 days old)
        rewards[address(0xE343D1d52E3801F0484192fD9426608Ba640ec54)] = 87943863861587176596;
        stake_times[0xE343D1d52E3801F0484192fD9426608Ba640ec54].push(Stake(1637481215,26383159158476152979395)); //Sun Nov 21 2021 12:53:35 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x5388F3c7F6EF705d3a2E2563c84875658b6aCcFd  receives for 11 days rewards: 31.359999999999999996 from amount: 9408.0 apy:20 (169 days old)
        rewards[address(0x5388F3c7F6EF705d3a2E2563c84875658b6aCcFd)] = 31359999999999999996;
        stake_times[0x5388F3c7F6EF705d3a2E2563c84875658b6aCcFd].push(Stake(1637574648,9408000000000000000000)); //Mon Nov 22 2021 14:50:48 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x24642bBbcc850cACFa7a5bCbb79c57E44373D9EE  receives for 11 days rewards: 2526.648844121175622368 from amount: 757994.653236352686712175 apy:20 (169 days old)
        rewards[address(0x24642bBbcc850cACFa7a5bCbb79c57E44373D9EE)] = 2526648844121175622368;
        stake_times[0x24642bBbcc850cACFa7a5bCbb79c57E44373D9EE].push(Stake(1637598300,757994653236352686712175)); //Mon Nov 22 2021 21:25:00 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x2bF5F4ccCe747E3828e4bd5e32074974250F4475  receives for 11 days rewards: 156.894330997026311514 from amount: 47068.299299107893454942 apy:20 (168 days old)
        rewards[address(0x2bF5F4ccCe747E3828e4bd5e32074974250F4475)] = 156894330997026311514;
        stake_times[0x2bF5F4ccCe747E3828e4bd5e32074974250F4475].push(Stake(1637634174,47068299299107893454942)); //Tue Nov 23 2021 07:22:54 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7  receives for 11 days rewards: 404.851086759494398398 from amount: 121455.32602784831952053 apy:20 (105 days old)
        rewards[address(0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7)] = 404851086759494398398;
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1643103716,121455326027848319520530)); //Tue Jan 25 2022 14:41:56 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7  receives for 11 days rewards: 287.891040221659435188 from amount: 115156.416088663774076318 apy:15 (90 days old)
        rewards[address(0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7)] = 287891040221659435188;
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1644431283,115156416088663774076318)); //Wed Feb 09 2022 23:28:03 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7  receives for 11 days rewards: 722.517974830944393342 from amount: 289007.189932377757337042 apy:15 (78 days old)
        rewards[address(0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7)] = 722517974830944393342;
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1645454728,289007189932377757337042)); //Mon Feb 21 2022 19:45:28 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7  receives for 11 days rewards: 541.363165379094746484 from amount: 216545.266151637898593979 apy:15 (71 days old)
        rewards[address(0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7)] = 541363165379094746484;
        stake_times[0x031Ad46E26ca18D44572E6d938e1cF2C35eC51C7].push(Stake(1646042049,216545266151637898593979)); //Mon Feb 28 2022 14:54:09 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x874FCf122Bb816b4BB1770A3aceb03B9B39cCa9c  receives for 11 days rewards: 222.218866666666666662 from amount: 66665.66 apy:20 (164 days old)
        rewards[address(0x874FCf122Bb816b4BB1770A3aceb03B9B39cCa9c)] = 222218866666666666662;
        stake_times[0x874FCf122Bb816b4BB1770A3aceb03B9B39cCa9c].push(Stake(1638013568,66665660000000000000000)); //Sat Nov 27 2021 16:46:08 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xfa35113163bFD33c18A01d1A62d4D14a1Ed30a42  receives for 11 days rewards: 0.000536163901166658 from amount: 0.321698340699995291 apy:10 (17 days old)
        rewards[address(0xfa35113163bFD33c18A01d1A62d4D14a1Ed30a42)] = 536163901166658;
        stake_times[0xfa35113163bFD33c18A01d1A62d4D14a1Ed30a42].push(Stake(1650688025,321698340699995291)); //Sat Apr 23 2022 09:27:05 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xCCFA24354a7Dd35AdDC70affCF9A18d7Bf1F199A  receives for 11 days rewards: 163.906008626367143556 from amount: 49171.802587910143068106 apy:20 (158 days old)
        rewards[address(0xCCFA24354a7Dd35AdDC70affCF9A18d7Bf1F199A)] = 163906008626367143556;
        stake_times[0xCCFA24354a7Dd35AdDC70affCF9A18d7Bf1F199A].push(Stake(1638530418,49171802587910143068106)); //Fri Dec 03 2021 16:20:18 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x58e05d57b0493dad1681244b6217E768c27aE2aE  receives for 11 days rewards: 0.132379310812787754 from amount: 39.713793243836327426 apy:20 (148 days old)
        rewards[address(0x58e05d57b0493dad1681244b6217E768c27aE2aE)] = 132379310812787754;
        stake_times[0x58e05d57b0493dad1681244b6217E768c27aE2aE].push(Stake(1639391180,39713793243836327426)); //Mon Dec 13 2021 15:26:20 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xadE9086630754563619908beAd432de161a1F558  receives for 11 days rewards: 15.45277103948498976 from amount: 4635.831311845496929562 apy:20 (142 days old)
        rewards[address(0xadE9086630754563619908beAd432de161a1F558)] = 15452771039484989760;
        stake_times[0xadE9086630754563619908beAd432de161a1F558].push(Stake(1639888308,4635831311845496929562)); //Sun Dec 19 2021 09:31:48 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xB8E671600583578aafCaAE44c179CE2229642d1C  receives for 11 days rewards: 0.00021386634692937 from amount: 0.06415990407881262 apy:20 (101 days old)
        rewards[address(0xB8E671600583578aafCaAE44c179CE2229642d1C)] = 213866346929370;
        stake_times[0xB8E671600583578aafCaAE44c179CE2229642d1C].push(Stake(1643464796,64159904078812620)); //Sat Jan 29 2022 18:59:56 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xF9cD228AD3D9c22aCc105C91dd82e3A1ebdE1977  receives for 11 days rewards: 16.6938924 from amount: 5008.16772 apy:20 (98 days old)
        rewards[address(0xF9cD228AD3D9c22aCc105C91dd82e3A1ebdE1977)] = 16693892400000000000;
        stake_times[0xF9cD228AD3D9c22aCc105C91dd82e3A1ebdE1977].push(Stake(1643713341,5008167720000000000000)); //Tue Feb 01 2022 16:02:21 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x3988091cFe07bA3E200E4E8b9Fdb490C2de450B4  receives for 11 days rewards: 8.767222282464471732 from amount: 3506.888912985788693641 apy:15 (90 days old)
        rewards[address(0x3988091cFe07bA3E200E4E8b9Fdb490C2de450B4)] = 8767222282464471732;
        stake_times[0x3988091cFe07bA3E200E4E8b9Fdb490C2de450B4].push(Stake(1644396156,3506888912985788693641)); //Wed Feb 09 2022 13:42:36 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x3835CB929762CBEE7d49c0D504196076f12500Ff  receives for 11 days rewards: 2250.0 from amount: 900000.0 apy:15 (87 days old)
        rewards[address(0x3835CB929762CBEE7d49c0D504196076f12500Ff)] = 2250000000000000000000;
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1644665557,900000000000000000000000)); //Sat Feb 12 2022 16:32:37 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x3835CB929762CBEE7d49c0D504196076f12500Ff  receives for 11 days rewards: 99.999999999999999996 from amount: 60000.0 apy:10 (23 days old)
        rewards[address(0x3835CB929762CBEE7d49c0D504196076f12500Ff)] = 99999999999999999996;
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1650187100,60000000000000000000000)); //Sun Apr 17 2022 14:18:20 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x3835CB929762CBEE7d49c0D504196076f12500Ff  receives for 11 days rewards: 333.33333333333333333 from amount: 200000.0 apy:10 (7 days old)
        rewards[address(0x3835CB929762CBEE7d49c0D504196076f12500Ff)] = 333333333333333333330;
        stake_times[0x3835CB929762CBEE7d49c0D504196076f12500Ff].push(Stake(1651567410,200000000000000000000000)); //Tue May 03 2022 13:43:30 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x96CB0C9FC8b78a730006632194ec0D34F2167Cda  receives for 11 days rewards: 38.044407114760392834 from amount: 15217.762845904157134614 apy:15 (85 days old)
        rewards[address(0x96CB0C9FC8b78a730006632194ec0D34F2167Cda)] = 38044407114760392834;
        stake_times[0x96CB0C9FC8b78a730006632194ec0D34F2167Cda].push(Stake(1644867410,15217762845904157134614)); //Tue Feb 15 2022 00:36:50 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0xAd233Db0Ba3dcC071b0625921eA01720CF0aBa9f  receives for 11 days rewards: 0.000000000000002514 from amount: 0.000000000001509549 apy:10 (24 days old)
        rewards[address(0xAd233Db0Ba3dcC071b0625921eA01720CF0aBa9f)] = 2514;
        stake_times[0xAd233Db0Ba3dcC071b0625921eA01720CF0aBa9f].push(Stake(1650119040,1509549)); //Sat Apr 16 2022 19:24:00 GMT+0500 (Jekaterinburg-Normalzeit) 

        //0x169c356bF2d7c25e9cf14c1Cf7d8AEa3d96A759B  receives for 11 days rewards: 6.978933445402795884 from amount: 4187.360067241677531158 apy:10 (4 days old)
        rewards[address(0x169c356bF2d7c25e9cf14c1Cf7d8AEa3d96A759B)] = 6978933445402795884;
        stake_times[0x169c356bF2d7c25e9cf14c1Cf7d8AEa3d96A759B].push(Stake(1651843995,4187360067241677531158)); //Fri May 06 2022 18:33:15 GMT+0500 (Jekaterinburg-Normalzeit) 
        _upgradedV2_3_1 = true;
        _upgradedV2_3_2 = true;
   }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner{
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function updateDistributionPool(address _distributionPoolContract) external onlyOwner {
        require(_distributionPoolContract != address(0), "Bad distributionPoolContract address");
        distributionPoolContract = _distributionPoolContract;
    }

    /**
     * @notice setAutoStake true/false
     */
    function updateAutoStake(bool _autostake) external onlyOwner {
        autostake = _autostake;
    }


   /**
    * @notice as the token bridge calls this function,
    * we mint the amount to the users balance and
    * immediately creating a stake with this amount.
    *
    * The latter function might get removed as we get more functionality onto this contract
    */
    function deposit(address user, bytes calldata depositData) external whenNotPaused {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
        
        if(autostake)
            createStake(user,amount);
    }

   /**
    * @notice Withdraw just burns the amount which triggers the POS-bridge.
    * After the next checkpoint the amount can be withrawn on Ethereum
    */
    function withdraw(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    // ---------- STAKES ----------
    /**
     * Updates minimum Stake - only owner can do
    */
    function updateMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    /**
     * @notice A method to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public whenNotPaused
    {
        createStake(msg.sender, _stake);
    }

    /**
    * @notice A method to create a stake from anybody for anybody. 
    * The transfered amount gets locked at this contract.

    * @param _stakeHolder The address of the beneficiary stake holder 
    * @param _stake The size of the stake to be created.
    */
    function createStake(address _stakeHolder, uint256 _stake)
        private whenNotPaused
    {
        require((_stakeHolder == msg.sender || msg.sender == childChainManagerProxy), "stakeholder must be msg.sender");
        require(_stake >= minimumStake, "Minimum Stake not reached");

        if(stakes[_stakeHolder] == 0) addStakeholder(_stakeHolder);
        stakes[_stakeHolder] = stakes[_stakeHolder].add(_stake);

        stake_times[_stakeHolder].push(Stake(block.timestamp,_stake));  //should contain each single stake

        //we lock the stake amount in this contract 
        _transfer(_stakeHolder,address(this), _stake);
        emit StakeCreated(_stakeHolder, _stake);
    }

    /**
     * @notice A method for a stakeholder to completely remove his stake. 
     * All stakes are removed, in case he was increasing his stakes over time! 
     */
    function removeStake() 
        public whenNotPaused
    { 
        uint256 oldStake = stakes[msg.sender];

        delete stakes[msg.sender]; 
        delete stake_times[msg.sender];
        removeStakeholder(msg.sender);

        _transfer(address(this), msg.sender, oldStake);

        emit StakeRemoved(msg.sender, oldStake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public whenNotPaused
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256)
    {
        return rewards[_stakeholder];
    }

  /**
    * @notice Get the timestamp of a stake
    * @param _stakeholder The stakeholders address
    * @param _index the index of the stake
    */   
    function stakeTimeOf(address _stakeholder, uint256 _index) public view returns(uint256)
    {
        return stake_times[_stakeholder][_index].timestamp;
    }

  /**
    * @notice Get the timestamp of a stake
    * @param _stakeholder The stakeholders address
    * @param _index the index of the stake
    */    
    function stakeAmountOf(address _stakeholder, uint256 _index) public view returns(uint256)
    {
        return stake_times[_stakeholder][_index].amount;
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * - a normal apy is 10%
     * - after 1 month apy is 15%
     * - after 3 month apy is 20%
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {

        uint256 summedReward = 0;
        Stake[] memory stakeList = stake_times[_stakeholder];
        //0. Loop over all stakes of the stakeholder
        for (uint256 s = 0; s < stakeList.length; s += 1){
        
            //1. we find out how long he was staking
            uint256 timeElapsed = block.timestamp - stakeList[s].timestamp;
            uint256 apy = 10;
        
            //2. depending on his staking time we decide the APY (10%, 15% or 20%)
            if ( timeElapsed > 60*60*24*(30+1) && timeElapsed < 60*60*24*(30*3+1)) apy = 15;
            if ( timeElapsed > 60*60*24*(30*3+1)) apy = 20;

            //3. we calculate the reward for 1 day according to the selected APY
            // summedReward = summedReward.add((stakeList[s].amount.mul(apy)).div(36000));
             summedReward = (stakeList[s].amount * apy/36000) + summedReward;
        }
        return summedReward;
    }

    /**
     *
     * @notice The method to distribute rewards to all stakeholders from 
     * the distribution contract accounts funds in MEL ("the distribution pool")
     * 
     * TODO as we register rewards for payout at some point the sum of all rewards (totalRewards) could reach an amount which is higher then the amount in the distributionPool
     * TODO in such a case the staker who withraws is rewards first will win even if he still has registered rewards left. 
     * TODO implement a requirement which checks the amount of totalRewards and the balance of the distributionPool. Best case also unstake all stakes - prevent distribution 
     * 
     */
    function distributeRewards() public whenNotPaused
    {
        require(lastDistributionTimestamp <= block.timestamp-60-60*24, "distributions should be done only once every 24h");
        lastDistributionTimestamp = block.timestamp;
        uint256 _distributionAmount = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];

            uint256 reward = calculateReward(stakeholder);
            _distributionAmount = _distributionAmount.add(reward);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }

        totalDistributions+=_distributionAmount;
        emit RewardsDistributed(_distributionAmount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public whenNotPaused
    {
        uint256 reward = rewards[msg.sender];
         rewards[msg.sender] = 0;
        _transfer(distributionPoolContract, msg.sender, reward);
        emit RewardWithdrawn(msg.sender,reward);
    }
        
    /**
     *  @notice 
     * - the owner of this smart contract should be able to transfer MelalieToken from this contract
     * - doing so he could use the staked tokens for important goals 
     */
    function sendMel(address recipient,uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @notice 
     * the owner of this smart contract should be able to transfer MelalieToken 
     * from the distribution pool contract
     */
    function sendMelFromDistributionPool(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(distributionPoolContract), recipient, amount);
    }

    /**
     * @notice The owner of this smart contract should be able to transfer ETH 
     * to any other address from this contract address
     */
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
       _unpause();
    }

   function version() public virtual pure returns (string memory){ 
      return "2.3.2";
   }
    /**
    *  @notice This smart contract should be able to receive ETH and other tokens.
    */
    receive() payable external {}
}