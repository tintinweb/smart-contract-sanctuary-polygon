/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/utils/structs/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/trade/utils/EnumerableMap.sol



pragma solidity 0.8.9;

/**
 * This library was copied from OpenZeppelin's EnumerableMap.sol and adjusted to our needs.
 * The only changes made are:
 * - change pragma solidity to 0.7.3
 * - change UintToAddressMap to AddressToAddressMap by renaming and adjusting methods
 * - add SupportState enum declaration
 * - clone AddressToAddressMap and change it to AddressToSupportStateMap by renaming and adjusting methods
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // AddressToAddressMap

    struct AddressToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToAddressMap storage map, address key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressToAddressMap storage map, uint256 index) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToAddressMap storage map, address key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(uint256(uint160(key)))))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(AddressToAddressMap storage map, address key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(uint256(uint160(key))), errorMessage))));
    }


    // AddressToSupportStateMap

    struct AddressToSupportStateMap {
        Map _inner;
    }

    enum SupportState {
        UNSUPPORTED,
        SUPPORTED,
        SUPPORT_STOPPED
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToSupportStateMap storage map, address key, SupportState value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToSupportStateMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToSupportStateMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToSupportStateMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToSupportStateMap storage map, uint256 index) internal view returns (address, SupportState) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), SupportState(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToSupportStateMap storage map, address key) internal view returns (SupportState) {
        return SupportState(uint256(_get(map._inner, bytes32(uint256(uint160(key))))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(AddressToSupportStateMap storage map, address key, string memory errorMessage) internal view returns (SupportState) {
        return SupportState(uint256(_get(map._inner, bytes32(uint256(uint160(key))), errorMessage)));
    }
}


// File contracts/trade/utils/FractionMath.sol



pragma solidity 0.8.9;

library FractionMath {

    struct Fraction {
        uint48 numerator;
        uint48 denominator;
    }

    function sanitize(Fraction calldata fraction) internal pure returns (Fraction calldata) {
        require(fraction.denominator > 0, "FractionMath: denominator must be greater than zero");
        return fraction;
    }

    function mul(Fraction storage fraction, uint256 value) internal view returns (uint256) {
        return value * fraction.numerator / fraction.denominator;
    }
}


// File contracts/trade/TradeStorage.sol



pragma solidity 0.8.9;
abstract contract TradeStorage {
    // Initializable.sol
    bool internal _initialized;
    bool internal _initializing;

    // Ownable.sol
    address internal _owner;

    // Trade.sol
    mapping (bytes32 => bool) internal _usedOfferSignatures;

    // TradeConfig.sol
    address internal _feeRecipient;
    EnumerableMap.AddressToAddressMap internal _tokenAddressToHandlerAddress;
    EnumerableMap.AddressToSupportStateMap internal _tradeTokens;
    mapping (address => FractionMath.Fraction) internal _tradeFees;

    // EIP712Domain.sol
    bytes32 internal DOMAIN_SEPARATOR; // solhint-disable-line var-name-mixedcase
}


// File contracts/trade/Initializable.sol



pragma solidity 0.8.9;
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable is TradeStorage {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    // bool _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool _initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(_initializing || isConstructor() || !_initialized, "Contract instance has already been initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}


// File contracts/trade/RoyaltiesSupport.sol



pragma solidity 0.8.9;
interface IERC2981 {
   function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

abstract contract RoyaltiesSupport {
    using SafeERC20 for IERC20;

    /**
     * @dev calculate and pay royalties
     * the function is safe against reentrancy attack: first calculate all royalties, second transfer funds
     * (transfers do not depend on previous external calls)
     * The function handles both a single item trade and batch trade.
     * Assumption: all royalties for items in a batch are equal, percentage wise.
     * Assumption: NFT contract supports ERC2981
     */
    function _payRoyalties(address royaltiesPayer, uint settlementPrice, address realityPropertiesContractAddress, uint256[] memory tokenIds, address tradeTokenAddress) internal returns (uint256) {
      (address receiver, uint256 royalty) = IERC2981(realityPropertiesContractAddress).royaltyInfo(tokenIds[0], settlementPrice);
      if (tradeTokenAddress == address(0)) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = receiver.call{value: royalty}("");
        require(success, "Trade: failed to transfer royalties");
      } else {
        IERC20(tradeTokenAddress).safeTransferFrom(royaltiesPayer, receiver, royalty);
      }
      return royalty;
    }
}


// File contracts/trade/Ownable.sol



pragma solidity 0.8.9;
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
contract Ownable is TradeStorage, Initializable {
    // address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Ownable_init_unchained(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/trade/handlers/IHandler.sol



pragma solidity 0.8.9;

interface IHandler {
    function supportToken(address token) external;

    function stopSupportingToken(address token) external;

    function isSupported(address token) external view returns (bool);

    function ownerOf(address token, uint256 tokenId) external view returns (address);

    /**
     * @notice Puts a single item into the deposit - the item handler
     * @param from the previous owner
     * @param to new owner (can take out from the deposit)
     * @param stateHash expected state hash of the item 
     * @dev from address has to the owner of the item or approved
     */
    function put(address from, address to, address tokenContract, uint256 tokenId, uint256 amount, bytes32 stateHash) external;

    /**
     * @notice Puts a batch of items into the deposit - the item handler
     * @param from the previous owner
     * @param to new owner (can take out from the deposit)
     * @dev from address has to the owner of the items or approved, the function is useful for ERC1155
     */
    function batchPut(address from, address to, address tokenContract, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Takes out an item from the deposit - the item handler
     * @param recipient who gets the item
     * @param owner the address which the item is assigned to in the deposit
     * @dev only the owner can call this function
     */
    function take(address recipient, address owner, address tokenContract, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Takes out a batch of items from the deposit - the item handler
     * @param recipient who gets the items
     * @param owner the address which the items are assigned to in the deposit
     * @dev only the owner can call this function, the function is useful for ERC1155
     */
    function batchTake(address recipient, address owner, address tokenContract, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Simply transfers an item. This is an abstract for different kinds of items.
     * @dev The item owner has to approve this contact. Only authorized addresses can call this function.
     * @param stateHash This must be 0x0 for ERC1155 and ERC721 that does not support StateHash. 
     * This may be 0x0 for ERC721 that supports StateHash (like hoard-composables-erc998)
     */
    function transferFrom(address tokenAddress, address from, address to, uint256 tokenId, uint256 amount, bytes32 stateHash) external;

    /**
     * @notice Simply transfers a batch of items. This is an abstract for different kinds of items.
     * @dev The items owner has to approve this contact. Only authorized addresses can call this function.
     * The function is useful for ERC1155.
     */
    function batchTransferFrom(address tokenAddress, address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Abi encodes a transfer of an item from the owner to a recipient.
     * Encoded transfer can be used with call().
     * @dev This is used for the emergency withdrawal of stuck items by Trade and Loan.
     * Trade and Loan do not know how to handle different kind of items.
     * Note that Trade and Loan cannot delegatecall item handlers because of upgradable proxies.
     * @param from the owner
     * @param to the recipient
     * @return abi encoded transfer
     */
    function encodeTransfer(address from, address to, uint256 tokenId, uint256 amount) external pure returns (bytes memory);
}


// File contracts/trade/TradeConfig.sol



pragma solidity 0.8.9;
abstract contract TradeConfig is TradeStorage, Ownable {
    using EnumerableMap for EnumerableMap.AddressToAddressMap;
    using EnumerableMap for EnumerableMap.AddressToSupportStateMap;
    using FractionMath for FractionMath.Fraction;

    // address _feeRecipient;
    // EnumerableMap.AddressToAddressMap _tokenAddressToHandlerAddress;
    // EnumerableMap.AddressToSupportStateMap _tradeTokens;
    // mapping (address => FractionMath.Fraction) _tradeFees;

    event TradeFeesSet(address indexed tradeTokenAddress, FractionMath.Fraction _tradeFee);

    event ItemSupported(address indexed tokenAddress);
    event TradeTokenSupported(address indexed tokenAddress);
    event ItemSupportStopped(address indexed tokenAddress);
    event TradeTokenSupportStopped(address indexed tokenAddress);

    event FeeRecipientSet(address indexed feeRecipient);

    function setFeeRecipient(address __feeRecipient) external onlyOwner {
        _setFeeRecipient(__feeRecipient);
    }

    function _setFeeRecipient(address __feeRecipient) internal {
        require(address(__feeRecipient) != address(0), "Trade: Fee recipient cannot be null");
        _feeRecipient = __feeRecipient;
        emit FeeRecipientSet(__feeRecipient);
    }

    function feeRecipient() public view returns (address) {
       return _feeRecipient;
    }

    function setTradeFees(address tradeTokenAddress, FractionMath.Fraction calldata _tradeFee) public onlyOwner {
        require(isTradeTokenSupported(tradeTokenAddress), "Trade: the trade token is not supported");
        _tradeFees[tradeTokenAddress] = FractionMath.sanitize(_tradeFee);

        emit TradeFeesSet(
            tradeTokenAddress,
            _tradeFee
        );
    }

    function supportItem(IHandler handler, address tokenAddress) external onlyOwner {
        require(!_isItemTokenSupported(tokenAddress), "Trade: the item is already supported");
        _tokenAddressToHandlerAddress.set(tokenAddress, address(handler));
        emit ItemSupported(tokenAddress);

        handler.supportToken(tokenAddress);
    }

    function supportTradeToken(address tokenAddress, FractionMath.Fraction calldata _tradeFee) external onlyOwner {
        require(!isTradeTokenSupported(tokenAddress), "Trade: the ERC20 trade token is already supported");
        _tradeTokens.set(tokenAddress, EnumerableMap.SupportState.SUPPORTED);
        setTradeFees(tokenAddress, _tradeFee);
        emit TradeTokenSupported(tokenAddress);
    }

    function stopSupportingItem(address tokenAddress) external onlyOwner {
        IHandler handler = itemHandler(tokenAddress);
        emit ItemSupportStopped(tokenAddress);

        handler.stopSupportingToken(tokenAddress);
    }

    function stopSupportingTradeToken(address tokenAddress) external onlyOwner {
        require(isTradeTokenSupported(tokenAddress), "Trade: the ERC20 trade token is not supported");
        _tradeTokens.set(tokenAddress, EnumerableMap.SupportState.SUPPORT_STOPPED);
        emit TradeTokenSupportStopped(tokenAddress);
    }

    function isTradeTokenSupported(address tokenAddress) public view returns (bool) {
        return _tradeTokens.contains(tokenAddress) &&
            _tradeTokens.get(tokenAddress) == EnumerableMap.SupportState.SUPPORTED;
    }

    function wasTradeTokenEverSupported(address tokenAddress) public view returns (bool) {
        return _tradeTokens.contains(tokenAddress);
    }

    function isItemTokenSupported(address tokenAddress) external view returns (bool) {
        return _isItemTokenSupported(tokenAddress);
    }

    function totalItemTokens() external view returns (uint256) {
        return _tokenAddressToHandlerAddress.length();
    }

    function itemTokenByIndex(uint256 index) external view returns (address tokenAddress, address handlerAddress, bool isCurrentlySupported) {
        (tokenAddress, handlerAddress) = _tokenAddressToHandlerAddress.at(index);
        isCurrentlySupported = IHandler(handlerAddress).isSupported(tokenAddress);
    }

    function tradeFee(address tradeTokenAddress) external view returns (FractionMath.Fraction memory) {
        return _tradeFees[tradeTokenAddress];
    }

    function totalTradeTokens() external view returns (uint256) {
        return _tradeTokens.length();
    }

    function tradeTokenByIndex(uint256 index) external view returns (address, EnumerableMap.SupportState) {
        return _tradeTokens.at(index);
    }

    function itemHandler(address itemTokenAddress) public view returns (IHandler) {
        return IHandler(_tokenAddressToHandlerAddress.get(itemTokenAddress, "Trade: the item is not supported"));
    }

    function _isItemTokenSupported(address tokenAddress) private view returns (bool) {
        if (!_tokenAddressToHandlerAddress.contains(tokenAddress)) {
            return false;
        }
        address handler = _tokenAddressToHandlerAddress.get(tokenAddress);
        return IHandler(handler).isSupported(tokenAddress);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ├À 2 + 1, and for v in (302): v Ôêê {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/trade/verifiers/EIP712Domain.sol



pragma solidity 0.8.9;
abstract contract EIP712Domain is TradeStorage, Initializable {
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

    // bytes32 DOMAIN_SEPARATOR;

    // solhint-disable-next-line func-name-mixedcase
    function __EIP712Domain_init_unchained(string memory name, string memory version) internal { // this is not a part of initializer
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                _getChainId(),
                address(this)
            ));
    }

    function _getChainId() private view returns (uint256 id) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
    }
}


// File contracts/trade/model/TradeModel.sol



pragma solidity 0.8.9;

abstract contract TradeModel {
    string internal constant TRADE_ITEM__TYPE = "TradeItem(uint256 tokenId,uint256 amount,bytes32 stateHash)";
    string internal constant TRADE_OFFER__TYPE = "TradeOffer(uint32 nonce,uint40 expirationTime,address tradeTokenAddress,address itemsTokenAddress,TradeItem[] items,uint256 offerValue,address to)"
                                                         "TradeItem(uint256 tokenId,uint256 amount,bytes32 stateHash)";
    string internal constant TRADE_BID__TYPE = "TradeBid(uint32 nonce,uint40 expirationTime,address tradeTokenAddress,address itemsTokenAddress,TradeItem[] items,uint256 bidValue)"
                                                         "TradeItem(uint256 tokenId,uint256 amount,bytes32 stateHash)";
    struct TradeItem {
        uint256 tokenId;
        uint256 amount;
        bytes32 stateHash; // only for ERC721 tokens, set bytes32(0) for state hash to be ignored on trade validation
    }

    /**
     * @dev filed to is optional, if set to 0, defaults to sellerAddress
     */
    struct TradeOffer {
        uint32 nonce;
        uint40 expirationTime;
        address tradeTokenAddress;
        address itemsTokenAddress;
        TradeItem[] items;
        uint256 offerValue;
        address to;
    }

    struct TradeBid {
        uint32 nonce;
        uint40 expirationTime;
        address tradeTokenAddress;
        address itemsTokenAddress;
        TradeItem[] items;
        uint256 bidValue;
    }
}


// File contracts/trade/verifiers/TradeSigVerifier.sol



pragma solidity 0.8.9;
abstract contract TradeSigVerifier is TradeModel, EIP712Domain {
    using ECDSA for bytes32;

    bytes32 private constant TRADE_ITEM__TYPEHASH = keccak256(abi.encodePacked(TRADE_ITEM__TYPE));
    bytes32 private constant TRADE_OFFER__TYPEHASH = keccak256(abi.encodePacked(TRADE_OFFER__TYPE));
    bytes32 private constant TRADE_BID__TYPEHASH = keccak256(abi.encodePacked(TRADE_BID__TYPE));

    function _hashTradeItem(TradeItem calldata item) private pure returns (bytes32) {
        return keccak256(abi.encode(
                TRADE_ITEM__TYPEHASH,
                item.tokenId,
                item.amount,
                item.stateHash
            ));
    }

    function _hashItems(TradeItem[] calldata items) private pure returns (bytes32) {
        bytes32[] memory hashedItems = new bytes32[](items.length);
        for (uint i = 0; i < items.length; i++) {
            hashedItems[i] = _hashTradeItem(items[i]);
        }
        return keccak256(abi.encodePacked(hashedItems));
    }

    function _hashOffer(TradeOffer calldata offer) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRADE_OFFER__TYPEHASH,
                    offer.nonce,
                    offer.expirationTime,
                    offer.tradeTokenAddress,
                    offer.itemsTokenAddress,
                    _hashItems(offer.items),
                    offer.offerValue,
                    offer.to
                ))
            ));
    }

    function _hashBid(TradeBid calldata bid) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRADE_BID__TYPEHASH,
                    bid.nonce,
                    bid.expirationTime,
                    bid.tradeTokenAddress,
                    bid.itemsTokenAddress,
                    _hashItems(bid.items),
                    bid.bidValue
                ))
            ));
    }

    function _verifyOffer(address signerAddress, bytes calldata signature, TradeOffer calldata offer) internal view returns (bool) {
        bytes32 hash = _hashOffer(offer);
        return hash.recover(signature) == signerAddress;
    }

    function _verifyBid(address signerAddress, bytes calldata signature, TradeBid calldata bid) internal view returns (bool) {
        bytes32 hash = _hashBid(bid);
        return hash.recover(signature) == signerAddress;
    }
}


// File contracts/trade/Trade.sol



pragma solidity 0.8.9;
/**
 * @notice Trading contract: buy and sell NFTs.
 * @dev Raw ETH payments are enabled for buying on the offer trade only.
 */
contract Trade is RoyaltiesSupport, TradeStorage, Initializable, TradeSigVerifier,
        TradeConfig, IERC165 {
    using SafeERC20 for IERC20;
    using FractionMath for FractionMath.Fraction;

    // mapping (bytes32 => bool) _usedOfferSignatures;

    event OfferAccepted(address indexed buyer, address indexed seller, bytes32 signatureHash, address tokenAddress, uint256[] tokenIds);
    event OfferCanceled(address indexed seller, bytes32 signatureHash);
    event BidAccepted(address indexed buyer, address indexed seller, bytes32 signatureHash, address tokenAddress, uint256[] tokenIds);
    event BidCanceled(address indexed buyer, bytes32 signatureHash);

    string public constant NAME = "Trade";
    string public constant VERSION = "2.2.0";
    string public constant CVERSION = "2.2.0";

    constructor(address owner) {
        __Ownable_init_unchained(owner);
    }

    function initialize(address owner, address feeRecipient) public initializer {
        __Ownable_init_unchained(owner);
        __EIP712Domain_init_unchained(NAME, VERSION);
        __Trade_init_unchained(feeRecipient);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Trade_init_unchained(address feeRecipient) internal {
        _setFeeRecipient(feeRecipient);
    }

    /**
     * @notice to be called after the proxy upgrade
     * @dev it is safe to be called by anyone anytime
     * cannot be a part of initialization because it has to be called after initialization
     */
    function afterUpgrade() external {
        __EIP712Domain_init_unchained(NAME, VERSION);
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev returns if order signature has been used
     */
    function isSignatureUsed(bytes32 signatureHash) external view returns (bool) {
        return _usedOfferSignatures[signatureHash];
    }

    /**
     * @notice trade with the price set by the seller, the offer is signed by the seller, it is executed by the buyer
     * @dev You can use raw ETH for payments - offer.tradeTokenAddress should be 0.
     * If ETH is used for payment then offer.itemValue must equal msg.value, no approve is required.
     * @param offer filed offer.to is optional, if set to 0, defaults to sellerAddress
     * @dev For ERC721 token, state hash that validates the state of token can be provided and is verified on transfer. See `TradeModel.TradeItem`
     */
    function buyOnOffer(address sellerAddress, bytes calldata signature, TradeOffer calldata offer) external payable {
        IHandler handler = itemHandler(offer.itemsTokenAddress);

        require(handler.isSupported(offer.itemsTokenAddress), "Trade: the item is not supported");
        require(isTradeTokenSupported(offer.tradeTokenAddress), "Trade: the trade token is not supported");
        require(_verifyExpirationTime(offer.expirationTime), "Trade: the offer has expired");
        require(offer.items.length > 0, "Trade: at least 1 items required");
        require(offer.offerValue > 0, "Trade: trade value must be greater than 0");
        require(_allAmountsPositive(offer.items), "Trade: all amounts must be greater than 0");
        if (offer.tradeTokenAddress == address(0)) {
            require(msg.value == offer.offerValue, "Trade: eth value is incorrect");
        } else {
            require(msg.value == 0, "Trade: eth transfer is not allowed");
        }

        require(_verifyOffer(sellerAddress, signature, offer), "Trade: the signature of the offer is invalid");

        bytes32 signatureHash = keccak256(signature);
        require(!_usedOfferSignatures[signatureHash], "Trade: the offer has already been either accepted or cancelled");

        uint256 tradeFee = _tradeFees[offer.tradeTokenAddress].mul(offer.offerValue);
        _usedOfferSignatures[signatureHash] = true;

        uint256[] memory tokenIds = _getTokenIds(offer.items);

        emit OfferAccepted(msg.sender, sellerAddress, signatureHash, offer.itemsTokenAddress, tokenIds);

        uint royaltiesPaid = _payRoyalties(msg.sender, offer.offerValue, offer.itemsTokenAddress, tokenIds, offer.tradeTokenAddress);
        uint netSalePrice = offer.offerValue - tradeFee - royaltiesPaid;

        if (offer.tradeTokenAddress == address(0)) { // ETH
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(_feeRecipient).call{value: tradeFee}("");
            require(success, "Trade: ETH transfer failed 1");
            if (offer.to == address (0)) {
                // solhint-disable-next-line avoid-low-level-calls
                (success, ) = sellerAddress.call{value: netSalePrice}("");
                require(success, "Trade: ETH transfer failed 2");
            } else { // payment to additional address
                // solhint-disable-next-line avoid-low-level-calls
                (success, ) = offer.to.call{value: netSalePrice}("");
                require(success, "Trade: ETH transfer failed 2");
            }
        } else {
            IERC20(offer.tradeTokenAddress).safeTransferFrom(msg.sender, address(_feeRecipient), tradeFee);
            if (offer.to == address (0)) {
                IERC20(offer.tradeTokenAddress).safeTransferFrom(msg.sender, sellerAddress, netSalePrice);
            } else { // payment to additional address
                IERC20(offer.tradeTokenAddress).safeTransferFrom(msg.sender, offer.to, netSalePrice);
            }
        }
        if (offer.items.length == 1) {
            handler.transferFrom(offer.itemsTokenAddress, sellerAddress, msg.sender, offer.items[0].tokenId, offer.items[0].amount, offer.items[0].stateHash);
        } else {
            handler.batchTransferFrom(offer.itemsTokenAddress, sellerAddress, msg.sender, tokenIds, _getAmounts(offer.items));
        }
    }

    function _allAmountsPositive(TradeItem[] calldata items) private pure returns (bool) {
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].amount == 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice auction style trade, bid is signed by the buyer, it is executed by the seller
     * @dev You cannot use raw ETH for payment. Payment is transferred to the seller.
     * @param buyerAddress buyer's address
     * @param signature buyer's signature of the bid
     * @param bid of the buyer
     */
    function sellOnBid(address buyerAddress, bytes calldata signature, TradeBid calldata bid) external {
        _sellOnBidTo(buyerAddress, signature, bid, msg.sender);
    }

    /**
     * @notice auction style trade, bid is signed by the buyer, it is executed by the seller,
     * the payment is directed to auxiliary address - the seller is a donor for instance
     * @param buyerAddress buyer's address
     * @param signature buyer's signature of the bid
     * @param bid of the buyer
     * @param to target address for payment
     * @dev You cannot use raw ETH for payment.
     * @dev For ERC721 token, state hash that validates the state of token can be provided and is verified on transfer. See `TradeModel.TradeItem`
     */
    function sellOnBidTo(address buyerAddress, bytes calldata signature, TradeBid calldata bid, address to) external {
        require(to != address(0), "Trade: target account cannot be zero");
        _sellOnBidTo(buyerAddress, signature, bid, to);
    }

    /**
     * @dev Auction style trade. It is executed by the seller. You cannot use raw ETH for payment.
     */
    function _sellOnBidTo(address buyerAddress, bytes calldata signature, TradeBid calldata bid, address to) internal {
        IHandler handler = itemHandler(bid.itemsTokenAddress);

        require(handler.isSupported(bid.itemsTokenAddress), "Trade: the item is not supported");
        require(isTradeTokenSupported(bid.tradeTokenAddress), "Trade: the trade token is not supported");
        require(bid.items.length > 0, "Trade: at least 1 items required");
        require(_verifyExpirationTime(bid.expirationTime), "Trade: the bid has expired");
        require(bid.bidValue > 0, "Trade: trade value must be greater than 0");
        require(_allAmountsPositive(bid.items), "Trade: all amounts must be greater than 0");

        require(_verifyBid(buyerAddress, signature, bid), "Trade: the signature of the bid is invalid");

        bytes32 signatureHash = keccak256(signature);
        require(!_usedOfferSignatures[signatureHash], "Trade: the bid has already been either accepted or cancelled");

        uint256 tradeFee = _tradeFees[bid.tradeTokenAddress].mul(bid.bidValue);
        _usedOfferSignatures[signatureHash] = true;

        uint256[] memory tokenIds = _getTokenIds(bid.items);
        emit BidAccepted(buyerAddress, msg.sender, signatureHash, bid.itemsTokenAddress, tokenIds);


        uint256 royaltiesPaid = _payRoyalties(buyerAddress, bid.bidValue, bid.itemsTokenAddress, tokenIds, bid.tradeTokenAddress);
        uint netSalePrice = bid.bidValue - tradeFee - royaltiesPaid;

        IERC20(bid.tradeTokenAddress).safeTransferFrom(buyerAddress, address(_feeRecipient), tradeFee);
        IERC20(bid.tradeTokenAddress).safeTransferFrom(buyerAddress, to, netSalePrice);
        if (bid.items.length == 1) {
            handler.transferFrom(bid.itemsTokenAddress, msg.sender, buyerAddress, bid.items[0].tokenId, bid.items[0].amount, bid.items[0].stateHash);
        } else {
            handler.batchTransferFrom(bid.itemsTokenAddress, msg.sender, buyerAddress, tokenIds, _getAmounts(bid.items));
        }
    }

    function _getTokenIds(TradeItem[] calldata items) private pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](items.length);
        for (uint i = 0; i < items.length; i++) {
            tokenIds[i] = items[i].tokenId;
        }
        return tokenIds;
    }

    function _getAmounts(TradeItem[] calldata items) private pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](items.length);
        for (uint i = 0; i < items.length; i++) {
            amounts[i] = items[i].amount;
        }
        return amounts;
    }

    /**
     * @notice kill the offer signed by the seller
     * @dev the cancellation is permanent
     * you do not need to cancel expired offers
     */
    function cancelOffer(bytes calldata signature, TradeOffer calldata offer) external {
        require(_verifyOffer(msg.sender, signature, offer), "Trade: the transaction sender is not the offer signer");

        bytes32 signatureHash = keccak256(signature);
        _usedOfferSignatures[signatureHash] = true;

        emit OfferCanceled(msg.sender, signatureHash);
    }

    /**
     * @notice kill the bid signed by the buyer
     * @dev the cancellation is permanent
     * you do not need to cancel expired bids
     */
    function cancelBid(bytes calldata signature, TradeBid calldata bid) external {
        require(_verifyBid(msg.sender, signature, bid), "Trade: the transaction sender is not the bid signer");

        bytes32 signatureHash = keccak256(signature);
        _usedOfferSignatures[signatureHash] = true;

        emit BidCanceled(msg.sender, signatureHash);
    }

    /**
     * @dev the trade allows non expiring offers/bids: expirationTime == 0
     */
    function _verifyExpirationTime(uint40 expirationTime) private view returns (bool) {
       return expirationTime == 0 || block.timestamp < expirationTime;
    }

    /**
     * @notice This is the method to withdraw items that were transferred directly to Trade by mistake.
     * It can be called by authorized accounts only.
     * @dev The item contract has to be assigned to an item handler.
     * The Trade contract does not own at any time any items at the regular trades.
     */
    function emergencyNFTWithdrawal(address tokenAddress, address recipient, uint256 tokenId, uint256 amount) external onlyOwner {
        IHandler handler = itemHandler(tokenAddress);
        bytes memory encodedTransfer = handler.encodeTransfer(address(this), recipient, tokenId, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnedData) = tokenAddress.call(encodedTransfer);
        if (!success) {
            if (returnedData.length == 0) {
                revert("Trade: emergency withdrawal failed");
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, returnedData), mload(returnedData))
                }
            }
        }
    }

    /**
     * @notice This is the method to withdraw ERC20 tokens that were transferred directly to Trade by mistake.
     * It can be called by authorized accounts only.
     * @dev The Trade contract does not own at any time any ERC20 tokens at the regular trades.
     * Note that the contract does not accept ETH, so withdrawing ETH is a little redundant, ETH is 0 address.
     */
    function emergencyTradeTokenWithdrawal(address tradeTokenAddress, address recipient, uint256 amount) external onlyOwner {
        if (tradeTokenAddress == address(0)) { // ETH
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Trade: ETH transfer failed");
        } else {
            IERC20(tradeTokenAddress).safeTransfer(recipient, amount);
        }
    }
}