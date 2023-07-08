/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/IAccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/access/AccessControlEnumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: delorean/EvokeMarketplaceWithEscrow.sol



pragma solidity ^0.8.9;












interface EscrowFactory {
    struct CreatEscrowOptions {
        address receiver;
        address nftAddress;
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        address currency;
    }

    struct NftInfo {
        string metaHash;
        address royaltyReceiver;
        uint256 royaltyPercentage;
    }

    struct Fee {
        address receiver;
        uint256 percentageValue;
    }

    function createEscrow(
        CreatEscrowOptions calldata _escrowOptions,
        bool _isResell,
        NftInfo calldata _nftData,
        Fee calldata _fees
    ) external payable;
}

contract EvokeMarketplace is AccessControlEnumerable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    struct Sale {
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        address erc20Token;
        address seller;
        bool isResell;
    }

    struct TransferOptions {
        address receiver;
        address nftAddress;
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        address currency;
        bool isAuction;
    }

    struct Auction {
        uint256 tokenId;
        uint256 basePrice;
        uint256 salePrice;
        address erc20Token;
        uint256 quantity;
        address auctioner;
        address currentBidder;
        uint256 bidAmount;
        bool isResell;
    }

    struct NftInfo {
        string metaHash;
        address royaltyAddress;
        uint256 royaltyAmount;
    }

    struct Fee {
        address receiver;
        uint256 percentageValue;
    }

    struct CartItem {
        uint256 _tokenId;
        uint256 _quantity;
        address _nftAddress;
        address _sellerAddress;
        uint256 _saleType;
    }

    event NftListed(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        address erc20Token,
        uint256 quantity
    );

    event NftSold(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        address erc20Token,
        address buyer,
        uint256 quantity
    );

    event SaleCanceled(uint256 tokenId, address sellerOrAdmin);

    event AuctionCreated(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed auctioner,
        uint256 basePrice,
        uint256 salePrice,
        address erc20Token,
        uint256 quantity
    );

    event BidPlaced(
        uint256 indexed tokenId,
        address indexed tokenContract,
        address indexed auctioner,
        address bidder,
        address erc20Token,
        uint256 quantity,
        uint256 price
    );

    event AuctionSettled(
        uint256 indexed tokenId,
        address indexed tokenContract,
        address indexed auctioner,
        address heighestBidder,
        address erc20Token,
        uint256 quantity,
        uint256 heighestBid
    );

    event AuctionCancelled(
        uint256 indexed tokenId,
        address indexed tokenContract,
        address indexed auctioner,
        uint256 quantity,
        address erc20Token,
        uint256 heighestBid,
        address heighestBidder
    );

    event FundTransfer(Fee sellerProfit, Fee platformFee);

    event FundReceived(address indexed from, uint256 amount);

    event RefundAuction(address indexed buyer, uint256 price);

    // Define the admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Define sale type, based this it is determined to start a fixed price sale or auction
    uint256 private constant TYPE_SALE = 1;
    uint256 private constant TYPE_AUCTION = 2;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0x0000000000000000000000000000000000001010);

    /*
        @notice only admin and nft owner can cancel the sale
    */

    mapping(address => mapping(uint256 => mapping(address => Sale)))
        private mapSale;
    mapping(address => mapping(uint256 => mapping(address => Auction)))
        private mapAuction;
    mapping(address => mapping(uint256 => NftInfo)) private mapNftInfo;

    Fee private platformFee;

    address payable escrowContract;

    bytes4 private ERC721InterfaceId = 0x80ac58cd; // Interface Id of ERC721
    bytes4 private ERC1155InterfaceId = 0xd9b67a26; // Interface Id of ERC1155
    // bytes4 private royaltyInterfaceId = 0x2a55205a; // interface Id of Royalty
    using SafeERC20 for IERC20;

    /*
     * @notice Constructor
     * @param _erc721Token accept collection (nft contract) address
     */
    constructor(
        Fee memory _platformFee,
        address _rootAdmin,
        address payable _escrowContractAddress
    ) {
        _setPlatformFee(_platformFee);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, _rootAdmin);
        escrowContract = _escrowContractAddress;
    }

    function PlatformFee(Fee memory _platformFee) external onlyOwner {
        _setPlatformFee(_platformFee);
    }

    function setEscrowContractAddress(address payable _escrowContractAddress)
        external
        onlyOwner
    {
        escrowContract = _escrowContractAddress;
    }

    /**
     * @dev modifier to check admin rights.
     * contract owner and root admin have admin rights
     */
    modifier onlyOwner() {
        require(_isAdmin(), "Restricted to admin");
        _;
    }
    modifier callerNotAContract() {
        require(msg.sender == tx.origin, "Caller cannot be a contract");
        _;
    }

    /*w
     * @notice listNft add nfts for the sale
     * @param tokenid accept nft token id
     * @param price accept nft price
     * @param erc20Token accept erc20 token address for accepting multiple erc20 token for but nfts
     */
    function listNft(
        uint256 _tokenId,
        uint256 _price,
        uint256 _quantity,
        address _erc20Token,
        address _seller,
        address _nftAddress,
        string memory _ipfsHash,
        address _royaltyReciever,
        uint256 _royaltyPercentage,
        bool _isResell
    ) external onlyOwner {
        require(_price > 0, "Sell Nfts: Wont Accept Zero Price");
        require(_quantity > 0, "Sell Nfts: Wont Accept Zero Value");
        require(_seller != address(0), "Sell Nfts: Zero Address");
        require(
            _nftAddress != address(0),
            "Sell Nfts: Nft Address Can Not Be Zero"
        );
        require(
            _isNFT(_nftAddress),
            "Sell Nfts: Not confirming to an NFT contract"
        );

        if (_isResell) {
            require(
                _checkTokenApproval(_nftAddress, _tokenId, _quantity, _seller),
                "Sell Nfts: Token Approval Missing or Not Correct Quantity"
            );
        }
        _setNftDetails(
            _nftAddress,
            _tokenId,
            _ipfsHash,
            _royaltyReciever,
            _royaltyPercentage
        );
        _setSaleDetails(
            _tokenId,
            _price,
            _quantity,
            _erc20Token,
            _seller,
            _nftAddress,
            _isResell
        );

        emit NftListed(
            _tokenId,
            _nftAddress,
            _seller,
            _price,
            _erc20Token,
            _quantity
        );
    }

    /*
     * This function used to save nft informations to mint
     */
    function _setNftDetails(
        address _nftAddress,
        uint256 _tokenId,
        string memory _ipfsHash,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        NftInfo storage NftInfoStored = mapNftInfo[_nftAddress][_tokenId];

        // Storing basic nft informations only if it is not already stored.
        if (bytes(NftInfoStored.metaHash).length == 0) {
            NftInfoStored.metaHash = _ipfsHash;
            NftInfoStored.royaltyAddress = _royaltyReceiver;
            NftInfoStored.royaltyAmount = _royaltyAmount;
        }
    }

    /*
     * @notice SellNfts add nfts on the sale
     * @param starttime accept start time of sale
     * @param endtime accept end time of sale
     * @param tokenid accept nft token id
     * @param price accept nft price
     * @param erc20Token accept erc20 token address for accepting multiple erc20 token for but nfts
     */
    function _setSaleDetails(
        uint256 _tokenId,
        uint256 _price,
        uint256 _quantity,
        address _erc20Token,
        address _sellerAddress,
        address _nftAddress,
        bool _isResell
    ) internal {
        Sale storage NftForSale = mapSale[_nftAddress][_tokenId][
            _sellerAddress
        ];

        // Giving the ability to increase the quantity if the item is already listed
        // Otherwise create a new listing
        if (NftForSale.quantity > 0) {
            NftForSale.quantity += _quantity;
        } else {
            NftForSale.tokenId = _tokenId;
            NftForSale.price = _price;
            NftForSale.quantity = _quantity;
            NftForSale.erc20Token = _erc20Token;
            NftForSale.seller = _sellerAddress;
            NftForSale.isResell = _isResell;
        }
    }

    /*
     * @notice get details of sell nfts using token id
     * @param starttime selling start time
     * @param endTime selling end time
     * @param tokenid accept nft token id
     * @param price accept nft price
     * @param erc20Token accept erc20 token address for accepting multiple erc20 token for but nfts
     * @param seller address give nfts seller address
     * @param onsale nfts is on sale or not
     * @param sold nfts is sold or not
     * @param cancel nfts is cancel or not
     */
    function getSale(
        uint256 tokenId,
        address _nftAddress,
        address _sellerAddress
    ) public view returns (Sale memory) {
        Sale storage NftForSale = mapSale[_nftAddress][tokenId][_sellerAddress];
        return (NftForSale);
    }

    /*
     * @notice this function is used to buy nfts using native crypto currency and multiple erc20 token
     * @param _tokenId use to buy nfts on sell
     * @param _quantity Token Quantity
     * @param _nftAddress Take erc721 and erc1155 address
     */
    function buyNft(CartItem[] calldata _cartItems)
        external
        payable
        nonReentrant
    {
        require(msg.sender != address(0), "BuyNfts: Zero Address");

        for (uint256 i = 0; i < _cartItems.length; i++) {
            require(
                _cartItems[i]._nftAddress != address(0),
                "BuyNfts: Zero Address"
            );

            if (_cartItems[i]._saleType == TYPE_SALE) {
                require(_cartItems[i]._quantity > 0, "BuyNfts: Zero Quantitiy");
                _NftSaleFixedPrice(
                    _cartItems[i]._tokenId,
                    _cartItems[i]._quantity,
                    _cartItems[i]._nftAddress,
                    _cartItems[i]._sellerAddress
                );
            } else if (_cartItems[i]._saleType == TYPE_AUCTION) {
                _NftAuctionInstantBuy(
                    _cartItems[i]._tokenId,
                    _cartItems[i]._nftAddress,
                    _cartItems[i]._sellerAddress
                );
            } else {
                revert("Sale type is invalid");
            }
        }
    }

    /*
     * @notice This function can only be called by the admin account
     *         The fiat payment will be converted into to crypto via on-ramp and transferred to the contract for
     *         administering the payment split and token transfer on-chain
     *         IMPORTANT: It should only be called after the right amount of crypto/token should received in the contract
     *         The transfer should be confirmed off chain before calling this function
     * @param _tokenId use to buy nfts on sell
     * @param _quantity Token Quantity
     * @param _nftAddress Take erc721 and erc1155 address
     */
    function fiatPurchase(
        address _buyer,
        CartItem[] calldata _cartItems
    ) public payable onlyOwner nonReentrant {
        for (uint256 i = 0; i < _cartItems.length; i++) {
            require(_cartItems[i]._nftAddress != address(0), "BuyNfts: Zero Address");

            if (_cartItems[i]._saleType == TYPE_SALE) {
                require(_cartItems[i]._quantity > 0, "BuyNfts: Zero Quantitiy");
                _NftSaleFixedPriceFiat(
                    _cartItems[i]._tokenId,
                    _cartItems[i]._quantity,
                    _cartItems[i]._nftAddress,
                    _cartItems[i]._sellerAddress,
                    _buyer
                );
            } else if (_cartItems[i]._saleType == TYPE_AUCTION) {
                _NftAuctionInstantBuyFiat(
                    _cartItems[i]._tokenId,
                    _cartItems[i]._nftAddress,
                    _cartItems[i]._sellerAddress,
                    _buyer
                );
            } else {
                revert("Sale type is invalid");
            }
        }
    }

    /*
     * @notice this function is used to cancel the sell
     * @param _tokenId : Is the token ID
     * @param _nftAddress : NFT contract address
     * @param _sellerAddress : The address of the seller
     */
    function cancelListing(
        uint256 _tokenId,
        address _nftAddress,
        address _sellerAddress
    ) public {
        Sale storage NftForSale = mapSale[_nftAddress][_tokenId][
            _sellerAddress
        ];
        require(
            msg.sender == NftForSale.seller || _isAdmin(),
            "Cancel Listing : Only Seller or admin can cancel the Listing"
        );
        require(NftForSale.quantity > 0, "Buy Nfts :No active sale");

        delete mapSale[_nftAddress][_tokenId][_sellerAddress];

        emit SaleCanceled(_tokenId, msg.sender);
    }

    /*
     * @notice SellNfts add nfts on the sale
     * @param starttime accept start time of sale
     * @param endtime accept end time of sale
     * @param tokenid accept nft token id
     * @param price accept nft price
     * @param erc20Token accept erc20 token address for accepting multiple erc20 token for but nfts
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _salePrice,
        uint256 _quantity,
        address _erc20Token,
        address _auctioner,
        address _nftAddress,
        string memory _ipfsHash,
        address _royaltyReciever,
        uint256 _royaltyPercentage,
        bool _isResell
    ) public onlyOwner {
        require(_basePrice > 0, "CreateAuction : Not Accept Zero BasePrice");
        require(_quantity != 0, "CreateAuction: Zero Quantity");
        require(_auctioner != address(0), "CreateAuction: Zero Address");
        require(_nftAddress != address(0), "CreateAuction: Zero Address");
        require(
            _isNFT(_nftAddress),
            "CreateAuction: Not confirming to an NFT contract"
        );

        if (_isResell) {
            require(
                _checkTokenApproval(
                    _nftAddress,
                    _tokenId,
                    _quantity,
                    _auctioner
                ),
                "CreateAuction: Token Approval Missing or Not Correct Quantity"
            );
        }

        _setNftDetails(
            _nftAddress,
            _tokenId,
            _ipfsHash,
            _royaltyReciever,
            _royaltyPercentage
        );
        setAuctionDetails(
            _tokenId,
            _basePrice,
            _salePrice,
            _quantity,
            _erc20Token,
            _auctioner,
            _nftAddress,
            _isResell
        );

        emit AuctionCreated(
            _tokenId,
            _nftAddress,
            _auctioner,
            _basePrice,
            _salePrice,
            _erc20Token,
            _quantity
        );
    }

    /*
        @notice This SetAuctionDetails is used to set the auction details
    */
    function setAuctionDetails(
        uint256 _tokenId,
        uint256 _basePrice,
        uint256 _salePrice,
        uint256 _quantity,
        address _erc20Token,
        address _auctioner,
        address _nftAddress,
        bool _isResell
    ) internal {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];
        NftOnAuction.tokenId = _tokenId;
        NftOnAuction.basePrice = _basePrice;
        NftOnAuction.salePrice = _salePrice;
        NftOnAuction.erc20Token = _erc20Token;
        NftOnAuction.quantity = _quantity;
        NftOnAuction.auctioner = _auctioner;
        NftOnAuction.isResell = _isResell;
    }

    /*
     * @notice this function is used to buy nfts using native crypto currency and multiple erc20 token
     * @param _tokenId use to buy nfts on sell
     */

    function getAuction(
        uint256 tokenId,
        address _nftAddress,
        address _auctioner
    ) external view returns (Auction memory) {
        Auction storage nftOnAuction = mapAuction[_nftAddress][tokenId][
            _auctioner
        ];
        return (nftOnAuction);
    }

    /*
     * @notice this function is used to place the bid on the nfts using native cryptocurrency and multiple erc20 token
     * @param _tokenId use to bid on nfts
     * @param _price is used to bid on nfts
     */

    function placeBid(
        uint256 _tokenId,
        uint256 _price,
        address _nftAddress,
        address _auctioner
    ) public payable nonReentrant callerNotAContract {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];

        require(
            NftOnAuction.quantity > 0,
            "Place Bid: Bid for non existing auction"
        );

        require(!_isAdmin(), "Place Bid: Admin Can Not Place Bid");

        require(
            msg.sender != NftOnAuction.auctioner,
            "Place Bid: Seller not allowed to place bid"
        );
        require(
            _price >= NftOnAuction.basePrice,
            "Place Bid: Price Less Than the base price"
        );
        require(
            _price > NftOnAuction.bidAmount,
            "Place Bid: The price is less then the previous bid amount"
        );

        if (NftOnAuction.erc20Token == address(NATIVE_TOKEN_ADDRESS)) {
            require(
                msg.value == _price,
                "Amount received and price should be same"
            );
            require(
                msg.value > NftOnAuction.bidAmount,
                "Amount received should be grather than the current bid"
            );
            if (NftOnAuction.currentBidder != address(0)) {
                payable(NftOnAuction.currentBidder).transfer(
                    NftOnAuction.bidAmount
                );
            }
        } else {
            uint256 checkAllowance = IERC20(NftOnAuction.erc20Token).allowance(
                msg.sender,
                address(this)
            );
            require(
                checkAllowance >= _price,
                "Place Bid : Allowance is Less then Price"
            );
            IERC20(NftOnAuction.erc20Token).safeTransferFrom(
                msg.sender,
                address(this),
                _price
            );
            if (NftOnAuction.currentBidder != address(0)) {
                IERC20(NftOnAuction.erc20Token).safeTransfer(
                    NftOnAuction.currentBidder,
                    NftOnAuction.bidAmount
                );
            }
        }

        NftOnAuction.bidAmount = _price;
        NftOnAuction.currentBidder = msg.sender;

        emit BidPlaced(
            _tokenId,
            _nftAddress,
            _auctioner,
            msg.sender,
            NftOnAuction.erc20Token,
            NftOnAuction.quantity,
            _price
        );
    }

    //this function is used to settle auction
    function settleAuction(
        uint256 _tokenId,
        address _nftAddress,
        address _auctioner
    ) public onlyOwner {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];

        if (NftOnAuction.currentBidder != address(0)) {
            TransferOptions memory transferOptions;
            transferOptions.receiver = NftOnAuction.currentBidder;
            transferOptions.nftAddress = _nftAddress;
            transferOptions.seller = _auctioner;
            transferOptions.tokenId = _tokenId;
            transferOptions.quantity = NftOnAuction.quantity;
            transferOptions.price = NftOnAuction.bidAmount;
            transferOptions.currency = NftOnAuction.erc20Token;
            transferOptions.isAuction = true;
            _settleTransfers(transferOptions);
        }

        emit AuctionSettled(
            NftOnAuction.tokenId,
            _nftAddress,
            _auctioner,
            NftOnAuction.currentBidder,
            NftOnAuction.erc20Token,
            NftOnAuction.quantity,
            NftOnAuction.bidAmount
        );

        delete mapAuction[_nftAddress][_tokenId][_auctioner];
    }

    /*
     * @notice this function is used to cancel the auction
     * @param _tokenId
     * @param _nftAddress
     * @param _auctioner
     */

    function cancelAuction(
        uint256 _tokenId,
        address _nftAddress,
        address _auctioner
    ) external {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];
        require(
            _isAdmin() || msg.sender == NftOnAuction.auctioner,
            "CancelAuction: Admin or Auctioner can cancel auction"
        );
        require(
            NftOnAuction.tokenId == _tokenId,
            "Cancel Auction : Token id is not on auction"
        );
        require(
            NftOnAuction.quantity > 0,
            "Cancel Auction : Token id is not on auction"
        );

        // Return bid if there is any
        if (NftOnAuction.currentBidder != address(0)) {
            if (NftOnAuction.erc20Token == address(NATIVE_TOKEN_ADDRESS)) {
                payable(NftOnAuction.currentBidder).transfer(
                    NftOnAuction.bidAmount
                );
            } else {
                IERC20(NftOnAuction.erc20Token).safeTransfer(
                    NftOnAuction.currentBidder,
                    NftOnAuction.bidAmount
                );
            }
        }

        // refund escrow

        emit AuctionCancelled(
            _tokenId,
            _nftAddress,
            _auctioner,
            NftOnAuction.quantity,
            NftOnAuction.erc20Token,
            NftOnAuction.bidAmount,
            NftOnAuction.currentBidder
        );

        delete mapAuction[_nftAddress][_tokenId][_auctioner];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _isAdmin() internal view returns (bool) {
        return (hasRole(ADMIN_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    }

    function _setPlatformFee(Fee memory _platformFee) internal {
        require(
            _platformFee.percentageValue <= 5000,
            "Fee: max allowed perecentage is 50"
        );
        platformFee = _platformFee;
    }

    // handle fixed price sale with direct payment
    function _NftSaleFixedPrice(
        uint256 _tokenId,
        uint256 _quantity,
        address _nftAddress,
        address _sellerAddress
    ) internal {
        Sale storage NftForSale = mapSale[_nftAddress][_tokenId][
            _sellerAddress
        ];

        require(
            NftForSale.quantity > 0,
            "Buy Nfts:No NFT is availabe for purchase"
        );
        require(
            msg.sender != NftForSale.seller,
            "Buy Nfts: Owner Is Not Allowed To Buy Nfts"
        );
        require(
            _quantity <= NftForSale.quantity,
            "Buy Nfts: Exceeds max quantity"
        );
        require(!_isAdmin(), "Buy Nfts: Admin Cannot Buy Nfts");

        uint256 buyAmount = NftForSale.price.mul(_quantity);
        address buyer = msg.sender;

        if (NftForSale.erc20Token == address(NATIVE_TOKEN_ADDRESS)) {
            require(msg.value >= buyAmount, "Buy Nfts: Insufficient fund");
        } else {
            require(
                IERC20(NftForSale.erc20Token).allowance(buyer, address(this)) >=
                    buyAmount,
                "Buy Nfts: Insufficient allowance"
            );
        }
        _NftSale(
            _tokenId,
            _quantity,
            _nftAddress,
            buyAmount,
            buyer,
            NftForSale.seller,
            NftForSale.erc20Token
        );
    }

    // handle fixed price sale with fiat payment
    function _NftSaleFixedPriceFiat(
        uint256 _tokenId,
        uint256 _quantity,
        address _nftAddress,
        address _sellerAddress,
        address _buyer
    ) internal {
        Sale storage NftForSale = mapSale[_nftAddress][_tokenId][
            _sellerAddress
        ];

        require(
            NftForSale.quantity > 0,
            "Buy Nfts :No NFT is availabe for purchase"
        );
        require(
            _quantity <= NftForSale.quantity,
            "Buy Nfts: Exceeds max quantity"
        );

        uint256 buyAmount = 0;
        address buyer = _buyer;

        _NftSale(
            _tokenId,
            _quantity,
            _nftAddress,
            buyAmount,
            buyer,
            NftForSale.seller,
            NftForSale.erc20Token
        );
    }

    // handle auction instant buy with direct payment
    function _NftAuctionInstantBuy(
        uint256 _tokenId,
        address _nftAddress,
        address _auctioner
    ) internal {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];

        require(
            NftOnAuction.quantity > 0,
            "Auction Instant Buy: Buy for non existing auction"
        );
        require(
            !_isAdmin(),
            "Auction Instant Buy: Admin not allowed to perform purchase"
        );

        require(
            msg.sender != NftOnAuction.auctioner,
            "Auction Instant Buy : Sellernot allowed to perform purchase"
        );
        require(
            NftOnAuction.salePrice > NftOnAuction.bidAmount,
            "Auction Instant Buy: bid exceeds sale price"
        );

        if (NftOnAuction.erc20Token == address(NATIVE_TOKEN_ADDRESS)) {
            require(
                msg.value == NftOnAuction.salePrice,
                "Auction Instant Buy: Amount received and sale price should be same"
            );

            if (NftOnAuction.currentBidder != address(0)) {
                payable(NftOnAuction.currentBidder).transfer(
                    NftOnAuction.bidAmount
                );
            }
        } else {
            uint256 checkAllowance = IERC20(NftOnAuction.erc20Token).allowance(
                msg.sender,
                address(this)
            );

            require(
                checkAllowance >= NftOnAuction.salePrice,
                "Place Bid : Allowance is Less then Price"
            );

            if (NftOnAuction.currentBidder != address(0)) {
                IERC20(NftOnAuction.erc20Token).safeTransfer(
                    NftOnAuction.currentBidder,
                    NftOnAuction.bidAmount
                );
            }
        }

        address buyer = msg.sender;

        _NftAuction(
            _tokenId,
            _nftAddress,
            _auctioner,
            buyer,
            NftOnAuction,
            false
        );
    }

    // handle auction instant sale with fiat payment
    function _NftAuctionInstantBuyFiat(
        uint256 _tokenId,
        address _nftAddress,
        address _auctioner,
        address _buyer
    ) internal {
        Auction storage NftOnAuction = mapAuction[_nftAddress][_tokenId][
            _auctioner
        ];

        require(
            NftOnAuction.quantity > 0,
            "Auction Instant Buy: Buy for non existing auction"
        );
        require(
            !_isAdmin(),
            "Auction Instant Buy: Admin not allowed to perform purchase"
        );

        require(
            _buyer != NftOnAuction.auctioner,
            "Auction Instant Buy : Sellernot allowed to perform purchase"
        );
        require(
            NftOnAuction.salePrice > NftOnAuction.bidAmount,
            "Auction Instant Buy: bid exceeds sale price"
        );

        if (NftOnAuction.erc20Token == address(NATIVE_TOKEN_ADDRESS)) {
            if (NftOnAuction.currentBidder != address(0)) {
                payable(NftOnAuction.currentBidder).transfer(
                    NftOnAuction.bidAmount
                );
            }
        } else {
            if (NftOnAuction.currentBidder != address(0)) {
                IERC20(NftOnAuction.erc20Token).safeTransfer(
                    NftOnAuction.currentBidder,
                    NftOnAuction.bidAmount
                );
            }
        }

        _NftAuction(
            _tokenId,
            _nftAddress,
            _auctioner,
            _buyer,
            NftOnAuction,
            true
        );
    }

    function _settleTransfers(TransferOptions memory _transferOptions)
        internal
    {
        bool isApproved = _checkTokenApproval(
            _transferOptions.nftAddress,
            _transferOptions.tokenId,
            _transferOptions.quantity,
            _transferOptions.seller
        );
        NftInfo storage NftInfoStored = mapNftInfo[_transferOptions.nftAddress][
            _transferOptions.tokenId
        ];
        Auction storage nftOnAuctionStorage = mapAuction[
            _transferOptions.nftAddress
        ][_transferOptions.tokenId][_transferOptions.seller];
        Sale storage nftOnSaleStorage = mapSale[_transferOptions.nftAddress][
            _transferOptions.tokenId
        ][_transferOptions.seller];

        if (
            !isApproved &&
            _transferOptions.isAuction &&
            nftOnAuctionStorage.isResell
        ) {
            IERC20(_transferOptions.currency).safeTransfer(
                _transferOptions.receiver,
                _transferOptions.price
            );
            delete mapAuction[_transferOptions.nftAddress][
                _transferOptions.tokenId
            ][_transferOptions.seller];
            emit RefundAuction(
                _transferOptions.receiver,
                _transferOptions.price
            );
        }
        if (
            !isApproved &&
            !_transferOptions.isAuction &&
            nftOnSaleStorage.isResell
        ) {
            delete mapSale[_transferOptions.nftAddress][
                _transferOptions.tokenId
            ][_transferOptions.seller];
        }
        if (
            (isApproved &&
                _transferOptions.isAuction &&
                nftOnAuctionStorage.isResell) ||
            (!isApproved &&
                _transferOptions.isAuction &&
                !nftOnAuctionStorage.isResell)
        ) {
            EscrowFactory.NftInfo memory nftInfo;
            nftInfo.metaHash = NftInfoStored.metaHash;
            nftInfo.royaltyReceiver = NftInfoStored.royaltyAddress;
            nftInfo.royaltyPercentage = NftInfoStored.royaltyAmount;

            EscrowFactory.Fee memory currentFee;
            currentFee.receiver = platformFee.receiver;
            currentFee.percentageValue = platformFee.percentageValue;

            EscrowFactory.CreatEscrowOptions memory escrowOptions;
            escrowOptions.receiver = _transferOptions.receiver;
            escrowOptions.nftAddress = _transferOptions.nftAddress;
            escrowOptions.seller = _transferOptions.seller;
            escrowOptions.tokenId = _transferOptions.tokenId;
            escrowOptions.quantity = _transferOptions.quantity;
            escrowOptions.price = _transferOptions.price;
            escrowOptions.currency = _transferOptions.currency;

            if (_transferOptions.currency == address(NATIVE_TOKEN_ADDRESS)) {
                EscrowFactory(escrowContract).createEscrow{value: msg.value}(
                    escrowOptions,
                    nftOnAuctionStorage.isResell,
                    nftInfo,
                    currentFee
                );
            } else {
                require(
                    IERC20(_transferOptions.currency).allowance(
                        _transferOptions.receiver,
                        address(this)
                    ) >= _transferOptions.price,
                    "Buy Nfts: Insufficient allowance"
                );

                IERC20(_transferOptions.currency).safeTransferFrom(
                    payable(_transferOptions.receiver),
                    address(this),
                    _transferOptions.price
                );
                IERC20(_transferOptions.currency).approve(
                    payable(escrowContract),
                    _transferOptions.price
                );

                EscrowFactory(escrowContract).createEscrow{value: 0}(
                    escrowOptions,
                    nftOnAuctionStorage.isResell,
                    nftInfo,
                    currentFee
                );
            }

            nftOnAuctionStorage.quantity =
                nftOnAuctionStorage.quantity -
                _transferOptions.quantity;

            if (nftOnAuctionStorage.quantity == 0) {
                delete mapAuction[_transferOptions.nftAddress][
                    _transferOptions.tokenId
                ][_transferOptions.seller];
            }
        }
        if (
            (isApproved &&
                !_transferOptions.isAuction &&
                nftOnSaleStorage.isResell) ||
            (!isApproved &&
                !_transferOptions.isAuction &&
                !nftOnSaleStorage.isResell)
        ) {
            EscrowFactory.NftInfo memory nftInfo;
            nftInfo.metaHash = NftInfoStored.metaHash;
            nftInfo.royaltyReceiver = NftInfoStored.royaltyAddress;
            nftInfo.royaltyPercentage = NftInfoStored.royaltyAmount;

            EscrowFactory.Fee memory currentFee;
            currentFee.receiver = platformFee.receiver;
            currentFee.percentageValue = platformFee.percentageValue;

            EscrowFactory.CreatEscrowOptions memory escrowOptions;
            escrowOptions.receiver = _transferOptions.receiver;
            escrowOptions.nftAddress = _transferOptions.nftAddress;
            escrowOptions.seller = _transferOptions.seller;
            escrowOptions.tokenId = _transferOptions.tokenId;
            escrowOptions.quantity = _transferOptions.quantity;
            escrowOptions.price = _transferOptions.price;
            escrowOptions.currency = _transferOptions.currency;

            if (_transferOptions.currency == address(NATIVE_TOKEN_ADDRESS)) {
                require(
                    msg.value >= _transferOptions.price,
                    "Buy Nfts: Insufficient fund"
                );
                EscrowFactory(escrowContract).createEscrow{value: msg.value}(
                    escrowOptions,
                    nftOnSaleStorage.isResell,
                    nftInfo,
                    currentFee
                );
            } else {
                require(
                    IERC20(_transferOptions.currency).allowance(
                        _transferOptions.receiver,
                        address(this)
                    ) >= _transferOptions.price,
                    "Buy Nfts: Insufficient allowance"
                );

                IERC20(_transferOptions.currency).safeTransferFrom(
                    payable(_transferOptions.receiver),
                    address(this),
                    _transferOptions.price
                );
                IERC20(_transferOptions.currency).approve(
                    payable(escrowContract),
                    _transferOptions.price
                );

                EscrowFactory(escrowContract).createEscrow{value: 0}(
                    escrowOptions,
                    nftOnSaleStorage.isResell,
                    nftInfo,
                    currentFee
                );
            }

            nftOnSaleStorage.quantity =
                nftOnSaleStorage.quantity -
                _transferOptions.quantity;

            if (nftOnSaleStorage.quantity == 0) {
                delete mapSale[_transferOptions.nftAddress][
                    _transferOptions.tokenId
                ][_transferOptions.seller];
            }
        }
    }

    // manage fixed price sale common logic
    function _NftSale(
        uint256 _tokenId,
        uint256 _quantity,
        address _nftAddress,
        uint256 _buyAmount,
        address _buyer,
        address _seller,
        address _erc20Token
    ) internal {
        TransferOptions memory transferOptions;
        transferOptions.receiver = _buyer;
        transferOptions.nftAddress = _nftAddress;
        transferOptions.seller = _seller;
        transferOptions.tokenId = _tokenId;
        transferOptions.quantity = _quantity;
        transferOptions.price = _buyAmount;
        transferOptions.currency = _erc20Token;
        transferOptions.isAuction = false;
        _settleTransfers(transferOptions);

        emit NftSold(
            _tokenId,
            _nftAddress,
            _seller,
            _buyAmount,
            _erc20Token,
            _buyer,
            _quantity
        );
    }

    // manage auction instant purchase general logic
    function _NftAuction(
        uint256 _tokenId,
        address _nftAddress,
        address _auctioner,
        address _buyer,
        Auction memory NftOnAuction,
        bool _isFiatPurchase
    ) internal {
        uint256 currentPrice = NftOnAuction.salePrice;
        if (_isFiatPurchase) {
            currentPrice = 0;
        }
        TransferOptions memory transferOptions;
        transferOptions.receiver = _buyer;
        transferOptions.nftAddress = _nftAddress;
        transferOptions.seller = _auctioner;
        transferOptions.tokenId = _tokenId;
        transferOptions.quantity = NftOnAuction.quantity;
        transferOptions.price = NftOnAuction.salePrice;
        transferOptions.currency = NftOnAuction.erc20Token;
        transferOptions.isAuction = true;
        _settleTransfers(transferOptions);

        emit AuctionSettled(
            NftOnAuction.tokenId,
            _nftAddress,
            _auctioner,
            _buyer,
            NftOnAuction.erc20Token,
            NftOnAuction.quantity,
            NftOnAuction.salePrice
        );

        delete mapAuction[_nftAddress][_tokenId][_auctioner];
    }

    function _checkTokenApproval(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _seller
    ) internal view returns (bool) {
        if (IERC721(_nftContractAddress).supportsInterface(ERC721InterfaceId)) {
            if (
                IERC721(_nftContractAddress).getApproved(_tokenId) !=
                address(this)
            ) {
                return false;
            } else {
                return true;
            }
        } else if (
            IERC1155(_nftContractAddress).supportsInterface(ERC1155InterfaceId)
        ) {
            if (
                IERC1155(_nftContractAddress).isApprovedForAll(
                    _seller,
                    address(this)
                ) &&
                IERC1155(_nftContractAddress).balanceOf(_seller, _tokenId) >=
                _quantity
            ) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function _isNFT(address _nftAddress) internal view returns (bool) {
        return (IERC721(_nftAddress).supportsInterface(ERC721InterfaceId) ||
            IERC1155(_nftAddress).supportsInterface(ERC1155InterfaceId));
    }

    // Receive fund to this contract, usually for the purpose of fiat on-ramp
    // for EOA transfer
    receive() external payable {
        emit FundReceived(msg.sender, msg.value);
    }

    // Receive fund to this contract, usually for the purpose of fiat on-ramp
    // for contract transfer
    fallback() external payable {
        emit FundReceived(msg.sender, msg.value);
    }
}