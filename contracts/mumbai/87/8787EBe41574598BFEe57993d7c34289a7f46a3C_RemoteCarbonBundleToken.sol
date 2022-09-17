// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '../abstracts/AbstractRemoteToken.sol';
import '../RemoteCarbonStation.sol';
import './RemoteCarbonToken.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon-Bundle Token Contract
contract RemoteCarbonBundleToken is AbstractRemoteToken {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice Tokens in this bundle
    EnumerableSetUpgradeable.AddressSet private _tokensInBundle;

    /// @notice Tokens disabled for deposit
    EnumerableSetUpgradeable.AddressSet private _tokensPausedForBundle;

    /// @notice Emitted when a token is added
    /// @param token - The token added to the bundle
    event TokenAdded(address token);

    /// @notice Emitted when a token is removed
    /// @param token - The token removed from the bundle
    event TokenRemoved(address token);

    /// @notice Emitted when a token is paused for deposited or removed
    /// @param token - The token paused for deposits
    /// @param paused - Whether the token was paused (true) or reactivated (false)
    event TokenPaused(address token, bool paused);

    /// @notice Emitted when the minimum vintage requirements change
    /// @param vintage - The new vintage after the update
    event VintageIncremented(uint16 vintage);

    /// @notice The fee divisor taken upon unbundling
    /// @dev 1/feeDivisor is the fee in %
    uint256 public feeDivisor;

    /// @notice The lower bound of carbon vintage in this bundle
    uint16 public vintage;

    /// @dev See factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        uint256 feeDivisor_,
        RemoteCarbonStation station_
    ) external initializer {
        __AbstractWrappedToken__init(name_, symbol_, station_);

        vintage = vintage_;
        feeDivisor = feeDivisor_;
        station = station_;
    }

    /// @notice Checks if a token exists
    /// @param token_ - A carbon credit token
    function hasToken(RemoteCarbonToken token_) external view returns (bool) {
        return _tokensInBundle.contains(address(token_));
    }

    /// @notice Number of tokens in this bundle
    function tokenCount() external view returns (uint256) {
        return _tokensInBundle.length();
    }

    /// @notice A token from the bundle
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index position taken from tokenCount()
    function tokenAtIndex(uint256 index_) external view returns (address) {
        return _tokensInBundle.at(index_);
    }

    /// @notice Adds a new token to the bundle.
    /// @param token_ - A carbon credit token that is added to the bundle.
    /// @return True if token was added, false it if did already exist
    function addToken(RemoteCarbonToken token_) external onlyOwner returns (bool) {
        bool isAdded = _tokensInBundle.add(address(token_));
        emit TokenAdded(address(token_));
        return isAdded;
    }

    /// @notice Removes a token from the bundle
    /// @param token_ - The carbon credit token to remove
    function removeToken(RemoteCarbonToken token_) external onlyOwner {
        address tokenAddress = address(token_);
        _tokensInBundle.remove(tokenAddress);
        emit TokenRemoved(tokenAddress);
    }

    /// @notice Check if a token is paused for deposits
    /// @param token_ - The token to check
    /// @return Whether the token is paused or not
    function pausedForBundle(RemoteCarbonToken token_) public view returns (bool) {
        return _tokensPausedForBundle.contains(address(token_));
    }

    /// @notice Pauses or reactivates deposits for carbon credits
    /// @param token_ - The token to pause or reactivate
    /// @return Whether the action had an effect (the token was not already flagged for the respective action) or not
    function pauseOrReactivateForBundle(RemoteCarbonToken token_, bool pause_) external onlyOwner returns(bool) {
        bool actionHadEffect;
        if (pause_) {
            actionHadEffect = _tokensPausedForBundle.add(address(token_));
        } else {
            actionHadEffect = _tokensPausedForBundle.remove(address(token_));
        }

        if (actionHadEffect) {
            emit TokenPaused(address(token_), pause_);
        }

        return actionHadEffect;
    }

    /// @notice Increasing the vintage
    /// @dev Does nothings if the new vintage isn't higher than the old one
    /// @param vintage_ - The new vintage (e.g. 2020)
    function increaseVintage(uint16 vintage_) external onlyOwner {
        if (vintage < vintage_) {
            vintage = vintage_;
            emit VintageIncremented(vintage);
        }
    }

    /// @dev See parent
    function _forwardOffsets(uint256 amount_) internal virtual override {
        station.forwardBundleOffset{value: msg.value}(this, amount_);
    }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '../../abstracts/AbstractCarbonToken.sol';
import '../RemoteCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Token Base-Contract
abstract contract AbstractRemoteToken is AbstractCarbonToken {

    RemoteCarbonStation public station;

    function __AbstractWrappedToken__init(
        string memory name_,
        string memory symbol_,
        RemoteCarbonStation station_
    ) internal onlyInitializing {
        __AbstractCarbonToken_init(name_, symbol_, address(station_));
        station = station_;
    }

    /// @notice Mint new tokens
    /// @dev Only the terminal station, it's guaranteed to be backed
    /// @param account_ - The address of the recipient
    /// @param amount_ - The amount of tokens to mint to the recipient
    function mint(address account_, uint256 amount_) external onlyOwner {
        _mint(account_, amount_);
    }

    /// @notice Burn tokens
    /// @dev Only the terminal station, it's guaranteed to be backed
    /// @param account_ - The address of the arsonist
    /// @param amount_ - The amount to tokens to burn from the arsonists wallet
    function burn(address account_, uint256 amount_) external onlyOwner {
        _burn(account_, amount_);
    }

    /// @notice Send all pending offset to our main network
    function releasePendingOffsetsToMainChain() external payable  {
        uint256 amount = pendingOffsetBalance;
        offsetBalance += amount;
        pendingOffsetBalance = 0;
        _forwardOffsets(amount);
    }

    /// @dev The actual forwarding implementation to the terminal station
    /// @param amount_ - The amount forwarded
    function _forwardOffsets(uint256 amount_) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '../CarbonBundleToken.sol';
import '../CarbonToken.sol';
import '../CarbonAccessListFactory.sol';
import '../abstracts/AbstractFactory.sol';
import './abstracts/AbstractCarbonStation.sol';
import './remote/RemoteCarbonBundleTokenFactory.sol';
import './remote/RemoteCarbonBundleToken.sol';
import './remote/RemoteCarbonTokenFactory.sol';
import './remote/RemoteCarbonSender.sol';
import './remote/RemoteCarbonReceiver.sol';
import './CentralCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Station Contract
contract RemoteCarbonStation is AbstractCarbonStation {

    using ClonesUpgradeable for address;

    /// @notice Emitted when the offsets of a bundle token are forwarded to the main chain for processing
    /// @param bundle - The bundle being forwarded
    /// @param amount - The amount being forwarded
    event BundleOffsetsForwarded(address bundle, uint256 amount);

    /// @notice Emitted when the offsets of a token are forwarded to the main chain for processing
    /// @param token - The token being forwarded
    /// @param amount - The amount being forwarded
    event OffsetsForwarded(address token, uint256 amount);

    /// Chain ID of the central network
    uint256 public centralChainId;

    /// Chain ID of the local network
    uint256 public localChainId;

    /// Factory for wrapped GCO2 tokens
    RemoteCarbonTokenFactory public tokenFactory;

    /// Factory for wrapped bundle tokens
    RemoteCarbonBundleTokenFactory public bundleFactory;

    /// The access list factory
    CarbonAccessListFactory public accessListFactory;

    /// Map of local bundle addresses to central bundle addresses
    mapping (address => address) public localToCentralBundles;
    /// Map of central bundle addresses to local bundle addresses
    mapping (address => address) public centralToLocalBundles;

    /// Map of local GCO2 addresses to central GCO2 addresses
    mapping (address => address) public localToCentralTokens;
    /// Map of central GCO2 addresses to local GCO2 addresses
    mapping (address => address) public centralToLocalTokens;

    /// Map of local access list addresses to central access list addresses
    mapping (address => address) public localToCentralAccessLists;
    /// Map of central access list addresses to local access list addresses
    mapping (address => address) public centralToLocalAccessLists;

    /// @dev Allow access only for carbon token contracts
    modifier onlyTokens() {
        require(
            tokenFactory.hasInstanceAt(_msgSender()) || bundleFactory.hasInstanceAt(_msgSender()),
            'RemoteCarbonStation: caller is not known to protocol'
        );
        _;
    }

    constructor(
        uint256 centralChainId_,
        uint256 localChainId_,
        address owner_
    )  AbstractCarbonStation(address(new RemoteCarbonSender(this)), address(new RemoteCarbonReceiver(this)), owner_) {
        centralChainId = centralChainId_;
        localChainId = localChainId_;

        tokenFactory = new RemoteCarbonTokenFactory(new RemoteCarbonToken(), address(this));
        bundleFactory = new RemoteCarbonBundleTokenFactory(new RemoteCarbonBundleToken(), address(this));
        accessListFactory = new CarbonAccessListFactory(new CarbonAccessList(), address(this));
    }

    /// @notice Access function to the underlying factories to change the blueprint
    /// @param factory_ - The address of the factory
    /// @param blueprint_ - The address of the new implementation
    function setFactoryBlueprint(address factory_, address blueprint_) onlyOwner external {
        AbstractFactory factory;
        if (factory_ == address(bundleFactory)) {
            factory = RemoteCarbonBundleTokenFactory(factory_);
        } else if (factory_ == address(tokenFactory)) {
            factory = RemoteCarbonTokenFactory(factory_);
        } else if (factory_ == address(accessListFactory)) {
            factory = CarbonAccessListFactory(factory_);
        } else {
            revert('RemoteCarbonStation: unknown factory');
        }
        factory.setBlueprint(blueprint_);
    }

    /// @notice Sets chain specific addresses to a access list
    /// @param accessList_ - The access list to add/remove a contract to
    /// @param account_ - The contract to add/remove
    /// @param hasAccess_ - True if adding, false to remove
    function setLocalAccess(
        ICarbonAccessList accessList_,
        address account_,
        bool hasAccess_
    ) external onlyOwner {
        require(accessListFactory.hasInstanceAt(address(accessList_)),
            'RemoteCarbonStation: access list not registered');

        accessList_.setLocalAccess(account_, hasAccess_);
    }

    /// @dev Wrap setGlobalAccess because the station owns the access lists
    function setGlobalAccess(
        ICarbonAccessList accessList_,
        address account_,
        bool hasAccess
    ) external onlyEndpoints {
        accessList_.setGlobalAccess(account_, hasAccess);
    }

    /// @notice Returns the bundle for the given address or reverts if not a valid address
    /// @param bundle_ - The address of the bundle
    function getBundle(address bundle_) external view returns (RemoteCarbonBundleToken) {
        require(bundleFactory.hasInstanceAt(bundle_),
            'RemoteCarbonStation: bundle not registered');
        return RemoteCarbonBundleToken(bundle_);
    }

    /// @notice Returns the token for the given address or reverts if not a valid address
    /// @param token_ - The address of the token
    function getToken(address token_) external view returns (RemoteCarbonToken) {
        require(tokenFactory.hasInstanceAt(token_),
            'RemoteCarbonStation: token not registered');
        return RemoteCarbonToken(token_);
    }

    /// @dev Wrap createToken because the terminal station owns the factory
    function createToken(
        address token_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        ICarbonAccessList accessList_
    ) external onlyEndpoints returns (RemoteCarbonToken){
        RemoteCarbonToken rToken = tokenFactory.createToken(
            name_, symbol_, details_, accessList_, this
        );
        localToCentralTokens[address(rToken)] = token_;
        centralToLocalTokens[token_] = address(rToken);
        return rToken;
    }

    /// @dev Wrap mint because the terminal owns the tokens
    function mint(AbstractRemoteToken token_, address account_, uint256 amount_) external onlyEndpoints {
        token_.mint(account_, amount_);
    }

    /// @dev Wrap burn because the terminal owns the tokens
    function burn(AbstractRemoteToken token_, address account_, uint256 amount_) external onlyEndpoints {
        token_.burn(account_, amount_);
    }

    /// @dev Wrap setAccessList because the station owns the tokens
    function setAccessList(RemoteCarbonToken rToken, ICarbonAccessList wList) external onlyEndpoints {
        rToken.setAccessList(wList);
    }

    /// @dev Wrap increaseOffset because the station owns the tokens
    function increaseOffset(RemoteCarbonToken rToken, address beneficiary_, uint256 amount_) external onlyEndpoints {
        rToken.increaseOffset(beneficiary_, amount_);
    }

    /// @dev Wrap incrementVintage because the station owns the tokens
    function incrementVintage(RemoteCarbonBundleToken rBundle, uint16 vintage_) external onlyEndpoints {
        rBundle.increaseVintage(vintage_);
    }

    /// @dev Wrap createBundle because the terminal station owns the factory
    function createBundle(
        address token_,
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        uint256 feeDivisor_
    ) external onlyEndpoints returns (RemoteCarbonBundleToken) {
        RemoteCarbonBundleToken rBundle = bundleFactory.createBundle(name_, symbol_, vintage_, feeDivisor_, this);
        localToCentralBundles[address(rBundle)] = token_;
        centralToLocalBundles[token_] = address(rBundle);
        return rBundle;
    }

    /// @dev Wrap addToken and removeToken because the station owns the tokens
    function registerTokenForBundle(
        RemoteCarbonBundleToken rBundle,
        RemoteCarbonToken rToken,
        bool isAdded_,
        bool isPaused_
    ) external onlyEndpoints {
        rBundle.pauseOrReactivateForBundle(rToken, isPaused_);
        if (isAdded_) {
            rBundle.addToken(rToken);
        } else {
            rBundle.removeToken(rToken);
        }
    }

    /// @dev Wrap createAccessList because the station owns the factory
    function createAccessList(
        address token_,
        string memory name_
    ) external onlyEndpoints returns (ICarbonAccessList) {
        ICarbonAccessList accessList = ICarbonAccessList(accessListFactory.createAccessList(
            name_, address(this)
        ));
        localToCentralAccessLists[address(accessList)] = token_;
        centralToLocalAccessLists[token_] = address(accessList);

        accessList.setLocalAccess(address(this), true);
        accessList.setLocalAccess(sender, true);
        accessList.setLocalAccess(receiver, true);

        return accessList;
    }

    /// @dev Send bundle offsets to the main chain for processing
    function forwardBundleOffset(
        RemoteCarbonBundleToken rBundle_,
        uint256 amount_
    ) external onlyTokens payable {
        _send(
            centralChainId,
            abi.encodeWithSelector(
              CentralCarbonReceiver.handleOffsetFromTreasury.selector,
              localToCentralBundles[address(rBundle_)],
              amount_
            )
        );
        emit BundleOffsetsForwarded(address(rBundle_), amount_);
    }

    /// @dev Send GCO2 offsets to the main chain for processing
    function forwardOffset(
        RemoteCarbonToken rToken_,
        uint256 amount_
    ) external onlyTokens payable {
        _send(
            centralChainId,
            abi.encodeWithSelector(
              CentralCarbonReceiver.handleOffsetFromTreasury.selector,
              localToCentralTokens[address(rToken_)],
              amount_
            )
        );
        emit BundleOffsetsForwarded(address(rToken_), amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '../../interfaces/ICarbonAccessList.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import '../abstracts/AbstractRemoteToken.sol';
import '../RemoteCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Token Contract
contract RemoteCarbonToken is AbstractRemoteToken {

    /// @notice Emitted when a token renounces its access list
    /// @param accessList - The address of the renounced access list
    event AccessListRenounced(address accessList);

    /// @notice Emitted when the used access list changes
    /// @param oldList - The address of the old access list
    /// @param newList - The address of the new access list
    event AccessListChanged(address oldList, address newList);

    /// @notice Emitted when an increase is coming from a remote chain
    /// @param account_ - The account to increase
    /// @param amount_ - The amount that is increased
    event RemoteOffsetIncreased(address account_, uint256 amount_);

    /// @notice Token metadata
    CarbonToken.TokenDetails private _details;

    /// @notice The access list associated with this token
    ICarbonAccessList public accessList;

    /// @dev See factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        ICarbonAccessList accessList_,
        RemoteCarbonStation station_
    ) external initializer {
        __AbstractWrappedToken__init(name_, symbol_, station_);

        _details = details_;
        accessList = accessList_;
    }

    /// @notice The registry holding the underlying credits (e.g. 'VERRA')
    function registry() external view returns (string memory) {
      return _details.registry;
    }

    /// @notice The standard of this token (e.g. 'VERRA_VERIFIED_CARBON_STANDARD')
    function standard() external view returns (string memory) {
        return _details.standard;
    }

    /// @notice The creditType of this token (e.g. 'AGRICULTURE_FORESTRY_AND_OTHER_LAND_USE')
    function creditType() external view returns (string memory) {
        return _details.creditType;
    }

    /// @notice The guaranteed vintage of this token - newer is possible because new is always better :-)
    function vintage() external view returns (uint16) {
        return _details.vintage;
    }

    /// @notice Set the access list
    /// @param accessList_ - The access list to use
    /// @dev Since this may only be invoked by contracts, there is no dedicated renounce function
    function setAccessList(ICarbonAccessList accessList_) onlyOwner external {
        address oldList = address(accessList);
        address newList = address(accessList_);

        if (oldList == newList) {
            return;
        } else if (newList != address(0)) {
            accessList = accessList_;
            emit AccessListChanged(oldList, newList);
        } else {
            accessList = ICarbonAccessList(address(0));
            emit AccessListRenounced(oldList);
        }
    }

    /// @notice The terminal function increases the offset
    /// @dev This happens if a ping-pong with an exposure function happened (e.g. offset specific)
    /// @param account_ - The account for which the offset is increased
    /// @param amount_ - The amount to offset
    function increaseOffset(address account_, uint256 amount_) external onlyOwner  {
        // We mint to the terminal station to simplify bookkeeping
        _mint(_msgSender(), amount_);
        _offset(account_, amount_);

        // The balance is already forwarded to the central network
        pendingOffsetBalance -= amount_;
        emit RemoteOffsetIncreased(account_, amount_);

    }

    /// @dev See parent
    function _forwardOffsets(uint256 amount_) internal virtual override {
        station.forwardOffset{value: msg.value}(this, amount_);
    }

    /// @notice Override ERC20.transfer to respect access lists
    /// @param from_ - The senders address
    /// @param to_ - The recipients address
    /// @param amount_ - The amount of tokens to send
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(accessList) != address(0)) {
            require(accessList.hasAccess(from_),
                'RemoteCarbonToken: the sender is not allowed to transfer this token');
            require(accessList.hasAccess(to_),
                'RemoteCarbonToken: the recipient is not allowed to receive this token');
        }
        return super._transfer(from_, to_, amount_);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '../interfaces/ICarbonToken.sol';

/// @author FlowCarbon LLC
/// @title Carbon Token Base-Contract
abstract contract AbstractCarbonToken is Initializable, OwnableUpgradeable, ERC20Upgradeable, ICarbonToken {

    /// @notice The time and amount of a specific offset
    struct OffsetEntry {
        uint time;
        uint amount;
    }

    /// @notice Emitted when the underlying token is offset
    /// @param amount - The amount of tokens offset
    /// @param checksum - The checksum associated with the offset event
    event FinalizeOffset(uint256 amount, bytes32 checksum);

    /// @notice User mapping to the amount of offset tokens
    mapping (address => uint256) internal _offsetBalances;

    /// @notice Number of tokens offset by the protocol that have not been finalized yet
    uint256 public pendingOffsetBalance;

    /// @notice Number of tokens fully offset
    uint256 public offsetBalance;

    /// @dev Mapping of user to offsets to make them discoverable
    mapping(address => OffsetEntry[]) private _offsets;

    function __AbstractCarbonToken_init(
        string memory name_,
        string memory symbol_,
        address owner_
    ) internal onlyInitializing {
        require(bytes(name_).length != 0,
            'AbstractCarbonToken: name is required');
        require(bytes(symbol_).length != 0,
            'AbstractCarbonToken: symbol is required');

        __ERC20_init(name_, symbol_);
        __Ownable_init();
        transferOwnership(owner_);
    }

    /// @dev See ICarbonTokenInterface
    function offsetCountOf(address address_) external view returns (uint256) {
        return _offsets[address_].length;
    }

    /// @dev See ICarbonTokenInterface
    function offsetAmountAtIndex(address address_, uint256 index_) external view returns(uint256) {
        return _offsets[address_][index_].amount;
    }

    /// @dev See ICarbonTokenInterface
    function offsetTimeAtIndex(address address_, uint256 index_) external view returns(uint256) {
        return _offsets[address_][index_].time;
    }

    //// @dev See ICarbonTokenInterface
    function offsetBalanceOf(address account_) external view returns (uint256) {
        return _offsetBalances[account_];
    }

    /// @dev Common functionality of the two offset functions
    function _offset(address account_, uint256 amount_) internal {
        _burn(_msgSender(), amount_);
        _offsetBalances[account_] += amount_;
        pendingOffsetBalance += amount_;
        _offsets[account_].push(OffsetEntry(block.timestamp, amount_));

        emit Offset(account_, amount_);
    }

    /// @dev See ICarbonTokenInterface
    function offsetOnBehalfOf(address account_, uint256 amount_) external {
        _offset(account_, amount_);
    }

    /// @dev See ICarbonTokenInterface
    function offset(uint256 amount_) external {
        _offset(_msgSender(), amount_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('AbstractCarbonToken: renouncing ownership is disabled');
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/// @author FlowCarbon LLC
/// @title Carbon Token Interface
interface ICarbonToken is IERC20Upgradeable {

    /// @notice Emitted when someone offsets carbon tokens
    /// @param account - The account credited with offsetting
    /// @param amount - The amount of carbon that was offset
    event Offset(address account, uint256 amount);

    /// @notice Offset on behalf of the user
    /// @dev This will only offset tokens send by msg.sender, increases tokens awaiting finalization
    /// @param amount_ - The number of tokens to be offset
    function offset(uint256 amount_) external;

    /// @notice Offsets on behalf of the given address
    /// @dev This will offset tokens on behalf of account, increases tokens awaiting finalization
    /// @param account_ - The address of the account to offset on behalf of
    /// @param amount_ - The number of tokens to be offset
    function offsetOnBehalfOf(address account_, uint256 amount_) external;

    /// @notice Return the balance of tokens offsetted by the given address
    /// @param account_ - The account for which to check the number of tokens that were offset
    /// @return The number of tokens offsetted by the given account
    function offsetBalanceOf(address account_) external view returns (uint256);

    /// @notice Returns the number of offsets for the given address
    /// @dev This is a pattern to discover all offsets and their occurrences for a user
    /// @param address_ - Address of the user that offsetted the tokens
    function offsetCountOf(address address_) external view returns(uint256);

    /// @notice Returns amount of offsetted tokens for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetAmountAtIndex(address address_, uint256 index_) external view returns(uint256);

    /// @notice Returns the timestamp of an offset for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetTimeAtIndex(address address_, uint256 index_) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import './abstracts/AbstractCarbonToken.sol';
import './CarbonToken.sol';
import './CarbonTokenFactory.sol';
import './libraries/CarbonIntegrity.sol';

/// @author FlowCarbon LLC
/// @title Carbon Bundle-Token Contract
contract CarbonBundleToken is AbstractCarbonToken {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice The token address and amount of an offset event
    /// @dev The struct is stored for each checksum
    struct TokenChecksum {
        address _tokenAddress;
        uint256 _amount;
    }

    /// @notice Emitted when someone bundles tokens into the bundle token
    /// @param account - The token sender
    /// @param amount - The amount of tokens to bundle
    /// @param tokenAddress - The address of the vanilla underlying
    event Bundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when someone unbundles tokens from the bundle
    /// @param account - The token recipient
    /// @param amount - The amount of unbundled tokens
    /// @param tokenAddress - The address of the vanilla underlying
    event Unbundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when a new token is added to the bundle
    /// @param tokenAddress - The new token that is added
    event TokenAdded(address tokenAddress);

    /// @notice Emitted when a new token is removed from the bundle
    /// @param tokenAddress - The token that has been removed
    event TokenRemoved(address tokenAddress);

    /// @notice Emitted when a token is paused for deposited or removed
    /// @param token - The token paused for deposits
    /// @param paused - Whether the token was paused (true) or reactivated (false)
    event TokenPaused(address token, bool paused);

    /// @notice Emitted when the minimum vintage requirements change
    /// @param vintage - The new vintage after the update
    event VintageIncremented(uint16 vintage);

    /// @notice Emitted when an amount of the bundle is reserved for finalisation
    /// @param tokenAddress - The token that reserves a batch
    event ReservedForFinalization(address tokenAddress, uint256 amount);

    /// @notice The token factory for carbon credit tokens
    CarbonTokenFactory public tokenFactory;

    /// @notice The fee divisor taken upon unbundling
    /// @dev 1/feeDivisor is the fee in %
    uint256 public feeDivisor;

    /// @notice The minimal vintage
    uint16 public vintage;

    /// @notice The CarbonTokens that form this bundle
    EnumerableSetUpgradeable.AddressSet private _tokensInBundle;

    /// @notice Tokens disabled for deposit
    EnumerableSetUpgradeable.AddressSet private _tokensPausedForBundle;

    /// @notice Bookkeping of the token amounts are in this bundle
    /// @dev This could differ from the balance if someone sends raw tokens to the contract
    mapping (CarbonToken => uint256) public amountInBundle;

    /// @notice Amount reserved for offsetting
    mapping (CarbonToken => uint256) public amountReserved;

    /// @notice Total amount of reserved tokens
    uint256 public amountReservedInBundle;

    /// @notice Keeps track of checksums, amounts and underlying tokens
    mapping (bytes32 => TokenChecksum) private _offsetChecksums;

    /// Our minimum supported vintage
    uint16 constant MIN_VINTAGE_YEAR = 2000;

    /// Exists only for sanity checking
    uint16 constant MAX_VINTAGE_YEAR = 2100;

    /// Limit on vintage increments
    uint8 constant MAX_VINTAGE_INCREMENT = 10;

    /// @dev See factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_,
        CarbonTokenFactory tokenFactory_
    ) external initializer {
        require(vintage_ > MIN_VINTAGE_YEAR,
            'CarbonBundleToken: vintage out of bounds');
        require(vintage_ < MAX_VINTAGE_YEAR,
            'CarbonBundleToken: vintage out of bounds');
        require(address(tokenFactory_) != address(0),
            'CarbonBundleToken: token factory is required');

        __AbstractCarbonToken_init(name_, symbol_, owner_);

        vintage = vintage_;
        feeDivisor = feeDivisor_;
        tokenFactory = tokenFactory_;

        for (uint256 i = 0; i < tokens_.length; i++) {
            _addToken(tokens_[i]);
        }
    }

    /// @notice Increasing the vintage
    /// @dev Existing tokens can no longer be bundled, new tokens require the new vintage
    /// @param years_ - Number of years to increment the vintage, needs to be smaller than MAX_VINTAGE_INCREMENT
    function incrementVintage(uint16 years_) external onlyOwner returns (uint16) {
        require(years_ <= MAX_VINTAGE_INCREMENT,
            'CarbonBundleToken: vintage increment is too large');
        require(vintage + years_ < MAX_VINTAGE_YEAR,
            'CarbonBundleToken: vintage too high');

        vintage += years_;
        emit VintageIncremented(vintage);
        return vintage;
    }

    /// @notice Check if a token is paused for deposits
    /// @param token_ - The token to check
    /// @return Whether the token is paused or not
    function pausedForBundle(CarbonToken token_) public view returns (bool) {
        return _tokensPausedForBundle.contains(address(token_));
    }

    /// @notice Pauses or reactivates deposits for carbon credits
    /// @param token_ - The token to pause or reactivate
    /// @return Whether the action had an effect (the token was not already flagged for the respective action) or not
    function pauseOrReactivateForBundle(CarbonToken token_, bool pause_) external onlyOwner returns(bool) {
        CarbonIntegrity.requireHasToken(this, token_);

        bool actionHadEffect;
        if (pause_) {
            actionHadEffect = _tokensPausedForBundle.add(address(token_));
        } else {
            actionHadEffect = _tokensPausedForBundle.remove(address(token_));
        }

        if (actionHadEffect) {
            emit TokenPaused(address(token_), pause_);
        }

        return actionHadEffect;
    }

    /// @notice Withdraws tokens that have been transferred to the contract
    /// @dev This may happen if people accidentally transfer tokens to the bundle instead of using the bundle function
    /// @param token_ - The token to withdraw orphans for
    /// @return The amount withdrawn to the owner
    function withdrawOrphanedToken(CarbonToken token_) public returns (uint256) {
        uint256 _orphanTokens = token_.balanceOf(address(this)) - amountInBundle[token_];

        if (_orphanTokens > 0) {
            SafeERC20Upgradeable.safeTransfer(token_, owner(), _orphanTokens);
        }
        return _orphanTokens;
    }

    /// @notice Checks if a token exists
    /// @param token_ - A carbon credit token
    function hasToken(CarbonToken token_) public view returns (bool) {
        return _tokensInBundle.contains(address(token_));
    }

    /// @notice Number of tokens in this bundle
    function tokenCount() external view returns (uint256) {
        return _tokensInBundle.length();
    }

    /// @notice A token from the bundle
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index position taken from tokenCount()
    function tokenAtIndex(uint256 index_) external view returns (address) {
        return _tokensInBundle.at(index_);
    }

    /// @notice Adds a new token to the bundle. The token has to match the TokenDetails signature of the bundle
    /// @param token_ - A carbon credit token that is added to the bundle.
    /// @return True if token was added, false it if did already exist
    function addToken(CarbonToken token_) external onlyOwner returns (bool) {
        return _addToken(token_);
    }

    /// @dev Private function to execute addToken so it can be used in the initializer
    /// @return True if token was added, false it if did already exist
    function _addToken(CarbonToken token_) private returns (bool) {
        CarbonIntegrity.requireIsEligibleForBundle(this, token_);

        bool isAdded = _tokensInBundle.add(address(token_));
        emit TokenAdded(address(token_));
        return isAdded;
    }

    /// @notice Removes a token from the bundle
    /// @param token_ - The carbon credit token to remove
    function removeToken(CarbonToken token_) external onlyOwner {
        CarbonIntegrity.requireHasToken(this, token_);

        withdrawOrphanedToken(token_);
        require(token_.balanceOf(address(this)) == 0,
            'CarbonBundleToken: token has remaining balance');

        address tokenAddress = address(token_);
        _tokensInBundle.remove(tokenAddress);
        emit TokenRemoved(tokenAddress);
    }

    /// @notice Bundles an underlying into the bundle, bundle need to be approved beforehand
    /// @param token_ - The carbon credit token to bundle
    /// @param amount_ - The amount one wants to bundle
    function bundle(CarbonToken token_, uint256 amount_) external returns (bool) {
        CarbonIntegrity.requireCanBundleToken(this, token_, amount_);

        _mint(_msgSender(), amount_);
        amountInBundle[token_] += amount_;
        SafeERC20Upgradeable.safeTransferFrom(token_, _msgSender(), address(this), amount_);

        emit Bundle(_msgSender(), amount_, address(token_));
        return true;
    }

    /// @notice Unbundles an underlying from the bundle, note that a fee may apply
    /// @param token_ - The carbon credit token to undbundle
    /// @param amount_ - The amount one wants to unbundle (including fee)
    /// @return The amount of tokens after fees
    function unbundle(CarbonToken token_, uint256 amount_) external returns (uint256) {
        CarbonIntegrity.requireCanUnbundleToken(this, token_, amount_);

        _burn(_msgSender(), amount_);

        uint256 amountToUnbundle = amount_;
        if (feeDivisor > 0) {
            uint256 feeAmount = amount_ / feeDivisor;
            amountToUnbundle = amount_ - feeAmount;
            SafeERC20Upgradeable.safeTransfer(token_, owner(), feeAmount);
        }

        amountInBundle[token_] -= amount_;
        SafeERC20Upgradeable.safeTransfer(token_, _msgSender(), amountToUnbundle);

        emit Unbundle(_msgSender(), amountToUnbundle, address(token_));
        return amountToUnbundle;
    }

    /// @notice Reserves a specific amount of tokens for finalization of offsets
    /// @dev To avoid race-conditions this function should be called before completing the off-chain retirement process
    /// @param token_ - The token to reserve
    /// @param amount_ - The amount of tokens to reserve
    function reserveForFinalization(CarbonToken token_, uint256 amount_) external onlyOwner {
        CarbonIntegrity.requireHasToken(this, token_);

        amountReservedInBundle -= amountReserved[token_];
        amountReserved[token_] = amount_;
        amountReservedInBundle += amount_;

        require(pendingOffsetBalance >= amountReservedInBundle,
            'CarbonBundleToken: cannot reserve more than what is currently pending');

        emit ReservedForFinalization(address(token_), amount_);
    }

    /// @notice The contract owner can finalize the offsetting process once the underlying tokens have been offset
    /// @param token_ - The carbon credit token to finalize the offsetting process for
    /// @param amount_ - The number of token to finalize offsetting process for
    /// @param checksum_ - The checksum associated with the underlying offset event
    function finalizeOffset(CarbonToken token_, uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        CarbonIntegrity.requireCanFinalizeOffset(this, token_, amount_, checksum_);

        pendingOffsetBalance -= amount_;
        _offsetChecksums[checksum_] = TokenChecksum(address(token_), amount_);
        offsetBalance += amount_;
        amountInBundle[token_] -= amount_;

        token_.burn(amount_);

        amountReservedInBundle -= amount_;
        amountReserved[token_] -= amount_;

        emit FinalizeOffset(amount_, checksum_);
        return true;
    }

    /// @notice Return the balance of tokens offsetted by an address that match the given checksum
    /// @param checksum_ - The checksum of the associated offset event of the underlying token
    /// @return The number of tokens that have been offsetted with this checksum
    function amountOffsettedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _offsetChecksums[checksum_]._amount;
    }

    /// @param checksum_ - The checksum of the associated offset event of the underlying
    /// @return The address of the CarbonToken that has been offset with this checksum
    function tokenAddressOffsettedWithChecksum(bytes32 checksum_) external view returns (address) {
        return _offsetChecksums[checksum_]._tokenAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import './abstracts/AbstractCarbonToken.sol';
import './interfaces/ICarbonAccessList.sol';
import './CarbonBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Token Contract
contract CarbonToken is AbstractCarbonToken {

    /// @notice Emitted when a token renounces its access list
    /// @param accessList - The address of the renounced access list
    event AccessListRenounced(address accessList);

    /// @notice Emitted when the used access list changes
    /// @param oldList - The address of the old access list
    /// @param newList - The address of the new access list
    event AccessListChanged(address oldList, address newList);

    /// @notice The details of a token
    struct TokenDetails {
        /// The standard used during certification (e.g. VERRA_VERIFIED_CARBON_STANDARD)
        string registry;
        /// The standard used during certification (e.g. VERRA_VERIFIED_CARBON_STANDARD)
        string standard;
        /// The credit type of the token (e.g. AGRICULTURE_FORESTRY_AND_OTHER_LAND_USE)
        string creditType;
        /// The year in which the offset took place
        uint16 vintage;
    }

    /// @notice Token metadata
    TokenDetails private _details;

    /// @notice The access associated with this token
    ICarbonAccessList public accessList;

    /// @notice The bundle token factory associated with this token
    CarbonBundleTokenFactory public bundleFactory;

    /// @notice Emitted when the contract owner mints new tokens
    /// @dev The account is already in the Transfer Event and thus omitted here
    /// @param amount - The amount of tokens that were minted
    /// @param checksum - A checksum associated with the underlying purchase event
    event Mint(uint256 amount, bytes32 checksum);

    /// @notice Checksums associated with the underlying mapped to the number of minted tokens
    mapping (bytes32 => uint256) private _checksums;

    /// @notice Checksums associated with the underlying offset event mapped to the number of finally offsetted tokens
    mapping (bytes32 => uint256) private _offsetChecksums;

    /// @notice Number of tokens removed from chain
    uint256 public movedOffChain;

    /// @dev See CarbonTokenFactory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        TokenDetails memory details_,
        ICarbonAccessList accessList_,
        address owner_,
        CarbonBundleTokenFactory bundleFactory_
    ) external initializer {
        require(details_.vintage > 2000,
            'CarbonToken: vintage out of bounds');
        require(details_.vintage < 2100,
            'CarbonToken: vintage out of bounds');
        require(bytes(details_.registry).length > 0,
            'CarbonToken: registry is required');
        require(bytes(details_.standard).length > 0,
            'CarbonToken: standard is required');
        require(bytes(details_.creditType).length > 0,
            'CarbonToken: credit type is required');
        require(address(bundleFactory_) != address(0),
            'CarbonToken: bundle factory is required');

        __AbstractCarbonToken_init(name_, symbol_, owner_);
        _details = details_;
        accessList = accessList_;
        bundleFactory = bundleFactory_;
    }

    /// @notice Mints new tokens, a checksum representing purchase of the underlying with the minting event
    /// @param account_ - The account that will receive the new tokens
    /// @param amount_ - The amount of new tokens to be minted
    /// @param checksum_ - A checksum associated with the underlying purchase event
    function mint(address account_, uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        require(checksum_ != 0,
            'CarbonToken: checksum is required');
        require(_checksums[checksum_] == 0,
            'CarbonToken: checksum already used');

        _mint(account_, amount_);
        _checksums[checksum_] = amount_;
        emit Mint(amount_, checksum_);
        return true;
    }

    /// @notice Get the amount of tokens minted with the given checksum
    /// @param checksum_ - The checksum associated with a minting event
    /// @return The amount minted with the associated checksum
    function amountMintedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _checksums[checksum_];
    }

    /// @notice The contract owner can finalize the offsetting process once the underlying tokens have been offset
    /// @param amount_ - The number of token to finalize offsetting
    /// @param checksum_ - The checksum associated with the underlying offset event
    function finalizeOffset(uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        require(checksum_ != 0,
            'CarbonToken: checksum is required');
        require(_offsetChecksums[checksum_] == 0,
            'CarbonToken: checksum already used');
        require(amount_ <= pendingOffsetBalance,
            'CarbonToken: offset exceeds pending balance');

        _offsetChecksums[checksum_] = amount_;
        pendingOffsetBalance -= amount_;
        offsetBalance += amount_;
        emit FinalizeOffset(amount_, checksum_);
        return true;
    }

    /// @dev Allow only privileged users to burn the given amount of tokens
    /// @param amount_ - The amount of tokens to burn
    function burn(uint256 amount_) public virtual {
        require(_msgSender() == owner() || bundleFactory.hasInstanceAt(_msgSender()),
            'CarbonToken: caller is not allowed to burn');

        _burn(_msgSender(), amount_);
        if (owner() == _msgSender()) {
            movedOffChain += amount_;
        }
    }

    /// @notice Return the balance of tokens offsetted by an address that match the given checksum
    /// @param checksum_ - The checksum of the associated offset event of the underlying token
    /// @return The number of tokens that have been offsetted with this checksum
    function amountOffsettedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _offsetChecksums[checksum_];
    }

    /// @notice The registry holding the underlying credits (e.g. 'VERRA' or 'GOLDSTANDARD')
    function registry() external view returns (string memory) {
        return _details.registry;
    }

    /// @notice The standard of this token (e.g. 'VERIFIED_CARBON_STANDARD')
    function standard() external view returns (string memory) {
        return _details.standard;
    }

    /// @notice The creditType of this token (e.g. 'WETLAND_RESTORATION', or 'REFORESTATION')
    function creditType() external view returns (string memory) {
        return _details.creditType;
    }

    /// @notice The guaranteed vintage of this token - newer is possible because new is always better :-)
    function vintage() external view returns (uint16) {
        return _details.vintage;
    }

    /// @notice Renounce the access list, making this token accessible to everyone
    /// NOTE: This operation is *irreversible* and will leave the token permanently non-permissioned!
    function renounceAccessList() onlyOwner external {
        accessList = ICarbonAccessList(address(0));
        emit AccessListRenounced(address(this));
    }

    /// @notice Set the access list
    /// @param accessList_ - The access list to use
    function setAccessList(ICarbonAccessList accessList_) onlyOwner external {
        require(address(accessList) != address(0),
            'CarbonToken: invalid attempt at changing the access list');
        require(address(accessList_) != address(0),
            'CarbonToken: invalid attempt at renouncing the access list');
        address oldAccessListAddress = address(accessList);
        accessList = accessList_;
        emit AccessListChanged(oldAccessListAddress, address(accessList_));
    }

    /// @notice Override ERC20.transfer to respect access lists
    /// @param from_ - The senders address
    /// @param to_ - The recipients address
    /// @param amount_ - The amount of tokens to send
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(accessList) != address(0)) {
            require(accessList.hasAccess(from_),
                'CarbonToken: the sender is not allowed to transfer this token');
            require(accessList.hasAccess(to_),
                'CarbonToken: the recipient is not allowed to receive this token');
        }
        return super._transfer(from_, to_, amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CarbonAccessList.sol';
import './abstracts/AbstractFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Access List Factory Contract
contract CarbonAccessListFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param blueprint_ - The contract to be used as implementation for new lists
    /// @param owner_ - The address to which ownership of this contract will be transferred
    constructor (CarbonAccessList blueprint_, address owner_) {
        setBlueprint(address(blueprint_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon access list
    /// @param name_ - The name given to the newly deployed list
    /// @param owner_ - The address to which ownership of the deployed contract will be transferred
    /// @return The address of the newly created list
    function createAccessList(string memory name_, address owner_) onlyOwner external returns (address) {
        CarbonAccessList accessList = CarbonAccessList(blueprint.clone());
        accessList.initialize(name_, owner_);
        finalizeCreation(address(accessList));
        return address(accessList);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @author FlowCarbon LLC
/// @title Factory Base-Contract
abstract contract AbstractFactory is Ownable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice Emitted after the implementation contract has been swapped
    /// @param blueprint - The address of the new implementation contract
    event BlueprintChanged(address blueprint);

    /// @notice Emitted after a new token has been created by this factory
    /// @param instance - The address of the freshly deployed contract
    event InstanceCreated(address instance);

    /// @notice The implementation contract used to create new instances
    address public blueprint;

    /// @dev Discoverable contracts that have been deployed by this factory
    EnumerableSetUpgradeable.AddressSet private _instances;

    /// @notice The owner is able to swap out the underlying token implementation
    /// @param blueprint_ - The contract to be used from now on
    function setBlueprint(address blueprint_) onlyOwner public returns (bool) {
        require(blueprint_ != address(0),
            'AbstractFactory: null address given as implementation contract');
        blueprint = blueprint_;
        emit BlueprintChanged(blueprint_);
        return true;
    }

    /// @notice The number of contracts deployed by this factory
    function instanceCount() external view returns (uint256) {
        return _instances.length();
    }

    /// @notice Check if a contract as been released by this factory
    /// @param address_ - The address of the contract
    /// @return Whether this contract has been deployed by this factory
    function hasInstanceAt(address address_) external view returns (bool) {
        return _instances.contains(address_);
    }

    /// @notice The contract deployed at a specific index
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index into the set
    function instanceAt(uint256 index_) external view returns (address) {
        return _instances.at(index_);
    }

    /// @dev Internal function that should be called after each clone
    /// @param address_ - A freshly created token address
    function finalizeCreation(address address_) internal {
        _instances.add(address_);
        emit InstanceCreated(address_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('AbstractFactory: renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IBridgeReceiver.sol';
import '../interfaces/IBridge.sol';
import '../../CarbonBundleToken.sol';

/// @author FlowCarbon LLC
/// @title Carbon Station Base-Contract
abstract contract AbstractCarbonStation is IBridgeReceiver, Ownable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// @notice Emitted when native tokens are sent to this account
    /// @param account - The sender
    /// @param amount - The amount received
    event Received(address account, uint amount);

    /// @notice Emitted when a remote contract is registered
    /// @param bridgeAdapter - Address of the bridge adapter
    /// @param destination - The remote chain ID
    /// @param registeredContract - The registered contract
    event RemoteContractRegistered(address bridgeAdapter, uint256 destination, address registeredContract);

    /// @notice Emitted when a new bridge is configured for a chain
    /// @param destination - The remote chain ID
    /// @param bridgeAdapter - Address of the bridge adapter
    /// @param identifier - Hashed identifier of the bridge
    event BridgeConfigured(uint256 destination, address bridgeAdapter, bytes32 identifier);

    /// @notice Action Endpoint updated
    /// @param sender - New endpoint address
    event SenderChanged(address sender);

    /// @notice Handler Endpoint updated
    /// @param receiver - New endpoint address
    event ReceiverChanged(address receiver);

    /// Mapping of chain IDs to remote bridge addresses
    mapping(uint256 => address) public remoteBridges;

    /// Mapping of chain IDs to local bridge interfaces
    mapping(uint256 => IBridge) public bridges;

    /// Set of chain IDs which local bridge adapters
    EnumerableSetUpgradeable.UintSet private _supportedBridges;

    /// All actions configured for this station can be found here
    address public sender;

    /// All handlers that this station can handle
    address public receiver;

    /// If this is set, no further changes to the endpoints will be accepted
    bool public endpointsFinal;

    /// @dev Allows only the action or handler endpoints access to a method
    modifier onlyEndpoints() {
        require(_msgSender() == sender || _msgSender() == receiver,
            'AbstractCarbonStation: caller is not a station endpoint');
        _;
    }

    constructor(address actionEndpoint_, address handlerEndpoint_, address owner_)  {
        sender = actionEndpoint_;
        receiver = handlerEndpoint_;
        transferOwnership(owner_);
    }

    /// @notice Finalizing the sender and receiver endpoints will disable *all* future changes to them
    ///         THIS OPERATION IS IRREVERSIBLE, USE WITH CARE!
    function finalizeEndpoints() external onlyOwner {
        endpointsFinal = true;
    }

    /// @notice Configure a new action endpoint
    /// @param sender_ - Address of the new action endpoint
    function setSender(address sender_) external onlyOwner {
        require(!endpointsFinal, 'AbstractCarbonStation: endpoints are finalized');
        // NOTE: setting the endpoint to address(0) is possible in case of emergency
        sender = sender_;
        emit SenderChanged(sender_);
    }

    /// @notice Configure a new handler endpoint
    /// @param receiver_ - Address of the new handler endpoint
    function setReceiver(address receiver_) external onlyOwner {
        require(!endpointsFinal, 'AbstractCarbonStation: endpoints are finalized');
        // NOTE: setting the endpoint to address(0) is possible in case of emergency
        receiver = receiver_;
        emit ReceiverChanged(receiver_);
    }

    /// @notice Checks if we have a bridge for a given destination
    /// @return True if we have support, else false
    function hasBridge(uint256 destination_) public view returns (bool) {
        return _supportedBridges.contains(destination_);
    }

    /// @notice Returns the local bridge adapter for the given destination
    /// @dev Reverts if no bridge exists
    /// @param destination_ - The target chain
    /// @return The bridge for the given destination
    function getBridge(uint256 destination_) public view returns (IBridge) {
        require(hasBridge(destination_),
            'AbstractCarbonStation: no bridge registered for destination');
        return bridges[destination_];
    }

    /// @return The number of bridges / chains supported
    function bridgesCount() external view returns (uint256) {
        return _supportedBridges.length();
    }

    /// @notice The local bridge adapter at the given index
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index into the set
    /// @return The bridge at the given index
    function bridgeAt(uint256 index_) external view returns (IBridge) {
        return bridges[_supportedBridges.at(index_)];
    }

    /// @notice Add or remove a bridge adapter
    /// @param destination_ - The target destination chain
    /// @param bridge_ - The bridge adapter to use, address(0) disables the destination
    function registerBridge(uint256 destination_, IBridge bridge_) external onlyOwner {
        bridges[destination_] = bridge_;
        if (address(bridge_) == address(0)) {
            _supportedBridges.remove(destination_);
            /// NOTE: zero address indicates removal
            emit BridgeConfigured(destination_, address(bridge_), bytes32(uint256(uint160(0))));
        } else {
            _supportedBridges.add(destination_);
            emit BridgeConfigured(destination_, address(bridge_), bridge_.getIdentifier());
        }
    }

    /// @notice Registers a remote contract as authentic for this station
    /// @param destination_ - The remote chain ID
    /// @param contract_ - The address of the contract to trust as a message sender
    function registerRemoteContract(uint256 destination_, address contract_) external onlyOwner {
        getBridge(destination_).registerRemoteContract(destination_, contract_);
        remoteBridges[destination_] = contract_;
        emit RemoteContractRegistered(address(bridges[destination_]), destination_, contract_);
    }

    /// @dev See IBridgeReceiver
    function receiveMessage(uint256 source_, bytes memory payload_) external {
        require(address(getBridge(source_)) == _msgSender(), 'AbstractCarbonStation: invalid source');

        bool success;
        bytes memory returnData;
        /// Forward everything to our handler endpoint
        (success, returnData) = address(receiver).call(payload_);
        require(success, string(returnData));
    }

    /// @dev Send a message to a remote chain - only allowed for trusted endpoints
    function send(uint256 destination_, bytes memory payload_) external payable onlyEndpoints {
        _send(destination_, payload_);
    }

    /// @param destination_ - The remote chain
    /// @param payload_ - The raw payload of the message call
    function _send(uint256 destination_, bytes memory payload_) internal {
        getBridge(destination_).sendMessage{value: msg.value}(destination_, payload_);
    }

    /// @dev Runs on message receive
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '../../abstracts/AbstractFactory.sol';
import '../RemoteCarbonStation.sol';
import './RemoteCarbonBundleToken.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon-Bundle Token Factory Contract
contract RemoteCarbonBundleTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param blueprint_ - The contract that is used a implementation base for new tokens
    /// @param owner_ - The owner of this contract, this will be a terminal station
    constructor (RemoteCarbonBundleToken blueprint_, address owner_) {
        setBlueprint(address(blueprint_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit bundle token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param vintage_ - The minimum vintage of this bundle
    /// @param feeDivisor_ - The fee divisor that should be taken upon unbundling
    /// @param station_ - The terminal station to manage this token
    /// @return The address of the newly created token
    function createBundle(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        uint256 feeDivisor_,
        RemoteCarbonStation station_
    ) onlyOwner external returns (RemoteCarbonBundleToken) {
        RemoteCarbonBundleToken bundle = RemoteCarbonBundleToken(blueprint.clone());
        bundle.initialize(name_, symbol_, vintage_, feeDivisor_, station_);
        finalizeCreation(address(bundle));
        return bundle;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import {CarbonToken} from '../../CarbonToken.sol';
import '../../abstracts/AbstractFactory.sol';
import '../RemoteCarbonStation.sol';
import './RemoteCarbonToken.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Token Factory Contract
contract RemoteCarbonTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param blueprint_ - The contract that is used a implementation base for new tokens
    /// @param owner_ - The owner of this contract, this will be a terminal station
    constructor (RemoteCarbonToken blueprint_, address owner_) {
        setBlueprint(address(blueprint_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param details_ - Token details to define the fungibillity characteristics of this token
    /// @param accessList_ - The permission list of this token
    /// @param station_ - The terminal station to manage this token
    /// @return The address of the newly created token
    function createToken(
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        ICarbonAccessList accessList_,
        RemoteCarbonStation station_
    ) onlyOwner external returns (RemoteCarbonToken) {
        RemoteCarbonToken token = RemoteCarbonToken(blueprint.clone());
        token.initialize(name_, symbol_, details_, accessList_, station_);
        finalizeCreation(address(token));
        return token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/ICarbonSender.sol';
import '../central/CentralCarbonReceiver.sol';
import '../RemoteCarbonStation.sol';
import './RemoteCarbonBundleToken.sol';
import './RemoteCarbonToken.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Sender Contract
contract RemoteCarbonSender is ICarbonSender {

    RemoteCarbonStation station;

    /// @notice Emitted when someone bundles tokens into the bundle token
    /// @param account - The token sender
    /// @param amount - The amount of tokens to bundle
    /// @param token - The address of the vanilla underlying
    event Bundle(address account, uint256 amount, address token);

    /// @notice Emitted when someone unbundles tokens from the bundle
    /// @param account - The token recipient
    /// @param amount - The amount of unbundled tokens
    /// @param token - The address of the vanilla underlying
    event Unbundle(address account, uint256 amount, address token);

    /// @notice Emitted when a bundle swap is excuted
    /// @param sourceBundle - The source bundle
    /// @param targetBundle - The target bundle
    /// @param token - The token to swap from source to target
    /// @param amount - The amount of tokens to swap
    event SwapBundle(address sourceBundle, address targetBundle, address token, uint256 amount);

    /// @notice Emitted on offset specific on behalf of and offset specific (which is just a special case of the on behalf of)
    /// @param bundle - The bundle from which to offset
    /// @param token - The token to offset
    /// @param account - Address of the account that is granted the offset
    /// @param amount - The amount of tokens offsetted
    event OffsetSpecificOnBehalfOf(address bundle, address token, address account, uint256 amount);

    constructor(RemoteCarbonStation station_) {
        station = station_;
    }

    /// @dev See ICarbonSender - tokens are burned here
    function sendToken(
        uint256 destination_,
        address token_,
        address recipient_,
        uint256 amount_
    ) public payable {
        require(amount_ != 0, 'RemoteCarbonSender: amount must be greater than 0');

        RemoteCarbonToken rToken = station.getToken(token_);
        if (address(rToken.accessList()) != address(0)) {
            require(rToken.accessList().hasAccess(msg.sender),
                'RemoteCarbonSender: the sender is not allowed to send this token');
            require(rToken.accessList().hasAccess(recipient_),
                'RemoteCarbonSender: the recipient is not allowed to receive this token');
        }

        station.burn(rToken, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                ICarbonReceiver.handleReceiveToken.selector,
                station.localToCentralTokens(token_),
                recipient_,
                amount_
            )
        );
        emit TokenSent(destination_, address(rToken), msg.sender, recipient_, amount_);
    }

    /// @dev See ICarbonSender - bundles are burned here
    function sendBundle(
        uint256 destination_,
        address rBundle_,
        address recipient_,
        uint256 amount_
    ) external payable {
        require(amount_ != 0, 'RemoteCarbonSender: amount must be greater than 0');

        RemoteCarbonBundleToken rBundle = station.getBundle(rBundle_);
        station.burn(rBundle, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              ICarbonReceiver.handleReceiveBundle.selector,
              station.localToCentralBundles(rBundle_),
              recipient_,
              amount_
            )
        );
        emit BundleSent(destination_, address(rBundle), msg.sender, recipient_, amount_);
    }

    /// @notice Swaps source bundle for the target via the given token for the given amount
    /// @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param rSourceBundle_ - The source bundle
    /// @param rTargetBundle_ - The target bundle
    /// @param rToken_ - The token to swap from source to target
    /// @param amount_ - The amount of tokens to swap
    function swapBundle(
        RemoteCarbonBundleToken rSourceBundle_,
        RemoteCarbonBundleToken rTargetBundle_,
        RemoteCarbonToken rToken_,
        uint256 amount_
    ) external payable {
        require(rSourceBundle_.hasToken(rToken_),
            'RemoteCarbonSender: token must be compatible with source');
        require(rTargetBundle_.hasToken(rToken_),
            'RemoteCarbonSender: token must be compatible with target');
        require(!rTargetBundle_.pausedForBundle(rToken_),
            'RemoteCarbonSender: token is paused for bundling');

        station.burn(rSourceBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleSwapBundle.selector,
                station.localChainId(),
                station.localToCentralBundles(address(rSourceBundle_)),
                station.localToCentralBundles(address(rTargetBundle_)),
                station.localToCentralTokens(address(rToken_)),
                msg.sender,
                amount_
            )
        );
        emit SwapBundle(address(rSourceBundle_), address(rTargetBundle_), address(rToken_), amount_);
    }

    /// @notice Offsets a specific token from a bundle on behalf of a user
    /// @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param rBundle_ - The bundle from which to offset
    /// @param rToken_ - The token to offset
    /// @param account_ - Address of the account that is granted the offset
    /// @param amount_ - The amount of tokens to offset
    function offsetSpecificOnBehalfOf(
        RemoteCarbonBundleToken rBundle_,
        RemoteCarbonToken rToken_,
        address account_,
        uint256 amount_
    ) public payable {
        require(rBundle_.hasToken(rToken_),
            'RemoteCarbonSender: token must be compatible with bundle');

        station.burn(rBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleOffsetSpecificOnBehalfOf.selector,
                station.localChainId(),
                station.localToCentralBundles(address(rBundle_)),
                station.localToCentralTokens(address(rToken_)),
                msg.sender,
                account_,
                amount_
            )
        );
        emit OffsetSpecificOnBehalfOf(address(rBundle_), address(rToken_), account_, amount_);
    }

    /// @notice Offset in the name of the sender
    /// @dev See offsetSpecificOnBehalfOf, this is just a special case convenience function
    function offsetSpecific(
        RemoteCarbonBundleToken rBundle_,
        RemoteCarbonToken rToken_,
        uint256 amount_
    ) external payable {
        offsetSpecificOnBehalfOf(rBundle_, rToken_, msg.sender, amount_);
    }

    /// @notice Inject GCO2 tokens into a bundle
    /// @dev Tokens are sent back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param rBundle_ - The bundle token to receive
    /// @param rToken_ - The GCO2 token to bundle
    /// @param amount_ - The amount of tokens
    function bundle(
        RemoteCarbonBundleToken rBundle_,
        RemoteCarbonToken rToken_,
        uint256 amount_
    ) external payable {
        require(rBundle_.hasToken(rToken_),
            'RemoteCarbonSender: token must be compatible with bundle');
        require(!rBundle_.pausedForBundle(rToken_),
            'RemoteCarbonSender: token is paused for bundling');

        station.burn(rToken_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleBundle.selector,
                station.localChainId(),
                station.localToCentralBundles(address(rBundle_)),
                station.localToCentralTokens(address(rToken_)),
                msg.sender,
                amount_
            )
        );

        emit Bundle(msg.sender, amount_, address(rToken_));
    }

    /// @notice Takes GCO2s tokens out of a bundle
    /// @dev Bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param rBundle_ - The bundle token to input
    /// @param rToken_ - The GCO2 token to receive, must be part of the bundle
    /// @param amount_ - The amount of tokens
    function unbundle(
        RemoteCarbonBundleToken rBundle_,
        RemoteCarbonToken rToken_,
        uint256 amount_
    ) external payable {
        require(rBundle_.hasToken(rToken_),
            'RemoteCarbonSender: token must be compatible with bundle');

        station.burn(rBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.centralChainId(),
            abi.encodeWithSelector(
                CentralCarbonReceiver.handleUnbundle.selector,
                station.localChainId(),
                station.localToCentralBundles(address(rBundle_)),
                station.localToCentralTokens(address(rToken_)),
                msg.sender,
                amount_
            )
        );
        emit Unbundle(msg.sender, amount_, address(rToken_));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../../CarbonToken.sol';
import '../../interfaces/ICarbonAccessList.sol';
import '../interfaces/ICarbonReceiver.sol';
import '../RemoteCarbonStation.sol';
import './RemoteCarbonToken.sol';
import './RemoteCarbonBundleToken.sol';

/// @author FlowCarbon LLC
/// @title Remote Carbon Receiver Contract
contract RemoteCarbonReceiver is Ownable, ICarbonReceiver {

    /// The local station that connects us to the cross-chain network
    RemoteCarbonStation station;

    constructor(RemoteCarbonStation station_) {
        station = station_;
        transferOwnership(address(station_));
    }

    /// @dev Message handle for `syncToken`
    /// @param token_ - The address on the main chain
    /// @param name_ - The name of the token
    /// @param symbol_ - The symbol of the token
    /// @param details_ - The details of the token
    /// @param accessList_ - The access list of the token on the main chain
    function handleSyncToken(
        address token_,
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        address accessList_
    ) external onlyOwner {
        RemoteCarbonToken rToken;
        ICarbonAccessList rAccessList = accessList_ == address(0)
            ? ICarbonAccessList(address(0))
            : ICarbonAccessList(station.centralToLocalAccessLists(accessList_));

        if (station.centralToLocalTokens(token_) == address(0)) {
            rToken = station.createToken(token_, name_, symbol_, details_, rAccessList);
        } else {
            rToken = RemoteCarbonToken(station.centralToLocalTokens(token_));
            station.setAccessList(rToken, rAccessList);
        }
    }

    /// @dev Message handler for `syncBundle`
    /// @param token_ - The bundle on the main chain
    /// @param name_ - Tame of the bundle
    /// @param symbol_ - The symbol of the bundle
    /// @param vintage_ - Minimum vintage requirements of this bundle
    /// @param feeDivisor_ - The fee divisor of this bundle
     function handleSyncBundle(
         address token_,
         string memory name_,
         string memory symbol_,
         uint16 vintage_,
         uint256 feeDivisor_
    ) external onlyOwner {
        RemoteCarbonBundleToken rBundleToken;
        if (station.centralToLocalBundles(token_) == address(0)) {
            rBundleToken = station.createBundle(token_, name_, symbol_, vintage_, feeDivisor_);
        } else {
            rBundleToken = RemoteCarbonBundleToken(station.centralToLocalBundles(token_));
            station.incrementVintage(rBundleToken, vintage_);
        }
    }

    /// @dev Message handler for `syncAccessList`
    /// @param token_ - The address on the main chain
    /// @param name_ - The name of the access list
    function handleSyncAccessList(address token_, string memory name_) external onlyOwner {
        // NOTE: It is guaranteed by the central sender to be only synced once
        station.createAccessList(token_, name_);
    }

    /// @dev Update a access list - it is guaranteed by the main chain to exist
    /// @param accessList_ - The address of this access list on the main chain
    /// @param account_ - The address of the account to add or remove
    /// @param hasAccess_ - Flag if access is granted or removed
    function handleRegisterAccess(
        address accessList_,
        address account_,
        bool hasAccess_
    ) external onlyOwner {
        station.setGlobalAccess(
            ICarbonAccessList(station.centralToLocalAccessLists(accessList_)),
            account_,
            hasAccess_
        );
    }

    /// @dev Update a token - it is guaranteed by the main chain to exist
    /// @param bundle_ - The address of bundle that should add / remove the token
    /// @param token_ - The address of the token
    /// @param isAdded_ - Flag if added or removed
    /// @param isPaused_ - Flag if token is paused
    function handleRegisterTokenForBundle(
        address bundle_,
        address token_,
        bool isAdded_,
        bool isPaused_
    ) external onlyOwner {
        station.registerTokenForBundle(
            RemoteCarbonBundleToken(station.centralToLocalBundles(bundle_)),
            RemoteCarbonToken(station.centralToLocalTokens(token_)),
            isAdded_,
            isPaused_
        );
    }

    /// @dev See IHandlerInterface
    function handleReceiveToken(
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        station.mint(
            RemoteCarbonToken(station.centralToLocalTokens(token_)),
            recipient_,
            amount_
        );
    }

    /// @dev See IHandlerInterface
    function handleReceiveBundle(
        address bundle_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        station.mint(
            RemoteCarbonBundleToken(station.centralToLocalBundles(bundle_)),
            recipient_,
            amount_
        );
    }

    /// @dev Handles offsetting a specific token by increasing the offset for that token
    /// @param token_ - The address of the token on the central chain
    /// @param beneficiary_ - The receiver of the token
    /// @param amount_ - The amount of the token
    function handleOffsetSpecificOnBehalfOfCallback(
        address token_,
        address beneficiary_,
        uint256 amount_
    ) external onlyOwner {
        station.increaseOffset(
            RemoteCarbonToken(station.centralToLocalTokens(token_)),
            beneficiary_,
            amount_
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '../CarbonBundleConductor.sol';
import '../CarbonTokenFactory.sol';
import '../CarbonAccessListFactory.sol';
import '../CarbonToken.sol';
import './abstracts/AbstractCarbonStation.sol';
import './central/CentralPostageFeeMaster.sol';
import './central/CentralCarbonSender.sol';
import './central/CentralCarbonReceiver.sol';
import './RemoteCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Central Carbon Station Contract
contract CentralCarbonStation is AbstractCarbonStation {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Emitted when we send a callback type message to a remote blockchain
    /// @dev Gives us a hint on when to refill the main station
    /// @param destination - The receiver of the callback
    event CallbackInvoked(uint256 destination);

    /// The bundle conductor to handle rakeback of fees
    CarbonBundleConductor public bundleConductor;

    /// The token factory for GCO2 from where we deploy
    CarbonTokenFactory public tokenFactory;

    /// The access list factory from where we deploy
    CarbonAccessListFactory public accessListFactory;

    /// Mapping to keep track of which access lists have already been synced to remote chains
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedAccessLists;

    /// Mapping to keep track of which tokens have already been synced to remote chains
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedTokens;

    /// Mapping to keep track of which bundle token have already been synced to remote chains
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _syncedBundles;

    /// The postage fee master imposes a small fee on some transactions to prevent griefing
    CentralPostageFeeMaster public postageFeeMaster;

     constructor(
         address bundleConductor_,
         address tokenFactory_,
         address accessListFactory_,
         address owner_
    )  AbstractCarbonStation(address(new CentralCarbonSender(this)), address(new CentralCarbonReceiver(this)), owner_) {
         require(bundleConductor_ != address(0),
             'CentralCarbonStation: bundle conductor is required');
         require(tokenFactory_ != address(0),
             'CentralCarbonStation: token factory is required');
         require(accessListFactory_ != address(0),
             'CentralCarbonStation: access list factory is required');

         tokenFactory = CarbonTokenFactory(tokenFactory_);
         accessListFactory = CarbonAccessListFactory(accessListFactory_);
         bundleConductor = CarbonBundleConductor(bundleConductor_);

         postageFeeMaster = new CentralPostageFeeMaster(owner_);
    }

    /// @notice Get the bundle token at the given address, making sure it is part of our deployment
    /// @param bundle_ - The address of the bundle
    /// @return The bundle token
    function getBundle(address bundle_) public view returns (CarbonBundleToken) {
        require(bundleConductor.bundleFactory().hasInstanceAt(bundle_),
            'CentralCarbonStation: unknown bundle');
        return CarbonBundleToken(bundle_);
    }

    /// @notice Get the access list at the given address, making sure it is part of our deployment
    /// @param accessList_ - The address of the access list
    /// @return The access list
    function getAccessList(address accessList_) external view returns (CarbonAccessList) {
        require(accessListFactory.hasInstanceAt(accessList_),
            'CentralCarbonStation: unknown access list');
        return CarbonAccessList(accessList_);
    }

    /// @notice Get the GCO2 token the given address, making sure it is part of our deployment
    /// @param token_ - The address of the token
    /// @return The GCO2 token
    function getToken(address token_) public view returns (CarbonToken) {
        require(tokenFactory.hasInstanceAt(token_),
            'CentralCarbonStation: unknown token');
        return CarbonToken(token_);
    }

    /// @dev Enforces access list to be synced if it is not the zero address
    /// @param destination_ - The destination chain ID
    /// @param accessList_ - The access list to check
    function requireAccessListSynced(uint256 destination_, address accessList_) external view {
        if (accessList_ != address(0)) {
            require(_syncedAccessLists[destination_].contains(accessList_),
                'CentralCarbonStation: access list not synced');
        }
    }

    /// @dev Enforces access list to be NOT synced
    /// @param destination_ - The destination chain
    /// @param accessList_ - The access list to check for
    function requireAccessListNotSynced(uint256 destination_, address accessList_) external view {
        require(!_syncedAccessLists[destination_].contains(accessList_),
            'CentralCarbonStation: access list already synced');
    }


    /// @dev Enforces a token to be synced
    /// @param destination_ - The destination chain
    /// @param token_ - Address of the token
    function requireTokenSynced(uint256 destination_, address token_) external view {
        require(_syncedTokens[destination_].contains(token_),
            'CentralCarbonStation: token not synced');
    }

    /// @dev Enforces bundle to be synced
    /// @param destination_ - The destination chain
    /// @param bundle_ - Address of the bundle
    function requireBundleSynced(uint256 destination_, address bundle_) external view {
        require(_syncedBundles[destination_].contains(bundle_),
            'CentralCarbonStation: bundle not synced');
    }

    /// @dev Transfers out the postage fee to the station owner, this is to cover ping-pong actions below a threshold
    /// @param destination_ - The destination fee for which the is a fee to pay
    /// @param bundle_ - The bundle involved for price determination
    /// @param feeBasisToken_ - The token in which the fee is paid, can be the bundle or an underlying GCO2
    /// @param amount_ - The amount in terms of bundle that is subject to the fee
    /// @param isSuccessPath_ - On success the fee may be lower or even 0 (cause there is already an unbundle fee)
    /// @return The amount after fees
    function deductPostageFee(
        uint256 destination_,
        CarbonBundleToken bundle_,
        IERC20Upgradeable feeBasisToken_,
        uint256 amount_,
        bool isSuccessPath_
    ) external onlyEndpoints returns (uint256) {
        uint256 fee = postageFeeMaster.get(destination_, bundle_, amount_, isSuccessPath_);
        if (amount_ <= fee) {
            feeBasisToken_.safeTransfer(owner(), amount_);
            return 0;
        }
        if (fee > 0) {
            feeBasisToken_.safeTransfer(owner(), fee);
        }
        return amount_ - fee;
    }

    /// @dev Register a released GCO2 token - only available to endpoints
    function registerSyncedToken(
        uint256 destination_,
        address token_
    ) external onlyEndpoints returns (bool) {
        return _syncedTokens[destination_].add(token_);
    }

    /// @dev Register a released bundle token - only available to endpoints
    function registerSyncedBundle(
        uint256 destination_,
        address bundle_
    ) external onlyEndpoints returns (bool) {
        getBundle(bundle_).approve(address(bundleConductor), type(uint256).max);
        return _syncedBundles[destination_].add(bundle_);
    }

    /// @dev Register a released access list - only available to endpoints
    function registerSyncedAccessList(
        uint256 destination_,
        address accessList_
    ) external onlyEndpoints returns (bool) {
        return _syncedAccessLists[destination_].add(accessList_);
    }

    /// @dev Transfer wrapper, as this contract is the state-holding treasury of tokens - only available to endpoints
    function transfer(
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyEndpoints {
        IERC20Upgradeable(token_).safeTransfer(recipient_, amount_);
    }

    /// @dev Offset wrapper, as this contract is the state-holding treasury of tokens
    function offset(address token_, uint256 amount_) external onlyEndpoints {
        ICarbonToken(token_).offset(amount_);
    }

    /// @dev Bundle wrapper, as this contract is the state-holding treasury of tokens
    function bundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyEndpoints {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
    }

    /// @dev Unbundle wrapper, as this contract is the state-holding treasury of tokens
    function unbundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyEndpoints returns (uint256){
        return bundle_.unbundle(token_, amount_);
    }

    /// @dev Swap bundle wrapper, as this contract is the state-holding treasury of tokens
    function swapBundle(
        CarbonBundleToken sourceBundle_,
        CarbonBundleToken targetBundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyEndpoints returns (uint256) {
        return bundleConductor.swapBundle(sourceBundle_, targetBundle_, token_, amount_);
    }

    /// @dev Offset specific wrapper, as this contract is the state-holding treasury of tokens
    function offsetSpecific(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external onlyEndpoints returns (uint256) {
        return bundleConductor.offsetSpecific(bundle_, token_, amount_);
    }

    /// @dev Callback to the original chain, fee is paid by the contract and deducted in terms of GCO2/Bundle tokens
    /// @param destination_ - The source chain of the callback
    /// @param payload_ - The raw payload to send back
    function sendCallback(uint256 destination_, bytes memory payload_) external onlyEndpoints {
        getBridge(destination_).sendMessage{
            value: postageFeeMaster.getNative(destination_)
        }(destination_, payload_);

        emit CallbackInvoked(destination_);
    }
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import './abstracts/AbstractFactory.sol';
import './CarbonToken.sol';
import './CarbonAccessList.sol';
import './CarbonBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Token Factory Contract
contract CarbonTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    CarbonBundleTokenFactory public bundleFactory;

    /// @param blueprint_ - The contract that is used a implementation base for new tokens
    /// @param owner_ - The owner of this contract
    constructor (CarbonToken blueprint_, address owner_) {
        setBlueprint(address(blueprint_));
        transferOwnership(owner_);
    }

    /// @notice Set the carbon credit bundle token factory which is passed to token instances
    /// @param bundleFactory_ - The factory instance associated with new tokens
    function setBundleFactory(CarbonBundleTokenFactory bundleFactory_) external onlyOwner {
        bundleFactory = bundleFactory_;
    }

    /// @notice Deploy a new carbon credit token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param details_ - Token details to define the fungibillity characteristics of this token
    /// @param accessList_ - The access list of this token
    /// @param owner_ - The owner of the new token, able to mint and finalize offsets
    /// @return The address of the newly created token
    function createToken(
        string memory name_,
        string memory symbol_,
        CarbonToken.TokenDetails memory details_,
        ICarbonAccessList accessList_,
        address owner_
    ) onlyOwner external returns (address) {
        require(address(bundleFactory) != address(0), 'CarbonTokenFactory: bundle factory is not set');
        CarbonToken token = CarbonToken(blueprint.clone());
        token.initialize(name_, symbol_, details_, accessList_, owner_, bundleFactory);
        finalizeCreation(address(token));
        return address(token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '../CarbonToken.sol';
import '../CarbonBundleToken.sol';
import '../CarbonBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Integrity Library
library CarbonIntegrity {

    /// @dev Reverts if a bundle does not contain a token
    function requireHasToken(CarbonBundleToken bundle_, CarbonToken token_) public view {
        require(bundle_.hasToken(token_),'CarbonIntegrity: token is not part of bundle');
    }

    /// @dev Reverts if the vintage is outdated
    function requireVintageNotOutdated(CarbonBundleToken bundle_, CarbonToken token_) public view {
        require(token_.vintage() >= bundle_.vintage(), 'CarbonIntegrity: token outdated');
    }

    /// @dev Reverts if the token is not compatible with the bundle
    function requireIsEligibleForBundle(CarbonBundleToken bundle_, CarbonToken token_) external view {
        require(!bundle_.hasToken(token_),
            'CarbonIntegrity: token already added to bundle');
        require(bundle_.tokenFactory().hasInstanceAt(address(token_)),
            'CarbonIntegrity: unknown token');
        require(token_.vintage() >= bundle_.vintage(),
            'CarbonIntegrity: vintage mismatch');

        if (bundle_.tokenCount() > 0) {
            CarbonBundleTokenFactory existingTokenFactory = CarbonToken(bundle_.tokenAtIndex(0)).bundleFactory();
            require(address(token_.bundleFactory()) ==  address(existingTokenFactory),
                'CarbonIntegrity: all tokens must have the same bundle factory');
        }
    }

    /// @dev Reverts if the token can not be bundled with the given amount to the given bundle
    function requireCanBundleToken(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        requireVintageNotOutdated(bundle_, token_);
        require(amount_ != 0,
            'CarbonIntegrity: amount may not be zero');
        require(!bundle_.pausedForBundle(token_),
            'CarbonIntegrity: token is paused for bundling');
    }

    /// @dev Reverts if the token can not be unbundled with the given amount to the given bundle
    function requireCanUnbundleToken(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        require(token_.balanceOf(address(bundle_)) - bundle_.amountReserved(token_) >= amount_,
            'CarbonIntegrity: amount exceeds the token balance');
        require(amount_ != 0,
            'CarbonIntegrity: amount may not be zero');
        require(amount_ >= bundle_.feeDivisor(),
            'CarbonIntegrity: fee divisor exceeds amount');
    }

    /// @dev Reverts if the given checksum / amount combination cannot be finalized for the given bundle and token
    function requireCanFinalizeOffset(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_, bytes32 checksum_) external view {
        requireHasToken(bundle_, token_);
        require(checksum_ != 0,
            'CarbonIntegrity: checksum is required');
        require(bundle_.amountOffsettedWithChecksum(checksum_) == 0,
            'CarbonIntegrity: checksum already used');
        require(amount_ <= bundle_.pendingOffsetBalance(),
            'CarbonIntegrity: offset exceeds pending balance');
        require(token_.balanceOf(address(bundle_)) >= amount_,
            'CarbonIntegrity: amount exceeds the token balance');
        require(bundle_.amountReserved(token_) >= amount_,
            'CarbonIntegrity: reserve too low');
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title Carbon Access List Interface
interface ICarbonAccessList {

    /// @notice Emitted when the access list changes
    /// @param account - The account for which permissions have changed
    /// @param hasAccess - Flag indicating whether access was granted or revoked
    /// @param isGlobal - Flag indicating whether the permission is local or multi-chain enabled
    event AccessChanged(address account, bool hasAccess, bool isGlobal);

    // @notice Return the name of the list
    function name() external view returns (string memory);

    // @notice Grant or revoke the permission of an account that is synced across chains
    // @param account_ - The address to which to grant or revoke permissions
    // @param hasAccess_ - Flag indicating whether to grant or revoke permissions
    function setGlobalAccess(address account_, bool hasAccess_) external;

    // @notice Grant or revoke permissions of multiple multi chain accounts
    // @param account_ - The addresses to which to grant or revoke permissions
    // @param permission_ - Flags indicating whether to grant or revoke permissions
    function setGlobalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) external;

    /// @notice Checks if an account is permissioned as multi chain address
    /// @param account_ - The address to check
    /// @return True if the address is permissioned
    function hasGlobalAccess(address account_) external view returns (bool);

    // @notice Return the address at the given list index if it is on the multi chain address list
    // @param index_ - The index into the list
    // @return Address at the given index
    function globalAddressAt(uint256 index_) external view returns (address);

    // @notice Get the number of multi chain accounts that have been granted permission
    // @return Number of accounts that have been granted permission
    function globalAddressCount() external view returns (uint256);

    // @notice Get an array containing all multi chain addresses that have been granted permission
    // @return Array containing all multi chain addresses that have been granted permission
    function globalAddresses() external view returns (address[] memory);

    // @notice Grant or revoke the permission of an account on this chain only
    // @param account_ - The address to which to grant or revoke permissions
    // @param hasAccess_ - Flag indicating whether to grant or revoke permissions
    function setLocalAccess(address account_, bool hasAccess_) external;

    // @notice Grant or revoke permissions of an account on this chain only
    // @param account_ - The address to which to grant or revoke permissions
    // @param permission_ - Flags indicating whether to grant or revoke permissions
    function setLocalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) external;

    /// @notice Checks is an address is permissioned on this chain only
    /// @param account_ - The address to check
    /// @return True if the address is permissioned
    function hasLocalAccess(address account_) external view returns (bool);

    /// @notice Discovery function for the local chain counts
    /// @return The number of addresses on this list
    function localAddressCount() external view returns (uint256);

    /// @notice Discovery function for the local chain address
    /// @param index_ - The index of the address
    /// @return The local address
    function localAddressAt(uint256 index_) external view returns (address);

    // @notice Get an array containing all addresses that have been granted permission on this chain
    // @return Array containing all addresses that have been granted permission this chain
    function localAddresses() external view returns (address[] memory);

    // @notice Return the current permissions of an account on this chain (can be local or multi chain)
    // @param account_ - The address to check
    // @return Flag indicating whether this account has permission or not
    function hasAccess(address account_) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import './abstracts/AbstractFactory.sol';
import './abstracts/AbstractCarbonToken.sol';
import './CarbonBundleToken.sol';
import './CarbonToken.sol';
import './CarbonTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Bundle-Token Factory Contract
contract CarbonBundleTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @notice The token factory for carbon credit tokens
    CarbonTokenFactory public tokenFactory;

    /// @param blueprint_ - The contract to be used as implementation base for new tokens
    /// @param owner_ - The owner of the contract
    /// @param tokenFactory_ - The factory used to deploy carbon credits tokens
    constructor (CarbonBundleToken blueprint_, address owner_, CarbonTokenFactory tokenFactory_) {
        require(address(tokenFactory_) != address(0),
            'CarbonBundleTokenFactory: token factory is required');

        setBlueprint(address(blueprint_));
        tokenFactory = tokenFactory_;
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit bundle token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param vintage_ - The minimum vintage of this bundle
    /// @param tokens_ - Initial set of tokens
    /// @param owner_ - The owner of the bundle token, eligible for fees and able to finalize offsets
    /// @param feeDivisor_ - The fee divisor that should be taken upon unbundling
    /// @return The address of the newly created token
    function createBundle(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_
    ) onlyOwner external returns (address) {
        CarbonBundleToken bundle = CarbonBundleToken(blueprint.clone());
        bundle.initialize(name_, symbol_, vintage_, tokens_, owner_, feeDivisor_, tokenFactory);
        finalizeCreation(address(bundle));
        return address(bundle);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/ICarbonAccessList.sol';
import './CarbonAccessList.sol';

/// @author FlowCarbon LLC
/// @title Carbon Access-List Contract
contract CarbonAccessList is ICarbonAccessList, OwnableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _globalAddresses;

    EnumerableSetUpgradeable.AddressSet private _localAddresses;

    /// @dev The ecosystem-internal name given to the access list
    string private _name;

    /// @param name_ - The name of the access list
    /// @param owner_ - The owner of the access list, allowed manage it's entries
    function initialize(string memory name_, address owner_) external initializer {
        __Ownable_init();
        _name = name_;
        transferOwnership(owner_);
    }

    // @dev See ICarbonAccessList
    function name() external view returns (string memory) {
        return _name;
    }

    // @dev See ICarbonAccessList
    function setGlobalAccess(address account_, bool hasAccess_) onlyOwner public {
        require(account_ != address(0),
            'CarbonAccessList: account is required');

        bool changed;
        if (hasAccess_) {
            changed = _globalAddresses.add(account_);
        } else {
            changed = _globalAddresses.remove(account_);
        }
        if (changed) {
            emit AccessChanged(account_, hasAccess_, true);
        }
    }

    // @dev See ICarbonAccessList
    function setGlobalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) onlyOwner external {
        require(accounts_.length == permissions_.length, 'accounts and permissions must have the same length');
        for (uint256 i=0; i < accounts_.length; i++) {
            setGlobalAccess(accounts_[i], permissions_[i]);
        }
    }

    // @dev See ICarbonAccessList
    function hasGlobalAccess(address account_) external view returns (bool) {
        return _globalAddresses.contains(account_);
    }

    // @dev See ICarbonAccessList
    function globalAddressAt(uint256 index_) external view returns (address) {
        return _globalAddresses.at(index_);
    }

    // @dev See ICarbonAccessList
    function globalAddressCount() external view returns (uint256) {
        return _globalAddresses.length();
    }

    // @dev see ICarbonAccessList
    function globalAddresses() external view returns (address[] memory) {
        return _globalAddresses.values();
    }

    // @dev See ICarbonAccessList
    function setLocalAccess(address account_, bool hasAccess_) onlyOwner public {
        require(account_ != address(0),
            'CarbonAccessList: account is required');

        bool changed;
        if (hasAccess_) {
            changed = _localAddresses.add(account_);
        } else {
            changed = _localAddresses.remove(account_);
        }
        if (changed) {
            emit AccessChanged(account_, hasAccess_, false);
        }
    }

    // @dev See ICarbonAccessList
    function setLocalAccessInBatch(address[] memory accounts_, bool[] memory permissions_) onlyOwner external {
        require(accounts_.length == permissions_.length,
            'CarbonAccessList: accounts and permissions must have the same length');

        for (uint256 i=0; i < accounts_.length; i++) {
            setLocalAccess(accounts_[i], permissions_[i]);
        }
    }

    /// @dev see ICarbonAccessList
    function hasLocalAccess(address account_) external view returns (bool) {
        return _localAddresses.contains(account_);
    }

    /// @dev See ICarbonAccessList
    function localAddressCount() external view returns (uint256) {
        return _localAddresses.length();
    }

    /// @dev See ICarbonAccessList
    function localAddressAt(uint256 index_) external view returns (address) {
        return _localAddresses.at(index_);
    }

    // @dev see ICarbonAccessList
    function localAddresses() external view returns (address[] memory) {
        return _localAddresses.values();
    }

    // @dev See ICarbonAccessList
    function hasAccess(address account_) external view returns (bool) {
        return _globalAddresses.contains(account_) || _localAddresses.contains(account_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('CarbonAccessList: renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title Bridge Receiver Interface
interface IBridgeReceiver {

    /// @notice Interface hook for inbound messages
    /// @param source_ - The chain id from which this message was sent
    /// @param payload_ - The raw payload
    function receiveMessage(uint256 source_, bytes memory payload_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title Bridge Interface
interface IBridge {

    /// @dev The identifier should be in the format BRIDGE_NAME_v1.0.0
    /// @return Keccak256 encoded identifier
    function getIdentifier() external pure returns (bytes32);

    /// @notice Connect a contract on the terminal chain to this chain
    /// @dev The target contract needs to be an IBridgeReceiver
    /// @param destination_ - The chain id with the respective bridge endpoint contract
    /// @param contract_ - The address on the terminal chain
    function registerRemoteContract(uint256 destination_, address contract_) external;

    /// @notice Send a message to the remote chain
    /// @param destination_ - The chain id to which we want to send the message
    /// @param payload_ - The raw payload to send
    function sendMessage(uint256 destination_, bytes memory payload_) payable external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title Carbon Sender Interface
interface ICarbonSender {

    /// @notice Emitted on tokens send
    /// @param destination - The target chain
    /// @param token - The address of the token on source chain
    /// @param sender - The sending address on origin chain
    /// @param recipient - The receiving address on target chain
    /// @param amount - The amount sent
    event TokenSent(uint256 destination, address token, address sender, address recipient, uint256 amount);

    /// @notice Emitted on tokens send
    /// @param destination - The target chain
    /// @param bundle - The address of the bundle on source chain
    /// @param sender - The sending address on origin chain
    /// @param recipient - The receiving address on target chain
    /// @param amount - The amount sent
    event BundleSent(uint256 destination, address bundle, address sender, address recipient, uint256 amount);

   /// @notice Send GCO2 tokens to someone on a remote chain!
   /// @param destination_ - The destination chain ID
   /// @param token_ - The address of the token to send
   /// @param recipient_ - The address of the recipient on the remote chain
   /// @param amount_ - The amount of tokens to be sent
   function sendToken(uint256 destination_, address token_, address recipient_, uint256 amount_) external payable;

    /// @notice Send bundle tokens to someone on a remote chain!
    /// @param destination_ - The destination chain ID
    /// @param bundle_ - The address of the token to send
    /// @param recipient_ - The address of the recipient on the remote chain
    /// @param amount_ - The amount of tokens to be sent
    function sendBundle(uint256 destination_, address bundle_, address recipient_, uint256 amount_) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {CarbonToken, CarbonBundleToken} from '../../CarbonBundleToken.sol';
import '../remote/RemoteCarbonReceiver.sol';
import '../interfaces/ICarbonReceiver.sol';
import '../CentralCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Central Carbon Receiver Contract
contract CentralCarbonReceiver is Ownable, ICarbonReceiver {

    /// The central station that connects us to the cross-chain network
    CentralCarbonStation station;

    constructor(CentralCarbonStation station_) {
        station = station_;
        transferOwnership(address(station_));
    }

    /// @dev See IHandlerInterface
    function handleReceiveToken(
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        station.transfer(token_, recipient_, amount_);
    }

    /// @dev See IHandlerInterface
    function handleReceiveBundle(
        address bundle_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        station.transfer(bundle_, recipient_, amount_);
    }

    /// @dev Finalize received offsets from the treasury
    function handleOffsetFromTreasury(address token_, uint256 amount_) external onlyOwner {
        station.offset(token_, amount_);
    }

    /// @dev Completes the bundling of tokens across chains - sends back the bundle tokens or GCO2 on failure
    function handleBundle(
        uint256 destination_,
        address bundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        CarbonBundleToken bundle = station.getBundle(bundle_);
        CarbonToken token = station.getToken(token_);

        try station.bundle(bundle, token, amount_) {
            // Pay the fees in terms of bundle.
            uint256 amountAfterFees = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    destination_,
                    abi.encodeWithSelector(
                        RemoteCarbonReceiver.handleReceiveBundle.selector,
                        bundle_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
        } catch {
            // This is an edge-case when we removed the token on the main chain but it has not
            // been synced yet and someone tries to bundle.
            // We send back the tokens and take a postage fee in terms of the GCO2 token.
            uint256 amountAfterFees = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(token), amount_, false);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    destination_,
                    abi.encodeWithSelector(
                        RemoteCarbonReceiver.handleReceiveToken.selector,
                        token_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
        }
    }

    /// @dev Completes the unbundling of tokens accross chains - sends back the GCO2 tokens on success or bundle tokens on failure
    function handleUnbundle(
        uint256 destination_,
        address bundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        CarbonBundleToken bundle = station.getBundle(bundle_);
        CarbonToken token = station.getToken(token_);

        uint256 fee = station.postageFeeMaster().get(destination_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, bundle, bundle, amount_, true);
            // The provided amount is too low - do nothing.
            return;
        }

        try station.unbundle(bundle, token, amount_ - fee) returns (uint256 amountUnbundled){
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleReceiveToken.selector,
                    token_,
                    recipient_,
                    amountUnbundled
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleReceiveBundle.selector,
                    bundle_,
                    recipient_,
                    amountAfterFeesFailure
                )
            );
        }
    }

    /// @dev Completes a bundle swap accross chains - sends back the destination tokens on success or source tokens on failure
    function handleSwapBundle(
        uint256 destination_,
        address sourceBundle_,
        address targetBundle_,
        address token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        CarbonBundleToken sourceBundle = station.getBundle(sourceBundle_);
        CarbonBundleToken targetBundle = station.getBundle(targetBundle_);
        CarbonToken token = station.getToken(token_);

        uint256 fee = station.postageFeeMaster().get(destination_, sourceBundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, true);
            // The provided amount is too low - do nothing.
            return;
        }

        try station.swapBundle(sourceBundle, targetBundle, token, amount_ - fee) returns (uint256 amountSwapped) {
            station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleReceiveBundle.selector,
                    targetBundle_,
                    recipient_,
                    amountSwapped
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleReceiveBundle.selector,
                    sourceBundle_,
                    recipient_,
                    amountAfterFeesFailure
                )
            );
        }
    }

    /// @dev Completes offsetting a specific GCO2 token on behalf of a user - send back the offsets on success or bundle tokens on failure
    function handleOffsetSpecificOnBehalfOf(
        uint256 destination_,
        address bundle_,
        address token_,
        address offsetter_,
        address beneficiary_,
        uint256 amount_
    ) external onlyOwner {
        CarbonBundleToken bundle = station.getBundle(bundle_);
        CarbonToken token = station.getToken(token_);
        uint256 fee = station.postageFeeMaster().get(destination_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            // The provided amount is too low - do nothing.
            return;
        }

        try station.offsetSpecific(bundle, token, amount_ - fee) returns (uint256 amountOffsetted) {
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleOffsetSpecificOnBehalfOfCallback.selector,
                    token_,
                    beneficiary_,
                    amountOffsetted
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    RemoteCarbonReceiver.handleReceiveBundle.selector,
                    bundle_,
                    offsetter_,
                    amountAfterFeesFailure
                )
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title Carbon Receiver Interface
interface ICarbonReceiver {

    /// @notice Handler for inbound GCO2 tokens
    /// @dev Edge case: this fails if the token is not synced, sync and retry in that case
    /// @param sourceToken_ - The address of the token on the central network
    /// @param recipient_ - The receiver of the token
    /// @param amount_ - The amount of the token
    function handleReceiveToken(address sourceToken_, address recipient_, uint256 amount_) external;

    /// @notice Handler for inbound bundle tokens
    /// @dev Edge case: this fails if the token is not synced, sync and retry in that case
    /// @param sourceBundle_ - The address of the token on the main chain
    /// @param recipient_ - The receiver of the token
    /// @param amount_ - The amount of the token
    function handleReceiveBundle(address sourceBundle_, address recipient_, uint256 amount_) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {AbstractFactory, CarbonBundleTokenFactory, CarbonBundleToken} from './CarbonBundleTokenFactory.sol';
import {CarbonTokenFactory, CarbonToken} from './CarbonTokenFactory.sol';
import {CarbonRakeback, CarbonRakebackFactory} from './CarbonRakebackFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Bundle Conductor Contract
contract CarbonBundleConductor is Ownable {

    using SafeERC20Upgradeable for CarbonBundleToken;

    using SafeERC20Upgradeable for CarbonToken;

    /// @notice Emitted when a bundle token is connected to a new rakeback contract
    /// @param bundle - The respective bundle
    /// @param rakeback - The respective rakeback
    event RakebackChanged(address bundle, address rakeback);

    /// @notice Emitted when this contract is retired and the factories are released
    /// @param owner - The new owner of the underlying factories
    event FactoriesReleased(address owner);

    /// @dev This contract maintains and owns the bundle factory
    CarbonBundleTokenFactory public bundleFactory;

    /// @dev This contract maintains and owns the rakeback factory
    CarbonRakebackFactory public rakebackFactory;

    /// @notice Easy discovery of bundle tokens and their current active rakeback
    mapping (CarbonBundleToken => CarbonRakeback) public rakebacks;

    constructor (
        CarbonBundleTokenFactory bundleFactory_,
        CarbonRakebackFactory rakebackFactory_,
        address owner_
    ) {
        transferOwnership(owner_);

        bundleFactory = bundleFactory_;
        rakebackFactory = rakebackFactory_;

        for (uint256 i=0; i < rakebackFactory.instanceCount(); ++i) {
            CarbonRakeback rakeback = CarbonRakeback(rakebackFactory.instanceAt(i));
            _setBundleAndRakeback(CarbonBundleToken(rakeback.bundle()), rakeback);
        }
    }

    /// @notice Access function to the underlying factories to swap the implementation
    /// @param factory_ - The address of the factory
    /// @param blueprint_ - The address of the new implementation
    function setFactoryBlueprint(address factory_, address blueprint_) onlyOwner external {
        AbstractFactory factory;
        if (factory_ == address(bundleFactory)) {
            factory = CarbonTokenFactory(factory_);
        } else if (factory_ == address(rakebackFactory)) {
            factory = CarbonRakebackFactory(factory_);
        } else {
            revert('CarbonBundleConductor: factory address unknown');
        }
        factory.setBlueprint(blueprint_);
    }

    /// @notice Retire this conductor contract by releasing the ownership of the underlying factories
    /// @param newOwner_ - Address of the new owner
    function releaseFactories(address newOwner_) external onlyOwner {
        require(newOwner_ != address(0),
            'CarbonBundleConductor: owner may not be zero address');

        bundleFactory.transferOwnership(newOwner_);
        rakebackFactory.transferOwnership(newOwner_);

        emit FactoriesReleased(newOwner_);
    }

    /// @notice Creates a new bundle with an empty default rakeback contract
    /// @dev See bundleFactory.createBundle() for param definitions.
    function createBundleWithRakeback(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_
    ) onlyOwner external {
        CarbonBundleToken _bundle = CarbonBundleToken(
            bundleFactory.createBundle(name_, symbol_, vintage_, tokens_, owner_, feeDivisor_)
        );
        _setBundleAndRakeback(
            _bundle,
            CarbonRakeback(rakebackFactory.createRakeback(_bundle, owner_))
        );
    }

    /// @notice Creates a new rakeback for the given bundle
    /// @param bundle_ - The bundle that should be upgraded to the latest implementation
    /// @dev Note that the new rakeback is in an empty state
    function createNewRakebackImplementationForBundle(CarbonBundleToken bundle_) onlyOwner external {
        _setBundleAndRakeback(
            bundle_,
            CarbonRakeback(rakebackFactory.createRakeback(bundle_, bundle_.owner()))
        );
    }

    /// @notice Bundle the given amount of tokens to the given bundle
    /// @dev Requires approval to transferFrom the sender, this is just to have the same interface for terminal stations
    /// @param bundle_ - The bundle token to bundle from
    /// @param token_ - The token that should be bundled
    /// @param amount_ - The amount of tokens to bundle
    function bundle(CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_) external {
        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
        bundle_.safeTransfer(_msgSender(), amount_);
    }

    /// @notice Unbundle the given amount of tokens from the given bundle
    /// @dev Requires approval to transferFrom the sender
    /// @param bundle_ - The bundle token to unbundle from
    /// @param token_ - The token that should be unbundled
    /// @param amount_ - The amount of tokens to unbundle
    /// @return The amount unbundled after fees
    function unbundle(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external returns (uint256) {
        CarbonRakeback rakeback = _getRakeback(bundle_);

        bundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 amountUnbundled = rakeback.unbundle(token_, amount_);
        token_.safeTransfer(_msgSender(), amountUnbundled);
        return amountUnbundled;
    }

    /// @notice Swaps the sourceBundle for the targetBundle for the given amount
    /// @dev Requires approval to transferFrom the sender
    /// @param sourceBundle_ - The bundle token that one wants to swap
    /// @param targetBundle_ - The bundle token that one wants to receive
    /// @param token_ - The token to use for the swap
    /// @param amount_ - The amount of tokens to swap
    /// @return The amount of swapped tokens after the fee
    function swapBundle(
        CarbonBundleToken sourceBundle_,
        CarbonBundleToken targetBundle_,
        CarbonToken token_,
        uint256 amount_
    ) external returns (uint256) {
        CarbonRakeback rakeback = _getRakeback(sourceBundle_);

        sourceBundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        uint amountSwapped = rakeback.swapBundle(targetBundle_, token_, amount_);
        targetBundle_.safeTransfer(_msgSender(), amountSwapped);
        return amountSwapped;
    }

    /// @notice Offset a specific token on behalf of someone else
    /// @dev Requires approval to transferFrom the sender
    /// @param bundle_ - The bundle token to use for offset
    /// @param token_ - The underlying token used to offset
    /// @param account_ - The target address for the retirement
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after the fee
    function offsetSpecificOnBehalfOf(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        address account_,
        uint256 amount_
    ) public returns (uint256) {
        CarbonRakeback rakeback = _getRakeback(bundle_);

        bundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        return rakeback.offsetSpecificOnBehalfOf(token_, account_, amount_);
    }

    /// @notice Offset a specific token
    /// @dev Requires approval to transferFrom the sender
    /// @param bundle_ - The bundle token to use for offset
    /// @param token_ - The underlying token used to offset
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after the fee
    function offsetSpecific(
        CarbonBundleToken bundle_,
        CarbonToken token_,
        uint256 amount_
    ) external returns (uint256) {
        return offsetSpecificOnBehalfOf(bundle_, token_, _msgSender(), amount_);
    }

    /// @notice Find out if a bundle token has a respective rakeback contract
    /// @return True if a contract exists, else false
    function hasRakeback(CarbonBundleToken bundle_) public view returns (bool) {
        return address(rakebacks[bundle_]) != address(0);
    }

    /// @dev Sets the rakeback and approves it to withdraw from this contract
    /// @param bundle_ - The bundle token that should be connected
    /// @param rakeback_ - The rakeback contract for the given bundle
    function _setBundleAndRakeback(CarbonBundleToken bundle_, CarbonRakeback rakeback_) internal {
        bundle_.approve(address(rakeback_), type(uint256).max);
        rakebacks[bundle_] = rakeback_;

        emit RakebackChanged(address(bundle_), address(rakeback_));
    }

    /// @dev Returns the respective rakeback for the bundle or reverts if it does not have one
    /// @param bundle_ - The bundle token for which we want the rakeback
    function _getRakeback(CarbonBundleToken bundle_) internal view returns (CarbonRakeback) {
        require(hasRakeback(bundle_),
            'CarbonBundleConductor: rakeback does not exist');
        return CarbonRakeback(rakebacks[bundle_]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../../CarbonBundleToken.sol';

/// @author FlowCarbon LLC
/// @title Central Postage Fee Master Contract
contract CentralPostageFeeMaster is Ownable {

    /// @notice Emitted when the fee is set
    /// @param destination - Fee set for a specific destination
    /// @param bundle - Address of the bundle token
    /// @param amountNative - Amount in terms of the native currency
    /// @param amountInTermsOfBundle - Amount in terms of the bundle token
    /// @param noFeeOnSuccessThreshold - Threshold after which we take the fee
    event PostageFeeChanged(
        uint256 destination,
        address bundle,
        uint256 amountNative,
        uint256 amountInTermsOfBundle,
        uint256 noFeeOnSuccessThreshold
    );

    struct PostageFeeConfig {
        CarbonBundleToken bundle;
        /// Amount in bundle terms
        uint256 amountInBundleFee;
        // Threshold after which we take the fee
        uint256 noFeeOnSuccessThreshold;
    }

    // Map destination chain ID to postage fees
    mapping(uint256 => PostageFeeConfig[]) private _postageFees;

    // Map destination chain ID to native fees
    mapping(uint256 => uint256) private _nativeFees;

    constructor(address owner_) {
         transferOwnership(owner_);
    }

    /// @notice Batch update fees
    /// @dev All params are arrays of the set function
    function batchSet(
        uint256[] memory destinations_,
        CarbonBundleToken[] memory bundles_,
        uint256[] memory amountsNative_,
        uint256[] memory amountsInTermsOfBundle_,
        uint256[] memory noFeeOnSuccessThresholds_
    ) external onlyOwner {
        require(destinations_.length == bundles_.length,
            'CentralPostageFeeMaster: input length mismatch');
        require(destinations_.length == amountsNative_.length,
            'CentralPostageFeeMaster: input length mismatch');
        require(destinations_.length == amountsInTermsOfBundle_.length,
            'CentralPostageFeeMaster: input length mismatch');
        require(destinations_.length == noFeeOnSuccessThresholds_.length,
            'CentralPostageFeeMaster: input length mismatch');

        for (uint256 i=0; i < destinations_.length; ++i) {
            _set(destinations_[i], bundles_[i], amountsNative_[i], amountsInTermsOfBundle_[i], noFeeOnSuccessThresholds_[i]);
        }
    }

    /// @notice Update the fee structure for a given bundle at a given a destination
    /// @param destination_ - The chain on which to apply the new fee structure
    /// @param bundle_ - The bundle token for the new fee structure
    /// @param amountNative_ - The amount in terms of the native currency
    /// @param amountInTermsOfBundle_ - The amount in terms of the bundle token
    /// @param noFeeOnSuccessThreshold_ - Threshold after which we take the fee
    function set(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amountNative_,
        uint256 amountInTermsOfBundle_,
        uint256 noFeeOnSuccessThreshold_
    ) external onlyOwner {
        _set(destination_, bundle_, amountNative_, amountInTermsOfBundle_, noFeeOnSuccessThreshold_);
    }

    /// @notice Update the fee structure for a given bundle at a given a destination
    /// @param destination_ - The chain on which to apply the new fee structure
    /// @param bundle_ - The bundle token for the new fee structure
    /// @param amountNative_ - The amount in terms of the native currency
    /// @param amountInTermsOfBundle_ - The amount in terms of the bundle token
    /// @param noFeeOnSuccessThreshold_ - Threshold after which we take the fee
    function _set(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amountNative_,
        uint256 amountInTermsOfBundle_,
        uint256 noFeeOnSuccessThreshold_
    ) internal {
        _nativeFees[destination_] = amountNative_;
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            _postageFees[destination_][index] = PostageFeeConfig(
                bundle_,
                amountInTermsOfBundle_,
                noFeeOnSuccessThreshold_
            );
        } else {
            _postageFees[destination_].push(PostageFeeConfig(
                bundle_,
                amountInTermsOfBundle_,
                noFeeOnSuccessThreshold_
            ));
        }

        emit PostageFeeChanged(
            destination_,
            address(bundle_),
            amountNative_,
            amountInTermsOfBundle_,
            noFeeOnSuccessThreshold_
        );
    }

    /// @dev Defaults to 0
    /// @return The fee in terms of the native currency
    function getNative(uint256 destination_) external view returns (uint256) {
        return _nativeFees[destination_];
    }

    /// @param destination_ - The chain for which one is interested in the fees
    /// @param bundle_ - The bundle for which one is interested in the fees
    /// @param amount_ - The amount that is subject to fees
    /// @param onSuccess_ - Which path is this fee collected on? If successful, we might reimburse the fee :-)
    /// @return The fee for a chain / bundle
    function get(
        uint256 destination_,
        CarbonBundleToken bundle_,
        uint256 amount_,
        bool onSuccess_
    ) external view returns (uint256) {
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            PostageFeeConfig memory fee = _postageFees[destination_][index];
            if (onSuccess_ && amount_ >= fee.noFeeOnSuccessThreshold) {
                return 0;
            }
            return _postageFees[destination_][index].amountInBundleFee;
        }

        /// free as a bird!
        return 0;
    }

    /// @notice This is never a threshold for failure
    /// @return The threshold over which no fee is taken
    function getThresholdForSuccessPath(
        uint256 destination_,
        CarbonBundleToken bundle_
    ) external view returns (uint256) {
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            return _postageFees[destination_][index].noFeeOnSuccessThreshold;
        }
        revert('CentralPostageFeeMaster: no threshold');
    }

    /// @return The index of a postage fee or total number of entries if not found
    function _getForIndex(
        uint256 destination_,
        CarbonBundleToken bundle_
    ) internal view returns (uint256) {
        for (uint256 i=0; i < _postageFees[destination_].length; i++) {
            if (_postageFees[destination_][i].bundle == bundle_) {
                return i;
            }
        }
        return _postageFees[destination_].length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {CarbonToken, CarbonBundleToken} from '../../CarbonBundleToken.sol';
import '../../interfaces/ICarbonAccessList.sol';
import '../remote/RemoteCarbonReceiver.sol';
import '../interfaces/ICarbonSender.sol';
import '../CentralCarbonStation.sol';

/// @author FlowCarbon LLC
/// @title Central Carbon Sender Contract
contract CentralCarbonSender is ICarbonSender {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Emitted when a token is synced
    /// @param destination - The target chain of the sync
    /// @param token - The address of the synced token
    event TokenSynced(uint256 destination, address token);

    /// @notice Emitted when a bundle token is synced
    /// @param destination - The target chain of the sync
    /// @param bundle - The address of the synced bundle
    event BundleTokenSynced(uint256 destination, address bundle);

    /// @notice Emitted when a access list is synced
    /// @param destination - The target chain of the sync
    /// @param accessList - The address of the synced access list
    event AccessListSynced(uint256 destination, address accessList);

    /// @notice Emitted when a access is registered
    /// @param destination - The target chain of the sync
    /// @param accessList - The address of the synced access list
    /// @param account - Which account was registered
    /// @param hasAccess - Indicates if the access was granted or revoked
    event AccessRegistered(uint256 destination, address accessList, address account, bool hasAccess);

    /// @notice Emitted when a token is registered
    /// @param destination - The target chain of the sync
    /// @param token - The token being registered
    /// @param bundle - The bundle where the token is registered / deregistered for
    /// @param isAdded - True for adding, false for removal
    /// @param isPaused - True if paused, false if not
    event TokenRegistered(uint256 destination, address token, address bundle, bool isAdded, bool isPaused);

    /// The central station that connects us to cross-chain network
    CentralCarbonStation station;

    constructor(CentralCarbonStation station_) {
        station = station_;
    }

    /// @notice Syncs a token to the terminal chain, giving it the full interface on the terminal chain
    /// @dev Syncs initially, subsequent calls update the access list or do nothing but costing you fees
    /// @param destination_ - The terminal chain
    /// @param token_ - The address of the token to sync
    /// @return True if the token is added for the first time, else false (on update)
    function syncToken(uint256 destination_, address token_) external payable returns (bool) {
        CarbonToken token = station.getToken(token_);

        ICarbonAccessList accessList = token.accessList();
        station.requireAccessListSynced(destination_, address(accessList));

        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSyncToken.selector,
                token_,
                token.name(),
                token.symbol(),
                CarbonToken.TokenDetails(
                    token.registry(),
                    token.standard(),
                    token.creditType(),
                    token.vintage()
                ),
                accessList
            )
        );

        emit TokenSynced(destination_, token_);
        return station.registerSyncedToken(destination_, token_);
    }

    /// @notice Syncs a bundle to the destination chain, allowing access to all functionality on a remote network
    /// @dev After syncing once, subsequent calls will update the vintage
    /// @param destination_ - The terminal chain
    /// @param bundle_ - The address of the bundle to sync
    /// @return True if a new bundle was created, otherwise false
    function syncBundle(uint256 destination_, address bundle_) external payable returns (bool) {
        CarbonBundleToken bundle = station.getBundle(bundle_);

        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              RemoteCarbonReceiver.handleSyncBundle.selector,
              bundle_,
              bundle.name(),
              bundle.symbol(),
              bundle.vintage(),
              bundle.feeDivisor()
            )
        );

        emit BundleTokenSynced(destination_, bundle_);
        return station.registerSyncedBundle(destination_, bundle_);
    }

    /// @notice Sync an access list over to the destination chain
    /// @param destination_ - The terminal chain
    /// @param accessList_ - The access list to sync
    /// @return A flag if this action had an effect
    function syncAccessList(uint256 destination_, address accessList_) external payable returns (bool) {
        station.requireAccessListNotSynced(destination_, accessList_);

        ICarbonAccessList accessList = station.getAccessList(accessList_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleSyncAccessList.selector,
                accessList_,
                accessList.name()
            )
        );

        emit AccessListSynced(destination_, accessList_);
        return station.registerSyncedAccessList(destination_, accessList_);
    }

    /// @notice Registers a access given to the destination chain
    /// @param destination_ - The terminal chain id
    /// @param accessList_ - Address of the access list to register an account for
    /// @param account_ - The account to sync
    /// @return Flag that indicates if the access was added
    function registerAccess(
        uint256 destination_,
        address accessList_,
        address account_
    ) external payable returns (bool) {
        station.requireAccessListSynced(destination_, accessList_);

        ICarbonAccessList accessList = station.getAccessList(accessList_);
        bool hasAccess = accessList.hasGlobalAccess(account_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                RemoteCarbonReceiver.handleRegisterAccess.selector,
                accessList_,
                account_,
                hasAccess
            )
        );

        emit AccessRegistered(destination_, accessList_, account_, hasAccess);
        return hasAccess;
    }

    /// @notice Registers a token for a bundle
    /// @param destination_ - The target chain
    /// @param bundle_ - The bundle for which the token is registered
    /// @param token_ - The bundled token
    /// @return Flag indicating if the token was added or removed
    function registerTokenForBundle(
        uint256 destination_,
        address bundle_,
        address token_
    ) external payable returns (bool) {
        station.requireTokenSynced(destination_, token_);
        station.requireBundleSynced(destination_, bundle_);
        CarbonBundleToken bundle = station.getBundle(bundle_);
        CarbonToken token = CarbonToken(token_);

        bool isAdded = bundle.hasToken(token);
        bool isPaused = bundle.pausedForBundle(CarbonToken(token));

        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              RemoteCarbonReceiver.handleRegisterTokenForBundle.selector,
              bundle_,
              token_,
              isAdded,
              isPaused
            )
        );
        emit TokenRegistered(destination_, token_, bundle_, isAdded, isPaused);
        return isAdded;
    }

    /// @notice Send tokens to a someone on some chain!
    /// @param destination_ - The target chain
    /// @param token_ - The token to send
    /// @param recipient_ - The recipient on the remote chain
    /// @param amount_ - The amount of tokens to be send
    /// @dev Requires approval
    function sendToken(
        uint256 destination_,
        address token_,
        address recipient_,
        uint256 amount_
    ) public payable {
        station.requireTokenSynced(destination_, token_);
        CarbonToken token = station.getToken(token_);

        if (address(token.accessList()) != address(0)) {
            require(token.accessList().hasAccess(msg.sender),
                'CarbonCreditSender: the sender is not allowed to send this token');
            require(token.accessList().hasAccess(recipient_),
                'CarbonCreditSender: the recipient is not allowed to receive this token');
        }

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                ICarbonReceiver.handleReceiveToken.selector,
                token_,
                recipient_,
                amount_
            )
        );

        emit TokenSent(destination_, msg.sender, recipient_, token_, amount_);
    }

    /// @notice Send bundle tokens to a someone on some chain!
    /// @param destination_ - The target chain
    /// @param bundle_ - The token to send
    /// @param recipient_ - The recipient on the remote chain
    /// @param amount_ - The amount of tokens to be send
    /// @dev Requires approval
    function sendBundle(
        uint256 destination_,
        address bundle_,
        address recipient_,
        uint256 amount_
    ) public payable {
        station.requireBundleSynced(destination_, bundle_);

        IERC20Upgradeable(station.getBundle(bundle_)).safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              RemoteCarbonReceiver.handleReceiveBundle.selector,
              bundle_,
              recipient_,
              amount_
            )
        );

        emit BundleSent(destination_, msg.sender, recipient_, bundle_, amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CarbonRakeback.sol';
import './abstracts/AbstractFactory.sol';

/// @author FlowCarbon LLC
/// @title Carbon Rakeback Factory Contract
contract CarbonRakebackFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param blueprint_ - The contract to be used as implementation for new rakebacks
    /// @param owner_ - The address to which ownership of this contract will be transferred
    constructor (CarbonRakeback blueprint_, address owner_) {
        setBlueprint(address(blueprint_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new rakeback
    /// @param bundle_ - The bundle for this rakeback contract
    /// @param owner_ - The address to which ownership of the deployed contract will be transferred
    /// @return The address of the newly created rakeback
    function createRakeback(CarbonBundleToken bundle_, address owner_) onlyOwner external returns (address) {
        CarbonRakeback rakeback = CarbonRakeback(blueprint.clone());
        rakeback.initialize(bundle_, owner_);
        finalizeCreation(address(rakeback));
        return address(rakeback);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './CarbonToken.sol';
import './CarbonBundleToken.sol';

/// @author FlowCarbon LLC
/// @title Carbon Rakeback Contract
/// @dev NOTE: This contract must be added to the tokens access list, if one exists
contract CarbonRakeback is Initializable, OwnableUpgradeable {

    using SafeERC20Upgradeable for CarbonToken;

    using SafeERC20Upgradeable for CarbonBundleToken;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice Emitted after bundle swap
    /// @param account - The account that triggered the swap
    /// @param sourceBundle - The source bundle address
    /// @param targetBundle - The target bundle address
    /// @param token - The address of the token that was swapped
    /// @param amountIn - The amount swapped in terms of source bundle
    /// @param amountOut - The amount received after fees in terms of target bundle
    event BundleSwap(
        address account,
        address sourceBundle,
        address targetBundle,
        address token,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted after offset specific
    /// @param account - The account that triggered the offset
    /// @param bundle - The bundle address
    /// @param token - The address of the token that is to be offsetted
    /// @param amountIn - The amount to offset in terms of source bundle
    /// @param amountOffsetted - The amount offsetted after fees in terms of the token
    event OffsetSpecific(
        address account,
        address bundle,
        address token,
        uint256 amountIn,
        uint256 amountOffsetted
    );

    /// @notice Emitted when someone unbundles tokens from the bundle using the rakeback contract
    /// @param account - The token recipient
    /// @param bundle - The bundle from which the token was unbundled
    /// @param token - The address of the vanilla underlying
    /// @param amountIn - The amount sent to unbundle
    /// @param amountOut - The amount after fees (these may change in the rakeback and are therefore explicit)
    event RakebackUnbundle(
        address account,
        address bundle,
        address token,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted whenever a fee divisor is updated for a token
    /// @param token - The token with a new fee divisor
    /// @param feeDivisor - The new fee divisor; the actual fee is the reciprocal
    event FeeDivisorUpdated(CarbonToken token, uint256 feeDivisor);

    /// @notice The bundle token associated with this rakeback
    CarbonBundleToken public bundle;

    /// @dev Internal mapping of carbon credit tokens to fee divisor overrides.
    mapping(CarbonToken => uint256) private _feeDivisors;

    /// @dev Internal set of carbon credit tokens that have overridden fee divisors.
    EnumerableSetUpgradeable.AddressSet private _tokensWithFeeDivisorOverrides;

    /// @param bundle_ - The bundle that this rakeback contract controls
    /// @param owner_ - The owner of this rakeback contract
    function initialize(CarbonBundleToken bundle_, address owner_) external initializer {
        require(address(bundle_) != address(0),
            'CarbonRakeback: bundle is required');
        bundle = bundle_;
        __Ownable_init();
        transferOwnership(owner_);
    }

    /// @notice Batch setting of the feeDivisor
    /// @param tokens_ - Array of CarbonTokens
    /// @param feeDivisor_ - Array of feeDivisors
    function batchSetFeeDivisor(CarbonToken[] memory tokens_,  uint256[] memory feeDivisor_) onlyOwner external {
        require(tokens_.length == feeDivisor_.length,
            'CarbonRakeback: tokens and fee divisors must have the same length');
        for (uint256 i=0; i < tokens_.length; i++) {
            setFeeDivisor(tokens_[i], feeDivisor_[i]);
        }
    }

    /// @notice Batch remove of feeDivisors
    /// @param tokens_ - Array of CarbonTokens
    function batchRemoveFeeDivisor(CarbonToken[] memory tokens_) onlyOwner external {
        for (uint256 i=0; i < tokens_.length; i++) {
            removeFeeDivisor(tokens_[i]);
        }
    }

    // @notice Set a fee divisor for a token
    // @dev A fee divisor is the reciprocal of the actual fee, e.g. 100 is 1% because 1/100 = 0.01
    // @param token_ - The token for which we set the fee divisor
    // @param feeDivisor_ - The fee divisor
    function setFeeDivisor(CarbonToken token_, uint256 feeDivisor_) onlyOwner public {
        require(bundle.feeDivisor() < feeDivisor_,
            'CarbonRakeback: fee divisor must exceed base fee');
        require(_feeDivisors[token_] != feeDivisor_,
            'CarbonRakeback: fee divisor must change');

        _tokensWithFeeDivisorOverrides.add(address(token_));
        _feeDivisors[token_] = feeDivisor_;
        emit FeeDivisorUpdated(token_, feeDivisor_);
    }

    // @notice Removes a fee divisor for a token
    // @param token_ - The token for which we remove the fee divisor
    function removeFeeDivisor(CarbonToken token_) onlyOwner public {
        require(hasTokenWithFeeDivisor(token_),
            'CarbonRakeback: no fee divisor configured for token');

        uint bundleFeeDivisor = bundle.feeDivisor();
        _tokensWithFeeDivisorOverrides.remove(address(token_));
        _feeDivisors[token_] = bundleFeeDivisor;
        emit FeeDivisorUpdated(token_, bundleFeeDivisor);
    }

    /// @notice Checks if a token has a fee divisor specified in this contract
    /// @param token_ - A carbon credit token
    /// @return Whether we have a token fee divisor or not
    function hasTokenWithFeeDivisor(CarbonToken token_) public view returns (bool) {
        return _tokensWithFeeDivisorOverrides.contains(address(token_));
    }

    /// @notice Number of tokens that have a fee override
    /// @return The number of tokens
    function tokenWithFeeDivisorCount() external view returns (uint256) {
        return _tokensWithFeeDivisorOverrides.length();
    }

    /// @notice A token with a fee divisor
    /// @param index_ - The index position taken from tokenCount()
    /// @dev The ordering may change upon adding / removing
    /// @return Address of the token at the index
    function tokenWithFeeDivisorAtIndex(uint256 index_) external view returns (address) {
        return _tokensWithFeeDivisorOverrides.at(index_);
    }

    /// @notice The fee divisor of a token
    /// @dev This uses the bundles default as a fallback if not specified, so it'll always work
    /// @return The fee divisor
    function feeDivisor(CarbonToken token_) public view returns (uint256) {
        if (hasTokenWithFeeDivisor(token_)) {
            return _feeDivisors[token_];
        }
        return bundle.feeDivisor();
    }

    /// @dev Internal function to calculate the rakeback
    /// @param token_ - The token for which we calculate the rakeback
    /// @param amountBeforeFee_ - The amount before the fee was applied by the bundle
    /// @param amountAfterFee_ - The amount after the fee was applied by the bundle
    /// @return The rakeback provided by this contract
    function _calculateRakeback(CarbonToken token_, uint256 amountBeforeFee_, uint256 amountAfterFee_) internal view returns (uint256) {
        uint256 originalFeeDivisor = bundle.feeDivisor();
        uint256 currentFeeDivisor = feeDivisor(token_);
        if (currentFeeDivisor > originalFeeDivisor) {
            uint256 originalFee = amountBeforeFee_ - amountAfterFee_;
            // NOTE: this is safe because currentFeeDivisor > originalFeeDivisor >= 0
            uint256 feeAmount = amountBeforeFee_ / currentFeeDivisor;
            return originalFee - feeAmount;
        }
        return 0;
    }

    /// @dev Pulls in the tokens from the sender and unbundles it to the specified token
    /// @param token_ - The token the sender wishes to unbundle to
    /// @param amount_ - The amount the sender wishes to unbundle
    /// @return The amount after fees that the user receives
    function _transferFromAndUnbundle(CarbonToken token_, uint256 amount_) internal returns (uint256) {
        bundle.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 amountAfterFees = bundle.unbundle(token_, amount_);
        uint256 rakeback = _calculateRakeback(token_, amount_, amountAfterFees);
        token_.safeTransferFrom(bundle.owner(), address(this), rakeback);
        return amountAfterFees + rakeback;
    }

    /// @dev Bundles the amount of given tokens into the requested bundle and sends the bundle tokens back
    /// @param bundle_ - The target bundle to swap to
    /// @param token_ - The token the sender wishes to swap to
    /// @param amount_ - The amount the sender wishes to swap
    /// @return The amount after fees that the user receives
    function _bundleAndTransfer(
        CarbonBundleToken bundle_, CarbonToken token_, uint256 amount_
    ) internal returns (uint256) {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
        bundle_.safeTransfer(_msgSender(), amount_);
        return amount_;
    }

    /// @notice Unbundle the given token for the given amount
    /// @dev The sender needs to have given approval for the amount for the bundle
    /// @param token_ - The token the sender wishes to unbundle
    /// @param amount_ - The amount the sender wishes to unbundle
    /// @return The amount after fees that the user receives
    function unbundle(CarbonToken token_, uint256 amount_) external returns (uint256) {
        uint amountOut = _transferFromAndUnbundle(token_, amount_);
        token_.safeTransfer(_msgSender(), amountOut);

        emit RakebackUnbundle(_msgSender(), address(bundle), address(token_), amount_, amountOut);
        return amountOut;
    }

    /// @notice Swaps a given GCO2 token between bundles
    /// @param targetBundle_ - The bundle where the GCO2 token should be bundled into
    /// @param token_ - The GCO2 token to swap
    /// @param amount_ - The amount of tokens to swap
    /// @return The amount of tokens arriving in the bundle (after fee)
    function swapBundle(CarbonBundleToken targetBundle_, CarbonToken token_, uint256 amount_) external returns (uint256) {
        uint amountOut = _bundleAndTransfer(
            targetBundle_,
            token_,
            _transferFromAndUnbundle(token_, amount_)
        );

        emit BundleSwap(_msgSender(), address(bundle), address(targetBundle_), address(token_), amount_, amountOut);
        return amountOut;
    }

    /// @notice Offsets a specific GCO2 token on behalf of the given address
    /// @param token_ - The GCO2 token to offset
    /// @param account_ - The beneficiary to the offset
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after fee
    function offsetSpecificOnBehalfOf(CarbonToken token_, address account_, uint256 amount_) public returns (uint256) {
        uint256 amountToOffset = _transferFromAndUnbundle(token_, amount_);
        token_.offsetOnBehalfOf(
            account_,
            amountToOffset
        );

        emit OffsetSpecific(account_, address(bundle), address(token_), amount_, amountToOffset);
        return amountToOffset;
    }

    /// @notice Offsets a specific GCO2 token
    /// @param token_ - The GCO2 token to offset
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after fee
    function offsetSpecific(CarbonToken token_, uint256 amount_) external returns (uint256) {
        return offsetSpecificOnBehalfOf(token_, msg.sender, amount_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('CarbonRakeback: renouncing ownership is disabled');
    }
}