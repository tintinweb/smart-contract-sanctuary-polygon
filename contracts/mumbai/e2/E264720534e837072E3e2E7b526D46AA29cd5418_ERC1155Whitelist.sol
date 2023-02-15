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
contract CooperatableBase is Ownable 
{
    mapping (address => bool) cooperative_contracts;
    function add_cooperative(address contract_addr) external onlyOwner{
        cooperative_contracts[contract_addr] = true;
    }
    function add_cooperatives(address[] memory contract_addrs) external onlyOwner {
        for(uint256 i = 0; i < contract_addrs.length; i++)
            cooperative_contracts[contract_addrs[i]] = true;
    }

    function remove_cooperative(address contract_addr) external onlyOwner {
        delete cooperative_contracts[contract_addr];
    }
    function remove_cooperatives(address[] memory contract_addrs) external onlyOwner{
        for(uint256 i = 0; i < contract_addrs.length; i++)
           delete cooperative_contracts[contract_addrs[i]];
    }
    function is_cooperative_contract(address _addr) internal view returns (bool){return cooperative_contracts[_addr];}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC1155Whitelist.sol";
import "../base/WhitelistContractBase.sol";
import "../Interfaces/IERC1155WhitelistMintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC1155WhitelistContractBase is  IERC1155Whitelist ,WhitelistContractBase 
{
    using SafeMath for uint256;

    mapping(uint256 => uint256) private _item_quotas;
    mapping(uint256 => uint256) private _item_remains;
    mapping(uint256 => uint256) private _item_prices;

    uint256 private max_token_id = 0;

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) 
        WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_){
    }
    
    function get_item_quota(uint256 token_id) internal view returns(uint256) {return _item_quotas[token_id];}
    function get_item_remains(uint256 token_id) internal view returns(uint256) {return _item_remains[token_id];}
    function get_item_prices(uint256 token_id) internal view returns(uint256) {return _item_prices[token_id];}
    function get_max_token_id() internal view returns (uint256) {return max_token_id;}

    function deduct_token_remain(uint256 token_id,uint256 deduct_amount) internal {
         _item_remains[token_id] = _item_remains[token_id].sub(deduct_amount);
    }

    function fetch_token_contract_interface_id() internal virtual override view returns(bytes4){return type(IERC1155WhitelistMintable).interfaceId;}
    function define_mint_item(uint256 token_id,uint256 quota ,uint256 per_wallet_quota,uint256 price_per_token) external onlyOwner {
        address _token_address = get_token_contract_address();
        require(_token_address != address(0) && IERC1155WhitelistMintable(_token_address).isTokenDefineForWhitelist(token_id),"NO_MINTABLE_TOKEN");
        _define_mint_item(token_id,quota ,per_wallet_quota,price_per_token);
    }
    function undefine_mint_item(uint256 token_id) external onlyOwner {
        _undefine_mint_item(token_id);
    }
    function define_mint_item_batch(uint256[] memory token_ids,uint256[] memory quotas ,uint256[] memory per_wallet_quotas,uint256[] memory price_per_tokens) external onlyOwner{
        address _token_address = get_token_contract_address();
        require(_token_address != address(0),"NO_MINTABLE_TOKEN");
        
        IERC1155WhitelistMintable asMintable = IERC1155WhitelistMintable(_token_address);
        
        uint256 token_count = token_ids.length;
        require((token_count == quotas.length) && (token_count == per_wallet_quotas.length) && (token_count == price_per_tokens.length),"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < token_count; i++){
            require(asMintable.isTokenDefineForWhitelist(token_ids[i]),"NO_MINTABLE_TOKEN");
            _define_mint_item(token_ids[i],quotas[i],per_wallet_quotas[i],price_per_tokens[i]);
        }
    }
    function mint(uint256 token_id,uint256 amount) external payable {
        address _token_addr = get_token_contract_address();
        require(_token_addr != address(0),"TOKEN_UNDEFINED");
        consume_mint_quota(msg.sender,token_id,amount);
        consume_mint_fee(_item_prices[token_id],amount);
        IERC1155WhitelistMintable(_token_addr).whitelistMint(msg.sender, token_id, amount);
    }
    function _define_mint_item(uint256 token_id,uint256 quota,uint256 per_wallet_quota,uint256 price) internal{
        /*Check it's already defined*/
        require((quota > 0) && (per_wallet_quota > 0),"ZERO_AMOUNT");
        if(_item_quotas[token_id] == 0){
            _item_quotas[token_id] = quota;
            _item_remains[token_id] = quota;
            _item_prices[token_id] = price;
            onMintItemDefined(token_id,per_wallet_quota);
            if(token_id > max_token_id)
                max_token_id = token_id;
        }
    }
    function _undefine_mint_item(uint256 token_id) internal{
        if(_item_quotas[token_id] > 0){
            delete _item_quotas[token_id];
            delete _item_remains[token_id];
            delete _item_prices[token_id];
            onMintItemUndefined(token_id);
        }
    }
    function update_token_price(uint256 token_id ,uint256 price_per_token) external onlyOwner {
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_prices[token_id] = price_per_token;
    }
    function update_token_quota(uint256 token_id , uint256 token_quota) external onlyOwner{
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_quotas[token_id] = token_quota;
        if(token_quota < _item_remains[token_id]){
            _item_remains[token_id] = token_quota;
            onClampPerWalletItem(token_id);
        }
        onUpdateTokenQuota(token_id,token_quota);
    }
    function update_token_remain(uint256 token_id ,uint256 token_remain) external onlyOwner{
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        if(token_remain > _item_quotas[token_id])
            _item_remains[token_id] = _item_quotas[token_id];
        else
            _item_remains[token_id] = token_remain;
        onClampPerWalletItem(token_id);
    }
    function update_mint_quota(uint256 token_id,uint256 token_quota,uint256 token_remain) external onlyOwner{
        require((token_quota > 0) && (token_remain > 0),"ZERO_AMOUNT");
        require(token_remain <= token_quota,"SUPPLY_OVERFLOW");
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_quotas[token_id] = token_quota;
        _item_remains[token_id] = token_remain;
        onUpdateMintQuota(token_id,token_quota,token_remain);
        onClampPerWalletItem(token_id);
    }
    
    function onClampPerWalletItem(uint256) internal virtual {}
    function onMintItemDefined(uint256,uint256) internal virtual {}
    function onMintItemUndefined(uint256) internal virtual {}

    function onUpdateTokenQuota(uint256 token_id , uint256 token_quota) internal virtual {}
    function onUpdateMintQuota(uint256 token_id,uint256 token_quota,uint256 token_remain) internal virtual {}

    function consume_mint_quota(address,uint256,uint256) internal virtual {
        require(false,"MINT_CONSUME_UNIMPLEMENT");
    }
    function get_mintable_items() external view virtual override returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 mintable_item_count = 0;
        for(uint256 tId = 1; tId <= max_token_id; tId++){
            if(_item_quotas[tId] > 0)
                mintable_item_count = mintable_item_count.add(1);
        }

        uint256 counter = 0;
        uint256[] memory token_ids = new uint256[](mintable_item_count);
        uint256[] memory total_minted = new uint256[](mintable_item_count);
        uint256[] memory total_quotas = new uint256[](mintable_item_count);
        uint256[] memory token_prices = new uint256[](mintable_item_count);
        for(uint256 tId = 1; tId <= max_token_id; tId++){
            if(_item_quotas[tId] > 0)
            {
                token_ids[counter] = tId;
                total_quotas[counter] = _item_quotas[tId];
                total_minted[counter] = _item_quotas[tId] - _item_remains[tId];
                token_prices[counter] = _item_prices[tId];
                counter = counter.add(1);
            }
        }
        return (token_ids,total_minted,total_quotas,token_prices);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Whitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Util/Cooperatable.sol";
import "./WhitelistContractBase.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

abstract contract WalletEligibedOnlyContract {
    
    address[] private _wallets;
    uint256 private wallet_count = 0;
    mapping(address => uint256) private _wallet_indics;

    constructor(uint256 max_addresses) {
        _wallets = new address[](max_addresses);
    }
    
    function _add_whitelist_wallets(address[] memory wallets) internal {
        for(uint256 i = 0; i < wallets.length;i++){
           _add_whitelist_wallet(wallets[i]);
        }
    }
    function _add_whitelist_wallet(address addr) internal {
        if(_add_wallet(addr)){
            onWhitelistWalletAdded(addr);
        }
    }
    function _remove_whitelist_wallet(address addr) internal {
        if(_remove_wallet(addr)){
           onWhitelistWalletRemoved(addr);
        }
    }
    function _add_wallet(address addr) internal returns (bool){
        if(_wallet_indics[addr] == 0){
            _wallets[wallet_count] = addr;
            wallet_count++;
            _wallet_indics[addr] =wallet_count;
            return true;
        }
        return false;
    }
    //Use remove swap to prevent hold (address(0)) wallet in array.
    function _remove_wallet(address addr) internal returns (bool){
        if(_wallet_indics[addr] > 0){
            
            uint256 index = _wallet_indics[addr];
            _wallet_indics[addr] = 0;
            _wallets[index - 1] = address(0);

            if(wallet_count > 0){
                address _last_wallet = _wallets[wallet_count - 1];
                _wallets[index - 1] = _last_wallet;
                _wallet_indics[_last_wallet] = index;
                _wallets[wallet_count - 1] = address(0);
                wallet_count--;
            }
            return true;
        }
        return false;
    }

    function get_wallet_count() public view returns(uint256) {return wallet_count;}
    function get_wallet_address(uint256 index) public view returns(address){return _wallets[index];}
    function has_wallet(address addr) public view returns(bool){return (_wallet_indics[addr] > 0);}
    function get_wallets() public view returns (address[] memory){return _wallets;}
    
    //Invoke after whitelist wallet added
    function onWhitelistWalletAdded(address addr) internal virtual {}

    //Invoke after whitelist wallet removed
    function onWhitelistWalletRemoved(address addr) internal virtual {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Interfaces/IWhitelistContract.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract WhitelistContractBase is Ownable,IWhitelistContract,ERC165{

    using ERC165Checker for address;
    using SafeMath for uint256;
    using Address for address;

    string private name;
    string private description;
    address private merchant_address;
    
    uint256 private individual_cap;

    //NFT or Token to mint
    address private token_contract = address(0);
    //Interface id of token or NFT.
    bytes4 private token_constract_interface_id = 0xffffffff;

    address private price_currency_contract = address(0);
    bytes4 constant price_currency_interface_id = type(IERC20).interfaceId;

    mapping(address => uint256) private _wallet_remains;

    event OnMerchantChanged(address indexed previousMerchant, address indexed newMerchant);
    event OnWhitelistMetadataUpdated(string name,string desc,uint256 individual_cap);

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) {
        name = name_;
        description = description_;
        individual_cap = individual_cap_;
        merchant_address = msg.sender;
        token_constract_interface_id = fetch_token_contract_interface_id();

        _set_token_contract_internal(token_contract_);
        _set_price_currency_internal(price_currency_);
    }

    function get_individual_cap() public view returns (uint256){return individual_cap;}
    function get_merchant_adddress() public view returns (address){return merchant_address;}
    function get_token_contract_address() public view returns(address) {return token_contract;}
    function fetch_token_contract_interface_id() internal virtual view returns(bytes4){return 0xffffffff;}
    function get_wallet_remain(address addr) public view virtual returns(uint256){return _wallet_remains[addr];}
    function init_wallet_remain(address addr) internal virtual { _wallet_remains[addr] = individual_cap;}
    function clear_wallet_remain(address addr) internal virtual {delete _wallet_remains[addr];}
    function deduct_wallet_remain(address addr,uint256 deduct_amount) internal {
        _wallet_remains[addr] = _wallet_remains[addr].sub(deduct_amount);
    }

    function _set_token_contract_internal(address addr) internal {
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_TOKEN");
        token_contract = addr;
    }
    function _set_price_currency_internal(address addr) internal {
        require(addr == address(0) || addr.supportsInterface(price_currency_interface_id),"UNSUPPORT_CURRENCY");
        price_currency_contract = addr;
    }
    function set_token_contract(address addr) external onlyOwner {
        _set_token_contract_internal(addr);
    }
    function set_price_currency_contract(address addr) external onlyOwner{
        _set_price_currency_internal(addr);
    }
    function consume_mint_fee(uint256 price_per_token,uint256 amount) internal{
        
        require(amount > 0,"ZERO_AMOUNT");
        //free operation just skip.
        if(price_per_token == 0)
            return;

        require(merchant_address != address(0),"NO_MERCHANT_ADDR");

        uint256 total_mint_fee = price_per_token.mul(amount);
        if(price_currency_contract != address(0)){
           uint256 available_balance = IERC20(price_currency_contract).balanceOf(msg.sender);
           require(available_balance >= total_mint_fee,"UNSUFFICIENT_BALANCE");
           IERC20(price_currency_contract).transferFrom(msg.sender, merchant_address, total_mint_fee);
           if(msg.value > 0) //In-case accident has value from sender , just return back.
              payable(msg.sender).transfer(msg.value);
        }
        else{
            require(msg.value >= total_mint_fee,"UNSUFFICIENT_BALANCE");
            uint256 remain_value = msg.value.sub(total_mint_fee);
            payable(merchant_address).transfer(total_mint_fee);
            //Send back changes
            payable(msg.sender).transfer(remain_value);
        }
    }
    function change_owner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }
    function set_name(string memory newName) external onlyOwner {
        name = newName;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_description(string memory newDesc) external onlyOwner{
        description = newDesc;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_individual_cap(uint256 newCap) external onlyOwner{
        individual_cap = newCap;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_merchant(address newMerchant) external virtual onlyOwner{
        require((merchant_address != newMerchant) && (newMerchant != address(0)),"INVALID_MERCHANT");
        require(!newMerchant.isContract(),"MERCHANT_CANNOT_CONTRACT");       
        
        address _old_merchant = merchant_address;
        merchant_address = newMerchant;
        emit OnMerchantChanged(_old_merchant,merchant_address);
    }
    function get_metadata() external view virtual override returns (string memory,string memory,uint256,address,address){
        return (name,description,individual_cap,token_contract,price_currency_contract);
    }   
    function get_minted_amount(address addr) external view returns (uint256){
         return individual_cap.sub(get_wallet_remain(addr));
    }
    
    function get_minted_state(address addr) external view returns (uint256,uint256){
        return (individual_cap.sub(get_wallet_remain(addr)),individual_cap);
    }

    function get_quota_amount(address) external view virtual override returns (uint256){return individual_cap;}

    function get_all_wallets() external view virtual override returns (address[] memory){return new address[](0);}

    function get_token_contract() external view virtual override returns (address){return get_token_contract_address();}

    function get_price_currency_contract() external view virtual override returns (address){return price_currency_contract;}

    function is_public_whitelist() external view virtual override returns (bool){return true;}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IWhitelistContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155Whitelist {
    
    /*Mint funcitons*/
    function mint(uint256 token_id,uint256 amount) external payable;

    /*Return mintable (token_ids,minted amount,quotas,prices)*/
    function get_mintable_items() external view returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory);

    /*Return token (remain and total) amount for address */
    function get_token_minted_state(address addr,uint256 token_id) external view returns (uint256,uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155WhitelistMintable {
    
    function whitelistMint(address _addr,uint256 tokenId,uint256 amount) external;

    function isTokenDefineForWhitelist(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenOperatableTemplate {
    
    function get_template_metadata(uint256 template_id) external view returns (string memory,string memory,uint256,bool,address);

    function is_template_defined(uint256 template_id) external view returns (bool);

    function is_template_enabled(uint256 template_id) external view returns (bool);

    function get_token_contract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
interface IWhitelistContract {

    /*Retreive metada for whitelist
        + name , description,individual cap,token address,price currency address.
    */
    function get_metadata() external view returns (string memory,string memory,uint256,address,address);

    /*Return minted amount of address*/
    function get_minted_amount(address addr) external view returns (uint256);

    /*Return mint quota of address*/
    function get_quota_amount(address addr) external view returns (uint256);
    
    /*Return (minted and total) amount for address */
    function get_minted_state(address addr) external view returns (uint256,uint256);

    /* Address from one of these interfaces 
        + IERC721WhitelistMintable
        + IERC1155WhitelistMintable
    */
    function get_token_contract() external view returns (address);

    /*Address from IERC20 Interface*/
    function get_price_currency_contract() external view returns (address);

    /*Return all whitelist wallet*/
    function get_all_wallets() external view returns (address[] memory);

    /*Return true if public whitelist otherwise false*/
    function is_public_whitelist() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/CooperatableBase.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../Interfaces/ITokenOperatableTemplate.sol";

contract Cooperatable is CooperatableBase 
{
    using ERC165Checker for address;
    
    modifier onlyOwnerAndOperatableTemplate(){
        bool _as_owner = owner() == msg.sender;
        bool _as_operatable_template = msg.sender.supportsInterface(type(ITokenOperatableTemplate).interfaceId) && ITokenOperatableTemplate(msg.sender).get_token_contract() == address(this) && is_cooperative_contract(msg.sender);
        require(_as_owner || _as_operatable_template,"NOT_OPERATABLE_TEMPLATE");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../base/ERC1155WhitelistContractBase.sol";
import "../base/WalletEligibedOnlyContract.sol";

contract ERC1155Whitelist is  ERC1155WhitelistContractBase ,WalletEligibedOnlyContract 
{
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _item_per_wallet_remains;
    
    mapping(uint256 => uint256) private _item_per_wallet_quotas;
    
    constructor(string memory name_,string memory description_,uint256 individual_cap_,uint256 max_addresses,address token_contract_,address price_currency_) 
        ERC1155WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_)
        WalletEligibedOnlyContract(max_addresses){
    }
    function add_whitelist_wallets(address[] memory wallets) external onlyOwner {_add_whitelist_wallets(wallets);}
    function add_whitelist_wallet(address wallet) external onlyOwner {_add_whitelist_wallet(wallet);}
    
    function get_item_per_wallet_quota(uint256 token_id) internal view returns(uint256) {return _item_per_wallet_quotas[token_id];}
    function get_item_per_wallet_remain(address addr,uint256 token_id) internal view returns(uint256) {return _item_per_wallet_remains[addr][token_id];}
    
    function init_wallet_remain(address addr) internal virtual override{ 
        super.init_wallet_remain(addr);
        uint256 _max_token_id = get_max_token_id();
        for(uint256 id=1; id <= _max_token_id; id++){
            if((get_item_quota(id) > 0) && (_item_per_wallet_remains[addr][id] == 0)){
                _item_per_wallet_remains[addr][id] =_item_per_wallet_quotas[id];
            }
        }
    }
    function clear_wallet_remain(address addr) internal virtual override {
        super.clear_wallet_remain(addr);
        uint256 _max_token_id = get_max_token_id();
        for(uint256 id=1; id <= _max_token_id; id++){
            if((get_item_quota(id) > 0) && (_item_per_wallet_remains[addr][id] > 0)){
                _item_per_wallet_remains[addr][id];
            }
        }
    }
    function clamp_item_per_wallet_quota(uint256 token_id , uint256 token_quota) internal{
        if(token_quota < _item_per_wallet_quotas[token_id])
            _item_per_wallet_quotas[token_id] = token_quota;
    }
    function onUpdateTokenQuota(uint256 token_id , uint256 token_quota) internal virtual override{
        clamp_item_per_wallet_quota(token_id,token_quota);   
    }
    function onUpdateMintQuota(uint256 token_id,uint256 token_quota,uint256) internal virtual override{
        clamp_item_per_wallet_quota(token_id,token_quota);   
    }
    function onWhitelistWalletAdded(address addr) internal virtual override {
        super.onWhitelistWalletAdded(addr);
        init_wallet_remain(addr);
    }
    function onWhitelistWalletRemoved(address addr) internal virtual override {
        super.onWhitelistWalletRemoved(addr);
        clear_wallet_remain(addr);
    }
    function onClampPerWalletItem(uint256 token_id) internal virtual override{
        super.onClampPerWalletItem(token_id);
        uint256 wallet_count = get_wallet_count();
        uint256 _item_remain = get_item_remains(token_id);
        for(uint256 i; i <= wallet_count; i++){
            address wallet = get_wallet_address(i);
            if(_item_remain < _item_per_wallet_remains[wallet][token_id])
                _item_per_wallet_remains[wallet][token_id] = _item_remain;   
        }
    }
    function onMintItemDefined(uint256 token_id,uint256 per_wallet_quota) internal virtual override {
        super.onMintItemDefined(token_id,per_wallet_quota);
        _item_per_wallet_quotas[token_id] = per_wallet_quota;
        uint256 wallet_count = get_wallet_count(); 
        for(uint256 i = 0; i < wallet_count; i++){
            address _wallet_adddr = get_wallet_address(i);
            _item_per_wallet_remains[_wallet_adddr][token_id] = per_wallet_quota;
        }
    }
    function onMintItemUndefined(uint256 token_id) internal virtual override {
        super.onMintItemUndefined(token_id);
        delete _item_per_wallet_quotas[token_id];
        uint256 wallet_count = get_wallet_count();
        for(uint256 i = 0; i < wallet_count; i++){
            delete _item_per_wallet_remains[get_wallet_address(i)][token_id];
        }
    }
    function deduct_item_per_wallet_remain(address addr,uint256 token_id,uint256 deduct_amount) internal{
        _item_per_wallet_remains[addr][token_id] = _item_per_wallet_remains[addr][token_id].sub(deduct_amount);
    }
    function consume_mint_quota(address addr,uint256 token_id,uint256 amount) internal virtual override {
        
        require(has_wallet(addr),"NOT_WHITELIST");
        require(get_wallet_remain(addr) >= amount,"OUT_OF_QUOTA"); 
        require(_item_per_wallet_remains[addr][token_id] >= amount,"OUT_OF_QUOTA");
        require(get_item_remains(token_id) >= amount,"OUT_OF_SUPPLY");

        deduct_wallet_remain(addr, amount);
        deduct_item_per_wallet_remain(addr,token_id,amount);
        deduct_token_remain(token_id,amount);
    }
    function is_public_whitelist() external view virtual override returns (bool){return false;}

    function get_token_minted_state(address addr,uint256 token_id) external view virtual override returns (uint256,uint256){
        uint256 _quota = get_item_per_wallet_quota(token_id);
        uint256 _remain = has_wallet(addr) ? _item_per_wallet_remains[addr][token_id] : _quota;
        return (_quota - _remain,_quota);
    }
    function get_wallet_remain(address addr) public view virtual override returns(uint256){
        return has_wallet(addr) ? super.get_wallet_remain(addr) : get_individual_cap();
    }
    function get_all_wallets() external view virtual override returns (address[] memory){return get_wallets();}
}