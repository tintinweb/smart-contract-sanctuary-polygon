/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//File: [EnumerableSet.sol]

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
}

//File: [ReentrancyGuard.sol]

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
     * by making the `nonReentrant` function external, and make it call a
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

//File: [IRouter.sol]

interface IUniRouterV1
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouterV2 is IUniRouterV1
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//File: [IFactory.sol]

interface IFactory
{
    //========================
    // PAIR FUNCTIONS
    //========================

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

//File: [IERC20.sol]

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

//File: [Context.sol]

/*
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

//File: [Address.sol]

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

//File: [IERC165.sol]

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

//File: [ML_TransferETH.sol]

contract ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    uint256 public transferGas = 30000;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setTransferGas(uint256 _gas) internal
    {
        require(_gas >= 30000, "Gas to low");
        require(_gas <= 250000, "Gas to high");
        transferGas = _gas;
    }

    //========================
    // TRANSFER FUNCTIONS
    //======================== 

    function transferETH(address _to, uint256 _amount) internal
    {
        (bool success, ) = payable(_to).call{ value: _amount, gas: transferGas }("");
        success; //prevent warning
    }
}

//File: [IToken.sol]

interface IToken
{
	//========================
    // EVENTS FUNCTIONS
    //========================

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//========================
    // INFO FUNCTIONS
    //========================
	
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	//========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address account) external view returns (uint256);

    //========================
    // TRANSFER / APPROVE FUNCTIONS
    //========================

    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
}

//File: [Ownable.sol]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//File: [Pausable.sol]

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

//File: [IERC721.sol]

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

//File: [IERC1155.sol]

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

//File: [ML_ETHOracle.sol]

contract ML_ETHOracle
{
    //========================
    // CONSTANTS
    //========================

    uint256 public constant PERCENT_FACTOR = 1000000; //100%

    //========================
    // ATTRIBUTES
    //========================

    //fees
    IToken public peggedToken; //pegged token for oracle (recommended: stable coin)
    IUniRouterV2 public oracleRouter; //router to get amount in ETH
    uint256 public oracleSlippage; //allowed oracle slippage

    //========================
    // CONFIG FUNCTIONS
    //========================

    function _setFeeSlippage(uint256 _slippage) internal
    {
        require(_slippage <= PERCENT_FACTOR, "Invalid slippage");
        oracleSlippage = _slippage;
    }

    function _setOracle(IUniRouterV2 _router, IToken _peggedToken) internal
    {
        //check
        require(
            IFactory(_router.factory())
                .getPair(
                    address(_peggedToken),
                    _router.WETH())
                != address(0),
            "No oracle pair found"
        );

        //set
        oracleRouter = _router;
        peggedToken = _peggedToken;
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function _getOracleAmountInETH(uint256 _amount) internal view returns (uint256)
    {
        if (address(oracleRouter) == address(0)
            || address(peggedToken) == address(0))
        {
            return 0;
        }

        //make direct route [token => wETH]
        address[] memory path = new address[](2);
        path[0] = address(peggedToken);  
        path[1] = oracleRouter.WETH(); 

        //get amounts out
        uint256[] memory out = oracleRouter.getAmountsOut(_amount, path);          
        return out[out.length - 1];
    }

    function _getOracleAmountInETHWithSlippage(uint256 _amount) internal view returns (uint256)
    {
        return (_getOracleAmountInETH(_amount) * (PERCENT_FACTOR - oracleSlippage)) / PERCENT_FACTOR;
    }
}

//File: [SafeERC20.sol]

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

//File: [IReferralManager.sol]

interface IReferralManager
{
    //========================
    // ATTRIBUTES
    //========================

    function userReferralMap(uint256 _referralID) external view returns (address);

    //========================
    // REFERRAL INFO FUNCTIONS
    //========================

    function getUserReferralFeeShare(address _user, string calldata _service, uint256 _amount) external view returns (uint256);

    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositToken(uint256 _referralID, IToken _token, uint256 _amount) external;
    function depositETH(uint256 _referralID) external payable;
}

//File: [ML_RecoverFunds.sol]

contract ML_RecoverFunds is ML_TransferETH
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function _recoverETH(uint256 _amount, address _to) internal
    {
        transferETH(_to, _amount);
    }

    function _recoverToken(IToken _token, uint256 _amount, address _to) internal
    {
        IERC20(address(_token)).safeTransfer(_to, _amount);
    }  
}

//File: [ServiceWithReferral.sol]

contract ServiceWithReferral is
    ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    IReferralManager public referralManager;
    string public serviceName;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setReferralManager(IReferralManager _manager) internal
    {
        referralManager = _manager;
    }

    function _setServiceName(string memory _service) internal
    {
        serviceName = _service;
    }

    //========================
    // REFERRAL FEE FUNCTIONS
    //========================     

    function getReferralFeeAmount(uint256 _referralID, uint256 _amount) private view returns (uint256)
    {
        if (address(referralManager) == address(0)
            || bytes(serviceName).length == 0
            || _referralID == 0)
        {
            return 0;
        }

        address referrer = referralManager.userReferralMap(_referralID);
        if (referrer == address(0))
        {
            return 0;
        }

        return referralManager.getUserReferralFeeShare(referrer, serviceName, _amount);
    }

    function _handleReferralFeeETH(uint256 _referralID, uint256 _amount) internal returns (uint256)
    {
        uint256 referralFeeAmount = getReferralFeeAmount(_referralID, _amount);
        if (referralFeeAmount != 0)
        {
            referralManager.depositETH{ value: referralFeeAmount }(_referralID);
        }

        return (_amount - referralFeeAmount);
    }

    function _handleReferralFeeToken(uint256 _referralID, IToken _token, uint256 _amount) internal returns (uint256)
    {
        uint256 referralFeeAmount = getReferralFeeAmount(_referralID, _amount);
        if (referralFeeAmount != 0)
        {
            //approve
            _token.approve(address(referralManager), 0);
            _token.approve(address(referralManager), referralFeeAmount);

            //deposit
            referralManager.depositToken(_referralID, _token, referralFeeAmount);

            //remove approval
            _token.approve(address(referralManager), 0);
        }

        return (_amount - referralFeeAmount);
    }
}

contract Escrow is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ML_RecoverFunds,
    ML_ETHOracle,
    ServiceWithReferral
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // ENUMS
    //======================== 

    enum ItemType
    {
        ERC20,
        ERC721,
        ERC1155
    }

    enum TradeStatus
    {
        ONGOING,
        CANCELLED,
        COMPLETE
    }

    //========================
    // STRUCTS
    //========================    

    struct OfferItem
    {
        ItemType itemType;          //type of token
        address contractAddress;    //contract of token
        uint256 nftId;              //ID of NFT, if NFT
        uint256 amount;             //amount, if not ERC721
    }

    struct Offer
    {
        address owner;              //owner of offer (can make changes)
        address receiver;           //alternative receiving wallet
        uint256 lastUpdated;        //timestamp of last update
        uint256 revision;           //revision of trade
        bool accepted;              //accepted by partner
        uint256 balance;            //ETH in offer
        OfferItem[] items;          //items in offer
    }

    struct Trade
    {
        uint256 id;                 //unique ID (never 0)
        TradeStatus status;         //current status 
        uint256 created;            //timestamp of creation
        uint256 lastUpdated;        //timestamp of last update
        Offer offer1;               //offer1 is from trade creator
        Offer offer2;               //offer2 is partner
    }

    struct UserInfo
    {
        uint256[] completedTrades;  //list with completed trades
        uint256[] activeTrades;     //list with active trades
        uint256[] cancelledTrades;  //list with cancelled trades
    }

    //========================
    // CONSTANTS
    //========================

    string public constant VERSION = "1.0.0";

    //========================
    // ATTRIBUTES
    //========================

    //fees
    uint256 public feesInPeggedAmount; //fee in the value of pegged token
    address public feeWallet; //fee receiver
    uint256 public feeSlippage; //allowed fee slippage

    //trades
    uint256 public tradeCounter; //increment for trades
    mapping(uint256 => Trade) public trades; //all trades
    mapping(address => mapping(address => uint256)) public tradePartnerMap; //map for active trades by partners
    mapping(address => UserInfo) private users; //user info

    //stats
    uint256 public completedTrades; //number of completed trades
    uint256 public cancelledTrades; //number of cancelled trades
    uint256 public activeTrades; //number of currently active trades

    //========================
    // CREATE
    //========================

    constructor()
    {
        _setServiceName("Escrow");
        feeSlippage = 50; //0.5%
    }
  
    //========================
    // CONFIG FUNCTIONS
    //========================

    function setReferralManager(IReferralManager _manager) external onlyOwner
    {
        _setReferralManager(_manager);
    }

    function setFeeSlippage(uint256 _slippage) external onlyOwner
    {
        _setFeeSlippage(_slippage);
    }

    function setOracle(IUniRouterV2 _router, IToken _peggedToken) external onlyOwner
    {
        _setOracle(_router, _peggedToken);
    }

    function setFeeWallet(address _wallet) external onlyOwner
    {
        feeWallet = _wallet;
    }

    function setFeeAmountInPegged(uint256 _amount) external onlyOwner
    {
        feesInPeggedAmount = _amount;
    }

    function setTransferGas(uint256 _gas) external onlyOwner
    {
        _setTransferGas(_gas);
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function getFeeAmountInETH() public view returns (uint256)
    {
        return _getOracleAmountInETH(feesInPeggedAmount);
    }

    function getFeeAmountInETHWithSlippage() public view returns (uint256)
    {
        return _getOracleAmountInETHWithSlippage(feesInPeggedAmount);
    }    

    //========================
    // USER INFO FUNCTIONS
    //========================

    function findUserTrade(address _user1, address _user2) public view returns (uint256)
    {
        (address p1, address p2) = getTradeUserOrder(_user1, _user2);
        return tradePartnerMap[p1][p2];
    }

    function getUserTradeListLength(address _user, TradeStatus _status) public view returns (uint256)
    {
        if (_status == TradeStatus.ONGOING)
        {
            return users[_user].activeTrades.length;
        }
        else if (_status == TradeStatus.COMPLETE)
        {
            return users[_user].completedTrades.length;
        }
        else if (_status == TradeStatus.CANCELLED)
        {
            return users[_user].cancelledTrades.length;
        }
        return 0;
    }

    function getUserTradesInRange(address _user, TradeStatus _status, uint256 _from, uint256 _to) external view returns (uint256[] memory)
    {
        uint256[] storage listRead = users[_user].activeTrades;
        if (_status == TradeStatus.COMPLETE)
        {
            listRead = users[_user].completedTrades;
        }
        else if (_status == TradeStatus.CANCELLED)
        {
            listRead = users[_user].cancelledTrades;
        }
     
        //get range excluding _to
        requireValidRange(listRead.length, _from, _to);
        uint256[] memory list = new uint256[](_to - _from);
        for (uint256 n = _from; n < _to; n++)
        {
            list[n - _from] = listRead[n];
        }
        return list;
    }

    //========================
    // TRADE INFO FUNCTIONS
    //========================

    function isTradeOffer1(uint256 _tradeId, address _user) public view returns (bool)
    {
        return (trades[_tradeId].offer1.owner == _user);        
    }

    function isTradeOwner(uint256 _tradeId, address _user) public view returns (bool)
    {
        return (trades[_tradeId].offer1.owner == _user
            || trades[_tradeId].offer2.owner == _user);
    }
    
    function getTradesInRange(uint256 _from, uint256 _to) external view returns (Trade[] memory)
    {
        //get range excluding _to
        requireValidRange(tradeCounter, _from, _to);
        Trade[] memory list = new Trade[](_to - _from);
        for (uint256 n = _from; n < _to; n++)
        {
            list[n - _from] = trades[n + 1];
        }
        return list;
    }    

    //========================
    // OFFER FUNCTIONS
    //========================

    function setReceiver(uint256 _tradeId, address _wallet) external
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        //edit offer
        Offer storage offer = (isTradeOffer1(_tradeId, msg.sender)
            ? trades[_tradeId].offer1
            : trades[_tradeId].offer2);

        offer.receiver = _wallet;
        offerUpdated(_tradeId);
    }

    function setOffer(uint256 _tradeId, uint256 _coinAmount, OfferItem[] memory _items) external payable nonReentrant
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        //edit offer, change revision and undo acceptance
        Trade storage trade = trades[_tradeId];
        Offer storage offer = (isTradeOffer1(_tradeId, msg.sender)
            ? trade.offer1
            : trade.offer2);  
        offer.revision += 1;
        trade.offer1.accepted = false;
        trade.offer2.accepted = false;

        //change balance
        offer.balance += msg.value;
        if (offer.balance > _coinAmount)
        {
            transferETH(msg.sender, offer.balance - _coinAmount);
            offer.balance = _coinAmount;
        }

        //clear items
        while (offer.items.length > 0)
        {
            offer.items.pop();
        }

        //add items
        for (uint256 n = 0; n < _items.length; n++)
        {
            offer.items.push(_items[n]);
        }

        //update
        offerUpdated(_tradeId);
    }    

    function refuseOffer(uint256 _tradeId) external
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        //unaccept if correct revision
        Offer storage offerPartner = (isTradeOffer1(_tradeId, msg.sender)
            ? trades[_tradeId].offer2
            : trades[_tradeId].offer1);
        require(offerPartner.accepted, "Offer wasn't accepted");
        offerPartner.accepted = false;
        offerUpdated(_tradeId);
    }

    function acceptOffer(uint256 _tradeId, uint256 _revision) external
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        //accept if correct revision
        Offer storage offerPartner = (isTradeOffer1(_tradeId, msg.sender)
            ? trades[_tradeId].offer2
            : trades[_tradeId].offer1);
        require(offerPartner.revision == _revision, "Offer was changed");
        offerPartner.accepted = true;
        offerUpdated(_tradeId);
    }

    function offerUpdated(uint256 _tradeId) private
    {
        Offer storage offer = (isTradeOffer1(_tradeId, msg.sender)
            ? trades[_tradeId].offer1
            : trades[_tradeId].offer2);
        offer.lastUpdated = block.timestamp;
        trades[_tradeId].lastUpdated = block.timestamp;
    }

    //========================
    // TRADE FUNCTIONS
    //========================

    function executeTrade(uint256 _tradeId, uint256 _referralID) external payable whenNotPaused nonReentrant
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);
        require(
            getFeeAmountInETHWithSlippage() <= msg.value,
            "Insufficent fee payment");
        require(trades[_tradeId].offer1.accepted, "Partner 1 hasn't accepted");
        require(trades[_tradeId].offer2.accepted, "Partner 2 hasn't accepted");

        //collect fees
        if (feeWallet != address(0))
        {
            uint256 feeAmount = _handleReferralFeeETH(_referralID, msg.value);
            transferETH(feeWallet, feeAmount);
        }        

        //execute trade
        executeTradeOffer(_tradeId, true);
        executeTradeOffer(_tradeId, false);
        closeTrade(_tradeId, true);
    }

    function executeTradeOffer(uint256 _tradeId, bool _offer1) private
    {
        //init
        Offer storage offer = (_offer1
            ? trades[_tradeId].offer1
            : trades[_tradeId].offer2);
        Offer storage partnerOffer = (_offer1
            ? trades[_tradeId].offer2
            : trades[_tradeId].offer1);
        address partner = (partnerOffer.receiver == address(0)
            ? partnerOffer.owner
            : partnerOffer.receiver);

        //send balance
        if (offer.balance > 0)
        {
            transferETH(partner, offer.balance);
        }        

        //execute item trades
        for (uint256 n = 0; n < offer.items.length; n++)
        {
            require(
                executeTradeOfferItem(
                    offer.owner,
                    partner,
                    offer.items[n]),
                "Trade failed");
        }
    }

    function executeTradeOfferItem(address _from, address _to, OfferItem memory _item) private returns (bool)
    {
        if (_item.itemType == ItemType.ERC20)
        {
            //ERC20
            IERC20(_item.contractAddress).safeTransferFrom(_from, _to, _item.amount);
            return true;
        }
        else if (_item.itemType == ItemType.ERC721)
        {
            //ERC721
            IERC721(_item.contractAddress).safeTransferFrom(_from, _to, _item.nftId);
            return true;
        }
        else if (_item.itemType == ItemType.ERC1155)
        {
            //ERC1155
            IERC1155(_item.contractAddress).safeTransferFrom(_from, _to, _item.nftId, _item.amount, "");
            return true;
        }

        return false;
    }

    function cancelTrade(uint256 _tradeId) external nonReentrant
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        closeTrade(_tradeId, false);
    }

    function createTrade(address _partner) external whenNotPaused nonReentrant returns (uint256)
    {
        require(_partner != msg.sender, "Can't trade with yourself");
        (address p1, address p2) = getTradeUserOrder(msg.sender, _partner);

        //check for existing trade
        uint256 userTrade = findUserTrade(p1, p2);
        require(userTrade == 0 || trades[userTrade].status != TradeStatus.ONGOING, "Ongoing trade found");

        //create trade
        tradeCounter += 1;
        Trade storage trade = trades[tradeCounter];
        trade.id = tradeCounter;
        trade.status = TradeStatus.ONGOING;
        trade.created = block.timestamp;
        trade.lastUpdated = block.timestamp;
        trade.offer1.owner = msg.sender;
        trade.offer2.owner = _partner;

        //add to users
        users[msg.sender].activeTrades.push(tradeCounter);
        users[_partner].activeTrades.push(tradeCounter);

        //map trade
        tradePartnerMap[p1][p2] = tradeCounter;

        activeTrades += 1;
        return tradeCounter;
    }

    function closeTrade(uint256 _tradeId, bool _completed) private
    {
        //check
        requireTradeOwner(_tradeId);
        requireTradeActive(_tradeId);

        //close
        trades[_tradeId].status = (_completed ? TradeStatus.COMPLETE : TradeStatus.CANCELLED);
        closeUserTrade(_tradeId, trades[_tradeId].offer1.owner, _completed);
        closeUserTrade(_tradeId, trades[_tradeId].offer2.owner, _completed);
        activeTrades -= 1;
        if (_completed)
        {
            completedTrades += 1;
        }
        else
        {
            cancelledTrades += 1;
        }

        //update
        offerUpdated(_tradeId);
    }

    function closeUserTrade(uint256 _tradeId, address _user, bool _completed) private
    {
        //refund balance
        uint256 balance = (isTradeOffer1(_tradeId, _user)
            ? trades[_tradeId].offer1.balance
            : trades[_tradeId].offer2.balance);
        if (!_completed
            && balance > 0)
        {
            transferETH(_user, balance);
        }

        //remove from active
        UserInfo storage user = users[_user];
        for (uint256 n = 0; n < user.activeTrades.length; n++)
        {
            if (user.activeTrades[n] == _tradeId)
            {
                //swap data
                if (n != user.activeTrades.length - 1)
                {
                    user.activeTrades[n] = user.activeTrades[user.activeTrades.length - 1];
                }

                //pop
                user.activeTrades.pop();
            }
        }

        //move to correct category
        if (_completed)
        {
            user.completedTrades.push(_tradeId);
        }
        else
        {
            user.cancelledTrades.push(_tradeId);
        }        
    }

    //========================
    // HELPER FUNCTIONS
    //========================

    receive() external payable {}  

    function requireValidRange(uint256 _length, uint256 _from, uint256 _to) private pure
    {
        require(_to <= _length, "Index is out of bounds");
        require(_to > _from, "End index must be greater than start index");
    }

    function getTradeUserOrder(address _user1, address _user2) private pure returns (address, address)
    {
        return (_user1 < _user2 ? (_user1, _user2) : (_user2, _user1));
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function requireTradeOwner(uint256 _tradeId) private view
    {
        require(isTradeOwner(_tradeId, msg.sender), "User not part of Trade");
    } 

    function requireTradeActive(uint256 _tradeId) private view
    {
        require(trades[_tradeId].status == TradeStatus.ONGOING, "Trade closed");
    } 

    function pause() external onlyOwner
    {
        _pause();
    }

    function unpause() external onlyOwner
    {
        _unpause();
    }

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function recoverETH(uint256 _amount, address _to) external onlyOwner
    {
        super._recoverETH(_amount, _to);        
    }

    function recoverToken(IToken _token, uint256 _amount, address _to) external onlyOwner
    {
        super._recoverToken(_token, _amount, _to);
    }  
}