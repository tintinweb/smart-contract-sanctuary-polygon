// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity ^0.8.0;

/// @title An interface of a factory of custom ERC20 tokens
interface IBentureAdmin {
    /// @notice Checks it the provided address owns any admin token
    function checkOwner(address user) external view;

    /// @notice Checks if the provided user owns an admin token controlling the provided ERC20 token
    /// @param user The address of the user that potentially controls ERC20 token
    /// @param ERC20Address The address of the potentially controlled ERC20 token
    function verifyAdminToken(address user, address ERC20Address) external view;

    /// @notice Returns the address of the controlled ERC20 token
    /// @param tokenId The ID of ERC721 token to check
    /// @return The address of the controlled ERC20 token
    function getControlledAddressById(
        uint256 tokenId
    ) external view returns (address);

    /// @notice Returns the list of all admin tokens of the user
    /// @param admin The address of the admin
    function getAdminTokenIds(
        address admin
    ) external view returns (uint256[] memory);

    /// @notice Returns the address of the factory that mints admin tokens
    /// @return The address of the factory
    function getFactory() external view returns (address);

    /// @notice Mints a new ERC721 token with the address of the controlled ERC20 token
    /// @param to The address of the receiver of the token
    /// @param ERC20Address The address of the controlled ERC20 token
    function mintWithERC20Address(address to, address ERC20Address) external;

    /// @notice Burns the token with the provided ID
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external;

    /// @dev Indicates that a new ERC721 token got minted
    event AdminTokenCreated(
        uint256 indexed tokenId,
        address indexed ERC20Address
    );

    /// @dev Indicates that an ERC721 token got burnt
    event AdminTokenBurnt(uint256 indexed tokenId);

    /// @dev Indicates that an ERC721 token got transferred
    event AdminTokenTransferred(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title An interface of a Salary contract.
interface ISalary {
    struct SalaryInfo {
        uint256 id;
        uint256 periodDuration;
        uint256 amountOfPeriods;
        uint256 amountOfWithdrawals;
        address tokenAddress;
        uint256 totalTokenAmount;
        uint256[] tokensAmountPerPeriod;
        uint256 lastWithdrawalTime;
        address employer;
        address employee;
    }

    /// @notice Emits when user was added to Employees of Admin
    event EmployeeAdded(
        address indexed employeeAddress,
        address indexed adminAddress
    );

    /// @notice Emits when user was removed from Employees of Admin
    event EmployeeRemoved(
        address indexed employeeAddress,
        address indexed adminAddress
    );

    /// @notice Emits when Employee's name was added or changed
    event EmployeeNameChanged(
        address indexed employeeAddress,
        string indexed name
    );

    /// @notice Emits when name was removed from Employee
    event EmployeeNameRemoved(address indexed employeeAddress);

    /// @notice Emits when salary was added to Employee
    event EmployeeSalaryAdded(
        address indexed employeeAddress,
        address indexed adminAddress,
        SalaryInfo indexed salary
    );

    /// @notice Emits when salary was removed from Employee
    event EmployeeSalaryRemoved(
        address indexed employeeAddress,
        address indexed adminAddress,
        SalaryInfo indexed salary
    );

    /// @notice Emits when Employee withdraws salary
    event EmployeeSalaryClaimed(
        address indexed employeeAddress,
        address indexed adminAddress,
        SalaryInfo indexed salary
    );

    /// @notice Returns the name of employee.
    /// @param employeeAddress Address of employee.
    /// @return name The name of employee.
    function getNameOfEmployee(
        address employeeAddress
    ) external view returns (string memory name);

    /// @notice Returns the array of employees of admin.
    /// @param adminAddress Address of admin.
    /// @return employees The array of employees of admin.
    function getEmployeesByAdmin(
        address adminAddress
    ) external view returns (address[] memory employees);

    /// @notice Returns true if user if employee for admin and False if not.
    /// @param adminAddress Address of admin.
    /// @param employeeAddress Address of employee.
    /// @return isEmployee True if user if employee for admin. False if not.
    function checkIfUserIsEmployeeOfAdmin(
        address adminAddress,
        address employeeAddress
    ) external view returns (bool isEmployee);

    /// @notice Returns the array of admins of employee.
    /// @param employeeAddress Address of employee.
    /// @return admins The array of admins of employee.
    function getAdminsByEmployee(
        address employeeAddress
    ) external view returns (address[] memory admins);

    /// @notice Returns true if user is admin for employee and False if not.
    /// @param employeeAddress Address of employee.
    /// @param adminAddress Address of admin.
    /// @return isAdmin True if user is admin for employee. False if not.
    function checkIfUserIsAdminOfEmployee(
        address employeeAddress,
        address adminAddress
    ) external view returns (bool isAdmin);

    /// @notice Returns array of salaries of employee.
    /// @param employeeAddress Address of employee.
    /// @return salaries Array of salaries of employee.
    function getSalariesIdByEmployeeAndAdmin(
        address employeeAddress,
        address adminAddress
    ) external view returns (uint256[] memory salaries);

    /// @notice Returns salary by ID.
    /// @param salaryId Id of SalaryInfo.
    /// @return salary SalaryInfo by ID.
    function getSalaryById(
        uint256 salaryId
    ) external view returns (SalaryInfo memory salary);

    /// @notice Adds new employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function addEmployee(address employeeAddress) external;

    /// @notice Removes employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function removeEmployee(address employeeAddress) external;

    /// @notice Sets new or changes current name of the employee.
    /// @param employeeAddress Address of employee.
    /// @param name New name of employee.
    /// @dev Only admin can call this method.
    function setNameToEmployee(
        address employeeAddress,
        string memory name
    ) external;

    /// @notice Removes name from employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function removeNameFromEmployee(address employeeAddress) external;

    /// @notice Adds salary to employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function addSalaryToEmployee(
        address employeeAddress,
        uint256 periodDuration,
        uint256 amountOfPeriods,
        address tokenAddress,
        uint256 totalTokenAmount,
        uint256[] memory tokensAmountPerPeriod
    ) external;

    /// @notice Removes salary from employee.
    /// @param salaryId ID of employee salary.
    /// @dev Only admin can call this method.
    function removeSalaryFromEmployee(uint256 salaryId) external;

    /// @notice Withdraws employee's salary.
    /// @param salaryId IDs of employee salaries.
    /// @dev Anyone can call this method. No restrictions.
    function withdrawSalary(uint256 salaryId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IBentureAdmin.sol";
import "./interfaces/ISalary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Salary contract. A contract to manage salaries 
contract Salary is ISalary{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Last added salary's ID
    uint256 private lastSalaryId;

    /// @dev Address of BentureAdmin Token
    address private bentureAdminToken;

    /// @dev Mapping from user address to his name
    mapping(address => string) private names;

    /// @dev Mapping from admins address to its array of employees
    mapping(address => EnumerableSet.AddressSet) private adminToEmployees;

    /// @dev Mapping from employee address to its array of admins
    mapping(address => EnumerableSet.AddressSet) private employeeToAdmins;

    /// @dev Mapping from salary ID to its info
    mapping(uint256 => SalaryInfo) private salaryById;

    mapping(address => mapping(address => EnumerableSet.UintSet)) private employeeToAdminToSalaryId;

    /// @dev Uses to check if user is BentureAdmin tokens holder
    modifier onlyAdmin() {
        IBentureAdmin(bentureAdminToken).checkOwner(msg.sender);
        _;
    }

    /// @param adminTokenAddress The address of the BentureAdmin Token
    constructor(address adminTokenAddress) {
        require(adminTokenAddress != address(0), "Salary: Zero address!");
        bentureAdminToken = adminTokenAddress;
    }

    /// @notice Returns the name of employee.
    /// @param employeeAddress Address of employee.
    /// @return name The name of employee.
    function getNameOfEmployee(
        address employeeAddress
    ) external view returns (string memory name) {
        return names[employeeAddress];
    }

    /// @notice Returns the array of admins of employee.
    /// @param employeeAddress Address of employee.
    /// @return admins The array of admins of employee.
    function getAdminsByEmployee(
        address employeeAddress
    ) external view returns (address[] memory admins) {
        return employeeToAdmins[employeeAddress].values();
    }

    /// @notice Sets new or changes current name of the employee.
    /// @param employeeAddress Address of employee.
    /// @param name New name of employee.
    /// @dev Only admin can call this method.
    function setNameToEmployee(
        address employeeAddress,
        string memory name
    ) external onlyAdmin {
        require(
            checkIfUserIsAdminOfEmployee(employeeAddress, msg.sender),
            "Salary: not allowed to set name!"
        );
        names[employeeAddress] = name;
        emit EmployeeNameChanged(employeeAddress, name);
    }

    /// @notice Removes name from employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function removeNameFromEmployee(
        address employeeAddress
    ) external onlyAdmin {
        require(
            checkIfUserIsAdminOfEmployee(employeeAddress, msg.sender),
            "Salary: not allowed to remove name!"
        );
        delete names[employeeAddress];
        emit EmployeeNameRemoved(employeeAddress);
    }

    /// @notice Adds new employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function addEmployee(address employeeAddress) external onlyAdmin {
        require(
            !checkIfUserIsAdminOfEmployee(employeeAddress, msg.sender),
            "Salary: user already is employee!"
        );
        adminToEmployees[msg.sender].add(employeeAddress);
        employeeToAdmins[employeeAddress].add(msg.sender);
        emit EmployeeAdded(employeeAddress, msg.sender);
    }

    /// @notice Removes employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function removeEmployee(address employeeAddress) external onlyAdmin {
        require(
            checkIfUserIsEmployeeOfAdmin(msg.sender, employeeAddress),
            "Salary: already not an employee!"
        );
        
        if (employeeToAdminToSalaryId[employeeAddress][msg.sender].length() > 0) {
        uint256[] memory id = employeeToAdminToSalaryId[employeeAddress][msg.sender].values();
            for (uint256 i = 0; i < employeeToAdminToSalaryId[employeeAddress][msg.sender].length(); i++) {
                if (salaryById[id[i]].employer == msg.sender) {
                    removeSalaryFromEmployee(id[i]);
                }
            }
        }

        adminToEmployees[msg.sender].remove(employeeAddress);
        employeeToAdmins[employeeAddress].remove(msg.sender);
    }

    /// @notice Withdraws employee's salary.
    /// @param salaryId IDs of employee salaries.
    /// @dev Anyone can call this method. No restrictions.
    function withdrawSalary(uint256 salaryId) external {
        SalaryInfo storage _salary = salaryById[salaryId];
        require(
            _salary.employee == msg.sender,
            "Salary: not employee for this salary!"
        );
        uint256 periodsToPay = (block.timestamp - _salary.lastWithdrawalTime) /
            _salary.periodDuration;
        if (
            periodsToPay + _salary.amountOfWithdrawals >=
            _salary.amountOfPeriods
        ) {
            periodsToPay =
                _salary.amountOfPeriods -
                _salary.amountOfWithdrawals;
        }

        if (periodsToPay != 0) {
            uint256 toPay;
            for(uint256 i = _salary.amountOfWithdrawals; i < _salary.amountOfWithdrawals + periodsToPay; i++) {
                toPay = toPay + _salary.tokensAmountPerPeriod[i];
            }

            _salary.amountOfWithdrawals =
                _salary.amountOfWithdrawals +
                periodsToPay;
            _salary.lastWithdrawalTime = block.timestamp;

            

            IERC20(_salary.tokenAddress).safeTransferFrom(
                _salary.employer,
                _salary.employee,
                toPay
            );

            emit EmployeeSalaryClaimed(
                _salary.employee,
                _salary.employer,
                salaryById[salaryId]
            );
        }
    }

    /// @notice Returns the array of employees of admin.
    /// @param adminAddress Address of admin.
    /// @return employees The array of employees of admin.
    function getEmployeesByAdmin(
        address adminAddress
    ) external view returns (address[] memory employees) {
        return adminToEmployees[adminAddress].values();
    }

    /// @notice Returns true if user is employee for admin and False if not.
    /// @param adminAddress Address of admin.
    /// @param employeeAddress Address of employee.
    /// @return isEmployee True if user is employee for admin. False if not.
    function checkIfUserIsEmployeeOfAdmin(
        address adminAddress,
        address employeeAddress
    ) public view returns (bool isEmployee) {
        return adminToEmployees[adminAddress].contains(employeeAddress);
    }

    /// @notice Returns true if user is admin for employee and False if not.
    /// @param employeeAddress Address of employee.
    /// @param adminAddress Address of admin.
    /// @return isAdmin True if user is admin for employee. False if not.
    function checkIfUserIsAdminOfEmployee(
        address employeeAddress,
        address adminAddress
    ) public view returns (bool isAdmin) {
        return employeeToAdmins[employeeAddress].contains(adminAddress);
    }

    /// @notice Returns array of salaries of employee.
    /// @param employeeAddress Address of employee.
    /// @return ids Array of salaries id of employee.
    function getSalariesIdByEmployeeAndAdmin(
        address employeeAddress,
        address adminAddress
    ) external view returns (uint256[] memory ids) {
        return employeeToAdminToSalaryId[employeeAddress][adminAddress].values();
    }

    /// @notice Returns salary by ID.
    /// @param salaryId Id of SalaryInfo.
    /// @return salary SalaryInfo by ID.
    function getSalaryById(
        uint256 salaryId
    ) external view returns (SalaryInfo memory salary) {
        return salaryById[salaryId];
    }

    /// @notice Adds salary to employee.
    /// @param employeeAddress Address of employee.
    /// @dev Only admin can call this method.
    function addSalaryToEmployee(
        address employeeAddress,
        uint256 periodDuration,
        uint256 amountOfPeriods,
        address tokenAddress,
        uint256 totalTokenAmount,
        uint256[] memory tokensAmountPerPeriod
    ) external onlyAdmin {
        require(
            checkIfUserIsAdminOfEmployee(employeeAddress, msg.sender),
            "Salary: not an admin for employee!"
        );
        require(
            IERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                totalTokenAmount,
            "Salary: not enough tokens allowed!"
        );
        SalaryInfo memory _salary;
        lastSalaryId++;
        _salary.id = lastSalaryId;
        _salary.periodDuration = periodDuration;
        _salary.amountOfPeriods = amountOfPeriods;
        _salary.amountOfWithdrawals = 0;
        _salary.tokenAddress = tokenAddress;
        _salary.totalTokenAmount = totalTokenAmount;
        _salary.tokensAmountPerPeriod = tokensAmountPerPeriod;
        _salary.lastWithdrawalTime = block.timestamp;
        _salary.employer = msg.sender;
        _salary.employee = employeeAddress;
        employeeToAdminToSalaryId[employeeAddress][msg.sender].add(_salary.id);
        salaryById[_salary.id] = _salary;
        emit EmployeeSalaryAdded(employeeAddress, msg.sender, _salary);
    }

    /// @notice Removes salary from employee.
    /// @param salaryId ID of employee salary.
    /// @dev Only admin can call this method.
    function removeSalaryFromEmployee(uint256 salaryId) public onlyAdmin {
        SalaryInfo memory _salary = salaryById[salaryId];
        require(
            checkIfUserIsAdminOfEmployee(_salary.employee, msg.sender),
            "Salary: not an admin for employee!"
        );
        require(
            _salary.employer == msg.sender,
            "Salary: not an admin of salary!"
        );

        employeeToAdminToSalaryId[_salary.employee][msg.sender].remove(salaryId);
        delete salaryById[_salary.id];

        if (_salary.amountOfWithdrawals != _salary.amountOfPeriods) {
            uint256 amountToPay;
            uint256 amountOfRemainingPeriods = _salary.amountOfPeriods - _salary.amountOfWithdrawals;
            uint256 timePassedFromLastWithdrawal = block.timestamp - _salary.lastWithdrawalTime;
            uint256 periodsPassed = timePassedFromLastWithdrawal / _salary.periodDuration;

            if (periodsPassed < amountOfRemainingPeriods) {
                ///@dev The case when an employee withdraw salary before the end of all periods
                uint256 period;
                for (uint256 i = _salary.amountOfWithdrawals; i < _salary.amountOfWithdrawals + (periodsPassed); i++) {
                    amountToPay = amountToPay + _salary.tokensAmountPerPeriod[i];
                    period = i;
                }

                if (timePassedFromLastWithdrawal - (_salary.periodDuration * (periodsPassed)) > 0) {
                    amountToPay = amountToPay + (_salary.tokensAmountPerPeriod[period + 1] * (timePassedFromLastWithdrawal - (periodsPassed) * _salary.periodDuration)) / _salary.periodDuration;
                }
                
            } else {
                ///@dev The case when an employee withdraw salary after the end of all periods
                for (uint256 i = _salary.amountOfWithdrawals; i < _salary.amountOfWithdrawals + amountOfRemainingPeriods; i++) {
                    amountToPay = amountToPay + _salary.tokensAmountPerPeriod[i];
                }
            }

            IERC20(_salary.tokenAddress).safeTransferFrom(
                msg.sender,
                _salary.employee,
                amountToPay
            );
        }
    }
}