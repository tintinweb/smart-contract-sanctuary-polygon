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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a pair of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature signature, e.g. ECDSA signature for default flow
        bytes signature;
        ///
        /// @param signer signer of the signature, required for smart contract signatures
        address signer;
    }

    /// @notice an executable action, including operation (call or delegateCall), target, data and value
    struct Action {
        ///
        /// @param target the target to execute the actions on
        address target;
        ///
        /// @param data the data to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on AvoSafe
        ///                       or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source e.g. referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for future flexibility
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Required:
        ///                       As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects against potential gas griefing attacks & ensures the relayer sends enough gas
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum fee allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be executed in
        ///                       or 0 if the request is not time-limited to occur after a certain time
        ///                       Protects against executing a certain transaction at  an earlier moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       is valid for, or 0 if request should be valid forever.
        ///                       Protects against executing a certain transaction at a later moment
        ///                       not intended when signed, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IAvoMultisigV3 } from "./interfaces/IAvoMultisigV3.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoSignersList } from "./interfaces/IAvoSignersList.sol";

abstract contract AvoSignersListErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoSignersList__InvalidParams();

    /// @notice thrown when a view method is called that would require storage mapping data but the flag `trackInStorage`
    /// is set to false.
    error AvoSignersList__NotTracked();
}

abstract contract AvoSignersListConstants is AvoSignersListErrors {
    /// @notice AvoFactory used to confirm that an address is an AvoMultiSafe
    IAvoFactory public immutable avoFactory;

    /// @notice flag to signal if tracking should happen in storage or only events should be emitted (for off-chain)
    /// This can be used to reduce gas cost on expensive chains
    bool public immutable trackInStorage;

    /// @notice constructor sets the immutable avoFactory address and trackInStorage flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoSignersList__InvalidParams();
        }
        avoFactory = avoFactory_;

        trackInStorage = trackInStorage_;
    }
}

abstract contract AvoSignersListVariables is AvoSignersListConstants {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev add a gap for slot 0 to 100 to easily inherit Initializable / OwnableUpgradeable etc. later on
    uint256[101] private __gap;

    // ---------------- slot 101 -----------------

    /// @notice tracks all AvoMultiSafes mapped to a signer: signer => EnumerableSet AvoMultiSafes list
    /// @dev mappings to a struct with a mapping can not be public because the getter function that Solidity automatically
    /// generates for public variables cannot handle the potentially infinite size caused by mappings within the structs.
    mapping(address => EnumerableSet.AddressSet) internal _safesPerSigner;
}

abstract contract AvoSignersListEvents {
    /// @notice emitted when a new signer <> AvoMultiSafe mapping is added
    event SignerMappingAdded(address signer, address avoMultiSafe);

    /// @notice emitted when a signer <> AvoMultiSafe mapping is removed
    event SignerMappingRemoved(address signer, address avoMultiSafe);
}

abstract contract AvoSignersListViews is AvoSignersListVariables {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice returns true if `signer_` is an allowed signer of `avoMultiSafe_`
    function isSignerOf(address avoMultiSafe_, address signer_) public view returns (bool) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].contains(avoMultiSafe_);
        } else {
            return IAvoMultisigV3(avoMultiSafe_).isSigner(signer_);
        }
    }

    /// @notice returns all signers for a certain `avoMultiSafe_`
    function signers(address avoMultiSafe_) public view returns (address[] memory) {
        if (Address.isContract(avoMultiSafe_)) {
            return IAvoMultisigV3(avoMultiSafe_).signers();
        } else {
            return new address[](0);
        }
    }

    /// @notice returns all avoMultiSafes for a certain `signer_'.
    /// reverts with AvoSignersList__NotTracked() if `trackInStorage` is set to false (data is not available on-chain)
    function avoMultiSafes(address signer_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].values();
        } else {
            revert AvoSignersList__NotTracked();
        }
    }

    /// @notice returns the number of mapped signers for a certain `avoMultiSafe_'
    function signersCount(address avoMultiSafe_) public view returns (uint256) {
        if (Address.isContract(avoMultiSafe_)) {
            return IAvoMultisigV3(avoMultiSafe_).signersCount();
        } else {
            return 0;
        }
    }

    /// @notice returns the number of mapped avoMultiSafes for a certain `signer_'
    /// reverts with AvoSignersList__NotTracked() if `trackInStorage` is set to false (data is not available on-chain)
    function avoMultiSafesCount(address signer_) public view returns (uint256) {
        if (trackInStorage) {
            return _safesPerSigner[signer_].length();
        } else {
            revert AvoSignersList__NotTracked();
        }
    }
}

/// @title  AvoSignersList v3.0.0
/// @notice keeps track of allowed signers for AvoMultiSafes. Making available a list of all signers
/// linked to an AvoMultiSafe or all AvoMultiSafes for a certain signer address.
/// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking. The contract
/// itself will not track avoMultiSafes per signer!
/// @dev Note that in off-chain tracking make sure to check for duplicates (i.e. mapping already exists).
/// This should not happen but when not tracking the data on-chain there is no way to be sure.
/// @dev    Upgradeable through AvoSignersListProxy
contract AvoSignersList is
    AvoSignersListErrors,
    AvoSignersListConstants,
    AvoSignersListVariables,
    AvoSignersListEvents,
    AvoSignersListViews,
    IAvoSignersList
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice constructor sets the immutable avoFactory address and trackInStorage flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) AvoSignersListConstants(avoFactory_, trackInStorage_) {}

    /// @inheritdoc IAvoSignersList
    function syncAddAvoSignerMappings(address avoMultiSafe_, address[] calldata addSigners_) external {
        // make sure avoMultiSafe_ is an actual AvoMultiSafe
        if (avoFactory.isAvoSafe(avoMultiSafe_) == false) {
            revert AvoSignersList__InvalidParams();
        }

        uint256 addSignersLength_ = addSigners_.length;
        if (addSignersLength_ == 1) {
            // if adding just one signer, using `isSigner()` is cheaper than looping through allowed signers here
            if (IAvoMultisigV3(avoMultiSafe_).isSigner(addSigners_[0])) {
                if (trackInStorage) {
                    // add method also checks if signer is already mapped to avocado Multisig, returns false in that case
                    if (_safesPerSigner[addSigners_[0]].add(avoMultiSafe_) == true) {
                        emit SignerMappingAdded(addSigners_[0], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit SignerMappingAdded(addSigners_[0], avoMultiSafe_);
                }
            } else {
                revert AvoSignersList__InvalidParams();
            }
        } else {
            // get actual signers present at AvoMultisig to make sure data here will be correct
            address[] memory allowedSigners_ = IAvoMultisigV3(avoMultiSafe_).signers();
            uint256 allowedSignersLength_ = allowedSigners_.length;
            // track last allowed signer index for loop performance improvements
            uint256 lastAllowedSignerIndex_;

            bool isAllowedSigner_; // keeping this variable outside the loop so it is not re-initialized in each loop -> cheaper
            for (uint256 i; i < addSignersLength_; ) {
                // because allowedSigners_ and addSigners_ must be ordered ascending the for loop can be optimized each
                // new cycle to start from the position where the last signer has been found
                for (uint256 j = lastAllowedSignerIndex_; j < allowedSignersLength_; ) {
                    if (allowedSigners_[j] == addSigners_[i]) {
                        isAllowedSigner_ = true;
                        lastAllowedSignerIndex_ = j + 1; // set to j+1 so that next cycle starts at next array position
                        break;
                    }

                    // could be optimized by checking if allowedSigners_[j] > recoveredSigners_[i] immediately skipping with a break;
                    // because that implies that the recoveredSigners_[i] can not be present in allowedSigners_ due to sort.
                    // but that would optimize the failing invalid case and in turn increase cost for the default case where
                    // the input data is valid -> skip.

                    unchecked {
                        ++j;
                    }
                }

                // validate signer trying to add mapping for is really allowed at AvoMultisig
                if (!isAllowedSigner_) {
                    revert AvoSignersList__InvalidParams();
                }

                // reset isAllowedSigner_ for next loop
                isAllowedSigner_ = false;

                if (trackInStorage) {
                    // add method also checks if signer is already mapped to avocado Multisig, returns false in that case
                    if (_safesPerSigner[addSigners_[i]].add(avoMultiSafe_) == true) {
                        emit SignerMappingAdded(addSigners_[i], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit SignerMappingAdded(addSigners_[i], avoMultiSafe_);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc IAvoSignersList
    function syncRemoveAvoSignerMappings(address avoMultiSafe_, address[] calldata removeSigners_) external {
        // make sure avoMultiSafe_ is an actual AvoMultiSafe
        if (avoFactory.isAvoSafe(avoMultiSafe_) == false) {
            revert AvoSignersList__InvalidParams();
        }

        uint256 removeSignersLength_ = removeSigners_.length;

        if (removeSignersLength_ == 1) {
            // if removing just one signer, using `isSigner()` is cheaper than looping through allowed signers here
            if (IAvoMultisigV3(avoMultiSafe_).isSigner(removeSigners_[0])) {
                revert AvoSignersList__InvalidParams();
            } else {
                if (trackInStorage) {
                    // remove method also checks if signer is not mapped to avocado Multisig, returns false in that case
                    if (_safesPerSigner[removeSigners_[0]].remove(avoMultiSafe_) == true) {
                        emit SignerMappingRemoved(removeSigners_[0], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit SignerMappingRemoved(removeSigners_[0], avoMultiSafe_);
                }
            }
        } else {
            // get actual signers present at AvoMultisig to make sure data here will be correct
            address[] memory allowedSigners_ = IAvoMultisigV3(avoMultiSafe_).signers();
            uint256 allowedSignersLength_ = allowedSigners_.length;
            // track last signer index where signer to be removed was > allowedSigners for loop performance improvements
            uint256 lastSkipSignerIndex_;

            for (uint256 i; i < removeSignersLength_; ) {
                for (uint256 j = lastSkipSignerIndex_; j < allowedSignersLength_; ) {
                    if (allowedSigners_[j] == removeSigners_[i]) {
                        // validate signer trying to remove mapping for is really not present at AvoMultisig
                        revert AvoSignersList__InvalidParams();
                    }

                    if (allowedSigners_[j] > removeSigners_[i]) {
                        // because allowedSigners_ and removeSigners_ must be ordered ascending the for loop can be optimized:
                        // there is no need to search further once the signer to be removed is < than the allowed signer.
                        // and the next cycle can start from that position
                        lastSkipSignerIndex_ = j;
                        break;
                    }

                    unchecked {
                        ++j;
                    }
                }

                if (trackInStorage) {
                    // remove method also checks if signer is not mapped to avocado Multisig, returns false in that case
                    if (_safesPerSigner[removeSigners_[i]].remove(avoMultiSafe_) == true) {
                        emit SignerMappingRemoved(removeSigners_[i], avoMultiSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit SignerMappingRemoved(removeSigners_[i], avoMultiSafe_);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an AvoSafe instance. only works for already deployed AvoSafes
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for owner based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                      Computes the deterministic Multisig address for owner based on Create2
    /// @param owner_                AvoMultiSafe owner
    /// @return computedAddress_     computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                    Deploys an AvoSafe with non-default version for an owner deterministcally using Create2.
    ///                            ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                            Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_              AvoSafe owner
    /// @param avoWalletVersion_   Version of AvoWallet logic contract to deploy
    /// @return                    deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an AvoMultiSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                      Deploys an AvoMultiSafe with non-default version for an owner
    ///                              deterministcally using Create2.
    ///                              Does not check if contract at address already exists. AvoForwarder already does that.
    /// @param owner_                AvoMultiSafe owner
    /// @param avoMultisigVersion_   Version of AvoMultisig logic contract to deploy
    /// @return                      deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                     registry can update the current AvoWallet implementation contract set as default
    ///                             `_ avoWalletImpl` logic contract address for new AvoSafe (proxy) deployments
    /// @param avoWalletImpl_       the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                     registry can update the current AvoMultisig implementation contract set as default
    ///                             `_ avoMultisigImpl` logic contract address for new AvoMultiSafe (proxy) deployments
    /// @param avoMultisigImpl_     the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice      returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice      returns  the byteCode for the AvoSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

/// @notice base interface without getters for storage variables
interface IAvoMultisigV3Base is AvoCoreStructs {
    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoMultisig version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoMultisig logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               returns non-sequential nonce that will be marked as used when the request with the matching
    ///                       `params_` and `forwardParams_` is executed via `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 non sequential nonce
    function nonSequentialNonce(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   returns non-sequential nonce that will be marked as used when the request with the matching
    ///                           `params_` and `authorizedParams_` is executed via `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the transaction signature for a `cast()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the transaction signature for a `castAuthorized()' request is valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   executes arbitrary `actions_` with a valid signature executable by AvoForwarder
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   executes arbitrary `actions_` through authorized tx sent with valid signatures.
    ///                           Includes a fee to be paid in native network gas currency, depends on registry feeConfig
    ///                           if one action fails the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           in that case, all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  array of struct for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                           -signer(Optional): address of the signature signer. Required for smart contract signatures.
    ///                           If defined, it must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice  checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice  returns allowed signers on AvoMultisig wich can trigger actions
    ///          if reaching quorum of `requiredSigners` (include owner)
    function signers() external view returns (address[] memory signers);
}

/// @notice full interface with some getters for storage variables
interface IAvoMultisigV3 is IAvoMultisigV3Base {
    /// @notice             AvoMultisig Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             returns the number of allowed signers
    function signersCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoSignersList {
    /// @notice adds mappings of `addSigners_` to an AvoMultiSafe `avoMultiSafe_`
    ///         checks the data present at the AvoMultisig to validate input.
    ///         Silently ignores `addSigners_` that are already added
    function syncAddAvoSignerMappings(address avoMultiSafe_, address[] calldata addSigners_) external;

    /// @notice removes mappings of `removeSigners_` from an AvoMultiSafe `avoMultiSafe_`
    ///         checks the data present at the AvoMultisig to validate input
    ///         Silently ignores `removeSigners_` that are already removed
    function syncRemoveAvoSignerMappings(address avoMultiSafe_, address[] calldata removeSigners_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice FeeConfig params used to determine the fee
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        // for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%);
        // for static mode: absolute amount in native gas token to charge (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the fee for an AvoSafe (msg.sender) transaction `gasUsed_` based on fee configuration
    /// @param gasUsed_ amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version and reverts if not
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}