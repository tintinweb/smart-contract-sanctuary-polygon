// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CommunityRegistry is
    Initializable,
    OwnableUpgradeable
{
    ////////////////////////////////// STRUCTS //////////////////////////////////
    /// @dev Struct used to contain the community info
    ///      Also, note that using structs in mappings should be safe:
    ///      https://forum.openzeppelin.com/t/how-to-use-a-struct-in-an-upgradable-contract/832/4
    struct CommunityContainer {
        string uniqId;
        string name;
        string description;         // optional
        string logoUrl;             // optional
        string discordId;           // optional
        string discordServerName;   // optional
    }

    /// @dev This event allows us to track which community was registered.
    event RegisteredCommunity(string uniqId);

    /// @dev This event allows us to track which community metadata was modified.
    event ModifyCommunityMetadata(string uniqId, string name, string logoUrl, string discordId, string discordServerName);

    /// @dev This event allows us to track how many admins were added.
    event AddAdmins(string uniqId, uint256 numOfAdmins);

    /// @dev This event allows us to track how many admins were removed.
    event RemoveAdmins(string uniqId, uint256 numOfAdmins);

    ////////////////////////////////// VARIABLES //////////////////////////////////
    /// @dev We use this simplistic mapping to contain the list of admins that are allowed to take
    ///      certain adminstrative operations.
    ///      Note that in the future, we will very likely modify the following:
    ///      1. change this to use a Merkle tree as holding a list of allowlisted people is inefficient
    ///      2. add more roles and make it modifiable by the admins themselves (self-governance)
    mapping(string => CommunityContainer) public communityIdToMetadata;
    mapping(string => address[]) public communityIdToAdmins;

    /// @dev This mapping is used to efficiently figure out the index of an existing admin.
    ///      Note that because the default zero value for an integer is 0, we use 1-index.
    mapping(string => mapping(address => uint256)) public communityIdToAdminOneIndexIndices;

    ////////////////////////////////// CODE //////////////////////////////////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @notice An owner-only function that allows us to instantiate a community and add the initial set of admins
    /// @dev We want to decentralize this process in the future where we're not the only ones with the power to
    ///      seed the initial community & admin data. However, for now we centralize this process to provide a better UX.
    function createCommunityAndAddInitialAdmin(
        string memory uniqId,
        string memory name,
        string memory description,
        string memory logoUrl,
        string memory discordId,
        string memory discordServerName,
        address[] memory admins
    ) public onlyOwner {
        require(compareStringsbyBytes(communityIdToMetadata[uniqId].uniqId, ""), "Community should not already be registered");

        CommunityContainer memory cc;
        cc.uniqId = uniqId;
        cc.name = name;
        cc.description = description;
        cc.logoUrl = logoUrl;
        cc.discordId = discordId;
        cc.discordServerName = discordServerName;

        communityIdToMetadata[uniqId] = cc;
        communityIdToAdmins[uniqId] = admins;

        emit RegisteredCommunity(uniqId);
    }

    /// @notice An owner-only function that allows us to modify metadata for a given community 
    /// @dev We plan to add another method that takes in a signature from an authorized admin to also modify
    ///      this metadata.
    function modifyCommunityMetadata(
        string memory uniqId,
        string memory name,
        string memory description,
        string memory logoUrl,
        string memory discordId,
        string memory discordServerName
    ) public onlyOwner {
        require(!compareStringsbyBytes(communityIdToMetadata[uniqId].uniqId, ""), "Community should already be registered");

        CommunityContainer memory cc = communityIdToMetadata[uniqId];

        if (!compareStringsbyBytes(name, "")) {
            cc.name = name;
        }
        if (!compareStringsbyBytes(description, "")) {
            cc.description = description;
        }
        if (!compareStringsbyBytes(logoUrl, "")) {
            cc.logoUrl = logoUrl;
        }
        if (!compareStringsbyBytes(discordId, "")) {
            cc.discordId = discordId;
        }
        if (!compareStringsbyBytes(discordServerName, "")) {
            cc.discordServerName = discordServerName;
        }
        communityIdToMetadata[uniqId] = cc;

        emit ModifyCommunityMetadata(uniqId, name, logoUrl, discordId, discordServerName);
    }

    /// @notice An owner-only function that allows us to add admins to a community
    /// @dev We plan to add another method that takes in a signature from an authorized admin to also
    ///      take this action.
    ///      Note that if the admin already exists in the allowlist, we ignore that admin all together.
    function addCommunityAdmins(
        string memory uniqId,
        address[] memory admins
    ) public onlyOwner {
        require(!compareStringsbyBytes(communityIdToMetadata[uniqId].uniqId, ""), "Community should already be registered");

        uint256 numOfAdminsAdded = 0;

        for(uint256 i=0; i < admins.length; i++) {
            // for each admin make sure that the admin doesn't exist already
            if(communityIdToAdminOneIndexIndices[uniqId][admins[i]] != 0) {
                continue;
            }
            communityIdToAdmins[uniqId].push(admins[i]);
            communityIdToAdminOneIndexIndices[uniqId][admins[i]] = i+1; // 1-index

            numOfAdminsAdded++;
        }

        emit AddAdmins(uniqId, numOfAdminsAdded);
    }

    /// @notice An owner-only function that allows us to delete admins in a community
    /// @dev We plan to add another method that takes in a signature from an authorized admin to also
    ///      take this action.
    ///      Note that if the admin doesn't exists in the allowlist, we ignore that admin all together.
    function removeCommunityAdmins(
        string memory uniqId,
        address[] memory admins
    ) public onlyOwner {
        require(!compareStringsbyBytes(communityIdToMetadata[uniqId].uniqId, ""), "Community should already be registered");

        uint256 numOfAdminsRemoved = 0;

        for(uint256 i=0; i < admins.length; i++) {
            // for each admin make sure that the admin exists already
            if(communityIdToAdminOneIndexIndices[uniqId][admins[i]] == 0) {
                continue;
            }
            uint256 adminIndex = communityIdToAdminOneIndexIndices[uniqId][admins[i]]-1;

            // override admin to remove with the last spot and then update index
            address lastSpotAdmin = communityIdToAdmins[uniqId][communityIdToAdmins[uniqId].length - 1];
            communityIdToAdmins[uniqId][adminIndex] = lastSpotAdmin;
            communityIdToAdmins[uniqId].pop();

            communityIdToAdminOneIndexIndices[uniqId][lastSpotAdmin] = adminIndex+1; // 1-index

            numOfAdminsRemoved++;
        }

        emit RemoveAdmins(uniqId, numOfAdminsRemoved);
    }

    function compareStringsbyBytes(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function doesCommunityExist(string memory uniqId) external view returns (bool) {
        return !compareStringsbyBytes(communityIdToMetadata[uniqId].uniqId, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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