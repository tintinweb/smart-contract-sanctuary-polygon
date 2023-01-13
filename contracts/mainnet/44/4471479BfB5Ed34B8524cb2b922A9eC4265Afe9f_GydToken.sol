// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "ERC20Upgradeable.sol";

import "IGyroConfig.sol";

import "ConfigHelpers.sol";

contract GydToken is ERC20Upgradeable {
    using ConfigHelpers for IGyroConfig;

    IGyroConfig public immutable gyroConfig;

    constructor(address _gyroConfig) {
        require(_gyroConfig != address(0), Errors.INVALID_ARGUMENT);
        gyroConfig = IGyroConfig(_gyroConfig);
    }

    function initialize(string memory name, string memory symbol) external initializer {
        __ERC20_init(name, symbol);
    }

    function mint(address account, uint256 amount) external {
        require(address(gyroConfig.getMotherboard()) == _msgSender(), Errors.NOT_AUTHORIZED);
        _mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        bool isMinter = address(gyroConfig.getMotherboard()) == _msgSender();
        require(isMinter || currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        if (!isMinter) {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

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

pragma solidity ^0.8.0;
import "Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGovernable.sol";

/// @notice IGyroConfig stores the global configuration of the Gyroscope protocol
interface IGyroConfig is IGovernable {
    /// @notice Event emitted every time a configuration is changed
    event ConfigChanged(bytes32 key, uint256 previousValue, uint256 newValue);
    event ConfigChanged(bytes32 key, address previousValue, address newValue);

    /// @notice Event emitted when a configuration is unset
    event ConfigUnset(bytes32 key);

    /// @notice Event emitted when a configuration is frozen
    event ConfigFrozen(bytes32 key);

    /// @notice Returns a set of known configuration keys
    function listKeys() external view returns (bytes32[] memory);

    /// @notice Returns true if the configuration has the given key
    function hasKey(bytes32 key) external view returns (bool);

    /// @notice Returns the metadata associated with a particular config key
    function getConfigMeta(bytes32 key) external view returns (uint8, bool);

    /// @notice Returns a uint256 value from the config
    function getUint(bytes32 key) external view returns (uint256);

    /// @notice Returns a uint256 value from the config or `defaultValue` if it does not exist
    function getUint(bytes32 key, uint256 defaultValue) external view returns (uint256);

    /// @notice Returns an address value from the config
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Returns an address value from the config or `defaultValue` if it does not exist
    function getAddress(bytes32 key, address defaultValue) external view returns (address);

    /// @notice Set a uint256 config
    /// NOTE: We avoid overloading to avoid complications with some clients
    function setUint(bytes32 key, uint256 newValue) external;

    /// @notice Set an address config
    function setAddress(bytes32 key, address newValue) external;

    /// @notice Unset a key in the config
    function unset(bytes32 key) external;

    /// @notice Freezes a key, making it impossible to update or unset
    function freeze(bytes32 key) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IGovernable {
    /// @notice Emmited when the governor is changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    /// @notice Emmited when the governor is change is requested
    event GovernorChangeRequested(address newGovernor);

    /// @notice Returns the current governor
    function governor() external view returns (address);

    /// @notice Returns the pending governor
    function pendingGovernor() external view returns (address);

    /// @notice Changes the governor
    /// can only be called by the current governor
    function changeGovernor(address newGovernor) external;

    /// @notice Called by the pending governor to approve the change
    function acceptGovernance() external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC721.sol";

import "ConfigKeys.sol";

import "IBatchVaultPriceOracle.sol";
import "IMotherboard.sol";
import "ISafetyCheck.sol";
import "IGyroConfig.sol";
import "IVaultRegistry.sol";
import "IAssetRegistry.sol";
import "IReserveManager.sol";
import "IFeeBank.sol";
import "IReserve.sol";
import "IGYDToken.sol";
import "IFeeHandler.sol";
import "ICapAuthentication.sol";

/// @notice Defines helpers to allow easy access to common parts of the configuration
library ConfigHelpers {
    function getRootPriceOracle(IGyroConfig gyroConfig)
        internal
        view
        returns (IBatchVaultPriceOracle)
    {
        return IBatchVaultPriceOracle(gyroConfig.getAddress(ConfigKeys.ROOT_PRICE_ORACLE_ADDRESS));
    }

    function getRootSafetyCheck(IGyroConfig gyroConfig) internal view returns (ISafetyCheck) {
        return ISafetyCheck(gyroConfig.getAddress(ConfigKeys.ROOT_SAFETY_CHECK_ADDRESS));
    }

    function getVaultRegistry(IGyroConfig gyroConfig) internal view returns (IVaultRegistry) {
        return IVaultRegistry(gyroConfig.getAddress(ConfigKeys.VAULT_REGISTRY_ADDRESS));
    }

    function getAssetRegistry(IGyroConfig gyroConfig) internal view returns (IAssetRegistry) {
        return IAssetRegistry(gyroConfig.getAddress(ConfigKeys.ASSET_REGISTRY_ADDRESS));
    }

    function getReserveManager(IGyroConfig gyroConfig) internal view returns (IReserveManager) {
        return IReserveManager(gyroConfig.getAddress(ConfigKeys.RESERVE_MANAGER_ADDRESS));
    }

    function getFeeBank(IGyroConfig gyroConfig) internal view returns (IFeeBank) {
        return IFeeBank(gyroConfig.getAddress(ConfigKeys.FEE_BANK_ADDRESS));
    }

    function getReserve(IGyroConfig gyroConfig) internal view returns (IReserve) {
        return IReserve(gyroConfig.getAddress(ConfigKeys.RESERVE_ADDRESS));
    }

    function getGYDToken(IGyroConfig gyroConfig) internal view returns (IGYDToken) {
        return IGYDToken(gyroConfig.getAddress(ConfigKeys.GYD_TOKEN_ADDRESS));
    }

    function getFeeHandler(IGyroConfig gyroConfig) internal view returns (IFeeHandler) {
        return IFeeHandler(gyroConfig.getAddress(ConfigKeys.FEE_HANDLER_ADDRESS));
    }

    function getMotherboard(IGyroConfig gyroConfig) internal view returns (IMotherboard) {
        return IMotherboard(gyroConfig.getAddress(ConfigKeys.MOTHERBOARD_ADDRESS));
    }

    function getGlobalSupplyCap(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.GYD_GLOBAL_SUPPLY_CAP, type(uint256).max);
    }

    function getPerUserSupplyCap(IGyroConfig gyroConfig, bool authenticated)
        internal
        view
        returns (uint256)
    {
        if (authenticated) {
            return gyroConfig.getUint(ConfigKeys.GYD_AUTHENTICATED_USER_CAP, type(uint256).max);
        }
        return gyroConfig.getUint(ConfigKeys.GYD_USER_CAP, type(uint256).max);
    }

    function isAuthenticated(IGyroConfig gyroConfig, address user) internal view returns (bool) {
        if (!gyroConfig.hasKey(ConfigKeys.CAP_AUTHENTICATION_ADDRESS)) return false;
        return
            ICapAuthentication(gyroConfig.getAddress(ConfigKeys.CAP_AUTHENTICATION_ADDRESS))
                .isAuthenticated(user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different configuration keys used in the Gyroscope system
library ConfigKeys {
    // Addresses
    bytes32 internal constant GYD_TOKEN_ADDRESS = "GYD_TOKEN_ADDRESS";
    bytes32 internal constant PAMM_ADDRESS = "PAMM_ADDRESS";
    bytes32 internal constant FEE_BANK_ADDRESS = "FEE_BANK_ADDRESS";
    bytes32 internal constant RESERVE_ADDRESS = "RESERVE_ADDRESS";
    bytes32 internal constant ROOT_PRICE_ORACLE_ADDRESS = "ROOT_PRICE_ORACLE_ADDRESS";
    bytes32 internal constant ROOT_SAFETY_CHECK_ADDRESS = "ROOT_SAFETY_CHECK_ADDRESS";
    bytes32 internal constant VAULT_REGISTRY_ADDRESS = "VAULT_REGISTRY_ADDRESS";
    bytes32 internal constant ASSET_REGISTRY_ADDRESS = "ASSET_REGISTRY_ADDRESS";
    bytes32 internal constant RESERVE_MANAGER_ADDRESS = "RESERVE_MANAGER_ADDRESS";
    bytes32 internal constant FEE_HANDLER_ADDRESS = "FEE_HANDLER_ADDRESS";
    bytes32 internal constant MOTHERBOARD_ADDRESS = "MOTHERBOARD_ADDRESS";
    bytes32 internal constant CAP_AUTHENTICATION_ADDRESS = "CAP_AUTHENTICATION_ADDRESS";

    // Uints
    bytes32 internal constant GYD_GLOBAL_SUPPLY_CAP = "GYD_GLOBAL_SUPPLY_CAP";
    bytes32 internal constant GYD_AUTHENTICATED_USER_CAP = "GYD_AUTHENTICATED_USER_CAP";
    bytes32 internal constant GYD_USER_CAP = "GYD_USER_CAP";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

import "IGyroVault.sol";

interface IBatchVaultPriceOracle {
    event BatchPriceOracleChanged(address indexed priceOracle);
    event VaultPriceOracleChanged(Vaults.Type indexed vaultType, address indexed priceOracle);

    /// @notice Fetches the price of the vault token as well as the underlying tokens
    /// @return the same vaults info with the price data populated
    function fetchPricesUSD(DataTypes.VaultInfo[] memory vaultsInfo)
        external
        view
        returns (DataTypes.VaultInfo[] memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Contains the data structures to express token routing
library DataTypes {
    /// @notice Contains a token and the amount associated with it
    struct MonetaryAmount {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Contains a token and the price associated with it
    struct PricedToken {
        address tokenAddress;
        bool isStable;
        uint256 price;
    }

    /// @notice A route from/to a token to a vault
    /// This is used to determine in which vault the token should be deposited
    /// or from which vault it should be withdrawn
    struct TokenToVaultMapping {
        address inputToken;
        address vault;
    }

    /// @notice Asset used to mint
    struct MintAsset {
        address inputToken;
        uint256 inputAmount;
        address destinationVault;
    }

    /// @notice Asset to redeem
    struct RedeemAsset {
        address outputToken;
        uint256 minOutputAmount;
        uint256 valueRatio;
        address originVault;
    }

    /// @notice Persisted metadata about the vault
    struct PersistedVaultMetadata {
        uint256 initialPrice;
        uint256 initialWeight;
        uint256 shortFlowMemory;
        uint256 shortFlowThreshold;
    }

    /// @notice Directional (in or out) flow data for the vaults
    struct DirectionalFlowData {
        uint128 shortFlow;
        uint64 lastSafetyBlock;
        uint64 lastSeenBlock;
    }

    /// @notice Bidirectional vault flow data
    struct FlowData {
        DirectionalFlowData inFlow;
        DirectionalFlowData outFlow;
    }

    /// @notice Vault flow direction
    enum Direction {
        In,
        Out,
        Both
    }

    /// @notice Vault address and direction for Oracle Guardian
    struct GuardedVaults {
        address vaultAddress;
        Direction direction;
    }

    /// @notice Vault with metadata
    struct VaultInfo {
        address vault;
        uint8 decimals;
        address underlying;
        uint256 price;
        PersistedVaultMetadata persistedMetadata;
        uint256 reserveBalance;
        uint256 currentWeight;
        uint256 idealWeight;
        PricedToken[] pricedTokens;
    }

    /// @notice Vault metadata
    struct VaultMetadata {
        address vault;
        uint256 idealWeight;
        uint256 currentWeight;
        uint256 resultingWeight;
        uint256 price;
        bool allStablecoinsOnPeg;
        bool atLeastOnePriceLargeEnough;
        bool vaultWithinEpsilon;
        PricedToken[] pricedTokens;
    }

    /// @notice Metadata to contain vaults metadata
    struct Metadata {
        VaultMetadata[] vaultMetadata;
        bool allVaultsWithinEpsilon;
        bool allStablecoinsAllVaultsOnPeg;
        bool allVaultsUsingLargeEnoughPrices;
        bool mint;
    }

    /// @notice Mint or redeem order struct
    struct Order {
        VaultWithAmount[] vaultsWithAmount;
        bool mint;
    }

    /// @notice Vault info with associated amount for order operation
    struct VaultWithAmount {
        VaultInfo vaultInfo;
        uint256 amount;
    }

    /// @notice state of the reserve (i.e., all the vaults)
    struct ReserveState {
        uint256 totalUSDValue;
        VaultInfo[] vaults;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Vaults.sol";

import "IERC20Metadata.sol";

/// @notice A vault is one of the component of the reserve and has a one-to-one
/// mapping to an underlying pool (e.g. Balancer pool, Curve pool, Uniswap pool...)
/// It is itself an ERC-20 token that is used to track the ownership of the LP tokens
/// deposited in the vault
/// A vault can be associated with a strategy to generate yield on the deposited funds
interface IGyroVault is IERC20Metadata {
    /// @return The type of the vault
    function vaultType() external view returns (Vaults.Type);

    /// @return The token associated with this vault
    /// This can be any type of token but will likely be an LP token in practice
    function underlying() external view returns (address);

    /// @return The token associated with this vault
    /// In the case of an LP token, this will be the underlying tokens
    /// associated to it (e.g. [ETH, DAI] for a ETH/DAI pool LP token or [USDC] for aUSDC)
    /// In most cases, the tokens returned will not be LP tokens
    function getTokens() external view returns (IERC20[] memory);

    /// @return The total amount of underlying tokens in the vault
    function totalUnderlying() external view returns (uint256);

    /// @return The exchange rate between an underlying tokens and the token of this vault
    function exchangeRate() external view returns (uint256);

    /// @notice Deposits `underlyingAmount` of LP token supported
    /// and sends back the received vault tokens
    /// @param underlyingAmount the amount of underlying to deposit
    /// @return vaultTokenAmount the amount of vault token sent back
    function deposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        returns (uint256 vaultTokenAmount);

    /// @notice Simlar to `deposit(uint256 underlyingAmount)` but credits the tokens
    /// to `beneficiary` instead of `msg.sender`
    function depositFor(
        address beneficiary,
        uint256 underlyingAmount,
        uint256 minVaultTokensOut
    ) external returns (uint256 vaultTokenAmount);

    /// @notice Dry-run version of deposit
    function dryDeposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        view
        returns (uint256 vaultTokenAmount, string memory error);

    /// @notice Withdraws `vaultTokenAmount` of LP token supported
    /// and burns the vault tokens
    /// @param vaultTokenAmount the amount of vault token to withdraw
    /// @return underlyingAmount the amount of LP token sent back
    function withdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        returns (uint256 underlyingAmount);

    /// @notice Dry-run version of `withdraw`
    function dryWithdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        view
        returns (uint256 underlyingAmount, string memory error);

    /// @return The address of the current strategy used by the vault
    function strategy() external view returns (address);

    /// @notice Sets the address of the strategy to use for this vault
    /// This will be used through governance
    /// @param strategyAddress the address of the strategy contract that should follow the `IStrategy` interface
    function setStrategy(address strategyAddress) external;

    /// @return the block at which the vault has been deployed
    function deployedAt() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

library Vaults {
    enum Type {
        GENERIC,
        BALANCER_CPMM,
        BALANCER_2CLP,
        BALANCER_3CLP,
        BALANCER_ECLP
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGyroConfig.sol";
import "IGYDToken.sol";
import "IReserve.sol";
import "IPAMM.sol";
import "IFeeBank.sol";

/// @title IMotherboard is the central contract connecting the different pieces
/// of the Gyro protocol
interface IMotherboard {
    /// @dev The GYD token is not upgradable so this will always return the same value
    /// @return the address of the GYD token
    function gydToken() external view returns (IGYDToken);

    /// @notice Returns the address for the PAMM
    /// @return the PAMM address
    function pamm() external view returns (IPAMM);

    /// @notice Returns the address for the reserve
    /// @return the address of the reserve
    function reserve() external view returns (IReserve);

    /// @notice Returns the address of the global configuration
    /// @return the global configuration address
    function gyroConfig() external view returns (IGyroConfig);

    /// @notice Main minting function to be called by a depositor
    /// This mints using the exact input amount and mints at least `minMintedAmount`
    /// All the `inputTokens` should be approved for the motherboard to spend at least
    /// `inputAmounts` on behalf of the sender
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @return mintedGYDAmount GYD token minted amount
    function mint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount)
        external
        returns (uint256 mintedGYDAmount);

    /// @notice Main redemption function to be called by a withdrawer
    /// This redeems using at most `maxRedeemedAmount` of GYD and returns the
    /// exact outputs as specified by `tokens` and `amounts`
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    function redeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] calldata assets)
        external
        returns (uint256[] memory outputAmounts);

    /// @notice Simulates a mint to know whether it would succeed and how much would be minted
    /// The parameters are the same as the `mint` function
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @param account the account that wants to mint
    /// @return mintedGYDAmount the amount that would be minted, or 0 if it an error would occur
    /// @return err a non-empty error message in case an error would happen when minting
    function dryMint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount, address account)
        external
        returns (uint256 mintedGYDAmount, string memory err);

    /// @notice Dry version of the `redeem` function
    /// exact outputs as specified by `tokens` and `amounts`
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    /// @return err a non-empty error message in case an error would happen when redeeming
    function dryRedeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] memory assets)
        external
        returns (uint256[] memory outputAmounts, string memory err);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC20.sol";

/// @notice IGYDToken is the GYD token contract
interface IGYDToken is IERC20 {
    /// @notice Set the address allowed to mint new GYD tokens
    /// @dev This should typically be the motherboard that will mint or burn GYD tokens
    /// when user interact with it
    /// @param _minter the address of the authorized minter
    function setMinter(address _minter) external;

    /// @notice Gets the address for the minter contract
    /// @return the address of the minter contract
    function minter() external returns (address);

    /// @notice Mints `amount` of GYD token for `account`
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` of GYD token
    function burn(uint256 amount) external;

    /// @notice Burns `amount` of GYD token from `account`
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice IReserve allows an authorized contract to deposit and withdraw tokens
interface IReserve {
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdraw(address indexed from, address indexed token, uint256 amount);

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    /// @notice the address of the reserve managers, the only entities allowed to withdraw
    /// from this reserve
    function managers() external view returns (address[] memory);

    /// @notice Adds a manager, who will be allowed to withdraw from this reserve
    function addManager(address manager) external;

    /// @notice Removes manager
    function removeManager(address manager) external;

    /// @notice Deposits vault tokens in the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function depositToken(address token, uint256 amount) external;

    /// @notice Withdraws vault tokens from the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function withdrawToken(address token, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";
import "Governable.sol";

/// @title IPAMM is the pricing contract for the Primary Market
interface IPAMM {
    /// @notice this event is emitted when the system parameters are updated
    event SystemParamsUpdated(uint64 alphaBar, uint64 xuBar, uint64 thetaBar, uint64 outflowMemory);

    // NB gas optimization, don't need to use uint64
    struct Params {
        uint64 alphaBar; // ᾱ ∊ [0,1]
        uint64 xuBar; // x̄_U ∊ [0,1]
        uint64 thetaBar; // θ̄ ∊ [0,1]
        uint64 outflowMemory; // this is [0,1]
    }

    /// @notice Quotes the amount of GYD to mint for the given USD amount
    /// @param usdAmount the USD value to add to the reserve
    /// @param reserveUSDValue the current USD value of the reserve
    /// @return the amount of GYD to mint
    function computeMintAmount(uint256 usdAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the amount of GYD to mint for the given USD amount.
    /// NB that reserveUSDValue is added here to future proof the implementation
    /// @param usdAmount the USD value to add to the reserve
    /// @return the amount of GYD to mint
    function mint(uint256 usdAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Quotes the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function computeRedeemAmount(uint256 gydAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function redeem(uint256 gydAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Allows for the system parameters to be updated
    function setSystemParams(Params memory params) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "GovernableBase.sol";

contract Governable is GovernableBase {
    constructor(address _governor) {
        governor = _governor;
        emit GovernorChanged(address(0), _governor);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Errors.sol";
import "IGovernable.sol";

contract GovernableBase is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    modifier governanceOnly() {
        require(msg.sender == governor, Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IGovernable
    function changeGovernor(address newGovernor) external override governanceOnly {
        require(address(newGovernor) != address(0), Errors.INVALID_ARGUMENT);
        pendingGovernor = newGovernor;
        emit GovernorChangeRequested(newGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override {
        require(msg.sender == pendingGovernor, Errors.NOT_AUTHORIZED);
        address currentGovernor = governor;
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorChanged(currentGovernor, msg.sender);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGovernable.sol";

/// @notice IFeeBank is where the fees will be stored
interface IFeeBank is IGovernable {
    /// @notice Deposits `amount` of `underlying` in the fee bank
    /// @dev the fee bank should be approved to spend at least `amount` of `underlying`
    function depositFees(address underlying, uint256 amount) external;

    /// @notice Withdraws `amount` of `underlying` from the fee bank to `beneficiary`
    function withdrawFees(
        address underlying,
        address beneficiary,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface ISafetyCheck {
    /// @notice Checks whether a mint operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isMintSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isRedeemSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe and reverts otherwise
    /// This is only called when an actual redeem is performed
    /// The implementation should store any relevant information for the redeem
    function checkAndPersistRedeem(DataTypes.Order memory order) external;

    /// @notice Checks whether a mint operation is safe and reverts otherwise
    /// This is only called when an actual mint is performed
    /// The implementation should store any relevant information for the mint
    function checkAndPersistMint(DataTypes.Order memory order) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IVaultRegistry {
    event VaultRegistered(address indexed vault);
    event VaultDeregistered(address indexed vault);

    /// @notice Returns the metadata for the given vault
    function getVaultMetadata(address vault)
        external
        view
        returns (DataTypes.PersistedVaultMetadata memory);

    /// @notice Get the list of all vaults
    function listVaults() external view returns (address[] memory);

    /// @notice Registers a new vault
    function registerVault(address vault, DataTypes.PersistedVaultMetadata memory) external;

    /// @notice Deregister a vault
    function deregisterVault(address vault) external;

    /// @notice sets the initial price of a vault
    function setInitialPrice(address vault, uint256 initialPrice) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IAssetRegistry {
    /// @notice Emitted when an asset address is updated
    /// If `previousAddress` was 0, it means that the asset was added to the registry
    event AssetAddressUpdated(
        string indexed assetName,
        address indexed previousAddress,
        address indexed newAddress
    );

    /// @notice Emitted when an asset is set as being stable
    event StableAssetAdded(address indexed asset);

    /// @notice Emitted when an asset is unset as being stable
    event StableAssetRemoved(address indexed asset);

    /// @notice Returns the address associated with the given asset name
    /// e.g. "DAI" -> 0x6B175474E89094C44Da98b954EedeAC495271d0F
    function getAssetAddress(string calldata assetName) external view returns (address);

    /// @notice Returns a list of names for the registered assets
    /// The asset are encoded as bytes32 (big endian) rather than string
    function getRegisteredAssetNames() external view returns (bytes32[] memory);

    /// @notice Returns a list of addresses for the registered assets
    function getRegisteredAssetAddresses() external view returns (address[] memory);

    /// @notice Returns a list of addresses contaning the stable assets
    function getStableAssets() external view returns (address[] memory);

    /// @return true if the asset name is registered
    function isAssetNameRegistered(string calldata assetName) external view returns (bool);

    /// @return true if the asset address is registered
    function isAssetAddressRegistered(address assetAddress) external view returns (bool);

    /// @return true if the asset name is stable
    function isAssetStable(address assetAddress) external view returns (bool);

    /// @notice Adds a stable asset to the registry
    /// The asset must already be registered in the registry
    function addStableAsset(address assetAddress) external;

    /// @notice Removes a stable asset to the registry
    /// The asset must already be a stable asset
    function removeStableAsset(address asset) external;

    /// @notice Set the `assetName` to the given `assetAddress`
    function setAssetAddress(string memory assetName, address assetAddress) external;

    /// @notice Removes `assetName` from the registry
    function removeAsset(string memory assetName) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IVaultWeightManager.sol";
import "IUSDPriceOracle.sol";
import "DataTypes.sol";

interface IReserveManager {
    event NewVaultWeightManager(address indexed oldManager, address indexed newManager);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);

    /// @notice Returns a list of vaults including metadata such as price and weights
    function getReserveState() external view returns (DataTypes.ReserveState memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IVaultWeightManager {
    /// @notice Retrieves the weight of the given vault
    function getVaultWeight(address _vault) external view returns (uint256);

    /// @notice Retrieves the weights of the given vaults
    function getVaultWeights(address[] calldata _vaults) external view returns (uint256[] memory);

    /// @notice Sets the weight of the given vault
    function setVaultWeight(address _vault, uint256 _weight) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IUSDPriceOracle {
    /// @notice Quotes the USD price of `tokenAddress`
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param tokenAddress the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IFeeHandler {
    /// @return an order with the fees applied
    function applyFees(DataTypes.Order memory order) external view returns (DataTypes.Order memory);

    /// @return if the given vault is supported
    function isVaultSupported(address vaultAddress) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice ICapAuthentication handles cap authentication for the capped protocol
interface ICapAuthentication {
    /// @return `true` if the account is authenticated
    function isAuthenticated(address account) external view returns (bool);
}