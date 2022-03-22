// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function borrowForPayNFT(uint256 amount) external;

    function returnForBorrow(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

contract Market is Context, ERC721Holder, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct ReserveAuction {
        uint256 auctionId;
        uint256 tokenId;
        address payable beneficiary;
        uint256 endTime;
        address payable bidder;
        uint256 startPrice;
        uint256 amount;
        bool isFund;
        bool isPublic;
        bool auctionEnd;
        address[] allowList;
    }

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        uint256 stakingFund;
        uint256 price;
        address payable seller;
        uint256 startTime;
        uint256 endTime;
        bool isFund;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address payable buyer;
        uint256 price;
        uint256 endTime;
    }

    uint32 private auctionBidPeriod = 5;

    uint256 private auctionId = 0;

    uint256 private listingId = 0;

    uint256 private offerId = 0;

    uint16 private sellerFee = 250; // is 2.5 percent

    IERC721 private nft;

    IERC20 private token;

    IStaking private staking;

    mapping(uint256 => uint256) private nftIdToAuctionId;

    mapping(uint256 => ReserveAuction) private auctionIdToReserveAuction;

    mapping(uint256 => mapping(address => bool)) private auctionIdAllowList;

    mapping(uint256 => Listing) private listings;

    mapping(uint256 => uint256) private nftIdToListingId;

    mapping(uint256 => Offer) private offers;

    mapping(uint256 => EnumerableSet.UintSet) private offerListKeys;

    event PrivateBidCreated(
        uint256 indexed auctionId,
        address indexed creator,
        uint256 indexed nftId,
        uint256 price,
        uint256 exptime
    );

    event PrivateBidPlaced(
        uint256 indexed auctionId,
        address indexed bider,
        uint256 indexed nftId,
        uint256 price
    );

    event PrivateBitClosed(
        uint256 indexed auctionId,
        uint256 indexed nftId,
        bool isWon,
        address buyer,
        uint256 price
    );

    event ListingCreated(
        uint256 indexed listingId,
        address indexed creator,
        uint256 indexed nftId,
        uint256 price,
        uint256 startTime,
        uint256 exptime
    );

    event PurchaseCreated(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 indexed nftId,
        uint256 price
    );

    event ListingCanceled(uint256 indexed listingId, address indexed cancelBy);

    event OfferCreated(
        uint256 indexed offerId,
        address indexed buyer,
        uint256 indexed nftId,
        uint256 price,
        uint256 exptime
    );

    event ApproveOffer(
        uint256 indexed offerId,
        address indexed seller,
        address indexed buyer,
        uint256 nftId,
        uint256 price
    );

    event OfferCanceled(
        uint256 indexed offerId,
        address indexed buyer,
        uint256 indexed nftId
    );

    constructor(
        IERC20 tokenAddr,
        address stakingAddr,
        IERC721 nftAddr
    ) {
        token = IERC20(tokenAddr);
        nft = IERC721(nftAddr);
        staking = IStaking(stakingAddr);
    }

    function getEndTime() public view returns (uint256 time) {
        return block.timestamp + 7 days;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        auctionId++;
        return auctionId;
    }

    function _getNextAndIncrementListingId() internal returns (uint256) {
        listingId++;
        return listingId;
    }

    function _getNextAndIncrementOfferId() internal returns (uint256) {
        offerId++;
        return offerId;
    }

    function createPrivateBidList(
        uint256 nftId,
        uint256 reservePrice,
        bool isFund,
        address[] memory allowList
    ) public {
        nft.safeTransferFrom(_msgSender(), address(this), nftId);
        uint256 _auctionID = _getNextAndIncrementAuctionId();

        ReserveAuction storage act = auctionIdToReserveAuction[_auctionID];
        nftIdToAuctionId[nftId] = _auctionID;
        act.auctionId = _auctionID;
        act.tokenId = nftId;
        act.isPublic = false;
        act.beneficiary = payable(_msgSender());
        act.endTime = getEndTime();
        act.bidder = payable(0);
        act.startPrice = reservePrice;
        act.amount = reservePrice;
        act.isFund = isFund;
        act.allowList = allowList;

        for (uint256 i = 0; i < allowList.length; i++) {
            auctionIdAllowList[_auctionID][allowList[i]] = true;
        }

        emit PrivateBidCreated(
            _auctionID,
            _msgSender(),
            nftId,
            reservePrice,
            getEndTime()
        );
    }

    function setSellerFee(uint16 _fee) public onlyOwner {
        sellerFee = _fee;
    }

    function setNFTAddr(address _nftAddr) public onlyOwner {
        nft = IERC721(_nftAddr);
    }

    function getSellerFee() public view returns (uint256) {
        return sellerFee;
    }

    function isPublicBid(uint256 _auctionID) public view returns (bool) {
        return auctionIdToReserveAuction[_auctionID].isPublic;
    }

    function uintToString(uint256 v) internal pure returns (bytes memory str) {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = s;
    }

    function _checkValueLength(uint256 amount, int256 minus)
        internal
        pure
        returns (int256)
    {
        uint256 strLength = uintToString(amount).length;
        return int256(strLength) - 18 + minus;
    }

    function _multiplyAndPow(
        uint256 amount,
        uint256 multiply,
        int256 minus
    ) internal pure returns (uint256) {
        int256 powVal = _checkValueLength(amount, minus);
        if (powVal < 0) {
            return multiply / (10**uint256(-powVal));
        } else {
            return uint256(multiply * uint256(10**uint256(powVal)));
        }
    }

    function checkWhiteList(uint256 _auctionID) public view returns (bool) {
        return _isWhitelistedSale(_auctionID);
    }

    function getWhiteList(uint256 _auctionID)
        public
        view
        returns (address[] memory)
    {
        return auctionIdToReserveAuction[_auctionID].allowList;
    }

    function getMinBid(uint256 _auctionID) public view returns (uint256) {
        ReserveAuction storage act = auctionIdToReserveAuction[_auctionID];
        uint256 minBid;
        if (act.amount >= _multiplyAndPow(act.amount, 5 ether, -1)) {
            minBid = _multiplyAndPow(act.amount, 0.5 ether, -2);
        } else if (
            act.amount >= _multiplyAndPow(act.amount, 1 ether, -1) &&
            act.amount < _multiplyAndPow(act.amount, 2 ether, -1)
        ) {
            minBid = _multiplyAndPow(act.amount, 1 ether, -3);
        } else if (act.amount >= _multiplyAndPow(act.amount, 2 ether, -1)) {
            minBid = _multiplyAndPow(act.amount, 2.5 ether, -3);
        }
        return act.amount + minBid;
    }

    function getCurrentBidAmount(uint256 _auctionID)
        public
        view
        returns (uint256)
    {
        return auctionIdToReserveAuction[_auctionID].amount;
    }

    function getLastestAuctionId() public view returns (uint256) {
        return auctionId;
    }

    function getLastestListingId() public view returns (uint256) {
        return listingId;
    }

    function getLastestOfferId() public view returns (uint256) {
        return offerId;
    }

    modifier auctionOngoing(uint256 _auctionID) {
        require(_isAuctionOnGoing(_auctionID), "Auction has ended");
        _;
    }

    modifier listingOnGoing(uint256 _listingID) {
        require(_isListingOnGoing(_listingID), "listing has ended");
        _;
    }

    // check if the highest bidder can purchase this NFT.
    modifier onlyApplicableBuyer(uint256 _auctionID) {
        if (!isPublicBid(_auctionID)) {
            require(
                _isWhitelistedSale(_auctionID),
                "Only the whitelisted buyer"
            );
        }
        _;
    }

    modifier bidRequirements(uint256 _auctionID, uint256 _tokenAmount) {
        uint256 minBid = getMinBid(_auctionID);
        require(
            _tokenAmount >= minBid,
            string(
                abi.encodePacked(
                    "require minimum bid volume : ",
                    uintToString(minBid)
                )
            )
        );
        require(
            token.balanceOf(msg.sender) > minBid,
            "Not enough funds to bid on NFT"
        );
        _;
    }

    modifier offerRequirements(uint256 _tokenAmount) {
        require(
            token.balanceOf(msg.sender) > _tokenAmount,
            "Not enough funds to bid on NFT"
        );
        _;
    }

    modifier isAuctionEnd(uint256 _auctionID) {
        require(!_isAuctionEnd(_auctionID), "this auction already end");
        _;
    }

    function _isWhitelistedSale(uint256 _auctionID)
        internal
        view
        returns (bool)
    {
        return auctionIdAllowList[_auctionID][msg.sender];
    }

    modifier isOwner(uint256 _tokenId) {
        require(_isOwner(_tokenId), "You not own this item");
        _;
    }

    modifier purchaseRequirement(uint256 _listingID) {
        require(
            token.balanceOf(msg.sender) >= listings[_listingID].price,
            "Not enough funds"
        );
        _;
    }

    modifier isOfferExpired(uint256 _offerId) {
        require(_isOfferExpired(_offerId), "offer already expired");
        _;
    }

    function _isOwner(uint256 _tokenId) internal view returns (bool) {
        return nft.ownerOf(_tokenId) == address(msg.sender);
    }

    function _isListingOnGoing(uint256 _listing) internal view returns (bool) {
        Listing storage listing = listings[_listing];
        if (listing.isFund) {
            return true;
        }
        return
            block.timestamp >= listing.startTime &&
            block.timestamp < listing.endTime;
    }

    function _isOfferExpired(uint256 _offerId) internal view returns (bool) {
        Offer storage offer = offers[_offerId];
        return block.timestamp < offer.endTime;
    }

    function _isAuctionOnGoing(uint256 _auctionID)
        internal
        view
        returns (bool)
    {
        ReserveAuction storage act = auctionIdToReserveAuction[_auctionID];
        uint256 auctionEndTimestamp = act.endTime;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp ||
            act.auctionEnd == false);
    }

    function _isAuctionEnd(uint256 _auctionID) internal view returns (bool) {
        return auctionIdToReserveAuction[_auctionID].auctionEnd;
    }

    function getAuctionByNftId(uint256 _nftId)
        public
        view
        returns (ReserveAuction memory)
    {
        return auctionIdToReserveAuction[nftIdToAuctionId[_nftId]];
    }

    function getAuctionPrice(uint256 _auctionID) public view returns (uint256) {
        return auctionIdToReserveAuction[_auctionID].amount;
    }

    function makeBid(uint256 _auctionID, uint128 _tokenAmount)
        external
        payable
        auctionOngoing(_auctionID)
        bidRequirements(_auctionID, _tokenAmount)
        onlyApplicableBuyer(_auctionID)
    {
        ReserveAuction storage act = auctionIdToReserveAuction[_auctionID];
        if (act.bidder != address(0)) {
            _payout(act.bidder, act.amount);
        }
        act.amount = _tokenAmount;
        act.bidder = payable(msg.sender);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        // lock coin and return coins

        emit PrivateBidPlaced(
            _auctionID,
            msg.sender,
            act.tokenId,
            _tokenAmount
        );
    }

    function _payout(address _receiver, uint256 _amount) internal {
        token.safeTransfer(_receiver, _amount);
    }

    function _returnBorrowToStaking(uint256 _amount) internal {
        uint256 allowance = token.allowance(address(this), address(staking));
        if (allowance < _amount) {
            token.approve(address(staking), _amount);
        }
        staking.returnForBorrow(_amount);
    }

    function endBid(uint256 _auctionID) public isAuctionEnd(_auctionID) {
        ReserveAuction storage act = auctionIdToReserveAuction[_auctionID];
        if (act.auctionEnd == false) {
            if (act.bidder != address(0)) {
                nft.transferFrom(address(this), act.bidder, act.tokenId);
                _returnBorrowToStaking(act.startPrice);
                // TODO transfer profit to treasure address (profit is act.amount - act.startPrice)
            } else {
                uint256 _listingID = _makeListing(
                    act.tokenId,
                    block.timestamp,
                    0,
                    act.startPrice
                );
                setListingFund(_listingID);
            }
        }
        act.auctionEnd = true;
    }

    function _makeListing(
        uint256 _tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice
    ) private returns (uint256) {
        uint256 _listingID = _getNextAndIncrementListingId();
        nftIdToListingId[_listingID] = _tokenId;
        Listing storage listing = listings[_listingID];
        listing.listingId = _listingID;
        listing.tokenId = _tokenId;
        listing.seller = payable(_msgSender());
        listing.startTime = startTime;
        listing.endTime = endTime;
        listing.price = reservePrice;
        listing.isFund = false;
        emit ListingCreated(
            _listingID,
            _msgSender(),
            _tokenId,
            listing.price,
            startTime,
            endTime
        );

        return _listingID;
    }

    function makeListing(
        uint256 _tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice
    ) public isOwner(_tokenId) returns (uint256) {
        require(
            nft.isApprovedForAll(_msgSender(), address(this)),
            "permission not allow"
        );
        return _makeListing(_tokenId, startTime, endTime, reservePrice);
    }

    function setListingFund(uint256 _listingID) private {
        Listing storage listing = listings[_listingID];
        uint256 reservePrice = listing.price;
        listing.isFund = true;
        uint256 salePrice = (reservePrice * 2000) / 10000; // 20 percent
        listing.stakingFund = reservePrice;
        listing.price = reservePrice + salePrice;
        listing.seller = payable(address(this));
    }

    function getListingPrice(uint256 _listingID) public view returns (uint256) {
        return listings[_listingID].price;
    }

    function getListingByTokenId(uint256 _tokenId, bool _includeExpired)
        public
        view
        returns (Listing memory)
    {
        Listing storage lis = listings[nftIdToListingId[_tokenId]];
        Listing memory mList;
        if (_includeExpired) {
            mList = lis;
        } else {
            if (_isListingOnGoing(lis.listingId)) {
                mList = lis;
            }
        }

        return mList;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function purchase(uint256 _listingID)
        public
        payable
        purchaseRequirement(_listingID)
        listingOnGoing(_listingID)
    {
        Listing storage listing = listings[_listingID];
        nft.safeTransferFrom(
            address(listing.seller),
            _msgSender(),
            listing.tokenId
        );

        token.safeTransferFrom(
            address(_msgSender()),
            address(this),
            listing.price
        );
        if (listing.isFund) {
            _returnBorrowToStaking(listing.stakingFund);
            // TODO transfer profit to treasure address
        } else {
            uint256 fee = (listing.price * sellerFee) / 10000;
            token.safeTransfer(listing.seller, listing.price - fee);
            // TODO transfer fee to treasure address
        }

        delete listings[_listingID];

        emit PurchaseCreated(
            _listingID,
            _msgSender(),
            listing.tokenId,
            listing.price
        );
    }

    function cancelListing(uint256 _listingID) public {
        Listing storage listing = listings[_listingID];
        require(listing.seller == _msgSender(), "you are not own");

        delete listings[_listingID];

        emit ListingCanceled(_listingID, _msgSender());
    }

    function makeOffer(
        uint256 _tokenID,
        uint256 _endTime,
        uint256 _reservePrice
    ) public payable offerRequirements(_reservePrice) returns (uint256) {
        uint256 _offerID = _getNextAndIncrementOfferId();

        Offer storage offer = offers[_offerID];
        offer.offerId = _offerID;
        offer.tokenId = _tokenID;
        offer.buyer = payable(_msgSender());
        offer.endTime = _endTime;
        offer.price = _reservePrice;

        offerListKeys[_tokenID].add(_offerID);
        // token.safeTransferFrom(msg.sender, address(this), reservePrice);
        emit OfferCreated(
            _offerID,
            _msgSender(),
            _tokenID,
            _reservePrice,
            _endTime
        );

        return _offerID;
    }

    function approveOffer(uint256 _tokenID, uint256 _offerID)
        public
        isOwner(_tokenID)
        isOfferExpired(_offerID)
    {
        Offer storage offer = offers[_offerID];

        nft.safeTransferFrom(_msgSender(), offer.buyer, offer.tokenId);

        uint256 fee = (offer.price * sellerFee) / 10000;
        token.safeTransferFrom(offer.buyer, _msgSender(), offer.price - fee);
        // TODO transfer fee to treasure address

        delete offers[_offerID];
        delete offerListKeys[offer.tokenId];

        emit ApproveOffer(
            _offerID,
            _msgSender(),
            offer.buyer,
            offer.tokenId,
            offer.price
        );
    }

    function getOffersByNftId(uint256 _tokenID, bool _includeExpired)
        public
        view
        returns (Offer[] memory)
    {
        uint256 rl;
        uint256 offLength = offerListKeys[_tokenID].length();
        if (_includeExpired) {
            rl = offLength;
        } else {
            for (uint256 i = 0; i < offLength; i++) {
                if (
                    block.timestamp <
                    offers[offerListKeys[_tokenID].at(i)].endTime
                ) {
                    rl++;
                }
            }
        }

        Offer[] memory _offers = new Offer[](rl);
        uint256 j;
        for (uint256 i = 0; i < offLength; i++) {
            Offer storage off = offers[offerListKeys[_tokenID].at(i)];
            if (_includeExpired) {
                _offers[j] = off;
                j++;
            } else {
                if (block.timestamp < off.endTime) {
                    _offers[j] = off;
                    j++;
                }
            }
        }

        return _offers;
    }

    function cancelOffer(uint256 _offerId) public {
        require(offers[_offerId].buyer == _msgSender(), "only owner");
        offerListKeys[offers[_offerId].tokenId].remove(_offerId);
        delete offers[_offerId];

        emit OfferCanceled(_offerId, _msgSender(), offers[_offerId].tokenId);
    }
}