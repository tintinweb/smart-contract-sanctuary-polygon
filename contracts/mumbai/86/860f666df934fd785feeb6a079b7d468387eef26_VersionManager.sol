// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import { IVersionManager } from "./interfaces/IVersionManager.sol";

/// @title Shoply Version Manager
/// @dev Version Manager for Shoply Stores
contract VersionManager is IVersionManager, Ownable {

    /// @notice Array of all version names
    string[] internal _versionString;

    /// @notice Mapping from version names to version structs
    mapping(string=>Version) internal _versions;

    /// @dev The recommended version
    string internal _recommendedVersion;

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    modifier versionExists(
        string memory versionName
    ) 
    {
        if (_versions[versionName].implementation == address(0)) {
            revert VersionNotRegistered();
        }
        _;
    }

    /// @notice Registers a new version of the store contract
    /// @param versionName The name of the version to be added
    /// @param status Status of the version to be added
    /// @param implementation The address of the implementation of the version
    function addVersion(
        string calldata versionName,
        Status status,
        address implementation
    )
        external
        onlyOwner
        nonZeroAddress(implementation)
    {
        // version name must not be the empty string
        if (bytes(versionName).length == 0) {
            revert InvalidVersionName();
        }

        // implementation must be a contract
        if (!Address.isContract(implementation)) {
            revert InvalidImplementation();
        }

        // the version name should not already be registered
        if (_versions[versionName].implementation != address(0)) {
            revert VersionAlreadyRegistered();
        }
        _versionString.push(versionName);

        _versions[versionName] = Version({
            versionName:versionName,
            status:status,
            bugLevel:BugLevel.NONE,
            implementation:implementation,
            dateAdded:block.timestamp
        });

        emit VersionAdded(versionName, implementation);
    }

    /// @notice Update a contract version
    /// @param versionName Version of the contract
    /// @param status Status of the contract
    /// @param bugLevel New bug level for the contract
    function updateVersion(
        string calldata versionName,
        Status status,
        BugLevel bugLevel
    )
        external
        onlyOwner
        versionExists(versionName)
    {

        _versions[versionName].status = status;
        _versions[versionName].bugLevel = bugLevel;

        emit VersionUpdated(
            versionName,
            status,
            bugLevel
        );
    }

    /// @notice Set the recommended version
    /// @param versionName Version of the contract
    function markRecommendedVersion(
        string calldata versionName
    )
        external
        onlyOwner
        versionExists(versionName)
    {
        // set the version name as the recommended version
        _recommendedVersion = versionName;

        emit VersionRecommended(versionName);
    }

    /// @notice Remove the recommended version
    function removeRecommendedVersion()
        external
        onlyOwner
    {
        // delete the recommended version name
        delete _recommendedVersion;

        emit RecommendedVersionRemoved();
    }

    /// @notice Get recommended version for the contract.
    /// @return versionName The name of the recommended version
    /// @return status The status of the recommended version
    /// @return bugLevel The bug level of the recommended version
    /// @return implementation The address of the implementation of the recommended version
    /// @return dateAdded The date the recommended version was added
    function getRecommendedVersion()
        external
        view
        returns (
            string memory versionName,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        )
    {
        versionName = _recommendedVersion;

        Version storage recommendedVersion = _versions[
            versionName
        ];

        status = recommendedVersion.status;
        bugLevel = recommendedVersion.bugLevel;
        implementation = recommendedVersion.implementation;
        dateAdded = recommendedVersion.dateAdded;

        return (
            versionName,
            status,
            bugLevel,
            implementation,
            dateAdded
        );
    }

    /// @notice Get total count of versions
    function getVersionCount()
        external
        view
        returns (uint256 count)
    {
        count = _versionString.length;
        return count;
    }

    /// @dev Returns the version name at specific index in the versionString[] array
    /// @param index The index to be searched for
    function getVersionAtIndex(uint256 index)
        external
        view
        returns (string memory versionName)
    {
        versionName = _versionString[index];
        return versionName;
    }

    /// @notice Get the implementation address for a version
    /// @param index The index of the version
    function getVersionAddress(uint256 index) external view returns (address) {
        string memory versionName = _versionString[index];
        Version memory v = _versions[versionName];
        return v.implementation;
    }

    /// @notice Returns the version details for the given version name
    /// @param versionName Version string
    function getVersionDetails(
        string calldata versionName
    )
        external
        view
        returns (
            string memory versionString,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        )
    {
        Version storage v = _versions[versionName];

        versionString = v.versionName;
        status = v.status;
        bugLevel = v.bugLevel;
        implementation = v.implementation;
        dateAdded = v.dateAdded;

        return (
            versionString,
            status,
            bugLevel,
            implementation,
            dateAdded
        );
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
pragma solidity ^0.8.17;

/// @title Interface for Shoply Version Manager
/// @dev Version Manager for Shoply Stores
interface IVersionManager {
    /// @notice parameter cannot be the zero address
    error ZeroAddress();
    /// @notice contract is not registered
    error ContractNotRegistered();
    /// @notice version is not registered
    error VersionNotRegistered();
    /// @notice version name cannot be the empty string
    error InvalidVersionName();
    /// @notice contract name cannot be the empty string
    error InvalidContractName();
    /// @notice implementation must be a contract
    error InvalidImplementation();
    /// @notice version is already registered
    error VersionAlreadyRegistered();

    /// @dev Signifies the status of a version
    enum Status {BETA, RC, PRODUCTION, DEPRECATED}

    /// @dev Indicated the highest level of bug found in the version
    enum BugLevel {NONE, LOW, MEDIUM, HIGH, CRITICAL}

    /// @dev A struct to encode version details
    struct Version {
        // the version number string ex. "v1.0"
        string versionName;

        Status status;

        BugLevel bugLevel;
        // the address of the instantiation of the version
        address implementation;
        // the date when this version was registered with the contract
        uint256 dateAdded;
    }

    event VersionAdded(
        string versionName,
        address indexed implementation
    );

    event VersionUpdated(
        string versionName,
        Status status,
        BugLevel bugLevel
    );

    event VersionRecommended(string versionName);

    event RecommendedVersionRemoved();

    function addVersion(
        string calldata versionName,
        Status status,
        address implementation
    ) external;

    function updateVersion(
        string calldata versionName,
        Status status,
        BugLevel bugLevel
    ) external;

    function markRecommendedVersion(
        string calldata versionName
    ) external;

    function removeRecommendedVersion() external;

    function getRecommendedVersion() external view returns (
            string memory versionName,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
    );

    function getVersionCount() external view returns (uint256 count);

    function getVersionAtIndex(uint256 index)
        external
        view
        returns (string memory versionName);

    function getVersionAddress(uint256 index) external view returns (address);

    function getVersionDetails(
        string calldata versionName
    )
        external
        view
        returns (
            string memory versionString,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        );
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