// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.16;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.16;

import "./IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./StorageSlotUpgradeable.sol";
import "./IBeaconUpgradeable.sol";
import "./IERC1822ProxiableUpgradeable.sol";


/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.4;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./AddressUpgradeable.sol";

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

pragma solidity ^0.8.16;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function saveTransferEth(
        address payable recipient, 
        uint256 amount
    ) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }
    
    function safeApproveForAllNFT1155(
        address token,
        address operator,
        bool approved
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, operator, approved)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_NFT1155_FAILED"
        );
    }
    
    function safeTransferNFT1155(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory dataValue
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, id, amount, dataValue)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_NFT1155_FAILED"
        );
    }

    function safeMintNFT(
        address token,
        address to
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x40d097c3, to)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: MINT_NFT_FAILED"
        );
    }

    function safeApproveForAll(
        address token,
        address to,
        bool value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC1822ProxiableUpgradeable.sol";
import "./ERC1967UpgradeUpgradeable.sol";



/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./EnumerableSet.sol";
import "./Initializable.sol";



abstract contract VerifyInitializable is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(string => bool) public VERIFY_MESSAGE;
    EnumerableSet.AddressSet private OPERATOR;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Verify_init() internal onlyInitializing {
        __Verify_init_unchained();
    }

    function __Verify_init_unchained() internal onlyInitializing {
        OPERATOR.add(msg.sender);
    }

    modifier onlyOperator() {
        require(OPERATOR.contains(msg.sender), "NOT OPERATOR.");
        _;
    }

    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(checkVerifySignature(message, v, r, s), "INVALID SIGNATURE.");
        _;
    }


    modifier rejectDoubleMessage(string memory message) {
        require(!VERIFY_MESSAGE[message], "SIGNATURE ALREADY USED.");
        _;
    }

    function checkVerifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        return OPERATOR.contains(verifyString(message, v, r, s));
    }

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer){
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "NOT PROVIDED.");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function getOperator() public view returns (address[] memory) {
        return OPERATOR.values();
    }

    function updateOperator(address _operatorAddr, bool _flag) public onlyOperator {
        require(getOperator().length != 0 || OPERATOR.contains(msg.sender) ,"NOT OPERATOR.");
        require(_operatorAddr != address(0), "ZERO ADDRESS.");
        if (_flag) {
            OPERATOR.add(_operatorAddr);
        } else {
            OPERATOR.remove(_operatorAddr);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Library/TransferHelper.sol";
import "./Library/SafeMath.sol";
import "./IERC721.sol";
import "./Library/VerifyInitializable.sol";
import "./Library/UUPSUpgradeable.sol";
import "./Library/Initializable.sol";

contract GroupChallenge is Initializable, VerifyInitializable, UUPSUpgradeable {
    using SafeMath for uint256;

    enum UserStatus {
        NotYet,
        AlreadyEntry,
        Successed,
        Failed,
        GiveUp
    }

    struct UserInfor {
        UserStatus userStatus;
        uint256 totalReward;
        uint256[] historyDate;
        uint256[] historyData;
        uint256 currentStatus;
        mapping(uint256 => uint256) stepOn;
        uint256 sequence;
    }

    struct PercentRateSendDaily {
        uint256 adminPercent;
        uint256 successPercent;
        uint256 holdNftPercent;
        uint256 goldPercent;
        uint256 silverPercent;
        uint256 bronzePercent;
        address nftHold;
    }

    struct PercentGiveUp {
        uint256 adminGiveupPercent;
        uint256 successGiveupPercent;
        uint256 giveUpPercent;
    }

    struct ChallengeInfor {
        uint256 challengeEntryStart; // 0
        uint256 challengeEntryFinish; // 1
        uint256 challengeStart; // 2
        uint256 challengeFinish; // 3
        uint256 endDaySendStepData; // 4
        uint256 targetStepsPerDay; // 5
        uint256 challengeDuration; // 6
        uint256 dayRequired; // 7
        uint256 entryFee; // 8
        uint256 typeChallenge; // 9
        bool isAllowGiveUp; // 10
        address token20Address; // 11
    }

    struct ChallengeStatus {
        uint256 numberUser;
        address[] listUser;
        address[] listUserAchieved;
        address[] listUserNotAchieved;
        uint256 totalAmountCollected;
        uint256 amountForAchieved;
        uint256 amountForAdmin;
    }

    ChallengeInfor public challengeInfor;
    ChallengeStatus public challengeStatus;
    PercentRateSendDaily public percentRateSendDaily;
    PercentGiveUp public percentGiveUp;
    address public adminAddress;
    address[] private listRandomUser;
    mapping(address => UserInfor) public userInfor;

    event UserEntryChallenge(address indexed _caller, uint256 _amount);
    event UserCancelEntryChallenge(address indexed _caller, uint256 _amount);
    event SendDailyResult(
        address indexed _caller,
        uint256[] _day,
        uint256[] _stepIndex
    );
    event GiveUp(address indexed _caller);
    event PaymentToAchievedUser(
        address _caller,
        address[] _listUserAchieved,
        address[] _listUserNotAchieved
    );
    event FundTransfers(address[] indexed to, uint256 indexed valueSend);
    event FundTransfer(address indexed to, uint256 indexed valueSend);

    modifier onTimeSendResult() {
        require(
            block.timestamp <=
                challengeInfor.challengeFinish.add(
                    challengeInfor.endDaySendStepData
                ),
            "CHALLENGE WAS FINISHED."
        );
        require(
            block.timestamp >= challengeInfor.challengeStart,
            "CHALLENGE HAS NOT STARTED YET."
        );
        _;
    }

    modifier onTimeForPayment() {
        require(
            block.timestamp >
                challengeInfor.challengeFinish.add(
                    challengeInfor.endDaySendStepData
                ),
            "NOT TIME TO PAYMENT TO ACHIEVED USER."
        );
        _;
    }

    modifier onTime() {
        require(
            block.timestamp < challengeInfor.challengeFinish,
            "CHALLENGE WAS FINISHED"
        );
        require(
            block.timestamp >= challengeInfor.challengeStart,
            "CHALLENGE HAS NOT STARTED YET"
        );
        _;
    }

    modifier canGiveUp() {
        require(challengeInfor.isAllowGiveUp, "CAN NOT GIVE UP.");
        _;
    }

    // Address 0: 0x0000000000000000000000000000000000000000
    // [1677343670, 1677344090, 1677344100, 1677344330, 60, 6000, 1, 1, 100000000000000000000, 0]
    /*
    Option 0: [20, 80, 0, 0, 0, 0]
    [0, 0, 0]
    Option 1: [20, 60, 20, 0, 0, 0]
    [0, 0, 0]
    Option 2: [20, 30, 0, 35, 10, 5]
    [0, 0, 0]
    Option 3: [20, 80, 0, 0, 0, 0]
    [0, 0, 0]
    Option 4: [20, 80, 0, 0, 0, 0]
    [20, 70, 10]
    */

    // true
    // 0xe2bE9361d162Bd4f5f7C438CFD872B0CdF17c2D9
    // 0x2835D412b70e6bA9a6E562e14d91fAf973288d8c
    // 0x4a6f4FFd8e7164235E5aA7Db2B8425D3E3a7a165

    /*  For sendDailyResult function */
    // Input for send daily result
    // [1, 2, 9, 3, 4, 5, 6]
    // [111111111, 111111111, 111111111, 111111111, 111111111, 111111111, 111111111, 111111111]

    function initialize(
        uint256[] memory _challengeInfor,
        uint256[] memory _percentRateSendDaily,
        uint256[] memory _percentGiveUp,
        bool _isAllowGiveUp,
        address _token20Address,
        address _token721Address,
        address _adminAddress
    ) external initializer {
        __UUPSUpgradeable_init();
        __Verify_init();
        
        require(
            _challengeInfor[0] > block.timestamp,
            "INVALID CHALLENGE ENTRY START TIME."
        );
        require(
            _challengeInfor[0] < _challengeInfor[1] &&
                _challengeInfor[1] < _challengeInfor[2] &&
                _challengeInfor[2] < _challengeInfor[3],
            "INVALID TIME TO PREPARE FOR NEW CHALLENGE."
        );

        require(
            _challengeInfor[5] > 0 &&
                _challengeInfor[6] > 0 &&
                _challengeInfor[7] > 0 &&
                _challengeInfor[8] > 0,
            "INVALID CHALLENGE CONDITION INFORMATION."
        );

        require(
            _challengeInfor[9] >= 0 && _challengeInfor[9] < 5,
            "INVALID TYPE CHALLENGE"
        );

        require(_token20Address != address(0), "INVALID TOKEN20 ADDRESS.");
        require(_adminAddress != address(0), "INVALID ADMIN ADDRESS.");

        challengeInfor = ChallengeInfor(
            _challengeInfor[0],
            _challengeInfor[1],
            _challengeInfor[2],
            _challengeInfor[3],
            _challengeInfor[4],
            _challengeInfor[5],
            _challengeInfor[6],
            _challengeInfor[7],
            _challengeInfor[8],
            _challengeInfor[9],
            _isAllowGiveUp,
            _token20Address
        );

        percentRateSendDaily = PercentRateSendDaily(
            _percentRateSendDaily[0],
            _percentRateSendDaily[1],
            _percentRateSendDaily[2],
            _percentRateSendDaily[3],
            _percentRateSendDaily[4],
            _percentRateSendDaily[5],
            _token721Address
        );

        percentGiveUp = PercentGiveUp(
            _percentGiveUp[0],
            _percentGiveUp[1],
            _percentGiveUp[2]
        );

        adminAddress = _adminAddress;
    }

    function userEntryChallenge() external {
        require(
            userInfor[msg.sender].userStatus == UserStatus.NotYet,
            "USER HAS REALLY ENTRY, CANNOT ENTRY AGAIN."
        );
        require(
            challengeInfor.challengeEntryStart <= block.timestamp &&
                challengeInfor.challengeEntryFinish >= block.timestamp,
            "NO TIME FOR USER ENTRY CHALLENGE."
        );

        userInfor[msg.sender].userStatus = UserStatus.AlreadyEntry;

        TransferHelper.safeTransferFrom(
            challengeInfor.token20Address,
            msg.sender,
            address(this),
            challengeInfor.entryFee
        );

        challengeStatus.numberUser = challengeStatus.numberUser.add(1);
        challengeStatus.listUser.push(msg.sender);
        challengeStatus.totalAmountCollected = challengeStatus
            .totalAmountCollected
            .add(challengeInfor.entryFee);

        emit UserEntryChallenge(msg.sender, challengeInfor.entryFee);
    }

    function userCancelEntryChallenge() external {
        require(
            userInfor[msg.sender].userStatus == UserStatus.AlreadyEntry,
            "USER NOT YET ENTRY, CANNOT ENTRY AGAIN."
        );
        require(
            challengeInfor.challengeEntryStart <= block.timestamp &&
                challengeInfor.challengeEntryFinish >= block.timestamp,
            "NO TIME FOR USER CANCEL ENTRY CHALLENGE."
        );

        userInfor[msg.sender].userStatus = UserStatus.NotYet;

        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            msg.sender,
            challengeInfor.entryFee
        );

        for (uint256 i = 0; i < challengeStatus.listUser.length; i++) {
            if (msg.sender == challengeStatus.listUser[i]) {
                challengeStatus.listUser[i] = challengeStatus.listUser[
                    challengeStatus.listUser.length.sub(1)
                ];
            }
        }
        challengeStatus.listUser.pop();

        challengeStatus.numberUser = challengeStatus.numberUser.sub(1);
        challengeStatus.totalAmountCollected = challengeStatus
            .totalAmountCollected
            .sub(challengeInfor.entryFee);

        emit UserCancelEntryChallenge(msg.sender, challengeInfor.entryFee);
    }

    function giveUp() external canGiveUp onTime {
        require(
            userInfor[msg.sender].userStatus == UserStatus.AlreadyEntry,
            "USER NOT YET ENTRY, CANNOT GIVEUP."
        );
        require(
            challengeInfor.challengeStart <= block.timestamp &&
                challengeInfor.challengeFinish >= block.timestamp,
            "NO TIME FOR USER GIVEUP."
        );

        userInfor[msg.sender].userStatus = UserStatus.GiveUp;

        emit GiveUp(msg.sender);
    }

    function sendDailyResult(
        uint256[] memory _day,
        uint256[] memory _stepIndex,
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onTimeSendResult rejectDoubleMessage(message) {
        require(
            userInfor[msg.sender].userStatus == UserStatus.AlreadyEntry,
            "USER NOT YET ENTRY, CANNOT SEND DAILY RESULT."
        );

        for (uint256 i = 0; i < _day.length; i++) {
            require(
                userInfor[msg.sender].stepOn[_day[i]] == 0,
                "THIS DAY'S DATA HAD ALREADY UPDATED."
            );
            userInfor[msg.sender].stepOn[_day[i]] = _stepIndex[i];
            userInfor[msg.sender].historyDate.push(_day[i]);
            userInfor[msg.sender].historyData.push(_stepIndex[i]);
            if (
                _stepIndex[i] >= challengeInfor.targetStepsPerDay &&
                userInfor[msg.sender].currentStatus < challengeInfor.dayRequired
            ) {
                userInfor[msg.sender].currentStatus = userInfor[msg.sender]
                    .currentStatus
                    .add(1);
            }
        }

        userInfor[msg.sender].sequence = userInfor[msg.sender].sequence.add(
            _day.length
        );
        if (
            userInfor[msg.sender].sequence.sub(
                userInfor[msg.sender].currentStatus
            ) > challengeInfor.challengeDuration.sub(challengeInfor.dayRequired)
        ) {
            userInfor[msg.sender].userStatus = UserStatus.Failed;
        } else {
            if (
                userInfor[msg.sender].currentStatus >=
                challengeInfor.dayRequired
            ) {
                userInfor[msg.sender].userStatus = UserStatus.Successed;
            }
        }

        VERIFY_MESSAGE[message] = true;
        emit SendDailyResult(msg.sender, _day, _stepIndex);
    }

    function paymentToAchievedUser() external onTimeForPayment {
        require(
            challengeStatus.listUserAchieved.length == 0 &&
                challengeStatus.listUserNotAchieved.length == 0,
            "THE REWARD ALREADY PAID"
        );
        bool isUserHasEntry = false;
        for (uint256 i = 0; i < challengeStatus.listUser.length; i++) {
            if (msg.sender == challengeStatus.listUser[i]) {
                isUserHasEntry = true;
                break;
            }
        }

        require(
            isUserHasEntry || adminAddress == msg.sender,
            "ONLY USER HAS ENTRY OR ADMIN CAN CALL THIS FUNCTION."
        );

        for (uint256 i = 0; i < challengeStatus.listUser.length; i++) {
            if (
                userInfor[challengeStatus.listUser[i]].userStatus ==
                UserStatus.Successed
            ) {
                challengeStatus.listUserAchieved.push(
                    challengeStatus.listUser[i]
                );
            } else if (
                userInfor[challengeStatus.listUser[i]].userStatus ==
                UserStatus.Failed ||
                userInfor[challengeStatus.listUser[i]].userStatus ==
                UserStatus.AlreadyEntry
            ) {
                challengeStatus.listUserNotAchieved.push(
                    challengeStatus.listUser[i]
                );
            }
        }

        if (challengeInfor.typeChallenge == 0) {
            normalPayment();
        } else if (challengeInfor.typeChallenge == 1) {
            NFTMeritPayment();
        } else if (challengeInfor.typeChallenge == 2) {
            random3Payment();
        } else if (challengeInfor.typeChallenge == 3) {
            giveupOption1Payment();
        } else {
            giveupOption2Payment();
        }
        emit PaymentToAchievedUser(
            msg.sender,
            challengeStatus.listUserAchieved,
            challengeStatus.listUserNotAchieved
        );
    }

    function normalPayment() internal {
        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub( 
        (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            TransferHelper.safeTransfer(
                challengeInfor.token20Address,
                challengeStatus.listUserAchieved[i],
                challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
                    .div(challengeStatus.listUserAchieved.length)
                    .add(challengeInfor.entryFee)
            );

            challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub( 
            challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
                    .div(challengeStatus.listUserAchieved.length)
                    .add(challengeInfor.entryFee)
            );
        }

        emit FundTransfer(
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );
        emit FundTransfers(
            challengeStatus.listUserAchieved,
            challengeStatus
                .listUserNotAchieved
                .length
                .mul(challengeInfor.entryFee)
                .mul(percentRateSendDaily.successPercent)
                .div(100)
                .div(challengeStatus.listUserAchieved.length)
                .add(challengeInfor.entryFee)
        );
    }

    function NFTMeritPayment() internal {
        uint256 countUserHoldNFT = 0;
        
        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            if (
                IERC721(percentRateSendDaily.nftHold).balanceOf(
                    challengeStatus.listUserAchieved[i]
                ) > 0
            ) countUserHoldNFT = countUserHoldNFT.add(1);
        }

        address[] memory listUserHoldNFT = new address[](countUserHoldNFT);
        address[] memory listUserJustSuccess = new address[](challengeStatus.listUserAchieved.length - countUserHoldNFT);

        uint256 idxUserHoldNFT = 0;
        uint256 idxUserJustSuccess = 0;

        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub((
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            if (
                IERC721(percentRateSendDaily.nftHold).balanceOf(
                    challengeStatus.listUserAchieved[i]
                ) > 0
            ) {
                listUserHoldNFT[idxUserHoldNFT] = challengeStatus.listUserAchieved[i];
                idxUserHoldNFT = idxUserHoldNFT.add(1);
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.holdNftPercent)
                                .div(100)
                                .div(countUserHoldNFT)
                        )
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.holdNftPercent)
                                .div(100)
                                .div(countUserHoldNFT)
                        )
                        );
            } else {
                listUserJustSuccess[idxUserJustSuccess] = challengeStatus.listUserAchieved[i];
                idxUserJustSuccess = idxUserJustSuccess.add(1);
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                );
            }
        }

        emit FundTransfer(
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        emit FundTransfers(
            listUserHoldNFT,
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.holdNftPercent)
                                .div(100)
                                .div(countUserHoldNFT)
                        )
        );

        emit FundTransfers(
            listUserJustSuccess, 
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
        );
    }

    function random3Payment() internal {
        address[] memory listUserJustSuccess = new address[](challengeStatus.listUserAchieved.length - 3);
        uint256 idxUserJustSuccess = 0;

        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            if (
                IERC721(percentRateSendDaily.nftHold).balanceOf(
                    challengeStatus.listUserAchieved[i]
                ) > 0
            ) {
                listRandomUser.push(challengeStatus.listUserAchieved[i]);
                listRandomUser.push(challengeStatus.listUserAchieved[i]);
            } else listRandomUser.push(challengeStatus.listUserAchieved[i]);
        }
        address[3] memory listUserGotMedal;
        for (uint256 round = 0; round < 3; round++) {
            uint256 randomIndex = checkRandomNumber(listRandomUser.length);
            listUserGotMedal[round] = listRandomUser[randomIndex];
            uint256 left = 0;
            uint256 right = listRandomUser.length - 1;

            while (left <= right) {
                if (listRandomUser[left] == listUserGotMedal[round]) {
                    if (listRandomUser[left] != listRandomUser[right]) {
                        listRandomUser[left] = listRandomUser[right];
                        listRandomUser.pop();
                        right = right.sub(1);
                    } else {
                        listRandomUser.pop();
                        right = right.sub(1);
                    }
                } else left = left.add(1);
                if (listRandomUser[right] == listUserGotMedal[round]) {
                    listRandomUser.pop();
                    right = right.sub(1);
                }
            }
        }

        // Transfer reward for admin
        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        // Transfer reward for user success
        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            if (challengeStatus.listUserAchieved[i] == listUserGotMedal[0]) {
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.goldPercent)
                                .div(100)
                        )
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.goldPercent)
                                .div(100)
                        )
                );
            } else if (
                challengeStatus.listUserAchieved[i] == listUserGotMedal[1]
            ) {
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.silverPercent)
                                .div(100)
                        )
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.silverPercent)
                                .div(100)
                        )
                );
            } else if (
                challengeStatus.listUserAchieved[i] == listUserGotMedal[2]
            ) {
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.bronzePercent)
                                .div(100)
                        )
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.bronzePercent)
                                .div(100)
                        )
                );
            } else {
                listUserJustSuccess[idxUserJustSuccess] = challengeStatus.listUserAchieved[i];
                idxUserJustSuccess = idxUserJustSuccess.add(1);
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUserAchieved[i],
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                );
            }
        }

        emit FundTransfer(
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        emit FundTransfer(
            listUserGotMedal[0],
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.goldPercent)
                                .div(100)
                )
        );

        emit FundTransfer(
            listUserGotMedal[1], 
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.silverPercent)
                                .div(100)
                        )
        );

        emit FundTransfer(
            listUserGotMedal[2],
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
                        .add(
                            challengeStatus
                                .listUserNotAchieved
                                .length
                                .mul(challengeInfor.entryFee)
                                .mul(percentRateSendDaily.bronzePercent)
                                .div(100)
                        )
        );

        emit FundTransfers(
            listUserJustSuccess,
            challengeStatus
                        .listUserNotAchieved
                        .length
                        .mul(challengeInfor.entryFee)
                        .mul(percentRateSendDaily.successPercent)
                        .div(100)
                        .div(challengeStatus.listUserAchieved.length)
                        .add(challengeInfor.entryFee)
        );

}

    function giveupOption1Payment() internal {
        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );

        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            TransferHelper.safeTransfer(
                challengeInfor.token20Address,
                challengeStatus.listUserAchieved[i],
                challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
            );

            challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
            );
        }

        emit FundTransfer(
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100)
        );
        emit FundTransfers(
            challengeStatus.listUserAchieved,
            challengeStatus
                .listUserNotAchieved
                .length
                .mul(challengeInfor.entryFee)
                .mul(percentRateSendDaily.successPercent)
                .div(100)
                .div(challengeStatus.listUserAchieved.length)
                .add(challengeInfor.entryFee)
        );
    }

    function giveupOption2Payment() internal {
        uint256 countUserGiveup;
        
        for (uint256 i = 0; i < challengeStatus.listUser.length; i++) {
            if (
                userInfor[challengeStatus.listUser[i]].userStatus ==
                UserStatus.GiveUp
            ) {
                countUserGiveup = countUserGiveup.add(1);
                TransferHelper.safeTransfer(
                    challengeInfor.token20Address,
                    challengeStatus.listUser[i],
                    challengeInfor
                        .entryFee
                        .mul(percentGiveUp.giveUpPercent)
                        .div(100)
                );

                challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                    challengeInfor
                        .entryFee
                        .mul(percentGiveUp.giveUpPercent)
                        .div(100)
                );
            }
        }
        address[] memory listUserGiveup = new address[](countUserGiveup);
        uint256 idxUserGiveup = 0;

        for (uint256 i = 0; i < challengeStatus.listUser.length; i++) {
            if (
                userInfor[challengeStatus.listUser[i]].userStatus ==
                UserStatus.GiveUp
            ) {
                listUserGiveup[idxUserGiveup] = challengeStatus.listUser[i];
                idxUserGiveup = idxUserGiveup.add(1);
            }
        }

        TransferHelper.safeTransfer(
            challengeInfor.token20Address,
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100).add(
                    countUserGiveup
                        .mul(challengeInfor.entryFee)
                        .mul(percentGiveUp.adminGiveupPercent)
                        .div(100)
            )
        );

        challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100).add(
                    countUserGiveup
                        .mul(challengeInfor.entryFee)
                        .mul(percentGiveUp.adminGiveupPercent)
                        .div(100)
            )
        );
        for (uint256 i = 0; i < challengeStatus.listUserAchieved.length; i++) {
            TransferHelper.safeTransfer(
                challengeInfor.token20Address,
                challengeStatus.listUserAchieved[i],
                challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
                    .div(challengeStatus.listUserAchieved.length)
                    .add(challengeInfor.entryFee)
                    .add(
                        countUserGiveup
                            .mul(challengeInfor.entryFee)
                            .mul(percentGiveUp.successGiveupPercent)
                            .div(100)
                            .div(challengeStatus.listUserAchieved.length)
                    )
            );

            challengeStatus.totalAmountCollected = challengeStatus.totalAmountCollected.sub(
                challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
                    .div(challengeStatus.listUserAchieved.length)
                    .add(challengeInfor.entryFee)
                    .add(
                        countUserGiveup
                            .mul(challengeInfor.entryFee)
                            .mul(percentGiveUp.successGiveupPercent)
                            .div(100)
                            .div(challengeStatus.listUserAchieved.length)
                    )
            );
        }

        emit FundTransfer(
            adminAddress,
            (
                challengeStatus.listUserNotAchieved.length.mul(
                    challengeInfor.entryFee
                )
            ).mul(percentRateSendDaily.adminPercent).div(100).add(
                    countUserGiveup
                        .mul(challengeInfor.entryFee)
                        .mul(percentGiveUp.adminGiveupPercent)
                        .div(100)
                )
        );

        emit FundTransfers(
            listUserGiveup,
            challengeInfor
                        .entryFee
                        .mul(percentGiveUp.giveUpPercent)
                        .div(100)
        );

        emit FundTransfers(
            challengeStatus.listUserAchieved,
            challengeStatus
                    .listUserNotAchieved
                    .length
                    .mul(challengeInfor.entryFee)
                    .mul(percentRateSendDaily.successPercent)
                    .div(100)
                    .div(challengeStatus.listUserAchieved.length)
                    .add(challengeInfor.entryFee)
                    .add(
                        countUserGiveup
                            .mul(challengeInfor.entryFee)
                            .mul(percentGiveUp.successGiveupPercent)
                            .div(100)
                            .div(challengeStatus.listUserAchieved.length)
                    )
        );

    }

    function checkRandomNumber(uint256 _limitValue) internal returns (uint256) {
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(block.number, block.difficulty, msg.sender)
            )
        ) % _limitValue;
        return randomValue;
    }

    function getListUserEntry()
        external
        view
        returns (
            address[] memory listUserEntry,
            address[] memory listUserAchieved,
            address[] memory listUserNotAchieved
        )
    {
        return (
            challengeStatus.listUser,
            challengeStatus.listUserAchieved,
            challengeStatus.listUserNotAchieved
        );
    }

    function getChallengeHistory(
        address _caller
    ) external view returns (uint256[] memory date, uint256[] memory data) {
        return (userInfor[_caller].historyDate, userInfor[_caller].historyData);
    }

    function getChallengeInfo(
        address _caller
    )
        external
        view
        returns (
            uint256 challengeCleared,
            uint256 challengeDayRequired,
            uint256 daysRemained
        )
    {
        return (
            userInfor[_caller].currentStatus,
            challengeInfor.dayRequired,
            challengeInfor.dayRequired.sub(userInfor[_caller].currentStatus)
        );
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOperator
    override
    {}
}