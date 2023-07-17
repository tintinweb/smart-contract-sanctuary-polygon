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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlocking {

    // Update the whitelist
    function updateWhitelist(address toToggle) external;

    // Update the blacklist
    function updateBlacklist(address toToggle) external;

    // Check if a requester is allowed to interact with target
    function isAllowed(address requesterAddress, address targetAddress) external view returns (bool);

    // Enable or disable whitelist functionality for self
    function toggleWhiteList() external;

    // Clear our a whitelist or blacklist with a single call
    function clearList(bool clearWhitelist) external;
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
pragma solidity ^0.8.0;

interface IGroupPosts {

    // Get a list of a posts in a group
    function getMsgIDsByGroupID(uint256 groupID, uint256 startFrom) external view returns(uint256[] memory);

    // Remove a post from a group mapping
    function addPost(uint256 msgID, uint256[] calldata groupIDs) external;

    // Add a post to a groups mapping
    function removePost(uint256 msgID, uint256[] calldata groupIDs) external;
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
    function setInitialDetails(uint256 _groupID, address owner, string memory groupName, address setInitialDetails) external;

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
pragma solidity ^0.8.0;

interface IHashtags {

    // Get Message IDs from a hashtag
    function getMsgIDsFromHashtag(string memory hashtag, uint256 startFrom) external view returns(uint256[] memory);

    // Remove a hashtag from a message
    function removeHashtags(uint256 msgID, string[] calldata hashtagsToToggle) external;

    // Add a hashtag to a message
    function addHashtags(uint256 msgID, string[] memory hashtagsToToggle) external;
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
pragma solidity ^0.8.0;

interface IMessageFormat {
    // Build a JSON string from the message data
    // msgData[]
    // 0 = msgID
    // 1 = time
    // 2 = block
    // 3 = tip
    // 4 = paid
    // 5 = postByContract
    // 6 = likes
    // 7 = reposts
    // 8 = comments
    // 9 = isCommentOf
    // 10 = isRepostOf
    // 11 = commentLevel
    // 12 = asGroup
    // 13 = ERC20 Tip Amount
    // 14 = Comment ID
    function buildMsg(uint256[] memory msgData, string memory message, address[2] memory postedBy, string[] memory hashtags, address[] memory taggedAccounts,string memory uri, uint256[] memory inGroups, address tipContract) external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPosts {

    // Get a list of a users posts or posts of a message
    function getMsgIDsByAddress(address usrAddress, uint256 startFrom, uint256[] calldata whatToGet) external view returns(uint256[] memory);

    // Remove a post from a user mapping
    function addPost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;

    // Add a post to a users mapping
    function removePost(uint256 msgID, address addressPoster, uint256 isCommentOf, uint256 isRepostOf) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITagged {

    // Get a list of a messages a user is tagged in
    function getTaggedMsgIDs(address usrAddress, uint256 startFrom) external view returns(uint256[] memory);

    // Add a tag to a users post
    function removeTags(uint256 msgID, address[] memory addressesTagged) external;

    // Remove a tag from a users post
    function addTags(uint256 msgID, address[] memory addressTagged) external;
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

    @title MessageData
    v0.3

    KUTHULU : https://www.KUTHULU.xyz
    A project by DOOM Labs (https://DOOMLabs.io)
    The first truly decentralized social framework.
    Built for others to build upon and share freedom of expression.
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IHashtags.sol";
import "./interfaces/ITagged.sol";
import "./interfaces/IPosts.sol";
import "./interfaces/IGroupPosts.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IMessageFormat.sol";
import "./interfaces/IFollowers.sol";
import "./interfaces/IBlocking.sol";

contract MessageData is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) public admins;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;

    // Set the Bucket Key and Count
    uint256[2] public buckets;

    // Message Stats
    struct MsgStats {
        int likes;
        int comments;
        uint256 totalInThread;
        int reposts;
        uint256 tipsReceived;
        address tipContract;
        uint256 tipERC20Amount;
        uint postByContract;
        uint256 time;
        uint256 block;
    }


    // The Message data struct
    struct MsgData {
        uint msgID;
        address[2] postedBy;
        string message;
        uint256 paid;      // May not need this
        string[] hashtags;
        address[] taggedAccounts;
        uint256 asGroup;
        uint256[] inGroups;
        string uri;
        uint256 commentLevel;
        uint256 isCommentOf;
        uint256 isRepostOf;
        uint256 commentID;
        MsgStats msgStats;
    }


    // Map of all the message buckets (posts is static)
    // posts/msgID-0, posts/msgID-1, posts/msgID-2 ...
    mapping (string => uint256[]) public msgMap;
    mapping (string => mapping (uint256 => bool)) public msgMapMap;

    // Bucket Key => Msg ID => Msg Data
    mapping (string => mapping (uint256 => MsgData)) public msgData;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Link to the Hashtags
    IHashtags public Hashtags;

    // Link to the Tagged Accounts
    ITagged public Tagged;

    // Link to the Posts Owners
    IPosts public Posts;

    // Link to the Group Posts
    IGroupPosts public GroupPosts;

    // Link to the Group Details
    IGroups public Groups;

    // Link to the Message Formatter
    IMessageFormat public MessageFormat;

    // Link to the Followers
    IFollowers public Followers;

    // Link to the Blocking
    IBlocking public Blocking;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _kutils, uint256 _maxItemsPerBucket) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsPerBucket = _maxItemsPerBucket;

        // Setup link to User Profiles
        KUtils = IKUtils(_kutils);

        // Initialize Buckets
        buckets = [0,0];
    }


    /*

    EVENTS

    */

    event logNewMsg(uint256 msgID, uint256 isCommentOf, uint256 isRepostOf, address[2] postedBy, MsgData newMsg, uint256 indexed asGroup, uint256[] inGroups);
    event logRemoveMsg(uint256 msgID);
    event logUpdateMsgStats(uint256 indexed statType, uint256 msgID, int256 statValue, uint256 tips);



    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
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


    function updateContracts(address _kutils, address _hashtags, address _tagged, address _posts, address _messageFormat, address _followers, address _groupPosts, address _groups, address _blocking) public onlyAdmins {
        // Update the User Profiles contract address
        KUtils = IKUtils(_kutils);

        // Update the Hashtags address
        Hashtags = IHashtags(_hashtags);

        // Update the Tagged addresses
        Tagged = ITagged(_tagged);

        // Update the Posts addresses
        Posts = IPosts(_posts);

        // Update the Group Posts addresses
        GroupPosts = IGroupPosts(_groupPosts);

        // Update the Group Posts addresses
        Groups = IGroups(_groups);

        // Update the Message Formatting
        MessageFormat = IMessageFormat(_messageFormat);

        // Update the Followers addresses
        Followers = IFollowers(_followers);

        // Update the Blocking addresses
        Blocking = IBlocking(_blocking);
    }

    function saveMsg(MsgData memory newMsg) public onlyAdmins {

        // Check if this is a repost, and if so, update that messages updateStats
        if (newMsg.isRepostOf > 0){
            addStat(3, newMsg.isRepostOf, 1, 0);
        }

        // Get the bucket to store the message
        if (buckets[1] == maxItemsPerBucket){
            // If so, update the buckets and then return the next bucket ID
            buckets[0] += 1;
            buckets[1] = 0;
        }

        // Get the bucket key to save the message into
        string memory thisBucketKey = KUtils.append('posts-',KUtils.toString(buckets[0]),'','','');

        // if it's a comment, store the map to isCommentOf
        if (newMsg.isCommentOf > 0){

            // Update the message stats the comment is for
            addStat(2, newMsg.isCommentOf, 1, 0);

            // Add the comment ID to the message
            string memory commentOfBucketKey = getBucketKeyByID(newMsg.isCommentOf);
            newMsg.commentID = msgData[commentOfBucketKey][newMsg.isCommentOf].msgStats.totalInThread;
        }

        // Add to the messages bucket
        msgMap[thisBucketKey].push(newMsg.msgID);

        // Add to the messages bucket flag
        msgMapMap[thisBucketKey][newMsg.msgID] = true;

        // Save the Message MessageData
        msgData[thisBucketKey][newMsg.msgID] = newMsg;

        // Record the post to the poster
        Posts.addPost(newMsg.msgID, newMsg.postedBy[0], newMsg.isCommentOf, 0);

        // If this is a repost, also save the message as so for queries
        if (newMsg.isRepostOf > 0){
            Posts.addPost(newMsg.msgID, newMsg.postedBy[0], newMsg.isCommentOf, newMsg.isRepostOf);
        }

        // Save the message to the groups if there are any
        GroupPosts.addPost(newMsg.msgID, newMsg.inGroups);

        // Increase the bucket counter
        buckets[1] += 1;

        // Emit to the logs for external reference
        emit logNewMsg(newMsg.msgID, newMsg.isCommentOf, newMsg.isRepostOf, newMsg.postedBy, newMsg, newMsg.asGroup, newMsg.inGroups);
    }

    function removeMsg(uint256 msgID, address requester) public onlyAdmins {
        // Find the bucket containing the message
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Get the the data from the post
        MsgData memory thisMsgData = msgData[thisBucketKey][msgID];

        // Only the message poster can erase it
        require(thisMsgData.postedBy[0] == requester || Groups.isMemberOfGroupByID(thisMsgData.asGroup, requester), "Only the message owner or proxy can erase it");

        if (thisMsgData.isCommentOf > 0){

            // Remove a comment stat
            addStat(2, thisMsgData.isCommentOf, -1, 0);

        } else if (thisMsgData.isRepostOf > 0){

            // Remove a comment stat
            addStat(3, thisMsgData.isRepostOf, -1, 0);

        }

        // Remove the message bucket flag
        msgMapMap[thisBucketKey][thisMsgData.msgID] = false;


        // Remove the Hashtags
        if (thisMsgData.hashtags.length > 0){
            Hashtags.removeHashtags(msgID, thisMsgData.hashtags);
        }

        // Remove the Tagged accounts
        if (thisMsgData.taggedAccounts.length > 0){
            Tagged.removeTags(msgID, thisMsgData.taggedAccounts);
        }

        // Remove link to Groups
        GroupPosts.removePost(msgID, thisMsgData.inGroups);

        // Remove the post from the poster
        Posts.removePost(msgID, msgData[thisBucketKey][msgID].postedBy[0], thisMsgData.isCommentOf, 0);

        // If this is a repost, also remove the message from repost buckets (comment / repost must be removed separately)
        if (thisMsgData.isRepostOf > 0){
            Posts.removePost(msgID, msgData[thisBucketKey][msgID].postedBy[0], thisMsgData.isCommentOf, thisMsgData.isRepostOf);
        }

        msgData[thisBucketKey][msgID].message = "This message has been deleted by the poster.";
        msgData[thisBucketKey][msgID].uri = "";
        delete msgData[thisBucketKey][msgID].hashtags;
        delete msgData[thisBucketKey][msgID].taggedAccounts;

        // Emit to the logs for external reference
        emit logRemoveMsg(msgID);
    }

    function getMsgsByIDs(uint256[] memory msgIDs, bool onlyFollowers, address userToCheck) public whenNotPaused onlyAdmins view returns (string[][] memory){
        string[][] memory allData = new string[][](msgIDs.length);

        for (uint i=0; i < msgIDs.length; i++) {

            // Get the bucket key where this message is stored
            string memory thisBucketKey = getBucketKeyByID(msgIDs[i]);

            // Check to make sure the message exists
            require(bytes(thisBucketKey).length > 0, "Invalid Message ID");

             // Only get the valid messages
            if (msgMapMap[thisBucketKey][msgIDs[i]]){

                // Get the message data from the bucket
                MsgData storage thisMsgData = msgData[thisBucketKey][msgIDs[i]];

                bool validPost = true;

                // If only getting followers posts
                if (onlyFollowers && userToCheck != address(0)){

                    // If they are not following this user, skip returning the data
                    if (!Followers.isUserFollowing(userToCheck, thisMsgData.postedBy[0])){
                        validPost = false;
                    }
                }

                // Check to see if either account is being blocked by the other
                if (!Blocking.isAllowed(userToCheck, thisMsgData.postedBy[0]) || !Blocking.isAllowed(thisMsgData.postedBy[0], userToCheck)) {
                    // If so, skip showing the post
                    validPost = false;
                }

                // If it's still valid, show it
                if (validPost){

                    uint256[] memory thisData = new uint256[](15);

                    MsgStats storage stats = thisMsgData.msgStats;

                    thisData[0] = thisMsgData.msgID;
                    thisData[1] = stats.time;
                    thisData[2] = stats.block;
                    thisData[3] = stats.tipsReceived;
                    thisData[4] = thisMsgData.paid;
                    thisData[5] = stats.postByContract;
                    thisData[6] = uint(stats.likes);
                    thisData[7] = uint(stats.reposts);
                    thisData[8] = uint(stats.comments);
                    thisData[9] = thisMsgData.isCommentOf;
                    thisData[10] = thisMsgData.isRepostOf;
                    thisData[11] = uint(thisMsgData.commentLevel);
                    thisData[12] = thisMsgData.asGroup;
                    thisData[13] = stats.tipERC20Amount;
                    thisData[14] = thisMsgData.commentID;

                    // Get the formatted message
                    allData[i] = MessageFormat.buildMsg(thisData, thisMsgData.message, thisMsgData.postedBy, thisMsgData.hashtags, thisMsgData.taggedAccounts, thisMsgData.uri, thisMsgData.inGroups, stats.tipContract);
                }
            }
        }

        return allData;
    }

    // statType
    // 1 = like
    // 2 = comment
    // 3 = repost
    // 4 = tip

    function addStat(uint8 statType, uint256 msgID, int amount, uint256 tips) public onlyAdmins {
        // Find the bucket where this message is
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Update the respective stat
        if (statType == 1){
            msgData[thisBucketKey][msgID].msgStats.likes += amount;
        } else if (statType == 2){
            msgData[thisBucketKey][msgID].msgStats.comments += amount;
            if (amount > 0){
                msgData[thisBucketKey][msgID].msgStats.totalInThread += uint(amount);
            }
        } else if (statType == 3){
            msgData[thisBucketKey][msgID].msgStats.reposts += amount;
        }

        // update tips received
        msgData[thisBucketKey][msgID].msgStats.tipsReceived += tips;

        // Emit to the logs for external reference
        emit logUpdateMsgStats(statType, msgID, amount, tips);
    }


    /*

    PUBLIC FUNCTIONS

    */

    /**
    * @dev Get the address of the user or group that posted a message
    * @param msgID : The message ID to check for the posters address
    * @return address : the address of the member that posted the message
    */
    function getPoster(uint256 msgID) public view whenNotPaused returns (address){
        string memory topBucketKey = getBucketKeyByID(msgID);
        return msgData[topBucketKey][msgID].postedBy[0];
    }

    /**
    * @dev Get a list of group IDs that a message was posted in
    * @param msgID : The message ID to check for
    * @return uint256[] : an array of group IDs that the message was posted in
    */
    function getInGroups(uint256 msgID) public view whenNotPaused returns (uint256[] memory){
        string memory topBucketKey = getBucketKeyByID(msgID);
        return msgData[topBucketKey][msgID].inGroups;
    }

    /**
    * @dev Get the comment level of a post.
    * @dev 0 = Comments are open / 1 = Comments are closed
    * @param msgID : The message ID to check for
    * @return uint256 : the comment level of the message
    */
    function getMsgCommentLevel(uint256 msgID) public view whenNotPaused returns (uint256){
        // Find the bucket key for the message
        string memory thisBucketKey = getBucketKeyByID(msgID);

        // Return the message data from the bucket
        return msgData[thisBucketKey][msgID].commentLevel;
    }


    /*

    PRIVATE FUNCTIONS

    */

    function getBucketKeyByID(uint256 msgID) private view returns (string memory){
        // Initialize the bucket key
        string memory thisBucketKey = "";

        // Go through each bucket to see if it's there in reverse
        for (uint b=buckets[0]; b >= 0; b--) {
            // Get the next bucket key
            thisBucketKey = KUtils.append('posts-',KUtils.toString(b),'','','');

            // Get the poster address from the message for a post
            address poster = msgData[thisBucketKey][msgID].postedBy[0];
            
            if (poster != address(0)) {
                // We found the bucket with the message in it
                break;
            } else if (b == 0){
                thisBucketKey = '';
                break;
            }
        }

        return thisBucketKey;
    }

}