// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OperatableTemplateBaseContract is Ownable {
    using SafeMath for uint256;
    using ERC165Checker for address;
    using Address for address;

    string private name;
    string private description;

    mapping(uint256 => string) private template_names;
    mapping(uint256 => string) private template_descs;
    mapping(uint256 => uint256) private operation_prices;
    mapping(uint256 => bool) private template_enabled;

    //For some reason in marketing we have template specific merchant if not set just use merchant address.
    mapping(uint256 => address) private template_merchants;

    address private merchant_address;
    address private price_currency_contract = address(0);
    bytes4 constant price_currency_interface_id = type(IERC20).interfaceId;

    constructor(string memory name_,string memory description_,address price_currency_contract_) {
        name = name_;
        description = description_;
        merchant_address = msg.sender;
        _set_price_currency_contract_internal(price_currency_contract_);
    }
    event OnTemplateUndefined(uint256 template_id);
    function _set_price_currency_contract_internal(address addr) internal {
        require(addr == address(0) || addr.supportsInterface(price_currency_interface_id),"UNSUPPORT_CURRENCY");
        price_currency_contract = addr;
    }
    function get_name() public view returns (string memory){return name;}
    function get_description() public view returns (string memory){return description;}

    function set_name(string memory name_) external onlyOwner{name = name_;}
    function set_description(string memory desc_) external onlyOwner{name = desc_;}
    

    function set_price_currency_contract(address addr) external onlyOwner {
        _set_price_currency_contract_internal(addr);
    }
    function set_merchant(address merchant) external onlyOwner {
        require((merchant_address != merchant) && (merchant != address(0)),"INVALID_MERCHANT");
        require(!merchant.isContract(),"MERCHANT_CANNOT_CONTRACT");
        merchant_address = merchant;
    }
    function get_price_currency_contract_address() public view returns (address){return price_currency_contract;}
    function get_last_template_id() internal view virtual returns (uint256) {return 0;}
    function get_merchant_address(uint256 template_id) internal view returns(address){
       address addr = template_merchants[template_id];
       return addr != address(0) ? addr : merchant_address;
    }
    function undefine_template(uint256 template_id) external onlyOwner {
        _undefine_template(template_id);
    }
    function undefine_templates(uint256[] memory template_ids) external onlyOwner {
         for(uint256 i = 0; i < template_ids.length; i++)
           _undefine_template(template_ids[i]);    
    }

    function update_template_name(uint256 template_id,string memory template_name_) external onlyOwner{
        _udpate_template_name(template_id,template_name_);
    }
    function update_template_names(uint256[] memory template_ids,string[] memory template_names_) external onlyOwner {
        require(template_ids.length == template_names_.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _udpate_template_name(template_ids[i],template_names_[i]);    
    }
    function update_template_desc(uint256 template_id,string memory desc) external onlyOwner{
        _update_template_desc(template_id,desc);
    }
    function update_template_descs(uint256[] memory template_ids,string[] memory descs) external onlyOwner {
        require(template_ids.length == descs.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_template_desc(template_ids[i],descs[i]);    
    }
    function update_operation_price(uint256 template_id,uint256 price) external onlyOwner{
        _update_operation_price(template_id,price);
    }
    function update_operation_prices(uint256[] memory template_ids,uint256[] memory prices) external onlyOwner {
        require(template_ids.length == prices.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_operation_price(template_ids[i],prices[i]);    
    }

    function update_template_merchant(uint256 template_id,address merchant) external onlyOwner{
        _update_template_merchant(template_id,merchant);
    }
    function update_template_merchants(uint256[] memory template_ids,address[] memory merchants) external onlyOwner {
        require(template_ids.length == merchants.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_template_merchant(template_ids[i],merchants[i]);    
    }

    function is_defined(uint256 template_id) internal view returns(bool) {return (bytes(template_names[template_id]).length > 0);}
    function is_enabled(uint256 template_id) internal view returns(bool) {return template_enabled[template_id];}
    function get_metadata(uint256 template_id) internal view returns (string memory,string memory,uint256,bool,address) {return (template_names[template_id],template_descs[template_id],operation_prices[template_id],template_enabled[template_id],get_merchant_address(template_id));}

    function get_template_ids(uint256 page_index,uint256 per_page) public view returns (uint256[] memory){
        
        uint256 last_id = get_last_template_id();
        uint256 start_offset_counter = 1;
        uint256 start_offset = page_index.mul(per_page).add(1);
        
        uint256 start_id = 1;
        while((start_offset_counter < start_offset) && (start_id <= last_id)){
            if(is_defined(start_id))
                start_offset_counter = start_offset_counter.add(1);
            start_id = start_id.add(1);
        }
        
        if(start_id <= last_id){
            uint256 _counter = 0;
            uint256[] memory out_ids = new uint256[](per_page);
            uint256 _next_id = start_id;
            while(_next_id <= last_id && (_counter < per_page)){
                while(!is_defined(_next_id) && (_next_id <= last_id)){
                    _next_id = _next_id.add(1);
                }
                if(_next_id <= last_id)
                out_ids[_counter] = _next_id;
                _next_id = _next_id.add(1);
                _counter = _counter.add(1);
            }
            return out_ids;
        }
        return new uint256[](0);
    }
    function enable_template(uint256 template_id,bool enabled) external onlyOwner {
        _enable_template(template_id,enabled);
    }
    function enable_templates(uint256[] memory template_ids,bool[] memory enables) external onlyOwner {
        require(template_ids.length == enables.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _enable_template(template_ids[i],enables[i]);
    }
    function _undefine_template(uint256 template_id) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");
        _clear_template_metadata(template_id);
        onUndefineTemplate(template_id);
        emit OnTemplateUndefined(template_id);
    }
    function _fill_template_metadata(uint256 template_id,string memory name_,string memory desc,uint256 op_price,bool start_enabled,address merchant) internal{
        template_names[template_id] = name_;
        template_descs[template_id] = desc;
        operation_prices[template_id] = op_price;
        template_enabled[template_id] = start_enabled;
        template_merchants[template_id] = merchant;
    }
    function _clear_template_metadata(uint256 template_id) internal{
        delete template_names[template_id];
        delete template_descs[template_id];
        delete operation_prices[template_id];
        delete template_enabled[template_id];
        delete template_merchants[template_id];
    }
    function _udpate_template_name(uint256 template_id,string memory name_) internal{
        require(bytes(template_names[template_id]).length > 0,"NO_TPL_DEFINED");        
        require(bytes(name_).length > 0,"NO_TPL_NAME");        
        template_names[template_id] = name_;
    }
    function _update_template_desc(uint256 template_id,string memory desc) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        template_descs[template_id] = desc;
    }
    function _update_operation_price(uint256 template_id,uint256 price) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        operation_prices[template_id] = price;
    }
    function _update_template_merchant(uint256 template_id,address merchant) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");
        require(merchant != address(0),"NULL_ADDRESS");
        require(!merchant.isContract(),"MERCHANT_CANNOT_CONTRACT");       
        template_merchants[template_id] = merchant;
    }
    function _enable_template(uint256 template_id,bool enabled) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        template_enabled[template_id] = enabled;
    }
    function consume_operation_cost(uint256 template_id,uint256 applyCount) internal {
        require(applyCount > 0,"ZERO_APPLYCOUNT");
        uint256 op_price = operation_prices[template_id];
        if(op_price == 0)
            return;

        address _merchant_addr = get_merchant_address(template_id);
        require(_merchant_addr != address(0),"NO_MERCHANT_ADDR");

        uint256 total_op_cost = op_price.mul(applyCount);
        if(price_currency_contract != address(0)){
           uint256 available_balance = IERC20(price_currency_contract).balanceOf(msg.sender);
           require(available_balance >= total_op_cost,"UNSUFFICIENT_BALANCE");
           IERC20(price_currency_contract).transferFrom(msg.sender, _merchant_addr, total_op_cost);
           if(msg.value > 0)
              payable(msg.sender).transfer(msg.value);
        }
        else{
            require(msg.value >= total_op_cost,"UNSUFFICIENT_BALANCE");
            uint256 remain_value = msg.value.sub(total_op_cost);
            payable(_merchant_addr).transfer(total_op_cost);
            payable(msg.sender).transfer(remain_value);
        }
    }
    
    function isTemplateValid(uint256) internal virtual returns (bool) {return false;}
    function onUndefineTemplate(uint256) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatableTemplateBaseContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../Interfaces/ITokenOperatableTemplate.sol";


contract TokenOperatableTemplateContract is OperatableTemplateBaseContract,ITokenOperatableTemplate,ERC165 {
    using SafeMath for uint256;
    using ERC165Checker for address;
    using Address for address;

    //NFT or Token to mint
    address private token_contract = address(0);

    //Interface id of token or NFT.
    bytes4 private token_constract_interface_id = 0xffffffff;

    constructor(string memory name_,string memory description_,address token_contract_,address price_currency_contract_) 
        OperatableTemplateBaseContract(name_,description_,price_currency_contract_) {
        token_constract_interface_id = fetch_token_contract_interface_id();
        _set_token_contract_internal(token_contract_);
    }

    function fetch_token_contract_interface_id() internal virtual returns(bytes4) {return 0xffffffff;}    
    function _set_token_contract_internal(address addr) internal{
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_TOKEN");
        token_contract = addr;
    }
    function set_token_contract(address addr) external onlyOwner{
        _set_token_contract_internal(addr);
    }

    function get_token_contract_address() internal view returns (address){return token_contract;}
    function get_token_contract() external view virtual override returns (address){return token_contract;}
    function get_template_metadata(uint256 template_id) external view virtual override returns (string memory,string memory,uint256,bool,address){return get_metadata(template_id);}
    function is_template_defined(uint256 template_id) external view virtual override returns (bool){return is_defined(template_id);}
    function is_template_enabled(uint256 template_id) external view virtual override returns (bool){return is_enabled(template_id);}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITokenOperatableTemplate).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../base/TokenOperatableTemplateContract.sol";
import "../Interfaces/IERC1155TokenContract.sol";
import "../Interfaces/IERC1155CraftTemplates.sol";

contract ERC1155Crafts is TokenOperatableTemplateContract , IERC1155CraftTemplates {
    using SafeMath for uint256;

    struct CraftElement{
        uint256 token_id;
        uint256 amount;
    }
    
    struct CraftFormula {
        CraftElement[] inputs;
        CraftElement[] outputs;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _templateIds;

    mapping(uint256 => CraftFormula) private templates;
    event OnCraftFoumulaDefined(uint256 template_id,CraftFormula formula);
    event OnCraftFormulaUpdated(uint256 template_id,CraftFormula formula);

    constructor(string memory name_,string memory description_,address token_contract_,address price_currency_contract_)
    TokenOperatableTemplateContract(name_,description_,token_contract_,price_currency_contract_) {
        
    }

    function fetch_token_contract_interface_id() internal virtual override returns(bytes4) {
       return type(IERC1155TokenContract).interfaceId;
    }
    function get_last_template_id() internal view virtual override returns (uint256) {return _templateIds.current();}

    function define_template(string memory name,string memory desc,uint256 op_price,bool start_enabled,address merchant,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner returns (uint256){        
        require(bytes(name).length > 0,"NO_NAME");

        uint256 input_count = input_token_ids.length;
        require(input_count > 0,"NO_INPUTS");
        require(input_count == input_amounts.length,"INPUT_DIM_MISMATCH");

        uint256 output_count = output_token_ids.length;
        require(output_count > 0,"NO_OUTPUT");
        require(output_count == output_amounts.length,"OUTPUT_DIM_MISMATCH");

        _templateIds.increment();
        uint256 tpl_id = _templateIds.current();
        _fill_template_metadata(tpl_id,name,desc,op_price,start_enabled,merchant);
        
        for(uint256 i = 0; i < input_count; i++)
            templates[tpl_id].inputs.push(CraftElement(input_token_ids[i],input_amounts[i]));
       
        for(uint256 i = 0; i < output_count; i++)
            templates[tpl_id].outputs.push(CraftElement(output_token_ids[i],output_amounts[i]));
        
        emit OnCraftFoumulaDefined(tpl_id,templates[tpl_id]);
        return tpl_id;
    }
    function udpate_template_formula(uint256 template_id,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner {
        require(is_defined(template_id),"NOT_DEFINED");

        uint256 input_count = input_token_ids.length;
        require((input_count > 0) && (input_count == input_amounts.length),"INPUT_DIM_MISMATCH");

        uint256 output_count = output_token_ids.length;
        require((output_count > 0) && (output_count == output_amounts.length),"OUTPUT_DIM_MISMATCH");

        delete templates[template_id].inputs;
        delete templates[template_id].outputs;

        for(uint256 i = 0; i < input_count; i++)
            templates[template_id].inputs.push(CraftElement(input_token_ids[i],input_amounts[i]));
        
        for(uint256 i = 0; i < output_count; i++)
            templates[template_id].outputs.push(CraftElement(output_token_ids[i],output_amounts[i]));
            
        emit OnCraftFormulaUpdated(template_id,templates[template_id]);
    }

    function update_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        _update_template_input(template_id,input_token_id,input_amount);
    }
    function update_template_output(uint256 template_id,uint256 output_token_id,uint256 output_amount) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        _update_template_output(template_id,output_token_id,output_amount);
    }

    function update_template_inputs(uint256 template_id,uint256[] memory input_token_ids,uint256[] memory input_amounts) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        uint256 input_count = input_token_ids.length;
        require(input_count == input_amounts.length,"INPUT_DIM_MISMATCH");
        for(uint256 i = 0; i < input_count; i++)
           _update_template_input(template_id,input_token_ids[i],input_amounts[i]);
    }
    function update_template_outputs(uint256 template_id,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        uint256 output_count = output_token_ids.length;
        require(output_count == output_amounts.length,"OUTPUT_DIM_MISMATCH");
        for(uint256 i = 0; i < output_count; i++)
           _update_template_output(template_id,output_token_ids[i],output_amounts[i]);
    }
    function craft(uint256 template_id,uint256 applyCount) external payable{
       require((applyCount > 0),"ZERO_APPLY_COUNT");
       address token_contract = get_token_contract_address();
       require((token_contract != address(0)),"NO_TOKEN_CONTRACT");
       require(is_enabled(template_id),"TEMPLATE_DISABLED");
       require(_is_template_valid(templates[template_id],token_contract),"INVALID_TEMPLATE");

       IERC1155TokenContract asCraftable = IERC1155TokenContract(token_contract);
       CraftFormula memory template = templates[template_id];
       for(uint8 i = 0; i < template.inputs.length; i++)
            asCraftable.burnNFTFor(msg.sender, template.inputs[i].token_id,template.inputs[i].amount.mul(applyCount));
       for(uint8 i = 0; i < template.outputs.length; i++)
            asCraftable.mintNFTFor(msg.sender, template.outputs[i].token_id,template.outputs[i].amount.mul(applyCount));       
        consume_operation_cost(template_id,applyCount);
    }
    function _update_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) internal {
        require((input_amount > 0) && (input_token_id > 0),"INVALID_INPUT");
        uint256 input_count = templates[template_id].inputs.length;
        for(uint256 i = 0; i < input_count; i++){
            if(templates[template_id].inputs[i].token_id == input_token_id){
                templates[template_id].inputs[i].amount = input_amount;
                return;
            }
        }
        templates[template_id].inputs.push(CraftElement(input_token_id,input_amount));
    }
    function _update_template_output(uint256 template_id,uint256 output_token_id,uint256 output_amount) internal {
        require((output_amount > 0) && (output_token_id > 0),"INVALID_OUTPUT");
        uint256 output_count = templates[template_id].outputs.length;
        for(uint256 i = 0; i < output_count; i++){
            if(templates[template_id].outputs[i].token_id == output_token_id){
                templates[template_id].outputs[i].amount = output_amount;
                return;
            }
        }
        templates[template_id].outputs.push(CraftElement(output_token_id,output_amount));
    }
    function onUndefineTemplate(uint256 template_id) internal virtual override{
        delete templates[template_id];
    }
    function _is_template_valid(CraftFormula memory template,address token_caddr) internal view returns(bool){
        if(template.inputs.length == 0 || template.outputs.length == 0)
            return false;

        IERC1155TokenContract asCraftable = IERC1155TokenContract(token_caddr);
        for(uint8 i = 0; i < template.inputs.length; i++){
            if(template.inputs[i].amount == 0 || (!asCraftable.is_token_defined(template.inputs[i].token_id)))
                return false;
        }
         for(uint8 i = 0; i < template.outputs.length; i++){
            if(template.outputs[i].amount == 0 || (!asCraftable.is_token_defined(template.outputs[i].token_id)))
                return false;
        }
        return true;
    }
    function get_template_formula(uint256 template_id) external view returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
       CraftFormula memory template = templates[template_id];
       uint256 input_count = template.inputs.length;
       uint256[] memory _input_token_ids = new uint256[](input_count);
       uint256[] memory _input_amounts = new uint256[](input_count);
       for(uint8 i = 0; i < input_count; i++){
            _input_token_ids[i] = template.inputs[i].token_id;
            _input_amounts[i] = template.inputs[i].amount;
       }

       uint256 output_count = template.outputs.length;
       uint256[] memory _output_token_ids = new uint256[](output_count);
       uint256[] memory _output_amounts = new uint256[](output_count);
       for(uint8 i = 0; i < output_count; i++){
            _output_token_ids[i] = template.outputs[i].token_id;
            _output_amounts[i] = template.outputs[i].amount;
       }
       return (_input_token_ids,_input_amounts,_output_token_ids,_output_amounts);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155CraftTemplates).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155CraftTemplates {
    
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenContract {

     //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    function lastTokenIds() external view returns (uint256);
    
    //Return token ids and amount.
    function ownedTokenOf(address _addr) external view returns(uint256[] memory,uint256[] memory);

    function canMintForAmount(uint256 tokenId,uint256 tokmentAmount) external view returns(bool);

    function canMintBulkForAmount(uint256[] memory tokenIds,uint256[] memory tokmentAmounts) external view returns(bool);
    
    function is_token_defined(uint256 token_id) external view returns (bool);

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenOperatableTemplate {
    
    function get_template_metadata(uint256 template_id) external view returns (string memory,string memory,uint256,bool,address);

    function is_template_defined(uint256 template_id) external view returns (bool);

    function is_template_enabled(uint256 template_id) external view returns (bool);

    function get_token_contract() external view returns (address);
}