/**
 *Submitted for verification at polygonscan.com on 2022-11-03
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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


// File contracts/ERC2771ContextUpgradeable.sol



// OpenZeppelin Contracts v4.3.2 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.4;

// import {Initializable} from "../proxy/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    address public trustedForwarder;

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        trustedForwarder = tForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}


// File contracts/OwnableUpgradeable.sol



// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.4;

// import {Initializable} from "../proxy/Initializable.sol";

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

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address trustedForwarder) internal initializer {
        __Ownable_init_unchained();
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(owner() == _msgSender(), "ONA");
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
        require(newOwner != address(0), "INA");
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

    function updateTrustedForwarder(
        address _newForwarder
    ) external onlyOwner {
        trustedForwarder = _newForwarder;
    }

    uint256[49] private __gap;
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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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


// File contracts/UnifarmAccountsUpgradeable.sol


pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";



contract UnifarmAccountsUpgradeable is Initializable, OwnableUpgradeable {
    // --------------------- DAPPS STORAGE -----------------------

    struct Role {
        bool sendNotificationRole;
        bool addAdminRole;
    }
    struct SecondaryWallet {
        address account;
        string encPvtKey;
        string publicKey;
    }

    struct Dapp {
        string appName;
        uint256 appId;
        address appAdmin; //primary
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string[] appScreenshots; // upto 5
        string[] appCategory; // upto 7
        string[] appTags; // upto 7
        bool isVerifiedDapp; // true or false
    }

    struct Notification {
        uint256 appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint256 timestamp;
    }
    mapping(uint256 => Dapp) public dapps;

    // all dapps count
    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

    mapping(address => Notification[]) public notificationsOf;
    // dappID => dapp

    mapping(address => Role) public roleOfAddress;

    // dappId => address => bool(true/false)
    mapping(uint256 => mapping(address => bool)) public isSubscribed;

    // -------------------- WALLET STORAGE -----------------------

    // userAddress => dappID => Wallet
    mapping(address => SecondaryWallet) public userWallets;
    // secondary to primary wallet mapping to get primary wallet from secondary
    mapping(address => address) public getPrimaryFromSecondary;

    modifier onlySuperAdmin() {
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
        _;
    }
    modifier isValidSender(address from) {
        require(
            _msgSender() == from ||
                _msgSender() == getSecondaryWalletAccount(from),
            "INVALID_SENDER"
        );
        _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(uint256 appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()].addAdminRole == true,
            "INVALID_SENDER"
        );
        _;
    }
    modifier superAdminOrDappAdminOrSendNotifRole(uint256 appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()].sendNotificationRole == true,
            "INVALID_SENDER"
        );
        _;
    }

    event NewAppRegistered(uint256 appID, address appAdmin, string appName);

    event AppAdmin(
        uint256 appID,
        address appAdmin,
        address admin,
        uint8 role
    );

    event AppSubscribed(uint256 appID, address subscriber);

    event AppUnSubscribed(uint256 appID, address subscriber);

    event NewNotification(
        uint256 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta
    );

    function __UnifarmAccounts_init(address _trustedForwarder)
        public
        initializer
    {
        __Ownable_init(_trustedForwarder);
        // __Pausable_init();
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        string memory _appName,
        address _appAdmin, //primary
        string memory _appIcon,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags
    ) external {
        require(_appScreenshots.length < 6, "surpassed image limit");
        require(_appCategory.length < 8, "surpassed image limit");
        require(_appTags.length < 8, "surpassed image limit");

        uint256 _appID = dappsCount;
        Dapp memory dapp = Dapp({
            appName: _appName,
            appId: _appID,
            appAdmin: _appAdmin,
            appIcon: _appIcon,
            appSmallDescription: _appSmallDescription,
            appLargeDescription: _appLargeDescription,
            appScreenshots: _appScreenshots,
            appCategory: _appCategory,
            appTags: _appTags,
            isVerifiedDapp: false
        });
        dapps[_appID] = dapp;

        emit NewAppRegistered(_appID, _appAdmin, _appName);
        dappsCount++;
    }

    function subscribeToDapp(
        address user,
        uint256 appID,
        bool subscriptionStatus
    ) external isValidSender(user) {
        require(appID <= dappsCount, "INVALID DAPP ID");
        require(dapps[appID].isVerifiedDapp == true, "UNVERIFIED DAPP");
        isSubscribed[appID][user] = subscriptionStatus;

        if (subscriptionStatus) {
            emit AppSubscribed(appID, user);
        } else {
            emit AppUnSubscribed(appID, user);
        }
    }

    function appVerification(uint256 appID, bool verificationStatus)
        external
        onlySuperAdmin
    {
        require(appID <= dappsCount, "INVALID DAPP ID");
        if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            verificationStatus
        ) {
            verifiedDappsCount++;
            dapps[appID].isVerifiedDapp = verificationStatus;

        } else if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            !verificationStatus
        ) {
            verifiedDappsCount--;
            dapps[appID].isVerifiedDapp = verificationStatus;
        }
    }

    function getDappAdmin(uint256 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------

    function addAppAdmin(
        uint256 appID,
        address admin,
        uint8 _role // 0 meaning only notif, 1 meaning only add admin, 2 meaning both
    ) external superAdminOrDappAdminOrAddedAdmin(appID) {
        require(_role < 3, "INAVLID ROLE");
        if (_role == 0) {
            roleOfAddress[admin].sendNotificationRole == true;
            roleOfAddress[getSecondaryWalletAccount(admin)]
                .sendNotificationRole == true;
        } else if (_role == 1) {
            roleOfAddress[admin].addAdminRole == true;
            roleOfAddress[getSecondaryWalletAccount(admin)].addAdminRole ==
                true;
        } else if (_role == 2) {
            roleOfAddress[admin].addAdminRole == true;
            roleOfAddress[getSecondaryWalletAccount(admin)].addAdminRole ==
                true;
            roleOfAddress[admin].sendNotificationRole == true;
            roleOfAddress[getSecondaryWalletAccount(admin)]
                .sendNotificationRole == true;
        }
        emit AppAdmin(appID, getDappAdmin(appID), admin, _role);
    }

    // primary wallet address. ??
    function sendAppNotification(
        uint256 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta
    ) external superAdminOrDappAdminOrSendNotifRole(_appId) {
        require(isSubscribed[_appId][walletAddress] == true);
        Notification memory notif = Notification({
            appID: _appId,
            walletAddressTo: walletAddress,
            message: _message,
            buttonName: buttonName,
            cta: _cta,
            timestamp: block.timestamp
        });

        notificationsOf[walletAddress].push(notif);
        emit NewNotification(_appId, walletAddress, _message, buttonName, _cta);
    }

    function createWallet(
        address _account,
        string calldata _encPvtKey,
        string calldata _publicKey
    ) external {
        require(
            userWallets[_msgSender()].account == address(0),
            "ACCOUNT_ALREADY_EXISTS"
        );
        SecondaryWallet memory wallet = SecondaryWallet({
            account: _account,
            encPvtKey: _encPvtKey,
            publicKey: _publicKey
        });
        userWallets[_msgSender()] = wallet;
        getPrimaryFromSecondary[_account] == _msgSender();
    }
     function getNotificationsOf(address user) external view returns(Notification[] memory){
        return notificationsOf[user];
    }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        return userWallets[_account].account;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
}


// File contracts/MessagingUpgradeable.sol


pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
// import "./ERC2771ContextUpgradeable.sol";
// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// import "./ERC2771ContextUpgradeable.sol";

contract MessagingUpgradeable is Initializable, OwnableUpgradeable {

    uint256 public dappId;     // dappID for this decentralized messaging application (should be fixed)
    UnifarmAccountsUpgradeable public unifarmAccounts;

    // ---------------- ATTACHMENTS STORAGE ---------------

    struct Attachment {
        string location;
        string fileType;
        address receiver;
        string rsaKeyReceiver;       // encrypted using receiver's public key
        string rsaKeySender;         // encrypted using sender's public key
        bool isEncrypted;
    }

    // dataID => attachment
    mapping(uint256 => Attachment) public attachments;

    uint256 public dataIdsCount;

    mapping(address => uint256[]) public receiverAttachments;   // to get all the files received by the user (gdrive analogy)

    // ------------------ MESSAGE STORAGE ------------------

    struct Message {
        address sender;
        string textMessageReceiver;      // encrypted using receiver's public key
        string textMessageSender;        // encrypted using sender's public key
        uint256[] attachmentIds;
        bool isEncrypted;                // to check if the message has been encrypted
        uint256 timestamp;
    }

    // from => to => messageID
    mapping(address => mapping(address => uint256)) public messageIds;

    // to keep a count of all the 1 to 1 communication
    uint256 public messageIdCount;

    // messageID => messages[]
    mapping(uint256 => Message[]) public messages;

    // ------------------ WHITELISTING STORAGE ------------------

    mapping(address => bool) public isWhitelisting;

    // from => to => isWhitelisted
    mapping(address => mapping(address => bool)) public isWhitelisted;

    // ------------------ SPAM RPOTECTION STORAGE ------------------

    mapping(address => bool) public isSpamProtecting;

    address public ufarmToken;
    address public spamTokensAdmin;

    // set by dappAdmin
    address[] public spamProtectionTokens;

    struct SpamProtectionToken {
        address token;
        uint256 amount;     // amount to pay in wei for message this user
    }

    // userAddress => tokens
    mapping(address => SpamProtectionToken[]) public userSpamTokens;

    struct TokenTransferMapping {
        address token;
        uint256 amount;
        uint256 startTimestamp;
    }

    // from => to => TokenTransferMapping
    mapping(address => mapping(address => TokenTransferMapping)) public tokenTransferMappings;

    event MessageSent(
        address indexed from,
        address indexed to,
        uint256 indexed messageId,
        string textMessageReceiver,
        string textMessageSender,
        uint256[] attachmentIds,
        bool isEncrypted,
        uint256 timestamp
    );

    event AddedToWhitelist(
        address indexed from,
        address indexed to
    );

    event RemovedFromWhitelist(
        address indexed from,
        address indexed to
    );

    modifier isValidSender(
        address _from
    ) {
        _isValidSender(_from);
        _;
    }

    function _isValidSender(
        address _from
    ) internal view {
        // _msgSender() should be either primary (_from) or secondary wallet of _from
        require(_msgSender() == _from || 
                _msgSender() == unifarmAccounts.getSecondaryWalletAccount(_from), "INVALID_SENDER");
    }

    function __Messaging_init(
        uint256 _dappId,
        UnifarmAccountsUpgradeable _unifarmAccounts,
        address _ufarmToken,
        address _spamTokensAdmin,
        address _trustedForwarder
    ) public initializer {
        __Ownable_init(_trustedForwarder);
        // __Pausable_init();
        // __ERC2771ContextUpgradeable_init(_trustedForwarder);
        // _trustedForwarder = trustedForwarder;
        dappId = _dappId;
        unifarmAccounts = _unifarmAccounts;
        ufarmToken = _ufarmToken;
        spamTokensAdmin = _spamTokensAdmin;
    }

    // ------------------ ATTACHMENT FUNCTIONS ----------------------

    function writeData(
        string memory _location,
        string memory _fileType,
        address _receiver,
        string memory _rsaKeyReceiver,
        string memory _rsaKeySender,
        bool _isEncrypted
    ) internal returns (uint256) {
        uint256 dataId = dataIdsCount++;
        Attachment memory attachment = Attachment({
            location: _location,
            fileType: _fileType,
            receiver: _receiver,
            rsaKeyReceiver: _rsaKeyReceiver,
            rsaKeySender: _rsaKeySender,
            isEncrypted: _isEncrypted
        });
        attachments[dataId] = attachment;
        receiverAttachments[_receiver].push(dataId);
        return dataId;
    }

    // -------------------- MESSAGE FUNCTIONS -----------------------

    // function to send message when receiver's spam protection is OFF
    function newMessage(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted
    ) public isValidSender(_from) {
        bool isSendWhitelisted = isWhitelisted[_from][_to];
        // bool isReceiveWhitelisted = isWhitelisted[_to][_msgSender()];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if(isWhitelisting[_to])
            require(isSendWhitelisted, "NOT_WHITELISTED");

        _createMessageRecord(_from, _to, _textMessageReceiver, _textMessageSender, _attachments, _isEncrypted);
    }

    // function to send message when receiver's spam protection is ON
    function newMessageOnSpamProtection(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted,
        ERC20 _token
    ) public isValidSender(_from) {
        bool isSendWhitelisted = isWhitelisted[_from][_to];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if(isWhitelisting[_to])
            require(isSendWhitelisted, "NOT_WHITELISTED");

        // check if receiver has spam protection enabled
        if(isSpamProtecting[_to] && !isSendWhitelisted) {
            _createSpamRecord(_from, _to, _token);
        }

        _createMessageRecord(_from, _to, _textMessageReceiver, _textMessageSender, _attachments, _isEncrypted);
    }

    function _createMessageRecord(
        address _from,
        address _to,
        string memory _textMessageReceiver,
        string memory _textMessageSender,
        Attachment[] memory _attachments,
        bool _isEncrypted
    ) internal {
        // to check if tokenTransferMappings record exists
        if(tokenTransferMappings[_to][_from].startTimestamp > 0) {
            TokenTransferMapping memory tokenTransferMapping = tokenTransferMappings[_to][_from];
            delete tokenTransferMappings[_to][_from];
            
            ERC20(tokenTransferMapping.token).transfer(_from, tokenTransferMapping.amount);
        }

        uint len = _attachments.length;
        uint[] memory attachmentIds = new uint[](len);
        for (uint i = 0; i < len; i++) {
            uint256 dataId = writeData(
                _attachments[i].location, 
                _attachments[i].fileType, 
                _attachments[i].receiver, 
                _attachments[i].rsaKeyReceiver, 
                _attachments[i].rsaKeySender, 
                _attachments[i].isEncrypted
            );
            attachmentIds[i] = dataId;
        }

        Message memory message = Message({
            sender: _from,
            textMessageReceiver: _textMessageReceiver,
            textMessageSender: _textMessageSender,
            isEncrypted: _isEncrypted,
            attachmentIds: attachmentIds,
            timestamp: block.timestamp
        });

        uint256 messageId = messageIds[_from][_to];
        if(messageId == 0) {
            messageId = ++messageIdCount;
            messageIds[_from][_to] = messageId;
            messageIds[_to][_from] = messageId;
            emit AddedToWhitelist(_from, _to);
            emit AddedToWhitelist(_to, _from);
        }
        messages[messageId].push(message);
        
        emit MessageSent(_from, _to, messageId, _textMessageReceiver, _textMessageSender, attachmentIds, _isEncrypted, block.timestamp);
    } 

    function _createSpamRecord(
        address _from,
        address _to,
        ERC20 _token
    ) internal {
        uint256 amount = getTokenAmountToSend(_from, address(_token));
        require(amount > 0, "INVALID_TOKEN");
        uint256 adminAmount;
        if(address(_token) != ufarmToken) {
            adminAmount = amount / 5;   // 20% goes to admin
            amount -= adminAmount;
            _token.transferFrom(_from, spamTokensAdmin, adminAmount);
        }
        _token.transferFrom(_from, address(this), amount);
        tokenTransferMappings[_from][_to] = TokenTransferMapping({
            token: address(_token),
            amount: amount,
            startTimestamp: block.timestamp
        });

        isWhitelisted[_from][_to] = true;
        emit AddedToWhitelist(_from, _to);
        
        isWhitelisted[_to][_from] = true;
        emit AddedToWhitelist(_to, _from);
    }

    function getTokenAmountToSend(
        address _account,
        address _token
    ) public view returns (uint256) {
        SpamProtectionToken[] memory spamTokens = userSpamTokens[_account];
        for (uint256 i = 0; i < spamTokens.length; i++) {
            if(spamTokens[i].token == _token)
                return spamTokens[i].amount;
        }
        return 0;
    }

    // function getMessageForReceiver(
    //     address receiver,
    //     uint256 limit, 
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userReceivedMessages[receiver].length;
    //     Message[] memory receivedMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         receivedMessages[i] = userReceivedMessages[receiver][i];
    //     }
    //     return receivedMessages;
    // }

    // function getMessageForSender(
    //     address sender,
    //     uint256 limit, 
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userSentMessages[sender].length;
    //     Message[] memory sentMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         sentMessages[i] = userSentMessages[sender][i];
    //     }
    //     return sentMessages;
    // }

    function getCommunication(
        address _from,
        address _to
    ) public view returns (Message[] memory) {
        uint256 messageId = messageIds[_from][_to];
        return messages[messageId];
    }

    // ------------------ SPAM RPOTECTION FUNCTIONS ------------------

    function adminAddPaymentToken(
        address _token
    ) external {
        require(_msgSender() == unifarmAccounts.getDappAdmin(dappId), "ONLY_DAPP_ADMIN");
        require(_token != address(0), "INVALID_ADDRESS");

        uint len = spamProtectionTokens.length;
        for(uint256 i = 0; i < len; i++) {
            require(spamProtectionTokens[i] != _token, "TOKEN_ALREADY_EXISTS");
        }
        spamProtectionTokens.push(_token);
    }

    function adminRemovePaymentToken(
        address _token
    ) external {
        require(_msgSender() == unifarmAccounts.getDappAdmin(dappId), "ONLY_DAPP_ADMIN");
        require(_token != address(0), "INVALID_ADDRESS");
        
        uint len = spamProtectionTokens.length;
        for(uint256 i = 0; i < len; i++) {
            if(spamProtectionTokens[i] == _token) {
                if(i < len-1) {
                    spamProtectionTokens[i] = spamProtectionTokens[len-1];
                }
                spamProtectionTokens.pop();
                return;
            }
        }
        revert("NO_TOKEN");
    }

    // to add a new token or update the price of alreayd added token
    function addSpamProtectionToken(
        address _account,
        address _token,
        uint256 _amount
    ) external isValidSender(_account) {
        require(_token != address(0), "INVALID_ADDRESS");
        require(_amount > 0, "ZERO_AMOUNT");

        uint len = spamProtectionTokens.length;
        uint8 count;
        for(uint256 i = 0; i < len; i++) {
            // token should be allowed by the admin
            if(spamProtectionTokens[i] == _token) {
                count = 1;
                break;
            }
        }
        require(count == 1, "INVALID_TOKEN");
        
        len = userSpamTokens[_account].length;
        for(uint256 i = 0; i < len; i++) {
            // if token already exists then update its price and return
            if(userSpamTokens[_account][i].token == _token) {
                userSpamTokens[_account][i].amount = _amount;
                return;
            }
        }

        // If token doesn't exist then add it
        SpamProtectionToken memory token = SpamProtectionToken({
            token: _token,
            amount: _amount
        });
        userSpamTokens[_account].push(token);
    }
    
    function removeSpamProtectionToken(
        address _account,
        address _token
    ) external isValidSender(_account) {
        require(_token != address(0), "INVALID_ADDRESS");
        
        uint len = userSpamTokens[_account].length;
        for(uint256 i = 0; i < len; i++) {
            if(userSpamTokens[_account][i].token == _token) {
                if(i < len-1) {
                    userSpamTokens[_account][i] = userSpamTokens[_account][len-1];
                }
                userSpamTokens[_account].pop();
                return;
            }
        }
        revert("NO_TOKEN");
    }

    function setIsSpamProtecting(
        address _account,
        bool _isSpamProtecting
    ) external isValidSender(_account) {
        isSpamProtecting[_account] = _isSpamProtecting;
    }

    function getRefund(
        address _user,
        address _to
    ) external isValidSender(_user) {
        // tokenTransferMappings record should exist
        require(tokenTransferMappings[_user][_to].startTimestamp > 0, "NO_RECORD");
        // 7 days time must have passed
        require(block.timestamp > tokenTransferMappings[_user][_to].startTimestamp + 7 days, "TIME_PENDING");
        
        TokenTransferMapping memory tokenTransferMapping = tokenTransferMappings[_user][_to];
        delete tokenTransferMappings[_user][_to];
        ERC20(tokenTransferMapping.token).transfer(_user, tokenTransferMapping.amount);
    }

    // ------------------ WHITELISTING FUNCTIONS ------------------

    function setIsWhitelisting(
        address _account,
        bool _isWhitelisting
    ) external isValidSender(_account) {
        isWhitelisting[_account] = _isWhitelisting;
    }

    function addWhitelist(
        address _user,
        address _account
    ) external isValidSender(_user) {
        isWhitelisted[_account][_user] = true;
        emit AddedToWhitelist(_account, _user);
    }

    function removeWhitelist(
        address _user,
        address _account
    ) external isValidSender(_user) {
        isWhitelisted[_account][_user] = false;
        emit RemovedFromWhitelist(_account, _user);
    }

}