/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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


interface ITokenLock {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external returns (uint256 lockId);

    function unlock(uint256 lockId) external payable;

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external payable;
}


interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}


interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}


/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    unchecked {
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

contract TokenLockV2Simple is ITokenLock, Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate;
        uint256 tgeDate; // TGE date for vesting locks, unlock date for normal locks
        uint256 tgeBps; // In bips. Is 0 for normal locks
        uint256 cycle; // Is 0 for normal locks
        uint256 cycleBps; // In bips. Is 0 for normal locks
        uint256 unlockedAmount;
        string description;
    }

    struct CumulativeLockInfo {
        address token;
        address factory;
        uint256 amount;
    }

    // ID padding from PinkLock v1, as there is a lack of a pausing mechanism
    // as of now the lastest id from v1 is about 22K, so this is probably a safe padding value.
    uint256 private constant ID_PADDING = 1_000_000;
    uint256 public editFee;
    uint256 public withdrawFee;
    address public fundAddress;

    Lock[] private _locks;
    mapping(address => EnumerableSet.UintSet) private _userLpLockIds;
    mapping(address => EnumerableSet.UintSet) private _userNormalLockIds;

    EnumerableSet.AddressSet private _lpLockedTokens;
    EnumerableSet.AddressSet private _normalLockedTokens;
    mapping(address => CumulativeLockInfo) public cumulativeLockInfo;
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds;

    event LockAdded(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockDate
    );
    event LockUpdated(
        uint256 indexed id,
        address token,
        address owner,
        uint256 newAmount,
        uint256 newUnlockDate
    );
    event LockRemoved(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockedAt
    );
    event LockDescriptionChanged(uint256 lockId);
    event LockOwnerChanged(uint256 lockId, address owner, address newOwner);
    event EditFeeChanged(address _operator, uint256 _editFee);
    event WithdrawFeeChanged(address _operator, uint256 _withdrawFee);
    event FundAddressChanged(address _operator, address _newAddress);

    modifier validLock(uint256 lockId) {
        _getActualIndex(lockId);
        _;
    }

    constructor(uint256 _editFee, uint256 _withdrawFee, address _fundAddress) {
        editFee = _editFee;
        withdrawFee = _withdrawFee;
        fundAddress = _fundAddress;
    }

    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external override returns (uint256 id) {
        require(token != address(0), "Invalid token");
        require(amount > 0, "Amount should be greater than 0");
        require(
            unlockDate > block.timestamp,
            "Unlock date should be in the future"
        );
        id = _createLock(
            owner,
            token,
            isLpToken,
            amount,
            unlockDate,
            0,
            0,
            0,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit LockAdded(id, token, owner, amount, unlockDate);
        return id;
    }

    function setEditFee(uint256 _editFee) external onlyOwner {
        editFee = _editFee;
        emit EditFeeChanged(msg.sender, _editFee);
    }
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        withdrawFee = _withdrawFee;
        emit WithdrawFeeChanged(msg.sender, _withdrawFee);
    }

    function setFundAddress(address _newAddress) external onlyOwner {
        require(fundAddress != _newAddress, "same addr");
        fundAddress = _newAddress;
        emit FundAddressChanged(msg.sender, _newAddress);
    }

    function _createLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) internal returns (uint256 id) {
        if (isLpToken) {
            address possibleFactoryAddress = _parseFactoryAddress(token);
            id = _lockLpToken(
                owner,
                token,
                possibleFactoryAddress,
                amount,
                tgeDate,
                tgeBps,
                cycle,
                cycleBps,
                description
            );
        } else {
            id = _lockNormalToken(
                owner,
                token,
                amount,
                tgeDate,
                tgeBps,
                cycle,
                cycleBps,
                description
            );
        }
        return id;
    }

    function _lockLpToken(
        address owner,
        address token,
        address factory,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userLpLockIds[owner].add(id);
        _lpLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = factory;
        }
        tokenInfo.amount = tokenInfo.amount + amount;

        _tokenToLockIds[token].add(id);
    }

    function _lockNormalToken(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userNormalLockIds[owner].add(id);
        _normalLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = address(0);
        }
        tokenInfo.amount = tokenInfo.amount + amount;

        _tokenToLockIds[token].add(id);
    }

    function _registerLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _locks.length + ID_PADDING;
        Lock memory newLock = Lock({
            id: id,
            token: token,
            owner: owner,
            amount: amount,
            lockDate: block.timestamp,
            tgeDate: tgeDate,
            tgeBps: tgeBps,
            cycle: cycle,
            cycleBps: cycleBps,
            unlockedAmount: 0,
            description: description
        });
        _locks.push(newLock);
    }

    function unlock(uint256 lockId) external payable override validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not the owner of this lock"
        );
        require(msg.value >= withdrawFee, "has no enough fee");
        if(withdrawFee > 0){
            payable(fundAddress).transfer(withdrawFee);
        }

        _normalUnlock(userLock);
    }

    function _normalUnlock(Lock storage userLock) internal {
        require(
            block.timestamp >= userLock.tgeDate,
            "It is not time to unlock"
        );
        require(userLock.unlockedAmount == 0, "Nothing to unlock");

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        bool isLpToken = tokenInfo.factory != address(0);

        if (isLpToken) {
            _userLpLockIds[msg.sender].remove(userLock.id);
        } else {
            _userNormalLockIds[msg.sender].remove(userLock.id);
        }

        uint256 unlockAmount = userLock.amount;

        if (tokenInfo.amount <= unlockAmount) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount - unlockAmount;
        }

        if (tokenInfo.amount == 0) {
            if (isLpToken) {
                _lpLockedTokens.remove(userLock.token);
            } else {
                _normalLockedTokens.remove(userLock.token);
            }
        }
        userLock.unlockedAmount = unlockAmount;

        _tokenToLockIds[userLock.token].remove(userLock.id);

        IERC20(userLock.token).safeTransfer(msg.sender, unlockAmount);

        emit LockRemoved(
            userLock.id,
            userLock.token,
            msg.sender,
            unlockAmount,
            block.timestamp
        );
    }

    function withdrawableTokens(uint256 lockId)
        external
        view
        returns (uint256)
    {
        Lock memory userLock = getLockById(lockId);
        return _withdrawableTokens(userLock);
    }

    function _withdrawableTokens(Lock memory userLock)
        internal
        view
        returns (uint256)
    {
        if (userLock.amount == 0) return 0;
        if (userLock.unlockedAmount >= userLock.amount) return 0;
        if (block.timestamp < userLock.tgeDate) return 0;
        if (userLock.cycle == 0) return 0;

        uint256 tgeReleaseAmount = FullMath.mulDiv(
            userLock.amount,
            userLock.tgeBps,
            10_000
        );
        uint256 cycleReleaseAmount = FullMath.mulDiv(
            userLock.amount,
            userLock.cycleBps,
            10_000
        );
        uint256 currentTotal = 0;
        if (block.timestamp >= userLock.tgeDate) {
            currentTotal =
                (((block.timestamp - userLock.tgeDate) / userLock.cycle) *
                    cycleReleaseAmount) +
                tgeReleaseAmount; // Truncation is expected here
        }
        uint256 withdrawable = 0;
        if (currentTotal > userLock.amount) {
            withdrawable = userLock.amount - userLock.unlockedAmount;
        } else {
            withdrawable = currentTotal - userLock.unlockedAmount;
        }
        return withdrawable;
    }

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external payable override validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not the owner of this lock"
        );
        require(userLock.unlockedAmount == 0, "Lock was unlocked");
        require(msg.value >= editFee, "has no enough fee");
        if(editFee > 0){
            payable(fundAddress).transfer(editFee);
        }

        if (newUnlockDate > 0) {
            require(
                newUnlockDate >= userLock.tgeDate &&
                    newUnlockDate > block.timestamp,
                "New unlock time should not be before old unlock time or current time"
            );
            userLock.tgeDate = newUnlockDate;
        }

        if (newAmount > 0) {
            require(
                newAmount >= userLock.amount,
                "New amount should not be less than current amount"
            );

            uint256 diff = newAmount - userLock.amount;

            if (diff > 0) {
                userLock.amount = newAmount;
                CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
                    userLock.token
                ];
                tokenInfo.amount = tokenInfo.amount + diff;
                _safeTransferFromEnsureExactAmount(
                    userLock.token,
                    msg.sender,
                    address(this),
                    diff
                );
            }
        }

        emit LockUpdated(
            userLock.id,
            userLock.token,
            userLock.owner,
            userLock.amount,
            userLock.tgeDate
        );
    }

    function editLockDescription(uint256 lockId, string memory description)
        external
        validLock(lockId)
    {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not the owner of this lock"
        );
        userLock.description = description;
        emit LockDescriptionChanged(lockId);
    }

    function transferLockOwnership(uint256 lockId, address newOwner)
        public
        validLock(lockId)
    {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        address currentOwner = userLock.owner;
        require(
            currentOwner == msg.sender,
            "You are not the owner of this lock"
        );

        userLock.owner = newOwner;

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        bool isLpToken = tokenInfo.factory != address(0);

        if (isLpToken) {
            _userLpLockIds[currentOwner].remove(lockId);
            _userLpLockIds[newOwner].add(lockId);
        } else {
            _userNormalLockIds[currentOwner].remove(lockId);
            _userNormalLockIds[newOwner].add(lockId);
        }

        emit LockOwnerChanged(lockId, currentOwner, newOwner);
    }

    function renounceLockOwnership(uint256 lockId) external {
        transferLockOwnership(lockId, address(0));
    }

    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        recipient.transfer(amount);
    }

    function getTotalLockCount() external view returns (uint256) {
        // Returns total lock count, regardless of whether it has been unlocked or not
        return _locks.length;
    }

    function getLockAt(uint256 index) external view returns (Lock memory) {
        return _locks[index];
    }

    function getLockById(uint256 lockId) public view returns (Lock memory) {
        return _locks[_getActualIndex(lockId)];
    }

    function allLpTokenLockedCount() public view returns (uint256) {
        return _lpLockedTokens.length();
    }

    function allNormalTokenLockedCount() public view returns (uint256) {
        return _normalLockedTokens.length();
    }

    function getCumulativeLpTokenLockInfoAt(uint256 index)
        external
        view
        returns (CumulativeLockInfo memory)
    {
        return cumulativeLockInfo[_lpLockedTokens.at(index)];
    }

    function getCumulativeNormalTokenLockInfoAt(uint256 index)
        external
        view
        returns (CumulativeLockInfo memory)
    {
        return cumulativeLockInfo[_normalLockedTokens.at(index)];
    }

    function getCumulativeLpTokenLockInfo(uint256 start, uint256 end)
        external
        view
        returns (CumulativeLockInfo[] memory)
    {
        if (end >= _lpLockedTokens.length()) {
            end = _lpLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[_lpLockedTokens.at(i)];
            currentIndex++;
        }
        return lockInfo;
    }

    function getCumulativeNormalTokenLockInfo(uint256 start, uint256 end)
        external
        view
        returns (CumulativeLockInfo[] memory)
    {
        if (end >= _normalLockedTokens.length()) {
            end = _normalLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[
                _normalLockedTokens.at(i)
            ];
            currentIndex++;
        }
        return lockInfo;
    }

    function totalTokenLockedCount() external view returns (uint256) {
        return allLpTokenLockedCount() + allNormalTokenLockedCount();
    }

    function lpLockCountForUser(address user) public view returns (uint256) {
        return _userLpLockIds[user].length();
    }

    function lpLocksForUser(address user)
        external
        view
        returns (Lock[] memory)
    {
        uint256 length = _userLpLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);
        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userLpLockIds[user].at(i));
        }
        return userLocks;
    }

    function lpLockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (Lock memory)
    {
        require(lpLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userLpLockIds[user].at(index));
    }

    function normalLockCountForUser(address user)
        public
        view
        returns (uint256)
    {
        return _userNormalLockIds[user].length();
    }

    function normalLocksForUser(address user)
        external
        view
        returns (Lock[] memory)
    {
        uint256 length = _userNormalLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userNormalLockIds[user].at(i));
        }
        return userLocks;
    }

    function normalLockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (Lock memory)
    {
        require(normalLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userNormalLockIds[user].at(index));
    }

    function totalLockCountForUser(address user)
        external
        view
        returns (uint256)
    {
        return normalLockCountForUser(user) + lpLockCountForUser(user);
    }

    function totalLockCountForToken(address token)
        external
        view
        returns (uint256)
    {
        return _tokenToLockIds[token].length();
    }

    function getLocksForToken(
        address token,
        uint256 start,
        uint256 end
    ) public view returns (Lock[] memory) {
        if (end >= _tokenToLockIds[token].length()) {
            end = _tokenToLockIds[token].length() - 1;
        }
        uint256 length = end - start + 1;
        Lock[] memory locks = new Lock[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            locks[currentIndex] = getLockById(_tokenToLockIds[token].at(i));
            currentIndex++;
        }
        return locks;
    }

    function _getActualIndex(uint256 lockId) internal view returns (uint256) {
        if (lockId < ID_PADDING) {
            revert("Invalid lock id");
        }
        uint256 actualIndex = lockId - ID_PADDING;
        require(actualIndex < _locks.length, "Invalid lock id");
        return actualIndex;
    }

    function _parseFactoryAddress(address token)
        internal
        view
        returns (address)
    {
        address possibleFactoryAddress;
        try IUniswapV2Pair(token).factory() returns (address factory) {
            possibleFactoryAddress = factory;
        } catch {
            revert("This token is not a LP token");
        }
        require(
            possibleFactoryAddress != address(0) &&
                _isValidLpToken(token, possibleFactoryAddress),
            "This token is not a LP token."
        );
        return possibleFactoryAddress;
    }

    function _isValidLpToken(address token, address factory)
        private
        view
        returns (bool)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        address factoryPair = IUniswapV2Factory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == token;
    }

    receive() external payable {}

    fallback() external payable {}
}