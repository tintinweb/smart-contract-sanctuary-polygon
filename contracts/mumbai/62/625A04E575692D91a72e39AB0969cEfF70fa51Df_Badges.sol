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

/*

                                   :-++++++++=:.
                                -++-.   ..   .-++-
                              -*=      *==*      -*-
                             ++.                   ++
                            +*     =++:    :+*=.    ++
                           :*.    .: .:    :: :.    .*-
                           =*                        *+
                           =**==+=:            .=*==**+
                .-----:.  =*..--..*=          =*:.--..*=  .:-----:
                 -******= *: *::* .+          +: *-:* :* =******=
                  -*****= *: *..*.              .*. *..* =*****=
                  -****** ++ =**=                =**= =* +*****-
                    :****= ++-:                    :-++ =****:
                   :--:.:+***:-.                  .-:+**+:.:--:.
                 -*-::-+= .**                        +*. =*-::-*-
                 -*-:   +*.+*.  .--            :-.   *+.++   .:*-
                   :*+  :*+--=*=*-=*    --.   *+:*++=--+*-  =*:
                    ++  -*:    +* :*  .*--*.  *- *+    :*=  =*
                    ++  -*=*+  :* :*  .*. *.  *- *:  +*=*=  +*
                    **  .+=*+  :*++*  .*++*.  *+=*:  +*=*.  +*.
                  =*-*=    +*  :*.-*  .*::*.  *-.*-  *+    =*-++.
                 *=   -++- =*  .*=++  .*..*:  ++-*.  *= -++-   =*.
                -*       .  *=   ::   ++  ++   ::   -*.         *=
                -*:..........**=:..:=*+....+*=-..:-**:.........:*=

   ▄█   ▄█▄ ███    █▄      ███        ▄█    █▄    ███    █▄   ▄█       ███    █▄
  ███ ▄███▀ ███    ███ ▀█████████▄   ███    ███   ███    ███ ███       ███    ███
  ███▐██▀   ███    ███    ▀███▀▀██   ███    ███   ███    ███ ███       ███    ███
 ▄█████▀    ███    ███     ███   ▀  ▄███▄▄▄▄███▄▄ ███    ███ ███       ███    ███
▀▀█████▄    ███    ███     ███     ▀▀███▀▀▀▀███▀  ███    ███ ███       ███    ███
  ███▐██▄   ███    ███     ███       ███    ███   ███    ███ ███       ███    ███
  ███ ▀███▄ ███    ███     ███       ███    ███   ███    ███ ███▌    ▄ ███    ███
  ███   ▀█▀ ████████▀     ▄████▀     ███    █▀    ████████▀  █████▄▄██ ████████▀
  ▀                                                          ▀

    @title Badges
    v0.2.1
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/INFT.sol";

contract Badges is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) private admins;

    // Trusted Contracts
    mapping (address => bool) private trustedContracts;

    struct BadgeDetails {
        string badgeName;
        uint256 badgeTypeID;
        string badgeURI;
        address allowedAddress;
        uint256 minimumReq;
        bool status;
        string desc;
        string otherURI;
    }

    // Mapping of all the badge details to a unique ID
    mapping (uint256 => BadgeDetails) badgeDetails;

    // The array to keep track of badges
    uint256[] public badgeIDs;

    // Badge count for indexing
    uint256 public badgeCount;

    // Mapping of all the badges to user address
    mapping (address => uint256[]) userBadges;


    // Link to the KUtils Contracts
    IKUtils public KUtils;



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;
        trustedContracts[msg.sender] = true;

        // Initialize badgeCount to 0
        badgeCount = 0;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);
    }


    /*

    EVENTS

    */

    event addBadgeToApp(string indexed badgeName, string badgeURL, address indexed allowedAddress, string otherURI, string desc);
    event updateBadgeLog(uint256 indexed badgeID, string indexed badgeName, string badgeURL, address indexed allowedAddress, string otherURI);
    event removeBadgeFromApp(uint256 indexed badgeID);
    event enableBadgeLog(uint256 indexed badgeID);
    event disableBadgeLog(uint256 indexed badgeID);
    event addToUser(address indexed addedBy, uint256 indexed badgeID, address indexed userAddress);
    event removeFromUser(address indexed removedBy, uint256 indexed badgeID, address indexed userAddress);


    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyTrustedContracts() {
        require(trustedContracts[msg.sender], "Only trusted contracts can call this function.");
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateContracts(address _kutils) public onlyAdmins {
        // Update the KUtils address
        KUtils = IKUtils(_kutils);
    }

    function updateTrustedContract(address contractAddress, bool status) public onlyAdmins {
        trustedContracts[contractAddress] = status;
    }

    /**
    * @dev Add a badge to the list of badges to be added to users
    * @param badgeName : Name of the badge to add
    * @param badgeURI : The badge image URI
    * @param allowedAddress : Address that is allowed to call to add the badge (0x0 = admin only)
    * @param minimumReq : A minimum amount of tokens required from allowedAddress contract for this badge to be added
    * @param badgeTypeID : A specific string that the contract will verify ownership of by address
    * @param otherURI : Typically a link to the project behind the badge
    * @param desc : General descriptive text about the badge
    */
    function addBadge(string calldata badgeName, string calldata badgeURI, address allowedAddress, uint256 minimumReq, uint256 badgeTypeID, string calldata otherURI, string calldata desc) public whenNotPaused onlyAdmins {

        // Increase badgeCount
        badgeCount++;

        // Add the badge to the list of available badges
        badgeIDs.push(badgeCount);

        // Add the badge details to the mapping
        badgeDetails[badgeCount].badgeName = badgeName;
        badgeDetails[badgeCount].badgeTypeID = badgeTypeID;
        badgeDetails[badgeCount].badgeURI = badgeURI;
        badgeDetails[badgeCount].otherURI = otherURI;
        badgeDetails[badgeCount].desc = desc;
        badgeDetails[badgeCount].allowedAddress = allowedAddress;
        badgeDetails[badgeCount].minimumReq = minimumReq;
        badgeDetails[badgeCount].status = true;

        // Log the adding of the badge
        emit addBadgeToApp(badgeName, badgeURI, allowedAddress, otherURI, desc);
    }


    /**
    * @dev Update a badge
    * @param badgeID : The ID of the badge to update
    * @param badgeName : Name of the badge to add
    * @param badgeURI : The badge image URI
    * @param allowedAddress : Address that is allowed to call to add the badge (0x0 = admin only)
    * @param minimumReq : A minimum amount of tokens required from allowedAddress contract for this badge to be added
    * @param badgeTypeID : A specific string that the contract will verify ownership of by address
    * @param otherURI : Typically a link to the project behind the badge
    * @param desc : General descriptive text about the badge
    */
    function updateBadge(uint256 badgeID, string calldata badgeName, string calldata badgeURI, address allowedAddress, uint256 minimumReq, uint256 badgeTypeID, string calldata otherURI, string calldata desc) public whenNotPaused onlyAdmins {

        // Add the badge details to the mapping
        badgeDetails[badgeID].badgeName = badgeName;
        badgeDetails[badgeID].badgeTypeID = badgeTypeID;
        badgeDetails[badgeID].badgeURI = badgeURI;
        badgeDetails[badgeID].otherURI = otherURI;
        badgeDetails[badgeID].desc = desc;
        badgeDetails[badgeID].allowedAddress = allowedAddress;
        badgeDetails[badgeID].minimumReq = minimumReq;

        // Log the updating of the badge
        emit updateBadgeLog(badgeID, badgeName, badgeURI, allowedAddress, otherURI);
    }




    /**
    * @dev Remove a badge from the list of badges to be added to users
    * @param badgeID : The ID of the badge to remove
    */
    function removeBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Get the index of the badgeID
        uint256 place = 0;
        bool ok = false;
        for (uint i=0; i < badgeIDs.length; i++) {
            if (badgeIDs[i] == badgeID){
                place = i;
                ok = true;
                break;
            }
        }

        // Make sure this badge exists
        require(ok, "User does not have badge");

        // Swap the last entry with this one
        badgeIDs[place] = badgeIDs[badgeIDs.length-1];

        // Remove the last element
        badgeIDs.pop();

        // Disable the badge details
        badgeDetails[badgeID].status = false;

        // Log the adding of the badge
        emit removeBadgeFromApp(badgeID);
    }

    /**
    * @dev Enable an existing badge
    * @param badgeID : The ID of the badge to enable
    */
    function enableBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Make sure this badge exists
        require(badgeDetails[badgeID].status == false, "Invalid badge ID or not disabled");

        // Enable the badge
        badgeDetails[badgeID].status = true;

        // Log the adding of the badge
        emit enableBadgeLog(badgeID);
    }

    /**
    * @dev Disable an existing badge
    * @param badgeID : The ID of the badge to disable
    */
    function disableBadge(uint256 badgeID) public whenNotPaused onlyAdmins {

        // Make sure this badge exists
        require(badgeDetails[badgeID].status == true, "Invalid badge ID or not enabled");

        // Enable the badge
        badgeDetails[badgeID].status = false;

        // Log the adding of the badge
        emit disableBadgeLog(badgeID);
    }


    /*

    EXTERNAL CONTRACT FUNCTIONS

    */

    /**
    * @dev Add a badge to a user from the allowed address of the badge or by an admin
    * @param userAddress : Wallet address of the user to add the badge to
    * @param badgeID : The badge ID
    */
    function addBadgeToUser(address userAddress, uint256 badgeID) public whenNotPaused {

        // Initialize that it's ok to add badge
        bool ok = true;

        // Check to see if if this user / contract is allowed to add this badge ID to users and it's active
        require((badgeDetails[badgeID].allowedAddress == msg.sender || admins[msg.sender]) && badgeDetails[badgeID].status, "Not adding.");

        // Check to make sure they don't already have this badge
        for (uint i=0; i < userBadges[userAddress].length; i++) {
            if (userBadges[userAddress][i] == badgeID){
                ok = false;
                break;
            }
        }

        // If they don't already have it (it's ok), then add it
        if (ok){

            // Add the badge to their profile
            userBadges[userAddress].push(badgeID);

            // Log the adding of the badge
            emit addToUser(msg.sender, badgeID, userAddress);
        }
    }

    /**
    * @dev Remove a badge from a user by the allowed address of the badge or by an admin
    * @param userAddress : Wallet address of the user to remove the badge from
    * @param badgeID : The badge ID
    */
    function removeBadgeFromUser(address userAddress, uint256 badgeID) public whenNotPaused {

        // Check to see if if this user / contract is allowed to remove this badge ID to users and it's active
        require(userAddress == msg.sender || badgeDetails[badgeID].allowedAddress == msg.sender || admins[msg.sender], "Nope.");

        // Get the index of the badgeID
        uint256 place = 0;
        bool ok = false;
        for (uint i=0; i < userBadges[userAddress].length; i++) {
            if (userBadges[userAddress][i] == badgeID){
                place = i;
                ok = true;
                break;
            }
        }

        // Make sure this badge exists
        if (ok) {

            // Swap the last entry with this one
            userBadges[userAddress][place] = userBadges[userAddress][userBadges[userAddress].length-1];

            // Remove the last element
            userBadges[userAddress].pop();

            // Log the adding of the badge
            emit removeFromUser(msg.sender, badgeID, userAddress);
        }
    }


    /*

    PUBLIC FUNCTIONS

    */


    /**
    * @dev Check to see if the requesting user qualifies for a badge
    * @param badgeID : The badge ID to check to see if they qualify to be added
    */
    function verifyBadge(uint256 badgeID) public whenNotPaused {

        // Get the address for this badge
        address badgeContract = badgeDetails[badgeID].allowedAddress;

        // Verify that this is a verifiable badge
        require(badgeContract != address(0), "Badge not verifiable");

        // Build interface to link to NFT contract
        INFT NFT;

        // Setup link to the NFT contract
        NFT = INFT(badgeContract);

        // Check that they have the minimum amount required if set
        require(NFT.balanceOf(tx.origin) >= badgeDetails[badgeID].minimumReq, "Not enough owned");

        // If they passed a badge type, check for it in the contract
        if (badgeDetails[badgeID].badgeTypeID > 0){
            require(NFT.kuthuluVerifyBadgeType(badgeDetails[badgeID].badgeTypeID), "You don't have that badge");
        }

        // They meet the requirements so add the badge to their profile
        userBadges[tx.origin].push(badgeID);
    }

    /**
    * @dev return a list of users badge IDs
    * @param userAddress : The address of the user to get badges for
    */
    function getUserBadges(address userAddress) public view whenNotPaused returns(uint256[] memory) {
        return userBadges[userAddress];
    }

    /**
    * @dev Get badge details
    * @param badgeID : The ID of the badge to get the details for
    * @dev 0 = Badge Name
    * @dev 1 = Badge URI for the thumbnail
    * @dev 2 = Contract address that is allowed to add and remove badges to members dynamically
    * @dev 3 = Minimum quantity of NFTs / tokens required to be owned to qualify for the badge
    * @dev 4 = Status (0 = Disabled / 1 = Enabled)
    * @dev 5 = Badge Type ID
    * @dev 6 = Other URI : generally a URI to the location of the project behind it
    * @dev 7 = Description about the badge
    */
    function getBadgeDetails(uint256 badgeID) public view whenNotPaused returns(string[] memory) {
        // Initialize the return array of badge details
        string[] memory thisBadge = new string[](8);

        thisBadge[0] = badgeDetails[badgeID].badgeName;
        thisBadge[1] = badgeDetails[badgeID].badgeURI;
        thisBadge[2] = KUtils.addressToString(badgeDetails[badgeID].allowedAddress);
        thisBadge[3] = KUtils.toString(badgeDetails[badgeID].minimumReq);
        thisBadge[4] = badgeDetails[badgeID].status ? "active" : "disabled";
        thisBadge[5] = KUtils.toString(badgeDetails[badgeID].badgeTypeID);
        thisBadge[6] = badgeDetails[badgeID].otherURI;
        thisBadge[7] = badgeDetails[badgeID].desc;

        return thisBadge;
    }

    /**
    * @dev get a list of all the badge IDs
    */
    function getBadges() public view whenNotPaused returns(uint256[] memory) {
        return badgeIDs;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKUtils {
    // Append a string
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) external pure returns (string memory);

    // Convert an address to a string
    function addressToString(address addr) external pure returns (string memory);

    // Is a valid URI
    function isValidURI(string memory str) external pure returns (bool);

    // Is a valid string
    function isValidString(string memory str) external pure returns (bool);

    // Is a valid string for group names
    function isValidGroupString(string memory str) external pure returns (bool);

    // Convert a uint to string
    function toString(uint256 value) external pure returns (string memory);

    // Returns a lowercase version of the string provided
    function _toLower(string memory str) external pure returns (string memory);

    // Check if 2 strings are the same
    function stringsEqual(string memory a, string memory b) external pure returns (bool);

    // Check literal string length (10x gas cost)
    function strlen(string memory s) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface INFT {

    // Get the amount of tokens they own
    function balanceOf(address owner) external view returns (uint256);

    // Get the owner of a token
    function ownerOf(uint256 tokenId) external view returns (address);

    // Get the owner of a token
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // Return if a user owns a specific badge type
    function kuthuluVerifyBadgeType(uint256 badgeTypeID) external view returns (bool);
}