// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: AggregatorV3Interface.sol

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// File: IAccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: AccessManagement.sol

/**
 * @dev Library to externalize the access control features to cut down on deployed 
 * bytecode in the main contract.
 * @dev see {ViciAccess}
 * @dev Moving all of this code into this library cut the size of ViciAccess, and all of 
 * the contracts that extend from it, by about 4kb.
 */
library AccessManagement {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessManagementState {
        address contractOwner;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    
    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function DEFAULT_ADMIN_ROLE() public pure returns (bytes32) {
        return 0x00;
    }

    function BANNED_ROLE_NAME() public pure returns (bytes32) {
        return "banned";
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setContractOwner(
        AccessManagementState storage ams,
        address _newOwner
    ) external {
        require(
            ams.contractOwner == address(0) || msg.sender == ams.contractOwner
        );
        require(!isBanned(ams, _newOwner));
        require(_newOwner != address(0));
        _grantRole(ams, DEFAULT_ADMIN_ROLE(), _newOwner);
        address oldOwner = ams.contractOwner;
        ams.contractOwner = _newOwner;

        if (oldOwner != address(0)) {
            emit OwnershipTransferred(oldOwner, _newOwner);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getContractOwner(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return ams.contractOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function enforceIsContractOwner(AccessManagementState storage ams)
        public
        view
    {
        require(msg.sender == ams.contractOwner);
    }

    /**
     * @dev Throws if called by a banned account.
     */
    function enforceIsNotBanned(AccessManagementState storage ams)
        external
        view
    {
        require(!isBanned(ams, msg.sender));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view returns (bool) {
        return ams.roles[_role].members[_account];
    }

    /**
     * @dev Throws if `_account` does not have `_role`.
     */
    function checkRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (!hasRole(ams, _role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Grants `_role` to `_account`.
     */
    function grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsContractOwner(ams);
            require(_account != ams.contractOwner);
        } else {
            checkRole(ams, DEFAULT_ADMIN_ROLE(), msg.sender);
        }

        _grantRole(ams, _role, _account);
    }

    /**
     * @dev Returns `true` if `_account` is banned.
     */
    function isBanned(AccessManagementState storage ams, address _account)
        public
        view
        returns (bool)
    {
        return hasRole(ams, BANNED_ROLE_NAME(), _account);
    }

     /**
     * @dev Revokes `_role` from `_account`.
     */
    function revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        checkRole(ams, DEFAULT_ADMIN_ROLE(), msg.sender);
        require(
            _role != DEFAULT_ADMIN_ROLE() || _account != ams.contractOwner
        );
        require(
            _role != BANNED_ROLE_NAME() || msg.sender == ams.contractOwner
        );

        _revokeRole(ams, _role, _account);
    }

     /**
     * @dev Revokes `_role` from the calling account.
     */
    function renounceRole(AccessManagementState storage ams, bytes32 _role)
        external
    {
        require(
            _role != DEFAULT_ADMIN_ROLE() || msg.sender != ams.contractOwner
        );
        require(_role != BANNED_ROLE_NAME());
        _revokeRole(ams, _role, msg.sender);
    }

    /**
     * @dev Returns one of the accounts that have `_role`. `_index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     */
    function getRoleMember(
        AccessManagementState storage ams,
        bytes32 _role,
        uint256 _index
    ) external view returns (address) {
        return ams.roleMembers[_role].at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `_role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(
        AccessManagementState storage ams,
        bytes32 _role
    ) external view returns (uint256) {
        return ams.roleMembers[_role].length();
    }

    function _grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (!hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = true;
            ams.roleMembers[_role].add(_account);
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    function _revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = false;
            ams.roleMembers[_role].remove(_account);
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }
}

// File: ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: IAccessControlEnumerable.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: IERC1155.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: Pausable.sol

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: CurrencyExchange.sol

/**
 * @title CurrencyExchange
 * @dev Library for converting an amount in one supported currency to another.
 * @dev Uses USD as the intermediate currency.
 */
library CurrencyExchange {
    using SafeMath for uint256;
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Exchange {
        IERC20Metadata usdCurrency;
        mapping(IERC20Metadata => AggregatorV3Interface) tickers;
        EnumerableSet.AddressSet allSupportedTokens;
    }

    /**
     * @dev Set the currency you will use as the intermediary.
     * @dev This should be something like USDC.
     * @dev This currency should have 8 decimal places.
     */
    function setUSDCurrency(
        Exchange storage _exchange,
        IERC20Metadata _usdCurrency
    ) public {
        _exchange.usdCurrency = _usdCurrency;
    }

    /**
     * @dev Returns the number of currencies supported by the
     * exchange. The count includes the USD currency. Can be used
     * together withg {getCurrency} to enumerate all currencies.
     */
    function getCurrencyCount(Exchange storage _exchange)
        public
        view
        returns (uint256)
    {
        return _exchange.allSupportedTokens.length() + 1;
    }

    /**
     * @dev Returns one of the supported currencies. `_index` must be a
     * value between 0 and {getCurrencyCount}, exclusive.
     * 
     * An `_index` of 0 will always be the usdCurrency. The other values
     * are not sorted in any particular way.
     */
    function getCurrency(Exchange storage _exchange, uint256 _index)
        public
        view
        returns (IERC20Metadata)
    {
        if (_index == 0) {
            return _exchange.usdCurrency;
        }
        return IERC20Metadata(_exchange.allSupportedTokens.at(_index-1));
    }

    /**
     * @dev Returns true if the token is supported.
     * @dev Will always return true for the USD Currency.
     */
    function isSupportedToken(
        Exchange storage _exchange,
        IERC20Metadata _maybeToken
    ) public view returns (bool) {
        if (address(_maybeToken) == address(_exchange.usdCurrency)) {
            return true;
        }
        return address(_exchange.tickers[_maybeToken]) != address(0);
    }

    /**
     * @dev add several supported tokens all at once.
     * @dev will revert if the arrays aren't the same length.
     * @dev The exchanges should all convert to USD from the tokens
     * @dev The exchanges should all have 8 decimal places.
     */
    function addSupportedTokens(
        Exchange storage _exchange,
        IERC20Metadata[] memory _supportedTokens,
        AggregatorV3Interface[] memory _dataFeeds
    ) public {
        require(_supportedTokens.length == _dataFeeds.length);
        for (uint256 i = _supportedTokens.length - 1; i >= 0; i--) {
            addToken(_exchange, _supportedTokens[i], _dataFeeds[i]);
        }
    }

    /**
     * @dev add support for a new token.
     * @dev The exchange should convert to USD from the token
     * @dev The exchange should have 8 decimal places.
     */
    function addToken(
        Exchange storage _exchange,
        IERC20Metadata _newToken,
        AggregatorV3Interface _newDataFeed
    ) public {
        _exchange.tickers[_newToken] = _newDataFeed;
        _exchange.allSupportedTokens.add(address(_newToken));
    }

    /**
     * @dev stop supporting a token
     */
    function removeToken(Exchange storage _exchange, IERC20Metadata _oldToken)
        public
    {
        delete _exchange.tickers[_oldToken];
        _exchange.allSupportedTokens.remove(address(_oldToken));
    }

    /**
     * @dev convert an amount from one currency to another.
     */
    function convertCurrency(
        Exchange storage _exchange,
        uint256 _amount,
        IERC20Metadata _fromCurrency,
        IERC20Metadata _toCurrency
    ) public view returns (uint256) {
        if (address(_fromCurrency) == address(_toCurrency)) {
            return _amount;
        }

        uint256 usdAmount;
        if (address(_fromCurrency) == address(_exchange.usdCurrency)) {
            usdAmount = _amount;
        } else {
            usdAmount = convertToUSD(_exchange, _amount, _fromCurrency);
        }

        if (address(_toCurrency) == address(_exchange.usdCurrency)) {
            return usdAmount;
        } else {
            return convertFromUSD(_exchange, usdAmount, _toCurrency);
        }
    }

    /**
     * @dev simpler version of {convertCurrency} for when your from currency is USD.
     */
    function convertFromUSD(
        Exchange storage _exchange,
        uint256 _amount,
        IERC20Metadata _toCurrency
    ) public view returns (uint256) {
        require(
            isSupportedToken(_exchange, _toCurrency),
            "Unsupported 'to' currency"
        );

        AggregatorV3Interface toConverter = _exchange.tickers[_toCurrency];
        uint256 factor = 10**_toCurrency.decimals();
        (, int256 toAsUSD, , , ) = toConverter.latestRoundData();
        return (_amount * factor) / uint256(toAsUSD);
    }

    /**
     * @dev simpler version of {convertCurrency} for when your to currency is USD.
     */
    function convertToUSD(
        Exchange storage _exchange,
        uint256 _amount,
        IERC20Metadata _fromCurrency
    ) public view returns (uint256) {
        require(
            isSupportedToken(_exchange, _fromCurrency),
            "Unsupported 'to' currency"
        );

        AggregatorV3Interface toConverter = _exchange.tickers[_fromCurrency];
        uint256 factor = 10**_fromCurrency.decimals();
        (, int256 fromAsUSD, , , ) = toConverter.latestRoundData();
        return (_amount * uint256(fromAsUSD)) / factor;
    }
}

// File: Disbursements.sol

/**
 * @title Disbursements
 * 
 * @dev This library allows to split ERC20 payments among a group of accounts.
 * @dev The share proportions don't have to add up to any specific number, but 
 *     if the typical dispersement amounts don't divide neatly by the totalShares, 
 *     the contract will end up accumulating tiny amounts of the ERC20 tokens 
 *     from the rounding errors.
 * @dev This library is inspired by OpenZeppelin's PaymentSplitter, but differs 
 *     from it in the following ways:
 * @dev - It is possible to update a payee's share
 * @dev - It is possible to set a payee's share to 0
 * @dev - It is possible to reset and overwrite the payee distribution.
 * @dev - Payments are pushed out to payees via the `disburse` function, rather 
 *        than each payee having to call a `release` function.
 * @dev - It only supports ERC20 tokens, not native currencies.
 * @notice Don't try to use ERC20 tokens with weird tokenomics like rebasing or 
 *     inbuilt transfer fees with this library.
 */
library Disbursements {
    using SafeMath for uint256;
    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );

    struct DisbursementSchedule {
        uint256 totalShares;
        address[] payees;
        mapping(address => uint256) shares;
    }

    /**
     * @dev Returns the number of shares held by an account.
     */
    function shares(DisbursementSchedule storage _schedule, address _account)
        internal
        view
        returns (uint256)
    {
        return _schedule.shares[_account];
    }

    /**
     * @dev Returns the address for payer number `_index`.
     */
    function payee(DisbursementSchedule storage _schedule, uint256 _index)
        internal
        view
        returns (address)
    {
        return _schedule.payees[_index];
    }

    /**
     * @dev Split the amount of `_token` held by the contract using this library
     *     between all payees.
     * @dev This will do nothing except waste gas if the contract's balance is
     *     0 or if the totalShares is 0.
     */
    function disperse(
        DisbursementSchedule storage _schedule,
        IERC20Metadata _token
    ) internal {
        uint256 totalToDisperse = _token.balanceOf(address(this));
        if(totalToDisperse == 0 || _schedule.totalShares == 0) {
            return;
        }

        _doDispersement(_schedule, _token, totalToDisperse);
    }

    /**
     * @dev Split `_totalToDisperse` amount of `_token` held by the contract 
     *     using this library between all payees.
     * @dev If `_totalToDisperse` is greater than the contract balance, will
     *     split the contract balance instead.
     * @dev This will do nothing except waste gas if the contract's balance is
     *     0 or if the totalShares is 0.
     */
    function dispersePayment(
        DisbursementSchedule storage _schedule,
        IERC20Metadata _token,
        uint256 _totalToDisperse
    ) internal {
        if(_schedule.totalShares == 0) {
            return;
        }
        if (_token.balanceOf(address(this)) < _totalToDisperse) {
            _totalToDisperse = _token.balanceOf(address(this));
        }
        if (_totalToDisperse == 0) {
            return;
        }

        _doDispersement(_schedule, _token, _totalToDisperse);
    }

    function _doDispersement(
        DisbursementSchedule storage _schedule,
        IERC20Metadata _token,
        uint256 _totalToDisperse
    ) internal {
        for (uint256 i = 0; i < _schedule.payees.length; i++) {
            address account = _schedule.payees[i];
            uint256 payment = (_totalToDisperse * _schedule.shares[account]) /
                _schedule.totalShares;
            if(payment == 0) {
                continue;
            }

            SafeERC20.safeTransfer(_token, account, payment);
            emit ERC20PaymentReleased(_token, account, payment);
        }
    }

    /**
     * @dev Remove all payees.
     */
    function clearPayees(
        DisbursementSchedule storage _schedule
    ) internal {
        for (uint256 i = 0; i < _schedule.payees.length; i++) {
            address eachPayee = _schedule.payees[i];
            delete _schedule.shares[eachPayee];
            emit PayeeRemoved(eachPayee);
        }
        _schedule.totalShares = 0;
        delete _schedule.payees;
    }

    /**
     * @dev Add and/or update payees.
     */
    function setPayees(
        DisbursementSchedule storage _schedule,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(
            _payees.length == _shares.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(_payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < _payees.length; i++) {
            addPayee(_schedule, _payees[i], _shares[i]);
        }
    }

    /**
     * @dev Add or update a payee.
     */
    function addPayee(
        DisbursementSchedule storage _schedule,
        address _account,
        uint256 _shares
    ) internal {
        require(
            _account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        if (_schedule.shares[_account] > 0) {
            _updatePayee(_schedule, _account, _shares);
        } else if (_shares > 0) {
            _addPayee(_schedule, _account, _shares);
        }
    }

    function _addPayee(
        DisbursementSchedule storage _schedule,
        address _account,
        uint256 _shares
    ) internal {
        _schedule.payees.push(_account);
        _schedule.shares[_account] = _shares;
        _schedule.totalShares += _shares;
        emit PayeeAdded(_account, _shares);
    }

    function _updatePayee(
        DisbursementSchedule storage _schedule,
        address _account,
        uint256 _shares
    ) internal {
        _schedule.totalShares += _shares;
        uint256 oldShares = _schedule.shares[_account];
        _schedule.totalShares -= oldShares;
        _schedule.shares[_account] = _shares;
        
        if (_shares == 0) {
            emit PayeeRemoved(_account);
        } else {
            emit PayeeAdded(_account, _shares);
        }
    }
}

// File: ViciAccess.sol

/**
 * @title ViciAccess
 * @author Josh Davis <[email protected]>
 */
abstract contract ViciAccess is IAccessControlEnumerable, Context, ERC165 {
    using AccessManagement for AccessManagement.AccessManagementState;

    AccessManagement.AccessManagementState ams;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Role for banned users.
    bytes32 public constant BANNED_ROLE_NAME = "banned";

    constructor() {
        ams.setContractOwner(msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
            interfaceId == type(IAccessControl).interfaceId || 
            interfaceId == type(IAccessControlEnumerable).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier onlyOwnerOrRole(bytes32 role) {
        if (_msgSender() != owner()) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    modifier noBannedAccounts() {
        require(!hasRole(BANNED_ROLE_NAME, _msgSender()));
        _;
    }

    function _isBanned(address account) internal virtual returns (bool) {
        return hasRole(BANNED_ROLE_NAME, account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return ams.hasRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        ams.checkRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32) public pure override returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `roll` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     *
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
    {
        ams.grantRole(role, account);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return ams.getContractOwner();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return ams.getRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return ams.getRoleMemberCount(role);
    }

    /**
     * Make another account the owner of this contract.
     * @param newOwner the new owner.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `newOwner` MUST NOT have the banned role.
     */
    function transferOwnership(address newOwner)
        public
        virtual
    {
        ams.setContractOwner(newOwner);
    }

    /**
     * Take the role away from the account. This will throw an exception
     * if you try to take the admin role (0x00) away from the owner.
     *
     * Requirements:
     *
     * - Calling user has admin role.
     * - If `role` is admin, `address` MUST NOT be owner.
     * - if `role` is banned, calling user MUST be owner.
     *
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
    {
        ams.revokeRole(role, account);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` MUST be the same as the calling user.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role, address)
        public
        virtual
        override
    {
        ams.renounceRole(role);
    }
}

// File: BaseViciContract.sol

abstract contract BaseViciContract is ViciAccess, Pausable {
	constructor() {
	}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	
	function _withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(
			address(this), toAddress, tokenId, amount, data
		);
	}
	
	function withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) public virtual onlyOwner {
		_withdrawERC1155(tokenId, amount, toAddress, data, tokenContract);
	}
	
	function _withdraw(
		address payable toAddress
	) internal virtual {
		toAddress.transfer(address(this).balance);
	}
	
	function withdraw(
		address payable toAddress
	) public virtual onlyOwner {
		_withdraw(toAddress);
	}

	receive() external payable virtual {}
}
// File: Marketplace.sol

struct Item {
    uint256 itemId;
    uint256 pricePerUnit;
    uint256 minQuantity;
    uint256 maxQuantity;
}

contract Marketplace is BaseViciContract {
    using SafeMath for uint256;
    using CurrencyExchange for CurrencyExchange.Exchange;
    using Disbursements for Disbursements.DisbursementSchedule;

    bytes32 public constant STOCK_BOY = "Stock boy";
    bytes32 public constant EXCHANGE_MANAGER = "Exchange Manager";
    bytes32 public constant DISBURSEMENTS_MANAGER = "Disbursements Manager";

    event PaymentReceived(
        address payer,
        uint256 amount,
        IERC20Metadata currency,
        uint256 quantity,
        Item item,
        bytes arguments
    );
    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(uint256 => Item) internal items;
    mapping(uint256 => uint256) internal inventory;
    mapping(uint256 => Disbursements.DisbursementSchedule)
        internal accountsPayable;
    CurrencyExchange.Exchange exchange;
    IERC20Metadata public itemCurrency;

    /**
     * @param _usdCurrency A token to indicate the customer is paying in USD.
     *      It doesn't have to be a real token, but the decimals should be 8.
     * @param _itemCurrency The currency used to price items for sale. If you are
     *      pricing your items in USD, this should be the same as `_usdCurrency`.
     * @param _itemCurrencyFeed The oracle contract that converts `_itemCurrency`
     *      to USD. If your `_itemCurrency` is USD, then this should be address(0)
     */
    constructor(
        IERC20Metadata _usdCurrency,
        IERC20Metadata _itemCurrency,
        AggregatorV3Interface _itemCurrencyFeed
    ) {
        itemCurrency = _itemCurrency;
        exchange.setUSDCurrency(_usdCurrency);
        if (address(_itemCurrency) != address(_usdCurrency)) {
            exchange.addToken(_itemCurrency, _itemCurrencyFeed);
        }
    }

    /**
     * @dev Returns the item for an id. Will revert if the `_itemId` is invalid.
     */
    function getItem(uint256 _itemId) public view returns (Item memory) {
        Item storage item = items[_itemId];
        require(_isValidItem(item), "Unknown item");
        return item;
    }

    /**
     * @dev Returns true if `_itemId` is a valid item.
     */
    function isValidItem(uint256 _itemId) public view returns (bool) {
        return _isValidItem(items[_itemId]);
    }

    function _isValidItem(Item storage _item) internal view returns (bool) {
        return _item.maxQuantity != 0;
    }

    /**
     * @dev Set the payment distribution for an item
     * @param _itemId The item id
     * @param _payees The addresses of the payment recipients
     * @param _shares The number of shares owned by each recipient
     *
     * Emits a {PayeeAdded} event for each member of `_payees` with a nonzero value in `_shares`.
     * Emits a {PayeeRemoved} event for each previously existing payee, if any.
     *
     * Requirements:
     * - `_itemId` MAY refer to an invalid item. You can set the royalties before adding the item.
     * - `_itemId` MAY already have royalties set up for it. In this case, the existing royalties
     *    schedule will be replaced by this one.
     * - `_payees` and `_shares` MUST be the same length.
     * - `_payees` MUST NOT contain the null address.
     * - `_shares` MAY contain zeros. Any recipients at the same index will receive no disbursements.
     */
    function setRoyalties(
        uint256 _itemId,
        address[] memory _payees,
        uint256[] memory _shares
    ) public onlyOwnerOrRole(DISBURSEMENTS_MANAGER) {
        if (areDispersmentsInitialized(_itemId)) {
            accountsPayable[_itemId].clearPayees();
        }
        accountsPayable[_itemId].setPayees(_payees, _shares);
    }

    /**
     * @dev Add or update a payee for an item.
     * @param _itemId The item id
     * @param _account The address of the payee to add or update.
     * @param _shares The number of shares owned by the payee.
     *
     * Emits a {PayeeAdded} event if `_account` is a new payee.
     * Emits a {PayeeRemoved} event if `_account` was an exiting payee and `_shares` is 0.
     *
     * Requirements:
     * - `_itemId` MAY refer to an invalid item. You can set the royalties before adding the item.
     * - `_account` MUST NOT be the null address.
     * - `_shares` MAY be zero, in which case `_account` will no longer receive disbursements.
     */
    function addRoyaltyRecipient(
        uint256 _itemId,
        address _account,
        uint256 _shares
    ) public onlyOwnerOrRole(DISBURSEMENTS_MANAGER) {
        accountsPayable[_itemId].addPayee(_account, _shares);
    }

    /**
     * @dev returns true if royalties have been set up for the `_itemId`.
     */
    function areDispersmentsInitialized(uint256 _itemId)
        public
        view
        returns (bool)
    {
        return
            accountsPayable[_itemId].totalShares > 0 &&
            accountsPayable[_itemId].payees.length > 0;
    }

    /**
     * @dev Add or update an Item
     * @dev If `_itemId` represents a valid item, this will update the item.
     * @dev If `_itemId` does not represent a valid item, this will create a new item.
     * @param _itemId The item id
     * @param _pricePerUnit The price in `itemCurrency` * (10**decimals), e.g., an item
     *      price of 1 in a currency with 18 decimals would have a `_pricePerUnit` of
     *      1000000000000000000.
     * @param _minQuantity The minimum quantity that can be purchased in one transaction.
     * @param _maxQuantity The maximum quantity that can be purchased in one transaction.
     * @param _inventory The initial inventory for this item.
     *
     * Requirements:
     *
     * - Caller MUST be owner or have the STOCK_BOY role.
     * - `_minQuantity` MUST be greater than 0.
     */
    function setItem(
        uint256 _itemId,
        uint256 _pricePerUnit,
        uint256 _minQuantity,
        uint256 _maxQuantity,
        uint256 _inventory
    ) public onlyOwnerOrRole(STOCK_BOY) {
        if (isValidItem(_itemId)) {
            inventory[_itemId] += _inventory;
        } else {
            inventory[_itemId] = _inventory;
        }

        require(_minQuantity > 0);

        items[_itemId] = Item(
            _itemId,
            _pricePerUnit,
            _minQuantity,
            _maxQuantity
        );
    }

    /**
     * @notice Returns the available inventory for the `_itemId`.
     * @dev Returns 0 if called with an invalid `_itemId`.
     */
    function getInventory(uint256 _itemId) public view returns (uint256) {
        return inventory[_itemId];
    }

    /**
     * @dev Deletes an item.
     *
     * Requirements:
     *
     * - Caller MUST be owner or have the STOCK_BOY role.
     * - This function MAY  be called with an invalid `_itemId`.
     */
    function deleteItem(uint256 _itemId) public onlyOwnerOrRole(STOCK_BOY) {
        delete inventory[_itemId];
        delete items[_itemId];
    }

    /**
     * @dev Sets the available inventory for an item to the new value.
     * @param _itemId The item id
     * @param _inventory The new inventory total
     *
     * Requirements:
     *
     * - Caller MUST be owner or have the STOCK_BOY role.
     * - `_itemId` MUST refer to a valid item.
     */
    function setInventory(uint256 _itemId, uint256 _inventory)
        public
        onlyOwnerOrRole(STOCK_BOY)
    {
        require(isValidItem(_itemId), "Unknown item");
        inventory[_itemId] = _inventory;
    }

    /**
     * @dev Adjustments the inventory for an item up or down by some amount.
     * @dev Call this function with a negative `_adjustment` if items are sold
     *      outside of this contract.
     * @dev Call this function with a positive `_adjustment` if new items are made
     *      available.
     * @param _itemId The item id
     * @param _adjustment The amount to add (or subtract if negtive)
     *
     * Requirements:
     *
     * - Caller MUST be owner or have the STOCK_BOY role.
     * - `_itemId` MUST refer to a valid item.
     * - If `_adjustment` is negative, then the absolute value MUST NOT be
     *      greater than the current inventory.
     */
    function adjustInventory(uint256 _itemId, int256 _adjustment)
        public
        onlyOwnerOrRole(STOCK_BOY)
    {
        require(isValidItem(_itemId), "Unknown item");
        int256 inventoryCount = int256(inventory[_itemId]);
        if (_adjustment < 0) {
            require(
                inventoryCount >= -_adjustment,
                "Negative adjustment too high"
            );
        }

        inventory[_itemId] = uint256(inventoryCount + _adjustment);
    }

    /**
     * @notice Returns the price for an item demoninated in the specified currency.
     * @notice Reverts if `_itemId` does not refer to a valid item.
     * @notice Reverts if `_currency` is not supported.
     */
    function getPerUnitPriceForCurrency(
        uint256 _itemId,
        IERC20Metadata _currency
    ) public view returns (uint256) {
        Item memory item = getItem(_itemId);
        return _convertPayment(_currency, item, 1);
    }

    /**
     * @notice Pay for one or more items in the specified currency.
     * @notice Before calling this function, you MUST call approve on the `_currency`
     *      contract, and grant this contract a sufficient allowance in the amount to
     *      purchase the items.
     * @notice You SHOULD grant an allowance equal to the total puchace price plus
     *      an amount of "slippage" you are willing to tolerate.
     * @notice Emits {PaymentReceived}.
     * @notice Emits {ERC20PaymentReleased} for each recipient.
     * @dev If successful, the inventory for the item will be reduced by `_quantity`.
     * @param _currency The payment currency
     * @param _itemId The item id
     * @param _quantity The quantity to purchase.
     * @param _arguments Additional calldata passed in.
     *
     * Requirements:
     * - `_currency` MUST be a supported currency.
     * - `_itemId` MUST refer to a valid item.
     * - `_quantity` MUST be >=  the item's `minQuantity`.
     * - `_quantity` MUST be <=  the item's `maxQuantity`.
     * - `_quantity` MUST be <= the available inventory.
     * - The caller MUST have already granted an allowance on the ERC20 contract
     *      sufficient to cover the purchase.
     */
    function pay(
        IERC20Metadata _currency,
        uint256 _itemId,
        uint256 _quantity,
        bytes memory _arguments
    ) public noBannedAccounts whenNotPaused {
        Item memory item = getItem(_itemId);
        require(_quantity <= inventory[item.itemId], "Insufficient Inventory");
        require(_quantity >= item.minQuantity, "Quantity below minimum");
        require(_quantity <= item.maxQuantity, "Quantity below minimum");
        uint256 requestedAmount = _convertPayment(_currency, item, _quantity);

        _currency.transferFrom(msg.sender, address(this), requestedAmount);
        inventory[_itemId] -= _quantity;

        emit PaymentReceived(
            msg.sender,
            requestedAmount,
            _currency,
            _quantity,
            item,
            _arguments
        );

        _postPayment(_itemId, _quantity, _arguments);
        if (areDispersmentsInitialized(_itemId)) {
            accountsPayable[_itemId].dispersePayment(
                _currency,
                requestedAmount
            );
        }
    }

    /**
     * @dev hook for subclasses to do stuff after payment is accepted.
     */
    function _postPayment(
        uint256 _itemId,
        uint256 _quantity,
        bytes memory _arguments
    ) internal {}

    /**
     * @dev Returns the number of currencies supported by the
     * exchange. The count includes the USD currency. Can be used
     * together withg {getCurrency} to enumerate all currencies.
     */
    function getCurrencyCount() public view returns (uint256) {
        return exchange.getCurrencyCount();
    }

    /**
     * @dev Returns one of the supported currencies. `_index` must be a
     * value between 0 and {getCurrencyCount}, exclusive.
     * 
     * An `_index` of 0 will always be the usdCurrency. The other values
     * are not sorted in any particular way.
     */
    function getCurrency(uint256 _index) public view returns (IERC20Metadata) {
        return exchange.getCurrency(_index);
    }

    /**
     * @dev Returns true if the ERC20 token is supported.
     */
    function isSupportedToken(IERC20Metadata _maybeToken)
        public
        view
        returns (bool)
    {
        return exchange.isSupportedToken(_maybeToken);
    }

    /**
     * @dev Start accepting payments in a new currency.
     * @param _newToken The address for the ERC20 contract.
     * @param _newDataFeed The oracle contract that converts `_newToken` to USD.
     *
     * Requirements
     *
     * - Caller MUST be owner or have EXCHANGE_MANAGER role.
     */
    function addToken(
        IERC20Metadata _newToken,
        AggregatorV3Interface _newDataFeed
    ) public onlyOwnerOrRole(EXCHANGE_MANAGER) {
        exchange.addToken(_newToken, _newDataFeed);
    }

    /**
     * @dev Stop accepting payments in a currency
     * @param _oldToken The address for the ERC20 contract.
     *
     * Requirements
     *
     * - Caller MUST be owner or have EXCHANGE_MANAGER role.
     * - `_oldToken` MUST NOT be the `itemCurrency`.
     */
    function removeToken(IERC20Metadata _oldToken)
        public
        onlyOwnerOrRole(EXCHANGE_MANAGER)
    {
        require(
            address(_oldToken) != address(itemCurrency),
            "Can't remove item currency."
        );
        exchange.removeToken(_oldToken);
    }

    function _convertPayment(
        IERC20Metadata _currency,
        Item memory _item,
        uint256 _quantity
    ) internal view returns (uint256) {
        require(exchange.isSupportedToken(_currency), "Unsupported Currency");

        uint256 requestedAmount = _item.pricePerUnit * _quantity;
        if (_currency == itemCurrency) {
            return requestedAmount;
        }

        return
            exchange.convertCurrency(requestedAmount, itemCurrency, _currency);
    }
}

// File: DefaultTestnetMarketplace.sol

/**
 * @title DefaultTestnetMarketplace
 * @dev This test version is preloaded with currency price feeds from various
 *     mock currencies.
 */
contract DefaultTestnetMarketplace is Marketplace {
    using CurrencyExchange for CurrencyExchange.Exchange;

    constructor()
        Marketplace(
            IERC20Metadata(address(0xF40e4B4147A6d62301ef532DD61B3840D6CAE71D)), // MockUSD is USD
            IERC20Metadata(address(0xF40e4B4147A6d62301ef532DD61B3840D6CAE71D)), // MockUSD is item price
            AggregatorV3Interface(address(0x00))
        )
    {
        require(block.chainid == 80001, "Deploy on Mumbai chain only");
    }
}