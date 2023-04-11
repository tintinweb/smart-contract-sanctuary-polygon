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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFollowers {

    // Get a list of a users followers
    function getFollowers(address usrAddress, uint256 startFrom) external view returns(string[] memory);

    // Add a follower to a users mapping
    function addFollower(address addressRequester, address addressTarget) external;

    // Remove a follower from a user mapping
    function removeFollower(address addressRequester, address addressTarget) external;

    // Check if a user (requester) is following another user (target)
    function isUserFollowing(address addressRequester, address addressTargetStr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGroups {

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Function to set group details on initial mint
    function setInitialDetails(uint256 _groupID, address _owner, string memory groupName, address setInitialDetails) external;

    // Get group owner address by Group ID
    function getOwnerOfGroupByID(uint256 groupID) external view returns (address);

    // Get a list of members of a group
    function getMembersOfGroupByID(uint256 groupID) external view returns (address[] memory);

    // Check if a user is a member of a group
    function isMemberOfGroupByID(uint256 groupID, address member) external view returns (bool);

    // Get a Group ID from the Group Name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Get a generated Group Address from a Group ID
    function getGroupAddressFromID(uint256 groupID) external view returns (address);

    // Get Group Name from a Group ID
    function getGroupNameFromID(uint256 groupID) external view returns (string memory);

    // Get Group Details from a Group ID
    function getGroupDetailsFromID(uint256 groupID) external view returns (string memory);

    // Get Group URI from a Group ID
    function getGroupURIFromID(uint256 groupID) external view returns (string memory);

    // Get Avatar Colors from a Group ID
    function getGroupColorsFromID(uint256 groupID) external view returns (string[3] memory);

    // Get a group ID from their generated address
    function getGroupIDFromAddress(address groupAddress) external view returns (uint256);

    // Get the owner address of a group by the group address
    function getOwnerOfGroupByAddress(address groupAddress) external view returns (address);

    // Check if a group is available
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Get Group Details
    function groupDetails(uint256 groupID) external view returns (GroupDetails memory);

    // Update Group Ownership on Token transfer (only callable from Token contract overrides)
    function onTransfer(address from, address to, uint256 tokenId) external;
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
    // Get the owner of a token
    function ownerOf(uint256 tokenId) external view returns (address);

    // Get the owner of a token
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/*
    ./UserProfiles.sol
    v0.2
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IFollowers.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/INFT.sol";

contract UserProfiles is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) admins;

    // Approved Wallets
    mapping (address => bool) approved;

    // User Stats
    struct UserStats {
        uint256 postCount;
        uint256 commentCount;
        uint256 followerCount;
        uint256 followingCount;
        uint256 tipsReceived;
        uint256 tipsSent;
    }

    // User Avatar
    struct UserAvatar {
        string avatar;
        string metadata;
        address contractAddress;
        uint256 tokenID;
        uint256 networkID;
    }

    // The User data struct
    struct UserData {
        string handle;
        string location;
        uint256 joinBlock;
        uint256 joinTime;
        UserAvatar userAvatar;
        string uri;
        string bio;
        uint256 followLimit;
        uint256 verified;
        uint256 groupID;
        UserStats userStats;
    }

    // Map the User Address => User Data
    mapping (address => UserData) public usrProfileMap;

    // Set Max URI Length
    uint256 public maxURILength;

    // Set Max Bio Length
    uint256 public maxBioLength;

    // Set Following Limit
    uint256 public maxFollowing;

    // Set the network ID to lookup NFT
    uint256 public networkID;

    // Keep track of the number of users that have joined
    uint256 public joinedUserCount;

    // Link to the KUtils Contracts
    IKUtils public KUtils;

    // Link to the Followers Contract
    IFollowers public Followers;

    // Link to the Groups Contract
    IGroups public Groups;

    // Link to Random NFT Contract
    INFT public NFT;

    // Canary
    string public canary;

    function initialize(address _kutils, uint256 _maxURILength, uint256 _maxBioLength, uint256 _maxFollowing, uint256 _networkID) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;
        approved[msg.sender] = true;

        // Setup link to KUtils
        KUtils = IKUtils(_kutils);

        maxURILength = _maxURILength;
        maxBioLength = _maxBioLength;
        maxFollowing = _maxFollowing;
        networkID = _networkID;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*

    EVENTS

    */

    event logProfileUpdated(address indexed requester, string uri, string avatar, string location, string bio);
    event logNewUser(address indexed requester);
    event logHandleUpdate(address indexed userAddress, string indexed handle);



    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier onlyApproved() {
        require(approved[msg.sender], "Only approved wallets can call this function.");
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

    function updateApproved(address _address, bool status) public onlyAdmins {
        approved[_address] = status;
    }


    /**
    * Updates the maximum length of a Bio and URI to store in a user profile
    * @param _bioLen : the maximum amount of characters to allow for a Bio in a user profile
    * @param _uriLen : the maximum amount of characters to allow for a URI in a user profile
    */
    function updateProfileVars(uint256 _bioLen, uint256 _uriLen, uint256 _networkID) public onlyAdmins {

        maxBioLength = _bioLen;

        maxURILength = _uriLen;

        networkID = _networkID;
    }

    /**
    * Updates the user followers contract in case of updates to functionality
    * @param _followers : the address to make the following checks go to
    */
    function updateContracts(address _followers, address _kutils, address _groups) public onlyAdmins {
        // Update the Followers contract address
        Followers = IFollowers(_followers);

        // Update the KUtils address
        KUtils = IKUtils(_kutils);

        // Update the Groups address
        Groups = IGroups(_groups);
    }



    /*

    Post Handling

    */

    /**
    * Updates the profile by decrementing post count
    * @param posterAddress : the address of the post count to update
    * @param isComment : remove the count from a comment
    */
    function updatePostCount(address posterAddress, bool isComment) public onlyAdmins {
        // Make sure we have a valid address
        require(posterAddress != address(0), "Can't update 0 address");

        if (isComment){
            // Post count must be a number > 0
            require(usrProfileMap[posterAddress].userStats.commentCount > 0, "Invalid Comment Count");

            usrProfileMap[posterAddress].userStats.commentCount -= 1;
        } else {
            // Post count must be a number > 0
            require(usrProfileMap[posterAddress].userStats.postCount > 0, "Invalid Post Count");

            usrProfileMap[posterAddress].userStats.postCount -= 1;
        }
    }


    /**
    * Updates the profile with contracts posted in
    */
    function recordPost(address posterAddress, uint256 tipPerTag, address[] calldata tipReceivers, uint256 isCommentOf) public onlyAdmins {

        // If this poster doesn't have a profile setup yet, start it
        if (usrProfileMap[posterAddress].joinBlock == 0){
            joinUser(posterAddress);
        }

        // Add the post to their total count
        if (isCommentOf > 0){
            usrProfileMap[posterAddress].userStats.commentCount += 1;
        } else {
            usrProfileMap[posterAddress].userStats.postCount += 1;
        }

        // Add the total tips sent to their count
        updateUserTips(posterAddress, 0, (tipPerTag * tipReceivers.length));

        // Update the tips received to each account tagged
        for (uint i=0; i < tipReceivers.length; i++) {
            updateUserTips(tipReceivers[i], tipPerTag, 0);
        }
    }

    // Update a users tips sent / received
    function updateUserTips(address targetAddress, uint256 tipsReceived, uint256 tipsSent) public onlyAdmins {
        usrProfileMap[targetAddress].userStats.tipsSent += tipsSent;
        usrProfileMap[targetAddress].userStats.tipsReceived += tipsReceived;
    }


    /*

    PROFILE

    */


    /**
    * Updates user profile
    * @param _uri : the URI value to update for the sender
    */
    function updateProfile(string calldata location, string calldata avatar, string calldata _uri, string calldata _bio, uint256 groupID) public whenNotPaused {

        address profileAddress = msg.sender;

        // If this is a group validate that they are the owner
        if (groupID > 0){
            profileAddress = Groups.getGroupAddressFromID(groupID);

            // Validate that they are the owner
            require(msg.sender == Groups.getOwnerOfGroupByID(groupID), "You are not the owner of this group");
        }

        // If it's a new user, setup their initial profile
        if (usrProfileMap[profileAddress].joinBlock == 0){
            joinUser(profileAddress);
        }

        // Make sure the Location length is within limits
        require(bytes(location).length <= 25, "Your Location is too long");

        // Make sure the Avatar length is within limits
        require(bytes(avatar).length <= maxURILength, "Your Avatar is too long");

        // Require a Avatar with RCF compliant characters only
        require(KUtils.isValidURI(avatar), "Bad characters in Avatar");

        // Make sure the URI length is within limits
        require(bytes(_uri).length <= maxURILength, "Your URI is too long");

        // Require a URI with RCF compliant characters only
        require(KUtils.isValidURI(_uri), "Bad characters in URI");

        // Make sure the Bio length is within limits
        require(bytes(_bio).length <= maxBioLength, "Your Bio is too long");

        // If they're updating their Avatar to a URI, erase the NFT data
        if (bytes(avatar).length > 4){
            setNFTAvatarInt(profileAddress, '', address(0), 0, 0);
        }

        // Update the URI
        usrProfileMap[profileAddress].uri = _uri;

        // Update the Avatar
        usrProfileMap[profileAddress].userAvatar.avatar = avatar;

        // Update the Location
        usrProfileMap[profileAddress].location = location;

        // Update the Bio
        usrProfileMap[profileAddress].bio = _bio;

        // Emit to the logs for external reference
        emit logProfileUpdated(profileAddress, _uri, avatar, location, _bio);
    }


    // Set an NFT as your profile photo
    function setNFTAsAvatar(address _nftContract, uint256 tokenId, uint256 groupID) public whenNotPaused {
        // Make sure we get a valid address
        require(_nftContract != address(0), "Need the contract address that minted the NFT");

        // Setup link to the NFT contract
        NFT = INFT(_nftContract);

        // Check that they're the owner of the NFT
        require(NFT.ownerOf(tokenId) == msg.sender, "Not the owner of that NFT");

        address profileAddress = groupID > 0 ? Groups.groupDetails(groupID).groupAddress : msg.sender;

        // Save the NFT parts
        setNFTAvatarInt(profileAddress, NFT.tokenURI(tokenId), _nftContract, tokenId, networkID);
    }


    // Set an NFT as your profile photo (only for users / not groups)
    function setAvatar(address profileAddress, string calldata imageURI, address _nftContract, uint256 tokenId, string memory metadata, uint256 _networkID) public whenNotPaused onlyApproved {
        // Save image URI
        usrProfileMap[profileAddress].userAvatar.avatar = imageURI;

        // Save the NFT parts
        setNFTAvatarInt(profileAddress, metadata, _nftContract, tokenId, _networkID);
    }


    // Save all the NFT data for an avatar
    function setNFTAvatarInt(address profileAddress, string memory metadata, address _nftContract, uint256 tokenId, uint256 _networkID) internal {
        // Save the token metadata
        usrProfileMap[profileAddress].userAvatar.metadata = metadata;

        // Save the token contract
        usrProfileMap[profileAddress].userAvatar.contractAddress = _nftContract;

        // Save the token ID
        usrProfileMap[profileAddress].userAvatar.tokenID = tokenId;

        // Save contract network
        usrProfileMap[profileAddress].userAvatar.networkID = _networkID;

        // If setting an NFT as the avatar, wipe out the URI for it
        if (tokenId > 0){
            usrProfileMap[profileAddress].userAvatar.avatar = '';
        }
    }


    // Setup a new groups details for the metadata
    function setupNewGroup(address groupAddress, string memory groupName, uint256 groupID, address _nftContract) public onlyAdmins {
        // Setup link to the NFT contract
        NFT = INFT(_nftContract);

        // Save the token contract
        usrProfileMap[groupAddress].userAvatar.contractAddress = _nftContract;

        // Save the token ID
        usrProfileMap[groupAddress].userAvatar.tokenID = groupID;

        // Save the group name to the profile
        usrProfileMap[groupAddress].handle = groupName;

        // Save the Group ID to the group profile
        usrProfileMap[groupAddress].groupID = groupID;

        // Save the Network ID to the group profile
        usrProfileMap[groupAddress].userAvatar.networkID = networkID;

        // Setup initial profile details for joining
        joinUser(groupAddress);
    }


    // Setup a new user profile
    function joinUser(address newUser) internal {
        usrProfileMap[newUser].followLimit = maxFollowing;
        usrProfileMap[newUser].joinBlock = block.number;
        usrProfileMap[newUser].joinTime = block.timestamp;

        // Add them to the bucket
        Followers.addFollower(newUser, newUser);

        // Update the joined user count
        joinedUserCount++;

        // Emit to the logs for external reference
        emit logNewUser(msg.sender);
    }


    // Update a users handle and verification level
    function updateHandleVerify(address userAddress, string calldata handle, uint256 verified) public onlyAdmins {

        // Update their verified level
        usrProfileMap[userAddress].verified = verified;

        // Update their handle
        usrProfileMap[userAddress].handle = handle;

        // Emit to the logs for external reference
        emit logHandleUpdate(userAddress, handle);
    }


    /**
    * Returns the user details by address in JSON string
    * @param usrAddress : the address to retrieve the details for
    * 0 = Handle
    * 1 = Post Count
    * 2 = Number of users they are following
    * 3 = Number of users that are following them
    * 4 = User Verification level
    * 5 = Avatar URI
    * 6 = Avatar Metadata
    * 7 = Avatar Contract Address
    * 8 = Avatar Network ID
    * 9 = token ID
    * 10 = URI
    * 11 = Bio
    * 12 = Location
    * 13 = Block number when joined
    * 14 = Block timestamp when joined
    * 15 = Limit of number of users they can follow
    * 16 = Total Tips Received
    * 17 = Total Tips Sent
    * 18 = Group ID (0 = user)
    */
    function getUserDetails(address usrAddress) public view whenNotPaused returns(string[] memory){

        // Initialize the return array of users details
        string[] memory userDetails = new string[](19);


        userDetails[0] = usrProfileMap[usrAddress].handle;
        userDetails[1] = KUtils.toString(usrProfileMap[usrAddress].userStats.postCount);
        userDetails[2] = KUtils.toString(usrProfileMap[usrAddress].userStats.followingCount);
        userDetails[3] = KUtils.toString(usrProfileMap[usrAddress].userStats.followerCount);
        userDetails[4] = KUtils.toString(uint256(usrProfileMap[usrAddress].verified));
        userDetails[5] = usrProfileMap[usrAddress].userAvatar.avatar;
        userDetails[6] = usrProfileMap[usrAddress].userAvatar.metadata;
        userDetails[7] = KUtils.addressToString(usrProfileMap[usrAddress].userAvatar.contractAddress);
        userDetails[8] = KUtils.toString(usrProfileMap[usrAddress].userAvatar.networkID);
        userDetails[9] = KUtils.toString(usrProfileMap[usrAddress].userAvatar.tokenID);
        userDetails[10] = usrProfileMap[usrAddress].uri;
        userDetails[11] = usrProfileMap[usrAddress].bio;
        userDetails[12] = usrProfileMap[usrAddress].location;
        userDetails[13] = KUtils.toString(usrProfileMap[usrAddress].joinBlock);
        userDetails[14] = KUtils.toString(usrProfileMap[usrAddress].joinTime);
        userDetails[15] = KUtils.toString(usrProfileMap[usrAddress].followLimit);
        userDetails[16] = KUtils.toString(usrProfileMap[usrAddress].userStats.tipsReceived);
        userDetails[17] = KUtils.toString(usrProfileMap[usrAddress].userStats.tipsSent);
        userDetails[18] = KUtils.toString(usrProfileMap[usrAddress].groupID);

        return userDetails;
    }


    function followUser(address addressRequester, address addressToFollow) public onlyAdmins {
        // If this poster doesn't have a profile setup yet, start it
        if (usrProfileMap[addressRequester].joinBlock == 0){
            joinUser(addressRequester);
        }

        // Check to make sure they're under their max follow count
        require(usrProfileMap[addressToFollow].userStats.followerCount < usrProfileMap[addressRequester].followLimit, "You are following the maximum amount of accounts");

        // Add the follower to the followers lists
        Followers.addFollower(addressRequester, addressToFollow);

        // Add a follower to the users profile follower count
        usrProfileMap[addressToFollow].userStats.followerCount += 1;

        // Update following count by one
        usrProfileMap[addressRequester].userStats.followingCount += 1;
    }


    function unfollowUser(address addressRequester, address addressToUnfollow) public onlyAdmins {

        // Remove the follower from the followers lists
        Followers.removeFollower(addressRequester, addressToUnfollow);

        // Subtract a follower count from the dropped user
        usrProfileMap[addressToUnfollow].userStats.followerCount -= 1;

        // Remove following count by one
        usrProfileMap[addressRequester].userStats.followingCount -= 1;
    }

    function updateMetadata(address _address, string memory _metadata) public onlyAdmins {
        // Save the token metadata
        usrProfileMap[_address].userAvatar.metadata = _metadata;
    }

    function updateCanary(string memory _canary) public onlyAdmins{
        canary = _canary;
    }
}