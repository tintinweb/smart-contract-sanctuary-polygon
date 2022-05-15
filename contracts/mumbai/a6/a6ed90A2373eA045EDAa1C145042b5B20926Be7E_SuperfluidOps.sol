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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ISuperfluid} from "./interfaces/Superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "./interfaces/Superfluid/ISuperfluidToken.sol";
import {
    IConstantFlowAgreementV1,
    FlowChangeType
} from "./interfaces/Superfluid/IConstantFlowAgreementV1.sol";
import {IOps} from "./interfaces/IOps.sol";
import {IOpsSponsor} from "./interfaces/IOpsSponsor.sol";
import {ETH} from "./vendor/gelato/FGelato.sol";

contract SuperfluidOps {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    ISuperfluid public immutable superfluid;
    IConstantFlowAgreementV1 public immutable cfa;
    IOps public immutable ops;
    IOpsSponsor public immutable sponsor;

    mapping(address => EnumerableSet.Bytes32Set) internal _opsTaskIds;

    modifier onlyOps() {
        require(msg.sender == address(ops), "SuperfluidOps: Only Ops");
        _;
    }

    constructor(
        ISuperfluid _superfluid,
        IConstantFlowAgreementV1 _cfa,
        IOps _ops,
        IOpsSponsor _sponsor
    ) {
        superfluid = _superfluid;
        cfa = _cfa;
        ops = _ops;
        sponsor = _sponsor;
    }

    function createAction(
        FlowChangeType _action,
        uint256 _actionTime,
        address _token,
        address _receiver,
        int96 _flowRate
    ) external {
        require(
            _actionTime > block.timestamp,
            "SuperfluidOps: createAction: Time past"
        );

        bytes memory resolverData = _getResolverData(
            _action,
            _actionTime,
            _token,
            msg.sender,
            _receiver,
            _flowRate
        );

        bytes32 opsTaskId = ops.createTaskNoPrepayment(
            address(this),
            this.doAction.selector,
            address(this),
            resolverData,
            ETH
        );

        _opsTaskIds[msg.sender].add(opsTaskId);
    }

    function cancelAction(bytes32 opsTaskId) external {
        require(
            _opsTaskIds[msg.sender].contains(opsTaskId),
            "SuperfluidOps: cancelAction: No taskId"
        );

        ops.cancelTask(opsTaskId);
    }

    function doAction(
        FlowChangeType _action,
        uint256 _actionTime,
        address _token,
        address _sender,
        address _receiver,
        int96 _flowRate
    ) external onlyOps {
        bytes32 opsTaskId = _getOpsTaskId(
            _action,
            _actionTime,
            _token,
            _sender,
            _receiver,
            _flowRate
        );

        bytes memory callAgreementData = _getCallAgreementData(
            _action,
            _token,
            _sender,
            _receiver,
            _flowRate
        );

        require(
            _opsTaskIds[_sender].contains(opsTaskId),
            "SuperfluidOps: doAction: Action not found"
        );

        sponsor.sponsorOpsTxnFee();

        superfluid.callAgreement(cfa, callAgreementData, bytes(""));

        ops.cancelTask(opsTaskId);
    }

    function checker(
        FlowChangeType _action,
        uint256 _actionTime,
        address _token,
        address _sender,
        address _receiver,
        int96 _flowRate
    ) external view returns (bool canExec, bytes memory execPayload) {
        execPayload = bytes("SuperfluidOps: checker: Time not elapsed");

        (, uint8 permissions, int96 flowRateAllowance) = cfa
            .getFlowOperatorData(
                ISuperfluidToken(_token),
                _sender,
                address(this)
            );

        if (flowRateAllowance < _flowRate)
            execPayload = bytes(
                "SuperfluidOps: checker: Insufficient flowrate allowance"
            );

        if (!_getBooleanFlowOperatorPermissions(permissions, _action))
            execPayload = bytes(
                "SuperfluidOps: checker: No flow operator permission"
            );

        if (block.timestamp >= _actionTime) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                this.doAction.selector,
                _action,
                _actionTime,
                _token,
                _sender,
                _receiver,
                _flowRate
            );
        }
    }

    function _getBooleanFlowOperatorPermissions(
        uint8 permissions,
        FlowChangeType flowChangeType
    ) internal pure returns (bool flowchangeTypeAllowed) {
        if (flowChangeType == FlowChangeType.CREATE_FLOW) {
            flowchangeTypeAllowed = permissions & uint8(1) == 1;
        } else if (flowChangeType == FlowChangeType.UPDATE_FLOW) {
            flowchangeTypeAllowed = (permissions >> 1) & uint8(1) == 1;
        } else {
            /** flowChangeType === FlowChangeType.DELETE_FLOW */
            flowchangeTypeAllowed = (permissions >> 2) & uint8(1) == 1;
        }
    }

    function getOpsTaskIdsByUser(address _user)
        external
        view
        returns (bytes32[] memory)
    {
        return _opsTaskIds[_user].values();
    }

    function _getCallAgreementData(
        FlowChangeType _action,
        address _token,
        address _sender,
        address _receiver,
        int96 _flowRate
    ) public pure returns (bytes memory data) {
        if (_action == FlowChangeType.CREATE_FLOW)
            data = abi.encodeWithSelector(
                IConstantFlowAgreementV1.createFlowByOperator.selector,
                _token,
                _sender,
                _receiver,
                _flowRate,
                bytes("")
            );

        if (_action == FlowChangeType.UPDATE_FLOW)
            data = abi.encodeWithSelector(
                IConstantFlowAgreementV1.updateFlowByOperator.selector,
                _token,
                _sender,
                _receiver,
                _flowRate,
                bytes("")
            );
        if (_action == FlowChangeType.DELETE_FLOW)
            data = abi.encodeWithSelector(
                IConstantFlowAgreementV1.deleteFlowByOperator.selector,
                _token,
                _sender,
                _receiver,
                bytes("")
            );
    }

    function _getOpsTaskId(
        FlowChangeType _action,
        uint256 _actionTime,
        address _token,
        address _sender,
        address _receiver,
        int96 _flowRate
    ) private view returns (bytes32 opsTaskId) {
        bytes memory resolverData = _getResolverData(
            _action,
            _actionTime,
            _token,
            _sender,
            _receiver,
            _flowRate
        );

        bytes32 resolverHash = ops.getResolverHash(address(this), resolverData);
        opsTaskId = ops.getTaskId(
            address(this),
            address(this),
            this.doAction.selector,
            false,
            ETH,
            resolverHash
        );
    }

    function _getResolverData(
        FlowChangeType _action,
        uint256 _actionTime,
        address _token,
        address _sender,
        address _receiver,
        int96 _flowRate
    ) private pure returns (bytes memory resolverData) {
        resolverData = abi.encodeWithSelector(
            this.checker.selector,
            _action,
            _actionTime,
            _token,
            _sender,
            _receiver,
            _flowRate
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ITaskTreasuryUpgradable } from "./ITaskTreasuryUpgradable.sol";

interface IOps {
  /// @notice Structs ///

  struct Time {
    uint128 nextExec;
    uint128 interval;
  }

  /// @notice Events ///

  event ExecSuccess(
    uint256 indexed txFee,
    address indexed feeToken,
    address indexed execAddress,
    bytes execData,
    bytes32 taskId,
    bool callSuccess
  );
  event TaskCreated(
    address taskCreator,
    address execAddress,
    bytes4 selector,
    address resolverAddress,
    bytes32 taskId,
    bytes resolverData,
    bool useTaskTreasuryFunds,
    address feeToken,
    bytes32 resolverHash
  );
  event TaskCancelled(bytes32 taskId, address taskCreator);
  event TimerSet(
    bytes32 indexed taskId,
    uint128 indexed nextExec,
    uint128 indexed interval
  );

  /// @notice External functions ///

  function createTask(
    address _execAddress,
    bytes4 _execSelector,
    address _resolverAddress,
    bytes calldata _resolverData
  ) external returns (bytes32 taskId);

  function createTaskNoPrepayment(
    address _execAddress,
    bytes4 _execSelector,
    address _resolverAddress,
    bytes calldata _resolverData,
    address _feeToken
  ) external returns (bytes32 taskId);

  function createTimedTask(
    uint128 _startTime,
    uint128 _interval,
    address _execAddress,
    bytes4 _execSelector,
    address _resolverAddress,
    bytes calldata _resolverData,
    address _feeToken
  ) external returns (bytes32 taskId);

  function cancelTask(bytes32 _taskId) external;

  function exec(
    uint256 _txFee,
    address _feeToken,
    address _taskCreator,
    bool _useTaskTreasuryFunds,
    bool _revertOnFailure,
    bytes32 _resolverHash,
    address _execAddress,
    bytes calldata _execData
  ) external;

  /// @notice External view functions ///

  function gelato() external view returns (address payable);

  function getFeeDetails() external view returns (uint256, address);

  function getTaskIdsByUser(address _taskCreator)
    external
    view
    returns (bytes32[] memory);

  function taskTreasury() external view returns (ITaskTreasuryUpgradable);

  function getTaskId(
    address _taskCreator,
    address _execAddress,
    bytes4 _selector,
    bool _useTaskTreasuryFunds,
    address _feeToken,
    bytes32 _resolverHash
  ) external pure returns (bytes32);

  function getResolverHash(address _resolverAddress, bytes memory _resolverData)
    external
    pure
    returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpsSponsor {
  function sponsorOpsTxnFee() external;

  function withdraw(
    address payable _addr,
    address _token,
    uint256 _amount
  ) external;

  function updateWhitelistedServices() external;

  function getWhitelistedServices() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskTreasuryUpgradable {
    /// @notice Events ///
    event FundsDeposited(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );

    event FundsWithdrawn(
        address indexed receiver,
        address indexed initiator,
        address indexed token,
        uint256 amount
    );

    event LogDeductFees(
        address indexed user,
        address indexed executor,
        address indexed token,
        uint256 fees,
        address service
    );

    event UpdatedService(address indexed service, bool add);

    event UpdatedMaxFee(uint256 indexed maxFee);

    /// @notice External functions ///

    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function useFunds(
        address user,
        address token,
        uint256 amount
    ) external;

    function updateMaxFee(uint256 _newMaxFee) external;

    function updateWhitelistedService(address service, bool isWhitelist)
        external;

    /// @notice External view functions ///

    function getCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getTotalCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getWhitelistedServices() external view returns (address[] memory);

    function totalUserTokenBalance(address user, address token)
        external
        view
        returns (uint256);

    function userTokenBalance(address user, address token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.0;

import {ISuperAgreement} from "./ISuperAgreement.sol";
import {ISuperfluidToken} from "./ISuperfluidToken.sol";

enum FlowChangeType {
    CREATE_FLOW,
    UPDATE_FLOW,
    DELETE_FLOW
}

/**
 * @title Constant Flow Agreement interface
 * @author Superfluid
 */
interface IConstantFlowAgreementV1 is ISuperAgreement {
    /// @dev ISuperAgreement.agreementType implementation
    function agreementType() external pure returns (bytes32);

    /**
     * @notice Get the maximum flow rate allowed with the deposit
     * @dev The deposit is clipped and rounded down
     * @param deposit Deposit amount used for creating the flow
     * @return flowRate The maximum flow rate
     */
    function getMaximumFlowRateFromDeposit(
        ISuperfluidToken token,
        uint256 deposit
    ) external view returns (int96 flowRate);

    /**
     * @notice Get the deposit required for creating the flow
     * @dev Calculates the deposit based on the liquidationPeriod and flowRate
     * @param flowRate Flow rate to be tested
     * @return deposit The deposit amount based on flowRate and liquidationPeriod
     * NOTE:
     * - if calculated deposit (flowRate * liquidationPeriod) is less
     *   than the minimum deposit, we use the minimum deposit otherwise
     *   we use the calculated deposit
     */
    function getDepositRequiredForFlowRate(
        ISuperfluidToken token,
        int96 flowRate
    ) external view returns (uint256 deposit);

    /**
     * @dev Returns whether it is the patrician period based on host.getNow()
     * @param account The account we are interested in
     * @return isCurrentlyPatricianPeriod Whether it is currently the patrician period dictated by governance
     * @return timestamp The value of host.getNow()
     */
    function isPatricianPeriodNow(ISuperfluidToken token, address account)
        external
        view
        returns (bool isCurrentlyPatricianPeriod, uint256 timestamp);

    /**
     * @dev Returns whether it is the patrician period based on timestamp
     * @param account The account we are interested in
     * @param timestamp The timestamp we are interested in observing the result of isPatricianPeriod
     * @return bool Whether it is currently the patrician period dictated by governance
     */
    function isPatricianPeriod(
        ISuperfluidToken token,
        address account,
        uint256 timestamp
    ) external view returns (bool);

    /**
     * @dev msgSender from `ctx` updates permissions for the `flowOperator` with `flowRateAllowance`
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param permissions A bitmask representation of the granted permissions
     * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function updateFlowOperatorPermissions(
        ISuperfluidToken token,
        address flowOperator,
        uint8 permissions,
        int96 flowRateAllowance,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @dev msgSender from `ctx` grants `flowOperator` all permissions with flowRateAllowance as type(int96).max
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function authorizeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice msgSender from `ctx` revokes `flowOperator` create/update/delete permissions
     * @dev `permissions` and `flowRateAllowance` will both be set to 0
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function revokeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice Get the permissions of a flow operator between `sender` and `flowOperator` for `token`
     * @param token Super token address
     * @param sender The permission granter address
     * @param flowOperator The permission grantee address
     * @return flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
     * @return permissions A bitmask representation of the granted permissions
     * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    function getFlowOperatorData(
        ISuperfluidToken token,
        address sender,
        address flowOperator
    )
        external
        view
        returns (
            bytes32 flowOperatorId,
            uint8 permissions,
            int96 flowRateAllowance
        );

    /**
     * @notice Get flow operator using flowOperatorId
     * @param token Super token address
     * @param flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
     * @return permissions A bitmask representation of the granted permissions
     * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    function getFlowOperatorDataByID(
        ISuperfluidToken token,
        bytes32 flowOperatorId
    ) external view returns (uint8 permissions, int96 flowRateAllowance);

    /**
     * @notice Create a flow betwen ctx.msgSender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * # App callbacks
     *
     * - AgreementCreated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * NOTE:
     * - A deposit is taken as safety margin for the solvency agents
     * - A extra gas fee may be taken to pay for solvency agent liquidations
     */
    function createFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice Create a flow between sender and receiver
     * @dev A flow created by an approved flow operator (see above for details on callbacks)
     * @param token Super token address
     * @param sender Flow sender address (has granted permissions)
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function createFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice Update the flow rate between ctx.msgSender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * # App callbacks
     *
     * - AgreementUpdated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * NOTE:
     * - Only the flow sender may update the flow rate
     * - Even if the flow rate is zero, the flow is not deleted
     * from the system
     * - Deposit amount will be adjusted accordingly
     * - No new gas fee is charged
     */
    function updateFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice Update a flow between sender and receiver
     * @dev A flow updated by an approved flow operator (see above for details on callbacks)
     * @param token Super token address
     * @param sender Flow sender address (has granted permissions)
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function updateFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @dev Get the flow data between `sender` and `receiver` of `token`
     * @param token Super token address
     * @param sender Flow receiver
     * @param receiver Flow sender
     * @return timestamp Timestamp of when the flow is updated
     * @return flowRate The flow rate
     * @return deposit The amount of deposit the flow
     * @return owedDeposit The amount of owed deposit of the flow
     */
    function getFlow(
        ISuperfluidToken token,
        address sender,
        address receiver
    )
        external
        view
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        );

    /**
     * @notice Get flow data using agreementId
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param agreementId The agreement ID
     * @return timestamp Timestamp of when the flow is updated
     * @return flowRate The flow rate
     * @return deposit The deposit amount of the flow
     * @return owedDeposit The owed deposit amount of the flow
     */
    function getFlowByID(ISuperfluidToken token, bytes32 agreementId)
        external
        view
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        );

    /**
     * @dev Get the aggregated flow info of the account
     * @param token Super token address
     * @param account Account for the query
     * @return timestamp Timestamp of when a flow was last updated for account
     * @return flowRate The net flow rate of token for account
     * @return deposit The sum of all deposits for account's flows
     * @return owedDeposit The sum of all owed deposits for account's flows
     */
    function getAccountFlowInfo(ISuperfluidToken token, address account)
        external
        view
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        );

    /**
     * @dev Get the net flow rate of the account
     * @param token Super token address
     * @param account Account for the query
     * @return flowRate Net flow rate
     */
    function getNetFlow(ISuperfluidToken token, address account)
        external
        view
        returns (int96 flowRate);

    /**
     * @notice Delete the flow between sender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @param receiver Flow receiver address
     *
     * # App callbacks
     *
     * - AgreementTerminated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * NOTE:
     * - Both flow sender and receiver may delete the flow
     * - If Sender account is insolvent or in critical state, a solvency agent may
     *   also terminate the agreement
     * - Gas fee may be returned to the sender
     */
    function deleteFlow(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @notice Delete the flow between sender and receiver
     * @dev A flow deleted by an approved flow operator (see above for details on callbacks)
     * @param token Super token address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @param receiver Flow receiver address
     */
    function deleteFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    ) external returns (bytes memory newCtx);

    /**
     * @dev Flow operator updated event
     * @param token Super token address
     * @param sender Flow sender address
     * @param flowOperator Flow operator address
     * @param permissions Octo bitmask representation of permissions
     * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    event FlowOperatorUpdated(
        ISuperfluidToken indexed token,
        address indexed sender,
        address indexed flowOperator,
        uint8 permissions,
        int96 flowRateAllowance
    );

    /**
     * @dev Flow updated event
     * @param token Super token address
     * @param sender Flow sender address
     * @param receiver Flow recipient address
     * @param flowRate Flow rate in amount per second for this flow
     * @param totalSenderFlowRate Total flow rate in amount per second for the sender
     * @param totalReceiverFlowRate Total flow rate in amount per second for the receiver
     * @param userData The user provided data
     *
     */
    event FlowUpdated(
        ISuperfluidToken indexed token,
        address indexed sender,
        address indexed receiver,
        int96 flowRate,
        int256 totalSenderFlowRate,
        int256 totalReceiverFlowRate,
        bytes userData
    );

    /**
     * @dev Flow updated extension event
     * @param flowOperator Flow operator address - the Context.msgSender
     * @param deposit The deposit amount for the stream
     */
    event FlowUpdatedExtension(address indexed flowOperator, uint256 deposit);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.0;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {
  /**
   * @dev Get the type of the agreement class
   */
  function agreementType() external view returns (bytes32);

  /**
   * @dev Calculate the real-time balance for the account of this agreement class
   * @param account Account the state belongs to
   * @param time Time used for the calculation
   * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
   * @return deposit Account deposit amount of this agreement
   * @return owedDeposit Account owed deposit amount of this agreement
   */
  function realtimeBalanceOf(
    ISuperfluidToken token,
    address account,
    uint256 time
  )
    external
    view
    returns (
      int256 dynamicBalance,
      uint256 deposit,
      uint256 owedDeposit
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";

interface ISuperfluid {
  function callAgreement(
    ISuperAgreement agreementClass,
    bytes calldata callData,
    bytes calldata userData
  )
    external
    returns (
      //cleanCtx
      //isAgreement(agreementClass)
      bytes memory returnedData
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";

/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {
  /**************************************************************************
   * Basic information
   *************************************************************************/

  /**
   * @dev Get superfluid host contract address
   */
  function getHost() external view returns (address host);

  /**
   * @dev Encoded liquidation type data mainly used for handling stack to deep errors
   *
   * Note:
   * - version: 1
   * - liquidationType key:
   *    - 0 = reward account receives reward (PIC period)
   *    - 1 = liquidator account receives reward (Pleb period)
   *    - 2 = liquidator account receives reward (Pirate period/bailout)
   */
  struct LiquidationTypeData {
    uint256 version;
    uint8 liquidationType;
  }

  /**************************************************************************
   * Real-time balance functions
   *************************************************************************/

  /**
   * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
   * @param account for the query
   * @param timestamp Time of balance
   * @return availableBalance Real-time balance
   * @return deposit Account deposit
   * @return owedDeposit Account owed Deposit
   */
  function realtimeBalanceOf(address account, uint256 timestamp)
    external
    view
    returns (
      int256 availableBalance,
      uint256 deposit,
      uint256 owedDeposit
    );

  /**
   * @notice Calculate the realtime balance given the current host.getNow() value
   * @dev realtimeBalanceOf with timestamp equals to block timestamp
   * @param account for the query
   * @return availableBalance Real-time balance
   * @return deposit Account deposit
   * @return owedDeposit Account owed Deposit
   */
  function realtimeBalanceOfNow(address account)
    external
    view
    returns (
      int256 availableBalance,
      uint256 deposit,
      uint256 owedDeposit,
      uint256 timestamp
    );

  /**
   * @notice Check if account is critical
   * @dev A critical account is when availableBalance < 0
   * @param account The account to check
   * @param timestamp The time we'd like to check if the account is critical (should use future)
   * @return isCritical Whether the account is critical
   */
  function isAccountCritical(address account, uint256 timestamp)
    external
    view
    returns (bool isCritical);

  /**
   * @notice Check if account is critical now (current host.getNow())
   * @dev A critical account is when availableBalance < 0
   * @param account The account to check
   * @return isCritical Whether the account is critical
   */
  function isAccountCriticalNow(address account)
    external
    view
    returns (bool isCritical);

  /**
   * @notice Check if account is solvent
   * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
   * @param account The account to check
   * @param timestamp The time we'd like to check if the account is solvent (should use future)
   * @return isSolvent
   */
  function isAccountSolvent(address account, uint256 timestamp)
    external
    view
    returns (bool isSolvent);

  /**
   * @notice Check if account is solvent now
   * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
   * @param account The account to check
   * @return isSolvent
   */
  function isAccountSolventNow(address account)
    external
    view
    returns (bool isSolvent);

  /**
   * @notice Get a list of agreements that is active for the account
   * @dev An active agreement is one that has state for the account
   * @param account Account to query
   * @return activeAgreements List of accounts that have non-zero states for the account
   */
  function getAccountActiveAgreements(address account)
    external
    view
    returns (ISuperAgreement[] memory activeAgreements);

  /**************************************************************************
   * Super Agreement hosting functions
   *************************************************************************/

  /**
   * @dev Create a new agreement
   * @param id Agreement ID
   * @param data Agreement data
   */
  function createAgreement(bytes32 id, bytes32[] calldata data) external;

  /**
   * @dev Agreement created event
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @param data Agreement data
   */
  event AgreementCreated(
    address indexed agreementClass,
    bytes32 id,
    bytes32[] data
  );

  /**
   * @dev Get data of the agreement
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @return data Data of the agreement
   */
  function getAgreementData(
    address agreementClass,
    bytes32 id,
    uint256 dataLength
  ) external view returns (bytes32[] memory data);

  /**
   * @dev Create a new agreement
   * @param id Agreement ID
   * @param data Agreement data
   */
  function updateAgreementData(bytes32 id, bytes32[] calldata data) external;

  /**
   * @dev Agreement updated event
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @param data Agreement data
   */
  event AgreementUpdated(
    address indexed agreementClass,
    bytes32 id,
    bytes32[] data
  );

  /**
   * @dev Close the agreement
   * @param id Agreement ID
   */
  function terminateAgreement(bytes32 id, uint256 dataLength) external;

  /**
   * @dev Agreement terminated event
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   */
  event AgreementTerminated(address indexed agreementClass, bytes32 id);

  /**
   * @dev Update agreement state slot
   * @param account Account to be updated
   *
   * NOTE
   * - To clear the storage out, provide zero-ed array of intended length
   */
  function updateAgreementStateSlot(
    address account,
    uint256 slotId,
    bytes32[] calldata slotData
  ) external;

  /**
   * @dev Agreement account state updated event
   * @param agreementClass Contract address of the agreement
   * @param account Account updated
   * @param slotId slot id of the agreement state
   */
  event AgreementStateUpdated(
    address indexed agreementClass,
    address indexed account,
    uint256 slotId
  );

  /**
   * @dev Get data of the slot of the state of an agreement
   * @param agreementClass Contract address of the agreement
   * @param account Account to query
   * @param slotId slot id of the state
   * @param dataLength length of the state data
   */
  function getAgreementStateSlot(
    address agreementClass,
    address account,
    uint256 slotId,
    uint256 dataLength
  ) external view returns (bytes32[] memory slotData);

  /**
   * @notice Settle balance from an account by the agreement
   * @dev The agreement needs to make sure that the balance delta is balanced afterwards
   * @param account Account to query.
   * @param delta Amount of balance delta to be settled
   *
   * Modifiers:
   *  - onlyAgreement
   */
  function settleBalance(address account, int256 delta) external;

  /**
   * @dev Make liquidation payouts (v2)
   * @param id Agreement ID
   * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
   * @param liquidatorAccount Address of the executor of the liquidation
   * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
   * @param targetAccount Account of the stream sender
   * @param rewardAmount The amount the reward recepient account will receive
   * @param targetAccountBalanceDelta The amount the sender account balance should change by
   *
   * - If a bailout is required (bailoutAmount > 0)
   *   - the actual reward (single deposit) goes to the executor,
   *   - while the reward account becomes the bailout account
   *   - total bailout include: bailout amount + reward amount
   *   - the targetAccount will be bailed out
   * - If a bailout is not required
   *   - the targetAccount will pay the rewardAmount
   *   - the liquidator (reward account in PIC period) will receive the rewardAmount
   *
   * Modifiers:
   *  - onlyAgreement
   */
  function makeLiquidationPayoutsV2(
    bytes32 id,
    bytes memory liquidationTypeData,
    address liquidatorAccount,
    bool useDefaultRewardAccount,
    address targetAccount,
    uint256 rewardAmount,
    int256 targetAccountBalanceDelta
  ) external;

  /**
   * @dev Agreement liquidation event v2 (including agent account)
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @param liquidatorAccount Address of the executor of the liquidation
   * @param targetAccount Account of the stream sender
   * @param rewardAccount Account that collects the reward or bails out insolvent accounts
   * @param rewardAmount The amount the reward recipient account balance should change by
   * @param targetAccountBalanceDelta The amount the sender account balance should change by
   * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
   *
   * NOTE:
   * Reward account rule:
   * - if the agreement is liquidated during the PIC period
   *   - the rewardAccount will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
   *   - the targetAccount will pay for the rewardAmount
   * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
   *   - the liquidatorAccount will get the rewardAmount (remaining deposit)
   *   - the targetAccount will pay for the rewardAmount
   * - if the targetAccount is insolvent
   *   - the liquidatorAccount will get the rewardAmount (single deposit)
   *   - the rewardAccount will pay for both the rewardAmount and bailoutAmount
   *   - the targetAccount will receive the bailoutAmount
   */
  event AgreementLiquidatedV2(
    address indexed agreementClass,
    bytes32 id,
    address indexed liquidatorAccount,
    address indexed targetAccount,
    address rewardAccount,
    uint256 rewardAmount,
    int256 targetAccountBalanceDelta,
    bytes liquidationTypeData
  );

  /**************************************************************************
   * Function modifiers for access control and parameter validations
   *
   * While they cannot be explicitly stated in function definitions, they are
   * listed in function definition comments instead for clarity.
   *
   * NOTE: solidity-coverage not supporting it
   *************************************************************************/

  /// @dev The msg.sender must be host contract
  //modifier onlyHost() virtual;

  /// @dev The msg.sender must be a listed agreement.
  //modifier onlyAgreement() virtual;

  /**************************************************************************
   * DEPRECATED
   *************************************************************************/

  /**
   * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @param penaltyAccount Account of the agreement to be penalized
   * @param rewardAccount Account that collect the reward
   * @param rewardAmount Amount of liquidation reward
   *
   * NOTE:
   *
   * [DEPRECATED] Use AgreementLiquidatedV2 instead
   */
  event AgreementLiquidated(
    address indexed agreementClass,
    bytes32 id,
    address indexed penaltyAccount,
    address indexed rewardAccount,
    uint256 rewardAmount
  );

  /**
   * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
   * @param bailoutAccount Account that bailout the penalty account
   * @param bailoutAmount Amount of account bailout
   *
   * NOTE:
   *
   * [DEPRECATED] Use AgreementLiquidatedV2 instead
   */
  event Bailout(address indexed bailoutAccount, uint256 bailoutAmount);

  /**
   * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
   * @param liquidatorAccount Account of the agent that performed the liquidation.
   * @param agreementClass Contract address of the agreement
   * @param id Agreement ID
   * @param penaltyAccount Account of the agreement to be penalized
   * @param bondAccount Account that collect the reward or bailout accounts
   * @param rewardAmount Amount of liquidation reward
   * @param bailoutAmount Amount of liquidation bailouot
   *
   * NOTE:
   * Reward account rule:
   * - if bailout is equal to 0, then
   *   - the bondAccount will get the rewardAmount,
   *   - the penaltyAccount will pay for the rewardAmount.
   * - if bailout is larger than 0, then
   *   - the liquidatorAccount will get the rewardAmouont,
   *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
   *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
   */
  event AgreementLiquidatedBy(
    address liquidatorAccount,
    address indexed agreementClass,
    bytes32 id,
    address indexed penaltyAccount,
    address indexed bondAccount,
    uint256 rewardAmount,
    uint256 bailoutAmount
  );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility
function _transfer(
    address payable _to,
    address _paymentToken,
    uint256 _amount
) {
    if (_paymentToken == ETH) {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "_transfer: ETH transfer failed");
    } else {
        SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
    }
}